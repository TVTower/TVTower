SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.roomhandler.movieagency.bmx"

Type TDebugScreenPage_MovieAgency extends TDebugScreenPage
	Global _instance:TDebugScreenPage_MovieAgency
	Field offerHighlight:TProgrammeLicence
	Field offerHighlightOffset:Int
	Field auctions:TProgrammeLicence[] = new TProgrammeLicence[0]
	Field crapList:TObjectList


	Method New()
		_instance = self
	End Method


	Function GetInstance:TDebugScreenPage_MovieAgency()
		If Not _instance Then new TDebugScreenPage_Movieagency
		Return _instance
	End Function


	Method Init:TDebugScreenPage_MovieAgency()
		Local texts:String[] = ["Refill Offers", "Replace Offers", "End Auctions"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], position.x, position.y)
			button.w = 115
			'custom position
			button.x = position.x + 547
			button.y = 18 + 2 + i * (button.h + 2)
			button._onClickHandler = OnButtonClickHandler

			buttons :+ [button]
		Next

		Return self
	End Method


	Method MoveBy(dx:Int, dy:Int) override
		'move buttons
		For Local b:TDebugControlsButton = EachIn buttons
			b.x :+ dx
			b.y :+ dy
		Next
	End Method


	Method Reset()
		offerHighlight = Null
	End Method


	Method Activate()
		crapList = Null
	End Method


	Method Deactivate()
		crapList = Null
	End Method


	Method Update()
		Local playerID:Int = GetShownPlayerID()

		UpdateBlock_Offers(playerID, position.x + 5, position.y + 3, 410, 230)

		If Not offerHighlight And MOUSEMANAGER.GetX() > position.x + 495 And crapList
			offerHighlightOffset = -100
			Local textX:Int = position.x + 495
			Local textY:Int = position.y + 85 + 11
			For Local p:TProgrammeLicence = EachIn crapList
				textY:+11
				If THelper.MouseIn(textX, textY, 200, 11)
					offerHighlight = p
					Exit
				EndIf
				If textY > 600 Then Exit
			Next
		EndIf

		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next
	End Method


	Method UpdateBlock_Offers(playerID:Int, x:Int, y:Int, w:Int = 200, h:Int = 150)
		'reset
		offerHighlight = null
		offerHighlightOffset = 0

		Local textX:Int = x + 2
		Local textY:Int = y + 20 + 2

		Local barWidth:Int = 205

		Local movieVendor:RoomHandler_MovieAgency = RoomHandler_MovieAgency.GetInstance()
		Local textYStart:Int = textY

		Local licenceLists:TProgrammeLicence[][] = [movieVendor.listMoviesGood, movieVendor.listMoviesCheap, movieVendor.listSeries, auctions]
		Local entryPos:Int = 0
		For Local listNumber:Int = 0 Until licenceLists.length
			If listNumber = 2
				textY = textYStart
				textX :+ barWidth + 15
				offerHighlightOffset = -365
			EndIf


			Local licences:TProgrammeLicence[] = licenceLists[listNumber]
			textY :+ 11
			For Local i:Int = 0 Until licences.length
				If THelper.MouseIn(textX, textY, barWidth, 11)
					offerHighlight = licences[i]
					Exit
				EndIf

				textY :+ 11
				entryPos :+ 1
			Next
			If offerHighlight Then Exit

			textY :+ 5
		Next
	End Method


	Method Render()
		Local playerID:Int = GetShownPlayerID()

		RenderBlock_Offers(playerID, position.x, position.y, 490, 340)

		RenderBlock_NoLongerAvailable(playerID, position.x + 495, position.y + 85, 170, 255)


		DrawWindow(position.x + 545, position.y, 120, 60, "Manipulate")
		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		If offerHighlight
			offerHighlight.ShowSheet(position.x + 5 + 250 + offerHighlightOffset, position.y + 3, 0, TVTBroadcastMaterialType.PROGRAMME, playerID)
		EndIf
	End Method


	'stuff filtered out
	Method RenderBlock_NoLongerAvailable(playerID:Int, x:Int, y:Int, w:Int = 200, h:Int = 300)
		Local movieVendor:RoomHandler_MovieAgency = RoomHandler_MovieAgency.GetInstance()

		If Not crapList
			crapList = new TObjectList
			For Local pl:TProgrammeLicence = EachIn GetProgrammeLicenceCollection()._GetParentLicences().values()
				If Not pl.IsReleased() Then Continue
	'			If pl.GetMaxTopicality() > 0.15 Then Continue
	'			If Not (movieVendor.filterMoviesCheap.DoesFilter(pl) Or movieVendor.filterMoviesGood.DoesFilter(pl) Or movieVendor.filterSeries.DoesFilter(pl)) Then Continue
				If Not movieVendor.filterCrap.DoesFilter(pl) Then Continue
				crapList.addLast(pl)
			Next
			crapList.sort(False, CrapSort)
		EndIf

		Local contentRect:SRectI = DrawWindow(x, y, w, h, "Crap-Filtered ("+crapList.size+")")

		Local textX:Int = contentRect.x
		Local textY:Int = contentRect.y
		Local oldAlpha:Float = GetAlpha()

		For Local pl:TProgrammeLicence = EachIn crapList
			textFont.DrawBox(pl.GetTitle(), textX , textY - 1, 110, 15, sALIGN_LEFT_TOP, SColor8.White)
			textFont.DrawBox(TFunctions.LocalizedDottedValue(pl.GetPriceForPlayer(playerID)), textX  + 110, textY - 1, 50, 15, sALIGN_RIGHT_TOP, SColor8.White)
			'textFont.DrawBox(TFunctions.LocalizedNumberToString(pl.GetMaxTopicality()*100,2)+"%", textX + 110 + 50 -5 + 130, textY - 1, 40, 15, sALIGN_RIGHT_TOP, SColor8.White)
			If pl And pl = offerHighlight
				SetAlpha 0.25 * oldAlpha
				SetBlend LIGHTBLEND
				DrawRect(textX , textY, 160, 11)
				SetAlpha oldAlpha
				SetBlend ALPHABLEND
			EndIf
			textY :+ 11
			If textY > 600 Then Exit 'do not render all
		Next

	End Method

	Function CrapSort:Int(o1:Object, o2:Object)
		Local a1:TProgrammeLicence = TProgrammeLicence(o1)
		Local a2:TProgrammeLicence = TProgrammeLicence(o2)
		If a1 And a2 And a1.GetData() And a2.GetData()
			If a1.GetData().GetReleaseTime() > a2.GetData().GetReleaseTime()
				Return 1
			Else
				Return -1
			EndIf
		endif
		return 0
	End Function


	Method RenderBlock_Information(playerID:Int, x:Int, y:Int, w:Int = 180, h:Int = 150)
'		DrawBorderRect(x, y, w, h)
	End Method


	Method RenderBlock_Offers(playerID:Int, x:Int, y:Int, w:Int = 200, h:Int = 150)
		Local contentRect:SRectI = DrawWindow(x, y, w, h, "MovieAgency", "(Refilled on figure visit)")

		Local textX:Int = contentRect.x
		Local textY:Int = contentRect.y
		Local barWidth:Int = 205
		Local movieVendor:RoomHandler_MovieAgency = RoomHandler_MovieAgency.GetInstance()

		Local textYStart:Int = textY

		Local auctionList:TList = TAuctionProgrammeBlocks.List
		auctions = new TProgrammeLicence[auctionList.Count()]
		Local nextBid:Int[] = new Int[auctionList.Count()]
		Local bidOffset:Int = movieVendor.listSeries.length * 10 + 42

		textFontBold.DrawBox("Offer", textX + 410, textY + bidOffset - 12, 60, 15, sALIGN_RIGHT_TOP, SColor8.White)

		For Local index:Int = 0 Until auctions.length
			Local auction:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(auctionList.ValueAtIndex(index))
			auctions[index] = auction.GetLicence()
			nextBid[index] = auction.GetNextBid(playerID)
			If auction.bestBid > 0
				Local bestBidder:TPlayer = GetPlayer(auction.bestBidder)
				textFont.DrawBox(TFunctions.LocalizedDottedValue(auction.bestBid), textX + 410, textY + bidOffset + index * 11, 60, 15, sALIGN_RIGHT_TOP, bestBidder.color.ToSColor8())
			Else
				textFont.DrawBox("---", textX + 410, textY + bidOffset + index * 11, 60, 15, sALIGN_RIGHT_TOP, New SColor8(200,200,200, 200))
			EndIf
		Next

		Local licenceListsTitle:String[] = ["Good", "Cheap", "Series", "Auction"]
		Local licenceLists:TProgrammeLicence[][] = [movieVendor.listMoviesGood, movieVendor.listMoviesCheap, movieVendor.listSeries, auctions]
		Local entryPos:Int = 0
		Local oldAlpha:Float = GetAlpha()
		For Local listNumber:Int = 0 Until licenceLists.length
			If listNumber = 2
				textY = textYStart
				textX :+ barWidth + 15
			EndIf


			Local licences:TProgrammeLicence[] = licenceLists[listNumber]

			textFontBold.Draw(licenceListsTitle[listNumber] + ":", textX, textY)
			textY :+ 12
			Local blockY:Int = textY + 2
			For Local i:Int = 0 Until licences.length
				If entryPos Mod 2 = 0
					SetColor 0,0,0
				Else
					SetColor 60,60,60
				EndIf
				SetAlpha 0.75 * oldAlpha
				DrawRect(textX, blockY, barWidth, 11)

				SetColor 255,255,255
				SetAlpha oldAlpha

				If licences[i] And licences[i] = offerHighlight
					SetAlpha 0.25 * oldAlpha
					SetBlend LIGHTBLEND
					DrawRect(textX, blockY, barWidth, 11)
					SetAlpha oldAlpha
					SetBlend ALPHABLEND
				EndIf

				textFont.DrawSimple(RSet(i, 2).Replace(" ", "0"), textX, textY)
				If licences[i]
					textFont.DrawBox(": " + licences[i].GetTitle(), textX + 13, textY, 115, 20, sALIGN_LEFT_TOP, SColor8.White)
					Local price:Int
					If listNumber = 3
						price = nextBid[i]
					Else
						price = licences[i].GetPriceForPlayer(playerID)
					EndIf
					textFont.DrawBox(TFunctions.LocalizedDottedValue(price), textX + 10 + 115, textY, 50, 20, sALIGN_RIGHT_TOP, SColor8.White)
					textFont.DrawBox(licences[i].data.GetYear(), textX + 10 + 115 + 53 - 5, textY, barWidth - (10 + 115 + 50), 20, sALIGN_RIGHT_TOP, New SColor8(200,200,200))
				Else
					textFont.DrawSimple(": ---", textX + 15, textY)
				EndIf
				textY :+ 11
				blockY :+ 11

				entryPos :+ 1
			Next
			textY :+ 5
		Next
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Select sender.dataInt
			Case 0
				RoomHandler_MovieAgency.GetInstance().ReFillBlocks()
			Case 1
				RoomHandler_MovieAgency.GetInstance().ReFillBlocks(True, 1.0)
			Case 2
				TAuctionProgrammeBlocks.EndAllAuctions()
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function
End Type
