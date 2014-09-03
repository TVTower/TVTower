SuperStrict
Import "base.framework.entity.bmx"
Import "base.gfx.bitmapfont.bmx"
Import "base.gfx.renderconfig.bmx"
Import "base.util.event.bmx"


Type TToastMessageCollection extends TStaticEntity
	'spawnPoints contain the messages
	Field spawnPoints:TMap = CreateMap()
	Global _instance:TToastMessageCollection
	Global _eventsRegistered:Int


	Method New()
		if not _eventsRegistered then RegisterEvents()
		'occupy all/no space (different to 0,0 !!)
		self.area.dimension.SetXY(-1,-1)
	End Method


	Function GetInstance:TToastMessageCollection()
		if not _instance then _instance = new TToastMessageCollection
		return _instance
	End Function


	Function RegisterEvents:Int()
		if _eventsRegistered then return False

		'remove closed messages
		EventManager.registerListenerFunction("toastmessage.onClose", onCloseToastMessage)

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
		return True
	End Method


	'add a message on top of others
	Method AddMessageFirst:Int(message:TToastMessage, addToSpawnPoint:String, skipDuplicates:Int = True)
		if skipDuplicates and ContainsMessage(message) then return False

		'get spawnpoint
		local spawnPoint:TToastMessageSpawnPoint = TToastMessageSpawnPoint(spawnPoints.ValueForKey(addToSpawnPoint.ToUpper()))
		if not spawnPoint then return False

		spawnPoint.AddMessageFirst(message)
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


	Method Render:Int(xOffset:Float=0, yOffset:Float=0)
		For local spawnPoint:TToastMessageSpawnPoint = EachIn spawnPoints.Values()
			spawnPoint.Render(xOffset, yOffset)
		Next
	End Method
	

	Method Update:Int()
		For local spawnPoint:TToastMessageSpawnPoint = EachIn spawnPoints.Values()
			spawnPoint.Update()
		Next
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
	Field messages:TList = CreateList()
	'=== CONFIGURATION ===
	'vector describing spaces between two messages
	Field spacerSize:TVec2D = New TVec2D.Init(0,5)
	'render a background?
	Field showBackground:Int = False

	Global GROW_DOWN:int = 1
	Global GROW_UP:int = -1


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


	Method RemoveMessage:Int(message:TToastMessage)
		return messages.Remove(message)
	End Method


	Method ContainsMessage:Int(message:TToastMessage)
		return messages.Contains(message)
	End Method


	'override to displace if there are other entities
	Method GetChildY:Float(child:TStaticEntity)
		if not child then return Null

		local result:Float = 0
		'if alignment.y = GROW_DOWN then result = 0
		if alignment.y = GROW_UP then result :+ area.GetH()

		For local message:TToastMessage = EachIn messages
			if message = child then return result

			Select alignment.y
				case GROW_DOWN
					result :+ child.area.GetH()
					result :+ spacerSize.GetY()
				case GROW_UP
					result :- child.area.GetH()
					result :- spacerSize.GetY()
			End Select
		Next
		return result
	End Method


	Method RenderBackground:Int(xOffset:Float=0, yOffset:Float=0)
		local oldAlpha:Float = GetAlpha()
		SetAlpha oldAlpha * 0.3
		SetColor 255,0,0
		DrawRect(GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight())
		SetAlpha oldAlpha
		SetColor 255,255,255
	End Method


	Method Render:Int(xOffset:Float=0, yOffset:Float=0)
		'store old render config and adjust to our needs
		local renderConfig:TRenderconfig = TRenderConfig.Push()
		if HasSize() then SetViewPort(GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight())


		if showBackground then RenderBackground(xOffset, yOffset)
		
		For local message:TToastMessage = EachIn messages
			message.Render(xOffset, yOffset)
		Next

		'restore old render config
		TRenderConfig.Pop()
	End Method
	

	Method Update:Int()
		For local message:TToastMessage = EachIn messages
			message.Update()
		Next
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


	Method New()
		area.dimension.SetXY(200,50)
		Open()
	End Method


	Method SetDimension:Int(w:int = 0, h:int = 0)
		self.area.dimension.SetXY(w, h)
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
		EventManager.triggerEvent(TEventSimple.Create("toastmessage.onClose", null, Self))
	End Method


	Method SetOpen:Int()
		SetStatus(TOASTMESSAGE_OPEN, True)
		SetStatus(TOASTMESSAGE_CLOSED, False)
		SetStatus(TOASTMESSAGE_OPENING_OR_CLOSING, False)

		'fire event so others can handle it
		EventManager.triggerEvent(TEventSimple.Create("toastmessage.onOpen", null, Self))
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
				MouseManager.ResetKey(1)

				'fire event (eg. to play sound)
				EventManager.triggerEvent(TEventSimple.Create("toastmessage.onClick", new TData.AddNumber("mouseButton", 1), Self))
			Endif
		Endif
	End Method


	Method RenderContent:Int(xOffset:Float=0, yOffset:Float=0)
		'rem
		if canvasImage
			DrawImage(canvasImage, xOffset + GetScreenX(), yOffset + GetScreenY())
		else
			DrawRect(xOffset + GetScreenX(), yOffset + GetScreenY(), area.GetW(), area.GetH())
			SetColor 0,0,255
			if _lifeTime > 0
				local lifeTimeWidth:int = GetScreenWidth() - 10
				lifeTimeWidth :* GetLifeTimeProgress()
				DrawRect(xOffset + GetScreenX() + 5, yOffset + GetScreenY() + area.GetH() - 15, lifeTimeWidth, 10)
			endif
			DrawText(name+" "+id, xOffset + GetScreenX() + 5, yOffset + GetScreenY() + 5)
			SetColor 255,255,255
		endif
		'endrem
	End Method


	Method Render:Int(xOffset:Float=0, yOffset:Float=0)
		'do not draw closed and unanimated elements
		if HasStatus(TOASTMESSAGE_CLOSED) and not HasStatus(TOASTMESSAGE_OPENING_OR_CLOSING) then return False

		'prepare visuals (alpha)
		local progress:Float = GetOpeningClosingProgress()
		if HasStatus(TOASTMESSAGE_OPEN) then progress = 1 - progress 
		
		local oldAlpha:Float = GetAlpha()
		if HasStatus(TOASTMESSAGE_OPENING_OR_CLOSING) then SetAlpha(oldAlpha * progress)


		'draw the message container itself
		Rendercontent(xOffset, yOffset)


		SetAlpha(oldAlpha)
	End Method
End Type