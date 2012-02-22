'Sprite-Classes
superstrict

Import BRL.Max2D
Import BRL.Random
Import brl.reflection
'Import "basefunctions.bmx"
Import "basefunctions_xml.bmx"
Import "basefunctions_loadsave.bmx"
Import "basefunctions_image.bmx"
Import "basefunctions_asset.bmx"

Type TRenderManager
	field list:TList = CreateList()

	Function Create:TRenderManager()
		local obj:TRenderManager = new TRenderManager
		return obj
	End Function

	Method Render()
		For local obj:TRenderable = eachin self.list
			'obj.Draw()
		Next
	end Method
End Type

Type TRenderable extends TAsset
	field pos:TPosition = TPosition.Create(0,0)
'	field renderParams:object[]

'	Method DrawInPipeline() abstract
End Type


Type TGW_SpritePack extends TRenderable
	Field image:TImage
	Field sprites:TList = CreateList()
	Field LastSpriteID:Int = 0

	Function Create:TGW_SpritePack(image:TImage, name:string)
		Local Obj:TGW_SpritePack = New TGW_SpritePack
		Obj.image = image
		'asset
		Obj.setName(name)
		Obj.setUrl("NONE")
		Obj.setType("SPRITEPACK")

		Return Obj
	End Function

	Method GetSpriteImage:TImage(spritename:String = "", SpriteID:Int = -1, loadAnimated:Int =1)
		Local tmpObj:TGW_Sprites
		If spritename <> ""
			tmpObj = GetSprite(spritename)
		Else
			tmpObj = GetSpriteByID(SpriteID)
		EndIf
		Local DestPixmap:TPixmap = LockImage(image, 0, False, True).Window(tmpObj.Pos.x, tmpObj.Pos.y, tmpObj.w, tmpObj.h)
		UnlockImage(image)
		GCCollect() '<- FIX!
		If tmpObj.animcount >1 And loadAnimated
			Return TImage.LoadAnim(DestPixmap, tmpObj.framew, tmpObj.frameh, 0, tmpObj.animcount, 0, 255, 0, 255)
		Else
			Return TImage.Load(DestPixmap, 0, 255, 0, 255)
		End If
	End Method

	Method GetSpriteFrameImage:TImage(spritename:String = "", SpriteID:Int = -1, framenr:Int = 0)
		Local tmpObj:TGW_Sprites
		If spritename <> ""
			tmpObj = GetSprite(spritename)
		Else
			tmpObj = GetSpriteByID(SpriteID)
		EndIf
		Local DestPixmap:TPixmap = LockImage(image, 0, False, True).Window(tmpObj.Pos.x + framenr * tmpObj.framew, tmpObj.Pos.y, tmpObj.framew, tmpObj.h)
		UnlockImage(image)
		GCCollect() '<- FIX!
		Return TImage.Load(DestPixmap, 0, 255, 0, 255)
	End Method

	Method GetSprite:TGW_Sprites(spritename:String = "")
		For Local i:Int = 0 To Self.sprites.Count() - 1
			If lower(TGW_Sprites(Self.sprites.ValueAtIndex(i)).spritename) = lower(spritename) Then Return TGW_Sprites(Self.sprites.ValueAtIndex(i))
		Next
		Return TGW_Sprites(Self.sprites.ValueAtIndex(0))
	End Method

	Method GetSpriteByID:TGW_Sprites(SpriteID:Int = 0)
		For Local i:Int = 0 To Self.sprites.Count() - 1
			If TGW_Sprites(Self.sprites.ValueAtIndex(i)).SpriteID = SpriteID Then Return TGW_Sprites(Self.sprites.ValueAtIndex(i))
		Next
		Return TGW_Sprites(Self.sprites.ValueAtIndex(0))
	End Method

	Method AddSprite:TGW_Sprites(spritename:String, posx:Float, posy:Float, w:Int, h:Int, animcount:int = 0, SpriteID:Int = -1)
		Local sID:Int = SpriteID
		If SpriteID < 0 Then LastSpriteID:+1;SpriteID = LastSpriteID;
		local sprite:TGW_Sprites = TGW_Sprites.Create(Self, spritename, posx, posy, w, h, animcount, SpriteID)
		Self.sprites.AddLast(sprite)
		return sprite
	End Method

	Method AddAnimSpriteMultiCol(spritename:String, posx:Float, posy:Float, w:Int, h:Int, spritew:Int, spriteh:Int, animcount:Int, SpriteID:Int = -1)
		Local sID:Int = SpriteID
		If SpriteID < 0 Then LastSpriteID:+1;SpriteID = LastSpriteID;
		Self.sprites.AddLast(TGW_Sprites.Create(Self, spritename, posx, posy, w, h, animcount, SpriteID, spritew, spriteh))
	End Method

	Method DrawSprite(spritename:String = "", x:Float, y:Float, animframe:Int = -1, spriteobj:TGW_Sprites = Null)
		If spriteobj = Null
			For Local i:Int = 0 To Self.sprites.Count() - 1
				If TGW_Sprites(Self.sprites.ValueAtIndex(i)).spritename = spritename Then spriteobj = TGW_Sprites(Self.sprites.ValueAtIndex(i)) ;Exit
			Next
		End If
		If spriteobj <> Null
			DrawImageArea(Self.image, x, y, spriteobj.Pos.x + Max(0, animframe) * spriteobj.framew, spriteobj.Pos.y, spriteobj.framew, spriteobj.h, 0)
		EndIf
	End Method

	Method Draw()
		DrawImage(self.image, self.pos.x, self.pos.y)
	End Method

	Method DrawToViewPort(spritename:String = "", x:Float, y:Float, vx:Float, vy:Float, vw:Float, vh:Float, spriteobj:TGW_Sprites = Null)
		If spriteobj = Null
			For Local i:Int = 0 To Self.sprites.Count() - 1
				If TGW_Sprites(Self.sprites.ValueAtIndex(i)).spritename = spritename Then spriteobj = TGW_Sprites(Self.sprites.ValueAtIndex(i)) ;Exit
			Next
		End If
		If spriteobj <> Null Then ClipImageToViewport(Self.image, x - spriteobj.pos.x, y - spriteobj.pos.y, vx, vy, vw, vh, 0, 0)
	End Method

	Method ColorizeSprite(spriteName:String, colR:Int,colG:Int,colB:Int)
		'to access pos and dimension
		Local tmpSprite:TGW_Sprites = Self.GetSprite(spriteName)
		'store backup (we clean it before pasting colorized output
		local tmpImg:TImage = ColorizeTImage(Self.GetSpriteImage(spriteName), colR, colG, colB)
		Local tmppix:TPixmap = LockImage(Self.image, 0)
			tmppix.Window(tmpSprite.Pos.x, tmpSprite.pos.y, tmpSprite.w, tmpSprite.h).ClearPixels(0)
			DrawOnPixmap(tmpImg, 0, tmppix, tmpSprite.pos.x, tmpSprite.pos.y)
		UnlockImage(Self.image, 0)
		GCCollect() '<- FIX!
	End Method

	Method CopySprite(spriteNameSrc:String, spriteNameDest:String, colR:Int,colG:Int,colB:Int)
		Local tmpSpriteDest:TGW_Sprites = Self.GetSprite(spriteNameDest)
		Local tmppix:TPixmap = LockImage(Self.image, 0)
			tmppix.Window(tmpSpriteDest.Pos.x, tmpSpriteDest.pos.y, tmpSpriteDest.w, tmpSpriteDest.h).ClearPixels(0)
			DrawOnPixmap(ColorizeTImage(Self.GetSpriteImage(spriteNameSrc), colR, colG, colB), 0, tmppix, tmpSpriteDest.pos.x, tmpSpriteDest.pos.y)
		UnlockImage(Self.image, 0)
		GCCollect() '<- FIX!
	End Method

	Method CopyImageOnSpritePackImage(src:object, dest:object = null, destX:float, destY:float)
		local tmppix:TPixmap = null
		local imgWidth:int = 0
		local imgHeight:int = 0
		local srcPix:TPixmap = null
		if TImage(src)<> null then srcPix = LockImage(TImage(src), 0) else srcPix = TPixmap(src)
		if dest = null then tmppix = LockImage(self.image,0) else tmppix = TPixmap(dest)
			'resize needed ? position+dimension extends original size
			if tmppix.width < (srcPix.width + destX) OR ImageHeight(self.image) < (srcPix.height + destY)
				ResizePixmap(tmppix, srcPix.width + destX, srcPix.height + destY)
				print "CopyImageOnSpritePackImage: resize"
			endif
			DrawPixmapOnPixmap(srcPix, tmppix, destX, destY)
		if dest = null then UnlockImage(Self.image, 0)
		if TImage(src)<> null then UnlockImage(TImage(src))
		GCCollect() '<- FIX!
	End Method
End Type


Type TGW_Sprites extends TRenderable
	Field spriteName:String = ""
	Field w:Float
	Field h:Float
	Field framew:Int
	Field frameh:Int
	Field animcount:Int
	Field SpriteID:Int = -1
	Field parent:TGW_SpritePack

	Function Create:TGW_Sprites(spritepack:TGW_SpritePack, spritename:String, posx:Float, posy:Float, w:Int, h:Int, animcount:Int = 0, SpriteID:Int = -1, spritew:Int = 0, spriteh:Int = 0)
		Local Obj:TGW_Sprites = New TGW_Sprites
		Obj.spritename	= spritename
		Obj.parent		= spritepack
		Obj.Pos.setXY(posx, posy)
		Obj.w = w
		Obj.framew = w
		obj.frameh = h
		Obj.h			= h
		Obj.SpriteID	= SpriteID
		Obj.animcount	= animcount
		If animcount > 0 Then
			Obj.framew = ceil(w / animcount)
			Obj.frameh = h
		End If
		If spritew <> 0 And spriteh <> 0
			Obj.framew = spritew
			Obj.frameh = spriteh
		End If

		'asset
		Obj.setName(spritename)
		Obj.setUrl("NONE")
		Obj.setType("SPRITE")

		Return Obj
	End Function

	Function LoadFromAsset:TGW_Sprites(asset:object)
		local obj:TGW_Sprites = TGW_Sprites(asset)

		local spritepack:TGW_Spritepack = null
		if obj.parent = null
			if obj._flags & MASKEDIMAGE then SetMaskColor(255,0,255)
			local _img:TImage = LoadImage(obj._url, obj._flags)

			'load img to find out celldimensions
			if obj.animcount > 0 AND (obj.framew = 0 OR obj.frameh = 0)
				obj.framew = ImageWidth(_img) / obj.animcount
				obj.frameh = ImageHeight(_img)
			endif
			spritepack = TGW_Spritepack.Create(_img, obj.getName()+"_pack")
			if _img = null then print "image null : "+obj.getName()
		else
			spritepack = obj.parent
		endif
		if obj._flags & MASKEDIMAGE then SetMaskColor(0,0,0)

		return TGW_Sprites.Create(spritepack, obj.getName(), 0,0, ImageWidth(spritepack.image), ImageHeight(spritepack.image), obj.animcount, -1, obj.framew, obj.frameh)
	End Function

	Method GetImage:TImage(loadAnimated:Int =1)
		Local DestPixmap:TPixmap = LockImage(self.parent.image, 0, False, True).Window(self.Pos.x, self.Pos.y, self.w, self.h)
		UnlockImage(self.parent.image)
		GCCollect() '<- FIX!
		If self.animcount >1 And loadAnimated
			Return TImage.LoadAnim(DestPixmap, self.framew, self.frameh, 0, self.animcount, 0, 255, 0, 255)
		Else
			Return TImage.Load(DestPixmap, 0, 255, 0, 255)
		End If
	End Method

	'let spritePack colorize the sprite
	Method Colorize(colR:Int,colG:Int,colB:Int)
		self.parent.ColorizeSprite(self.spriteName, colR,colG,colB)
	End Method

	Method GetColorizedImage:TImage(r:int, g:int, b:int)
		return ColorizeTImage(self.GetImage(0), r,g,b, self.framew, self.frameh, 0, self.animcount, 0, 0)
	End Method

	Method GetFrameImage:TImage(framenr:Int = 0)
		Local tmpObj:TGW_Sprites = self.parent.GetSprite(self.spritename)
		Local DestPixmap:TPixmap = LockImage(self.parent.image, 0, False, True).Window(tmpObj.Pos.x + framenr * tmpObj.framew, tmpObj.Pos.y, tmpObj.framew, tmpObj.h)
		UnlockImage(self.parent.image)
		GCCollect() '<- FIX!
		Return TImage.Load(DestPixmap, 0, 255, 0, 255)
	End Method

	Method DrawClipped(imagex:Float, imagey:Float, ViewportX:Float, ViewPortY:Float, ViewPortW:Float, ViewPortH:Float, offsetx:Float = 0, offsety:Float = 0, theframe:Int = 0)
		If imagex+framew>=ViewportX And imagex-framew<ViewportX+ViewportW And imagey+frameh>=ViewportY And imagey-frameh<ViewportY+ViewportH Then
			Local startx#	= Max(0,ViewportX-imagex)
			Local starty#	= Max(0,ViewportY-imagey)
			Local endx#		= Max(0,(imagex+framew)-(ViewportX+ViewportW))
			Local endy#		= Max(0,(imagey+frameh)-(ViewportY+ViewportH))

			'calculate WHERE the frame is positioned in spritepack
			If Self.framew <> 0
				Local MaxFramesInCol:Int	= Ceil(w / framew)
				Local framerow:Int			= Ceil(theframe / maxframesincol)
				Local framecol:Int 			= theframe - (framerow * maxframesincol)
				DrawImageArea(parent.image, imageX + startX + offsetx, imagey + starty + offsety, pos.x + framecol* framew + startx, pos.y + framerow * frameh + starty, framew - startx - endx, frameh - starty - endy, 0)
			EndIf
		EndIf
	End Method

	'Draws an Image if its in the viewport of the screen (not on Interface)
	Method DrawInViewPort(_x:Int, _yItStandsOn:Int, align:Byte=0, Frame:Int=0)
		If _yItStandsOn > 10 And _yItStandsOn - self.h < 373+10
		  If align = 0 '_x is left side of image
			self.Draw(_x, _yItStandsOn - self.h, Frame)
		  ElseIf align = 1 '_x is right side of image
			self.Draw(_x - self.w, _yItStandsOn - self.h,Frame)
		  EndIf
		EndIf
	End Method

	Method TileDrawHorizontal(x:float, y:float, w:float, scale:float=1.0)
		local widthLeft:float = w
		local currentX:float = x
		while widthLeft > 0
			local widthPart:float = Min(self.w, widthLeft) 'draw part of sprite or whole ?
			DrawSubImageRect( parent.image, currentX, y, widthPart, self.h, self.pos.x, self.pos.y, widthPart, self.h )
			currentX :+ widthPart * scale
			widthLeft :- widthPart * scale
		Wend
	End Method

	Method TileDrawVertical(x:float, y:float, h:float, scale:float=1.0)
		local heightLeft:float = h
		local currentY:float = y
		while heightLeft >= 1
			local heightPart:float = Min(self.h, heightLeft) 'draw part of sprite or whole ?
			DrawSubImageRect( parent.image, x, currentY, self.w, ceil(heightPart), self.pos.x, self.pos.y, self.w, ceil(heightPart) )
			currentY :+ floor(heightPart * scale)
			heightLeft :- (heightPart * scale)
		Wend
	End Method


	Method TileDraw(x:Float, y:Float, w:Int, h:Int, animframe:Int = -1, scale:float=1.0)
		local heightLeft:float = floor(h)
		local currentY:float = y
		while heightLeft >= 1
			local heightPart:float	= Min(self.h, heightLeft) 'draw part of sprite or whole ?
			local widthLeft:float	= w
			local currentX:float	= x
			while widthLeft > 0
				local widthPart:float = Min(self.w, widthLeft) 'draw part of sprite or whole ?
				DrawSubImageRect( parent.image, currentX, currentY, ceil(widthPart), ceil(heightPart), self.pos.x, self.pos.y, ceil(widthPart), ceil(heightPart) )
				currentX	:+ floor(widthPart * scale)
				widthLeft	:- (widthPart * scale)
			Wend
			currentY	:+ floor(heightPart * scale)
			heightLeft	:- (heightPart * scale)
		Wend
	End Method

	Method Update()
	End Method

	Method Draw(x:Float, y:Float, theframe:Int = -1, valign:Int = 0, align:int=0, scale:float=1.0)
		If theframe = -1 Or framew = 0
			DrawImageArea(parent.image, x - align*w*scale , y - valign * h * scale, pos.x, pos.y, w, h, 0)
		Else
			Local MaxFramesInCol:Int	= Ceil(w / framew)
			Local framerow:Int			= Ceil(theframe / MaxFramesInCol)
			Local framecol:Int 			= theframe - (framerow * MaxFramesInCol)
			DrawImageArea(parent.image, x - align*w * scale, y - valign * h * scale, pos.x + framecol * framew, pos.y + framerow * frameh, framew, frameh, 0)
		EndIf
	End Method

End Type

Type TSpritesPack
	Field List:TList = CreateList()
	Field LastSpriteID:Int = 0

	Function Create:TSpritesPack()
		Local Obj:TSpritesPack = New TSpritesPack
		Obj.List = CreateList()
		Return Obj
	End Function
rem
asdsad
endrem
	Method GetSprite:TSprites(spritename:String = "")
		spritename = lower(spritename)
		For Local i:Int = 0 To Self.list.Count() - 1
			If lower(TSprites(Self.list.ValueAtIndex(i)).spritename) = spritename Then Return TSprites(Self.list.ValueAtIndex(i))
		Next
'		Print spritename + " nicht gefunden"
'		Print "--------------"
'		For Local i:Int = 0 To Self.list.Count() - 1
'			If TSprites(Self.list.ValueAtIndex(i)).spritename <> "0" Then Print Upper(TSprites(Self.list.ValueAtIndex(i)).spritename)
'		Next
'		Print "--------------"
'		Throw "error"

		Return TSprites(Self.list.ValueAtIndex(0))
		'Return Null
	End Method

	Method FindDuplicate:Object(spritepath:String)
		If spritepath = "" Then Return Null
		For Local i:Int = 0 To Self.list.Count() - 1
			If Upper(TSprites(Self.list.ValueAtIndex(i)).spritepath) = Upper(spritepath) Then Print "duplicate";Return TSprites(Self.list.ValueAtIndex(i)).image
		Next
		Return Null
	End Method

	Method AddSprite:TSprites(image:TImage, spritepath:String = "", spritename:String = " ", x:Float, y:Float, dx:Float, dy:Float, returnToStart:Int, useframe:Int = 0, SpriteID:Int = -1, addtolist:Int = 1, textx:Float = 0.0, texty:Float = 0.0)
		If image = Null Then Print "Error: AddSprite: " + spritename + " path:" + spritepath
		Local sID:Int = SpriteID
		Local tmpObj:TSprites
		If SpriteID < 0 Then LastSpriteID:+1;SpriteID = LastSpriteID;
		tmpObj = TSprites.Create(Self, image, spritepath, Upper(spritename), x, y, dx, dy, returntostart, 0, 0, 1, useframe, SpriteID, textx, texty)
		If addtolist Then Self.list.AddLast(tmpObj)
		Return tmpObj
	End Method

	Method AddAnimSprite:TSprites(image:TImage, spritepath:String = "", spritename:String = " ", x:Float, y:Float, dx:Float, dy:Float, returnToStart:Int, frameW:Int = 0, frameH:Int = 0, frames:Int = 1, SpriteID:Int = -1, addtolist:Int = 1, textx:Float = 0.0, texty:Float = 0.0)
		If image = Null Then Print "Error: AddAnimSprite: " + spritename + " path:" + spritepath
		Local sID:Int = SpriteID
		Local tmpObj:TSprites
		If SpriteID < 0 Then LastSpriteID:+1;SpriteID = LastSpriteID;
		tmpObj = TSprites.Create(Self, image, spritepath, Upper(spritename), x, y, dx, dy, returntostart, frameW, frameH, frames, 0, SpriteID, textx, texty)
		If addtolist Then Self.list.AddLast(tmpObj)
		Return tmpObj
	End Method

	Method AddBigSprite:TSprites(image:TImage, spritepath:String = "", spritename:String = " ", x:Float, y:Float, dx:Float, dy:Float, returnToStart:Int, frameW:Int = 0, frameH:Int = 0, frames:Int = 1, SpriteID:Int = -1, addtolist:Int = 1, textx:Float = 0.0, texty:Float = 0.0)
		Local sID:Int = SpriteID
		Local tmpObj:TSprites
		If SpriteID < 0 Then LastSpriteID:+1;SpriteID = LastSpriteID
		tmpObj = TSprites.CreateBigImage(Self, image, spritepath, Upper(spritename), x, y, dx, dy, returntostart, frameW, frameH, frames, 0, SpriteID, textx, texty)
		If addtolist Then Self.list.AddLast(tmpObj)
		Return tmpObj
	End Method

End Type

Type TSprites
	Field spritename:String
	Field spritepath:String = ""
	Field textx:Float = 0.0, texty:Float = 0.0
	Field x:Float = 0.0, y:Float = 0.0
	Field dy:Float = 0.0,dx:Float = 0.0
	Field image:Object
	Field height:Int = 0
	Field returnToStart:Int
	Field visible:Int = 1
	Field frameW:Int = 0, frameH:Int = 0, frames:Int = 1
	Field useframe:Int = 0
	Field SpriteID:Int = 0

	Function CreateBigImage:TSprites(SpritePack:TSpritesPack, image:TImage, spritepath:String, spritename:String, x:Float, y:Float, dx:Float, dy:Float, returnToStart:Int, frameW:Int = 0, frameH:Int = 0, frames:Int = 1, useframe:Int = 0, SpriteID:Int = -1, textx:Float = 0.0, texty:Float = 0.0)
		Local Sprite:TSprites = New TSprites
		sprite.spritename = spritename
		sprite.spritepath = spritepath
		sprite.textx = textx
		sprite.texty = texty
		Sprite.frameW = frameW;If frameW = 0 Then frameW = ImageWidth(image)
		Sprite.frameH = frameH;If frameH = 0 Then frameH = ImageHeight(image)
		Sprite.frames = frames
		Sprite.x = x
		Sprite.y = y
		Sprite.dx = dx
		Sprite.dy = dy
		Sprite.SpriteID = SpriteID
		Sprite.height = ImageHeight(image)
		Sprite.returnToStart = returnToStart
		Sprite.image = TBigImage.CreateFromImage(image)
		sprite.useframe = useframe
		If Not SpritePack.List Then SpritePack.List = CreateList()
		SpritePack.List.AddLast(Sprite)
		'	  SortList List
		Return Sprite
	End Function

	Function Create:TSprites(SpritePack:TSpritesPack, image:TImage, spritepath:String = "", spritename:String = " ", x:Float, y:Float, dx:Float, dy:Float, returnToStart:Int, frameW:Int = 0, frameH:Int = 0, frames:Int = 1, useframe:Int = 0, SpriteID:Int = -1, textx:Float = 0.0, texty:Float = 0.0)
		Local Sprite:TSprites = New TSprites
		sprite.spritename = spritename
		sprite.spritepath = spritepath
		sprite.textx = textx
		sprite.texty = texty
		Sprite.frameW = frameW;If frameW = 0 Then Sprite.frameW = ImageWidth(image)
		Sprite.frameH = frameH;If frameH = 0 Then Sprite.frameH = ImageHeight(image)
		Sprite.frames = frames
		Sprite.x = x
		Sprite.y = y
		Sprite.dx = dx
		Sprite.dy = dy
		Sprite.SpriteID = SpriteID
		Sprite.height = ImageHeight(image)
		Sprite.returnToStart = returnToStart
		Sprite.image = image
		sprite.useframe = useframe
		If Not SpritePack.List Then SpritePack.List = CreateList()
		SpritePack.List.AddLast(Sprite)
		'	  SortList List
		Return Sprite
	End Function

	Method DrawXadded(addx:Float = 0.0, useframe:Int = -1)
		Self.Draw(Self.x + addx, Self.y, useframe)
	End Method

	Method Draw(_x:Int = -1, _y:Int = -1, _useframe:Int = -1, texttodraw:String = "", font:TImageFont = Null)
		If _useframe = -1 Then _useframe = useframe
		If _x = -1 And _y = -1 Then _x = Self.x;_y = Self.y
		If visible
			If TImage(image)
				If _y + ImageHeight(TImage(image)) > 0 And _y < 600
					DrawImage(TImage(image), _x, _y, _useframe)
				EndIf
			Else If TBigImage(image)
				TBigImage(image).render(_x, _y, 1.0)
			EndIf
		EndIf
		If texttodraw <> ""
			if font <> Null then SetImageFont font
			DrawText(texttodraw, _x + textx, _y + texty)
		End If
	End Method

 Method UpdateWithReturn(_x:Float = -10000, _y:Float = -10000)
 	x:+dx
 	If _x = -10000 Then _x = x
    If _y = -10000 Then _y = y
    If returnToStart > 0 And x-returntostart>800 Then x = -returnToStart -Rand(50); dx=4+Rand(0,5)
 End Method

 Method Update(_x:Float = -10000, _y:Float = -10000)
 	x:+dx
 	If _x = -10000 Then _x = x
    If _y = -10000 Then _y = y
    If returnToStart > 0 And x-returntostart>800 Then x = -returnToStart -Rand(50); dx=4+Rand(0,5)
 End Method

 Method UpdateAndDraw(_x:Int=-10000, _y:Int = -10000)
 	x:+dx
 	If _x = -10000 Then _x = x
    If _y = -10000 Then _y = y
    Draw(_x,_y)
    If returnToStart > 0 And x-returntostart>800 Then x = -returnToStart -Rand(50); dx=4+Rand(0,5)
 End Method
End Type

Type TAnimation
	field repeatTimes:int		= 0		'how many times animation should repeat until finished
	field currentFrame:int		= 0		'frame of sprite/image
	field currentFramePos:int	= 0		'position in frames-array
	field frames:int[]
	field framesTime:float[]			'duration for each frame
	field paused:byte			= 0		'stay with currentFrame or cycle through frames?
	field frameTimer:float		= null


	Function Create:TAnimation(framesArray:int[][], repeatTimes:int=0, paused:byte=0)
		local obj:TAnimation = new TAnimation
		local framecount:int = len( framesArray )

		obj.frames		= obj.frames[..framecount] 'extend
		obj.framesTime	= obj.framesTime[..framecount] 'extend

		For local i:int = 0 to framecount-1
			obj.frames[i]		= framesArray[i][0]
			obj.framesTime[i]	= float(framesArray[i][1]) * 0.001
		Next
		obj.repeatTimes	= repeatTimes
		obj.paused		= paused
		return obj
	End Function

	Method Update(deltaTime:float=1.0)
		If not self.paused
			if self.frameTimer = null then self.ResetFrameTimer()

			self.frameTimer :- deltaTime
			if self.frameTimer <= 0.0
				'increase current frameposition but only if frame is set
				'resets frametimer too
				self.setCurrentFramePos(self.currentFramePos + 1)
				'print self.currentFramePos + " -> "+ self.currentFrame

				'reached end
				If self.currentFramePos >= len(self.frames)-1
					If self.repeatTimes = 0 then
						self.Pause()	'stop animation
					Else
						self.setCurrentFramePos( 0 )
						self.repeatTimes	:-1
					EndIf
				EndIf
			Endif
		EndIf
	End Method

	'''''''''''''' animation sollte "sprite" besitzen - dadurch kann man "geschlossene tuer", "oeffnen" und "schliessen" in ein objekt packen
	Method Reset()
		self.setCurrentFramePos(0)
	End Method

	Method ResetFrameTimer()
		self.frameTimer = self.framesTime[self.currentFramePos]
	End Method

	Method getFrameCount:int()
		return len(self.frames)
	End Method

	Method getCurrentFrame:int()
		return self.currentFrame
	End Method

	Method setCurrentFrame(frame:int)
		self.currentFrame = frame
		self.ResetFrameTimer()
	End Method

	Method getCurrentFramePos:int()
		return self.currentFramePos
	End Method

	Method setCurrentFramePos(framePos:int)
		self.currentFramePos = Max( Min(framePos, len(self.frames) - 1), 0)
		self.setCurrentFrame( self.frames[ self.currentFramePos ] )
	End Method

	Method isPaused:byte()
		return self.paused
	End Method

	Method isFinished:byte()
		return self.paused AND (self.currentFramePos >= len(self.frames)-1)
	End Method

	Method Playback()
		self.paused = 0
	End Method

	Method Pause()
		self.paused = 1
	End Method


End Type


'base of animated sprites... contains timers and so on, supports reversed animations
Type TAnimSprites
	Global List:TList = CreateList()
	Field pos:TPosition	= TPosition.Create(0,0)
 Field dx:Int 			= 0
 Field image:TImage
 Field returnToStart:Int= 0
 Field visible:Int 		= 1
 Field AnimationSets:TMap	 	= CreateMap()
 Field currentAnimation:string	= "default"

	Function Create:TAnimSprites(image:TImage, x:Int, y:Int, dx:Int, AnimCount:Int = 1, animTime:Int)
		Local AnimSprites:TAnimSprites=New TAnimSprites
		AnimSprites.pos.setXY(x, y)
		AnimSprites.dx = dx
		AnimSprites.image = image

		local framesArray:int[][2]
		framesArray	= framesArray[..AnimCount] 'extend
		for local i:int = 0 to AnimCount -1
			framesArray[i]		= framesArray[i][..2] 'extend to 2 fields each entry
			framesArray[i][0]	= i
			framesArray[i][1]	= animTime
		Next
		AnimSprites.insertAnimation( "default", TAnimation.Create(framesArray,0,0) )

		List.AddLast(AnimSprites)
		SortList List
		Return AnimSprites
	End Function

	Method InsertAnimation(animationName:string, animation:TAnimation)
		self.AnimationSets.insert(lower(animationName), animation)
		if not self.AnimationSets.contains("default") then self.setCurrentAnimation(animationName, 0)
	End Method

	Method setCurrentAnimation(animationName:string, startAnimation:byte = 1)
		self.currentAnimation = lower(animationName)
		self.getCurrentAnimation().Reset()
		if startAnimation then self.getCurrentAnimation().Playback()

'		local frameset:string = "frames:"
'		for local i:int = 0 to self.getCurrentAnimation().getFrameCount()-1
'			frameset = frameset + self.getCurrentAnimation().frames[i] + ", "
'		Next
'		print frameset
	End Method

	Method getCurrentAnimation:TAnimation()
		local obj:TAnimation = TAnimation(self.AnimationSets.ValueForKey(self.currentAnimation))
		if obj = null then obj = TAnimation(self.AnimationSets.ValueForKey("default"))
		return obj
	End Method

	Method getAnimation:TAnimation(animationName:string="default")
		local obj:TAnimation = TAnimation(self.AnimationSets.ValueForKey(animationName))
		if obj = null then obj = TAnimation(self.AnimationSets.ValueForKey("default"))
		return obj
	End Method


	Method getCurrentAnimationName:string()
		return self.currentAnimation
	End Method


	Method getCurrentFrame:int()
		return self.getCurrentAnimation().getCurrentFrame()
	End Method

	Method Draw(_x:Int=-10000, _y:Int = -10000, overwriteAnimation:string="")
		If visible
			If _x = -10000 Then _x = pos.x
			If _y = -10000 Then _y = pos.y
			if overwriteAnimation <> ""
				DrawImage(image, _x,_y, self.getAnimation(overwriteAnimation).getCurrentFrame() )
			else
				DrawImage(image, _x,_y, self.getCurrentAnimation().getCurrentFrame() )
			endif
		EndIf
	End Method

	Method Update(deltaTime:float=1.0)
		self.getCurrentAnimation().Update(deltaTime)
		self.pos.x :+ deltaTime * dx
	End Method

	Method UpdateWithReturn(deltaTime:float=1.0)
		Update(deltaTime)
		If returnToStart > 0 And pos.x-returntostart>800 Then pos.x = -returnToStart
	End Method
End Type