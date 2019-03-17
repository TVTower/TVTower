SuperStrict
Import "Dig/base.gfx.gui.dropdown.bmx"
Import "Dig/base.gfx.gui.chat.bmx"
Import "Dig/base.gfx.gui.window.base.bmx"
Import "Dig/base.gfx.gui.window.modal.bmx"
Import "Dig/base.gfx.gui.window.modalchain.bmx"
Import "Dig/base.gfx.gui.list.selectlist.bmx"
Import "Dig/base.gfx.gui.list.slotlist.bmx"
Import "Dig/base.gfx.gui.accordeon.bmx"
Import "common.misc.datasheet.bmx"


Global headerFont:TBitmapFont


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
		guiCaptionTextBox.SetValueAlignment( ALIGN_LEFT_TOP )

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



Type TGUIGameModalWindowChainDialogue extends TGUIModalWindowChainDialogue
	Method Create:TGUIGameModalWindowChainDialogue(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		_defaultValueColor = TColor.clBlack.copy()
		defaultCaptionColor = TColor.clWhite.copy()

		Super.Create(pos, dimension, limitState)

		SetCaptionArea(New TRectangle.Init(-1,10,-1,25))
		guiCaptionTextBox.SetValueAlignment( ALIGN_CENTER_TOP )


		Return Self
	End Method

	Method SetCaption:Int(caption:String="")
		Super.SetCaption(caption)
		If guiCaptionTextBox Then guiCaptionTextBox.SetFont(.headerFont)
	End Method
End Type


Type TGUIGameModalWindow Extends TGUIModalWindow
	Method Create:TGUIGameModalWindow(pos:TVec2D, dimension:TVec2D, limitState:String = "")
		_defaultValueColor = TColor.clBlack.copy()
		defaultCaptionColor = TColor.clWhite.copy()

		Super.Create(pos, dimension, limitState)

		SetCaptionArea(New TRectangle.Init(-1,10,-1,25))
		guiCaptionTextBox.SetValueAlignment( ALIGN_CENTER_TOP )


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


Type TGUIGameList Extends TGUISelectList
    Method Create:TGUIGameList(pos:TVec2D=null, dimension:TVec2D=null, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		Return Self
	End Method
End Type


Type TGUIGameSlotList Extends TGUISlotList
	'Field onlyDropFromList:int = False
	'Field onlyDropToList:int = False

    Method Create:TGUIGameSlotList(position:TVec2D = null, dimension:TVec2D = null, limitState:String = "")
		Super.Create(position, dimension, limitState)
		return self
	End Method


	'override to add sort
	Method AddItem:int(item:TGUIobject, extra:object=null)
		if super.AddItem(item, extra)
			'store list ids
			if TGUIGameListItem(item)
				local i:TGUIGameListItem = TGUIGameListItem(item)
				i.lastListID = i.inListID
				i.inListID = self._id
			endif

			GUIManager.sortLists()
			return TRUE
		endif
		return FALSE
	End Method


	'override default event handler
	Function onDropOnTarget:int( triggerEvent:TEventBase )
		local item:TGUIListItem = TGUIListItem(triggerEvent.GetSender())
		if item = Null then return FALSE

		'ATTENTION:
		'Item is still in dragged state!
		'Keep this in mind when sorting the items

		'only handle if coming from another list ?
		local parent:TGUIobject = item._parent
		if TGUIPanel(parent) then parent = TGUIPanel(parent)._parent
		local fromList:TGUIListBase = TGUIListBase(parent)
		if not fromList then return FALSE

		local toList:TGUIListBase = TGUIListBase(triggerEvent.GetReceiver())
		if not toList then return FALSE

		local data:TData = triggerEvent.getData()
		if not data then return FALSE

		'move item if possible
		fromList.removeItem(item)
		'try to add the item, if not able, readd
		if not toList.addItem(item, data)
			if fromList.addItem(item) then return TRUE

			'not able to add to "toList" but also not to "fromList"
			'so set veto and keep the item dragged
			triggerEvent.setVeto()
		endif


		return TRUE
	End Function
End Type


'a graphical representation of multiple object ingame
Type TGUIGameListItem Extends TGUIListItem
	Field assetNameDefault:String = "gfx_movie_undefined"
	Field assetNameDragged:String = "gfx_movie_undefined"
	Field lastListID:int
	Field inListID:int
	Field asset:TSprite = Null
	Field assetName:string = ""
	Field assetDefault:TSprite = Null
	Field assetDragged:TSprite = Null


    Method Create:TGUIGameListItem(pos:TVec2D=null, dimension:TVec2D=null, value:String="")
		'creates base, registers click-event,...
		Super.Create(pos, dimension, value)

   		Self.InitAssets()
   		Self.SetAsset()

		Return Self
	End Method


	Method InitAssets(nameDefault:String="", nameDragged:String="")
		If nameDefault = "" Then nameDefault = Self.assetNameDefault
		If nameDragged = "" Then nameDragged = Self.assetNameDragged

		Self.assetNameDefault = nameDefault
		Self.assetNameDragged = nameDragged
		Self.assetDefault = GetSpriteFromRegistry(nameDefault)
		Self.assetDragged = GetSpriteFromRegistry(nameDragged)

		Self.SetAsset(Self.assetDefault, self.assetNameDefault)
	End Method


	Method GetAssetName:string(targetGroup:int=-1, dragged:int=FALSE)
		if dragged then return assetNameDragged
		return assetNameDefault
	End Method


	Method SetAsset(sprite:TSprite=Null, name:string = "")
		If Not sprite then sprite = Self.assetDefault
		If Not name then name = Self.assetNameDefault


		'only resize if not done already
		If Self.asset <> sprite or self.assetName <> name
			Self.asset = sprite
			Self.assetName = name
			Self.Resize(sprite.area.GetW(), sprite.area.GetH())
		EndIf
	End Method


	'acts as cache
	Method GetAsset:TSprite()
		'refresh cache if not set or wrong sprite name
		if not asset or asset.GetName() <> assetName
			SetAsset(GetSpriteFromRegistry(self.assetNameDefault))
			'new -non default- sprite: adjust appearance
			if asset.GetName() <> "defaultsprite"
				SetAppearanceChanged(TRUE)
			endif
		endif
		return asset
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		If isDragged() then SetAsset(assetDragged)
	End Method


	Method DrawGhost()
		Local oldAlpha:Float = GetAlpha()
		'by default a shaded version of the gui element is drawn at the original position
		self.SetOption(GUI_OBJECT_IGNORE_POSITIONMODIFIERS, TRUE)
		SetOption(GUI_OBJECT_DRAWMODE_GHOST, True)
		SetAlpha oldAlpha * 0.5

		local backupAssetName:string = self.asset.getName()
		self.asset = GetSpriteFromRegistry(assetNameDefault)
		self.Draw()
		self.asset = GetSpriteFromRegistry(backupAssetName)

		SetAlpha oldAlpha
		self.SetOption(GUI_OBJECT_IGNORE_POSITIONMODIFIERS, FALSE)
		SetOption(GUI_OBJECT_DRAWMODE_GHOST, False)
	End Method


	Method DrawContent()
		asset.draw(int(Self.GetScreenX()), int(Self.GetScreenY()))
		'hovered
		If isHovered() and not isDragged()
			Local oldAlpha:Float = GetAlpha()
			SetAlpha 0.20*oldAlpha
			SetBlend LightBlend
			GetAsset().draw(int(Self.GetScreenX()), int(Self.GetScreenY()))
			SetBlend AlphaBlend
			SetAlpha oldAlpha
		EndIf
	End Method
End Type




Type TGameGUIAccordeon extends TGUIAccordeon
	Field skin:TDatasheetSkin
	Field skinName:string = "default"


	Method GetSkin:TDatasheetSkin()
		if not skin
			skin = GetDatasheetSkin(skinName)
			RefitPanelSizes()
		endif

		return skin
	End Method


	Method GetContentScreenWidth:Float()
		if not skin then return GetScreenWidth()
		return skin.GetContentW(GetScreenWidth())
	End Method


	Method GetContentWidth:Float()
		if not skin then return Super.GetContentWidth()
		return skin.GetContentW(GetWidth())
	End Method


	Method GetContentX:Float()
		if not skin then return Super.GetContentX()
		return skin.GetContentX()
	End Method


	Method GetContentY:Float()
		if not skin then return Super.GetContentY()
		return skin.GetContentY()
	End Method


	'override
	Method GetMaxPanelBodyHeight:int()
		if not skin then return Super.GetMaxPanelBodyHeight()
		'subtract skin's border padding
		return skin.GetContentH( super.GetMaxPanelBodyHeight() )
	End Method


	Method DrawOverlay()
		'use GetSkin() to fetch the skin when drawing was possible
		GetSkin().RenderBorder(int(GetScreenX()), int(GetScreenY()), int(GetScreenWidth()), int(GetScreenHeight()))
	End Method
End Type




Type TGameGUIAccordeonPanel extends TGUIAccordeonPanel
	Method GetSkin:TDatasheetSkin()
		if TGameGUIAccordeon(GetParent()) then return TGameGUIAccordeon(GetParent()).GetSkin()
		return null
	End Method


	Method IsHeaderHovered:int()
		'skip further checks
		if not isHovered() then return False

		local mouseYOffset:int = MouseManager.y - GetScreenY()

		Return mouseYOffset > 0 and mouseYOffset < GetHeaderHeight()
	End Method


	Method GetHeaderValue:string()
		return GetValue()
	End Method


	Method DrawHeader()
		local openStr:string = Chr(9654)
		if isOpen then openStr = Chr(9660)

		local skin:TDatasheetSkin = GetSkin()
		if skin
			local contentW:int = GetScreenWidth()
			local contentX:int = GetScreenX()
			local contentY:int = GetScreenY()
			local headerHeight:int = GetHeaderHeight()

			skin.RenderContent(contentX, contentY, contentW, headerHeight, "1_top")
			if IsHeaderHovered()
				local oldCol:TColor = new TColor.Get()
				SetBlend LightBlend
				SetAlpha 0.25 * oldCol.a
				skin.RenderContent(contentX, contentY, contentW, headerHeight, "1_top")
				SetBlend AlphaBlend
				SetAlpha oldCol.a
			endif
			if isOpen
				skin.fontNormal.drawBlock(openStr + " |b|" +GetHeaderValue()+"|/b|", contentX + 5, contentY, contentW - 10, headerHeight, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			else
				skin.fontNormal.drawBlock(openStr + " " +GetHeaderValue(), contentX + 5, contentY, contentW - 10, headerHeight, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			endif
		endif
	End Method


	Method DrawBody()
		local skin:TDatasheetSkin = GetSkin()
		if skin
			skin.RenderContent(int(GetScreenX()), int(GetScreenY() + GetHeaderHeight()), int(GetScreenWidth()), int(GetBodyHeight()), "2")
		endif
	End Method
End Type