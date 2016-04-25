SuperStrict

Framework brl.StandardIO
Import "../source/Dig/base.gfx.bitmapfont.bmx"
Import "../source/Dig/base.util.deltatimer.bmx"
Import "../source/Dig/base.util.input.bmx"
Import "../source/Dig/base.util.figuregenerator.bmx"



Local gm:TGraphicsManager = TGraphicsManager.GetInstance()
GetDeltatimer().Init(30, -1)
GetGraphicsManager().SetResolution(800,600)
GetGraphicsManager().InitGraphics()	
SetBlend AlphaBlend


'=== LOAD RESOURCES ===
Local registryLoader:TRegistryLoader = New TRegistryLoader
'if loading from a "parent directory" - state this here
'-> all resources can get loaded with "relative paths"
registryLoader.baseURI = "../"
if FileType("TVTower") or FileType("TVTower.app") or FileType("TVTower.exe")
	registryLoader.baseURI = ""
endif

'afterwards we can display background images and cursors
'"TRUE" indicates that the content has to get loaded immediately
registryLoader.LoadFromXML("config/startup.xml", True)


Global figureGenerator:TFigureGenerator = new TFigureGenerator
Global currentFigure:TFigureGeneratorFigure[64]
Global currentFigureImage:TImage[64]

'register the loaders
new TRegistryFigureGeneratorPartLoader.Init()
registryLoader.LoadFromXML("config/figuregenerator.xml", True)

global figImage:TImage 
Function Update:Int()
	MouseManager.Update()
	KeyManager.Update()

	if KeyManager.IsHit(KEY_SPACE)
		figImage = figureGenerator.GenerateFigure(0, 1, 2).GenerateImage()

		'generate new
		for local i:int = 0 until 64
			currentFigure[i] = figureGenerator.GenerateFigure(0, Rand(1,2), Rand(0,2))
			currentFigureImage[i] = currentFigure[i].GenerateImage()
		Next
	Endif
End Function


Function Render:int()
	SetColor 255,255,255

	DrawRect(100,100, 320,320)
	for local i:int = 0 until 64
		if currentFigure[i]
			local col:int = i mod 8
			local row:int = i / 8
			'currentFigure[i].Draw(100 + 40*col,100 + 40*row)
			DrawImage(currentFigureImage[i], 100 + 40*col,100 + 40*row)
		endif
	Next
	DrawRect(500,300, 40,40)
	if figImage then DrawImage(figImage, 500,300)

	DrawText("Tasten:", 50,525)
	DrawText("Leertaste: Neues Gesicht", 50,570)


	'default pointer
	'If Game.cursorstate = 0 Then
	GetSpriteFromRegistry("gfx_mousecursor").Draw(MouseManager.x-9, 	MouseManager.y-2	,0)
End Function



While not KeyHit(KEY_ESCAPE) or AppTerminate()
	Update()
	Cls
	Render()
	Flip
	delay(2)
Wend

