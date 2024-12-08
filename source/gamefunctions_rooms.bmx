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
Type RoomHandler_Boss Extends TRoomHandler
	'smoke effect
	Global smokeEmitter:TSpriteParticleEmitter

	Global _instance:RoomHandler_Boss
	Global _initDone:Int = False


	Function GetInstance:RoomHandler_Boss()
		If Not _instance Then _instance = New RoomHandler_Boss
		Return _instance
	End Function


	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===
		If Not smokeEmitter
			Local smokeConfig:TData = New TData
			smokeConfig.Add("sprite", GetSpriteFromRegistry("gfx_misc_smoketexture"))
			smokeConfig.Add("velocityMin", 25)
			smokeConfig.Add("velocityMax", 40)
			smokeConfig.Add("lifeMin", 0.3)
			smokeConfig.Add("lifeMax", 2.5)
			smokeConfig.Add("scaleMin", 0.2)
			smokeConfig.Add("scaleMax", 0.3)
			smokeConfig.Add("scaleRate", 1.2)
			smokeConfig.Add("alphaMin", 0.5)
			smokeConfig.Add("alphaMax", 0.8)
			smokeConfig.Add("alphaRate", -0.90)
			smokeConfig.Add("angleMin", 165)
			smokeConfig.Add("angleMax", 195)
			smokeConfig.Add("xRange", 2)
			smokeConfig.Add("yRange", 2)

			Local emitterConfig:TData = New TData
			emitterConfig.Add("area", New TRectangle.Init(44, 335, 0, 0))
			emitterConfig.Add("particleLimit", 70)
			emitterConfig.Add("spawnEveryMin", 0.45)
			emitterConfig.Add("spawnEveryMax", 0.70)

			smokeEmitter = New TSpriteParticleEmitter.Init(emitterConfig, smokeConfig)
		EndIf
	End Method


	Method CleanUp()
		'
	End Method


	Method RegisterHandler:Int()
		If GetInstance() <> Self Then Self.CleanUp()
		GetRoomHandlerCollection().SetHandler("boss", GetInstance())
	End Method
	

	Method onDrawRoom:Int( triggerEvent:TEventBase )
		smokeEmitter.Draw()

		Local room:TRoom = TRoom(triggerEvent.GetSender())
		'only handle custom elements for players room
		'if room.owner <> GetPlayerCollection().playerID then return FALSE


		Local boss:TPlayerBoss = GetPlayerBoss(room.owner)
		If Not boss Then Return False

		Local figure:TFigureBase = GetObservedFigure()
		If Not figure Then Return False


		If boss.GetDialogue(figure.playerID)
			boss.GetDialogue(figure.playerID).Draw()
		EndIf
	End Method


	Method onUpdateRoom:Int( triggerEvent:TEventBase )
		smokeEmitter.Update()

		Local room:TRoom = TRoom(triggerEvent._sender)
		'only handle custom elements for players room
		'if room.owner <> GetPlayerCollection().playerID then return FALSE

		
		Local boss:TPlayerBoss = GetPlayerBoss(room.owner)
		If Not boss Then Return False

		Local figure:TFigureBase = GetObservedFigure()
		If Not figure Then Return False

		'generate the dialogue if not done yet (and not just leaving)
		If Not boss.GetDialogue(figure.playerID) And ..
		   Not figure.isLeavingRoom() And figure.GetInRoomID() > 0
			'generate for the visiting one
			boss.GenerateDialogues(figure.playerID)
		EndIf

		If boss.GetDialogue(figure.playerID)
			If boss.GetDialogue(figure.playerID).Update() = 0
				figure.LeaveRoom()
				boss.ResetDialogues(figure.playerID)
			EndIf
		EndIf
	End Method
End Type
