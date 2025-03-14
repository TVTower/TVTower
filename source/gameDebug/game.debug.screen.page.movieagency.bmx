SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.roomhandler.movieagency.bmx"

Type TDebugScreenPage_MovieAgency extends TDebugScreenPage
	Global _instance:TDebugScreenPage_MovieAgency
	Field offerHightlight:TProgrammeLicence
	Field offerHightlightOffset:Int
	Field auctions:TProgrammeLicence[] = new TProgrammeLicence[0]


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
		offerHightlight = Null
	End Method


	Method Activate()
	End Method


	Method Deactivate()
	End Method


	Method Update()
		Local playerID:Int = GetShownPlayerID()

		UpdateBlock_Offers(playerID, position.x + 5, position.y + 3, 410, 230)

		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next
	End Method


	Method UpdateBlock_Offers(playerID:Int, x:Int, y:Int, w:Int = 200, h:Int = 150)
		'reset
		offerHightlight = null
		offerHightlightOffset = 0

		Local textX:Int = x + 5
		Local textY:Int = y + 5
		Local barWidth:Int = 200

		Local movieVendor:RoomHandler_MovieAgency = RoomHandler_MovieAgency.GetInstance()
		textY :+ 12 + 10 + 5

		Local textYStart:Int = textY

		Local licenceLists:TProgrammeLicence[][] = [movieVendor.listMoviesGood, movieVendor.listMoviesCheap, movieVendor.listSeries, auctions]
		Local entryPos:Int = 0
		For Local listNumber:Int = 0 Until licenceLists.length
			If listNumber = 2
				textY = textYStart
				textX :+ barWidth + 10
				offerHightlightOffset = -365
			EndIf


			Local licences:TProgrammeLicence[] = licenceLists[listNumber]
			textY :+ 10
			For Local i:Int = 0 Until licences.length
				If THelper.MouseIn(textX, textY, barWidth, 10)
					offerHightlight = licences[i]
					Exit
				EndIf

				textY :+ 10
				entryPos :+ 1
			Next
			If offerHightlight Then Exit

			textY :+ 5
		Next
	End Method


	Method Render()
		Local playerID:Int = GetShownPlayerID()

		RenderBlock_Offers(playerID, position.x + 5, position.y + 3, 460, 330)

		RenderBlock_NoLongerAvailable(playerID, position.x + 5 + 250 + 5 + 250, position.y  + 3 + 55)


		DrawBorderRect(position.x + 510, 13, 160, 65)
		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		If offerHightlight
			offerHightlight.ShowSheet(position.x + 5 + 250 + offerHightlightOffset, position.y + 3, 0, TVTBroadcastMaterialType.PROGRAMME, playerID)
		EndIf
	End Method


	'stuff filtered out
	Method RenderBlock_NoLongerAvailable(playerID:Int, x:Int, y:Int, w:Int = 200, h:Int = 300)
		DrawBorderRect(x, y, w, h)

		Local textX:Int = x + 5
		Local textY:Int = y + 5

		titleFont.DrawSimple("Crap-filtered", textX, textY)
		textY :+ 12

		Local movieVendor:RoomHandler_MovieAgency = RoomHandler_MovieAgency.GetInstance()

		For Local pl:TProgrammeLicence = EachIn GetProgrammeLicenceCollection()._GetParentLicences().values()
			If Not pl.IsReleased() Then Continue
'			If pl.GetMaxTopicality() > 0.15 Then Continue
'			If Not (movieVendor.filterMoviesCheap.DoesFilter(pl) Or movieVendor.filterMoviesGood.DoesFilter(pl) Or movieVendor.filterSeries.DoesFilter(pl)) Then Continue
			If Not movieVendor.filterCrap.DoesFilter(pl) Then Continue

			textFont.DrawBox(pl.GetTitle(), textX + 10, textY - 1, 110, 15, sALIGN_LEFT_TOP, SColor8.White)
			textFont.DrawBox(MathHelper.DottedValue(pl.GetPriceForPlayer(playerID)), textX + 10 + 110, textY - 1, 50, 15, sALIGN_RIGHT_TOP, SColor8.White)
			textFont.DrawBox(MathHelper.NumberToString(pl.GetMaxTopicality()*100,2)+"%", textX + 10 + 110 + 50 -5 + 130, textY - 1, 40, 15, sALIGN_RIGHT_TOP, SColor8.White)
			textY :+ 10
		Next
'		filterMoviesGood
	End Method


	Method RenderBlock_Information(playerID:Int, x:Int, y:Int, w:Int = 180, h:Int = 150)
'		DrawBorderRect(x, y, w, h)
	End Method


	Method RenderBlock_Offers(playerID:Int, x:Int, y:Int, w:Int = 200, h:Int = 150)
		DrawBorderRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5
		Local barWidth:Int = 200
		Local movieVendor:RoomHandler_MovieAgency = RoomHandler_MovieAgency.GetInstance()

		titleFont.draw("MovieAgency", textX, textY)
		textY :+ 12
		textFont.Draw("Refilled on figure visit.", textX, textY)
		textY :+ 10
		textY :+ 5

		Local textYStart:Int = textY

		Local auctionList:TList = TAuctionProgrammeBlocks.List
		auctions = new TProgrammeLicence[auctionList.Count()]
		Local nextBid:Int[] = new Int[auctionList.Count()]
		Local bidOffset:Int = movieVendor.listSeries.length * 10 + 25
		For Local index:Int = 0 Until auctions.length
			Local auction:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(auctionList.ValueAtIndex(index))
			auctions[index] = auction.GetLicence()
			nextBid[index] = auction.GetNextBid(playerID)
			If auction.bestBid > 0
				Local bestBidder:TPlayer = GetPlayer(auction.bestBidder)
				textFont.DrawBox(MathHelper.DottedValue(auction.bestBid), textX + 400, textY + bidOffset + index * 10, 50, 15, sALIGN_RIGHT_TOP, bestBidder.color.ToSColor8())
			EndIf
		Next

		Local licenceListsTitle:String[] = ["Good", "Cheap", "Series", "Auction"]
		Local licenceLists:TProgrammeLicence[][] = [movieVendor.listMoviesGood, movieVendor.listMoviesCheap, movieVendor.listSeries, auctions]
		Local entryPos:Int = 0
		Local oldAlpha:Float = GetAlpha()
		For Local listNumber:Int = 0 Until licenceLists.length
			If listNumber = 2
				textY = textYStart
				textX :+ barWidth + 10
			EndIf


			Local licences:TProgrammeLicence[] = licenceLists[listNumber]

			textFontBold.Draw(licenceListsTitle[listNumber] + ":", textX, textY)
			textY :+ 10
			Local blockY:Int = textY + 2
			For Local i:Int = 0 Until licences.length
				If entryPos Mod 2 = 0
					SetColor 0,0,0
				Else
					SetColor 60,60,60
				EndIf
				SetAlpha 0.75 * oldAlpha
				DrawRect(textX, blockY, barWidth, 10)

				SetColor 255,255,255
				SetAlpha oldAlpha

				If licences[i] And licences[i] = offerHightlight
					SetAlpha 0.25 * oldAlpha
					SetBlend LIGHTBLEND
					DrawRect(textX, blockY, barWidth, 10)
					SetAlpha oldAlpha
					SetBlend ALPHABLEND
				EndIf

				textFont.DrawSimple(RSet(i, 2).Replace(" ", "0"), textX, textY)
				If licences[i]
					textFont.DrawBox(": " + licences[i].GetTitle(), textX + 10, textY, 110, 15, sALIGN_LEFT_TOP, SColor8.White)
					Local price:Int
					If listNumber = 3
						price = nextBid[i]
					Else
						price = licences[i].GetPriceForPlayer(playerID)
					EndIf
					textFont.DrawBox(MathHelper.DottedValue(price), textX + 10 + 110, textY, 50, 15, sALIGN_RIGHT_TOP, SColor8.White)
					textFont.DrawBox(licences[i].data.GetYear(), textX + 10 + 110 + 50 - 5, textY, barWidth - (10 + 110 + 50), 15, sALIGN_RIGHT_TOP, SColor8.White)
				Else
					textFont.DrawSimple(": -", textX + 15, textY)
				EndIf
				textY :+ 10
				blockY :+ 10

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
