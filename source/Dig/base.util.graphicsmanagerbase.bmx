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
Import BRL.Max2D

Import "base.util.rectangle.bmx"
Import "base.util.logger.bmx"
Import "base.util.time.bmx"


Type TGraphicsManager
	Field displayMode:Int = 0     '0 = DISPLAYMODE_WINDOW, 1 = DISPLAYMODE_WINDOWED_FULLSCREEN, ...
	Field lastFullscreenMode:Int = 0 'previous fullscreen variant used
	Field renderer:Int = 0           'remove
	Field rendererBackend:Int
	Field colorDepth:Int = 16
	'drawable canvas dimensions
	Field canvasPos:SVec2I = New SVec2I(0, 0)
	Field canvasSize:SVec2I = New SVec2I(800, 600)
	'designed application dimensions (scaled to the canvas dimensions)
	Field designedSize:SVec2I = New SVec2I(-1, -1)
	'window dimensions
	Global windowSize:SVec2I
	Global windowSizeValid:Int

	Field hertz:Int			= 60
	Field vsync:Int			= True
	Field flags:Int			= 0 'GRAPHICS_BACKBUFFER '0 'GRAPHICS_BACKBUFFER | GRAPHICS_ALPHABUFFER '& GRAPHICS_ACCUMBUFFER & GRAPHICS_DEPTHBUFFER

	'to allow smooth window resizing, the manager disables a previously
	'activated vsync-flag (eg SDL blocks when waiting for vsync, so 
	'window resizing with enabled vsync becomes very sluggish)
	Global windowResizeActive:Int
	Global _windowResizeLastTime:Long
	Global _windowResizeVsyncWasOn:Int
	Global _windowResizeActiveTime:Int = 200 'reactivate vsync X ms after last resize event 

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
	
	Const DISPLAYMODE_WINDOW:Int              = 0
	Const DISPLAYMODE_WINDOWED_FULLSCREEN:Int = 1
	Const DISPLAYMODE_FULLSCREEN:Int          = 2


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

		'update smooth-resize logic
		TGraphicsManager._windowResizeActiveTime = Time.MillisecsLong()
		'deactivate vsync if some resize is happening
		If Not TGraphicsManager.windowResizeActive
			TGraphicsManager.windowResizeActive = True
			'only fetch state on "resize start" (as deactivation sets
			'vsync value to False.
			TGraphicsManager._windowResizeVsyncWasOn = TGraphicsManager.GetInstance().vsync
			If TGraphicsManager._windowResizeVsyncWasOn
				TGraphicsManager.GetInstance().SetVSync(False)
			EndIf
		EndIf
		'pay attention to re-enable vsync (eg. calling the manager's flip)
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


	Function IsRendererAvailable:Int(index:int)
		if index >= RENDERER_BACKEND_AVAILABILITY.length then return False
		if index < 0 then return False

		Return RENDERER_BACKEND_AVAILABILITY[index]
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
				
				If viewportStackIndex >= 0
					self.SetViewport( viewportStack[viewportStackIndex] )
				Else
					self.ResetViewport()
				EndIf

				UpdateCanvasInformation()

				Return True
			Else
				UpdateCanvasInformation()
			EndIf
		EndIf

		Return False
	End Method
	
	
	Method RetrieveWindowSize:SVec2I()
		return windowSize
	End Method
	
	
	Method UpdateCanvasInformation:Int()
		UpdateCanvasSize()

		'move canvas into position
		'we are defaulting to "letterbox"
		canvasPos = New SVec2I((windowSize.x - canvasSize.x)/2, (windowSize.y - canvasSize.y)/2)
	End Method




	Method UpdateCanvasSize:Int()
		Local oldSize:SVec2I = canvasSize
		
		'either window size zero or canvas size zero
		If (windowSize.x = 0 or windowSize.y = 0)
			canvasSize = New SVec2I(0,0)
		Else
			'defaulting to letterbox

			' compare aspect ratios and use min of it
			Local canvasW:Int = canvasSize.x
			Local canvasH:Int = canvasSize.y
			'use original size if possible as we scale nonetheless
			'but now avoid taking over rounding issues with each update
			If designedSize.x > 0
				canvasW = designedSize.x
				canvasH = designedSize.Y
			EndIf
				
			'take over window size / auto size ?
			if canvasW < 0 Then canvasW = windowSize.x
			if canvasH < 0 Then canvasH = windowSize.y

			'to keep aspect ratio, scale both to minimum of both
			Local minScale:Float = min(windowSize.x / Float(canvasW), windowSize.y / Float(canvasH))

			canvasSize = New SVec2I(Int(canvasW * minScale), Int(canvasH * minScale))
			'print "minScale: " + minScale + "   windowSize="+windowSize.x+", " + windowSize.y + "  canvasWH="+canvasW+", " + canvasH + "  -> new canvasSize: " + canvasSize.x + ", " +canvasSize.y
		EndIf
	End Method


	Method SetCanvasSize:Int(width:Int, height:Int)
		If canvasSize.x <> width Or canvasSize.y <> height
			canvasSize = New SVec2I(width, height)
			
			UpdateCanvasInformation()

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

			'update virtual resolution if graphics object already exists
			If _g
				'update viewport too
				rem
				Local oldVirtualResolutionW:Int = VirtualResolutionWidth()
				Local oldVirtualResolutionH:Int = VirtualResolutionHeight()
				if width <> oldVirtualResolutionW or oldVirtualResolutionH <> height
					'TODO - scale viewport?
				EndIf
				endrem
				'for now: simply set viewport to full window again

				'print "SetDesignedSize: virtual res: " + Int(VirtualResolutionWidth())+"x"+Int(VirtualResolutionHeight()) + " -> " + width+"x"+height	
				SetVirtualResolution(width, height)
				SetViewport(0, 0, width, height)
				'print "               : virtual res: " + Int(VirtualResolutionWidth())+"x"+Int(VirtualResolutionHeight()) + " -> " + width+"x"+height	
			EndIf

			Return True
		Else
			Return False
		EndIf
	End Method
	
	
	'Switch display mode
	'fullscreenMode:
	'  DISPLAYMODE_WINDOW (0)
	'  DISPLAYMODE_WINDOWED_FULLSCREEN (1)
	'  DISPLAYMODE_FULLSCREEN (2)
	Method SetDisplayMode:Int(displayMode:Int = 0)
		If displayMode <> self.displayMode
			'backup last fullscreen mode
			If self.displayMode = DISPLAYMODE_WINDOWED_FULLSCREEN or self.displayMode = DISPLAYMODE_FULLSCREEN
				lastFullscreenMode = self.displayMode
			EndIf
		
			self.displayMode = displayMode

			Return True
		EndIf
		Return False
	End Method


	Method IsFullscreen:Int()
		Return displayMode = DISPLAYMODE_FULLSCREEN or displayMode = DISPLAYMODE_WINDOWED_FULLSCREEN
	End Method


	'switch between fullscreen or window mode
	Method SwitchFullscreen:Int()
		If displayMode = DISPLAYMODE_WINDOW
			'switch to windowed fullscreen except last was exclusive fullscreen
			If lastFullscreenMode <> DISPLAYMODE_FULLSCREEN
				SetDisplayMode(DISPLAYMODE_WINDOWED_FULLSCREEN)
			Else
				SetDisplayMode(DISPLAYMODE_FULLSCREEN)
			EndIf
		Else
			SetDisplayMode(DISPLAYMODE_WINDOW)
		EndIf
	End Method


	Method SetVSync:Int(bool:Int = True)
		If vsync <> bool
			' avoid window resize smoother to turn on a now manually
			' deactivated vsync
			if not bool then _windowResizeVsyncWasOn = False

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


	Method GetRendererBackend:Int(backendName:String)
		backendName = backendName.ToLower()
		For local i:Int = 0 until RENDERER_BACKEND_NAMES.length
			if RENDERER_BACKEND_NAMES[i].ToLower() = backendName Then return i
		Next
		Return -1
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

		Return canvasSize <> windowSize
	End Method


	Method InitGraphics(width:Int, height:Int, flags:Long = 0)
		TLogger.Log("GraphicsManager.InitGraphics()", "Initializing graphics.", LOG_DEBUG)
		'close old one
		If _g
			TLogger.Log("GraphicsManager.InitGraphics()", "Closing previous graphics object.", LOG_DEBUG)
			CloseGraphics(_g)
		EndIf


		windowSize = New SVec2I(width, height)
		windowSizeValid = False

		Local smoothPixels:Int = False 'TODO: remove/make configurable
		_g = CreateGraphicsObject(windowSize, colorDepth, hertz, flags, displayMode, smoothPixels)
		
		'now window is created, allow the driver to update window size
		'if required
		UpdateWindowSize()

		If Not _g
			TLogger.Log("GraphicsManager.InitGraphics()", "Failed to initialize graphics.", LOG_ERROR)
			Throw "Failed to initialize graphics! No render engine available."
			End
		EndIf

		'now "renderer" contains the ID of the used renderer
		TLogger.Log("GraphicsManager.InitGraphics()", "Initialized graphics with backend ~q"+GetRendererBackendName()+"~q. Window size " + windowSize.x + "x" + windowSize.y + ".", LOG_DEBUG)


		SetBlend ALPHABLEND
		SetMaskColor 0, 0, 0
		HideMouse()

		'print "SetDesignedSize: virtual res: " + Int(VirtualResolutionWidth())+"x"+Int(VirtualResolutionHeight()) + " -> " + designedSize.x+"x"+designedSize.y	
		SetVirtualResolution(designedSize.x, designedSize.y)
		'set viewport to full "canvas"
		SetViewport(0, 0, designedSize.x, designedSize.y)

	End Method
	
	
	Method CreateGraphicsObject:TGraphics(windowSize:SVec2I, colorDepth:Int, hertz:Int, flags:Long, fullscreen:Int, smoothPixels:Int)
		Local g:TGraphics = Graphics(windowSize.x, windowSize.y, colorDepth*fullScreen, hertz, flags)
		Return g
	End Method


	'the designed mouse position must be a float, as the virtual canvas
	'can be scaled into the real canvas (and window)
	Method DesignedMouseX:Float()
		'TODO: "canvas" as parameter - default to "current canvas"

		Local x:Float = self.WindowMouseX()
		'make a local coordinate
		x :- canvasPos.x
		'also scale it
		x :* designedSize.x / Float(canvasSize.x)
		Return x
	End Method


	'the designed mouse position must be a float, as the virtual canvas
	'can be scaled into the real canvas (and window)
	Method DesignedMouseY:Float()
		'TODO: "canvas" as parameter - default to "current canvas"

		Local y:Float = self.WindowMouseY()
		'make a local coordinate
		y :- canvasPos.y
		'also scale it
		y :* designedSize.y / Float(canvasSize.y)
		Return y
	End Method


	Method DesignedMoveMouse(x:Float, y:Float)
		' clamp to virtual canvas (design area) 
		Local cx:Float = Min(designedSize.x-1, Max(0, x))
		Local cy:Float = Min(designedSize.y-1, Max(0, y))

		' window positions (Float)
		Local winX:Float = cx * canvasSize.x / Float(designedSize.x) + canvasPos.x
		Local winY:Float = cy * canvasSize.y / Float(designedSize.y) + canvasPos.y
		
		' clamp to canvas?
		'winX = Max(canvasPos.x, Min(canvasPos.x + canvasSize.x - 1, winX))
		'winX = Max(canvasPos.y, Min(canvasPos.y + canvasSize.y - 1, winX))

		'print "DesignedMoveMouseBy("+dx+", "+dy+") designedMouse: " + DesignedMouseX()+","+DesignedMouseY() + " -> "+cx+","+cy + "  //  canvasScale="+(canvasSize.x / Float(designedSize.x))+", " + (canvasSize.y / Float(designedSize.y)) + "  //  windowMouse: " + WindowMouseX()+","+WindowMouseY() +" -> " + winX+", " + winY + " -> " + Int(winX) +"," + Int(winY)
		MoveMouse(Int(winX + 0.5), Int(winY + 0.5))
	End Method


	Method DesignedMoveMouseBy(dx:Float, dy:Float)
		DesignedMoveMouse(DesignedMouseX() + dx, DesignedMouseY() + dy)
   	End Method


	Method CanvasMouseX:Int()
		Local x:Int = self.WindowMouseX()
		x :- canvasPos.x
		Return x
	End Method


	Method CanvasMouseY:Int()
		Local y:Int = self.WindowMouseY()
		y :- canvasPos.y
		Return y
	End Method


	Method CanvasMoveMouse(x:Int, y:Int)
		' limit position to inside canvas
		Local cx:Int = Min(canvasSize.x, Max(0, x))
		Local cy:Int = Min(canvasSize.y, Max(0, y))

		' transform to window coordinates
		Local winX:Int = cx + canvasPos.x
		Local winY:Int = cy + canvasPos.y

		MoveMouse(winX, winY)
	End Method


	Method WindowMouseX:Int()
		Return brl.polledInput.MouseX()
	End Method


	Method WindowMouseY:Int()
		Return brl.polledInput.MouseY()
	End Method


	Method WindowMoveMouse(x:Int, y:Int)
		MoveMouse(x, y)
	End Method


	Method WindowMoveMouseBy(dx:Int, dy:Int)
		MoveMouse(WindowMouseX() + dx, WindowMouseY() + dy)
	End Method
	
	
	'Transforms a window coordinate to a designed coordinate.
	'This includes scaling.
	'Set "makeLocalCoordinate" to false" to ignore a letterbox
	Method WindowToDesignedCoordinate:SVec2I(x:Int, y:Int, makeLocalCoordinate:Int = True)
		'make local when rendering with active virtual resolution
		If makeLocalCoordinate
			x :- canvasPos.x
			y :- canvasPos.y
		EndIf

		' scale
		x :* (designedSize.x / Float(canvasSize.x))
		y :* (designedSize.y / Float(canvasSize.y))
		Return New SVec2I(x, y)
	End Method


	Method DesignedToWindowCoordinate:SVec2I(x:Int, y:Int, makeGlobalCoordinate:Int = True)
		' inverse scale
		x :* (canvasSize.x / Float(designedSize.x))
		y :* (canvasSize.y / Float(designedSize.y))

		'keep global?
		If Not makeGlobalCoordinate
			x :+ canvasPos.x
			y :+ canvasPos.y
		EndIf

		Return New SVec2I(x, y)
	End Method


	'Transforms a window coordinate to a canvas coordinate.
	'This just removes the letterbox offset.
	Method WindowToCanvasCoordinate:SVec2I(x:Int, y:Int)
		x :- canvasPos.x
		y :- canvasPos.y
		Return New SVec2I(x, y)
	End Method


	'Transforms a canvas coordinate to a window coordinate.
	'This just adds the letterbox offset.
	Method CanvasToWindowCoordinate:SVec2I(x:Int, y:Int)
		x :+ canvasPos.x
		y :+ canvasPos.y
		Return New SVec2I(x, y)
	End Method


	'Transforms a canvas coordinate to a designed coordinate.
	'This applies scaling.
	Method CanvasToDesignedCoordinate:SVec2I(x:Int, y:Int)
		x :* (designedSize.x / Float(canvasSize.x))
		y :* (designedSize.y / Float(canvasSize.y))
		Return New SVec2I(x, y)
	End Method


	'Transforms a designed coordinate to a canvas coordinate.
	'This applies inverse scaling.
	Method DesignedToCanvasCoordinate:SVec2I(x:Int, y:Int)
		x :* (canvasSize.x / Float(designedSize.x))
		y :* (canvasSize.y / Float(designedSize.y))
		Return New SVec2I(x, y)
	End Method
	

	Method ResetVirtualGraphicsArea()
	End Method


	Method SetupVirtualGraphicsArea()
	End Method


	Method VirtualGrabPixmap:TPixmap()
'TODO: Check
		Return VirtualGrabPixmap(0, 0, designedSize.x, designedSize.y)
	End Method


	Method VirtualGrabPixmap:TPixmap(x:int,y:int,w:int,h:int)
'TODO: Check
		local scaleX:float = windowSize.x / float(self.canvasSize.x)
		local scaleY:float = windowSize.y / float(self.canvasSize.y)
		Local vxOff:Int = 0
		Local vyOff:Int = 0
		return _max2dDriver.GrabPixmap(int(x*scaleX + vxoff), int(y*scaleY + vyoff), int(w*scaleX), int(h*scaleY))
	End Method


	Method Cls()
		brl.max2d.Cls()
	End Method

rem
	Method Cls()
		Local x:Int, y:Int, w:Int, h:Int
		Local vResW:Int = VirtualResolutionWidth()
		Local vResH:Int = VirtualResolutionHeight()
		.GetViewport(x,y,w,h)
		SetVirtualResolution(windowSize.x, windowSize.y)
		ResetViewport()
		brl.max2d.Cls()
		SetVirtualResolution(vResW, vResH)
		.SetViewport(x,y,w,h)
'		SetViewport( TVirtualGfx.GetInstance().vxoff, TVirtualGfx.GetInstance().vyoff, TVirtualGfx.GetInstance().vwidth, TVirtualGfx.GetInstance().vheight )
	End Method
endrem

	Method Flip(restrictFPS:Int=False)
		'we call "."flip so we call the "original flip function"
		If Not restrictFPS
			If vsync Then .Flip 1 Else .Flip 0
		Else
			If vsync Then .Flip 1 Else .Flip -1
		EndIf

		'reactivate vsync if it was on before
		If windowResizeActive and Time.MillisecsLong() > _windowResizeLastTime + _windowResizeActiveTime
			windowResizeActive = False
			'was on before, and still wants to be activated
			If _windowResizeVsyncWasOn
				SetVSync(True)
			EndIf
		EndIf

	End Method


	'set viewport to full window, disable logical size
	Method DisableVirtualResolution:SRectI()
		local oldViewport:SRectI = self.GetViewPort()
		'print "Disabling viewport: " + oldViewport.x+", "+oldViewport.y+", "+oldViewport.w+", "+oldViewport.h 	+"  virtual res: " + Int(VirtualResolutionWidth())+"x"+Int(VirtualResolutionHeight())	
		SetVirtualResolution(windowSize.x, windowSize.y)
		Self.SetViewport(0, 0, windowSize.x, windowSize.y)
		Return oldViewport
	End Method
	

	Method EnableVirtualResolution(viewport:SRectI)
		'print "Enabling viewport: " + viewport.x+", "+viewport.y+", "+viewport.w+", "+viewport.h 	+"  virtual res: " + Int(VirtualResolutionWidth())+"x"+Int(VirtualResolutionHeight())	+" -> " + designedSize.x+"x"+designedSize.y
		SetVirtualResolution(designedSize.x, designedSize.y)
		Self.SetViewport(viewport.x, viewport.y, viewport.w, viewport.h)
	End Method
	

	'adjust virtual resolution so that no letterbox is used
	'(so you can draw on the letterbox areas)
	'while maintaining the "scaling" factor
	Method DisableVirtualResolutionLetterbox:SRectI()
		Local oldViewport:SRectI = self.GetViewPort()
		Local scaleX:Float = windowSize.x / Float(canvasSize.x)
		Local scaleY:Float = windowSize.y / Float(canvasSize.y)

		'a scale <> 1.0 means that _this_ axis of the original designed
		'size needs to be scaled to also cover a letterbox
		Local extendedDesignedSizeX:Int = ceil(designedSize.x * scaleX)
		Local extendedDesignedSizeY:Int = ceil(designedSize.y * scaleY)

		'print "Disabling letterbox viewport: " + oldViewport.x+", "+oldViewport.y+", "+oldViewport.w+", "+oldViewport.h 	+"  virtual res: " + Int(VirtualResolutionWidth())+"x"+Int(VirtualResolutionHeight())	+" -> " + extendedDesignedSizeX+"x"+extendedDesignedSizeY
		SetVirtualResolution(extendedDesignedSizeX, extendedDesignedSizeY)
		SetViewport(0, 0, extendedDesignedSizeX, extendedDesignedSizeY)

		Return oldViewport
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

		viewPortStack[viewPortStackIndex] = GetViewport()

		return viewPortStack[viewPortStackIndex]
	End Method


	Method RestoreViewport:Int()
		if viewportStackIndex < 0 then return False
		
		self.SetViewport( viewportStack[viewportStackIndex] )
		viewportStackIndex :- 1
		
		return True
	End Method


	Method ResetViewport()
		SetViewport(0,0, GetWidth(), GetHeight())
	End Method


	Method SetViewport(x:Int, y:Int, w:Int, h:Int)
		'limit the viewport to the virtual dimension (to disable drawing
		'on the black bars)
		x = Max(0, x)
		y = Max(0, y)

		'we call the original max2d-viewport as it updates internal
		'variables used during image drawing and other functions!
		.SetViewport(x, y, w, h)
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
	End Method
	
	
	Method GetViewport:SRectI()
		Local vpX:int, vpY:int, vpW:int, vpH:Int
		'the . means: access globally defined SetViewPort()
		.GetViewport(vpX, vpY, vpW, vpH)

		Return New SRectI(vpX, vpY, vpW, vpH)
	End Method
		

	Method EnableSmoothLines:Int()
		Return False
	End Method
End Type


'convenience function
Function GetGraphicsManager:TGraphicsManager()
	Return TGraphicsManager.GetInstance()
End Function

