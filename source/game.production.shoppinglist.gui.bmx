'a graphical representation of shopping lists in studios/supermarket
Type TGuiShoppingList extends TGUIGameListItem
	Field shoppingList:TShoppingList


    Method Create:TGuiShoppingList(pos:TVec2D=null, dimension:TVec2D=null, value:String="")
		Super.Create(pos, dimension, value)

		self.assetNameDefault = "gfx_studio_shoppinglist_0"
		self.assetNameDragged = "gfx_studio_shoppinglist_0"

		return self
	End Method


	Method CreateWithShoppingList:TGuiShoppingList(shoppingList:TShoppingList)
		self.Create()
		self.SetShoppingList(shoppingList)
		return self
	End Method


	Method SetShoppingList:TGuiShoppingList(shoppingList:TShoppingList)
		self.shoppingList = shoppingList
		self.InitAssets(GetAssetName(shoppingList.script.GetGenre(), FALSE), GetAssetName(shoppingList.script.GetGenre(), TRUE))

		return self
	End Method


	'override default update-method
	Method Update:int()
		super.Update()

		'set mouse to "hover"
		if shoppingList.owner = GetPlayerCollection().playerID or shoppingList.owner <= 0 and mouseover then Game.cursorstate = 1
				
		'set mouse to "dragged"
		if isDragged() then Game.cursorstate = 2
	End Method


	Method DrawSheet(leftX:int=30, rightX:int=30)
		local sheetY:float 	= 20
		local sheetX:float 	= leftX
		local sheetAlign:int= 0

		'just use the half of a screen - ensures the data sheet does not overlap
		'the object
		if MouseManager.x < GetGraphicsManager().GetWidth()/2
			sheetX = GetGraphicsManager().GetWidth() - rightX
			sheetAlign = 1
		endif

		SetColor 0,0,0
		SetAlpha 0.2
		Local x:Float = self.GetScreenX()
		Local tri:Float[]=[sheetX+20,sheetY+25,sheetX+20,sheetY+90,self.GetScreenX()+self.GetScreenWidth()/2.0+3,self.GetScreenY()+self.GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		DrawRect(sheetX - sheetAlign*300, sheetY, 300, 100)
		'shoppingList.ShowSheet(sheetX, sheetY, sheetAlign)
	End Method



	Method Draw:Int()
		SetColor 255,255,255
		local oldCol:TColor = new TColor.Get()

		'make faded as soon as not "dragable" for us
		if not isDragable()
			'in our collection
			if shoppingList.owner = GetPlayerCollection().playerID
				SetAlpha 0.80*oldCol.a
				SetColor 200,200,200
			else
				SetAlpha 0.70*oldCol.a
				SetColor 250,200,150
			endif
		endif

		Super.Draw()

		oldCol.SetRGBA()
	End Method
End Type




Type TGUIShoppingListSlotList extends TGUIGameSlotList
    Method Create:TGUIShoppingListSlotList(position:TVec2D = null, dimension:TVec2D = null, limitState:String = "")
		Super.Create(position, dimension, limitState)
		return self
	End Method


	Method ContainsShoppingList:int(shoppingList:TShoppingList)
		for local i:int = 0 to self.GetSlotAmount()-1
			local block:TGuiShoppingList = TGuiShoppingList( self.GetItemBySlot(i) )
			if block and block.shoppingList = shoppingList then return TRUE
		Next
		return FALSE
	End Method
End Type
