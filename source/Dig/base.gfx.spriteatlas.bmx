SuperStrict
Import BRL.Max2d 'to debug draw the sprite atlas
Import BRL.Map
Import "base.util.rectangle.bmx"

Type TSpriteAtlas
	field elements:TMap = CreateMap()
	field w:int, h:int
	field packer:TSpritePacker = New TSpritePacker


	Function Create:TSpriteAtlas(w:int, h:int)
		local obj:TSpriteAtlas = new TSpriteAtlas
		obj.w = w
		obj.h = h
		obj.packer.setRect(0,0,w,h)
		return obj
	End Function


	Method AddElement(name:string, w:int, h:int)
		Local freeArea:TSpritePacker = null

		while freeArea = null
			freeArea = packer.pack(w,h)
			if not freeArea
				IncreaseSize()
				Repack()
			endif
		Wend
		elements.Insert(name, new TRectangle.Init(freeArea.x, freeArea.y, w, h))
	End Method


	Method Repack()
		local newElements:TMap = CopyMap(elements)
		packer = new TSpritePacker
		packer.setRect(0, 0, w, h)

		ClearMap(elements)

		for local name:string = eachin newElements.Keys()
			local rect:TRectangle = TRectangle(newElements.ValueForKey(name))
			AddElement(name, int(rect.GetW()), int(rect.GetH()))
		next
	End Method


	Method Draw(x:int=0, y:int=0)
		setColor 255,100,100
		DrawRect(x, y, w, h)
		setColor 50,100,200
		For local rect:TRectangle = eachin elements.Values()
			DrawRect(rect.GetX()+1, rect.GetY()+1, rect.GetW()-2, rect.GetH()-2)
		Next
	End Method


	Method IncreaseSize(w:int = 0, h:int = 0)
		if w = 0 AND h = 0
			if self.h < self.w then self.h = nextPow2(self.h) else self.w = nextPow2(self.w)
		else
			if w<>0 then self.w = w
			if h<>0 then self.h = h
		endif
		packer.setRect(0, 0, self.w, self.h)
	End Method


	Function nextPow2:int(currentValue:int=0)
		local newValue:int = 1
		while newValue <= currentValue
			newValue :* 2
		wend
		'print "nextPow2: got:"+currentValue + " new:"+newValue
		return newValue
	End Function
End Type




Type TSpritePacker
	Field childNode1:TSpritePacker
	Field childNode2:TSpritePacker

	Field x:Int,y:Int,w:Int,h:Int
	Field occupied:Int = False


	Method toString:String()
		Return "rect : "+x+" "+y+" "+w+" "+h
	End Method


	Method setRect(x:Int,y:Int,w:Int,h:Int)
		Self.x = x
		Self.y = y
		Self.w = w
		Self.h = h
	End Method


	' recursively split area until it fits the desired size
	Method pack:TSpritePacker(width:Int,height:Int)

		 'If we are a leaf node
		If (childNode1 = Null And childNode2 = Null)

			If occupied Or width > w Or height > h then Return Null

			If width = w And height = h
				occupied = True
				Return Self
			Else
				splitArea(width,height)
				Return childNode1.pack(width,height)
			EndIf

		Else
			' Try inserting into first child
			Local newNode:TSpritePacker = childNode1.pack(width,height)
			If newNode <> Null then Return newNode

			'no room, insert into second
			Return childNode2.pack(width,height)
		EndIf
	End Method


	Method splitArea(width:Int,height:Int)
		childNode1 = New TSpritePacker
        childNode2 = New TSpritePacker

        ' decide which way to split
        Local dw:Int = w - width
        Local dh:Int = h - height

        ' split vertically
        If dw > dh
            childNode1.setRect(x,y,width,h)
            childNode2.setRect(x+width,y,dw,h)
		Else ' split horizontally
            childNode1.setRect(x,y,w,height)
            childNode2.setRect(x,y+height,w,dh)
		EndIf

	End Method

End Type