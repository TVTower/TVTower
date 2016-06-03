Rem
	===========================================================
	specific implementations of game screens
	===========================================================

	The screens within this file are made specifically for the
	game.
ENDREM

'SuperStrict
'Import "basefunctions_sprites.bmx"
'Import "basefunctions_events.bmx"
'Import "common.misc.screen.bmx"
'Import "basefunctions_resourcemanager.bmx"

'register to the onLoad-Event for "Screens"
EventManager.registerListenerFunction("RegistryLoader.onLoadResourceFromXML", onLoadScreens,Null, "SCREENS")
Function onLoadScreens:Int( triggerEvent:TEventBase )
	Local screensNode:TxmlNode = TxmlNode(triggerEvent.GetData().Get("xmlNode"))
	Local registryLoader:TRegistryLoader = TRegistryLoader(triggerEvent.GetSender())
	If Not screensNode Or Not registryLoader Then Return False


	Local ScreenCollection:TScreenCollection = TScreenCollection.GetInstance()
	For Local child:TxmlNode = EachIn TXmlHelper.GetNodeChildElements(screensNode)
		Local name:String	= Lower( TXmlHelper.FindValue(child, "name", "") )
		Local image:String	= Lower( TXmlHelper.FindValue(child, "image", "screen_bg_archive") )
		Local parent:String = Lower( TXmlHelper.FindValue(child, "parent", "") )
		If name <> ""
			Local screen:TInGameScreen_Room= New TInGameScreen_Room.Create(name)
			screen.backgroundSpriteName = image
			'add to collection list
			ScreenCollection.Add(screen)

			'if screen has a parent -> set it
			If parent <> "" And ScreenCollection.GetScreen(parent)
				ScreenCollection.GetScreen(parent).AddSubScreen(screen)
			EndIf
		EndIf
	Next
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

		EventManager.registerListenerMethod("Language.onSetLanguage", Self, "onSetLanguage")
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
			TColor.Create(100,0,0).SetRGBA()
			DrawRect(0,0,800,600)
		Else
			SetBlend SOLIDBLEND
			GetBackground().Draw(0, 0)
			SetBlend ALPHABLEND
		EndIf
	End Method


	Method Draw:Int(tweenValue:Float)
		DrawBackground()
	End Method
End Type



'screens used ingame (with visible interface)
Type TInGameScreen Extends TScreen
    Field backgroundSpriteName:String
    'Field hotspots:THotspots     'clickable areas on the screen
	Field _contentArea:TRectangle


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
					_enterScreenEffect = New TScreenChangeEffect_ClosingRects.Create(TScreenChangeEffect.DIRECTION_OPEN, _contentArea)
				EndIf
			Default
				'print "-> FADE default"
				_enterScreenEffect = New TScreenChangeEffect_SimpleFader.Create(TScreenChangeEffect.DIRECTION_OPEN)
		End Select
	End Method


	Method BeginLeave:Int(toScreen:TScreen=Null)
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
					_leaveScreenEffect = New TScreenChangeEffect_ClosingRects.Create(TScreenChangeEffect.DIRECTION_CLOSE, _contentArea)
				EndIf
			Default
				_leaveScreenEffect = New TScreenChangeEffect_SimpleFader.Create(TScreenChangeEffect.DIRECTION_CLOSE)
		End Select
	End Method


	Method Draw:Int(tweenValue:Float)
		DrawContent(tweenValue)
	End Method


	Method DrawOverlay:Int(tweenValue:Float)
		'TProfiler.Enter("Draw-Interface")
		GetInGameInterface().Draw()
		TError.DrawErrors()
		'TProfiler.Leave("Draw-Interface")
	End Method


	Method Update:Int(deltaTime:Float)
		'check for clicks on items BEFORE others check and use it
		GUIManager.Update("InGame")

		UpdateContent(deltaTime)


		'ingamechat
		If KEYMANAGER.IsHit(KEY_ENTER)
			If Not GetIngameInterface().chat.guiInput.hasFocus()
				If GetIngameInterface().chat.antiSpamTimer < Time.GetAppTimeGone()
					GUIManager.setFocus( GetIngameInterface().chat.guiInput )
				Else
					Print "no spam pls (input stays deactivated). Timer: " + (GetIngameInterface().chat.antiSpamTimer - Time.GetAppTimeGone())+"ms"
				EndIf
			EndIf
		EndIf



		If Not GetWorldTime().IsPaused()
			GetGame().Update(deltaTime)
			GetInGameInterface().Update(deltaTime)
			GetElevator().Update()
			GetFigureCollection().UpdateAll()
		EndIf
	End Method


	Method DrawContent:Int(tweenValue:Float)
'		SetColor(255,255,255)
		If GetBackground()
			If _contentArea
				GetBackground().draw(_contentArea.GetX(), _contentArea.GetY())
			Else
				GetBackground().draw(0, 0)
			EndIf
		EndIf
'		SetColor(255,255,255)
	End Method


	Method UpdateContent(deltaTime:Float)
		'by default do nothing
	End Method
End Type



'of this type only one instance can exist
Type TInGameScreen_World Extends TInGameScreen
	Global instance:TInGameScreen_World
	Global _eventListeners:TLink[]


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
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== add new event listeners
		_eventListeners :+ [ EventManager.registerListenerFunction("figure.onLeaveRoom", onLeaveRoom, "TFigure" ) ]
	End Method


	Method ToString:String()
		Return "TInGameScreen_World: group="+group+" name="+name
	End Method


	Function onLeaveRoom:Int( triggerEvent:TEventBase )
		Local figure:TFigure = TFigure( triggerEvent._sender )
		If Not figure Or GetPlayerBase().GetFigure() <> figure Then Return False

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


	'override default
	Method UpdateContent(deltaTime:Float)
		GetWorld().Update()
		GetBuilding().Update()

		'handle player target changes
		local fig:TFigure = GetPlayer().GetFigure()
		If Not fig.IsInRoom()
			If MOUSEMANAGER.isClicked(1) And Not GUIManager._ignoreMouse
				If Not fig.isChangingRoom()
					If THelper.MouseIn(0, 0, 800, 385)
						'convert mouse position to building-coordinates
						Local x:Int = MouseManager.x - GetBuilding().buildingInner.GetScreenX()
						Local y:Int = MouseManager.y - GetBuilding().buildingInner.GetScreenY()
						fig.ChangeTarget(x, y)
						MOUSEMANAGER.resetKey(1)
					EndIf
				EndIf
			EndIf
		EndIf
	End Method


	'override default
	Method DrawContent:Int(tweenValue:Float)
		GetWorld().Render()
		'player is not in a room so draw building
		GetBuilding().Render()

		if GetGameBase().IsGameOver()
			local oldA:float = GetAlpha()
			SetAlpha oldA * 0.85
			GetBitmapFont("default", 72, BOLDFONT).DrawBlock("GAME OVER", 0,0, GetGraphicsManager().GetWidth(), 380, ALIGN_CENTER_CENTER, new TColor.Create(255,155,125), TBitmapFont.STYLE_SHADOW)
			Setalpha oldA
		endif
	End Method
End Type




Type TInGameScreen_Room Extends TInGameScreen
	'the rooms connected to this screen
'	Field roomIDs:int[]
	Field currentRoomID:Int = -1
	Global temporaryDisableScreenChangeEffects:Int = False
	Global _eventListeners:TLink[]


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
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== add new event listeners
		_eventListeners :+ [ EventManager.registerListenerFunction("room.onBeginEnter", OnRoomBeginEnter) ]
		_eventListeners :+ [ EventManager.registerListenerFunction("room.onEnter", OnRoomEnter) ]
	End Method
	

	Method ToString:String()
		Local rooms:String = ""
		For Local room:TRoomBase = EachIn GetRoomBaseCollection().list
			If Not IsConnectedToRoom(room) Then Continue

			If rooms <> "" Then rooms :+ ","
			rooms :+ room.name
		Next

		Return "TInGameScreen_Room: group="+group+" name="+ name +" rooms="+rooms
	End Method



	Method IsConnectedToRoom:Int(room:TRoomBase)
		Return (room.screenName = name)
	End Method


	Method GetCurrentRoom:TRoomBase()
		'if the player is in a specific room, store that ID, so next
		'time GetRoom() might return "null" but we still know what room
		'we have to care for

		'the room of this screen MUST be the room the active player
		'figure is in ...
		Local room:TRoomBase = GetPlayer().GetFigure().inRoom
		If room
			currentRoomID = room.id
		Else
			room = GetRoomBaseCollection().Get(currentRoomID)
		EndIf 
		Return room
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


	Function OnRoomEnter:Int(triggerEvent:TEventBase)
		Local room:TRoomBase = TRoomBase(triggerEvent.GetSender())
		If Not room Then Return False

		'only interested in figures entering the room
		Local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		If Not figure Or GetPlayerBase().GetFigure() <> figure Then Return False

		'try to change played music when entering a room
		TSoundManager.GetInstance().PlayMusicPlaylist(room.name)
	End Function


	Function OnRoomBeginEnter:Int(triggerEvent:TEventBase)
		Local room:TRoomBase = TRoomBase(triggerEvent.GetSender())
		If Not room Then Return False

		'only interested in figures entering the room
		Local figure:TFigure = TFigure(triggerEvent.GetReceiver())
		If Not figure Or GetPlayerBase().GetFigure() <> figure Then Return False

		'Set the players current screen when changing rooms
		ScreenCollection.GoToScreen( ScreenCollection.GetScreen(room.screenName) )
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
		'TProfiler.Leave("Draw-Room")
	End Method
End Type
