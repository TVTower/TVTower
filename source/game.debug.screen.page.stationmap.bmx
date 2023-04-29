SuperStrict
Import "game.debug.screen.page.bmx"
Import "game.game.bmx"
Import "game.stationmap.bmx"

'TODO: * data sheet when hovering
'      * reset on "map" change
'      * sorting (by section, by audience count, by "name", running cost (absolute/per 1000 viewers))
'      * make buttons less wide
Type TDebugScreenPage_Stationmap extends TDebugScreenPage
	Global _instance:TDebugScreenPage_Stationmap
	Field buttons:TDebugControlsButton[]
	Field attributeToShow:Int = 0 '0=exclusive reach, 1=running costs, 2=costs/1K viewer
	Field currentPlayer:Int = -1
	Field satellites:TList = CreateList()
	Field cables:TList = CreateList()
	Field antennas:TList = CreateList()

	Method New()
		_instance = self
	End Method

	Function GetInstance:TDebugScreenPage_Stationmap()
		if not _instance then new TDebugScreenPage_Stationmap
		return _instance
	End Function 

	Method Init:TDebugScreenPage_Stationmap()
		Local texts:String[] = ["show exclusive reach", "show running costs", "show costs/1K Viewer"]
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
		currentPlayer = -1
		satellites.Clear()
		cables.Clear()
		antennas.Clear()
	End Method


	Method Activate()
		Reset()
	End Method


	Method Deactivate()
		Reset()
	End Method


	Method Update()
		Local playerID:Int = GetShownPlayerID()
		If playerID <> currentPlayer
			Reset() 'in particular clear the arrays
			Local map:TStationMap = GetStationMap(playerID)
			For local satellite:TStationMap_Satellite = EachIn GetStationMapCollection().satellites
				Local station:TStationBase = map.GetSatelliteUplinkBySatellite(satellite)
				If station
					satellites.AddLast(station)
				EndIf
			Next
			For local section:TStationMapSection = EachIn GetStationMapCollection().sections
				Local sectionName:String = section.name
				Local station:TStationBase = map.GetCableNetworkUplinkStationBySectionName(sectionName)
				If station
					cables.AddLast(station)
				EndIf
				For Local station:TStationAntenna = EachIn map.GetStationsBySectionName(sectionName)
					antennas.AddLast(station)
				Next
			Next
			currentPlayer = playerID
		EndIf

		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next
	End Method


	Method Render()
		Local playerID:Int = GetShownPlayerID()

		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next
		Local boxWidth:Int = 130
		Local boxHeight:Int = 330
		Local fistBlockOffset:Int = 15

		RenderBlock_PlayerStations(playerID, position.x + 5, position.y, boxWidth, boxHeight)
		RenderBlock_PlayerStationsList(playerID, fistBlockOffset, position.x + 5, position.y, boxWidth, boxHeight)
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


	Method RenderBlock_PlayerStations(playerID:Int, x:Int, y:Int, w:Int, h:Int)
		Local player:TPlayer = GetPlayer(playerID)

		For Local i:Int = 0 Until 4
			SetColor 40,40,40
			DrawRect(x + i*135, y, w, h)
			SetColor 50,50,40
			DrawRect(x + 1 + i*135, y+1, w-2, h)
			SetColor 255,255,255
		Next

		Local textX:Int = x + 3
		Local textY:Int = y + 3 - 1
		Local map:TStationMap = GetStationMap(playerID)
		textFont.Draw("Player: " + playerID, textX, textY)
		textFont.DrawBox("Reach: " + MathHelper.DottedValue(map.GetReach()), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, SColor8.WHITE)
	End Method


	Method RenderBlock_PlayerStationsList(playerID:Int, firstBlockOffset:Int, x:Int, y:Int, w:Int, h:int)
		Local player:TPlayer = GetPlayer(playerID)
		Local map:TStationMap = GetStationMap(playerID)

		Local textX:Int = x + 3
		Local textY:Int = y + firstBlockOffset + 3 - 1
		Local textYStart:Int = textY

		textFont.Draw("Sat Uplinks: " + map.GetStationCount(TVTStationType.SATELLITE_UPLINK), textX, textY)
		If attributeToShow = 0 Then textFont.DrawBox(MathHelper.DottedValue(GetStationMapCollection().GetSatelliteUplinkAudienceSum(playerID)), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, SColor8.WHITE)
		textY :+ 12
		For local station:TStationBase = EachIn satellites
			Local n:String =station.GetName()
			if n.length > 13 then n = ".." + n[n.length-12..]
			textFont.Draw( Chr(9654) + " " + n, textX + 5, textY)
			textFont.DrawBox(getValueToShow(station, attributeToShow), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, SColor8.WHITE)
			textY :+ 10
		Next
		textY :+ 3

		textFont.Draw("Cable Uplinks: " + map.GetStationCount(TVTStationType.CABLE_NETWORK_UPLINK), textX, textY)
		If attributeToShow = 0 Then textFont.DrawBox(MathHelper.DottedValue(GetStationMapCollection().GetCableNetworkUplinkAudienceSum(playerID)), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, SColor8.WHITE)
		textY :+ 12
		For local station:TStationBase = EachIn cables
			Local iso:String = station.GetSectionISO3166Code()
			Local n:String = GetLocale("MAP_COUNTRY_"+iso+"_LONG")
			if n.length > 13 then n = n[.. 12]+".."
			Local c:SColor8 = SColor8.WHITE
			if not station.IsActive() then c = SColor8.GRAY
			textFont.DrawBox( Chr(9654) + " " + n, textX + 5, textY, 90, 16, sALIGN_LEFT_TOP, c)
			textFont.DrawBox(getValueToShow(station, attributeToShow), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, c)
			textY :+ 10
		Next
		textY :+ 3

		textFont.Draw("Antennas: " + map.GetStationCount(TVTStationType.ANTENNA), textX, textY)
		If attributeToShow = 0 Then textFont.DrawBox(MathHelper.DottedValue(GetStationMapCollection().GetAntennaAudienceSum(playerID)), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, SColor8.WHITE)

		textY :+ 12
		For local station:TStationBase = EachIn antennas
			If textY >= y + h - 1
				x = x + 135
				textX:Int = x + 3
				textY:Int = y - 1
			EndIf
			Local iso:String = station.GetSectionISO3166Code()
			Local n:String = GetLocale("MAP_COUNTRY_"+iso+"_SHORT")
			if n.length > 13 then n = n[.. 12]+".."
			Local c:SColor8 = SColor8.WHITE
			if not station.IsActive() then c = SColor8.GRAY
			textFont.DrawBox( Chr(9654) + " " + n +": " + station.GetName(), textX + 5, textY, 90, 16, sALIGN_LEFT_TOP, c)
			textFont.DrawBox(getValueToShow(station, attributeToShow), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, c)
			textY :+ 10
		Next

		Function getValueToShow:String(station:TStationBase, typeToShow:Int)
			Select typeToShow
				case 0
					return MathHelper.DottedValue(station.GetExclusiveReach())
				case 1
					return MathHelper.DottedValue(station.GetRunningCosts())
				case 2
					return MathHelper.DottedValue(1000.0 * station.GetRunningCosts() / station.GetExclusiveReach())
			End Select
		EndFunction
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
				GetInstance().attributeToShow = 0
			case 1
				GetInstance().attributeToShow = 1
			case 2
				GetInstance().attributeToShow = 2
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function
End Type