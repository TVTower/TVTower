SuperStrict
Import "game.screen.base.bmx"
Import "game.betty.bmx"
Import "game.player.base.bmx"
Import "Dig/base.gfx.gui.button.bmx"
Import "common.misc.datasheet.bmx"


Type TScreenHandler_SupermarketPresents extends TScreenHandler
	Global box:TRectangle = new TRectangle.Init(117,13,679,247)
	Global draggedPresent:TGUIBettyPresent
	Global presentInSuitcase:TGUIBettyPresent
	Global vendorSprite:TSprite
	Global vendorArea:TRectangle = new TRectangle.Init(0,70,120,312)

	Global presentButtons:TGUIButton[10]
	Global presentToolTips:TTooltipBase[10]
	Global LS_supermarket_presents:TLowerString = TLowerString.Create("supermarket_presents")
	Global _eventListeners:TEventListenerBase[]
	Global _instance:TScreenHandler_SupermarketPresents
	Global spriteSuitcase:TSprite
	Global suitcaseArea:SRect = new SRect(210,260, 145, 120)

	Function GetInstance:TScreenHandler_SupermarketPresents()
		if not _instance then _instance = new TScreenHandler_SupermarketPresents
		return _instance
	End Function


	Method Initialize:int()
		local screen:TScreen = ScreenCollection.GetScreen("screen_supermarket_presents")
		if not screen then return False

		'=== CREATE ELEMENTS ===

		'=== create gui elements if not done yet

		if not spriteSuitcase
			spriteSuitcase = GetSpriteFromRegistry("gfx_suitcase_presents")
		endif

		if not presentButtons[0]
			For local i:int = 0 to 9
				local presentX:int = box.getX() + 13 + (i mod 5) * (123 + 8)
				local presentY:int = box.getY() + 13 + (i / 5) * (91 + 19)
				local present:TBettyPresent = TBettyPresent.GetPresent(i)
				presentButtons[i] = new TGUIButton.Create(new SVec2I(presentX, presentY), new SVec2I(123,91), "present "+(i+1), "supermarket_presents")
				presentButtons[i].SetSpriteName( present.getSpriteName() )
				presentButtons[i].data.add("present", present)

'				presentButtons[i].SetAutoSizeMode(TGUIButton.AUTO_SIZE_MODE_SPRITE, TGUIButton.AUTO_SIZE_MODE_SPRITE)
				presentButtons[i].caption.SetContentAlignment(ALIGN_CENTER, ALIGN_TOP)
				presentButtons[i].caption.SetFont( GetBitmapFont("Default", 11, BOLDFONT) )
				presentButtons[i].SetCaptionOffset(0,92)

				presentTooltips[i] = New TGUITooltipBase.Initialize(present.getName(), "", New TRectangle.Init(0,0,-1,-1))
				presentTooltips[i].parentArea = presentButtons[i].getScreenRect()
				presentTooltips[i].SetOrientationPreset("TOP")
				presentTooltips[i].offset = New TVec2D(0,+5)
				presentTooltips[i].SetOption(TGUITooltipBase.OPTION_PARENT_OVERLAY_ALLOWED)
				'standard icons should need a bit longer for tooltips to show up
				presentTooltips[i].dwellTime = 50

				presentButtons[i].setToolTip(presentTooltips[i])
			Next
		endif

		vendorSprite = GetSpriteFromRegistry("gfx_supermarket_vendor")


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]


		'=== register event listeners
		'listen to clicks on the four buttons
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnClick, onClickButtons, "TGUIButton") ]
		'reset button text when entering a screen
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Screen_OnBeginEnter, onEnterScreen, screen) ]
		'remove suitcase present from GUI
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Screen_OnBeginLeave, onLeaveScreen, screen) ]
		'listen to clicks on a draggable present
		_eventListeners :+ [ EventManager.registerListenerFunction(GUIEventKeys.GUIObject_OnClick, onClickPresent, "TGUIBettyPresent") ]

		'to update/draw the screen
		_eventListeners :+ _RegisterScreenHandler( onUpdate, onDraw, screen )
	End Method


	Method SetLanguage()
	End Method


	Method AbortScreenActions:Int()
		If draggedPresent
			undoDragPresent()
			Return True
		EndIf
		Return False
	End Method


	'=== EVENTS ===

	'reset button text when entering the screen
	Function onEnterScreen:int( triggerEvent:TEventBase )
		draggedPresent = null
		presentInSuitcase = null
		'update number of times a present was given
		If presentButtons[0]
			For local i:int = 0 to 9
				local present:TBettyPresent = TBettyPresent.GetPresent(i)
				presentButtons[i].SetValue( GetFormattedCurrency(present.price) +" ("+GetBetty().getPresentGivenCount(present)+"x)")
			Next
		End If
	End function

	Function onLeaveScreen:int(triggerEvent:TEventBase )
		If presentInSuitcase
			GuiManager.remove(presentInSuitcase)
		End If
		undoDragPresent()
	End Function

	Function onClickButtons:int(triggerEvent:TEventBase)
		local button:TGUIButton = TGUIButton(triggerEvent.GetSender())
		if not button then return False
		'can't buy present
		if GetInstance().presentInSuitcase or GetInstance().draggedPresent then return False

		For local i:int = 0 until presentButtons.length
			if presentButtons[i] <> button then continue
			local present:TBettyPresent=TBettyPresent(button.data.get("present"))
			if GetPlayerBase().GetFinance().CanAfford(present.price)
				GetInstance().draggedPresent = new TGUIBettyPresent.Create(button.getX(), button.getY(), present)
				draggedPresent.setLimitToState("supermarket_presents")
				GUIManager.add(GetInstance().draggedPresent)
				GUIManager.addDragged(GetInstance().draggedPresent)
			endIf
			exit
		Next
	End Function

	Function onClickPresent:int( triggerEvent:TEventBase )
		If Not CheckObservedFigureInRoom("supermarket") then Return False
		Local presentItem:TGUIBettyPresent = TGUIBettyPresent(triggerEvent._sender)
		local button:Int=triggerEvent.GetData().getInt("button",0)
		If presentItem
			Local present:TBettyPresent=presentItem.present

			If button = 2 and presentItem.isDragged()
				undoDragPresent()
				MouseManager.SetClickHandled(2)
			Else If button = 1
				Local suitcasePos:int = THelper.MouseInSRect(suitcaseArea)
				Local returnPos:int = THelper.MouseInRect(box) or THelper.MouseInRect(vendorArea)
				If suitcasePos
					If not presentInSuitcase
						if GetPlayerBase().GetFinance().CanAfford(present.price) And GetBetty().BuyPresent(GetPlayerBase().playerID, present)
							GetPlayerBase().GetFinance().PayMisc(present.price)
							undoDragPresent()
						endif
					Else if not draggedPresent
						draggedPresent = presentItem
					Else
						undoDragPresent()
					End If
				Else If returnPos
					if presentInSuitcase and GetBetty().SellPresent(GetPlayerBase().playerID, present)
						GetPlayerBase().GetFinance().SellMisc(present.price)
						presentInSuitcase = null
					End If
					undoDragPresent()
				End If
				Return True
			End If
		End If
		Return False
	End Function

	Function undoDragPresent()
		If draggedPresent
			If draggedPresent = presentInSuitcase
				draggedPresent.dropBackToOrigin()
			Else
				GuiManager.remove(draggedPresent)
			End If
			draggedPresent = null
		End If
	End Function

	Function onUpdate:int( triggerEvent:TEventBase )
		GetInstance().Update()
	End Function


	Function onDraw:int( triggerEvent:TEventBase )
		GetInstance().Render()
	End Function


	Method Render()
		local skin:TDatasheetSkin = GetDatasheetSkin("customproduction")

		local contentX:int, contentY:int, contentW:int, contentH:int
		contentX = skin.GetContentX(box.GetX())
		contentY = skin.GetContentY(box.GetY())
		contentW = skin.GetContentW(box.GetW())
		contentH = skin.GetContentH(box.GetH())

'		skin.RenderContent(contentX, contentY, contentW, 20, "1_top")
'		contentY :+ 20
		skin.RenderContent(contentX, contentY, contentW, contentH , "2")
'		contentY :+ contentH - 30
'		skin.RenderContent(contentX, contentY, contentW, 30 , "1_bottom")

		skin.RenderBorder(box.GetIntX(), box.GetIntY(), box.GetIntW(), box.GetIntH())

		spriteSuitcase.Draw(suitcaseArea.x, suitcaseArea.y)
		vendorSprite.Draw(vendorArea.GetX(), vendorArea.GetY())

		if draggedPresent
			Local oldCol:TColor = New TColor.Get()
			SetBlend LightBlend
			SetAlpha oldCol.a * Float(0.4 + 0.2 * Sin(Time.GetAppTimeGone() / 5))

			vendorSprite.Draw(vendorArea.GetX(), vendorArea.GetY())
			spriteSuitcase.Draw(suitcaseArea.x, suitcaseArea.y)

			SetAlpha oldCol.a
			SetBlend AlphaBlend
		Endif

		If draggedPresent
			GetGameBase().SetCursor(TGameBase.CURSOR_HOLD)
		Else If presentInSuitcase And presentInSuitcase.isHovered()
			GetGameBase().SetCursor(TGameBase.CURSOR_PICK)
		Else
			For local i:int = 0 until presentButtons.length
			If presentButtons[i].isHovered()
				local present:TBettyPresent = TBettyPresent(presentButtons[i].data.get("present"))
				If not presentInSuitcase and GetPlayerBase().GetFinance().CanAfford(present.price)
					GetGameBase().SetCursor(TGameBase.CURSOR_PICK)
				Else
					GetGameBase().SetCursor(TGameBase.CURSOR_PICK, TGameBase.CURSOR_EXTRA_FORBIDDEN)
				End If
				exit
			End If
			Next
		End If

		
		GuiManager.Draw( LS_supermarket_presents )
	End Method


	Method Update()
		Local present:TBettyPresent=GetBetty().getCurrentPresent(GetPlayerBaseCollection().playerID)
		If present And Not presentInSuitcase
			presentInSuitcase=new TGUIBettyPresent.Create(Int(GetInstance().suitcaseArea.x + 14), Int(GetInstance().suitcaseArea.y + 19), present)
			presentInSuitcase.setLimitToState("supermarket_presents")
		End If
		If not present And presentInSuitcase
			GUIManager.remove(presentInSuitcase)
			presentInSuitcase = null
		End If
		
		GuiManager.Update( LS_supermarket_presents )
	End Method
End Type