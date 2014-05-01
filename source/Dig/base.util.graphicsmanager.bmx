SuperStrict
Import BRL.GLMax2D
?Win32
Import BRL.D3D9Max2D
Import BRL.D3D7Max2D
?Linux
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
	CONST RENDERER_BUFFEREDOPENGL:int   =-1
	CONST RENDERER_OPENGL:int   		= 0
	CONST RENDERER_DIRECTX7:int 		= 1
	CONST RENDERER_DIRECTX9:int 		= 2


	Method New()
		_instance = self
	End Method


	Function GetInstance:TGraphicsManager()
		If not _instance Then New TGraphicsManager
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


	Method SetFullscreen:Int(bool:int = TRUE)
		fullscreen = bool
	End Method


	Method SetVSync:Int(bool:int = TRUE)
		vsync = bool
	End Method


	Method SetHertz:Int(value:int=0)
		hertz = value
	End Method


	Method SetRenderer:Int(value:int = 0)
		renderer = value
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


	Method InitGraphics:Int()
		'virtual resolution
		InitVirtualGraphics()

'		Try
			Select renderer
				?Win32
				Case RENDERER_DIRECTX7
						SetGraphicsDriver D3D7Max2DDriver()
				Case RENDERER_DIRECTX9
						SetGraphicsDriver D3D9Max2DDriver()
				?
				?Linux
'				Case RENDERER_BUFFEREDOPENGL
'						SetGraphicsDriver BufferedGLMax2DDriver()
				?
				Default SetGraphicsDriver GLMax2DDriver()
			EndSelect

			_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)

			?Win32
			'on win32 we could try to fallback to DX7
			If not _g and renderer <> RENDERER_DIRECTX7
				Throw "Graphics initiation error! The game will try to open in DirectX 7 mode."
				SetGraphicsDriver D3D7Max2DDriver()
				_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)
			endif
			'or to OpenGL
			If not _g and renderer <> RENDERER_OPENGL
				Throw "Graphics initiation error! The game will try to open in OpenGL mode."
				SetGraphicsDriver GLMax2DDriver()
				_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)
			endif
			?
			if not _g then Throw "Graphics initiation error! no render engine available."
'		End Try
		SetBlend ALPHABLEND
		SetMaskColor 0, 0, 0
		HideMouse()

		'virtual resolution
		SetVirtualGraphics(GetWidth(), GetHeight(), False)
	End Method


	Method Flip(restrictFPS:int=FALSE)
		'we call "."flip so we call the "original flip function"
		If Not restrictFPS
			if vsync then .Flip 1 else .Flip 0
		Else
			if vsync then .Flip 1 else .Flip -1
		EndIf
	End Method
End Type


'convenience function
Function GetGraphicsManager:TGraphicsManager()
	Return TGraphicsManager.GetInstance()
End Function