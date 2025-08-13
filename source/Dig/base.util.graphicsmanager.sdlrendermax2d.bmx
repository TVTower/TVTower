Rem
	====================================================================
	Graphicsmanager class
	====================================================================

	Helper to initialize a renderer engine and to setup graphics.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2024-2025 Ronny Otto, digidea.de

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
Import SDL.SDLRenderMax2D
Import SDL.SDLHints

Import "base.util.graphicsmanagerbase.bmx"
Import "base.util.rectangle.bmx"
Import "base.util.logger.bmx"

'ensure manager override base one
TGraphicsManagerSDLRenderMax2D.GetInstance()

Type TGraphicsManagerSDLRenderMax2D Extends TGraphicsManager

	Function GetInstance:TGraphicsManagerSDLRenderMax2D()
		If Not TGraphicsManagerSDLRenderMax2D(_instance) Then _instance = New TGraphicsManagerSDLRenderMax2D
		Return TGraphicsManagerSDLRenderMax2D(_instance)
	End Function
	
	
	Method New()
		'SDLRender specific
		SDLRender_UpdateAvailableRendererBackends()
	End Method


	Method ResizeWindow:Int(width:Int, height:Int) Override
		'bigger than initial resolution!
		Local window:TSDLWindow = TSDLGLContext.GetCurrentWindow()
		'alternatively (recent sdl.mod commits):
		'Local window:TSDLWindow = SDLRenderMax2DDriver().GetCurrentWindow()
		If window
			if width <> windowSize.x or height <> windowSize.y
				'this is a request to the OS which can be denied!
				window.SetSize(width, height)
				
				self.windowSizeValid = False
				
				Return True
			EndIf
		EndIf
		Return False
	End Method
	
	
	Function SDLRender_SetPreferredRendererBackend:Int(rendererBackend:Int)
		'SDLRender specific part
		
		If rendererBackend < 0 or rendererBackend >= RENDERER_BACKEND_NAMES_RAW.length Then Return False

		SDLSetPreferredRenderer( RENDERER_BACKEND_NAMES_RAW[rendererBackend] )

		TLogger.Log("GraphicsManager.SetPreferredRendererBackend()", "[SDLRender] Set preferred renderer to ~q" + RENDERER_BACKEND_NAMES[rendererBackend] + "~q.", LOG_DEBUG)

		Return True
	End Function

	
	Function SDLRender_UpdateAvailableRendererBackends()
		'SDLRender specific part
		
		'potential sdl renderer names as returned by the function
		'the names should be ordered to correspond to "max2D" numbers
		'means at least OpenGL, D3D9 and D3D11 should be in order (0, 1, 2)
		Local sdlRendererNamesRAW:String[] = ["opengl", "direct3d",   "direct3d11",  "direct3d12",  "opengles",    "opengles2", "metal", "vulkan", "gpu", "software"]
		'potential sdl renderer names in a ready-for-print variant
		Local sdlRendererNames:String[]    = ["OpenGL", "Direct3D 9", "Direct3D 11", "Direct3D 12", "OpenGL ES 2", "OpenGL ES", "Metal", "Vulkan", "GPU", "Software"]

		'add all SDL renderer existing in Max2D
		'(so IDs between Max2D and SDLRender stay consistent)
		Rem
		For local i:Int = 0 until max2DRendererID.length
			If max2DRendererID[i] < 0 Then Continue
			RENDERER_BACKEND_NAMES_RAW :+ [sdlRendererNamesRAW[i]]
			RENDERER_BACKEND_NAMES :+ [sdlRendererNames[i]]
			RENDERER_BACKEND_MAX2D_ID :+ [max2DRendererID[i]]
			RENDERER_BACKEND_AVAILABILITY :+ [0]
		Next
		EndRem
		'alternatively:
		RENDERER_BACKEND_NAMES_RAW = sdlRendererNamesRAW
		RENDERER_BACKEND_NAMES = sdlRendererNames
		RENDERER_BACKEND_AVAILABILITY = New Int[sdlRendererNamesRAW.length]
		
			
		'iterate over the SDLRender backends and mark them as available
		'also add not-yet-known-ones if required (should only happen if
		'SDLRender received an update without this code here being touched)
		Local availablesRendererNamesRAW:String[] = SDLGetRendererNames()
		For local r:String = EachIn availablesRendererNamesRAW
			Local sdlRendererIndex:Int = -1
			'identify indices of available renderers 
			For local i:int = 0 until RENDERER_BACKEND_NAMES_RAW.length
				If RENDERER_BACKEND_NAMES_RAW[i] = r.ToLower()
					'set them available
					sdlRendererIndex = i
					exit
				EndIf
			Next

			'add unknown renderer
			If sdlRendererIndex < 0
				sdlRendererIndex = RENDERER_BACKEND_NAMES_RAW.length
				RENDERER_BACKEND_NAMES_RAW :+ [r]
				RENDERER_BACKEND_NAMES :+ [r] 'same as raw!
				RENDERER_BACKEND_AVAILABILITY :+ [1]
			EndIf
			
			'mark available
			SetRendererAvailable(sdlRendererIndex)
		Next
		
		Local renderers:String
		For local i:Int = 0 until RENDERER_BACKEND_NAMES.length
			If Not RENDERER_BACKEND_AVAILABILITY[i] Then Continue
			
			if renderers Then renderers :+ ", "
			renderers :+ RENDERER_BACKEND_NAMES[i]
		Next
		TLogger.Log("GraphicsManager.UpdateAvailableRendererBackends()", "[SDLRender] Added available renderers: ~q" + renderers + "~q.", LOG_DEBUG)
	End Function


	Method RetrieveWindowSize:SVec2I() Override
		'fetch new window size
		Local driver:TSDLRenderMax2DDriver = TSDLRenderMax2DDriver(brl.max2d._max2dDriver)
		If driver
			Local oW:Int, oH:Int
			driver.renderer.GetOutputSize(oW, oH)
			Return New SVec2I(oW, oH)
		Else
			Return windowSize
		EndIf
	End Method



	Method SetRendererBackend:Int(value:Int = 0) Override
		'SDL specific
		If SDLRender_SetPreferredRendererBackend(value)
			rendererBackend = value
			Return True
		Endif
		
		Return False
	End Method


	Method SetScreenMode:Int(screenMode:Int = 0) Override
		If screenMode <> self.screenMode
			'backup last fullscreen mode
			If self.screenMode = SCREENMODE_WINDOWED_FULLSCREEN or self.screenMode = SCREENMODE_FULLSCREEN
				lastFullscreenMode = self.screenMode
			EndIf

			self.screenMode = screenMode 

			'if a window already is created, set mode
			Local window:TSDLWindow = TSDLGLContext.GetCurrentWindow()
			If window
				Select screenMode
					case SCREENMODE_WINDOW
						window.SetFullScreen(0)
					case SCREENMODE_WINDOWED_FULLSCREEN
						window.SetFullScreen(SDL_WINDOW_FULLSCREEN_DESKTOP)
					case SCREENMODE_FULLSCREEN
						window.SetFullScreen(SDL_WINDOW_FULLSCREEN)
				End Select
				Return True
			EndIf
		EndIf
		Return False
	End Method


	Method SetVSync:Int(bool:Int = True) override
		vsync = bool

		Local driver:TSDLRenderMax2DDriver = TSDLRenderMax2DDriver(brl.max2d._max2dDriver)
		If driver and driver.renderer.SetVSync(bool) = 0
			Return True
		Else
			Return False
		EndIf
	End Method

	
	
	Method CreateGraphicsObject:TGraphics(windowSize:SVec2I, colorDepth:Int, hertz:Int, flags:Long, fullscreenMode:Int, smoothPixels:Int) override
		If fullscreenMode = SCREENMODE_WINDOWED_FULLSCREEN
			flags :| SDL_WINDOW_FULLSCREEN_DESKTOP
			TLogger.Log("GraphicsManager.CreateGraphicsObject()", "Set SDL Render to use windowed fullscreen mode.", LOG_DEBUG)
		ElseIf fullscreenMode = SCREENMODE_FULLSCREEN
			flags :| SDL_WINDOW_FULLSCREEN
			TLogger.Log("GraphicsManager.CreateGraphicsObject()", "Set SDL Render to use exclusive fullscreen mode.", LOG_DEBUG)
		Else
			TLogger.Log("GraphicsManager.CreateGraphicsObject()", "Set SDL Render to use window mode.", LOG_DEBUG)
		EndIf

		If vsync
			flags :| GRAPHICS_SWAPINTERVAL1
			TLogger.Log("GraphicsManager.CreateGraphicsObject()", "Set SDL Render to use vertical sync.", LOG_DEBUG)
		Else
			TLogger.Log("GraphicsManager.CreateGraphicsObject()", "Set SDL Render to ignore vertical sync.", LOG_DEBUG)
		EndIf

		If smoothPixels
			SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1") 'smooth
			TLogger.Log("GraphicsManager.CreateGraphicsObject()", "Set window canvas to smooth pixels.", LOG_DEBUG)
		Else
			SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0") 'pixel
			TLogger.Log("GraphicsManager.CreateGraphicsObject()", "Set window canvas to keep pixels non-smoothed.", LOG_DEBUG)
		EndIf

		'set sdlrendermax2d as active driver
		SetGraphicsDriver SDLRenderMax2DDriver()

		flags :| SDL_WINDOW_RESIZABLE
		TLogger.Log("GraphicsManager.CreateGraphicsObject()", "Set windows to be resizable.", LOG_DEBUG)

		'actually create the graphics object
		If fullscreenMode <> SCREENMODE_FULLSCREEN
			colorDepth = 0 'only exclusive fullscreen allows colorDepth setting
		EndIf

		Local g:TGraphics = Graphics(windowSize.x, windowSize.y, colorDepth*IsFullScreen(), hertz, flags)
		
		Return g
	End Method

'rem
	Method CurrentCanvasMouseX:Int() Override
		'SDL already subtracts letterbox offsets from mouse coordinates
		' (so negative values left/top of the content)
		'Return MouseX() 'self.WindowMouseX() - canvasPos.x

		Local x:Int = self.WindowMouseX()
		'make a local coordinate
		x :- canvasPos.x
		'also scale it
		x :* designedSize.x / Float(canvasSize.x)
		Return x
	End Method


	Method CurrentCanvasMouseY:Int() Override
		'SDL already subtracts letterbox offsets from mouse coordinates
		' (so negative values left/top of the content)
		'Return MouseY() 'self.WindowMouseY() - canvasPos.y
		
		Local y:Int = self.WindowMouseY()
		'make a local coordinate
		y :- canvasPos.y
		'also scale it
		y :* designedSize.y / Float(canvasSize.y)
		Return y
	End Method


	Method WindowMouseX:Int() Override
		'SDL already subtracts letterbox offsets from mouse coordinates
		' (so negative values left/top of the content)
		'SDL seems to not always do that
		' (it lazy-adds ... once the first thing is drawn/render command
		'  is used)
		'This is why we retrieve it from SDL on our own here
		Local cursorX:Int, cursorY:Int
		MouseState(varptr cursorX, varptr cursorY)
		Return cursorX
	End Method


	Method WindowMouseY:Int() Override
		'SDL seems to not always add letterbox to coordinates
		'(it lazy-adds ... once the first thing is drawn/render command
		' is used)
		'this is why we retrieve it from SDL on our own here
		Local cursorX:Int, cursorY:Int
		MouseState(varptr cursorX, varptr cursorY)
		Return cursorY
	End Method
'endrem
End Type


'convenience function
Function GetGraphicsManagerSDLRenderMax2D:TGraphicsManagerSDLRenderMax2D()
	Return TGraphicsManagerSDLRenderMax2D.GetInstance()
End Function

