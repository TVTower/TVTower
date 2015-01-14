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
	Global RENDERER_NAMES:string[] = [	"OpenGL",..
										"DirectX 7", ..
										"DirectX 9", ..
										"Buffered OpenGL" ..
									 ]
	CONST RENDERER_OPENGL:int   		= 0
	CONST RENDERER_DIRECTX7:int 		= 1
	CONST RENDERER_DIRECTX9:int 		= 2
	CONST RENDERER_BUFFEREDOPENGL:int   = 3


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
			'create a new graphics object
			InitGraphics()
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


	'switch between fullscreen or windowed mode
	Method SwitchFullscreen:int()
		SetFullscreen(1 - GetGraphicsManager().GetFullscreen())
	End Method


	Method InitGraphics:Int()
		'initialize virtual graphics only when "InitGraphics()" is run
		'for the first time
		if not _g then InitVirtualGraphics()

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
			If not _g and renderer <> RENDERER_DIRECTX9
				Notify "Graphics initiation error! The game will try to open in DirectX 9 mode."
				SetGraphicsDriver D3D7Max2DDriver()
				_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)
			endif
			'on win32 we could try to fallback to DX7
			If not _g and renderer <> RENDERER_DIRECTX7
				Notify "Graphics initiation error! The game will try to open in DirectX 7 mode."
				SetGraphicsDriver D3D7Max2DDriver()
				_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)
			endif
			'or to OpenGL
			If not _g and renderer <> RENDERER_OPENGL
				Notify "Graphics initiation error! The game will try to open in OpenGL mode."
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