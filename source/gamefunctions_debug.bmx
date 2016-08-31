
Global debugAudienceInfos:TDebugAudienceInfos = New TDebugAudienceInfos
Global debugProgrammePlanInfos :TDebugProgrammePlanInfos = new TDebugProgrammePlanInfos


Type TDebugAudienceInfos
	Field currentStatement:TBroadcastFeedbackStatement
	Field lastCheckedMinute:Int

	Method Draw()
		SetColor 0,0,0
		DrawRect(0,0,800,385)
		SetColor 255, 255, 255

		'GetBitmapFontManager().baseFont.Draw("Bevölkerung", 25, startY)

		local playerID:int = TIngameInterface.GetInstance().ShowChannel
		if playerID <= 0 then playerID = GetPlayerBaseCollection().playerID

		Local audienceResult:TAudienceResult = GetBroadcastManager().GetAudienceResult( playerID )

		Local x:Int = 200
		Local y:Int = 25
		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall
		GetBitmapFontManager().baseFont.drawBlock("|b|Taste |color=255,100,0|~qQ~q|/color| drücken|/b| um (Debug-)Quotenbildschirm wieder auszublenden. Spielerwechsel: Strg+(1-4)", 0, 360, GetGraphicsManager().GetWidth(), 25, ALIGN_CENTER_CENTER, TColor.clRed)

		font.drawBlock("Gesamt", x, y, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)
		font.drawBlock("Kinder", x + (70*1), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Jugendliche", x + (70*2), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Hausfrau.", x + (70*3), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Arbeitneh.", x + (70*4), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Arbeitslose", x + (70*5), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Manager", x + (70*6), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)
		font.drawBlock("Rentner", x + (70*7), y, 65, 25, ALIGN_RIGHT_TOP, TColor.clWhite)


		font.Draw("Bevölkerung", 25, 50, TColor.clWhite)
		DrawAudience(audienceResult.WholeMarket, 200, 50)

		Local percent:String = MathHelper.NumberToString(audienceResult.GetPotentialMaxAudienceQuotePercentage()*100,2) + "%"
		font.Draw("Potentielle Zuschauer", 25, 70, TColor.clWhite)
		font.Draw(percent, 160, 70, TColor.clWhite)
		DrawAudience(audienceResult.PotentialMaxAudience, 200, 70)

		local colorLight:TColor = TColor.CreateGrey(150)

		'font.drawStyled("      davon Exklusive", 25, 90, TColor.clWhite);
		'DrawAudience(audienceResult.ExclusiveAudienceSum, 200, 90, true);

		'font.drawStyled("      davon gebunden (Audience Flow)", 25, 105, colorLight);
		'DrawAudience(audienceResult.AudienceFlowSum, 200, 105, true);

		'font.drawStyled("      davon Zapper", 25, 120, colorLight);
		'DrawAudience(audienceResult.ChannelSurferToShare, 200, 120, true);


		font.Draw("Aktuelle Zuschauerzahl", 25, 90, TColor.clWhite);
		percent = MathHelper.NumberToString(audienceResult.GetAudienceQuotePercentage()*100,2) + "%"
		font.Draw(percent, 160, 90, TColor.clWhite);
		DrawAudience(audienceResult.Audience, 200, 90);

		'font.drawStyled("      davon Exklusive", 25, 155, colorLight);
		'DrawAudience(audienceResult.ExclusiveAudience, 200, 155, true);

		'font.drawStyled("      davon gebunden (Audience Flow)", 25, 170, colorLight);
		'DrawAudience(audienceResult.AudienceFlow, 200, 170, true);

		'font.drawStyled("      davon Zapper", 25, 185, colorLight);
		'DrawAudience(audienceResult.ChannelSurfer, 200, 185, true);







		Local attraction:TAudienceAttraction = audienceResult.AudienceAttraction
		Local genre:String = "kein Genre"
		Select attraction.BroadcastType
			case TVTBroadcastMaterialType.PROGRAMME
				If (attraction.BaseAttraction <> Null and attraction.genreDefinition)
					genre = GetLocale("PROGRAMME_GENRE_"+TVTProgrammeGenre.GetAsString(attraction.genreDefinition.referenceID))
				Endif
			case TVTBroadcastMaterialType.ADVERTISEMENT
				If (attraction.BaseAttraction <> Null)
					genre = GetLocale("INFOMERCIAL")
				Endif
			case TVTBroadcastMaterialType.NEWSSHOW
				If (attraction.BaseAttraction <> Null)
					genre = "News-Genre-Mix"
				Endif
		End Select

		Local offset:Int = 110

		GetBitmapFontManager().baseFontBold.drawStyled("Sendung: " + audienceResult.GetTitle() + "     (" + genre + ") [Spieler: "+playerID+"]", 25, offset, TColor.clRed);
		offset :+ 20

		font.Draw("1. Programmqualität & Aktual.", 25, offset, TColor.clWhite)
		If attraction.Quality
			DrawAudiencePercent(new TAudience.InitValue(attraction.Quality,  attraction.Quality), 200, offset, true, true)
		Endif
		offset :+ 20

		font.Draw("2. * Zielgruppenattraktivität", 25, offset, TColor.clWhite)
		if attraction.GetTargetGroupAttractivity()
			DrawAudiencePercent(attraction.GetTargetGroupAttractivity(), 200, offset, true, true)
		endif
		offset :+ 20

		font.Draw("3. * TrailerMod ("+MathHelper.NumberToString(TAudienceAttraction.MODINFLUENCE_TRAILER*100)+"%)", 25, offset, TColor.clWhite)
		If attraction.TrailerMod
			font.drawBlock(genre, 60, offset, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.TrailerMod.Copy().MultiplyFloat(TAudienceAttraction.MODINFLUENCE_TRAILER).AddFloat(1), 200, offset, true, true)
		Endif
		offset :+ 20

		font.Draw("4. + Sonstige Mods ("+MathHelper.NumberToString(TAudienceAttraction.MODINFLUENCE_MISC*100)+"%)", 25, offset, TColor.clWhite)
		If attraction.MiscMod
			DrawAudiencePercent(attraction.MiscMod, 200, offset, true, true)
		Endif
		offset :+ 20

		font.Draw("5. + CastMod ("+MathHelper.NumberToString(TAudienceAttraction.MODINFLUENCE_CAST*100)+"%)", 25, offset, TColor.clWhite)
		DrawAudiencePercent(new TAudience.InitValue(attraction.CastMod,  attraction.CastMod), 200, offset, true, true)
		offset :+ 20

		font.Draw("6. * SenderimageMod", 25, offset, TColor.clWhite)
		If attraction.PublicImageMod
			DrawAudiencePercent(attraction.PublicImageMod.Copy().AddFloat(1.0), 200, offset, true, true)
		Endif
		offset :+ 20

		font.Draw("7. + Zuschauerentwicklung (inaktiv)", 25, offset, TColor.clWhite)
	'	DrawAudiencePercent(new TAudience.InitValue(-1, attraction.QualityOverTimeEffectMod), 200, offset, true, true)
		offset :+ 20

		font.Draw("9. + Glück / Zufall", 25, offset, TColor.clWhite)
		If attraction.LuckMod
			DrawAudiencePercent(attraction.LuckMod, 200, offset, true, true)
		endif
		offset :+ 20

		font.Draw("9. + Audience Flow Bonus", 25, offset, TColor.clWhite)
		if attraction.AudienceFlowBonus
			DrawAudiencePercent(attraction.AudienceFlowBonus, 200, offset, true, true)
		endif
		offset :+ 20

		font.Draw("10. * Genreattraktivität (zeitabh.)", 25, offset, TColor.clWhite)
		if attraction.GetGenreAttractivity()
			DrawAudiencePercent(attraction.GetGenreAttractivity(), 200, offset, true, true)
		endif
		offset :+ 20
	
		font.Draw("11. + Sequence", 25, offset, TColor.clWhite)
		If attraction.SequenceEffect
			DrawAudiencePercent(attraction.SequenceEffect, 200, offset, true, true)
		endif
		offset :+ 20

		font.Draw("Finale Attraktivität (Effektiv)", 25, offset, TColor.clRed)
		If attraction.FinalAttraction
			DrawAudiencePercent(attraction.FinalAttraction, 200, offset, false, true)
		endif
rem
		font.Draw("Basis-Attraktivität", 25, offset+230, TColor.clRed)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.BaseAttraction Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.BaseAttraction, 200, offset+230, false, true);
		Endif
		endrem
		rem
		endrem

		rem
		font.Draw("10. Nachrichteneinfluss", 25, offset+330, TColor.clWhite)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.NewsShowBonus Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.NewsShowBonus, 200, offset+330, true, true);
		Endif
		endrem

		rem
		font.Draw("Block-Attraktivität", 25, offset+290, TColor.clRed)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.BlockAttraction Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.BlockAttraction, 200, offset+290, false, true);
		Endif
		endrem



		rem
		font.Draw("Ausstrahlungs-Attraktivität", 25, offset+270, TColor.clRed)
		'DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.BroadcastAttraction Then
			'font.drawBlock(genre, 60, offset+150, 205, 25, ALIGN_RIGHT_TOP, colorLight )
			DrawAudiencePercent(attraction.BroadcastAttraction, 200, offset+270, false, true);
		Endif
		endrem

		Local currBroadcast2:TBroadcast = GetBroadcastManager().GetCurrentBroadcast()
		Local feedback:TBroadcastFeedback = currBroadcast2.GetFeedback(playerID)

		Local minute:Int = GetWorldTime().GetDayMinute()

		If ((minute Mod 5) = 0)
			If Not (self.lastCheckedMinute = minute)
				self.lastCheckedMinute = minute
				currentStatement = null
				'DebugStop
			End If
		Endif

		If Not currentStatement Then
			currentStatement:TBroadcastFeedbackStatement = feedback.GetNextAudienceStatement()
		Endif

		SetColor 0,0,0
		DrawRect(520,415,250,40)
		font.Draw("Statements: " + feedback.AudienceInterest.ToStringMinimal(), 530, 420, TColor.clRed);
		font.Draw("Statements: " + feedback.FeedbackStatements.Count(), 530, 430, TColor.clRed);
		If currentStatement Then
			font.Draw(currentStatement.ToString(), 530, 440, TColor.clRed);
		Endif

		SetColor 255,255,255


rem
		font.Draw("Genre <> Sendezeit", 25, offset+240, TColor.clWhite)
		Local genreTimeMod:string = MathHelper.NumberToString(attraction.GenreTimeMod  * 100,2) + "%"
		Local genreTimeQuality:string = MathHelper.NumberToString(attraction.GenreTimeQuality * 100,2) + "%"
		font.Draw(genreTimeMod, 160, offset+240, TColor.clWhite)
		font.drawBlock(genreTimeQuality, 200, offset+240, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)

		'Nur vorübergehend
		font.Draw("Trailer-Mod", 25, offset+250, TColor.clWhite)
		Local trailerMod:String = MathHelper.NumberToString(attraction.TrailerMod  * 100,2) + "%"
		Local trailerQuality:String = MathHelper.NumberToString(attraction.TrailerQuality * 100,2) + "%"
		font.Draw(trailerMod, 160, offset+250, TColor.clWhite)
		font.drawBlock(trailerQuality, 200, offset+250, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)



		font.Draw("Image", 25, offset+295, TColor.clWhite);
		font.Draw("100%", 160, offset+295, TColor.clWhite);
		DrawAudiencePercent(attraction, 200, offset+295);

		font.Draw("Effektive Attraktivität", 25, offset+325, TColor.clWhite);
		DrawAudiencePercent(attraction, 200, offset+325)
endrem
	End Method


	Function DrawAudience(audience:TAudience, x:Int, y:Int, gray:Int = false)
		Local val:String
		Local x2:Int = x + 70
		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall
		local color:TColor = TColor.clWhite
		If gray Then color = TColor.CreateGrey(150)

		val = TFunctions.convertValue(audience.GetTotalSum(), 2)
		If gray Then
			font.drawBlock(val, x, y, 65, 25, ALIGN_RIGHT_TOP, TColor.Create(150, 80, 80))
		Else
			font.drawBlock(val, x, y, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)
		End If

		for local i:int = 1 to TVTTargetGroup.baseGroupCount
			val = TFunctions.convertValue(audience.GetTotalValue(TVTTargetGroup.GetAtIndex(i)), 2)
			font.drawBlock(val, x2 + 70*(i-1), y, 65, 25, ALIGN_RIGHT_TOP, color)
		next
	End Function


	Function DrawAudiencePercent(audience:TAudience, x:Int, y:Int, gray:Int = false, hideAverage:Int = false)
		Local val:String
		Local x2:Int = x + 70
		Local font:TBitmapFont = GetBitmapFontManager().baseFontSmall
		local color:TColor = TColor.clWhite
		If gray Then color = TColor.CreateGrey(150)

		If Not hideAverage Then
			val = MathHelper.NumberToString(audience.GetWeightedAverage(),2)
			If gray Then
				font.drawBlock(val, x, y, 65, 25, ALIGN_RIGHT_TOP, TColor.Create(150, 80, 80))
			Else
				font.drawBlock(val, x, y, 65, 25, ALIGN_RIGHT_TOP, TColor.clRed)
			End If
		End if

		for local i:int = 1 to TVTTargetGroup.baseGroupCount
			val = MathHelper.NumberToString(0.5 * audience.GetTotalValue(TVTTargetGroup.GetAtIndex(i)),2)
			font.drawBlock(val, x2 + 70*(i-1), y, 65, 25, ALIGN_RIGHT_TOP, color)
		Next
	End Function
End Type



Type TDebugProgrammePlanInfos
	Global programmeBroadcasts:TMap = CreateMap()
	Global adBroadcasts:TMap = CreateMap()
	Global oldestEntryTime:Long
	Global _eventListeners:TLink[]

	
	Method New()
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]
		
		_eventListeners :+ [ EventManager.registerListenerFunction("programmeplan.addObject", onChangeProgrammePlan) ]
'		_eventListeners :+ [ EventManager.registerListenerFunction("programmeplan.removeObject", onChangeProgrammePlan) ]

	End Method


	Function onChangeProgrammePlan:Int(triggerEvent:TEventBase)
		local broadcast:TBroadcastMaterial = TBroadcastMaterial(triggerEvent.GetData().Get("object"))
		local slotType:int = triggerEvent.GetData().GetInt("slotType", -1)
		if not broadcast or slotType <= 0 then return False

		if slotType = TVTBroadcastMaterialType.ADVERTISEMENT
			adBroadcasts.Insert(broadcast.GetGUID(), string(Time.GetTimeGone()) )
		else
			programmeBroadcasts.Insert(broadcast.GetGUID(), string(Time.GetTimeGone()) )
		endif

		RemoveOutdated()
	End Function


	Function RemoveOutdated()
		local maps:TMap[] = [programmeBroadcasts, adBroadcasts]

		oldestEntryTime = -1

		'remove outdated ones (older than 30 seconds))
		For local map:TMap = EachIn maps
			For local guid:String = EachIn map.Copy().Keys()
				local broadcastTime:Long = Long( string(map.ValueForKey(guid)) )
				if broadcastTime + 10000 < Time.GetTimeGone()
					map.Remove(guid)
				else
					if oldestEntryTime = -1 then oldestEntryTime = broadcastTime
					oldestEntryTime = Min(oldestEntryTime, broadcastTime)
				endif
			Next
		Next
	End Function
	


	Function GetAddedTime:Long(guid:string, slotType:int=0)
		if slotType = TVTBroadcastMaterialType.PROGRAMME
			return int( string(programmeBroadcasts.ValueForKey(guid)) )
		else
			return int( string(adBroadcasts.ValueForKey(guid)) )
		endif
	End Function

	
	Function Draw(playerID:int, x:int, y:int)
		if playerID <= 0 then playerID = GetPlayerBase().playerID
		local currDay:int = GetWorldTime().GetDay()
		Local daysProgramme:TBroadcastMaterial[] = GetPlayerProgrammePlan( playerID ).GetProgrammeSlotsInTimeSpan(currDay, 0, currDay, 23)
		Local daysAdvertisements:TBroadcastMaterial[] = GetPlayerProgrammePlan( playerID ).GetAdvertisementSlotsInTimeSpan(currDay, 0, currDay, 23)
		Local lineHeight:int = 15

		'clean up if needed
		if oldestEntryTime >= 0 and oldestEntryTime + 10000 < Time.GetTimeGone() then RemoveOutdated()

		For local hour:int = 0 until daysProgramme.length
			Local adString:String = ""
			Local progString:String = ""

			'use "0" as day param because currentHour includes days already
			Local advertisement:TBroadcastMaterial = daysAdvertisements[hour]
			If advertisement
				local spotNumber:string
				local ad:TAdvertisement = TAdvertisement(advertisement)
				if ad
					if ad.IsState(TAdvertisement.STATE_FAILED)
						spotNumber = "-/" + ad.contract.GetSpotCount()
					else
						spotNumber = GetPlayerProgrammePlan(advertisement.owner).GetAdvertisementSpotNumber(ad) + "/" + ad.contract.GetSpotCount()
					endif
				else
					spotNumber = (hour - advertisement.programmedHour + 1) + "/" + advertisement.GetBlocks(TVTBroadcastMaterialType.ADVERTISEMENT)
				endif
				adString = advertisement.GetTitle() + " [" + spotNumber + "]"

				if TProgramme(advertisement) then adString = "T: "+adString
			EndIf

			Local programme:TBroadcastMaterial = daysProgramme[hour]
			If programme
				progString = programme.GetTitle() + " ["+ (hour - programme.programmedHour + 1) + "/" + programme.GetBlocks(TVTBroadcastMaterialType.PROGRAMME) +"]"
				
				if TAdvertisement(programme) then progString = "I: "+progString
			EndIf

			If progString = "" and GetWorldTime().GetDayHour() > hour Then progString = "PROGRAMME OUTAGE"
			If adString = "" and GetWorldTime().GetDayHour() > hour Then adString = "AD OUTAGE"

			local oldAlpha:Float = GetAlpha()
			if hour mod 2 = 0
				SetColor 0,0,0
			else
				SetColor 60,60,60
			endif
			SetAlpha 0.75 * GetAlpha()
			DrawRect(x, y + hour * lineHeight, 20, lineHeight-1)
			DrawRect(x+25, y + hour * lineHeight, 190, lineHeight-1)
			DrawRect(x+220, y + hour * lineHeight, 150, lineHeight-1)


			local progTime:Long = 0, adTime:Long = 0
			if advertisement then adTime = GetAddedTime(advertisement.GetGUID(), TVTBroadcastMaterialType.ADVERTISEMENT)
			if programme then progTime = GetAddedTime(programme.GetGUID(), TVTBroadcastMaterialType.PROGRAMME)

			SetColor 255,235,20
			if progTime <> 0
				local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - progTime) / 5000.0))
				SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
				SetBlend LIGHTBLEND
				DrawRect(x+25, y + hour * lineHeight, 190, lineHeight-1)
				SetBlend ALPHABLEND
			endif
			if adTime <> 0
				local alphaValue:Float = 1.0 - Min(1.0, ((Time.GetTimeGone() - adTime) / 5000.0))
				SetAlpha Float(0.4 * Min(1.0, 2 * alphaValue^3))
				SetBlend LIGHTBLEND
				DrawRect(x+220, y + hour * lineHeight, 150, lineHeight-1)
				SetBlend ALPHABLEND
			endif
			
			SetColor 255,255,255
			SetAlpha oldAlpha

			GetBitmapFont("default", 11).Draw( Rset(hour,2).Replace(" ", "0"), x+5, y+1 + hour*lineHeight)
			if programme then SetStateColor(programme)
			GetBitmapFont("default", 11).DrawBlock( progString, x+30, y+1 + hour*lineHeight, 185, lineHeight)
			if advertisement then SetStateColor(advertisement)
			GetBitmapFont("default", 11).DrawBlock( adString, x+225, y+1 + hour*lineHeight, 145, lineHeight)
			SetColor 255,255,255
		Next
	End Function

	Function SetStateColor(material:TBroadcastMaterial)
		if not material
			SetColor 255,255,255
			return
		endif
			
		Select material.state
			Case TBroadcastMaterial.STATE_RUNNING
				SetColor 255,230,120
			Case TBroadcastMaterial.STATE_OK
				SetColor 200,255,200
			Case TBroadcastMaterial.STATE_FAILED
				SetColor 250,150,120
			default
				SetColor 255,255,255
		End select
	End Function
End Type
