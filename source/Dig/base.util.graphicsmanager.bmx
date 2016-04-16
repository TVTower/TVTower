Rem
	====================================================================
	Graphicsmanager class
	====================================================================

	Helper to initialize a renderer engine and to setup graphics.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2015 Ronny Otto, digidea.de

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
Import brl.Graphics
Import brl.glmax2d

?bmxng
Import BRL.GLMax2D
'Import sdl.gl2sdlmax2d
'Import pub.opengles
?
?MacOs
Import BRL.GLMax2D
?Win32
Import BRL.GLMax2D
Import "base.util.graphicsmanager.win32.bmx"
?Linux
Import BRL.GLMax2D
'Import "../source/external/bufferedglmax2d/bufferedglmax2d.bmx"
?

Import "base.util.virtualgraphics.bmx"

Type TGraphicsManager
	Field fullscreen:Int	= 0
	Field renderer:Int		= 0
	Field colorDepth:Int	= 16
	Field realWidth:Int		= 800
	Field realHeight:Int	= 600
	Field designedWidth:Int	= -1
	Field designedHeight:Int= -1
	Field hertz:Int			= 60
	Field vsync:Int			= True
	Field flags:Int			= GRAPHICS_BACKBUFFER '0 'GRAPHICS_BACKBUFFER | GRAPHICS_ALPHABUFFER '& GRAPHICS_ACCUMBUFFER & GRAPHICS_DEPTHBUFFER
	Global _instance:TGraphicsManager
	Global _g:TGraphics
	Global RENDERER_NAMES:String[] = [	"OpenGL",..
										"DirectX 7", ..
										"DirectX 9", ..
										"DirectX 11", ..
										"Buffered OpenGL", ..
										"GL2SDL" ..
									 ]
	Const RENDERER_OPENGL:Int   		= 0
	Const RENDERER_DIRECTX7:Int 		= 1
	Const RENDERER_DIRECTX9:Int 		= 2
	Const RENDERER_DIRECTX11:Int 		= 3
	Const RENDERER_BUFFEREDOPENGL:Int   = 4
	Const RENDERER_GL2SDL:Int           = 5

	Function GetInstance:TGraphicsManager()
		If Not _instance Then _instance = New TGraphicsManager
		Return _instance
	End Function



	Method SetResolution:Int(width:Int, height:Int)
		If realWidth <> width Or realHeight <> height
			realWidth = width
			realHeight = height
			Return True
		Else
			Return False
		EndIf
	End Method


	'set the resolution the assets are designed for
	'things get resized according the real resolution
	Method SetDesignedResolution:Int(width:Int, height:Int)
		designedWidth = width
		designedHeight = height
	End Method


	'ATTENTION: there is no guarantee that it works flawless on
	'all computers (graphics context/images might have to be
	'initialized again)
	Method SetFullscreen:Int(bool:Int = True)
		If fullscreen <> bool
			fullscreen = bool
			'create a new graphics object if already in graphics mode
			If _g Then InitGraphics()

			Return True
		EndIf
		Return False
	End Method
	

	Method GetFullscreen:Int()
		Return (fullscreen = True)
	End Method


	Method SetVSync:Int(bool:Int = True)
		If vsync <> bool
			vsync = bool
			Return True
		Else
			Return False
		EndIf
	End Method


	Method SetHertz:Int(value:Int=0)
		hertz = value
	End Method


	Method SetColordepth:Int(value:Int=0)
		If colorDepth <> value
			colorDepth = value
			Return True
		Else
			Return False
		EndIf
	End Method
	

	Method GetColordepth:Int()
		Return colorDepth
	End Method


	Method SetRenderer:Int(value:Int = 0)
		If renderer <> value
			renderer = value
			Return True
		Else
			Return False
		EndIf
	End Method


	Method GetRenderer:Int()
		Return renderer
	End Method
	

	Method GetRendererName:String(forRenderer:Int=-1)
		If forRenderer = -1 Then forRenderer = Self.renderer
		If forRenderer < 0 Or forRenderer > RENDERER_NAMES.length
			Return "UNKNOWN"
		Else
			Return RENDERER_NAMES[forRenderer]
		EndIf
	End Method


	Method SetFlags:Int(value:Int = 0)
		flags = value
	End Method


	Method GetHeight:Int()
		If designedHeight = -1 Then Return realHeight
		Return designedHeight
	End Method


	Method GetWidth:Int()
		If designedWidth = -1 Then Return realWidth
		Return designedWidth
	End Method


	Method GetRealHeight:Int()
		Return realHeight
	End Method


	Method GetRealWidth:Int()
		Return realWidth
	End Method


	Method HasBlackBars:Int()
		If designedWidth = -1 And designedHeight = -1 Then Return False
		Return designedWidth <> realWidth Or designedHeight <> realHeight
	End Method
	

	'switch between fullscreen or windowed mode
	Method SwitchFullscreen:Int()
		SetFullscreen(1 - GetGraphicsManager().GetFullscreen())
	End Method


	Method InitGraphics:Int()
		'initialize virtual graphics only when "InitGraphics()" is run
		'for the first time
		If Not _g Then InitVirtualGraphics()

		'needed to allow ?win32 + ?bmxng
		?win32
		_InitGraphicsWin32()
		?Not win32
		_InitGraphicsDefault()
		?


		SetBlend ALPHABLEND
		SetMaskColor 0, 0, 0
		HideMouse()

		'virtual resolution
		SetVirtualGraphics(GetWidth(), GetHeight(), False)
	End Method


	Method _InitGraphicsDefault:Int()
		Select renderer
			'buffered gl?
			?android
			Default SetGraphicsDriver GL2Max2DDriver()
			?Not android
			Default SetGraphicsDriver GLMax2DDriver()
			?
		EndSelect

		_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)

		If Not _g Then Throw "Graphics initiation error! no render engine available."
	End Method


	'cannot "?win32" this method as this disables "?not bmxng" in this method
	Method _InitGraphicsWin32:Int()
		?win32
		'done in base.util.graphicsmanager.win32.bmx
		'alternatively to "_g = Func(_g,...)"
		'SetRenderWin32 could also use "_g:TGraphics var"
		_g = SetRendererWin32(_g, renderer, realWidth, realHeight, colorDepth, fullScreen, hertz, flags)
		?
	End Method

	
	Method Flip(restrictFPS:Int=False)
		'we call "."flip so we call the "original flip function"
		If Not restrictFPS
			If vsync Then .Flip 1 Else .Flip 0
		Else
			If vsync Then .Flip 1 Else .Flip -1
		EndIf
	End Method


	Method SetViewport(x:Int, y:Int, w:Int, h:Int)
		'the . means: access globally defined SetViewPort()
		.SetViewport(TVirtualGfx.getInstance().vxoff + x, TVirtualGfx.getInstance().vyoff + y, w, h)
	End Method


	Method GetViewport(x:Int Var, y:Int Var, w:Int Var, h:Int Var)
		'the . means: access globally defined SetViewPort()
		.GetViewport(x, y, w, h)
		x :- TVirtualGfx.getInstance().vxoff
		y :- TVirtualGfx.getInstance().vyoff
	End Method


	Method EnableSmoothLines:Int()
		If renderer = RENDERER_OPENGL Or renderer = RENDERER_BUFFEREDOPENGL
			GlEnable(GL_LINE_SMOOTH)
			Return True
		Else
			Return False
		EndIf
	End Method
End Type


'convenience function
Function GetGraphicsManager:TGraphicsManager()
	Return TGraphicsManager.GetInstance()
End Function