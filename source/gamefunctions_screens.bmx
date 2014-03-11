REM
	===========================================================
	specific implementations of game screens
	===========================================================

	The screens within this file are made specifically for the
	game.
ENDREM

'SuperStrict
'Import "basefunctions_sprites.bmx"
'Import "basefunctions_events.bmx"
'Import "basefunctions_screens.bmx"
'Import "basefunctions_resourcemanager.bmx"


EventManager.registerListenerFunction("resources.onLoad.SCREENS", onLoadScreens)
Function onLoadScreens:int( triggerEvent:TEventBase )
	local childNode:TxmlNode = null
	local xmlLoader:TXmlLoader = null
	if not TResourceLoaders.assignBasics( triggerEvent, childNode, xmlLoader ) then return 0

	'screen group
	if triggerEvent.isTrigger("resources.onLoad.SCREENS")
		local ScreenCollection:TScreenCollection = TScreenCollection.GetInstance()
		For Local child:TxmlNode = EachIn childNode.GetChildren()
			Local name:String	= Lower( xmlLoader.xml.FindValue(child, "name", "") )
			local image:string	= Lower( xmlLoader.xml.FindValue(child, "image", "screen_bg_archive") )
			local parent:string = Lower( xmlLoader.xml.FindValue(child, "parent", "") )
			if name <> ""
				local screen:TInGameScreen_Room= new TInGameScreen_Room.Create(name)
				screen.background = Assets.GetSprite(image)
				'add to collection list
				ScreenCollection.Add(screen)

				'if screen has a parent -> set it
				if parent <> "" and ScreenCollection.GetScreen(parent)
					ScreenCollection.GetScreen(parent).AddSubScreen(screen)
				endif
			endif
		Next
	endif
End Function


'a default game screen
'eg. for menu or loading screens
Type TGameScreen extends TScreen
    Field background:TGW_Sprite  'background, the image containing the whole room


	Method Create:TGameScreen(name:string)
		Super.Create(name)
		_enterScreenEffect = new TScreenChangeEffect_SimpleFader.Create(TScreenChangeEffect.DIRECTION_OPEN)
		_leaveScreenEffect = new TScreenChangeEffect_SimpleFader.Create(TScreenChangeEffect.DIRECTION_CLOSE)
		return self
	End Method


	Method ToString:string()
		return "TGameScreen"
	End Method


	Method DrawBackground:int()
'		if not background then return FALSE
		if not background
			TColor.Create(100,0,0).SetRGBA()
			DrawRect(0,0,800,600)
		else
			SetBlend SOLIDBLEND
			background.Draw(20,10)
			SetBlend ALPHABLEND
		endif
	End Method


	Method Draw:int(tweenValue:float)
		DrawBackground()
	End Method
End Type



'screens used ingame (with visible interface)
Type TInGameScreen extends TScreen
    Field background:TGW_Sprite  'background, the image containing the whole room
	field _contentArea:TRectangle


	Method Create:TInGameScreen(name:string)
		Super.Create(name)
		'limit content area
		_contentArea = TRectangle.Create(20, 10, 760, 373)
		return self
	End Method


	Method ToString:string()
		return "TInGameScreen"
	End Method



	Method HasScreenChangeEffect:int(otherScreen:TScreen)
		'the game rooms have change effects as long as not to or from subscreens

		'is current screen the parent or is toScreen the parent of the current?
		if otherScreen and (otherScreen.GetSubScreen(name) or GetSubScreen(otherScreen.name))
			return FALSE
		else
			return TRUE
		endif
	End Method



	'override to react to different screentypes
	Method Enter:int(fromScreen:TScreen=null)
		local screenName:string = ""
		if fromScreen then screenName = fromScreen.ToString().toUpper()


		'no change effect when going to a subscreen or parent (aka screen has parent)
		If not HasScreenChangeEffect(fromScreen)
			_enterScreenEffect = null
			return TRUE
		endif

		Select screenName
			case "TInGameScreen".toUpper()
				_enterScreenEffect = new TScreenChangeEffect_ClosingRects.Create(TScreenChangeEffect.DIRECTION_OPEN, _contentArea)
			default
				_enterScreenEffect = new TScreenChangeEffect_SimpleFader.Create(TScreenChangeEffect.DIRECTION_OPEN)
		End Select
	End Method


	Method Leave:int(toScreen:TScreen=null)
		local screenName:string = ""
		if toScreen then screenName = toScreen.ToString().toUpper()

		'no change effect when leaving a subscreen
		If not HasScreenChangeEffect(toScreen)
			_leaveScreenEffect = null
			return TRUE
		endif

		Select screenName
			case "TInGameScreen".toUpper()
				_leaveScreenEffect = new TScreenChangeEffect_ClosingRects.Create(TScreenChangeEffect.DIRECTION_CLOSE, _contentArea)
			default
				_leaveScreenEffect = new TScreenChangeEffect_SimpleFader.Create(TScreenChangeEffect.DIRECTION_CLOSE)
		End Select
	End Method


	Method Draw:int(tweenValue:float)
		DrawContent(tweenValue)
	End Method


	Method DrawOverlay:int(tweenValue:float)
		'TProfiler.Enter("Draw-Interface")
		Interface.Draw()
		'TProfiler.Leave("Draw-Interface")
	End Method


	Method Update:int(deltaTime:float)
		'check for clicks on items BEFORE others check and use it
		GUIManager.Update("InGame")

		UpdateContent(deltaTime)


		'ingamechat
		If Game.networkgame And KEYMANAGER.IsHit(KEY_ENTER)
			If Not InGame_Chat.guiInput.hasFocus()
				If InGame_Chat.antiSpamTimer < MilliSecs()
					GUIManager.setFocus( InGame_Chat.guiInput )
				Else
					Print "no spam pls (input stays deactivated)"
				EndIf
			EndIf
		EndIf

		If Not Game.paused
			Game.Update(deltaTime)
			Interface.Update(deltaTime)
'			If Game.Players[Game.playerID].Figure.inRoom = Null Then Building.Update(deltaTime)
			Building.Elevator.Update(deltaTime)
			TFigure.UpdateAll(deltaTime)
		EndIf
	End Method


	Method DrawContent:int(tweenValue:Float)
'		SetColor(255,255,255)
		if background
			if _contentArea
				background.draw(_contentArea.GetX(), _contentArea.GetY())
			else
				background.draw(0, 0)
			endif
		endif
'		SetColor(255,255,255)
	End Method


	Method UpdateContent(deltaTime:Float)
		'by default do nothing
	End Method
End Type



'of this type only one instance can exist
Type TInGameScreen_Building extends TInGameScreen
	global instance:TInGameScreen_Building

	Method Create:TInGameScreen_Building(name:string)
		Super.Create(name)
		instance = self

		EventManager.registerListenerFunction("figure.onLeaveRoom", onLeaveRoom, "TFigure" )

		return self
	End Method

	Function onLeaveRoom:int( triggerEvent:TEventBase )
		local figure:TFigure = TFigure( triggerEvent._sender )
		if not figure or not figure.isActivePlayer() then return FALSE

		'Set the players current screen when leaving a room
		ScreenCollection.GoToScreen(instance)

		'try to change played music when leaving a room
		'only do this if the playlist is differing from the default one
		'(means: there was another music active)
		if TSoundManager.GetInstance().GetCurrentPlaylist() <> "default"
			TSoundManager.GetInstance().PlayMusicPlaylist("default")
		endif

		return TRUE
	End Function


	'override default
	Method UpdateContent(deltaTime:Float)
		'66 = 13th floor height, 2 floors normal = 1*73, 50 = roof
		If Game.Players[Game.playerID].Figure.inRoom = Null Then Building.pos.y =  1 * 66 + 1 * 73 + 50 - Game.Players[Game.playerID].Figure.rect.GetY()  'working for player as center

		Building.Update(deltaTime)
	End Method

	'override default
	Method DrawContent(tweenValue:float)
		'TProfiler.Enter("Draw-Building")
		SetColor Int(190 * Building.timecolor), Int(215 * Building.timecolor), Int(230 * Building.timecolor)
		DrawRect(20, 10, 140, 373)
		If Building.pos.y > 10 Then DrawRect(150, 10, 500, 200)
		DrawRect(650, 10, 130, 373)
		SetColor 255, 255, 255
		Building.Draw()									'player is not in a room so draw building
		'TProfiler.Leave("Draw-Building")
	End Method
End Type


Type TInGameScreen_Room extends TInGameScreen
	Field roomName:string
	Field currentRoom:TRoom
	Field rooms:TList = CreateList()  'rooms connected to this screen (eg office 1-4 )
	global shortcutTarget:TRoom = null 'whacky hack

	Method Create:TInGameScreen_Room(name:string)
		Super.Create(name)
		return self
	End Method


	Method SetRoom(room:TRoom)
		EventManager.registerListenerMethod("room.onBeginEnter", self, "OnRoomBeginEnter", room)
		EventManager.registerListenerMethod("room.onEnter", self, "OnRoomEnter", room)

		rooms.addLast(room)
		'store the identifier
		roomName = room.name
	End Method


	Method GetRoom:TRoom()
		'the room of this screen MUST be the room the active player
		'figure is in ...
		return Game.GetPlayer().figure.inRoom
	End Method


	'instead of comparing rooms directly we check for names
	'so the screen for "all" offices is getting returned
	Function GetByRoom:TInGameScreen_Room(room:TRoom)
		For local screen:TInGameScreen_Room = eachin ScreenCollection.screens.Values()
			if screen.roomName = room.name then return screen
		Next
		return Null
	End Function


	'override parental function
	Method HasScreenChangeEffect:int(otherScreen:TScreen)
		'the game rooms have no change effect when changing to another
		'room screen -> dev keys

		'skip animation if a shortcutTargets exists
		if TInGameScreen_Room(otherScreen) or shortcutTarget
			return FALSE
		else
			return TRUE
		endif
	End Method


	Method OnRoomEnter:int(triggerEvent:TEventBase)
		local room:TRoom = TRoom(triggerEvent.GetSender())
		if not room or not rooms.contains(room) then return FALSE

		local figure:TFigure = TFigure(triggerEvent.GetData().Get("figure"))
		if not figure or not figure.isActivePlayer() then return FALSE

		'try to change played music when entering a room
		TSoundManager.GetInstance().PlayMusicPlaylist(room.name)
	End Method


	Method OnRoomBeginEnter:int(triggerEvent:TEventBase)
		local room:TRoom = TRoom(triggerEvent.GetSender())
		if not room or not rooms.contains(room) then return FALSE

		local figure:TFigure = TFigure(triggerEvent.GetData().Get("figure"))
		if not figure or not figure.isActivePlayer() then return FALSE

		'Set the players current screen when changing rooms
		ScreenCollection.GoToScreen(self)

		'remove potential shortcutTargets
		shortcutTarget = null

		return TRUE
	End Method


	'override default
	Method UpdateContent:int(deltaTime:Float)
		'instead of relying on Game.GetPlayer().inRoom each time
		'use currentRoom as inRoom gets reset during room change
		'now we got the correct instance (eg. office from player 1)
		if Game.GetPlayer().figure.inRoom then currentRoom = Game.GetPlayer().figure.inRoom
		if not currentRoom then return FALSE

		currentRoom.update()
	End Method


	'override default
	Method DrawContent:int(tweenValue:Float)
		'instead of relying on Game.GetPlayer().inRoom each time
		'use currentRoom as inRoom gets reset during room change
		'now we got the correct instance (eg. office from player 1)
		if Game.GetPlayer().figure.inRoom then currentRoom = Game.GetPlayer().figure.inRoom
		if not currentRoom then return FALSE

		'TProfiler.Enter("Draw-Room")
		'drawing a subscreen (not the room itself)
		if background and not currentRoom.background then background.Draw(20,10)
		currentRoom.Draw()
		'TProfiler.Leave("Draw-Room")
	End Method
End Type
