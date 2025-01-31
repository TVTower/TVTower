Rem
	====================================================================
	class providing a simple toast message functionality
	====================================================================

	Toast messages are small message boxes in the corners of the screen
	(or a manual position) to show the user some information. They might
	auto close after a given amount of time or react on clicks.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2015 Ronny Otto, digidea.de

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
Import "base.framework.entity.bmx"
Import "base.gfx.bitmapfont.bmx"
Import "base.gfx.renderconfig.bmx"
Import "base.util.event.bmx"
Import "base.util.input.bmx"


Type TToastMessageCollection extends TRenderableEntity
	'spawnPoints contain the messages
	Field spawnPoints:TMap = CreateMap()
	Global _instance:TToastMessageCollection
	Global _eventsRegistered:Int
	Global eventKey_ToastMessageCollection_onAddMessage:TEventKey = EventManager.GetEventKey("ToastMessageCollection.onAddMessage", True)
	Global eventKey_ToastMessage_onClose:TEventKey = EventManager.GetEventKey("ToastMessage.onClose", True)
	Global eventKey_ToastMessage_onOpen:TEventKey = EventManager.GetEventKey("ToastMessage.onOpen", True)
	Global eventKey_ToastMessage_onClick:TEventKey = EventManager.GetEventKey("ToastMessage.onClick", True)


	Method New()
		if not _eventsRegistered then RegisterEvents()
		'occupy all/no space (different to 0,0 !!)
		self.area.SetWH(-1,-1)
	End Method


	Function GetInstance:TToastMessageCollection()
		if not _instance then _instance = new TToastMessageCollection
		return _instance
	End Function


	Function RegisterEvents:Int()
		if _eventsRegistered then return False

		'remove closed messages
		EventManager.registerListenerFunction(eventKey_ToastMessage_onClose, onCloseToastMessage)

		_eventsRegistered = True
		return True
	End Function


	'=== EVENT FUNCTIONS ===

	'remove a closed message from all potential spawning points
	Function onCloseToastMessage:Int(triggerEvent:TEventBase)
		local toastMessage:TToastMessage = TToastMessage(triggerEvent.GetSender())
		if not toastMessage then return False

		return GetInstance().RemoveMessage(toastMessage)
	End Function



	'=== UTILITY FUNCTIONS ===

	'removes all message in all spawn points
	Method RemoveAllMessages:Int()
		for local spawnPoint:TToastMessageSpawnPoint = EachIn spawnPoints.Values()
			spawnPoint.RemoveAllMessages()
		next
	End Method


	'add a point for messages to spawn from
	Method AddSpawnPoint:Int(spawnPoint:TToastMessageSpawnPoint)
		spawnPoint.SetParent(self)

		spawnPoints.insert(spawnPoint.name.toUpper(), spawnPoint)
		return True
	End Method


	'add a point for messages to spawn from
	Method AddNewSpawnPoint:Int(area:TRectangle, alignment:TVec2D, name:String)
		local spawnPoint:TToastMessageSpawnPoint = new TToastMessageSpawnPoint

		spawnPoint.area.copyFrom(area)
		if alignment then spawnPoint.alignment = alignment.copy()

		spawnPoint.name = name

		return AddSpawnPoint(spawnPoint)
	End Method


	'add a message after others
	Method AddMessage:Int(message:TToastMessage, addToSpawnPoint:String, skipDuplicates:Int = True)
		if skipDuplicates and ContainsMessage(message) then return False

		'get spawnpoint
		local spawnPoint:TToastMessageSpawnPoint = TToastMessageSpawnPoint(spawnPoints.ValueForKey(addToSpawnPoint.ToUpper()))
		if not spawnPoint then return False

		spawnPoint.AddMessage(message)

		'send out event - eg for sounds
		TriggerBaseEvent(eventKey_ToastMessageCollection_onAddMessage, new TData.Add("spawnPoint", spawnPoint), null, message )

		return True
	End Method


	'add a message on top of others
	Method AddMessageFirst:Int(message:TToastMessage, addToSpawnPoint:String, skipDuplicates:Int = True)
		if skipDuplicates and ContainsMessage(message) then return False

		'get spawnpoint
		local spawnPoint:TToastMessageSpawnPoint = TToastMessageSpawnPoint(spawnPoints.ValueForKey(addToSpawnPoint.ToUpper()))
		if not spawnPoint then return False

		spawnPoint.AddMessageFirst(message)

		'send out event - eg for sounds
		TriggerBaseEvent(eventKey_ToastMessageCollection_onAddMessage, new TData.Add("spawnPoint", spawnPoint), null, message )

		return True
	End Method


	'checks if the message list contains the given message
	Method ContainsMessage:Int(message:TToastMessage)
		for local spawnPoint:TToastMessageSpawnPoint = EachIn spawnPoints.Values()
			if spawnPoint.ContainsMessage(message) then return True
		next
		return False
	End Method


	'removes a message from the list
	Method RemoveMessage:Int(message:TToastMessage)
		for local spawnPoint:TToastMessageSpawnPoint = EachIn spawnPoints.Values()
			if spawnPoint.RemoveMessage(message) then return True
		next
		return False
	End Method


	Method GetMessageByGUID:TToastMessage(guid:string)
		local m:TToastMessage = null
		for local spawnPoint:TToastMessageSpawnPoint = EachIn spawnPoints.Values()
			m = spawnPoint.GetMessageByGUID(guid)
			if m then return m
		next
		return Null
	End Method


	Method Render:Int(xOffset:Float = 0, yOffset:Float=0, alignment:TVec2D = Null)
		For local spawnPoint:TToastMessageSpawnPoint = EachIn spawnPoints.Values()
			spawnPoint.Render(xOffset, yOffset)
		Next

		'=== DRAW CHILDREN ===
		RenderChildren(xOffset, yOffset, alignment)
	End Method


	Method Update:Int()
		if spawnPoints
			'using "copy()" leads to segfaults in "TMap.NextObject() -> NextNode()"
			'For local spawnPoint:TToastMessageSpawnPoint = EachIn spawnPoints.Copy().Values()
			For local spawnPoint:TToastMessageSpawnPoint = EachIn spawnPoints.Values()
				spawnPoint.Update()
			Next
		endif

		'=== UPDATE CHILDREN ===
		UpdateChildren()
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetToastMessageCollection:TToastMessageCollection()
	Return TToastMessageCollection.GetInstance()
End Function




Type TToastMessageSpawnPoint extends TEntity
	'alignment of messages according to the position of the spawnpoint
	Field alignment:TVec2D
	'messages of the spawnpoint
	Field messages:TObjectList = new TObjectList
	'=== CONFIGURATION ===
	'vector describing spaces between two messages
	Field spacerSize:TVec2D = New TVec2D(0,5)
	'render a background?
	Field showBackground:Int = False

	Global GROW_DOWN:int = 0
	Global GROW_UP:int = 1


	'add a message after others
	Method AddMessage:Int(message:TToastMessage, skipDuplicates:Int = True)
		if skipDuplicates and messages.contains(message) then return False

		message.SetParent(self)

		messages.AddLast(message)
		return True
	End Method


	'add a message on top of others
	Method AddMessageFirst:Int(message:TToastMessage, skipDuplicates:Int = True)
		if skipDuplicates and messages.contains(message) then return False

		message.SetParent(self)

		messages.AddFirst(message)
		return True
	End Method


	Method RemoveAllMessages:Int()
		messages.Clear()
	End Method


	Method RemoveMessage:Int(message:TToastMessage)
		return messages.Remove(message)
	End Method


	Method ContainsMessage:Int(message:TToastMessage)
		return messages.Contains(message)
	End Method


	Method GetMessageByGUID:TToastMessage(guid:string)
		For local i:Int = 0 until messages.Count()
			Local message:TToastMessage = TToastMessage(messages.data[i])
			If message And message.GetGUID() = guid Then Return message
		Next
		return Null
	End Method


	'override to allow alignment
	Method GetChildX:Float(child:TRenderableEntity = Null)
		if not child then return Super.GetChildX()

		return alignment.GetX() * (GetScreenRect().GetW() - child.area.GetW())
	End Method


	'override to displace if there are other entities
	Method GetChildY:Float(child:TRenderableEntity = Null)
		if not child then return Super.GetChildY()

		local result:Float = 0
		'if alignment.y = GROW_DOWN then result = 0
		if alignment.y = GROW_UP then result :+ area.GetH()

		For local i:Int = 0 until messages.Count()
			Local message:TToastMessage = TToastMessage(messages.data[i])
			if message = child
				if alignment.y = GROW_UP then result :- message.area.GetH()
				return result
			endif

			Select alignment.y
				case GROW_DOWN
					result :+ message.area.GetH()
					result :+ spacerSize.GetY()
				case GROW_UP
					result :- message.area.GetH()
					result :- spacerSize.GetY()
			End Select
		Next
		return result
	End Method


	Method RenderBackground:Int(xOffset:Float=0, yOffset:Float=0)
		local oldAlpha:Float = GetAlpha()
		SetAlpha oldAlpha * 0.3
		SetColor 255,0,0
		DrawRect(GetScreenRect().GetX(), GetScreenRect().GetY(), GetScreenRect().GetW(), GetScreenRect().GetH())
		SetAlpha oldAlpha
		SetColor 255,255,255
	End Method


	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		'store old render config and adjust to our needs
		TRenderConfig.Backup()
		Local rect:TRectangle = GetScreenRect()
		if HasSize() then GetGraphicsManager().SetViewPort(int(rect.GetX()), int(rect.GetY()), int(rect.GetW()), int(rect.GetH()))


		if showBackground then RenderBackground(xOffset, yOffset)

		For local i:Int = 0 until messages.Count()
			TToastMessage(messages.data[i]).Render(xOffset, yOffset, alignment)
		Next

		'=== DRAW CHILDREN ===
		RenderChildren(xOffset, yOffset)

		'restore old render config
		TRenderConfig.Restore()
	End Method


	Method Update:Int()
		For local i:Int = 0 until messages.Count()
			TToastMessage(messages.data[i]).Update()
		Next

		'=== UPDATE CHILDREN ===
		UpdateChildren()
	End Method
End Type




Const TOASTMESSAGE_CLOSED:Int = 1
Const TOASTMESSAGE_OPEN:Int = 2
Const TOASTMESSAGE_OPENING_OR_CLOSING:Int = 4

Type TToastMessage extends TEntity
	'a potential canvas to draw things on
	Field canvasImage:TImage = null
	Field _status:Int = 1 'closed
	'time the animation for opening/closing takes, 0 to disable
	Field _openCloseDuration:Float = 0.25
	Field _openCloseTimeGone:Float = 0
	Field _lifeTime:Float = -1
	Field _lifeTimeStartValue:Float = -1
	Field _lifeTimeBarHeight:int = 5
	Field _lifeTimeBarColor:TColor
	Field _lifeTimeBarBottomY:int = 15
	Field _textOffset:TVec2D
	'additional data
	Field _data:TData
	Field _onCloseFunction:int(sender:TToastMessage)
	Global defaultDimension:TVec2D = new TVec2D(200,50)
	Global defaultLifeTimeBarHeight:int = 10
	Global defaultLifeTimeBarColor:TColor = TColor.clWhite
	Global defaultLifeTimeBarBottomY:int = 15
	Global defaultTextOffset:TVec2D = new TVec2D(5,5)


	Method New()
		area.SetWH(defaultDimension)
		_lifeTimeBarHeight = defaultLifeTimeBarHeight
		_lifeTimeBarColor = defaultLifeTimeBarColor.Copy()
		_lifeTimeBarBottomY = defaultLifeTimeBarBottomY
		_textOffset = defaultTextOffset.Copy()

		Open()
	End Method


	Method GenerateGUID:string()
		return "toastmessage-"+id
	End Method


	'sets a function to call when the message gets closed
	Method SetOnCloseFunction(onCloseFunction:int(sender:TToastMessage))
		_onCloseFunction = onCloseFunction
	End Method


	'sets the data the close function gets as param
	Method SetData(data:TData)
		_data = data
	End Method


	Method GetData:TData()
		if not _data then _data = new TData
		return _data
	End Method


	Method SetDimension:Int(w:int = 0, h:int = 0)
		self.area.SetWH(w, h)
	End Method


	Method SetStatus(statusCode:Int, enable:Int=True)
		If enable
			_status :| statusCode
		Else
			_status :& ~statusCode
		EndIf
	End Method


	Method HasStatus:Int(statusCode:Int)
		Return _status & statusCode
	End Method


	Method Close:Int()
		if HasStatus(TOASTMESSAGE_OPEN)
			SetStatus(TOASTMESSAGE_OPENING_OR_CLOSING, True)
			_openCloseTimeGone = 0
		endif
	End Method


	Method Open:Int()
		if HasStatus(TOASTMESSAGE_CLOSED)
			SetStatus(TOASTMESSAGE_OPENING_OR_CLOSING, True)
			_openCloseTimeGone = 0
		endif
	End Method


	Method IsOpen:Int()
		return HasStatus(TOASTMESSAGE_OPEN) and not HasStatus(TOASTMESSAGE_OPENING_OR_CLOSING)
	End Method


	Method IsClosed:Int()
		return HasStatus(TOASTMESSAGE_CLOSED) and not HasStatus(TOASTMESSAGE_OPENING_OR_CLOSING)
	End Method


	Method SetClosed:Int()
		SetStatus(TOASTMESSAGE_OPEN, False)
		SetStatus(TOASTMESSAGE_CLOSED, True)
		SetStatus(TOASTMESSAGE_OPENING_OR_CLOSING, False)

		'fire event so others can handle it (eg. remove from list)
		TriggerBaseEvent(TToastMessageCollection.eventKey_ToastMessage_onClose, null, Self)
		if _onCloseFunction then _onCloseFunction(self)
	End Method


	Method SetOpen:Int()
		SetStatus(TOASTMESSAGE_OPEN, True)
		SetStatus(TOASTMESSAGE_CLOSED, False)
		SetStatus(TOASTMESSAGE_OPENING_OR_CLOSING, False)

		'fire event so others can handle it
		TriggerBaseEvent(TToastMessageCollection.eventKey_ToastMessage_onOpen, null, Self)
	End Method


	Method SetLifeTime:Int(lifeTime:Float = -1)
		_lifeTime = lifeTime
		_lifeTimeStartValue = lifeTime
	End Method


	Method GetLifeTimeProgress:Float()
		return _lifeTime / _lifeTimeStartValue
	End Method


	Method GetOpeningClosingProgress:Float()
		return Max(0, Min(1, _openCloseTimeGone / _openCloseDuration))
	End Method


	'override default to add extra handling
	Method Update:Int()
		'check if lifetime is running out - close message then
		if _lifeTime > 0
			_lifeTime :- GetDeltaTimer().GetDelta()
			if _lifeTime < 0 then Close()
		endif

		'check if closing/opening finished
		if HasStatus(TOASTMESSAGE_OPENING_OR_CLOSING)
			_openCloseTimeGone :+ GetDeltaTimer().GetDelta()

			if _openCloseTimeGone > _openCloseDuration
				if HasStatus(TOASTMESSAGE_CLOSED)
					SetOpen()
				else
					SetClosed()
					return True
				endif
			endif
		endif

		'check clicked state
		If GetScreenArea().containsXY(MouseManager.x, MouseManager.y)
			If MouseManager.IsClicked(1)
				Close()

				'fire event (eg. to play sound)
				TriggerBaseEvent(TToastMessageCollection.eventKey_ToastMessage_onClick, new TData.AddNumber("mouseButton", 1), Self)

				'handled single click
				MouseManager.SetClickHandled(1)
			Endif
		Endif
	End Method


	Method RenderBackground:Int(xOffset:Float=0, yOffset:Float=0)
		if canvasImage
			DrawImage(canvasImage, xOffset + GetScreenRect().GetX(), yOffset + GetScreenRect().GetY())
'rem
		else
			DrawRect(xOffset + GetScreenRect().GetX(), yOffset + GetScreenRect().GetY(), area.GetW(), area.GetH())
			_lifeTimeBarColor.SetRGB()
			if _lifeTime > 0
				local lifeTimeWidth:int = GetScreenRect().GetW() - 2 * _textOffset.GetIntX()
				lifeTimeWidth :* GetLifeTimeProgress()
				DrawRect(xOffset + GetScreenRect().GetX() + _textOffset.GetIntX(), yOffset + GetScreenRect().GetY() + area.GetH() - _lifeTimeBarBottomY, lifeTimeWidth, _lifeTimeBarHeight)
			endif
			SetColor 255,255,255
			DrawText(name+" "+id, xOffset + GetScreenRect().GetX() + _textOffset.GetIntX(), yOffset + GetScreenRect().GetY() + _textOffset.GetIntY())
'endrem
		endif
	End Method


	Method RenderForeground:Int(xOffset:Float=0, yOffset:Float=0)
		'
	End Method


	Method RenderContent:Int(xOffset:Float=0, yOffset:Float=0)
		RenderBackground(xOffset, yOffset)
		RenderForeground(xOffset, yOffset)
	End Method


	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
		'do not draw closed and unanimated elements
		if HasStatus(TOASTMESSAGE_CLOSED) and not HasStatus(TOASTMESSAGE_OPENING_OR_CLOSING) then return False

		'prepare visuals (alpha)
		local progress:Float = GetOpeningClosingProgress()
		if HasStatus(TOASTMESSAGE_OPEN) then progress = 1 - progress

		local oldAlpha:Float = GetAlpha()
		if HasStatus(TOASTMESSAGE_OPENING_OR_CLOSING) then SetAlpha(oldAlpha * progress)

		'draw the message container itself
		RenderContent(xOffset, yOffset)

		SetAlpha(oldAlpha)

		'=== DRAW CHILDREN ===
		RenderChildren(xOffset, yOffset)
	End Method
End Type
