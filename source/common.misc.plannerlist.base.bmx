SuperStrict
Import "Dig/base.util.rectangle.bmx"
Import "game.gameobject.bmx"

Type TPlannerList extends TOwnedGameObject
	'0=enabled 1=openedgenres 2=openedmovies 3=openedepisodes = 1
	Field openState:Int = 0
	Field currentGenre:Int =-1
	Field enabled:Int = 0
	Field Pos:TVec2D = New TVec2D.Init()
	Field entriesRect:TRectangle
	Field entrySize:TVec2D = New TVec2D

	'whether the player can click / create elements? 
	Field clicksAllowed:int = True

	Method getOpen:Int()
		Return Self.openState And enabled
	End Method
End Type


