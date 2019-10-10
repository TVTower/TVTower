Rem
	====================================================================
	Classes for Sprites and Spritecontainers
	====================================================================

	This class provides TSpritePack and TSprite, which are alternatives
	to TImage as they use the principle of SpriteAtlases which decrease
	the amount of drawcalls if sprites from the same base image
	(spritepack) are drawn after another.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2014 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
EndRem
SuperStrict

Import BRL.Max2D
Import BRL.Random
Import "base.util.event.bmx"
Import "base.util.vector.bmx"
Import "base.gfx.imagehelper.bmx"
Import "base.util.graphicsmanagerbase.bmx"


Const ALIGN_LEFT:Float = 0
Const ALIGN_CENTER:Float = 0.5
Const ALIGN_RIGHT:Float = 1.0
Const ALIGN_TOP:Float = 0
Const ALIGN_BOTTOM:Float = 1.0

Global ALIGN_LEFT_TOP:TVec2D = New TVec2D
Global ALIGN_CENTER_TOP:TVec2D = New TVec2D.Init(ALIGN_CENTER, ALIGN_TOP)
Global ALIGN_RIGHT_TOP:TVec2D = New TVec2D.Init(ALIGN_RIGHT, ALIGN_TOP)

Global ALIGN_LEFT_CENTER:TVec2D = New TVec2D.Init(ALIGN_LEFT, ALIGN_CENTER)
Global ALIGN_CENTER_CENTER:TVec2D = New TVec2D.Init(ALIGN_CENTER, ALIGN_CENTER)
Global ALIGN_RIGHT_CENTER:TVec2D = New TVec2D.Init(ALIGN_RIGHT, ALIGN_CENTER)

Global ALIGN_LEFT_BOTTOM:TVec2D = New TVec2D.Init(ALIGN_LEFT, ALIGN_BOTTOM)
Global ALIGN_CENTER_BOTTOM:TVec2D = New TVec2D.Init(ALIGN_CENTER, ALIGN_BOTTOM)
Global ALIGN_RIGHT_BOTTOM:TVec2D = New TVec2D.Init(ALIGN_RIGHT, ALIGN_BOTTOM)



Type TSpritePack
	Field image:TImage {nosave}
	Field name:String
	Field sprites:TSprite[]


	Method Init:TSpritePack(image:TImage, name:String)
		Self.image = image
		Self.name = name
		Return Self
	End Method


	Method GetImage:TImage()
		Return image
	End Method


	'returns the sprite defined by "spriteName"
	'if no sprite was found, the first in the pack is returned to avoid errors
	Method GetSprite:TSprite(spriteName:String = "")
		spriteName = Lower(spriteName)
		For Local i:Int = 0 Until sprites.length
			'skip missing or with wrong names
			If Not sprites[i] Or Lower(sprites[i].name) <> spriteName Then Continue

			Return sprites[i]
		Next
		Return sprites[0]
	End Method


	'returns the sprite from array position
	'if no sprite was found, the first in the pack is returned to avoid errors
	Method GetSpriteByPosition:TSprite(position:Int=0)
		If Len(sprites) >= position Then Return sprites[0]
		Return sprites[position]
	End Method


	'returns the sprite with a specified id
	'if no sprite was found, the first in the pack is returned to avoid errors
	Method GetSpriteByID:TSprite(id:Int=0)
		For Local i:Int = 0 Until sprites.length
			'skip missing
			If Not sprites[i] Then Continue
			If sprites[i].id <> id Then Return sprites[i]
		Next
		Return sprites[0]
	End Method


	Method HasSprite:Int(sprite:TSprite)
		For Local i:Int = 0 Until sprites.length
			'skip missing
			If Not sprites[i] Then Continue

			If Lower(sprites[i].name) = Lower(sprite.name) Then Return True
		Next
		Return False
	End Method


	Method AddSprite:Int(sprite:TSprite)
		'skip if already added
		If HasSprite(sprite) Then Return True

		sprite.parent = Self
		sprites :+ [sprite]

		Return True
	End Method


	'draws the whole spritesheet
	Method Render:Int(offsetX:Int, offsetY:Int)
		DrawImage(GetImage(), 0 + offsetX, 0 + offsetY)
	End Method
End Type




Type TSprite
	'defines how many pixels have to get offset from a given position
	Field offset:TRectangle = New TRectangle.Init(0,0,0,0)
	'defines at which pixels of the area the content "starts"
	'or how many pixels from the last row/col the content "ends"
	Field padding:TRectangle = New TRectangle.Init(0,0,0,0)
	Field area:TRectangle = New TRectangle.Init(0,0,0,0)
	'the id is NOT globally unique but a value to make it selectable
	'from a TSpritePack without knowing the name
	Field id:Int = 0
	Field name:String
	Field frameW:Int
	Field frameH:Int
	Field frames:Int
	'amount of rotation: 0=none, 90=90°clockwise, -90=90°anti-clockwise
	Field rotated:Int = 0
	Field parent:TSpritePack
	Field _pix:TPixmap = Null

	Field tileMode:Int = 0

	'=== NINE PATCH SECTION ===
	Field ninePatchEnabled:Int = False
	'center: size of the middle parts (width, height)
	Field ninePatch_centerDimension:TVec2D
	'border: size of TopLeft,TopRight,BottomLeft,BottomRight
	Field ninePatch_borderDimension:TRectangle
	'content: limits for displaying content
	Field ninePatch_contentBorder:TRectangle
	'the scale of "non-stretchable" borders - rest will scale
	'automatically through bigger dimensions
	Field ninePatch_borderDimensionScale:Float = 1.0
	'subtract this amount of pixels on each side for markers
	Const NINEPATCH_MARKER_WIDTH:Int = 1
	Const BORDER_NONE:Int = 0
	Const BORDER_LEFT:Int = 1
	Const BORDER_RIGHT:Int = 2
	Const BORDER_TOP:Int = 4
	Const BORDER_BOTTOM:Int = 8
	Const BORDER_ALL:Int = 1 | 2 | 4 | 8

	Const TILEMODE_UNDEFINED:Int = 0
	Const TILEMODE_STRETCHED:Int = 1
	Const TILEMODE_TILED:Int = 2



	Method Init:TSprite(spritepack:TSpritePack=Null, name:String, area:TRectangle, offset:TRectangle, frames:Int = 0, spriteDimension:TVec2D=Null, id:Int=0)
		Self.name = name
		Self.area = area.copy()
		Self.id = id
		parent = spritepack
		If offset Then Self.offset = offset.copy()
		frameW = area.GetW()
		frameH = area.GetH()
		Self.frames = frames
		If frames > 0
			frameW = Ceil(area.GetW() / frames)
			frameH = area.GetH()
		EndIf
		If spriteDimension And spriteDimension.x<>0 And spriteDimension.y<>0
			frameW = spriteDimension.GetX()
			frameH = spriteDimension.GetY()
		EndIf

		Return Self
	End Method


	Method InitFromImage:TSprite(img:TImage, spriteName:String, frames:Int = 1)
		If Not img
			TLogger.Log("TSprite.InitFromImage()", "Image is null. Cannot create ~q"+spriteName+"~q.", LOG_ERROR)
			Throw "TSprite.InitFromImage: Image is null. Cannot create ~q"+spriteName+"~q."
		EndIf
		'create new spritepack
		Local spritepack:TSpritePack = New TSpritePack.init(img, spriteName+"_pack")
		Init(spritepack, spriteName, New TRectangle.Init(0, 0, img.width, img.height), Null, frames)
		spritepack.addSprite(Self)
		Return Self
	End Method


	'create a sprite using a dataset containing the needed information
	Method InitFromConfig:TSprite(data:TData)
		If Not data Then Return Null
		Local flags:Int = data.GetInt("flags", 0)
		Local url:String = data.GetString("url", "")
		Local name:String = data.GetString("name", "unknownSprite")
		Local frames:Int = data.GetInt("frames", 0)
		Local frameW:Int = data.GetInt("frameW", 0)
		Local frameH:Int = data.GetInt("frameH", 0)
		Local id:Int = data.GetInt("id", 0)
		Local ninePatch:Int = data.GetBool("ninePatch", False)
		Local definedTileMode:Int = data.GetInt("tileMode", TILEMODE_UNDEFINED)
		Local parent:TSpritePack = TSpritePack(data.Get("parent", Null))

		'create a new spritepack if none is assigned yet
		If parent = Null
			If flags & MASKEDIMAGE Then SetMaskColor(255,0,255)

			Local img:TImage = LoadImage(url, flags)
			If Not img
				If Not img
					TLogger.Log("TSprite.InitFromConfig()", "Image is null. Cannot create ~q"+name+"~q out of ~q"+url+"~q.", LOG_ERROR)
					Throw "TSprite.InitFromConfig: Image is null. Cannot create ~q"+name+"~q out of ~q"+url+"~q."
				EndIf
				Throw "image null : "+name + " (url: "+url+" )"
				Return Null
			EndIf
			'load img to find out celldimensions
			If (frameW = 0 Or frameW = 0)
				If frames > 0
					frameW = ImageWidth(img) / frames
				Else
					frameW = ImageWidth(img)
				EndIf
				frameH = ImageHeight(img)
			EndIf
			parent = New TSpritePack.Init(img, name + "_pack")

			If flags & MASKEDIMAGE Then SetMaskColor(0,0,0)
		EndIf


		'assign an offset rect if defined so
		Local offsetLeft:Int = data.GetInt("offsetLeft", 0)
		Local offsetRight:Int = data.GetInt("offsetRight", 0)
		Local offsetTop:Int = data.GetInt("offsetTop", 0)
		Local offsetBottom:Int = data.GetInt("offsetBottom", 0)
		Local offset:TRectangle = Null
		If offsetLeft <> 0 Or offsetRight <> 0 Or offsetTop <> 0 Or offsetBottom <> 0
			offset = New TRectangle.SetTLBR(offsetTop, offsetLeft, offsetBottom, offsetRight)
		EndIf

		'define the area in the parental spritepack, if no dimension
		'is defined, use the whole parental image
		Local area:TRectangle = New TRectangle
		area.position.SetXY(data.GetInt("x", 0), data.GetInt("y", 0))
		area.dimension.SetXY(data.GetInt("w", parent.GetImage().width), data.GetInt("h", parent.GetImage().height))

		'intialize sprite
		Init(parent, name, area, offset, frames, New TVec2D.Init(frameW, frameH), id)

		'rotation
		rotated = data.GetInt("rotated", 0)
		'padding
		SetPadding(New TRectangle.Init(..
			data.GetInt("paddingTop"), ..
			data.GetInt("paddingLeft"), ..
			data.GetInt("paddingBottom"), ..
			data.GetInt("paddingRight") ..
		))

		'recolor/colorize?
		If data.GetInt("r",-1) >= 0 And data.GetInt("g",-1) >= 0 And data.GetInt("b",-1) >= 0
			colorize( TColor.Create(data.GetInt("r"), data.GetInt("g"), data.GetInt("b")) )
		EndIf


		'enable nine patch if wanted
		If ninePatch Then EnableNinePatch()

		tileMode = definedTileMode

		'add to parental spritepack
		parent.addSprite(Self)

		Return Self
	End Method


	'copies a given sprites image to the own area
	Method SetImageContent(img:TImage, color:TColor)
		Local tmppix:TPixmap = LockImage(parent.GetImage(), 0)
			tmppix.Window(Int(area.GetX()), Int(area.GetY()), Int(area.GetW()), Int(area.GetH())).ClearPixels(0)
			DrawImageOnImage(ColorizeImageCopy(img, color), tmppix, Int(area.GetX()), Int(area.GetY()))
		UnlockImage(parent.GetImage(), 0)
	End Method


	Method GetName:String()
		Return name
	End Method


	Method SetPadding:Int(padding:TRectangle)
		Self.padding = padding
	End Method


	Method IsNinePatchEnabled:Int()
		Return ninePatchEnabled
	End Method


	Method EnableNinePatch:Int()
		'read markers in the image to get border and content sizes
		ninePatch_borderDimension = ReadNinePatchMarker(0)
		ninePatch_contentBorder = ReadNinePatchMarker(1)

		If ninePatch_borderDimension.GetLeft() = 0 And ninePatch_borderDimension.GetRight() = 0 And ninePatch_borderDimension.GetTop() = 0 And ninePatch_borderDimension.GetBottom() = 0
			If ninePatch_contentBorder.GetLeft() = 0 And ninePatch_contentBorder.GetRight() = 0 And ninePatch_contentBorder.GetTop() = 0 And ninePatch_contentBorder.GetBottom() = 0
				ninePatchEnabled = False
				Return False
			EndIf
		EndIf

		'center has to consider the marker_width (content dimension marker)
		ninePatch_centerDimension = New TVec2D.Init(..
					area.GetW() - (2* NINEPATCH_MARKER_WIDTH + ninePatch_borderDimension.GetLeft() + ninePatch_borderDimension.GetRight()), ..
					area.GetH() - (2* NINEPATCH_MARKER_WIDTH + ninePatch_borderDimension.GetTop() + ninePatch_borderDimension.GetBottom()) ..
				  )

		ninePatchEnabled = True

		Return True
	End Method


	Method GetNinePatchBorderDimension:TRectangle()
		If Not ninePatch_borderDimension Then ninePatch_borderDimension = New TRectangle.Init(0,0,0,0)
		Return ninePatch_borderDimension
	End Method


	Method GetNinePatchContentBorder:TRectangle()
		If Not ninePatch_contentBorder Then ninePatch_contentBorder = New TRectangle.Init(0,0,0,0)
		Return ninePatch_contentBorder
	End Method


	'read ninepatch markers out of the sprites image data
	'mode = 0: sprite borders
	'mode = 1: content borders
	Method ReadNinePatchMarker:TRectangle(Mode:Int=0)
		If Not _pix Then _pix = GetPixmap()
		Local sourcepixel:Int
		Local sourceW:Int = _pix.width
		Local sourceH:Int = _pix.height
		Local result:TRectangle = New TRectangle.init(0,0,0,0)
		Local markerRow:Int=0, markerCol:Int=0, skipLines:Int=0

		'do not check if there is no space for markers
		If sourceW <= 0 Or sourceH <= 0 Then Return result

		'content is defined at the last pixmap row/col
		If Mode = 1
			markerCol = sourceH - NINEPATCH_MARKER_WIDTH
			markerRow = sourceW - NINEPATCH_MARKER_WIDTH
			skipLines = 1
		EndIf

		'  °= L ====== R = °			ROW ROW ROW ROW
		'  T               T		COL
		'  |               |		COL
		'  B               B		COL
		'  °= L ====== R = °		COL

		Local minVal:Int = 0, maxVal:Int = 0

		'find left border: from 1 to first non-transparent pixel in row 0
		minVal = NINEPATCH_MARKER_WIDTH
		maxVal = sourceW - NINEPATCH_MARKER_WIDTH
		For Local i:Int = minVal Until maxVal
			If ARGB_Alpha(ReadPixel(_pix, i, markerCol)) > 0 Then result.SetLeft(i - minVal);Exit
		Next

		'find right border: from left border the first non opaque pixel in row 0
		minVal = NINEPATCH_MARKER_WIDTH + result.GetLeft()
		'same maxVal as left border
		For Local i:Int = minVal Until maxVal
			If ARGB_Alpha(ReadPixel(_pix, i, markerCol)) = 0 Then result.SetRight(maxVal - i);Exit
		Next


		'find top border: from 1 to first opaque pixel in col 0
		minVal = NINEPATCH_MARKER_WIDTH
		maxVal = sourceH - NINEPATCH_MARKER_WIDTH
		For Local i:Int = minVal Until maxVal
			If ARGB_Alpha(ReadPixel(_pix, markerRow, i)) > 0 Then result.SetTop(i - minVal);Exit
		Next

		'find bottom border: from top border the first non opaque pixel in col 0
		minVal = NINEPATCH_MARKER_WIDTH + result.GetTop()
		'same maxVal as top border
		For Local i:Int = minVal To maxVal
			If ARGB_Alpha(ReadPixel(_pix, markerRow, i)) = 0 Then result.SetBottom(maxVal - i);Exit
		Next

		Return result
	End Method


	'returns the image of this sprite (reference, no copy)
	'if the frame is 0+, only this frame is returned
	'if includeBorder is TRUE, then an potential ninePatchBorder will be
	'included
	Method GetImage:TImage(frame:Int=-1, includeBorder:Int=False)
		'if a frame is requested, just return it (no need for "animated" check)
		If frame >=0 Then Return GetFrameImage(frame)

		Local DestPixmap:TPixmap
		If includeBorder
			DestPixmap = LockImage(parent.GetImage(), 0, False, True).Window(Int(area.GetX()), Int(area.GetY()), Int(area.GetW()), Int(area.GetH()))
		Else
			Local border:TRectangle = GetNinePatchBorderDimension()
			DestPixmap = LockImage(parent.GetImage(), 0, False, True).Window(Int(area.GetX()+ border.GetLeft()), Int(area.GetY() + border.GetTop()), Int(area.GetW() - border.GetLeft() - border.GetRight()), Int(area.GetH() - border.GetTop() - border.GetBottom()))
		EndIf

		UnlockImage(parent.GetImage())

		Return TImage.Load(DestPixmap, 0, 255, 0, 255)
	End Method


	Method GetFrameImage:TImage(frame:Int=0)
		'give back whole image if no frames are configured
		If frames <= 0 Then frame = 0
		Local DestPixmap:TPixmap = LockImage(parent.GetImage(), 0, False, True).Window(Int(area.GetX() + frame * framew), Int(area.GetY()), framew, Int(area.GetH()))

		Return TImage.Load(DestPixmap, 0, 255, 0, 255)
	End Method


	'return the pixmap of the sprite' image (reference, no copy)
	Method GetPixmap:TPixmap(frame:Int=-1)
		'give back whole image if no frames are configured
		If frames <= 0 Then frame = -1

		If Not parent.GetImage() Then Throw "TSprite.GetPixmap() failed: invalid parent.GetImage()"

		Local DestPixmap:TPixmap
		If frame >= 0
			DestPixmap = LockImage(parent.GetImage(), 0, False, True).Window(Int(area.GetX() + frame * framew), Int(area.GetY()), framew, Int(area.GetH()))
		Else
			DestPixmap = LockImage(parent.GetImage(), 0, False, True).Window(Int(area.GetX()), Int(area.GetY()), Int(area.GetW()), Int(area.GetH()))
		EndIf

		Return DestPixmap
	End Method


	'creates a REAL copy (no reference) of an image
	Method GetImageCopy:TImage(loadAnimated:Int = 1)
		SetMaskColor(255,0,255)
		If Self.frames >1 And loadAnimated
			Return LoadAnimImage(GetPixmap().copy(), frameW, frameH, 0, frames)
		Else
			Return LoadImage(GetPixmap().copy())
		EndIf
	End Method


	Method GetColorizedImage:TImage(color:TColor, frame:Int=-1, colorizeMode:Int=0)
		Return ColorizeImageCopy(GetImage(frame), color, 0,0,0, 1,0, colorizeMode)
	End Method


	'removes the part of the sprite packs image occupied by the sprite
	Method ClearImageData()
		Local tmppix:TPixmap = LockImage(parent.GetImage(), 0)
		tmppix.Window(Int(area.GetX()), Int(area.GetY()), Int(area.GetW()), Int(area.GetH())).ClearPixels(0)
	End Method


	Method GetMinWidth:Int(includeOffset:Int=True)
		If ninePatchEnabled
			Return ninePatch_borderDimension.GetLeft() + ninePatch_borderDimension.GetRight()
		Else
			Return GetWidth(includeOffset)
		EndIf
	End Method


	Method GetWidth:Int(includeOffset:Int=True)
		'substract 2 pixels (left and right) ?
		Local ninePatchPixels:Int = 0
		If ninePatchEnabled Then ninePatchPixels = 2

		'todo: advanced calculation
		If rotated = 90 Or rotated = -90
			If includeOffset
				Return area.GetH() - (offset.GetTop() + offset.GetBottom()) - (padding.GetTop() + padding.GetBottom()) - ninePatchPixels
			Else
				Return area.GetH() - (padding.GetTop() + padding.GetBottom()) - ninePatchPixels
			EndIf
		Else
			If includeOffset
				Return area.GetW() - (offset.GetLeft() + offset.GetRight()) - (padding.GetLeft() + padding.GetRight()) - ninePatchPixels
			Else
				Return area.GetW() - (padding.GetLeft() + padding.GetRight()) - ninePatchPixels
			EndIf
		EndIf
	End Method


	Method GetMinHeight:Int(includeOffset:Int=True)
		If ninePatchEnabled
			Return ninePatch_borderDimension.GetTop() + ninePatch_borderDimension.GetBottom()
		Else
			Return GetHeight(includeOffset)
		EndIf
	End Method


	Method GetHeight:Int(includeOffset:Int=True)
		'substract 2 pixles (left and right) ?
		Local ninePatchPixels:Int = 0
		If ninePatchEnabled Then ninePatchPixels = 2

		'todo: advanced calculation
		If rotated = 90 Or rotated = -90
			If includeOffset
				Return area.GetW() - (offset.GetLeft() + offset.GetRight()) - (padding.GetLeft() + padding.GetRight()) - ninePatchPixels
			Else
				Return area.GetW() - (padding.GetLeft() + padding.GetRight()) - ninePatchPixels
			EndIf
		Else
			If includeOffset
				Return area.GetH() - (offset.GetTop() + offset.GetBottom()) - (padding.GetTop() + padding.GetBottom()) - ninePatchPixels
			Else
				Return area.GetH() - (padding.GetTop() + padding.GetBottom()) - ninePatchPixels
			EndIf
		EndIf
	End Method


	Method GetFramePos:TVec2D(frame:Int=-1)
		If frame < 0 Then Return New TVec2D.Init(0,0)

		Local MaxFramesInCol:Int = Ceil(area.GetW() / framew)
		Local framerow:Int = Ceil(frame / Max(1,MaxFramesInCol))
		Local framecol:Int = frame - (framerow * MaxFramesInCol)
		Return New TVec2D.Init(framecol * frameW, framerow * frameH)
	End Method


	'let spritePack colorize the sprite
	Method Colorize(color:TColor)
		'store backup
		'(we clean image data before pasting colorized output)
		Local newImg:TImage = ColorizeImageCopy(GetImage(), color)
		'remove old image part
		ClearImageData()
		'draw now colorized image on the parent image
		DrawImageOnImage(newImg, parent.GetImage(), Int(area.GetX()), Int(area.GetY()))
	End Method


	Method PixelIsOpaque:Int(x:Int, y:Int)
		If x < 0 Or y < 0 Or x > frameW Or y > frameH
			Print "out of bounds: "+x+", "+y
			Return False
		EndIf

		If Not _pix
			_pix = LockImage(GetImage())
			'UnlockImage(parent.image) 'unlockimage does nothing in blitzmax (1.48)
		EndIf

		Return ARGB_Alpha(ReadPixel(_pix, x,y))
	End Method


	'draw the sprite onto a given image or pixmap
	Method DrawOnImage(imageOrPixmap:Object, x:Int, y:Int, frame:Int = -1, alignment:TVec2D=Null, modifyColor:TColor=Null)
		If frames <= 0 Then frame = -1

		If Not alignment Then alignment = ALIGN_LEFT_TOP
		If frame >= 0
			x :- alignment.GetX() * framew
			y :- alignment.GetY() * frameh
		Else
			x :- alignment.GetX() * area.GetW()
			y :- alignment.GetY() * area.GetH()
		EndIf

		DrawImageOnImage(getPixmap(frame), imageOrPixmap, Int(x + offset.GetLeft()), Int(y + offset.GetTop()), modifyColor)
	End Method


	'draw the sprite covering an area (if ninePatch is enabled, the
	'stretching is only done on the center of the sprite)
	Method DrawArea:Int(x:Float, y:Float, width:Float=-1, height:Float=-1, frame:Int=-1, skipBorders:Int = 0, clipRect:TRectangle = Null, forceTileMode:Int = 0)
		If width=-1 Then width = area.GetW()
		If height=-1 Then height = area.GetH()
		If frames <= 0 Then frame = -1

		'nothing to draw?
		If width <= 0 Or height <= 0 Then Return False

		'normal sprites draw their image stretched to area
		If Not ninePatchEnabled
			DrawResized(x, y, width, height, 0,0,0,0, frame, False, Null, tileMode)
		Else
			Local middleW:Int = area.GetW() - ninePatch_borderDimensionScale*(ninePatch_borderDimension.GetLeft()+ninePatch_borderDimension.GetRight())
			Local middleH:Int = area.GetH() - ninePatch_borderDimensionScale*(ninePatch_borderDimension.GetTop()+ninePatch_borderDimension.GetBottom())

			'minimal dimension has to be same or bigger than all 4 borders + 0.1* the stretch portion
			'if borders are disabled, ignore them in minWidth-calculation
			width = Max(width, Max(0.2*middleW, 2) + ninePatch_borderDimensionScale*((1-(skipBorders & BORDER_LEFT)>0)*ninePatch_borderDimension.GetLeft() + (1-(skipBorders & BORDER_RIGHT)>0)*ninePatch_borderDimension.GetRight()))
			height = Max(height, Max(0.2*middleH, 2) + ninePatch_borderDimensionScale*((1-(skipBorders & BORDER_TOP)>0)*ninePatch_borderDimension.GetTop() + (1-(skipBorders & BORDER_BOTTOM)>0)*ninePatch_borderDimension.GetBottom()))

			'dimensions of the stretch-parts (the middle elements)
			'adjusted by a potential border scale
			Local stretchDestW:Float = width - ninePatch_borderDimensionScale*(ninePatch_borderDimension.GetLeft()+ninePatch_borderDimension.GetRight())
			Local stretchDestH:Float = height - ninePatch_borderDimensionScale*(ninePatch_borderDimension.GetTop()+ninePatch_borderDimension.GetBottom())
			'border sizes
			Local bsLeft:Int = ninePatch_borderDimension.GetLeft()
			Local bsTop:Int = ninePatch_borderDimension.GetTop()
			Local bsRight:Int = ninePatch_borderDimension.GetRight()
			Local bsBottom:Int = ninePatch_borderDimension.GetBottom()

			If skipBorders <> 0
				'disable the borders by setting their size to 0
				If skipBorders & BORDER_LEFT > 0
					stretchDestW :+ bsLeft * ninePatch_borderDimensionScale
					bsLeft = 0
				EndIf
				If skipBorders & BORDER_RIGHT > 0
					stretchDestW :+ bsRight * ninePatch_borderDimensionScale
					bsRight = 0
				EndIf
				If skipBorders & BORDER_TOP > 0
					stretchDestH :+ bsTop * ninePatch_borderDimensionScale
					bsTop = 0
				EndIf
				If skipBorders & BORDER_BOTTOM > 0
					stretchDestH :+ bsBottom * ninePatch_borderDimensionScale
					bsBottom = 0
				EndIf
			EndIf


			'prepare render coordinates
			Local targetX1:Int = x
			Local targetX2:Int = targetX1 + bsLeft * ninePatch_borderDimensionScale
			Local targetX3:Int = targetX2 + stretchDestW
			Local targetY1:Int = y
			Local targetY2:Int = targetY1 + bsTop * ninePatch_borderDimensionScale
			Local targetY3:Int = targetY2 + stretchDestH
			Local targetW1:Int = bsLeft * ninePatch_borderDimensionScale
			Local targetW2:Int = stretchDestW
			Local targetW3:Int = bsRight * ninePatch_borderDimensionScale
			Local targetH1:Int = bsTop * ninePatch_borderDimensionScale
			Local targetH2:Int = stretchDestH
			Local targetH3:Int = bsBottom * ninePatch_borderDimensionScale

			Local sourceX1:Int = NINEPATCH_MARKER_WIDTH
			Local sourceX2:Int = sourceX1 + ninePatch_borderDimension.GetLeft()
			Local sourceX3:Int = sourceX2 + ninePatch_centerDimension.GetX()
			Local sourceY1:Int = NINEPATCH_MARKER_WIDTH
			Local sourceY2:Int = sourceY1 + ninePatch_borderDimension.GetTop()
			Local sourceY3:Int = sourceY2 + ninePatch_centerDimension.GetY()

			Local vpx:Int, vpy:Int, vpw:Int, vph:Int
			If clipRect
				GetGraphicsManager().GetViewport(vpx, vpy, vpw, vph)
				Local intersectingVP:TRectangle = clipRect.IntersectRectXYWH(vpx, vpy, vpw, vph)
				If intersectingVP
					GetGraphicsManager().SetViewport(Int(intersectingVP.GetX()), Int(intersectingVP.GetY()), Int(intersectingVP.GetW()), Int(intersectingVP.GetH()))
				EndIf
			EndIf

			'render
			'top
			If ninePatch_borderDimension.GetTop()
				If ninePatch_borderDimension.GetLeft()
					DrawResized( targetX1, targetY1, targetW1, targetH1, sourceX1, sourceY1, ninePatch_borderDimension.GetLeft(), ninePatch_borderDimension.GetTop(), frame, False, clipRect )
				EndIf

				DrawResized( targetX2, targetY1, targetW2, targetH1, sourceX2, sourceY1, ninePatch_centerDimension.GetX(), ninePatch_borderDimension.GetTop(), frame, False, clipRect, tileMode )

				If ninePatch_borderDimension.GetRight()
					DrawResized( targetX3, targetY1, targetW3, targetH1, sourceX3, sourceY1, ninePatch_borderDimension.GetRight(), ninePatch_borderDimension.GetTop(), frame, False, clipRect )
				EndIf
			EndIf


			'middle
			If ninePatch_borderDimension.GetLeft()
				DrawResized( targetX1 , targetY2, targetW1, targetH2, sourceX1, sourceY2, ninePatch_borderDimension.GetLeft(), ninePatch_centerDimension.GetY(), frame, False, clipRect, tileMode )
			EndIf

			DrawResized( targetX2, targetY2, targetW2, targetH2, sourceX2, sourceY2, ninePatch_centerDimension.GetX(), ninePatch_centerDimension.GetY(), frame, False, clipRect, tileMode )

			If ninePatch_borderDimension.GetRight()
				DrawResized( targetX3, targetY2, targetW3, targetH2, sourceX3, sourceY2, ninePatch_borderDimension.GetRight(), ninePatch_centerDimension.GetY(), frame, False, clipRect, tileMode )
			EndIf


			'bottom
			If ninePatch_borderDimension.GetBottom()
				If ninePatch_borderDimension.GetLeft()
					DrawResized( targetX1, targetY3, targetW1, targetH3, sourceX1, sourceY3, ninePatch_borderDimension.GetLeft(), ninePatch_borderDimension.GetBottom(), frame, False, clipRect )
				EndIf

				DrawResized( targetX2, targetY3, targetW2, targetH3, sourceX2, sourceY3, ninePatch_centerDimension.GetX(), ninePatch_borderDimension.GetBottom(), frame, False, clipRect, tileMode)

				If ninePatch_borderDimension.GetRight()
					DrawResized( targetX3, targetY3, targetW3, targetH3, sourceX3, sourceY3, ninePatch_borderDimension.GetRight(), ninePatch_borderDimension.GetBottom(), frame, False, clipRect )
				EndIf
			EndIf

			'reset viewport if it was modified
			If clipRect
				GetGraphicsManager().SetViewport(vpX, vpY, vpW, vpH)
			EndIf
		EndIf
	End Method


	'draw the sprite resized/stretched
	'source is a rectangle within sprite.area
	Method DrawResized(tX:Float, tY:Float, tW:Float, tH:Float, sX:Float, sY:Float, sW:Float, sH:Float, frame:Int=-1, drawCompleteImage:Int=False, clipRect:TRectangle = Null, forceTileMode:Int = 0)
		If frames <= 0 Then frame = -1
		If drawCompleteImage Then frame = -1

		'we got a frame request - try to find it
		'calculate WHERE the frame is positioned in spritepack
		If frame >= 0 And frameW > 0 And frameH > 0
			Local MaxFramesInCol:Int = Floor(area.GetW() / framew)
			Local frameInRow:Int = Floor(frame / MaxFramesInCol)	'0based
			Local frameInCol:Int = frame Mod MaxFramesInCol			'0based
			'move the source rect accordingly
			sX = frameInCol*frameW
			sY = frameinRow*frameH

			'if no source dimension was given - use frame dimension
			If sW <= 0 Then sW = frameW
			If sH <= 0 Then sH = frameH
		Else
			'if no source dimension was given - use image dimension
			If sW <= 0 Then sW = area.GetW()
			If sH <= 0 Then sH = area.GetH()
		EndIf

		'resize source rect so it stays within the sprite's limits
		sW = Min(area.GetW(), sW)
		sH = Min(area.GetH(), sH)

		'if no target dimension was given - use source dimension
		If tW <= 0 Then tW = sW
		If tH <= 0 Then tH = sH

		'take care of offsets
		If offset And (offset.position.x<>0 Or offset.position.y<>0 Or offset.dimension.x<>0 Or offset.dimension.y<>0)
			'top and left border also modify position to draw
			'starting at the top border - so include that offset
			If sY = 0
				tY :+ -offset.GetTop()
				tH :+ offset.GetTop()
				sH :+ offset.GetTop()
			Else
				sY :+ offset.GetTop()
			EndIf
			If sX = 0
				tX :+ -offset.GetLeft()
				tW :+ offset.GetLeft()
				sW :+ offset.GetLeft()
			Else
				sX :+ offset.GetLeft()
			EndIf

			'hitting bottom border - draw bottom offset
			If (sY + sH) >= (area.GetH() - offset.GetBottom())
				sH :+ offset.GetBottom()
				tH :+ offset.GetBottom()
			EndIf
			'hitting right border - draw right offset
'			if (sX + sW) >= (area.GetW() - offset.GetRight())
'				sW :+ offset.GetRight()
'			endif
		EndIf

		If clipRect
			'check if render area is outside of clipping area
			If Not clipRect.IntersectsXYWH(tX, tY, tW, tH) Then Return


			'limit viewport to intersection of current VP and clipping area
			Local vpx:Int, vpy:Int, vpw:Int, vph:Int
			GetGraphicsManager().GetViewport(vpx, vpy, vpw, vph)

			Local intersectingVP:TRectangle = clipRect.IntersectRectXYWH(vpx, vpy, vpw, vph)
			If intersectingVP
				GetGraphicsManager().SetViewport(Int(intersectingVP.GetX()), Int(intersectingVP.GetY()), Int(intersectingVP.GetW()), Int(intersectingVP.GetH()))
					If forceTileMode = TILEMODE_UNDEFINED Then forceTileMode = tileMode

					If forceTileMode = TILEMODE_UNDEFINED Or forceTileMode = TILEMODE_STRETCHED
						DrawSubImageRect(parent.GetImage(), Float(Floor(tX)), Float(Floor(tY)), Float(Ceil(tW)), Float(Ceil(tH)), Float(area.GetX() + sX), Float(area.GetY() + sY), sW, sH)
					ElseIf forceTileMode = TILEMODE_TILED
						Local startX:Int = Int(Floor(tX))
						Local startY:Int = Int(Floor(tY))
						Local w:Int = Int(Ceil(tW))
						Local h:Int = Int(Ceil(tH))

						Local x:Int = 0
						While x <= w '- sourceCopy.GetIntW()
							Local y:Int = 0
							Local maxW:Int = Min(sW, w - x)
							While y <= h - Int(sH)
								Local maxH:Int = Min(sH, h - y)
								DrawSubImageRect(parent.GetImage(), Float(startX + x), Float(startY + y), maxW, maxH, Float(area.GetX() + sX), Float(area.GetY() + sY), maxW, maxH)
								y :+ Int(sH)
							Wend
							x :+ Int(sW)
						Wend
					EndIf
				GetGraphicsManager().SetViewport(vpx, vpy, vpw, vph)
			EndIf

Rem
'unfinished- calculations not free of bugs...
			'Clip left and top
			Local clipL:float = Max(0, clipRect.GetX() - targetCopy.GetX())
			Local clipT:float = Max(0, clipRect.GetY() - targetCopy.GetY())
			'Clip right and bottom
			Local clipR:float = Max(0, targetCopy.GetX2() - clipRect.GetX2())
			Local clipB:float = Max(0, targetCopy.GetY2() - clipRect.GetY2())

			'source area has to get scaled down because of clipping...
			Local scaleX:Float = 1.0 - (clipL + clipR) / targetCopy.GetW()
			Local scaleY:Float = 1.0 - (clipT + clipB) / targetCopy.GetH()

'			DrawImageArea(Image, x + startX + offsetX, y + startY + offsetY, startX, startY, w - startX - endX, h - startY - endY, frame)

	print "clipL="+clipL+" T="+clipT+" R="+clipR+" B="+clipB+"  scaleX="+scaleX+"  scaleY="+scaleY
	print "classic:  target="+floor(targetCopy.GetX())+", "+floor(targetCopy.GetY())+", "+ceil(targetCopy.GetW())+", "+ceil(targetCopy.GetH())+"   source="+int(area.GetX() + sourceCopy.GetX())+", "+int(area.GetY() + sourceCopy.GetY())+", "+int(sourceCopy.GetW())+", "+int(sourceCopy.GetH())
	print "new    :  target="+floor(targetCopy.GetX() + clipL)+", "+floor(targetCopy.GetY() + clipT)+", "+ceil(targetCopy.GetW() - clipR - clipL)+", "+ceil(targetCopy.GetH() - clipB - clipT)+"  source="+int(area.GetX() + sourceCopy.GetX() + clipL*scaleX)+", "+int(area.GetY() + sourceCopy.GetY() + clipT*scaleY)+", "+int(sourceCopy.GetW()*scaleX)+", "+int(sourceCopy.GetH()*scaleY)

			DrawSubImageRect(parent.GetImage(),..
				floor(targetCopy.GetX() + clipL), floor(targetCopy.GetY() + clipT), ceil(targetCopy.GetW() - clipR - clipL), ceil(targetCopy.GetH() - clipB - clipT), ..
				area.GetX() + sourceCopy.GetX() + clipL*(1.0-scaleX), area.GetY() + sourceCopy.GetY() + (clipT/targetcopy.GetH())*scaleY, sourceCopy.GetW()*scaleX, sourceCopy.GetH()*scaleY)
endrem
'			DrawSubImageRect(parent.GetImage(), Float(floor(targetCopy.GetX())), Float(floor(targetCopy.GetY())), Float(ceil(targetCopy.GetW())), Float(ceil(targetCopy.GetH())), Float(area.GetX() + sourceCopy.GetX()), Float(area.GetY() + sourceCopy.GetY()), sourceCopy.GetW(), sourceCopy.GetH())
		Else
			If tileMode = 0 'stretched
				DrawSubImageRect(parent.GetImage(), Float(Floor(tX)), Float(Floor(tY)), Float(Ceil(tW)), Float(Ceil(tH)), Float(area.GetX() + sX), Float(area.GetY() + sY), sW, sH)
			ElseIf tileMode = 1 'tiled

				Local startX:Int = Int(Floor(tX))
				Local startY:Int = Int(Floor(tY))
				Local w:Int = Int(Ceil(tW))
				Local h:Int = Int(Ceil(tH))

				Local x:Int = 0
				While x <= w '- int(sW)
					Local y:Int = 0
					Local maxW:Int = Min(sW, w - x)
					While y <= h '- sourceCopy.GetIntH()
						Local maxH:Int = Min(sH, h - y)
						DrawSubImageRect(parent.GetImage(), Float(startX + x), Float(startY + y), maxW, maxH, Float(area.GetX() + sX), Float(area.GetY() + sY), maxW, maxH)
						y :+ Int(sH)
					Wend
					x :+ Int(sW)
				Wend
			EndIf
			'TODO: for "target = image" use DrawImageOnImage() and stretch
			'via "ResizePixmap()"
		EndIf
	End Method


	Method DrawClipped(x:Float, y:Float, w:Float, h:Float, offsetX:Float=0, offsetY:Float=0, frame:Int=-1)
		DrawResized(x, y, 0#, 0#, offsetX, offsetY, w, h, frame)
	End Method


	Method DrawInArea(x:Float, y:Float, area:TRectangle = Null, frame:Int=-1)
		Local vpRect:TRectangle

		If area
			Local vpx:Int, vpy:Int, vpw:Int, vph:Int
			GetGraphicsManager().GetViewport(vpx, vpy, vpw, vph)

			Local intersectingVP:TRectangle = area.IntersectRectXYWH(vpx, vpy, vpw, vph)
			GetGraphicsManager().SetViewport(Int(intersectingVP.GetX()), Int(intersectingVP.GetY()), Int(intersectingVP.GetW()), Int(intersectingVP.GetH()))
		EndIf

		Draw(x, y)

		'reset viewport if it was modified
		If vpRect
			GetGraphicsManager().SetViewport(Int(vpRect.GetX()), Int(vpRect.GetY()), Int(vpRect.GetW()), Int(vpRect.GetH()))
		EndIf
	End Method


	Method TileDrawHorizontal(x:Float, y:Float, w:Float, alignment:TVec2D=Null, scale:Float=1.0, theframe:Int=-1)
		If frames <= 0 Then theframe = -1
		Local widthLeft:Float = w
		Local currentX:Float = x
		Local framePos:TVec2D = getFramePos(theframe)

		Local alignX:Float = 0.0
		Local alignY:Float = 0.0

		If alignment
			alignX = alignment.x
			alignY = alignment.y
		EndIf

		'add offset
		currentX :- offset.GetLeft() * scale

		Local offsetX:Int = Int(alignX * area.GetW())
		Local offsetY:Int = Int(alignY * area.GetH())


		While widthLeft > 0
			Local widthPart:Float = Min(frameW, widthLeft) 'draw part of sprite or whole ?
			DrawSubImageRect( parent.GetImage(), currentX + offsetX, y - offsetY, widthPart, area.GetH(), area.GetX() + framePos.x, area.GetY() + framePos.y, widthPart, frameH, 0 )
			currentX :+ widthPart * scale
			widthLeft :- widthPart * scale
		Wend
	End Method


	Method TileDrawVertical(x:Float, y:Float, h:Float, alignment:TVec2D=Null, scale:Float=1.0)
		Local heightLeft:Float = h
		Local currentY:Float = y
		While heightLeft >= 1
			Local heightPart:Float = Min(area.GetH(), heightLeft) 'draw part of sprite or whole ?
			DrawSubImageRect( parent.GetImage(), x + offset.GetLeft(), currentY + offset.GetTop(), area.GetW(), Float(Ceil(heightPart)), area.GetX(), area.GetY(), area.GetW(), Float(Ceil(heightPart)) )
			currentY :+ Floor(heightPart * scale)
			heightLeft :- (heightPart * scale)
		Wend
	End Method


	Method TileDraw(x:Float, y:Float, w:Int, h:Int, scale:Float=1.0)
		Local heightLeft:Float = Floor(h)
		Local currentY:Float = y
		While heightLeft >= 1
			Local heightPart:Float = Min(area.GetH(), heightLeft) 'draw part of sprite or whole ?
			Local widthLeft:Float = w
			Local currentX:Float = x
			While widthLeft > 0
				Local widthPart:Float = Min(area.GetW(), widthLeft) 'draw part of sprite or whole ?
				DrawSubImageRect( parent.GetImage(), currentX + offset.GetLeft(), currentY + offset.GetTop(), Float(Ceil(widthPart)), Float(Ceil(heightPart)), Self.area.GetX(), Self.area.GetY(), Float(Ceil(widthPart)), Float(Ceil(heightPart)) )
				currentX :+ Floor(widthPart * scale)
				widthLeft :- (widthPart * scale)
			Wend
			currentY :+ Floor(heightPart * scale)
			heightLeft :- (heightPart * scale)
		Wend
	End Method


	Method Draw(x:Float, y:Float, frame:Int=-1, alignment:TVec2D=Null, scale:Float=1.0, drawCompleteImage:Int=False)
		If frames <= 0 Then frame = -1
		If drawCompleteImage Then frame = -1

		Rem
			ALIGNMENT IS POSITION OF HANDLE !!

			   TOPLEFT        TOPRIGHT
			           .----.
			           |    |
			           '----'
			BOTTOMLEFT        BOTTOMRIGHT
		endrem

		Local alignX:Float = 0.0
		Local alignY:Float = 0.0

		If alignment
			alignX = alignment.x
			alignY = alignment.y
		EndIf

		'add offset
		x:- offset.GetLeft() * scale
		Y:- offset.GetTop() * scale
'		x:- offset.GetRight() * scale
'		Y:- offset.GetBottom() * scale


		Local offsetX:Int = Int(alignX * area.GetW())
		Local offsetY:Int = Int(alignY * area.GetH())

		'for a correct rotation calculation
		If scale <> 1.0 Then SetScale(scale, scale)
		If rotated
			SetRotation(-rotated)
			If rotated = 90
				offsetX = -Int((alignY-1) * area.GetW())
				offsetY =  Int( alignX    * area.GetH())
			ElseIf rotated = -90
				offsetX = Int((1-alignY) * area.GetW())
				offsetY = Int((1-alignX) * area.GetH())
			EndIf
		EndIf


		If ninePatchEnabled
			offsetX :- 2 * NINEPATCH_MARKER_WIDTH
			offsetY :- 2 * NINEPATCH_MARKER_WIDTH
		EndIf


		If frame = -1 Or framew = 0
			'cast handle-offsets to "int" to avoid subpixel offsets
			'which lead to visual garbage on thin pixel lines in images
			'(they are a little off and therefore have other alpha values)
			If ninePatchEnabled
				DrawSubImageRect(parent.GetImage(),..
							 x,..
							 y,..
							 area.GetW() - 2 * NINEPATCH_MARKER_WIDTH,..
							 area.GetH() - 2 * NINEPATCH_MARKER_WIDTH,..
							 area.GetX() + NINEPATCH_MARKER_WIDTH,..
							 area.GetY() + NINEPATCH_MARKER_WIDTH,..
							 area.GetW() - 2 * NINEPATCH_MARKER_WIDTH,..
							 area.GetH() - 2 * NINEPATCH_MARKER_WIDTH,..
							 offsetX,..
							 offsetY,..
							 0)
			Else
				DrawSubImageRect(parent.GetImage(),..
							 x,..
							 y,..
							 area.GetW(),..
							 area.GetH(),..
							 area.GetX(),..
							 area.GetY(),..
							 area.GetW(),..
							 area.GetH(),..
							 offsetX,..
							 offsetY,..
							 0)
			EndIf
		Else
			Local MaxFramesInCol:Int	= Ceil(area.GetW() / framew)
			Local framerow:Int			= Ceil(frame / MaxFramesInCol)
			Local framecol:Int 			= frame - (framerow * MaxFramesInCol)

			DrawSubImageRect(parent.GetImage(),..
							 x,..
							 y,..
							 framew,..
							 frameh,..
							 area.GetX() + framecol * frameW,..
							 area.GetY() + framerow * frameH,..
							 framew,..
							 frameh,..
							 Int(alignX * frameW), ..
							 Int(alignY * frameH), ..
							 0)
		EndIf

		If scale <> 1.0 Then SetScale(1.0, 1.0)
		If rotated <> 0 Then SetRotation(0)
	End Method
End Type