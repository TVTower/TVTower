SuperStrict
Import "Dig/base.gfx.gui.list.selectlist.bmx"
Import "Dig/base.gfx.gui.list.slotlist.bmx"

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
		asset.draw(Self.GetScreenX(), Self.GetScreenY())
		'hovered
		If isHovered() and not isDragged()
			Local oldAlpha:Float = GetAlpha()
			SetAlpha 0.20*oldAlpha
			SetBlend LightBlend
			GetAsset().draw(Self.GetScreenX(), Self.GetScreenY())
			SetBlend AlphaBlend
			SetAlpha oldAlpha
		EndIf
	End Method
End Type
