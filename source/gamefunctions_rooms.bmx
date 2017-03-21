Function RegisterRoomHandlers()
	'=== (re-)initialize all known room handlers
	RoomHandler_Office.GetInstance().RegisterHandler()
	RoomHandler_News.GetInstance().RegisterHandler()
	RoomHandler_Boss.GetInstance().RegisterHandler()
	RoomHandler_Archive.GetInstance().RegisterHandler()
	RoomHandler_Studio.GetInstance().RegisterHandler()

	RoomHandler_AdAgency.GetInstance().RegisterHandler()
	RoomHandler_ScriptAgency.GetInstance().RegisterHandler()
	RoomHandler_MovieAgency.GetInstance().RegisterHandler()
	RoomHandler_RoomAgency.GetInstance().RegisterHandler()

	RoomHandler_Betty.GetInstance().RegisterHandler()

	RoomHandler_ElevatorPlan.GetInstance().RegisterHandler()
	RoomHandler_Roomboard.GetInstance().RegisterHandler()

	RoomHandler_Supermarket.GetInstance().RegisterHandler()

	RoomHandler_Credits.GetInstance().RegisterHandler()
End Function




'Chief: credit and emmys - your boss :D
Type RoomHandler_Boss extends TRoomHandler
	'smoke effect
	Global smokeEmitter:TSpriteParticleEmitter

	Global _instance:RoomHandler_Boss
	Global _initDone:int = False


	Function GetInstance:RoomHandler_Boss()
		if not _instance then _instance = new RoomHandler_Boss
		return _instance
	End Function


	Method Initialize:int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===
		if not smokeEmitter
			local smokeConfig:TData = new TData
			smokeConfig.Add("sprite", GetSpriteFromRegistry("gfx_misc_smoketexture"))
			smokeConfig.AddNumber("velocityMin", 25)
			smokeConfig.AddNumber("velocityMax", 40)
			smokeConfig.AddNumber("lifeMin", 0.3)
			smokeConfig.AddNumber("lifeMax", 2.5)
			smokeConfig.AddNumber("scaleMin", 0.2)
			smokeConfig.AddNumber("scaleMax", 0.3)
			smokeConfig.AddNumber("scaleRate", 1.2)
			smokeConfig.AddNumber("alphaMin", 0.5)
			smokeConfig.AddNumber("alphaMax", 0.8)
			smokeConfig.AddNumber("alphaRate", -0.90)
			smokeConfig.AddNumber("angleMin", 165)
			smokeConfig.AddNumber("angleMax", 195)
			smokeConfig.AddNumber("xRange", 2)
			smokeConfig.AddNumber("yRange", 2)

			local emitterConfig:TData = new TData
			emitterConfig.Add("area", new TRectangle.Init(44, 335, 0, 0))
			emitterConfig.AddNumber("particleLimit", 70)
			emitterConfig.AddNumber("spawnEveryMin", 0.45)
			emitterConfig.AddNumber("spawnEveryMax", 0.70)

			smokeEmitter = new TSpriteParticleEmitter.Init(emitterConfig, smokeConfig)
		endif
	End Method


	Method CleanUp()
		'
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("boss", GetInstance())
	End Method
	

	Method onDrawRoom:int( triggerEvent:TEventBase )
		smokeEmitter.Draw()

		local room:TRoom = TRoom(triggerEvent.GetSender())
		'only handle custom elements for players room
		'if room.owner <> GetPlayerCollection().playerID then return FALSE


		local boss:TPlayerBoss = GetPlayerBoss(room.owner)
		if not boss then return False

		local figure:TFigureBase = GetObservedFigure()
		if not figure then return False


		if boss.GetDialogue(figure.playerID)
			boss.GetDialogue(figure.playerID).Draw()
		endif


		If TVTDebugInfos
			local screenX:int = 10
			local screenY:int = 20
			Local oldAlpha:Float = GetAlpha()

			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0
			DrawRect(screenX, screenY, 160, 50)
		
			SetColor 255,255,255
			SetAlpha oldAlpha

			Local textY:Int = screenY + 2
			Local fontBold:TBitmapFont = GetBitmapFontManager().basefontBold
			Local fontNormal:TBitmapFont = GetBitmapFont("",11)
			
			fontBold.draw("Boss #" +room.owner, screenX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Mood: " + MathHelper.NumberToString(boss.GetMood(), 2), screenX + 5, textY)
			SetColor 150,150,150
			DrawRect(screenX + 70, textY, 70, 10 )
			SetColor 0,0,0
			DrawRect(screenX + 70+1, textY+1, 70-2, 10-2)
			SetColor 190,150,150
			local handleX:int = MathHelper.Clamp(boss.GetMoodPercentage()*68 -2, 0, 68-4)
			DrawRect(screenX + 70+1 + handleX , textY+1, 4, 10-2 )
			SetColor 255,255,255
			textY :+ 11
		EndIf
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		smokeEmitter.Update()

		local room:TRoom = TRoom(triggerEvent._sender)
		'only handle custom elements for players room
		'if room.owner <> GetPlayerCollection().playerID then return FALSE

		
		local boss:TPlayerBoss = GetPlayerBoss(room.owner)
		if not boss then return False

		local figure:TFigureBase = GetObservedFigure()
		if not figure then return False

		'generate the dialogue if not done yet (and not just leaving)
		if not boss.GetDialogue(figure.playerID) and ..
		   not figure.isLeavingRoom() and figure.GetInRoomID() > 0
			'generate for the visiting one
			boss.GenerateDialogues(figure.playerID)
		endif

		if boss.GetDialogue(figure.playerID)
			If boss.GetDialogue(figure.playerID).Update() = 0
				figure.LeaveRoom()
				boss.ResetDialogues(figure.playerID)
			endif
		endif
	End Method
End Type