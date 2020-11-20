SuperStrict
Import "Dig/base.util.graphicsmanagerbase.bmx"
Import "common.misc.gamegui.bmx"
Import "game.production.script.bmx"
Import "game.player.base.bmx"
Import "game.game.base.bmx" 'to change game cursor


'a graphical representation of scripts at the script-agency ...
Type TGuiScript Extends TGUIGameListItem
	Field script:TScript
	Field studioMode:Int = 0


	Method New()
		SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, False)
	End Method


    Method Create:TGUIScript(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		Super.Create(pos, dimension, value)

		Self.assetNameDefault = "gfx_scripts_0"
		Self.assetNameDragged = "gfx_scripts_0_dragged"

		Return Self
	End Method


	Method CreateWithScript:TGuiScript(script:TScript)
		Self.Create()
		Self.setScript(script)
		Return Self
	End Method


	Method SetScript:TGuiScript(script:TScript)
		Self.script = script
		Self.InitAssets(GetAssetName(script.GetMainGenre(), False), GetAssetName(script.GetMainGenre(), True))

		Return Self
	End Method


	Method GetAssetName:String(genre:Int=-1, dragged:Int=False)
		If genre < 0 And script Then genre = script.GetMainGenre()
		Local result:String = "gfx_scripts_" + genre Mod 3 'only 3 sprites possible
		If dragged Then result = result + "_dragged"

		If studioMode And Not dragged Then result = "gfx_scripts_0_studiodesk"

		Return result
	End Method


	'override default update-method
	Method Update:Int()
		Super.Update()

		'set mouse to "hover"
		If isHovered() and (script.owner = GetPlayerBaseCollection().playerID Or script.owner <= 0)
			GetGameBase().cursorstate = TGameBase.CURSOR_PICK_VERTICAL
		EndIf

		'set mouse to "dragged"
		If isDragged()
			GetGameBase().cursorstate = TGameBase.CURSOR_HOLD
		EndIf
	End Method


	Method DrawSheet(leftX:Int=30, rightX:Int=30)
		Local sheetY:Int 	= 20
		Local sheetX:Int 	= leftX
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
		Local x:Float = GetScreenRect().GetX()
		Local tri:Float[]=[float(sheetX + (sheetAlign=0)*20 - (sheetAlign=1)*30),float(sheetY+25),float(sheetX + (sheetAlign=0)*20 - (sheetAlign=1)*30),float(sheetY+90),GetScreenRect().GetXCenter()+3, GetScreenRect().GetYCenter()]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		Self.script.ShowSheet(sheetX, sheetY, sheetAlign)
	End Method



	Method Draw()
		SetColor 255,255,255
		Local oldCol:TColor = New TColor.Get()

		'make faded as soon as not "dragable" for us
		If Not isDragable()
			'in our collection
			If script.owner = GetPlayerBaseCollection().playerID
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




Type TGUIScriptSlotList Extends TGUIGameSlotList
    Method Create:TGUIScriptSlotList(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
		Super.Create(position, dimension, limitState)
		Return Self
	End Method


	Method ContainsScript:Int(script:TScript)
		For Local i:Int = 0 To Self.GetSlotAmount()-1
			Local block:TGuiScript = TGuiScript( Self.GetItemBySlot(i) )
			If block And block.script = script Then Return True
		Next
		Return False
	End Method
Rem
	'override children sort
	Method SortChildren() override
		If _children Then _children.sort(True, SortObjectsBySlot)
		If _childrenReversed Then _childrenReversed.sort(False, SortObjectsBySlot)
	End Method
	
	
	Function SortObjectsBySlot:Int(obj1:Object, obj2:Object)
		local guiScript1:TGuiScript = TGuiScript(obj1)
		local guiScript2:TGuiScript = TGuiScript(obj2)

		if guiScript1 and not guiScript2 
			return 1
		Elseif not guiScript1 and guiScript2 
			return -1
		ElseIf not guiScript1 and not guiScript2
			return 0
		EndIf
	
		'when both scripts are in the same list, we sort by their slot position
		if guiScript1.parentListID >= 0 and guiScript1.parentListID = guiScript2.parentListID
			If guiScript1.parentListPosition > guiScript2.parentListPosition
				Return 1
			Elseif guiScript1.parentListPosition < guiScript2.parentListPosition 
				Return -1
			EndIf
		endif
		
		'fall back to default sort
		Return TGUIManager.SortObjects(obj1, obj2)
	End Function
End Rem
End Type
