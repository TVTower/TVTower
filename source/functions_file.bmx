
Import brl.Max2D
Import brl.PNGLoader
Import "basefunctions_image.bmx"
'Import brl.GLMax2D
'Import brl.StandardIO
'Import brl.Random
'Import brl.PNGLoader
'Import brl.FreeTypeFont



'This application was written with BLIde http://www.blide.org
'Application: TVGigant
'Author: Ronny Otto
'Description:
'  CheckLoadImage:Timage(path:string, flag:int)
'   - Checks before loading and returning an image
'     File not found: Error displayed until ESC (exits game)
'Strict
Global filestotal:Int = 37
Global pixelperfile:Float = 660 / Float(filestotal)
Global filecount:Int =0
Global filesperscreen:Int= 30

Global LoadImageError:Int = 0
Global LoadImageText :String = ""


Global gfx_startscreen:TBigImage = TBigImage.CreateFromImage(LoadImage("grafiken/start_bg1024.png"))
Global gfx_startscreen_logo:TImage = LoadImage("grafiken/logo.png", 0)
Global gfx_startscreen_logosmall:TImage = LoadImage("grafiken/logo_small.png", 0)
Global gfx_loading_bar:TImage = LoadAnimImage("grafiken/loading_bar.png", 800, 64, 0, 2, 0)
Global LogoFadeInFirstCall:Int = 0

'Author: Ronny Otto
'Date: 2006/09/21
'---------
'If the image does not exist the user will come into a loop which informs about the missing
'file and exits the game afterwards. Function returns the image if the file is existing.
'---------
'Existiert das angegebene Bild nicht, kommt der Nutzer in eine Schleife, die ueber die fehlende
'Datei informiert und danach das Spiel beendet. Ist die Datei vorhanden, gibt die Funktion das Bild zurueck.
Function CheckLoadImage:TImage(path:Object, flag:Int = -1)
 Local locstring:String = "pixmap"
 Local locfilesize:Int = 1
 If path <> "" Then locstring = String(path)
 If locstring <> "" Then locfilesize = FileSize(locstring)
 Cls
 filecount:+1
 SetColor 255, 255, 255
 gfx_startscreen.render(0, 0)
' DrawImage(gfx_startscreen, 0, 0)
	If LogoFadeInFirstCall = 0 Then LogoFadeInFirstCall = MilliSecs()
	SetAlpha Float(Float(MilliSecs() - LogoFadeInFirstCall) / 750.0)
 DrawImage(gfx_startscreen_logo, WIDTH/2 - ImageWidth(gfx_startscreen_logo) / 2, 100)
 	SetAlpha 1.0
 DrawImage(gfx_loading_bar, 0, 344 + 32, 1)
 SetViewport(75,0,Int(filecount*pixelperfile),600)
 DrawImage(gfx_loading_bar, 0, 344 + 32, 0)
 SetViewport(0, 0, 800, 600)
 SetAlpha 0.3
 SetColor 0,0,0
 If filecount < 10       Then DrawText "[00"+filecount+"/"+filestotal+"]", 90, 410
 If filecount < 100 And filecount >=10 Then DrawText "[0"+filecount+"/"+filestotal+"]", 90, 410
 If filecount >= 100     Then DrawText "["+filecount+"/"+filestotal+"]", 90, 410
 SetAlpha 0.5
 DrawText "Loading image: "+locstring, 170, 410
 SetAlpha 1.0


 SetColor 255, 255, 255
 Flip
' Delay(1)
 If locfilesize > -1 And LoadImageError = 0
   LoadImageError = 0
   LoadImageText = "GFX: "+locstring+" loaded..."
   Local Img:TImage = LoadImage(path, flag)
 '  DrawImage(img,0,0)
   Return Img
 Else
   LoadImageError = 1
   LoadImageText = "GFX: "+locstring+" not found..."

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
       If KeyHit(KEY_ESCAPE) ExitGame = 1
     Until ExitGame = 1  Or AppTerminate()
     AppTerminate()
   End If
 EndIf

End Function

Function CheckLoadAnimImage:TImage(path:String="grafiken/leer.png",cell_width:Int=1,cell_height:Int=1,first_cell:Int=0,cell_count:Int=1, flag:Int=-1)
 Cls
 filecount:+1
 SetColor 255,255,255
 gfx_startscreen.render(0, 0)
' DrawImage(gfx_startscreen, 0, 0)
	If LogoFadeInFirstCall = 0 Then LogoFadeInFirstCall = MilliSecs()
	SetAlpha Float(Float(MilliSecs() - LogoFadeInFirstCall) / 750.0)
 DrawImage(gfx_startscreen_logo, 400 - ImageWidth(gfx_startscreen_logo) / 2, 100)
 	SetAlpha 1.0
 DrawImage(gfx_loading_bar, 0, 344 + 32, 1)
 SetViewport(75,0,Int(filecount*pixelperfile),600)
 DrawImage(gfx_loading_bar, 0, 344 + 32, 0)
 SetViewport(0,0,800,600)
 SetAlpha 0.3
 SetColor 0,0,0
 If filecount < 10 Then DrawText "[00" + filecount + "/" + filestotal + "]", 90, 410
 If filecount < 100 And filecount >=10 Then DrawText "[0"+filecount+"/"+filestotal+"]", 90, 410
 If filecount >= 100     Then DrawText "["+filecount+"/"+filestotal+"]", 90, 410
 SetAlpha 0.5
 DrawText "Loading image: "+locstring, 170, 410
 SetAlpha 1.0
 SetColor 255,255,255
 Flip
' Delay(1)

 If FileSize(path) > -1 And LoadImageError = 0
   LoadImageError = 0
   LoadImageText = "GFX: "+path+" loaded..."
   Local Img:TImage = LoadAnimImage(path,cell_width,cell_height,first_cell,cell_count,DYNAMICIMAGE)
  ' DrawImage(img, 0, 0, 0)
   Return Img
 Else
   LoadImageError = 1
   LoadImageText = "GFX: "+path+" not found..."

   If LoadImageError = 1
     Repeat
       Cls
       SetColor 255,255,255
       DrawText LoadImageText,10,10
       DrawText "press ESC to exit TVGigant",10,30
       SetColor 0,0,0
       Flip
 	   Delay(1)
       LoadImageError = 0
       If KeyHit(KEY_ESCAPE) ExitGame = 1
     Until ExitGame = 1  Or AppTerminate()
     AppTerminate()
   End If
 EndIf
 End Function