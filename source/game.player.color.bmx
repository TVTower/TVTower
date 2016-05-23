SuperStrict
Import "Dig/base.util.color.bmx"

Type TPlayerColor extends TColor
	'store if a player/object... uses that color
	Field ownerID:int = 0


	Function Create:TPlayerColor(r:int=0,g:int=0,b:int=0,a:float=1.0)
		local obj:TPlayerColor = new TPlayerColor
		obj.r = r
		obj.g = g
		obj.b = b
		obj.a = a
		obj.ownerID = 0
		return obj
	End Function
	

	Function Initialize:Int()
		For local pc:TPlayerColor = EachIn list
			pc.ownerID = 0
		Next
		list.Clear()
	End Function


	Method RemoveFromList:TPlayerColor()
		list.remove(self)
		return self
	End Method
	

	Method AddToList:TPlayerColor()
		Super.AddToList()
		return self
	End Method
	

	Method SetOwner:TPlayerColor(ownerID:int)
		self.ownerID = ownerID
		return self
	End Method


	Function getByOwner:TPlayerColor(ownerID:int=0)
		For local obj:TPlayerColor = EachIn List
			if obj.ownerID = ownerID then return obj
		Next
		return Null
	End Function


	Function getUnowned:TPlayerColor[](defaultColor:TPlayerColor)
		local unowned:TPlayerColor[]
		For local c:TPlayerColor = EachIn List
			if c.ownerID = 0 then unowned :+ [c]
		Next
		if unowned.length = 0 then unowned :+ [defaultColor]
		return unowned
	End Function
End Type