SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.game.bmx"
Import "../game.stationmap.bmx"

'TODO: * reset on "map" change
'      * change summary value depending on attribute to show (reach, cost, cost per receiver)?
Type TDebugScreenPage_Stationmap extends TDebugScreenPage
	Global _instance:TDebugScreenPage_Stationmap
	Field attributeToShow:Int = 0 '0=exclusive reach, 1=running costs, 2=costs/1K excl.receiver
	Field sortMode:Int = 0 '0=default, 1=exclusive reach 2=cost, 3=cost/excl.receiver
	Field currentPlayer:Int = -1
	Field satellites:TList = CreateList()
	Field cables:TList = CreateList()
	Field antennas:TList = CreateList()


	Method New()
		_instance = self
	End Method


	Function GetInstance:TDebugScreenPage_Stationmap()
		If Not _instance Then new TDebugScreenPage_Stationmap
		Return _instance
	End Function


	Method Init:TDebugScreenPage_Stationmap()
		Local texts:String[] = ["show excl. receivers", "show running costs", "show costs/1K excl.r.", "default sort", "sort by excl. receivers", "sort by running costs", "sort by cost/1K excl.r."]
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
			Reset() 'in particular clear the lists
			Local map:TStationMap = GetStationMap(playerID)
			For Local satellite:TStationMap_Satellite = EachIn GetStationMapCollection().satellites
				Local station:TStationBase = map.GetSatelliteUplink(satellite.GetID())
				If station
					satellites.AddLast(station)
				EndIf
			Next
			For Local section:TStationMapSection = EachIn GetStationMapCollection().sections
				Local sectionName:String = section.name
				Local station:TStationBase = map.GetCableNetworkUplink(sectionName)
				If station
					cables.AddLast(station)
				EndIf
				For Local station:TStationAntenna = EachIn map.GetStationsBySectionName(sectionName)
					antennas.AddLast(station)
				Next
			Next
			currentPlayer = playerID
		EndIf
		Select sortMode
			Case 1
				satellites.Sort(False, SortByReach)
				cables.Sort(False, SortByReach)
				antennas.Sort(False, SortByReach)
			Case 2
				satellites.Sort(False, SortByCost)
				cables.Sort(False, SortByCost)
				antennas.Sort(False, SortByCost)
			Case 3
				satellites.Sort(False, SortByCostPerViewer)
				cables.Sort(False, SortByCostPerViewer)
				antennas.Sort(False, SortByCostPerViewer)
		EndSelect

		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next

		Function SortByReach:Int(o1:Object, o2:Object)
			Local s1:TStationBase = TStationBase(o1)
			Local s2:TStationBase = TStationBase(o2)
			Return s1.GetStationExclusiveReceivers() - s2.GetStationExclusiveReceivers()
		End Function

		Function SortByCost:Int(o1:Object, o2:Object)
			Local s1:TStationBase = TStationBase(o1)
			Local s2:TStationBase = TStationBase(o2)
			Return s1.GetRunningCosts() - s2.GetRunningCosts()
		End Function

		Function SortByCostPerViewer:Int(o1:Object, o2:Object)
			Local s1:TStationBase = TStationBase(o1)
			Local s2:TStationBase = TStationBase(o2)
			Return 1000.0 * s1.GetRunningCosts() / s1.GetStationExclusiveReceivers() -  1000.0 * s2.GetRunningCosts() / s2.GetStationExclusiveReceivers()
		End Function
	End Method


	Method Render()
		Local playerID:Int = GetShownPlayerID()

		DrawWindow(position.x + 545, position.y, 120, 150, "Show")
		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		Local boxWidth:Int = 130
		Local boxHeight:Int = 332
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
		Local map:TStationMap = GetStationMap(playerID)

		DrawWindow(x + 0*135, y, w, h, "P #" + playerID, "Recv.: " + MathHelper.DottedValue(map.GetReceivers()))
		For Local i:Int = 1 Until 4
			DrawWindow(x + i*135, y, w, h, "")
		Next
	End Method


	Method RenderBlock_PlayerStationsList(playerID:Int, firstBlockOffset:Int, x:Int, y:Int, w:Int, h:Int)
		Local player:TPlayer = GetPlayer(playerID)
		Local map:TStationMap = GetStationMap(playerID)
		Local font:TBitmapFont = GetBitmapFont("default", 9)

		Local textX:Int = x
		Local textY:Int = y + firstBlockOffset + 3 - 1
		Local textYStart:Int = textY
		Local c:SColor8
		Local detailsStationName:String
		Local detailsStation:TStationBase = Null
		Local xForDetails:Int = x + 540

		font.Draw("Sat Uplinks: " + map.GetStationCount(TVTStationType.SATELLITE_UPLINK), textX, textY)
		If attributeToShow = 0 Then font.DrawBox(MathHelper.DottedValue(GetStationMapCollection().GetSatelliteUplinkReceivers(playerID)), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, SColor8.WHITE)
		textY :+ 12
		For Local station:TStationBase = EachIn satellites
			c = SColor8.WHITE
			Local n:String =station.GetName()
			If THelper.MouseIn(textX, textY, w, 11)
				detailsStation = station
				c = SColor8.RED
				detailsStationName = n
			EndIf
			If n.length > 13 Then n = ".." + n[n.length-12..]
			font.DrawBox( Chr(9654) + " " + n, textX + 5, textY, 90, 16, sALIGN_LEFT_TOP, c)
			font.DrawBox(getValueToShow(station, attributeToShow), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, c)
			textY :+ 10
		Next
		textY :+ 3

		font.Draw("Cable Uplinks: " + map.GetStationCount(TVTStationType.CABLE_NETWORK_UPLINK), textX, textY)
		If attributeToShow = 0 Then font.DrawBox(MathHelper.DottedValue(GetStationMapCollection().GetCableNetworkUplinkReceivers(playerID)), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, SColor8.WHITE)
		textY :+ 12
		For Local station:TStationBase = EachIn cables
			c:SColor8 = SColor8.WHITE
			Local iso:String = station.GetSectionISO3166Code()
			Local n:String = GetLocale("MAP_COUNTRY_"+iso+"_LONG")
			If Not station.IsActive() Then c = SColor8.GRAY
			If THelper.MouseIn(textX, textY, w, 11)
				detailsStation = station
				c = SColor8.RED
				detailsStationName = n
			EndIf
			If n.length > 13 Then n = n[.. 12]+".."
			font.DrawBox( Chr(9654) + " " + n, textX + 5, textY, 90, 16, sALIGN_LEFT_TOP, c)
			font.DrawBox(getValueToShow(station, attributeToShow), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, c)
			textY :+ 10
		Next
		textY :+ 3

		font.Draw("Antennas: " + map.GetStationCount(TVTStationType.ANTENNA), textX, textY)
		If attributeToShow = 0 Then font.DrawBox(MathHelper.DottedValue(GetStationMapCollection().GetAntennaReceivers(playerID)), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, SColor8.WHITE)

		textY :+ 12
		For Local station:TStationBase = EachIn antennas
			c:SColor8 = SColor8.WHITE
			If textY >= y + h - 4
				x = x + 135
				textX:Int = x + 3
				textY:Int = y - 1
			EndIf
			Local iso:String = station.GetSectionISO3166Code()
			Local n:String = GetLocale("MAP_COUNTRY_"+iso+"_SHORT")
			If Not station.IsActive() Then c = SColor8.GRAY
			If THelper.MouseIn(textX, textY, w, 11)
				detailsStation = station
				c = SColor8.RED
				detailsStationName = n +": " + station.GetName()
			EndIf
			If n.length > 13 Then n = n[.. 12]+".."
			font.DrawBox( Chr(9654) + " " + n +": " + station.GetName(), textX + 5, textY, 90, 16, sALIGN_LEFT_TOP, c)
			font.DrawBox(getValueToShow(station, attributeToShow), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, c)
			textY :+ 10
		Next

		If detailsStation
			Local contentRect:SRectI = DrawWindow(position.x + 545, position.y + 200, 120, 100, detailsStationName)

			c = SColor8.WHITE
			w = 120
			textX = contentRect.x
			textY = contentRect.y
			textFont.DrawBox("Receivers", textX, textY, 90, 16, sALIGN_LEFT_TOP, c)
			textFont.DrawBox( MathHelper.DottedValue(detailsStation.GetReceivers()), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, c)
			textY :+ 10
			textFont.DrawBox(" ~q exclusive", textX, textY, 90, 16, sALIGN_LEFT_TOP, c)
			textFont.DrawBox( MathHelper.DottedValue(detailsStation.GetStationExclusiveReceivers()), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, c)
			textY :+ 10
			textFont.DrawBox("Costs", textX, textY, 90, 16, sALIGN_LEFT_TOP, c)
			textFont.DrawBox( MathHelper.DottedValue(detailsStation.GetRunningCosts()), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, c)
			textY :+ 10
			textFont.DrawBox(" ~q /1K Recv.", textX, textY, 90, 16, sALIGN_LEFT_TOP, c)
			textFont.DrawBox( MathHelper.DottedValue(1000.0 * detailsStation.GetRunningCosts() / detailsStation.GetReceivers()), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, c)
			textY :+ 10
			textFont.DrawBox(" ~q /1K ex.Recv.", textX, textY, 90, 16, sALIGN_LEFT_TOP, c)
			textFont.DrawBox( MathHelper.DottedValue(1000.0 * detailsStation.GetRunningCosts() / detailsStation.GetStationExclusiveReceivers()), textX, textY, w - 6, 16, sALIGN_RIGHT_TOP, c)
		EndIf


		Function getValueToShow:String(station:TStationBase, typeToShow:Int)
			Select typeToShow
				Case 0
					Return MathHelper.DottedValue(station.GetStationExclusiveReceivers())
				Case 1
					Return MathHelper.DottedValue(station.GetRunningCosts())
				Case 2
					Return MathHelper.DottedValue(1000.0 * station.GetRunningCosts() / station.GetStationExclusiveReceivers())
			End Select
		EndFunction
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Select sender.dataInt
			Case 0
				GetInstance().attributeToShow = 0
			Case 1
				GetInstance().attributeToShow = 1
			Case 2
				GetInstance().attributeToShow = 2
			Case 3
				GetInstance().sortMode = 0
				GetInstance().Reset()
			Case 4
				GetInstance().sortMode = 1
				GetInstance().Reset()
			Case 5
				GetInstance().sortMode = 2
				GetInstance().Reset()
			Case 6
				GetInstance().sortMode = 3
				GetInstance().Reset()
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function
End Type
