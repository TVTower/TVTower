SuperStrict

Import "common.misc.gamegui.bmx"
Import "game.broadcastmaterial.base.bmx"
Import "game.broadcastmaterial.programme.bmx"
Import "game.broadcastmaterial.advertisement.bmx"
Import "game.game.base.bmx"
Import "game.player.programmeplan.bmx"


'base element for list items in the programme planner
Type TGUIProgrammePlanElement Extends TGUIGameListItem
	Field broadcastMaterial:TBroadcastMaterial
	Field inList:TGUISlotList
	Field lastList:TGUISlotList
	Field lastListType:Int = 0
	Field lastSlot:Int = 0
	Field plannedOnDay:Int = -1
	Field imageBaseName:String = "pp_programmeblock1"

	Global ghostAlpha:Float = 0.8

	'for hover effects
	Global hoveredElement:TGUIProgrammePlanElement = Null


    Method Create:TGUIProgrammePlanElement(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		If Not dimension Then dimension = New TVec2D.Init(120,20)
		Super.Create(pos, dimension, value)
		Return Self
	End Method


	Method CreateWithBroadcastMaterial:TGUIProgrammePlanElement(material:TBroadcastMaterial, limitToState:String="")
		Create()
		SetLimitToState(limitToState)
		SetBroadcastMaterial(material)
		Return Self
	End Method


	Method SetBroadcastMaterial:Int(material:TBroadcastMaterial = Null)
		'alow simple setter without param
		If Not material And broadcastMaterial Then material = broadcastMaterial

		broadcastMaterial = material

		If material
			'set ads to commercials, movies to trailers
			'this is needed because "drag and drop" on the same area
			'does not get handled by "AddObject"
			'alternatively do this in "onFinishDrop"...
			if not IsDragged() and TGUIProgrammePlanSlotList(inList)
				broadcastMaterial.setUsedAsType(TGUIProgrammePlanSlotList(inList).isType)
			EndIf

			'now we can calculate the item dimensions
			Resize(GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetW(), GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetH() * material.getBlocks())

			'set handle (center for dragged objects) to half of a 1-Block
			Self.SetHandle(New TVec2D.Init(GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetW()/2, GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetH()/2))
		EndIf
	End Method


	Method GetBlocks:Int()
		If isDragged() And Not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
			Return broadcastMaterial.GetBlocks(broadcastMaterial.materialType)
		EndIf
		If lastListType > 0 Then Return broadcastMaterial.GetBlocks(lastListType)
		Return broadcastMaterial.GetBlocks()
	End Method


	Method GetViewType:int()
		'dragged and not asked during ghost mode drawing
		If isDragged() And Not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
			return broadcastMaterial.materialType
		'ghost mode
		ElseIf isDragged() And hasOption(GUI_OBJECT_DRAWMODE_GHOST) And lastListType > 0
			return lastListType
		Else
			return broadcastMaterial.usedAsType
		EndIf
	End Method


	Method GetAssetBaseName:String()
		Local viewType:Int = GetViewType()

		If viewType = TVTBroadcastMaterialType.PROGRAMME
			imageBaseName = "pp_programmeblock"
		ElseIf viewType = TVTBroadcastMaterialType.ADVERTISEMENT
			imageBaseName = "pp_adblock"
		Else 'default
			imageBaseName = "pp_programmeblock"
		EndIf

		Return imageBaseName
	End Method


	'override default to enable splitted blocks (one left, two right etc.)
	Method containsXY:Int(x:Float,y:Float)
		If isDragged() Or broadcastMaterial.GetBlocks() = 1
			Return GetScreenRect().containsXY(x,y)
		EndIf

		For Local i:Int = 1 To GetBlocks()
			Local resultRect:TRectangle = Null
			If Self._parent
				resultRect = Self._parent.GetScreenRect()
				'get the intersecting rectangle between parentRect and blockRect
				'the x,y-values are screen coordinates!
				resultRect = resultRect.intersectRect(GetBlockRect(i))
			Else
				resultRect = GetBlockRect(i)
			EndIf
			If resultRect And resultRect.containsXY(x,y) Then Return True
		Next
		Return False
	End Method


	Method GetBlockRect:TRectangle(block:Int=1)
		Local pos:TVec2D = Null
		'dragged and not in DrawGhostMode
		If isDragged() And Not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
			pos = New TVec2D.Init(GetScreenX(), GetScreenY())
			If block > 1
				pos.addXY(0, GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetH() * (block - 1))
			EndIf
		Else
			Local startSlot:Int = lastSlot
			Local list:TGUISlotList = lastList
			If inList
				list = Self.inList
				startSlot = Self.inList.GetSlot(Self)
			EndIf

			If list
				pos = list.GetSlotCoord(startSlot + block-1).ToVec2D()
				pos.addXY(list.getScreenX(), list.getScreenY())
			Else
				pos = New TVec2D.Init(Self.GetScreenX(),Self.GetScreenY())
				pos.addXY(0, GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetH() * (block - 1))
				'print "block: "+block+"  "+pos.GetIntX()+","+pos.GetIntY()
			EndIf
		EndIf

		Return New TRectangle.Init(pos.x,pos.y, Self.rect.getW(), GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetH())
	End Method


	'override to disable clicks for items of other players
	Method IsClickable:int()
		'only owner can click on it 
		if broadcastMaterial and broadcastMaterial.GetOwner() <> GetPlayerBaseCollection().playerID Then return False

		'skip if player cannot control the material
		if broadcastMaterial and not broadcastMaterial.IsControllable() Then return False

		return Super.IsClickable()
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		Select broadcastMaterial.state
			Case broadcastMaterial.STATE_NORMAL
					setOption(GUI_OBJECT_DRAGABLE, True)
			Case broadcastMaterial.STATE_RUNNING
					setOption(GUI_OBJECT_DRAGABLE, False)
			Case broadcastMaterial.STATE_OK
					setOption(GUI_OBJECT_DRAGABLE, False)
			Case broadcastMaterial.STATE_FAILED
					setOption(GUI_OBJECT_DRAGABLE, False)
		End Select

		'no longer allowed to have this item dragged
		If isDragged() And Not hasOption(GUI_OBJECT_DRAGABLE)
			Print "RONNY: FORCE DROP"
			dropBackToOrigin()
		EndIf

		If Not broadcastMaterial
			'print "[ERROR] TGUIProgrammePlanElement.Update: broadcastMaterial not set."
			Return False
		EndIf


		'set mouse to "hover"
		If isHovered() and broadcastMaterial.IsOwnedByPlayer( GetPlayerBaseCollection().playerID)
			if not broadcastMaterial.IsControllable()
				GetGameBase().cursorstate = 3
			else
				GetGameBase().cursorstate = 1
			endif
		endif
		'set mouse to "dragged"
		If isDragged() Then GetGameBase().cursorstate = 2
	End Method


	'draws the background
	Method DrawBlockBackground:Int(variant:String="")
		Local titleIsVisible:Int = False
		Local drawPos:TVec2D = New TVec2D.Init(GetScreenX(), GetScreenY())
		'if dragged and not in ghost mode
		If isDragged() And Not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
			If broadcastMaterial.state = broadcastMaterial.STATE_NORMAL Then variant = "_dragged"
		EndIf

		Local blocks:Int = GetBlocks()
		For Local i:Int = 1 To blocks
			Local _blockPosition:Int = 1
			If i > 1
				If i < blocks Then _blockPosition = 2
				If i = blocks Then _blockPosition = 3
			EndIf

			'draw non-dragged OR ghost
			If Not isDragged() Or hasOption(GUI_OBJECT_DRAWMODE_GHOST)
				'skip invisible parts
				Local startSlot:Int = 0
				If Self.inList
					startSlot = Self.inList.GetSlot(Self)
				ElseIf Self.lastList And isDragged()
					startSlot = Self.lastSlot
				Else
					startSlot = Self.lastSlot
				EndIf
				If startSlot+i-1 < 0 Then Continue
				If startSlot+i-1 >= 24 Then Continue
			EndIf
			drawPos = GetBlockRect(i).position

			Select _blockPosition
				Case 1	'top
						'if only 1 block, use special graphics
						If blocks = 1
							GetSpriteFromRegistry(GetAssetBaseName()+"1"+variant).Draw(drawPos.x, drawPos.y)
						Else
							GetSpriteFromRegistry(GetAssetBaseName()+"2"+variant).DrawClipped(New TRectangle.Init(drawPos.x, drawPos.y, -1, 30))
						EndIf
						'live
						If TProgramme(broadcastMaterial) And TProgramme(broadcastMaterial).data.IsLive()
							GetSpriteFromRegistry("pp_live").Draw(drawPos.x + GetSpriteFromRegistry(GetAssetBaseName()+"1"+variant).GetWidth(), drawPos.y,  -1, ALIGN_RIGHT_TOP)
						EndIf
						'xrated
						If TProgramme(broadcastMaterial) And TProgramme(broadcastMaterial).data.IsXRated()
							GetSpriteFromRegistry("pp_xrated").Draw(drawPos.x + GetSpriteFromRegistry(GetAssetBaseName()+"1"+variant).GetWidth(), drawPos.y,  -1, ALIGN_RIGHT_TOP)
						EndIf
						'paid
						If TProgramme(broadcastMaterial) And TProgramme(broadcastMaterial).data.IsPaid()
							GetSpriteFromRegistry("pp_paid").Draw(drawPos.x + GetSpriteFromRegistry(GetAssetBaseName()+"1"+variant).GetWidth(), drawPos.y,  -1, ALIGN_RIGHT_TOP)
						EndIf

						titleIsVisible = True
				Case 2	'middle
						GetSpriteFromRegistry(GetAssetBaseName()+"2"+variant).DrawClipped(New TRectangle.Init(drawPos.x, drawPos.y, -1, 15), New TVec2D.Init(0, 30))
						drawPos.addXY(0,15)
						GetSpriteFromRegistry(GetAssetBaseName()+"2"+variant).DrawClipped(New TRectangle.Init(drawPos.x, drawPos.y, -1, 15), New TVec2D.Init(0, 30))
				Case 3	'bottom
						GetSpriteFromRegistry(GetAssetBaseName()+"2"+variant).DrawClipped(New TRectangle.Init(drawPos.x, drawpos.y, -1, 30), New TVec2D.Init(0, 30))
			End Select
		Next
		Return titleIsVisible
	End Method


	'returns whether a ghost can be drawn or false, if there is a
	'reason not to do so
	Method CanDrawGhost:Int()
		If IsDragged() And TGUIProgrammePlanSlotList(lastList)
			'if guiblock is planned on another day then what the list
			'of the ghost has set, we wont display the ghost
			If plannedOnDay <> TGUIProgrammePlanSlotList(lastList).planDay
				Return False
			Else
				Return True
			EndIf
		EndIf
		Return True
	End Method


	'draw the programmeblock inclusive text
    'zeichnet den Programmblock inklusive Text
	Method DrawContent()
		'check if we have to skip ghost drawing
		If hasOption(GUI_OBJECT_DRAWMODE_GHOST) And Not CanDrawGhost() Then Return


		If Not broadcastMaterial
			SetColor 255,0,0
			DrawRect(GetScreenX(), GetScreenY(), 150,20)
			SetColor 255,255,255
			GetBitmapFontManager().basefontBold.Draw("no broadcastMaterial", GetScreenX()+5, GetScreenY()+3)
			Return
		EndIf

		'If isDragged() Then state = 0
		Select broadcastMaterial.state
			Case broadcastMaterial.STATE_NORMAL
				if not broadcastMaterial.IsControllable()
					SetColor 255,252,238
				else
					SetColor 255,255,255
				endif
			Case broadcastMaterial.STATE_RUNNING
					SetColor 255,230,120
			Case broadcastMaterial.STATE_OK
					SetColor 200,255,200
			Case broadcastMaterial.STATE_FAILED
					SetColor 250,150,120
		End Select

		'draw the default background

		Local titleIsVisible:Int = DrawBlockBackground()
		SetColor 255,255,255

		'there is an hovered item
		If hoveredElement
			Local oldAlpha:Float = GetAlpha()
			'i am the hovered one (but not in ghost mode)
			'we could also check "self.isHovered()", this way we could
			'override it without changing the objects "behaviour" (if there is one)
			If Self = hoveredElement
				If Not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
					SetBlend LightBlend
					SetAlpha 0.30*oldAlpha
					SetColor 120,170,255
					DrawBlockBackground()
					SetAlpha oldAlpha
					SetBlend AlphaBlend
				EndIf
			'i have the same licence/programme...
			ElseIf Self.broadcastMaterial.GetReferenceID() = hoveredElement.broadcastMaterial.GetReferenceID()
				SetBlend LightBlend
				SetAlpha 0.15*oldAlpha
				'SetColor 150,150,250
				SetColor 120,170,255
				DrawBlockBackground()
				SetColor 250,255,255
				SetAlpha oldAlpha
				SetBlend AlphaBlend
			EndIf
			SetColor 255,255,255
		EndIf

		if not broadcastMaterial.IsControllable()
			SetAlpha GetAlpha() * 0.8
			GetSpriteFromRegistry("gfx_interface_ingamechat_key.locked").Draw(GetScreenX() + GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetW() - 4, GetScreenY() + 5, -1, ALIGN_RIGHT_TOP)
			SetAlpha GetAlpha() * 1.25
		endif
		
		If titleIsVisible
			Local useType:Int = broadcastMaterial.usedAsType
			If hasOption(GUI_OBJECT_DRAWMODE_GHOST) And lastListType > 0
				useType = lastListType
			EndIf

			Select useType
				Case TVTBroadcastMaterialType.PROGRAMME
					DrawProgrammeBlockText(New TRectangle.Init(GetScreenX(), GetScreenY(), GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetW()-1,30))
				Case TVTBroadcastMaterialType.ADVERTISEMENT
					DrawAdvertisementBlockText(New TRectangle.Init(GetScreenX(), GetScreenY(), GetSpriteFromRegistry(GetAssetBaseName()+"2").area.GetW()-4,30))
			End Select
		EndIf
	End Method


	Field textImageAd:TImage {nosave}
	Field textImageProgramme:TImage {nosave}
	Field cacheStringAd:string {nosave}
	Field cacheStringProgramme:string {nosave}
	
	Method DrawProgrammeBlockText:Int(textArea:TRectangle, titleColor:TColor=Null, textColor:TColor=Null)
		Local title:String			= broadcastMaterial.GetTitle()
		Local titleAppend:String	= ""
		Local text:String			= ""
		Local text2:String			= ""

		Select broadcastMaterial.materialType
			'we got a programme used as programme
			Case TVTBroadcastMaterialType.PROGRAMME
				If TProgramme(broadcastMaterial)
					Local programme:TProgramme	= TProgramme(broadcastMaterial)
					text = programme.data.getGenreString()
					If programme.isSeries() And programme.licence.parentLicenceGUID
						'use the genre of the parent
						text = programme.licence.GetParentLicence().data.getGenreString()
						title = programme.licence.GetParentLicence().GetTitle() + ":  "+programme.GetTitle()
						'uncomment if you wish episode number in title
						'titleAppend = " (" + programme.GetEpisodeNumber() + "/" + programme.GetEpisodeCount() + ")"
						text:+"-"+GetLocale("SERIES_SINGULAR")
						text2 = "Ep.: " + (programme.GetEpisodeNumber()) + "/" + programme.GetEpisodeCount()
					EndIf
				EndIf
			'we got an advertisement used as programme (aka Tele-Shopping)
			Case TVTBroadcastMaterialType.ADVERTISEMENT
				If TAdvertisement(broadcastMaterial)
					Local advertisement:TAdvertisement = TAdvertisement(broadcastMaterial)
					text = GetLocale("PROGRAMME_PRODUCT_INFOMERCIAL")
				EndIf
		End Select


		Local maxWidth:Int = textArea.GetW()
		Local titleFont:TBitmapFont = GetBitmapFont("DefaultThin", 12, BOLDFONT)

		'shorten the title to fit into the block
		While titleFont.getWidth(title + titleAppend) > maxWidth And title.length > 4
			title = title[..title.length-3]+".."
		Wend
		'add eg. "(1/10)"
		title = title + titleAppend

		'refresh cache?
		local newCacheString:string = title + text + text2
		if newCacheString <> cacheStringProgramme
			textImageProgramme = null
			cacheStringProgramme = newCacheString
		endif

		'create cache if needed
		if not textImageProgramme
			Local useFont:TBitmapFont = GetBitmapFont("Default", 12, ITALICFONT)
			If Not titleColor Then titleColor = TColor.Create(0,0,0)
			If Not textColor Then textColor = TColor.Create(50,50,50)

			textImageProgramme = TFunctions.CreateEmptyImage(int(textArea.GetW()), int(textArea.GetH()))
			TBitmapFont.setRenderTarget(textImageProgramme)
			TBitmapFont.pixmapOrigin.SetXY(-textArea.position.x, -textArea.position.y)

			'draw
			titleFont.drawBlock(title, textArea.position.GetIntX() + 5, textArea.position.GetIntY() +2, textArea.GetW() - 5, 18, Null, titleColor, 0, True, 1.0, False)
			useFont.draw(text, textArea.position.GetIntX() + 5, textArea.position.GetIntY() + 17, textColor)
			useFont.draw(text2, textArea.position.GetIntX() + 138, textArea.position.GetIntY() + 17, textColor)

			SetColor 255,255,255

			TBitmapFont.pixmapOrigin.SetXY(0, 0)
			TBitmapFont.setRenderTarget(null)
		endif

		if textImageProgramme
			DrawImage(textImageProgramme, textArea.position.GetIntX(), textArea.position.GetIntY())
		endif
	End Method


	Method DrawAdvertisementBlockText(textArea:TRectangle, titleColor:TColor=Null, textColor:TColor=Null)
		Local title:String			= broadcastMaterial.GetTitle()
		Local titleAppend:String	= ""
		Local text:String			= "123"
		Local text2:String			= "" 'right aligned on same spot as text

		Select broadcastMaterial.materialType
			'we got an advertisement used as advertisement
			Case TVTBroadcastMaterialType.ADVERTISEMENT
				If TAdvertisement(broadcastMaterial)
					Local advertisement:TAdvertisement = TAdvertisement(broadcastMaterial)
					If advertisement.isState(advertisement.STATE_FAILED)
						text = "------"
					Else
						If advertisement.contract.isSuccessful()
							text = "- OK -"
						Else
							text = GetPlayerProgrammePlan(advertisement.owner).GetAdvertisementSpotNumber(advertisement, lastListType) + "/" + advertisement.contract.GetSpotCount()
						EndIf
					EndIf
				EndIf
			'we got an programme used as advertisement (aka programmetrailer)
			Case TVTBroadcastMaterialType.PROGRAMME
				If TProgramme(broadcastMaterial)
					Local programme:TProgramme	= TProgramme(broadcastMaterial)
					text = GetLocale("TRAILER")
					'red corner mark should be enough to recognized X-rated
					'removing "FSK18" from text removes the bug that this text
					'does not fit into the rectangle on Windows systems
					'if programme.data.xrated then text = GetLocale("X_RATED")+"-"+text
				EndIf
		End Select


		'refresh cache?
		local newCacheString:string = title + text + text2
		if newCacheString <> cacheStringAd
			textImageAd = null
			cacheStringAd = newCacheString
		endif

		'create cache if needed
		if not textImageAd
			textImageAd = TFunctions.CreateEmptyImage(int(textArea.GetW()), int(textArea.GetH()))
			TBitmapFont.setRenderTarget(textImageAd)
			TBitmapFont.pixmapOrigin.SetXY(-textArea.position.x, -textArea.position.y)

			If Not titleColor Then titleColor = TColor.Create(0,0,0)
			If Not textColor Then textColor = TColor.Create(50,50,50)

			GetBitmapFont("DefaultThin", 10, BOLDFONT).drawBlock(title, textArea.position.GetIntX() + 3, textArea.position.GetIntY() + 2, textArea.GetW(), 18, Null, TColor.CreateGrey(0), 0,1,1.0, False)
			textColor.setRGB()
			GetBitmapFont("Default", 10).drawBlock(text, textArea.position.GetIntX() + 3, textArea.position.GetIntY() + 17, TextArea.GetW(), 30)
			GetBitmapFont("Default", 10).drawBlock(text2,textArea.position.GetIntX() + 3, textArea.position.GetIntY() + 17, TextArea.GetW(), 20, New TVec2D.Init(ALIGN_RIGHT))

			SetColor 255,255,255

			TBitmapFont.pixmapOrigin.SetXY(0, 0)
			TBitmapFont.setRenderTarget(null)
		endif

		if textImageAd
			DrawImage(textImageAd, textArea.position.GetIntX(), textArea.position.GetIntY())
		endif
	End Method


	Method DrawSheet(leftX:Int=30, rightX:Int=30, width:Int=0)
		Local sheetY:Int = 10
		Local sheetX:Int = leftX
		Local sheetAlign:Int= 0
		If width = 0 Then width = GetGraphicsManager().GetWidth()
		'if mouse on left side of area - align sheet on right side
		If MouseManager.x < width/2
			sheetX = width - rightX
			sheetAlign = 1
		EndIf

		'by default nothing is shown
		'because we already have hover effects
		Rem
			SetColor 0,0,0
			SetAlpha 0.2
			Local x:Float = self.GetScreenX()
			Local tri:Float[]
			if sheetAlign=0
				tri = [sheetX+20,sheetY+25,sheetX+20,sheetY+90,self.GetScreenX()+self.GetScreenWidth()/2.0+3,self.GetScreenY()+self.GetScreenHeight()/2.0]
			else
				tri = [sheetX-20,sheetY+25,sheetX-20,sheetY+90,self.GetScreenX()+self.GetScreenWidth()/2.0+3,self.GetScreenY()+self.GetScreenHeight()/2.0]
			endif
			DrawPoly(tri)
			SetColor 255,255,255
			SetAlpha 1.0
		endrem
		Self.broadcastMaterial.ShowSheet(sheetX,sheetY, sheetAlign)
	End Method
End Type





'list to handle elements in the programmeplan (ads and programmes)
Type TGUIProgrammePlanSlotList Extends TGUISlotList
	'sollten nicht gebraucht werden - die "slotpositionen" muessten auch herhalten
	'koennen
	Field zoneLeft:TRectangle		= New TRectangle.Init(0, 0, 200, 350)
	Field zoneRight:TRectangle		= New TRectangle.Init(300, 0, 200, 350)

	'what day this slotlist is planning currently
	Field planDay:Int = -1

	'holding the object representing a programme started a day earlier (eg. 23:00-01:00)
	'this should not get handled by panels but the list itself (only interaction is
	'drag-n-drop handling)
	Field daychangeGuiProgrammePlanElement:TGUIProgrammePlanElement

	Field slotBackground:TSprite= Null
	Field blockDimension:TVec2D		= Null
	Field acceptTypes:Int			= 0
	Field isType:Int				= 0
	Global registeredGlobalListeners:Int = False

    Method Create:TGUIProgrammePlanSlotList(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
		Super.Create(position, dimension, limitState)

		SetOrientation(GUI_OBJECT_ORIENTATION_VERTICAL)
		Self.resize( dimension.x, dimension.y)
		Self.Init("pp_programmeblock1")
		Self.SetItemLimit(24)
		Self._fixedSlotDimension = True

		Self.acceptTypes :| TVTBroadcastMaterialType.PROGRAMME
		Self.acceptTypes :| TVTBroadcastMaterialType.ADVERTISEMENT
		Self.isType = TVTBroadcastMaterialType.PROGRAMME



		SetAcceptDrop("TGUIProgrammePlanElement")
		SetAutofillSlots(False)

		'===== REGISTER EVENTS =====
		'nobody was against dropping the item - so transform according to the lists type
		EventManager.registerListenerMethod("guiobject.onFinishDrop", Self, "onFinishDropProgrammePlanElement", "TGUIProgrammePlanElement", Self)

		'nobody was against dragging the item - so transform according to the items base type
		'attention: "drag" does not have a "receiver"-list like a drop has..
		'so we would have to check vs slot-elements here
		'that is why we just use a global listener... for all programmeslotlists (prog and ad)
		If Not registeredGlobalListeners
			EventManager.registerListenerFunction("guiobject.onFinishDrag", onFinishDragProgrammePlanElement, "TGUIProgrammePlanElement")

			rem
			'refresh visual style
			EventManager.registerListenerFunction("guiobject.onFinishDrop", onFinishProgrammePlanMovement, "TGUIProgrammePlanElement")
			EventManager.registerListenerFunction("guiobject.onFinishDrag", onFinishProgrammePlanMovement, "TGUIProgrammePlanElement")
			EventManager.registerListenerFunction("guiobject.onDropBack", onFinishProgrammePlanMovement, "TGUIProgrammePlanElement")
			endrem

			registeredGlobalListeners = True
		EndIf


		Return Self
	End Method


	Method Init:Int(spriteName:String="", displaceX:Int = 0)
		Self.zoneLeft.dimension.SetXY(GetSpriteFromRegistry(spriteName).area.GetW(), 12 * GetSpriteFromRegistry(spriteName).area.GetH())
		Self.zoneRight.dimension.SetXY(GetSpriteFromRegistry(spriteName).area.GetW(), 12 * GetSpriteFromRegistry(spriteName).area.GetH())

		Self.slotBackground = GetSpriteFromRegistry(spriteName)

		Self.blockDimension = New TVec2D.Init(slotBackground.area.GetW(), slotBackground.area.GetH())
		SetSlotMinDimension(blockDimension.GetIntX(), blockDimension.GetIntY())

		Self.SetEntryDisplacement(slotBackground.area.GetW() + displaceX , -12 * slotBackground.area.GetH(), 12) '12 is stepping
	End Method


	'override to remove daychange-object too
	Method EmptyList:Int()
		Super.EmptyList()
		If dayChangeGuiProgrammePlanElement
			dayChangeGuiProgrammePlanElement.remove()
			dayChangeGuiProgrammePlanElement = Null
		EndIf
	End Method

rem
	'refresh visual state on dropback
	Function onFinishProgrammePlanMovement:Int(triggerEvent:TEventBase)
		'resize that item to conform to the list
		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		If Not item Then Return False

		'resizes item according to usage type of the current list
		item.SetBroadcastMaterial()

		Return True
	End Function
endrem
	
	'handle successful drops of broadcastmaterial on the list
	Method onFinishDropProgrammePlanElement:Int(triggerEvent:TEventBase)
		'resize that item to conform to the list
		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		If Not item Then Return False

		item.lastListType = isType

		item.SetBroadcastMaterial()

		Return True
	End Method


	'handle successful drags of broadcastmaterial
	Function onFinishDragProgrammePlanElement:Int(triggerEvent:TEventBase)
		'resize that item to conform to the list
		Local item:TGUIProgrammePlanElement = TGUIProgrammePlanElement(triggerEvent.GetSender())
		If Not item Then Return False

		'resizes item according to usage type
		item.broadcastMaterial.setUsedAsType(item.broadcastMaterial.materialType)
		item.SetBroadcastMaterial()

		Return True
	End Function

	'override default behaviour for zones
	Method SetEntryDisplacement(x:Float=0.0, y:Float=0.0, stepping:Int=1)
		Super.SetEntryDisplacement(x,y,stepping)

		'move right zone according to setup
		zoneRight.position.SetX(x)
	End Method


	Method SetDayChangeBroadcastMaterial:Int(material:TBroadcastMaterial, day:Int=-1)
		Local guiElement:TGUIProgrammePlanElement = dayChangeGuiProgrammePlanElement
		If guiElement
			'clear out old gui element
			guiElement.remove()
		Else
			guiElement = New TGUIProgrammePlanElement.Create()
		EndIf
		'assign programme
		guiElement.SetBroadcastMaterial(material)

		'move the element to the correct position
		'1. find out when it was send:
		'   just ask the plan when the programme at "0:00" really started
		Local startHour:Int = 0
		Local player:TPlayerBase = GetPlayerBase(material.owner)
		If player
			If day < 0 Then day = GetWorldTime().GetDay()
			startHour = GetPlayerProgrammePlan(player.playerID).GetObjectStartHour(material.materialType,day,0)
			'get a 0-23 value
			startHour = startHour Mod 24
		Else
			Print "[ERROR] No player found for ~qprogramme~q in SetDayChangeBroadcastMaterial"
			startHour = 23 'nur als beispiel, spaeter entfernen
'			return FALSE
		EndIf

		'2. set the position of that element so that the "todays blocks" are starting at
		'   0:00
		Local firstSlotCoord:TVec2D = GetSlotOrCoord(0).ToVec2D()
		Local blocksRunYesterday:Int = 24 - startHour
		guiElement.lastSlot = - blocksRunYesterday
		guiElement.rect.position.CopyFrom(firstSlotCoord)
		'move above 0:00 (gets hidden automatically)
		guiElement.rect.position.addXY(0, -1 * blocksRunYesterday * blockDimension.GetIntY() )

		dayChangeGuiProgrammePlanElement = guiElement


		'assign parent
		guiEntriesPanel.addChild(dayChangeGuiProgrammePlanElement)

		Return True
	End Method


	'override default "default accept behaviour" of onDrop
	Method onDrop:Int(triggerEvent:TEventBase)
		Local dropCoord:TVec2D = TVec2D(triggerEvent.GetData().get("coord"))
		If Not dropCoord Then Return False

		If Self.containsXY(dropCoord.x, dropCoord.y)
			triggerEvent.setAccepted(True)
			'print "TGUIProgrammePlanSlotList.onDrop: coord="+dropCoord.getIntX()+","+dropCoord.getIntY()
			Return True
		Else
			Return False
		EndIf
	End Method


	Method ContainsBroadcastMaterial:Int(material:TBroadcastMaterial)
		'check special programme from yesterday
		If Self.dayChangeGuiProgrammePlanElement
			If Self.daychangeGuiProgrammePlanElement.broadcastMaterial = material Then Return True
		EndIf

		For Local i:Int = 0 To Self.GetSlotAmount()-1
			Local block:TGUIProgrammePlanElement = TGUIProgrammePlanElement(Self.GetItemBySlot(i))
			If Not block Then Continue
			If block.broadcastMaterial = material Then Return True
		Next
		Return False
	End Method


	'override default to also recognize slots occupied by prior ones
	Method GetItemBySlot:TGUIobject(slot:Int)
		If slot < 0 Or slot > _slots.length-1 Then Return Null

		'if no item is at the given slot, check prior ones
		If _slots[slot] = Null
			'check regular slots
			Local parentSlot:Int = slot-1
			While parentSlot > 0
				If _slots[parentSlot]
					'only return if the prior one is running long enough
					' - else it also returns programmes with empty slots between
					Local blocks:Int = TGUIProgrammePlanElement(_slots[parentSlot]).broadcastMaterial.getBlocks(isType)
					If blocks > (slot - parentSlot) Then Return _slots[parentslot]
				EndIf
				parentSlot:-1
			Wend
			'no item found in regular slots but already are at start
			'-> check special programme from yesterday (if existing it is the searched one)
			If daychangeGuiProgrammePlanElement
				Local blocks:Int = daychangeGuiProgrammePlanElement.broadcastMaterial.getBlocks(isType)
				'lastSlot is a negative value from 0
				'-> -3 means 3 blocks already run yesterday
				Local blocksToday:Int = blocks + dayChangeGuiProgrammePlanElement.lastSlot
				If blocksToday > slot Then Return daychangeGuiProgrammePlanElement
			EndIf

			Return Null
		EndIf

		Return _slots[slot]
	End Method


	'overridden method to check slots after the block-slot for occupation too
	Method SetItemToSlot:Int(item:TGUIobject,slot:Int)
		Local itemSlot:Int = Self.GetSlot(item)
		'somehow we try to place an item at the place where the item
		'already resides
		If itemSlot = slot Then Return True

		Local guiElement:TGUIProgrammePlanElement = TGUIProgrammePlanElement(item)
		If Not guiElement Then Return False

		'is there another item?
		Local slotStart:Int = slot
		Local slotEnd:Int = slot + guiElement.broadcastMaterial.getBlocks(isType)-1

		'to check previous ones we try to find a previous one
		'then we check if it reaches "our" slot or ends earlier
		Local previousItemSlot:Int = GetPreviousUsedSlot(slot)
		If previousItemSlot > -1
			Local previousGuiElement:TGUIProgrammePlanElement = TGUIProgrammePlanElement(getItemBySlot(previousItemSlot))
			If previousGuiElement And previousItemSlot + previousGuiElement.GetBlocks()-1 >= slotStart
				slotStart = previousItemSlot
			EndIf
		EndIf

		For Local i:Int = slotStart To slotEnd
			Local dragItem:TGUIProgrammePlanElement = TGUIProgrammePlanElement(getItemBySlot(i))

			'only drag an item once
			If dragItem 'and not dragItem.isDragged()
				'do not allow if the underlying item cannot get dragged
				If Not dragItem.isDragable() Then Return False

				'ask others if they want to intercept that exchange
				Local event:TEventSimple = TEventSimple.Create( "guiSlotList.onBeginReplaceSlotItem", New TData.Add("source", item).Add("target", dragItem).AddNumber("slot",slot), Self)
				EventManager.triggerEvent(event)

				If Not event.isVeto()
					'remove the other one from the panel
					If dragItem._parent Then dragItem._parent.RemoveChild(dragItem)

					'drag the other one
					dragItem.drag()
					'unset the occupied slot
					_SetSlot(i, Null)

					EventManager.triggerEvent(TEventSimple.Create( "guiSlotList.onReplaceSlotItem", New TData.Add("source", item).Add("target", dragItem).AddNumber("slot",slot) , Self))
				EndIf
				'skip slots occupied by this item
				i:+ (dragItem.broadcastMaterial.GetBlocks(isType)-1)
			EndIf
		Next

		'if the item is already on the list, remove it from the former slot
		_SetSlot(itemSlot, Null)

		'set the item to the new slot
		_SetSlot(slot, item)

		 'panel manages it now | RON 03.01.14
		guiEntriesPanel.addChild(item)

		RecalculateElements()

		Return True
	End Method


	'overriden Method: so it does not accept a certain
	'kind of programme (movies - series)
	'plus it drags items in other occupied slots
	Method AddItem:Int(item:TGUIobject, extra:Object=Null)
		Local guiElement:TGUIProgrammePlanElement = TGUIProgrammePlanElement(item)
		If Not guiElement Then Return False

		'something odd happened - no material
		If Not guiElement.broadcastMaterial Then Return False
		'list does not accept type? stop adding the item.
		If Not(acceptTypes & guiElement.broadcastMaterial.usedAsType) Then Return False
		'item is not allowed to drop there ? stop adding the item.
		If Not(acceptTypes & guiElement.broadcastMaterial.useableAsType) Then Return False

		Local addToSlot:Int = -1
		Local extraIsRawSlot:Int = False
		If String(extra)<>"" Then addToSlot= Int( String(extra) );extraIsRawSlot=True

		'search for first free slot
		If _autofillSlots Then addToSlot = Self.getFreeSlot()
		'auto slot requested
		If extraIsRawSlot And addToSlot = -1 Then addToSlot = getFreeSlot()

		'no free slot or none given? find out on which slot we are dropping
		'if possible, drag the other one and drop the new
		If addToSlot < 0
			Local data:TData = TData(extra)
			If Not data Then Return False

			Local dropCoord:TVec2D = TVec2D(data.get("coord"))
			If Not dropCoord Then Return False

			'set slot to land
			addToSlot = GetSlotByCoord(dropCoord)
			'no slot was hit
			If addToSlot < 0 Then Return False
		EndIf

		'ask if an add to this slot is ok
		Local event:TEventSimple =  TEventSimple.Create("guiList.TryAddItem", New TData.Add("item", item).AddNumber("slot",addToSlot) , Self)
		EventManager.triggerEvent(event)
		If event.isVeto() Then Return False

		'check underlying slots
		For Local i:Int = 0 To guiElement.broadcastMaterial.getBlocks(isType)-1
			'return if there is an underlying item which cannot get dragged
			Local dragItem:TGUIProgrammePlanElement = TGUIProgrammePlanElement(getItemBySlot(addToSlot + i))
			If Not dragItem Then Continue

			'check if the programme can be dragged
			'this should not be the case if the programme already run
			If Not dragItem.isDragable() Then Print "NOT DRAGABLE UNDERLAYING";Return False
		Next


		'set self as the list the items is belonging to
		'this also drags underlying items if possible
		If SetItemToSlot(guiElement, addToSlot)
			guiElement.lastList = guiElement.inList
			guiElement.inList = Self
			If Not guiElement.lastList
				guiElement.lastList = Self
				guiElement.lastListType = isType
			EndIf

			Return True
		EndIf
	End Method


	'override RemoveItem-Handler to include inList-property (and type check)
	Method RemoveItem:Int(item:TGUIobject)
		Local guiElement:TGUIProgrammePlanElement = TGUIProgrammePlanElement(item)
		If Not guiElement Then Return False

		If Super.RemoveItem(guiElement)
			guiElement.lastList = guiElement.inList
			'inList is only set for manual drags
			'while a replacement-drag has no inList (and no last Slot)
			If guiElement.inList
				guiElement.lastSlot = guiElement.inList.GetSlot(Self)
			Else
				guiElement.lastSlot = -1
			EndIf

			guiElement.inList = Null
			Return True
		Else
			Return False
		EndIf
	End Method


	'override default "rectangle"-check to include splitted panels
	Method containsXY:Int(x:Float,y:Float)
		'convert to local coord
		x :-GetScreenX()
		y :-GetScreenY()

		If zoneLeft.containsXY(x,y) Or zoneRight.containsXY(x,y)
			Return True
		Else
			Return False
		EndIf
	End Method


	Method Update:Int()
		If dayChangeGuiProgrammePlanElement Then dayChangeGuiProgrammePlanElement.Update()

		Super.Update()
	End Method


	Method DrawContent()
		Local atPoint:TVec2D = GetScreenPos()
		Local pos:TVec2D = Null
		For Local i:Int = 0 To _slotsState.length-1
			'skip occupied slots
			If _slots[i]
				If TGUIProgrammePlanElement(_slots[i])
					i :+ TGUIProgrammePlanElement(_slots[i]).GetBlocks()-1
					Continue
				EndIf
			EndIf

			If _slotsState[i] = 0 Then Continue

			pos = GetSlotOrCoord(i).ToVec2D()
			'disabled
			If _slotsState[i] = 1 Then SetColor 100,100,100
			'occupied
			If _slotsState[i] = 2 Then SetColor 250,150,120

			SetAlpha 0.35
			SlotBackground.Draw(atPoint.GetX()+pos.getX(), atPoint.GetY()+pos.getY())
			SetAlpha 1.0
			SetColor 255,255,255
		Next

		If dayChangeGuiProgrammePlanElement Then dayChangeGuiProgrammePlanElement.draw()
	End Method
End Type










