Rem
	====================================================================
	Virtual camera class
	====================================================================

	Class handles virtual resolutions for a given/fixed resolution.
	Extensions might change behaviour (stretching, extending, ...).

	TSurfaceCamera
	Fixed viewport, no scaling. Basement for extensions.

	TStretchingSurfaceCamera
	Keeps aspect-ratio, scales and addes letterboxes

	TExtendingSurfaceCamera
	Camera limiting to a specific min-max virtual resolution
	
	====================================================================
	LICENCE

	Copyright (C) 2015 Ronny Otto, digidea.de

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
Import BRL.Graphics
Import BRL.Max2D


'try to fetch the native resolution upon "bootstrapping"
TSurfaceCamera.FetchNativeResolution()
TSurfaceCamera.defaultCamera = new TSurfaceCamera

'The basic surfacecamera should not change anything to the "known"
'behaviour of vanilla BlitzMax in desktop applications.
Type TSurfaceCamera
	'=== VARIABLES SHARED ACROSS ALL CAMERAS ===
	'feel free to make "nativeWidth" available using a system module!
	'then the code could be moved from here to somewhere else
	Global nativeWidth:Int = 0
	Global nativeHeight:Int = 0
	'does the used device force a specific resolution when run in
	'fullscreen?
	?android
	'default to true on android devices
	Global deviceForcesFullscreenResolution:Int = True
	?Not android
	Global deviceForcesFullscreenResolution:Int = False
	?
	Global activeCamera:TSurfaceCamera
	Global defaultCamera:TSurfaceCamera

	'=== CAMERA SPECIFIC VARIABLES ===
	Field width:Int
	Field height:Int
	Field offsetX:Float = 0.0
	Field offsetY:Float = 0.0
	Field scaleX:Float = 1.0
	Field scaleY:Float = 1.0


	Method New()
		'try to fetch the native resolution
		If nativeWidth = 0 Or nativeHeight = 0
			FetchNativeResolution()
		EndIf

		'set current camera as initial camera if not done yet
		If Not activeCamera Then Self.Activate()
	End Method


	'camera specific
	Method Init:TSurfaceCamera( dimensions:Int[] = Null )
		If dimensions = Null Or dimensions.length < 2
			Self.width = GetGraphicsWidth()
			Self.height = GetGraphicsHeight()
		Else
			Self.width = dimensions[0]
			Self.height = dimensions[1]
		EndIf
		Return Self
	End Method


	Method Activate()
		'try to takeover dimensions
		'the default camera will ignore the values and set it to the
		'graphics dimension
		If activeCamera
			SetDimension(activeCamera.GetWidth(), activeCamera.GetHeight())
		EndIf

		'not yet initialized?
		if width = 0 and height = 0 then Init()
		
		activeCamera = Self
	End Method


	Method Deactivate()
		if defaultCamera then defaultCamera.Activate()
	End Method


	Function GetActiveCamera:TSurfaceCamera()
		if not activeCamera then return defaultCamera
		return activeCamera
	End Function


	'fetch the native resolution using functions provided by BlitzMax
	'if there is another possibility: modify this method
	Function FetchNativeResolution()
		nativeWidth = DesktopWidth()
		nativeHeight = DesktopHeight()
	End Function


	'returns the aspect ratio of the (potential) native desktop resolution
	Method GetNativeAspectRatio:Float()
		If nativeWidth = 0 Or nativeHeight = 0 Then Throw "Invalid native resolution: "+nativeWidth+" x "+nativeHeight
		Return nativeWidth / Float(nativeHeight)
	End Method


	'returns the aspect ratio of the created graphics context
	Method GetGraphicsAspectRatio:Float()
		If GetGraphicsWidth() = 0 Or GetGraphicsWidth() = 0 Then Throw "Invalid graphics resolution: "+GraphicsWidth()+" x "+GraphicsHeight()
		Return GetGraphicsWidth() / Float(GetGraphicsHeight())
	End Method


	'returns the aspect ratio of the camera
	Method GetAspectRatio:Float()
		If GetWidth() = 0 Or GetHeight() = 0 Then Throw "Invalid camera resolution: "+GetWidth()+" x "+GetHeight()
		Return GetWidth() / Float(GetHeight())
	End Method


	Method SetDimension( width:Int, height:Int )
		'ignore incoming dimension
		CalculateViewport()
	End Method


	Method ResetViewport()
		SetVirtualResolution( GetWidth(), GetHeight() )
		SetViewport( 0, 0, GetWidth(), GetHeight() )
		SetOrigin( 0, 0 )
	End Method


	Method CalculateViewport()
		SetVirtualResolution( GetWidth(), GetHeight() )
		SetViewport( 0, 0, GetWidth(), GetHeight() )
		SetOrigin( 0, 0 )
	End Method


	Method SetOffset( offsetX:Float, offsetY:Float)
		'stub - default camera does not use offsets
	End Method
	

	Method GetMouseX:Float ()
		Return MouseX()
	End Method


	Method GetMouseY:Float ()
		Return MouseY()
	End Method


	Method GetWidth:Int()
		'return the intended width, not the really existing one could
		'get with GetGraphicsWidth()
		Return GraphicsWidth()
	End Method


	Method GetHeight:Int()
		'return the intended height, not the really existing one could
		'get with GetGraphicsHeight()
		Return GraphicsHeight()
	End Method


	'Display might not allow the given full screen resolution.
	'Eg. Android devices run in their native display resolution.
	'    Also some monitors only run in their native resolution when
	'    starting fullscreen applications.
	Method GetGraphicsWidth:Int()
		If GraphicsDepth() And deviceForcesFullscreenResolution And nativeWidth > 0
			Return nativeWidth
		Else
			Return GraphicsWidth()
		EndIf
	End Method

	'see GetGraphisWidth
	Method GetGraphicsHeight:Int()
		If GraphicsDepth() And deviceForcesFullscreenResolution And nativeHeight > 0
			Return nativeHeight
		Else
			Return GraphicsHeight()
		EndIf
	End Method


	Method GrabPixmap:TPixmap( x:Int, y:Int, w:Int, h:Int )
		Return _max2dDriver.GrabPixmap( x, y, w, h )
	End Method
End Type




'A camera which stretches the content while keeping the aspect ratio.
Type TStretchingSurfaceCamera Extends TSurfaceCamera

	'camera specific
	Method Init:TStretchingSurfaceCamera( dimensions:Int[] )
		If dimensions.length < 2 Then Throw "TStretchingSurfaceCamera.Init(): at least 2 arguments needed."

		Super.init(dimensions)

		Return Self
	End Method

	'override
	Method SetOffset( offsetX:Float, offsetY:Float )
		Self.offsetX = offsetX
		Self.offsetY = offsetY
	End Method


	'override
	Method SetDimension( width:Int, height:Int )
		Self.width = width
		Self.height = height

		CalculateViewport()
	End Method
	

	'override
	Method CalculateViewport()

		'=== BLACK LETTERBOX ===
		Local clsR:Int, clsG:Int, clsB:Int
		GetClsColor( clsR, clsG, clsB )
		SetClsColor( 0, 0, 0 )
		'blitzSupport: Clear both front AND back buffers or it flickers
		'              if new display area is smaller...
		'Ronny: Think about another method of cleaning the "letterbox 
		'       areas" - without doing cls/flip as this flickers 1 time.
		'       Maybe a "reset + draw border parts + set viewport again"
		'       would help.
		Cls;Flip; Cls;Flip; Cls;Flip
		SetClsColor( clsR, clsG, clsB )

		'calculate individual scales
		scaleX = GetGraphicsHeight() / Float(GetHeight())
		scaleY = GetGraphicsWidth() / Float(GetWidth())

		'fit to WIDTH
		If scaleY >= scaleX
			SetVirtualResolution( GetGraphicsAspectRatio() * GetHeight(), GetHeight() )
			offsetX = 0.5 * ( GetGraphicsWidth() / scaleX - GetWidth() )
			offsetY = 0
		'fit to HEIGHT
		Else
			SetVirtualResolution( GetWidth(), 1.0/GetGraphicsAspectRatio() * GetWidth() )

			offsetX = 0
			offsetY = 0.5 * (GetGraphicsHeight()/scaleY - GetHeight())
		EndIf

		'setup viewport
		SetViewport( offsetX, offsetY, GetWidth(), GetHeight() )
		SetOrigin( offsetX, offsetY )
	End Method


	'override
	Method GetMouseX:Float ()
		Return Max(0, Min(width - 1, VirtualMouseX () - offsetX))
	End Method


	'override
	Method GetMouseY:Float ()
		Return Max(0, Min(height - 1, VirtualMouseY () - offsetY))
	End Method


	'override
	Method GetWidth:Int()
		Return width
	End Method


	'override
	Method GetHeight:Int()
		Return height
	End Method


	'override
	Method GrabPixmap:TPixmap( x:Int, y:Int, w:Int, h:Int )
		Local scaleX:Float = GraphicsWidth() / Float(width)
		Local scaleY:Float = GraphicsHeight() / Float(height)
		Return _max2dDriver.GrabPixmap( x * scaleX + offsetX, y* scaleY + offsetY, w * scaleX, h * scaleY )
	End Method
End Type



'The extending surface camera is defined by a minimum aspect ratio and
'a maximum aspect ratio.
'At the extremum of one of them the app will show letterboxing on the
'left/right - or - top/bottom
Type TExtendingSurfaceCamera Extends TStretchingSurfaceCamera
	Field minWidth:Int = 0
	Field minHeight:Int = 0
	Field maxWidth:Int = 0
	Field maxHeight:Int = 0

	'camera specific
	'the given dimensions define the useable area (the union of the
	'given resolutions).
	'Ex.: [800,600, 854,480]
	'     results in minArea "800x480" and maxArea "854,600" 
	Method Init:TExtendingSurfaceCamera( dimensions:Int[] )
		If dimensions.length < 2 Then Throw "TExtendingSurfaceCamera.Init(): at least 2 arguments needed."
		If minWidth = 0 And minHeight = 0 And minWidth = 0 And minHeight = 0
			If dimensions.length >= 4
				SetMinMaxRatios(dimensions[0], dimensions[1], dimensions[2], dimensions[3])
			Else
				SetMinMaxRatios(dimensions[0], dimensions[1])
			EndIf
		EndIf
		
		Super.Init(dimensions)
		Return Self
	End Method


	Method SetMinMaxRatios( minRatioWidth:Int, minRatioHeight:Int, maxRatioWidth:Int=0, maxRatioHeight:Int=0 )
		If maxRatioWidth = 0 Then maxRatioWidth = minRatioWidth
		If maxRatioHeight = 0 Then maxRatioHeight = minRatioHeight

		Self.minWidth = Min(minRatioWidth, maxRatioWidth)
		Self.minHeight = Min(minRatioHeight, maxRatioHeight)
		Self.maxWidth = Max(minRatioWidth, maxRatioWidth)
		Self.maxHeight = Max(minRatioHeight, maxRatioHeight)
	End Method


	Method CalculateViewport()
		'if the requested viewport lies within the given ratios we
		'could let the stretched camera do the work
        If IsBetween(width, minWidth, maxWidth) And IsBetween(height, minHeight, maxHeight)
            Super.CalculateViewport()
			Return
		EndIf

        
        Local scaleForMinSize:Float = minWidth / Float(width)  
        Local scaleForMaxSize:Float = maxWidth / Float(width)

		'check if the maxSize is bigger than the calculated ones
        Local newWidth:Float = width * scaleForMaxSize  
        Local newHeight:Float = newWidth / GetAspectRatio()  
		If IsBetween(newWidth, minWidth, maxWidth) And IsBetween(newHeight, minHeight, maxHeight)
            Self.width = newWidth
            Self.height = newHeight
	    Else
			newWidth = width * scaleForMinSize
			newHeight = newWidth / GetAspectRatio()
			If IsBetween(newWidth, minWidth, maxWidth) And IsBetween(newHeight, minHeight, maxHeight)
				Self.width = newWidth
				Self.height = newHeight
			Else
				'just keep the currently stored width/height
			EndIf
		EndIf

		'again we leave it up to the stretched camera to do the letter-
		'boxing and offset calculation
		Super.CalculateViewport()
		Return
		

		Function IsBetween:Int(value:Float, minValue:Float, maxValue:Float)
			Return (value >= minValue And value <= maxValue)  
		End Function
	End Method

Rem
	'approach of "libgdx" extendViewport - seems to do the same
	'than an normal "stretch + keep aspect ratio"
	'override
	Method CalculateViewport()
		'if no min/max was defined, fallback to "stretched" (parent)
		if minWidth = 0 or minHeight = 0
			super.CalculateViewport()
			return
		endif

		local newWidth:Float = minWidth 
		local newHeight:Float = minHeight
		'try to fit the minimum dimension to the screen
		local scale:Float = 1.0
		if (float(height) / float(width)) > (newHeight / newWidth)
			scale = width / newWidth
		else
			scale = height / newHeight
		endif

		'store rounded...
		local scaledW:Int = _RoundInt(newWidth * scale)
		local scaledH:Int = _RoundInt(newHeight * scale)


		'extend the shorter dimension
		if scaledW < GetWidth()
			'set lengthen factor according the scaleRatio for the minSize
			local lengthen:float = (GetWidth() - scaledW) * (newHeight / GetHeight())
			lengthen = min(lengthen, maxWidth - minWidth)
			newWidth :+ lengthen
			'increase size by lengthen factor * scaledRatio
			scaledW :+ int(lengthen * (scaledH / float(GetHeight())))
		elseif scaledH < GetHeight()
			local lengthen:float = (GetHeight() - scaledW) * (newWidth / GetWidth())
			lengthen = min(lengthen, maxHeight - minHeight)
			newHeight :+ lengthen
			'increase size by lengthen factor * scaledRatio
			scaledH :+ int(lengthen * (scaledW / float(GetWidth())))
		endif
		self.width = _RoundInt(newWidth)
		self.height = _RoundInt(newHeight)
		'now we leave it to the "stretching" camera to add letterboxes
		'and calculate offsets
		super.CalculateViewport()

		Function _RoundInt:int(f:float)
			return f + 0.5*Sgn(f)
		End Function
	End Method
endrem
End Type