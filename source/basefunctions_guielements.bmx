SuperStrict
'Author: Ronny Otto
Import "basefunctions.bmx"
Import "basefunctions_sprites.bmx"
Import "basefunctions_keymanager.bmx"
Import "basefunctions_localization.bmx"
Import "basefunctions_resourcemanager.bmx"
Import "basefunctions_events.bmx"


''''''GUIzeugs'
CONST EVENT_CLICK:int		= 1
CONST EVENT_DOUBLECLICK:int = 2

Global gfx_GuiPack:TGW_SpritePack = TGW_SpritePack.Create(LoadImage("grafiken/GUI/guipack.png"), "guipack_pack")
gfx_GuiPack.AddAnimSpriteMultiCol("Input", 290, 30, 204, 27, 34, 27, 6)
gfx_GuiPack.AddAnimSpriteMultiCol("ListControl", 96, 0, 56, 28, 14, 14, 8)
gfx_GuiPack.AddAnimSpriteMultiCol("DropDown", 160, 0, 126, 42, 14, 14, 21)
gfx_GuiPack.AddSprite("Slider", 0, 30, 112, 14, 8)
gfx_GuiPack.AddSprite("Chat_IngameOverlay", 0, 60, 504, 20)
gfx_GuiPack.AddSprite("Chat_Top", 0, 80, 445, 20)
gfx_GuiPack.AddSprite("Chat_Middle", 0, 100, 445, 50)
gfx_GuiPack.AddSprite("Chat_Bottom", 0, 142, 445, 35)
gfx_GuiPack.AddSprite("Chat_Input", 0, 186, 445, 35)

For Local i:Int = 0 To 255
  KEYWRAPPER.allowKey(i,KEYWRAP_ALLOW_BOTH,600,200)
Next

Type TGUIManager
	Field Defaultfont:TBitmapFont
	Field GUIobjectactive:Int
	Field LastGuiID:Int 		= 0
	Field globalScale:Float		= 1.0
	Field MouseIsHit:Int 		= 0
	Field List:TList = CreateList()

	Function Create:TGUIManager()
		Local obj:TGUIManager = New TGUIManager
		Return obj
	End Function

	Method Add(GUIobject:TGUIobject)
		Self.List.AddLast(GUIobject)
		Self.list.sort(True, Self.SortObjects)
	End Method

	Function SortObjects:Int(ob1:Object, ob2:Object)
		Local objA:TGUIobject = TGUIobject(ob1)
		Local objB:TGUIobject = TGUIobject(ob2)

		If Not objB Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
		If GUIManager.getActive() = objB.uid Return - 1 Else Return 1
		If objB._visible = 0
			If objB.Zindex <= objA.ZIndex
				Return 0
			Else
				Return -1
			EndIf
		EndIf
		If objB.ZIndex <= objA.ZIndex Then	Return 1 Else Return 0
	End Function

	Method isActive:Int(uid:Int)
		Return uid = Self.GUIobjectactive
	End Method

	Method getActive:Int()
		Return Self.GUIobjectactive
	End Method


	Method setActive(uid:Int)
		Self.GUIobjectactive = uid
	End Method

	Method Remove(guiobject:TGUIObject)
		Self.List.remove(guiobject)
	End Method


	Method Update(State:String = "", updatelanguage:Int = 0, fromZ:Int=-1000, toZ:Int=-1000)
		If Not List Return                           'aufhoeren wenn keine Liste vorhanden
		List.Sort()
		If MOUSEMANAGER.IsHit(1) Then MouseIsHit = 1 Else MouseIsHit = 0
		For Local GUIobject:TGUIobject = EachIn Self.List 'Liste hier global
			If (toZ = -1000 Or guiobject.zIndex <= toZ) And (fromZ = -1000 Or guiobject.zIndex >= fromZ)
				If guiobject._visible = 1 And (State = guiobject.forstateonly Or State = "")
					If guiobject.clickable
						If State <> guiobject.forstateonly Or Not functions.isIn( MouseX(), MouseY(), guiobject.pos.x, guiobject.pos.y, guiobject.dimension.x, guiobject.dimension.y )
							guiobject.mouseIsDown = null
							guiobject.clicked = null
							guiobject.mouseover = 0
							guiobject.setState("")
							If MouseIsHit And Self.getActive() = guiobject.uid Then Self.setActive(0)
					   EndIf
					   If guiobject.typ <> "background" And functions.isIn(MouseX(), MouseY(), guiobject.pos.x, guiobject.pos.y, guiobject.dimension.x, guiobject.dimension.y)
							If MOUSEMANAGER.IsDown(1) And guiobject._enabled
								Self.setActive(guiobject.uid)
								guiobject.EnterPressed = 1
								guiobject.MouseIsDown = TPosition.Create( MouseX(), MouseY() )
							EndIf
							guiobject.mouseover = 1

							If guiobject.clickable And guiobject._enabled
								If MOUSEMANAGER.isDown(1) Or guiobject.MouseIsDown Then guiobject.setState("active") Else guiobject.setState("hover")

								If MOUSEMANAGER.isUp(1) And guiobject.MouseIsDown
									guiobject.Clicked = TPosition.Create( MouseX(), MouseY() )
									'fire onClickEvent
									If guiobject._enabled
										EventManager.registerEvent( TEventSimple.Create( "guiobject.OnClick", TEventData.Create().AddNumber("type", 1), guiobject ) )
									EndIf
									guiobject.MouseIsDown = null 'added for imagebutton and arrowbutton not being reset when mouse standing still
								EndIf
							EndIf
						EndIf
					EndIf
					If guiobject.value = "" Then guiobject.value = "  "
					If guiobject.backupvalue = "x" Then guiobject.backupvalue = guiobject.value
					If updatelanguage Or Chr(guiobject.value[0] ) = "_" Then If Chr(guiobject.backupvalue[0] ) = "_" Then guiobject.value = Localization.GetString(Right(guiobject.backupvalue, Len(guiobject.backupvalue) - 1))

					EventManager.registerEvent( TEventSimple.Create( "guiobject.onUpdate", null, guiobject ) )
					guiobject.Update()
				EndIf 'forstateonly
			EndIf
		Next
	End Method

	Method DisplaceGUIobjects(State:String = "", x:Int = 0, y:Int = 0)
    	If Not List Return                           'aufhoeren wenn keine Liste vorhanden
		For Local GUIobject:TGUIobject = EachIn Self.List 'Liste hier global
			If State = guiobject.forstateonly
				guiobject.pos.x:+x
				guiobject.pos.y:+y
			EndIf 'forstateonly
		Next
	End Method

	Method Draw:Int(State:String = "", updatelanguage:Int = 0, fromZ:Int=-1000, toZ:Int=-1000)
		If Not List Return False	'aufhoeren wenn keine Liste vorhanden
		'Self.oldfont = GetImageFont()
		'Local myoldfont:TImageFont = Self.oldfont

		For Local GUIobject:TGUIobject = EachIn Self.List 'Liste hier global
			If (toZ = -1000 Or guiobject.zIndex <= toZ) And (fromZ = -1000 Or guiobject.zIndex >= fromZ)
				If State = guiobject.forstateonly
					'If guiobject.enabled = 0 Return
					If guiobject._visible = 1
						'If GuiObject.UseFont <> Null Then SetImageFont guiobject.UseFont Else SetImageFont Self.Defaultfont
						If guiobject.value = "" Then guiobject.value = "  "
						If guiobject.backupvalue = "x" Then guiobject.backupvalue = guiobject.value
						If updatelanguage Or Chr(guiobject.value[0] ) = "_" Then If Chr(guiobject.backupvalue[0] ) = "_" Then guiobject.value = Localization.GetString(Right(guiobject.backupvalue, Len(guiobject.backupvalue) - 1))
						GUIobject.Draw()
					EndIf
				EndIf 'forstateonly
			EndIf
		Next
		'SetImageFont myoldfont
	End Method

End Type

Global GUIManager:TGUIManager = TGUIManager.Create()


Type TGUIobject
	Field pos:TPosition				= TPosition.Create(-1,-1)
	Field dimension:TPosition		= TPosition.Create(-1,-1)
	Field scale:Float				= 1.0
	Field align:Int					= 0 			'alignment of object
	Field state:String				= ""
	Field value:String				= ""
	Field backupvalue:String		= "x"
	Field clicked:TPosition			= null			'null = not clicked
	Field mouseIsDown:TPosition		= TPosition.Create(-1,-1)
	Field ParentGUIObject:TGUIobject = Null
	Field zIndex:Int
	Field EnterPressed:Int=0
	Field uid:Int
	Field on:Int
	Field typ:String
	Field _enabled:Int = 1
	Field _visible:Int = 1
	Field clickable:Int=1
	Field mouseover:Int = 0			'could be done with TPosition
	Field forstateonly:String = "" 'fuer welchen gamestate anzeigen
	Field useFont:TBitmapFont' = SmallImageFont
	Field grayedout:Int = 0


	Method BaseInit(useFont:TBitmapFont=Null)
		If useFont = Null Then Self.useFont = GUIManager.defaultFont Else Self.useFont = useFont
	End Method

	Function GetNewID:Int()
		GUIManager.LastGuiID:+1
		Return GUIManager.LastGuiID
	End Function

	Method GetClicks:Int()
		If Self.grayedout Then Self.Clicked = null

		if self.clicked
			self.clicked = null
			return 1
		else
			return 0
		endif
	End Method

	Method Draw() Abstract
	Method Update() Abstract

	Method Show()
		Self._visible = 1
	End Method

	Method Hide()
		Self._visible = 0
	End Method

	Method enable()
		self._enabled = 1
		GUIManager.list.sort()
	End Method

	Method disable()
		self._enabled = 0
		GUIManager.list.sort()
	End Method

	Method SetZIndex(zindex:Int)
		Self.zIndex = zindex
		GUIManager.list.sort()
	End Method

	Method SetState(state:String="")
		If state <> "" Then state = "."+state
		Self.state = state
	End Method

	Method Input2Value:String(value$)
		Local shiftPressed:Int = False
		Local altGrPressed:Int = False
		?win32
		If KEYMANAGER.IsDown(160) Or KEYMANAGER.IsDown(161) Then shiftPressed = True
		If KEYMANAGER.IsDown(164) Or KEYMANAGER.IsDown(165) Then altGrPressed = True
		?
		?Not win32
		If KEYMANAGER.IsDown(160) Or KEYMANAGER.IsDown(161) Then shiftPressed = True
		If KEYMANAGER.IsDown(3) Then altGrPressed = True
		?

		Local charToAdd:String = ""
		For Local i:Int = 65 To 90
			charToAdd = ""
			If KEYWRAPPER.pressedKey(i)
				If i = 69 And altGrPressed Then charToAdd = "€"
				If i = 81 And altGrPressed Then charToAdd = "@"
				If shiftPressed Then charToAdd = Chr(i) Else charToAdd = Chr(i+32)
			EndIf
			value :+ charToAdd
		Next

        If KEYWRAPPER.pressedKey(186) If shiftPressed Then value:+ "Ü" Else value :+ "ü"
        If KEYWRAPPER.pressedKey(192) If shiftPressed Then value:+ "Ö" Else value :+ "ö"
        If KEYWRAPPER.pressedKey(222) If shiftPressed Then value:+ "Ä" Else value :+ "ä"

        If KEYWRAPPER.pressedKey(48)  If shiftPressed Then value :+ "=" Else value :+ "0"
        If KEYWRAPPER.pressedKey(49)  If shiftPressed Then value :+ "!" Else value :+ "1"
        If KEYWRAPPER.pressedKey(50)  If shiftPressed Then value :+ Chr(34) Else value :+ "2"
        If KEYWRAPPER.pressedKey(51)  If shiftPressed Then value :+ "§" Else value :+ "3"
        If KEYWRAPPER.pressedKey(52)  If shiftPressed Then value :+ "$" Else value :+ "4"
        If KEYWRAPPER.pressedKey(53)  If shiftPressed Then value :+ "%" Else value :+ "5"
        If KEYWRAPPER.pressedKey(54)  If shiftPressed Then value :+ "&" Else value :+ "6"
        If KEYWRAPPER.pressedKey(55)  If shiftPressed Then value :+ "/" Else value :+ "7"
        If KEYWRAPPER.pressedKey(56)  If shiftPressed Then value :+ "(" Else value :+ "8"
        If KEYWRAPPER.pressedKey(57)  If shiftPressed Then value :+ ")" Else value :+ "9"
        If KEYWRAPPER.pressedKey(219) And shiftPressed Then value :+ "?"
        If KEYWRAPPER.pressedKey(219) And altGrPressed Then value :+ "\"
        If KEYWRAPPER.pressedKey(219) And Not altGrPressed And Not shiftPressed Then value :+ "ß"

        If KEYWRAPPER.pressedKey(221) If shiftPressed Then value :+ "`" Else value :+ "´"
	    If KEYWRAPPER.pressedKey(188) If shiftPressed Then value :+ ";" Else value :+ ","
	    If KEYWRAPPER.pressedKey(189) If shiftPressed Then value :+ "_" Else value :+ "-"
	    If KEYWRAPPER.pressedKey(190) If shiftPressed Then value :+ ":" Else value :+ "."
        If KEYWRAPPER.pressedKey(226) If shiftPressed Then value :+ ">" Else value :+ "<"
        If KEYWRAPPER.pressedKey(KEY_BACKSPACE) value = value[..value.length -1]
	    If KEYWRAPPER.pressedKey(106) value :+ "*"
	    If KEYWRAPPER.pressedKey(111) value :+ "/"
	    If KEYWRAPPER.pressedKey(109) value :+ "-"
	    If KEYWRAPPER.pressedKey(109) value :+ "-"
	    If KEYWRAPPER.pressedKey(110) value :+ ","
	    For Local i:Int = 0 To 9
			If KEYWRAPPER.pressedKey(96+i) Then  value :+ "0"
		Next
	    If KEYWRAPPER.pressedKey(32) Then value :+ " "

	    If KEYWRAPPER.pressedKey(13) Then EnterPressed :+1
   	    Return value
	End Method
End Type

Type TGUIButton Extends TGUIobject
	Field textalign:Int		= 0
	Field manualState:Int	= 0

	Function Create:TGUIButton(pos:TPosition, width:Int=-1, on:int=0, enabled:int=1, textalign:Int=0, value:String, State:String = "", UseFont:TBitmapFont = Null)
		Local obj:TGUIButton=New TGUIButton
		obj.BaseInit(UseFont)
		obj.pos.setPos(pos)
		obj.on			= on
		obj._enabled	= enabled
		obj.textalign	= textalign
		If width < 0 Then width = obj.useFont.getWidth(value) + 8
		obj.uid			= TGUIObject.GetNewID()
		obj.scale		= GUIManager.globalScale
		obj.dimension.SetXY(width, Assets.GetSprite("gfx_gui_button.L").h * obj.scale )
		obj.zindex		= 10
		obj.value		= value
		obj.typ			= "button"
		obj.forstateonly= State

    	GUIManager.Add( obj )
		Return obj
	End Function

	Method SetTextalign(aligntype:String = "LEFT")
		textalign = 0 'left
		If aligntype.ToUpper() = "CENTER" Then textalign = 1
		If aligntype.ToUpper() = "RIGHT" Then textalign = 2
	End Method

	Method Update()
		If Not manualState
	        If MouseIsDown And Not grayedout Then on = 1 Else on = 0
			If Not MouseOver Then on = 0 'no mouse within button-regions, so button not clicked
		EndIf
		If Self._enabled = False
			self.on = 2
			self.clicked = null
		endif
	End Method

	Method Draw()
		SetColor 255, 255, 255

		If Self.scale <> 1.0 Then SetScale Self.scale, Self.scale
		Assets.GetSprite("gfx_gui_button"+Self.state+".L").Draw(Self.pos.x,Self.pos.y)
		Assets.GetSprite("gfx_gui_button"+Self.state+".M").TileDrawHorizontal(Self.pos.x + Assets.GetSprite("gfx_gui_button"+Self.state+".L").w*Self.scale, Self.pos.y, self.dimension.x - ( Assets.GetSprite("gfx_gui_button"+Self.state+".L").w + Assets.GetSprite("gfx_gui_button"+Self.state+".R").w)*scale, Self.scale)
		Assets.GetSprite("gfx_gui_button"+Self.state+".R").Draw(Self.pos.x + self.dimension.x - Assets.GetSprite("gfx_gui_button"+Self.state+".R").w*Self.scale, Self.pos.y)
		If Self.scale <> 1.0 Then SetScale 1.0,1.0

		Local TextX:Float = Ceil(Self.pos.x + 10)
		Local TextY:Float = Ceil(Self.pos.y - (Self.useFont.getHeight("ABC") - self.dimension.y) / 2)
		If textalign = 1 Then TextX = Ceil(Self.pos.x + (Self.dimension.x - Self.useFont.getWidth(value)) / 2)

		SetAlpha 0.50
'		SetColor 250, 0,0
'		DrawRect(TextX, TextY, 40, self.useFont.getHeight("abcd"))
		SetColor 250, 250, 250
		Self.Usefont.Draw(value, TextX, TextY+1)
		SetAlpha 1.0
		if self._enabled
			if Self.mouseover Then SetColor 50, 50, 50	else SetColor 100, 100, 100
		else
			SetAlpha 0.75
			SetColor 150,150,150
		endif
		Self.Usefont.Draw(value, TextX, TextY)

		SetAlpha 1.0
		SetColor 255,255,255
	End Method

End Type

Type TGUIImageButton Extends TGUIobject
    Field grayedout:Int
	Field startframe:Int = 0
	Field spriteBaseName:String = ""

	Function Create:TGUIImageButton(x:Int, y:Int, width:Int, Height:Int, spriteBaseName:String, on:Byte = 0, enabled:Byte = 1, grayedout:Int = 0, State:String = "", startframe:Int = 0)
		Local obj:TGUIImageButton = New TGUIImageButton
		obj.pos.setXY( x,y )
		obj.on      = on
		obj.grayedout=grayedout
		obj._enabled = enabled
		obj.spriteBaseName = spriteBaseName
		obj.startframe = startframe
		obj.dimension.setXY( Assets.getSprite(spriteBaseName).w, Assets.getSprite(spriteBaseName).h )
		obj.uid      = TGUIObject.GetNewID()
		obj.value$  = ""
		obj.typ$    = "button"
		obj.forstateonly = State$

		GUIManager.Add( obj )
		Return obj
	End Function

	Method Update()
		'
	End Method

	Method Draw()
		SetColor 255,255,255

        If MouseIsDown Then on = 1 Else on = 0
        If grayedout = 1
			self.on = 2
			self.Clicked = null
		endif

		Local state:String = ""
		If on = 2 Then state = "_disabled"
		If on = 1 Then state = "_clicked"
 		Assets.GetSprite(Self.spriteBaseName+state).draw(Self.pos.x, Self.pos.y)
	End Method

End Type

'''''TProgressBar -> Ladebildschirm

Type TGUIBackgroundBox  Extends TGUIobject
   ' Global List:Tlist
	Field textalign:Int = 0
	Field manualState:Int = 0

	Function Create:TGUIBackgroundBox(x:Int, y:Int, width:Int = 100, height:Int= 100, textalign:Int = 0, value:String, State:String = "", UseFont:TBitmapFont = Null)
		Local obj:TGUIBackgroundBox=New TGUIBackgroundBox
		obj.BaseInit(useFont)
		obj.pos.setXY( x,y )
		obj.textalign	= textalign
		obj.uid			= TGUIObject.GetNewID()
		obj.dimension.setXY( width, height )
		obj.value		= value
		obj.typ			= "backgroundbox"
		obj.zindex		= 0
		obj.forstateonly = State
		obj.scale		= GUIManager.globalScale
		GUIManager.Add(obj)
		Return obj
	End Function

	Method SetTextalign(aligntype:String = "LEFT")
		textalign = 0 'left
		If aligntype.ToUpper() = "CENTER" Then textalign = 1
		If aligntype.ToUpper() = "RIGHT" Then textalign = 2
	End Method

	Method Update()
		'
	End Method

	Method Draw()
		SetColor 255, 255, 255

		If Self.scale <> 1.0 Then SetScale Self.scale, Self.scale
		Local addY:Float = 0
		Assets.GetSprite("gfx_gui_box_context.TL").Draw(Self.pos.x,Self.pos.y)
		Assets.GetSprite("gfx_gui_box_context.TM").TileDrawHorizontal(Self.pos.x + Assets.GetSprite("gfx_gui_box_context.TL").w*Self.scale, Self.pos.y, self.dimension.x - Assets.GetSprite("gfx_gui_box_context.TL").w*Self.scale - Assets.GetSprite("gfx_gui_box_context.TR").w*Self.scale, Self.scale)
		Assets.GetSprite("gfx_gui_box_context.TR").Draw(Self.pos.x + self.dimension.x - Assets.GetSprite("gfx_gui_box_context.TR").w*Self.scale, Self.pos.y) 'align left
		addY = Assets.GetSprite("gfx_gui_box_context.TM").h * scale

		Assets.GetSprite("gfx_gui_box_context.ML").TileDrawVertical(Self.pos.x,Self.pos.y + addY, self.dimension.y - addY - (Assets.GetSprite("gfx_gui_box_context.BL").h*Self.scale), Self.scale )
		Assets.GetSprite("gfx_gui_box_context.MM").TileDraw(Self.pos.x + Assets.GetSprite("gfx_gui_box_context.ML").w*Self.scale, Self.pos.y + addY, self.dimension.x - Assets.GetSprite("gfx_gui_box_context.BL").w*scale - Assets.GetSprite("gfx_gui_box_context.BR").w*scale,  self.dimension.y - addY - (Assets.GetSprite("gfx_gui_box_context.BL").h*Self.scale), -1, Self.scale )
		Assets.GetSprite("gfx_gui_box_context.MR").TileDrawVertical(Self.pos.x + self.dimension.x - Assets.GetSprite("gfx_gui_box_context.MR").w*Self.scale,Self.pos.y + addY, self.dimension.y - addY - (Assets.GetSprite("gfx_gui_box_context.BR").h*Self.scale), Self.scale )


		addY = self.dimension.y - Assets.GetSprite("gfx_gui_box_context.BM").h * scale

		'buggy "line" zwischen bottom und tiled bg
		addY :-1

'		drawRect(self.pos.x-5, self.pos.y + addY, 200, 50)
		Assets.GetSprite("gfx_gui_box_context.BL").Draw(Self.pos.x,Self.pos.y + addY)
		Assets.GetSprite("gfx_gui_box_context.BM").TileDrawHorizontal(Self.pos.x + Assets.GetSprite("gfx_gui_box_context.BL").w*Self.scale, Self.pos.y + addY, self.dimension.x - Assets.GetSprite("gfx_gui_box_context.TL").w*Self.scale - Assets.GetSprite("gfx_gui_box_context.BR").w*Self.scale, Self.scale)
		Assets.GetSprite("gfx_gui_box_context.BR").Draw(Self.pos.x + self.dimension.x - Assets.GetSprite("gfx_gui_box_context.BR").w*Self.scale, Self.pos.y +  addY) 'align left

		If Self.scale <> 1.0 Then SetScale 1.0,1.0

		Local TextX:Float = Ceil(Self.pos.x + 10)
		Local TextY:Float = Ceil(Self.pos.y - (Self.useFont.getHeight(value) - Assets.GetSprite("gfx_gui_box_context.TL").h * Self.scale) / 2)

		If textalign = 1 Then TextX = Ceil(Self.pos.x + (self.dimension.x - Self.useFont.getWidth(value)) / 2)
		SetAlpha 0.50
		SetColor 75, 75, 75
		Self.Usefont.Draw(value, TextX+1, TextY + 1)
		SetAlpha 0.35
		SetColor 0, 0, 0
		Self.Usefont.Draw(value, TextX-1, TextY - 1)
		SetAlpha 1.0
		SetColor 200, 200, 200
		Self.Usefont.Draw(value, TextX, TextY)

		SetColor 255,255,255
	End Method

End Type


Type TGUIArrowButton  Extends TGUIobject
   ' Global List:Tlist
    Field direction:String
    Field grayedout:Int

	Function Create:TGUIArrowButton(x:Int,y:Int, direction:Int=0, on:Byte = 0, enabled:Byte = 1, grayedout:Int =0, State:String="", align:Int = 0)
		Local obj:TGUIArrowButton=New TGUIArrowButton
		obj.pos.setXY( x,y)
		obj.on      	= on
		obj.grayedout	= grayedout
		obj._enabled 	= enabled
		obj.direction = "left"
		If direction = 0 Then obj.direction = "left"
		If direction = 1 Then obj.direction = "up"
		If direction = 2 Then obj.direction = "right"
		If direction = 3 Then obj.direction = "down"
		obj.zindex		= 40

		obj.scale		= GUIManager.globalScale
		obj.dimension.setXY( Assets.GetSprite("gfx_gui_arrow_"+obj.direction).w * obj.scale, Assets.GetSprite("gfx_gui_arrow_"+obj.direction).h * obj.scale )
		obj.uid			= obj.GetNewID()
		obj.value		= ""
		obj.typ			= "button"
		obj.forstateonly= State
		obj.setAlign(align)

		GUIManager.Add( obj )
		Return obj
	End Function

	Method setAlign(align:Int=0)
		If Self.align <> align
			If Self.align = 0 And align = 1
				Self.pos.setX( Self.pos.x - Self.dimension.x )
			EndIf
			If Self.align = 1 And align = 0
				Self.pos.setX( Self.pos.x + Self.dimension.x )
			EndIf
		EndIf
	End Method

	Method Update()
        If MouseIsDown And Not grayedout Then on = 1 Else on = 0
        If grayedout=1 then self.Clicked = null
	End Method

	Method Draw()
		SetColor 255,255,255
		If Self.scale <> 1.0 Then SetScale Self.scale, Self.scale
 		If on < 2 Then Assets.GetSprite("gfx_gui_arrow_"+Self.direction+Self.state).Draw(Self.pos.x, Self.pos.y)
		If Self.scale <> 1.0 Then SetScale 1.0, 1.0
	    If grayedout=1  on = 2
	End Method

End Type

Type TGUISlider  Extends TGUIobject
    Field minvalue:Int
    Field maxvalue:Int
    Field actvalue:Int = 50
    Field addvalue:Int = 0
    Field drawvalue:Int = 0

	Function Create:TGUISlider(x:Int, y:Int, width:Int, minvalue:Int, maxvalue:Int, enabled:Byte = 1, value:String, State:String = "")
		Local GUISlider:TGUISlider = New TGUISlider
		GUISlider.BaseInit()
		GUISlider.pos.setXY( x,y )
		GUISlider.on = 0
		GUISlider._enabled = enabled
		If width < 0 Then width = TextWidth(value) + 8
		guislider.uid = Rand(1, 10000)
		GUISlider.dimension.setXY( width, gfx_GuiPack.GetSprite("Button").frameh )
		GUISlider.value = value
		GUISlider.minvalue = minvalue
		GUISlider.maxvalue = maxvalue
		GUISlider.actvalue = minvalue
		GUISlider.typ = "slider"
		GUISlider.forstateonly = State
		GUIMAnager.Add( GUISlider )
		Return GUISlider
	End Function

	Method Update()
	'
	End Method

    Method EnableDrawValue:Int()
		drawvalue = 1
	End Method

    Method DisableDrawValue:Int()
		drawvalue = 0
	End Method

    Method EnableAddValue:Int(add:Int)
 		addvalue = add
	End Method

    Method DisableAddValue:Int()
 		addvalue = 0
	End Method


	Method GetValue:Int()
		Return actvalue + addvalue
	End Method

	Method Draw()
		Local gfx_gui_slider:TImage = gfx_GuiPack.GetSpriteImage("Slider")
	    Local SliderImgWidth:Int = ImageWidth(gfx_gui_slider)
	    Local SliderImgHeight:Int = ImageHeight(gfx_gui_slider)
		Local PixelPerValue:Float = self.dimension.x / (maxvalue - 1 - minvalue)
	    Local actvalueX:Float = actvalue * PixelPerValue
	    Local maxvalueX:Float = (maxvalue) * PixelPerValue
		Local i:Int = 0
		If MouseIsDown Then on = 1 Else on = 0
		Local difference:Int = actvalueX '+ PixelPerValue / 2

		If on
			difference = MouseX() - Self.pos.x + PixelPerValue / 2
			actvalue = Float(difference) / PixelPerValue
			If actvalue > maxvalue Then actvalue = maxvalue
			If actvalue < minvalue Then actvalue = minvalue
			actvalueX = difference'actvalue * PixelPerValue
			If actvalueX >= maxValueX - SliderImgWidth Then actvalueX = maxValueX - SliderImgWidth
		EndIf

  		If Ceil(actvalueX) < SliderImgWidth
			ClipImageToViewport(gfx_gui_slider, Self.pos.x, Self.pos.y, Self.pos.x, Self.pos.y, Ceil(actvalueX) + 5, SliderImgHeight, 0, 0, 4)       								'links an
  		    ClipImageToViewport(gfx_gui_slider, Self.pos.x, Self.pos.y, Self.pos.x + Ceil(actvalueX) + 5, Self.pos.y, SliderImgWidth, SliderImgHeight, 0, 0, 0)       'links aus
		Else
			DrawImage(gfx_gui_slider, Self.pos.x, Self.pos.y, 4)
		EndIf
  		If Ceil(actvalueX) > self.dimension.x - SliderImgWidth
			ClipImageToViewport(gfx_gui_slider, Self.pos.x + self.dimension.x - SliderImgWidth, Self.pos.y, Self.pos.x + self.dimension.x - SliderImgWidth, Self.pos.y, Ceil(actvalueX) - (self.dimension.x - SliderImgWidth) + 5, SliderImgHeight, 0, 0, 6)                        								'links an
  		    ClipImageToViewport(gfx_gui_slider, Self.pos.x + self.dimension.x - SliderImgWidth, Self.pos.y, Self.pos.x + actvalueX + 5, Self.pos.y, SliderImgWidth, SliderImgHeight, 0, 0, 2)                    'links aus
		Else
			DrawImage(gfx_gui_slider, Self.pos.x + self.dimension.x - SliderImgWidth, Self.pos.y, 2)
		EndIf

		For i = 1 To Ceil(actvalueX) / SliderImgWidth
			If i * SliderImgWidth < self.dimension.x - SliderImgWidth
				Local mywidth:Int = SliderImgWidth
				If i * SliderImgWidth + SliderImgWidth > actvalueX Then mywidth = actvalueX - i * SliderImgWidth
				If i * SliderImgWidth + SliderImgWidth > self.dimension.x - SliderImgWidth Then mywidth = self.dimension.x - SliderImgWidth - (i * SliderImgWidth)
				If i * SliderImgWidth + mywidth > actvalueX Then mywidth = actvalueX - i * SliderImgWidth
		    	ClipImageToViewport(gfx_gui_slider, Self.pos.x + i * SliderImgWidth, Self.pos.y, Self.pos.x + i * SliderImgWidth, Self.pos.y, mywidth, SliderImgHeight, 0, 0, 1 + 4)
			EndIf
		Next 'gefaerbter Balken

		For i = Ceil(actvalueX) / SliderImgWidth To Ceil(maxvalueX) / SliderImgWidth - 1
				Local minX:Int = Self.pos.x + i * SliderImgWidth
				Local mywidth:Float = SliderImgWidth
				If minx <= Max(Self.pos.x + SliderImgWidth, Self.pos.x + actvalueX) Then minx = Max(Self.pos.x + SliderImgWidth, Self.pos.x + actvalueX)
				If i * sliderImgWidth + SliderImgWidth >= self.dimension.x - SliderImgWidth Then mywidth = (self.dimension.x - SliderImgWidth) - (minx - Self.pos.x)
				If mywidth < 0 Then mywidth = 0
		    	ClipImageToViewport(gfx_gui_slider, Self.pos.x + i * SliderImgWidth, Self.pos.y, minx, Self.pos.y, mywidth, SliderImgHeight, 0, 0, 1)
		Next 'ungefaerbte Balken

		DrawImage(gfx_gui_slider, Self.pos.x + Ceil(actvalueX - 5), Self.pos.y, 3 + on * 4)    '5 = Mitte des Draggers
		SetColor 255, 255, 255
		If drawvalue = 0
  	 	  If value$ <> "" DrawText(value$, Self.pos.x+self.dimension.x+7, Self.pos.y- (TextHeight(value$) - self.dimension.y) / 2 - 1)
		Else
		  If value$ <> "" DrawText((actvalue + addvalue) + " "+value$, Self.pos.x+self.dimension.x+7, Self.pos.y- (TextHeight(value$) - self.dimension.y) / 2 - 1)
		EndIf
	End Method

End Type

Type TGUIinput  Extends TGUIobject
    Field maxLength:Int
    Field maxTextWidth:Int
    Field nobackground:Int
    Field color:TColor = TColor.Create(0,0,0)
    Field OverlayImage:TGW_Sprites = Null
    Field InputImage:TGW_Sprites = Null	  'own Image for Inputarea
    Field OverlayColor:TColor = TColor.Create(200,200,200)
    Field OverlayColA:Float = 0.5
    Field grayedout:Int = 0
	Field TextDisplacement:TPosition = TPosition.Create(5,5)

    Function Create:TGUIinput(x:Int, y:Int, width:Int, enabled:Byte = 1, value:String, maxlength:Int = 128, State:String = "", useFont:TBitmapFont = Null)
		Local obj:TGUIinput = New TGUIinput
		obj.BaseInit(UseFont)
		obj.pos.setXY( x,y )
		obj._enabled	= enabled
		obj.scale		= GUIManager.globalScale
		obj.zindex		= 20
		obj.dimension.setXY( Max(width, 40), Assets.GetSprite("gfx_gui_input.L").h * obj.scale )
		obj.maxTextWidth= obj.dimension.x - 15
		obj.value		= value
		obj.uid			= obj.GetNewID()
		obj.maxlength	= maxlength
		obj.forstateonly = State
		obj.EnterPressed = 0
		obj.nobackground = 0
		obj.color = TColor.Create(100,100,100)

		GUIMAnager.Add( obj )
	  	Return obj
	End Function


	Method Update()
		If Not grayedout
			If EnterPressed >= 2
				EnterPressed = 0
				GUIManager.setActive(0)
			EndIf
			If GUIManager.isActive(Self.uid) Then value = Input2Value(value)
		EndIf
		If GUIManager.isActive(uid) Then on = 1 Else on = 0
		If GUIManager.isActive(uid) Then Self.setState("active")

        If value.length > maxlength Then value = value[..maxlength]
	End Method

    Method SetOverlayImage:TGUIInput(_sprite:TGW_Sprites)
		If _sprite <> Null Then If _sprite.w > 0 Then OverlayImage = _sprite
		Return Self
	End Method

	Method Draw()

		Local useTextDisplaceX:Int	= Self.TextDisplacement.x
	    Local i:Int					= 0
		Local printvalue:String		= value
		If grayedout Then on = 0;SetColor 225, 255, 150

		If Self.scale <> 1.0 Then SetScale Self.scale, Self.scale
		If nobackground = 0
			Assets.GetSprite("gfx_gui_input"+Self.state+".L").Draw(Self.pos.x,Self.pos.y)
			Assets.GetSprite("gfx_gui_input"+Self.state+".M").TileDrawHorizontal(Self.pos.x + Assets.GetSprite("gfx_gui_input"+Self.state+".L").w*Self.scale, Self.pos.y, self.dimension.x - ( Assets.GetSprite("gfx_gui_input"+Self.state+".L").w + Assets.GetSprite("gfx_gui_input"+Self.state+".R").w)*scale, Self.scale)
			Assets.GetSprite("gfx_gui_input"+Self.state+".R").Draw(Self.pos.x + self.dimension.x - Assets.GetSprite("gfx_gui_input"+Self.state+".R").w*Self.scale, Self.pos.y)

			'center overlay over left frame
			If OverlayImage <> Null
				Local Left:Float = ( ( Assets.GetSprite("gfx_gui_input"+Self.state+".L").w - OverlayImage.w ) / 2 ) * Self.scale
				Local top:Float = ( ( Assets.GetSprite("gfx_gui_input"+Self.state+".L").h - OverlayImage.h ) / 2 ) * Self.scale
				OverlayImage.Draw( Self.pos.x + Left, Self.pos.y + top )
			EndIf
		Else
			If GUIManager.getActive() = uid
				If InputImage = Null
					SetAlpha OverlayColA
					OverlayColor.set()
					DrawRect Self.pos.x, Self.pos.y + 4, self.dimension.x, self.dimension.y
					SetAlpha 1
					SetColor 255, 255, 255
				Else
					InputImage.Draw(Self.pos.x, Self.pos.y)
				EndIf
			EndIf
			i = (self.dimension.x / 34) - 1
		EndIf
		If Self.scale <> 1.0 Then SetScale 1.0,1.0

		Local useMaxTextWidth:Int = Self.maxTextWidth
		If Self.useFont = Null Then Self.BaseInit() 'item not created with create but new
		Self.textDisplacement.y = (self.dimension.y) / 2 - Self.useFont.getHeight("abcd")/2

        If OverlayImage <> Null
			useTextDisplaceX :+ OverlayImage.framew * Self.scale
			useMaxTextWidth :-  OverlayImage.framew * Self.scale
		EndIf
		local textPosX:int = ceil( Self.pos.x + usetextDisplaceX + 2 )
		local textPosY:int = ceil( Self.pos.y + Self.textDisplacement.y )

		If on = 1
			Self.color.set()
'			SetColor self.color.r - 100, self.color.g - 100, self.color.b - 100
			While Len(printvalue) >1 And Self.useFont.getWidth(printValue + "_") > useMaxTextWidth
				printvalue = printValue[1..]
			Wend
			Self.useFont.draw(printValue, textPosX, textPosY)

			SetAlpha Ceil(Sin(MilliSecs() / 4))
			Self.useFont.draw("_", textPosX + Self.useFont.getWidth(printValue), textPosY )
			SetAlpha 1
	    Else
			Self.color.set()
			While TextWidth(printValue) > useMaxTextWidth And printvalue.length > 0
				printvalue = printValue[..printvalue.length - 1]
			Wend

			If Self.mouseover
				Self.useFont.drawStyled(printValue, textPosX, textPosY, Self.color.r-50, Self.color.g-50, Self.color.b-50, 1)
			Else
				Self.useFont.drawStyled(printValue, textPosX, textPosY, Self.color.r, Self.color.g, Self.color.b, 1)
			EndIf
		EndIf

		SetColor 255, 255, 255
	End Method

End Type

Type TGUIDropDownEntries   'Listeneintraege der GUIListe
  Global List:TList
  Field value:String
  Field entryid:Int
  Field pid:Int

  Function Create:TGUIDropDownEntries(value:String, id:Int)
    Local GUIDropDownEntries:TGUIDropDownEntries = New TGUIDropDownEntries
    'DebugLog("entry created")
	GUIDropDownEntries.value$ = value$
	GUIDropDownEntries.pid    = 0'pid
	GUIDropDownEntries.entryid= id

    Return GUIDropDownEntries
  End Function
End Type

Type TGUIDropDown  Extends TGUIobject
   ' Global List:Tlist
    Field grayedout:Int
    Field Values : String[]
	Field Entries:TGUIDropDownEntries = New TGUIDropDownEntries
	Field EntryList: TList
    Field PosChangeTimer: Int
	Field ListPosClicked:Int=-1
	Field ListPosEntryID:Int=-1
	Field buttonheight:Int
	Field textalign:Int = 0
	Field OnChange_(listpos:Int) = TGUIDropDown.DoNothing

	Function Create:TGUIDropDown(x:Int, y:Int, width:Int = -1, on:Byte = 0, enabled:Byte = 1, grayedout:Int = 0, value:String, State:String = "")
		Local GUIDropDown:TGUIDropDown=New TGUIDropDown
		GUIDropDown.pos.setXY( x,y )
		GUIDropDown.on = on
		guiDropDown.grayedout = grayedout
		GUIDropDown._enabled = enabled
		If width < 0 Then width = TextWidth(value:String) + 8
		guiDropDown.uid = Rand(1, 10000)
		GUIDropDown.buttonheight = gfx_GuiPack.GetSprite("DropDown").frameh * 2
		GUIDropDown.dimension.setXY( width, GUIDropDown.buttonheight)
		GUIDropDown.value = value
		GUIDropDown.typ = "dropdown"
		GUIDropDown.forstateonly = State
		If Not guiDropDown.EntryList Then guiDropDown.EntryList = CreateList()

		GUIManager.Add( GUIDropDown )
		Return GUIDropDown
	End Function

	Function DoNothing(listpos:Int)
		'
	End Function

	Method SetActiveEntry(id:Int)
		Self.ListPosClicked = id
		Self.value = TGUIDropDownEntries(Self.EntryList.ValueAtIndex(id)).value
	End Method

	Method Update()
	    Local printheight:Int = 0, i:Int = 0
        If GUIManager.getActive() = uid Then on = 1 Else on = 0
		If MOUSEMANAGER.IsHit(1) And on
			For Local Entries:TGUIDropDownEntries = EachIn EntryList 'Liste hier global
				If functions.isin( MouseX(),MouseY(), Self.pos.x + 5, Self.pos.y + 5 + printheight + 30, self.dimension.x - 10, 5 + printheight + 30 + TextHeight(Entries.value) )
					ListPosClicked	= i
					value			= Entries.value
		        	EnterPressed	= 0
					ListPosEntryID	= Entries.entryid
					on				= 0
					GUIManager.setActive(0)
					OnChange_(Entries.entryid)
					Exit
		        EndIf
	          	printheight :+ TextHeight(Entries.value)
			  	i:+1
			Next
        	on = 0
			GUIManager.setActive(0)
			MOUSEMANAGER.resetKey(1)
		End If
	End Method

	Method AddEntry(value:String, id:Int)
		EntryList.AddLast(Entries.Create(value, id))
		If Self.value = "" Then Self.value = value
		If Self.ListPosEntryID = -1 Then Self.ListPosEntryID = id
	End Method

	Method Draw()
		Local GuiSprite:TGW_Sprites	= gfx_GuiPack.GetSprite("DropDown")
		Local ImgWidth:Int			= GuiSprite.framew
		Local ImgHeight:Int			= GuiSprite.frameh
	    Local i:Int					= 0
	    Local j:Int					= 0
	    Local useheight:Int			= 0
	    Local printheight:Int		= 0
        If grayedout = 1
			self.on = 2
			self.clicked = null
		endif

		If on = 1 And Not grayedout 'ausgeklappt zeichnen
			useheight = 0
			For Local Entries:TGUIDropDownEntries = EachIn EntryList 'Liste hier global
				useheight = useheight + TextHeight(Entries.value)
			Next
			useheight = useheight + 15
			Local lineheight:Int = 19

			SetAlpha 0.8
			'SetViewport(0, 0, 800, 600)
			For i = 1 To useheight / ImgHeight + 1
				Local minY:Int = i * lineheight
				If minY + lineheight > useheight + buttonheight - ImgHeight
					minY = useheight + buttonheight - ImgHeight - lineheight
				EndIf
				GuiSprite.DrawClipped(Self.pos.x + 5, Self.pos.y + i * lineheight, Self.pos.x + 5, Self.pos.y + minY, self.dimension.x - 10 - imgwidth, lineheight,,, 18)
	  		    For j = 1 To (self.dimension.x - 10) / ImgWidth - 1
					GuiSprite.DrawClipped(Self.pos.x + j * ImgWidth, Self.pos.y + i * lineheight, Self.pos.x + 5, Self.pos.y + miny, self.dimension.x - 10 - ImgWidth, lineheight, 0, 0, 19)
	            Next
				GuiSprite.DrawClipped(Self.pos.x - 5 + self.dimension.x - ImgWidth, Self.pos.y + i * lineheight, Self.pos.x - 5 + self.dimension.x - ImgWidth, Self.pos.y + minY, imgWidth, lineheight,,, 20)
			Next

			'unten "liste"
			For i = 1 To (self.dimension.x / ImgWidth) - 1
				GuiSprite.DrawClipped(Self.pos.x + 5 + i * ImgWidth, Self.pos.y + useheight + imgheight, Self.pos.x + 5, Self.pos.y + useheight + imgHeight, self.dimension.x - 10 - ImgWidth, imgHeight, 0, 0, 22)
			Next
	  		'SetViewport(Self.pos.x + 5, Self.pos.y + useheight + buttonheight - ImgHeight, self.dimension.x - 10, lineheight)
			GuiSprite.Draw(Self.pos.x + 5, Self.pos.y + useheight + buttonheight - ImgHeight, 21)
			GuiSprite.Draw(Self.pos.x - 5 + self.dimension.x - ImgWidth, Self.pos.y + useheight + buttonheight - ImgHeight, 23)
			SetAlpha 1.0

			'Zeileninhalte
			'SetViewport(0, 0, 800, 600)
			'SetViewport(0, 0, Game.GameGraphics.screenw, Game.GameGraphics.screenh)
			i = 0
			For Local Entries:TGUIDropDownEntries = EachIn EntryList 'Liste hier global
				If i = ListPosClicked
					SetAlpha 0.2
					SetColor 95, 80, 30
					DrawRect(Self.pos.x + 13, Self.pos.y + 5 + printheight + 30, self.dimension.x - 27, TextHeight(Entries.value))
					SetAlpha 1.0
					SetColor 255, 255, 255
				EndIf
				If ListPosClicked = i Then SetColor(244, 206, 74)
				If MouseX() > Self.pos.x + 5 And MouseX() < Self.pos.x + self.dimension.x - 10 And MouseY() > Self.pos.y + 5 + printheight + 30 And MouseY() < Self.pos.y + 5 + printheight + 30 + TextHeight(Entries.value)
		        	SetAlpha 0.2
		        	DrawRect(Self.pos.x + 13, Self.pos.y + 5 + printheight + 30, self.dimension.x - 27, TextHeight(Entries.value))
		        	SetAlpha 1.0
				EndIf
				If textalign = 1 Then DrawText(Entries.value, Self.pos.x + (self.dimension.x - TextWidth(Entries.value)) / 2, Self.pos.y + 5 + printheight + 30)
				If textalign = 0 Then DrawText(Entries.value, Self.pos.x + 15, Self.pos.y + 5 + printheight + 30)
				If ListPosClicked = i Then SetColor 255, 255, 255
				printheight:+TextHeight(Entries.value)
				i:+1
			Next

			GuiSprite.Draw(Self.pos.x, Self.pos.y, 0 + 3 * on)
			GuiSprite.Draw(Self.pos.x, Self.pos.y + buttonheight - ImgHeight, 9 + 3 * on)

			For i = 1 To (self.dimension.x / ImgWidth) - 1
				GuiSprite.DrawClipped(Self.pos.x + i * ImgWidth, Self.pos.y, Self.pos.x, Self.pos.y, self.dimension.x - ImgWidth, self.dimension.y, 0, 0, 1 + 3 * on)
				GuiSprite.DrawClipped(Self.pos.x + i * ImgWidth, Self.pos.y + ImgHeight, Self.pos.x, Self.pos.y, self.dimension.x - ImgWidth, self.dimension.y, 0, 0, 10 + 3 * on)
			Next
			'SetViewport(GetViewPortX, GetViewPortY, GetViewPortWidth, GetViewPortHeight)
			GuiSprite.Draw(Self.pos.x + self.dimension.x - ImgWidth, Self.pos.y, 2 + 3 * on)
			GuiSprite.Draw(Self.pos.x + self.dimension.x - ImgWidth, Self.pos.y + ImgHeight, 11 + 3 * on)
		End If
		If on = 0 Or grayedout
			GuiSprite.Draw(Self.pos.x, Self.pos.y, 0 + 3 * on)
			GuiSprite.Draw(Self.pos.x, Self.pos.y + buttonheight - ImgHeight, 9 + 3 * on)

			For i = 1 To (self.dimension.x / ImgWidth) - 1
				GuiSprite.DrawClipped(Self.pos.x + i * ImgWidth, Self.pos.y, Self.pos.x, Self.pos.y, self.dimension.x - ImgWidth, self.dimension.y, 0, 0, 1 + 3 * on)
				GuiSprite.DrawClipped(Self.pos.x + i * ImgWidth, Self.pos.y + ImgHeight, Self.pos.x, Self.pos.y, self.dimension.x - ImgWidth, self.dimension.y, 0, 0, 10 + 3 * on)
			Next
			'SetViewport(GetViewPortX, GetViewPortY, GetViewPortWidth, GetViewPortHeight)
			GuiSprite.Draw(Self.pos.x + self.dimension.x - ImgWidth, Self.pos.y, 2 + 3 * on)
			GuiSprite.Draw(Self.pos.x + self.dimension.x - ImgWidth, Self.pos.y + ImgHeight, 11 + 3 * on)
		EndIf
		If on Or grayedout
			If grayedout Then SetAlpha 0.7
			DrawText(value, Self.pos.x + (self.dimension.x - TextWidth(value)) / 2 - 4, Self.pos.y - (TextHeight(value) - buttonheight) / 2 - 2)
			If grayedout Then SetAlpha 1.0
	    Else
			SetColor 230, 230, 230
			DrawText(value, Self.pos.x + (self.dimension.x - TextWidth(value)) / 2 - 4 + 1, Self.pos.y - (TextHeight(value) - buttonheight) / 2 - 1)
			SetColor 255, 255, 255
		EndIf
        If grayedout = 1 Then on = 2
		'debuglog ("GUIradiobutton zeichnen")
	End Method
End Type



Type TGUIOkButton  Extends TGUIobject
	Field crossed:Byte = 0
	Field onoffstate:String = "off"
	Field assetWidth:Float = 1.0

	Function Create:TGUIOkButton(x:Int,y:Int,on:Byte = 0, enabled:Byte = 1, value:String, State:String="")
		Local obj:TGUIOkButton=New TGUIOkButton
		obj.pos.setXY( x,y )
		obj.on			= on
		obj._enabled 	= enabled
		obj.scale		= GUIManager.globalScale
		obj.dimension.setXY( Assets.GetSprite("gfx_gui_ok_off").w * obj.scale, Assets.GetSprite("gfx_gui_ok_off").h * obj.scale)
		obj.assetWidth	= Assets.GetSprite("gfx_gui_ok_off").w
		obj.value		= value
		obj.forstateonly= State
		obj.zindex		= 50
		obj.crossed		= on
		obj.typ			= "okbutton"
		obj.uid			= obj.GetNewID()
		GUIManager.Add( obj )
		Return obj
	End Function

	Method Update()
		If clicked Then crossed = 1-crossed; self.clicked = null
		If crossed Then on = 1 Else on = 0
		If crossed Then Self.onoffstate = "on" Else Self.onoffstate = "off"
		'disable "active state"
		If Self.state = ".active" Then Self.state = ".hover"
	End Method

	Method IsCrossed:Int()
		Return crossed & 1
		'If crossed = 1 Then Return 1 Else Return 0
	End Method

	Method Draw()
		If Self.scale <> 1.0 Then SetScale Self.scale, Self.scale
		Assets.GetSprite("gfx_gui_ok_"+Self.onoffstate+Self.state).Draw(Self.pos.x, Self.pos.y)
		If Self.scale <> 1.0 Then SetScale 1.0,1.0

		Local textDisplaceX:Int = 5
		SetColor 50,50,100
		DrawText(value, Self.pos.x+Self.assetWidth*Self.scale + textDisplaceX, Self.pos.y - (TextHeight(value) - self.dimension.y) / 2 - 1)
		self.dimension.x = Self.assetWidth*Self.scale + textDisplaceX + TextWidth(value)
		SetColor 255,255,255
	End Method

End Type

Type TGUIbackground Extends TGUIobject
    Field guigfx:Int =0
    Function Create:TGUIbackground(x:Int,y:Int,width:Int, height:Int, Own:Int=0, State:String="")
    Print "OLD OWN-Param : TGUIbackground"
		Local GUIbackground:TGUIbackground = New TGUIbackground
			GUIbackground.pos.setXY( x,y )
		 GUIbackground._enabled = 1
		 If width < 0 Then width = 40
		 GUIbackground.dimension.setXY( width, height )
		 GUIbackground.value$   = ""
		 GUIbackground.typ$     = "background"
		 GUIbackground.forstateonly = State$

		GUIManager.Add( GUIbackground )

		Return GUIbackground
	End Function

	Method Update()

	End Method

	Method Draw()
'		If guigfx = 0 DrawImage(gfx_nw_option, x, y)
   	        'SetViewport(GetViewPortX, GetViewPortY, GetViewPortWidth, GetViewPortHeight)
       End Method
End Type

Type TGUIListEntries   'Listeneintraege der GUIListe
  Global List:TList
  Field value:String
  Field title:String
  Field pid: Int
  Field team:String
  Field ip:String
  Field port:String
  Field time:Int

  Function Create:TGUIListEntries(title:String, value:String, team:String,pid:Int, ip:String="", port:String="", time:Int=0)
    Local GUIListEntries:TGUIListEntries = New TGUIListEntries
    'DebugLog("entry created")
	GUIListEntries.title$ = title$
	GUIListEntries.value$ = value$
	GUIListEntries.team$ = team$
	GUIListEntries.pid    = pid
	GUIListEntries.port$   = port$
	GUIListEntries.ip$     = ip$
	GUIListEntries.time    = time

    Return GUIListEntries
  End Function
End Type

Type TGUIList  Extends TGUIobject
    Field maxlength:Int
    Field filter:String
	Field buttonclicked: Int
	Field ListStartsAtPos :Int
	Field PosChangeTimer: Int
	Field ListPosClicked:Int
	Field GUIbackground: TGUIbackground
'	Field Entries:TGUIListEntries = New TGUIListEntries
	Field EntryList: TList
	Field ControlEnabled:Int = 0
	Field lastMouseClickTime:Int = 0
	Field LastMouseClickPos:Int = 0
    Field nobackground:Int

    Function Create:TGUIList(x:Int, y:Int, width:Int, height:Int = 50, enabled:Byte = 1, maxlength:Int = 128, State:String = "")
		Local GUIList:TGUIList=New TGUIList
			GUIList.baseInit()
			GUIList.pos.setXY( x,y )
		 GUIList._enabled = enabled
		 If width < 40 Then width = 40
		 GUIList.dimension.setXY( width, height )
		 GUIList.uid      = Rand(1,10000)
		 GUIList.maxlength= maxlength
		 guilist.typ      = "list"
		 guilist.PosChangeTimer  = MilliSecs()
		 guilist.ListStartsAtPos = 0
		 guilist.ListPosClicked = -1
		 guilist.GUIbackground:TGUIbackground = New TGUIbackground
		 guilist.GUIbackground.pos.setXY( x,y )
		 guilist.GUIbackground.dimension.setXY( width, height )
		 guilist.GUIbackground.typ$     = "background"

		 GUIList.forstateonly = State$


	     If Not guilist.EntryList Then guilist.EntryList = CreateList()

		GUIManager.Add( GUIList )
	  	 Return GUIList
	End Function

	Method Update()
		'
	End Method

	Method DisableBackground()
		Self.nobackground = True
	End Method

	Method SetControlState(on:Int = 1)
		Self.ControlEnabled = on
	End Method

	Method SetFilter:Int(usefilter:String = "")
	  filter$ = usefilter$
	End Method

 	Method RemoveOldEntries:Int(uid:Int=0, timeout:Int=500)
	  Local i:Int = 0
	  Local RemoveTime:Int = MilliSecs()
	  For Local Entries:TGUIListEntries = EachIn Self.EntryList
        If Entries.pid = uid
		  If Entries.time = 0 Then Entries.time = MilliSecs()
          If Entries.time +timeout < RemoveTime
		    Print "RemoveOldEntries - entry aged... removing "+ (entries.time + timeout)+"<"+RemoveTime
	        EntryList.Remove(Entries)
		    Print  "entry aged... removed "
	      EndIf
	    EndIf
  	    i = i + 1
 	  Next
 	  Return i
	End Method


	Method AddUniqueEntry:Int(title$, value$, team$, ip$, port$, time:Int, usefilter:String = "")
      If filter$ = "" Or filter$ = usefilter$
	    For Local Entries:TGUIListEntries = EachIn Self.EntryList 'Liste hier global
			If Entries.pid = uid
				If Entries.ip$ = ip$ And Entries.port$ = port$
					Entries.time = time
					If time = 0 Then Entries.time = MilliSecs()
					Entries.team$ = team$
					Entries.value = value
					Return 0
				EndIf
			EndIf
 	    Next
		EntryList.AddLast( TGUIListEntries.Create(title, value, team, uid, ip, port, time) )
      EndIf
	End Method

 	Method GetEntryCount:Int()
	    Return EntryList.count()
	End Method

 	Method GetEntryPort:Int()
	    Local i:Int = 0
	    For Local Entries:TGUIListEntries = EachIn Self.EntryList 'Liste hier lokal
	      If i = ListPosClicked
	          Return Int(Entries.port)
	      EndIf
  	      i = i + 1
	    Next
	End Method

	Method GetEntryTime:Int()
	    Local i:Int = 0
  	    For Local Entries:TGUIListEntries = EachIn EntryList 'Liste hier lokal
   	        If i = ListPosClicked
	          Return Entries.time
	        EndIf
  	      i = i + 1
	    Next
	End Method

	Method GetEntryValue:String()
	    Local i:Int = 0
  	    For Local Entries:TGUIListEntries = EachIn EntryList 'Liste hier lokal
   	        If i = ListPosClicked
	          Return Entries.value$
	      EndIf
  	      i = i + 1
	    Next
	End Method

	Method GetEntryTitle:String()
	    Local i:Int = 0
  	    For Local Entries:TGUIListEntries = EachIn EntryList 'Liste hier lokal
			If i = ListPosClicked Then Return Entries.title:String
  	      	i:+1
	    Next
	End Method

	Method GetEntryIP:String()
	    Local i:Int = 0
  	    For Local Entries:TGUIListEntries = EachIn EntryList
 	        If i = ListPosClicked Then Return Entries.ip:String
  	      	i:+1
	    Next
	End Method

	Method ClearEntries()
		EntryList.Clear()
	End Method

	Method AddEntry(title$, value$, team$, ip$, port$, time:Int)
	  If time = 0 Then time = MilliSecs()
	  EntryList.AddLast(TGUIListEntries.Create(title$, value$,team$,uid, ip$, port$, time))
	End Method

	Method Draw()
		Local i:Int = 0
		Local spaceavaiable:Int =0
		Local Zeit : Int
		Local printvalue:String
		Zeit = MilliSecs()
        If GUIManager.getActive() = uid Then on = 1 Else on = 0
		If Not Self.nobackground
		    If GUIbackground <> Null
			 GUIbackground.pos.setPos(Self.pos)
			 GUIbackground.dimension.setPos(self.dimension)
	        Else
				gfx_GuiPack.GetSprite("Chat_Top").Draw(Self.pos.x, Self.pos.y)
				gfx_GuiPack.GetSprite("Chat_Middle").TileDraw(Self.pos.x, Self.pos.y + gfx_GuiPack.GetSprite("Chat_Top").h, gfx_GuiPack.GetSprite("Chat_Middle").w, self.dimension.y - gfx_GuiPack.GetSprite("Chat_Top").h - gfx_GuiPack.GetSprite("Chat_Bottom").h)
				gfx_GuiPack.GetSprite("Chat_Bottom").Draw(Self.pos.x, Self.pos.y + self.dimension.y, 0, 1)
	        EndIf
		EndIf
		'SetViewport(Self.pos.x, Self.pos.y, width - 12, height)
	    i = 0
		SpaceAvaiable = self.dimension.y 'Hoehe der Liste
		Local controlWidth:Float = ControlEnabled * gfx_GuiPack.GetSprite("ListControl").framew
	    For Local Entries:TGUIListEntries = EachIn EntryList 'Liste hier global
		  If i > ListStartsAtPos-1 Then
	  	    If TextHeight(Entries.value$) < SpaceAvaiable
			  If Int(Entries.team$) > 0
			    printValue$ = "[Team "+Entries.team$ + "]: "+Entries.value$
			  Else
			    printValue$ = Entries.value$
			  EndIf
			  While TextWidth(printValue$+"...") > self.dimension.x-4-18
		    	printvalue$= printValue$[..printvalue$.length-1]
	      	  Wend
	          If Int(Entries.team$) > 0
	            If printvalue$ <> "[Team "+Entries.team$ + "]: "+Entries.value$   printvalue$ = printvalue$+"..."
	          Else
	            If printvalue$ <> Entries.value$   printvalue$ = printvalue$+"..."
	          EndIf
		      If i = ListPosClicked
			    SetAlpha(0.5)
		        SetColor(250,180,20)
		        DrawRect(Self.pos.x+8,Self.pos.y+8+self.dimension.y-SpaceAvaiable ,self.dimension.x-20, TextHeight(printvalue$))
		        SetAlpha(1)
		        SetColor(255,255,255)
 			  EndIf
              If ListPosClicked = i SetColor(250, 180, 20)
			  If MouseX() > Self.pos.x + 5 And MouseX() < Self.pos.x + self.dimension.x - 6 - ControlWidth And MouseY() > Self.pos.y + 5 + self.dimension.y - Spaceavaiable And MouseY() < Self.pos.y + 5 + self.dimension.y - Spaceavaiable + TextHeight(printvalue)
		        SetAlpha(0.5)
		        DrawRect(Self.pos.x+8,Self.pos.y+8+self.dimension.y-SpaceAvaiable ,self.dimension.x-20, TextHeight(printvalue$))
		        SetAlpha(1)
		        If MouseIsDown
				  ListPosClicked = i
				  If LastMouseClickPos = i
				    If LastMouseClickTime + 50 < MilliSecs() And LastMouseClicktime +700 > MilliSecs()
						EventManager.registerEvent( TEventSimple.Create( "guiobject.OnClick", TEventData.Create().AddNumber("type", EVENT_DOUBLECLICK), self ) )
				    EndIf
				  EndIf
				  LastMouseClickTime = MilliSecs()
				  LastMouseClickPos = i
				EndIf
 		      EndIf
	            SetColor(55,55,55)
	            Local text:String[] = printvalue.split(":")
	            If Len(text) = 2 Then text[0] = text[0]+":"

  	            useFont.Draw(text[0], Self.pos.x+13, Self.pos.y+8+self.dimension.y-SpaceAvaiable)
	            SetColor(55,55,55)
	            If Len(text) > 1
					useFont.Draw(text[1], Self.pos.x+13+useFont.getWidth(text[0]), Self.pos.y+8+self.dimension.y-SpaceAvaiable)
					SetColor(255,255,255)
				EndIf
                SpaceAvaiable:-useFont.getHeight(printvalue)
            EndIf
          EndIf
          i= i+1
  		Next

    If ControlEnabled = 1
		Local guiListControl:TGW_Sprites = gfx_GuiPack.GetSprite("ListControl")
		For i = 0 To Ceil(self.dimension.y / guiListControl.frameh) - 1
  		  guiListControl.Draw(Self.pos.x + self.dimension.x - guiListControl.framew, Self.pos.y + i * guiListControl.frameh, 7)
		Next
        If GUIManager.getActive() = uid And self.mouseIsDown And self.clicked and Self.clicked.x >= Self.pos.x+self.dimension.x-14 And Self.clicked.y <= Self.pos.y+14
			guiListControl.Draw(Self.pos.x + self.dimension.x - 14, Self.pos.y, 1)
			If PosChangeTimer + 250 < Zeit And ListStartsAtPos > 0
				ListStartsAtPos = ListStartsAtPos -1
				PosChangeTimer = Zeit
			EndIf
	    Else
			guiListControl.Draw(Self.pos.x + self.dimension.x - 14, Self.pos.y, 0)
        EndIf

        If GUIManager.getActive() = uid And self.mouseIsDown And self.clicked and Self.clicked.x >= Self.pos.x+self.dimension.x-14 And Self.clicked.y >= Self.pos.y+self.dimension.y-14
			guiListControl.Draw(Self.pos.x + self.dimension.x - 14, Self.pos.y + self.dimension.y - 14, 5)
			If PosChangeTimer + 250 < Zeit And ListStartsAtPos < Int(EntryList.Count() - 2)
				ListStartsAtPos = ListStartsAtPos + 1
				PosChangeTimer = Zeit
			EndIf
        Else
			guiListControl.Draw(Self.pos.x + self.dimension.x - 14, Self.pos.y + self.dimension.y - 14, 4)
		EndIf
    EndIf 'ControlEnabled

		SetColor 255,255,255
	End Method

End Type

Type TGUIChat  Extends TGUIList
    Field AutoScroll:Int
    Field turndirection:Int = 0
    Field fadeout:Int = 0
    Field GUIInput: TGUIinput
    Field guichatgfx:Int=1
    Field colR:Int =110
    Field colG:Int =110
    Field ColB:Int =110
	Field EnterPressed:Int = 0
	Field _UpdateFunc_()
	Field TeamNames:String[5]
	Field TeamColors:TPlayerColor[5]

    Function Create:TGUIChat(x:Int, y:Int, width:Int, height:Int = 50, enabled:Byte = 1, maxlength:Int = 128, State:String = "")
		Local GUIChat:TGUIChat=New TGUIChat
			GUIChat.pos.setXY( x,y )
			GUIChat.BaseInit()
		 GUIChat._enabled = enabled
		 If width < 40 Then width = 40
		 GUIChat.dimension.setXY( width, height )
		 GUIChat.uid      = Rand(1,10000)
		 GUIChat.maxlength= maxlength
		 GUIChat.typ      = "list"
		 GUIChat.PosChangeTimer  = MilliSecs()
		 GUIChat.ListStartsAtPos = 0
		 GUIChat.ListPosClicked = -1
		 GUIChat.GUIInput:TGUIinput = New TGUIinput
		 GUIChat.ParentGUIObject = GUIChat
		 GUIChat.GUIInput.pos.setXY( x+8, y+height-26 -3)
		 GUIChat.GUIInput.dimension.setXY( width-30, 20 )
		 GUIChat.GUIInput.uid = GUIchat.uid
		 GUIChat.GUIInput.maxlength = 100
		 GUIChat.GUIInput.typ$     = "input"
		 GUIChat.GUIInput.color.adjust(50,50,50, True)

		 GUIchat.GUIInput.nobackground = 1
'		 guichat.guichatgfx = 1
		 GUIchat.nobackground = 1


		 GUIChat.GUIbackground:TGUIbackground = New TGUIbackground
		 GUIChat.GUIbackground.pos.setXY( x,y )
		 GUIChat.GUIbackground.dimension.setXY( width, height )
		 GUIChat.GUIbackground.typ$     = "background"
		 GUIchat.AutoScroll  = 1

		 GUIChat.forstateonly = State$


	     If Not guichat.EntryList Then guichat.EntryList = CreateList()

		GUIManager.Add( GUIChat )
	  	 Return GUIChat
	End Function

   	Method Update()
		Self.EnterPressed = Self.GUIInput.EnterPressed
		Self.GUIInput.Update()
		If Self.EnterPressed = 1 Then GUIManager.setActive(Self.uid)
		_UpdateFunc_()
       If GUIManager.getActive() = uid Then on = 1 Else on = 0
	End Method


	Method Draw()
		Local SpaceAvaiable:Int = 0
		Local i:Int =0
		Local chatinputheight:Int
		Local Zeit : Int = MilliSecs()
		Local printvalue:String
		Local charcount:Int
		Local charpos:Int
		Local lineprintvalue:String=""
	   If nobackground = 0
			GUIbackground.pos.setPos(Self.pos)
			GUIbackground.dimension.setPos(self.dimension)

                 GUIbackground.Draw()
                 chatinputheight = 0
	   Else
	    If guichatgfx > 0
			gfx_GuiPack.GetSprite("Chat_Top").Draw(Self.pos.x, Self.pos.y)
			gfx_GuiPack.GetSprite("Chat_Middle").TileDraw(Self.pos.x, Self.pos.y + gfx_GuiPack.GetSprite("Chat_Top").h, gfx_GuiPack.GetSprite("Chat_Middle").w, Self.dimension.y - gfx_GuiPack.GetSprite("Chat_Top").h - gfx_GuiPack.GetSprite("Chat_Input").h)
			gfx_GuiPack.GetSprite("Chat_Input").Draw(Self.pos.x, Self.pos.y + Self.dimension.y, 0, 1)
	    EndIf
	    chatinputheight = 35
  	   EndIf
		'SetViewport(Self.pos.x,Self.pos.y,width-18, height)
		SpaceAvaiable = Self.dimension.y 'Hoehe der Liste
	    i = 0

		Local displace:Float = 0.0
	    For Local Entries:TGUIListEntries = EachIn EntryList 'Liste hier global
          If fadeout Then SetAlpha (7 - Float(MilliSecs() - Entries.time)/1000)
		  If i > ListStartsAtPos-1 Then
	  	    If AutoScroll=1 And Self.useFont.getHeight(Entries.value$) > SpaceAvaiable-chatinputheight
				ListStartsAtPos :+1
			EndIf
	  	    If Self.useFont.getHeight(Entries.value$) < SpaceAvaiable-chatinputheight
              Local playerID:Int = Int(Entries.team)

				Local dimension:TPosition
				Local nameWidth:Float=0.0
				Local blockHeight:Float = 0.0

				For Local i:Int = 0 To 1
					If i = 1
						SetAlpha 0.3
						SetColor 0,0,0
						DrawRect(Self.pos.x, Self.pos.y+displace, self.dimension.x, blockHeight)
						SetColor 255,255,255
						SetAlpha 1.0
					EndIf

					If PlayerID > 0
						dimension = TPosition(Self.useFont.drawStyled(Self.TeamNames[PlayerID]+": ", Self.pos.x+2, Self.pos.y+displace +2, TeamColors[PlayerID].colR,TeamColors[PlayerID].colG,TeamColors[PlayerID].ColB, 2,2, i))
					Else
						dimension = TPosition(Self.useFont.drawStyled("System:", Self.pos.x+2, Self.pos.y+displace +2, 50,50,50, 2,2, i))
					EndIf
					nameWidth = dimension.x
					blockHeight = Self.useFont.drawBlock(Entries.value, Self.pos.x+2+nameWidth, Self.pos.y+displace +2, self.dimension.x - nameWidth, SpaceAvaiable, 0, 255,255,255,0,2, i)

					If i = 1 Then displace:+blockHeight
				Next
            EndIf
          EndIf
          i= i+1
          If fadeout Then SetAlpha (1)
          If fadeout And (7 - Float(MilliSecs() - Entries.time)/1000) <=0 Then EntryList.Remove(Entries)
  		Next

           GUIInput.Draw()

		Local guiListControl:TGW_Sprites = gfx_GuiPack.GetSprite("ListControl")
	   If nobackground = 0
		For i = 0 To Ceil(Self.dimension.y / guiListControl.frameh) - 1
  		  guiListControl.Draw(Self.pos.x + self.dimension.x - guiListControl.framew, Self.pos.y + i * guiListControl.frameh, 7)
		Next
        If GUIManager.getActive() = uid And self.mouseIsDown And self.clicked and Self.clicked.x >= Self.pos.x+self.dimension.x-14 And Self.clicked.y <= Self.pos.y+14
          guiListControl.Draw(Self.pos.x + self.dimension.x - 14, Self.pos.y, 1)
          If PosChangeTimer + 250 < Zeit And ListStartsAtPos > 0
            ListStartsAtPos = ListStartsAtPos -1
            PosChangeTimer = Zeit
          EndIf
	    Else
	      guiListControl.Draw(Self.pos.x + self.dimension.x - 14, Self.pos.y, 0)
        EndIf

        If GUIManager.getActive() = uid And self.mouseIsDown And self.clicked and Self.clicked.x >= Self.pos.x+self.dimension.x-14 And Self.clicked.y >= Self.pos.y+Self.dimension.y-14
          guiListControl.Draw(Self.pos.x + self.dimension.x - 14, Self.pos.y + Self.dimension.y - 14, 5)
          If PosChangeTimer + 250 < Zeit And ListStartsAtPos < Int(EntryList.Count() - 2)
            ListStartsAtPos = ListStartsAtPos + 1
            PosChangeTimer = Zeit
          EndIf
        Else
          guiListControl.Draw(Self.pos.x + self.dimension.x - 14, Self.pos.y + Self.dimension.y - 14, 4)
		EndIf
	EndIf 'nobackground

		SetColor 255,255,255
	  '  debuglog ("GUIList zeichnen")
	End Method

End Type
