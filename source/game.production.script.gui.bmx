SuperStrict
Import "Dig/base.util.graphicsmanagerbase.bmx"
Import "common.misc.gamegui.bmx"
Import "game.production.script.bmx"
Import "game.player.base.bmx"
Import "game.game.base.bmx" 'to change game cursor


'a graphical representation of scripts at the script-agency ...
Type TGuiScript Extends TGUIGameListItem
	Field script:TScript


	Method New()
		SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, False)
	End Method


    Method Create:TGUIScript(pos:SVec2I, dimension:SVec2I, value:String="")
		Super.Create(pos, dimension, value)

		Self.assetNameDefault = "gfx_scripts_0"
		Self.assetNameDragged = "gfx_scripts_0_dragged"

		Return Self
	End Method


	Method CreateWithScript:TGuiScript(script:TScript)
		Self.Create(New SVec2I(0,0), New SVec2I(0,0))
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

		Return result
	End Method


	Method IsAffordable:Int()
		Return GetPlayerBase().GetFinance().CanAfford(script.GetPrice())
	End Method


	Method DrawSheet(leftX:Int=30, rightX:Int=30, sheetAlign:Int = 0)
		Local sheetY:Int = 20
		Local sheetX:Int = leftX
		Local sheetWidth:Int = 310
		Select sheetAlign
			'align to left x
			case -1	 sheetX = leftX
			'use left X as center
			case  0  sheetX = leftX
			'align to right if required
			case  1  sheetX = GetGraphicsManager().GetWidth() - rightX
			'automatic - left or right
			default
				If MouseManager.x < GetGraphicsManager().GetWidth()/2
					sheetX = GetGraphicsManager().GetWidth() - rightX
					sheetAlign = 1
				Else
					sheetX = leftX
					sheetAlign = -1
				EndIf
		EndSelect
		

		Local baseX:Float
		Select sheetAlign
			case 0	baseX = sheetX
			case 1  baseX = sheetX - sheetWidth/2
			default baseX = sheetX + sheetWidth/2 
		End Select

		local oldA:Float = GetAlpha()
		local oldCol:SColor8
		GetColor(oldCol)
		SetColor 0,0,0
		SetAlpha 0.2 * oldA
		Local scrRect:TRectangle = Self.GetScreenRect()
		TFunctions.DrawBaseTargetRect(baseX, ..
		                              sheetY + 70, ..
		                              scrRect.x + scrRect.w/2.0, ..
		                              scrRect.y + scrRect.h/2.0, ..
		                              20, 3)
		SetColor(oldCol)
		SetAlpha oldA

		Self.script.ShowSheet(sheetX, sheetY, sheetAlign, GetStudioRoomSize())
	End Method
	
	
	Method GetStudioRoomSize:Int()
		Return -1
	End Method
	
	
	Method Draw() override
		Local oldCol:SColor8
		Local oldA:Float = GetAlpha()
		GetColor(oldCol)

		'make faded as soon as not "dragable" for us
		local markFaded:int = not IsDragable()

		if markFaded then SetAlpha oldA * 0.75

		Super.Draw()

		SetColor(oldCol)
		SetAlpha oldA
	End Method
End Type




Type TGUIScriptSlotList Extends TGUIGameSlotList
    Method Create:TGUIScriptSlotList(position:SVec2I, dimension:SVec2I, limitState:String = "")
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
