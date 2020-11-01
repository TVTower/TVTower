Rem
	===========================================================
	GUI Textbox
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"



Type TGUITextBox Extends TGUIobject
	Field valueAlignment:SVec2F = New SVec2F(0,0)
	Field valueColor:SColor8 = SColor8.Black
	Field valueEffect:TDrawTextEffect
	Field _autoAdjustHeight:Int	= False


	Method GetClassName:String()
		Return "tguitextbox"
	End Method


	Method Create:TGUITextBox(position:TVec2D = null, dimension:TVec2D = null, text:String, limitState:String="")
		Super.CreateBase(position, dimension, limitState)

		SetValue(text)

		GUIManager.Add(Self)
		Return Self
	End Method


	Method SetAutoAdjustHeight(bool:Int=True)
		_autoAdjustHeight = bool
	End Method


	Method GetHeightWithMax:Int(maxHeight:Int=800)
		If _autoAdjustHeight
			Return Min(maxHeight, GetFont().GetBoxHeight(value, int(rect.GetW()), maxHeight))
		Else
			Return rect.GetH()
		EndIf
	End Method


	Method SetValueColor(color:TColor)
		if color 
			valueColor = color.ToSColor8()
		else
			valueColor = SColor8.Black
		endif
	End Method

	Method SetValueColor(color:SColor8)
		valueColor = color
	End Method


	Method SetValuePosition:Int(valueLeft:Float=0.0, valueTop:Float=0.0)
		rect.position.SetXY(valueLeft, valueTop)
	End Method


	Method SetValueAlignment(alignment:TVec2D)
		valueAlignment = new SVec2F(alignment.x, alignment.y)
	End Method


	Method SetValueAlignment(alignment:SVec2F)
		valueAlignment = alignment
	End Method


	Method DrawContent()
		local oldCol:TColor = new TColor.Get()
		SetAlpha oldCol.a * GetScreenAlpha()
		
		Local scrRect:TRectangle = GetScreenRect()

		GetFont().DrawBox(value, scrRect.GetIntX(), scrRect.GetIntY(), rect.GetW(), rect.GetH(), valueAlignment, valueColor, EDrawTextEffect.Shadow, 0.25)

		oldCol.SetRGBA()
	End Method


	Method UpdateLayout()
	End Method
End Type
