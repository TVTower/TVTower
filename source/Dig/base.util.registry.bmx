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
		if not _instance then _instance = new TRegistry
		return _instance
	End Function


	Method Init:TRegistry()
		data.Clear()
	End Method


	'set a data with the given key
	Method Set(key:string, obj:object)
		?Threaded
			LockMutex(_dataMutex)
		?
		data.insert(key.ToUpper(), obj)
		?Threaded
			UnlockMutex(_dataMutex)
		?
	End Method


	'set a default object for a data type
	Method GetDefault:object(key:string)
		return defaults.ValueForKey(key.ToUpper())
	End Method


	'set a default object for a data type
	Method SetDefault(key:string, obj:object)
		?Threaded
			LockMutex(_dataMutex)
		?
		defaults.insert(key.ToUpper(), obj)
		?Threaded
			UnlockMutex(_dataMutex)
		?
	End Method


	Method Get:object(key:string, defaultObject:object=null, defaultType:string="")
		local res:object = data.ValueForKey(key.toUpper())
		'try to get the default object
		if not res
			if string(defaultObject)<>""
				res = data.ValueForKey(string(defaultObject).toUpper())
			else
				res = defaultObject
			endif
		endif

		'still no res (none by key, no defaultObject)
		'try to find defaultType
		if not res and defaultType <> ""
			'does a default object exist in defaults list?
			res = defaults.ValueForKey(defaultType.toUpper())
			if res then return res
		endif

		return res
	End Method


	Method ToString:String()
		local elementCount:int = 0
		For Local k:String = EachIn data.Keys()
			elementCount :+ 1
		Next

		Return "TRegistry: " + elementCount + " data elements."
	End Method
End Type

'===== CONVENIENCE REGISTRY ACCESSORS =====
Function GetRegistry:TRegistry()
	return TRegistry.GetInstance()
End Function

Function GetDataFromRegistry:TData(name:string, defaultNameOrObject:object = Null)
	Return TData( GetRegistry().Get(name, defaultNameOrObject, "data") )
End Function

Function GetStringFromRegistry:String(name:string, defaultNameOrObject:object = Null)
	Return String( GetRegistry().Get(name, defaultNameOrObject, "string") )
End Function




'==== LOADER TO FILL REGISTRY FROM FILES ====

Type TRegistryLoader
	'base url prepended to all given paths in a config-file
	Field baseURI:string = ""
	Field xmlHelper:TXmlHelper

	'holding descendants of TRegistryResourceLoader which handle
	'certain types.
	'map-key is TYPENAME in uppercase
	Global resourceLoaders:TMap = CreateMap()
	Global _defaultsCreated:int = FALSE


	Method New()
		if not _defaultsCreated
			'give loaders a chance to create default resources
			TRegistryLoader.CreateRegistryDefaults()
			_defaultsCreated = TRUE
		endif
	End Method



	Function RegisterResourceLoader:Int(resourceLoader:TRegistryBaseLoader, resourceNames:string="")
		if resourceNames = "" then resourceNames = resourceLoader.resourceNames

		For local resourceName:string = eachin resourceNames.Split("|")
			resourceLoaders.insert(resourceName.ToUpper(), resourceLoader)
		Next
	End Function


	Function CreateRegistryDefaults:Int()
		'give loaders a chance to create a default resources
		'but: call in order of creation, not sorted by name
		'so dependencies are solved
		local resList:TList = CreateList()
		For local loader:TRegistryBaseLoader = eachin resourceLoaders.Values()
			resList.AddLast(loader)
		Next
		SortList(resList)

		For local loader:TRegistryBaseLoader = eachin resList
			loader.CreateDefaultResource()
		Next
	End Function


	Function GetResourceLoader:TRegistryBaseLoader(resourceName:string)
		Return TRegistryBaseLoader(resourceLoaders.ValueForKey(resourceName.ToUpper()))
	End Function


	Method SetBaseURI:TRegistryLoader(baseURI:string)
		self.baseURI = baseURI
		return self
	End Method


	'appends a given uri to the current base uri
	Method GetUri:String(uri:string="")
		?android
			'try to prepend "sdl::" if the file seems to be within the
			'APK
			if filesize(uri) <= 0 and uri.Find("sdl::") <> 0
				uri = "sdl::"+uri
			endif
		?		
	
		return baseURI + uri
	End Method


	Method LoadFromXML:int(file:string, forceDirectLoad:int=FALSE)
		file = GetUri(file)

		xmlHelper = TXmlHelper.Create(file, "", False)
		if not xmlHelper.xmlDoc
			TLogger.Log("TRegistryLoader.LoadFromXML", "file '" + file + "' not found or invalid.", LOG_LOADING)
			return FALSE
		endif


		LoadResourcesFromXML(xmlHelper.GetRootNode(), forceDirectLoad)

		'load everything until everything from that file was loaded
		if forceDirectLoad
			local instance:TRegistryUnloadedResourceCollection = TRegistryUnloadedResourceCollection.GetInstance()
			repeat
				instance.Update()
			until instance.FinishedLoading()
		endif


		EventManager.triggerEvent( TEventSimple.Create("RegistryLoader.onLoadXmlFromFinished", new TData.AddString("uri", file) ) )
		Return TRUE
	End Method


	Method LoadResourcesFromXML:int(node:TXmlNode, forceDirectLoad:int=FALSE)
		For local resourceNode:TxmlNode = eachin TXmlHelper.GetNodeChildElements(node)
			LoadSingleResourceFromXML(resourceNode, forceDirectLoad)
		Next
	End Method


	Method LoadSingleResourceFromXML:int(node:TXmlNode, forceDirectLoad:int=FALSE, extras:TData = null)
		'get the name defined in:
		'- type (<bla type="identifier" />) or
		'- tagname ( <identifier x="1" />)
		local resourceName:string = TXmlHelper.FindValue(node, "type", node.getName())

		'we handle "resource" on our own
		if resourceName.ToUpper() = "RESOURCES"
			local directLoad:int = TXmlHelper.findValueBool(node, "directload", forceDirectLoad)
			LoadResourcesFromXML(node, directLoad)
		else
			local loader:TRegistryBaseLoader = GetResourceLoader(resourceName)
			if loader
				'load config from XML
				local conf:TData = loader.GetConfigFromXML(self, node)

				'do nothing without a configuration (maybe it is a virtual group handled
				'directly by the loader -> eg. "fonts" which only groups "font")
				if conf
					'merge in the extras (eg. overwrite "names")
					if extras then conf.Append(extras)

					local lazyLoad:int = not (loader.directLoading or forceDirectLoad)

					'directly load the objects or defer to a helper
					if not lazyLoad
						'if direct loading failed ... load it later 
						if not loader.LoadFromConfig(conf, resourceName)
							lazyLoad = true
						endif
					endif

					if lazyLoad
						'try to get a name for the resource:
						'a) from TData "extras"
						'b) from the config read from xml
						local name:String = conf.GetString("name")
						if name = "" then name = loader.GetNameFromConfig(conf)

						AddLazyLoadedResource(name, resourceName, conf)
					endif
				endif
			endif
		Endif

		'inform others about the to-load-element
		'sender: self (the loader)
		'target: resourceName in uppercases ("SPRITE") -> so listeners can filter on it
		'print "RegistryLoader.onLoadResourceFromXML: self + "+ resourceName.ToUpper()
		EventManager.triggerEvent( TEventSimple.Create("RegistryLoader.onLoadResourceFromXML", new TData.AddString("resourceName", resourceName).Add("xmlNode", node), self, resourceName.ToUpper()))
	End Method


	Function AddLazyLoadedResource(name:string, resourceName:string, data:TData)
		'add to "ToLoad"-list
		TRegistryUnloadedResourceCollection.GetInstance().Add(..
			new TRegistryUnloadedResource.Init(name, resourceName, data)..
		)
	End Function
End Type




'collection handling multiple resourcecontainers (unloaded resources)
Type TRegistryUnloadedResourceCollection
	'simple counters for a 1of10-display
	Field toLoadCount:int = 0
	Field loadedCount:int = 0
	'list files containing names of loaded resources
	Field loadedLog:TList = CreateList()
	Field failedLog:TList = CreateList()
	'list files containing objects to get loaded
	Field unloadedResources:TList = CreateList()
	Field failedResources:TList = CreateList()
	'indicator if something failed when the last list got processed
	Field failedResourceLoaded:int = FALSE
	'indicator (cache) whether there is still something to load
	Field _finishedLoading:int = TRUE
	?Threaded
	Field _listMutex:TMutex = CreateMutex()
	Field _loaderThread:TThread
	?
	Global _instance:TRegistryUnloadedResourceCollection


	Function GetInstance:TRegistryUnloadedResourceCollection()
		if not _instance then _instance = new TRegistryUnloadedResourceCollection
		return _instance
	End Function


	Method Add(resource:TRegistryUnloadedResource)
		?Threaded
			'wait for the listMutex to be unlocked (nobody modifying the list)
			LockMutex(_listMutex)
		?
		unloadedResources.AddLast(resource)
		toLoadCount :+ 1
		?Threaded
			UnlockMutex(_listMutex)
		?
		_finishedLoading = FALSE
	End Method


	Method AddFailed(resource:TRegistryUnloadedResource)
		?Threaded
			'wait for the listMutex to be unlocked (nobody modifying the list)
			LockMutex(_listMutex)
		?
		failedResources.AddLast(resource)
		failedLog.AddLast(resource.name)
		?Threaded
			UnlockMutex(_listMutex)
		?
	End Method


	Method GetUnloadedCount:Int()
		return unloadedResources.Count()
	End Method


	Method GetFailedCount:Int()
		return failedResources.Count()
	End Method


	'removes and returns the first element of the unloaded list
	Method PopFirstUnloadedResource:TRegistryUnloadedResource()
		?Threaded
			'wait for the listMutex to be unlocked (nobody modifying the list)
			LockMutex(_listMutex)
		?
		local res:TRegistryUnloadedResource = TRegistryUnloadedResource(unloadedResources.RemoveFirst())
		?Threaded
			UnlockMutex(_listMutex)
		?
		return res
	End Method


	Method AddToLoadedLog:int(value:string)
		?Threaded
			'wait for the listMutex to be unlocked (nobody modifying the list)
			LockMutex(_listMutex)
		?
		loadedLog.AddLast(value)
		loadedCount :+ 1
		?Threaded
			UnlockMutex(_listMutex)
		?
	End Method


	Method FinishedLoading:int()
		'if already calculated, just return true (gets "FALSE" on add of
		'a new resource)
		if _finishedLoading then return TRUE
		'finished as soon as nothing to load and last cycle no
		'previously failed resource was loaded
		_finishedLoading = (GetUnloadedCount() = 0 and not failedResourceLoaded)
		return _FinishedLoading
	End Method


	Method Update:int()
		if FinishedLoading() then return TRUE

		'threaded binary: kick off a loader thread
		'unthreaded: load the next one
		?Threaded
			if not _loaderThread OR not ThreadRunning(_loaderThread)
				_loaderThread = CreateThread(RunLoaderThread, Null)

				'helper function
				Function RunLoaderThread:Object(Input:Object)
					'this thread runs as long as there is something to load
					'-> it gets auto-recreated if no longer running but there is
					'something to load
					Repeat
						'try to load the next item
						TRegistryUnloadedResourceCollection.GetInstance().LoadNext()
'						delay(1)
					Until TRegistryUnloadedResourceCollection.GetInstance().FinishedLoading()
				End Function
			endif
		?not Threaded
			LoadNext()
		?
	End Method


	Method LoadNext:Int()
		'refresh unloaded list with former failed resources
		'maybe they are now loadable (dependencies)
		if GetUnloadedCount() = 0
			'nothing to load
			If GetFailedCount() = 0 then return TRUE

			'try failed again ?!
			unloadedResources = failedResources
			failedResources = CreateList()
			failedResourceLoaded = FALSE
		Endif

		local toLoad:TRegistryUnloadedResource = PopFirstUnloadedResource()
		if not toLoad then return TRUE
		'try to load the resource
		if toLoad.Load()
			AddToLoadedLog(toLoad.name)
			'mark the fact that a previously failed resource was now
			'correctly loaded - indicator to loop through the failed again
			if toLoad.loadAttempts > 0 then failedResourceLoaded = TRUE
			return TRUE
		endif
		'loading failed
		toLoad.loadAttempts :+1
'RONNY
'print "  loading failed : "+ toLoad.name + " | "+ toLoad.loadAttempts
		'add to the list of failed resources
		AddFailed(toLoad)
		return FALSE
	End Method
End Type




'object containing information about an not yet loaded element
Type TRegistryUnloadedResource
	Field config:TData
	Field resourceName:string	'eg. "IMAGE"
	Field name:string			'eg. "my background" or "gfx/office/background.png"
	Field id:int = 0
	Field loadAttempts:int = 0 	'times engine tried to load this resource

	Global LastID:int = 0


	Method New()
		LastID :+ 1
		id = LastID
	End Method


	Method Init:TRegistryUnloadedResource(name:String, resourceName:String, config:TData)
		self.name = name
		self.resourceName = resourceName.ToLower()
		self.config = config
		return self
	End Method


	Method Load:Int()
		EventManager.triggerEvent(TEventSimple.Create("RegistryLoader.onBeginLoadResource", new TData.AddString("name", name).AddString("resourceName", resourceName)))

		'try to find a loader for the objects resource type
		local loader:TRegistryBaseLoader = TRegistryLoader.GetResourceLoader(resourceName)
		if not loader then return false

		'try to load an object with the given config and resourceType-name
		if loader.LoadFromConfig(config, resourceName)
			'inform others: we loaded something
			EventManager.triggerEvent(TEventSimple.Create("RegistryLoader.onLoadResource", new TData.AddString("name", name).AddString("resourceName", resourceName)))
			return True
		else
			return False
		endif
	End Method


	'sort by ID
	Method Compare:int(Other:Object)
		local otherResource:TRegistryUnloadedResource = TRegistryUnloadedResource(Other)
		if otherResource
			if otherResource.id > id then return -1
			if otherResource.id < id then return 1
		endif
		return Super.Compare(Other)
	End Method
End Type




'==== RESOURCE LOADER HANDLING SPECIFIC TYPES ====

'register basic loaders
new TRegistryFileLoader.Init()
new TRegistryDataLoader.Init()


'base loader
Type TRegistryBaseLoader
	Field name:String = "Base"
	Field resourceNames:string = "nothing"
	Field registered:int = FALSE
	Field directLoading:int = FALSE
	Field id:int = 0
	Global LastID:int = 0


	Method New()
		LastID :+ 1
		id = LastID
	End Method

	'call to initialize a loader, set names etc
	Method Init:Int() abstract

	'called with the corresponding xmlNode containing the
	'element which the loader registered for
	'loads all recognized values of the node into a tdata-object
	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode) abstract


	'return a printable identifier of this resource (url, spritename, ...)
	Method GetNameFromConfig:String(data:TData) abstract


	'loading the objects contained in the data
	Method LoadFromConfig:object(data:TData, resourceName:string) abstract


	Method CreateDefaultResource:Int()
		'
	End Method


	'sort loaders according creation date
	Method Compare:Int(other:Object)
		Local otherLoader:TRegistryBaseLoader = TRegistryBaseLoader(other)
		'no weighting
		If Not otherLoader then Return 0
		If otherLoader = Self then Return 0
		'below me
		If otherLoader.id < id Then Return 1
		'on top of me
		Return -1
	End Method


	'register loader in registry
	Method Register:Int()
		TRegistryLoader.RegisterResourceLoader(self)
		registered = True
	End Method


	Method ToString:String()
		return "TRegistry"+name.ToUpper()+"Loader"
	End Method
End Type




'loader caring about "<file>"-types
Type TRegistryFileLoader extends TRegistryBaseLoader
	Method Init:Int()
		resourceNames = "file"
		name = "File"
		'xml files can get loaded directly
		directLoading = TRUE
		if not registered then Register()
	End Method


	Method GetNameFromConfig:String(data:TData)
		local res:String = data.GetString("baseURI","")
		if res<>"" then res :+ "/"
		res :+ data.GetString("url")

		return res
	End Method


	'load url of the xml file (information about file)
	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		Local _url:String = TXmlHelper.FindValue(node, "url", "")
		if _url = "" then return NULL

		local data:TData = new TData
		data.addString("url", _url)
		data.addString("baseURI", loader.baseURI)

		return data
	End Method


	'load the xml file (content of file)
	Method LoadFromConfig:object(data:TData, resourceName:string)
		local newLoader:TRegistryLoader = new TRegistryLoader
		'take over baseURI
		newLoader.baseURI = data.GetString("baseURI")
		newLoader.LoadFromXML(data.GetString("url"))

		'indicate that the loading was successful (else return null)
		return self
	End Method
End Type


'loader caring about "<data>"-types
'data blocks are merged with existing ones (except "merge" is set to
'false in the xml-node)
Type TRegistryDataLoader extends TRegistryBaseLoader
	Method Init:Int()
		resourceNames = "data"
		name = "Data"
		if not registered then Register()
	End Method


	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		local name:String = TXmlHelper.FindValue(node, "name", node.GetName())
		'skip unnamed data (no name="x" or <namee type="data">)
		if name = "" or name.ToUpper() = "DATA"
			TLogger.Log("TRegistryDataLoader.LoadFromXML", "Node ~q<"+node.GetName()+">~q contained no or invalid name field. Skipped.", LOG_WARNING)
			return NULL
		endif

		local data:TData = new TData
		data.AddString("name", name)
		data.AddNumber("merge", TXmlHelper.FindValueBool(node, "merge", TRUE))
		local values:TData = new TData


		For local child:TxmlNode = eachin TXmlHelper.GetNodeChildElements(node)
			local childName:String = TXmlHelper.FindValue(child, "name", child.getName())
			if childName = "" then continue

			local childValue:String = TXmlHelper.FindValue(child, "value", child.getcontent())
			values.Add(childName, childValue)
		Next

		data.Add("values", values)
		return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		return data.GetString("name","unknown data block")
	End Method


	'load the xml file (content of file)
	Method LoadFromConfig:object(data:TData, resourceName:string)
		local merge:int = data.GetInt("merge", FALSE)
		local name:string = GetNameFromConfig(data)
		local values:TData = new TData
		'if merging - we load the previously stored data (if there is some)
		if merge then values = TData(GetRegistry().Get(name, new TData))

		'merge in the new values (to an empty - or the old tdata)
		values.Append(TData(data.Get("values")))

		'add to registry
		GetRegistry().Set(name, values)

		'indicate that the loading was successful
		return values
	End Method
End Type