SuperStrict
'Author: Ronny Otto
Import "basefunctions.bmx"
Import "basefunctions_sprites.bmx"
Import "basefunctions_keymanager.bmx"
Import "basefunctions_localization.bmx"
Import "basefunctions_resourcemanager.bmx"
Import "basefunctions_events.bmx"


''''''GUIzeugs'
CONST EVENT_GUI_CLICK:int		= 1
CONST EVENT_GUI_DOUBLECLICK:int = 2

Global gfx_GuiPack:TGW_SpritePack = TGW_SpritePack.Create(LoadImage("grafiken/GUI/guipack.png"), "guipack_pack")
gfx_GuiPack.AddAnimSpriteMultiCol("ListControl", 96, 0, 56, 28, 14, 14, 8)
gfx_GuiPack.AddAnimSpriteMultiCol("DropDown", 160, 0, 126, 42, 14, 14, 21)
gfx_GuiPack.AddSprite("Slider", 0, 30, 112, 14, 8)
gfx_GuiPack.AddSprite("Chat_IngameOverlay", 0, 60, 504, 20)
gfx_GuiPack.AddSprite("Chat_Top", 0, 80, 445, 20)
gfx_GuiPack.AddSprite("Chat_Middle", 0, 100, 445, 50)
gfx_GuiPack.AddSprite("Chat_Bottom", 0, 142, 445, 35)
gfx_GuiPack.AddSprite("Chat_Input", 0, 186, 445, 35)

Type TGUIManager
	Field Defaultfont:TBitmapFont
	Field globalScale:Float		= 1.0
	Field MouseIsHit:Int 		= 0
	Field MouseIsDown:Int 		= 0
	Field List:TList			= CreateList()

	Function Create:TGUIManager()
		Local obj:TGUIManager = New TGUIManager

		Return obj
	End Function

	Method Add(GUIobject:TGUIobject)
		Self.List.AddLast(GUIobject)
		Self.List.sort(True, Self.SortObjects)
	End Method

	Function SortObjects:Int(ob1:Object, ob2:Object)
		Local objA:TGUIobject = TGUIobject(ob1)
		Local objB:TGUIobject = TGUIobject(ob2)

		If Not objB Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
		If GUIManager.getActive() = objB._id then Return - 1 Else Return 1
		If objB._visible = 0
			If objB.Zindex <= objA.ZIndex then Return 0 else Return -1
		EndIf
		If objB.ZIndex <= objA.ZIndex Then Return 1 Else Return 0
	End Function

	Method isActive:Int(id:Int)
		Return id = TGUIObject._activeID
	End Method

	Method getActive:Int()
		Return TGUIObject._activeID
	End Method

	Method setActive(id:Int)
		TGUIObject._activeID = id
	End Method

	Method Remove(guiobject:TGUIObject)
		Self.List.remove(guiobject)
	End Method


	Method Update(State:String = "", updatelanguage:Int = 0, fromZ:Int=-1000, toZ:Int=-1000)
		'sort needed ? should be done during adding
		'List.Sort()

		'store mouse button 1 state
		If MOUSEMANAGER.IsHit(1) Then MouseIsHit = 1 Else MouseIsHit = 0
		If MOUSEMANAGER.IsDown(1) Then MouseIsDown = 1 Else MouseIsDown = 0

		For Local obj:TGUIobject = EachIn Self.List
			'skip if not visible
			If not ( (toZ = -1000 Or obj.zIndex <= toZ) And (fromZ = -1000 Or obj.zIndex >= fromZ)) then continue
			'skip if not set visible or different state
			If obj._visible = 0 or (State <> obj.forstateonly And State <> "") then continue

			If obj.clickable
				If State <> obj.forstateonly Or Not functions.isIn( MouseX(), MouseY(), obj.pos.x, obj.pos.y, obj.dimension.x, obj.dimension.y )
					obj.mouseIsDown = null
					obj.clicked = null
					obj.mouseover = 0
					obj.setState("")
				'	If MouseIsHit And obj.isActive() Then Self.setActive(0)
				EndIf
				If functions.isIn(MouseX(), MouseY(), obj.pos.x, obj.pos.y, obj.dimension.x, obj.dimension.y)
					If MouseIsDown And obj._enabled and Self.getActive() <> obj._id
						Self.setActive(obj._id)
						'print Millisecs() +": set2 active " + TTypeId.ForObject( obj )
						obj.EnterPressed = 1
						obj.MouseIsDown = TPosition.Create( MouseX(), MouseY() )
						MouseIsDown = 0 'we found the gui element accepting the down-event
					EndIf
					obj.mouseover = 1

					If obj._enabled
						If MouseIsDown Or obj.MouseIsDown Then obj.setState("active") Else obj.setState("hover")

						If MOUSEMANAGER.isUp(1) And obj.MouseIsDown
							obj.Clicked = TPosition.Create( MouseX(), MouseY() )
							'fire onClickEvent
							If obj._enabled then EventManager.registerEvent( TEventSimple.Create( "guiobject.OnClick", TData.Create().AddNumber("type", 1), obj ) )
							'added for imagebutton and arrowbutton not being reset when mouse standing still
							obj.MouseIsDown = null
						EndIf
					EndIf
				EndIf
			EndIf
			If obj.value = "" Then obj.value = "  "
			If obj.backupvalue = "x" Then obj.backupvalue = obj.value
			If updatelanguage Or Chr(obj.value[0] ) = "_" Then If Chr(obj.backupvalue[0] ) = "_" Then obj.value = Localization.GetString(Right(obj.backupvalue, Len(obj.backupvalue) - 1))

			EventManager.registerEvent( TEventSimple.Create( "guiobject.onUpdate", null, obj ) )
			obj.Update()
		Next
	End Method

	Method DisplaceGUIobjects(State:String = "", x:Int = 0, y:Int = 0)
		For Local obj:TGUIobject = EachIn Self.List
			If State = obj.forstateonly then obj.pos.MoveXY( x,y )
		Next
	End Method

	Method Draw:Int(State:String = "", updatelanguage:Int = 0, fromZ:Int=-1000, toZ:Int=-1000)
		For Local obj:TGUIobject = EachIn Self.List
			'skip if not visible
			If not ( (toZ = -1000 Or obj.zIndex <= toZ) And (fromZ = -1000 Or obj.zIndex >= fromZ)) then continue
			'skip if not set visible or different state
			If obj._visible = 0 or (State <> obj.forstateonly And State <> "") then continue

			obj.Draw()
		Next
	End Method

End Type

Global GUIManager:TGUIManager = TGUIManager.Create()


Type TGUIobject
	Field pos:TPosition				= TPosition.Create(-1,-1)
	Field dimension:TPosition		= TPosition.Create(-1,-1)
	Field zIndex:Int
	Field scale:Float				= 1.0
	Field align:Int					= 0 			'alignment of object
	Field state:String				= ""
	Field value:String				= ""
	Field backupvalue:String		= "x"
	Field clicked:TPosition			= null			'null = not clicked
	Field mouseIsDown:TPosition		= TPosition.Create(-1,-1)
	Field EnterPressed:Int=0
	Field on:Int
	Field clickable:Int				= 1
	Field mouseover:Int				= 0			'could be done with TPosition
	Field _id:Int
	Field _enabled:Int				= 1
	Field _visible:Int				= 1
	Field forstateonly:String		= ""		'fuer welchen gamestate anzeigen
	Field useFont:TBitmapFont

	global _activeID:int			= 0
	global _lastID:int

	Method New()
		self._id	= self.GetNextID()
		self.scale	= GUIManager.globalScale
		self.BaseInit(null)
	End Method

	Method BaseInit(useFont:TBitmapFont=Null)
		If useFont = Null Then Self.useFont = GUIManager.defaultFont Else Self.useFont = useFont
	End Method

	Function GetNextID:Int()
		TGUIobject._lastID:+1
		Return TGUIobject._lastID
	End Function

	'returns true if clicked
	'resets clicked value!
	Method getClicks:Int()
		If not Self._enabled Then Self.Clicked = null

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

	Method isActive:int()
		return self._id = self._activeID
	End Method

	Method SetZIndex(zindex:Int)
		Self.zIndex = zindex
		GUIManager.list.sort()
	End Method

	Method SetState(state:String="")
		If state <> "" Then state = "."+state
		Self.state = state
	End Method

	'eg. for buttons/inputfields/dropdownbase...
	Method DrawBaseForm(identifier:string, x:float, y:float)
		SetScale Self.scale, Self.scale
		Assets.GetSprite(identifier+".L").Draw(x,y)
		Assets.GetSprite(identifier+".M").TileDrawHorizontal(x + Assets.GetSprite(identifier+".L").w*Self.scale, y, self.dimension.x - ( Assets.GetSprite(identifier+".L").w + Assets.GetSprite(identifier+".R").w)*self.scale, Self.scale)
		Assets.GetSprite(identifier+".R").Draw(x + self.dimension.x, y, -1, VALIGN_BOTTOM, ALIGN_LEFT, self.scale)
		SetScale 1.0,1.0
	End Method

	Method DrawBaseFormText(_value:string, x:float, y:float)
		local col:TColor = TColor.create(100,100,100)
		if Self.mouseover Then col = TColor.create(50,50,50)
		if not self._enabled then col = TColor.create(150,150,150)

		self.useFont.drawStyled(_value,x,y, col.r, col.g, col.b, 1, 0, 1, 0.5)
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

        If KEYWRAPPER.pressedKey(186) then If shiftPressed Then value:+ "Ü" Else value :+ "ü"
        If KEYWRAPPER.pressedKey(192) then If shiftPressed Then value:+ "Ö" Else value :+ "ö"
        If KEYWRAPPER.pressedKey(222) then If shiftPressed Then value:+ "Ä" Else value :+ "ä"

        If KEYWRAPPER.pressedKey(48) then If shiftPressed Then value :+ "=" Else value :+ "0"
        If KEYWRAPPER.pressedKey(49) then If shiftPressed Then value :+ "!" Else value :+ "1"
        If KEYWRAPPER.pressedKey(50) then If shiftPressed Then value :+ Chr(34) Else value :+ "2"
        If KEYWRAPPER.pressedKey(51) then If shiftPressed Then value :+ "§" Else value :+ "3"
        If KEYWRAPPER.pressedKey(52) then If shiftPressed Then value :+ "$" Else value :+ "4"
        If KEYWRAPPER.pressedKey(53) then If shiftPressed Then value :+ "%" Else value :+ "5"
        If KEYWRAPPER.pressedKey(54) then If shiftPressed Then value :+ "&" Else value :+ "6"
        If KEYWRAPPER.pressedKey(55) then If shiftPressed Then value :+ "/" Else value :+ "7"
        If KEYWRAPPER.pressedKey(56) then If shiftPressed Then value :+ "(" Else value :+ "8"
        If KEYWRAPPER.pressedKey(57) then If shiftPressed Then value :+ ")" Else value :+ "9"
        If KEYWRAPPER.pressedKey(219) And shiftPressed Then value :+ "?"
        If KEYWRAPPER.pressedKey(219) And altGrPressed Then value :+ "\"
        If KEYWRAPPER.pressedKey(219) And Not altGrPressed And Not shiftPressed Then value :+ "ß"

        If KEYWRAPPER.pressedKey(221) then If shiftPressed Then value :+ "`" Else value :+ "´"
	    If KEYWRAPPER.pressedKey(188) then If shiftPressed Then value :+ ";" Else value :+ ","
	    If KEYWRAPPER.pressedKey(189) then If shiftPressed Then value :+ "_" Else value :+ "-"
	    If KEYWRAPPER.pressedKey(190) then If shiftPressed Then value :+ ":" Else value :+ "."
        If KEYWRAPPER.pressedKey(226) then If shiftPressed Then value :+ ">" Else value :+ "<"
        If KEYWRAPPER.pressedKey(KEY_BACKSPACE) then value = value[..value.length -1]
	    If KEYWRAPPER.pressedKey(106) then value :+ "*"
	    If KEYWRAPPER.pressedKey(111) then value :+ "/"
	    If KEYWRAPPER.pressedKey(109) then value :+ "-"
	    If KEYWRAPPER.pressedKey(109) then value :+ "-"
	    If KEYWRAPPER.pressedKey(110) then value :+ ","
	    For Local i:Int = 0 To 9
			If KEYWRAPPER.pressedKey(96+i) Then value :+ "0"
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
		obj.dimension.SetXY(width, Assets.GetSprite("gfx_gui_button.L").h * obj.scale )
		obj.zindex		= 10
		obj.value		= value
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
	        If MouseIsDown And self._enabled Then on = 1 Else on = 0
			'no mouse within button-regions, so button not clicked
			If Not MouseOver Then on = 0
		EndIf
		If not Self._enabled
			self.on = 2
			self.clicked = null
			self.mouseover = null
		endif
	End Method

	Method Draw()
		SetColor 255, 255, 255

		self.DrawBaseForm("gfx_gui_button"+Self.state, Self.pos.x,Self.pos.y)

		Local TextX:Float = Ceil(Self.pos.x + 10)
		Local TextY:Float = Ceil(Self.pos.y - (Self.useFont.getHeight("ABC") - self.dimension.y) / 2)
		If textalign = 1 Then TextX = Ceil(Self.pos.x + (Self.dimension.x - Self.useFont.getWidth(value)) / 2)

		self.DrawBaseFormText(value, TextX, TextY)
	End Method

End Type

Type TGUIImageButton Extends TGUIobject
	Field startframe:Int = 0
	Field spriteBaseName:String = ""

	Function Create:TGUIImageButton(x:Int, y:Int, width:Int, Height:Int, spriteBaseName:String, on:Byte = 0, enabled:Byte = 1, State:String = "", startframe:Int = 0)
		Local obj:TGUIImageButton = New TGUIImageButton
		obj.pos.setXY( x,y )
		obj.on      = on
		obj._enabled = enabled
		obj.spriteBaseName = spriteBaseName
		obj.startframe = startframe
		obj.dimension.setXY( Assets.getSprite(spriteBaseName).w, Assets.getSprite(spriteBaseName).h )
		obj.value$  = ""
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
        If not self._enabled
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
		obj.dimension.setXY( width, height )
		obj.value		= value
		obj.zindex		= 0
		obj.forstateonly = State
		obj.clickable	= 0 'by default not clickable
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
		Assets.GetSprite("gfx_gui_box_context.TR").Draw(Self.pos.x + self.dimension.x, Self.pos.y, -1, VALIGN_BOTTOM, ALIGN_LEFT, self.scale)
		addY = Assets.GetSprite("gfx_gui_box_context.TM").h * scale

		Assets.GetSprite("gfx_gui_box_context.ML").TileDrawVertical(Self.pos.x,Self.pos.y + addY, self.dimension.y - addY - (Assets.GetSprite("gfx_gui_box_context.BL").h*Self.scale), Self.scale )
		Assets.GetSprite("gfx_gui_box_context.MM").TileDraw(Self.pos.x + Assets.GetSprite("gfx_gui_box_context.ML").w*Self.scale, Self.pos.y + addY, self.dimension.x - Assets.GetSprite("gfx_gui_box_context.BL").w*scale - Assets.GetSprite("gfx_gui_box_context.BR").w*scale,  self.dimension.y - addY - (Assets.GetSprite("gfx_gui_box_context.BL").h*Self.scale), Self.scale )
		Assets.GetSprite("gfx_gui_box_context.MR").TileDrawVertical(Self.pos.x + self.dimension.x - Assets.GetSprite("gfx_gui_box_context.MR").w*Self.scale,Self.pos.y + addY, self.dimension.y - addY - (Assets.GetSprite("gfx_gui_box_context.BR").h*Self.scale), Self.scale )


		addY = self.dimension.y - Assets.GetSprite("gfx_gui_box_context.BM").h * scale

		'buggy "line" zwischen bottom und tiled bg
		addY :-1

		Assets.GetSprite("gfx_gui_box_context.BL").Draw(Self.pos.x,Self.pos.y + addY)
		Assets.GetSprite("gfx_gui_box_context.BM").TileDrawHorizontal(Self.pos.x + Assets.GetSprite("gfx_gui_box_context.BL").w*Self.scale, Self.pos.y + addY, self.dimension.x - Assets.GetSprite("gfx_gui_box_context.TL").w*Self.scale - Assets.GetSprite("gfx_gui_box_context.BR").w*Self.scale, Self.scale)
		Assets.GetSprite("gfx_gui_box_context.BR").Draw(Self.pos.x + self.dimension.x, Self.pos.y +  addY, -1, VALIGN_BOTTOM, ALIGN_LEFT, self.scale)

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

	Function Create:TGUIArrowButton(x:Int,y:Int, direction:Int=0, on:Byte = 0, enabled:Byte = 1, State:String="", align:Int = 0)
		Local obj:TGUIArrowButton=New TGUIArrowButton
		obj.pos.setXY( x,y)
		obj.on      	= on
		obj._enabled 	= enabled
		select direction
			case 0		obj.direction="left"
			case 1		obj.direction="up"
			case 2		obj.direction="right"
			case 3		obj.direction="down"
			default		obj.direction="left"
		endselect

		obj.zindex		= 40
		obj.dimension.setXY( Assets.GetSprite("gfx_gui_arrow_"+obj.direction).w * obj.scale, Assets.GetSprite("gfx_gui_arrow_"+obj.direction).h * obj.scale )
		obj.value		= ""
		obj.forstateonly= State
		obj.setAlign(align)

		GUIManager.Add( obj )
		Return obj
	End Function

	Method setAlign(align:Int=0)
		If Self.align <> align
			If Self.align = 0 And align = 1 then Self.pos.setX( Self.pos.x - Self.dimension.x )
			If Self.align = 1 And align = 0 then Self.pos.setX( Self.pos.x + Self.dimension.x )
		EndIf
	End Method

	Method Update()
        If MouseIsDown And Not self._enabled Then on = 1 Else on = 0
        If not self._enabled
			self.Clicked = null
			self.on = 2
		endif
	End Method

	Method Draw()
		If self.on >= 2 then return

		SetColor 255,255,255
		SetScale Self.scale, Self.scale
		Assets.GetSprite("gfx_gui_arrow_"+Self.direction+Self.state).Draw(Self.pos.x, Self.pos.y)
		SetScale 1.0, 1.0
	End Method

End Type

Type TGUISlider  Extends TGUIobject
    Field minvalue:Int
    Field maxvalue:Int
    Field actvalue:Int = 50
    Field addvalue:Int = 0
    Field drawvalue:Int = 0

	Function Create:TGUISlider(x:Int, y:Int, width:Int, minvalue:Int, maxvalue:Int, enabled:Byte = 1, value:String, State:String = "")
		Local obj:TGUISlider = New TGUISlider
		obj.BaseInit()
		obj.pos.setXY( x,y )
		obj.on			= 0
		obj._enabled	= enabled
		If width < 0 Then width = TextWidth(value) + 8
		obj.dimension.setXY( width, gfx_GuiPack.GetSprite("Button").frameh )
		obj.value		= value
		obj.minvalue	= minvalue
		obj.maxvalue	= maxvalue
		obj.actvalue	= minvalue
		obj.forstateonly= State

		GUIMAnager.Add( obj )
		Return obj
	End Function

	Method Update()
		If MouseIsDown Then on = 1 Else on = 0
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
		Local sprite:TGW_Sprites = gfx_GuiPack.GetSprite("Slider")

		Local PixelPerValue:Float = self.dimension.x / (maxvalue - 1 - minvalue)
	    Local actvalueX:Float = actvalue * PixelPerValue
	    Local maxvalueX:Float = (maxvalue) * PixelPerValue
		Local difference:Int = actvalueX '+ PixelPerValue / 2

		If on
			difference = MouseX() - Self.pos.x + PixelPerValue / 2
			actvalue = Float(difference) / PixelPerValue
			If actvalue > maxvalue Then actvalue = maxvalue
			If actvalue < minvalue Then actvalue = minvalue
			actvalueX = difference'actvalue * PixelPerValue
			If actvalueX >= maxValueX - sprite.framew Then actvalueX = maxValueX - sprite.framew
		EndIf

  		If Ceil(actvalueX) < sprite.framew
			'links an
			sprite.DrawClipped( self.pos.x, self.pos.y, Self.pos.x, Self.pos.y, Ceil(actvalueX) + 5, sprite.frameh, 0, 0, 4)
			'links aus
  		    sprite.DrawClipped( Self.pos.x, Self.pos.y, Self.pos.x + Ceil(actvalueX) + 5, Self.pos.y, sprite.framew, sprite.frameh, 0, 0, 0)
		Else
			sprite.Draw( Self.pos.x, Self.pos.y, 4 )
		EndIf
  		If Ceil(actvalueX) > self.dimension.x - sprite.framew
			sprite.DrawClipped( Self.pos.x + self.dimension.x - sprite.framew, Self.pos.y, Self.pos.x + self.dimension.x - sprite.framew, Self.pos.y, Ceil(actvalueX) - (self.dimension.x - sprite.framew) + 5, sprite.frameh, 0, 0, 6)                        								'links an
  		    'links aus
  		    sprite.DrawClipped( Self.pos.x + self.dimension.x - sprite.framew, Self.pos.y, Self.pos.x + actvalueX + 5, Self.pos.y, sprite.framew, sprite.frameh, 0, 0, 2 )
		Else
			sprite.Draw( Self.pos.x + self.dimension.x, Self.pos.y, 2, VALIGN_BOTTOM, ALIGN_LEFT )
		EndIf


		' middle
		'      \
		' [L][++++++()-----][R]
		' MaxWidth = GuiObj.w - [L].w - [R].w
		local maxWidth:float = self.dimension.x - 2*sprite.framew
		local reachedWidth:float = Min(maxWidth, actvalueX - sprite.framew)
		local missingWidth:float = maxWidth - reachedWidth
		'gefaerbter Balken
		sprite.TileDrawHorizontal(Self.pos.x + sprite.framew, self.pos.y, reachedWidth, self.scale, 1+4)
		'ungefaerbter Balken
		if missingWidth > 0 then sprite.TileDrawHorizontal(Self.pos.x + sprite.framew + reachedWidth, self.pos.y, missingWidth, self.scale, 1)

	    'dragger  -5px = Mitte des Draggers
		sprite.Draw( Self.pos.x + Ceil(actvalueX - 5), Self.pos.y, 3 + on * 4)


		'draw label/text
		if self.value = "" then return

		local drawText:string = self.value
		If drawvalue <> 0 then drawText = (actvalue + addvalue) + " " + drawText

		Self.Usefont.Draw(value, Self.pos.x+self.dimension.x+7, Self.pos.y- (Self.useFont.getHeight(drawText) - self.dimension.y) / 2 - 1)
	End Method

End Type

Type TGUIinput Extends TGUIobject
    Field maxLength:Int
    Field maxTextWidth:Int
    Field nobackground:Int
    Field color:TColor = TColor.Create(0,0,0)
    Field OverlayImage:TGW_Sprites	= Null
    Field InputImage:TGW_Sprites	= Null	  'own Image for Inputarea
    Field OverlayColor:TColor		= TColor.Create(200,200,200, 0.5)
	Field TextDisplacement:TPosition = TPosition.Create(5,5)

    Function Create:TGUIinput(x:Int, y:Int, width:Int, enabled:Byte = 1, value:String, maxlength:Int = 128, State:String = "", useFont:TBitmapFont = Null)
		Local obj:TGUIinput = New TGUIinput
		obj.BaseInit(UseFont)
		obj.pos.setXY( x,y )
		obj._enabled	= enabled
		obj.zindex		= 20
		obj.dimension.setXY( Max(width, 40), Assets.GetSprite("gfx_gui_input.L").h * obj.scale )
		obj.maxTextWidth= obj.dimension.x - 15
		obj.value		= value
		obj.maxlength	= maxlength
		obj.forstateonly = State
		obj.EnterPressed = 0
		obj.nobackground = 0
		obj.color = TColor.Create(100,100,100)

		GUIMAnager.Add( obj )
	  	Return obj
	End Function


	Method Update()
		If self._enabled
			If EnterPressed >= 2
				EnterPressed = 0
				GUIManager.setActive(0)
				print "disable"
			EndIf
			If GUIManager.isActive(Self._id) Then value = Input2Value(value)
		EndIf
		If GUIManager.isActive(self._id)
			self.on = 1
			self.setState("active")
		Else
			self.on = 0
		endif

		If not self._enabled then self.on = 0

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

		If not self._enabled then SetColor 225, 255, 150
		SetScale Self.scale, Self.scale

		If nobackground = 0
			'draw base buttonstyle
			self.DrawBaseForm("gfx_gui_input"+Self.state, Self.pos.x,Self.pos.y)

			'center overlay over left frame
			If OverlayImage <> Null
				Local Left:Float = ( ( Assets.GetSprite("gfx_gui_input"+Self.state+".L").w - OverlayImage.w ) / 2 ) * Self.scale
				Local top:Float = ( ( Assets.GetSprite("gfx_gui_input"+Self.state+".L").h - OverlayImage.h ) / 2 ) * Self.scale
				OverlayImage.Draw( Self.pos.x + Left, Self.pos.y + top )
			EndIf
		Else
			If GUIManager.getActive() = self._id
				If InputImage = Null
					OverlayColor.setRGBA()
					DrawRect Self.pos.x, Self.pos.y + 4, self.dimension.x, self.dimension.y
					SetAlpha 1
					SetColor 255, 255, 255
				Else
					InputImage.Draw(Self.pos.x, Self.pos.y)
				EndIf
			EndIf
			i = (self.dimension.x / 34) - 1
		EndIf
		SetScale 1.0,1.0

		Local useMaxTextWidth:Int = Self.maxTextWidth
		If Self.useFont = Null Then Self.BaseInit() 'item not created with create but new
		Self.textDisplacement.y = (self.dimension.y - Self.useFont.getHeight("abcd")) /2

        If OverlayImage <> Null
			useTextDisplaceX :+ OverlayImage.framew * Self.scale
			useMaxTextWidth :-  OverlayImage.framew * Self.scale
		EndIf
		local textPosX:int = ceil( Self.pos.x + usetextDisplaceX + 2 )
		local textPosY:int = ceil( Self.pos.y + Self.textDisplacement.y )

		If on = 1
			Self.color.set()
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

'data objects for gui objects (eg. dropdown entries, list entries, ...)
Type TGUIEntry
	Field formatValue:String = "#value"		'how to format value
	Field id:Int							'internal gui id
	Field data:TData						'custom data

	Function Create:TGUIEntry(data:TData=null)
		Local obj:TGUIEntry = New TGUIEntry
		obj.data	= data
		obj.id		= TGUIObject.getNextID()
		Return obj
	End Function

	Method setFormatValue(newValue:string)
		self.formatValue = newValue
	End Method

	Method getValue:string()
		return self.data.getString("value", "")
	End Method

End Type

Type TGUIDropDown Extends TGUIobject
    Field Values:String[]
	Field EntryList:TList = CreateList()
    Field PosChangeTimer:Int
	Field clickedEntryID:Int=-1
	Field hoveredEntryID:int=-1
	Field textalign:Int = 0

	Function Create:TGUIDropDown(x:Int, y:Int, width:Int = -1, on:Byte = 0, enabled:Byte = 1, value:String, State:String = "", UseFont:TBitmapFont = Null)
		Local obj:TGUIDropDown=New TGUIDropDown
		obj.BaseInit(UseFont)
		obj.pos.setXY( x,y )
		obj.on			= 0	'open or closed dropdown?
		obj._enabled	= enabled

		If width < 0 Then width = obj.useFont.getWidth(value) + 8
		obj.dimension.setXY( width, Assets.GetSprite("gfx_gui_dropdown.L").frameh * obj.scale)
		obj.value		= value
		obj.forstateonly= State

		GUIManager.Add( obj )
		Return obj
	End Function


	Method SetActiveEntry(id:Int)
		Self.clickedEntryID = id
		Self.value = TGUIEntry(Self.EntryList.ValueAtIndex(id)).getValue()
	End Method

	Method Update()
        If self.isActive() Then on = 1 Else on = 0

        If not self._enabled
			self.on = 2
			self.clicked = null
		endif

		if self.on = 0 then return

		local currentAddY:Int = self.dimension.y
		local lineHeight:float = Assets.GetSprite("gfx_gui_dropdown_list_entry.L").h*self.scale

		'reset hovered item id ...
		self.hoveredEntryID = -1

		'check new hovered or clicked items
		For Local Entry:TGUIEntry = EachIn self.EntryList 'Liste hier global
			If functions.MouseIn( Self.pos.x, Self.pos.y + currentAddY, self.dimension.x, lineHeight)
				If GUIManager.MouseIsHit
					value			= Entry.getValue()
					clickedEntryID	= Entry.id
					on				= 0			'close it
					GUIManager.setActive(0)
					EventManager.registerEvent( TEventSimple.Create( "guiobject.OnChange", TData.Create().AddNumber("entryID", entry.id), self ) )
					GUIManager.MouseIsHit = 0
					Exit
				else
					hoveredEntryID	= Entry.id
				endif
			EndIf
			currentAddY:+ lineHeight
		Next

		if hoveredEntryID > 0
			GUIManager.setActive(self._id)
			self.setState("hover")
		else
			'clicked outside of list
			if GUIManager.MouseIsHit and self.isActive() then GUIManager.setActive(0)
		EndIf

	End Method

	Method AddEntry(value:String)
		local entry:TGUIEntry = TGUIEntry.Create( TData.Create().AddString("value", value) )
		EntryList.AddLast(entry)
		If Self.value = "" Then Self.value = entry.getValue()
		If Self.clickedEntryID = -1 Then Self.clickedEntryID = entry.id
	End Method


	Method Draw()
	    Local i:Int					= 0
	    Local j:Int					= 0
	    Local useheight:Int			= 0
	    Local printheight:Int		= 0

		'draw list if enabled
		If on = 1 And self._enabled 'ausgeklappt zeichnen
			useheight = self.dimension.y
			For Local Entry:TGUIEntry = EachIn self.EntryList
				if self.EntryList.last() = Entry
					self.DrawBaseForm( "gfx_gui_dropdown_list_bottom", Self.pos.x, Self.pos.y + useheight )
				else
					self.DrawBaseForm( "gfx_gui_dropdown_list_entry", Self.pos.x, Self.pos.y + useheight )
				endif

				SetColor 100,100,100

				If Entry.id = self.clickedEntryID then SetColor 0,0,0
				If Entry.id = self.hoveredEntryID then SetColor 150,150,150

				If textalign = 1 Then self.useFont.Draw( Entry.getValue(), Self.pos.x + (self.dimension.x - self.useFont.getWidth( Entry.GetValue() ) ) / 2, Self.pos.y + useheight + 5)
				If textalign = 0 Then self.useFont.Draw( Entry.getValue(), Self.pos.x + 10, Self.pos.y + useHeight + 5)
				SetColor 255,255,255

				'move y to next spot
				if self.EntryList.last() = Entry
					useheight:+ Assets.GetSprite("gfx_gui_dropdown_list_bottom.L").h*self.scale
				else
					useheight:+ Assets.GetSprite("gfx_gui_dropdown_list_entry.L").h*self.scale
				endif
			Next
		endif

		'draw base button
		self.DrawBaseForm( "gfx_gui_dropdown"+Self.state, Self.pos.x, Self.pos.y )

		'text on button

		If on Or not self._enabled
			If not self._enabled Then SetAlpha 0.7
			self.DrawBaseFormText(value, Self.pos.x + 10, Self.pos.y + self.dimension.y/2 - self.useFont.getHeight(value)/2)
			If not self._enabled Then SetAlpha 1.0
	    Else
			self.DrawBaseFormText(value, Self.pos.x + 10, Self.pos.y + self.dimension.y/2 - self.useFont.getHeight(value)/2)
		EndIf
		SetColor 255, 255, 255

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
		'scale in both dimensions ()
		obj.dimension.setXY( Assets.GetSprite("gfx_gui_ok_off").w * obj.scale, Assets.GetSprite("gfx_gui_ok_off").h * obj.scale)
		'store assetWidth to have dimension.x store "whole widget"
		obj.assetWidth	= Assets.GetSprite("gfx_gui_ok_off").w
		obj.value		= value
		obj.forstateonly= State
		obj.zindex		= 50
		obj.crossed		= on
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

Type TGUIPanel Extends TGUIobject
	field children:TList = CreateList()

    Function Create:TGUIPanel(x:Int,y:Int,width:Int, height:Int, State:String="")
		Local obj:TGUIPanel = New TGUIPanel
		obj.pos.setXY( x,y )
		obj._enabled = 1
		If width < 0 Then width = 40
		obj.dimension.setXY( width, height )
		obj.value   = ""
		obj.forstateonly = State

		GUIManager.Add( obj )

		Return obj
	End Function

	Method Update()
		'
	End Method

	Method Draw()
		'
	End Method
End Type


Type TGUIList  Extends TGUIobject
    Field maxlength:Int
    Field filter:String
	Field buttonclicked: Int
	Field ListStartsAtPos :Int
	Field PosChangeTimer: Int
	Field ListPosClicked:Int
	Field GUIbackground:TGUIPanel = null
	Field EntryList:TList = CreateList()
	Field ControlEnabled:Int = 0
	Field lastMouseClickTime:Int = 0
	Field LastMouseClickPos:Int = 0
    Field nobackground:Int

    Function Create:TGUIList(x:Int, y:Int, width:Int, height:Int = 50, enabled:Byte = 1, maxlength:Int = 128, State:String = "")
		Local obj:TGUIList=New TGUIList
		obj.baseInit()
		obj.pos.setXY( x,y )
		obj._enabled = enabled
		If width < 40 Then width = 40
		obj.dimension.setXY( width, height )
		obj.maxlength			= maxlength
		obj.PosChangeTimer  	= MilliSecs()
		obj.ListStartsAtPos		= 0
		obj.ListPosClicked		= -1
		obj.GUIbackground		= TGUIPanel.Create( x,y, width,height, "")
		obj.forstateonly		= State

		GUIManager.Add( obj )
		Return obj
	End Function

	Method DisableBackground()
		Self.nobackground = True
	End Method

	Method SetControlState(on:Int = 1)
		Self.ControlEnabled = on
	End Method

	Method SetFilter:Int(usefilter:String = "")
		self.filter = usefilter
	End Method


'RemoveOld ... should be done in specific object (pid...)

 	Method RemoveOldEntries:Int(pid:Int=0, timeout:Int=500)
	  Local i:Int = 0
	  Local RemoveTime:Int = MilliSecs()
	  For Local Entry:TGUIEntry = EachIn Self.EntryList
        If Entry.data.getInt("pid",0) = pid
		  If Entry.data.getInt("time",0) = 0 Then Entry.data.addNumber("time", MilliSecs() )
          If Entry.data.getInt("time",0) + timeout < RemoveTime
	        EntryList.Remove(Entry)
		    Print  "entry aged... removed "
	      EndIf
	    EndIf
  	    i = i + 1
 	  Next
 	  Return i
	End Method

' should be done in specific
	Method AddUniqueEntry:Int(title:string, value:string, team:string, ip:string, port:int, time:Int, usefilter:String = "")
		If filter = "" Or filter = usefilter
			For Local Entry:TGUIEntry = EachIn Self.EntryList
				If Entry.data.getInt("pid", 0) = self._id AND ..
				   Entry.data.getString("ip", "0.0.0.0") = ip AND ..
				   Entry.data.getInt("port",0) = port

					If time = 0 Then time = MilliSecs()
					Entry.data.addNumber("time", time)
					Entry.data.addString("team", team)
					Entry.data.addString("value", value)
					Return 0
				EndIf
			Next
			local data:TData = new TData
			data.addString("title",title).addString("value", value).addString("team", team)
			data.addNumber("pid", self._id).addString("ip", ip).addNumber("port", port).addNumber("time",time)
			EntryList.AddLast( TGUIEntry.Create(data) )
		EndIf
	End Method

 	Method GetEntryCount:Int()
	    Return EntryList.count()
	End Method

'getters should be specific - eg. extension of list
 	Method GetEntryPort:Int()
	    Local i:Int = 0
	    For Local Entries:TGUIEntry = EachIn Self.EntryList
			If i = ListPosClicked then Return Entries.data.getInt("port",0)
  	      	i:+1
	    Next
	    return 0
	End Method

	Method GetEntryTime:Int()
	    Local i:Int = 0
  	    For Local Entries:TGUIEntry = EachIn self.EntryList
   	        If i = ListPosClicked then Return Entries.data.getInt("time",0)
  	      	i:+1
	    Next
	    return 0
	End Method

	Method GetEntryValue:String()
	    Local i:Int = 0
  	    For Local Entries:TGUIEntry = EachIn self.EntryList
			If i = ListPosClicked then Return Entries.data.getString("value", "")
  	      	i:+1
	    Next
	End Method

	Method GetEntryTitle:String()
	    Local i:Int = 0
  	    For Local Entries:TGUIEntry = EachIn EntryList
			If i = ListPosClicked Then Return Entries.data.getString("title", "")
  	      	i:+1
	    Next
	End Method

	Method GetEntryIP:String()
	    Local i:Int = 0
  	    For Local Entries:TGUIEntry = EachIn EntryList
 	        If i = ListPosClicked Then Return Entries.data.getString("ip", "0.0.0.0")
  	      	i:+1
	    Next
	End Method

	Method ClearEntries()
		EntryList.Clear()
	End Method

	Method AddEntry(title$, value$, team$, ip$, port:int, time:Int)
		If time = 0 Then time = MilliSecs()

		local data:TData = new TData
		data.addString("title",title).addString("value", value).addString("team", team)
		data.addNumber("pid", self._id).addString("ip", ip).addNumber("port", port).addNumber("time",time)
		EntryList.AddLast( TGUIEntry.Create(data) )
	End Method

	Method Update()
        If self.isActive() Then on = 1 Else on = 0
	End Method

	Method Draw()
		Local i:Int					= 0
		Local spaceavaiable:Int		= self.dimension.y 'Hoehe der Liste
		Local controlWidth:Float	= ControlEnabled * gfx_GuiPack.GetSprite("ListControl").framew
		Local Zeit:Int				= MilliSecs()
		Local printvalue:String

'			gfx_GuiPack.GetSprite("Chat_Top").Draw(Self.pos.x, Self.pos.y)
'			gfx_GuiPack.GetSprite("Chat_Middle").TileDraw(Self.pos.x, Self.pos.y + gfx_GuiPack.GetSprite("Chat_Top").h, gfx_GuiPack.GetSprite("Chat_Middle").w, self.dimension.y - gfx_GuiPack.GetSprite("Chat_Top").h - gfx_GuiPack.GetSprite("Chat_Bottom").h)
'			gfx_GuiPack.GetSprite("Chat_Bottom").Draw(Self.pos.x, Self.pos.y + self.dimension.y, 0, 1)

	    For Local Entries:TGUIEntry = EachIn self.EntryList
			If i > ListStartsAtPos-1 AND SpaceAvaiable > TextHeight( Entries.data.getString("value", "") )
				printValue = Entries.data.getString("value", "")
				If Entries.data.getInt("team", 0) > 0 then printValue = "[Team "+Entries.data.getInt("team", 0) + "]: "+printValue

				While TextWidth(printValue+"...") > self.dimension.x-4-18
					printvalue= printValue[..printvalue.length-1]
				Wend
				If Entries.data.getInt("team", 0) > 0
					If printvalue <> "[Team "+Entries.data.getInt("team", 0) + "]: "+Entries.data.getString("value", "") then printvalue = printvalue+"..."
				Else
					If printvalue <> Entries.data.getString("value", "") then printvalue = printvalue+"..."
				EndIf
				If i = ListPosClicked
					SetAlpha(0.5)
					SetColor(250,180,20)
					DrawRect(Self.pos.x+8,Self.pos.y+8+self.dimension.y-SpaceAvaiable ,self.dimension.x-20, TextHeight(printvalue))
					SetAlpha(1)
					SetColor(255,255,255)
				EndIf
				If ListPosClicked = i then SetColor(250, 180, 20)
				If functions.MouseIn(Self.pos.x + 5, Self.pos.y + 5 + self.dimension.y - Spaceavaiable, self.dimension.x - 1 - ControlWidth, useFont.getHeight(printvalue))
					SetAlpha(0.5)
					DrawRect(Self.pos.x+8,Self.pos.y+8+self.dimension.y-SpaceAvaiable ,self.dimension.x-20, useFont.getHeight(printvalue))
					SetAlpha(1)
					If MouseIsDown
						If LastMouseClickPos = i AND LastMouseClickTime + 50 < MilliSecs() And LastMouseClicktime +700 > MilliSecs()
							EventManager.registerEvent( TEventSimple.Create( "guiobject.OnClick", TData.Create().AddNumber("type", EVENT_GUI_DOUBLECLICK), self ) )
						EndIf
						ListPosClicked		= i
						LastMouseClickTime	= MilliSecs()
						LastMouseClickPos	= i
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
			i:+1
  		Next

		If ControlEnabled = 1
			Local guiListControl:TGW_Sprites = gfx_GuiPack.GetSprite("ListControl")
			For i = 0 To Ceil(self.dimension.y / guiListControl.frameh) - 1
			  guiListControl.Draw(Self.pos.x + self.dimension.x - guiListControl.framew, Self.pos.y + i * guiListControl.frameh, 7)
			Next
			If self.isActive() And self.mouseIsDown And self.clicked and Self.clicked.x >= Self.pos.x+self.dimension.x-14 And Self.clicked.y <= Self.pos.y+14
				guiListControl.Draw(Self.pos.x + self.dimension.x - 14, Self.pos.y, 1)
				If PosChangeTimer + 250 < Zeit And ListStartsAtPos > 0
					ListStartsAtPos = ListStartsAtPos -1
					PosChangeTimer = Zeit
				EndIf
			Else
				guiListControl.Draw(Self.pos.x + self.dimension.x - 14, Self.pos.y, 0)
			EndIf

			If self.isActive() And self.mouseIsDown And self.clicked and Self.clicked.x >= Self.pos.x+self.dimension.x-14 And Self.clicked.y >= Self.pos.y+self.dimension.y-14
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
		 GUIChat.maxlength= maxlength
		 GUIChat.PosChangeTimer  = MilliSecs()
		 GUIChat.ListStartsAtPos = 0
		 GUIChat.ListPosClicked = -1
		 GUIChat.GUIInput:TGUIinput = New TGUIinput
		 GUIChat.GUIInput.pos.setXY( x+8, y+height-26 -3)
		 GUIChat.GUIInput.dimension.setXY( width-30, 20 )
		 GUIChat.GUIInput._id = GUIchat._id
		 GUIChat.GUIInput.maxlength = 100
		 GUIChat.GUIInput.color.adjust(50,50,50, True)

		 GUIchat.GUIInput.nobackground = 1
'		 guichat.guichatgfx = 1
		 GUIchat.nobackground = 1


'		 GUIChat.GUIbackground:TGUIbackground = New TGUIbackground
'		 GUIChat.GUIbackground.pos.setXY( x,y )
'		 GUIChat.GUIbackground.dimension.setXY( width, height )
		 GUIchat.AutoScroll  = 1

		 GUIChat.forstateonly = State$


	     If Not guichat.EntryList Then guichat.EntryList = CreateList()

		GUIManager.Add( GUIChat )
	  	 Return GUIChat
	End Function

   	Method Update()
		Self.EnterPressed = Self.GUIInput.EnterPressed
		Self.GUIInput.Update()
		If Self.EnterPressed = 1 Then GUIManager.setActive(Self._id)
		_UpdateFunc_()
       If self.isActive() Then on = 1 Else on = 0
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
'			GUIbackground.pos.setPos(Self.pos)
'			GUIbackground.dimension.setPos(self.dimension)
'			GUIbackground.Draw()
			chatinputheight = 0
		Else
			If guichatgfx > 0
				gfx_GuiPack.GetSprite("Chat_Top").Draw(Self.pos.x, Self.pos.y)
				gfx_GuiPack.GetSprite("Chat_Middle").TileDraw(Self.pos.x, Self.pos.y + gfx_GuiPack.GetSprite("Chat_Top").h, gfx_GuiPack.GetSprite("Chat_Middle").w, Self.dimension.y - gfx_GuiPack.GetSprite("Chat_Top").h - gfx_GuiPack.GetSprite("Chat_Input").h)
				gfx_GuiPack.GetSprite("Chat_Input").Draw(Self.pos.x, Self.pos.y + Self.dimension.y, 0, 1)
			EndIf
			chatinputheight = 35
		EndIf
		SpaceAvaiable = Self.dimension.y 'Hoehe der Liste
	    i = 0

		Local displace:Float = 0.0
	    For Local Entries:TGUIEntry = EachIn self.EntryList 'Liste hier global
			If fadeout Then SetAlpha (7 - Float(MilliSecs() - Entries.data.getInt("time",0) )/1000)
			If i > ListStartsAtPos-1
				If AutoScroll=1 And Self.useFont.getHeight( Entries.data.getString("value", "") ) > SpaceAvaiable-chatinputheight
					ListStartsAtPos :+1
				EndIf
				If Self.useFont.getHeight( Entries.data.getString("value", "") ) < SpaceAvaiable-chatinputheight
					Local playerID:Int = Entries.data.getInt("team",1)
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
						blockHeight = Self.useFont.drawBlock(Entries.data.getString("value", ""), Self.pos.x+2+nameWidth, Self.pos.y+displace +2, self.dimension.x - nameWidth, SpaceAvaiable, 0, 255,255,255,0,2, i)

						If i = 1 Then displace:+blockHeight
					Next
				EndIf
			EndIf
			i:+1
			If fadeout Then SetAlpha (1)
			If fadeout And (7 - Float(MilliSecs() - Entries.data.getInt("time", 0))/1000) <=0 Then EntryList.Remove(Entries)
		Next

		GUIInput.Draw()

		Local guiListControl:TGW_Sprites = gfx_GuiPack.GetSprite("ListControl")
		If nobackground = 0
			For i = 0 To Ceil(Self.dimension.y / guiListControl.frameh) - 1
				guiListControl.Draw(Self.pos.x + self.dimension.x - guiListControl.framew, Self.pos.y + i * guiListControl.frameh, 7)
			Next
			If self.isActive() And self.mouseIsDown And self.clicked and Self.clicked.x >= Self.pos.x+self.dimension.x-14 And Self.clicked.y <= Self.pos.y+14
				guiListControl.Draw(Self.pos.x + self.dimension.x - 14, Self.pos.y, 1)
				If PosChangeTimer + 250 < Zeit And ListStartsAtPos > 0
					ListStartsAtPos = ListStartsAtPos -1
					PosChangeTimer = Zeit
				EndIf
			Else
				guiListControl.Draw(Self.pos.x + self.dimension.x - 14, Self.pos.y, 0)
			EndIf

			If self.isActive() And self.mouseIsDown And self.clicked and Self.clicked.x >= Self.pos.x+self.dimension.x-14 And Self.clicked.y >= Self.pos.y+Self.dimension.y-14
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
	End Method

End Type
