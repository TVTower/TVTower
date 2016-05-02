SuperStrict

Framework brl.StandardIO

Import "../source/Dig/base.gfx.bitmapfont.bmx"
Import "../source/Dig/base.util.registry.bmx"
Import "../source/Dig/base.util.registry.imageloader.bmx"
Import "../source/Dig/base.util.registry.bitmapfontloader.bmx"

Import "../source/Dig/base.util.registry.bmx"
Import "../source/Dig/base.gfx.gui.list.slotlist.bmx"


Import "../source/game.database.bmx"
Import "../source/game.player.base.bmx"
Import "../source/game.registry.loaders.bmx" 'genres

Import "../source/game.screen.supermarket.production.bmx"
Import "../source/game.production.productionconcept.bmx"
Import "../source/game.production.productioncompany.bmx"
Import "../source/game.production.productionmanager.bmx"



'=== INIT =============================
'======================================

'set worldTime to 20:00, day 3 of 12 a year, in 1985
GetWorldTime().SetTimeGone( GetWorldTime().MakeTime(1985, 3, 20, 0, 0) )
'set speed 10x realtime
GetWorldTime().SetTimeFactor(120)

'for local i:int = 0 to 10
'	print THelper.LogisticalInfluence_Euler(i / 10.0, 3.0)
'next
'end

Local gm:TGraphicsManager = TGraphicsManager.GetInstance()
GetDeltatimer().Init(30, -1)
GetGraphicsManager().SetResolution(800,600)
GetGraphicsManager().InitGraphics()	


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

registryLoader.LoadFromXML("config/programmedatamods.xml", True)
GetMovieGenreDefinitionCollection().Initialize()

registryLoader.LoadFromXML("config/screen_elements.xml", True)
registryLoader.LoadFromXML("config/gfx.xml")

registryLoader.LoadFromXML("config/gui.xml")


'load db
global dbLoader:TDatabaseLoader = New TDatabaseLoader
dbLoader.LoadDir(registryLoader.baseURI + "res/database/Default")

'load stationmap
GetStationMapCollection().LoadMapFromXML("res/maps/germany/germany.xml", registryLoader.baseURI)

'set game time
GetWorldTime().SetStartYear(1985)
'refresh states of old programme productions (now we now
'the start year and are therefore able to refresh who has
'done which programme yet)
GetProgrammeDataCollection().UpdateAll()


TLocalization.LoadLanguageFiles(registryLoader.baseURI + "res/lang/lang_*.txt")
'set default languages
TLocalization.SetFallbackLanguage("en")
TLocalization.SetCurrentLanguage("de")


'create some companies
local cnames:string[] = ["Movie World", "Picture Fantasy", "UniPics", "Motion Gems", "Screen Jewel"]
For local i:int = 0 until cnames.length
	local c:TProductionCompany = new TProductionCompany
	c.name = cnames[i]
	c.SetExperience( BiasedRandRange(0, 0.35 * TProductionCompanyBase.MAX_XP, 0.25) )
	GetProductionCompanyBaseCollection().Add(c)
Next



'create some random concepts
'add some items to that list
for local i:int = 1 to 4
	local script:TScript = GetRandomScript()

	if script.IsEpisode()
		'parent too
		script.GetParentScript().SetOwner(1)
	else
		script.SetOwner(1)
	endif

	local productionConcept:TProductionConcept = new TProductionConcept.Initialize(1, script)
	GetProductionConceptCollection().Add(productionConcept)

	'add two others of that series
	if script.IsEpisode()
		productionConcept.studioSlot = 1
		for local subI:int = 1 to 2
			local otherScript:TScript = TScript(script.GetParentScript().GetSubScriptAtIndex(subI))
			local otherConcept:TProductionConcept = new TProductionConcept.Initialize(1, otherScript)
			otherConcept.studioSlot = subI + 1
			GetProductionConceptCollection().Add(otherConcept)
			otherScript.SetOwner(1)
		Next
	endif
Next

global bgImage:TImage = LoadImage("../res/gfx/supermarket/screen_supermarket.png")

ScreenCollection.Add( new TScreen.Create("screen_supermarket_production") )
ScreenCollection.GoToScreen(null, "screen_supermarket_production")

TScreenHandler_SupermarketProduction.GetInstance().Initialize()


Function GetRandomScript:TScript()
	'get a new script
	local script:TScript = GetScriptCollection().GetRandomAvailable()

	'use first episode of a series
	if script.isSeries()
		script = TScript(script.GetSubScriptAtIndex(0))
	endif

	return script
End Function



Function Update:Int()
	MouseManager.Update()
	KeyManager.Update()

	EventManager.Update()
	EventManager.triggerEvent( TEventSimple.Create("room.onScreenUpdate", new TData.Add("room", null) , ScreenCollection.GetCurrentScreen() ) )
	
	'fetch and cache mouse and keyboard states for this cycle
	GUIManager.StartUpdates()

	'update worldtime (eg. in games this is the ingametime)
	GetWorldTime().Update()
	
	GetProductionManager().Update()

	'=== UPDATE GUI ===
	'system wide gui elements
	GuiManager.Update("SYSTEM")


	if not GuiManager.GetKeystrokeReceiver()
		if KeyManager.IsHit(KEY_SPACE)
			'get a new script
			local script:TScript = GetRandomScript()
			script.SetOwner(1)
			local productionConcept:TProductionConcept = new TProductionConcept.Initialize(1, script)
			'create new and take over
			TScreenHandler_SupermarketProduction.GetInstance().SetCurrentProductionConcept( productionConcept, TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept)
		endif

		if TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept
			if KeyManager.IsHit(KEY_1)
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetCast(0, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True))
			Endif
			if KeyManager.IsHit(KEY_2)
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetCast(1, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True))
			Endif
			if KeyManager.IsHit(KEY_3)
				TScreenHandler_SupermarketProduction.GetInstance().castSlotList.SetSlotCast(2, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True) )
			Endif
			if KeyManager.IsHit(KEY_4)
				TScreenHandler_SupermarketProduction.GetInstance().castSlotList.SetSlotCast(3, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True) )
			Endif
			if KeyManager.IsHit(KEY_5)
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetCast(4, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True))
			Endif

			if KeyManager.IsHit(KEY_Q)
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetProductionCompany( TProductionCompanyBase(TScreenHandler_SupermarketProduction.GetInstance().productionCompanySelect.GetEntryByPos(0).data.Get("productionCompany")) )
			Endif
			if KeyManager.IsHit(KEY_W)
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetProductionCompany( TProductionCompanyBase(TScreenHandler_SupermarketProduction.GetInstance().productionCompanySelect.GetEntryByPos(1).data.Get("productionCompany")) )
			Endif
			if KeyManager.IsHit(KEY_E)
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetProductionCompany( TProductionCompanyBase(TScreenHandler_SupermarketProduction.GetInstance().productionCompanySelect.GetEntryByPos(2).data.Get("productionCompany")) )
			Endif
			if KeyManager.IsHit(KEY_R)
				'random one
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetProductionCompany( GetProductionCompanyBaseCollection().GetRandom() )
			Endif

			if KeyManager.IsHit(KEY_NUM1)
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetProductionFocus(1, RandRange(0,10))
			Endif
			if KeyManager.IsHit(KEY_NUM2)
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetProductionFocus(2, RandRange(0,10))
			Endif
			if KeyManager.IsHit(KEY_NUM3)
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetProductionFocus(3, RandRange(0,10))
			Endif
			if KeyManager.IsHit(KEY_NUM4)
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetProductionFocus(4, RandRange(0,10))
			Endif
			if KeyManager.IsHit(KEY_NUM5)
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetProductionFocus(5, RandRange(0,10))
			Endif
			if KeyManager.IsHit(KEY_NUM6)
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetProductionFocus(6, RandRange(0,10))
			Endif
			if KeyManager.IsHit(KEY_NUM7)
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetProductionFocus(7, RandRange(0,10))
			Endif
			if KeyManager.IsHit(KEY_NUM8)
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.productionFocus.SetFocusPointsMax( Max(0, TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.productionFocus.focusPointsMax - 1))
			Endif
			if KeyManager.IsHit(KEY_NUM9)
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.productionFocus.SetFocusPointsMax( TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.productionFocus.focusPointsMax + 1)
			Endif

			if KeyManager.IsHit(KEY_P)
				if TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.IsProduceable()
					local count:int = GetProductionManager().StartProductionInStudio("test", TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.script)
					print "added "+count+" productions to shoot"
				else
					print TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.GetTitle()+"  not ready"
				endif
			endif
		endif
	

		'create demo production
		if KeyManager.IsHit(KEY_O)
			if not TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept
				local productionConcept:TProductionConcept
				if KeyManager.IsDown(KEY_LSHIFT)
					print "shoot random episode"
					productionConcept = GetProductionConceptCollection().GetRandomEpisode()
					if not productionConcept
						print "no episode concept available, returning normal one"
						productionConcept = GetProductionConceptCollection().GetRandom()
					endif
				else
					print "shoot random programme"
					productionConcept = GetProductionConceptCollection().GetRandom()
				endif
				'create new and take over
				TScreenHandler_SupermarketProduction.GetInstance().SetCurrentProductionConcept( productionConcept, TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept)
			endif
			
			'random company
			TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetProductionCompany( GetProductionCompanyBaseCollection().GetRandom() )

			For local i:int = 0 until TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.cast.length
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetCast(i, GetProgrammePersonBaseCollection().GetRandomCelebrity(null, True))
			Next
			For local i:int = 0 until TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.productionFocus.focusPoints.length
				TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.SetProductionFocus(i, RandRange(0,10))
			Next

			'pay for it
			TScreenHandler_SupermarketProduction.GetInstance().PayCurrentProductionConceptDeposit()
			
			if TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.IsProduceable()
				local count:int = GetProductionManager().StartProductionInStudio("test", TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.script)

				local production:TProduction = GetProductionManager().GetProductionInStudio("test")
				if production
					'1 minute production time
					production.endDate = production.startDate + 60*1
				endif

				print "added "+count+" productions to shoot"
			else
				print TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.GetTitle()+"  not ready"
			endif
		endif
		if KeyManager.IsHit(KEY_UP)
			GetWorldTime().SetTimeFactor( 2 * GetWorldTime().GetTimeFactor())
			print "factor: "+GetWorldTime().GetTimeFactor()
		endif
		if KeyManager.IsHit(KEY_DOWN)
			GetWorldTime().SetTimeFactor( Max(10, 0.5 * GetWorldTime().GetTimeFactor()))
			print "factor: "+GetWorldTime().GetTimeFactor()
		endif
	endif

	'check if new resources have to get loaded
	TRegistryUnloadedResourceCollection.GetInstance().Update()

	'reset modal window states
	GUIManager.EndUpdates()
End Function


Function Render:int()
	DrawImage(bgImage, 0,0)

	SetColor 50,50,50
	DrawRect(0,375,800,225)
	SetColor 255,255,255

	'=== RENDER SCREEN ===
	EventManager.triggerEvent( TEventSimple.Create("room.onScreenDraw", new TData.Add("room", null) , ScreenCollection.GetCurrentScreen() ) )



	'=== RENDER GUI ===
	'system wide gui elements
	GuiManager.Draw("SYSTEM")


	'=== DEBUG ===
	local debugX:int = 20
	local debugY:int = 400
	if TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept
		SetColor 0,0,0
		SetAlpha 0.5
		DrawRect(debugX, debugY, 180, 20 + TScreenHandler_SupermarketProduction.GetInstance().castSlotList.GetSlotAmount() * 15 + 5)
		SetColor 255,255,255
		SetAlpha 1.0
		DrawText("Cast:", debugX + 5, debugY)
		For local i:int = 0 until TScreenHandler_SupermarketProduction.GetInstance().castSlotList.GetSlotAmount()
			if TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.GetCast(i)
				DrawText((i+1)+") " + TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.GetCast(i).GetFullName(), debugX + 5, debugY + 20 + i * 15)
			else
				DrawText((i+1)+") ", debugX + 5, debugY + 20 + i * 15)
			endif
		Next

		debugX = 220

		SetColor 0,0,0
		SetAlpha 0.5
		DrawRect(debugX, debugY, 190, 20 + TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.productionFocus.GetFocusAspectCount() * 15 + 5)
		SetColor 255,255,255
		SetAlpha 1.0
		DrawText("FocusPoints: " + TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.productionFocus.GetFocusPointsSet()+"/" + TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.productionFocus.GetFocusPointsMax(), debugX + 5, debugY)
		For local i:int = 0 until TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.productionFocus.GetFocusAspectCount()
			DrawText((i+1)+") " + TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.productionFocus.GetFocus( TVTProductionFocus.GetAtIndex(i+1) ), debugX + 5, debugY + 20 + i * 15)
		
			DrawText(GetLocale(TVTProductionFocus.GetAsString(i+1)), debugX + 45, debugY + 20 + i * 15)
		Next
	endif


	DrawText("Tasten:", 50,525)
	DrawText("1-5: Zufallsbesetzung #1-5   Num1-7: Focus #1-7   Num8/9: FocusPoints +/-", 50,540)
	DrawText("Q/W/E: Produktionsfirma #1-3   R: Zufallsproduktionsfirma", 50,555)
	DrawText("Leertaste: Neue Zufallsproduktion", 50,570)



	'=== RENDER HUD ===
	DrawText("worldTime: "+GetWorldTime().GetFormattedTime(-1, "h:i:s")+ " at day "+GetWorldTime().GetDayOfYear()+" in "+GetWorldTime().GetYear(), 90, 0)

	'default pointer
	'If Game.cursorstate = 0 Then
	GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-9, 	MouseManager.y-2	,0)

End Function



While not KeyHit(KEY_ESCAPE) or AppTerminate()
	Update()
	Cls
	Render()
	Flip
	delay(2)
Wend




Type RoomHandler_Supermarket 'extends TRoomHandler
	Global _instance:RoomHandler_Supermarket
	Global _eventListeners:TLink[]


	Function GetInstance:RoomHandler_Supermarket()
		if not _instance then _instance = new RoomHandler_Supermarket
		return _instance
	End Function

	
	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'reset/initialize screens (event connection etc.)
		TScreenHandler_SupermarketProduction.GetInstance().Initialize()


		'=== REGISTER HANDLER ===
		RegisterHandler()

		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== register event listeners


		'(re-)localize content
'		SetLanguage()
	End Method

	
	Method CleanUp()
		'=== unset cross referenced objects ===
		'
		
		'=== remove obsolete gui elements ===
		'
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
	End Method

End Type




