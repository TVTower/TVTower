SuperStrict
Import BRL.Max2d 'to debug draw the sprite atlas
Import BRL.Map
Import "base.util.rectangle.bmx"
Import "base.util.srectangle.bmx"


'TEST
Rem
Graphics 800, 600
local sa:TSpriteAtlas = new TSpriteAtlas(128,128, 20)
For local i:int = 32 until 133
	sa.AddElement(i, 9, 17)
Next
Repeat
	sa.Draw()
	Flip 0
until KeyHit(KEY_ESCAPE) or AppTerminate()
print "done."
endrem

Struct SSpriteAtlasRect
	Field id:Int 'eg. charCode
	Field rect:SRectI
	
	Method New(id:Int, x:Int, y:Int, w:Int, h:Int)
		Self.id = id
		Self.rect = New SRectI(x,y,w,h)
	End Method
End Struct




Type TSpriteAtlas
	Field elements:SSpriteAtlasRect[]
	Field elementsIndex:Int
	Field w:Int, h:Int
	Field packer:TSpritePacker = New TSpritePacker


	Method New(w:Int, h:Int, initialElementCount:Int = 50)
		Self.w = w
		Self.h = h
		Self.packer.setRect(0,0,w,h)
		
		Self.elements = New SSpriteAtlasRect[initialElementCount]
	End Method


	Method AddElement(id:Int, w:Int, h:Int)
		'ignore elements with w=0 or h=0?
		If w=0 Or h=0 Then Throw "TSpriteAtlas: Cannot AddElement() with zero width or height."

		If (elementsIndex+1) >= elements.length 
			elements = elements[.. (elementsIndex+1) * 3 / 2 + 1]
		EndIf

		Local freeArea:TSpritePacker = Null

		While freeArea = Null
			freeArea = packer.pack(w,h)
			If Not freeArea
				IncreaseSize()
				Repack()
			EndIf
		Wend
		
		elements[elementsIndex] = New SSpriteAtlasRect(id, freeArea.x, freeArea.y, w, h)
		elementsIndex :+ 1
	End Method


	Method Repack()
		'keep old elements ... and try to add them back to a new atlas

		Local previousElements:SSpriteAtlasRect[] = elements
		elements = New SSpriteAtlasRect[elements.length]
		elementsIndex = 0
		
		packer = New TSpritePacker
		packer.setRect(0, 0, w, h)

		For Local atlasRect:SSpriteAtlasRect = EachIn previousElements
			If atlasRect.id <> 0
				AddElement(atlasRect.id, atlasRect.rect.w, atlasRect.rect.h)
			EndIf
		Next
	End Method


	Method Draw(x:Int=0, y:Int=0)
		SetColor 255,100,100
		DrawRect(x, y, w, h)
		SetColor 50,100,200

		For Local i:Int = 0 Until elementsIndex
			Local atlasRect:SSpriteAtlasRect = elements[i]
			DrawRect(atlasRect.rect.x + 1, atlasRect.rect.y + 1, atlasRect.rect.w - 2, atlasRect.rect.h - 2)
		Next
	End Method


	Method IncreaseSize(w:Int = 0, h:Int = 0)
		If w = 0 And h = 0
			If Self.h < Self.w 
				Self.h = nextPow2(Self.h)
			Else
				Self.w = nextPow2(Self.w)
			EndIf
		Else
			If w <> 0 Then Self.w = w
			If h <> 0 Then Self.h = h
		EndIf
		packer.SetRect(0, 0, Self.w, Self.h)
	End Method


	Function nextPow2:Int(currentValue:Int=0)
		Local newValue:Int = 1
		While newValue <= currentValue
			newValue :* 2
		Wend
		'print "nextPow2: got:"+currentValue + " new:"+newValue
		Return newValue
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

			If occupied Or width > w Or height > h Then Return Null

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
			If newNode <> Null Then Return newNode

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