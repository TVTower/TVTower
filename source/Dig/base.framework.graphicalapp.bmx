Rem
	====================================================================
	class providing a basical graphical app
	====================================================================

	Your graphical app MUST extend from this class so update/render-
	functions can get called accordingly.
	Only ONE APP AT A TIME is possible


	====================================================================
	LICENCE

	Copyright (C) 2002-now Ronny Otto, digidea.de

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
Import "base.util.graphicsmanager.bmx"
Import "base.framework.app.bmx"
Import "base.framework.screen.bmx"




Type TGraphicalApp extends TApp
	'should the app do a CLS before rendering?
	Field autoCls:int = TRUE
	Field startupFadeInTime:float = 0.5
	Field resolutionX:int = 800
	Field resolutionY:int = 600


	Method Prepare:int()
		local gm:TGraphicsManager = GetGraphicsManager()
		gm.SetResolution(resolutionX, resolutionY)
		gm.SetVSync(true)
		gm.SetHertz(0)

		gm.InitGraphics()
	End Method


	Method Start:int()
		local screen:TScreen = GetScreenManager().GetCurrent()

		If screen
			screen.PrepareStart()
			screen.FadeIn(startupFadeInTime)
		endif
	End Method


	Method Update:Int()
		local screen:TScreen = GetScreenManager().GetCurrent()
		If screen
			'update screen fader
			if screen.GetFadingEffect()
				screen.GetFadingEffect().Update()
			endif

			'update screen
			If Not screen.IsFading() Or screen.GetFadingEffect().allowScreenUpdate
				screen.Update()
			endif
		EndIf

		if ExitAppRequested() then exitApp = true
	End Method


	'by default we exit on ESCAPE key
	Method ExitAppRequested:int()
		If KeyManager.IsHit(KEY_ESCAPE) then return True
		return False
	End Method


	Method Render:Int()
		if autoCls then Cls

		'render current screen
		local screen:TScreen = GetScreenManager().GetCurrent()
		If screen
			screen.RenderBackgroundLayers()
			screen.Render()
			screen.RenderForegroundLayers()

			screen.ExtraRender()

			'render a potential screen fader
			If screen.IsFading() Then screen.GetFadingEffect().Render()

			'draw debug on all (even fader)
			screen.DebugRender()
		EndIf

		'render whatever
		RenderContent()

		'render debug info?
		If debugLevel > 0 then RenderDebug()

		'render mouse cursor etc
		RenderHUD()

		'flip render buffer onto screen
		GetGraphicsManager().Flip( GetDeltaTimer().HasLimitedFPS() )
	End Method


	Method RenderContent:Int()
		'
	End Method


	Method RenderHUD:Int()
		'
	End Method


	Method RenderDebug:Int()
		DrawText("FPS: "+GetDeltaTimer().currentFPS, 0, 0)
	End Method
End Type
