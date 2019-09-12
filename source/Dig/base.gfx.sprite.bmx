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


CONST ALIGN_LEFT:FLOAT = 0
CONST ALIGN_CENTER:FLOAT = 0.5
CONST ALIGN_RIGHT:FLOAT = 1.0
CONST ALIGN_TOP:FLOAT = 0
CONST ALIGN_BOTTOM:FLOAT = 1.0

Global ALIGN_LEFT_TOP:TVec2D = new TVec2D
Global ALIGN_CENTER_TOP:TVec2D = new TVec2D.Init(ALIGN_CENTER, ALIGN_TOP)
Global ALIGN_RIGHT_TOP:TVec2D = new TVec2D.Init(ALIGN_RIGHT, ALIGN_TOP)

Global ALIGN_LEFT_CENTER:TVec2D = new TVec2D.Init(ALIGN_LEFT, ALIGN_CENTER)
Global ALIGN_CENTER_CENTER:TVec2D = new TVec2D.Init(ALIGN_CENTER, ALIGN_CENTER)
Global ALIGN_RIGHT_CENTER:TVec2D = new TVec2D.Init(ALIGN_RIGHT, ALIGN_CENTER)

Global ALIGN_LEFT_BOTTOM:TVec2D = new TVec2D.Init(ALIGN_LEFT, ALIGN_BOTTOM)
Global ALIGN_CENTER_BOTTOM:TVec2D = new TVec2D.Init(ALIGN_CENTER, ALIGN_BOTTOM)
Global ALIGN_RIGHT_BOTTOM:TVec2D = new TVec2D.Init(ALIGN_RIGHT, ALIGN_BOTTOM)



Type TSpritePack
	Field image:TImage {nosave}
	Field name:String
	Field sprites:TSprite[]


	Method Init:TSpritePack(image:TImage, name:string)
		self.image = image
		self.name = name
		Return self
	End Method


	Method GetImage:TImage()
		return image
	End Method


	'returns the sprite defined by "spriteName"
	'if no sprite was found, the first in the pack is returned to avoid errors
	Method GetSprite:TSprite(spriteName:String = "")
		spriteName = lower(spriteName)
		For Local i:Int = 0 until sprites.length
			'skip missing or with wrong names
			If not sprites[i] or lower(sprites[i].name) <> spriteName then continue

			Return sprites[i]
		Next
		Return sprites[0]
	End Method


	'returns the sprite from array position
	'if no sprite was found, the first in the pack is returned to avoid errors
	Method GetSpriteByPosition:TSprite(position:int=0)
		if len(sprites) >= position then return sprites[0]
		return sprites[position]
	End Method


	'returns the sprite with a specified id
	'if no sprite was found, the first in the pack is returned to avoid errors
	Method GetSpriteByID:TSprite(id:int=0)
		For Local i:Int = 0 until sprites.length
			'skip missing
			If not sprites[i] then continue
			if sprites[i].id <> id then return sprites[i]
		Next
		Return sprites[0]
	End Method


	Method HasSprite:int(sprite:TSprite)
		For Local i:Int = 0 until sprites.length
			'skip missing
			If not sprites[i] then continue

			if lower(sprites[i].name) = lower(sprite.name) then return TRUE
		Next
		return FALSE
	End Method


	Method AddSprite:int(sprite:TSprite)
		'skip if already added
		if HasSprite(sprite) then return True

		sprite.parent = self
		sprites :+ [sprite]

		return true
	End Method


	'draws the whole spritesheet
	Method Render:int(offsetX:Int, offsetY:Int)
		DrawImage(GetImage(), 0 + offsetX, 0 + offsetY)
	End Method
End Type




Type TSprite
	'defines how many pixels have to get offset from a given position
	Field offset:TRectangle = new TRectangle.Init(0,0,0,0)
	'defines at which pixels of the area the content "starts"
	'or how many pixels from the last row/col the content "ends"
	Field padding:TRectangle = new TRectangle.Init(0,0,0,0)
	Field area:TRectangle = new TRectangle.Init(0,0,0,0)
	'the id is NOT globally unique but a value to make it selectable
	'from a TSpritePack without knowing the name
	Field id:int = 0
	Field name:string
	Field frameW:Int
	Field frameH:Int
	Field frames:Int
	'amount of rotation: 0=none, 90=90°clockwise, -90=90°anti-clockwise
	Field rotated:int = 0
	Field parent:TSpritePack
	Field _pix:TPixmap = null

	Field tileMode:int = 0

	'=== NINE PATCH SECTION ===
	Field ninePatchEnabled:int = FALSE
	'center: size of the middle parts (width, height)
	Field ninePatch_centerDimension:TVec2D
	'border: size of TopLeft,TopRight,BottomLeft,BottomRight
	Field ninePatch_borderDimension:TRectangle
	'content: limits for displaying content
	Field ninePatch_contentBorder:TRectangle
	'the scale of "non-stretchable" borders - rest will scale
	'automatically through bigger dimensions
	Field ninePatch_borderDimensionScale:float = 1.0
	'subtract this amount of pixels on each side for markers
	CONST NINEPATCH_MARKER_WIDTH:int = 1
	CONST BORDER_NONE:int = 0
	CONST BORDER_LEFT:int = 1
	CONST BORDER_RIGHT:int = 2
	CONST BORDER_TOP:int = 4
	CONST BORDER_BOTTOM:int = 8
	CONST BORDER_ALL:int = 1 | 2 | 4 | 8

	CONST TILEMODE_UNDEFINED:int = 0
	CONST TILEMODE_STRETCHED:int = 1
	CONST TILEMODE_TILED:int = 2



	Method Init:TSprite(spritepack:TSpritePack=null, name:String, area:TRectangle, offset:TRectangle, frames:Int = 0, spriteDimension:TVec2D=null, id:int=0)
		self.name = name
		self.area = area.copy()
		self.id = id
		parent = spritepack
		if offset then self.offset = offset.copy()
		frameW = area.GetW()
		frameH = area.GetH()
		self.frames = frames
		If frames > 0
			frameW = ceil(area.GetW() / frames)
			frameH = area.GetH()
		EndIf
		If spriteDimension and spriteDimension.x<>0 and spriteDimension.y<>0
			frameW = spriteDimension.GetX()
			frameH = spriteDimension.GetY()
		EndIf

		Return self
	End Method


	Method InitFromImage:TSprite(img:Timage, spriteName:string, frames:int = 1)
		if not img
			TLogger.Log("TSprite.InitFromImage()", "Image is null. Cannot create ~q"+spriteName+"~q.", LOG_ERROR)
			Throw "TSprite.InitFromImage: Image is null. Cannot create ~q"+spriteName+"~q."
		endif
		'create new spritepack
		local spritepack:TSpritePack = new TSpritePack.init(img, spriteName+"_pack")
		Init(spritepack, spriteName, new TRectangle.Init(0, 0, img.width, img.height), null, frames)
		spritepack.addSprite(self)
		return self
	End Method


	'create a sprite using a dataset containing the needed information
	Method InitFromConfig:TSprite(data:TData)
		if not data then return Null
		local flags:int = data.GetInt("flags", 0)
		local url:string = data.GetString("url", "")
		local name:string = data.GetString("name", "unknownSprite")
		local frames:int = data.GetInt("frames", 0)
		local frameW:int = data.GetInt("frameW", 0)
		local frameH:int = data.GetInt("frameH", 0)
		local id:int = data.GetInt("id", 0)
		local ninePatch:int = data.GetBool("ninePatch", FALSE)
		local definedTileMode:int = data.GetInt("tileMode", TILEMODE_UNDEFINED)
		local parent:TSpritePack = TSpritePack(data.Get("parent", null))

		'create a new spritepack if none is assigned yet
		if parent = null
			if flags & MASKEDIMAGE then SetMaskColor(255,0,255)

			local img:TImage = LoadImage(url, flags)
			if not img
				if not img
					TLogger.Log("TSprite.InitFromConfig()", "Image is null. Cannot create ~q"+name+"~q out of ~q"+url+"~q.", LOG_ERROR)
					Throw "TSprite.InitFromConfig: Image is null. Cannot create ~q"+name+"~q out of ~q"+url+"~q."
				endif
				Throw "image null : "+name + " (url: "+url+" )"
				Return Null
			endif
			'load img to find out celldimensions
			if (frameW = 0 OR frameW = 0)
				if frames > 0
					frameW = ImageWidth(img) / frames
				else
					frameW = ImageWidth(img)
				endif
				frameH = ImageHeight(img)
			endif
			parent = new TSpritePack.Init(img, name + "_pack")

			if flags & MASKEDIMAGE then SetMaskColor(0,0,0)
		endif


		'assign an offset rect if defined so
		local offsetLeft:int = data.GetInt("offsetLeft", 0)
		local offsetRight:int = data.GetInt("offsetRight", 0)
		local offsetTop:int = data.GetInt("offsetTop", 0)
		local offsetBottom:int = data.GetInt("offsetBottom", 0)
		local offset:TRectangle = null
		if offsetLeft <> 0 or offsetRight <> 0 or offsetTop <> 0 or offsetBottom <> 0
			offset = new TRectangle.SetTLBR(offsetTop, offsetLeft, offsetBottom, offsetRight)
		EndIf

		'define the area in the parental spritepack, if no dimension
		'is defined, use the whole parental image
		local area:TRectangle = new TRectangle
		area.position.SetXY(data.GetInt("x", 0), data.GetInt("y", 0))
		area.dimension.SetXY(data.GetInt("w", parent.GetImage().width), data.GetInt("h", parent.GetImage().height))

		'intialize sprite
		Init(parent, name, area, offset, frames, new TVec2D.Init(frameW, frameH), id)

		'rotation
		rotated = data.GetInt("rotated", 0)
		'padding
		SetPadding(new TRectangle.Init(..
			data.GetInt("paddingTop"), ..
			data.GetInt("paddingLeft"), ..
			data.GetInt("paddingBottom"), ..
			data.GetInt("paddingRight") ..
		))

		'recolor/colorize?
		If data.GetInt("r",-1) >= 0 And data.GetInt("g",-1) >= 0 And data.GetInt("b",-1) >= 0
			colorize( TColor.Create(data.GetInt("r"), data.GetInt("g"), data.GetInt("b")) )
		endif


		'enable nine patch if wanted
		if ninePatch then EnableNinePatch()

		tileMode = definedTileMode

		'add to parental spritepack
		parent.addSprite(self)

		return self
	End Method


	'copies a given sprites image to the own area
	Method SetImageContent(img:TImage, color:TColor)
		Local tmppix:TPixmap = LockImage(parent.GetImage(), 0)
			tmppix.Window(int(area.GetX()), int(area.GetY()), int(area.GetW()), int(area.GetH())).ClearPixels(0)
			DrawImageOnImage(ColorizeImageCopy(img, color), tmppix, int(area.GetX()), int(area.GetY()))
		UnlockImage(parent.GetImage(), 0)
	End Method


	Method GetName:String()
		return name
	End Method


	Method SetPadding:int(padding:TRectangle)
		self.padding = padding
	End Method


	Method IsNinePatchEnabled:int()
		return ninePatchEnabled
	End Method


	Method EnableNinePatch:int()
		'read markers in the image to get border and content sizes
		ninePatch_borderDimension = ReadNinePatchMarker(0)
		ninePatch_contentBorder = ReadNinePatchMarker(1)

		If ninePatch_borderDimension.GetLeft() = 0 and ninePatch_borderDimension.GetRight() = 0 and ninePatch_borderDimension.GetTop() = 0 and ninePatch_borderDimension.GetBottom() = 0
			If ninePatch_contentBorder.GetLeft() = 0 and ninePatch_contentBorder.GetRight() = 0 and ninePatch_contentBorder.GetTop() = 0 and ninePatch_contentBorder.GetBottom() = 0
				ninePatchEnabled = FALSE
				return FALSE
			endif
		Endif

		'center has to consider the marker_width (content dimension marker)
		ninePatch_centerDimension = new TVec2D.Init(..
					area.GetW() - (2* NINEPATCH_MARKER_WIDTH + ninePatch_borderDimension.GetLeft() + ninePatch_borderDimension.GetRight()), ..
					area.GetH() - (2* NINEPATCH_MARKER_WIDTH + ninePatch_borderDimension.GetTop() + ninePatch_borderDimension.GetBottom()) ..
				  )

		ninePatchEnabled = true

		return TRUE
	End Method


	Method GetNinePatchBorderDimension:TRectangle()
		if not ninePatch_borderDimension then ninePatch_borderDimension = new TRectangle.Init(0,0,0,0)
		return ninePatch_borderDimension
	End Method


	Method GetNinePatchContentBorder:TRectangle()
		if not ninePatch_contentBorder then ninePatch_contentBorder = new TRectangle.Init(0,0,0,0)
		return ninePatch_contentBorder
	End Method


	'read ninepatch markers out of the sprites image data
	'mode = 0: sprite borders
	'mode = 1: content borders
	Method ReadNinePatchMarker:TRectangle(mode:int=0)
		if not _pix then _pix = GetPixmap()
		Local sourcepixel:Int
		local sourceW:int = _pix.width
		local sourceH:int = _pix.height
		local result:TRectangle = new TRectangle.init(0,0,0,0)
		local markerRow:int=0, markerCol:int=0, skipLines:int=0

		'do not check if there is no space for markers
		if sourceW <= 0 or sourceH <= 0 then return result

		'content is defined at the last pixmap row/col
		if mode = 1
			markerCol = sourceH - NINEPATCH_MARKER_WIDTH
			markerRow = sourceW - NINEPATCH_MARKER_WIDTH
			skipLines = 1
		endif

		'  °= L ====== R = °			ROW ROW ROW ROW
		'  T               T		COL
		'  |               |		COL
		'  B               B		COL
		'  °= L ====== R = °		COL

		local minVal:int = 0, maxVal:int = 0

		'find left border: from 1 to first non-transparent pixel in row 0
		minVal = NINEPATCH_MARKER_WIDTH
		maxVal = sourceW - NINEPATCH_MARKER_WIDTH
		For Local i:Int = minVal Until maxVal
			if ARGB_Alpha(ReadPixel(_pix, i, markerCol)) > 0 then result.SetLeft(i - minVal);exit
		Next

		'find right border: from left border the first non opaque pixel in row 0
		minVal = NINEPATCH_MARKER_WIDTH + result.GetLeft()
		'same maxVal as left border
		For Local i:Int = minVal Until maxVal
			if ARGB_Alpha(ReadPixel(_pix, i, markerCol)) = 0 then result.SetRight(maxVal - i);exit
		Next


		'find top border: from 1 to first opaque pixel in col 0
		minVal = NINEPATCH_MARKER_WIDTH
		maxVal = sourceH - NINEPATCH_MARKER_WIDTH
		For Local i:Int = minVal Until maxVal
			if ARGB_Alpha(ReadPixel(_pix, markerRow, i)) > 0 then result.SetTop(i - minVal);exit
		Next

		'find bottom border: from top border the first non opaque pixel in col 0
		minVal = NINEPATCH_MARKER_WIDTH + result.GetTop()
		'same maxVal as top border
		For Local i:Int = minVal To maxVal
			if ARGB_Alpha(ReadPixel(_pix, markerRow, i)) = 0 then result.SetBottom(maxVal - i);exit
		Next

		Return result
	End Method


	'returns the image of this sprite (reference, no copy)
	'if the frame is 0+, only this frame is returned
	'if includeBorder is TRUE, then an potential ninePatchBorder will be
	'included
	Method GetImage:TImage(frame:int=-1, includeBorder:int=FALSE)
		'if a frame is requested, just return it (no need for "animated" check)
		if frame >=0 then return GetFrameImage(frame)

		Local DestPixmap:TPixmap
		if includeBorder
			DestPixmap = LockImage(parent.GetImage(), 0, False, True).Window(int(area.GetX()), int(area.GetY()), int(area.GetW()), int(area.GetH()))
		else
			local border:TRectangle = GetNinePatchBorderDimension()
			DestPixmap = LockImage(parent.GetImage(), 0, False, True).Window(int(area.GetX()+ border.GetLeft()), int(area.GetY() + border.GetTop()), int(area.GetW() - border.GetLeft() - border.GetRight()), int(area.GetH() - border.GetTop() - border.GetBottom()))
		endif

		UnlockImage(parent.GetImage())

		Return TImage.Load(DestPixmap, 0, 255, 0, 255)
	End Method


	Method GetFrameImage:TImage(frame:Int=0)
		'give back whole image if no frames are configured
		if frames <= 0 then frame = 0
		Local DestPixmap:TPixmap = LockImage(parent.GetImage(), 0, False, True).Window(int(area.GetX() + frame * framew), int(area.GetY()), framew, int(area.GetH()))

		Return TImage.Load(DestPixmap, 0, 255, 0, 255)
	End Method


	'return the pixmap of the sprite' image (reference, no copy)
	Method GetPixmap:TPixmap(frame:Int=-1)
		'give back whole image if no frames are configured
		if frames <= 0 then frame = -1

		if not parent.GetImage() then Throw "TSprite.GetPixmap() failed: invalid parent.GetImage()"

		Local DestPixmap:TPixmap
		if frame >= 0
			DestPixmap = LockImage(parent.GetImage(), 0, False, True).Window(int(area.GetX() + frame * framew), int(area.GetY()), framew, int(area.GetH()))
		Else
			DestPixmap = LockImage(parent.GetImage(), 0, False, True).Window(int(area.GetX()), int(area.GetY()), int(area.GetW()), int(area.GetH()))
		EndIf

		return DestPixmap
	End Method


	'creates a REAL copy (no reference) of an image
	Method GetImageCopy:TImage(loadAnimated:int = 1)
		SetMaskColor(255,0,255)
		If self.frames >1 And loadAnimated
			Return LoadAnimImage(GetPixmap().copy(), frameW, frameH, 0, frames)
		Else
			Return LoadImage(GetPixmap().copy())
		EndIf
	End Method


	Method GetColorizedImage:TImage(color:TColor, frame:int=-1, colorizeMode:int=0)
		return ColorizeImageCopy(GetImage(frame), color, 0,0,0, 1,0, colorizeMode)
	End Method


	'removes the part of the sprite packs image occupied by the sprite
	Method ClearImageData()
		Local tmppix:TPixmap = LockImage(parent.GetImage(), 0)
		tmppix.Window(int(area.GetX()), int(area.GetY()), int(area.GetW()), int(area.GetH())).ClearPixels(0)
	End Method


	Method GetMinWidth:int(includeOffset:int=TRUE)
		if ninePatchEnabled
			return ninePatch_borderDimension.GetLeft() + ninePatch_borderDimension.GetRight()
		else
			return GetWidth(includeOffset)
		endif
	End Method


	Method GetWidth:int(includeOffset:int=TRUE)
		'substract 2 pixels (left and right) ?
		local ninePatchPixels:int = 0
		if ninePatchEnabled then ninePatchPixels = 2

		'todo: advanced calculation
		if rotated = 90 or rotated = -90
			if includeOffset
				return area.GetH() - (offset.GetTop() + offset.GetBottom()) - (padding.GetTop() + padding.GetBottom()) - ninePatchPixels
			else
				return area.GetH() - (padding.GetTop() + padding.GetBottom()) - ninePatchPixels
			endif
		else
			if includeOffset
				return area.GetW() - (offset.GetLeft() + offset.GetRight()) - (padding.GetLeft() + padding.GetRight()) - ninePatchPixels
			else
				return area.GetW() - (padding.GetLeft() + padding.GetRight()) - ninePatchPixels
			endif
		endif
	End Method


	Method GetMinHeight:int(includeOffset:int=TRUE)
		if ninePatchEnabled
			return ninePatch_borderDimension.GetTop() + ninePatch_borderDimension.GetBottom()
		else
			return GetHeight(includeOffset)
		endif
	End Method


	Method GetHeight:int(includeOffset:int=TRUE)
		'substract 2 pixles (left and right) ?
		local ninePatchPixels:int = 0
		if ninePatchEnabled then ninePatchPixels = 2

		'todo: advanced calculation
		if rotated = 90 or rotated = -90
			if includeOffset
				return area.GetW() - (offset.GetLeft() + offset.GetRight()) - (padding.GetLeft() + padding.GetRight()) - ninePatchPixels
			else
				return area.GetW() - (padding.GetLeft() + padding.GetRight()) - ninePatchPixels
			endif
		else
			if includeOffset
				return area.GetH() - (offset.GetTop() + offset.GetBottom()) - (padding.GetTop() + padding.GetBottom()) - ninePatchPixels
			else
				return area.GetH() - (padding.GetTop() + padding.GetBottom()) - ninePatchPixels
			endif
		endif
	End Method


	Method GetFramePos:TVec2D(frame:int=-1)
		If frame < 0 then return new TVec2D.Init(0,0)

		Local MaxFramesInCol:Int = Ceil(area.GetW() / framew)
		Local framerow:Int = Ceil(frame / Max(1,MaxFramesInCol))
		Local framecol:Int = frame - (framerow * MaxFramesInCol)
		return new TVec2D.Init(framecol * frameW, framerow * frameH)
	End Method


	'let spritePack colorize the sprite
	Method Colorize(color:TColor)
		'store backup
		'(we clean image data before pasting colorized output)
		local newImg:TImage = ColorizeImageCopy(GetImage(), color)
		'remove old image part
		ClearImageData()
		'draw now colorized image on the parent image
		DrawImageOnImage(newImg, parent.GetImage(), int(area.GetX()), int(area.GetY()))
	End Method


	Method PixelIsOpaque:int(x:int, y:int)
		If x < 0 or y < 0 or x > frameW or y > frameH
			print "out of bounds: "+x+", "+y
			return False
		Endif

		If not _pix
			_pix = LockImage(GetImage())
			'UnlockImage(parent.image) 'unlockimage does nothing in blitzmax (1.48)
		EndIf

		return ARGB_Alpha(ReadPixel(_pix, x,y))
	End Method


	'draw the sprite onto a given image or pixmap
	Method DrawOnImage(imageOrPixmap:object, x:int, y:int, frame:int = -1, alignment:TVec2D=null, modifyColor:TColor=null)
		if frames <= 0 then frame = -1

		if not alignment then alignment = ALIGN_LEFT_TOP
		if frame >= 0
			x :- alignment.GetX() * framew
			y :- alignment.GetY() * frameh
		else
			x :- alignment.GetX() * area.GetW()
			y :- alignment.GetY() * area.GetH()
		endif

		DrawImageOnImage(getPixmap(frame), imageOrPixmap, int(x + offset.GetLeft()), int(y + offset.GetTop()), modifyColor)
	End Method


	'draw the sprite covering an area (if ninePatch is enabled, the
	'stretching is only done on the center of the sprite)
	Method DrawArea:int(x:float, y:float, width:float=-1, height:float=-1, frame:int=-1, skipBorders:int = 0, clipRect:TRectangle = null, forceTileMode:int = 0)
		if width=-1 then width = area.GetW()
		if height=-1 then height = area.GetH()
		if frames <= 0 then frame = -1

		'nothing to draw?
		if width <= 0 or height <= 0 then return False

		'normal sprites draw their image stretched to area
		if not ninePatchEnabled
			DrawResized(new TRectangle.Init(x, y, width, height), null, frame, False, null, tileMode)
		else
			Local middleW:int = area.GetW() - ninePatch_borderDimensionScale*(ninePatch_borderDimension.GetLeft()+ninePatch_borderDimension.GetRight())
			Local middleH:int = area.GetH() - ninePatch_borderDimensionScale*(ninePatch_borderDimension.GetTop()+ninePatch_borderDimension.GetBottom())

			'minimal dimension has to be same or bigger than all 4 borders + 0.1* the stretch portion
			'if borders are disabled, ignore them in minWidth-calculation
			width = Max(width, Max(0.2*middleW, 2) + ninePatch_borderDimensionScale*((1-(skipBorders & BORDER_LEFT)>0)*ninePatch_borderDimension.GetLeft() + (1-(skipBorders & BORDER_RIGHT)>0)*ninePatch_borderDimension.GetRight()))
			height = Max(height, Max(0.2*middleH, 2) + ninePatch_borderDimensionScale*((1-(skipBorders & BORDER_TOP)>0) * ninePatch_borderDimension.GetTop() + (1-(skipBorders & BORDER_BOTTOM)>0)*ninePatch_borderDimension.GetBottom()))

			'dimensions of the stretch-parts (the middle elements)
			'adjusted by a potential border scale
			Local stretchDestW:float = width - ninePatch_borderDimensionScale*(ninePatch_borderDimension.GetLeft()+ninePatch_borderDimension.GetRight())
			Local stretchDestH:float = height - ninePatch_borderDimensionScale*(ninePatch_borderDimension.GetTop()+ninePatch_borderDimension.GetBottom())
			local target:TRectangle = new TRectangle
			local source:TRectangle = new TRectangle
			local borderSize:TRectangle = new TRectangle.CopyFrom(ninePatch_borderDimension)

			if skipBorders <> 0
				'disable the borders by setting their size to 0
				if skipBorders & BORDER_LEFT > 0
					stretchDestW :+ borderSize.GetLeft() * ninePatch_borderDimensionScale
					borderSize.SetLeft(0)
				endif
				if skipBorders & BORDER_RIGHT > 0
					stretchDestW :+ borderSize.GetRight() * ninePatch_borderDimensionScale
					borderSize.SetRight(0)
				endif
				if skipBorders & BORDER_TOP > 0
					stretchDestH :+ borderSize.GetTop() * ninePatch_borderDimensionScale
					borderSize.SetTop(0)
				endif
				if skipBorders & BORDER_BOTTOM > 0
					stretchDestH :+ borderSize.GetBottom() * ninePatch_borderDimensionScale
					borderSize.SetBottom(0)
				endif
			endif


			'prepare render coordinates
			local targetX1:int = x
			local targetX2:int = targetX1 + borderSize.GetLeft() * ninePatch_borderDimensionScale
			local targetX3:int = targetX2 + stretchDestW
			local targetY1:int = y
			local targetY2:int = targetY1 + borderSize.GetTop() * ninePatch_borderDimensionScale
			local targetY3:int = targetY2 + stretchDestH
			local targetW1:int = borderSize.GetLeft() * ninePatch_borderDimensionScale
			local targetW2:int = stretchDestW
			local targetW3:int = borderSize.GetRight() * ninePatch_borderDimensionScale
			local targetH1:int = borderSize.GetTop() * ninePatch_borderDimensionScale
			local targetH2:int = stretchDestH
			local targetH3:int = borderSize.GetBottom() * ninePatch_borderDimensionScale

			local sourceX1:int = NINEPATCH_MARKER_WIDTH
			local sourceX2:int = sourceX1 + ninePatch_borderDimension.GetLeft()
			local sourceX3:int = sourceX2 + ninePatch_centerDimension.GetX()
			local sourceY1:int = NINEPATCH_MARKER_WIDTH
			local sourceY2:int = sourceY1 + ninePatch_borderDimension.GetTop()
			local sourceY3:int = sourceY2 + ninePatch_centerDimension.GetY()

			local vpRect:TRectangle
			if clipRect
				local vpx:int, vpy:int, vpw:int, vph:int
				GetGraphicsManager().GetViewPort(vpx, vpy, vpw, vph)
				vpRect = New TRectangle.Init(vpx, vpy, vpw, vph)
				local intersectingVP:TRectangle = vpRect.Copy().Intersect(clipRect)
				GetGraphicsManager().SetViewPort(int(intersectingVP.GetX()), int(intersectingVP.GetY()), int(intersectingVP.GetW()), int(intersectingVP.GetH()))
			endif

			'render
			'top
			if ninePatch_borderDimension.GetTop()
				If ninePatch_borderDimension.GetLeft()
					target.Init( targetX1, targetY1, targetW1, targetH1 )
					source.Init( sourceX1, sourceY1, ninePatch_borderDimension.GetLeft(), ninePatch_borderDimension.GetTop() )
					DrawResized( target, source, frame, false, clipRect )
				endif

				target.Init( targetX2, targetY1, targetW2, targetH1 )
				source.Init( sourceX2, sourceY1, ninePatch_centerDimension.GetX(), ninePatch_borderDimension.GetTop() )
				DrawResized( target, source, frame, false, clipRect, tileMode )

				If ninePatch_borderDimension.GetRight()
					target.Init( targetX3, targetY1, targetW3, targetH1 )
					source.Init( sourceX3, sourceY1, ninePatch_borderDimension.GetRight(), ninePatch_borderDimension.GetTop() )
					DrawResized( target, source, frame, false, clipRect )
				endif
			endif


			'middle
			If ninePatch_borderDimension.GetLeft()
				target.Init( targetX1 , targetY2, targetW1, targetH2 )
				source.Init( sourceX1, sourceY2, ninePatch_borderDimension.GetLeft(), ninePatch_centerDimension.GetY() )
				DrawResized( target, source, frame, false, clipRect, tileMode )
			endif

			target.Init( targetX2, targetY2, targetW2, targetH2 )
			source.Init( sourceX2, sourceY2, ninePatch_centerDimension.GetX(), ninePatch_centerDimension.GetY() )
			DrawResized( target, source, frame, false, clipRect, tileMode )

			If ninePatch_borderDimension.GetRight()
				target.Init( targetX3, targetY2, targetW3, targetH2 )
				source.Init( sourceX3, sourceY2, ninePatch_borderDimension.GetRight(), ninePatch_centerDimension.GetY() )
				DrawResized( target, source, frame, false, clipRect, tileMode )
			endif


			'bottom
			if ninePatch_borderDimension.GetBottom()
				If ninePatch_borderDimension.GetLeft()
					target.Init( targetX1, targetY3, targetW1, targetH3 )
					source.Init( sourceX1, sourceY3, ninePatch_borderDimension.GetLeft(), ninePatch_borderDimension.GetBottom() )
					DrawResized( target, source, frame, false, clipRect )
				endif

				target.Init( targetX2, targetY3, targetW2, targetH3 )
				source.Init( sourceX2, sourceY3, ninePatch_centerDimension.GetX(), ninePatch_borderDimension.GetBottom() )
				DrawResized( target, source, frame, false, clipRect, tileMode)

				If ninePatch_borderDimension.GetRight()
					target.Init( targetX3, targetY3, targetW3, targetH3 )
					source.Init( sourceX3, sourceY3, ninePatch_borderDimension.GetRight(), ninePatch_borderDimension.GetBottom() )
					DrawResized( target, source, frame, false, clipRect )
				endif
			endif

			'reset viewport if it was modified
			if vpRect
				GetGraphicsManager().SetViewport(int(vpRect.GetX()), int(vpRect.GetY()), int(vpRect.GetW()), int(vpRect.GetH()))
			endif
		endif
	End Method


	'draw the sprite resized/stretched
	'source is a rectangle within sprite.area
	Method DrawResized(target:TRectangle, source:TRectangle = null, frame:int=-1, drawCompleteImage:Int=FALSE, clipRect:TRectangle = null, forceTileMode:int = 0)
		'needed as "target" is a reference (changes original variable)
		local targetCopy:TRectangle = target.Copy()
		local sourceCopy:TRectangle
		if source
			sourceCopy = source.Copy()
		else
			sourceCopy = new TRectangle
		endif

		if frames <= 0 then frame = -1
		if drawCompleteImage then frame = -1

		'we got a frame request - try to find it
		'calculate WHERE the frame is positioned in spritepack
		if frame >= 0 and frameW > 0 and frameH > 0
			Local MaxFramesInCol:Int = floor(area.GetW() / framew)
			local frameInRow:int = floor(frame / MaxFramesInCol)	'0based
			local frameInCol:int = frame mod MaxFramesInCol			'0based
			'move the source rect accordingly
			sourceCopy.position.SetXY(frameInCol*frameW, frameinRow*frameH)

			'if no source dimension was given - use frame dimension
			if sourceCopy.GetW() <= 0 then sourceCopy.dimension.setX(frameW)
			if sourceCopy.GetH() <= 0 then sourceCopy.dimension.setY(frameH)
		else
			'if no source dimension was given - use image dimension
			if sourceCopy.GetW() <= 0 then sourceCopy.dimension.setX(area.GetW())
			if sourceCopy.GetH() <= 0 then sourceCopy.dimension.setY(area.GetH())
		endif

		'receive source rect so it stays within the sprite's limits
		sourceCopy.dimension.SetX(Min(area.GetW(), sourceCopy.GetW()))
		sourceCopy.dimension.SetY(Min(area.GetH(), sourceCopy.GetH()))

		'if no target dimension was given - use source dimension
		if targetCopy.GetW() <= 0 then targetCopy.dimension.SetX(sourceCopy.GetW())
		if targetCopy.GetH() <= 0 then targetCopy.dimension.SetY(sourceCopy.GetH())


		'take care of offsets
		if offset and (offset.position.x<>0 or offset.position.y<>0 or offset.dimension.x<>0 or offset.dimension.y<>0)
			'top and left border also modify position to draw
			'starting at the top border - so include that offset
			if sourceCopy.GetY() = 0
				targetCopy.position.AddY(-offset.GetTop())
				targetCopy.dimension.AddY(offset.GetTop())
				sourceCopy.dimension.AddY(offset.GetTop())
			else
				sourceCopy.position.AddY(offset.GetTop())
			endif
			if sourceCopy.GetX() = 0
				targetCopy.position.AddX(-offset.GetLeft())
				targetCopy.dimension.AddX(offset.GetLeft())
				sourceCopy.dimension.AddX(offset.GetLeft())
			else
				sourceCopy.position.AddX(offset.GetLeft())
			endif

			'hitting bottom border - draw bottom offset
			if (sourceCopy.GetY() + sourceCopy.GetH()) >= (area.GetH() - offset.GetBottom())
				sourceCopy.dimension.AddY(offset.GetBottom())
				targetCopy.dimension.AddY(offset.GetBottom())
			endif
			'hitting right border - draw right offset
'			if (sourceCopy.GetX() + sourceCopy.GetW()) >= (area.GetW() - offset.GetRight())
'				sourceCopy.dimension.MoveX(offset.GetRight())
'			endif
		endif

		if clipRect
			'check if render area is outside of clipping area
			If not clipRect.Intersects(targetCopy) then return


			'limit viewport to intersection of current VP and clipping area
			local vpx:int, vpy:int, vpw:int, vph:int
			GetGraphicsManager().GetViewPort(vpx, vpy, vpw, vph)
			local vpRect:TRectangle = New TRectangle.Init(vpx, vpy, vpw, vph)
			local intersectingVP:TRectangle = vpRect.Copy().Intersect(clipRect)
			GetGraphicsManager().SetViewPort(int(intersectingVP.GetX()), int(intersectingVP.GetY()), int(intersectingVP.GetW()), int(intersectingVP.GetH()))
				if forceTileMode = TILEMODE_UNDEFINED then forceTileMode = tileMode

				if forceTileMode = TILEMODE_UNDEFINED or forceTileMode = TILEMODE_STRETCHED
					DrawSubImageRect(parent.GetImage(), Float(floor(targetCopy.GetX())), Float(floor(targetCopy.GetY())), Float(ceil(targetCopy.GetW())), Float(ceil(targetCopy.GetH())), Float(area.GetX() + sourceCopy.GetX()), Float(area.GetY() + sourceCopy.GetY()), sourceCopy.GetW(), sourceCopy.GetH())
				elseif forceTileMode = TILEMODE_TILED
					local startX:int = int(floor(targetCopy.GetX()))
					local startY:int = int(floor(targetCopy.GetY()))
					local w:int = int(ceil(targetCopy.GetW()))
					local h:int = int(ceil(targetCopy.GetH()))

					local x:int = 0
					while x <= w '- sourceCopy.GetIntW()
						local y:int = 0
						local maxW:int = Min(sourceCopy.GetW(), w - x)
						while y <= h - sourceCopy.GetIntH()
							local maxH:int = Min(sourceCopy.GetH(), h - y)
							DrawSubImageRect(parent.GetImage(), Float(startX + x), Float(startY + y), maxW, maxH, Float(area.GetX() + sourceCopy.GetX()), Float(area.GetY() + sourceCopy.GetY()), maxW, maxH)
							y :+ sourceCopy.GetIntH()
						wend
						x :+ sourceCopy.GetIntW()
					wend
				endif
			GetGraphicsManager().SetViewPort(vpx, vpy, vpw, vph)


rem
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
		else
			if tileMode = 0 'stretched
				DrawSubImageRect(parent.GetImage(), Float(floor(targetCopy.GetX())), Float(floor(targetCopy.GetY())), Float(ceil(targetCopy.GetW())), Float(ceil(targetCopy.GetH())), Float(area.GetX() + sourceCopy.GetX()), Float(area.GetY() + sourceCopy.GetY()), sourceCopy.GetW(), sourceCopy.GetH())
			elseif tileMode = 1 'tiled

				local startX:int = int(floor(targetCopy.GetX()))
				local startY:int = int(floor(targetCopy.GetY()))
				local w:int = int(ceil(targetCopy.GetW()))
				local h:int = int(ceil(targetCopy.GetH()))

				local x:int = 0
				while x <= w '- sourceCopy.GetIntW()
					local y:int = 0
					local maxW:int = Min(sourceCopy.GetW(), w - x)
					while y <= h '- sourceCopy.GetIntH()
						local maxH:int = Min(sourceCopy.GetH(), h - y)
						DrawSubImageRect(parent.GetImage(), Float(startX + x), Float(startY + y), maxW, maxH, Float(area.GetX() + sourceCopy.GetX()), Float(area.GetY() + sourceCopy.GetY()), maxW, maxH)
						y :+ sourceCopy.GetIntH()
					wend
					x :+ sourceCopy.GetIntW()
				wend
			endif
			'TODO: for "target = image" use DrawImageOnImage() and stretch
			'via "ResizePixmap()"
		endif
	End Method


	Method DrawClipped(target:TRectangle, offset:TVec2D = null, frame:int=-1)
		if not offset then offset = new TVec2D
		DrawResized(new TRectangle.Init(target.GetX(),target.GetY()), new TRectangle.Init(offset.GetX(), offset.GetY(), target.GetW(), target.GetH()), frame)
	End Method


	Method DrawInArea(x:Float, y:Float, area:TRectangle = null, frame:int=-1)
		local vpRect:TRectangle

		if area
			local vpx:int, vpy:int, vpw:int, vph:int
			GetGraphicsManager().GetViewPort(vpx, vpy, vpw, vph)
			vpRect = New TRectangle.Init(vpx, vpy, vpw, vph)
			local intersectingVP:TRectangle = vpRect.Copy().Intersect(area)
			GetGraphicsManager().SetViewPort(int(intersectingVP.GetX()), int(intersectingVP.GetY()), int(intersectingVP.GetW()), int(intersectingVP.GetH()))
		endif

		Draw(x, y)

		'reset viewport if it was modified
		if vpRect
			GetGraphicsManager().SetViewport(int(vpRect.GetX()), int(vpRect.GetY()), int(vpRect.GetW()), int(vpRect.GetH()))
		endif
	End Method


	Method TileDrawHorizontal(x:float, y:float, w:float, alignment:TVec2D=null, scale:float=1.0, theframe:int=-1)
		if frames <= 0 then theframe = -1
		local widthLeft:float = w
		local currentX:float = x
		local framePos:TVec2D = getFramePos(theframe)

		local alignX:Float = 0.0
		local alignY:Float = 0.0

		if alignment
			alignX = alignment.x
			alignY = alignment.y
		endif

		'add offset
		currentX :- offset.GetLeft() * scale

		local offsetX:int = int(alignX * area.GetW())
		local offsetY:int = int(alignY * area.GetH())


		While widthLeft > 0
			local widthPart:float = Min(frameW, widthLeft) 'draw part of sprite or whole ?
			DrawSubImageRect( parent.GetImage(), currentX + offsetX, y - offsetY, widthPart, area.GetH(), area.GetX() + framePos.x, area.GetY() + framePos.y, widthPart, frameH, 0 )
			currentX :+ widthPart * scale
			widthLeft :- widthPart * scale
		Wend
	End Method


	Method TileDrawVertical(x:float, y:float, h:float, alignment:TVec2D=null, scale:float=1.0)
		local heightLeft:float = h
		local currentY:float = y
		while heightLeft >= 1
			local heightPart:float = Min(area.GetH(), heightLeft) 'draw part of sprite or whole ?
			DrawSubImageRect( parent.GetImage(), x + offset.GetLeft(), currentY + offset.GetTop(), area.GetW(), Float(Ceil(heightPart)), area.GetX(), area.GetY(), area.GetW(), Float(Ceil(heightPart)) )
			currentY :+ floor(heightPart * scale)
			heightLeft :- (heightPart * scale)
		Wend
	End Method


	Method TileDraw(x:Float, y:Float, w:Int, h:Int, scale:float=1.0)
		local heightLeft:float = floor(h)
		local currentY:float = y
		while heightLeft >= 1
			local heightPart:float = Min(area.GetH(), heightLeft) 'draw part of sprite or whole ?
			local widthLeft:float = w
			local currentX:float = x
			while widthLeft > 0
				local widthPart:float = Min(area.GetW(), widthLeft) 'draw part of sprite or whole ?
				DrawSubImageRect( parent.GetImage(), currentX + offset.GetLeft(), currentY + offset.GetTop(), Float(Ceil(widthPart)), Float(Ceil(heightPart)), self.area.GetX(), self.area.GetY(), Float(Ceil(widthPart)), Float(Ceil(heightPart)) )
				currentX :+ floor(widthPart * scale)
				widthLeft :- (widthPart * scale)
			Wend
			currentY :+ floor(heightPart * scale)
			heightLeft :- (heightPart * scale)
		Wend
	End Method


	Method Draw(x:Float, y:Float, frame:Int=-1, alignment:TVec2D=null, scale:float=1.0, drawCompleteImage:Int=FALSE)
		if frames <= 0 then frame = -1
		if drawCompleteImage then frame = -1

		rem
			ALIGNMENT IS POSITION OF HANDLE !!

			   TOPLEFT        TOPRIGHT
			           .----.
			           |    |
			           '----'
			BOTTOMLEFT        BOTTOMRIGHT
		endrem

		local alignX:Float = 0.0
		local alignY:Float = 0.0

		if alignment
			alignX = alignment.x
			alignY = alignment.y
		endif

		'add offset
		x:- offset.GetLeft() * scale
		Y:- offset.GetTop() * scale
'		x:- offset.GetRight() * scale
'		Y:- offset.GetBottom() * scale


		local offsetX:int = int(alignX * area.GetW())
		local offsetY:int = int(alignY * area.GetH())

		'for a correct rotation calculation
		if scale <> 1.0 then SetScale(scale, scale)
		if rotated
			SetRotation(-rotated)
			if rotated = 90
				offsetX = -int((alignY-1) * area.GetW())
				offsetY =  int( alignX    * area.GetH())
			elseif rotated = -90
				offsetX = int((1-alignY) * area.GetW())
				offsetY = int((1-alignX) * area.GetH())
			endif
		endif


		if ninePatchEnabled
			offsetX :- 2 * NINEPATCH_MARKER_WIDTH
			offsetY :- 2 * NINEPATCH_MARKER_WIDTH
		endif


		If frame = -1 Or framew = 0
			'cast handle-offsets to "int" to avoid subpixel offsets
			'which lead to visual garbage on thin pixel lines in images
			'(they are a little off and therefore have other alpha values)
			if ninePatchEnabled
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
			else
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
			endif
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
							 int(alignX * frameW), ..
							 int(alignY * frameH), ..
							 0)
		EndIf

		if scale <> 1.0 then SetScale(1.0, 1.0)
		if rotated <> 0 then SetRotation(0)
	End Method
End Type