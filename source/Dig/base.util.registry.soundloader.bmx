REM
	===========================================================
	class to load sfx/music from xml configs, ...
	===========================================================

	Contrary to other loaders this class does not insert entries
	to the Registry but to the SoundManager.

ENDREM
SuperStrict
Import BRL.PNGLoader
Import "base.util.registry.bmx"
Import "base.sfx.soundmanager.bmx"
'register this loader
new TRegistrySoundLoader.Init()


'===== LOADER IMPLEMENTATION =====
'loader caring about "<sfx>"- and "<music>"-types
Type TRegistrySoundLoader extends TRegistryBaseLoader
	Method Init:Int()
		name = "Sound"
		'we also load each image as sprite
		resourceNames = "sfx|music"
		if not registered then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		'
	End Method



	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		local data:TData = new TData

		'music and sfx share the same properties so no need to
		'distinguish them before real loading

		'load config properties
		local fieldNames:String[] = ["name", "url", "loop", "playlists"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)

		'process given relative-url
		data.AddString("url", loader.GetURI(data.GetString("url", "")))

		return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		return data.GetString("name","unknown sound")
	End Method


	Method LoadFromConfig:int(data:TData, resourceName:string)
		Local name:String = GetNameFromConfig(data).ToLower()
		Local url:String = data.GetString("url", "")
		Local loop:Int = data.GetBool("loop", False)
		Local playlists:String = data.GetString("playlists", "")

		'instead of using a default-value in "GetString()" we also want
		'to have "default" set if one defined 'playlists=""' in the xml
		'file (and therefor in the TData)
		If playlists="" Then playlists = "default"


		Select resourceName
			case "music"
				Local stream:TMusicStream = TMusicStream.Create(url, loop)
				If Not stream Or Not stream.isValid()
					TLogger.Log("TRegistrySoundLoader.LoadFromConfig()", "File ~q"+url+"~q is missing or corrupt.", LOG_ERROR)
				Else
					GetSoundManager().AddSound(name, stream, playlists)
				EndIf

			case "sfx"
				Local flags:Int = SOUND_HARDWARE
				If loop Then flags :| SOUND_LOOP

				Local sound:TSound = LoadSound(url, flags)
				If Not sound
					TLogger.Log("TRegistrySoundLoader.LoadFromConfig()", "File ~q"+url+"~q is missing or corrupt.", LOG_ERROR)
				Else
					GetSoundManager().AddSound(name, sound, playlists)
				EndIf
		End Select

		'indicate that the loading was successful
		return True
	End Method
End Type