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

'SuperStrict
'from bufferedglmax2d.bmx
'Import cower.renderbuffer

Type TGLPackedTexture
	Global MinPackingSize%=3
	
	Field _filled:Int
	Field _u0#, _v0#, _u1#, _v1#
	Field _x%, _y%
	Field _width%, _height%
	field _pwidth%, _pheight%
'	Field _sc_right:Float, _sc_top:Float
	Field _owner:TGLTexturePack
	Field _p_right:TGLPackedTexture, _p_bottom:TGLPackedTexture
	
	Method GetUnused:TGLPackedTexture(width%, height%)
		If MinPackingSize <= Min(width, height) And Min(_width, _height) <= MinPackingSize Then
			Return Null
		EndIf
		
		If _filled Or _width < width Or _height < height Then
			Local r:TGLPackedTexture
			If _p_right And _p_bottom And Not(_p_bottom._filled Or _p_right._filled) Then
				If width >= height Then
					Local tw% = _p_bottom._width-width
					If 0 < tw And tw < _p_right._width-width Then
						r = _p_bottom.GetUnused(width, height)
						If Not r Then r = _p_right.GetUnused(width, height)
					Else
						r = _p_right.GetUnused(width, height)
						If Not r Then r = _p_bottom.GetUnused(width, height)
					EndIf
				Else
					Local th% = _p_bottom._height-height
					If 0 < th And th < _p_right._height-height Then
						r = _p_bottom.GetUnused(width, height)
						If Not r Then r = _p_right.GetUnused(width, height)
					Else
						r = _p_right.GetUnused(width, height)
						If Not r Then r = _p_bottom.GetUnused(width, height)
					EndIf
				EndIf
			Else
				If Not r And _p_right Then r = _p_right.GetUnused(width, height)
				If Not r And _p_bottom Then r = _p_bottom.GetUnused(width, height)
			EndIf
			Return r
		EndIf
		
		If _p_right Or _p_bottom Then
			Local botBuffer% = _height-height
			Local rightBuffer% = _width-width
			
			If botBuffer Or Not _p_bottom Then
				Local nb:TGLPackedTexture = New TGLPackedTexture
				nb._height = botBuffer
				nb._width = _width
				nb._p_bottom = _p_bottom
				nb._owner = _owner
				_p_bottom = nb
			EndIf
			
			If rightBuffer Or Not _p_right Then
				Local nr:TGLPackedTexture = New TGLPackedTexture
				nr._height = height
				nr._width = rightBuffer
				nr._p_right = _p_right
				nr._owner = _owner
				_p_right = nr
			EndIf
		Else
			_p_right = New TGLPackedTexture
			_p_bottom = New TGLPackedTexture
			' this is confusing.
			If _height-height < _width-width Then
				_p_right._width = _width-width
				_p_right._height = height
				_p_bottom._width = _width
				_p_bottom._height = _height-height
			Else
				_p_right._width = _width-width
				_p_right._height = _height
				_p_bottom._width = width
				_p_bottom._height = _height-height
			EndIf
		EndIf
		
		' TODO: add rotation ala' Tommo's code for fitting images that otherwise wouldn't fit...
		
		_p_right._x = _x+width
		_p_right._y = _y
		
		_p_bottom._x = _x
		_p_bottom._y = _y+height
		
		_p_right._owner = _owner
		_p_bottom._owner = _owner
		
		_width = width
		_height = height
		
		Return Self
	End Method
	
	Method Buffer(pixmap:TPixmap)
		Assert pixmap
		_filled = True
		
		_pwidth = pixmap.width
		_pheight = pixmap.height

'		_sc_right# = Float(pixmap.width)/Float(_width)
' 		_sc_top# = Float(pixmap.height)/Float(_height)
		
		_u0 = _x*_owner._wscale
		_u1 = _u0 + _pwidth*_owner._wscale
		_v0 = _y*_owner._hscale
		_v1 = _v0 + _pheight*_owner._hscale

		Local format% = GLFormatForPixmap(pixmap)

		Local level% = 0
		Local tx%=_x, ty%=_y
		
		TRenderState.SetTexture(Name())
		
		Local pRowLen%
		glGetIntegerv(GL_UNPACK_ROW_LENGTH, Varptr pRowLen)
		Repeat
			glPixelStorei(GL_UNPACK_ROW_LENGTH, pixmap.pitch/BytesPerPixel[pixmap.format]) ' pixmap windows are evil yo
			glTexSubImage2D(GL_TEXTURE_2D, level, tx, ty, pixmap.width, pixmap.height, format, GL_UNSIGNED_BYTE, pixmap.pixels)
			If Not (_owner._flags&MIPMAPPEDIMAGE) Then Exit
			If pixmap.width = 1 And pixmap.height = 1 Then Exit
			level :+ 1
			tx :/ 2
			ty :/ 2
			pixmap = ResizePixmap(pixmap, pixmap.width/2 Or 1, pixmap.height/2 Or 1)
		Forever
		glPixelStorei(GL_UNPACK_ROW_LENGTH, pRowLen)
	End Method
	
	Method Name%() NoDebug
		Return _owner.Name()
	End Method
	
	Method Unload()
		_filled = False
		_owner.MergeEmpty()
	End Method
	
	Method MergeEmpty()
		If _p_right Then _p_right.MergeEmpty()
		If _p_bottom Then _p_bottom.MergeEmpty()
		
		If _filled Then
			Return
		EndIf
		
		If _p_right Then
			If Not _p_right._filled And _p_right._height = _height Then
				_width :+ _p_right._width
				_p_right = _p_right._p_right
			EndIf
			
			If Not _p_bottom._filled And _p_bottom._width = _width Then
				_height :+ _p_bottom._height
				_p_bottom = _p_bottom._p_bottom
			EndIf
		EndIf
		
		If _p_bottom Then
			If Not _p_bottom._filled And _p_bottom._width = _width Then
				_height :+ _p_bottom._height
				_p_bottom = _p_bottom._p_bottom
			EndIf
			
			If Not _p_right._filled And _p_right._height = _height Then
				_width :+ _p_right._width
				_p_right = _p_right._p_right
			EndIf
		EndIf
	End Method
End Type

Type TGLTexturePack
	Field _gseq:Int
	Field _name:Int
	Field _root:TGLPackedTexture
	Field _width:Int, _height:Int, _flags:Int = -1
	Field _wscale#, _hscale#
	
	Method Name%() NoDebug
		Return _name
	End Method
	
	Method Bind()
		TRenderState.SetTexture(_name)
	End Method
	
	Method Reset()
		If GraphicsSeq = _gseq Then
			glDeleteTextures(1, Varptr _name)
		EndIf
		_gseq = GraphicsSeq
		_name = 0
		
		Local width% = _width
		Local height% = _height
		
		glGenTextures(1, Varptr _name)
		TRenderState.SetTexture(_name)
		
		glTexImage2D(GL_PROXY_TEXTURE_2D, 0, GL_RGBA8, _width, _height, 0, GL_ALPHA, GL_UNSIGNED_BYTE, Null)
		Local proxyw:Int = 0
		glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, Varptr proxyw)
		If proxyw = 0 Then
			TRenderState.SetTexture(0)
			glDeleteTextures(1, Varptr _name)
			Throw "Unable to create texture for image"
			Return
		EndIf
		
		Local magFilter% = GL_NEAREST
		Local minFilter% = GL_NEAREST
		If _flags&FILTEREDIMAGE Then
			magFilter = GL_LINEAR
			If _flags&MIPMAPPEDIMAGE Then
				minFilter = GL_LINEAR_MIPMAP_LINEAR
			Else
				minFilter = GL_LINEAR
			EndIf
		ElseIf _flags&MIPMAPPEDIMAGE Then
			minFilter = GL_NEAREST_MIPMAP_NEAREST
		EndIf
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter)
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter)
		
		Local blankmem:Byte Ptr = MemAlloc(width*height)'hack
		Local level:Int = 0
		Repeat
			glTexImage2D(GL_TEXTURE_2D, level, GL_RGBA8, width, height, 0, GL_ALPHA, GL_UNSIGNED_BYTE, blankmem)
			If width = 1 And height = 1 Then Exit
			level :+ 1
			width  = width/2 Or 1
			height = height/2 Or 1
		Forever
		MemFree(blankmem)
	End Method
	
	Method Init:TGLTexturePack(width%, height%, flags%)
		_width = width
		_height = height
		_flags = flags
		_wscale = 1.0 / _width
		_hscale = 1.0 / _height
		Reset()
		_root = New TGLPackedTexture
		_root._width = _width
		_root._height = _height
		_root._x = 0
		_root._y = 0
		_root._owner = Self
		Return Self
	End Method
	
	Method GetUnused:TGLPackedTexture(width:Int, height:Int)
		If width > _width Or height > _height Then Return Null
		Return _root.GetUnused(width, height)
	End Method
	
	Method MergeEmpty() NoDebug
		_root.MergeEmpty()
	End Method
	
	Method Delete()
		If _gseq = GraphicsSeq Then
			glDeleteTextures(1, Varptr _name)
		EndIf
		_name = 0
		_gseq = 0
	End Method
End Type
