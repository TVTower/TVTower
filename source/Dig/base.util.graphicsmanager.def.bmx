SuperStrict

Import "base.util.graphicsmanagerbase.bmx"

'Import brl.Graphics
?MacOs
Import BRL.GLMax2D
?Win32
Import BRL.GLMax2D
Import "base.util.graphicsmanager.win32.bmx"
?Linux
Import BRL.GLMax2D
'Import "../source/external/bufferedglmax2d/bufferedglmax2d.bmx"
?

'setup available renderers
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_OPENGL, GLMax2DDriver() <> null)
'TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_BUFFEREDOPENGL, BufferedGLMax2DDriver() <> null)



Type TGraphicsManagerDefault Extends TGraphicsManager

	Function GetInstance:TGraphicsManager()
		If Not TGraphicsManagerDefault(_instance) Then _instance = New TGraphicsManagerDefault
		Return _instance
	End Function


	Method _InitGraphicsDefault:Int()
		?win32
			Return _InitGraphicsWin32()
		?Not win32
			Select renderer
				Default
					TLogger.Log("GraphicsManager.InitGraphics()", "SetGraphicsDriver ~qOpenGL~q.", LOG_DEBUG)
					SetGraphicsDriver GLMax2DDriver()
					renderer = RENDERER_OPENGL
			End Select

			_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)
		?
	End Method

	Method _InitGraphicsWin32:Int()
		?win32
		'done in base.util.graphicsmanager.win32.bmx
		'alternatively to "_g = Func(_g,...)"
		'SetRenderWin32 could also use "_g:TGraphics var"
		'attention: renderer is passed by reference (might be changed)
		'           during execution of SetRendererWin32(...)
		_g = SetRendererWin32(_g, renderer, realWidth, realHeight, colorDepth, fullScreen, hertz, flags)
		?
	End Method


	Method CenterDisplay()
		If Not fullscreen Then
			'based on "ccCentreWindowHandle(hWnD%)" from the old blitzmax forums
			?Win32
			Local hWnd:Int = GetActiveWindow()
			Local desk:Int[4], window:Int[4]
			GetWindowRect(GetDesktopWindow(), desk)
			GetWindowRect(hWnd, window)

			SetWindowPos(hWnd, HWND_NOTOPMOST, (desk[2] - (window[2] - window[1])) / 2, (desk[3] - (window[3] - window[0])) / 2, 0, 0, SWP_NOSIZE)
		?
		End If
	End Method


	Method EnableSmoothLines:Int()
		If renderer = RENDERER_OPENGL Or renderer = RENDERER_GL2SDL Or renderer = RENDERER_BUFFEREDOPENGL
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
Function GetGraphicsManagerDefault:TGraphicsManager()
	Return TGraphicsManagerDefault.GetInstance()
End Function

GetGraphicsManagerDefault()
