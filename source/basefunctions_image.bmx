SuperStrict
Import brl.Graphics

Import brl.d3d7max2d
Import brl.glmax2d
Import brl.Max2D

Import brl.StandardIO
Import brl.Max2D

Import "basefunctions.bmx"
?Win32
'Import "Dx9Max2dDriver05\Dx9Max2dGraphicsDriver.bmx"
?

Function DrawImageArea(image:TImage, x:Float, y:Float, rx:Float, ry:Float, rw:Float, rh:Float, theframe:Int = 0)
	DrawSubImageRect(image, x, y, rw, rh, rx, ry, rw, rh, 0, 0, theframe)
End Function

Function DrawImageAreaPow2Size:Int(n:Int)
	n:-1
	n :| (n Shr 1)
	n :| (n Shr 2)
	n :| (n Shr 4)
	n :| (n Shr 8)
	n :| (n Shr 16)
	Return n+1
End Function

' -----------------------------------------------------------------------------
' ClipImageToViewport: Clips an image into a "safe" viewport (doesn't use BMax viewport)
' -----------------------------------------------------------------------------
Function ClipImageToViewport(image:TImage, imagex:Float, imagey:Float, ViewportX:Float, ViewPortY:Float, ViewPortW:Float, ViewPortH:Float, offsetx:Float = 0, offsety:Float = 0, theframe:Int = 0)
	'Perform basic clipping first by checking to see if the image is completely outside of the viewport.
	'Note that images are drawn from the top left, not midhandled or anything else.
	Local w:Int = ImageWidth(image)
	Local h:Int = ImageHeight(image)

	If imagex+w>=ViewportX And imagex-w<ViewportX+ViewportW and..
		imagey+h>=ViewportY And imagey-h<ViewportY+ViewportH Then
		'Clip left and top
		Local startx#=ViewportX-imagex
		Local starty#=ViewportY-imagey
		If startx<0 Then startx=0 'clamp normal values
		If starty<0 Then starty=0 'clamp normal values
		'Clip right and bottom
		Local endx#=(imagex+w)-(ViewportX+ViewportW)
		Local endy#=(imagey+h)-(ViewportY+ViewportH)
		If endx<0 Then endx=0 'clamp normal values
		If endy<0 Then endy=0 'clamp normal values
		DrawImageArea(Image, imageX + startX + offsetx, imagey + starty + offsety, startx, starty, w - startx - endx, h - starty - endy, theframe)
	EndIf
End Function

  'Draws an Image if its in the viewport of the screen (not on Interface)
Function DrawImageInViewPort(_image:TImage, _x:Int, _yItStandsOn:Int, align:Byte=0, Frame:Int=0)
    If _yItStandsOn > 10 And _yItStandsOn - ImageHeight(_image) < 373+10
	  If align = 0 '_x is left side of image
	    DrawImage(_image, _x, _yItStandsOn - ImageHeight(_image), Frame)
	  ElseIf align = 1 '_x is right side of image
	    DrawImage(_image, _x-ImageWidth(_image), _yItStandsOn - ImageHeight(_image),Frame)
	  EndIf
    EndIf
End Function


Function DrawOnPixmap(image:TImage, framenr:Int = 0, Pixmap:TPixmap, x:Int, y:Int, alpha:Float = 1.0, light:Float = 1.0, multiply:Int = 0)
      Local TempPix:TPixmap = Null
	  If image = Null Then Throw "image doesnt exist"
	  If framenr = 0 Then TempPix = LockImage(image)
      If framenr > 0 Then TempPix = LockImage(image, Framenr)
	  For Local i:Int = 0 To ImageWidth(image) - 1
	    For Local j:Int = 0 To ImageHeight(image) - 1
		  If x + i < pixmap.width And y + j < pixmap.Height 'And i >= x And j >= y
			Local sourcepixel:Int = ReadPixel(TempPix, i, j)

			Local destpixel:Int = ReadPixel(pixmap, x + i, y + j)
			Local destA:Float = ARGB_Alpha(destpixel)
			Local sourceA:Float = ARGB_Alpha(sourcepixel) * alpha
			If sourceA = 255 Then destA = 0
			'remove comment to remove unneeded calculations
			'but only when light/alpha not used!
'			If sourceA <> 255 And sourceA <> 0
				Local destR:Float = ARGB_Red(destpixel)
				Local destG:Float = ARGB_Green(destpixel)
				Local destB:Float = ARGB_Blue(destpixel)
				Local SourceR:Float = ARGB_Red(Sourcepixel)
				Local SourceG:Float = ARGB_Green(Sourcepixel)
				Local SourceB:Float = ARGB_Blue(Sourcepixel)
					Local AlphaSum:Int = destA + sourceA
					If multiply = 1
						sourceR = (sourceR * light * sourceA / AlphaSum) + destA / AlphaSum * (destR * destA / AlphaSum)
						sourceG = (sourceG * light * sourceA / AlphaSum) + destA / AlphaSum * (destG * destA / AlphaSum)
						sourceB = (sourceB * light * sourceA / AlphaSum) + destA / AlphaSum * (destB * destA / AlphaSum)
					Else
						sourceR = (sourceR * light * sourceA / AlphaSum) + (destR * destA / AlphaSum)
						sourceG = (sourceG * light * sourceA / AlphaSum) + (destG * destA / AlphaSum)
						sourceB = (sourceB * light * sourceA / AlphaSum) + (destB * destA / AlphaSum)
					EndIf
					If AlphaSum > 255 Then AlphaSum = 255
					sourcepixel = ARGB_Color(AlphaSum, SourceR, sourceG, sourceB)
'			EndIf
			If SourceA <> 0 Then WritePixel(Pixmap, x + i, y + j, sourcepixel)
		  EndIf
		Next
	  Next
	  If framenr = 0 UnlockImage(image)
	  If framenr > 0 UnlockImage(image, framenr)
End Function

Function DrawPixmapOnPixmap(Source:TPixmap,Pixmap:TPixmap, x:Int, y:Int)
	  For Local i:Int = 0 To Source.width-1
	    For Local j:Int = 0 To Source.height-1
		  If x+1 < pixmap.width And y+j < pixmap.height
			Local sourcepixel:Int = ReadPixel(Source, i,j)
			Local destpixel:Int = ReadPixel(pixmap, x+i,y+j)
'			Local destA:Int = ARGB_Alpha(destpixel)
			Local sourceA:Int = ARGB_Alpha(sourcepixel)
			If sourceA <> -1 Then
				If sourceA< -1 Then sourceA = -sourceA
				Local destR:Int = ARGB_Red(destpixel)
				Local destG:Int = ARGB_Green(destpixel)
				Local destB:Int = ARGB_Blue(destpixel)
				Local SourceR:Int = ARGB_Red(Sourcepixel)
				Local SourceG:Int = ARGB_Green(Sourcepixel)
				Local SourceB:Int = ARGB_Blue(Sourcepixel)
				sourceR = Int( Float(sourceA/255.0)*sourceR) + Int(Float((255-sourceA)/255.0)*destR)
				sourceG = Int( Float(sourceA/255.0)*sourceG) + Int(Float((255-sourceA)/255.0)*destG)
				sourceB = Int( Float(sourceA/255.0)*sourceB) + Int(Float((255-sourceA)/255.0)*destB)
				sourcepixel = ARGB_Color(255, sourceR, sourceG, sourceB)
			EndIf
			If sourceA <> 0 Then WritePixel(Pixmap, x+i,y+j, sourcepixel)
		  EndIf
		Next
	  Next
End Function

Function blurPixmap(pm:TPixmap, k:Float = 0.5)

	'pm - the pixmap to blur. Format must be PF_RGBA8888
	'k - blurring amount. Value between 0.0 and 1.0
	'	 0.1 = Extreme, 0.9 = Minimal

	For Local x:Int = 1 To (pm.Width - 1)
    	For Local z:Int = 0 To (pm.Height - 1)
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x - 1, z), k))
    	Next
    Next

    For Local x:Int = (pm.Width - 3) To 0 Step -1
    	For Local z:Int = 0 To (pm.Height - 1)
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x + 1, z), k))
    	Next
    Next

    For Local x:Int = 0 To (pm.Width - 1)
    	For Local z:Int = 1 To (pm.Height - 1)
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x, z - 1), k))
    	Next
    Next

    For Local x:Int = 0 To (pm.Width - 1)
    	For Local z:Int = (pm.Height - 3) To 0 Step -1
			WritePixel(pm, x, z, blurPixel(ReadPixel(pm, x, z), ReadPixel(pm, x, z + 1), k))
    	Next
    Next

End Function

Function blurPixel:Int(px:Int, px2:Int, k:Float)

	'Utility function used by blurPixmap.
	'Uncomment the commented lines to enable alpha component
	'processing (usually not required).

	Local pxa:Byte = px Shr 24
	Local pxb:Byte = px Shr 16
	Local pxg:Byte = px Shr 8
	Local pxr:Byte = px

	'Local px2a:Byte = px2 Shr 24
	Local px2b:Byte = px2 Shr 16
	Local px2g:Byte = px2 Shr 8
	Local px2r:Byte = px2

	'pxa = (px2a * (1 - k)) + (pxa * k)
	pxb = (px2b * (1 - k)) + (pxb * k)
	pxg = (px2g * (1 - k)) + (pxg * k)
	pxr = (px2r * (1 - k)) + (pxr * k)

	Return Int(pxa Shl 24 | pxb Shl 16 | pxg Shl 8 | pxr)

EndFunction

Function DrawTextOnPixmap(Text:String, x:Int, y:Int, Pixmap:TPixmap, blur:Byte=0)
If blur
	Local r:Int = 0, g:Int = 0, b:Int = 0
	GetColor(r,g,b)
	SetColor(50,50,50)
	DrawText(Text,x-1,y-1)
	DrawText(Text,x+1,y+1)
	SetColor(r,g,b)
Else
	DrawText(Text,x,y)
EndIf
	Local TxtWidth:Int   = TextWidth(Text)
    Local Source:TPixmap = GrabPixmap(x-2,y-2,TxtWidth+4,TextHeight(Text)+4)
	Source = ConvertPixmap(Source, PF_RGB888)
If blur
	blurPixmap(Source, 0.5)
	Source = ConvertPixmap(Source, PF_RGB888)
	DrawPixmap(Source, x-2,y-2)
	DrawText(Text,x,y)
    Source = GrabPixmap(x-2,y-2,TxtWidth+4,TextHeight(Text)+4)
	Source = ConvertPixmap(Source, PF_RGB888)
EndIf
    DrawPixmapOnPixmap(Source, Pixmap,x-20,y-10)
End Function

Const MINFRAGSIZE:Int = 64 ' maximum image fragment size
Const MAXFRAGSIZE:Int = 256 ' maximum image fragment size
Type ImageFragment

    Field img:TImage
    Field x:Float,y:Float,w:Float,h:Float

    ' ----------------------------------
    ' constructor
    ' ----------------------------------
    Function create:ImageFragment(pmap:TPixmap,x:Float,y:Float,w:Float,h:Float)

        Local frag:ImageFragment = New ImageFragment
        frag.img = LoadImage(PixmapWindow(pmap,x,y,w,h),0)'|FILTEREDIMAGE)
        frag.x = x
        frag.y = y
        frag.w = w
        frag.h = h

        Return frag

    End Function

    ' --------------------
    ' Draw individual tile
    ' --------------------
    Method render(xoff:Float = 0, yoff:Float = 0, Scale:Float = 1.0)
	    Local vx:Int = 0, vy:Int = 0, vh:Int = 0
	    GetViewport(vx,vy,vx,vh)
		If yoff + Scale * Self.y + Self.h > 0 And yoff + Scale * Self.y < vy + vh Then
          DrawImage(Self.img, xoff + Scale * Self.x, yoff + Scale * Self.y)
		EndIf
    End Method

    Method renderInViewPort(xoff:Float = 0, yoff:Float = 0, vx:Float, vy:Float, vw:Float, vh:Float)
		'DrawSubImageRect(Self.img,xoff + Self.x, yoff + Self.y, vw, vh,  vx,vy,vw,vh,0,0,0)

		ClipImageToViewport(Self.img, xoff + Self.x, yoff + Self.y, vx, vy, vw, vh, 0, 0, 0)
	End Method

End Type

Type TBigImage

    Field pixmap:TPixmap
    Field px:Float,py:Float
    Field fragments:TList
    Field width:Float
    Field height:Float
	Field PixFormat:Int
    Field x:Float = 0
    Field y:Float = 0

    ' ----------------------------------
    ' constructor
    ' ----------------------------------
	Function CreateFromImage:TBigImage(i:TImage)
	  Local pix:TPixmap = i.pixmaps[0]
	  Return TBigImage.Create(pix)
	End Function

	Function CreateFromPixmap:TBigImage(i:TPixmap)
	  Return TBigImage.create(i)
	End Function

	Function create:TBigImage(p:TPixmap)

        Local bi:TBigImage = New TBigImage
        bi.pixmap = p
        bi.width = p.width
        bi.height = p.height
        bi.fragments = CreateList()
        bi.load()
		bi.PixFormat = p.format
		bi.pixmap = Null
        Return bi

    End Function

    Method RestorePixmap:TPixmap()
	  Local Pix:TPixmap = TPixmap.Create(Self.width, Self.height, Self.PixFormat)
	  For Local ImgFrag:ImageFragment = EachIn Self.fragments
	    DrawOnPixmap(ImgFrag.img,0, Pix, ImgFrag.x, ImgFrag.y)
      Next
	  Return Pix
	End Method

	' -------------------------------------
    ' convert pixmap into image fragments
    ' -------------------------------------
    Method Load()
		'Print "Adding Fragments..."

        Local px:Float = 0
        Local py:Float = 0
        Local loading:Byte = True

        While (loading)
            Local w:Int = MAXFRAGSIZE
            Local h:Int = MAXFRAGSIZE
            If Self.pixmap.width - px < MAXFRAGSIZE w = Self.pixmap.width - px
            If Self.pixmap.Height - py < MAXFRAGSIZE h = Self.pixmap.Height - py
            Local f1:ImageFragment = ImageFragment.Create(Self.pixmap, px, py, w, h)
			'Print "Added Fragment: w" + w + " h" + h
            ListAddLast Self.fragments, f1
            px:+MAXFRAGSIZE
            If px >= Self.pixmap.width
                px = 0
                py:+MAXFRAGSIZE
                If py >= Self.pixmap.height loading = False
            End If

        Wend

    End Method

    ' -----------------
    ' Draw entire image
    ' -----------------
    Method render(x:Float = 0, y:Float = 0, Scale:Float = 1.0)
        For Local f:ImageFragment = EachIn Self.fragments
            f.render(x, y, Scale)
        Next
    End Method

    ' -----------------
    ' Draw entire image
    ' -----------------
    Method renderInViewPort(x:Float = 0, y:Float = 0, vx:Float, vy:Float, vw:Float, vh:Float)
        For Local f:ImageFragment = EachIn Self.fragments
            f.renderInViewPort(x, y, vx, vy, vw, vh)
        Next
    End Method
End Type




Const DDERR_INVALIDSURFACETYPE:Int = $88760250
Const DDERR_INVALIDPARAMS:Int = $80070057
Const DDERR_INVALIDOBJECT:Int = $88760082
Const DDERR_NOTFOUND:Int = $887600ff
Const DDERR_SURFACELOST:Int = $887601c2

Global tRenderERROR:String

Function tRTTError:String(err:Int)

	Select err
		Case DDERR_INVALIDSURFACETYPE
			Return "DDERR_INVALIDSURFACETYPE"

		Case DDERR_INVALIDPARAMS
			Return "DDERR_INVALIDPARAMS"

		Case DDERR_INVALIDOBJECT
			Return "DDERR_INVALIDOBJECT"

		Case DDERR_NOTFOUND
			Return "DDERR_NOTFOUND"

		Case DDERR_SURFACELOST
			Return "DDERR_SURFACELOST"

	End Select
End Function

Type tRender

	?Win32
'	Global DX9Surface:IDirect3DSurface9
	Global DXFrame:TD3D7ImageFrame
'	Global DX9Frame:TDX9ImageFrame
	Global backbuffer:IDirectDrawSurface7
'	Global backbufferDX9:IDirect3DSurface9

	?
	Global GLFrame:TGLImageFrame
	Global DX:Int
	Global Image:TImage = CreateImage(1,1)
	Global Width:Int
	Global Height:Int
	Global o_r:Int, o_g:Int, o_b:Int
Rem
bbdoc: Initialise the Module
about:
The module must be initialised before use. This ensures usage of the correct render pipeline. If the render device is changed then you must
re initialise the module.
End Rem
	Function Initialise:int()
	?Win32
		If _max2dDriver.ToString() = "DirectX7"
			DX = True
			D3D7GraphicsDriver().Direct3DDevice7().GetRenderTarget Varptr backbuffer

		'	ViewPort = New D3DVIEWPORT7
'		Else If _max2dDriver.toString() = "DirectX9"
'			DX = 2
'			D3D9GraphicsDriver().Direct3DDevice9().GetRenderTarget(0, backbufferDX9)
		Else
	?
			DX = False
			'kommentierung entfernt
		'GlEnable(GL_TEXTURE_2D)
	?Win32
		EndIf
	?
'		DebugLog "tRender : Initialise OK"
		Return True
	End Function

'#################################################################################

Rem
bbdoc: Create Image with Render Characteristics
returns: TImage Handle to Object
about:
 <table>
		<tr><td><b>Width:Int</td><td>Width in Pixels of Image, try to follow the normal rules of textures</td></tr>
		<tr><td><b>Height:Int</td><td>Height in Pixels of Image</td></tr>
		<tr><td><b>Flags:Int</td><td>Normal Image Flags</td></tr>
	</table>
End Rem
	Function Create:TImage(Width:Int,Height:Int,Flags:Int=FILTEREDIMAGE)

		Local t:TImage=New TImage
		t.width=width
		t.height=height
		t.flags=flags
		t.mask_r= 0
		t.mask_g= 0
		t.mask_b= 0
		t.pixmaps=New TPixmap[1]
		t.frames=New TImageFrame[1]
		t.seqs=New Int[1]
		t.pixmaps[0]= t.Lock(0,True,False)
		t.seqs[0]=GraphicsSeq

	'	MaskPixmap( t.pixmaps[0],mask_r,mask_g,mask_b )
	?Win32
		If DX = 1
			t.frames[0] = CreateFrame(TD3D7Max2DDriver(_max2dDriver),t.Width,t.Height,t.flags)
'		Else If DX = 2
'			t.frames[0] = CreateFrameDX9(TD3D9Max2DDriver(_max2dDriver), t.width, t.Height, t.flags)
		Else
	?
			t.frames[0] = TGLImageFrame.CreateFromPixmap:TGLImageFrame(t.pixmaps[0] , t.flags)

	?Win32
		EndIf
	?

'		DebugLog "tRender : Create OK"


		Return t

	End Function

'#################################################################################
?Win32
	Function CreateFrame:TD3D7ImageFrame(Driver:TD3D7Max2DDriver, width:Int, Height:Int, flags:Int)
		Function Pow2Size(n:Int)
			Local t:Int = 1
			While t<n
				t:*2
			Wend
			Return t
		End Function

		Local swidth:Int = Pow2Size(width)
		Local sheight:Int = Pow2Size(Height)
		Local desc:DDSURFACEDESC2 = New DDSURFACEDESC2
		Local res

		desc.dwSize=SizeOf(desc)
		desc.dwFlags=DDSD_WIDTH|DDSD_HEIGHT|DDSD_CAPS|DDSD_PIXELFORMAT
		desc.dwWidth=swidth
		desc.dwHeight=sheight
		desc.ddsCaps=DDSCAPS_TEXTURE|DDSCAPS_3DDEVICE|DDSCAPS_VIDEOMEMORY|DDSCAPS_LOCALVIDMEM  ' **************************************************
		desc.ddsCaps2=DDSCAPS2_HINTDYNAMIC'|DDSCAPS2_TEXTUREMANAGE
		desc.ddpf_dwSize=SizeOf(DDPIXELFORMAT)
		desc.ddpf_dwFlags=DDPF_RGB|DDPF_ALPHAPIXELS
		desc.ddpf_BitCount=32
		desc.ddpf_BitMask_0=$ff0000
		desc.ddpf_BitMask_1=$00ff00
		desc.ddpf_BitMask_2=$0000ff
		desc.ddpf_BitMask_3=$ff000000


		Local surf:IDirectDrawSurface7
		If flags & MIPMAPPEDIMAGE desc.ddsCaps:|DDSCAPS_MIPMAP|DDSCAPS_COMPLEX
		res=D3D7GraphicsDriver().DirectDraw7().CreateSurface( desc,Varptr surf,Null )
		If res<>DD_OK
			tRenderERROR = tRTTError(res)
			DebugLog "tRender : CreateFrame ERROR : "+tRenderERROR
			Return Null
		EndIf
		'RuntimeError "Create DX7 surface Failed"

		Local frame:TD3D7ImageFrame=New TD3D7ImageFrame
		frame.driver=driver
		frame.surface=surf
		frame.sinfo=New DDSURFACEDESC2
		frame.sinfo.dwSize=SizeOf(frame.sinfo)
		frame.xyzuv=New Float[24]
		frame.width=width
		frame.height=height
		frame.flags=flags
		frame.SetUV 0.0,0.0,Float(width)/swidth,Float(height)/sheight


		'frame.BuildMipMaps()
		DebugLog "tRender : CreateFrame OK"
		Return frame
	End Function
?

'#################################################################################
Rem
bbdoc: Set Screen Viewport
about:
 <table>
	<tr><td><b>X:Int</td><td>Set the X Position of the Viewport</td></tr>
	<tr><td><b>Y:Int</td><td>Set the Y Position of the Viewport</td></tr>
	<tr><td><b>Width:Int</td><td>Set the Viewport Width in Pixels</td></tr>
	<tr><td><b>Height:Int</td><td>Set the Viewport Height in Pixels</td></tr>
	<tr><td><b>FlipY:Byte</td><td>Flip the Viewport on the Y Axis, OpenGL only. Automatically done by the Texture Renderer.</td></tr>
 </table>
End Rem
	Function ViewportSet:int(X:Int=0,Y:Int=0,Width:Int,Height:Int,FlipY:Byte=False)
	?Win32
		If DX = 1
			Local viewport:D3DVIEWPORT7=New D3DVIEWPORT7
			viewport.dwX=x
			viewport.dwY=y
			viewport.dwWidth=width
			viewport.dwHeight=height
			D3D7GraphicsDriver().Direct3DDevice7().SetViewport(viewport)
'		Else If DX = 2
'			Local viewport:D3DVIEWPORT9 = New D3DVIEWPORT9
'			viewport.x = x
'			viewport.Y = y
'			viewport.Width = width
'			viewport.Height = Height
'			D3D9GraphicsDriver().Direct3DDevice9().SetViewport(viewport)
		Else
	?
			If FlipY
				glViewport(X, Y, Width, Height)
				glMatrixMode(GL_PROJECTION)
				glPushMatrix()
				glLoadIdentity()
				gluOrtho2D(X, GraphicsWidth(), GraphicsHeight(),Y)
				glScalef(1, -1, 1)
				glTranslatef(0, -GraphicsHeight(), 0)
				glMatrixMode(GL_MODELVIEW)
			Else
				glViewport(X, Y, Width, Height)
				glMatrixMode(GL_PROJECTION)
				glLoadIdentity()
				glOrtho(X, GraphicsWidth(), GraphicsHeight(), Y, -1, 1)
				glMatrixMode(GL_MODELVIEW)
				glLoadIdentity()
			EndIf
	?Win32
		EndIf
	?
'		DebugLog "tRender : ViewportSet OK"
		Return True
	EndFunction

'#################################################################################
Rem
bbdoc: Begin the Texture Render Process
about:
 <table>
	<tr><td><b>Image:TImage</td><td>The Image to Render to, as created with "Create" command.</td></tr>
	<tr><td><b>Viewport:Byte</td><td>True (default) to Automatically resize the viewport to the image size</td></tr>
 </table>
End Rem
	Function TextureRender_Begin:int(Image1:TImage,Viewport:Byte=True)
	SetScale Float(GraphicsWidth())/Float(ImageWidth(image1)),Float(GraphicsHeight())/Float(ImageHeight(image1))


		Image = Image1
		If Viewport Then
			Width = image1.width
			Height = image1.height
		Else
			Width = GraphicsWidth()
			Height = GraphicsHeight()
		EndIf
		If DX = 1
			'DebugLog "w : " + width + " h : " + height
			ViewportSet(0, 0, Width, Height)
'		Else If DX = 2
'			ViewportSet(0, 0, Width, Height)
		Else
			ViewportSet(0,0,Width,Height,True)
		EndIf

	?Win32
		If DX = 1
			Local DXFrame:TD3D7ImageFrame = TD3D7ImageFrame (image1.frame(0))
			D3D7GraphicsDriver().Direct3DDevice7().SetRenderTarget( DXFrame.Surface,0)
			D3D7GraphicsDriver().Direct3DDevice7().BeginScene()
'		Else If DX = 2
'			D3D9GraphicsDriver().Direct3DDevice9().SetRenderTarget(0, DX9Surface)  'backbufferDX9)
'			D3D9GraphicsDriver().Direct3DDevice9().BeginScene()
		Else
	?
			GLFrame:TGLImageFrame = TGLImageFrame(Image1.frame(0))
		'	ViewportSet(0,0,Width,Height,True)
	?Win32
		EndIf
	?
	'	debuglog "tRender : TextureRender_Begin OK"
		Return True
	End Function

	'Clear the Current Viewport with color
	'col:Int - The Color to clear the Viewport with includes Alpha AARRGGBB format.
	Function Cls(col:Int=$FF000000)
	?Win32
		If dx = 1
			D3D7GraphicsDriver().Direct3DDevice7().Clear 1,Null,D3DCLEAR_TARGET,col,0,0
'		Else If dx = 2
'			D3D9GraphicsDriver().Direct3DDevice9().Clear 1, Null, D3DCLEAR_TARGET, col, 0, 0
		Else
	?
				Local Red# 	= (col Shr 16) & $FF
				Local Green# 	= (col Shr 8) & $FF
				Local Blue# 	= col & $FF
				Local Alpha# 	= (col Shr 24) & $FF
			'	DebugLog Alpha
				glClearColor red/255.0,green/255.0,blue/255.0,alpha/255.0
				glClear GL_COLOR_BUFFER_BIT
	?Win32
		EndIf
	?
	End Function

'#################################################################################
?win32
	Function SetMipMap:int(Image:TImage,Level:Int)
		If DX = 1
			Local DXFrame:TD3D7ImageFrame = TD3D7ImageFrame (image.frame(0))

			'DXFrame.BuildMipMaps()

			Local	src:IDirectDrawSurface7
			Local	dest:IDirectDrawSurface7
			Local	caps2:DDSCAPS2
			caps2=New DDSCAPS2
			caps2.dwCaps=DDSCAPS_TEXTURE|DDSCAPS_MIPMAP'|DDSCAPS_3DDEVICE
			caps2.dwCaps2= DDSCAPS2_MIPMAPSUBLEVEL

			src = DXFrame.Surface

			Local res = src.GetAttachedSurface(caps2,Varptr dest)

			If res<>DD_OK
				tRenderERROR = tRTTError(res)
				Return False
			EndIf

			DXFrame.Surface =  dest
			dest.Release_

			'DebugLog "MipMap Selected OK"
			Return True
'		Else If DX = 2
'			Local DXFrame:TDX9ImageFrame = TDX9ImageFrame (image.Frame(0))
'
'			'DXFrame.BuildMipMaps()
'
'			Local src:IDirect3DSurface9
'			Local dest:IDirect3DSurface9
'			Local	caps2:DDSCAPS2
'			caps2=New DDSCAPS2
'			caps2.dwCaps=DDSCAPS_TEXTURE|DDSCAPS_MIPMAP'|DDSCAPS_3DDEVICE
'			caps2.dwCaps2= DDSCAPS2_MIPMAPSUBLEVEL
'
'			src = backbufferdx9
'			'DebugLog "MipMap Selected OK"
'			Return True
		Else
			Return False
		EndIf
	End Function
?

		Function Pow2Size:int(n:Int)
			Local t:Int = 1
			While t<n
				t:*2
			Wend
			Return t
		End Function

	'End the Texture Render Process
	'This Must be called when you have finished rendering To the Texture
	Function TextureRender_End:int()
	SetScale 1.0, 1.0
	?Win32
		If dx = 1
			D3D7GraphicsDriver().Direct3DDevice7().EndScene()
'		Else If dx = 2
'			D3D9GraphicsDriver().Direct3DDevice9().EndScene()
		Else
	?
'			glBindTexture_ GL_TEXTURE_2D, GLFrame.name
			glBindTexture GL_TEXTURE_2D, GLFrame.name
			glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, Pow2Size(Width), Pow2Size(Height), 0)
'			glBindTexture_ GL_TEXTURE_2D, 0
			glBindTexture GL_TEXTURE_2D, 0
	?Win32
		EndIf
	?
		ViewportSet(0,0,GraphicsWidth(),GraphicsHeight())
		DrawImageRect Image, - 2000, - 2000, 1, 1
	'	debuglog "tRender : TextureRender_End OK"
		Return True
	End Function

	'Begin the Normal BackBuffer Rendering Process
	Function BackBufferRender_Begin:int()
	?Win32
		If DX = 1 Then
			D3D7GraphicsDriver().Direct3DDevice7().SetRenderTarget(backbuffer,0)
'		Else If DX = 2 Then
'			D3D9GraphicsDriver().Direct3DDevice9().SetRenderTarget(0, backbufferdx9)
'
		Else
	?
		'entfernt
		'	If GLFrame <> Null Then glBindTexture GL_TEXTURE_2D,GLFrame.name
	?Win32
		EndIf
	?
		ViewportSet(0,0,GraphicsWidth(),GraphicsHeight())
'		DebugLog "tRender : BackBufferRender_Begin OK"
		Return True
	End Function

	'This Must be called when you have finished rendering to the BackBuffer and Before the Flip Command.
	Function BackBufferRender_End:int()
	?Win32
		If DX = 1
			D3D7GraphicsDriver().Direct3DDevice7().EndScene()
'		Else If DX = 2
'			D3D9GraphicsDriver().Direct3DDevice9().EndScene()
		Else
	?
'			glBindTexture_ GL_TEXTURE_2D, 0
			glBindTexture GL_TEXTURE_2D, 0
	?Win32
		EndIf
	?
'		DebugLog "tRender : BackBufferRender_End OK"
		Return True
	End Function

'#################################################################################


End Type


'colorize an image with rgb-colors (bigger than 255 is no problem as long grey isn't 255
Function ColorizedImage:TImage(imagea:TImage, r:Float, g:Float, b:Float)
  Local mypixmap2:TPixmap = LockImage(imagea)
  If mypixmap2.format <> PF_RGBA8888 Then mypixmap2.convert(PF_RGBA8888) 'make sure the pixmaps are 32 bit format

  UnlockImage(imagea)
  Local mypixelptr2:Int Ptr = Int Ptr(mypixmap2.PixelPtr(0,0))
  Local mypixelptr2backup:Int Ptr = mypixelptr2
  For Local my_x:Int=0 To ((mypixmap2.width)*(mypixmap2.height))
 '   If Mypixelptr2[0] = Null Then Exit
 	 Local graycolor:Int = isMonochrome(mypixelptr2[0])
     If graycolor > 0
         If mypixelptr2[0] <> 0 Then mypixelptr2[0] = ARGB_Color(ARGB_Alpha(mypixelptr2[0]), Int(graycolor * r / 100), Int(graycolor * g / 100), Int(graycolor * b / 100))
    EndIf
     mypixelptr2:+1
     If mypixelptr2 = mypixelptr2backup+(mypixmap2.pitch Shr 2)
         mypixelptr2backup=mypixelptr2
     EndIf
  Next
  mypixmap2.height = imagea.height
  mypixmap2.width = imagea.width
  Return LoadImage(mypixmap2)
End Function

'colorize an TImage and return a pixmap
Function ColorizePixmap:TPixmap(_image:TImage,frame:Int,r:Float,g:Float,b:Float)
If _image <> Null

  Local mypixmap:TPixmap= LockImage(_image, frame)
  If mypixmap.format <> PF_RGBA8888 Then mypixmap.convert(PF_RGBA8888) 'make sure the pixmaps are 32 bit format
  Local mypixmap2:TPixmap = TPixmap.Create(mypixmap.width,mypixmap.height, mypixmap.format,1)
  mypixmap2 = mypixmap.Copy()
  Local mypixelptr2:Int Ptr = Int Ptr(mypixmap2.PixelPtr(0,0))
  Local mypixelptr2backup:Int Ptr = mypixelptr2
  For Local my_x:Int=0 To ((mypixmap2.width)*(mypixmap2.height))
  '  If Mypixelptr2[0] = Null Then Exit
     Local colortone:Int = isMonochrome(mypixelptr2[0])
     If colortone > 0 And mypixelptr2[0] <> 0
       mypixelptr2[0] = ARGB_Color(ARGB_Alpha(mypixelptr2[0]),Int(colortone*r/255), Int(colortone*g/255), Int(colortone*b/255))
     EndIf
     mypixelptr2:+1
     If mypixelptr2 = mypixelptr2backup+(mypixmap2.pitch Shr 2)
         mypixelptr2backup=mypixelptr2
     EndIf
  Next
  UnlockImage(_image, Frame)
  Return mypixmap2
EndIf
End Function

'colorizing not animated images
Function ColorizeImage:TPixmap(imgpath:String, cr:Int,cg:Int,cb:Int)
  Local colorpixmap:TPixmap=LockImage(ColorizedImage(LoadImage(imgpath), cr,cg,cb))
  UnlockImage(ColorizedImage(LoadImage(imgpath), cr,cg,cb))
  Return colorpixmap
End Function

'copies an TImage to not manipulate the source image
Function CopyImage:TImage(src:TImage)
   If src = Null Then Return Null

   Local dst:TImage = New TImage
   MemCopy(dst, src, SizeOf(dst))

   dst.pixmaps = New TPixmap[src.pixmaps.length]
   dst.frames = New TImageFrame[src.frames.length]
   dst.seqs = New Int[src.seqs.length]

   For Local i:Int = 0 To dst.pixmaps.length-1
      dst.pixmaps[i] = CopyPixmap(src.pixmaps[i])
   Next

   For Local i:Int = 0 To dst.frames.length-1
      dst.Frame(i)
   Next

   MemCopy(dst.seqs, src.seqs, SizeOf(dst.seqs))

   Return dst
End Function

'colorizes an TImage (may be an AnimImage when given cell_width and height)
Function ColorizeTImage:TImage(_image:TImage, r:Int,g:Int,b:Int, cell_width:Int=0,cell_height:Int=0,first_cell:Int=0,cell_count:Int=1, flag:Int=0, loadAnimated:int = 1)
	If _image <> Null
		Local d:Int = r
		r = b;b = d
		Local mypixmap:TPixmap = LockImage(_image)
		If mypixmap.format <> PF_RGBA8888 Then mypixmap.convert(PF_RGBA8888) 'make sure the pixmaps are 32 bit format
		Local mypixmap2:TPixmap = TPixmap.Create(_image.width, _image.height, mypixmap.format, 1)
		mypixmap2 = mypixmap.Copy()
		UnlockImage(_image)
		Local mypixelptr2:Int Ptr = Int Ptr(mypixmap2.PixelPtr(0, 0))
		Local mypixelptr2backup:Int Ptr = mypixelptr2
		For Local my_x:Int=0 To ((mypixmap2.width)*(mypixmap2.height))
			Local colortone:Int = isMonochrome(mypixelptr2[0])
			If colortone > 0 And mypixelptr2[0] <> 0
				mypixelptr2[0] = ARGB_Color(ARGB_Alpha(mypixelptr2[0]), Int(colortone * r / 255), Int(colortone * g / 255), Int(colortone * b / 255))
			EndIf
			mypixelptr2:+1
			If mypixelptr2 = mypixelptr2backup+(mypixmap2.pitch Shr 2)
				mypixelptr2backup=mypixelptr2
			EndIf
		Next
		MyPixmap = Null
		If cell_width > 0 And cell_count > 0 And loadAnimated Then Return LoadAnimImage(mypixmap2, cell_width, cell_height, first_cell,cell_count, flag)
		Return LoadImage(mypixmap2)
	EndIf
End Function
'End Type
