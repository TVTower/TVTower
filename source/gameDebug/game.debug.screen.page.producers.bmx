SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.game.bmx"
Import "../game.programmeproducer.bmx"

Type TDebugScreenPage_Producers extends TDebugScreenPage
	Global _instance:TDebugScreenPage_Producers

	Method New()
		_instance = self
	End Method

	Function GetInstance:TDebugScreenPage_Producers()
		If Not _instance Then new TDebugScreenPage_Producers
		Return _instance
	End Function 

	Method Init:TDebugScreenPage_Producers()
		Return self
	End Method


	Method Reset()
	End Method


	Method Activate()
	End Method


	Method Deactivate()
	End Method


	Method Update()
	End Method


	Method Render()
		RenderProducersList(position.x + 5, 13)
	End Method


	Method RenderProducersList(x:Int, y:Int, w:Int=280, h:Int=363)
		DrawBorderRect(x, y, w, h)
		Local textX:Int = x + 5
		Local textY:Int = y + 5

		Local mouseOverProducer:TProgrammeProducer

		titleFont.DrawSimple("Programme Producers: ", textX, textY)
		textY :+ 12 + 8

		For Local producer:TProgrammeProducerBase = EachIn GetProgrammeProducerCollection()
			textFont.DrawBox(producer.name + "  ("+producer.countryCode+")", textX, textY, w - 10 - 40, 15, sALIGN_LEFT_TOP, SColor8.White)
			textY :+ 10
			textFont.DrawBox("  " + TTypeID.ForObject(producer).name(), textX, textY, 150, 15, sALIGN_LEFT_TOP, new SColor8(220,220,220))
			textFont.DrawBox("XP: " + producer.experience, textX + 150, textY, 35, 15, sALIGN_LEFT_TOP, new SColor8(220,220,220))
			textFont.DrawBox("Budget: " + MathHelper.DottedValue(producer.budget), textX + 100 + 85, textY, 90, 15, sALIGN_LEFT_TOP, new SColor8(220,220,220))
			textY :+ 12
			If TProgrammeProducer(producer)
				textY :- 2
				Local pp:TProgrammeProducer = TProgrammeProducer(producer)
				
				textFont.DrawBox("  Productions    Next: " + GetWorldTime().GetFormattedDate(pp.nextProductionTime, "g/h:i") , textX, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
				textFont.DrawBox("  Active: " + pp.activeProductions.Count() , textX + 130, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
				textFont.DrawBox("  Done: " + pp.producedProgrammeIDs.length, textX + 180, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
				textY :+ 10

				If pp.activeProductions.Count() > 0
					Local listedProduction:Int = 0
					Local maxProductions:Int = Min(2, pp.activeProductions.Count())
					For Local production:TProduction = EachIn pp.activeProductions
						If production And production.productionconcept.script.HasParentScript()
							textFont.DrawBox("  Prod: " + production.productionConcept.GetTitle() + " (Ep.)", textX, textY, w - 70, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
						Else
							textFont.DrawBox("  Prod: " + production.productionConcept.GetTitle(), textX, textY, w - 70, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
						EndIf
						If production.IsInProduction()
							textFont.DrawBox("End: " + GetWorldTime().GetFormattedDate(production.endTime, "g/h:i"), textX + w - 70, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
						Else
							textFont.DrawBox("Start: " + GetWorldTime().GetFormattedDate(production.startTime, "g/h:i"), textX + w - 70, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
						EndIf

						textY :+ 10
						listedProduction :+ 1
						If listedProduction = maxProductions Then Exit
					Next
				EndIf
				If pp.producedProgrammeIDs.length > 0
					Local listedLicences:Int = 0
					Local maxLicences:Int = Min(2, pp.producedProgrammeIDs.length)
					For Local licenceID:Int = EachIn pp.producedProgrammeIDs
						Local l:TProgrammeLicence = GetProgrammeLicenceCollection().Get(licenceID)
						If l And Not l.IsEpisode()
							If l.IsSeries()
								textFont.DrawBox("  Lic: " + l.GetTitle() +" (Series, " + l.GetEpisodeCount() + " Ep.)", textX, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
							Else
								textFont.DrawBox("  Lic: " + l.GetTitle(), textX, textY, w, 15, sALIGN_LEFT_TOP, new SColor8(235,235,235))
							EndIf
							textY :+ 10
							listedLicences :+ 1
						EndIf
						If listedLicences = maxLicences Then Exit
					Next
				EndIf
			EndIf
			textY :+ 4
		Next
	End Method
End Type
