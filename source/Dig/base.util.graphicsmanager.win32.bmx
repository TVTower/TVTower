SuperStrict
Import BRL.GLMax2D
?Not bmxng
Import BRL.D3D9Max2D
Import BRL.D3D7Max2D
Print "import"
?


Function SetRendererWin32:Int(_g:TGraphics, renderer:Int, realWidth:Int, realHeight:Int, colorDepth:Int, fullScreen:Int, hertz:Int, flags:Int)
	Local RENDERER_OPENGL:Int   		= 0
	Local RENDERER_DIRECTX7:Int 		= 1
	Local RENDERER_DIRECTX9:Int 		= 2
	Local RENDERER_BUFFEREDOPENGL:Int   = 3

	Select renderer
		?Not bmxng
		Case RENDERER_DIRECTX7
				SetGraphicsDriver D3D7Max2DDriver()
		Case RENDERER_DIRECTX9
				SetGraphicsDriver D3D9Max2DDriver()
		?
		Default SetGraphicsDriver GLMax2DDriver()
	EndSelect

	_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)

	?Not bmxng
	'on win32 we could try to fallback to DX7
	If Not _g And renderer <> RENDERER_DIRECTX9
		Notify "Graphics initiation error! The game will try to open in DirectX 9 mode."
		SetGraphicsDriver D3D7Max2DDriver()
		_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)
	EndIf
	'on win32 we could try to fallback to DX7
	If Not _g And renderer <> RENDERER_DIRECTX7
		Notify "Graphics initiation error! The game will try to open in DirectX 7 mode."
		SetGraphicsDriver D3D7Max2DDriver()
		_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)
	EndIf
	'or to OpenGL
	If Not _g And renderer <> RENDERER_OPENGL
		Notify "Graphics initiation error! The game will try to open in OpenGL mode."
		SetGraphicsDriver GLMax2DDriver()
		_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)
	EndIf
	?
	If Not _g Then Throw "Graphics initiation error! no render engine available."
End Function