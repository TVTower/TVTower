SuperStrict
Import "game.debug.screen.page.bmx"
Import "game.game.bmx"
Import "game.stationmap.bmx"



Type TDebugScreenPage_Stationmap extends TDebugScreenPage
	Field buttons:TDebugControlsButton[]
	Field playerStationsListHeight:Int[4]
	Field playerStationsListOffsetY:Int[4]
	Field playerStationsListButtonHeight:Int = 20
	
	Method Init:TDebugScreenPage_Stationmap()
		Local texts:String[] = ["Destroy", "Add"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], position.x, position.y)
			button._onClickHandler = OnButtonClickHandler

			buttons :+ [button]
		Next
		
		Return self
	End Method
	
	
	Method SetPosition(x:Int, y:Int)
		position = new SVec2I(x, y)

		'move buttons
		For local b:TDebugControlsButton = EachIn buttons
			b.x = x + 510 + 5
			b.y = y + b.dataInt * (b.h + 3)
		Next
	End Method
	
	
	Method Reset()
	End Method
	
	
	Method Activate()
	End Method


	Method Deactivate()
	End Method


	Method Update()
		Local playerID:Int = GetShownPlayerID()


		'move buttons
		if buttons.length >= 6
			buttons[ 0].SetXY(position.x + 510 + 70, position.y + 0 * 18 + 5).SetWH( 43, 15)
			buttons[ 1].SetXY(position.x + 510 + 90 + 47, position.y + 0 * 18 + 5).SetWH( 26, 15)
		endif


		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next

		For local i:int = 1 to 4
			UpdateBlock_PlayerStationsList(playerID, position.x + 5 * (i-1) * 135, position.y + 50, 130, 250)
		Next
	End Method


	Method Render()
		DrawOutlineRect(position.x + 510, 13, 160, 150)
		textFont.Draw("Satellites", position.x + 510, position.y + 0 * 18 + 5)

		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next
		

		For local i:int = 1 to 4
			RenderBlock_PlayerStations(i, position.x + 5 + (i-1) * 135, position.y)
			RenderBlock_PlayerStationsList(i, position.x + 5 + (i-1) * 135, position.y + 50, 130, 250)
		Next
rem
		Local headerText:String = GetLocale("COUNTRYNAME_ISO3166_"+GetStationMapCollection().GetMapISO3166Code())

		skin.fontNormal.DrawBox("|b|"+GetLocale("POPULATION")+":|/b|", col1, textY + 0*lineH, col1W,  overviewLineH, sALIGN_LEFT_TOP, skin.textColorNeutral)
		skin.fontNormal.DrawBox(TFunctions.DottedValue(GetStationMapCollection().GetPopulation()), col2, textY + 0*lineH, col2W,  overviewLineH, sALIGN_RIGHT_TOP, skin.textColorNeutral)
		skin.fontNormal.DrawBox("|b|"+GetLocale("STATIONMAP_SECTIONS_NAME")+":|/b|", col1, textY + 1*lineH, col1W,  overviewLineH, sALIGN_LEFT_TOP, skin.textColorNeutral)
		skin.fontNormal.DrawBox(GetStationMapCollection().GetSectionCount(), col2, textY + 1*lineH, col2W,  overviewLineH, sALIGN_RIGHT_TOP, skin.textColorNeutral)

		skin.fontNormal.DrawBox("|b|"+GetLocale("RECEIVER_SHARE")+"|/b|", col3, textY + 0*lineH, col3W + col4W,  overviewLineH, sALIGN_LEFT_TOP, skin.textColorNeutral)
		skin.fontNormal.DrawBox(GetLocale("ANTENNA_RECEIVERS")+":", col3, textY + 1*lineH, col3W,  overviewLineH, sALIGN_LEFT_TOP, skin.textColorNeutral, EDrawTextEffect.Shadow, 0.2)
		skin.fontNormal.DrawBox(MathHelper.NumberToString(GetStationMapCollection().GetAveragePopulationAntennaShare()*100, 2)+"%", col4, textY + 1*lineH, col4W,  overviewLineH, sALIGN_RIGHT_TOP, skin.textColorNeutral)
		skin.fontNormal.DrawBox(GetLocale("SATELLITE_RECEIVERS")+":", col3, textY + 2*lineH, col3W,  overviewLineH, sALIGN_LEFT_TOP, skin.textColorNeutral, EDrawTextEffect.Shadow, 0.2)
		skin.fontNormal.DrawBox(MathHelper.NumberToString(GetStationMapCollection().GetAveragePopulationSatelliteShare()*100, 2)+"%", col4, textY + 2*lineH, col4W,  overviewLineH, sALIGN_RIGHT_TOP, skin.textColorNeutral)
		skin.fontNormal.DrawBox(GetLocale("CABLE_NETWORK_RECEIVERS")+":", col3, textY + 3*lineH, col3W,  overviewLineH, sALIGN_LEFT_TOP, skin.textColorNeutral, EDrawTextEffect.Shadow, 0.2)
		skin.fontNormal.DrawBox(MathHelper.NumberToString(GetStationMapCollection().GetAveragePopulationCableShare()*100, 2)+"%", col4, textY + 3*lineH, col4W,  overviewLineH, sALIGN_RIGHT_TOP, skin.textColorNeutral)
endrem


	End Method


	Method RenderBlock_PlayerStations(playerID:Int, x:Int, y:Int)
		Local player:TPlayer = GetPlayer(playerID)
		Local boxWidth:Int = 130
		Local boxHeight:Int = 330

		SetColor 40,40,40
		DrawRect(x, y, boxWidth, boxHeight)
		SetColor 50,50,40
		DrawRect(x+1, y+1, boxWidth-2, boxHeight)
		SetColor 255,255,255

		Local textX:Int = x + 3
		Local textY:Int = y + 3 - 1
		Local map:TStationMap = GetStationMap(playerID)
		textFont.Draw("Player: " + playerID, textX, textY)
		textFont.DrawBox("Reach: " + MathHelper.DottedValue(map.GetReach()), textX, textY, boxWidth - 6, 16, sALIGN_RIGHT_TOP, SColor8.WHITE)
		textY :+ 15
	End Method


	Method UpdateBlock_PlayerStationsList(playerID:Int, x:Int, y:Int, w:Int, h:int)
		if THelper.MouseIn(x, y + h - 50, w/2, 50)
			If MouseManager.IsClicked(1)
				playerStationsListOffsetY[playerID - 1] :- 50
				MouseManager.SetClickHandled(1)
			EndIf
		Elseif THelper.MouseIn(x + w/2, y + h - 50, w/2, 50)
			If MouseManager.IsClicked(1)
				playerStationsListOffsetY[playerID - 1] :+ 50
				MouseManager.SetClickHandled(1)
			EndIf
		EndIf
		'clamp
		if playerStationsListHeight[playerID - 1] > h
			playerStationsListOffsetY[playerID - 1] = Min(Max(0, playerStationsListOffsetY[playerID - 1]), playerStationsListHeight[playerID - 1] - h + playerStationsListButtonHeight)
		else
			playerStationsListOffsetY[playerID - 1] = Min(Max(0, playerStationsListOffsetY[playerID - 1]), playerStationsListHeight[playerID - 1] - h)
		endif
	End Method


	Method RenderBlock_PlayerStationsList(playerID:Int, x:Int, y:Int, w:Int, h:int)
		Local player:TPlayer = GetPlayer(playerID)
		Local map:TStationMap = GetStationMap(playerID)

		Local vpx:Int, vpy:Int, vpw:Int, vph:Int
		GetViewport(vpx, vpy, vpw, vph)
		SetViewport(x, y, w, h)

		SetColor 40,40,40
		DrawRect(x, y, w, h)
		SetColor 50,50,40
		DrawRect(x+1, y+1, w-2, h)
		SetColor 255,255,255

		Local textX:Int = x + 3
		Local textY:Int = y + 3 - 1
		textY :- playerStationsListOffsetY[playerID-1]
		Local textYStart:Int = textY

		'do not render over buttons
		if playerStationsListHeight[playerID-1] > h
			SetViewport(x, y, w, h - playerStationsListButtonHeight)
		EndIf
		textFont.Draw("Antennas: " + map.GetStationCount(TVTStationType.ANTENNA), textX, textY)
		textFont.DrawBox(MathHelper.DottedValue(GetStationMapCollection().GetAntennaAudienceSum(playerID)), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, SColor8.WHITE)

		textY :+ 12
		For local section:TStationMapSection = EachIn GetStationMapCollection().sections
			Local sectionName:String = section.GetName()
			For local station:TStationAntenna = EachIn map.GetStationsBySectionName(sectionName)
				Local n:String = GetLocale("MAP_COUNTRY_"+sectionName)
				if n.length > 11 then n = n[.. 10]+".."
				Local c:SColor8 = SColor8.WHITE
				if not station.IsActive() then c = SColor8.GRAY
				textFont.DrawBox( Chr(9654) + " " + n +": " + station.GetName(), textX + 5, textY, 90, 16, sALIGN_LEFT_TOP, c)
				textFont.DrawBox(MathHelper.DottedValue(station.GetExclusiveReach()), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, c)
				textY :+ 10
			Next
		Next
		textY :+ 3

		textFont.Draw("Cable Uplinks: " + map.GetStationCount(TVTStationType.CABLE_NETWORK_UPLINK), textX, textY)
		textFont.DrawBox(MathHelper.DottedValue(GetStationMapCollection().GetCableNetworkUplinkAudienceSum(playerID)), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, SColor8.WHITE)
		textY :+ 12
		For local section:TStationMapSection = EachIn GetStationMapCollection().sections
			Local sectionName:String = section.GetName()
			Local station:TStationBase = map.GetCableNetworkUplinkStationBySectionName(sectionName)
			If station
				Local n:String = GetLocale("MAP_COUNTRY_"+sectionName)
				if n.length > 11 then n = n[.. 10]+".."
				Local c:SColor8 = SColor8.WHITE
				if not station.IsActive() then c = SColor8.GRAY
				textFont.DrawBox( Chr(9654) + " " + n +": " + station.GetName(), textX + 5, textY, 90, 16, sALIGN_LEFT_TOP, c)
				textFont.DrawBox(MathHelper.DottedValue(station.GetExclusiveReach()), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, c)
				textY :+ 10
			EndIf
		Next
		textY :+ 3

		textFont.Draw("Sat Uplinks: " + map.GetStationCount(TVTStationType.SATELLITE_UPLINK), textX, textY)
		textFont.DrawBox(MathHelper.DottedValue(GetStationMapCollection().GetSatelliteUplinkAudienceSum(playerID)), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, SColor8.WHITE)
		textY :+ 12
		For local satellite:TStationMap_Satellite = EachIn GetStationMapCollection().satellites
			Local station:TStationBase = map.GetSatelliteUplinkBySatellite(satellite)
			If station
				textFont.Draw( Chr(9654) + " " + satellite.GetName() +": till", textX + 5, textY)
				textFont.DrawBox(MathHelper.DottedValue(station.GetExclusiveReach()), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, SColor8.WHITE)
				textY :+ 10
			EndIf
		Next
		textY :+ 3
		
		if playerStationsListHeight[playerID-1] > h
			SetViewport(x, y, w, h)

			Local listH:Int = h - playerStationsListButtonHeight
			local indicatorHeight:int = listH * (float(listH) / playerStationsListHeight[playerID-1])
			local indicatorOffset:int = playerStationsListOffsetY[playerID-1] * indicatorHeight/float(listH)
			SetAlpha 0.5
			SetColor 100,100,100
			DrawRect(x + w - 2, y, 2, listH)
			SetAlpha 0.8
			SetColor 180,160,150
			DrawRect(x + w - 2, y  + indicatorOffset, 2, indicatorHeight)
			SetAlpha 1.0
			SetColor 255,255,255

			TDebugControlsButton.RenderButton(x + 5, y + h - playerStationsListButtonHeight + 2, w/2 - 10, playerStationsListButtonHeight - 4, chr(9650))
			TDebugControlsButton.RenderButton(x + w/2 + 10, y + h - playerStationsListButtonHeight + 2, w/2 - 10, playerStationsListButtonHeight - 4, chr(9660))
		EndIf
			
		SetViewport(vpx, vpy, vpw, vph)

		playerStationsListHeight[playerID-1] = textY - textYStart
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Local changeValue:Float = 1.0 '1%
		Select sender.dataInt
rem
			case 0
				GetPublicImage(1).Reset()
			case 1
				GetPublicimage(1).ChangeImage(New TAudience.InitValue(-changeValue, -changeValue))
			case 2
				GetPublicimage(1).ChangeImage(New TAudience.InitValue(changeValue, changeValue))
			case 3
				GetPublicimage(1).ChangeImage(New TAudience.InitValue(changeValue*10, changeValue*10))
			case 4
				GetPublicImage(2).Reset()
			case 5
				GetPublicimage(2).ChangeImage(New TAudience.InitValue(-changeValue, -changeValue))
			case 6
				GetPublicimage(2).ChangeImage(New TAudience.InitValue(changeValue, changeValue))
			case 7
				GetPublicimage(2).ChangeImage(New TAudience.InitValue(changeValue*10, changeValue*10))
			case 8
				GetPublicImage(3).Reset()
			case 9
				GetPublicimage(3).ChangeImage(New TAudience.InitValue(-changeValue, -changeValue))
			case 10
				GetPublicimage(3).ChangeImage(New TAudience.InitValue(changeValue, changeValue))
			case 11
				GetPublicimage(3).ChangeImage(New TAudience.InitValue(changeValue*10, changeValue*10))
			case 12
				GetPublicImage(4).Reset()
			case 13
				GetPublicimage(4).ChangeImage(New TAudience.InitValue(-changeValue, -changeValue))
			case 14
				GetPublicimage(4).ChangeImage(New TAudience.InitValue(changeValue, changeValue))
			case 15
				GetPublicimage(4).ChangeImage(New TAudience.InitValue(changeValue*10, changeValue*10))
endrem
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function
End Type