'Application: TVTower
'Author: Ronny Otto
'Description: Loads all needed Files (checked) and returns them to variables
'
SuperStrict

Import brl.Graphics
Import "bufferedglmax2d.bmx"
?Win32
Import brl.D3D9Max2D
Import brl.D3D7Max2D
?
Import brl.PNGLoader
Import brl.FreeTypeFont
?Threaded
Import brl.threads
?

Import brl.Max2D
Import brl.Retro

Import "basefunctions.bmx"
Import "basefunctions_xml.bmx"
Import "basefunctions_image.bmx"
Import "basefunctions_resourcemanager.bmx"
'Import "functions_file.bmx"


Global VersionDate:String = LoadText("incbin::source/version.txt")
Global versionstring:String = "version of " + VersionDate
Global copyrightstring:String = "by Ronny Otto, gamezworld.de"
AppTitle = "TVTower - " + versionstring + " " + copyrightstring

Global filestotal:Int = 76
Global pixelperfile:Float = 660 / Float(filestotal)
Global filecount:Int =0
Global filesperscreen:Int= 30

Global LoadImageError:Int = 0
Global LoadImageText :String = ""


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
	DrawImage(gfx_startscreen_logo, WIDTH/2 - ImageWidth(gfx_startscreen_logo) / 2, 100)
	SetAlpha 1.0
	DrawImage(gfx_loading_bar, 0, WIDTH/2 -56  + 32, 1)

	LoaderWidth = Max(filecount * pixelperfile, LoaderWidth+1)
	DrawSubImageRect(gfx_loading_bar,0,WIDTH/2 -56 +32, LoaderWidth, gfx_loading_bar.Height, 0, 0, LoaderWidth, gfx_loading_bar.Height, 0, 0, 0)

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

Global LastMem:Int	= 0
Global totalmem:Int	= 0
Global freemem:Int	= 0
Global UsedMemAtStart:Int = 0

Function PrintVidMem(usage:String)
?win32
	If directx = 1
		Local mycaps:DDCAPS_DX7 = New DDCAPS_DX7
		mycaps.dwCaps = DDSCAPS_VIDEOMEMORY'|LOCALVIDMEM|NONLOCALVIDMEM|SYSTEMMEMORY
		D3D7GraphicsDriver().DirectDraw7().GetAvailableVidMem(MyCaps, Varptr totalmem, Varptr freemem)
		If UsedMemAtStart = 0 Then UsedMemAtStart = totalmem - freemem
		Print ("VidMem: " + Int((totalmem - freemem - UsedMemAtStart) / 1024) + "kb  - Zuwachs:" + (Int((totalmem - freemem - UsedMemAtStart) - LastMem) / 1024) + "kb - geladen:" + usage)
		LastMem = Int(totalmem - freemem - UsedMemAtStart)
	EndIf
?
End Function

Global DX9StartMemory:Int = 0
Global fullscreen:Int = 0
Global directx:Int = 0
Global colordepth:Int = 16
'#Region Read Screenmode
	  Local root:xmlNode
      Local XMLFile:xmlDocument = xmlDocument.Create("config/settings.xml")
 	  If XMLFile <> Null Then PrintDebug ("files.bmx", "settings.xml zur Ueberpruefung zwecks Vollbildeinstellung geladen", DEBUG_LOADING)
      root = XMLFile.root().FindChild("settings")
	  If root = Null Then Throw "root not found"
	  If root.Name = "settings" Then
		If root.FindChild("fullscreen") <> Null
          fullscreen     = Int(root.FindChild("fullscreen").Value)
		Else
	 	  PrintDebug ("files.bmx", "settings.xml fehlt 'fullscreen', setze Defaultwert: 0", DEBUG_LOADING)
		  fullscreen = 0
		EndIf
		If root.FindChild("directx") <> Null
          directx     = Int(root.FindChild("directx").value)
		Else
	 	  PrintDebug ("files.bmx", "settings.xml fehlt 'directx', setze Defaultwert: 0 (OpenGL)", DEBUG_LOADING)
		  directx = 0
		EndIf
		If root.FindChild("colordepth") <> Null
          colordepth = Int(root.FindChild("colordepth").value)
		  If colordepth <> 16 And colordepth <> 32 Then
			PrintDebug ("files.bmx", "settings.xml enthaelt fehlerhaften Eintrag fuer 'colordepth', setze Defaultwert: 16", DEBUG_LOADING)
		  	colordepth = 16
		  EndIf
		Else
			PrintDebug ("files.bmx", "settings.xml fehlt 'colordepth', setze Defaultwert: 16", DEBUG_LOADING)
		  colordepth = 16
		EndIf
      EndIf
'	 EndIf
'#End Region

Local g:TGraphics
Global WIDTH:Int=800,HEIGHT:Int=600
Local d:Int=colordepth*fullscreen,hertz2:Int=60
Local MyFlag:Int = 0 'GRAPHICS_BACKBUFFER | GRAPHICS_ALPHABUFFER '& GRAPHICS_ACCUMBUFFER & GRAPHICS_DEPTHBUFFER
Try
?Win32
	If directx = 1
		SetGraphicsDriver D3D7Max2DDriver()
	Else If directx = 2
		SetGraphicsDriver D3D9Max2DDriver()
	Else If directx = 0
		SetGraphicsDriver GLMax2DDriver()
	EndIf
	g = Graphics(WIDTH, HEIGHT, d, hertz2, MyFlag)
	If g = Null
		Throw "Graphics initiation error! The game will try to open in windowed DirectX 7 mode."
		SetGraphicsDriver D3D7Max2DDriver()
		g = Graphics(WIDTH, HEIGHT, 0, hertz2)
	EndIf
?
?Linux
	'SetGraphicsDriver GLMax2DDriver()
	SetGraphicsDriver BufferedGLMax2DDriver()
	g = Graphics(WIDTH, HEIGHT, d, hertz2, MyFlag)
	If g = Null Then Throw "Graphics initiation error! no DirectX available."
?
?MacOs
	SetGraphicsDriver GLMax2DDriver()
	g = Graphics(WIDTH, HEIGHT, d, hertz2, MyFlag)
	If g = Null Then Throw "Graphics initiation error! no DirectX available."
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
'image bounds
'particle_image = LoadImage(GrabPixmap(0,0,16,16))
GrabImage(particle_image,0,0) ; Cls
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
rem

'Global gfx_news_pp_btn:TImage 				= CheckLoadImage("grafiken/news/newsplanung_button.png", -1, 47, 32, 0, 6)
'Global gfx_news_btn:TImage 					= CheckLoadImage("grafiken/news/button.png", -1, 41, 42, 0, 10)
Global gfx_news_sheet_base:TImage			= CheckLoadImage("grafiken/news/newsplanung_news.png",0)
Global gfx_news_sheet:TImage				= TImage.Create(ImageWidth(gfx_news_sheet_base), ImageHeight(gfx_news_sheet_base) * 5, 1, 0, 255, 0, 255)

Local tmppix:TPixmap = LockImage(gfx_news_sheet, 0)
DrawOnPixmap(ColorizeTImage(gfx_news_sheet_base, 205, 170, 50) , 0, tmppix, 0, 0)
DrawOnPixmap(ColorizeTImage(gfx_news_sheet_base, 50, 140, 205) , 0, tmppix, 0, ImageHeight(gfx_news_sheet_base) * 1)
DrawOnPixmap(ColorizeTImage(gfx_news_sheet_base, 220, 30, 30) , 0, tmppix, 0, ImageHeight(gfx_news_sheet_base) * 2)
DrawOnPixmap(ColorizeTImage(gfx_news_sheet_base, 170, 30, 220) , 0, tmppix, 0, ImageHeight(gfx_news_sheet_base) * 3)
DrawOnPixmap(ColorizeTImage(gfx_news_sheet_base, 60, 160, 60) , 0, tmppix, 0, ImageHeight(gfx_news_sheet_base) * 4)
UnlockImage(gfx_news_sheet, 0)
endrem
Global gfx_financials_barren_base:TImage = LoadImage("grafiken/buero/finanzen_balken.png", 0)

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

Global gfx_mousecursor:TImage       = CheckLoadImage("grafiken/interface/cursor.png", 0, 32,32,0,3) 'normal mousecursor

'=== fonts =========================
Global FontManager:TGW_FontManager	= TGW_FontManager.Create()
FontManager.DefaultFont	= FontManager.AddFont("Default", "res/fonts/Vera.ttf", 11, SMOOTHFONT)
FontManager.baseFont = FontManager.DefaultFont.ffont
FontManager.AddFont("Default", "res/fonts/VeraBd.ttf", 11, SMOOTHFONT + BOLDFONT)
FontManager.AddFont("Default", "res/fonts/VeraIt.ttf", 11, SMOOTHFONT + ITALICFONT)
SetImageFont(LoadTrueTypeFont("res/fonts/Vera.ttf", 11,SMOOTHFONT))

PrintVidMem("Fonts")

Global gfx_figures_hausmeister:TImage = CheckLoadImage("grafiken/hochhaus/spielfigur_hausmeister.png", 0, 51, 44, 0, 15)


'=== StationMap ====================
Global stationmap_mainpix:TPixmap 			= LoadPixmap("grafiken/senderkarte/senderkarte_bevoelkerungsdichte.png")
Global gfx_collisionpixel:TImage 		    = CheckLoadImage("grafiken/senderkarte/collisionpixel.png")
'===================================

Global gfx_button_blue:TImage = LoadImage(ColorizeImage("grafiken/button.png",75,90,100), 0)

Global gfx_contract_base:TImage = CheckLoadImage("grafiken/werbeagentur/werbung_vertraege.png", 0)
Global gfx_contract_img:TImage	= TImage.Create(ImageWidth(gfx_contract_base) * 10, ImageHeight(gfx_contract_base), 1, 0, 255, 0, 255)
local tmppix:TPixmap
tmppix = LockImage(gfx_contract_img, 0)
tmppix.ClearPixels(0)
	DrawOnPixmap(gfx_contract_base, 0, tmppix, 0, 0)
	DrawOnPixmap(ColorizeTImage(gfx_contract_base, 200, 60, 40) , 0, tmppix, ImageWidth(gfx_contract_base) * 1, 0)
	DrawOnPixmap(ColorizeTImage(gfx_contract_base, 40, 200, 40) , 0, tmppix, ImageWidth(gfx_contract_base) * 2, 0)
	DrawOnPixmap(ColorizeTImage(gfx_contract_base, 100, 100, 200) , 0, tmppix, ImageWidth(gfx_contract_base) * 3, 0)
	DrawOnPixmap(ColorizeTImage(gfx_contract_base, 20, 140, 180) , 0, tmppix, ImageWidth(gfx_contract_base) * 4, 0)
	DrawOnPixmap(ColorizeTImage(gfx_contract_base, 40, 200, 40) , 0, tmppix, ImageWidth(gfx_contract_base) * 5, 0)
	DrawOnPixmap(ColorizeTImage(gfx_contract_base, 100, 100, 200) , 0, tmppix, ImageWidth(gfx_contract_base) * 6, 0)
	DrawOnPixmap(ColorizeTImage(gfx_contract_base, 20, 140, 180) , 0, tmppix, ImageWidth(gfx_contract_base) * 7, 0)
	DrawOnPixmap(ColorizeTImage(gfx_contract_base, 40, 200, 40) , 0, tmppix, ImageWidth(gfx_contract_base) * 8, 0)
	DrawOnPixmap(ColorizeTImage(gfx_contract_base, 100, 100, 200) , 0, tmppix, ImageWidth(gfx_contract_base) * 9, 0)
UnlockImage(gfx_contract_img, 0)

Global gfx_contract:TGW_Spritepack = TGW_Spritepack.Create(gfx_contract_img, "gfx_contract_img_pack")
	gfx_contract.AddSprite("ContractDragged-1", 21 * 0, 0, 21, 60)
	gfx_contract.AddSprite("Contract-1", 21 * 0, 60, 17, 68)
For Local i:Int = 0 To 9
	gfx_contract.AddSprite("ContractDragged" + i, 21 * i, 0, 21, 60)
	gfx_contract.AddSprite("Contract" + i, 21 * i, 60, 17, 68)
Next
'gfx_contract_base = Null 'ram sparen

rem
Global gfx_movie:TImage 		= CheckLoadImage("grafiken/filmverleiher/film_huellen.png", 0, 15,70,0,10)
'Global gfx_auctionmovie:TImage	= CheckLoadImage("grafiken/filmverleiher/film_auktionsfilm.png", 0)

gfx_movie.pixmaps[0] = ColorizePixmap(gfx_movie, 0, 100, 30, 130)
gfx_movie.pixmaps[1] = ColorizePixmap(gfx_movie,1,120,100, 20)
gfx_movie.pixmaps[2] = ColorizePixmap(gfx_movie,2,150, 50,100)
gfx_movie.pixmaps[3] = ColorizePixmap(gfx_movie,3,100,150,200)
gfx_movie.pixmaps[4] = ColorizePixmap(gfx_movie,4,130,200, 80)
gfx_movie.pixmaps[5] = ColorizePixmap(gfx_movie,5,210, 25,220)
gfx_movie.pixmaps[6] = ColorizePixmap(gfx_movie,6,180,180, 20)
gfx_movie.pixmaps[7] = ColorizePixmap(gfx_movie,7,130, 50,100)
gfx_movie.pixmaps[8] = ColorizePixmap(gfx_movie,8,230,120, 80)
gfx_movie.pixmaps[9] = ColorizePixmap(gfx_movie,9,230,220, 40)
endrem

SetMaskColor 255, 0, 255
SetBlend ALPHABLEND
'Global gfx_gimmick_rooms_movieagency:TImage = (CheckLoadImage("grafiken/filmverleiher/raum_filmverleiher_gimmick.png"))
'Global gfx_hint_rooms_movieagency:TImage = (CheckLoadImage("grafiken/filmverleiher/raum_filmverleiher_glow.png"))
SetMaskColor 0, 0, 0
PrintDebug ("files.bmx", filecount + " Dateien per 'checked loading' eingelesen", DEBUG_LOADING)
print "finished loading"