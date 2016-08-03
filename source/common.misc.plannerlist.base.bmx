SuperStrict
Import "Dig/base.util.rectangle.bmx"
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

	'whether the player can click / create elements? 
	Field clicksAllowed:int = True


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


	Method UpdateSortButtons()
		local buttonX:int = GetEntriesRect().GetX() + 2
		local buttonY:int = GetEntriesRect().GetY() + 4
		local buttonWidth:int = 32
		local buttonPadding:int = 2

		if THelper.MouseIn(buttonX + 5, buttonY, sortKeys.length * (buttonWidth + buttonPadding), 27)
			if MouseManager.isShortClicked(1)
				For local i:int = 0 until sortKeys.length
					If THelper.MouseIn(buttonX + i * (buttonWidth + buttonPadding), buttonY, 35, 27)
						'sort now
						if ListSortMode <> sortKeys[i]
							ListSortMode = sortKeys[i]
						else
							ListSortDirection = 1 - ListSortDirection
						endif
					endif
				Next
			endif
		endif
	End Method

End Type


