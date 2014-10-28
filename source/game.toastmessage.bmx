Rem
	====================================================================
	Game specific implementation/configuration of the generic
	TToastMessage.
	====================================================================
End Rem

SuperStrict

Import "Dig/base.framework.toastmessage.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"
Import "game.world.worldtime.bmx"



Type TGameToastMessage extends TToastMessage
	Field backgroundSprite:TSprite
	Field messageType:int = 0
	Field caption:string = ""
	Field text:string = ""
	'the higher the more important the message is
	Field priority:int = 0
	Field showBackgroundSprite:int = True
	'an array containing registered event listeners
	Field _registeredEventListener:TLink[]
	Field _closeAtWorldTime:Double = -1
	Field _closeAtWorldTimeText:String = "closing at %TIME%"


	Method New()
		area.dimension.SetXY(250,50)
	End Method


	Method Remove:Int()
		For Local link:TLink = EachIn _registeredEventListener
			link.Remove()
		Next
		return Super.Remove()
	End Method
	

	Method SetMessageType:Int(messageType:int)
		self.messageType = messageType

		Select messageType
			case 0
				self.backgroundSprite = GetSpriteFromRegistry("gfx_toastmessage.info")
			case 1
				self.backgroundSprite = GetSpriteFromRegistry("gfx_toastmessage.attention")
			case 2
				self.backgroundSprite = GetSpriteFromRegistry("gfx_toastmessage.positive")
			case 3
				self.backgroundSprite = GetSpriteFromRegistry("gfx_toastmessage.negative")
		EndSelect

		RecalculateHeight()
	End Method


	Method SetCloseAtWorldTimeText:int(text:string)
		_closeAtWorldTimeText = text
	End Method


	Method AddCloseOnEvent(eventKey:String)
		local listenerLink:TLink = EventManager.registerListenerMethod(eventKey, self, "onReceiveCloseEvent", self)
		_registeredEventListener :+ [listenerLink]
	End Method


	Method onReceiveCloseEvent(triggerEvent:TEventSimple)
		Close()
	End Method


	Method SetCaption:Int(caption:String)
		self.caption = caption
		RecalculateHeight()
	End Method


	Method SetText:Int(text:String)
		self.text = text
		RecalculateHeight()
	End Method


	'override to add height recalculation (as a bar is drawn then)
	Method SetLifeTime:Int(lifeTime:Float = -1)
		Super.SetLifeTime(lifeTime)
		RecalculateHeight()
	End Method


	Method SetCloseAtWorldTime:Int(worldTime:Double = -1)
		_closeAtWorldTime = worldTime
		RecalculateHeight()
	End Method


	Method SetPriority:Int(priority:int=0)
		self.priority = priority
	End Method 


	Method RecalculateHeight:Int()
		local height:int = 0
		'caption singleline
		height :+ GetBitmapFontManager().baseFontBold.GetMaxCharHeight()
		'text
		'attention: subtract some pixels from width (to avoid texts fitting
		'because of rounding errors - but then when drawing they do not
		'fit)
		height :+ GetBitmapFontManager().baseFont.GetBlockDimension(text, area.GetW() - 3, -1).GetY()
		'gfx padding
		if showBackgroundSprite and backgroundSprite
			height :+ backgroundSprite.GetNinePatchContentBorder().GetTop()
			height :+ backgroundSprite.GetNinePatchContentBorder().GetBottom()
		endif
		'lifetime bar
		if _lifeTime > 0 then height :+ 5
		'close hint
		if _closeAtWorldTime > 0 and _closeAtWorldTimeText <> ""
			height :+ GetBitmapFontManager().baseFontBold.GetMaxCharHeight()
		endif
		
		area.dimension.SetY(height)
	End Method


	'override to add worldTime
	Method Update:Int()
		'check if lifetime is running out - close message then
		if _closeAtWorldTime >= 0 and not HasStatus(TOASTMESSAGE_OPENING_OR_CLOSING)
			if _closeAtWorldTime < GetWorldTime().GetTimeGone()
				close()
			endif
		endif
		
		return Super.Update()
	End Method


	'override to draw our nice background
	Method RenderBackground:Int(xOffset:Float=0, yOffset:Float=0)
		if showBackgroundSprite
			'set type again to reload sprite
			if not backgroundSprite or backgroundSprite.name = "defaultsprite" then SetMessageType(messageType)
			if backgroundSprite
				local oldAlpha:float = GetAlpha()
				SetAlpha oldAlpha * 0.80
				backgroundSprite.DrawArea(xOffset + GetScreenX(), yOffset + GetScreenY(), area.GetW(), area.GetH())
				SetAlpha oldAlpha
			endif
		endif
	End Method


	'override to draw our texts
	Method RenderForeground:Int(xOffset:Float=0, yOffset:Float=0)
		local contentX:int = xOffset + GetScreenX()
		local contentY:int = yOffset + GetScreenY()
		local contentX2:int = contentX + GetScreenWidth()
		local contentY2:int = contentY + GetScreenHeight()
		if showBackgroundSprite and backgroundSprite
			contentX :+ backgroundSprite.GetNinePatchContentBorder().GetLeft()
			contentY :+ backgroundSprite.GetNinePatchContentBorder().GetTop()
			contentX2 :- backgroundSprite.GetNinePatchContentBorder().GetRight()
			contentY2 :- backgroundSprite.GetNinePatchContentBorder().GetBottom()
		endif

		local captionHeight:int = GetBitmapFontManager().baseFontBold.GetMaxCharHeight()
		GetBitmapFontManager().baseFontBold.DrawBlock(caption, contentX, contentY, contentX2 - contentX, captionHeight, null, TColor.clBlack)
		GetBitmapFontManager().baseFont.DrawBlock(text, contentX, contentY + captionHeight, contentX2 - contentX, -1, null, TColor.CreateGrey(50))


		'worldtime close hint
		if _closeAtWorldTime > 0 and _closeAtWorldTimeText <> ""
			local text:String = GetLocale(_closeAtWorldTimeText)
			text = text.Replace("%H%", GetWorldTime().GetDayHour(_closeAtWorldTime))
			text = text.Replace("%I%", GetWorldTime().GetDayMinute(_closeAtWorldTime))
			text = text.Replace("%S%", GetWorldTime().GetDaySecond(_closeAtWorldTime))
			text = text.Replace("%D%", GetWorldTime().GetDay(_closeAtWorldTime))
			text = text.Replace("%Y%", GetWorldTime().GetYear(_closeAtWorldTime))
			text = text.Replace("%SEASON%", GetWorldTime().GetSeason(_closeAtWorldTime))
			text = text.Replace("%TIME%", GetWorldTime().GetFormattedTime(_closeAtWorldTime))
			
			GetBitmapFontManager().baseFontBold.DrawBlock(text, contentX, contentY2 - GetBitmapFontManager().baseFontBold.GetMaxCharHeight(), contentX2 - contentX, -1, null, TColor.CreateGrey(50))
		endif
		
		'lifetime bar
		if _lifeTime > 0
			local lifeTimeWidth:int = contentX2 - contentX
			local oldCol:TColor = new TColor.Get()
			lifeTimeWidth :* GetLifeTimeProgress()

			if priority <= 2
				SetAlpha oldCol.a * 0.2 + 0.05*priority
				SetColor(120,120,120)
			elseif priority <= 5
				SetAlpha oldCol.a * 0.3 + 0.1*priority
				SetColor(200,150,50)
			else
				SetAlpha oldCol.a * 0.5 + 0.05*priority
				SetColor(255,80,80)
			endif
			'+2 = a bit of padding
			DrawRect(contentX, contentY2 - 5 + 2, lifeTimeWidth, 3)
			oldCol.SetRGBA()
		endif

	End Method
End Type
