'Application: TVTower
'Author: Ronny Otto
'Description: Loads all needed Files (checked) and returns them to variables
'
SuperStrict

Import brl.Graphics
?Linux
Import "external/bufferedglmax2d/bufferedglmax2d.bmx"
?
?Win32
Import brl.D3D9Max2D
Import brl.D3D7Max2D
?
Import brl.PNGLoader
Import brl.FreeTypeFont
?Threaded
'Import brl.threads
?

Import brl.Max2D
Import brl.Retro

Import "basefunctions.bmx"
Import "basefunctions_image.bmx"
Import "basefunctions_resourcemanager.bmx"


Global VersionDate:String		= LoadText("incbin::source/version.txt")
Global versionstring:String		= "version of " + VersionDate
Global copyrightstring:String	= "by Ronny Otto, gamezworld.de"
AppTitle = "TVTower - " + versionstring + " " + copyrightstring

Global filestotal:Int		= 16
Global pixelperfile:Float	= 660 / Float(filestotal)
Global filecount:Int		= 0
Global filesperscreen:Int	= 30
Global LoadImageError:Int	= 0
Global LoadImageText:String	= ""


Global gfx_startscreen:TBigImage		= TBigImage.CreateFromImage(LoadImage("grafiken/start_bg.png"))
Global gfx_startscreen_logo:TImage		= LoadImage("grafiken/logo.png", 0)
Global gfx_startscreen_logosmall:TImage	= LoadImage("grafiken/logo_small.png", 0)
Global gfx_loading_bar:TImage			= LoadAnimImage("grafiken/loading_bar.png", 800, 64, 0, 2, 0)
Global LogoFadeInFirstCall:Int = 0
Global LoaderWidth:Int = 0


'Author: Ronny Otto
'Date: 2006/09/21
'---------
'If the image does not exist the user will come into a loop which informs about the missing
'file and exits the game afterwards. Function returns the image if the file is existing.
'---------
'Existiert das angegebene Bild nicht, kommt der Nutzer in eine Schleife, die ueber die fehlende
'Datei informiert und danach das Spiel beendet. Ist die Datei vorhanden, gibt die Funktion das Bild zurueck.
Function CheckLoadImage:TImage(path:Object, flag:Int = -1, cellWidth:Int = -1,cellHeight:Int = -1,firstCell:Int = -1,cellCount:Int = -1)
	filecount:+1

	Local locstring:String	= "pixmap"
	Local locfilesize:Int	= 1

	If path <> "" Then locstring = String(path)
	If locstring <> "" Then locfilesize = FileSize(locstring)
	SetColor 255, 255, 255
	gfx_startscreen.render(0, 0)
	If LogoFadeInFirstCall = 0 Then LogoFadeInFirstCall = MilliSecs()
	SetAlpha Float(Float(MilliSecs() - LogoFadeInFirstCall) / 750.0)
	DrawImage(gfx_startscreen_logo, Settings.width/2 - ImageWidth(gfx_startscreen_logo) / 2, 100)
	SetAlpha 1.0
	DrawImage(gfx_loading_bar, 0, Settings.width/2 -56  + 32, 1)

	LoaderWidth = Max(filecount * pixelperfile, LoaderWidth+1)
	DrawSubImageRect(gfx_loading_bar,0,Settings.width/2 -56 +32, LoaderWidth, gfx_loading_bar.Height, 0, 0, LoaderWidth, gfx_loading_bar.Height, 0, 0, 0)

	SetAlpha 0.3
	SetColor 0,0,0
	DrawText "[" + Replace(RSet(filecount, String(filestotal).Length), " ", "0") + "/" + filestotal + "]", 90, 410
	SetAlpha 0.5
	DrawText "Loading ... "+locstring, 150, 410
	SetAlpha 1.0
	SetColor 255, 255, 255
	Flip
	If locfilesize > -1 And LoadImageError = 0
		LoadImageError = 0
		LoadImageText = "GFX: "+locstring+" loading..."
		Local Img:TImage = Null
		If cellWidth > 0
			Img = LoadAnimImage(path, cellWidth, cellHeight, firstCell, cellCount,DYNAMICIMAGE)
		Else
			Img = LoadImage(path, flag)
		EndIf
		'DrawImage(img,0,0)
		Return Img
	Else
		LoadImageError = 1
		LoadImageText = "GFX: "+locstring+" not found..."
		Print LoadImageText
		Local ExitGame:Int = 0
		If LoadImageError = 1
			Repeat
				Cls
				SetColor 255,255,255
				DrawText LoadImageText,10,10
				DrawText "press ESC to exit TVGigant",10,30
				SetColor 0,0,0
				Flip
				Delay(5)
				LoadImageError = 0
				If KeyHit(KEY_ESCAPE) Then ExitGame = 1
			Until ExitGame = 1  Or AppTerminate()
     		AppTerminate()
		End If
	EndIf
End Function

Const DYNAMICALLY_LOAD_IMAGES:Byte = 1

Global LastMem:Int			= 0
Global totalmem:Int			= 0
Global freemem:Int			= 0
Global UsedMemAtStart:Int	= 0

Function PrintVidMem(usage:String)
?win32
	If settings.directx = 1
		Local mycaps:DDCAPS_DX7 = New DDCAPS_DX7
		mycaps.dwCaps = DDSCAPS_VIDEOMEMORY'|LOCALVIDMEM|NONLOCALVIDMEM|SYSTEMMEMORY
		D3D7GraphicsDriver().DirectDraw7().GetAvailableVidMem(MyCaps, Varptr totalmem, Varptr freemem)
		If UsedMemAtStart = 0 Then UsedMemAtStart = totalmem - freemem
		Print ("VidMem: " + Int((totalmem - freemem - UsedMemAtStart) / 1024) + "kb  - Zuwachs:" + (Int((totalmem - freemem - UsedMemAtStart) - LastMem) / 1024) + "kb - geladen:" + usage)
		LastMem = Int(totalmem - freemem - UsedMemAtStart)
	EndIf
?
End Function

Global DX9StartMemory:Int	= 0

Global Settings:TApplicationSettings = TApplicationSettings.Create()
'#Region Read Screenmode
	Local xml:TXmlHelper = TXmlHelper.Create("config/settings.xml")
	local node:TXmlNode = xml.findRootChild("settings")
	If node = Null Or node.getName() <> "settings" then	Print "settings.xml fehlt der settings-Bereich"

	Settings.fullscreen	= xml.FindValueInt(node, "fullscreen", Settings.fullscreen, "settings.xml fehlt 'fullscreen', setze Defaultwert: "+Settings.fullscreen)
	Settings.directx	= xml.FindValueInt(node, "directx", Settings.directx, "settings.xml fehlt 'directx', setze Defaultwert: "+Settings.directx+" (OpenGL)")
	Settings.colordepth	= xml.FindValueInt(node, "colordepth", Settings.colordepth, "settings.xml fehlt 'colordepth', setze Defaultwert: "+Settings.colordepth)

	If Settings.colordepth <> 16 And Settings.colordepth <> 32
		Print "settings.xml enthaelt fehlerhaften Eintrag fuer 'colordepth', setze Defaultwert: 16"
		Settings.colordepth = 16
	EndIf
'#End Region

Local g:TGraphics
Try
?Win32
	Select Settings.directx
		Case  1	SetGraphicsDriver D3D7Max2DDriver()
		Case  2	SetGraphicsDriver D3D9Max2DDriver()
		Case -1 SetGraphicsDriver GLMax2DDriver()
'		Default SetGraphicsDriver BufferedGLMax2DDriver()
		Default SetGraphicsDriver GLMax2DDriver()
	EndSelect
	g = Graphics(Settings.width, Settings.height, Settings.colordepth*Settings.fullscreen, Settings.Hertz, Settings.flag)
	If g = Null
		Throw "Graphics initiation error! The game will try to open in windowed DirectX 7 mode."
		SetGraphicsDriver D3D7Max2DDriver()
		g = Graphics(Settings.width, Settings.height, 0, Settings.Hertz)
	EndIf
?
?Not Win32
	If Settings.directx = -1
		SetGraphicsDriver GLMax2DDriver()
	Else
		SetGraphicsDriver GLMax2DDriver()
'		SetGraphicsDriver BufferedGLMax2DDriver()
	EndIf
	g = Graphics(Settings.width, Settings.height, Settings.colordepth*Settings.fullscreen, Settings.hertz, Settings.Flag)
	If g = Null Then Throw "Graphics initiation error! no OpenGL available."
?
EndTry


SetBlend ALPHABLEND     'without it alphachannels are worth nothing
PrintDebug ("files.bmx", "Lade Grafiken", DEBUG_LOADING)

Global particle_image:TImage = CreateImage(16, 16)
Local alpha:Float = 1.0
Local grau:Int = Rnd(30,80)
For Local i:Int = 1 To 16 / 2
 	SetColor grau,grau,grau+5

	DrawOval (16 / 2) - i, (16 / 2) - i, i * 2, i * 2
	alpha:* 0.55
	SetAlpha alpha
Next
GrabImage(particle_image,0,0)
Cls
SetAlpha 1.0
Global XmlLoader:TXmlLoader = TXmlLoader.Create()
XmlLoader.Parse("config/resources.xml")
Assets.AddSet(XmlLoader.Values) 'copy XML-values

'=== Building ======================
'--- Elevator / Items -----
Global gfx_building_tooltips:TImage 		= CheckLoadImage("grafiken/hochhaus/tooltips.png", -1, 20, 20, 0, 7)
Global gfx_building_textballons:TImage		= CheckLoadImage("grafiken/hochhaus/textballons.png",-1, 23,12,0,6)
'===================================

Global gfx_interface_topbottom:TBigImage	= TBigImage.createFromImage(CheckLoadImage("grafiken/interface/interface_ou.png", 0))

Global gfx_datasheets_movie:TBigImage		= TBigImage.createFromImage(CheckLoadImage("grafiken/datenblaetter/tv_filmblatt.png"))
Global gfx_datasheets_series:TBigImage		= TBigImage.createFromImage(CheckLoadImage("grafiken/datenblaetter/tv_serienblatt.png"))
Global gfx_datasheets_contract:TBigImage	= TBigImage.createFromImage(CheckLoadImage("grafiken/datenblaetter/tv_werbeblatt.png"))

'=== StationMap ====================
Global stationmap_land_sachsen:TImage		= Assets.GetSprite("gfx_officepack_topo_sachsen").GetImage()
Global stationmap_land_niedersachsen:TImage	= Assets.GetSprite("gfx_officepack_topo_niedersachsen").GetImage()
Global stationmap_land_schleswigholstein:TImage = Assets.GetSprite("gfx_officepack_topo_schleswigholstein").GetImage()
Global stationmap_land_meckpom:TImage		= Assets.GetSprite("gfx_officepack_topo_meckpom").GetImage()
Global stationmap_land_nrw:TImage			= Assets.GetSprite("gfx_officepack_topo_nrw").GetImage()
Global stationmap_land_brandenburg:TImage	= Assets.GetSprite("gfx_officepack_topo_brandenburg").GetImage()
Global stationmap_land_sachsenanhalt:TImage = Assets.GetSprite("gfx_officepack_topo_sachsenanhalt").GetImage()
Global stationmap_land_hessen:TImage		= Assets.GetSprite("gfx_officepack_topo_hessen").GetImage()
Global stationmap_land_thueringen:TImage	= Assets.GetSprite("gfx_officepack_topo_thueringen").GetImage()
Global stationmap_land_rheinlandpfalz:TImage= Assets.GetSprite("gfx_officepack_topo_rheinlandpfalz").GetImage()
Global stationmap_land_saarland:TImage		= Assets.GetSprite("gfx_officepack_topo_saarland").GetImage()
Global stationmap_land_bayern:TImage		= Assets.GetSprite("gfx_officepack_topo_bayern").GetImage()
Global stationmap_land_bawue:TImage			= Assets.GetSprite("gfx_officepack_topo_bawue").GetImage()
Global stationmap_land_berlin:TImage		= Assets.GetSprite("gfx_officepack_topo_berlin").GetImage()
Global stationmap_land_hamburg:TImage		= Assets.GetSprite("gfx_officepack_topo_hamburg").GetImage()
Global stationmap_land_bremen:TImage		= Assets.GetSprite("gfx_officepack_topo_bremen").GetImage()

Global stationmap_mainpix:TPixmap 			= LoadPixmap("grafiken/senderkarte/senderkarte_bevoelkerungsdichte.png")
'===================================

Global gfx_mousecursor:TImage       		= CheckLoadImage("grafiken/interface/cursor.png", 0, 32,32,0,3) 'normal mousecursor

'=== fonts =========================
Global FontManager:TGW_FontManager	= TGW_FontManager.Create()
FontManager.DefaultFont	= FontManager.AddFont("Default", "res/fonts/Vera.ttf", 11, SMOOTHFONT)
FontManager.baseFont = FontManager.DefaultFont.ffont
FontManager.AddFont("Default", "res/fonts/VeraBd.ttf", 12, SMOOTHFONT + BOLDFONT)
FontManager.AddFont("Default", "res/fonts/VeraIt.ttf", 11, SMOOTHFONT + ITALICFONT)
FontManager.baseFontBold = FontManager.getFont("Default", 11, BOLDFONT)

SetImageFont(LoadTrueTypeFont("res/fonts/Vera.ttf", 11,SMOOTHFONT))


SetBlend ALPHABLEND
SetMaskColor 0, 0, 0