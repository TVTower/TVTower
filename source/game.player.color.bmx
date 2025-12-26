SuperStrict
Import "Dig/base.util.color.bmx"
Import Collections.ObjectList


Type TPlayerColor extends TColor
	'store if a player/object... uses that color
	Field ownerID:int = 0

	Global registeredColors:TObjectList = new TObjectList


	Function Create:TPlayerColor(r:int=0,g:int=0,b:int=0,a:float=1.0)
		local obj:TPlayerColor = new TPlayerColor
		obj.r = r
		obj.g = g
		obj.b = b
		obj.a = a
		obj.ownerID = 0
		return obj
	End Function


	'=== SERIALIZATION / DESERIALIZATION ===
	Method SerializeTPlayerColorToString:string()
		return r + "," +..
		       g + "," +..
		       b + "," +..
		       f2i(a) + "," +..
		       ownerID

		Function f2i:String(f:float)
			if float(int(f)) = f then return int(f)
			return string(f).replace(",",".")
		End Function
	End Method


	Method DeSerializeTPlayerColorFromString(text:String)
		local vars:string[] = text.split(",")
		if vars.length > 0 then r = int(vars[0])
		if vars.length > 1 then g = int(vars[1])
		if vars.length > 2 then b = int(vars[2])
		if vars.length > 3 then a = float(vars[3])
		if vars.length > 4 then ownerID = int(vars[4])
	End Method


	Function Initialize:Int()
		'mark all unowned
		For local pc:TPlayerColor = EachIn registeredColors
			pc.ownerID = 0
		Next
		'list.Clear()
	End Function
	

	Function IsRegisteredColor:Int(col:TPlayerColor)
		Return registeredColors.Contains(col)
	End Function
	

	Function RegisterColor:Int(col:TPlayerColor)
		If not IsRegisteredColor(col)
			registeredColors.AddLast(col)
			Return True
		EndIf
		Return False
	End Function


	Function UnregisterColor:Int(col:TPlayerColor)
		Return registeredColors.remove(col)
	End Function


	Function GetFromListByRGBA:TPlayerColor(r:Int, g:Int, b:Int, a:Float=1.0)
		For Local obj:TPlayerColor = EachIn registeredColors
			If obj.r = r And obj.g = g And obj.b = b And obj.a = a Then Return obj
		Next
		Return Null
	End Function


	Method Unregister:TPlayerColor()
		UnregisterColor(self)
		Return self
	End Method
	
	
	Method Register:TPlayerColor()
		RegisterColor(self)
		Return self
	End Method


	Method SetOwner:TPlayerColor(ownerID:int)
		self.ownerID = ownerID
		return self
	End Method


	Function GetByOwner:TPlayerColor(ownerID:int=0)
		For local obj:TPlayerColor = EachIn registeredColors
			if obj.ownerID = ownerID then return obj
		Next
		return Null
	End Function


	Function GetUnowned:TPlayerColor[](defaultColor:TPlayerColor = Null)
		local unowned:TPlayerColor[]
		For local c:TPlayerColor = EachIn registeredColors
			if c.ownerID = 0 then unowned :+ [c]
		Next
		if unowned.length = 0 and defaultColor then unowned :+ [defaultColor]
		return unowned
	End Function
End Type
