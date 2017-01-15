Rem
	===========================================================
	GUI Textbox
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"



Type TGUITextBox Extends TGUIobject
	Field valueAlignment:TVec2D = new TVec2D.Init(0,0)
	Field valueColor:TColor	= TColor.Create(0,0,0)
	Field valueStyle:Int = 0 'used in DrawBlock(...style)
	Field valueStyleSpecial:Float = 1.0	 'used in DrawBlock(...special)
	Field _autoAdjustHeight:Int	= False


	Method Create:TGUITextBox(position:TVec2D = null, dimension:TVec2D = null, text:String, limitState:String="")
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
			Return Min(maxHeight, GetFont().getBlockHeight(value, rect.GetW(), maxHeight))
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


	Method SetValueAlignment(alignment:TVec2D)
		valueAlignment = alignment
	End Method


	Method DrawContent()
		local oldCol:TColor = new TColor.Get()
		SetAlpha oldCol.a * GetScreenAlpha()

		GetFont().drawBlock(value, int(GetScreenX()), int(GetScreenY()), rect.GetW(), rect.GetH(), valueAlignment, valueColor, 1, 1, 0.25)

		oldCol.SetRGBA()
	End Method
End Type
