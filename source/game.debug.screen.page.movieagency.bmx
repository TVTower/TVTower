SuperStrict
Import "game.debug.screen.page.bmx"
Import "game.roomhandler.movieagency.bmx"



Type TDebugScreenPage_MovieAgency extends TDebugScreenPage
	Field buttons:TDebugControlsButton[]
	Field offerHightlight:TProgrammeLicence
	Field offerHightlightOffset:Int
	Field auctions:TProgrammeLicence[] = new TProgrammeLicence[0]

	Global _instance:TDebugScreenPage_MovieAgency
	
	
	Method New()
		_instance = self
	End Method
	
	
	Function GetInstance:TDebugScreenPage_MovieAgency()
		if not _instance then new TDebugScreenPage_Movieagency
		return _instance
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
		For local b:TDebugControlsButton = EachIn buttons
			b.x :+ dx
			b.y :+ dy
		Next
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
				RoomHandler_MovieAgency.GetInstance().ReFillBlocks()
			case 1
				RoomHandler_MovieAgency.GetInstance().ReFillBlocks(True, 1.0)
			case 2
				TAuctionProgrammeBlocks.EndAllAuctions()
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function
	

	Method Reset()
		offerHightlight = Null
	End Method
	
	
	Method Activate()
	End Method


	Method Deactivate()
	End Method


	Method Update()
		Local playerID:Int = GetShownPlayerID()

		'initial refill?
		'if RoomHandler_AdAgency.listNormal.length = 0 then ReFillBlocks()

		UpdateBlock_Offers(playerID, position.x + 5, position.y + 3, 410, 230)

		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next
	End Method


	Method Render()
		Local playerID:Int = GetShownPlayerID()

		RenderBlock_Offers(playerID, position.x + 5, position.y + 3, 460, 330)

		RenderBlock_NoLongerAvailable(playerID, position.x + 5 + 250 + 5 + 250, position.y  + 3 + 55)


		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		if offerHightlight
			offerHightlight.ShowSheet(position.x + 5 + 250 + offerHightlightOffset, position.y + 3, 0, TVTBroadcastMaterialType.PROGRAMME, playerID)
		endif
	End Method


	'stuff filtered out
	Method RenderBlock_NoLongerAvailable(playerID:Int, x:int, y:int, w:int = 200, h:int = 300)
		DrawOutlineRect(x, y, w, h)

		Local textX:Int = x + 5
		Local textY:Int = y + 5

		titleFont.DrawSimple("Crap-filtered", textX, textY)
		textY :+ 12

		local movieVendor:RoomHandler_MovieAgency = RoomHandler_MovieAgency.GetInstance()

		For local pl:TProgrammeLicence = EachIn GetProgrammeLicenceCollection()._GetParentLicences().values()
			if not pl.IsReleased() then continue
'			if pl.GetMaxTopicality() > 0.15 then continue
'			if not (movieVendor.filterMoviesCheap.DoesFilter(pl) or movieVendor.filterMoviesGood.DoesFilter(pl) or movieVendor.filterSeries.DoesFilter(pl)) then continue
			if not movieVendor.filterCrap.DoesFilter(pl) then continue

			textFont.DrawBox(pl.GetTitle(), textX + 10, textY - 1, 110, 15, sALIGN_LEFT_TOP, SColor8.White)
			textFont.DrawBox(MathHelper.DottedValue(pl.GetPriceForPlayer(playerID)), textX + 10 + 110, textY - 1, 50, 15, sALIGN_RIGHT_TOP, SColor8.White)
			textFont.DrawBox(MathHelper.NumberToString(pl.GetMaxTopicality()*100,2)+"%", textX + 10 + 110 + 50 -5 + 130, textY - 1, 40, 15, sALIGN_RIGHT_TOP, SColor8.White)
			textY :+ 10
		Next
'		filterMoviesGood
	End Method


	Method RenderBlock_Information(playerID:int, x:int, y:int, w:int = 180, h:int = 150)
'		DrawOutlineRect(x, y, w, h)
	End Method



	Method UpdateBlock_Offers(playerID:int, x:int, y:int, w:int = 200, h:int = 150)
		'reset
		offerHightlight = null
		offerHightlightOffset = 0

		Local textX:Int = x + 5
		Local textY:Int = y + 5
		local barWidth:int = 200

		local movieVendor:RoomHandler_MovieAgency = RoomHandler_MovieAgency.GetInstance()
		textY :+ 12 + 10 + 5

		local textYStart:int = textY

		local licenceLists:TProgrammeLicence[][] = [movieVendor.listMoviesGood, movieVendor.listMoviesCheap, movieVendor.listSeries, auctions]
		local entryPos:int = 0
		For local listNumber:int = 0 until licenceLists.length
			if listNumber = 2
				textY = textYStart
				textX :+ barWidth + 10
				offerHightlightOffset = -365
			endif


			local licences:TProgrammeLicence[] = licenceLists[listNumber]
			textY :+ 10
			For local i:int = 0 until licences.length
				if THelper.MouseIn(textX, textY, barWidth, 10)
					offerHightlight = licences[i]
					exit
				endif

				textY :+ 10
				entryPos :+ 1
			Next
			if offerHightlight then exit

			textY :+ 5
		Next
	End Method


	Method RenderBlock_Offers(playerID:int, x:int, y:int, w:int = 200, h:int = 150)
		DrawOutlineRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5
		local barWidth:int = 200
		local movieVendor:RoomHandler_MovieAgency = RoomHandler_MovieAgency.GetInstance()

		titleFont.draw("MovieAgency", textX, textY)
		textY :+ 12
		textFont.Draw("Refilled on figure visit.", textX, textY)
		textY :+ 10
		textY :+ 5

		local textYStart:int = textY

		local auctionList:TList = TAuctionProgrammeBlocks.List
		auctions = new TProgrammeLicence[auctionList.Count()]
		local nextBid:Int[] = new Int[auctionList.Count()]
		local bidOffset:Int = movieVendor.listSeries.length * 10 + 25
		For local index:int = 0 until auctions.length
			local auction:TAuctionProgrammeBlocks = TAuctionProgrammeBlocks(auctionList.ValueAtIndex(index))
			auctions[index] = auction.GetLicence()
			nextBid[index] = auction.GetNextBid(playerID)
			if auction.bestBid > 0
				local bestBidder:TPlayer = GetPlayer(auction.bestBidder)
				textFont.DrawBox(MathHelper.DottedValue(auction.bestBid), textX + 400, textY + bidOffset + index * 10, 50, 15, sALIGN_RIGHT_TOP, bestBidder.color.ToSColor8())
			endif
		Next

		local licenceListsTitle:String[] = ["Good", "Cheap", "Series", "Auction"]
		local licenceLists:TProgrammeLicence[][] = [movieVendor.listMoviesGood, movieVendor.listMoviesCheap, movieVendor.listSeries, auctions]
		local entryPos:int = 0
		local oldAlpha:Float = GetAlpha()
		For local listNumber:int = 0 until licenceLists.length
			if listNumber = 2
				textY = textYStart
				textX :+ barWidth + 10
			endif


			local licences:TProgrammeLicence[] = licenceLists[listNumber]

			textFontBold.Draw(licenceListsTitle[listNumber] + ":", textX, textY)
			textY :+ 10
			Local blockY:Int = textY + 2
			For local i:int = 0 until licences.length
				If entryPos Mod 2 = 0
					SetColor 0,0,0
				Else
					SetColor 60,60,60
				EndIf
				SetAlpha 0.75 * oldAlpha
				DrawRect(textX, blockY, barWidth, 10)

				SetColor 255,255,255
				SetAlpha oldAlpha

				if licences[i] and licences[i] = offerHightlight
					SetAlpha 0.25 * oldAlpha
					SetBlend LIGHTBLEND
					DrawRect(textX, blockY, barWidth, 10)
					SetAlpha oldAlpha
					SetBlend ALPHABLEND
				endif

				textFont.DrawSimple(RSet(i, 2).Replace(" ", "0"), textX, textY)
				if licences[i]
					textFont.DrawBox(": " + licences[i].GetTitle(), textX + 10, textY, 110, 15, sALIGN_LEFT_TOP, SColor8.White)
					local price:Int
					if listNumber = 3
						price = nextBid[i]
					else
						price = licences[i].GetPriceForPlayer(playerID)
					endif
					textFont.DrawBox(MathHelper.DottedValue(price), textX + 10 + 110, textY, 50, 15, sALIGN_RIGHT_TOP, SColor8.White)
					textFont.DrawBox(licences[i].data.GetYear(), textX + 10 + 110 + 50 - 5, textY, barWidth - (10 + 110 + 50), 15, sALIGN_RIGHT_TOP, SColor8.White)
				else
					textFont.DrawSimple(": -", textX + 15, textY)
				endif
				textY :+ 10
				blockY :+ 10

				entryPos :+ 1
			Next
			textY :+ 5
		Next
	End Method
End Type