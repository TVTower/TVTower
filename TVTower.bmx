SuperStrict

'Application: TVGigant/TVTower
'Author: Ronny Otto / Manuel Voegele

' creates version.txt and puts date in it
' @bmk include source/version_script.bmk
' @bmk doVersion source/version.txt
'

Framework brl.glmax2d
?Win32
'	Import "tvtower_icon.o"
?
Import pub.freeaudio 'fuer rtaudio
Import "source/main.bmx"

Incbin "source/version.txt"

?Win32
rem
	Function SetIcon(iconname$, TheWindow%)
		Local icon:Int=ExtractIconA(TheWindow,iconname,0)
		Local WM_SETICON:Int = $80
		Local ICON_SMALL:Int = 0
		Local ICON_BIG:Int = 1
		sendmessage(TheWindow, WM_SETICON, ICON_BIG, icon)
	End Function

	Extern "win32"
		Function ExtractIconA%(hWnd%,File$z,Index%)
		Function GetActiveWindow%()
		Function SendMessage:Int(hWnd:Int,MSG:Int,wParam:Int,lParam:Int) = "SendMessageA@16"
	End Extern

	SetIcon(AppFile, GetActiveWindow())
endrem
?
