Type TDebugQuoteInfos
	Function Draw()
		SetColor 0,0,0
		DrawRect(20,10,760,373)
		SetColor 255, 255, 255

		'Assets.fonts.baseFont.Draw("Bevölkerung", 25, startY)

		Local audienceResult:TAudienceResult = Game.GetPlayer().audience

		Local x:Int = 200
		Local y:Int = 25
		Local font:TGW_BitmapFont = Assets.fonts.baseFontSmall

		font.drawBlock("Gesamt", x, y, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.clRed)
		font.drawBlock("Kinder", x + (70*1), y, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.clWhite)
		font.drawBlock("Jugendliche", x + (70*2), y, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.clWhite)
		font.drawBlock("Hausfrau.", x + (70*3), y, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.clWhite)
		font.drawBlock("Arbeitneh.", x + (70*4), y, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.clWhite)
		font.drawBlock("Arbeitslose", x + (70*5), y, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.clWhite)
		font.drawBlock("Manager", x + (70*6), y, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.clWhite)
		font.drawBlock("Rentner", x + (70*7), y, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.clWhite)


		font.Draw("Bevölkerung", 25, 50, TColor.clWhite);
		DrawAudience(audienceResult.WholeMarket, 200, 50);

		Local percent:String = TFunctions.shortenFloat(audienceResult.PotentialMaxAudienceQuote.Average*100,2) + "%"
		font.Draw("Potentielle Zuschauer", 25, 75, TColor.clWhite);
		font.Draw(percent, 160, 75, TColor.clWhite);
		DrawAudience(audienceResult.PotentialMaxAudience, 200, 75);

		local colorLight:TColor = TColor.CreateGrey(150)

		font.drawStyled("      davon Exklusive", 25, 90, TColor.clWhite);
		DrawAudience(audienceResult.ExclusiveAudienceSum, 200, 90, true);

		font.drawStyled("      davon gebunden (Audience Flow)", 25, 105, colorLight);
		DrawAudience(audienceResult.AudienceFlowSum, 200, 105, true);

		font.drawStyled("      davon Zapper", 25, 120, colorLight);
		DrawAudience(audienceResult.ChannelSurferToShare, 200, 120, true);


		font.Draw("Aktuelle Zuschauerzahl", 25, 140, TColor.clWhite);
		percent = TFunctions.shortenFloat(audienceResult.AudienceQuote.Average*100,2) + "%"
		font.Draw(percent, 160, 140, TColor.clWhite);
		DrawAudience(audienceResult.Audience, 200, 140);

		font.drawStyled("      davon Exklusive", 25, 155, colorLight);
		DrawAudience(audienceResult.ExclusiveAudience, 200, 155, true);

		font.drawStyled("      davon gebunden (Audience Flow)", 25, 170, colorLight);
		DrawAudience(audienceResult.AudienceFlow, 200, 170, true);

		font.drawStyled("      davon Zapper", 25, 185, colorLight);
		DrawAudience(audienceResult.ChannelSurfer, 200, 185, true);







		Local attraction:TAudienceAttraction = audienceResult.AudienceAttraction
		Local genre:String = "kein Genre"
		If (attraction.AudienceAttraction <> Null) Then
			genre = GetLocale("MOVIE_GENRE_"+attraction.Genre)
		Endif

		Local offset:Int = 40

		Assets.fonts.baseFontBold.drawStyled("Sendung: " + audienceResult.Title + "     (" + genre + ")", 25, offset + 170, TColor.clRed);


		font.Draw("Basis-Programmattraktivität", 25, offset+190, TColor.clWhite)
		percent = TFunctions.shortenFloat(attraction.RawQuality * 100,2) + "%"
		font.drawBlock(percent, 200, offset+190, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.clRed)

		font.Draw("Genre-Popularität", 25, offset+215, TColor.clWhite)
		Local genrePopularityMod:string = TFunctions.shortenFloat(attraction.GenrePopularityMod  * 100,2) + "%"
		Local genrePopularityQuality:string = TFunctions.shortenFloat(attraction.GenrePopularityQuality * 100,2) + "%"
		font.Draw(genrePopularityMod, 160, offset+215, TColor.clWhite)
		font.drawBlock(genrePopularityQuality, 200, offset+215, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.clRed)

		font.Draw("Genre <> Sendezeit", 25, offset+240, TColor.clWhite)
		Local genreTimeMod:string = TFunctions.shortenFloat(attraction.GenreTimeMod  * 100,2) + "%"
		Local genreTimeQuality:string = TFunctions.shortenFloat(attraction.GenreTimeQuality * 100,2) + "%"
		font.Draw(genreTimeMod, 160, offset+240, TColor.clWhite)
		font.drawBlock(genreTimeQuality, 200, offset+240, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.clRed)

		'Nur vorübergehend
		font.Draw("Trailer-Mod", 25, offset+250, TColor.clWhite)
		Local trailerMod:String = TFunctions.shortenFloat(attraction.TrailerMod  * 100,2) + "%"
		Local trailerQuality:String = TFunctions.shortenFloat(attraction.TrailerQuality * 100,2) + "%"
		font.Draw(trailerMod, 160, offset+250, TColor.clWhite)
		font.drawBlock(trailerQuality, 200, offset+250, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.clRed)

		font.Draw("Genre <> Zielgruppe", 25, offset+260, TColor.clWhite)
		DrawAudiencePercent(attraction, 200, offset+260)
		If attraction.AudienceAttraction Then
			font.drawBlock(genre, 60, offset+275, 205, 25, TPoint.Create(ALIGN_RIGHT), colorLight )
			DrawAudiencePercent(attraction.AudienceAttraction, 200, offset+275, true, true);
		Endif

		font.Draw("Image", 25, offset+295, TColor.clWhite);
		font.Draw("100%", 160, offset+295, TColor.clWhite);
		DrawAudiencePercent(attraction, 200, offset+295);

		font.Draw("Effektive Attraktivität", 25, offset+325, TColor.clWhite);
		DrawAudiencePercent(attraction, 200, offset+325)

	End Function


	Function DrawAudience(audience:TAudience, x:Int, y:Int, gray:Int = false)
		Local val:String
		Local x2:Int = x + 70
		Local font:TGW_BitmapFont = Assets.fonts.baseFontSmall
		local color:TColor = TColor.clWhite
		If gray Then color = TColor.CreateGrey(150)

		val = TFunctions.convertValue(audience.GetSum(), 2)
		If gray Then
			font.drawBlock(val, x, y, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.Create(150, 80, 80))
		Else
			font.drawBlock(val, x, y, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.clRed)
		End If

		for local i:int = 1 to 7
			val = TFunctions.convertValue(audience.getByTargetID(i), 2)
			font.drawBlock(val, x2 + 70*(i-1), y, 65, 25, TPoint.Create(ALIGN_RIGHT), color)
		next
	End Function


	Function DrawAudiencePercent(audience:TAudience, x:Int, y:Int, gray:Int = false, hideAverage:Int = false)
		Local val:String
		Local x2:Int = x + 70
		Local font:TGW_BitmapFont = Assets.fonts.baseFontSmall
		local color:TColor = TColor.clWhite
		If gray Then color = TColor.CreateGrey(150)

		If Not hideAverage Then
			val = TFunctions.shortenFloat(audience.Average * 100,2) + "%"
			If gray Then
				font.drawBlock(val, x, y, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.Create(150, 80, 80))
			Else
				font.drawBlock(val, x, y, 65, 25, TPoint.Create(ALIGN_RIGHT), TColor.clRed)
			End If
		End if

		for local i:int = 1 to 7
			val = TFunctions.shortenFloat(audience.GetByTargetID(i) * 100,2) + "%"
			font.drawBlock(val, x2 + 70*(i-1), y, 65, 25, TPoint.Create(ALIGN_RIGHT), color)
		Next
	End Function
End Type