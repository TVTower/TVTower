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
	Field entries:TMap = New TMap

	Method Add(name:Object, tooltip:TTooltipBase)
		Local key:TLowerString = TLowerString(name)
		If key
			entries.Insert(key, tooltip)
		Else
			entries.Insert(TLowerString.Create(String(name)), tooltip)
		EndIf
	End Method


	Method Get:TTooltipBase(key:TLowerString)
		Return TTooltipBase(entries.ValueForKey(key))
	End Method


	Method Update:Int()
		For Local t:TTooltipBase = EachIn entries.Values()
			t.Update()
		Next
	End Method


	Method Render:Int(xOffset:Int = 0, yOffset:Int=0)
		For Local t:TTooltipBase = EachIn entries.Values()
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
	Field _renderPositionOffset:TVec2D

	'time the step was set
	'time when first hovering
	Field _stepStartTime:Long = -1
	Field _stepTime:Int = 0
	'time until the tooltip is shown (millisecs)
	Field dwellTime:Int = 250
	'how long this tooltip will still be shown (millisecs)
	Field activeTime:Int = 5000
	'how long fading takes (millisecs)
	Field fadeTime:Int = 100

	Field data:TData = New TData

	Field title:String
	Field content:String
	Field _titleCache:TBitmapFontText
	Field _contentCache:TBitmapFontText
	Field _minTitleDim:TVec2D ' = new TVec2D(160,0)
	Field _maxTitleDim:TVec2D
	Field _minContentDim:TVec2D ' = new TVec2D(160,0)
	Field _maxContentDim:TVec2D

	Field titleColor:SColor8 = new SColor8(50,50,50)
	Field contentColor:SColor8 = new SColor8(50,50,50)

	'left (2) and right (4) is for all elements
	'top (1) and bottom (3) padding for content
	Field _contentPadding:TRectangle = New TRectangle.Init(2,3,2,3)

	Field _options:Int = 0
	Field _step:Int = 0

	Field _customDrawBackground:Int(tooltip:TTooltipBase, x:Int, y:Int, w:Int, h:Int)
	Field _customDrawForeground:Int(tooltip:TTooltipBase, x:Int, y:Int, w:Int, h:Int)
	Field _customDrawHeader:Int(tooltip:TTooltipBase, x:Int, y:Int, w:Int, h:Int)
	Field _customDrawContent:Int(tooltip:TTooltipBase, x:Int, y:Int, w:Int, h:Int)

	Global sharedDwellTime:Int = 1000
	'after this time sharedDwellTime is added again to total DwellTime
	Global sharedDwellTimeSkipTime:Int = 1000
	Global _lastTooltipActiveTime:Long = -1
	Global _useFontBold:TBitmapFont
	Global _useFont:TBitmapFont

	Global titleDrawTextEffect:TDrawTextEffect
	Global titleDrawTextSettings:TDrawTextSettings
	Global contentDrawTextEffect:TDrawTextEffect
	Global contentDrawTextSettings:TDrawTextSettings

	Const STEP_INACTIVE:Int = 1
	Const STEP_DWELLING:Int = 2
	Const STEP_ACTIVE:Int = 3
	Const STEP_FADING_OUT:Int = 4

	Const OPTION_DISABLED:Int = 1
	Const OPTION_HOVERED:Int = 2
	Const OPTION_MANUAL_HOVER_CHECK:Int = 4
	Const OPTION_MANUALLY_HOVERED:Int = 8
	Const OPTION_NULL_LIFETIME_WHEN_NOT_HOVERED:Int = 16
	Const OPTION_HAS_LIFETIME:Int = 32
	Const OPTION_WAS_ACTIVE:Int = 64
	'if the tooltip has to be moved to stay on screen - this sets if it
	'may be rendered over the parent area
	Const OPTION_PARENT_OVERLAY_ALLOWED:Int = 128
	Const OPTION_MIRRORED_RENDER_POSITION_X:Int = 256
	Const OPTION_MIRRORED_RENDER_POSITION_Y:Int = 512
	
	
	Method New()
		If not titleDrawTextEffect
			titleDrawTextEffect = new TDrawTextEffect
			titleDrawTextEffect.data.mode = EDrawTextEffect.None
			titleDrawTextEffect.data.value = 0.2
			
			titleDrawTextSettings = new TDrawTextSettings

			contentDrawTextEffect = new TDrawTextEffect
			contentDrawTextSettings = new TDrawTextSettings
		EndIf
	End Method




	Method Initialize:TTooltipBase(title:String="", content:String="unknown", area:TRectangle)
		Self.title = title
		Self.content = content
		Self.area = area
		Self.SetActiveTime(-1)

		Self.alignment = ALIGN_CENTER_BOTTOM
		Self.parentAlignment = ALIGN_CENTER_TOP

		SetStep(STEP_INACTIVE)

		Return Self
	End Method


	'sort tooltips according lifetime (dying ones behind)
	Method Compare:Int(other:Object)
		Local otherTip:TTooltipBase = TTooltipBase(other)
		If otherTip
			'below me
			If otherTip.IsStep(STEP_ACTIVE) And otherTip._step = _step
				If otherTip._stepStartTime > _stepStartTime	Then Return 1
				If otherTip._stepStartTime < _stepStartTime	Then Return -1
			EndIf
			'on top of me
			If otherTip.IsStep(STEP_ACTIVE) And otherTip._step <> _step Then Return 1
		EndIf

		Return Super.Compare(other)
	End Method


	Method SetOrientationPreset(direction:String="TOP", distance:Int = 0)
		If Not offset Then offset = New TVec2D

		Select direction.ToUpper()
			Case "LEFT"
				parentAlignment = ALIGN_LEFT_CENTER
				alignment = ALIGN_RIGHT_CENTER
				If distance Then offset.SetXY(-1 * Abs(distance), 0)
			Case "RIGHT"
				parentAlignment = ALIGN_RIGHT_CENTER
				alignment = ALIGN_LEFT_CENTER
				If distance Then offset.SetXY(+1 * Abs(distance), 0)
			Case "BOTTOM"
				parentAlignment = ALIGN_CENTER_BOTTOM
				alignment = ALIGN_CENTER_TOP
				If distance Then offset.SetXY(0, +1 * Abs(distance))
			Default
				parentAlignment = ALIGN_CENTER_TOP
				alignment = ALIGN_CENTER_BOTTOM
				If distance Then offset.SetXY(0, +1 * Abs(distance))
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


	Method SetActiveTime(time:Int)
		Self.activeTime = time
		If time = -1
			SetOption(OPTION_HAS_LIFETIME, False)
		Else
			SetOption(OPTION_HAS_LIFETIME, True)
		EndIf
	End Method


	Method SetStep:Int(s:Int)
		If Self._step = s Then Return False

		Select s
			Case STEP_DWELLING
				Self._stepTime = GetDwellTime()
				'
			Case STEP_ACTIVE
				Self._stepTime = activeTime
				'
			Case STEP_FADING_OUT
				Self._stepTime = fadeTime
				'
			Case STEP_INACTIVE
				Self._stepTime = -1
				'
			Default
				Return False
		End Select

		Self._step = s
		Self._stepStartTime = Time.MilliSecsLong()

		Return True
	End Method


	Method IsStep:Int(s:Int)
		Return Self._step = s
	End Method


	Method IsStepTimeGone:Int()
		Return Time.MilliSecsLong() > _stepStartTime + _stepTime
	End Method


	Method GetContentPadding:TRectangle()
		Return _contentPadding
	End Method


	'Returns the visible rectangle on screen
	Method GetScreenRect:TRectangle()
		Return New TRectangle.Init(GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight())
	End Method


	'Returns the x coordinate on the screen
	Method GetScreenX:Int()
		Local moveX:Int = 0
		If alignment Then moveX :- alignment.GetX() * GetWidth()
		If GetOffset()
			'offset is static (not multiplied with alignment) but when
			'mirrored it should switch direction
			If HasOption(OPTION_MIRRORED_RENDER_POSITION_X)
				moveX :- GetOffset().GetX()
			Else
				moveX :+ GetOffset().GetX()
			EndIf
		EndIf
		If _renderPositionOffset Then moveX :+ _renderPositionOffset.x

		If parentArea
			If parentAlignment Then moveX :+ parentAlignment.GetX() * parentArea.GetW()

			Return parentArea.GetX() + moveX
		EndIf
		Return area.GetX() - moveX
	End Method


	'Returns the y coordinate on the screen
	Method GetScreenY:Int()
		Local moveY:Int = 0
		If alignment Then moveY :- alignment.GetY() * GetHeight()
		If GetOffset()
			'offset is static (not multiplied with alignment) but when
			'mirrored it should switch direction
			If HasOption(OPTION_MIRRORED_RENDER_POSITION_Y)
				moveY :- GetOffset().GetY()
			Else
				moveY :+ GetOffset().GetY()
			EndIf
		EndIf
		If _renderPositionOffset Then moveY :+ _renderPositionOffset.y

		If parentArea
			If parentAlignment Then moveY :+ parentAlignment.GetY() * parentArea.GetH()

			Return parentArea.GetY() + moveY
		EndIf
		Return area.GetY() + moveY
	End Method


	'Returns the visible width on the screen
	Method GetScreenWidth:Int()
		Return GetWidth()
	End Method


	'Returns the visible height on the screen
	Method GetScreenHeight:Int()
		Return GetHeight()
	End Method


	Method GetOffset:TVec2D()
		Return offset
	End Method


	'Returns the width (not screen limited)
	Method GetWidth:Int()
		'manual config
		If area.GetW() > 0 Then Return area.GetW()

		'auto width calculation
		If area.GetW() <= 0
			Return Max(GetTitleWidth(), GetContentWidth()) + GetContentPadding().GetLeft() + GetContentPadding().GetRight()
		EndIf
	End Method


	'Returns the height (not screen limited)
	Method GetHeight:Int()
		'manual config
		If area.GetH() > 0 Then Return area.GetH()

		'auto height calculation
		If area.GetH() <= 0
			Local result:Int = 0
			Local contentHeight:Int = GetContentHeight()
			'height from title + content + spacing
			result:+ GetTitleHeight()
			If contentHeight > 0
				result:+ contentHeight
'				result:+ GetContentPadding().GetTop() + GetContentPadding().GetBottom()
			EndIf
			result:+ GetContentPadding().GetTop() + GetContentPadding().GetBottom()

			Return result
		EndIf
	End Method



	Method GetContentWidth:Int()
		If content = ""
			If _minContentDim Then Return _minContentDim.GetIntX()
			Return 0
		EndIf

		If _contentCache And _contentCache.HasCache() Then Return _contentCache.cache.width

		Local maxWidth:Int = 0
		Local minWidth:Int = 0
		If area.GetW() > 0
			maxWidth = area.GetW() - GetContentPadding().GetLeft() - GetContentPadding().GetRight()
		Else If _maxContentDim
			maxWidth = _maxContentDim.GetIntX()
		EndIf
		If _minContentDim Then minWidth = _minContentDim.GetIntX()
		If maxWidth > 0 Then minWidth = Min(minWidth, maxWidth)

		If _maxContentDim And _maxContentDim.GetX() > 0
			Return Int(Min(Max(minWidth, 1 + GetFont().GetWidth(content, int(Min(maxWidth, _maxContentDim.GetX())), -1)), _maxContentDim.GetX()))
		Else
			Return Int(Max(minWidth, 1 + GetFont().GetWidth(content, maxWidth, -1)))
		EndIf
	End Method


	Method GetContentHeight:Int()
		If content=""
			If _minContentDim Then Return _minContentDim.GetIntY()
			Return 0
		EndIf

		Local minContentHeight:Int = 0
		If _minContentDim Then minContentHeight = _minContentDim.GetIntY()

		If _contentCache And _contentCache.HasCache() Then Return Max(minContentHeight, _contentCache.cache.height)

		If _maxContentDim And _maxContentDim.GetY() > 0
			Return Int(Min(Max(GetFont().GetHeight(content, GetInnerWidth(), -1), minContentHeight), _maxContentDim.GetY()))
		Else
			Return Int(Max(GetFont().GetHeight(content, GetInnerWidth(), -1), minContentHeight))
		EndIf
	End Method


	Method GetInnerWidth:Int()
		Return GetWidth() - GetContentPadding().GetLeft() - GetContentPadding().GetRight()
	End Method


	'adjusts "_renderPositionOffset" to be totally visible on screen
	Method MoveToVisibleScreenArea(checkParentArea:Int = True)
		If Not _renderPositionOffset Then _renderPositionOffset = New TVec2D
		_renderPositionOffset.SetXY(0,0)
		SetOption(OPTION_MIRRORED_RENDER_POSITION_X, False)
		SetOption(OPTION_MIRRORED_RENDER_POSITION_Y, False)

		Local screenRect:TRectangle = GetScreenRect()

		'limit to visible areas
		'-> moves tooltip  so that everything is visible on screen
		Local outOfScreenLeft:Int = Min(0, screenRect.GetX())
		Local outOfScreenRight:Int = Max(0, screenRect.GetX2() - GetGraphicsManager().GetWidth())
		Local outOfScreenTop:Int = Min(0, screenRect.GetY())
		Local outOfScreenBottom:Int = Max(0, screenRect.GetY2() - GetGraphicsManager().GetHeight())

		If outOfScreenLeft Then _renderPositionOffset.AddXY(-outOfScreenLeft, 0)
		If outOfScreenRight Then _renderPositionOffset.AddXY(-outOfScreenRight, 0)
		If outOfScreenTop Then _renderPositionOffset.AddXY(0, -outOfScreenTop)
		If outOfScreenBottom Then _renderPositionOffset.AddXY(0, -outOfScreenBottom)

		'check if it overlaps a parental area
		If checkParentArea And parentArea And Not HasOption(OPTION_PARENT_OVERLAY_ALLOWED)
			'store how much it overlaps
			Local intersectRect:TRectangle = parentArea.IntersectRectXYWH(screenRect.GetX() + _renderPositionOffset.x, screenRect.GetY() + _renderPositionOffset.y, screenRect.GetW(), screenRect.GetH())
			If intersectRect
				'only correct if we else would cross the parentArea

				If alignment.GetX() <> 1.0 And alignment.GetX() <> 0.0
					'move to _other_ side of the widget if overlapping is too much
					If (outOfScreenTop < 0 Or outOfScreenBottom > 0) And intersectRect.GetH() > 5
						Local offsetY:Int = 0
						If GetOffset() Then offsetY = GetOffset().GetY()

						'from top to bottom?
						If screenRect.GetY() < parentArea.GetY()
							_renderPositionOffset.SetY( parentArea.GetY2() + _renderPositionOffset.y + offsetY)
							SetOption(OPTION_MIRRORED_RENDER_POSITION_Y, True)
						'from bottom to top
						Else
							_renderPositionOffset.SetY( - parentArea.GetH() - screenRect.GetH())
							SetOption(OPTION_MIRRORED_RENDER_POSITION_Y, True)
						EndIf
					EndIf
				EndIf

				If alignment.GetY() <> 1.0 And alignment.GetY() <> 0.0
					If (outOfScreenLeft < 0 Or outOfScreenRight > 0) And intersectRect.GetW() > 5
						Local offsetX:Int = 0
						If GetOffset() Then offsetX = GetOffset().GetX()

						'from left to right?
						If screenRect.GetX() < parentArea.GetX()
							_renderPositionOffset.SetX( parentArea.GetX2() + _renderPositionOffset.x + offsetX)
							SetOption(OPTION_MIRRORED_RENDER_POSITION_X, True)
						'from right to left
						Else
							_renderPositionOffset.SetX( - parentArea.GetW() - screenRect.GetW())
							SetOption(OPTION_MIRRORED_RENDER_POSITION_X, True)
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	End Method


	Method SetTitle:Int(value:String)
		If title = value Then Return False

		If _titleCache Then _titleCache.Invalidate()

		title = value
	End Method


	Method SetContent:Int(value:String)
		If content = value Then Return False

		If _contentCache Then _contentCache.Invalidate()

		content = value

		Return True
	End Method


	Method SetTitleAndContentMinLimits(minTitleDim:TVec2D, minContentDim:TVec2D=Null)
		If minTitleDim
			If Not minContentDim = -1 Then minContentDim = minTitleDim.Copy()
		EndIf

		Self._minTitleDim = minTitleDim
		Self._minContentDim = minContentDim

		If _contentCache Then _contentCache.Invalidate()
	End Method


	Method GetTitleHeight:Int()
		If title = ""
			If _minTitleDim Then Return _minTitleDim.GetIntY()
			Return 0
		EndIf

		If _titleCache And _titleCache.HasCache() 
			Return _titleCache.cache.height
'			Return _titleCache.textBoxdimension.y
		endif
		If _maxTitleDim And _maxTitleDim.GetIntY() > 0
			Return Min(GetFontBold().GetBoxDimension(title, GetTitleWidth(), -1, titleDrawTextEffect.data, titleDrawTextSettings.data).y, _maxTitleDim.GetIntY())
		Else
			Return GetFontBold().GetBoxDimension(title, GetTitleWidth(), -1, titleDrawTextEffect.data, titleDrawTextSettings.data).y
		EndIf
	End Method


	Method GetTitleWidth:Int()
		If title = ""
			If _minTitleDim Then Return _minTitleDim.GetIntX()
			Return 0
		EndIf

		If _titleCache And _titleCache.HasCache() 
			Return _titleCache.cache.width
'			Return _titleCache.textBoxdimension.x
		EndIf

		Local minTitleW:Int = 0
		If _minTitleDim Then minTitleW = _minTitleDim.GetIntX()

		If _maxTitleDim And _maxTitleDim.GetIntX() > 0
			local tWidth:Int = GetFontBold().GetBoxDimension(title, _maxTitleDim.GetIntX(), -1, titleDrawTextEffect.data, titleDrawTextSettings.data).x
			Return Min(Max(minTitleW, 1 + tWidth), _maxTitleDim.GetIntX())
		Else
			local tWidth:Int = GetFontBold().GetBoxDimension(title, -1, -1, titleDrawTextEffect.data, titleDrawTextSettings.data).x
			Return Max(minTitleW, 1 + tWidth)
		EndIf
	End Method


	Method GetStepProgress:Float()
		If _stepTime = -1 Then Return 0.0
		Return Float(Min(1.0, Max(0, Double(Time.MilliSecsLong() - _stepStartTime) / _stepTime)))
	End Method


	Method GetFont:TBitmapFont()
		If Not _useFont Then _useFont = GetBitmapFont("Default", 11)
		Return _useFont
	End Method


	Method GetFontBold:TBitmapFont()
		If Not _useFontBold Then _useFontBold = GetBitmapFont("Default", 11, BOLDFONT)
		Return _useFontBold
	End Method


	Method GetDwellTime:Int()
		If _lastTooltipActiveTime + sharedDwellTimeSkipTime > Time.MilliSecsLong()
			Return dwellTime
		EndIf
		Return dwellTime + sharedDwellTime
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

	Method IsFadingOut:Int()
		Return IsStep(STEP_FADING_OUT)
	End Method



	Method _DrawForeground:Int(x:Int, y:Int, w:Int, h:Int)
		If _customDrawForeground Then Return _customDrawForeground(Self, x, y, w, h)

		Local headerSize:Int = GetTitleHeight()

		_DrawHeader(x, y, w, headerSize)
		_DrawContent(x, y + headerSize, w, h - headerSize)
	End Method


	Method _DrawHeader:Int(x:Int, y:Int, w:Int, h:Int)
		If _customDrawHeader Then Return _customDrawHeader(Self, x, y, w, h)

		'caption
		If Not _titleCache Then _titleCache = New TBitmapFontText
		If _titleCache.HasCache()
			_titleCache.DrawCached(x,y)
		Else
			_titleCache.DrawBlock(GetFontBold(), title, x, y, w, h, sALIGN_LEFT_CENTER, titleColor, titleDrawTextEffect, titleDrawTextSettings)
		EndIf

		Return True
	End Method


	Method _DrawContent:Int(x:Int, y:Int, w:Int, h:Int)
		If _customDrawContent Then Return _customDrawContent(Self, x, y, w, h)
		If content = "" Then Return False

		If Not _contentCache Then _contentCache = New TBitmapFontText
		If _contentCache.HasCache()
			_contentCache.DrawCached(x,y)
		Else
			_contentCache.DrawBlock(GetFont(), content, x, y, GetContentWidth(), -1, sALIGN_LEFT_TOP, contentColor, contentDrawTextEffect, contentDrawTextSettings)
		EndIf

		Return True
	End Method


	Method _DrawBackground:Int(x:Int, y:Int, w:Int, h:Int)
		If _customDrawBackground Then Return _customDrawBackground(Self, x, y, w, h)

		Local oldCol:SColor8; GetColor(oldCol)
		Local oldA:Float = GetAlpha()

		'=== SHADOW ===
		SetColor 0, 0, 0
		SetAlpha oldA * 0.3
		DrawRect(x+2, y+2, w, h)

		SetAlpha oldA * 0.1
		DrawRect(x+1, y+1, w, h)

		'=== BORDER ===
		SetAlpha oldA
		SetColor 0,0,0
		DrawRect(x, y, w, h)
		SetColor 255,255,255

		'=== FILLING ===
		SetColor 255,255,255
		DrawRect(x+1, y+1, w-2, h-2)

		SetColor(oldCol)
		SetAlpha(oldA)

		Return True
	End Method


	Method Render:Int(xOffset:Int = 0, yOffset:Int=0)
		Rem
		DrawText(GetFadeProgress(), GetScreenRect().GetX() + xOffset,GetScreenRect().GetY() + yOffset + 50)
		DrawText("lifetime="+lifetime, GetScreenRect().GetX() + xOffset,GetScreenRect().GetY() + yOffset + 62)
		DrawText("fadeStartTime="+_fadeStartTime, GetScreenRect().GetX() + xOffset,GetScreenRect().GetY() + yOffset + 74)
		DrawText("hovered="+HasOption(OPTION_HOVERED), GetScreenRect().GetX() + xOffset,GetScreenRect().GetY() + yOffset + 86)
		DrawText("inactive="+HasOption(OPTION_INACTIVE), GetScreenRect().GetX() + xOffset,GetScreenRect().GetY() + yOffset + 98)
		DrawText("dwelling="+IsDwelling(), GetScreenRect().GetX() + xOffset,GetScreenRect().GetY() + yOffset + 110)
		endrem

		If HasOption(OPTION_DISABLED) Then Return False
		If Not IsStep(STEP_ACTIVE) And Not IsStep(STEP_FADING_OUT) Then Return False

		MoveToVisibleScreenArea()

		Local boxX:Int = GetScreenRect().GetX() + xOffset
		Local boxY:Int	= GetScreenRect().GetY() + yOffset
		Local boxWidth:Int = GetWidth()
		Local boxHeight:Int	= GetHeight()
		Local padding:TRectangle = GetContentPadding()

		Local oldColA:Float = GetAlpha()
		If IsFadingOut()
			'fade out a bit faster ... ^3
			SetAlpha oldColA * Float((1.0 - GetStepProgress())^2)
		EndIf

		_DrawBackground(boxX, boxY, boxWidth, boxHeight)
		_DrawForeground(boxX + Int(padding.GetLeft()), boxY + Int(padding.GetTop()), boxWidth - Int(padding.GetLeft() - padding.GetRight()), boxHeight - Int(padding.GetTop() - padding.GetBottom()))

		SetAlpha oldColA

		Return True
	End Method


	Method Update:Int()
		If HasOption(OPTION_DISABLED) Then Return False

		'=== ADJUST HOVER STATE ===
		Local isHovering:Int = False
		If HasOption(OPTION_MANUAL_HOVER_CHECK)
			If HasOption(OPTION_MANUALLY_HOVERED)
				isHovering = True
				onMouseOver()
			EndIf
		Else
			If parentArea And THelper.MouseInRect(parentArea)
				isHovering = True
				onMouseOver()
			EndIf
		EndIf
		If Not isHovering And HasOption(OPTION_HOVERED)
			onMouseOut()
		EndIf



		'=== ADJUST STEPS ====
		If IsStep(STEP_INACTIVE) And isHovering
			SetStep(STEP_DWELLING)
		EndIf

		If IsStep(STEP_DWELLING) And IsStepTimeGone()
			If isHovering Or HasOption(OPTION_HAS_LIFETIME)
				SetStep(STEP_ACTIVE)
			ElseIf Not isHovering
				SetStep(STEP_INACTIVE)
			EndIf
		EndIf

		If IsStep(STEP_ACTIVE)
			_lastTooltipActiveTime = Time.MilliSecsLong()

			If Not HasOption(OPTION_HAS_LIFETIME) And Not isHovering
				SetStep(STEP_FADING_OUT)
			ElseIf HasOption(OPTION_HAS_LIFETIME) And IsStepTimeGone()
				SetStep(STEP_FADING_OUT)
			EndIf
		EndIf

		If IsStep(STEP_FADING_OUT) And IsStepTimeGone()
			SetStep(STEP_INACTIVE)
		EndIf

		Return True
	End Method
End Type
