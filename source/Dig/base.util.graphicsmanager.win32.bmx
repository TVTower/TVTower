SuperStrict
Import BRL.GLMax2D
?Not bmxng
'Import "external/srs.mod/d3d11max2d.mod/d3d11max2d.bmx"
Import SRS.D3D11Max2D
Import BRL.D3D9Max2D
Import BRL.D3D7Max2D
?


Function SetRendererWin32:TGraphics(_g:TGraphics, renderer:Int var, realWidth:Int, realHeight:Int, colorDepth:Int, fullScreen:Int, hertz:Int, flags:Int)
	Local RENDERER_OPENGL:Int   		= 0
	Local RENDERER_DIRECTX7:Int 		= 1
	Local RENDERER_DIRECTX9:Int 		= 2
	Local RENDERER_DIRECTX11:Int 		= 3
	Local RENDERER_BUFFEREDOPENGL:Int   = 4
	Local RENDERER_GL2SDL:int           = 5


	?Not bmxng
	'try DX11, DX9, then DX7 and if all fail, fall back to OGL
	if renderer = RENDERER_DIRECTX11 and not D3D11Max2DDriver()
		print "SetRenderer: Directx 11 not available or not a DX11 compatible GPU."
		renderer = RENDERER_DIRECTX9
	endif
	if renderer = RENDERER_DIRECTX9 and not D3D9Max2DDriver()
		print "SetRenderer: Directx 9 not available or not a DX9 compatible GPU."
		renderer = RENDERER_DIRECTX7
	endif
	if renderer = RENDERER_DIRECTX7 and not D3D7Max2DDriver()
		print "SetRenderer: Directx 7 not available or not a DX7 compatible GPU."
		renderer = RENDERER_OPENGL
	endif
	?

	Select renderer
		?Not bmxng
		Case RENDERER_DIRECTX7
			SetGraphicsDriver D3D7Max2DDriver()
		Case RENDERER_DIRECTX9
			SetGraphicsDriver D3D9Max2DDriver()
		Case RENDERER_DIRECTX11
			SetGraphicsDriver D3D11Max2DDriver()
		?
		Default
			SetGraphicsDriver GLMax2DDriver()
	EndSelect

	_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)

	?Not bmxng
	If Not _g And renderer <> RENDERER_DIRECTX11 and D3D11Max2DDriver()<>Null
		Notify "Graphics initiation error! The game will try to open in DirectX 11 mode."
		SetGraphicsDriver D3D11Max2DDriver()
		_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)
	EndIf
	If Not _g And renderer <> RENDERER_DIRECTX9 and D3D9Max2DDriver()<>Null
		Notify "Graphics initiation error! The game will try to open in DirectX 9 mode."
		SetGraphicsDriver D3D9Max2DDriver()
		_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)
	EndIf
	If Not _g And renderer <> RENDERER_DIRECTX7 and D3D7Max2DDriver()<>Null
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
	return _g
End Function