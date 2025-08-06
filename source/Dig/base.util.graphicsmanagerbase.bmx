Rem
	====================================================================
	Graphicsmanager class
	====================================================================

	Helper to initialize a renderer engine and to setup graphics.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2002-2025 Ronny Otto, digidea.de

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
Import sdl.SDLGraphics

Import "base.util.virtualgraphics.bmx"
Import "base.util.rectangle.bmx"
Import "base.util.logger.bmx"


Type TGraphicsManager
	Field fullscreen:Int	= 0
	Field renderer:Int		= 0 'remove
	Field rendererBackend:Int
	Field colorDepth:Int	= 16
	'drawable canvas dimensions
	Field canvasSize:SVec2I = New SVec2I(800, 600)
	Field canvasStretchMode:Int = 0       ' no stretch
	'designed application dimensions (scaled to the canvas dimensions)
	Field designedSize:SVec2I = New SVec2I(-1, -1)
	'window dimensions
	Global windowSize:SVec2I
	Global windowSizeValid:Int

	Const STRETCHMODE_NONE:Int = 0      ' keep size
	Const STRETCHMODE_FULL:Int = 1      ' use full window
	Const STRETCHMODE_SCALE:Int = 2     ' adjust to window aspect ratio
	Const STRETCHMODE_LETTERBOX:Int = 3 ' keep aspect ratio

	Field hertz:Int			= 60
	Field vsync:Int			= True
	Field flags:Int			= 0 'GRAPHICS_BACKBUFFER '0 'GRAPHICS_BACKBUFFER | GRAPHICS_ALPHABUFFER '& GRAPHICS_ACCUMBUFFER & GRAPHICS_DEPTHBUFFER

	Field viewportStack:SRectI[] = new SRectI[0]
	Field viewportStackIndex:Int = -1
	Global _instance:TGraphicsManager
	Global _g:TGraphics
	Global RENDERER_BACKEND_NAMES_RAW:String[]  'name of the renderer eg used internally
	Global RENDERER_BACKEND_NAMES:String[]      'printable name of the renderer
	Global RENDERER_BACKEND_MAX2D_ID:Int[]      'numeric key (for ini files)
	Global RENDERER_BACKEND_AVAILABILITY:Int[]  'is that renderer available?

	Const RENDERER_BACKEND_OPENGL:Int   = 0
	Const RENDERER_BACKEND_D3D9:Int     = 1
	Const RENDERER_BACKEND_D3D11:Int    = 2


	Function GetInstance:TGraphicsManager()
		If Not _instance Then _instance = New TGraphicsManager
		Return _instance
	End Function


	Method New()
		If not _instance
			AddHook(EmitEventHook, WindowResizedHook, Null,-10000)
		EndIf
	End Method


	' "Window resized" is emit if the window is manually resized
	' either via "double click" on the window title bar or by dragging
	' of one window border. It is NOT emit on internal resize commands
	' like "window.setSize()" 
	Function WindowResizedHook:Object( id:Int, data:Object,context:Object )
		Local ev:TEvent=TEvent( data )
		If Not ev Return Null
		If ev.id <> EVENT_WINDOWSIZE Then Return Null
		
		TGraphicsManager.windowSizeValid = False
	End Function


	Function SetRendererAvailable(index:int, bool:int=True)
		if index >= RENDERER_BACKEND_AVAILABILITY.length then return
		'setall
		if index < 0
			for local i:int = 0 until RENDERER_BACKEND_AVAILABILITY.length
				SetRendererAvailable(i, bool)
			next
		elseif index < RENDERER_BACKEND_AVAILABILITY.length
			RENDERER_BACKEND_AVAILABILITY[index] = bool
		else
			Throw "Renderer index ~q"+ index+"~q is out of bounds."
		endif
	End Function


	Method ResizeWindow:Int(width:Int, height:Int)
		print "ResizeWindow() not implemented"
	End Method


	Method CenterWindow()
		print "CenterWindow() not implemented"
	End Method


	' "window maximizing" can lead to a resize-event but eg. the SDL
	' renderer is still spitting out the old value (driver.renderer.GetOutputSize())
	' this is why the window size has to be recalculated in a "lazy"
	' way (aka on next frame).
	Method UpdateWindowSize:Int()
		If Not windowSizeValid
			Local newSize:SVec2I = RetrieveWindowSize()
			
			windowSizeValid = True

			If windowSize.x <> newSize.x Or windowSize.y <> newSize.y
				windowSize = newSize
				
				UpdateCanvasSize()

				If viewportStackIndex >= 0
					self.SetViewport( viewportStack[viewportStackIndex] )
				Else
					self.SetViewport(0,0, canvasSize.x, canvasSize.y)
				EndIf

				Return True
			EndIf
		EndIf

		Return False
	End Method
	
	
	Method RetrieveWindowSize:SVec2I()
		return windowSize
	End Method


	Method UpdateCanvasSize:Int()
		'by default nothing is done there
	End Method


	Method SetCanvasSize:Int(width:Int, height:Int)
		If canvasSize.x <> width Or canvasSize.y <> height
			canvasSize = New SVec2I(width, height)
			Return True
		Else
			Return False
		EndIf
	End Method


	'set the canvas size the assets are designed for
	'things get resized according the real canvas size
	Method SetDesignedSize:Int(width:Int, height:Int)
		If designedSize.x <> width Or designedSize.y <> height
			designedSize = New SVec2I(width, height)
			Return True
		Else
			Return False
		EndIf
	End Method


	'ATTENTION: there is no guarantee that it works flawless on
	'all computers (graphics context/images might have to be
	'initialized again)
	Method SetFullscreen:Int(bool:Int = True, reInitGraphics:Int = True)
		If fullscreen <> bool
			fullscreen = bool
			'create a new graphics object if already in graphics mode
			If _g And reInitGraphics Then InitGraphics(windowSize.x, windowSize.y)

			Return True
		EndIf
		Return False
	End Method


	Method GetFullscreen:Int()
		Return (fullscreen = True)
	End Method


	'switch between fullscreen or windowed mode
	Method SwitchFullscreen:Int()
		SetFullscreen(1 - GetFullscreen())
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


	Method SetRendererBackend:Int(value:Int = 0)
		If rendererBackend <> value
			rendererBackend = value
			Return True
		Else
			Return False
		EndIf
	End Method


	Method GetRendererBackend:Int()
		Return rendererBackend
	End Method


	Method GetRendererBackendName:String(forRendererBackend:Int = -1)
		If forRendererBackend = -1 Then forRendererBackend = Self.rendererBackend
		If forRendererBackend < 0 Or forRendererBackend > RENDERER_BACKEND_NAMES.length
			Return "UNKNOWN"
		Else
			Return RENDERER_BACKEND_NAMES[forRendererBackend]
		EndIf
	End Method


	Method SetFlags:Int(value:Long)
		flags = value
	End Method


	Method GetHeight:Int()
		If designedSize.y = -1 Then Return canvasSize.y

		Return designedSize.y
	End Method


	Method GetWidth:Int()
		If designedSize.x = -1 Then Return canvasSize.x

		Return designedSize.x
	End Method


	Method GetCanvasHeight:Int()
		Return canvasSize.y
	End Method


	Method GetCanvasWidth:Int()
		Return canvasSize.x
	End Method


	Method HasBlackBars:Int()
		If designedSize.x = -1 And designedSize.y = -1 Then Return False

		Return designedSize <> canvasSize
	End Method


	Method InitGraphics(width:Int, height:Int, flags:Long = 0)
		TLogger.Log("GraphicsManager.InitGraphics()", "Initializing graphics.", LOG_DEBUG)

		windowSize = New SVec2I(width, height)

		'initialize virtual graphics only when "InitGraphics()" is run
		'for the first time
		If Not _g Then InitVirtualGraphics()

		'close old one
		If _g Then CloseGraphics(_g)

		Local smoothPixels:Int = False 'TODO: remove/make configurable
		flags = _PrepareGraphics(flags, smoothPixels)
		_g = Graphics(windowSize.x, windowSize.y, colorDepth*fullScreen, hertz, flags)

		'now window is created, allow the driver to update window size
		'if required
		UpdateWindowSize()

		If Not _g
			TLogger.Log("GraphicsManager.InitGraphics()", "Failed to initialize graphics.", LOG_ERROR)
			Throw "Failed to initialize graphics! No render engine available."
			End
		EndIf

		'now "renderer" contains the ID of the used renderer
		TLogger.Log("GraphicsManager.InitGraphics()", "Initialized graphics with backend ~q"+GetRendererBackendName()+"~q.", LOG_DEBUG)


		SetBlend ALPHABLEND
		SetMaskColor 0, 0, 0
		HideMouse()

		'virtual resolution
		SetVirtualGraphics(GetWidth(), GetHeight(), False)
		TLogger.Log("GraphicsManager.InitGraphics()", "Initialized virtual graphics (for optional letterboxes).", LOG_DEBUG)
	End Method


	Method _PrepareGraphics:Long(flags:Long, smoothPixels:Int = False)
		Return flags
	End Method


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


	Method BackupAndSetViewport(newViewport:SRectI)
		BackupViewport()
		SetViewport(newViewport)
	End Method

	
	Method BackupViewport:SRectI()
		viewportStackIndex :+ 1
		'resize stack
		if viewportStack.length <= viewPortStackIndex
			viewportStack = viewportStack[.. viewportStack.length + 10]

			if viewportStack.length >= 500 Then Throw "Too many viewports put to stack: " + viewportStack.length
		endif

		viewPortStack[viewPortStackIndex] = GetViewportRect()

		return viewPortStack[viewPortStackIndex]
	End Method


	Method RestoreViewport:Int()
		if viewportStackIndex < 0 then return False
		
		self.SetViewport( viewportStack[viewportStackIndex] )
		viewportStackIndex :- 1
		
		return True
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


	Method SetViewport(r:TRectangle)
		self.SetViewport(int(r.x), int(r.y), int(r.w), int(r.h))
	End Method

	Method SetViewport(r:SRectI)
		self.SetViewport(r.x, r.y, r.w, r.h)
	End Method


	Method GetViewport(x:Int Var, y:Int Var, w:Int Var, h:Int Var)
		'the . means: access globally defined SetViewPort()
		.GetViewport(x, y, w, h)
		x :- TVirtualGfx.getInstance().vxoff
		y :- TVirtualGfx.getInstance().vyoff
	End Method
	
	
	Method GetViewportRect:SRectI()
		Local vpX:int, vpY:int, vpW:int, vpH:Int
		'the . means: access globally defined SetViewPort()
		.GetViewport(vpX, vpY, vpW, vpH)

		Return New SRectI(vpX - TVirtualGfx.getInstance().vxoff, ..
		                  vpY - TVirtualGfx.getInstance().vyoff, ..
		                  vpW, ..
		                  vpH)
	End Method
		

	Method EnableSmoothLines:Int()
		Return False
	End Method
End Type


'convenience function
Function GetGraphicsManager:TGraphicsManager()
	Return TGraphicsManager.GetInstance()
End Function

