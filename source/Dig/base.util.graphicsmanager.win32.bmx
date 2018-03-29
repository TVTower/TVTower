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
?not bmxng
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_DIRECTX11, D3D11Max2DDriver() <> null)
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_DIRECTX9, D3D9Max2DDriver() <> null)
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_DIRECTX7, D3D7Max2DDriver() <> null)
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_OPENGL, GLMax2DDriver() <> null)
?bmxng
TGraphicsManager.SetRendererAvailable(TGraphicsManager.RENDERER_GL2SDL, GL2Max2DDriver() <> null)
?



Function SetRendererWin32:TGraphics(_g:TGraphics, renderer:Int var, realWidth:Int, realHeight:Int, colorDepth:Int, fullScreen:Int, hertz:Int, flags:Int)
	Local RENDERER_OPENGL:Int   		= 0
	Local RENDERER_DIRECTX7:Int 		= 1
	Local RENDERER_DIRECTX9:Int 		= 2
	Local RENDERER_DIRECTX11:Int 		= 3
	Local RENDERER_BUFFEREDOPENGL:Int   = 4
	Local RENDERER_GL2SDL:int           = 5


	local drivers:TMax2DDriver[4]
	local driversID:Int[]
	local driversName:String[]

	?Not bmxng
	drivers[0] = D3D11Max2DDriver()
	drivers[1] = D3D9Max2DDriver()
	drivers[2] = D3D7Max2DDriver()
	drivers[3] = GLMax2DDriver()
	driversID  = [3,            2,           1,           0]
	driversName= ["DirectX 11", "DirectX 9", "DirectX 7", "OpenGL"]
	?bmxng
	drivers[0] = GLMax2DDriver()
	driversID  = [0]
	driversName= ["OpenGL"]
	?

	local currentDriverIndex:int = 0
	For local i:int = 0 until driversID.length
		if driversID[i] = renderer then currentDriverIndex = i
	Next

	'if selected driver is not available, use the highest available one
	if not drivers[currentDriverIndex]
		TLogger.Log("GraphicsManager.InitGraphics()", "~q"+driversName[currentDriverIndex]+"~q not available or incompatible GPU.", LOG_WARNING)

		local driversAvailable:string = ""
		For local i:int = 0 until drivers.length
			if driversAvailable <> "" then driversAvailable :+ ", "
			if drivers[i]
				driversAvailable :+ driversName[i] +" [OK]"
			else
				driversAvailable :+ driversName[i] +" [--]"
			endif
		Next
		TLogger.Log("GraphicsManager.InitGraphics()", "Known renderers: "+driversAvailable, LOG_WARNING)
		
		'loop over all drivers
		for local i:int = 0 until driversID.length
			'skip current
			if currentDriverIndex = i then continue

			if drivers[i]
				TLogger.Log("GraphicsManager.InitGraphics()", "Switching to ~q"+driversName[i]+"~q.", LOG_WARNING)
				currentDriverIndex = i
				exit
			endif
		Next
		'nothing changed?
		if renderer = driversID[currentDriverIndex]
			TLogger.Log("GraphicsManager.InitGraphics()", "Failed to find an alternative renderer.", LOG_ERROR)
		endif
	endif

	'set the graphics driver
	TLogger.Log("GraphicsManager.InitGraphics()", "SetGraphicsDriver ~q"+driversName[currentDriverIndex]+"~q.", LOG_DEBUG)
	SetGraphicsDriver drivers[currentDriverIndex]


	_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)

	'context created?
	if _g then return _g

	if driversID.length > 1
		TLogger.Log("GraphicsManager.InitGraphics()", "Failed to create graphic context with ~q"+driversName[currentDriverIndex]+"~q. Trying alternative renderers.", LOG_DEBUG)
		Notify "Failed to open graphics context for ~q"+driversName[currentDriverIndex]+"~q. Trying alternative renderers."
	
		'try to create the context with another available renderer
		for local i:int = 0 until driversID.length
			if not drivers[i] then continue
			'the first selected one
			if currentDriverIndex = i then continue

			SetGraphicsDriver drivers[i]
			_g = Graphics(realWidth, realHeight, colorDepth*fullScreen, hertz, flags)
			
			if not _g
				TLogger.Log("GraphicsManager.InitGraphics()", "Failed to create graphic context with alternative renderer ~q"+driversName[i]+"~q. Trying ~q"+driversName[i mod driversName.length]+"~q now.", LOG_DEBUG)
			else
				TLogger.Log("GraphicsManager.InitGraphics()", "Found alternative renderer ~q"+driversName[i]+"~q.", LOG_DEBUG)
				'set new renderer
				renderer = driversID[i]

				'exit loop, found a valid context
				exit
			endif
		Next

		'nothing changed?
		if renderer = driversID[currentDriverIndex]
			TLogger.Log("GraphicsManager.InitGraphics()", "Failed to find an alternative way to create the graphics context.", LOG_ERROR)
		endif

	endif
	
	return _g
End Function