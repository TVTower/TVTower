'SuperStrict
'Import "common.misc.gamelist.bmx"
'Import "game.production.script.bmx"
'Import "game.player.base.bmx"



'a graphical representation of scripts at the script-agency ...
Type TGuiScript extends TGUIGameListItem
	Field script:TScript
	Field studioMode:int = 0

    Method Create:TGUIScript(pos:TVec2D=null, dimension:TVec2D=null, value:String="")
		Super.Create(pos, dimension, value)

		self.assetNameDefault = "gfx_scripts_0"
		self.assetNameDragged = "gfx_scripts_0_dragged"

		return self
	End Method


	Method CreateWithScript:TGuiScript(script:TScript)
		self.Create()
		self.setScript(script)
		return self
	End Method


	Method SetScript:TGuiScript(script:TScript)
		self.script = script
		self.InitAssets(GetAssetName(script.GetGenre(), FALSE), GetAssetName(script.GetGenre(), TRUE))

		return self
	End Method


	Method GetAssetName:string(genre:int=-1, dragged:int=FALSE)
		if genre < 0 and script then genre = script.GetGenre()
		local result:string = "gfx_scripts_" + genre mod 3 'only 3 sprites possible
		if dragged then result = result + "_dragged"

		if studioMode and not dragged then result = "gfx_scripts_0_studiodesk"

		return result
	End Method


	'override default update-method
	Method Update:int()
		super.Update()

		'set mouse to "hover"
		if script.owner = GetPlayerBaseCollection().playerID or script.owner <= 0 and mouseover then Game.cursorstate = 1
				
		'set mouse to "dragged"
		if isDragged() then Game.cursorstate = 2
	End Method


	Method DrawSheet(leftX:int=30, rightX:int=30)
		local sheetY:float 	= 20
		local sheetX:float 	= leftX
		local sheetAlign:int= 0
		'if mouse on left side of screen - align sheet on right side
		'METHOD 1
		'instead of using the half screen width, we use another
		'value to remove "flipping" when hovering over the desk-list
		'if MouseManager.x < RoomHandler_AdAgency.suitcasePos.GetX()
		'METHOD 2
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

		self.script.ShowSheet(sheetX, sheetY, sheetAlign)
	End Method



	Method Draw:Int()
		SetColor 255,255,255
		local oldCol:TColor = new TColor.Get()

		'make faded as soon as not "dragable" for us
		if not isDragable()
			'in our collection
			if script.owner = GetPlayerCollection().playerID
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




Type TGUIScriptSlotList extends TGUIGameSlotList
    Method Create:TGUIScriptSlotList(position:TVec2D = null, dimension:TVec2D = null, limitState:String = "")
		Super.Create(position, dimension, limitState)
		return self
	End Method


	Method ContainsScript:int(script:TScript)
		for local i:int = 0 to self.GetSlotAmount()-1
			local block:TGuiScript = TGuiScript( self.GetItemBySlot(i) )
			if block and block.script = script then return TRUE
		Next
		return FALSE
	End Method
End Type
