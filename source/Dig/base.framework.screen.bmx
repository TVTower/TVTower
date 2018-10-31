Rem
	====================================================================
	Screen + Screenmanager + Screenfader classes
	====================================================================

	Code contains following classes:
	TScreenManger: basic screen manager (Set, Get, Current, ...)
	TScreen: the basic screen containing multiple Render-functions to
	hook in.
	TScreenFader + derivates: effects for changing to other screens


	====================================================================
	LICENCE

	Copyright (C) 2002-2015 Ronny Otto, digidea.de

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
Import "base.framework.layer.bmx"
Import "base.util.deltatimer.bmx"
Import "base.util.rectangle.bmx"
Import "base.util.color.bmx"
Import "base.util.graphicsmanagerbase.bmx"
Import BRL.Max2D
Import BRL.LinkedList


Type TScreenManager
	Field screens:TMap = CreateMap()
	Field currentScreen:TScreen = Null
	Field nextScreen:TScreen = Null
	Field exitScreen:TScreen = Null
	global _instance:TScreenManager


	Method New()
		if _instance Then Throw "Multiple TScreenManager not allowed"
		_instance = self
	End Method


	Function GetInstance:TScreenManager()
		If not _instance Then New TScreenManager
		Return _instance
	End Function


	Method SetCurrent:Int(screen:TScreen)
		'if there was no current set check if we can use this
		'screen as exit screen
		if screen and not currentScreen and not exitScreen then exitScreen = screen

		currentScreen = screen
	End Method


	Method GetCurrent:TScreen()
		return currentScreen
	End Method


	Method SetNext:Int(screen:TScreen)
		nextScreen = screen
	End Method


	Method GetNext:TScreen()
		return nextScreen
	End Method


	Method SetExit:Int(screen:TScreen)
		exitScreen = screen
	End Method


	Method GetExit:TScreen()
		return exitScreen
	End Method


	'adds a screen
	'overwrites an existing screen with same name
	Method Set:int(screen:TScreen, key:string="")
		'if no key was given, use the screens name
		if key = "" then key = screen.name

		screens.Insert(key.ToUpper(), screen)
	End Method


	Method Get:TScreen(name:String)
		return TScreen(screens.ValueForKey(name.ToUpper()))
	End Method
End Type


'convencience function
Function GetScreenManager:TScreenManager()
	Return TScreenManager.GetInstance()
End Function




Type TScreen abstract
	Field name:String = ""
	Field backScreenName:String = "" 'what is the previous screen ?
	Field layers:TList = CreateList()

	'default configs
	Field fadeInEffect:TScreenFader = new TScreenFader
	Field fadeOutEffect:TScreenFader = null
	Field autoFadeIn:Int = False
	Field autoFadeDuration:Float = 0.2


	Method Init:TScreen(name:String="")
		Self.name = name
		'setup this screen
		Setup()
		return self
	End Method


	Method Setup:Int()
	End Method


	Method ToString:string()
		return "TScreen:"+name
	End Method


	Method GetName:String()
		return name
	End Method


	'called before regulary update/drawing is started
	'So something like an "initialization"
	Method PrepareStart:Int()
		'add screen to the screenmanager (overwrites if already there)
		TScreenManager.GetInstance().Set(Self)
		TScreenManager.GetInstance().SetCurrent(Self)

		If autoFadeIn then FadeIn()
	End Method


	'Render layers below zIndex 0
	Method RenderBackgroundLayers:Int()
		For Local layer:TLayer = Eachin layers
			If layer.zIndex >= 0 Then Return FALSE
			layer.Render()
		Next
	End Method


	'Render layers with zIndex >= 0
	Method RenderForegroundLayers:Int()
		For Local layer:TLayer = Eachin layers
			If layer.zIndex < 0 Then continue
			layer.Render()
		Next
	End Method



	Method Render:Int() Abstract


	Method Update:Int() Abstract


	'go to previous screen
	Method Back:Int(duration:Float = 0.2, allowScreenUpdate:Int = True)
		If backScreenName = "exit"
			FadeToScreen(Null)
		ElseIf backScreenName <> ""
			Local screen:TScreen = TScreenManager.GetInstance().Get(backScreenName)
			If screen
				FadeToScreen(screen, duration, allowScreenUpdate)
			Endif
		Endif
	End Method


	'run after fade out finished
	Method RunAfterFadeOut:Int()
		'disable fader
		if fadeOutEffect then fadeOutEffect.active = FALSE

		'give myself a Chance to tidy up before I get killed
		Kill()
		'call next screen to get ready
		TScreenManager.GetInstance().GetNext().PrepareStart()
	End Method


	'run after fade in finished
	Method RunAfterFadeIn:Int()
	End Method


	'tidy up things I have created - run before deletion
	Method Kill:Int()
	End Method


	Method ExtraRender:Int()
	End Method


	Method DebugRender:Int()
	End Method

Rem
maybe we should do something like this - to inform
screens about things - instead of having all of them
registering for events?
	Method OnMouseHit:Int(x:Int, y:Int, button:Int)
	End Method

	Method OnMouseDown:Void(x:Int, y:Int, button:Int)
	End Method

	Method OnMouseReleased:Void(x:Int, y:Int, button:Int)
	End Method
End Rem


	'adjust used fade effect according to previous/next screen
	Method AdjustFadeEffects:Int(fromScreen:Tscreen, nextScreen:TScreen)
		'by default do nothing
	End Method


	Method GetFadingEffect:TScreenFader()
		if fadeInEffect and fadeInEffect.active then return fadeInEffect
		if fadeOutEffect and fadeOutEffect.active then return fadeOutEffect
		return Null
	End Method


	Method IsFading:int()
		if fadeInEffect and fadeInEffect.active then return True
		if fadeOutEffect and fadeOutEffect.active then return True
		return False
	End Method


	Method FadeIn:int(duration:float = -1)
		if duration < 0 then duration = autoFadeDuration
		if autoFadeIn then autoFadeIn = False
		fadeInEffect.Start(duration, False, fadeInEffect.allowScreenUpdate)
	End Method


	'change to another screen
	Method FadeToScreen:Int(screen:TScreen, duration:Float=0.2, allowScreenUpdate:Int=True)
		If IsFading() Then Return False

		'if no screen is given this might mean
		'user wants to exiting
		If Not screen Then screen = TScreenManager.GetInstance().GetExit()

		'configure fading
		screen.autoFadeIn = True
		screen.autoFadeDuration = duration

		'set target screen as next one
		TScreenManager.GetInstance().SetNext(screen)

		'adjust in and out effects for current and next screen
		AdjustFadeEffects(null, screen)
		screen.AdjustFadeEffects(self, null)

		'start the fade out with my very own screen fader
		'check if there is a differing effect for fading out
		if fadeOutEffect
			fadeOutEffect.Start(duration, True, allowScreenUpdate)
		else
			fadeInEffect.Start(duration, True, allowScreenUpdate)
		endif
	End Method
End Type



'BASIC SCREEN CHANGE EFFECT
'basic class handling screen a change effect with a cross fader
Type TScreenFader
	'how long does this effect take in seconds
	Field duration:Float = 0
	'how much time is gone already
	Field timeGone:Float
	'in which direction is the effect moving ("opening/closing")
	Field fadeOut:Int = True
	Field active:Int = False
	'area covered by the fader, private property
	Field _area:TRectangle
	Field allowScreenUpdate:Int = True


	Method Start:int(duration:Float=0.2, fadeOut:Int, allowScreenUpdate:Int=True)
		If active Then Return False

		active = True
		Self.duration = duration
		Self.fadeOut = fadeOut
		Self.allowScreenUpdate = allowScreenUpdate
		timeGone = 0
	End Method


	Method Stop:Int()
		active = FALSE
	End Method


	Method GetArea:TRectangle()
		if not _area then _area = new TRectangle.Init(0,0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())
		return _area
	End Method


	Method SetArea:Int(rect:TRectangle)
		_area = rect
	End Method


	Method GetProgress:Float()
		return Max(0, Min(1, timeGone / duration))
	End Method


	Method Update:int()
		If Not active Then Return False

		timeGone :+ GetDeltaTimer().GetDelta()
		If timegone > duration
			'deactivate
			Stop()
			If fadeOut
				TScreenManager.GetInstance().GetCurrent().RunAfterFadeOut()
			Else
				TScreenManager.GetInstance().GetCurrent().RunAfterFadeIn()
			EndIf
		EndIf
	End Method


	Method Render:Int()
		If Not active then Return False
		local oldCol:TColor = new TColor.Get()

		If fadeOut
			SetAlpha(GetProgress())
		Else
			SetAlpha(1 - GetProgress())
		EndIf
		SetColor(0, 0, 0)
		DrawRect(0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight())

		oldCol.SetRGBA()
	End Method
End Type




'growing/shrinking rectangles hiding an area
Type TScreenFaderClosingRects extends TScreenFader
	Method Render:int()
		local relativeProgress:float
		If fadeOut
			relativeProgress = GetProgress()
		Else
			relativeProgress = 1 - GetProgress()
		Endif

		local col:TColor = new TColor.Get()
		local rectsWidth:float  = relativeProgress * (GetArea().GetW() / 2)
		local rectsHeight:float = relativeProgress * (GetArea().GetH() / 2)

		SetColor 0,0,0
		SetAlpha relativeProgress

		DrawRect(GetArea().GetX(), GetArea().GetY(), rectsWidth, rectsHeight)
		DrawRect(GetArea().GetX(), GetArea().GetY() + GetArea().GetH() - rectsHeight, rectsWidth, rectsHeight)

		DrawRect(GetArea().GetX() + GetArea().GetW() - rectsWidth, GetArea().GetY(), rectsWidth, rectsHeight)
		DrawRect(GetArea().GetX() + GetArea().GetW() - rectsWidth, GetArea().GetY() + GetArea().GetH() - rectsHeight, rectsWidth, rectsHeight)

		col.SetRGBA()
	End Method
End Type