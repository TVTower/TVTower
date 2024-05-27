SuperStrict
Import BRL.GLMax2D
?Not bmxng
'Import "external/srs.mod/d3d11max2d.mod/d3d11max2d.bmx"
Import SRS.D3D11Max2D
Import BRL.D3D9Max2D
Import BRL.D3D7Max2D
?
Import "base.util.logger.bmx"
Import "base.util.graphicsmanagerbase.bmx"

'setup available renderers
?Not bmxng
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_DIRECTX11, D3D11Max2DDriver() <> Null)
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_DIRECTX9, D3D9Max2DDriver() <> Null)
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_DIRECTX7, D3D7Max2DDriver() <> Null)
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_OPENGL, GLMax2DDriver() <> Null)
?bmxng
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_DIRECTX9, D3D9Max2DDriver() <> Null)
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_GL2SDL, GL2Max2DDriver() <> Null)
?



Function SetRendererWin32:TGraphics(_g:TGraphics, renderer:Int Var, realWidth:Int, realHeight:Int, colorDepth:Int, fullScreen:Int, hertz:Int, flags:Int)
	Local RENDERER_OPENGL:Int   		= 0
	Local RENDERER_DIRECTX7:Int 		= 1
	Local RENDERER_DIRECTX9:Int 		= 2
	Local RENDERER_DIRECTX11:Int 		= 3
	Local RENDERER_BUFFEREDOPENGL:Int   = 4
	Local RENDERER_GL2SDL:Int           = 5


	Local drivers:TMax2DDriver[4]
	Local driversID:Int[]
	Local driversName:String[]

	?Not bmxng
	drivers[0] = D3D11Max2DDriver()
	drivers[1] = D3D9Max2DDriver()
	drivers[2] = D3D7Max2DDriver()
	drivers[3] = GLMax2DDriver()
	driversID  = [3,            2,           1,           0]
	driversName= ["DirectX 11", "DirectX 9", "DirectX 7", "OpenGL"]
	?bmxng
	drivers[0] = GL2Max2DDriver()
	driversID  = [0]
	driversName= ["OpenGL SDL"]
	?

	Local currentDriverIndex:Int = 0
	For Local i:Int = 0 Until driversID.length
		If driversID[i] = renderer Then currentDriverIndex = i
	Next

	'if selected driver is not available, use the highest available one
	If Not drivers[currentDriverIndex]
		TLogger.Log("GraphicsManager.InitGraphics()", "~q"+driversName[currentDriverIndex]+"~q not available or incompatible GPU.", LOG_WARNING)

		Local driversAvailable:String = ""
		For Local i:Int = 0 Until drivers.length
			If driversAvailable <> "" Then driversAvailable :+ ", "
			If drivers[i]
				driversAvailable :+ driversName[i] +" [OK]"
			Else
				driversAvailable :+ driversName[i] +" [--]"
			EndIf
		Next
		TLogger.Log("GraphicsManager.InitGraphics()", "Known renderers: "+driversAvailable, LOG_WARNING)

		'loop over all drivers
		For Local i:Int = 0 Until driversID.length
			'skip current
			If currentDriverIndex = i Then Continue

			If drivers[i]
				TLogger.Log("GraphicsManager.InitGraphics()", "Switching to ~q"+driversName[i]+"~q.", LOG_WARNING)
				currentDriverIndex = i
				Exit
			EndIf
		Next
		'nothing changed?
		If renderer = driversID[currentDriverIndex]
			TLogger.Log("GraphicsManager.InitGraphics()", "Failed to find an alternative renderer.", LOG_ERROR)
		EndIf
	EndIf

	'set the graphics driver
	TLogger.Log("GraphicsManager.InitGraphics()", "SetGraphicsDriver ~q"+driversName[currentDriverIndex]+"~q.", LOG_DEBUG)
	SetGraphicsDriver drivers[currentDriverIndex]


	_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)

	'context created?
	If _g Then Return _g

	If driversID.length > 1
		TLogger.Log("GraphicsManager.InitGraphics()", "Failed to create graphic context with ~q"+driversName[currentDriverIndex]+"~q. Trying alternative renderers.", LOG_DEBUG)
		Notify "Failed to open graphics context for ~q"+driversName[currentDriverIndex]+"~q. Trying alternative renderers."

		'try to create the context with another available renderer
		For Local i:Int = 0 Until driversID.length
			If Not drivers[i] Then Continue
			'the first selected one
			If currentDriverIndex = i Then Continue

			SetGraphicsDriver drivers[i]
			_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)

			If Not _g
				TLogger.Log("GraphicsManager.InitGraphics()", "Failed to create graphic context with alternative renderer ~q"+driversName[i]+"~q. Trying ~q"+driversName[i Mod driversName.length]+"~q now.", LOG_DEBUG)
			Else
				TLogger.Log("GraphicsManager.InitGraphics()", "Found alternative renderer ~q"+driversName[i]+"~q.", LOG_DEBUG)
				'set new renderer
				renderer = driversID[i]

				'exit loop, found a valid context
				Exit
			EndIf
		Next

		'nothing changed?
		If renderer = driversID[currentDriverIndex]
			TLogger.Log("GraphicsManager.InitGraphics()", "Failed to find an alternative way to create the graphics context.", LOG_ERROR)
		EndIf

	EndIf

	Return _g
End Function