SuperStrict
Import "game.screen.base.bmx"
Import "game.betty.bmx"
Import "Dig/base.gfx.gui.button.bmx"
Import "common.misc.datasheet.bmx"


Type TScreenHandler_SupermarketPresents extends TScreenHandler
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
			buyButton = new TGUIButton.Create(new TVec2D.Init(20, 10), new TVec2D.Init(100, -1), GetLocale("BUY"), "supermarket_presents")
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

				presentButtons[i].SetValue( TFunctions.DottedValue(TBettyPresent.GetPresent(i).price) + getLocale("CURRENCY"))

			Next
		endif


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		
		'=== register event listeners
		'listen to clicks on the four buttons
'		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.onClick", onClickButtons, "TGUIArrowButton") ]
		'reset button text when entering a screen
'		_eventListeners :+ [ EventManager.registerListenerFunction("screen.onEnter", onEnterScreen, screen) ]

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
		'...
	End function

	
	Function onClickButtons:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent.GetSender())
		if not button or not buyButton then return False

		'buy
	End Function


	Function onUpdate:int( triggerEvent:TEventBase )
		GetInstance().Update()
	End Function


	Function onDraw:int( triggerEvent:TEventBase )
		GetInstance().Render()
	End Function


	Method Render()
		local skin:TDatasheetSkin = GetDatasheetSkin("customproduction")

		local box:TRectangle = new TRectangle.Init(55,50,690,300)
		local contentX:int, contentY:int, contentW:int, contentH:int
		contentX = skin.GetContentX(box.GetX())
		contentY = skin.GetContentY(box.GetY())
		contentW = skin.GetContentW(box.GetW())
		contentH = skin.GetContentH(box.GetH())

		skin.RenderContent(contentX, contentY, contentW, 20, "1_top")
		contentY :+ 20
		skin.RenderContent(contentX, contentY, contentW, contentH - 20 - 20 , "2")
		contentY :+ contentH - 20 - 20
		skin.RenderContent(contentX, contentY, contentW, 20 , "1_bottom")

		GuiManager.Draw("supermarket_presents")
		
		skin.RenderBorder(box.GetX(), box.GetY(), box.GetW(), box.GetH())
	End Method

	
	Method Update()
		GuiManager.Update("supermarket_presents")
	End Method
End Type