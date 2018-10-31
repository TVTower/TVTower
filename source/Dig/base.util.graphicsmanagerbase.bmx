Rem
	====================================================================
	Graphicsmanager class
	====================================================================

	Helper to initialize a renderer engine and to setup graphics.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2018 Ronny Otto, digidea.de

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
'?MacOs
'Import BRL.GLMax2D
'?Win32
'Import BRL.GLMax2D
'Import "base.util.graphicsmanager.win32.bmx"
'?Linux
'Import BRL.GLMax2D
'Import "../source/external/bufferedglmax2d/bufferedglmax2d.bmx"
'?
'?bmxng
'?android
'Import sdl.gl2sdlmax2d
'?

Import "base.util.virtualgraphics.bmx"
Import "base.util.logger.bmx"


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
	Field flags:Int			= 0 'GRAPHICS_BACKBUFFER '0 'GRAPHICS_BACKBUFFER | GRAPHICS_ALPHABUFFER '& GRAPHICS_ACCUMBUFFER & GRAPHICS_DEPTHBUFFER
	Global _instance:TGraphicsManager
	Global _g:TGraphics
	Global RENDERER_NAMES:String[] = [	"OpenGL",..
										"DirectX 7", ..
										"DirectX 9", ..
										"DirectX 11", ..
										"Buffered OpenGL", ..
										"GL2SDL" ..
									 ]
	Global RENDERER_AVAILABILITY:Int[] = [ False, False, False, False, False, False ]

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


	Function SetRendererAvailable(index:int, bool:int=True)
		if index >= RENDERER_AVAILABILITY.length then return
		'setall
		if index < 0
			for local i:int = 0 until RENDERER_AVAILABILITY.length
				SetRendererAvailable(i, bool)
			next
		elseif index < RENDERER_AVAILABILITY.length
			RENDERER_AVAILABILITY[index] = bool
		else
			Throw "Renderer index ~q"+ index+"~q is out of bounds."
		endif
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
	Method SetFullscreen:Int(bool:Int = True, reInitGraphics:Int = True)
		If fullscreen <> bool
			fullscreen = bool
			'create a new graphics object if already in graphics mode
			If _g And reInitGraphics Then InitGraphics()

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
		SetFullscreen(1 - GetFullscreen())
	End Method


	Method InitGraphics:Int()
		TLogger.Log("GraphicsManager.InitGraphics()", "Initializing graphics.", LOG_DEBUG)

		'initialize virtual graphics only when "InitGraphics()" is run
		'for the first time
		If Not _g Then InitVirtualGraphics()

		'close old one
		If _g Then CloseGraphics(_g)

		'needed to allow ?win32 + ?bmxng
'		?win32
'		_InitGraphicsWin32()
'		?Not win32
		_InitGraphicsDefault()
'		?
		If Not _g
			TLogger.Log("GraphicsManager.InitGraphics()", "Failed to initialize graphics.", LOG_ERROR)
			Throw "Failed to initialize graphics! No render engine available."
			End
		EndIf

		'now "renderer" contains the ID of the used renderer
		TLogger.Log("GraphicsManager.InitGraphics()", "Initialized graphics with ~q"+GetRendererName()+"~q.", LOG_DEBUG)


		SetBlend ALPHABLEND
		SetMaskColor 0, 0, 0
		HideMouse()

		'virtual resolution
		SetVirtualGraphics(GetWidth(), GetHeight(), False)
		TLogger.Log("GraphicsManager.InitGraphics()", "Initialized virtual graphics (for optional letterboxes).", LOG_DEBUG)
	End Method

	Method _InitGraphicsDefault:Int() 'Abstract
	End Method

Rem
	Method _InitGraphicsDefault:Int()
		Select renderer
			'buffered gl?
			'?android
			?bmxng
			Default
				TLogger.Log("GraphicsManager.InitGraphics()", "SetGraphicsDriver ~qGL2SDL~q.", LOG_DEBUG)
				SetGraphicsDriver GL2Max2DDriver()
				renderer = RENDERER_GL2SDL
			'?Not android
			?Not bmxng
			Default
				TLogger.Log("GraphicsManager.InitGraphics()", "SetGraphicsDriver ~qOpenGL~q.", LOG_DEBUG)
				SetGraphicsDriver GLMax2DDriver()
				renderer = RENDERER_OPENGL
			?
		End Select

		_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)
	End Method
End Rem
Rem
	'cannot "?win32" this method as this disables "?not bmxng" in this method
	Method _InitGraphicsWin32:Int()
		?win32
		'done in base.util.graphicsmanager.win32.bmx
		'alternatively to "_g = Func(_g,...)"
		'SetRenderWin32 could also use "_g:TGraphics var"
		'attention: renderer is passed by referenced (might be changed)
		'           during execution of SetRendererWin32(...)
		_g = SetRendererWin32(_g, renderer, realWidth, realHeight, colorDepth, fullScreen, hertz, flags)
		?
	End Method
End Rem

	Method ResetVirtualGraphicsArea()
		TVirtualGfx.ResetVirtualGraphicsArea()
	End Method


	Method SetupVirtualGraphicsArea()
		TVirtualGfx.SetupVirtualGraphicsArea()
	End Method


	Method Cls()
		Local x:Int, y:Int, w:Int, h:Int
		.GetViewport(x,y,w,h)
		.SetViewport( 0, 0, GraphicsWidth(), GraphicsHeight() )
		brl.max2d.Cls()
		.SetViewport(x,y,w,h)
'		SetViewport( TVirtualGfx.GetInstance().vxoff, TVirtualGfx.GetInstance().vyoff, TVirtualGfx.GetInstance().vwidth, TVirtualGfx.GetInstance().vheight )
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
		'limit the viewport to the virtual dimension (to disable drawing
		'on the black bars)

		x = Max(0, x)
		y = Max(0, y)

		'the . means: access globally defined SetViewPort()
		.SetViewport(TVirtualGfx.getInstance().vxoff + x, ..
		             TVirtualGfx.getInstance().vyoff + y, ..
		             Min(w, TVirtualGfx.getInstance().vWidth - x), ..
		             Min(h, TVirtualGfx.getInstance().vHeight - y) ..
		            )
	End Method


	Method GetViewport(x:Int Var, y:Int Var, w:Int Var, h:Int Var)
		'the . means: access globally defined SetViewPort()
		.GetViewport(x, y, w, h)
		x :- TVirtualGfx.getInstance().vxoff
		y :- TVirtualGfx.getInstance().vyoff
	End Method


	Method EnableSmoothLines:Int()
		Return False
	End Method

	Method CenterDisplay()
	End Method

End Type


'convenience function
Function GetGraphicsManager:TGraphicsManager()
	Return TGraphicsManager.GetInstance()
End Function

