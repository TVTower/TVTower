Rem
	===========================================================
	GUI Textbox
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"



Type TGUITextBox Extends TGUIobject
	Field valueAlignment:TPoint = new TPoint.Init(0,0)
	Field valueColor:TColor	= TColor.Create(0,0,0)
	Field valueStyle:Int = 0 'used in DrawBlock(...style)
	Field valueStyleSpecial:Float = 1.0	 'used in DrawBlock(...special)
	Field _autoAdjustHeight:Int	= False


	Method Create:TGUITextBox(position:TPoint = null, dimension:TPoint = null, text:String, limitState:String="")
		Super.CreateBase(position, dimension, limitState)

		SetValue(text)

		GUIManager.Add(Self)
		Return Self
	End Method


	Method SetAutoAdjustHeight(bool:Int=True)
		_autoAdjustHeight = bool
	End Method


	Method GetHeight:Int(maxHeight:Int=800)
		If _autoAdjustHeight
			Return Min(maxHeight, GetFont().drawBlock(value, GetScreenX(), GetScreenY(), rect.GetW(), maxHeight, valueAlignment, Null, 1, 0).getY())
		Else
			Return rect.GetH()
		EndIf
	End Method


	Method SetValue(value:string)
		self.value = value
	End Method


	Method SetValueColor(color:TColor)
		valueColor = color
	End Method


	Method SetValuePosition:Int(valueLeft:Float=0.0, valueTop:Float=0.0)
		rect.position.SetXY(valueLeft, valueTop)
	End Method


	Method SetValueAlignment(align:String="", valign:String="")
		Select align.ToUpper()
			Case "LEFT" 	valueAlignment.SetX(ALIGN_LEFT)
			Case "CENTER" 	valueAlignment.SetX(ALIGN_CENTER)
			Case "RIGHT" 	valueAlignment.SetX(ALIGN_RIGHT)

			Default	 		valueAlignment.SetX(ALIGN_LEFT)
		End Select

		Select valign.ToUpper()
			Case "TOP" 		valueAlignment.SetY(ALIGN_TOP)
			Case "CENTER" 	valueAlignment.SetY(ALIGN_CENTER)
			Case "BOTTOM" 	valueAlignment.SetY(ALIGN_BOTTOM)

			Default	 		valueAlignment.SetY(ALIGN_TOP)
		End Select
	End Method


	Method Draw:Int()
		Local drawPos:TPoint = new TPoint.Init(GetScreenX(), GetScreenY())
		GetFont().drawBlock(value, drawPos.GetIntX(), drawPos.GetIntY(), rect.GetW(), rect.GetH(), valueAlignment, valueColor, 1, 1, 0.25)
	End Method
End Type
