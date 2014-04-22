SuperStrict
Import brl.Reflection
Import Brl.Retro
Import "base.util.input.bmx" 		'Mousemanager
Import "base.util.rectangle.bmx"	'TRectangle

'collection of useful functions
Type THelper
	'check whether a checkedObject equals to a limitObject
	'1) is the same object
	'2) is of the same type
	'3) is extended from same type
	Function ObjectsAreEqual:int(checkedObject:object, limit:object)
		'one of both is empty
		if not checkedObject then return FALSE
		if not limit then return FALSE
		'same object
		if checkedObject = limit then return TRUE

		'check if classname / type is the same (type-name given as limit )
		if string(limit)<>null
			local typeId:TTypeId = TTypeId.ForName(string(limit))
			'if we haven't got a valid classname
			if not typeId then return FALSE
			'if checked object is same type or does extend from that type
			if TTypeId.ForObject(checkedObject).ExtendsType(typeId) then return TRUE
		endif

		return FALSE
	End Function


	'returns whether the mouse is within the given rectangle coords
	Function MouseIn:int(x:float,y:float,w:float,h:float)
		return IsIn(MouseManager.x, MouseManager.y, x,y,w,h)
	End Function


	'returns whether the mouse is within the given rectangle
	Function MouseInRect:int(rect:TRectangle)
		return IsIn(MouseManager.x, MouseManager.y, rect.position.x,rect.position.y,rect.dimension.x, rect.dimension.y)
	End Function


	'returns whether two pairs of "start-end"-values intersect
	Function DoMeet:int(startA:float, endA:float, startB:float, endB:float)
		'DoMeet - 4 possibilities - but only 2 for not meeting
		' |--A--| .--B--.    or   .--B--. |--A--|
		return  not (Max(startA,endA) < Min(startB,endB) or Min(startA,endA) > Max(startB, endB) )
	End function


	'returns whether the given x,y coordinate is within the given rectangle coords
	Function IsIn:Int(x:Float, y:Float, rectx:Float, recty:Float, rectw:Float, recth:Float)
		If x >= rectx And x<=rectx+rectw And..
		   y >= recty And y<=recty+recth
			Return 1
		Else
			Return 0
		End If
	End Function


	'convert a float to a string
	'float is rounded to the requested amount of digits after comma
	Function floatToString:String(value:Float, digitsAfterDecimalPoint:int = 2)
		Local s:String = RoundNumber(value, digitsAfterDecimalPoint + 1)

		'calculate amount of digits before "."
		'instead of just string(int(s))).length we use the "Abs"-value
		'and compare the original value if it is negative
		'- this is needed because "-0.1" would be "0" as int (one char less)
		local lengthBeforeDecimalPoint:int = string(abs(int(s))).length
		if value < 0 then lengthBeforeDecimalPoint:+1 'minus sign
		'remove unneeded digits (length = BEFORE + . + AFTER)
		s = Left(s, lengthBeforeDecimalPoint + 1 + digitsAfterDecimalPoint)

		'add at as much zeros as requested by digitsAfterDecimalPoint
		If s.EndsWith(".")
			for local i:int = 0 until digitsAfterDecimalPoint
				s :+ "0"
			Next
		endif

		Return s
	End Function


	Function RoundInt:Int(f:Float)
		'http://www.blitzbasic.com/Community/posts.php?topic=92064
	    Return f + 0.5 * Sgn(f)
	End Function


	'round a number using weighted non-trucate rounding.
	Function roundNumber:Double(number:Double, digitsAfterDecimalPoint:Byte = 2)
		Local t:Long = 10 ^ digitsAfterDecimalPoint
		Return Long(number * t + 0.5:double * Sgn(number)) / Double(t)
	End Function
End Type