SuperStrict
Import "Dig/base.util.time.bmx" 'interval timer
Import "game.roomhandler.base.bmx"


Type RoomHandler_Credits extends TRoomHandler
	Global roles:TCreditsRole[]
	Global currentRolePosition:int = 0
	Global currentCastPosition:int = 0
	Global changeRoleTimer:TIntervalTimer = TIntervalTimer.Create(3200, 0)
	Global fadeTimer:TIntervalTimer = TIntervalTimer.Create(1000, 0)
	Global fadeMode:int = 0 '0 = fadein, 1=stay, 2=fadeout
	Global fadeRole:int = TRUE
	Global fadeValue:float = 0.0

	Global _instance:RoomHandler_Credits


	Function GetInstance:RoomHandler_Credits()
		if not _instance then _instance = new RoomHandler_Credits
		return _instance
	End Function


	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS =====
		local role:TCreditsRole
		role = CreateRole("Das TVTower-Team", SColor8.White)
		role.addCast("und die fleissigen Helfer")

		role = CreateRole("Programmierung", new SColor8(200,200,0))
		role.addCast("Ronny Otto~n(Engine, Spielmechanik)")
		role.addCast("Alexander Nittka~n(Spielmechanik)~n(2020 -)")
		role.addCast("Manuel Vögele~n(Quotenberechnung, Sendermarkt)~n(bis 2015)")
		role.addCast("Bruce A. Henderson~n(BlitzMax-NG + Code-Module)~n(2013 -)")

		role = CreateRole("Grafik", new SColor8(240,160,150))
		role.addCast("Ronny Otto")

		role = CreateRole("KI-Entwicklung", new SColor8(140,240,250))
		role.addCast("Alexander Nittka~n(KI-Verhalten)~n(2022 -)")
		role.addCast("Ronny Otto~n(KI-Verhalten, KI-Anbindung)")
		role.addCast("Manuel Vögele~n(KI-Verhalten, KI-Anbindung)~n(bis 2015)")

		role = CreateRole("Handbuch", new SColor8(170,210,250))
		role.addCast("Själe~n(2017 - 2019")
		role.addCast("Matthew Forrester~n(English translation, 2022)")

		role = CreateRole("Datenbank-Team", new SColor8(210,120,250))
		role.addCast("scr0llbaer~n(2023 - )")
		role.addCast("Ronny Otto") 'begin - since ever
		role.addCast("Alexander Nittka~n(2022 - )")
		role.addCast("Själe~n(2013 - 2019)") 'begin 2013
		role.addCast("TheRob~n(2015 - 2019)") 'begin 2015
		role.addCast("DerFronck~n(2017 - 2019)") 'begin 2017
		role.addCast("Kasi~n(2019)")
		role.addCast("SpeedMinister~n(2014 - 2015)")
		role.addCast("Rumpelfreddy~n(2014)")
		role.addCast("Martin Rackow~n(bis 2007)")
		role.addCast("u.a. Freiwillige")

		role = CreateRole("Lokalisierung", new SColor8(240,120,180))
		role.addCast("scr0llbaer~n(2023 - )~n(English)")
		role.addCast("pauldim~n(2024 - )~n(Polish)")


		role = CreateRole("Tester", new SColor8(160,180,250))
		role.addCast("...und Motivationsteam")
		'old testers (< 2007)
		'role.addCast("Ceddy")
		'role.addCast("djmetzger")
		'old testers (< 2019)
		'role.addCast("domi")
		'role.addCast("DannyF")
		'role.addCast("Helmut")
		'role.addCast("Kurt TV")
		'role.addCast("red")
		'role.addCast("Själe")
		'role.addCast("Teppic")

		role.addCast("Dalli")
		role.addCast("DerFronck")
		role.addCast("dirkw")
		role.addCast("lonk")
		role.addCast("Ratz")
		role.addCast("Rauxelerritter")
		role.addCast("RCBishop")
		role.addCast("Stukov81")
		role.addCast("SushiTV")
		role.addCast("Yoshi")
		role.addCast("TheRob")
		role.addCast("Ulf")

		role.addCast("...und all die anderen Fehlermelder~nim Forum, auf Discord und Github")


		role = CreateRole("", SColor8.White)
		role.addCast("")

		role = CreateRole("Besucht uns im Netz", SColor8.White)
		role.addCast("https://www.tvtower.org")

		role = CreateRole("", SColor8.White)
		role.addCast("")


		'=== EVENTS ===
		'nothing up to now


		'(re-)localize content
		SetLanguage()
	End Method


	Method CleanUp()
		'remove old roles
		roles = new TCreditsRole[0]

		'=== unset cross referenced objects ===
		'

		'=== remove obsolete gui elements ===
		'

		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("credits", GetInstance())
	End Method



	'helper to create a role and store it in the array
	Function CreateRole:TCreditsRole(name:string, color:SColor8)
		roles = roles[..roles.length+1]
		roles[roles.length-1] = new TCreditsRole.Init(name, color)
		return roles[roles.length-1]
	End Function


	Function GetRole:TCreditsRole()
		'reached end
		if currentRolePosition = roles.length then currentRolePosition = 0
		return roles[currentRolePosition]
	End Function


	Function GetCast:string(addToCurrent:int=0)
		local role:TCreditsRole = GetRole()
		'reached end
		if (currentCastPosition + addToCurrent) = role.cast.length then return NULL
		return role.cast[currentCastPosition + addToCurrent]
	End function


	Function NextCast:int()
		currentCastPosition :+1
		return (GetCast() <> "")
	End Function


	Function NextRole:int()
		currentRolePosition :+1
		currentCastPosition = 0
		return TRUE
	End Function


	'reset to start role when entering
	Method onEnterRoom:int( triggerEvent:TEventBase )
		'only handle the players figure
		if TFigure(triggerEvent.GetSender()) <> GetPlayerBase().figure then return False

		fadeTimer.Reset()
		changeRoleTimer.Reset()
		currentRolePosition = 0
		currentCastPosition = 0
		fadeMode = 0
	End Method


	Method onDrawRoom:int( triggerEvent:TEventBase )
		SetAlpha fadeValue

		local fontRole:TBitmapFont = GetBitmapFont("Default",28, BOLDFONT)
		local fontCast:TBitmapFont = GetBitmapFont("Default",20, BOLDFONT)
		if not fadeRole then SetAlpha 1.0
		fontRole.DrawBox(GetRole().name.ToUpper(), 20,180, GetGraphicsManager().GetWidth() - 40, 40, sALIGN_CENTER_TOP, GetRole().color, EDrawTextEffect.Shadow, 0.6)
		SetAlpha fadeValue
		if GetCast() then fontCast.DrawBox(GetCast(), 150,210, GetGraphicsManager().GetWidth() - 300, 80, sALIGN_CENTER_TOP, new SColor8(230,230,30), EDrawTextEffect.Shadow, 0.6)

		SetAlpha 1.0
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		if fadeTimer.isExpired() and fadeMode < 2
			fadeMode:+1
			fadeTimer.Reset()

			'gets "true" if the role is changed again
			fadeRole = FALSE
			'fade if last cast is fading out
			if not GetCast(+1) then fadeRole = true

			if fadeMode = 0 then fadeValue = 0.0
			if fadeMode = 1 then fadeValue = 1.0
			if fadeMode = 2 then fadeValue = 1.0
		endif
		if changeRoleTimer.isExpired()
			'if there is no new cast...next role pls
			if not NextCast() then NextRole()
			changeRoleTimer.Reset()
			fadeTimer.Reset()
			fadeMode = 0 'next fadein
		endif

		'linear fadein
		fadeValue = fadeTimer.GetTimeGoneInPercents()
		if fadeMode = 0 then fadeValue = fadeValue
		if fadeMode = 1 then fadeValue = 1.0
		if fadeMode = 2 then fadeValue = 1.0 - fadeValue
	End Method
End Type



'helper for Credits
Type TCreditsRole
	field name:string = ""
	field cast:string[]
	field color:SColor8

	Method Init:TCreditsRole(name:string, color:SColor8)
		self.name = name
		self.color = color
		return self
	End Method

	Method addCast:int(name:string)
		cast = cast[..cast.length+1]
		cast[cast.length-1] = name
		return true
	End Method
End Type
