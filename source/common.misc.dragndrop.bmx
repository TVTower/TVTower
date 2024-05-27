SuperStrict
Import Brl.LinkedList
Import "Dig/base.util.vector.bmx"


Type TDragAndDrop
	Field pos:TVec2D = new TVec2D
	Field w:Int = 0
	Field h:Int = 0
	Field typ:String = ""
	Field slot:Int = 0
	Global List:TList = CreateList()

 	Function FindDragAndDropObject:TDragAndDrop(List:TList, _pos:TVec2D)
 	  For Local P:TDragAndDrop = EachIn List
		If P.pos.isSame(_pos) Then Return P
	  Next
	  Return Null
 	End Function


	Function Create:TDragAndDrop(x:Int, y:Int, w:Int, h:Int, _typ:String="")
		Local DragAndDrop:TDragAndDrop=New TDragAndDrop
		DragAndDrop.pos.SetXY(x,y)
		DragAndDrop.w = w
		DragAndDrop.h = h
		DragAndDrop.typ = _typ
		List.AddLast(DragAndDrop)
		SortList List
		Return DragAndDrop
	EndFunction

    Method IsIn:Int(x:Int, y:Int)
		return (x >= pos.x And x <= pos.x + w And y >= pos.y And y <= pos.y + h)
    End Method

    Method CanDrop:Int(x:Int, y:Int, _Typ:String="")
		return (IsIn(x,y) = 1 And typ=_Typ)
    End Method
End Type