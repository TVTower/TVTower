Type TGUINewsList Extends TGUIListBase

    Method Create:TGUINewsList(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
		Super.Create(position, dimension, limitState)
		Return Self
	End Method


	Method ContainsNews:Int(news:TNews)
		For Local guiNews:TGUINews = EachIn entries
			If guiNews.news = news Then Return True
		Next
		Return False
	End Method
End Type




Type TGUINewsSlotList Extends TGUISlotList

    Method Create:TGUINewsSlotList(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
		Super.Create(position, dimension, limitState)
		Return Self
	End Method


	Method ContainsNews:Int(news:TNews)
		For Local i:Int = 0 To Self.GetSlotAmount()-1
			Local guiNews:TGUINews = TGUINews( Self.GetItemBySlot(i) )
			If guiNews And guiNews.news = news Then Return True
		Next
		Return False
	End Method
End Type




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


	Method GetAssetBaseName:String()
		Local viewType:Int = 0

		'dragged and not asked during ghost mode drawing
		If isDragged() And Not hasOption(GUI_OBJECT_DRAWMODE_GHOST)
			viewType = broadcastMaterial.materialType
		'ghost mode
		ElseIf isDragged() And hasOption(GUI_OBJECT_DRAWMODE_GHOST) And lastListType > 0
			viewType = lastListType
		Else
			viewType = broadcastMaterial.usedAsType
		EndIf

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
		If broadcastMaterial.GetOwner() = GetPlayerCollection().playerID And mouseover Then Game.cursorstate = 1
		'set mouse to "dragged"
		If isDragged() Then Game.cursorstate = 2
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
						'xrated
						If TProgramme(broadcastMaterial) And TProgramme(broadcastMaterial).data.IsXRated()
							GetSpriteFromRegistry("pp_xrated").Draw(drawPos.x + GetSpriteFromRegistry(GetAssetBaseName()+"1"+variant).GetWidth(), drawPos.y,  -1, New TVec2D.Init(ALIGN_RIGHT, ALIGN_TOP))
						EndIf
						'paid
						If TProgramme(broadcastMaterial) And TProgramme(broadcastMaterial).data.IsPaid()
							GetSpriteFromRegistry("pp_paid").Draw(drawPos.x + GetSpriteFromRegistry(GetAssetBaseName()+"1"+variant).GetWidth(), drawPos.y,  -1, New TVec2D.Init(ALIGN_RIGHT, ALIGN_TOP))
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
					SetColor 255,255,255
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
			'we could also check "self.mouseover", this way we could
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

		If titleIsVisible
			Local useType:Int = broadcastMaterial.usedAsType
			If hasOption(GUI_OBJECT_DRAWMODE_GHOST) And lastListType > 0
				useType = lastListType
			EndIf

			Select useType
				Case TVTBroadcastMaterialType.PROGRAMME
					DrawProgrammeBlockText(New TRectangle.Init(GetScreenX(), GetScreenY(), GetSpriteFromRegistry(GetAssetBaseName()+"1").area.GetW()-1,-1))
				Case TVTBroadcastMaterialType.ADVERTISEMENT
					DrawAdvertisementBlockText(New TRectangle.Init(GetScreenX(), GetScreenY(), GetSpriteFromRegistry(GetAssetBaseName()+"2").area.GetW()-4,-1))
			End Select
		EndIf
	End Method


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
						title = programme.licence.GetParentLicence().GetTitle()
						'uncomment if you wish episode number in title
						'titleAppend = " (" + programme.GetEpisodeNumber() + "/" + programme.GetEpisodeCount() + ")"
						text:+"-"+GetLocale("SERIES_SINGULAR")
						text2 = "Ep.: " + (programme.GetEpisodeNumber()+1) + "/" + programme.GetEpisodeCount()
					EndIf
				EndIf
			'we got an advertisement used as programme (aka Tele-Shopping)
			Case TVTBroadcastMaterialType.ADVERTISEMENT
				If TAdvertisement(broadcastMaterial)
					Local advertisement:TAdvertisement = TAdvertisement(broadcastMaterial)
					text = GetLocale("PROGRAMME_PRODUCT_INFOMERCIAL")
				EndIf
		End Select


		Local maxWidth:Int			= textArea.GetW()
		Local titleFont:TBitmapFont = GetBitmapFont("DefaultThin", 12, BOLDFONT)
		Local useFont:TBitmapFont	= GetBitmapFont("Default", 12, ITALICFONT)
		If Not titleColor Then titleColor = TColor.Create(0,0,0)
		If Not textColor Then textColor = TColor.Create(50,50,50)

		'shorten the title to fit into the block
		While titleFont.getWidth(title + titleAppend) > maxWidth And title.length > 4
			title = title[..title.length-3]+".."
		Wend
		'add eg. "(1/10)"
		title = title + titleAppend

		'draw
		titleFont.drawBlock(title, textArea.position.GetIntX() + 5, textArea.position.GetIntY() +2, textArea.GetW() - 5, 18, Null, titleColor, 0, True, 1.0, False)
		useFont.draw(text, textArea.position.GetIntX() + 5, textArea.position.GetIntY() + 17, textColor)
		useFont.draw(text2, textArea.position.GetIntX() + 138, textArea.position.GetIntY() + 17, textColor)

		SetColor 255,255,255
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
							text = GetPlayerProgrammePlanCollection().Get(advertisement.owner).GetAdvertisementSpotNumber(advertisement) + "/" + advertisement.contract.GetSpotCount()
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

		'draw
		If Not titleColor Then titleColor = TColor.Create(0,0,0)
		If Not textColor Then textColor = TColor.Create(50,50,50)

		GetBitmapFont("DefaultThin", 10, BOLDFONT).drawBlock(title, textArea.position.GetIntX() + 3, textArea.position.GetIntY() + 2, textArea.GetW(), 18, Null, TColor.CreateGrey(0), 0,1,1.0, False)
		textColor.setRGB()
		GetBitmapFont("Default", 10).drawBlock(text, textArea.position.GetIntX() + 3, textArea.position.GetIntY() + 17, TextArea.GetW(), 30)
		GetBitmapFont("Default", 10).drawBlock(text2,textArea.position.GetIntX() + 3, textArea.position.GetIntY() + 17, TextArea.GetW(), 20, New TVec2D.Init(ALIGN_RIGHT))
		SetColor 255,255,255 'eigentlich alte Farbe wiederherstellen
	End Method


	Method DrawSheet(leftX:Int=30, rightX:Int=30, width:Int=0)
		Local sheetY:Float 	= 20
		Local sheetX:Float 	= leftX
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
		Local player:TPlayer = GetPlayerCollection().Get(material.owner)
		If player
			If day < 0 Then day = GetWorldTime().GetDay()
			startHour = player.GetProgrammePlan().GetObjectStartHour(material.materialType,day,0)
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




Type TPlannerList
	Field openState:Int		= 0		'0=enabled 1=openedgenres 2=openedmovies 3=openedepisodes = 1
	Field currentGenre:Int	=-1
	Field enabled:Int		= 0
	Field Pos:TVec2D 		= New TVec2D.Init()
	Field entriesRect:TRectangle
	Field entrySize:TVec2D = New TVec2D

	Method getOpen:Int()
		Return Self.openState And enabled
	End Method
End Type




'the programmelist shown in the programmeplaner
Type TgfxProgrammelist Extends TPlannerList
	Field displaceEpisodeTapes:TVec2D = New TVec2D.Init(6,5)
	'area of all genres/filters including top/bottom-area
	Field genresRect:TRectangle
	Field genresCount:Int = -1
	Field genreSize:TVec2D = New TVec2D
	Field currentEntry:Int = -1
	Field currentSubEntry:Int = -1
	Field subEntriesRect:TRectangle

	'licence with children
	Field hoveredParentalLicence:TProgrammeLicence = Null
	'licence 
	Field hoveredLicence:TProgrammeLicence = Null

	Const MODE_PROGRAMMEPLANNER:Int=0	'creates a GuiProgrammePlanElement
	Const MODE_ARCHIVE:Int=1			'creates a GuiProgrammeLicence

	

	Method Create:TgfxProgrammelist(x:Int, y:Int)
		genreSize = GetSpriteFromRegistry("gfx_programmegenres_entry.default").area.dimension.copy()
		entrySize = GetSpriteFromRegistry("gfx_programmeentries_entry.default").area.dimension.copy()

		'right align the list
		Pos.SetXY(x - genreSize.GetX(), y)

		'recalculate dimension of the area of all genres
		genresRect = New TRectangle.Init(Pos.GetX(), Pos.GetY(), genreSize.GetX(), 0)
		genresRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmegenres_top.default").area.GetH()
		genresRect.dimension.y :+ TProgrammeLicenceFilter.GetVisibleCount() * genreSize.GetY()
		genresRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmegenres_bottom.default").area.GetH()

		'recalculate dimension of the area of all entries (also if not all slots occupied)
		entriesRect = New TRectangle.Init(genresRect.GetX() - 175, genresRect.GetY(), entrySize.GetX(), 0)
		entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()
		entriesRect.dimension.y :+ GameRules.maxProgrammeLicencesPerFilter * entrySize.GetY()
		entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_bottom.default").area.GetH()

		'recalculate dimension of the area of all entries (also if not all slots occupied)
		subEntriesRect = New TRectangle.Init(entriesRect.GetX() + 175, entriesRect.GetY(), entrySize.GetX(), 0)
		subEntriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()
		subEntriesRect.dimension.y :+ 10 * entrySize.GetY()
		subEntriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_bottom.default").area.GetH()

		Return Self
	End Method


	Method Draw()
		If Not enabled Then Return

		'draw genre selector
		If Self.openState >=1
			'mark new genres
			'TODO: do this part in programmecollection (only on add/remove)
			Local visibleFilters:TProgrammeLicenceFilter[] = TProgrammeLicenceFilter.GetVisible()
			Local containsNew:Int[visibleFilters.length]

			For Local licence:TProgrammeLicence = EachIn GetPlayer().GetProgrammeCollection().justAddedProgrammeLicences
				'check all filters if they take care of this licence
				For Local i:Int = 0 Until visibleFilters.length
					'no check needed if already done
					If containsNew[i] Then Continue

					If visibleFilters[i].DoesFilter(licence)
						containsNew[i] = 1
						'do not check other filters
						Exit
					EndIf
				Next
			Next

			'=== DRAW ===
			Local currSprite:TSprite
			'maybe it has changed since initialization
			genreSize = GetSpriteFromRegistry("gfx_programmegenres_entry.default").area.dimension.copy()
			Local currY:Int = genresRect.GetY()
			Local currX:Int = genresRect.GetX()
			Local textRect:TRectangle = New TRectangle.Init(currX + 13, currY, genreSize.x - 12 - 5, genreSize.y)
			 
			Local oldAlpha:Float = GetAlpha()
			Local programmeCollection:TPlayerProgrammeCollection = GetPlayer().GetProgrammeCollection()

			'draw each visible filter
			Local filter:TProgrammeLicenceFilter
			For Local i:Int = 0 Until visibleFilters.length
				Local entryPositionType:String = "entry"
				If i = 0 Then entryPositionType = "first"
				If i = visibleFilters.length-1 Then entryPositionType = "last"

				Local entryDrawType:String = "default"
				'highlighted - if genre contains new entries
				If containsNew[i] = 1 Then entryDrawType = "highlighted"
				'active - if genre is the currently used (selected to see tapes)
				If i = currentGenre Then entryDrawType = "active"
				'hovered - draw hover effect if hovering
				'can only haver if no episode list is open
				If Self.openState <3 And THelper.MouseIn(currX, currY, genreSize.GetX(), genreSize.GetY()-1) Then entryDrawType="hovered"

				'add "top" portion when drawing first item
				'do this in the for loop, so the entrydrawType is known
				'(top-portion could contain color code of the drawType)
				If i = 0
					currSprite = GetSpriteFromRegistry("gfx_programmegenres_top."+entryDrawType)
					currSprite.draw(currX, currY)
					currY :+ currSprite.area.GetH()
				EndIf

				'draw background
				GetSpriteFromRegistry("gfx_programmegenres_"+entryPositionType+"."+entryDrawType).draw(currX,currY)

				'genre background contains a 2px splitter (bottom + top)
				'so add 1 pixel to textY
				textRect.position.SetY(currY + 1)


				Local licenceCount:Int = programmeCollection.GetFilteredLicenceCount(visibleFilters[i])
				Local filterName:String = visibleFilters[i].GetCaption()

				
				If licenceCount > 0
					GetBitmapFontManager().baseFont.drawBlock(filterName + " (" +licenceCount+ ")", textRect.GetX(), textRect.GetY(), textRect.GetW(), textRect.GetH(), ALIGN_LEFT_CENTER, TColor.clBlack)
Rem
					SetAlpha 0.6; SetColor 0, 255, 0
					'takes 20% of fps...
					For Local i:Int = 0 To genrecount -1
						DrawLine(currX + 121 + i * 2, currY + 4 + lineHeight*genres - 1, currX + 121 + i * 2, currY + 17 + lineHeight*genres - 1)
					Next
endrem
				Else
					SetAlpha 0.25 * GetAlpha()
					GetBitmapFontManager().baseFont.drawBlock(filterName, textRect.GetX(), textRect.GetY(), textRect.GetW(), textRect.GetH(), ALIGN_LEFT_CENTER, TColor.clBlack)
					SetAlpha 4 * GetAlpha()
				EndIf
				'advance to next line
				currY:+ genreSize.y

				'add "bottom" portion when drawing last item
				'do this in the for loop, so the entrydrawType is known
				'(top-portion could contain color code of the drawType)
				If i = visibleFilters.length-1
					currSprite = GetSpriteFromRegistry("gfx_programmegenres_bottom."+entryDrawType)
					currSprite.draw(currX, currY)
					currY :+ currSprite.area.GetH()
				EndIf
			Next
		EndIf

		'draw tapes of current genre + episodes of a selected series
		If Self.openState >=2 And currentGenre >= 0
			DrawTapes(currentgenre)
		EndIf

		'draw episodes background
		If Self.openState >=3
			If currentGenre >= 0 Then DrawSubTapes(hoveredParentalLicence)
		EndIf

	End Method


	Method DrawTapes:Int(filterIndex:Int=-1)
		'skip drawing tapes if no genreGroup is selected
		If filterIndex < 0 Then Return False


		Local currSprite:TSprite
		'maybe it has changed since initialization
		entrySize = GetSpriteFromRegistry("gfx_programmeentries_entry.default").area.dimension.copy()
		Local currY:Int = entriesRect.GetY()
		Local currX:Int = entriesRect.GetX()
		Local font:TBitmapFont = GetBitmapFont("Default", 10)
			 
		Local programmeCollection:TPlayerProgrammeCollection = GetPlayer().GetProgrammeCollection()
		Local filter:TProgrammeLicenceFilter = TProgrammeLicenceFilter.GetAtIndex(filterIndex)
		Local licences:TProgrammeLicence[] = programmeCollection.GetLicencesByFilter(filter)
		'draw slots, even if empty
		For Local i:Int = 0 Until GameRules.maxProgrammeLicencesPerFilter
			Local entryPositionType:String = "entry"
			If i = 0 Then entryPositionType = "first"
			If i = GameRules.maxProgrammeLicencesPerFilter-1 Then entryPositionType = "last"

			Local entryDrawType:String = "default"
			Local tapeDrawType:String = "default"
			If i < licences.length 
				'== BACKGROUND ==
				'planned is more important than new - both only happen
				'on startprogrammes
				If licences[i].IsPlanned()
					entryDrawType = "planned"
					tapeDrawType = "planned"
				Else
					'switch background to "new" if the licence is a just-added-one
					For Local licence:TProgrammeLicence = EachIn GetPlayer().GetProgrammeCollection().justAddedProgrammeLicences
						If licences[i] = licence
							entryDrawType = "new"
							tapeDrawType = "new"
							Exit
						EndIf
					Next
				EndIf
			EndIf

			
			'=== BACKGROUND ===
			'add "top" portion when drawing first item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			If i = 0
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_top."+entryDrawType)
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			EndIf
			GetSpriteFromRegistry("gfx_programmeentries_"+entryPositionType+"."+entryDrawType).draw(currX,currY)


			'=== DRAW TAPE===
			If i < licences.length
				'== ADJUST TAPE TYPE ==
				'do that afterwards because now "new" and "planned" are
				'already handled

				'active - if tape is the currently used
				If i = currentEntry Then tapeDrawType = "hovered"
				'hovered - draw hover effect if hovering
				'we add 1 pixel to height - to hover between tapes too
				If THelper.MouseIn(currX, currY + 1, entrySize.GetX(), entrySize.GetY()) Then tapeDrawType="hovered"


				If licences[i].isSingle()
					GetSpriteFromRegistry("gfx_programmetape_movie."+tapeDrawType).draw(currX + 8, currY+1)
				Else
					GetSpriteFromRegistry("gfx_programmetape_series."+tapeDrawType).draw(currX + 8, currY+1)
				EndIf
				font.drawBlock(licences[i].GetTitle(), currX + 22, currY + 3, 150,15, ALIGN_LEFT_CENTER, TColor.clBlack ,0, True, 1.0, False)

			EndIf


			'advance to next line
			currY:+ entrySize.y

			'add "bottom" portion when drawing last item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			If i = GameRules.maxProgrammeLicencesPerFilter-1
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_bottom."+entryDrawType)
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			EndIf
		Next
		
		Rem
		'debug
		currY = entriesRect.GetY()
		For Local i:Int = 0 To GameRules.maxProgrammeLicencesPerFilter
			if i = 0
				Local currSprite:TSprite
				If licences[0].IsPlanned()
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.planned")
				Else
					'switch background to "new" if the licence is a just-added-one
					For Local licence:TProgrammeLicence = EachIn GetPlayer().GetProgrammeCollection().justAddedProgrammeLicences
						If licences[i] = licence
							currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.new")
							Exit
						EndIf
					Next
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.default")
				EndIf

				currY :+ currSprite.area.GetH()
			EndIf
			
			SetColor 0,255,0
			If i mod 2 = 0 then SetColor 255,0,0
			SetAlpha 1.0
			DrawRect(entriesRect.GetX(), currY+1, entrySize.GetX(), 1)
			'we add 1 pixel to y - as we hover between tapes too
			DrawRect(entriesRect.GetX(), currY+1 + entrySize.GetY() - 1, entrySize.GetX(), 1)
			SetAlpha 0.4
			'we add 1 pixel to height - as we hover between tapes too
			DrawRect(entriesRect.GetX(), currY+1, entrySize.GetX(), entrySize.GetY())

			currY:+ entrySize.y

			SetColor 255,255,255
			SetAlpha 1.0
		Next
		endrem
	End Method


	Method UpdateTapes:Int(filterIndex:Int=-1, mode:Int=0)
		'skip doing something without a selected filter
		If filterIndex < 0 Then Return False

		Local currY:Int = entriesRect.GetY()
		Local programmeCollection:TPlayerProgrammeCollection = GetPlayer().GetProgrammeCollection()
		Local filter:TProgrammeLicenceFilter = TProgrammeLicenceFilter.GetAtIndex(filterIndex)
		Local licences:TProgrammeLicence[] = programmeCollection.GetLicencesByFilter(filter)

		For Local i:Int = 0 Until licences.length

			If i = 0
				Local currSprite:TSprite
				If licences[0].IsPlanned()
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.planned")
				Else
					'switch background to "new" if the licence is a just-added-one
					For Local licence:TProgrammeLicence = EachIn GetPlayer().GetProgrammeCollection().justAddedProgrammeLicences
						If licences[i] = licence
							currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.new")
							Exit
						EndIf
					Next
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.default")
				EndIf

				currY :+ currSprite.area.GetH()
			EndIf

			'we add 1 pixel to height - to hover between tapes too
			If THelper.MouseIn(entriesRect.GetX(), currY+1, entrySize.GetX(), entrySize.GetY())
				Game.cursorstate = 1
				Local doneSomething:Int = False
				'store for sheet-display
				hoveredLicence = licences[i]
				If MOUSEMANAGER.IsHit(1)
					If mode = MODE_PROGRAMMEPLANNER
						If licences[i].isSingle()
							'create and drag new block
							New TGUIProgrammePlanElement.CreateWithBroadcastMaterial( New TProgramme.Create(licences[i]), "programmePlanner" ).drag()
							SetOpen(0)
							doneSomething = True
						Else
							'set the hoveredParentalLicence so the episodes-list is drawn
							hoveredParentalLicence = licences[i]
							SetOpen(3)
							doneSomething = True
						EndIf
					ElseIf mode = MODE_ARCHIVE
						'create a dragged block
						Local obj:TGUIProgrammeLicence = New TGUIProgrammeLicence.CreateWithLicence(licences[i])
						obj.SetLimitToState("archive")
						obj.drag()

						SetOpen(0)
						doneSomething = True
					EndIf

					'something changed, so stop looping through rest
					If doneSomething
						MOUSEMANAGER.resetKey(1)
						MOUSEMANAGER.resetClicked(1)
						Return True
					EndIf
				EndIf
			EndIf

			'next tape
			currY :+ entrySize.y
		Next
		Return False
	End Method


	Method DrawSubTapes:Int(parentLicence:TProgrammeLicence)
		If Not parentLicence Then Return False

		Local hoveredLicence:TProgrammeLicence = Null
		Local currSprite:TSprite
		Local currY:Int = subEntriesRect.GetY()
		Local currX:Int = subEntriesRect.GetX()
		Local font:TBitmapFont = GetBitmapFont("Default", 10)
				
		For Local i:Int = 0 To parentLicence.GetSubLicenceCount()-1
			Local licence:TProgrammeLicence = parentLicence.GetsubLicenceAtIndex(i)

			Local entryPositionType:String = "entry"
			If i = 0 Then entryPositionType = "first"
			If i = parentLicence.GetSubLicenceCount()-1 Then entryPositionType = "last"

			Local entryDrawType:String = "default"
			Local tapeDrawType:String = "default"
			If licence
				'== BACKGROUND ==
				If licence.IsPlanned()
					entryDrawType = "planned"
					tapeDrawType = "planned"
				EndIf
			EndIf

			
			'=== BACKGROUND ===
			'add "top" portion when drawing first item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			If i = 0
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_top."+entryDrawType)
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			EndIf
			GetSpriteFromRegistry("gfx_programmeentries_"+entryPositionType+"."+entryDrawType).draw(currX,currY)


			'=== DRAW TAPE===
			If licence
				'== ADJUST TAPE TYPE ==
				'active - if tape is the currently used
				If i = currentSubEntry Then tapeDrawType = "hovered"
				'hovered - draw hover effect if hovering
				If THelper.MouseIn(currX, currY + 1, entrySize.GetX(), entrySize.GetY()) Then tapeDrawType="hovered"

				If licence.isSingle()
					GetSpriteFromRegistry("gfx_programmetape_movie."+tapeDrawType).draw(currX + 8, currY+1)
				Else
					GetSpriteFromRegistry("gfx_programmetape_series."+tapeDrawType).draw(currX + 8, currY+1)
				EndIf
				font.drawBlock("(" + (i+1) + "/" + parentLicence.GetSubLicenceCount() + ") " + licence.GetTitle(), currX + 22, currY + 3, 150,15, ALIGN_LEFT_CENTER, TColor.clBlack ,0, True, 1.0, False)
			EndIf


			'advance to next line
			currY:+ entrySize.y

			'add "bottom" portion when drawing last item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			If i = parentLicence.GetSubLicenceCount()-1
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_bottom."+entryDrawType)
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			EndIf
		Next

		Rem
		'debug - hitbox
		currY = subEntriesRect.GetY()
		For Local i:Int = 0 To parentLicence.GetSubLicenceCount()-1
			Local licence:TProgrammeLicence = parentLicence.GetsubLicenceAtIndex(i)

			If i = 0
				Local currSprite:TSprite
				If licence And licence.IsPlanned()
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.planned")
				else
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.default")
				endif
				currY :+ currSprite.area.GetH()
			EndIf


			If THelper.MouseIn(subEntriesRect.GetX(), currY + 1, entrySize.GetX(), entrySize.GetY())
				SetColor 100,255,100
				If i mod 2 = 0 then SetColor 255,100,100
			Else
				SetColor 0,255,0
				If i mod 2 = 0 then SetColor 255,0,0
			EndIf
			SetAlpha 1.0
			DrawRect(subEntriesRect.GetX(), currY + 1, entrySize.GetX(), 1)
			DrawRect(subEntriesRect.GetX(), currY + 1 + entrySize.GetY() - 1, entrySize.GetX(), 1)
			SetAlpha 0.3
			'complete size
			DrawRect(subEntriesRect.GetX(), currY + 1, entrySize.GetX(), entrySize.GetY() - 1)

			currY:+ entrySize.y

			SetColor 255,255,255
			SetAlpha 1.0
		Next
		EndRem
	End Method


	Method UpdateSubTapes:Int(parentLicence:TProgrammeLicence)
		If Not parentLicence Then Return False
		
		Local currY:Int = subEntriesRect.GetY() '+ GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()

		For Local i:Int = 0 To parentLicence.GetSubLicenceCount()-1
			Local licence:TProgrammeLicence = parentLicence.GetsubLicenceAtIndex(i)

			If i = 0
				Local currSprite:TSprite
				If licence And licence.IsPlanned()
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.planned")
				else
					currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.default")
				endif
				currY :+ currSprite.area.GetH()
			EndIf

			
			If licence
				If THelper.MouseIn(subEntriesRect.GetX(), currY + 1, entrySize.GetX(), entrySize.GetY())
					Game.cursorstate = 1 'mouse-over-hand

					'store for sheet-display
					hoveredLicence = licence
					If MOUSEMANAGER.IsHit(1)
						'create and drag new block
						New TGUIProgrammePlanElement.CreateWithBroadcastMaterial( New TProgramme.Create(licence), "programmePlanner" ).drag()
						SetOpen(0)
						MOUSEMANAGER.resetKey(1)
						Return True
					EndIf
				EndIf
			EndIf

			'next tape
			currY :+ entrySize.y
		Next
		Return False
	End Method


	Method Update:Int(mode:Int=0)
		'gets repopulated automagically if hovered
		hoveredLicence = Null

		'if not "open", do nothing (including checking right clicks)
		If Not GetOpen() Then Return False

		'clicking on the genre selector -> select Genre
		'instead of isClicked (butten must be "normal" then)
		'we use "hit" (as soon as mouse button down)
		Local genresStartY:Int = GetSpriteFromRegistry("gfx_programmegenres_top.default").area.GetH()

		'only react to genre area if episode area is not open
		If openState <3
			If MOUSEMANAGER.IsHit(1) And THelper.MouseIn(genresRect.GetX(), genresRect.GetY() + genresStartY, genresRect.GetW(), genreSize.GetY()*TProgrammeLicenceFilter.GetVisibleCount())
				SetOpen(2)
				Local visibleFilters:TProgrammeLicenceFilter[] = TProgrammeLicenceFilter.GetVisible()
				currentGenre = Max(0, Min(visibleFilters.length-1, Floor((MouseManager.y - (genresRect.GetY() + genresStartY)) / genreSize.GetY())))
				MOUSEMANAGER.ResetKey(1)
			EndIf
		EndIf

		'if the genre is selected, also take care of its programmes
		If Self.openState >=2
			If currentgenre >= 0 Then UpdateTapes(currentgenre, mode)
			'series episodes are only available in mode 0, so no mode-param to give
			If hoveredParentalLicence Then UpdateSubTapes(hoveredParentalLicence)
		EndIf

		'close if clicked outside - simple mode: so big rect
		If MouseManager.isHit(1) ' and mode=MODE_ARCHIVE
			Local closeMe:Int = True
			'in all cases the genre selector is opened
			If genresRect.containsXY(MouseManager.x, MouseManager.y) Then closeMe = False
			'check tape rect
			If openState >=2 And entriesRect.containsXY(MouseManager.x, MouseManager.y)  Then closeMe = False
			'check episodetape rect
			If openState >=3 And subEntriesRect.containsXY(MouseManager.x, MouseManager.y)  Then closeMe = False

			If closeMe
				SetOpen(0)
				'MouseManager.ResetKey(1)
			EndIf
		EndIf
	End Method


	Method SetOpen:Int(newState:Int)
		newState = Max(0, newState)
		If newState <= 1 Then currentgenre=-1
		If newState <= 2 Then hoveredParentalLicence=Null
		If newState = 0
			enabled = 0
		Else
			enabled = 1
		EndIf

		Self.openState = newState
	End Method
End Type




'the adspot/contractlist shown in the programmeplaner
Type TgfxContractlist Extends TPlannerList
	Field hoveredAdContract:TAdContract = Null

	Method Create:TgfxContractlist(x:Int, y:Int)
		entrySize = GetSpriteFromRegistry("gfx_programmeentries_entry.default").area.dimension.copy()

		'right align the list
		Pos.SetXY(x - entrySize.GetX(), y)

		'recalculate dimension of the area of all entries (also if not all slots occupied)
		entriesRect = New TRectangle.Init(Pos.GetX(), Pos.GetY(), entrySize.GetX(), 0)
		entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()
		entriesRect.dimension.y :+ GameRules.maxContracts * entrySize.GetY()
		entriesRect.dimension.y :+ GetSpriteFromRegistry("gfx_programmeentries_bottom.default").area.GetH()

		Return Self
	End Method


	Method Draw:Int()
		If Not enabled Or Self.openState < 1 Then Return False

		Local currSprite:TSprite
		'maybe it has changed since initialization
		entrySize = GetSpriteFromRegistry("gfx_programmeentries_entry.default").area.dimension.copy()
		Local currX:Int = entriesRect.GetX()
		Local currY:Int = entriesRect.GetY()
		Local font:TBitmapFont = GetBitmapFont("Default", 10)

		Local programmeCollection:TPlayerProgrammeCollection = GetPlayer().GetProgrammeCollection()
		'draw slots, even if empty
		For Local i:Int = 0 Until 10 'GameRules.maxContracts
			Local contract:TAdContract = programmeCollection.GetAdContractAtIndex(i)

			Local entryPositionType:String = "entry"
			If i = 0 Then entryPositionType = "first"
			If i = GameRules.maxContracts-1 Then entryPositionType = "last"

		
			'=== BACKGROUND ===
			'add "top" portion when drawing first item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			If i = 0
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_top.default")
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			EndIf
			GetSpriteFromRegistry("gfx_programmeentries_"+entryPositionType+".default").draw(currX,currY)


			'=== DRAW TAPE===
			If contract
				'hovered - draw hover effect if hovering
				If THelper.MouseIn(currX, currY, entrySize.GetX(), entrySize.GetY()-1)
					GetSpriteFromRegistry("gfx_programmetape_movie.hovered").draw(currX + 8, currY+1)
				Else
					GetSpriteFromRegistry("gfx_programmetape_movie.default").draw(currX + 8, currY+1)
				EndIf

				if TVTDebugInfos
					font.drawBlock(contract.GetProfit() +CURRENCYSIGN+" @ "+ contract.GetMinAudience(), currX + 22, currY + 3, 150,15, ALIGN_LEFT_CENTER, TColor.clBlack ,0, True, 1.0, False)
				else
					font.drawBlock(contract.GetTitle(), currX + 22, currY + 3, 150,15, ALIGN_LEFT_CENTER, TColor.clBlack ,0, True, 1.0, False)
				endif
			EndIf


			'advance to next line
			currY:+ entrySize.y

			'add "bottom" portion when drawing last item
			'do this in the for loop, so the entrydrawType is known
			'(top-portion could contain color code of the drawType)
			If i = GameRules.maxContracts-1
				currSprite = GetSpriteFromRegistry("gfx_programmeentries_bottom.default")
				currSprite.draw(currX, currY)
				currY :+ currSprite.area.GetH()
			EndIf
		Next
	End Method


	Method Update:Int()
		'gets repopulated if an contract is hovered
		hoveredAdContract = Null

		If Not enabled Then Return False

		If Self.openState >= 1
			Local currY:Int = entriesRect.GetY() + GetSpriteFromRegistry("gfx_programmeentries_top.default").area.GetH()

			Local programmeCollection:TPlayerProgrammeCollection = GetPlayer().GetProgrammeCollection()
			For Local i:Int = 0 Until GameRules.maxContracts
				Local contract:TAdContract = programmeCollection.GetAdContractAtIndex(i)

				If contract And THelper.MouseIn(entriesRect.GetX(), currY, entrySize.GetX(), entrySize.GetY()-1)
					'store for outside use (eg. displaying a sheet)
					hoveredAdContract = contract

					Game.cursorstate = 1
					If MOUSEMANAGER.IsHit(1)
						New TGUIProgrammePlanElement.CreateWithBroadcastMaterial( New TAdvertisement.Create(contract), "programmePlanner" ).drag()
						MOUSEMANAGER.resetKey(1)
						SetOpen(0)
					EndIf
				EndIf

				'next tape
				currY :+ entrySize.y
			Next
		EndIf

		If MOUSEMANAGER.IsHit(2)
			SetOpen(0)
			MOUSEMANAGER.resetKey(2)
		EndIf

		'close if mouse hit outside - simple mode: so big rect
		If MouseManager.IsHit(1)
			If Not entriesRect.containsXY(MouseManager.x, MouseManager.y)
				SetOpen(0)
				'MouseManager.ResetKey(1)
			EndIf
		EndIf
	End Method


	Method SetOpen:Int(newState:Int)
		newState = Max(0, newState)
		If newState <= 0 Then enabled = 0 Else enabled = 1
		Self.openState = newState
	End Method
End Type





'Programmeblocks used in Auction-Screen
'they do not need to have gui/non-gui objects as no special
'handling is done (just clicking)
Type TAuctionProgrammeBlocks Extends TGameObject {_exposeToLua="selected"}
	Field area:TRectangle = New TRectangle.Init(0,0,0,0)
	Field licence:TProgrammeLicence		'the licence getting auctionated (a series, movie or collection)
	Field bestBid:Int = 0				'what was bidden for that licence
	Field bestBidder:Int = 0			'what was bidden for that licence
	Field slot:Int = 0					'for ordering (and displaying sheets without overlapping)
	Field bidSavings:Float = 0.75		'how much to shape of the original price
	'cached image
	Field _imageWithText:TImage = Null {nosave}

	Global bidSavingsMaximum:Float		= 0.85			'base value
	Global bidSavingsMinimum:Float		= 0.50			'base value
	Global bidSavingsDecreaseBy:Float	= 0.05			'reduce the bidSavings-value per day
	Global List:TList = CreateList()	'list of all blocks

	'todo/idea: we could add a "started" and a "endTime"-field so
	'           auctions do not end at midnight but individually


	Method Create:TAuctionProgrammeBlocks(slot:Int=0, licence:TProgrammeLicence)
		Self.area.position.SetXY(140 + (slot Mod 2) * 260, 80 + Ceil(slot / 2) * 60)
		Self.area.dimension.CopyFrom(GetSpriteFromRegistry("gfx_auctionmovie").area.dimension)
		Self.slot = slot
		Self.Refill(licence)
		List.AddLast(Self)

		'sort so that slot1 comes before slot2 without having to matter about creation order
		TAuctionProgrammeBlocks.list.sort(True, TAuctionProgrammeBlocks.sort)
		Return Self
	End Method


	Function GetByLicence:TAuctionProgrammeBlocks(licence:TProgrammeLicence, licenceID:Int=-1)
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			If licence And obj.licence = licence Then Return obj
			If obj.licence and obj.licence.id = licenceID Then Return obj
		Next
		Return Null
	End Function


	Function Sort:Int(o1:Object, o2:Object)
		Local s1:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(o1)
		Local s2:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.slot)-(s2.slot)
	End Function


	'give all won auctions to the winners
	Function EndAllAuctions()
		For Local obj:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			obj.EndAuction()
		Next
	End Function


	'sets another licence into the slot
	Method Refill:Int(programmeLicence:TProgrammeLicence=Null)
		'turn back licence if nobody bought the old one
		if licence and licence.owner = TOwnedGameObject.OWNER_VENDOR
			licence.SetOwner( TOwnedGameObject.OWNER_NOBODY )
		endif
	
		licence = programmeLicence
		Local minPrice:Int = 200000

		While Not licence And minPrice >= 0
			licence = GetProgrammeLicenceCollection().GetRandomWithPrice(minPrice)
			'lower the requirements
			If Not licence Then minPrice :- 10000
		Wend
		If not licence
			TLogger.log("AuctionProgrammeBlocks.Refill()", "No licences for new auction found. Database needs more entries!", LOG_ERROR)
			'If Not licence Then Throw "[ERROR] TAuctionProgrammeBlocks.Refill - no licence"
		EndIf

		if licence
			'set licence owner to "-1" so it gets not returned again from Random-Getter
			licence.SetOwner( TOwnedGameObject.OWNER_VENDOR )
		endif

		'reset cache
		_imageWithText = Null
		'reset bids
		bestBid = 0
		bestBidder = 0
		bidSavings = bidSavingsMaximum
		'emit event
		EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.Refill", New TData.Add("licence", licence).AddNumber("slot", slot), Self))
	End Method


	Method EndAuction:Int()
		'if there was no licence stored, try again to refill the block
		If not licence
			Refill()
			Return False
		EndIf

		
		If bestBidder
			Local player:TPlayer = GetPlayerCollection().Get(bestBidder)
			player.GetProgrammeCollection().AddProgrammeLicence(licence)

			If player.isLocalAI()
				player.PlayerAI.CallOnProgrammeLicenceAuctionWin(licence, bestBid)
			EndIf

			'emit event so eg. toastmessages could attach
			Local evData:TData = New TData
			evData.Add("licence", licence)
			evData.AddNumber("bestBidder", player.playerID)
			evData.AddNumber("bestBid", bestBid)
			EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.onWin", evData, Self))
		End If

		'emit event
		Local evData:TData = New TData
		evData.Add("licence", licence)
		evData.AddNumber("bestBidder", bestBidder)
		evData.AddNumber("bestBid", bestBid)
		evData.AddNumber("bidSavings", bidSavings)
		EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.onEndAuction", evData, Self))

		'found nobody to buy this licence
		'so we decrease price a bit
		If Not bestBidder
			Self.bidSavings :- Self.bidSavingsDecreaseBy
		EndIf

		'if we had a bidder or found nobody with the allowed price minimum
		'we add another licence to this block and reset everything
		If bestBidder Or Self.bidSavings < Self.bidSavingsMinimum
			Refill()
		EndIf
	End Method


	Method GetLicence:TProgrammeLicence()  {_exposeToLua}
		Return licence
	End Method


	Method SetBid:Int(playerID:Int)
		If not licence Then Return -1
		
		Local player:TPlayer = GetPlayer(playerID)
		If Not player Then Return -1
		'if the playerID was -1 ("auto") we should assure we have a correct id now
		playerID = player.playerID
		'already highest bidder, no need to add another bid
		If playerID = bestBidder Then Return 0

		Local price:Int = GetNextBid()
		If player.getFinance().PayAuctionBid(price, Self.GetLicence())
			'another player was highest bidder, we pay him back the
			'bid he gave (which is the currently highest bid...)
			If bestBidder And GetPlayer(bestBidder)
				GetPlayerFinance(bestBidder).PayBackAuctionBid(bestBid, Self)

				'inform player AI that their bid was overbid
				If GetPlayer(bestBidder).isLocalAI()
					GetPlayer(bestBidder).PlayerAI.CallOnProgrammeLicenceAuctionGetOutbid(GetLicence(), price, playerID)
				EndIf
				
				'emit event so eg. toastmessages could attach
				Local evData:TData = New TData
				evData.Add("licence", GetLicence())
				evData.AddNumber("previousBestBidder", bestBidder)
				evData.AddNumber("previousBestBid", bestBid)
				evData.AddNumber("bestBidder", playerID)
				evData.AddNumber("bestBid", price)
				EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.onGetOutbid", evData, Self))
			EndIf
			'set new bid values
			bestBidder = playerID
			bestBid = price


			'reset so cache gets renewed
			_imageWithText = Null

			'emit event
			Local evData:TData = New TData
			evData.Add("licence", GetLicence())
			evData.AddNumber("bestBidder", bestBidder)
			evData.AddNumber("bestBid", bestBid)
			EventManager.triggerEvent(TEventSimple.Create("ProgrammeLicenceAuction.setBid", evData, Self))
		EndIf
		Return price
	End Method


	Method GetNextBid:Int() {_exposeToLua}
		If not licence Then Return -1

		Local nextBid:Int = 0
		'no bid done yet, next bid is the licences price cut by 25%
		If bestBid = 0
			nextBid = licence.getPrice() * 0.75
		Else
			nextBid = bestBid

			If nextBid < 100000
				nextBid :+ 10000
			Else If nextBid >= 100000 And nextBid < 250000
				nextBid :+ 25000
			Else If nextBid >= 250000 And nextBid < 750000
				nextBid :+ 50000
			Else If nextBid >= 750000
				nextBid :+ 75000
			EndIf
		EndIf

		Return nextBid
	End Method


	Method ShowSheet:Int(x:Int,y:Int)
		If not licence Then Return -1
		
		licence.ShowSheet(x,y)
	End Method


    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()
		If not licence Then Return

		SetColor 255,255,255  'normal
		'not yet cached?
	    If Not _imageWithText
			'print "renew cache for "+self.licence.GetTitle()
			_imageWithText = GetSpriteFromRegistry("gfx_auctionmovie").GetImageCopy()
			If Not _imageWithText Then Throw "GetImage Error for gfx_auctionmovie"

			Local pix:TPixmap = LockImage(_imageWithText)
			Local font:TBitmapFont		= GetBitmapFont("Default", 12)
			Local titleFont:TBitmapFont	= GetBitmapFont("Default", 12, BOLDFONT)

			'set target for fonts
			TBitmapFont.setRenderTarget(_imageWithText)

			If bestBidder
				Local player:TPlayer = GetPlayerCollection().Get(bestBidder)
				titleFont.drawStyled(player.name, 31,33, player.color, 2, 1, 0.25)
			Else
				font.drawStyled(GetLocale("AUCTION_WITHOUT_BID"), 31,33, TColor.CreateGrey(150), 0, 1, 0.25)
			EndIf
			titleFont.drawBlock(licence.GetTitle(), 31,5, 215,30, Null, TColor.clBlack, 1, 1, 0.50)

			font.drawBlock(GetLocale("AUCTION_MAKE_BID")+": "+TFunctions.DottedValue(GetNextBid())+CURRENCYSIGN, 31,33, 212,20, New TVec2D.Init(ALIGN_RIGHT), TColor.clBlack, 1)

			'reset target for fonts
			TBitmapFont.setRenderTarget(Null)
	    EndIf
		SetColor 255,255,255
		SetAlpha 1
		DrawImage(_imageWithText, area.GetX(), area.GetY())
    End Method


	Function DrawAll()
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			If not obj.GetLicence() Then continue

			obj.Draw()
		Next

		'draw sheets (must be afterwards to avoid overlapping (itemA Sheet itemB itemC) )
		For Local obj:TAuctionProgrammeBlocks = EachIn List
			If not obj.GetLicence() Then continue
			
			If obj.area.containsXY(MouseManager.x, MouseManager.y)
				Local leftX:Int = 30, rightX:Int = 30
				Local sheetY:Float 	= 20
				Local sheetX:Float 	= leftX
				Local sheetAlign:Int= 0
				'if mouse on left side of screen - align sheet on right side
				If MouseManager.x < GetGraphicsManager().GetWidth()/2
					sheetX = GetGraphicsManager().GetWidth() - rightX
					sheetAlign = 1
				EndIf

				SetBlend LightBlend
				SetAlpha 0.20
				GetSpriteFromRegistry("gfx_auctionmovie").Draw(obj.area.GetX(), obj.area.GetY())
				SetAlpha 1.0
				SetBlend AlphaBlend


				obj.licence.ShowSheet(sheetX, sheetY, sheetAlign, TVTBroadcastMaterialType.PROGRAMME)
				Exit
			EndIf
		Next
	End Function



	Function UpdateAll:Int()
		'without clicks we do not need to handle things
		If Not MOUSEMANAGER.IsClicked(1) Then Return False

		For Local obj:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			If not obj.GetLicence() Then continue

			If obj.bestBidder <> GetPlayerCollection().playerID And obj.area.containsXY(MouseManager.x, MouseManager.y)
				obj.SetBid( GetPlayerCollection().playerID )  'set the bid
				MOUSEMANAGER.ResetKey(1)
				Return True
			EndIf
		Next
	End Function

End Type






'a graphical representation of programmes/news/ads...
Type TGUINews Extends TGUIGameListItem
	Field news:TNews = Null
	Field imageBaseName:String = "gfx_news_sheet"
	Field cacheTextOverlay:TImage

    Method Create:TGUINews(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		Super.Create(pos, dimension, value)

		Return Self
	End Method

	Method SetNews:Int(news:TNews)
		Self.news = news
		If news
			'now we can calculate the item width
			Self.Resize( GetSpriteFromRegistry(Self.imageBaseName+news.newsEvent.genre).area.GetW(), GetSpriteFromRegistry(Self.imageBaseName+news.newsEvent.genre).area.GetH() )
		EndIf
		'self.SetLimitToState("Newsplanner")

		'as the news inflicts the sorting algorithm - resort
		GUIManager.sortLists()
	End Method


	Method Compare:Int(Other:Object)
		Local otherBlock:TGUINews = TGUINews(Other)
		If otherBlock<>Null
			'both items are dragged - check time
			If Self._flags & GUI_OBJECT_DRAGGED And otherBlock._flags & GUI_OBJECT_DRAGGED
				'if a drag was earlier -> move to top
				If Self._timeDragged < otherBlock._timeDragged Then Return 1
				If Self._timeDragged > otherBlock._timeDragged Then Return -1
				Return 0
			EndIf

			If Self.news And otherBlock.news
				Local publishDifference:Int = Self.news.GetPublishTime() - otherBlock.news.GetPublishTime()

				'self is newer ("later") than other
				If publishDifference>0 Then Return -1
				'self is older than other
				If publishDifference<0 Then Return 1
				'self is same age than other
				If publishDifference=0 Then Return Super.Compare(Other)
			EndIf
		EndIf

		Return Super.Compare(Other)
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		'set mouse to "hover"
		If news.owner = GetPlayerCollection().playerID Or news.owner <= 0 And mouseover Then Game.cursorstate = 1
		'set mouse to "dragged"
		If isDragged() Then Game.cursorstate = 2
	End Method


	Method DrawTextOverlay()
		Local screenX:Float = Int(GetScreenX())
		Local screenY:Float = Int(GetScreenY())

		'===== CREATE CACHE IF MISSING =====
		If Not cacheTextOverlay
			cacheTextOverlay = TFunctions.CreateEmptyImage(rect.GetW(), rect.GetH())
'			cacheTextOverlay = CreateImage(rect.GetW(), rect.GetH(), DYNAMICIMAGE | FILTEREDIMAGE)

			'render to image
			TBitmapFont.SetRenderTarget(cacheTextOverlay)

			'default texts (title, text,...)
			GetBitmapFontManager().basefontBold.drawBlock(news.GetTitle(), 15, 2, 330, 15, Null, TColor.CreateGrey(20))
			GetBitmapFontManager().baseFont.drawBlock(news.GetDescription(), 15, 17, 340, 50 + 8, Null, TColor.CreateGrey(100))

			Local oldAlpha:Float = GetAlpha()
			SetAlpha 0.3*oldAlpha
			GetBitmapFont("Default", 9).drawBlock(news.GetGenreString(), 15, 73, 120, 15, Null, TColor.clBlack)
			SetAlpha 1.0*oldAlpha

			'set back to screen Rendering
			TBitmapFont.SetRenderTarget(Null)
		EndIf

		'===== DRAW CACHE =====
		DrawImage(cacheTextOverlay, screenX, screenY)
	End Method


	Method DrawContent()
		State = 0
		SetColor 255,255,255

		If Self.RestrictViewPort()
			Local screenX:Float = Int(GetScreenX())
			Local screenY:Float = Int(GetScreenY())

			Local oldAlpha:Float = GetAlpha()
			Local itemAlpha:Float = 1.0
			'fade out dragged
			If isDragged() Then itemAlpha = 0.25 + 0.5^GuiManager.GetDraggedNumber(Self)

			SetAlpha oldAlpha*itemAlpha
			'background - no "_dragged" to add to name
			GetSpriteFromRegistry(Self.imageBaseName+news.GetGenre()).Draw(screenX, screenY)

			'highlight hovered news (except already dragged)
			If Not isDragged() And Self = RoomHandler_News.hoveredGuiNews
				Local oldAlpha:Float = GetAlpha()
				SetBlend LightBlend
				SetAlpha 0.30*oldAlpha
				SetColor 150,150,150
				GetSpriteFromRegistry(Self.imageBaseName+news.GetGenre()).Draw(screenX, screenY)
				SetAlpha oldAlpha
				SetBlend AlphaBlend
			EndIf

			'===== DRAW CACHED TEXTS =====
			'creates cache if needed
			DrawTextOverlay()

			'===== DRAW NON-CACHED TEXTS =====
			If Not news.paid
				GetBitmapFontManager().basefontBold.drawBlock(news.GetPrice() + ",-", screenX + 262, screenY + 70, 90, -1, New TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)
			Else
				GetBitmapFontManager().basefontBold.drawBlock(news.GetPrice() + ",-", screenX + 262, screenY + 70, 90, -1, New TVec2D.Init(ALIGN_RIGHT), TColor.CreateGrey(50))
			EndIf

			Select GetWorldTime().GetDay() - GetWorldTime().GetDay(news.GetHappenedtime())
				Case 0	GetBitmapFontManager().baseFont.drawBlock(GetLocale("TODAY")+" " + GetWorldTime().GetFormattedTime(news.GetHappenedtime()), screenX + 90, screenY + 73, 140, 15, New TVec2D.Init(ALIGN_RIGHT), TColor.clBlack )
				Case 1	GetBitmapFontManager().baseFont.drawBlock("("+GetLocale("OLD")+") "+GetLocale("YESTERDAY")+" "+ GetWorldTime().GetFormattedTime(news.GetHappenedtime()), screenX + 90, screenY + 73, 140, 15, New TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)
				Case 2	GetBitmapFontManager().baseFont.drawBlock("("+GetLocale("OLD")+") "+GetLocale("TWO_DAYS_AGO")+" " + GetWorldTime().GetFormattedTime(news.GetHappenedtime()), screenX + 90, screenY + 73, 140, 15, New TVec2D.Init(ALIGN_RIGHT), TColor.clBlack)
			End Select

			SetColor 255, 255, 255
			SetAlpha oldAlpha
	
			Self.resetViewport()
		EndIf

		If TVTDebugInfos
			Local oldAlpha:Float = GetAlpha()
			SetAlpha oldAlpha * 0.75
			SetColor 0,0,0

			Local w:Int = rect.GetW()
			Local h:Int = rect.GetH()
			Local screenX:Float = Int(GetScreenX())
			Local screenY:Float = Int(GetScreenY())
			DrawRect(screenX, screenY, w,h)
		
			SetColor 255,255,255
			SetAlpha 1.0

			Local textY:Int = screenY + 2
			Local fontBold:TBitmapFont = GetBitmapFontManager().basefontBold
			Local fontNormal:TBitmapFont = GetBitmapFontManager().basefont
			
			fontBold.draw("News: " + news.newsEvent.GetTitle(), screenX + 5, textY)
			textY :+ 14	
			fontNormal.draw("Preis: " + news.GetPrice()+"  (Preismodifikator: "+news.newsEvent.priceModifier+")", screenX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Qualitaet: "+news.GetQuality() +" (Event:"+ news.newsEvent.quality + ")", screenX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Attraktivitaet: "+news.newsEvent.GetAttractiveness()+"    Aktualitaet: " + news.newsEvent.ComputeTopicality(), screenX + 5, textY)
			textY :+ 12	
			fontNormal.draw("Alter: " + Long(GetWorldTime().GetTimeGone() - news.GetHappenedtime()) + " Sekunden  (" + (GetWorldTime().GetDay() - GetWorldTime().GetDay(news.GetHappenedtime())) + " Tage)", screenX + 5, textY)
			textY :+ 12	
			Rem
			local eventCan:string = ""
			if news.newsEvent.skippable
				eventCan :+ "ueberspringbar)"
			else
				eventCan :+ "nicht ueberspringbar"
			endif
			if eventCan <> "" then eventCan :+ ",  "
			if news.newsEvent.reuseable
				eventCan :+ "erneut nutzbar"
			else
				eventCan :+ "nicht erneut nutzbar"
			endif
			
			fontNormal.draw("Ist: " + eventCan, screenX + 5, textY)
			textY :+ 12	
			endrem
			fontNormal.draw("Effekte: " + news.newsEvent.happenEffects.Length + "x onHappen, "+news.newsEvent.broadcastEffects.Length + "x onBroadcast    Newstyp: " + news.newsEvent.newsType + "   Genre: "+news.newsEvent.genre, screenX + 5, textY)
			textY :+ 12	

			SetAlpha oldAlpha
		EndIf
	End Method
End Type




Type TGUIProgrammeLicenceSlotList Extends TGUISlotList
	Field  acceptType:Int		= 0	'accept all
	Global acceptAll:Int		= 0
	Global acceptMovies:Int		= 1
	Global acceptSeries:Int		= 2

    Method Create:TGUIProgrammeLicenceSlotList(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
		Super.Create(position, dimension, limitState)

		'albeit the list base already handles drop on itself
		'we want to intercept too -- to stop dropping if not
		'enough money is available
		'---alternatively we could intercept programmeblocks-drag-event
		'EventManager.registerListenerFunction( "guiobject.onDropOnTarget", self.onDropOnTarget, accept, self)

		Return Self
	End Method


	Method ContainsLicence:Int(licence:TProgrammeLicence)
		For Local i:Int = 0 To Self.GetSlotAmount()-1
			Local block:TGUIProgrammeLicence = TGUIProgrammeLicence(Self.GetItemBySlot(i))
			If block And block.licence = licence Then Return True
		Next
		Return False
	End Method


	'overriden Method: so it does not accept a certain
	'kind of programme (movies - series)
	Method AddItem:Int(item:TGUIobject, extra:Object=Null)
		Local coverBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(item)
		If Not coverBlock Then Return False

		'something odd happened - no licence
		If Not coverBlock.licence Then Return False

		If acceptType > 0
			'movies and series do not accept collections or episodes
			If acceptType = acceptMovies And coverBlock.licence.isSeries() Then Return False
			If acceptType = acceptSeries And coverBlock.licence.isSingle() Then Return False
		EndIf

		If Super.AddItem(item,extra)
			'print "added an item ... slot state:" + self.GetUnusedSlotAmount()+"/"+self.GetSlotAmount()
			Return True
		EndIf

		Return False
	End Method
End Type



'a graphical representation of programmes to buy/sell/archive...
Type TGUIProgrammeLicence Extends TGUIGameListItem
	Field licence:TProgrammeLicence


    Method Create:TGUIProgrammeLicence(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		Super.Create(pos, dimension, value)

		'override defaults - with the default genre identifier
		'(eg. "undefined" -> "gfx_movie_undefined")
		Self.assetNameDefault = "gfx_movie_"+TVTProgrammeGenre.GetAsString(-1)
		Self.assetNameDragged = "gfx_movie_"+TVTProgrammeGenre.GetAsString(-1)

		Return Self
	End Method


	Method CreateWithLicence:TGUIProgrammeLicence(licence:TProgrammeLicence)
		Self.Create()
		Self.setProgrammeLicence(licence)
		Return Self
	End Method


	Method SetProgrammeLicence:TGUIProgrammeLicence(licence:TProgrammeLicence)
		Self.licence = licence

		'get the string identifier of the genre (eg. "adventure" or "action")
		Local genreString:String = TVTProgrammeGenre.GetAsString(licence.GetGenre())
		Local assetName:String = ""

		'if it is a collection or series
		If licence.isCollection()
			assetName = "gfx_movie_" + genreString
		ElseIf licence.isSeries()
			assetName = "gfx_series_" + genreString
		Else
			assetName = "gfx_movie_" + genreString
		EndIf

		'use the name of the returned sprite - default or specific one
		assetName = GetSpriteFromRegistry(assetName, assetNameDefault).GetName()

		'check if "dragged" exists
		Local assetNameDragged:String = assetName+".dragged"
		If GetSpriteFromRegistry(assetNameDragged).GetName() <> assetNameDragged
			assetNameDragged = assetName
		EndIf
		
		Self.InitAssets(assetName, assetNameDragged)

		Return Self
	End Method


	'override to only allow dragging for affordable or own licences
	Method IsDragable:Int() 
		If Super.IsDragable()
			Return (licence.owner = GetPlayerCollection().playerID Or (licence.owner <= 0 And IsAffordable()))
		Else
			Return False
		EndIf
	End Method


	Method IsAffordable:Int()
		Return GetPlayer().getFinance().canAfford(licence.getPrice())
	End Method


	Method DrawSheet(leftX:Int=30, rightX:Int=30)
'		self.parentBlock.DrawSheet()
		Local sheetY:Float 	= 20
		Local sheetX:Float 	= leftX
		Local sheetAlign:Int= 0
		'if mouse on left side of screen - align sheet on right side
		If MouseManager.x < GetGraphicsManager().GetWidth()/2
			sheetX = GetGraphicsManager().GetWidth() - rightX
			sheetAlign = 1
		EndIf

		SetColor 0,0,0
		SetAlpha 0.2
		Local x:Float = Self.GetScreenX()
		Local tri:Float[]=[sheetX+20,sheetY+25,sheetX+20,sheetY+90,Self.GetScreenX()+Self.GetScreenWidth()/2.0+3,Self.GetScreenY()+Self.GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		Self.licence.ShowSheet(sheetX,sheetY, sheetAlign, TVTBroadcastMaterialType.PROGRAMME)
	End Method


	Method Draw()
		SetColor 255,255,255

		'make faded as soon as not "dragable" for us
		If licence.owner <> GetPlayerCollection().playerID And (licence.owner<=0 And Not IsAffordable()) Then SetAlpha 0.75
		Super.Draw()
		SetAlpha 1.0
	End Method
End Type






'a graphical representation of contracts at the ad-agency ...
Type TGuiAdContract Extends TGUIGameListItem
	Field contract:TAdContract


    Method Create:TGuiAdContract(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		Super.Create(pos, dimension, value)

		Self.assetNameDefault = "gfx_contracts_0"
		Self.assetNameDragged = "gfx_contracts_0_dragged"

		Return Self
	End Method


	Method CreateWithContract:TGuiAdContract(contract:TAdContract)
		Self.Create()
		Self.setContract(contract)
		Return Self
	End Method


	Method SetContract:TGuiAdContract(contract:TAdContract)
		Self.contract		= contract
		'targetgroup is between 0-9
		Self.InitAssets(GetAssetName(contract.GetLimitedToTargetGroup(), False), GetAssetName(contract.GetLimitedToTargetGroup(), True))

		Return Self
	End Method


	Method GetAssetName:String(targetGroup:Int=-1, dragged:Int=False)
		If targetGroup < 0 And contract Then targetGroup = contract.GetLimitedToTargetGroup()
		Local result:String = "gfx_contracts_" + Min(9,Max(0, targetGroup))
		If dragged Then result = result + "_dragged"
		Return result
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		'disable dragging if not signable
		If contract.owner <= 0
			If Not contract.IsAvailableToSign(GetPlayer().playerID)
				SetOption(GUI_OBJECT_DRAGABLE, False)
			Else
				SetOption(GUI_OBJECT_DRAGABLE, True)
			EndIf
		EndIf
			

		'set mouse to "hover"
		If contract.owner = GetPlayer().playerID Or contract.owner <= 0 And mouseover Then Game.cursorstate = 1
				
		
		'set mouse to "dragged"
		If isDragged() Then Game.cursorstate = 2
	End Method


	Method DrawSheet(leftX:Int=30, rightX:Int=30)
		Local sheetY:Float 	= 20
		Local sheetX:Float 	= leftX
		Local sheetAlign:Int= 0
		'if mouse on left side of screen - align sheet on right side
		'METHOD 1
		'instead of using the half screen width, we use another
		'value to remove "flipping" when hovering over the desk-list
		'if MouseManager.x < RoomHandler_AdAgency.suitcasePos.GetX()
		'METHOD 2
		'just use the half of a screen - ensures the data sheet does not overlap
		'the object
		If MouseManager.x < GetGraphicsManager().GetWidth()/2
			sheetX = GetGraphicsManager().GetWidth() - rightX
			sheetAlign = 1
		EndIf

		SetColor 0,0,0
		SetAlpha 0.2
		Local x:Float = Self.GetScreenX()
		Local tri:Float[]=[sheetX+20,sheetY+25,sheetX+20,sheetY+90,Self.GetScreenX()+Self.GetScreenWidth()/2.0+3,Self.GetScreenY()+Self.GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		Self.contract.ShowSheet(sheetX,sheetY, sheetAlign, TVTBroadcastMaterialType.ADVERTISEMENT)
	End Method


	Method Draw()
		SetColor 255,255,255
		Local oldCol:TColor = New TColor.Get()

		'make faded as soon as not "dragable" for us
		If Not isDragable()
			'in our collection
			If contract.owner = GetPlayerCollection().playerID
				SetAlpha 0.80*oldCol.a
				SetColor 200,200,200
			Else
				SetAlpha 0.70*oldCol.a
				SetColor 250,200,150
			EndIf
		EndIf

		Super.Draw()

		oldCol.SetRGBA()
	End Method
End Type




Type TGUIAdContractSlotList Extends TGUIGameSlotList

    Method Create:TGUIAdContractSlotList(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
		Super.Create(position, dimension, limitState)
		Return Self
	End Method


	Method ContainsContract:Int(contract:TAdContract)
		For Local i:Int = 0 To Self.GetSlotAmount()-1
			Local block:TGuiAdContract = TGuiAdContract( Self.GetItemBySlot(i) )
			If block And block.contract = contract Then Return True
		Next
		Return False
	End Method
End Type

