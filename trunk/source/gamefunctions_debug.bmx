Type TDebugQuoteInfos
	Function Draw()
		SetColor 0,0,0
		DrawRect(20,10,760,373)
		SetColor 255, 255, 255			

		'Assets.fonts.baseFont.Draw("Bevölkerung", 25, startY)
		
		Local audienceResult:TAudienceResult = TPlayer.Current().audience
		
		Local x:Int = 200
		Local y:Int = 25
		Local font:TBitmapFont = Assets.fonts.baseFontSmall

		font.drawBlock("Gesamt", x, y, 65, 25, 2, 255, 0, 0)		
		font.drawBlock("Kinder", x + (70*1), y, 65, 25, 2, 255, 255, 255)
		font.drawBlock("Jugenliche", x + (70*2), y, 65, 25, 2, 255, 255, 255)	
		font.drawBlock("Hausfrau.", x + (70*3), y, 65, 25, 2, 255, 255, 255)	
		font.drawBlock("Arbeitneh.", x + (70*4), y, 65, 25, 2, 255, 255, 255)	
		font.drawBlock("Arbeitslose", x + (70*5), y, 65, 25, 2, 255, 255, 255)	
		font.drawBlock("Manager", x + (70*6), y, 65, 25, 2, 255, 255, 255)	
		font.drawBlock("Rentner", x + (70*7), y, 65, 25, 2, 255, 255, 255)				
		
		
		Local wholeMarket:TAudience = audienceResult.WholeMarket
		font.Draw("Bevölkerung", 25, 50);
		DrawAudience(wholeMarket, 200, 50);	

		Local maxAudienceThisHour:TAudience = audienceResult.PotentialMaxAudience
		Local percent:String = functions.convertPercent(audienceResult.PotentialMaxAudienceQuote.Average*100,2) + "%"		
		font.Draw("Potentielle Zuschauer", 25, 75);
		font.Draw(percent, 160, 75);
		DrawAudience(maxAudienceThisHour, 200, 75);

		Local fixAudienceSum:TAudience = audienceResult.ExclusiveAudienceSum
		font.drawStyled("      davon Exklusive", 25, 90, 75, 75, 75);
		DrawAudience(fixAudienceSum, 200, 90, true);		
		
		Local audienceFlowSum:TAudience = audienceResult.AudienceFlowSum
		font.drawStyled("      davon gebunden (Audience Flow)", 25, 105, 75, 75, 75);	
		DrawAudience(audienceFlowSum, 200, 105, true);
		
		Local audienceToShare:TAudience = audienceResult.ChannelSurferToShare		
		font.drawStyled("      davon Zapper", 25, 120, 75, 75, 75);		
		DrawAudience(audienceToShare, 200, 120, true);			
		
		
		Local audience:TAudience = audienceResult.Audience 		
		font.Draw("Aktuelle Zuschauerzahl", 25, 140);		
		percent = functions.convertPercent(audienceResult.AudienceQuote.Average*100,2) + "%"		
		font.Draw(percent, 160, 140);
		DrawAudience(audience, 200, 140);
		
		Local fixAudience:TAudience = audienceResult.ExclusiveAudience
		font.drawStyled("      davon Exklusive", 25, 155, 75, 75, 75);
		DrawAudience(fixAudience, 200, 155, true);		
		
		Local audienceFlow:TAudience = audienceResult.AudienceFlow
		font.drawStyled("      davon gebunden (Audience Flow)", 25, 170, 75, 75, 75);	
		DrawAudience(audienceFlow, 200, 170, true);
		
		Local zapper:TAudience = audienceResult.ChannelSurfer		
		font.drawStyled("      davon Zapper", 25, 185, 75, 75, 75);		
		DrawAudience(zapper, 200, 185, true);			
		
		
		
		
		
		
		
		Local attraction:TAudienceAttraction = audienceResult.AudienceAttraction
		Local genre:String = "kein Genre"
		If (attraction.AudienceAttraction <> Null) Then
			genre = GetLocale("MOVIE_GENRE_"+attraction.Genre)
		Endif				
		
		Local offset:Int = 40
		
		Assets.fonts.baseFontBold.drawStyled("Sendung: " + audienceResult.Title + "     (" + genre + ")", 25, offset + 170, 255, 0, 0);
		
		
			
		font.Draw("Basis-Programmattraktivität", 25, offset+190);
		percent = functions.convertPercent(attraction.RawQuality * 100,2) + "%"
		font.drawBlock(percent, 200, offset+190, 65, 25, 2, 255, 0, 0)
		
		font.Draw("Genre-Popularität", 25, offset+215);			
		Local genrePopularityMod:string = functions.convertPercent(attraction.GenrePopularityMod  * 100,2) + "%"
		Local genrePopularityQuality:string = functions.convertPercent(attraction.GenrePopularityQuality * 100,2) + "%"
		font.Draw(genrePopularityMod, 160, offset+215);
		font.drawBlock(genrePopularityQuality, 200, offset+215, 65, 25, 2, 255, 0, 0)	

		font.Draw("Genre <> Sendezeit", 25, offset+240);			
		Local genreTimeMod:string = functions.convertPercent(attraction.GenreTimeMod  * 100,2) + "%"
		Local genreTimeQuality:string = functions.convertPercent(attraction.GenreTimeQuality * 100,2) + "%"
		font.Draw(genreTimeMod, 160, offset+240);
		font.drawBlock(genreTimeQuality, 200, offset+240, 65, 25, 2, 255, 0, 0)			
				
		font.Draw("Genre <> Zielgruppe", 25, offset+260);
		DrawAudiencePercent(attraction, 200, offset+260);
		If (attraction.AudienceAttraction <> Null) Then
			font.drawBlock(genre, 60, offset+275, 205, 25, 2, 75, 75, 75 )			
			DrawAudiencePercent(attraction.AudienceAttraction, 200, offset+275, true, true);
		Endif		
		
		font.Draw("Image", 25, offset+295);	
		font.Draw("100%", 160, offset+295);
		DrawAudiencePercent(attraction, 200, offset+295);	
		
		font.Draw("Effektive Attraktivität", 25, offset+325);	
		DrawAudiencePercent(attraction, 200, offset+325);	
		
	End Function
	
	Function DrawAudience(audience:TAudience, x:Int, y:Int, gray:Int = false)
		Local val:String
		Local x2:Int = x + 70
		Local font:TBitmapFont = Assets.fonts.baseFontSmall
		Local cr:Int = 255
		Local cg:Int = 255
		Local cb:Int = 255
			
		If gray Then
			cr = 75
			cg = 75
			cb = 75
		End If
		
		val = functions.convertValue(String(Int(audience.GetSum())), 2, 0)
		If gray Then
			font.drawBlock(val, x, y, 65, 25, 2, 150, 80, 80)
		Else	
			font.drawBlock(val, x, y, 65, 25, 2, 255, 0, 0)
		End If
		
		val = functions.convertValue(String(Int(audience.Children)), 2, 0)
		font.drawBlock(val, x2, y, 65, 25, 2, cr, cg, cb)
		
		val = functions.convertValue(String(Int(audience.Teenagers)), 2, 0)
		font.drawBlock(val, x2 + (70*1), y, 65, 25, 2, cr, cg, cb)	
		
		val = functions.convertValue(String(Int(audience.HouseWifes)), 2, 0)
		font.drawBlock(val, x2 + (70*2), y, 65, 25, 2, cr, cg, cb)	
		
		val = functions.convertValue(String(Int(audience.Employees)), 2, 0)
		font.drawBlock(val, x2 + (70*3), y, 65, 25, 2, cr, cg, cb)	
		
		val = functions.convertValue(String(Int(audience.Unemployed)), 2, 0)
		font.drawBlock(val, x2 + (70*4), y, 65, 25, 2, cr, cg, cb)	
		
		val = functions.convertValue(String(Int(audience.Manager)), 2, 0)
		font.drawBlock(val, x2 + (70*5), y, 65, 25, 2, cr, cg, cb)	
		
		val = functions.convertValue(String(Int(audience.Pensioners)), 2, 0)
		font.drawBlock(val, x2 + (70*6), y, 65, 25, 2, cr, cg, cb)	
	End Function
	
	Function DrawAudiencePercent(audience:TAudience, x:Int, y:Int, gray:Int = false, hideAverage:Int = false)
		Local val:String
		Local x2:Int = x + 70
		Local font:TBitmapFont = Assets.fonts.baseFontSmall
		Local cr:Int = 255
		Local cg:Int = 255
		Local cb:Int = 255
			
		If gray Then
			cr = 75
			cg = 75
			cb = 75
		End If	
		
		If Not hideAverage Then
			val = functions.convertPercent(audience.Average * 100,2) + "%"	
			If gray Then
				font.drawBlock(val, x, y, 65, 25, 2, 150, 80, 80)
			Else	
				font.drawBlock(val, x, y, 65, 25, 2, 255, 0, 0)
			End If		
		End if
		
		val = functions.convertPercent(audience.Children * 100,2) + "%"
		font.drawBlock(val, x2, y, 65, 25, 2, cr, cg, cb)
		
		val = functions.convertPercent(audience.Teenagers * 100,2) + "%"
		font.drawBlock(val, x2 + (70*1), y, 65, 25, 2, cr, cg, cb)	
		
		val = functions.convertPercent(audience.HouseWifes * 100,2) + "%"
		font.drawBlock(val, x2 + (70*2), y, 65, 25, 2, cr, cg, cb)	
		
		val = functions.convertPercent(audience.Employees * 100,2) + "%"
		font.drawBlock(val, x2 + (70*3), y, 65, 25, 2, cr, cg, cb)	
		
		val = functions.convertPercent(audience.Unemployed * 100,2) + "%"
		font.drawBlock(val, x2 + (70*4), y, 65, 25, 2, cr, cg, cb)	
		
		val = functions.convertPercent(audience.Manager * 100,2) + "%"
		font.drawBlock(val, x2 + (70*5), y, 65, 25, 2, cr, cg, cb)	
		
		val = functions.convertPercent(audience.Pensioners * 100,2) + "%"
		font.drawBlock(val, x2 + (70*6), y, 65, 25, 2, cr, cg, cb)	
	End Function	
End Type