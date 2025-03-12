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

	Copyright (C) 2002-now Ronny Otto, digidea.de

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
?not bmxng
Import Brl.Random
?bmxng
Import Random.Xoshiro
?
Import "base.util.event.bmx"
Import "base.util.vector.bmx"
Import "base.util.srectangle.bmx"
Import "base.gfx.imagehelper.bmx"
Import "base.util.graphicsmanagerbase.bmx"


Const ALIGN_LEFT:Float = 0
Const ALIGN_CENTER:Float = 0.5
Const ALIGN_RIGHT:Float = 1.0
Const ALIGN_TOP:Float = 0
Const ALIGN_BOTTOM:Float = 1.0

Global ALIGN_LEFT_TOP:TVec2D = New TVec2D
Global ALIGN_CENTER_TOP:TVec2D = New TVec2D(ALIGN_CENTER, ALIGN_TOP)
Global ALIGN_RIGHT_TOP:TVec2D = New TVec2D(ALIGN_RIGHT, ALIGN_TOP)

Global ALIGN_LEFT_CENTER:TVec2D = New TVec2D(ALIGN_LEFT, ALIGN_CENTER)
Global ALIGN_CENTER_CENTER:TVec2D = New TVec2D(ALIGN_CENTER, ALIGN_CENTER)
Global ALIGN_RIGHT_CENTER:TVec2D = New TVec2D(ALIGN_RIGHT, ALIGN_CENTER)

Global ALIGN_LEFT_BOTTOM:TVec2D = New TVec2D(ALIGN_LEFT, ALIGN_BOTTOM)
Global ALIGN_CENTER_BOTTOM:TVec2D = New TVec2D(ALIGN_CENTER, ALIGN_BOTTOM)
Global ALIGN_RIGHT_BOTTOM:TVec2D = New TVec2D(ALIGN_RIGHT, ALIGN_BOTTOM)

Global sALIGN_LEFT_TOP:SVec2F = New SVec2F
Global sALIGN_CENTER_TOP:SVec2F = New SVec2F(ALIGN_CENTER, ALIGN_TOP)
Global sALIGN_RIGHT_TOP:SVec2F = New SVec2F(ALIGN_RIGHT, ALIGN_TOP)

Global sALIGN_LEFT_CENTER:SVec2F = New SVec2F(ALIGN_LEFT, ALIGN_CENTER)
Global sALIGN_CENTER_CENTER:SVec2F = New SVec2F(ALIGN_CENTER, ALIGN_CENTER)
Global sALIGN_RIGHT_CENTER:SVec2F = New SVec2F(ALIGN_RIGHT, ALIGN_CENTER)

Global sALIGN_LEFT_BOTTOM:SVec2F = New SVec2F(ALIGN_LEFT, ALIGN_BOTTOM)
Global sALIGN_CENTER_BOTTOM:SVec2F = New SVec2F(ALIGN_CENTER, ALIGN_BOTTOM)
Global sALIGN_RIGHT_BOTTOM:SVec2F = New SVec2F(ALIGN_RIGHT, ALIGN_BOTTOM)



Type TSpritePack
	Field image:TImage {nosave}
	Field name:String
	Field sprites:TSprite[]
	
	
	Method New(image:TImage, name:String)
		Self.image = image
		Self.name = name
	End Method


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



Type TNinePatchInformation
	'center: size of the middle parts (width, height)
	Field centerDimension:SVec2i
	'border: size of TopLeft,TopRight,BottomLeft,BottomRight
	Field borderDimension:SRect
	'content: limits for displaying content
	Field contentBorder:SRect
	'the scale of "non-stretchable" borders - rest will scale
	'automatically through bigger dimensions
	Field borderDimensionScale:Float = 1.0
	'subtract this amount of pixels on each side for markers
	Const MARKER_WIDTH:Int = 1


	Method Init:Int(area:TRectangle, pixmap:TPixmap)
		'read markers in the image to get border and content sizes
		borderDimension = ReadMarker(pixmap, 0)
		contentBorder = ReadMarker(pixmap, 1)

		If borderDimension.GetLeft() = 0 And borderDimension.GetRight() = 0 And borderDimension.GetTop() = 0 And borderDimension.GetBottom() = 0
			If contentBorder.GetLeft() = 0 And contentBorder.GetRight() = 0 And contentBorder.GetTop() = 0 And contentBorder.GetBottom() = 0
				Return False
			EndIf
		EndIf

		'center has to consider the marker_width (content dimension marker)
		centerDimension = New SVec2i(..
			int(area.GetW() - (2* MARKER_WIDTH + borderDimension.GetLeft() + borderDimension.GetRight())), ..
			int(area.GetH() - (2* MARKER_WIDTH + borderDimension.GetTop() + borderDimension.GetBottom())) ..
		)

		Return True
	End Method
	

	'read ninepatch markers out of the sprites image data
	'mode = 0: sprite borders
	'mode = 1: content borders
	Method ReadMarker:SRect(pixmap:TPixmap, Mode:Int=0)
		Local sourcepixel:Int
		Local sourceW:Int = pixmap.width
		Local sourceH:Int = pixmap.height
		Local resL:Int, resT:Int, resB:Int, resR:Int
		Local markerRow:Int=0, markerCol:Int=0, skipLines:Int=0

		'do not check if there is no space for markers
		If sourceW <= 0 Or sourceH <= 0 Then Return new SRect()

		'content is defined at the last pixmap row/col
		If Mode = 1
			markerCol = sourceH - MARKER_WIDTH
			markerRow = sourceW - MARKER_WIDTH
			skipLines = 1
		EndIf

		'  °= L ====== R = °			ROW ROW ROW ROW
		'  T               T		COL
		'  |               |		COL
		'  B               B		COL
		'  °= L ====== R = °		COL

		Local minVal:Int = 0, maxVal:Int = 0

		'find left border: from 1 to first non-transparent pixel in row 0
		minVal = MARKER_WIDTH
		maxVal = sourceW - MARKER_WIDTH
		For Local i:Int = minVal Until maxVal
			If ARGB_Alpha(ReadPixel(pixmap, i, markerCol)) > 0 Then resL = i - minVal;Exit
		Next

		'find right border: from left border the first non opaque pixel in row 0
		minVal = MARKER_WIDTH + resL
		'same maxVal as left border
		For Local i:Int = minVal Until maxVal
			If ARGB_Alpha(ReadPixel(pixmap, i, markerCol)) = 0 Then resR = maxVal - i;Exit
		Next


		'find top border: from 1 to first opaque pixel in col 0
		minVal = MARKER_WIDTH
		maxVal = sourceH - MARKER_WIDTH
		For Local i:Int = minVal Until maxVal
			If ARGB_Alpha(ReadPixel(pixmap, markerRow, i)) > 0 Then resT = i - minVal;Exit
		Next

		'find bottom border: from top border the first non opaque pixel in col 0
		minVal = MARKER_WIDTH + resT
		'same maxVal as top border
		For Local i:Int = minVal To maxVal
			If ARGB_Alpha(ReadPixel(pixmap, markerRow, i)) = 0 Then resB = maxVal - i;Exit
		Next

		Return SRect.CreateTLBR(resT, resL, resB, resR)
	End Method
End Type



Type TSprite
	'defines how many pixels have to get offset from a given position
	Field offset:SRectI
	'defines at which pixels of the area the content "starts"
	'or how many pixels from the last row/col the content "ends"
	Field padding:SRectI
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

	Field ninePatch:TNinePatchInformation
	
	'can be used to define a default sprite used if a requested one was not available
	'for now it is used in the TRegistry and TRegistrySpriteLoader
	Global defaultSprite:TSprite
	
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
		If offset Then Self.offset = new SRectI(offset.GetIntX(), offset.GetIntY(), offset.GetIntW(), offset.GetIntH())
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


	Method Init:TSprite(spritepack:TSpritePack=Null, name:String, area:SRectI, offset:SRectI, frames:Int = 0, spriteDimension:TVec2D=Null, id:Int=0)
		Self.name = name
		Self.area = new TRectangle.Init(area.x, area.y, area.w, area.h)
		Self.id = id
		parent = spritepack
		Self.offset = offset
		frameW = area.w
		frameH = area.h
		Self.frames = frames
		If frames > 0
			frameW = Ceil(area.w / frames)
			frameH = area.h
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
		Local ninePatchEnabled:Int = data.GetBool("ninePatch", False)
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
		If offsetLeft <> 0 Or offsetRight <> 0 Or offsetTop <> 0 Or offsetBottom <> 0
			offset = SRectI.CreateTLBR(offsetTop, offsetLeft, offsetBottom, offsetRight)
		Else
			offset = new SRectI()
		EndIf

		'define the area in the parental spritepack, if no dimension
		'is defined, use the whole parental image
		Local area:SRectI = New SRectI( data.GetInt("x", 0), ..
		                                data.GetInt("y", 0), ..
		                                data.GetInt("w", parent.GetImage().width), ..
		                                data.GetInt("h", parent.GetImage().height) ..
		                              )
		'intialize sprite
		Init(parent, name, area, offset, frames, New TVec2D(frameW, frameH), id)

		'rotation
		rotated = data.GetInt("rotated", 0)
		'padding
		SetPadding( data.GetInt("paddingTop"), data.GetInt("paddingLeft"), ..
		            data.GetInt("paddingBottom"), data.GetInt("paddingRight") )

		'recolor/colorize?
		If data.GetInt("r",-1) >= 0 And data.GetInt("g",-1) >= 0 And data.GetInt("b",-1) >= 0
			colorize( TColor.Create(data.GetInt("r"), data.GetInt("g"), data.GetInt("b")) )
		EndIf


		'enable nine patch if wanted
		If ninePatchEnabled Then EnableNinePatch()

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


	Method SetPadding:Int(padding:SRectI)
		Self.padding = padding
	End Method


	Method SetPadding:Int(x:Int, y:Int, w:Int, h:Int)
		Self.padding = new SRectI(x,y,w,h)
	End Method


	Method IsNinePatch:Int()
		Return ninePatch <> Null
	End Method


	Method EnableNinePatch:Int()
		if not ninePatch then ninePatch = new TNinePatchInformation()
		
		if not _pix Then _pix = GetPixmap()

		if not ninePatch.Init(area, _pix)
			ninePatch = Null
			Return False
		Else
			Return True
		EndIf
	End Method


	Method GetNinePatchInformation:TNinePatchInformation()
		Return ninePatch
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
			if IsNinePatch() 
				DestPixmap = LockImage(parent.GetImage(), 0, False, True).Window(Int(area.GetX()+ ninePatch.borderDimension.GetLeft()), Int(area.GetY() + ninePatch.borderDimension.GetTop()), Int(area.GetW() - ninePatch.borderDimension.GetLeft() - ninePatch.borderDimension.GetRight()), Int(area.GetH() - ninePatch.borderDimension.GetTop() - ninePatch.borderDimension.GetBottom()))
			else
				DestPixmap = LockImage(parent.GetImage(), 0, False, True).Window(Int(area.GetX()), Int(area.GetY()), Int(area.GetW()), Int(area.GetH()))
			endif
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
			Return LoadAnimImage(GetPixmap().copy(), frameW, frameH, 0, frames, parent.GetImage().flags)
		Else
			Return LoadImage(GetPixmap().copy(), parent.GetImage().flags)
		EndIf
	End Method


	Method GetColorizedImage:TImage(color:TColor, frame:Int=-1, colorizeMode:EColorizeMode = EColorizeMode.Multiply)
		Return ColorizeImageCopy(GetImage(frame), color, 0,0,0, 1, -1, colorizeMode)
	End Method


	'removes the part of the sprite packs image occupied by the sprite
	Method ClearImageData()
		Local tmppix:TPixmap = LockImage(parent.GetImage(), 0)
		tmppix.Window(Int(area.GetX()), Int(area.GetY()), Int(area.GetW()), Int(area.GetH())).ClearPixels(0)
	End Method


	Method GetMinWidth:Int(includeOffset:Int=True)
		If ninePatch
			Return ninePatch.borderDimension.GetLeft() + ninePatch.borderDimension.GetRight()
		Else
			Return GetWidth(includeOffset)
		EndIf
	End Method


	Method GetWidth:Int(includeOffset:Int=True)
		'substract 2 pixels (left and right) ?
		Local ninePatchPixels:Int = 0
		If ninePatch Then ninePatchPixels = 2

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
		If ninePatch
			Return ninePatch.borderDimension.GetTop() + ninePatch.borderDimension.GetBottom()
		Else
			Return GetHeight(includeOffset)
		EndIf
	End Method


	Method GetHeight:Int(includeOffset:Int=True)
		'substract 2 pixles (left and right) ?
		Local ninePatchPixels:Int = 0
		If ninePatch Then ninePatchPixels = 2

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


	Method GetFramePos:SVec2I(frame:Int=-1)
		If frame < 0 Then Return New SVec2I(0,0)

		Local MaxFramesInCol:Int = Ceil(area.GetW() / framew)
		Local framerow:Int = Ceil(frame / Max(1,MaxFramesInCol))
		Local framecol:Int = frame - (framerow * MaxFramesInCol)
		Return New SVec2I(framecol * frameW, framerow * frameH)
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

	'draw the sprite onto a given image or pixmap
	Method DrawOnImageSColor(imageOrPixmap:Object, x:Int, y:Int, frame:Int = -1, alignment:TVec2D=Null, modifyColor:SColor8, scaleX:Float=1.0, scaleY:Float=1.0)
		If frames <= 0 Then frame = -1

		If Not alignment Then alignment = ALIGN_LEFT_TOP
		If frame >= 0
			x :- alignment.GetX() * framew
			y :- alignment.GetY() * frameh
		Else
			x :- alignment.GetX() * area.GetW()
			y :- alignment.GetY() * area.GetH()
		EndIf

		DrawImageOnImageSColor(getPixmap(frame), imageOrPixmap, Int(x + offset.GetLeft()), Int(y + offset.GetTop()), modifyColor, 0, scaleX, scaleY)
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
		If Not ninePatch
			DrawResized(x, y, width, height, 0,0,0,0, frame, False, Null, tileMode)
		Else
			Local middleW:Int = area.GetW() - ninePatch.borderDimensionScale*(ninePatch.borderDimension.GetLeft()+ninePatch.borderDimension.GetRight())
			Local middleH:Int = area.GetH() - ninePatch.borderDimensionScale*(ninePatch.borderDimension.GetTop()+ninePatch.borderDimension.GetBottom())

			'minimal dimension has to be same or bigger than all 4 borders + 0.1* the stretch portion
			'if borders are disabled, ignore them in minWidth-calculation
			width = Max(width, Max(0.2*middleW, 2) + ninePatch.borderDimensionScale*((1-(skipBorders & BORDER_LEFT)>0)*ninePatch.borderDimension.GetLeft() + (1-(skipBorders & BORDER_RIGHT)>0)*ninePatch.borderDimension.GetRight()))
			height = Max(height, Max(0.2*middleH, 2) + ninePatch.borderDimensionScale*((1-(skipBorders & BORDER_TOP)>0)*ninePatch.borderDimension.GetTop() + (1-(skipBorders & BORDER_BOTTOM)>0)*ninePatch.borderDimension.GetBottom()))

			'dimensions of the stretch-parts (the middle elements)
			'adjusted by a potential border scale
			Local stretchDestW:Float = width - ninePatch.borderDimensionScale*(ninePatch.borderDimension.GetLeft()+ninePatch.borderDimension.GetRight())
			Local stretchDestH:Float = height - ninePatch.borderDimensionScale*(ninePatch.borderDimension.GetTop()+ninePatch.borderDimension.GetBottom())
			'border sizes
			Local bsLeft:Int = ninePatch.borderDimension.GetLeft()
			Local bsTop:Int = ninePatch.borderDimension.GetTop()
			Local bsRight:Int = ninePatch.borderDimension.GetRight()
			Local bsBottom:Int = ninePatch.borderDimension.GetBottom()

			If skipBorders <> 0
				'disable the borders by setting their size to 0
				If skipBorders & BORDER_LEFT > 0
					stretchDestW :+ bsLeft * ninePatch.borderDimensionScale
					bsLeft = 0
				EndIf
				If skipBorders & BORDER_RIGHT > 0
					stretchDestW :+ bsRight * ninePatch.borderDimensionScale
					bsRight = 0
				EndIf
				If skipBorders & BORDER_TOP > 0
					stretchDestH :+ bsTop * ninePatch.borderDimensionScale
					bsTop = 0
				EndIf
				If skipBorders & BORDER_BOTTOM > 0
					stretchDestH :+ bsBottom * ninePatch.borderDimensionScale
					bsBottom = 0
				EndIf
			EndIf


			'prepare render coordinates
			Local targetX1:Int = x
			Local targetX2:Int = targetX1 + bsLeft * ninePatch.borderDimensionScale
			Local targetX3:Int = targetX2 + stretchDestW
			Local targetY1:Int = y
			Local targetY2:Int = targetY1 + bsTop * ninePatch.borderDimensionScale
			Local targetY3:Int = targetY2 + stretchDestH
			Local targetW1:Int = bsLeft * ninePatch.borderDimensionScale
			Local targetW2:Int = stretchDestW
			Local targetW3:Int = bsRight * ninePatch.borderDimensionScale
			Local targetH1:Int = bsTop * ninePatch.borderDimensionScale
			Local targetH2:Int = stretchDestH
			Local targetH3:Int = bsBottom * ninePatch.borderDimensionScale

			Local sourceX1:Int = NINEPatch.MARKER_WIDTH
			Local sourceX2:Int = sourceX1 + ninePatch.borderDimension.GetLeft()
			Local sourceX3:Int = sourceX2 + ninePatch.centerDimension.x
			Local sourceY1:Int = NINEPatch.MARKER_WIDTH
			Local sourceY2:Int = sourceY1 + ninePatch.borderDimension.GetTop()
			Local sourceY3:Int = sourceY2 + ninePatch.centerDimension.y

			Local vpx:Int, vpy:Int, vpw:Int, vph:Int
			If clipRect
				GetGraphicsManager().GetViewport(vpx, vpy, vpw, vph)
				Local intersectingVP:SRect = clipRect.IntersectSRectXYWH(vpx, vpy, vpw, vph)
				If intersectingVP.w > 0 and intersectingVP.h > 0
					GetGraphicsManager().SetViewport(Int(intersectingVP.x), Int(intersectingVP.y), Int(intersectingVP.w), Int(intersectingVP.h))
				EndIf
			EndIf

			'render
			'top
			If ninePatch.borderDimension.GetTop()
				If ninePatch.borderDimension.GetLeft()
					DrawResized( targetX1, targetY1, targetW1, targetH1, sourceX1, sourceY1, ninePatch.borderDimension.GetLeft(), ninePatch.borderDimension.GetTop(), frame, False, clipRect )
				EndIf

				DrawResized( targetX2, targetY1, targetW2, targetH1, sourceX2, sourceY1, ninePatch.centerDimension.x, ninePatch.borderDimension.GetTop(), frame, False, clipRect, tileMode )

				If ninePatch.borderDimension.GetRight()
					DrawResized( targetX3, targetY1, targetW3, targetH1, sourceX3, sourceY1, ninePatch.borderDimension.GetRight(), ninePatch.borderDimension.GetTop(), frame, False, clipRect )
				EndIf
			EndIf


			'middle
			If ninePatch.borderDimension.GetLeft()
				DrawResized( targetX1 , targetY2, targetW1, targetH2, sourceX1, sourceY2, ninePatch.borderDimension.GetLeft(), ninePatch.centerDimension.y, frame, False, clipRect, tileMode )
			EndIf

			DrawResized( targetX2, targetY2, targetW2, targetH2, sourceX2, sourceY2, ninePatch.centerDimension.x, ninePatch.centerDimension.y, frame, False, clipRect, tileMode )

			If ninePatch.borderDimension.GetRight()
				DrawResized( targetX3, targetY2, targetW3, targetH2, sourceX3, sourceY2, ninePatch.borderDimension.GetRight(), ninePatch.centerDimension.y, frame, False, clipRect, tileMode )
			EndIf


			'bottom
			If ninePatch.borderDimension.GetBottom()
				If ninePatch.borderDimension.GetLeft()
					DrawResized( targetX1, targetY3, targetW1, targetH3, sourceX1, sourceY3, ninePatch.borderDimension.GetLeft(), ninePatch.borderDimension.GetBottom(), frame, False, clipRect )
				EndIf

				DrawResized( targetX2, targetY3, targetW2, targetH3, sourceX2, sourceY3, ninePatch.centerDimension.x, ninePatch.borderDimension.GetBottom(), frame, False, clipRect, tileMode)

				If ninePatch.borderDimension.GetRight()
					DrawResized( targetX3, targetY3, targetW3, targetH3, sourceX3, sourceY3, ninePatch.borderDimension.GetRight(), ninePatch.borderDimension.GetBottom(), frame, False, clipRect )
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
		If offset.x<>0 Or offset.y<>0 Or offset.w<>0 Or offset.h<>0
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

			Local intersectingVP:SRect = clipRect.IntersectSRectXYWH(vpx, vpy, vpw, vph)
			If intersectingVP.w > 0 and intersectingVP.h > 0
				GetGraphicsManager().SetViewport(Int(intersectingVP.x), Int(intersectingVP.y), Int(intersectingVP.w), Int(intersectingVP.h))
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
		Local vpx:Int, vpy:Int, vpw:Int, vph:Int

		If area
			GetGraphicsManager().GetViewport(vpx, vpy, vpw, vph)

			Local intersectingVP:SRect = area.IntersectSRectXYWH(vpx, vpy, vpw, vph)
			if intersectingVP.w < 0 or intersectingVP.h < 0
				Return
			EndIf

			GetGraphicsManager().SetViewport(Int(intersectingVP.x), Int(intersectingVP.y), Int(intersectingVP.w), Int(intersectingVP.h))
		EndIf

		Draw(x, y)

		'reset viewport if it was modified
		If area
			GetGraphicsManager().SetViewport(vpx, vpy, vpw, vph)
		EndIf
	End Method


	Method TileDrawHorizontal(x:Float, y:Float, w:Float, alignment:TVec2D=Null, scale:Float=1.0, theframe:Int=-1)
		If frames <= 0 Then theframe = -1
		Local widthLeft:Float = w
		Local currentX:Float = x
		Local framePos:SVec2I = GetFramePos(theframe)

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


		If ninePatch
			offsetX :- 2 * ninePatch.MARKER_WIDTH
			offsetY :- 2 * ninePatch.MARKER_WIDTH
		EndIf


		If frame = -1 Or framew = 0
			'cast handle-offsets to "int" to avoid subpixel offsets
			'which lead to visual garbage on thin pixel lines in images
			'(they are a little off and therefore have other alpha values)
			If ninePatch
				DrawSubImageRect(parent.GetImage(),..
							 x,..
							 y,..
							 area.GetW() - 2 * ninePatch.MARKER_WIDTH,..
							 area.GetH() - 2 * ninePatch.MARKER_WIDTH,..
							 area.GetX() + ninePatch.MARKER_WIDTH,..
							 area.GetY() + ninePatch.MARKER_WIDTH,..
							 area.GetW() - 2 * ninePatch.MARKER_WIDTH,..
							 area.GetH() - 2 * ninePatch.MARKER_WIDTH,..
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
