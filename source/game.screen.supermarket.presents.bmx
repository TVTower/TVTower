SuperStrict
Import "game.screen.base.bmx"
Import "game.betty.bmx"
Import "game.player.base.bmx"
Import "Dig/base.gfx.gui.button.bmx"
Import "common.misc.datasheet.bmx"


Type TScreenHandler_SupermarketPresents extends TScreenHandler
	Global box:TRectangle = new TRectangle.Init(55,50,690,310)
	Global selectedPresent:int = 0
	Global lastSelectedPresent:int = 0

	Global buyButton:TGUIButton
	Global presentButtons:TGUIButton[10]
	Global _eventListeners:TLink[]
	Global _instance:TScreenHandler_SupermarketPresents


	Function GetInstance:TScreenHandler_SupermarketPresents()
		if not _instance then _instance = new TScreenHandler_SupermarketPresents
		return _instance
	End Function


	Method Initialize:int()
		local screen:TScreen = ScreenCollection.GetScreen("screen_supermarket_presents")
		if not screen then return False

		'=== CREATE ELEMENTS ===

		'=== create gui elements if not done yet
		if not buyButton
			buyButton = new TGUIButton.Create(new TVec2D.Init(box.GetX() + 0.5*box.GetW() - 200, box.GetY2() - 40), new TVec2D.Init(400, 25), "", "supermarket_presents")
			buyButton.spriteName = "gfx_gui_button.datasheet"
			buybutton.SetValue( GetLocale("SELECT_PRESENT_TO_BUY") )
		endif

		if not presentButtons[0]
			For local i:int = 0 to 9
				local presentX:int = 75 + (i mod 5) * (123 +8)
				local presentY:int = 90 + (i / 5) * (91 + 25)
				presentButtons[i] = new TGUIButton.Create(new TVec2D.Init(presentX, presentY), new TVec2D.Init(123,91), "present "+(i+1), "supermarket_presents")
				presentButtons[i].spriteName = "gfx_supermarket_present"+(i+1)

'				presentButtons[i].SetAutoSizeMode(TGUIButton.AUTO_SIZE_MODE_SPRITE, TGUIButton.AUTO_SIZE_MODE_SPRITE)
				presentButtons[i].caption.SetContentPosition(ALIGN_CENTER, ALIGN_TOP)
				presentButtons[i].caption.SetFont( GetBitmapFont("Default", 11, BOLDFONT) )
				presentButtons[i].SetCaptionOffset(0,92)

				presentButtons[i].SetValue( MathHelper.DottedValue(TBettyPresent.GetPresent(i).price) + getLocale("CURRENCY"))

			Next
		endif


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		
		'=== register event listeners
		'listen to clicks on the four buttons
		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickButtons, "TGUIButton") ]
		'reset button text when entering a screen
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.onBeginEnter", onEnterScreen, screen) ]

		'to update/draw the screen
		_eventListeners :+ _RegisterScreenHandler( onUpdate, onDraw, screen )
	End Method


	Method SetLanguage()
	End Method


	Method AbortScreenActions:Int()
	End Method


	'=== EVENTS ===

	'reset button text when entering the screen
	Function onEnterScreen:int( triggerEvent:TEventBase )
		'enforce button update
		selectedPresent = 0
		lastSelectedPresent = -1
	End function

	
	Function onClickButtons:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent.GetSender())
		if not button then return False

		if button = buyButton
			'buy te present
			if selectedPresent > 0
				local present:TBettyPresent = TBettyPresent.GetPresent(selectedPresent-1)
				if GetPlayerBase().GetFinance().PayMisc(present.price)
					GetBetty().GivePresent(GetPlayerBase().playerID, present)
				endif
			endif
			selectedPresent = 0
		endif

		For local i:int = 0 until presentButtons.length
			if presentButtons[i] <> button then continue

			selectedPresent = i+1
			exit
		Next
			 
	End Function


	Function onUpdate:int( triggerEvent:TEventBase )
		GetInstance().Update()
	End Function


	Function onDraw:int( triggerEvent:TEventBase )
		GetInstance().Render()
	End Function

global LS_supermarket_presents:TLowerString = TLowerString.Create("supermarket_presents")	

	Method Render()
		local skin:TDatasheetSkin = GetDatasheetSkin("customproduction")

		local contentX:int, contentY:int, contentW:int, contentH:int
		contentX = skin.GetContentX(box.GetX())
		contentY = skin.GetContentY(box.GetY())
		contentW = skin.GetContentW(box.GetW())
		contentH = skin.GetContentH(box.GetH())

		skin.RenderContent(contentX, contentY, contentW, 20, "1_top")
		contentY :+ 20
		skin.RenderContent(contentX, contentY, contentW, contentH - 20 - 30 , "2")
		contentY :+ contentH - 20 - 30
		skin.RenderContent(contentX, contentY, contentW, 30 , "1_bottom")

		GuiManager.Draw( LS_supermarket_presents )
		
		skin.RenderBorder(box.GetIntX(), box.GetIntY(), box.GetIntW(), box.GetIntH())
	End Method

	
	Method Update()
		local present:TBettyPresent = TBettyPresent.GetPresent(selectedPresent -1)

		if lastSelectedPresent <> selectedPresent
			if not present
				buyButton.SetValue( GetLocale("NO_PRESENT_SELECTED") )
				buyButton.disable()
			else
				local presentTitle:string = present.GetName()
				local presentPrice:string = MathHelper.DottedValue(present.price) + GetLocale("CURRENCY")
				if not GetPlayerBase().GetFinance().CanAfford(present.price)
					presentPrice = "|color=255,0,0|"+presentPrice+"|/color|"
				endif
				buyButton.SetValue(GetLocale("BUY_PRESENTTITLE_FOR_PRICE").Replace("%PRESENTTITLE%", "|color=50,90,135|"+presentTitle+"|/color|").Replace("%PRICE%", presentPrice) )
				buyButton.Enable()
			endif
				
			lastSelectedPresent = selectedPresent
		endif
		if present
			if not GetPlayerBase().GetFinance().CanAfford(present.price)
				if buyButton.IsEnabled() then buyButton.Disable(); lastSelectedPresent = -1
			else
				if not buyButton.IsEnabled() then buyButton.Enable(); lastSelectedPresent = -1
			endif
		endif
		GuiManager.Update( LS_supermarket_presents )
	End Method
End Type