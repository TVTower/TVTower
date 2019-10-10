SuperStrict
Import "Dig/base.util.rectangle.bmx"
Import "Dig/base.util.helper.bmx"
Import "game.gameobject.bmx"


Type TBlockMoveable Extends TOwnedGameObject
	Field rect:TRectangle = new TRectangle.Init(0,0,0,0)
	Field dragable:Int = 1
	Field dragged:Int = 0
	Field OrigPos:TVec2D = new TVec2D
	Field StartPos:TVec2D = new TVec2D
	Field StartPosBackup:TVec2D = new TVec2D


	'switches coords and state of blocks
	Method SwitchBlock(otherObj:TBlockMoveable)
		Self.SwitchCoords(otherObj)
		Local old:Int	= Self.dragged
		Self.dragged	= otherObj.dragged
		otherObj.dragged= old
	End Method


	'switches current and startcoords of two blocks
	Method SwitchCoords(otherObj:TBlockMoveable)
		TVec2D.SwitchVecs(rect.position, otherObj.rect.position)
		TVec2D.SwitchVecs(StartPos, otherObj.StartPos)
		TVec2D.SwitchVecs(StartPosBackup, otherObj.StartPosBackup)
	End Method


	'checks if x, y are within startPoint+dimension
	Method containsCoord:Int(x:Float, y:Float)
		Return THelper.IsIn( int(x), int(y), int(Self.StartPos.getX()), int(Self.StartPos.getY()), int(Self.rect.getW()), int(Self.rect.getH()) )
	End Method


	Method SetCoords(x:Int=Null, y:Int=Null, startx:Int=Null, starty:Int=Null)
      If x<>Null 		Then Self.rect.position.SetX(x)
      If y<>Null		Then Self.rect.position.SetY(y)
      If startx<>Null	Then Self.StartPos.setX(startx)
      If starty<>Null	Then Self.StartPos.SetY(starty)
	End Method


	Method SetBasePos(pos:TVec2D = Null)
		If pos <> Null
			rect.position.CopyFrom(pos)
			StartPos.CopyFrom(pos)
		EndIf
	End Method


	Method IsAtStartPos:Int()
		Return rect.position.isSame(StartPos, True)
	End Method


	Function SortDragged:Int(o1:Object, o2:Object)
		Local s1:TBlockMoveable = TBlockMoveable(o1)
		Local s2:TBlockMoveable = TBlockMoveable(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
		Return (s1.dragged * 100)-(s2.dragged * 100)
	End Function
End Type