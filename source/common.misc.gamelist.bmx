SuperStrict
Import "Dig/base.gfx.gui.list.selectlist.bmx"


Type TGUIGameList Extends TGUISelectList
    Method Create:TGUIGameList(pos:TVec2D=null, dimension:TVec2D=null, limitState:String = "")
		Super.Create(pos, dimension, limitState)

		Return Self
	End Method
End Type


'a graphical representation of multiple object ingame
Type TGUIGameListItem Extends TGUIListItem
	Field assetNameDefault:String = "gfx_movie_undefined"
	Field assetNameDragged:String = "gfx_movie_undefined"
	Field asset:TSprite = Null
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

		Self.SetAsset(Self.assetDefault)
	End Method


	Method SetAsset(sprite:TSprite=Null)
		If Not sprite Then sprite = Self.assetDefault

		'only resize if not done already
		If Self.asset <> sprite
			Self.asset = sprite
			Self.Resize(sprite.area.GetW(), sprite.area.GetH())
		EndIf
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		If isDragged() then SetAsset(assetDragged)
	End Method


	Method DrawGhost()
		'by default a shaded version of the gui element is drawn at the original position
		self.SetOption(GUI_OBJECT_IGNORE_POSITIONMODIFIERS, TRUE)
		SetAlpha 0.5

		local backupAssetName:string = self.asset.getName()
		self.asset = GetSpriteFromRegistry(assetNameDefault)
		self.Draw()
		self.asset = GetSpriteFromRegistry(backupAssetName)

		SetAlpha 1.0
		self.SetOption(GUI_OBJECT_IGNORE_POSITIONMODIFIERS, FALSE)
	End Method


	Method DrawContent()
		asset.draw(Self.GetScreenX(), Self.GetScreenY())
		'hovered
		If Self.mouseover
			Local oldAlpha:Float = GetAlpha()
			SetAlpha 0.20*oldAlpha
			SetBlend LightBlend
			asset.draw(Self.GetScreenX(), Self.GetScreenY())
			SetBlend AlphaBlend
			SetAlpha oldAlpha
		EndIf
	End Method
End Type
