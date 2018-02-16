Rem
	====================================================================
	GUI Slider
	====================================================================

	Sliders are similar to SpinControls. Widgets easing a mouse
	controlled number selection. Also a visual representation.
	
	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2015 Ronny Otto, digidea.de

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
End Rem
SuperStrict
Import "base.gfx.gui.bmx"
Import "base.util.registry.spriteloader.bmx"




Type TGUISlider extends TGUIObject
	Field minValue:Double
	Field maxValue:Double
	Field valueType:int = 0
	'limit the "configurable" value range?
	Field limitValue:int = False
	Field limitMinValue:Double
	Field limitMaxValue:Double
	Field steps:int = 0 '<1 disables steps
	Field handleSpriteName:String = "gfx_gui_slider.handle"
	Field gaugeSpriteName:String = "gfx_gui_slider.gauge"
	Field gaugeFilledSpriteName:String = "gfx_gui_slider.gauge.filled"
	Field renderMode:int = 0
	Field direction:int = 0
	Field _gaugeSprite:TSprite
	Field _gaugeFilledSprite:TSprite
	Field _handleSprite:TSprite
	Field _handleDim:TVec2D = new TVec2D
	Field _gaugeOffset:TVec2D = new TVec2D.Init(3,3)
	Field _gaugeAlpha:Float = 1.0
	Field _showFilledGauge:int = True
	Const DIRECTION_RIGHT:int = 0
	Const DIRECTION_LEFT:int = 1 
	Const DIRECTION_UP:int = 2
	Const DIRECTION_DOWN:int = 3 
	
	Const RENDERMODE_CONTINUOUS:int = 0  ' [##########   ] - all in one
	Const RENDERMODE_DISCRETE:int = 1    ' [#][#][#][ ][ ] - in steps
	Const VALUETYPE_INTEGER:int = 0
	Const VALUETYPE_FLOAT:int = 1
	Const VALUETYPE_DOUBLE:int = 2

	Method Create:TGUISlider(pos:TVec2D, dimension:TVec2D, value:String, State:String = "")
		'setup base widget
		Super.CreateBase(pos, dimension, State)

		SetValue(value)

		'the scroller itself ignores focus too
		'self.setOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)

		_handleDim = new TVec2D.Init(min(rect.GetW(), rect.GetH()), min(rect.GetW(), rect.GetH()))

    	GUIManager.Add(Self)
		Return Self
	End Method


	Method SetMinValue(value:Double)
		minValue = value
	End Method


	Method SetMaxValue(value:Double)
		maxValue = value
	End Method


	Method SetValueRange(minValue:Double, maxValue:Double)
		SetMinValue(minValue)
		SetMaxValue(maxValue)
	End Method


	Method SetLimitMinValue(value:Double)
		limitValue = true
		limitMinValue = value
	End Method


	Method SetLimitMaxValue(value:Double)
		limitValue = true
		limitMaxValue = value
	End Method


	Method SetLimitValueRange(minValue:Double, maxValue:Double)
		SetLimitMinValue(minValue)
		SetLimitMaxValue(maxValue)
	End Method


	Method DisableLimitValue()
		limitValue = False
	End Method


	Method GetLimitMaxValue:Double()
		if not limitValue then return maxValue
		return limitMaxValue
	End Method


	Method GetLimitMinValue:Double()
		if not limitValue then return minValue
		return limitMinValue
	End Method
	

	Method GetCurrentValue:Double()
		'this rounds to "int/float/double" before! - according to type
		'settings
		return Double(GetValue())
	End Method


	Method GetRelativeValue:Float()
		return Min(1.0, Max(0.0, GetCurrentValue() / (maxValue - minValue)))
	End Method


	Method SetRelativeValue:Double(percentage:Float)
'		SetValue(percentage * (maxValue - minValue + 1))
		SetValue(percentage * (maxValue - minValue))
		return GetCurrentValue()
	End Method
		

	'override default
	Method SetValue(newValue:string)
		local newValueD:Double = Max(minValue, Min(maxValue, Double(newValue)))
		if steps > 0
			local length:Double = (maxValue - minValue)
			local stepSize:Double = length / steps
			'math. rounding
			'newValueD = ceil(stepSize * (newValueD / length) - 0.5)
			'step rounding
			'newValueD = stepSize * ceil(stepSize * (newValueD / length) -0.5)
			newValueD = Ceil(newValueD / stepSize - 0.5) * stepSize
		endif

		'clamp value by potential limitations
		if limitValue then newValueD = Max(limitMinValue, Min(newValueD, limitMaxValue))
		
		'only adjust when different
		if value <> string(newValueD)
			value = newValueD
			EventManager.triggerEvent( TEventSimple.Create( "guiobject.onChangeValue", null, self ) )
		endif
	End Method


	'override default - to use type specific return value
	Method GetValue:String()
		Select valueType
			case VALUETYPE_INTEGER
				return int(value)
			case VALUETYPE_FLOAT
				return float(value)
			default
				return double(value)
		End Select
	End Method


	Method SetValueByMouse()
		'convert current mouse position to local widget coordinates
		'-9 is "manual adjustment"
		local mousePos:TVec2D = New TVec2D.Init(..
									MouseManager.x - GetScreenX() - GetGaugeOffsetX(), ..
									MouseManager.y - GetScreenY() - GetGaugeOffsetY() ..
								)

		local scale:Float = (maxValue - minValue + 1) / Float(maxValue - minValue)
		local lengthX:float = GetGaugeW() - 2* GetGaugeOffsetX()
		'scroll to the percentage
		Select direction
			case DIRECTION_RIGHT
				if steps > 0 then mousePos.x :- 0.5 *(GetGaugeW() / float(steps+1))
				SetRelativeValue( Max(0.0, scale * Min(1.0, mousePos.x/lengthX)) )
				'SetRelativeValue( Max(0.0, scale * Min(1.0, (mousePos.x) / GetGaugeW())) )
			case DIRECTION_LEFT
				if steps > 0 then mousePos.x :+ 0.5 *(GetGaugeW() / float(steps+1))
				SetRelativeValue( Max(0.0, scale * Min(1.0, 1.0 - mousePos.x/lengthX)) )
			case DIRECTION_UP
				SetRelativeValue( Max(0.0, scale * Min(1.0, 1.0 - (mousePos.y) / GetGaugeH())) )
			case DIRECTION_DOWN
				SetRelativeValue( Max(0.0, scale * Min(1.0, (mousePos.y) / GetGaugeH())) )
		End Select

		EventManager.triggerEvent( TEventSimple.Create( "guislider.setValueByMouse", null, self ) )
	End Method


	Method SetRenderMode(renderMode:int = 0)
		self.renderMode = renderMode
	End Method


	Method SetDirection(direction:int = 0)
		self.direction = direction
	End Method


	'acts as cache
	Method GetHandleSprite:TSprite()
		'refresh cache if not set or wrong sprite name
		if not _handleSprite or _handleSprite.GetName() <> handleSpriteName
			_handleSprite = GetSpriteFromRegistry(handleSpriteName)
			'new -non default- sprite: adjust appearance
			if _handleSprite.GetName() <> "defaultsprite"
				SetAppearanceChanged(TRUE)
			endif
		endif
		return _handleSprite
	End Method


	Method GetHandleSpriteName:String()
		return handleSpriteName
	End Method


	'acts as cache
	Method GetGaugeSprite:TSprite()
		'refresh cache if not set or wrong sprite name
		if not _gaugeSprite or _gaugeSprite.GetName() <> gaugeSpriteName
			_gaugeSprite = GetSpriteFromRegistry(gaugeSpriteName)
			'new -non default- sprite: adjust appearance
			if _gaugeSprite.GetName() <> "defaultsprite"
				SetAppearanceChanged(TRUE)
			endif
		endif
		return _gaugeSprite
	End Method


	Method GetGaugeSpriteName:String()
		return gaugeSpriteName
	End Method


	Method GetGaugeFilledSpriteName:String()
		return gaugeFilledSpriteName
	End Method


	'acts as cache
	Method GetGaugeFilledSprite:TSprite()
		'refresh cache if not set or wrong sprite name
		if not _gaugeFilledSprite or _gaugeFilledSprite.GetName() <> gaugeFilledSpriteName
			_gaugeFilledSprite = GetSpriteFromRegistry(gaugeFilledSpriteName)
			'new -non default- sprite: adjust appearance
			if _gaugeFilledSprite.GetName() <> "defaultsprite"
				SetAppearanceChanged(TRUE)
			endif
		endif
		return _gaugeFilledSprite
	End Method


	Method GetGaugeW:int()
		return rect.GetW() - GetGaugeOffsetX()*2
	End Method


	Method GetGaugeH:int()
		return rect.GetH() - GetGaugeOffsetY()*2
	End Method


	Method GetGaugeOffsetX:int()
		return _gaugeOffset.x
	End Method
	

	Method GetGaugeOffsetY:int()
		return _gaugeOffset.y
	End Method


	Method GetCurrentStep:int()
		return floor(GetRelativeValue()*steps)
	End Method


	Method onClick:Int(triggerEvent:TEventBase)
		'only if left button was used
		if triggerEvent.GetData().GetInt("button",0) <> 1 then return False
		
		'only if not already handling the same situation with mouseDown
		if not MouseIsDown Then SetValueByMouse

		return Super.onClick(triggerEvent)
	End Method


	'override to update caption
	Method Update:int()
		Super.Update()

		'adjust value
		if MouseIsDown and hasFocus() Then SetValueByMouse()

		'process long clicks to avoid odd "right click behaviour"
		if hasFocus() and MouseManager.IsLongClicked(1)
			MouseManager.ResetKey(1)
		endif
	End Method	


	'draw background element
	Method DrawGauge(position:TVec2D)
		local switchDirection:int = 0

		if (direction = DIRECTION_LEFT) ..
		   or (direction = DIRECTION_UP) ..
		   or (direction = DIRECTION_DOWN and renderMode = RENDERMODE_DISCRETE) ..
		   or (direction = DIRECTION_RIGHT and renderMode = RENDERMODE_DISCRETE)

			switchDirection = 1
		endif

		'NEW
		switchDirection = (direction & (DIRECTION_LEFT | DIRECTION_UP) > 0)


		Select direction
			case DIRECTION_LEFT
				DrawGaugeHorizontal(position, True)
			case DIRECTION_RIGHT
				DrawGaugeHorizontal(position, False)
			case DIRECTION_UP
				DrawGaugeVertical(position, True)
			case DIRECTION_DOWN
				DrawGaugeVertical(position, False)
		End Select
	End Method


	Method DrawGaugeHorizontal(position:TVec2D, switchDirection:int = 0)
		Local gaugeSprite:TSprite = GetGaugeSprite()
		Local gaugeFilledSprite:TSprite

		if _showFilledGauge
			gaugeFilledSprite = GetGaugeFilledSprite()
			'assign default gauge sprite if no "filled" is defined
			if gaugeSprite and (not gaugeFilledSprite or gaugeFilledSprite.GetName()) = "defaultsprite"
				gaugeFilledSprite = gaugeSprite
			endif
		else
			gaugeFilledSprite = gaugeSprite
		endif


		local w:int = GetGaugeW()
		local filledW:int = Min(1.0, GetRelativeValue()) * w
		if steps > 0
			'         (   current step  +0.5) * (     stepSize     )
			filledW = (GetCurrentStep() +0.5) * (w / float(steps+1))
		endif

		if switchDirection then filledW = w - filledW

		Select renderMode
			case RENDERMODE_CONTINUOUS
				'draw full "filled"
				if steps = 0 and GetRelativeValue() >= 1.0
					gaugeFilledSprite.DrawArea(position.getX() + GetGaugeOffsetX(), position.getY() + GetGaugeOffsetY(), filledW, GetGaugeH())
				'draw full "unfilled"
				elseif steps = 0 and GetRelativeValue() <= 0.0
					gaugeSprite.DrawArea(position.getX() + GetGaugeOffsetX(), position.getY() + GetGaugeOffsetY() , w, GetGaugeH())
				else
					'filled one
					if filledW > 0
						if switchDirection
							gaugeSprite.DrawArea(position.getX() + GetGaugeOffsetX(), position.getY() + GetGaugeOffsetY(), filledW, GetGaugeH(), -1, TSprite.BORDER_RIGHT)
						else
							gaugeFilledSprite.DrawArea(position.getX() + GetGaugeOffsetX(), position.getY() + GetGaugeOffsetY(), filledW - gaugeFilledSprite.GetNinePatchBorderDimension().GetRight(), GetGaugeH(), -1, TSprite.BORDER_RIGHT)
						endif
					endif

					'unfilled portion
					if w - filledW > gaugeSprite.GetMinWidth() - _handleDim.x
						if switchDirection
							gaugeFilledSprite.DrawArea(position.getX() + GetGaugeOffsetX() + Min(filledW, w-gaugeSprite.GetMinWidth()), position.getY() + GetGaugeOffsetY() , Max(w-filledW,gaugeSprite.GetMinWidth()) , GetGaugeH(), -1, TSprite.BORDER_LEFT)
						else
							gaugeSprite.DrawArea(position.getX() + GetGaugeOffsetX() + Min(filledW, w-gaugeSprite.GetMinWidth()), position.getY() + GetGaugeOffsetY() , Max(w-filledW,gaugeSprite.GetMinWidth()) , GetGaugeH(), -1, TSprite.BORDER_LEFT)
						endif
					endif
				endif

			case RENDERMODE_DISCRETE
				local stepW:int = w / float(steps+1)
				local stepX:int = position.getX() + GetGaugeOffsetX() + GetGaugeOffsetY()*0.5

				'switch starting position and grow direction
				if switchDirection
					stepX :+ GetGaugeW() - _handleDim.x
					stepX :+ 1
					stepW :* -1
				endif

				'draw each step on its own
				for local i:int = 0 to steps
					'unfilled/unreached values
					if GetRelativeValue() <= i/float(steps) +0.05
						gaugeSprite.DrawArea(stepX, position.getY() + GetGaugeOffsetY(), Abs(stepW) - GetGaugeOffsetY()*0.5, GetGaugeH())
					'filled/reached values
					else
						gaugeFilledSprite.DrawArea(stepX, position.getY() + GetGaugeOffsetY(), Abs(stepW) - GetGaugeOffsetY()*0.5, GetGaugeH())
					endif
					'DrawText(Left(i/float(steps), 4), stepX, position.getY() + GetGaugeOffsetY())
					stepX :+ stepW
				Next
		End Select
	End Method


	Method DrawGaugeVertical(position:TVec2D, switchDirection:int = 0)
		Local gaugeSprite:TSprite = GetGaugeSprite()
		Local gaugeFilledSprite:TSprite

		if _showFilledGauge
			gaugeFilledSprite = GetGaugeFilledSprite()
			'assign default gauge sprite if no "filled" is defined
			if gaugeSprite and (not gaugeFilledSprite or gaugeFilledSprite.GetName()) = "defaultsprite"
				gaugeFilledSprite = gaugeSprite
			endif
		else
			gaugeFilledSprite = gaugeSprite
		endif


		local h:int = GetGaugeH()
		local filledH:int = Min(1.0, GetRelativeValue()) * h
		if steps > 0
			'         (   current step  +0.5) * (     stepSize     )
			filledH = (GetCurrentStep() +0.5) * (h / float(steps+1))
		endif

		if switchDirection and GetRelativeValue() < 1.0 then filledH = h - filledH


		Select renderMode
			case RENDERMODE_CONTINUOUS
				'draw full "filled"
				if steps = 0 and GetRelativeValue() >= 1.0
					gaugeFilledSprite.DrawArea(position.getX() + GetGaugeOffsetX(), position.getY() + GetGaugeOffsetY(), GetGaugeW(), filledH)
				'draw full "unfilled"
				elseif steps = 0 and GetRelativeValue() <= 0.0
					gaugeSprite.DrawArea(position.getX() + GetGaugeOffsetX(), position.getY() + GetGaugeOffsetY(), GetGaugeW(), h)
				else
					'filled one
					if filledH > 0
						if switchDirection
							gaugeSprite.DrawArea(position.getX() + GetGaugeOffsetX(), position.getY() + GetGaugeOffsetY(), GetGaugeW(), filledH, -1, TSprite.BORDER_BOTTOM)
						else
							gaugeFilledSprite.DrawArea(position.getX() + GetGaugeOffsetX(), position.getY() + GetGaugeOffsetY(), GetGaugeW(), Min(filledH, h - 1.5*gaugeSprite.GetMinHeight()), -1, TSprite.BORDER_BOTTOM)
						endif
					endif

					'unfilled portion
					if h - filledH > gaugeSprite.GetMinHeight() - _handleDim.y
						if switchDirection
							gaugeFilledSprite.DrawArea(position.getX() + GetGaugeOffsetX(), position.getY() + GetGaugeOffsetY() + Min(filledH, h - gaugeSprite.GetMinHeight()), GetGaugeW(), Max(h - filledH, gaugeSprite.GetMinHeight()), -1, TSprite.BORDER_TOP)
						else
							gaugeSprite.DrawArea(position.getX() + GetGaugeOffsetX(), position.getY() + GetGaugeOffsetY() + Min(filledH, h - gaugeSprite.GetMinHeight()), GetGaugeW(), Max(h - filledH, gaugeSprite.GetMinHeight()), -1, TSprite.BORDER_TOP)
						endif
					endif
				endif

			case RENDERMODE_DISCRETE
				local stepH:int = h / float(steps+1)
				local stepY:int = position.getY() + GetGaugeOffsetY() + GetGaugeOffsetX()*0.5

				'switch starting position and grow direction
				if switchDirection
					stepY :+ GetGaugeH() - _handleDim.y
					stepY :+ 1
					stepH :* -1
				endif

				'draw each step on its own
				for local i:int = 0 to steps
					'unfilled/unreached values
					if GetRelativeValue() <= i/float(steps) +0.05
						gaugeSprite.DrawArea(position.GetX() + GetGaugeOffsetX(), stepY, GetGaugeW(), Abs(stepH) - GetGaugeOffsetX()*0.5)
					'filled/reached values
					else
						gaugeFilledSprite.DrawArea(position.getX() + GetGaugeOffsetX(), stepY, GetGaugeW(), Abs(stepH) - GetGaugeOffsetX()*0.5)
					endif
					stepY :+ stepH
				Next
		End Select
	End Method


	'draw foreground element
	Method DrawHandle(position:TVec2D)
		local state:string = ""
		if MouseIsDown then state = ".active"
		
		Local sprite:TSprite = GetHandleSprite()
		if state <> "" then sprite = GetSpriteFromRegistry(GetHandleSpriteName() + state, sprite)
		if sprite
			Select direction
				case DIRECTION_RIGHT, DIRECTION_LEFT
					local offsetX:int
					if steps > 0
						'         (        steps gone           ) * (    px-width per step   )
						offsetX = int(steps * GetRelativeValue()) * floor(GetGaugeW()/float(steps+1))
						'center the handle on the step:  0.5 (stepW - handleW)
						offsetX :+ ceil( 0.5*(floor(GetGaugeW() / float(steps+1)) - _handleDim.x))
					else
						'subtract half of the handle to center the handle   
						offsetX = GetRelativeValue() * GetGaugeW() - 0.5*_handleDim.x

						'but limit start and end
						offsetX = Max(0, Min(offsetX, GetGaugeW()-_handleDim.x))
					endif
					'switch direction?
					if direction = DIRECTION_LEFT then offsetX = GetGaugeW() - offsetX - _handleDim.x

					sprite.DrawArea(position.getX() + GetGaugeOffsetX() + offsetX, position.getY(), _handleDim.x, _handleDim.y)

				case DIRECTION_UP, DIRECTION_DOWN
					local offsetY:int
					if steps > 0
'						offsetY = int(steps * GetRelativeValue()) * (GetGaugeH()/float(steps+1))
						'         ( steps gone   ) * (    px- per step          )
						offsetY = GetCurrentStep() * floor(GetGaugeH()/float(steps+1))

						'center the handle on the step:  0.5 (stepW - handleW)
						offsetY :+ ceil( 0.5 *(floor(GetGaugeH() / float(steps+1)) - _handleDim.y))
					else
						offsetY = GetRelativeValue() * (GetGaugeH() - _handleDim.y)

						'but limit start and end
						offsetY = Max(0, Min(offsetY, GetGaugeH()-_handleDim.y))
					endif
					'switch direction?
					if direction = DIRECTION_UP then offsetY = GetGaugeH() - offsetY - _handleDim.y

					sprite.DrawArea(position.getX(), position.getY() + GetGaugeOffsetY() + offsetY, _handleDim.x, _handleDim.y)
			End Select
		endif
	End Method


	Method DrawContent()
		Local atPoint:TVec2D = GetScreenPos()
		Local oldCol:TColor = new TColor.Get()

		SetColor 255, 255, 255
		SetAlpha oldCol.a * GetScreenAlpha() * _gaugeAlpha
		DrawGauge(atPoint)
		SetAlpha oldCol.a * GetScreenAlpha()
		DrawHandle(atPoint)

		rem
		?debug
		SetColor 0,0,0
		DrawRect(GetScreenX()+40, GetScreenY(), 100,20)
		SetAlpha 1.0
		SetColor 255,255,255
		DrawText(GetValue()+" : " + Left(value, 6), GetScreenX()+42, GetScreenY()+2)
		?
		endrem
		oldCol.SetRGBA()
	End Method
End Type