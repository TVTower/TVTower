Rem
	====================================================================
	SoundLoader extension for Registry utility
	====================================================================

	Allows loading of "music/sfx" in config files.

	Contrary to other loaders this class does not insert entries
	to the Registry but to the SoundManager.

	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-now Ronny Otto, digidea.de

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
Import Brl.OGGLoader
Import "base.util.registry.bmx"
Import "base.sfx.soundmanager.base.bmx"
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
		local fieldNames:String[] = ["name", "url", "loop", "playonload", "playlists"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)

		'process given relative-url
		data.AddString("url", loader.GetURI(data.GetString("url", "")))

		return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		return data.GetString("name","unknown sound")
	End Method


	Method LoadFromConfig:object(data:TData, resourceName:string)
		Local name:String = GetNameFromConfig(data).ToLower()
		Local url:String = data.GetString("url", "")
		Local loop:Int = data.GetBool("loop", False)
		Local playlists:String = data.GetString("playlists", "")
		Local playonload:int = data.GetBool("playonload", False)

		'instead of using a default-value in "GetString()" we also want
		'to have "default" set if one defined 'playlists=""' in the xml
		'file (and therefor in the TData)
		If playlists="" Then playlists = "default"


		Select resourceName
			case "music"
				Local stream:TDigAudioStream = GetSoundManagerBase().CreateDigAudioStreamOgg(url, loop)
				If Not stream
					TLogger.Log("TRegistrySoundLoader.LoadFromConfig()", "File ~q"+url+"~q is missing or corrupt.", LOG_ERROR)
				Else
					GetSoundManagerBase().AddSound(name, stream, playlists)

					if playonload then GetSoundManagerBase().PlayMusic(name)
				EndIf
				'indicate that the loading was successful (or not)
				return stream

			case "sfx"
				Local flags:Int = SOUND_HARDWARE
				If loop Then flags :| SOUND_LOOP

				Local sound:TSound = LoadSound(url, flags)
				If Not sound
					TLogger.Log("TRegistrySoundLoader.LoadFromConfig()", "File ~q"+url+"~q is missing or corrupt.", LOG_ERROR)
				Else
					GetSoundManagerBase().AddSound(name, sound, playlists)
				EndIf
				'indicate that the loading was successful (or not)
				return sound
		End Select
		return null
	End Method
End Type