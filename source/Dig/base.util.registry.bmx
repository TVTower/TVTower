Rem
	====================================================================
	Class managing assets, configs, ...
	====================================================================

	The registry Type is a Getter/Setter managing multiple assets and
	resources of an app.

	There exist helper functions to allow lazy/threaded loading of
	assets.

	This file includes loaders only requiring the same "imports"
	as the Registry/XML-Loader itself.

	Recognized types:
	-> <data> OR <myname type="data">
	-> <file> OR <myname type="file">

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2015 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
EndRem
SuperStrict
Import BRL.Map
?Threaded
Import Brl.threads
?
Import "base.util.data.bmx"
Import "base.util.event.bmx"
Import "base.util.xmlhelper.bmx"
Import "base.util.logger.bmx"


Type TRegistry
	'holding the data in the registry
	Field data:TMap = CreateMap()
	'holding default objects in case something does not exist
	Field defaults:TMap = CreateMap()
	?Threaded
	Field _dataMutex:TMutex = CreateMutex()
	?

	Global _instance:TRegistry


	Function GetInstance:TRegistry()
		If Not _instance Then _instance = New TRegistry
		Return _instance
	End Function


	Method Init:TRegistry()
		data.Clear()
	End Method


	'set a data with the given key
	Method Set(key:String, obj:Object)
		?Threaded
			LockMutex(_dataMutex)
		?
		data.insert(key.ToUpper(), obj)
		?Threaded
			UnlockMutex(_dataMutex)
		?
	End Method


	'set a default object for a data type
	Method GetDefault:Object(key:String)
		Return defaults.ValueForKey(key.ToUpper())
	End Method


	'set a default object for a data type
	Method SetDefault(key:String, obj:Object)
		?Threaded
			LockMutex(_dataMutex)
		?
		defaults.insert(key.ToUpper(), obj)
		?Threaded
			UnlockMutex(_dataMutex)
		?
	End Method


	Method Get:Object(key:String, defaultObject:Object=Null, defaultType:String="")
		Local res:Object = data.ValueForKey(key.toUpper())
		'try to get the default object
		If Not res
			If String(defaultObject)<>""
				res = data.ValueForKey(String(defaultObject).toUpper())
			Else
				res = defaultObject
			EndIf
		EndIf

		'still no res (none by key, no defaultObject)
		'try to find defaultType
		If Not res And defaultType <> ""
			'does a default object exist in defaults list?
			res = defaults.ValueForKey(defaultType.toUpper())
			If res Then Return res
		EndIf

		Return res
	End Method


	Method ToString:String()
		Local elementCount:Int = 0
		For Local k:String = EachIn data.Keys()
			elementCount :+ 1
		Next

		Return "TRegistry: " + elementCount + " data elements."
	End Method
End Type

'===== CONVENIENCE REGISTRY ACCESSORS =====
Function GetRegistry:TRegistry()
	Return TRegistry.GetInstance()
End Function

Function GetDataFromRegistry:TData(name:String, defaultNameOrObject:Object = Null)
	Return TData( GetRegistry().Get(name, defaultNameOrObject, "data") )
End Function

Function GetStringFromRegistry:String(name:String, defaultNameOrObject:Object = Null)
	Return String( GetRegistry().Get(name, defaultNameOrObject, "string") )
End Function




'==== LOADER TO FILL REGISTRY FROM FILES ====

Type TRegistryLoader
	'base url prepended to all given paths in a config-file
	Field baseURI:String = ""
	Field xmlHelper:TXmlHelper

	'holding descendants of TRegistryResourceLoader which handle
	'certain types.
	'map-key is TYPENAME in uppercase
	Global resourceLoaders:TMap = CreateMap()
	Global _defaultsCreated:Int = False


	Method New()
		If Not _defaultsCreated
			'give loaders a chance to create default resources
			TRegistryLoader.CreateRegistryDefaults()
			_defaultsCreated = True
		EndIf
	End Method



	Function RegisterResourceLoader:Int(resourceLoader:TRegistryBaseLoader, resourceNames:String="")
		If resourceNames = "" Then resourceNames = resourceLoader.resourceNames

		For Local resourceName:String = EachIn resourceNames.Split("|")
			resourceLoaders.insert(resourceName.ToUpper(), resourceLoader)
		Next
	End Function


	Function CreateRegistryDefaults:Int()
		'give loaders a chance to create a default resources
		'but: call in order of creation, not sorted by name
		'so dependencies are solved
		Local resList:TList = CreateList()
		For Local loader:TRegistryBaseLoader = EachIn resourceLoaders.Values()
			resList.AddLast(loader)
		Next
		SortList(resList)

		For Local loader:TRegistryBaseLoader = EachIn resList
			loader.CreateDefaultResource()
		Next
	End Function


	Function GetResourceLoader:TRegistryBaseLoader(resourceName:String)
		Return TRegistryBaseLoader(resourceLoaders.ValueForKey(resourceName.ToUpper()))
	End Function


	Method SetBaseURI:TRegistryLoader(baseURI:String)
		Self.baseURI = baseURI
		Return Self
	End Method


	'appends a given uri to the current base uri
	Method GetUri:String(uri:String="")
		?android
			'try to prepend "sdl::" if the file seems to be within the
			'APK
			If FileSize(uri) <= 0 And uri.Find("sdl::") <> 0
				uri = "sdl::"+uri
			EndIf
		?

		Return baseURI + uri
	End Method


	Method LoadFromXML:Int(file:String, forceDirectLoad:Int=False)
		file = GetUri(file)

		xmlHelper = TXmlHelper.Create(file, "", False)
		If Not xmlHelper.xmlDoc
			TLogger.Log("TRegistryLoader.LoadFromXML", "file '" + file + "' not found or invalid.", LOG_LOADING)
			Return False
		EndIf


		LoadResourcesFromXML(xmlHelper.GetRootNode(), file, forceDirectLoad)

		'load everything until everything from that file was loaded
		If forceDirectLoad
			Local instance:TRegistryUnloadedResourceCollection = TRegistryUnloadedResourceCollection.GetInstance()
			Repeat
				instance.Update()
			Until instance.FinishedLoading()
		EndIf


		EventManager.triggerEvent( TEventSimple.Create("RegistryLoader.onLoadXmlFromFinished", New TData.AddString("uri", file) ) )
		Return True
	End Method


	Method LoadResourcesFromXML:Int(node:TxmlNode, source:Object, forceDirectLoad:Int=False)
		For Local resourceNode:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
			LoadSingleResourceFromXML(resourceNode, source, forceDirectLoad)
		Next
	End Method


	Method LoadSingleResourceFromXML:Int(node:TxmlNode, source:Object, forceDirectLoad:Int=False, extras:TData = Null)
		'get the name defined in:
		'- type (<bla type="identifier" />) or
		'- tagname ( <identifier x="1" />)
		Local resourceName:String = TXmlHelper.FindValue(node, "type", node.getName())

		'we handle "resource" on our own
		If resourceName.ToUpper() = "RESOURCES"
			Local directLoad:Int = TXmlHelper.findValueBool(node, "directload", forceDirectLoad)
			LoadResourcesFromXML(node, source, directLoad)
		Else
			Local loader:TRegistryBaseLoader = GetResourceLoader(resourceName)
			If loader
				'load config from XML
				Local conf:TData = loader.GetConfigFromXML(Self, node)

				'do nothing without a configuration (maybe it is a virtual group handled
				'directly by the loader -> eg. "fonts" which only groups "font")
				If conf
					conf.Add("_xmlSource", source)

					'merge in the extras (eg. overwrite "names")
					If extras Then conf.Append(extras)

					Local lazyLoad:Int = Not (loader.directLoading Or forceDirectLoad)

					'directly load the objects or defer to a helper
					If Not lazyLoad
						'if direct loading failed ... load it later
						If Not loader.LoadFromConfig(conf, resourceName)
							lazyLoad = True
						EndIf
					EndIf

					If lazyLoad
						'try to get a name for the resource:
						'a) from TData "extras"
						'b) from the config read from xml
						Local name:String = conf.GetString("name")
						If name = "" Then name = loader.GetNameFromConfig(conf)

						AddLazyLoadedResource(name, resourceName, conf)
					EndIf
				EndIf
			EndIf
		EndIf

		'inform others about the to-load-element
		'sender: self (the loader)
		'target: resourceName in uppercases ("SPRITE") -> so listeners can filter on it
		'print "RegistryLoader.onLoadResourceFromXML: self + "+ resourceName.ToUpper()
		EventManager.triggerEvent( TEventSimple.Create("RegistryLoader.onLoadResourceFromXML", New TData.AddString("resourceName", resourceName).Add("xmlNode", node), Self, resourceName.ToUpper()))
	End Method


	Function AddLazyLoadedResource(name:String, resourceName:String, data:TData)
		'add to "ToLoad"-list
		TRegistryUnloadedResourceCollection.GetInstance().Add(..
			New TRegistryUnloadedResource.Init(name, resourceName, data)..
		)
	End Function
End Type




'collection handling multiple resourcecontainers (unloaded resources)
Type TRegistryUnloadedResourceCollection
	'simple counters for a 1of10-display
	Field toLoadCount:Int = 0
	Field loadedCount:Int = 0
	'list files containing names of loaded resources
	Field loadedLog:TList = CreateList()
	Field failedLog:TList = CreateList()
	'list files containing objects to get loaded
	Field unloadedResources:TList = CreateList()
	Field failedResources:TList = CreateList()
	'indicator if something failed when the last list got processed
	Field failedResourceLoaded:Int = False
	'indicator (cache) whether there is still something to load
	Field _finishedLoading:Int = True
	?Threaded
	Field _loadedMutex:TMutex = CreateMutex()
	Field _failedMutex:TMutex = CreateMutex()
	Field _unloadedMutex:TMutex = CreateMutex()
	Field _loaderThread:TThread
	?
	Global _instance:TRegistryUnloadedResourceCollection


	Function GetInstance:TRegistryUnloadedResourceCollection()
		If Not _instance Then _instance = New TRegistryUnloadedResourceCollection
		Return _instance
	End Function


	Method Add(resource:TRegistryUnloadedResource)
		?Threaded
			'wait for the listMutex to be unlocked (nobody modifying the list)
			LockMutex(_unloadedMutex)
		?
		unloadedResources.AddLast(resource)
		toLoadCount :+ 1
		?Threaded
			UnlockMutex(_unloadedMutex)
		?
		_finishedLoading = False
	End Method


	Method AddFailed(resource:TRegistryUnloadedResource)
		?Threaded
			'wait for the listMutex to be unlocked (nobody modifying the list)
			LockMutex(_failedMutex)
		?
		failedResources.AddLast(resource)
		failedLog.AddLast(resource.name)
		?Threaded
			UnlockMutex(_failedMutex)
		?
	End Method


	Method GetUnloadedCount:Int()
		?Threaded
			'wait for the listMutex to be unlocked (nobody modifying the list)
			LockMutex(_unloadedMutex)
			Local c:Int =  unloadedResources.Count()
			UnlockMutex(_unloadedMutex)
			Return c
		?Not Threaded
			Return unloadedResources.Count()
		?
	End Method


	Method GetFailedCount:Int()
		?Threaded
			'wait for the listMutex to be unlocked (nobody modifying the list)
			LockMutex(_failedMutex)
			Local c:Int = failedResources.Count()
			UnlockMutex(_failedMutex)
			Return c
		?Not Threaded
			Return failedResources.Count()
		?
	End Method


	'removes and returns the first element of the unloaded list
	Method PopFirstUnloadedResource:TRegistryUnloadedResource()
		?Threaded
			'wait for the listMutex to be unlocked (nobody modifying the list)
			LockMutex(_unloadedMutex)
		?
		Local res:TRegistryUnloadedResource = TRegistryUnloadedResource(unloadedResources.RemoveFirst())
		?Threaded
			UnlockMutex(_unloadedMutex)
		?
		Return res
	End Method


	Method AddToLoadedLog:Int(value:String)
		?Threaded
			'wait for the listMutex to be unlocked (nobody modifying the list)
			LockMutex(_loadedMutex)
		?
		loadedLog.AddLast(value)
		loadedCount :+ 1
		?Threaded
			UnlockMutex(_loadedMutex)
		?
	End Method


	Method FinishedLoading:Int()
		'if already calculated, just return true (gets "FALSE" on add of
		'a new resource)
		If _finishedLoading Then Return True
		'finished as soon as nothing to load and last cycle no
		'previously failed resource was loaded
		_finishedLoading = (GetUnloadedCount() = 0 And Not failedResourceLoaded)
		Return _finishedLoading
	End Method


	Method Update:Int()
		If FinishedLoading() Then Return True

		'threaded binary: kick off a loader thread
		'unthreaded: load the next one
		?Threaded
			If Not _loaderThread Or Not ThreadRunning(_loaderThread)
				_loaderThread = CreateThread(RunLoaderThread, Null)
			EndIf

			'helper function
			Function RunLoaderThread:Object(Input:Object)
				'this thread runs as long as there is something to load
				'-> it gets auto-recreated if no longer running but there is
				'something to load
				Repeat
					'try to load the next item
					TRegistryUnloadedResourceCollection.GetInstance().LoadNext()
					Delay(1)
				Until TRegistryUnloadedResourceCollection.GetInstance().FinishedLoading()
			End Function
		?Not Threaded
			LoadNext()
		?
	End Method


	Method LoadNext:Int()
		'refresh unloaded list with former failed resources
		'maybe they are now loadable (dependencies)
		If GetUnloadedCount() = 0
			'nothing to load
			If GetFailedCount() = 0 Then Return True

			'try failed again ?!
			unloadedResources = failedResources
			If failedResources
				failedResources.Clear()
			Else
				failedResources = CreateList()
			EndIf
			failedResourceLoaded = False
		EndIf

		Local toLoad:TRegistryUnloadedResource = PopFirstUnloadedResource()
		If Not toLoad Then Return True
		'try to load the resource
'Print "loading: " + toLoad.name
		If toLoad.Load()
			AddToLoadedLog(toLoad.name)
			'mark the fact that a previously failed resource was now
			'correctly loaded - indicator to loop through the failed again
			If toLoad.loadAttempts > 0 Then failedResourceLoaded = True
'Print "... done loading " + toLoad.name
			Return True
		EndIf
		'loading failed
		toLoad.loadAttempts :+1
'Print "  loading failed : "+ toLoad.name + " | "+ toLoad.loadAttempts
		'add to the list of failed resources
		AddFailed(toLoad)
		Return False
	End Method
End Type




'object containing information about an not yet loaded element
Type TRegistryUnloadedResource
	Field config:TData
	Field resourceName:String	'eg. "IMAGE"
	Field name:String			'eg. "my background" or "gfx/office/background.png"
	Field id:Int = 0
	Field loadAttempts:Int = 0 	'times engine tried to load this resource

	Global LastID:Int = 0


	Method New()
		LastID :+ 1
		id = LastID
	End Method


	Method Init:TRegistryUnloadedResource(name:String, resourceName:String, config:TData)
		Self.name = name
		Self.resourceName = resourceName.ToLower()
		Self.config = config
		Return Self
	End Method


	Method Load:Int()
		EventManager.triggerEvent(TEventSimple.Create("RegistryLoader.onBeginLoadResource", New TData.AddString("name", name).AddString("resourceName", resourceName)))

		'try to find a loader for the objects resource type
		Local loader:TRegistryBaseLoader = TRegistryLoader.GetResourceLoader(resourceName)
		If Not loader Then Return False

		'try to load an object with the given config and resourceType-name
		If loader.LoadFromConfig(config, resourceName)
			'inform others: we loaded something
			EventManager.triggerEvent(TEventSimple.Create("RegistryLoader.onLoadResource", New TData.AddString("name", name).AddString("resourceName", resourceName)))
			Return True
		Else
			Return False
		EndIf
	End Method


	'sort by ID
	Method Compare:Int(Other:Object)
		Local otherResource:TRegistryUnloadedResource = TRegistryUnloadedResource(Other)
		If otherResource
			If otherResource.id > id Then Return -1
			If otherResource.id < id Then Return 1
		EndIf
		Return Super.Compare(Other)
	End Method
End Type




'==== RESOURCE LOADER HANDLING SPECIFIC TYPES ====

'register basic loaders
New TRegistryFileLoader.Init()
New TRegistryDataLoader.Init()


'base loader
Type TRegistryBaseLoader
	Field name:String = "Base"
	Field resourceNames:String = "nothing"
	Field registered:Int = False
	Field directLoading:Int = False
	Field id:Int = 0
	Global LastID:Int = 0


	Method New()
		LastID :+ 1
		id = LastID
	End Method

	'call to initialize a loader, set names etc
	Method Init:Int() Abstract

	'called with the corresponding xmlNode containing the
	'element which the loader registered for
	'loads all recognized values of the node into a tdata-object
	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode) Abstract


	'return a printable identifier of this resource (url, spritename, ...)
	Method GetNameFromConfig:String(data:TData) Abstract


	'loading the objects contained in the data
	Method LoadFromConfig:Object(data:TData, resourceName:String) Abstract


	Method CreateDefaultResource:Int()
		'
	End Method


	'sort loaders according creation date
	Method Compare:Int(other:Object)
		Local otherLoader:TRegistryBaseLoader = TRegistryBaseLoader(other)
		'no weighting
		If Not otherLoader Then Return 0
		If otherLoader = Self Then Return 0
		'below me
		If otherLoader.id < id Then Return 1
		'on top of me
		Return -1
	End Method


	'register loader in registry
	Method Register:Int()
		TRegistryLoader.RegisterResourceLoader(Self)
		registered = True
	End Method


	Method ToString:String()
		Return "TRegistry"+name.ToUpper()+"Loader"
	End Method
End Type




'loader caring about "<file>"-types
Type TRegistryFileLoader Extends TRegistryBaseLoader
	Method Init:Int()
		resourceNames = "file"
		name = "File"
		'xml files can get loaded directly
		directLoading = True
		If Not registered Then Register()
	End Method


	Method GetNameFromConfig:String(data:TData)
		Local res:String = data.GetString("baseURI","")
		If res<>"" Then res :+ "/"
		res :+ data.GetString("url")

		Return res
	End Method


	'load url of the xml file (information about file)
	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		Local _url:String = TXmlHelper.FindValue(node, "url", "")
		If _url = "" Then Return Null

		Local data:TData = New TData
		data.addString("url", _url)
		data.addString("baseURI", loader.baseURI)

		Return data
	End Method


	'load the xml file (content of file)
	Method LoadFromConfig:Object(data:TData, resourceName:String)
		Local newLoader:TRegistryLoader = New TRegistryLoader
		'take over baseURI
		newLoader.baseURI = data.GetString("baseURI")
		newLoader.LoadFromXML(data.GetString("url"))

		'indicate that the loading was successful (else return null)
		Return Self
	End Method
End Type


'loader caring about "<data>"-types
'data blocks are merged with existing ones (except "merge" is set to
'false in the xml-node)
Type TRegistryDataLoader Extends TRegistryBaseLoader
	Method Init:Int()
		resourceNames = "data"
		name = "Data"
		If Not registered Then Register()
	End Method


	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		Local name:String = TXmlHelper.FindValue(node, "name", node.GetName())
		'skip unnamed data (no name="x" or <namee type="data">)
		If name = "" Or name.ToUpper() = "DATA"
			TLogger.Log("TRegistryDataLoader.LoadFromXML", "Node ~q<"+node.GetName()+">~q contained no or invalid name field. Skipped.", LOG_WARNING)
			Return Null
		EndIf

		Local data:TData = New TData
		data.AddString("name", name)
		data.AddNumber("merge", TXmlHelper.FindValueBool(node, "merge", True))
		Local values:TData = New TData


		For Local child:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(node)
			Local childName:String = TXmlHelper.FindValue(child, "name", child.getName())
			If childName = "" Then Continue

			Local childValue:String = TXmlHelper.FindValue(child, "value", child.getcontent())
			values.Add(childName, childValue)
		Next

		data.Add("values", values)
		Return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		Return data.GetString("name","unknown data block")
	End Method


	'load the xml file (content of file)
	Method LoadFromConfig:Object(data:TData, resourceName:String)
		Local merge:Int = data.GetInt("merge", False)
		Local name:String = GetNameFromConfig(data)
		Local values:TData = New TData
		'if merging - we load the previously stored data (if there is some)
		If merge Then values = TData(GetRegistry().Get(name, New TData))

		'merge in the new values (to an empty - or the old tdata)
		values.Append(TData(data.Get("values")))

		'add to registry
		GetRegistry().Set(name, values)

		'indicate that the loading was successful
		Return values
	End Method
End Type