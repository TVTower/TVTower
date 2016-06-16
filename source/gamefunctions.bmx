Function Font_AddGradient:TBitmapFontChar(font:TBitmapFont, charKey:String, char:TBitmapFontChar, config:TData=Null)
	If Not char.img Then Return char 'for "space" and other empty signs
	Local pixmap:TPixmap	= LockImage(char.img)
	'convert to rgba
	If pixmap.format = PF_A8 Then pixmap = pixmap.convert(PF_RGBA8888)
'	pixmap = pixmap.convert(PF_A8)
	If Not config Then config = New TData

	'gradient
	Local color:Int
	Local gradientTop:Int	= config.GetInt("gradientTop", 255)
	Local gradientBottom:Int= config.GetInt("gradientBottom", 100)
	Local gradientSteps:Int = font.GetMaxCharHeight()
	Local onStep:Int		= Max(0, char.area.GetY() -2)
	Local brightness:Int	= 0

	For Local y:Int = 0 To pixmap.height-1
		brightness = 255 - onStep * (gradientTop - gradientBottom) / gradientSteps
		onStep :+1
		For Local x:Int = 0 To pixmap.width-1
			color = ARGB_Color( ARGB_Alpha( ReadPixel(pixmap, x,y) ), brightness, brightness, brightness)
			WritePixel(pixmap, x,y, color)
		Next
	Next
	char.img = LoadImage(pixmap)

	'in all cases we need a pf_rgba8888 font to make gradients work (instead of pf_A8)
	font._pixmapFormat = PF_RGBA8888

	Return char
End Function


Function Font_AddShadow:TBitmapFontChar(font:TBitmapFont, charKey:String, char:TBitmapFontChar, config:TData=Null)
	If Not char.img Then Return char 'for "space" and other empty signs

	If Not config Then config = New TData
	Local shadowSize:Int = config.GetInt("size", 0)
	'nothing to do?
	If shadowSize=0 Then Return char
	Local pixmap:TPixmap	= LockImage(char.img) ;If pixmap.format = PF_A8 Then pixmap = pixmap.convert(PF_RGBA8888)
	Local stepX:Float		= Float(config.GetString("stepX", "0.75"))
	Local stepY:Float		= Float(config.GetString("stepY", "1.0"))
	Local intensity:Float	= Float(config.GetString("intensity", "0.75"))
	Local blur:Float		= Float(config.GetString("blur", "0.5"))
 	Local width:Int			= pixmap.width + shadowSize
	Local height:Int		= pixmap.height + shadowSize

	Local newPixmap:TPixmap = TPixmap.Create(width, height, PF_RGBA8888)
	newPixmap.ClearPixels(0)

	If blur > 0.0
		DrawImageOnImage(pixmap, newPixmap, 1,1, TColor.Create(0,0,0,1.0))
		blurPixmap(newPixmap,0.5)
	EndIf

	'shadow
	For Local i:Int = 0 To shadowSize
		DrawImageOnImage(pixmap, newPixmap, Int(i*stepX),Int(i*stepY), TColor.Create(0,0,0,intensity/i))
	Next
	'original image
	DrawImageOnImage(pixmap, newPixmap, 0,0)

	'increase character dimension
	char.charWidth :+ shadowSize
	char.area.dimension.addXY(shadowSize, shadowSize)

	char.img = LoadImage(newPixmap)

	'in all cases we need a pf_rgba8888 font to make gradients work (instead of pf_A8)
	font._pixmapFormat = PF_RGBA8888

	Return char
End Function




Type TGUISpriteDropDown Extends TGUIDropDown

	Method Create:TGUISpriteDropDown(position:TVec2D = Null, dimension:TVec2D = Null, value:String="", maxLength:Int=128, limitState:String = "")
		Super.Create(position, dimension, value, maxLength, limitState)
		Return Self
	End Method
	

	'override to add sprite next to value
	Method DrawInputContent:Int(position:TVec2D)
		'position is already a copy, so we can reuse it without
		'copying it first

		'draw sprite
		If TGUISpriteDropDownItem(selectedEntry)
			Local scaleSprite:Float = 0.8
			Local labelHeight:Int = GetFont().GetHeight(GetValue())
			Local item:TGUISpriteDropDownItem = TGUISpriteDropDownItem(selectedEntry)
			Local sprite:TSprite = GetSpriteFromRegistry( item.data.GetString("spriteName", "default") )
			If item And sprite.GetName() <> "defaultSprite"
				Local displaceY:Int = -1 + 0.5 * (labelHeight - (item.GetSpriteDimension().y * scaleSprite))
				sprite.DrawArea(position.x, position.y + displaceY, item.GetSpriteDimension().x * scaleSprite, item.GetSpriteDimension().y * scaleSprite)
				position.addXY(item.GetSpriteDimension().x * scaleSprite + 3, 0)
			EndIf
		EndIf

		'draw value
		Super.DrawInputContent(position)
	End Method
End Type


Type TGUISpriteDropDownItem Extends TGUIDropDownItem
	Global spriteDimension:TVec2D
	Global defaultSpriteDimension:TVec2D = New TVec2D.Init(24, 24)
	

    Method Create:TGUISpriteDropDownItem(position:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		If Not dimension
			dimension = New TVec2D.Init(-1, GetSpriteDimension().y + 2)
		Else
			dimension.x = Max(dimension.x, GetSpriteDimension().x)
			dimension.y = Max(dimension.y, GetSpriteDimension().y)
		EndIf
		Super.Create(position, dimension, value)
		Return Self
    End Method


    Method GetSpriteDimension:TVec2D()
		If Not spriteDimension Then Return defaultSpriteDimension
		Return spriteDimension
    End Method


	Method SetSpriteDimension:Int(dimension:TVec2D)
		spriteDimension = dimension.copy()

		Resize(..
			Max(dimension.x, GetSpriteDimension().x), ..
			Max(dimension.y, GetSpriteDimension().y) ..
		)
	End Method


	'override to change color
	Method DrawBackground()
		Local oldCol:TColor = New TColor.Get()
		SetColor(125, 160, 215)
		If IsHovered()
			SetAlpha(oldCol.a * 0.75)
			DrawRect(getScreenX(), getScreenY(), GetScreenWidth(), rect.getH())
		ElseIf IsSelected()
			SetAlpha(oldCol.a * 0.5)
			DrawRect(getScreenX(), getScreenY(), GetScreenWidth(), rect.getH())
		EndIf
		oldCol.SetRGBA()
	End Method
    

	Method DrawValue()
		Local valueX:Int = getScreenX()

		Local sprite:TSprite = GetSpriteFromRegistry( data.GetString("spriteName", "default") )
		If sprite.GetName() <> "defaultSprite"
			sprite.DrawArea(valueX, GetScreenY()+1, GetSpriteDimension().x, GetSpriteDimension().y)
			valueX :+ GetSpriteDimension().x + 3
		Else
			valueX :+ GetSpriteDimension().x + 3
		EndIf
		'draw value
		GetFont().draw(value, valueX, Int(GetScreenY() + 2 + 0.5*(rect.getH()- GetFont().getHeight(value))), valueColor)
	End Method
End Type




Type TGUIChatWindow Extends TGUIGameWindow
	Field guiPanel:TGUIBackgroundBox
	Field guiChat:TGUIChat
	Field padding:TRectangle = New TRectangle.Init(8, 8, 8, 8)


	Method Create:TGUIChatWindow(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		'use "create" instead of "createBase" so the caption gets
		'positioned similar
		Super.Create(pos, dimension, limitState)

		guiPanel = AddContentBox(0, 0, Int(GetContentScreenWidth()-10), -1)
		'we manage the panel
		AddChild(guiPanel)

		guiChat = New TGUIChat.Create(New TVec2D.Init(0,0), New TVec2D.Init(-1,-1), limitState)
		'we manage the panel
		AddChild(guiChat)

		'resize base and move child elements
		resize(dimension.GetX(), dimension.GetY())

		GUIManager.Add( Self )

		Return Self
	End Method


	Method SetPadding:Int(top:Float, Left:Float, bottom:Float, Right:Float)
		GetPadding().setTLBR(top,Left,bottom,Right)
		resize()
	End Method


	'override resize and add minSize-support
	Method Resize(w:Float=Null,h:Float=Null)
		Super.Resize(w,h)

		'background covers whole area, so resize it
		If guiBackground Then guiBackground.resize(rect.getW(), rect.getH())

		If guiPanel Then guiPanel.Resize(GetContentScreenWidth(), GetContentScreenHeight())
		
		If guiChat
			guiChat.rect.position.SetXY(padding.GetLeft(), padding.GetTop())
			guiChat.Resize(GetContentScreenWidth() - padding.GetRight() - padding.GetLeft(), GetContentScreenHeight() - padding.GetTop() - padding.GetBottom())
		EndIf
	End Method
End Type


Type TGUIGameWindow Extends TGUIWindowBase
	Field contentBoxes:TGUIBackgroundBox[]

	Global childSpriteBaseName:String = "gfx_gui_panel.content"


	Method Create:TGUIGameWindow(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		GetPadding().SetTop(35)

		SetCaptionArea(New TRectangle.Init(20, 10, GetContentScreenWidth() - 2*20, 25))
		guiCaptionTextBox.SetValueAlignment("LEFT", "TOP")

		Return Self
	End Method


	'special handling for child elements of kind GuiGameBackgroundBox
	Method AddContentBox:TGUIBackgroundBox(displaceX:Int=0, displaceY:Int=0, w:Int=-1, h:Int=-1)
		If w < 0 Then w = GetContentScreenWidth()
		If h < 0 Then h = GetContentScreenHeight()

		'if no background was set yet - do it now
		If Not guiBackground Then SetBackground( New TGUIBackgroundBox.Create(Null, Null) )

		'replace single-content-window-sprite (aka: remove "drawn on"-contentimage)
		guiBackground.spriteBaseName = "gfx_gui_panel"

		Local maxOtherBoxesY:Int = 0
		Local panelGap:Int = GUIManager.config.GetInt("panelGap", 10)
		If _children
			For Local box:TGUIBackgroundBox = EachIn contentBoxes
				maxOtherBoxesY = Max(maxOtherBoxesY, box.rect.GetY() + box.rect.GetH())
				'after each box we want a gap
				maxOtherBoxesY :+ panelGap
			Next
		EndIf
		Local box:TGUIBackgroundBox = New TGUIBackgroundBox.Create(New TVec2D.Init(displaceX, maxOtherBoxesY + displaceY), New TVec2D.Init(w, h), "")

		box.spriteBaseName = childSpriteBaseName
		box.spriteAlpha = 1.0
		box.SetPadding(panelGap, panelGap, panelGap, panelGap)

		AddChild(box)

		contentBoxes = contentBoxes[.. contentBoxes.length +1]
		contentBoxes[contentBoxes.length-1] = box


		'resize self so it fits
		Local newHeight:Int = box.rect.GetY() + box.rect.GetH()
		'add padding
		newHeight :+ GetPadding().GetTop() + GetPadding().GetBottom()
		resize(rect.GetW(), Max(rect.GetH(), newHeight))

		Return box
	End Method


	Method Update:Int()
		If guiCaptionTextBox Then guiCaptionTextBox.SetFont(.headerFont)

		Super.Update()
	End Method
End Type




Type TGUIGameModalWindow Extends TGUIModalWindow
	Method Create:TGUIGameModalWindow(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		_defaultValueColor = TColor.clBlack.copy()
		defaultCaptionColor = TColor.clWhite.copy()

		Super.Create(pos, dimension, limitState)

		SetCaptionArea(New TRectangle.Init(-1,10,-1,25))
		guiCaptionTextBox.SetValueAlignment("CENTER", "TOP")


		Return Self
	End Method

	Method SetCaption:Int(caption:String="")
		Super.SetCaption(caption)
		If guiCaptionTextBox Then guiCaptionTextBox.SetFont(.headerFont)
	End Method
End Type



Type TGUIGameEntryList Extends TGUIGameList
    Method Create:TGUIGameEntryList(pos:TVec2D=Null, dimension:TVec2D=Null, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		Return Self
	End Method

	'override to check for similar entries
	Method AddItem:Int(item:TGUIobject, extra:Object=Null)
		'check if we already have an item with the same value
		Local gameItem:TGUIGameEntry = TGUIGameEntry(item)
		If gameItem
			For Local olditem:TGUIListItem = EachIn Self.entries
				'skip other items (same ip:port-combination)
				If gameItem.data.GetInt("hostPort") <> olditem.data.GetInt("hostPort") Or gameItem.data.GetString("hostIP") <> olditem.data.GetString("hostIP") Then Continue
				'refresh lifetime
				olditem.setLifeTime(olditem.initialLifeTime)
				'unset the new one
				item.remove()
				Return False
			Next
		EndIf
		Return Super.AddItem(item, extra)
	End Method
End Type


Type TGUIGameEntry Extends TGUISelectListItem
	Field paddingBottom:Int		= 3
	Field paddingTop:Int		= 2


	Method CreateSimple:TGUIGameEntry(HostIp:String, hostPort:Int, HostName:String="", gameTitle:String="", slotsUsed:Int, slotsMax:Int)
		'make it "unique" enough
		Self.Create(Null, Null, HostIp+":"+hostPort)

		Self.data.AddString("hostIP", HostIp)
		Self.data.AddNumber("hostPort", hostPort)
		Self.data.AddString("hostName", HostName)
		Self.data.AddString("gameTitle", gametitle)
		Self.data.AddNumber("slotsUsed", slotsUsed)
		Self.data.AddNumber("slotsMax", slotsMax)

		'resize it
		GetDimension()

		Return Self
	End Method


    Method Create:TGUIGameEntry(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")

		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(pos, dimension, "")

		SetLifetime(30000) '30 seconds
		SetValue(":D")
		SetValueColor(TColor.Create(0,0,0))
		
		GUIManager.add(Self)

		Return Self
	End Method


	Method getDimension:TVec2D()
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(Self.getParent("tguiscrollablepanel"))
		Local maxWidth:Int = 200
		If parentPanel Then maxWidth = parentPanel.getContentScreenWidth() '- GetScreenWidth()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local dimension:TVec2D = New TVec2D.Init(maxWidth, GetBitmapFontManager().baseFont.GetMaxCharHeight())
		
		'add padding
		dimension.addXY(0, Self.paddingTop)
		dimension.addXY(0, Self.paddingBottom)

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If Self.rect.getW() <> dimension.getX() Or Self.rect.getH() <> dimension.getY()
			'resize item
			Self.Resize(dimension.getX(), dimension.getY())
		EndIf

		Return dimension
	End Method


	'override
	Method DrawValue()
		'draw text
		Local move:TVec2D = New TVec2D.Init(0, Self.paddingTop)
		Local text:String = ""
		Local textColor:TColor = Null
		Local textDim:TVec2D = Null
		'line: title by hostname (slotsused/slotsmax)
'DrawRect(GetScreenX(), GetScreenY(), GetDimension().x, GetDimension().y)
		text 		= Self.Data.getString("gameTitle","#unknowngametitle#")
		textColor	= TColor(Self.Data.get("gameTitleColor", TColor.Create(150,80,50)) )
		textDim		= GetBitmapFontManager().baseFontBold.drawStyled(text, Self.getScreenX() + move.x, Self.getScreenY() + move.y, textColor, 2, 1,0.5)
		move.addXY(textDim.x,1)

		text 		= " by "+Self.Data.getString("hostName","#unknownhostname#")
		textColor	= TColor(Self.Data.get("hostNameColor", TColor.Create(50,50,150)) )
		textDim		= GetBitmapFontManager().baseFontBold.drawStyled(text, Self.getScreenX() + move.x, Self.getScreenY() + move.y, textColor)
		move.addXY(textDim.x,0)

		text 		= " ("+Self.Data.getInt("slotsUsed",1)+"/"++Self.Data.getInt("slotsMax",4)+")"
		textColor	= TColor(Self.Data.get("hostNameColor", TColor.Create(0,0,0)) )
		textDim		= GetBitmapFontManager().baseFontBold.drawStyled(text, Self.getScreenX() + move.x, Self.getScreenY() + move.y, textColor)
		move.addXY(textDim.x,0)
	End Method


	Method DrawContent()
		If Self.showtime <> Null
			SetAlpha Float(Self.showtime - Time.GetAppTimeGone())/500.0
		EndIf
		
		'draw highlight-background etc
		Super.DrawContent()

		SetAlpha 1.0
	End Method
End Type













Type TBlockGraphical Extends TBlockMoveable
	Field imageBaseName:String
	Field imageDraggedBaseName:String
	Field image:TSprite
	Field image_dragged:TSprite
    Global AdditionallyDragged:Int	= 0
End Type












Type TError
	Field title:String
	Field message:String
	Field id:Int
	Field link:TLink
	Field pos:TVec2D

	Global List:TList = CreateList()
	Global LastID:Int=0
	Global sprite:TSprite


	Function Create:TError(title:String, message:String)
		Local obj:TError =  New TError
		obj.title	= title
		obj.message	= message
		obj.id		= LastID
		LastID :+1
		If obj.sprite = Null Then obj.sprite = GetSpriteFromRegistry("gfx_errorbox")
		obj.pos		= New TVec2D.Init(400-obj.sprite.area.GetW()/2 +6, 200-obj.sprite.area.GetH()/2 +6)
		obj.link	= List.AddLast(obj)
		Return obj
	End Function

	Function hasActiveError:Int()
		Return (List.count() > 0)
	End Function


	Function CreateNotEnoughMoneyError()
		TError.Create(getLocale("ERROR_NOT_ENOUGH_MONEY"),getLocale("ERROR_NOT_ENOUGH_MONEY_TEXT"))
	End Function


	Function DrawErrors()
		Local error:TError = TError(List.Last())
		If error Then error.draw()
	End Function


	Function UpdateErrors()
		Local error:TError = TError(List.Last())
		If error Then error.Update()
	End Function


	Method Update()
		'no right clicking allowed as long as "error notice is active"
		MouseManager.ResetKey(2)
		'also avoid long-clicking (touch)
		MouseManager.ResetLongClicked(1)
		
		If Mousemanager.IsClicked(1)
			If THelper.MouseIn(Int(pos.x),Int(pos.y), Int(sprite.area.GetW()), Int(sprite.area.GetH()))
				link.Remove()
				MouseManager.resetKey(1) 'clicked to remove error
			EndIf
		EndIf
	End Method


	Function DrawNewError(str:String="unknown error")
		TError(TError.List.Last()).message = str
		TError.DrawErrors()
		Flip 0
	End Function


	Method Draw()
		SetAlpha 0.5
		SetColor 0,0,0
		DrawRect(0,0,800, 385)
		SetAlpha 1.0
		GetGameBase().cursorstate = 0
		SetColor 255,255,255
		sprite.Draw(pos.x,pos.y)
		GetBitmapFont("Default", 15, BOLDFONT).drawBlock(title, pos.x + 12 + 6, pos.y + 15, sprite.area.GetW() - 60, 40, Null, TColor.Create(150, 50, 50))
		GetBitmapFont("Default", 12).drawBlock(message, pos.x+12+6,pos.y+50,sprite.area.GetW()-40, sprite.area.GetH()-60, Null, TColor.Create(50, 50, 50))
  End Method
End Type




