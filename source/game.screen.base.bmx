Rem
	===========================================================
	specific implementations of game screens
	===========================================================

	The screens within this file are made specifically for the
	game.
ENDREM

SuperStrict
Import "Dig/base.util.event.bmx"
Import "Dig/base.util.registry.bmx"
Import "Dig/base.gfx.sprite.bmx"
Import "common.misc.screen.bmx"
Import "common.misc.error.bmx"
Import "game.player.base.bmx"
Import "game.ingameinterface.bmx"
Import "game.building.base.bmx"
Import "game.building.elevator.bmx"
Import "game.world.bmx"
Import "game.room.base.bmx"
Import "game.gameconfig.bmx"
Import Brl.LinkedList




Type TScreenHandler
	Method Initialize:int() abstract

	'special events for screens used in rooms - only this event has the room as sender
	'screen.onScreenUpdate/Draw is more general purpose
	'returns the event listener links
	Function _RegisterScreenHandler:TEventListenerBase[](updateFunc:int(triggerEvent:TEventBase), drawFunc:int(triggerEvent:TEventBase), screen:TScreen)
		local listeners:TEventListenerBase[]
		if screen
			listeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Room_OnScreenUpdate, updateFunc, screen ) ]
			listeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Room_OnScreenDraw, drawFunc, screen ) ]
		endif
		return listeners
	End Function
End Type




'register to the onLoad-Event for "Screens"
EventManager.registerListenerFunction(TRegistryLoader.eventKey_onLoadResourceFromXML, onLoadScreens, Null, "SCREENS")
Function onLoadScreens:Int( triggerEvent:TEventBase )
	Local screensNode:TxmlNode = TxmlNode(triggerEvent.GetData().Get("xmlNode"))
	Local registryLoader:TRegistryLoader = TRegistryLoader(triggerEvent.GetSender())
	If Not screensNode Or Not registryLoader Then Return False


	Local ScreenCollection:TScreenCollection = TScreenCollection.GetInstance()
	Local childNode:TxmlNode = TxmlNode(screensNode.GetFirstChild())
	While childNode
		Local name:String	= Lower( TXmlHelper.FindValue(childNode, "name", "") )
		If name <> ""
			Local image:String	= Lower( TXmlHelper.FindValue(childNode, "image", "screen_bg_archive") )
			Local parent:String = Lower( TXmlHelper.FindValue(childNode, "parent", "") )

			Local screen:TInGameScreen_Room= New TInGameScreen_Room.Create(name)
			screen.backgroundSpriteName = image
			'add to collection list
			ScreenCollection.Add(screen)

			'if screen has a parent -> set it
			If parent <> "" And ScreenCollection.GetScreen(parent)
				ScreenCollection.GetScreen(parent).AddSubScreen(screen)
			EndIf
		EndIf
		
		childNode = childNode.NextSibling()
	Wend
End Function




'a default game screen
'eg. for menu or loading screens
Type TGameScreen Extends TScreen
    Field backgroundSpriteName:String


	Method Create:TGameScreen(name:String)
		Super.Create(name)
		SetGroup("Game")

		'no default screen change effect
		'_enterScreenEffect = New TScreenChangeEffect_SimpleFader.Create(TScreenChangeEffect.DIRECTION_OPEN)
		'_leaveScreenEffect = New TScreenChangeEffect_SimpleFader.Create(TScreenChangeEffect.DIRECTION_CLOSE)

		EventManager.registerListenerMethod(GameEventKeys.App_OnSetLanguage, Self, "onSetLanguage")
		Return Self
	End Method

	'handle re-localization requests
	Method onSetLanguage:Int(triggerEvent:TEventBase)
		SetLanguage(triggerEvent.GetData().GetString("languageCode", ""))
	End Method


	Method SetLanguage:Int(languageCode:String = "")
		'by default do nothing
	End Method


	Method ToString:String()
		Return "TGameScreen"
	End Method


	Method GetBackground:TSprite()
		If backgroundSpriteName = "" Then Return Null
		Return GetSpriteFromRegistry(backgroundSpriteName)
	End Method


	Method DrawBackground:Int()
'		if not background then return FALSE
		If Not GetBackground()
			SetColor(100, 0, 0)
			SetAlpha(1.0)
			DrawRect(0,0,800,600)
		Else
			SetBlend SOLIDBLEND
			GetBackground().Draw(0, 0)
			SetBlend ALPHABLEND
		EndIf
	End Method


	Method DrawOverlay:Int(tweenValue:Float)
		TError.DrawErrors()
	End Method


	Method Draw:Int(tweenValue:Float)
		DrawBackground()
	End Method
End Type



'screens used ingame (with visible interface)
Type TInGameScreen Extends TScreen
    Field backgroundSpriteName:String
 	Field _contentArea:TRectangle

	Field ingameState:TLowerString = TLowerString.Create("InGame")

	Method Create:TInGameScreen(name:String)
		Super.Create(name)
		SetGroup("InGame")
		'limit content area
		_contentArea = New TRectangle.Init(0, 0, 800, 385)
		Return Self
	End Method


	Method ToString:String()
		Return "TInGameScreen: name="+name
	End Method


	Method Initialize:int()
		'stub
	End Method


	Method GetBackground:TSprite()
		If backgroundSpriteName = "" Then Return Null
		Return GetSpriteFromRegistry(backgroundSpriteName)
	End Method


	Method HasScreenChangeEffect:Int(otherScreen:TScreen)
		'the game rooms have change effects as long as not to or from subscreens

		'is current screen the parent or is toScreen the parent of the current?
		If otherScreen And (otherScreen.GetSubScreen(name) Or GetSubScreen(otherScreen.name))
			Return False
		Else
			Return True
		EndIf
	End Method



	'override to react to different screentypes
	Method BeginEnter:Int(fromScreen:TScreen=Null)
		Super.BeginEnter(fromScreen)

		Local fromScreenGroup:String = ""
		Local fromScreenName:String = ""
		If fromScreen
			fromScreenGroup = fromScreen.group.toUpper()
			fromScreenName = fromScreen.name.toUpper()
		EndIf

		'no change effect when going to a subscreen or parent (aka screen has parent)
		If Not HasScreenChangeEffect(fromScreen)
			_enterScreenEffect = Null
			Return True
		EndIf


		'print "Enter: "+fromScreenGroup+"::"+fromScreenName+" -> "+group+"::"+name
		Select fromScreenGroup
			Case "ExGame"
				'no effect when switching ExGame=>ExGame
				'ExGame::* => ExGame::*
				If group.toUpper() = "ExGame".toUpper()
					'
				'else fade into that screen
				'ExGame::* => *::*
				Else
					_enterScreenEffect = New TScreenChangeEffect_SimpleFader.Create(TScreenChangeEffect.DIRECTION_OPEN)
				EndIf
			Case "InGame".toUpper()
				'fade in when coming from a previous game
				'InGame::* => ExGame::*
				If group.toUpper() = "ExGame".toUpper()
					_enterScreenEffect = New TScreenChangeEffect_SimpleFader.Create(TScreenChangeEffect.DIRECTION_OPEN)
				Else
					'for ingame screens, we take care of "building time",
					'so use an IngameScreenChangeEffect
					_enterScreenEffect = New TInGameScreenChangeEffect_ClosingRects.Create(TScreenChangeEffect.DIRECTION_OPEN, _contentArea)
				EndIf
			Default
				'print "-> FADE default"
				_enterScreenEffect = New TScreenChangeEffect_SimpleFader.Create(TScreenChangeEffect.DIRECTION_OPEN)
		End Select
	End Method


	Method BeginLeave:Int(toScreen:TScreen=Null)
		Super.BeginLeave(toScreen)

		Local toScreenGroup:String = ""
		Local toScreenName:String = ""
		If toScreen
			toScreenGroup = toScreen.group.toUpper()
			toScreenName = toScreen.name.toUpper()
		EndIf

		'no change effect when leaving a subscreen
		If Not HasScreenChangeEffect(toScreen)
			_leaveScreenEffect = Null
			Return True
		EndIf

		'print "Leave: "+group+"::"+name + " -> " + toScreenGroup+"::"+toScreenName
		Select toScreenGroup
			Case "ExGame"
				'no effect when switching ExGame=>ExGame
				'ExGame::* => ExGame::*
				If group.toUpper() = "ExGame".toUpper()
					'
				'else fade out of that screen
				'*::* => ExGame::*
				Else
					_leaveScreenEffect = New TScreenChangeEffect_SimpleFader.Create(TScreenChangeEffect.DIRECTION_CLOSE)
				EndIf
			Case "InGame".toUpper()
				'fade out when starting the game
				'ExGame::* => InGame::*
				If group.toUpper() = "ExGame".toUpper()
					_leaveScreenEffect = New TScreenChangeEffect_SimpleFader.Create(TScreenChangeEffect.DIRECTION_CLOSE)
				Else
					'InGame::World => InGame::*
					'for ingame screens, we take care of "building time",
					'so use an IngameScreenChangeEffect
					_leaveScreenEffect = New TInGameScreenChangeEffect_ClosingRects.Create(TScreenChangeEffect.DIRECTION_CLOSE, _contentArea)
				EndIf
			Default
				_leaveScreenEffect = New TScreenChangeEffect_SimpleFader.Create(TScreenChangeEffect.DIRECTION_CLOSE)
		End Select
	End Method


	Function IsPlayerFigure:int(figure:TFigureBase)
		return GetPlayerBase().GetFigure() = figure
	End Function


	'returns if the figure is the observed one (if no special figure
	'is observed, the player figure is automatically observed)
	Function IsObservedFigure:int(figure:TFigureBase)
		return figure and (GameConfig.IsObserved(figure) or (not GameConfig.GetObservedObject() and GetPlayerBase().GetFigure() = figure))
	End Function


	Method Draw:Int(tweenValue:Float)
		DrawContent(tweenValue)
	End Method


	Method DrawOverlay:Int(tweenValue:Float)
		GetInGameInterface().Draw()
		TError.DrawErrors()
	End Method


	Method Update:Int(deltaTime:Float)
		'check for clicks on items BEFORE others check and use it
		GUIManager.Update(ingameState)

		UpdateContent(deltaTime)


		'ingamechat
		If KEYMANAGER.IsHit(KEY_ENTER)
			If Not GetIngameInterface().chat.guiInput.Isfocused()
				If GetIngameInterface().chat.antiSpamTimer < Time.GetAppTimeGone()
					GUIManager.setFocus( GetIngameInterface().chat.guiInput )
				Else
					Print "no spam pls (input stays deactivated). Timer: " + (GetIngameInterface().chat.antiSpamTimer - Time.GetAppTimeGone())+"ms"
				EndIf
			EndIf
		EndIf



		If Not GetWorldTime().IsPaused()
			GetGameBase().Update(deltaTime)
			GetElevator().Update()
			GetRoomBaseCollection().UpdateEnteringAndLeavingStates()
			GetFigureBaseCollection().UpdateAll()
		EndIf
		'update interface + tooltips also if paused
		GetInGameInterface().Update(deltaTime)
	End Method


	Method DrawContent:Int(tweenValue:Float)
		If GetBackground()
			If _contentArea
				GetBackground().draw(_contentArea.GetX(), _contentArea.GetY())
			Else
				GetBackground().draw(0, 0)
			EndIf
		EndIf
	End Method


	Method UpdateContent(deltaTime:Float)
		'by default do nothing
	End Method
End Type



'of this type only one instance can exist
Type TInGameScreen_World Extends TInGameScreen
	Global instance:TInGameScreen_World
	Global _eventListeners:TEventListenerBase[]


	Method Create:TInGameScreen_World(name:String)
		Super.Create(name)
		SetGroup("InGame")
		SetName(name)

		instance = Self

		Initialize()

		Return Self
	End Method


	Method Initialize:int()
		Super.Initialize()

		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'=== add new event listeners
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Figure_OnBeginLeaveRoom, onBeginLeaveRoom, "TFigure") ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Figure_OnFinishLeaveRoom, onFinishLeaveRoom, "TFigure") ]
	End Method


	Method ToString:String()
		Return "TInGameScreen_World: group="+group+" name="+name
	End Method


	Function onBeginLeaveRoom:Int( triggerEvent:TEventBase )
		Local figure:TFigureBase = TFigureBase( triggerEvent._sender )
		If not IsObservedFigure(figure) Then Return False

		'Set the players current screen when leaving a room
		ScreenCollection.GoToScreen(instance)

		'try to change played music when leaving a room
		'only do this if the playlist is differing from the default one
		'(means: there was another music active)
		If TSoundManager.GetInstance().GetCurrentPlaylist() <> "default"
			TSoundManager.GetInstance().PlayMusicPlaylist("default")
		EndIf

		Return True
	End Function


	Function onFinishLeaveRoom:Int( triggerEvent:TEventBase )
		Local figure:TFigureBase = TFigureBase( triggerEvent._sender )
		If not IsObservedFigure(figure) Then Return False

		'just set the current screen... no animation
		ScreenCollection.targetScreen = null
		ScreenCollection._SetCurrentScreen(instance)
	End Function


	'override default
	Method UpdateContent(deltaTime:Float)
		GetWorld().Update()
		GetBuildingBase().Update()

		'handle player target changes
		local fig:TFigureBase = GetPlayerBase().GetFigure()
		If Not fig.IsInRoom()
			If MOUSEMANAGER.isClicked(1) And Not GUIManager._ignoreMouse
				If Not fig.isChangingRoom()
					If THelper.MouseIn(0, 0, 800, 385)
						'convert mouse position to building-coordinates
						Local x:Int = MouseManager.x - GetBuildingBase().buildingInner.GetScreenRect().GetX()
						Local y:Int = MouseManager.y - GetBuildingBase().buildingInner.GetScreenRect().GetY()
						fig.ChangeTarget(x, y)

						'handled left click
						MouseManager.SetClickHandled(1)
					EndIf
				EndIf
			EndIf
		EndIf
	End Method


	'override default
	Method DrawContent:Int(tweenValue:Float)
		GetWorld().Render()
		'player is not in a room so draw building
		GetBuildingBase().Render()

		if GetGameBase().IsGameOver()
			local oldA:float = GetAlpha()
			SetAlpha oldA * 0.85
			GetBitmapFont("default", 72, BOLDFONT).DrawBox("GAME OVER", 0,0, GetGraphicsManager().GetWidth(), 380, sALIGN_CENTER_CENTER, new SColor8(255,155,125), EDrawTextEffect.Shadow, -1.0)
			Setalpha oldA
		endif
	End Method
End Type




Type TInGameScreen_Room Extends TInGameScreen
	'the rooms connected to this screen
'	Field roomIDs:int[]
	Field currentRoomID:Int = -1
	Global temporaryDisableScreenChangeEffects:Int = False
	Global _eventListeners:TEventListenerBase[]


	Method Create:TInGameScreen_Room(name:String)
		Super.Create(name)
		SetGroup("InGame")
		SetName(name)

		'register events
		Initialize()

		Return Self
	End Method


	Method Initialize:int()
		Super.Initialize()

		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'=== add new event listeners
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Room_OnBeginEnter, OnRoomBeginEnter) ]
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Room_OnFinishEnter, OnRoomFinishEnter) ]
	End Method


	Method ToString:String()
		Local rooms:String = ""
		For Local room:TRoomBase = EachIn GetRoomBaseCollection().list
			If Not IsConnectedToRoom(room) Then Continue

			If rooms <> "" Then rooms :+ ","
			rooms :+ room.GetName()
		Next

		Return "TInGameScreen_Room: group="+group+" name="+ name +" rooms="+rooms
	End Method



	Method IsConnectedToRoom:Int(room:TRoomBase)
		Return (room.GetScreenName() = name)
	End Method


	Method GetCurrentRoom:TRoomBase()
		'if the player is in a specific room, store that ID, so next
		'time GetRoom() might return "null" but we still know what room
		'we have to care for

		'the room of this screen MUST be the room the active player
		'figure is in ...
		Local roomID:int = 0
		Local forFigure:TFigureBase = TFigureBase(GameConfig.GetObservedObject())
		if not forFigure then forFigure = GetPlayerBase().GetFigure()
		if not forFigure Then Throw "GetCurrentRoom failed, no figure found"
		
		roomID = forFigure.GetInRoomID()
		If roomID > 0 then currentRoomID = roomID

		'when loading a savegame with "player in room" and then a savegame
		'with "player in building" this would "throw"
		'if roomID = 0 then Throw "TInGameScreen_Room.GetCurrentRoom() failed, roomID invalid."

		return GetRoomBaseCollection().Get(currentRoomID)
	End Method


	'override parental function
	Method HasScreenChangeEffect:Int(otherScreen:TScreen)
		'the game rooms have no change effect when changing to another
		'room screen -> dev keys

		'skip animation if a shortcutTargets exists
		If TInGameScreen_Room(otherScreen) Or temporaryDisableScreenChangeEffects
			Return False
		Else
			Return True
		EndIf
	End Method


	Function OnRoomFinishEnter:Int(triggerEvent:TEventBase)
		Local room:TRoomBase = TRoomBase(triggerEvent.GetSender())
		If Not room Then Return False

		'only interested in figures entering the room
		Local figure:TFigureBase = TFigureBase(triggerEvent.GetReceiver())
		if not IsObservedFigure(figure) Then Return False

		'try to change played music when entering a room
		'but only if a different playlist is played
		If GetSoundManagerBase().GetMusicPlaylist(room.GetName()) and GetSoundManagerBase().GetCurrentPlaylist() <> room.GetName()
			TSoundManager.GetInstance().PlayMusicPlaylist(room.GetName())
		EndIf
	End Function


	Function OnRoomBeginEnter:Int(triggerEvent:TEventBase)
		Local room:TRoomBase = TRoomBase(triggerEvent.GetSender())
		If Not room Then Return False

		'only interested in figures entering the room
		Local figure:TFigureBase = TFigureBase(triggerEvent.GetReceiver())
		if not IsObservedFigure(figure) Then Return False

		'Set the players current screen when changing rooms
		ScreenCollection.GoToScreen( ScreenCollection.GetScreen(room.GetScreenName()) )

		'reset potentially disabled screenChangeEffectsEnabled
		temporaryDisableScreenChangeEffects = False

		Return True
	End Function


	'override default
	Method UpdateContent(deltaTime:Float)
		Local room:TRoomBase = GetCurrentRoom()
		If room Then room.update()
	End Method


	'override default
	Method DrawContent:Int(tweenValue:Float)
		Local room:TRoomBase = GetCurrentRoom()
		If Not room Then Return False

		If GetBackground() And Not room.GetBackground() Then GetBackground().Draw(0, 0)
		room.Draw()
	End Method
End Type



'extend base effects to make the effect "building time aware"
Type TIngameScreenChangeEffect_SimpleFader extends TScreenChangeEffect_SimpleFader
	Field _timeStartRealTime:Long = 0


	Method GetCurrentTime:Long()
		GetBuildingTime().GetTimeGone()
	End Method


	Method Reset:int()
		Super.Reset()
		_timeStartRealTime = Time.GetAppTimeGone() + GetDuration()
	End Method


	Method GetProgress:Float()
		'slower than realtime
		if GetBuildingTime().GetTimeFactor() < 1.0
			local actionTime:Long = GetDuration() - _waitAtBegin - _waitAtEnd
			if actionTime <= 0 then return 1.0

			return Float( Min(1.0, Max(0, double(Time.GetAppTimeGone() - _timeStartRealTime - _waitAtBegin) / actionTime)))
		endif

		return Super.GetProgress()
	End Method
End Type

Type TIngameScreenChangeEffect_ClosingRects extends TScreenChangeEffect_ClosingRects
	Field _timeStartRealTime:Long = 0


	Method GetCurrentTime:Long()
		return GetBuildingTime().GetTimeGone()
	End Method


	Method Reset:int()
		Super.Reset()
		_timeStartRealTime = Time.GetAppTimeGone()
	End Method


	Method Initialize:int()
		Super.Initialize()

'		SetDuration( GetPlayerBase().GetFigure().changingRoomTime / 2 )
	End Method


	Method GetRealtimeDuration:int()
		If GetBuildingTime().GetTimeFactor() > 1.0
			return GetDuration() / GetBuildingTime().GetTimeFactor()
		Endif

		return Super.GetRealtimeDuration()
	End Method


	Method GetProgress:Float()
		'just skip animating at all then
		if GetBuildingTime().GetTimeFactor() > 6 then return 1.0

		'slower than realtime
		if GetBuildingTime().GetTimeFactor() < 1.0
			local actionTime:Long = GetDuration() - _waitAtBegin - _waitAtEnd
			if actionTime <= 0 then return 1.0

			return Float( Min(1.0, Max(0, double(Time.GetAppTimeGone() - _timeStartRealTime - _waitAtBegin) / actionTime)))
		endif

		return Super.GetProgress()
	End Method
End Type
