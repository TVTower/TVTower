SuperStrict
Framework Brl.StandardIO
Import Brl.GLMax2D

Import "source/Dig/base.util.time.bmx"
Import "source/common.misc.gamegui.bmx"

'=== LOAD RESOURCES ===
Local registryLoader:TRegistryLoader = New TRegistryLoader
'if loading from a "parent directory" - state this here
'-> all resources can get loaded with "relative paths"
registryLoader.baseURI = "../"
if FileType("TVTower") or FileType("TVTower.app") or FileType("TVTower.exe")
	registryLoader.baseURI = ""
endif

'afterwards we can display background images and cursors
'"TRUE" indicates that the content has to get loaded immediately
registryLoader.LoadFromXML("config/startup.xml", True)
registryLoader.LoadFromXML("config/gui.xml", True)
print "--------"





Global exitApp:int = False
Global ExitAppDialogue:TGUIModalWindow = Null
Global ExitAppDialogueTime:Long = 0
EventManager.registerListenerFunction( "guiModalWindow.onClose", onAppConfirmExit )


Graphics 800, 600, 0
SetBlend AlphaBlend

Repeat
	'=== UPDATE ===
	SetAutoPoll(False)
	KEYMANAGER.Update()
	MOUSEMANAGER.Update()
	SetAutoPoll(True)

	GUIManager.StartUpdates()

	'enable reading of clicked states (just for the case of being
	'diabled because of an exitDialogue exists)
	MouseManager.Enable(1)
	MouseManager.Enable(2)

	GUIManager.Update("SYSTEM")

	if AppTerminate() or KeyHit(KEY_ESCAPE)
		CreateConfirmExitAppDialogue()
	endif

	GUIManager.EndUpdates()


	'=== DRAW ===
	Cls
	GUIManager.Draw("SYSTEM")

	DrawText("ESCAPE oder [x] sollten Beenden?-Dialog anzeigen", 10, 10)
	DrawText("STRG + C beendet ohne Nachfrage", 10, 40)
	Flip 0
Until exitApp or ((KeyDown(KEY_LCONTROL) or KeyDown(KEY_RCONTROL)) and KeyHit(KEY_C))



Function CreateConfirmExitAppDialogue:Int(quitToMainMenu:int=True)
	'100ms since last dialogue
	If Time.MilliSecsLong() - ExitAppDialogueTime < 100
		TLogger.Log("RONNY DEBUGANGABE", "[DEV] "+Time.MilliSecsLong()+" - "+ExitAppDialogueTime+" IGNORIERE [x] gedrueckt, da erneut innerhalb 100ms.", LOG_DEBUG)
		Return False
	endif

	TLogger.Log("RONNY DEBUGANGABE", "[DEV]  [x] gedrueckt, erzeuge Beenden-Abfrage.", LOG_DEBUG)

	ExitAppDialogueTime = Time.MilliSecsLong()

	ExitAppDialogue = New TGUIGameModalWindow.Create(New TVec2D, New TVec2D.Init(400,150), "SYSTEM")
	ExitAppDialogue.SetDialogueType(2)
	ExitAppDialogue.SetZIndex(100000)
	ExitAppDialogue.data.AddNumber("quitToMainMenu", quitToMainMenu)
	'	ExitAppDialogue.Open()

	ExitAppDialogue.darkenedArea = New TRectangle.Init(0,0,800,385)
	'center to this area
	ExitAppDialogue.screenArea = New TRectangle.Init(0,0,800,385)

	ExitAppDialogue.SetCaptionAndValue( "Beenden?", "Wirklich beenden?" )
End Function


Function onAppConfirmExit:Int(triggerEvent:TEventBase)
	Local dialogue:TGUIModalWindow = TGUIModalWindow(triggerEvent.GetSender())
	If Not dialogue Then Return False

	'store closing time of this modal window (does not matter which
	'one) to skip creating another exit dialogue within a certain
	'timeframe
	ExitAppDialogueTime = Time.MilliSecsLong()

	'not interested in other dialogues
	If dialogue <> ExitAppDialogue Then Return False

	Local buttonNumber:Int = triggerEvent.GetData().getInt("closeButton",-1)

	'approve exit
	If buttonNumber = 0
		end
	else
		Return False
	endif
End Function
