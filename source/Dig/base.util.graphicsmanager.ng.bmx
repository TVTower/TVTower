SuperStrict

Import sdl.glsdlmax2d
Import sdl.gl2sdlmax2d
Import sdl.SDLRenderMax2D
?Win32
Import sdl.d3d9sdlmax2d
?

Import "base.util.graphicsmanagerbase.bmx"

'setup available renderers -> no renderers but GL2SDL
TGraphicsManager.SetRendererAvailable(-1, False)
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_OPENGL, GLMax2DDriver() <> Null)
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_GL2SDL, GL2Max2DDriver() <> Null)
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_SDLRENDER, SDLRenderMax2DDriver() <> Null)
?Win32
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_DIRECTX9, D3D9SDLMax2DDriver() <> Null)
?

Type TGraphicsManagerNG Extends TGraphicsManager

	Function GetInstance:TGraphicsManager()
		If Not TGraphicsManagerNG(_instance) Then _instance = New TGraphicsManagerNG
		Return _instance
	End Function

	Method _InitGraphicsDefault:Int()
		Select renderer
			Case RENDERER_SDLRENDER
				'SDLRender requires a specific flag to use hardware vsync
				If vsync
					flags :| GRAPHICS_SWAPINTERVAL1
					TLogger.Log("GraphicsManager.InitGraphics()", "SetGraphicsDriver ~qSDLRender~q (vsync enabled).", LOG_DEBUG)
				Else
					TLogger.Log("GraphicsManager.InitGraphics()", "SetGraphicsDriver ~qSDLRender~q (vsync disabled).", LOG_DEBUG)
				EndIf
				SetGraphicsDriver SDLRenderMax2DDriver()
				
			Case RENDERER_OPENGL
				TLogger.Log("GraphicsManager.InitGraphics()", "SetGraphicsDriver ~qOpenGL~q.", LOG_DEBUG)
				SetGraphicsDriver GLMax2DDriver()
			'buffered gl?
			'?android
			Default
				TLogger.Log("GraphicsManager.InitGraphics()", "SetGraphicsDriver ~qGL2SDL~q.", LOG_DEBUG)
				SetGraphicsDriver GL2Max2DDriver()
				renderer = RENDERER_GL2SDL
			'?Not android
		End Select

		_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)
	End Method


	Method EnableSmoothLines:Int()
		If renderer = RENDERER_OPENGL Or renderer = RENDERER_GL2SDL
			?Not android
			GlEnable(GL_LINE_SMOOTH)
			?
			Return True
		Else
			Return False
		EndIf
	End Method
End Type

'convenience function
Function GetGraphicsManagerNG:TGraphicsManager()
	Return TGraphicsManagerNG.GetInstance()
End Function

GetGraphicsManagerNG()

