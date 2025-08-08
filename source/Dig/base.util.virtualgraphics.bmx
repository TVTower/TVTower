SuperStrict
'Import BRL.Pixmap
Import BRL.Graphics
Import BRL.Max2D

' -----------------------------------------------------------------------------
' USAGE: Note that the order is important!
' -----------------------------------------------------------------------------

' 1) Call InitVirtualGraphics before anything else;
' 2) Call Graphics as normal to create display;
' 3) Call SetVirtualGraphics to set virtual display size.

' The optional 'monitor_stretch' parameter of SetVirtualGraphics is there
' because some monitors have the option to stretch non-native ratios to native
' ratios, and you cannot detect this programmatically.

' For instance, my monitor's native resolution is 1920 x 1080, and if I set the
' Graphics mode to 1024, 768, it defaults to stretching that to fill the screen,
' meaning the image is stretched horizontally, so a square will appear non-
' square; however, it also provides an option to scale to the correct aspect
' ratio. Since this is set on the monitor, there's no way to detect or correct
' it other than by offering the option to the user. Leave it off if unsure...

Type TVirtualGfx
	Global instance:TVirtualGfx

	Global DTInitComplete:Int = False
	Global DTW:Int
	Global DTH:Int

	Field vwidth:Int
	Field vheight:Int
	'the effective values including "letter boxes"
	Field effectiveVWidth:int
	Field effectiveVHeight:int

	Field vxoff:Int
	Field vyoff:Int

	Method Create:TVirtualGfx (width:Int, height:Int)
		instance = self
		self.vwidth = width
		self.vheight = height

		return self
	End Method

	Function getInstance:TVirtualGfx()
		if not instance then new TVirtualGfx.Create(800, 600)

		return instance
	End Function

	Method Init()
		' There must be a smarter way to check if Graphics has been called...
		If GraphicsWidth () > 0 Or GraphicsHeight () > 0
			EndGraphics
			Notify "Programmer error! Call InitVirtualGraphics BEFORE Graphics!", True
			'End
		endif
		self.DTW = DesktopWidth ()
		self.DTH = DesktopHeight ()
		' This only checks once... best to call InitVirtualGraphics again before any further Graphics calls (if you call EndGraphics at all)...
		self.DTInitComplete = True
	End Method

	Function SetVirtualGraphics (vwidth:Int, vheight:Int, monitor_stretch:Int = False)
		' InitVirtualGraphics has been called...
		If getInstance().DTInitComplete
			' Graphics has been called...
			If GraphicsWidth () = 0 Or GraphicsHeight () = 0
				Notify "Programmer error! Must call Graphics before SetVirtualGraphics", True
				'End
			EndIf
		Else
			EndGraphics
			Notify "Programmer error! Call InitVirtualGraphics before Graphics!", True
			'End
		EndIf


		' Reset of display needed when re-calculating virtual graphics stuff/clearing borders...
		ResetVirtualGraphicsArea()

		' Store current Cls colours...
		Local clsr:Int, clsg:Int, clsb:Int
		GetClsColor clsr, clsg, clsb

		' Set to black...
		SetClsColor 0, 0, 0

		' Got to clear both front AND back buffers or it flickers if new display area is smaller...
		Cls;Flip
		Cls;Flip
		Cls;Flip

		SetClsColor clsr, clsg, clsb

		' Create new (global) virtual display object...
		GetInstance().Create( vwidth, vheight )

		' Real Graphics width/height...
		Local gwidth:Int = GraphicsWidth()
		Local gheight:Int = GraphicsHeight()

		' If monitor is correcting aspect ratio IN FULL-SCREEN MODE, use desktop size, otherwise use
		' specified Graphics size. NB. This assumes user's desktop is using native monitor resolution,
		' as most laptops would be by default...
		If monitor_stretch And GraphicsDepth()
			' Pretend real Graphics mode is desktop width/height...
			gwidth = DTW
			gheight = DTH
		EndIf

		' Compare ratios...
		'If gwidth/float(gheight) => GetInstance().vwidth/float(GetInstance().vheight)
		'but we avoid divisions to skip floating point issues
		If gwidth * GetInstance().vheight => GetInstance().vwidth * gheight
			Local vscale:Double = gheight / Double(GetInstance().vheight)

			GetInstance().effectiveVWidth = Int(gwidth / vscale + 0.5)
			GetInstance().effectiveVHeight = GetInstance().vheight

			' Offset into 'real' display area...
			'move vxoff accordingly. Add 0.5 to round properly (1.49 to 1.0, 1.5 to 2)
			'GetInstance().vxoff = Int( (gwidth - GetInstance().vwidth * vscale) * vscale/2 + 0.5 )
			GetInstance().vxoff = Int((GetInstance().effectiveVWidth - GetInstance().vwidth)/2.0 + 0.5 )
			GetInstance().vyoff = 0

		Else
			' Graphics ratio narrower...
			Local vscale:Double = gwidth / Double(GetInstance().vwidth)

			GetInstance().effectiveVWidth = GetInstance().vwidth
			GetInstance().effectiveVHeight = Int(gheight / vscale + 0.5)

			GetInstance().vxoff = 0
			'GetInstance().vyoff = Int((gheight - GetInstance().vheight * vscale) * vscale/2 + 0.5)
			GetInstance().vyoff = Int((GetInstance().effectiveVHeight - GetInstance().vheight)/2.0 + 0.5)
			
		EndIf

		' Set up virtual graphics area...
		SetupVirtualGraphicsArea()
	End Function


	' Reset of display needed when re-calculating virtual graphics stuff/clearing borders...
	Function ResetVirtualGraphicsArea()
		SetVirtualResolution( GraphicsWidth(), GraphicsHeight() )
		SetViewport( 0, 0, GraphicsWidth(), GraphicsHeight())
		SetOrigin( 0, 0 )
	End Function


	Function SetupVirtualGraphicsArea()
		'print "SetViewport( "+GetInstance().vxoff+", "+GetInstance().vyoff+", "+GetInstance().vwidth+", "+GetInstance().vheight+" )"
		'print "SetOrigin( "+GetInstance().vxoff+", "+GetInstance().vyoff+" )"
		'print "NEW SetVirtualResolution( "+GetInstance().effectiveVWidth+", "+GetInstance().effectiveVHeight+" )"
		SetVirtualResolution( GetInstance().effectiveVWidth, GetInstance().effectiveVHeight )
		SetViewport( GetInstance().vxoff, GetInstance().vyoff, GetInstance().vwidth, GetInstance().vheight )
		SetOrigin( GetInstance().vxoff, GetInstance().vyoff )
	End Function
	

	Method VMouseX:Float ()
		Local mx:Float = VirtualMouseX () - vxoff
		If mx < 0 Then mx = 0 Else If mx > vwidth - 1 Then mx = vwidth - 1
		Return mx
	End Method

	Method VMouseY:Float ()
		Local my:Float = VirtualMouseY () - vyoff
		If my < 0 Then my = 0 Else If my > vheight - 1 Then my = vheight - 1
		Return my
	End Method

	Method VirtualWidth:Int ()
		Return vwidth
	End Method

	Method VirtualHeight:Int ()
		Return vheight
	End Method

	Method VirtualGrabPixmap:TPixmap(x:int,y:int,w:int,h:int)
		local scaleX:float = float(GraphicsWidth()) / float(self.vwidth)
		local scaleY:float = float(GraphicsHeight()) / float(self.vheight)
		return _max2dDriver.GrabPixmap(int(x*scaleX + self.vxoff), int(y*scaleY + self.vyoff), int(w*scaleX), int(h*scaleY))
	End Method

End Type

' -----------------------------------------------------------------------------
' ... and these helper functions (required)...
' -----------------------------------------------------------------------------
Function InitVirtualGraphics ()
	TVirtualGfx.getInstance().Init()
End Function

Function SetVirtualGraphics (vwidth:Int, vheight:Int, monitor_stretch:Int = False)
	TVirtualGfx.SetVirtualGraphics (vwidth, vheight, monitor_stretch)
End Function

Function VMouseX:Float ()
	Return TVirtualGfx.getInstance().VMouseX ()
End Function

Function VMouseY:Float ()
	Return TVirtualGfx.getInstance().VMouseY ()
End Function

' Don't need VirtualMouseXSpeed/YSpeed replacements!

Function VirtualWidth:Int ()
	Return TVirtualGfx.getInstance().VirtualWidth ()
End Function

Function VirtualHeight:Int ()
	Return TVirtualGfx.getInstance().VirtualHeight ()
End Function

'Grab an image from the back buffer with Virtual support
Function VirtualGrabPixmap:TPixmap(X:Int, Y:Int, W:int, H:int, Frame:Int = 0)
	Return TVirtualGfx.getInstance().VirtualGrabPixmap(x,y,w,h)
End Function
