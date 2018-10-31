Rem
	===========================================================
	GUI Textbox
	===========================================================
End Rem
SuperStrict
Import Brl.Map
Import "base.util.graphicsmanagerbase.bmx"
Import "base.util.deltatimer.bmx"
Import "base.util.rectangle.bmx"
Import "base.util.color.bmx"
Import "base.util.helper.bmx"
Import "base.gfx.bitmapfont.bmx"


Type TTooltipBaseGroup
	Field entries:TMap = new TMap

	Method Add(name:object, tooltip:TTooltipBase)
		local key:TLowerString = TLowerString(name)
		if key
			entries.Insert(key, tooltip)
		else
			entries.Insert(TLowerString.Create(string(name)), tooltip)
		endif
	End Method


	Method Get:TTooltipBase(key:TLowerString)
		return TTooltipBase(entries.ValueForKey(key))
	End Method


	Method Update:int()
		For local t:TTooltipBase = EachIn entries.Values()
			t.Update()
		Next
	End Method


	Method Render:Int(xOffset:Int = 0, yOffset:Int=0)
		For local t:TTooltipBase = EachIn entries.Values()
			t.Render(xOffset, yOffset)
		Next
	End Method
End Type




Type TTooltipBase
	'position and size of the tooltip
	Field area:TRectangle
	'alignment of the tooltip compared to position
	Field alignment:TVec2D
	Field offset:TVec2D
	Field parentArea:TRectangle
	Field parentAlignment:TVec2D
	'if a tooltip does not fit on the canvas, it is moved to these
	'coordinates so it fits properly
	Field _renderPosition:TVec2D

	'time the step was set
	'time when first hovering
	Field _stepStartTime:Long = -1
	Field _stepTime:int = 0
	'time until the tooltip is shown (millisecs)
	Field dwellTime:int = 250
	'how long this tooltip will still be shown (millisecs)
	Field activeTime:Int = 5000
	'how long fading takes (millisecs)
	Field fadeTime:Int = 100

	Field data:TData = new TData

	Field title:String
	Field content:String
	Field _minTitleDim:TVec2D ' = new TVec2D.Init(160,0)
	Field _maxTitleDim:TVec2D
	Field _minContentDim:TVec2D ' = new TVec2D.Init(160,0)
	Field _maxContentDim:TVec2D

	Field titleColor:TColor = TColor.Create(50,50,50)
	Field contentColor:TColor = TColor.Create(50,50,50)

	'left (2) and right (4) is for all elements
	'top (1) and bottom (3) padding for content
	Field _contentPadding:TRectangle = new TRectangle.Init(2,3,2,3)

	Field _options:int = 0
	Field _step:int = 0
	Field _contentChanged:int = False
	'cache
	Field _contentDimension:TVec2D()

	Field _customDrawBackground:int(tooltip:TTooltipBase, x:int, y:int, w:int, h:int)
	Field _customDrawForeground:int(tooltip:TTooltipBase, x:int, y:int, w:int, h:int)
	Field _customDrawHeader:int(tooltip:TTooltipBase, x:int, y:int, w:int, h:int)
	Field _customDrawContent:int(tooltip:TTooltipBase, x:int, y:int, w:int, h:int)

	Global sharedDwellTime:int = 1000
	'after this time sharedDwellTime is added again to total DwellTime
	Global sharedDwellTimeSkipTime:int = 1000
	Global _lastTooltipActiveTime:Long = -1
	Global _useFontBold:TBitmapFont
	Global _useFont:TBitmapFont

	Const STEP_INACTIVE:int = 1
	Const STEP_DWELLING:int = 2
	Const STEP_ACTIVE:int = 3
	Const STEP_FADING_OUT:int = 4

	Const OPTION_DISABLED:int = 1
	Const OPTION_HOVERED:int = 2
	Const OPTION_MANUAL_HOVER_CHECK:int = 4
	Const OPTION_MANUALLY_HOVERED:int = 8
	Const OPTION_NULL_LIFETIME_WHEN_NOT_HOVERED:int = 16
	Const OPTION_HAS_LIFETIME:int = 32
	Const OPTION_WAS_ACTIVE:int = 64
	'if the tooltip has to be moved to stay on screen - this sets if it
	'may be rendered over the parent area
	Const OPTION_PARENT_OVERLAY_ALLOWED:int = 128
	Const OPTION_MIRRORED_RENDER_POSITION:int = 256




	Method Initialize:TTooltipBase(title:String="", content:String="unknown", area:TRectangle)
		Self.title = title
		Self.content = content
		Self.area = area
		Self.SetActiveTime(-1)

		Self.alignment = ALIGN_CENTER_BOTTOM
		Self.parentAlignment = ALIGN_CENTER_TOP

		SetStep(STEP_INACTIVE)

		return Self
	End Method


	'sort tooltips according lifetime (dying ones behind)
	Method Compare:Int(other:Object)
		Local otherTip:TTooltipBase = TTooltipBase(other)
		If otherTip
			'below me
			If otherTip.IsStep(STEP_ACTIVE) and otherTip._step = _step
				if otherTip._stepStartTime > _stepStartTime	Then Return 1
				if otherTip._stepStartTime < _stepStartTime	Then Return -1
			endif
			'on top of me
			If otherTip.IsStep(STEP_ACTIVE) and otherTip._step <> _step Then Return 1
		endif

		Return Super.Compare(other)
	End Method


	Method SetOrientationPreset(direction:string="TOP", distance:int = 0)
		offset = null
		Select direction.ToUpper()
			case "LEFT"
				parentAlignment = ALIGN_LEFT_CENTER
				alignment = ALIGN_RIGHT_CENTER
				if distance then offset = new TVec2D.Init(-1 * abs(distance), 0)
			case "RIGHT"
				parentAlignment = ALIGN_RIGHT_CENTER
				alignment = ALIGN_LEFT_CENTER
				if distance then offset = new TVec2D.Init(+1 * abs(distance), 0)
			case "BOTTOM"
				parentAlignment = ALIGN_CENTER_BOTTOM
				alignment = ALIGN_CENTER_TOP
				if distance then offset = new TVec2D.Init(0, +1 * abs(distance))
			default
				parentAlignment = ALIGN_CENTER_TOP
				alignment = ALIGN_CENTER_BOTTOM
				if distance then offset = new TVec2D.Init(0, -1 * abs(distance))
		End Select
	End Method


	Method HasOption:Int(option:Int)
		Return (_options & option) <> 0
	End Method


	Method SetOption(option:Int, enable:Int=True)
		If enable
			_options :| option
		Else
			_options :& ~option
		EndIf
	End Method


	Method SetActiveTime(time:int)
		self.activeTime = time
		if time = -1
			SetOption(OPTION_HAS_LIFETIME, False)
		else
			SetOption(OPTION_HAS_LIFETIME, True)
		endif
	End Method


	Method SetStep:int(s:int)
		if self._step = s then return False

		Select s
			Case STEP_DWELLING
				self._stepTime = GetDwellTime()
				'
			Case STEP_ACTIVE
				self._stepTime = activeTime
				'
			Case STEP_FADING_OUT
				self._stepTime = fadeTime
				'
			Case STEP_INACTIVE
				self._stepTime = -1
				'
			Default
				return False
		End Select

		self._step = s
		self._stepStartTime = Time.MilliSecsLong()

		return True
	End Method


	Method IsStep:int(s:int)
		return self._step = s
	End Method


	Method IsStepTimeGone:int()
		Return Time.MilliSecsLong() > _stepStartTime + _stepTime
	End Method


	Method GetContentPadding:TRectangle()
		return _contentPadding
	End Method


	'Returns the visible rectangle on screen
	Method GetScreenRect:TRectangle()
		return new TRectangle.Init(GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight())
	End Method


	'Returns the x coordinate on the screen
	Method GetScreenX:int()
		local moveX:int = 0
		if alignment then moveX :- alignment.GetX() * GetWidth()
		if GetOffset() then moveX :+ GetOffset().GetX()
		if _renderPosition then moveX :+ _renderPosition.x

		if parentArea
			if parentAlignment then moveX :+ parentAlignment.GetX() * parentArea.GetW()

			return parentArea.GetX() + moveX
		endif
		return area.GetX() - moveX
	End Method


	'Returns the y coordinate on the screen
	Method GetScreenY:int()
		local moveY:int = 0
		if alignment then moveY :- alignment.GetY() * GetHeight()
		if GetOffset() then moveY :+ GetOffset().GetY()
		if _renderPosition then movey :+ _renderPosition.y

		if parentArea
			if parentAlignment then moveY :+ parentAlignment.GetY() * parentArea.GetH()

			return parentArea.GetY() + moveY
		endif
		return area.GetY() + moveY
	End Method


	'Returns the visible width on the screen
	Method GetScreenWidth:int()
		return GetWidth()
	End Method


	'Returns the visible height on the screen
	Method GetScreenHeight:int()
		return GetHeight()
	End Method


	Method GetOffset:TVec2D()
		return offset
	End Method


	'Returns the width (not screen limited)
	Method GetWidth:Int()
		'manual config
		If area.GetW() > 0 Then Return area.GetW()

		'auto width calculation
		If area.GetW() <= 0
			return Max(GetTitleWidth(), GetContentWidth()) + GetContentPadding().GetLeft() + GetContentPadding().GetRight()
		EndIf
	End Method


	'Returns the height (not screen limited)
	Method GetHeight:Int()
		'manual config
		If area.GetH() > 0 Then Return area.GetH()

		'auto height calculation
		If area.GetH() <= 0
			Local result:Int = 0
			Local contentHeight:int = GetContentHeight()
			'height from title + content + spacing
			result:+ GetTitleHeight()
			if contentHeight > 0
				result:+ contentHeight
'				result:+ GetContentPadding().GetTop() + GetContentPadding().GetBottom()
			endif
				result:+ GetContentPadding().GetTop() + GetContentPadding().GetBottom()
			Return result
		EndIf
	End Method



	Method GetContentWidth:Int()
		if content = ""
			if _minContentDim then return _minContentDim.GetIntX()
			return 0
		endif

		local maxWidth:int = 0
		local minWidth:int = 0
		if area.GetW() > 0
			maxWidth = area.GetW() - GetContentPadding().GetLeft() - GetContentPadding().GetRight()
		else if _maxContentDim
			maxWidth = _maxContentDim.GetIntX()
		endif
		if _minContentDim then minWidth = _minContentDim.GetIntX()
		if maxWidth > 0 then minWidth = Min(minWidth, maxWidth)

		if _maxContentDim and _maxContentDim.GetX() > 0
			return Min(Max(minWidth, 1 + GetFont().GetBlockWidth(content, Min(maxWidth, _maxContentDim.GetX()), -1)), _maxContentDim.GetX())
		else
			return Max(minWidth, 1 + GetFont().GetBlockWidth(content, maxWidth, -1))
		endif
	End Method


	Method GetContentHeight:Int()
		if content=""
			if _minContentDim then return _minContentDim.GetIntY()
			return 0
		endif

		local minContentHeight:int = -1
		if _minContentDim then minContentHeight = _minContentDim.GetIntY()

		if _maxContentDim and _maxContentDim.GetY() > 0
			return Min(Max(GetFont().getBlockHeight(content, GetInnerWidth(), -1), minContentHeight), _maxContentDim.GetY())
		else
			return Max(GetFont().getBlockHeight(content, GetInnerWidth(), -1), minContentHeight)
		endif
	End Method


	Method GetInnerWidth:int()
		return GetWidth() - GetContentPadding().GetLeft() - GetContentPadding().GetRight()
	End Method


	Method MoveToVisibleScreenArea(checkParentArea:int = True)
		if not _renderPosition then _renderPosition = new TVec2D
		_renderPosition.SetXY(0,0)
		SetOption(OPTION_MIRRORED_RENDER_POSITION, False)

		local screenRect:TRectangle = GetScreenRect()

		'limit to visible areas
		'-> moves tooltip  so that everything is visible on screen
		local outOfScreenLeft:int = Min(0, screenRect.GetX())
		local outOfScreenRight:int = Max(0, screenRect.GetX2() - GetGraphicsManager().GetWidth())
		local outOfScreenTop:int = Min(0, screenRect.GetY())
		local outOfScreenBottom:int = Max(0, screenRect.GetY2() - GetGraphicsManager().GetHeight())

		if outOfScreenLeft then _renderPosition.AddXY(-outOfScreenLeft, 0)
		if outOfScreenRight then _renderPosition.AddXY(-outOfScreenRight, 0)
		if outOfScreenTop then _renderPosition.AddXY(0, -outOfScreenTop)
		if outOfScreenBottom then _renderPosition.AddXY(0, -outOfScreenBottom)

		'check if it overlaps a parental area
		if checkParentArea and parentArea and not HasOption(OPTION_PARENT_OVERLAY_ALLOWED)
			'store how much it overlaps
			local intersectRect:TRectangle = parentArea.IntersectRect(screenRect)
			if intersectRect
				'move to _other_ side of the widget if overlapping is too much
				if (outOfScreenTop<0 or outOfScreenBottom<0) and intersectRect.GetH() > 5
					local offsetY:int = 0
					if GetOffset() then offsetY = GetOffset().GetY()

					if intersectRect.GetY() = parentArea.GetY()
						_renderPosition.SetY( parentArea.GetY2() - screenRect.GetY() + intersectRect.GetH() - 2 * offsetY )
						SetOption(OPTION_MIRRORED_RENDER_POSITION, True)
					else
						_renderPosition.SetY( -outOfScreenBottom + parentArea.GetY() - screenRect.GetY2() + offsetY )
						SetOption(OPTION_MIRRORED_RENDER_POSITION, True)
					endif
				endif

				if (outOfScreenLeft<0 or outOfScreenRight<0) and intersectRect.GetW() > 5
					local offsetX:int = 0
					if GetOffset() then offsetX = GetOffset().GetX()

					if outOfScreenLeft<>0
						_renderPosition.SetX( -outOfScreenLeft + parentArea.GetX2() - offsetX )
						SetOption(OPTION_MIRRORED_RENDER_POSITION, True)
					else
						_renderPosition.SetX( - screenRect.GetW() - parentArea.GetW()  - 2 * offsetX )
						SetOption(OPTION_MIRRORED_RENDER_POSITION, True)
					endif
				endif
			endif
		endif
	End Method


	Method SetTitle:Int(value:String)
		if title = value then return FALSE

		title = value
	End Method


	Method SetContent:Int(value:String)
		if content = value then return FALSE

		content = value
		_contentChanged = True

		return True
	End Method


	Method SetTitleAndContentMinLimits(minTitleDim:TVec2D, minContentDim:TVec2D=null)
		if minTitleDim
			if not minContentDim = -1 then minContentDim = minTitleDim.Copy()
		endif

		self._minTitleDim = minTitleDim
		self._minContentDim = minContentDim
	End Method


	Method GetTitleHeight:Int()
		if title = ""
			if _minTitleDim then return _minTitleDim.GetIntY()
			return 0
		endif

		if _maxTitleDim and _maxTitleDim.GetIntY() > 0
			return Min(GetFontBold().GetBlockHeight(title, GetTitleWidth(), -1), _maxTitleDim.GetIntY())
		else
			return GetFontBold().GetBlockHeight(title, GetTitleWidth(), -1)
		endif
	End Method


	Method GetTitleWidth:int()
		if title = ""
			if _minTitleDim then return _minTitleDim.GetIntX()
			return 0
		endif

		local minTitleW:int = 0
		if _minTitleDim then minTitleW = _minTitleDim.GetIntX()

		if _maxTitleDim and _maxTitleDim.GetIntX() > 0
			return Min(Max(minTitleW, 1 + GetFontBold().GetBlockWidth(title, _maxTitleDim.GetIntX(), -1)), _maxTitleDim.GetIntX())
		else
			return Max(minTitleW, 1 + GetFontBold().GetBlockWidth(title, -1, -1))
		endif
	End Method


	Method GetStepProgress:Float()
		if _stepTime = -1 then return 0.0
		return float(Min(1.0, Max(0, double(Time.MilliSecsLong() - _stepStartTime) / _stepTime)))
	End Method


	Method GetFont:TBitmapFont()
		if not _useFont then _useFont = GetBitmapFont("Default", 12)
		return _useFont
	End Method


	Method GetFontBold:TBitmapFont()
		if not _useFontBold then _useFontBold = GetBitmapFont("Default", 12, BOLDFONT)
		return _useFontBold
	End Method


	Method GetDwellTime:int()
		if _lastTooltipActiveTime + sharedDwellTimeSkipTime > Time.MilliSecsLong()
			return dwellTime
		endif
		return dwellTime + sharedDwellTime
	End Method


	'reset lifetime
	Method onMouseOver()
		SetOption(OPTION_HOVERED, True)
	End Method


	Method onMouseOut()
		SetOption(OPTION_HOVERED, False)
	End Method


	Method StartFadeOut()
		SetStep(STEP_FADING_OUT)
	End Method

	Method FinishFadeOut()
		SetStep(STEP_INACTIVE)
	End Method

	Method IsFadingOut:int()
		return IsStep(STEP_FADING_OUT)
	End Method



	Method _DrawForeground:Int(x:int, y:int, w:int, h:int)
		if _customDrawForeground then return _customDrawForeground(self, x, y, w, h)

		Local headerSize:Int = GetTitleHeight()

		_DrawHeader(x, y, w, headerSize)
		_DrawContent(x, y + headerSize, w, h - headerSize)
	End Method


	Method _DrawHeader:Int(x:int, y:int, w:int, h:int)
		if _customDrawHeader then return _customDrawHeader(self, x, y, w, h)

		rem
		SetColor 255,200,200
		DrawRect(x, y, w, h)
		SetColor 255,255,255
		endrem

		'caption
		GetFontBold().DrawBlock(title, x, y, w, h, ALIGN_LEFT_CENTER, titleColor, 2, 1, 0.1)

		return True
	End Method


	Method _DrawContent:Int(x:Int, y:Int, w:Int, h:Int)
		if _customDrawContent then return _customDrawContent(self, x, y, w, h)
		If content = "" then return FALSE

		rem
		SetColor 200,255,200
		DrawRect(x, y, w, h)
		SetColor 255,255,255
		endrem

		GetFont().drawBlock(content, x, y, GetContentWidth(), -1, ALIGN_LEFT_TOP, contentColor)

		return True
	End Method


	Method _DrawBackground:int(x:int, y:int, w:int, h:int)
		if _customDrawBackground then return _customDrawBackground(self, x, y, w, h)

		local oldCol:TColor = new TColor.Get()

		'=== SHADOW ===
		SetColor 0, 0, 0
		SetAlpha oldCol.a * 0.3
		DrawRect(x+2, y+2, w, h)

		SetAlpha oldCol.a * 0.1
		DrawRect(x+1, y+1, w, h)

		'=== BORDER ===
		SetAlpha oldCol.a
		SetColor 0,0,0
		DrawRect(x, y, w, h)
		SetColor 255,255,255

		'=== FILLING ===
		SetColor 255,255,255
		DrawRect(x+1, y+1, w-2, h-2)

		oldCol.SetRGBA()

		return True
	End Method


	Method Render:Int(xOffset:Int = 0, yOffset:Int=0)
		rem
		DrawText(GetFadeProgress(), GetScreenX() + xOffset,GetScreenY() + yOffset + 50)
		DrawText("lifetime="+lifetime, GetScreenX() + xOffset,GetScreenY() + yOffset + 62)
		DrawText("fadeStartTime="+_fadeStartTime, GetScreenX() + xOffset,GetScreenY() + yOffset + 74)
		DrawText("hovered="+HasOption(OPTION_HOVERED), GetScreenX() + xOffset,GetScreenY() + yOffset + 86)
		DrawText("inactive="+HasOption(OPTION_INACTIVE), GetScreenX() + xOffset,GetScreenY() + yOffset + 98)
		DrawText("dwelling="+IsDwelling(), GetScreenX() + xOffset,GetScreenY() + yOffset + 110)
		endrem

		If HasOption(OPTION_DISABLED) Then Return False
		If not IsStep(STEP_ACTIVE) and not IsStep(STEP_FADING_OUT) Then Return False

		MoveToVisibleScreenArea()

		Local boxX:int = GetScreenX() + xOffset
		Local boxY:Int	= GetScreenY() + yOffset
		Local boxWidth:int = GetWidth()
		Local boxHeight:Int	= GetHeight()
		Local padding:TRectangle = GetContentPadding()

		local oldCol:TColor = new TColor.Get()
		if IsFadingOut()
			'fade out a bit faster ... ^3
			SetAlpha oldCol.a * float((1.0-GetStepProgress())^2)
		endif

		_DrawBackground(boxX, boxY, boxWidth, boxHeight)
		_DrawForeground(boxX + int(padding.GetLeft()), boxY + int(padding.GetTop()), boxWidth - int(padding.GetLeft() - padding.GetRight()), boxHeight - int(padding.GetTop() - padding.GetBottom()))

		SetAlpha oldCol.a

		return True
	End Method


	Method Update:Int()
		If HasOption(OPTION_DISABLED) Then Return False

		'if _contentChanged
		'	_contentDimension = new TVec2D.Init(GetContentWidth(), GetContentHeight())
		'	_contentChanged = False
		'endif

		'=== ADJUST HOVER STATE ===
		local isHovering:int = False
		if HasOption(OPTION_MANUAL_HOVER_CHECK)
			if HasOption(OPTION_MANUALLY_HOVERED)
				isHovering = True
				onMouseOver()
			endif
		else
			if parentArea and THelper.MouseInRect(parentArea)
				isHovering = True
				onMouseOver()
			endif
		endif
		if not isHovering and HasOption(OPTION_HOVERED)
			onMouseOut()
		endif



		'=== ADJUST STEPS ====
		If IsStep(STEP_INACTIVE) and isHovering
			SetStep(STEP_DWELLING)
		endif

		If IsStep(STEP_DWELLING) and IsStepTimeGone()
			if isHovering or HasOption(OPTION_HAS_LIFETIME)
				SetStep(STEP_ACTIVE)
			elseif not isHovering
				SetStep(STEP_INACTIVE)
			endif
		endif

		If IsStep(STEP_ACTIVE)
			_lastTooltipActiveTime = Time.MilliSecsLong()

			if not HasOption(OPTION_HAS_LIFETIME) and not isHovering
				SetStep(STEP_FADING_OUT)
			elseif HasOption(OPTION_HAS_LIFETIME) and IsStepTimeGone()
				SetStep(STEP_FADING_OUT)
			endif
		endif

		If IsStep(STEP_FADING_OUT) and IsStepTimeGone()
			SetStep(STEP_INACTIVE)
		endif

		Return True
	End Method
End Type
