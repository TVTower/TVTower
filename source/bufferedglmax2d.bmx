Rem
Copyright (c) 2009 Noel R. Cower

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
EndRem

SuperStrict

'Module Cower.BufferedGLMax2D

Import Brl.Max2D
Import Brl.LinkedList
Import Brl.GLGraphics
Import Brl.Retro 'print
Import "renderbuffer.bmx"
'Import Cower.RenderBuffer

Public

Include "texturepack.bmx"

Private

Function PowerOfTwoFor%(i%)
	Local r% = %1
	While r<i ; r :Shl 1 ; Wend
	Return r
End Function

Function GLFormatForPixmap%(pixmap:TPixmap)
	Select pixmap.format
		Case PF_A8			Return GL_ALPHA8
		Case PF_I8			Return GL_LUMINANCE8
		Case PF_RGB888		Return GL_RGB
		Case PF_BGR888		Return GL_BGR
		Case PF_BGRA8888	Return GL_BGRA
		Default 			Return GL_RGBA
	End Select
End Function

Public

Type TGLBufferedImageFrame Extends TImageFrame
	Field _gseq:Int
	Field _texture:TGLPackedTexture

	Method New()
	End Method

	Method Init:TGLBufferedImageFrame(buffer:TGLPackedTexture)
		Assert buffer Else "No buffer provided"
		_gseq = GraphicsSeq
		_texture = buffer

		Return Self
	End Method

	Field uv:Float[8]
	Method Draw(x0#, y0#, x1#, y1#, tx#, ty#, sx#, sy#, sw#, sh#)
		Assert _gseq = GraphicsSeq Else "Image no longer exists"

		_activeDriver._buffer.SetTexture(_texture.Name())
		_activeDriver._buffer.SetMode(GL_TRIANGLE_STRIP)

		If sx <> 0 Or sy <> 0 Or sw <> _texture._pwidth Or sh <> _texture._pheight Then
			Local u0#, u1#, v0#, v1#
			u0 = _texture._u0 + sx*_texture._owner._wscale
			u1 = u0 + sw*_texture._owner._wscale
			v0 = _texture._v0 + sy*_texture._owner._hscale
			v1 = v0 + sh*_texture._owner._hscale

			uv[0]=u0
			uv[1]=v0
			uv[2]=u1
			uv[3]=v0
			uv[4]=u0
			uv[5]=v1
			uv[6]=u1
			uv[7]=v1
		Else
			uv[0]=_texture._u0
			uv[1]=_texture._v0
			uv[2]=_texture._u1
			uv[3]=_texture._v0
			uv[4]=_texture._u0
			uv[5]=_texture._v1
			uv[6]=_texture._u1
			uv[7]=_texture._v1
		EndIf
		_activeDriver._buffer.AddVerticesEx(4, _activeDriver._rectPoints(x0,y0,x1,y1,tx,ty), uv, _activeDriver._poly_colors)
	End Method

	Method Delete()
		_gseq = 0
		If _texture Then _texture.Unload()
	End Method
End Type


Private

Global _activeDriver:TBufferedGLMax2DDriver = Null


Public

Type TBufferedGLMax2DDriver Extends TMax2DDriver
	Global MinimumTextureWidth%=1024
	Global MinimumTextureHeight%=1024

	Field _buffer:TRenderBuffer = New TRenderBuffer
	Field _cr@, _cg@, _cb@, _ca@

	Field _txx#=1, _txy#=0, _tyx#=0, _tyy#=1

	Field _view_x%=0
	Field _view_y%=0
	Field _view_w%=-1-1
	Field _view_h%=-1

	Method Reset()
		glewinit()
		glEnableClientState(GL_VERTEX_ARRAY)
		glEnableClientState(GL_COLOR_ARRAY)
		glEnableClientState(GL_TEXTURE_COORD_ARRAY)
		TRenderState.RestoreState(Null)
		SetResolution(_r_width, _r_height)
		For Local i:Int = 0 Until _texPackages.Length
			_texPackages[i] = null
		Next
	End Method

	Method _rectPoints:Float[](x0#, y0#, x1#, y1#, tx#, ty#) NoDebug
		' Saves on 8 multiplications, which isn't really a big deal, but the code is cleaner for it.
		Local x0xx:Float = x0*_txx
		Local x0yx:Float = x0*_tyx
		Local x1xx:Float = x1*_txx
		Local x1yx:Float = x1*_tyx

		Local y0xy:Float = y0*_txy
		Local y0yy:Float = y0*_tyy
		Local y1xy:Float = y1*_txy
		Local y1yy:Float = y1*_tyy

		_poly_xy[0] = x0xx + y0xy + tx
		_poly_xy[1] = x0yx + y0yy + ty
		_poly_xy[2] = x1xx + y0xy + tx
		_poly_xy[3] = x1yx + y0yy + ty
		_poly_xy[4] = x0xx + y1xy + tx
		_poly_xy[5] = x0yx + y1yy + ty
		_poly_xy[6] = x1xx + y1xy + tx
		_poly_xy[7] = x1yx + y1yy + ty

		Return _poly_xy
	End Method

	' TGraphicsDriver

	Method GraphicsModes:TGraphicsMode[]() NoDebug
		Return GLGraphicsDriver().GraphicsModes()
	End Method

	Method AttachGraphics:TGraphics(widget%, flags%)
		Local gfx:TGLGraphics = GLGraphicsDriver().AttachGraphics(widget, flags)
		If gfx Then
			Return TMax2DGraphics.Create(gfx, Self)
		EndIf
		Return Null
	End Method

	Method CreateGraphics:TGraphics(width%, height%, depth%, hertz%, flags%)
		Local gfx:TGLGraphics = GLGraphicsDriver().CreateGraphics(width, height, depth, hertz, flags)
		If gfx Then
			Return TMax2DGraphics.Create(gfx, Self)
		EndIf
		Return Null
	End Method

	Method SetGraphics(g:TGraphics)
		If Not g Then
			TMax2DGraphics.ClearCurrent()
			GLGraphicsDriver().SetGraphics(Null)
			Return
		EndIf

		Local m2d:TMax2DGraphics = TMax2DGraphics(g)
		Assert m2d And TGLGraphics(m2d._graphics)

		GLGraphicsDriver().SetGraphics(m2d._graphics)
		Reset()
		m2d.MakeCurrent()
	End Method

	Method Flip(sync%)
		_buffer.Render()
		GLGraphicsDriver().Flip(sync)
		_buffer.Reset()
		glLoadIdentity()
	End Method

	' TMax2DDriver

	Field _texPackages:TGLTexturePack[16]
	Field _numPackages:Int = 0

	Method CreateFrameFromPixmap:TImageFrame(pixmap:TPixmap, flags%)
		Local maxtexsize%
		glGetIntegerv(GL_MAX_TEXTURE_SIZE, Varptr maxtexsize)
		If maxtexsize < MinimumTextureWidth Then
			MinimumTextureWidth = maxtexsize
		EndIf
		If maxtexsize < MinimumTextureHeight Then
			MinimumTextureHeight = maxtexsize
		EndIf

		If pixmap.format <> PF_RGBA8888 Then
			pixmap = pixmap.Convert(PF_RGBA8888)
		EndIf

		If maxtexsize <= Max(pixmap.width+4, pixmap.height+4) Then
			Local resize# = Float(maxtexsize)/Max(pixmap.width, pixmap.height)+4
			pixmap = ResizePixmap(pixmap, (pixmap.width+4)*resize, (pixmap.height+4)*resize)
		EndIf

		' images get 4 pixels worth of padding
		' upside: tends to remove any sort of bleeding between textures
		' downside: this can make a 1024x1024 image require the allocation of a 2048x2048 image,
		' but this is mitigated by the fact that the remainder of that texture can still be used for
		' other images
		Local pw% = PowerOfTwoFor(pixmap.width+4)
		Local ph% = PowerOfTwoFor(pixmap.height+4)

		Local buffer:TGLPackedTexture
		For Local i:Int = 0 Until _numPackages
			If Not _texPackages[i] Then Exit
			If _texPackages[i]._flags = flags Then
				buffer = _texPackages[i].GetUnused(pixmap.width, pixmap.height)
			EndIf
		Next

		If buffer = Null Then
			If _numPackages = _texPackages.Length Then
				_texPackages = _texPackages[.._texPackages.Length*2]
			EndIf

			_texPackages[_numPackages] = New TGLTexturePack.Init(Max(pw, MinimumTextureWidth), Max(ph, MinimumTextureHeight), flags)
			buffer = _texPackages[_numPackages].GetUnused(pixmap.width+4, pixmap.height+4)
			_numPackages :+ 1
		EndIf

		Assert buffer Else "Failed to create buffer for image"
		buffer.Buffer(pixmap)

		Return New TGLBufferedImageFrame.Init(buffer)
	End Method

	Global __blend_funcs:Int[]=[..
		GL_ONE, GL_ZERO, GL_GEQUAL, 1, ..
		GL_ONE, GL_ZERO, GL_ALWAYS, 0, ..
		GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ALWAYS, 0, ..
		GL_SRC_ALPHA, GL_ONE, GL_ALWAYS, 0, ..
		GL_DST_COLOR, GL_ZERO, GL_ALWAYS, 0]
	Field _blend:Int=-1
	Method SetBlend(blend%)
		Assert 0 < blend And blend <= SHADEBLEND Else "Invalid blendmode specified"
		If blend=_blend Then
			Return
		EndIf
		_blend = blend
		blend = (blend-1)*4
		_buffer.SetBlendFunc(__blend_funcs[blend], __blend_funcs[blend+1])
		_buffer.SetAlphaFunc(__blend_funcs[blend+2], __blend_funcs[blend+3]*.5)
		Rem
		Select blend
			Case MASKBLEND
				_buffer.SetBlendFunc(GL_ONE, GL_ZERO)
				_buffer.SetAlphaFunc(GL_GEQUAL, .5)
			Case SOLIDBLEND
				_buffer.SetBlendFunc(GL_ONE, GL_ZERO)
				_buffer.SetAlphaFunc(GL_ALWAYS, 0)
			Case ALPHABLEND
				_buffer.SetBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
				_buffer.SetAlphaFunc(GL_ALWAYS, 0)
			Case LIGHTBLEND
				_buffer.SetBlendFunc(GL_SRC_ALPHA, GL_ONE)
				_buffer.SetAlphaFunc(GL_ALWAYS, 0)
			Case SHADEBLEND
				_buffer.SetBlendFunc(GL_DST_COLOR, GL_ZERO)
				_buffer.SetAlphaFunc(GL_ALWAYS, 0)
			Default
				RuntimeError "Invalid blendmode specified: "+blend
		End Select
		EndRem
	End Method

	Method SetAlpha(alpha#) NoDebug
		'haaaaaack (to make sure that if you specify a value greater than 1, unlike if you passed
		' 2 and you would end up with some odd value between 0 and 1)
		Local lascolor:Int = Int Ptr(Varptr _cr)[0]
		_ca=Min(Max(alpha, 0), 1)*255
		Local curcolor:Int = Int Ptr(Varptr _cr)[0]
		If lascolor=curcolor Then
			Return
		EndIf
		Local colorptr:Int Ptr = Int Ptr(Varptr _poly_colors[0])
		For Local i:Int = 0 Until _poly_colors.Length/4
			colorptr[i] = curcolor
		Next
	End Method

	Method SetColor(r%, g%, b%) NoDebug
		Local lascolor:Int = Int Ptr(Varptr _cr)[0]
		_cr=Min(Max(r, 0), 255) 'haaaaaaaaaaaaaaaaaaaaaaaaack, same as above
		_cg=Min(Max(g, 0), 255)
		_cb=Min(Max(b, 0), 255)
		Local curcolor:Int = Int Ptr(Varptr _cr)[0]
		If lascolor=curcolor Then
			Return
		EndIf
		Local colorptr:Int Ptr = Int Ptr(Varptr _poly_colors[0])
		For Local i:Int = 0 Until _poly_colors.Length/4
			colorptr[i] = curcolor
		Next
	End Method

	Field _clr_r%, _clr_g%, _clr_b%
	Method SetClsColor(r%, g%, b%) NoDebug
		If _clr_r=r And _clr_g=g And _clr_b=b Then
			Return
		EndIf
		_clr_r=r
		_clr_g=g
		_clr_b=b
		glClearColor(r/255#, g/255#, b/255#, 1.0)
	End Method

	Method SetViewport(x%, y%, w%, h%)
		_buffer.SetScissorTest(Not (x=0 And y=0 And w=_r_width And h=_r_height), x, _r_height-(y+h), w, h)
	End Method

	Method SetTransform(xx#, xy#, yx#, yy#) NoDebug
		_txx = xx
		_txy = xy
		_tyx = yx
		_tyy = yy
	End Method

	Method SetLineWidth(width#) NoDebug
		_buffer.SetLineWidth(width)
	End Method

	Method Cls() NoDebug
		_buffer.Reset()
		glClear(GL_COLOR_BUFFER_BIT)'|GL_DEPTH_BUFFER_BIT)
	End Method

	Method Plot(x#, y#)
		_buffer.SetTexture(0)
		_buffer.SetMode(GL_POINTS)
		_poly_xy[0] = x
		_poly_xy[1] = y
		_buffer.AddVerticesEx(1, _poly_xy, Null, _poly_colors)
	End Method

	Method DrawLine(x0#, y0#, x1#, y1#, tx#, ty#)
		_buffer.SetTexture(0)
		_buffer.SetMode(GL_LINES)
		_poly_xy[0] = x0*_txx+y0*_txy+tx+.5
		_poly_xy[1] = x0*_tyx+y0*_tyy-1+ty+.5
		_poly_xy[2] = x1*_txx+y1*_txy+tx+.5
		_poly_xy[3] = x1*_tyx+y1*_tyy-1+ty+.5
		_buffer.AddVerticesEx(2, _poly_xy, Null, _poly_colors)
	End Method

	Method DrawRect(x0#, y0#, x1#, y1#, tx#, ty#)
		_buffer.SetTexture(0)
		_buffer.SetMode(GL_TRIANGLE_STRIP)
		_buffer.AddVerticesEx( 4, ..
			_rectPoints(x0,y0,x1,y1,tx,ty), ..
			Null, ..
			_poly_colors )
	End Method

	Method DrawOval(x0#, y0#, x1#, y1#, tx#, ty#)
		Local dx# = (x1-x0)*.5
		Local dy# = (y1-y0)*.5

		Local segments:Int = Max(dx, dy)*4 - 1

		If _poly_xy.Length < segments*2 Then
			_poly_xy = New Float[segments*2]
			_poly_colors = New Byte[segments*4]
		EndIf
		Local segToAngle# = 360#/Float(segments)
		Local colorptr:Int Ptr = Int Ptr(Varptr _poly_colors[0])
		Local curcolor:Int = Int Ptr(Varptr _cr)[0]
		For Local i:Int = 0 Until segments
			Local sdx# = Sin(i*segToAngle)*dx
			Local cdy# = Cos(i*segToAngle)*dy
			Local x# = x0+dx+sdx
			Local y# = y0+dy+cdy
			Local xyzi%=i*2
			_poly_xy[xyzi] = x*_txx + y*_txy + tx
			_poly_xy[xyzi+1] = y*_tyx + y*_tyy + ty
			colorptr[i] = curcolor
		Next
		_buffer.SetMode(GL_POLYGON)
		_buffer.SetTexture(0)
		_buffer.AddVerticesEx(segments, _poly_xy, Null, _poly_colors)
	End Method

	Field _poly_xy#[36]
	Field _poly_colors:Byte[36]
	Method DrawPoly(xy#[], handlex#, handley#, originx#, originy#)
		_buffer.SetTexture(0)
		_buffer.SetMode(GL_POLYGON)

		If _poly_colors.Length/2 < xy.Length Then
			_poly_colors = New Byte[Min(xy.Length,24)*2]
		EndIf
		Local colorptr:Int Ptr = Int Ptr(Varptr _poly_colors[0])
		Local curcolor:Int = Int Ptr(Varptr _cr)[0]
		For Local i:Int = 0 Until xy.Length Step 2
			Local ti:Int = (i/2)*3
			Local x#,y#
			x = xy[i]
			y = xy[i+1]

			x :+ handlex
			y :+ handley
			x = (x * _txx) + (y * _txy) + originx
			y = (x * _tyx) + (y * _tyy) + originy

			colorptr[i/2] = curcolor
		Next
		_buffer.AddVerticesEx(xy.Length/2, xy, Null, _poly_colors)
	End Method

	Method DrawPixmap(pixmap:TPixmap, x%, y%)
		_buffer.Render()
		_buffer.Reset()
		glRasterPos2i(x, y)
		glDrawPixels(pixmap.width, pixmap.height, GLFormatForPixmap(pixmap), GL_UNSIGNED_BYTE, pixmap.pixels)
	End Method

	Method GrabPixmap:TPixmap(x%, y%, width%, height%)
		_buffer.Render()
		_buffer.Reset()

		local pix:TPixmap = CreatePixmap(width, height, PF_RGBA8888)
		'coord gl = 'bottom left' while Blitzmax is 'top left'
		' - need to subtract y and height
		glReadPixels(x, _r_height - y - height, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pix.pixels)
		pix = YFlipPixmap(pix)
rem
		Local pix:TPixmap = TPixmap.Create(_r_width, _r_height, PF_RGBA8888, 4)
		glReadPixels(0, 0, _r_height, _r_height, GL_RGBA, GL_UNSIGNED_BYTE, pix.pixels)
		For Local px:Int = 0 Until pix.width
			For Local uy:Int = 0 Until pix.height/2
				Local upper:Int, lower:Int
				Local ly% = pix.height-uy
				upper = pix.ReadPixel(px, uy)
				lower = pix.ReadPixel(px, ly)
				pix.WritePixel(px, uy, lower)
				pix.WritePixel(px, ly, upper)
			Next
		Next
endrem
		Return pix
	End Method

	Field _r_width#=640, _r_height#=480 ' dummy values
	Method SetResolution(width#, height#)
		_r_width = width
		_r_height = height

		glMatrixMode(GL_PROJECTION)
		glLoadIdentity()
		glOrtho(0, width, height, 0, -32, 32)
		glMatrixMode(GL_MODELVIEW)
		glLoadIdentity()
	End Method

	Method ToString$() NoDebug
		Return "OpenGL (Buffered)"
	End Method

	Method RenderBuffer:TRenderBuffer() NoDebug
		Return _buffer
	End Method
End Type

' That's a mouthful
Function BufferedGLMax2DDriver:TBufferedGLMax2DDriver()
	' Borrowing this idea from the original GLMax2D
	Global _done:Int = False
	If Not _done Then
		_done = True
		If Not GLGraphicsDriver() Then
			Return Null
		EndIf
		_activeDriver = New TBufferedGLMax2DDriver
	EndIf
	Return _activeDriver
End Function
BufferedGLMax2DDriver()
