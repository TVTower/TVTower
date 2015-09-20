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
?bmxng
Import sdl.gl2sdlmax2d
Import pub.opengles
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
	Field fullscreen:int	= 0
	Field renderer:int		= 0
	Field colorDepth:int	= 16
	Field realWidth:int		= 800
	Field realHeight:int	= 600
	Field designedWidth:int	= -1
	Field designedHeight:int= -1
	Field hertz:int			= 60
	Field vsync:int			= TRUE
	Field flags:Int			= 0 'GRAPHICS_BACKBUFFER | GRAPHICS_ALPHABUFFER '& GRAPHICS_ACCUMBUFFER & GRAPHICS_DEPTHBUFFER
	Global _instance:TGraphicsManager
	Global _g:TGraphics
	Global RENDERER_NAMES:string[] = [	"OpenGL",..
										"DirectX 7", ..
										"DirectX 9", ..
										"Buffered OpenGL", ..
										"GL2SDL" ..
									 ]
	CONST RENDERER_OPENGL:int   		= 0
	CONST RENDERER_DIRECTX7:int 		= 1
	CONST RENDERER_DIRECTX9:int 		= 2
	CONST RENDERER_BUFFEREDOPENGL:int   = 3
	CONST RENDERER_GL2SDL:int           = 4


	Function GetInstance:TGraphicsManager()
		If not _instance Then _instance = New TGraphicsManager
		Return _instance
	End Function



	Method SetResolution:int(width:int, height:int)
		realWidth = width
		realHeight = height
	End Method


	'set the resolution the assets are designed for
	'things get resized according the real resolution
	Method SetDesignedResolution:int(width:int, height:int)
		designedWidth = width
		designedHeight = height
	End Method


	'ATTENTION: there is no guarantee that it works flawless on
	'all computers (graphics context/images might have to be
	'initialized again)
	Method SetFullscreen:Int(bool:int = TRUE)
		if fullscreen <> bool
			fullscreen = bool
			'create a new graphics object if already in graphics mode
			if _g then InitGraphics()
		endif
	End Method
	

	Method GetFullscreen:Int()
		return (fullscreen = true)
	End Method


	Method SetVSync:Int(bool:int = TRUE)
		vsync = bool
	End Method


	Method SetHertz:Int(value:int=0)
		hertz = value
	End Method


	Method SetColordepth:Int(value:int=0)
		colorDepth = value
	End Method
	

	Method GetColordepth:Int()
		return colorDepth
	End Method


	Method SetRenderer:Int(value:int = 0)
		renderer = value
	End Method


	Method GetRenderer:Int()
		return renderer
	End Method
	

	Method GetRendererName:String(forRenderer:int=-1)
		if forRenderer = -1 then forRenderer = self.renderer
		if forRenderer < 0 or forRenderer > RENDERER_NAMES.length
			return "UNKNOWN"
		else
			return RENDERER_NAMES[forRenderer]
		endif
	End Method


	Method SetFlags:Int(value:int = 0)
		flags = value
	End Method


	Method GetHeight:int()
		if designedHeight = -1 then return realHeight
		return designedHeight
	End Method


	Method GetWidth:int()
		if designedWidth = -1 then return realWidth
		return designedWidth
	End Method


	Method GetRealHeight:int()
		return realHeight
	End Method


	Method GetRealWidth:int()
		return realWidth
	End Method


	Method HasBlackBars:int()
		if designedWidth = -1 and designedHeight = -1 then return False
		return designedWidth <> realWidth or designedHeight <> realHeight
	End Method
	

	'switch between fullscreen or windowed mode
	Method SwitchFullscreen:int()
		SetFullscreen(1 - GetGraphicsManager().GetFullscreen())
	End Method


	Method InitGraphics:Int()
		'initialize virtual graphics only when "InitGraphics()" is run
		'for the first time
		if not _g then InitVirtualGraphics()

		'needed to allow ?win32 + ?bmxng
		?win32
		_InitGraphicsWin32()
		?not win32
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
			?not android
			Default SetGraphicsDriver GLMax2DDriver()
			?
		EndSelect

		_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)

		if not _g then Throw "Graphics initiation error! no render engine available."
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

	
	Method Flip(restrictFPS:int=FALSE)
		'we call "."flip so we call the "original flip function"
		If Not restrictFPS
			if vsync then .Flip 1 else .Flip 0
		Else
			if vsync then .Flip 1 else .Flip -1
		EndIf
	End Method


	Method SetViewPort(x:int, y:int, w:int, h:int)
		'the . means: access globally defined SetViewPort()
		.SetViewPort(TVirtualGfx.getInstance().vxoff + x, TVirtualGfx.getInstance().vyoff + y, w, h)
	End Method


	Method GetViewPort(x:int var, y:int var, w:int var, h:int var)
		'the . means: access globally defined SetViewPort()
		.GetViewPort(x, y, w, h)
		x :- TVirtualGfx.getInstance().vxoff
		y :- TVirtualGfx.getInstance().vyoff
	End Method


	Method EnableSmoothLines:int()
		if renderer = RENDERER_OPENGL or renderer = RENDERER_BUFFEREDOPENGL
			return GlEnable(GL_LINE_SMOOTH)
		else
			return False
		endif
	End Method
End Type


'convenience function
Function GetGraphicsManager:TGraphicsManager()
	Return TGraphicsManager.GetInstance()
End Function