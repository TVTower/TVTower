SuperStrict
Import "Dig/base.util.graphicsmanager.bmx"
Import "common.misc.gamelist.bmx"
Import "game.production.productionconcept.bmx"
Import "game.player.base.bmx"
Import "game.game.base.bmx" 'to change game cursor


'a graphical representation of shopping lists in studios/supermarket
Type TGuiProductionConceptListItem Extends TGUIGameListItem
	Field productionConcept:TProductionConcept

    Method Create:TGuiProductionConceptListItem(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		Super.Create(pos, dimension, value)

		Self.assetNameDefault = "gfx_studio_productionConcept_0"
		Self.assetNameDragged = "gfx_studio_productionConcept_0"

		Return Self
	End Method


	Method CreateWithproductionConcept:TGuiProductionConceptListItem(productionConcept:TProductionConcept)
		Self.Create()
		Self.SeTProductionConcept(productionConcept)
		Return Self
	End Method


	Method SeTProductionConcept:TGuiProductionConceptListItem(productionConcept:TProductionConcept)
		Self.productionConcept = productionConcept
		Self.InitAssets(GetAssetName(productionConcept.script.GetMainGenre(), False), GetAssetName(productionConcept.script.GetMainGenre(), True))

		Return Self
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		'set mouse to "hover"
		If productionConcept.owner = GetPlayerBaseCollection().playerID Or productionConcept.owner <= 0 And isHovered()
			GetGameBase().cursorstate = 1
		EndIf
				
		'set mouse to "dragged"
		If isDragged()
			GetGameBase().cursorstate = 2
		EndIf
	End Method


	Method DrawSheet(leftX:Int=30, rightX:Int=30)
		Local sheetY:Float 	= 20
		Local sheetX:Float 	= leftX
		Local sheetAlign:Int= 0

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

		DrawRect(sheetX - sheetAlign*300, sheetY, 300, 100)
		'productionConcept.ShowSheet(sheetX, sheetY, sheetAlign)
	End Method


	Method DrawContent()
		SetColor 255,255,255
		Local oldCol:TColor = New TColor.Get()

		'make faded as soon as not "dragable" for us
		If Not isDragable()
			'in our collection
			If productionConcept.owner = GetPlayerBaseCollection().playerID
				SetAlpha 0.80*oldCol.a
				SetColor 200,200,200
			Else
				SetAlpha 0.70*oldCol.a
				SetColor 250,200,150
			EndIf
		EndIf

		Super.DrawContent()

		oldCol.SetRGBA()
	End Method
End Type




Type TGUIProductionConceptSlotList Extends TGUIGameSlotList
    Method Create:TGUIProductionConceptSlotList(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
		Super.Create(position, dimension, limitState)
		Return Self
	End Method


	Method ContainsproductionConcept:Int(productionConcept:TProductionConcept)
		For Local i:Int = 0 To Self.GetSlotAmount()-1
			Local block:TGuiProductionConceptListItem = TGuiProductionConceptListItem( Self.GetItemBySlot(i) )
			If block And block.productionConcept = productionConcept Then Return True
		Next
		Return False
	End Method
End Type
