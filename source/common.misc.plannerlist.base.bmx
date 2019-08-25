SuperStrict
Import "Dig/base.gfx.gui.bmx"
'Import "Dig/base.util.rectangle.bmx"
Import "basefunctions.bmx"
Import "game.gameobject.bmx"

Type TPlannerList extends TOwnedGameObject
	'0=enabled 1=openedgenres 2=openedmovies 3=openedepisodes = 1
	Field openState:Int = 0
	Field currentGenre:Int =-1
	Field enabled:Int = 0
	Field Pos:TVec2D = New TVec2D.Init()
	Field entriesRect:TRectangle
	Field entrySize:TVec2D = New TVec2D

	Field ListSortMode:int = 0
	'ATTENTION: for now the "visibility state" is not saved in savegames
	'           as we assume to have sortbuttons for all players
	Field ListSortVisible:int = True
	Field ListSortDirection:int = 0
	Field sortSymbols:string[]
	Field sortKeys:int[]
	Field sortTooltips:TTooltipBase[]

	'whether the player can click / create elements?
	Field clicksAllowed:int = True

	Method GenerateGUID:string()
		return "plannerlist-"+id
	End Method


	Method Initialize:int()
		ListSortDirection = 0
		ListSortMode = 0
		ListSortVisible = True
	End Method


	Method getOpen:Int()
		Return Self.openState And enabled
	End Method


	Method GetEntriesRect:TRectangle()
		return entriesRect
	End Method


	Method GetEntrySize:TVec2D()
		return entrySize
	End Method


	Method Delete()
		UnRegisterEvents()
	End Method


	Method UnRegisterEvents:Int() abstract


	Method UpdateSortArea(x:int, y:int)
		local buttonX:int = x + 2
		local buttonY:int = y + 4
		local buttonWidth:int = 32
		local buttonPadding:int = 2

		if THelper.MouseIn(buttonX + 5, buttonY, sortKeys.length * (buttonWidth + buttonPadding), 27)
			if MouseManager.IsClicked(1)
				For local i:int = 0 until sortKeys.length
					If THelper.MouseIn(buttonX + i * (buttonWidth + buttonPadding), buttonY, 35, 27)
						'sort now
						if ListSortMode <> sortKeys[i]
							ListSortMode = sortKeys[i]
						else
							ListSortDirection = 1 - ListSortDirection
						endif

						'handled left click
						MouseManager.ResetClicked(1)
						exit
					endif
				Next
			endif
		endif


		if sortTooltips
			'move tooltip hotspots to their positions and then update
			For local i:int = 0 until sortTooltips.length
				if not sortTooltips[i].parentArea then sortTooltips[i].parentArea = new TRectangle
				sortTooltips[i].parentArea.Init(buttonX + i * (buttonWidth + buttonPadding), buttonY, 35, 27)

				sortTooltips[i].Update()
			Next
		endif
	End Method



	Method DrawSortArea(x:int, y:int)
		local buttonX:int = x + 2
		local buttonY:int = y + 4
		local buttonWidth:int = 32
		local buttonPadding:int = 2

		For local i:int = 0 until sortKeys.length
			local spriteName:string = "gfx_gui_button.datasheet"
			if ListSortMode = sortKeys[i]
				spriteName = "gfx_gui_button.datasheet.positive"
			endif

			if THelper.MouseIn(buttonX + 5 + i*(buttonWidth + buttonPadding), buttonY, buttonWidth, 27)
				spriteName :+ ".hover"
			endif
			GetSpriteFromRegistry(spriteName).DrawArea(buttonX + 5 + i*(buttonWidth + buttonPadding), buttonY, buttonWidth,27)
			GetSpriteFromRegistry(sortSymbols[ sortKeys[i] ]).Draw(buttonX + 9 + i*(buttonWidth + buttonPadding), buttonY+2)
			'sort
			if ListSortMode = sortKeys[i]
				if ListSortDirection = 0
					GetSpriteFromRegistry("gfx_datasheet_icon_arrow_down").Draw(buttonX + 10 + i*(buttonWidth + buttonPadding), buttonY+2)
				else
					GetSpriteFromRegistry("gfx_datasheet_icon_arrow_up").Draw(buttonX + 10 + i*(buttonWidth + buttonPadding), buttonY+2)
				endif
			endif
		Next


		if sortTooltips
			'move tooltip hotspots to their positions and then update
			For local i:int = 0 until sortTooltips.length
				sortTooltips[i].Render()
			Next
		endif
	End Method

End Type


