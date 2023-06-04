SuperStrict
Import "game.programmeproducer.base.bmx"

Import "game.programme.programmedata.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.production.bmx"
Import "game.production.script.bmx"
Import "game.production.productionconcept.bmx"
Import "game.gamescriptexpression.bmx"


'register self to producer collection
Rem
Local p:TProgrammeProducer = new TProgrammeProducer
p.countryCode = GetProgrammeProducerCollection().GenerateRandomCountryCode()
p.name = GetProgrammeProducerCollection().GenerateRandomName()
GetProgrammeProducerCollection().RandomizeCharacteristics(p)

GetProgrammeProducerCollection().Add( p )
endrem


'TODO: so umbauen, dass es ein Drehbuchproduzent ist - egal ob Morningshow oder Film
'      daraus dann "spezialisieren"

Rem
https://www.gamezworld.de/phpforum/viewtopic.php?pid=88875#p88875

Kurz fuer mich als "Erinnerung":
- BioPics ueber Kuenstler (evtl gleich mit "Kuenstler-Sim" + "News ueber Touren")
- Dokus ueber Fussballvereine (Saisonende - Aufsteiger bzw "Platz 1 der 1. Liga")
- Doku bei Senderpleite ("Aufstieg und Fall...")
- Doku bei Terroranschlaegen im Hochhaus ("VR - FR Duban")
- Fruehstuecksfernsehen + Mittagsunterhaltung
- Trashtalk fuer Nachmittag
- Sondersendungen zu Nachrichten (wichtig: bei wiederholter Nachricht nicht erneut erzeugen, also newsEventTemplateID protokollieren)
- Boersensendungen
- zufaellige Drehbuchumsetzungen (also auch Filme, Serien ...)

Zur Lokalisierung der Sonderformate muessten diese als Drehbuecher in der DB stehen, aber als "intern" markiert sein (so, dass sie nicht beim Drehbuchhaendler auftauchen).


endrem


'base class for a producer using "studios" and "productions" to generate
'the programme licences
'"sport" programme producers skip studio productions
Type TProgrammeProducer Extends TProgrammeProducerBase
	Field castFavorites:TPersonBase[]
	Field castFavoritesIDs:Int[]
	Field castFavoritesUsageCount:Int[]
	'percentage on how often celebrities are used
	Field preferCelebrityCastRate:Int = 100
	Field preferCelebrityCastRateSupportingRole:Int = 100
	Field nextProductionTime:Long
	Field updateCycle:Int = 0
	Field budgetIncrease:Int = 1000
	Field activeProductions:TObjectList = New TObjectList
	Field producedProgrammeIDs:Int[]

	Method New()
		_producerName:String = "PP_Programmes"
	End Method


	Method RandomizeCharacteristics:Int()
		Super.RandomizeCharacteristics()

		budgetIncrease = RandRange(3, 8) * 250
		nextProductionTime = GetWorldTime().GetTimeGone() + RandRange(12, 96) * TWorldTime.HOURLENGTH
		
		'TODO: greed, favorite genres...
	End Method


	Method Remove:Int() Override
		'remove instance specific event listeners...
	End Method	

	Method Update:Int()
		budget :+ budgetIncrease 'update every 15minutes = 96x a day ...
		
		updateCycle :+ 1

		If activeProductions.count() = 0 And nextProductionTime < GetWorldTime().GetTimeGone()
			ScheduleNextProduction(Null)
			Local minWaitHours:Int = GameRules.devConfig.GetInt("DEV_PRODUCERS_MIN_WAIT_HOURS", 36)
			Local maxWaitHours:Int = GameRules.devConfig.GetInt("DEV_PRODUCERS_MAX_WAIT_HOURS", 96)
			nextProductionTime = GetWorldTime().GetTimeGone() + TWorldTime.HOURLENGTH * RandRange(minWaitHours, maxWaitHours)
		EndIf
		
		'is one of the running/scheduled productions finished now?
		CheckActiveProductions()


		'too many favororites? - clean up every 48*15 minutes = 12 hours
		If updateCycle Mod 48 = 0
			While castFavorites.length > 20
				Local favoriteIndex:Int = RandRange(0, castFavorites.length - 1)
				castFavorites = castFavorites[.. favoriteIndex] + castFavorites[favoriteIndex + 1 ..]
				castFavoritesIDs = castFavoritesIDs[.. favoriteIndex] + castFavoritesIDs[favoriteIndex + 1 ..]
				castFavoritesUsageCount = castFavoritesUsageCount[.. favoriteIndex] + castFavoritesUsageCount[favoriteIndex + 1 ..]
			Wend
		EndIf
	End Method
	
	
	Method CheckActiveProductions()
		Local remove:TProduction[]
		
		For Local p:TProduction = EachIn activeProductions
			'move on to next production stage ?
			'(yes, this does not get called each minute but for the producer
			' 15 minute intervals are still ok)
			p.Update()

			If p.productionConcept.script.IsLive() And p.IsPreProductionDone()
				If HandleFinishedProduction(p) Then remove :+ [p]
			ElseIf p.IsProduced()
				If HandleFinishedProduction(p) Then remove :+ [p]
			EndIf
		Next

		If remove And remove.length > 0
			For Local p:TProduction = EachIn remove
				activeProductions.remove(p)
			Next
		EndIf
	End Method
	
	
	Method HandleFinishedProduction:Int(production:TProduction)
		'production.Finalize() 'skip waiting
		'production.AddProgrammeLicence() 'make licence available

		Local result:TProgrammeLicence
		If production.producedLicenceID
			result = GetProgrammeLicenceCollection().Get(production.producedLicenceID )
		'TODO: DEPRECATED - can be removed after v0.7.1
		ElseIf production.producedLicenceGUID
			result = GetProgrammeLicenceCollection().GetByGUID( production.producedLicenceGUID )
		EndIf
		If Not result
			TLogger.Log("TProgrammeProducer.CreateProgrammeLicence()", "Unable to fetch produced programmelicence (id="+production.producedLicenceID+", guid="+production.producedLicenceGUID+")", LOG_ERROR)
			Throw "TProgrammeProducer.CreateProgrammeLicence() : Unable to fetch produced programmelicence (id="+production.producedLicenceID+", guid="+production.producedLicenceGUID+")"
		EndIf
		
		If Not result.data.extra Then result.data.extra = New TData
		result.data.extra.AddInt("producerID", - GetID()) 'negative!
		If result.IsEpisode()
			If Not result.GetParentLicence().data.extra Then result.GetParentLicence().data.extra = New TData
			result.GetParentLicence().data.extra.AddInt("producerID", - GetID()) 'negative!
		EndIf

		budget :- production.productionConcept.GetTotalCost()
		'TODO: cinema simulation?
		'sell it in game country
		Local nationalSale:Int = result.GetSellPrice(-1)
		'sell it into some other countries
		Local internationalSale:Int
		If result.data.GetQualityRaw() > 0.1 Then internationalSale :+ result.GetSellPrice(-1) / 6
		If result.data.GetQualityRaw() > 0.2 Then internationalSale :+ result.GetSellPrice(-1) / 2
		If result.data.GetQualityRaw() > 0.3 Then internationalSale :+ result.GetSellPrice(-1)
		If result.data.GetQualityRaw() > 0.4 Then internationalSale :+ result.GetSellPrice(-1) * 1
		If result.data.GetQualityRaw() > 0.6 Then internationalSale :+ result.GetSellPrice(-1) * 3
		If result.data.GetQualityRaw() > 0.8 Then internationalSale :+ result.GetSellPrice(-1) * 5

		budget = Min(budget + nationalSale + internationalSale, 2000000000)


		Local oldExperience:Int = experience
		GainExperienceForProgrammeLicence(result)

		'Print "Programme producer ~q"+name+"~q produced ~q" + result.GetTitle() +"~q. Cost="+production.productionConcept.GetTotalCost() +"  Earned="+(nationalSale+internationalSale) + "(nat="+nationalSale+"  int="+internationalSale+"). New budget="+budget + ". Experience=" + oldExperience +" + " + (experience - oldExperience)

		'and add to done productions
		'add series header - on first ep or only on last?
		If result.IsEpisode()
			If Not MathHelper.InIntArray(result.GetParentLicence().GetID(), producedProgrammeIDs)
				producedProgrammeIDs = [result.GetParentLicence().GetID()] + producedProgrammeIDs
			EndIf
		EndIf
		producedProgrammeIDs = [result.GetID()] + producedProgrammeIDs
		
		
		
		'make it available?
		if Not result.IsEpisode()
		'	print "FINISHED SINGLE: " + result.GetParentLicence().GetTitle()
			result.SetOwner(TOwnedGameObject.OWNER_NOBODY)
		elseif result.GetParentLicence().GetSubLicenceCount() = production.productionConcept.script.GetParentScript().GetSubScriptCount()
			'print "FINISHED SERIES: " + result.GetParentLicence().GetTitle() + " ("+result.GetParentLicence().GetSubLicenceCount()+" Ep.)"
			result.SetOwner(TOwnedGameObject.OWNER_NOBODY)
			result.GetParentLicence().SetOwner(TOwnedGameObject.OWNER_NOBODY)
		'elseif result.GetParentLicence().GetSubLicenceCount()
		'	notify "FINISHED EP: " + result.GetParentLicence().GetTitle() + " ("+result.GetParentLicence().GetSubLicenceCount()+"/" + production.productionConcept.script.GetParentScript().GetSubScriptCount()+" Ep.)"
		endif
		
		
		Return True
	End Method


	Method CreateProgrammeLicence:Object(params:TData)
		'we cannot create a "instant" production
		Return Null
	End Method


	'schedule/produce a new element (movie, series, ...)
	Method ScheduleNextProduction(params:TData)
		Local result:TProgrammeLicence 
		
		Local productionConcepts:TProductionConcept[] = CreateProductionConcepts()
		Local productionTime:Long = 0
		Local productionStartTime:Long = GetWorldTime().GetTimeGone() 
		Local productionTimeFactorReduction:Int = 1
		If productionConcepts.length > 1 Then productionTimeFactorReduction = 2

		For Local productionConcept:TProductionConcept = EachIn productionConcepts
			Local production:TProduction = New TProduction
			production.SetProductionConcept(productionConcept)
			production.SetStudio(0)
			'production.PayProduction()
			
			production.ScheduleStart(productionStartTime, productionTimeFactorReduction)
			productionStartTime :+ production.GetProductionTime(productionTimeFactorReduction)
		
			activeProductions.AddLast(production)
		Next
	End Method


	Method GetTemplate:TScriptTemplate()
		Local scriptTemplate:TScriptTemplate
		For Local i:Int = 0 Until 30
			scriptTemplate = GetScriptTemplateCollection().GetRandomByFilter(True, True)
			Local rnd:Int = RandRange(0, 100)
			'print "contemplating "+ scriptTemplate.getTitle() +" with random "+ rnd
			If scriptTemplate.productionLimit <> 1
				'ignore script
			ElseIf scriptTemplate.IsLive() 
				If rnd > 95 Then Return scriptTemplate
			ElseIf scriptTemplate.IsSeries() 
				If rnd > 90 Then Return scriptTemplate
			Else
				'it is not the outcome that will be used for the production, but it is an indicator
				Local outcome:Int = 100 * scriptTemplate.Getoutcome()
				If rnd > outcome Then Return scriptTemplate
			EndIf
		Next
		Return scriptTemplate
	EndMethod


	Method CreateScript:TScript()
		Local script:TScript
		For Local i:Int = 0 Until 10
			Local scriptTemplate:TScriptTemplate = GetTemplate()
			If Not scriptTemplate
				Throw "CreateScript(): Failed to fetch a random script template. All reached their limits?"
			EndIf

			script:TScript = GetScriptCollection().GenerateFromTemplate(scriptTemplate)
			If script.getTitle().contains("#") and i < 10
				'print "Script name contained counter"
				GetScriptCollection().Remove(script)
			Else
				Exit
			Endif
		Next
		'adds the script to the collection and also set NEW owner
		'when NOT setting the owner, the script will be "available" for
		'the script agency to choose it TOO!
		script.SetOwner(- self.GetID() ) 'negative ID!

		'we also pay for it!
		budget :- script.GetPrice()

		Return script
	End Method



	Method ChooseCast(productionConcept:TProductionConcept, script:TScript)
'		local castFavorites:TPersonBase[] = new TPersonBase[castFavoriteIDs.length]
'		for local i:int = 0 until castFavoriteIDs.length
'			castFavorites[i] = GetPersonBaseCollection().GetByID(castFavoritesIDs[i])
'		next

		'TODO follow rules for casting as well; age already part of Filter?
		'use filter parameter object rather than 8 parameters
		'currently global min age
		'choose some cast suiting to the requirements of the script
		Local usedPersonIDs:Int[]
		For Local i:Int = 0 Until script.jobs.length
			Local job:TPersonProductionJob = script.jobs[i]
			Local jobCountry:String
			Local person:TPersonBase

			If script.IsLive() And job.job & TVTPersonJob.VISIBLECAST_MASK > 0 
				jobCountry = GetStationMapCollection().GetMapISO3166Code().ToUpper()
			ElseIf Not job.country
				jobCountry = ""
			ElseIf job.country = "LOCAL"
				jobCountry = GetStationMapCollection().GetMapISO3166Code().ToUpper()
			Else
				jobCountry = job.country
			EndIf
			'find best suiting country code
			If jobCountry Then jobCountry = GetProgrammeProducerCollection().GetBestFitPersonGeneratorCountryCode(jobCountry)

			'try to reuse someone
			If castFavoritesIDs.length > 0
				person = GetPersonBaseCollection().GetRandomFromArray(castFavorites, -1, True, True, job.job, job.gender, True, jobCountry, Null, usedPersonIDs)
				'if person print "would reuse: " + person.GetFullName()
				'slight chance to ignore the given one?
				'and to look for a new one
				If person And (RandRange(0,100) < 10 Or Not passesAgeRestriction(person)) Then person = Null
			EndIf


			'nobody to reuse now - fetch a new one
			If Not person
				Local celebPrefRate:Int = preferCelebrityCastRate
				If job.job = TVTPersonJob.SUPPORTINGACTOR then celebPrefRate=preferCelebrityCastRateSupportingRole
				If RandRange(0, 100) <= celebPrefRate
					person = GetPersonBaseCollection().GetRandomCastableCelebrity(Null, True, True, job.job, job.gender, True, jobCountry, Null, usedPersonIDs)
				Else
					person = GetPersonBaseCollection().GetRandomCastableInsignificant(Null, True, True, job.job, job.gender, True, jobCountry, Null, usedPersonIDs)
				EndIf
				If Not passesAgeRestriction(person) Then person = Null

				'not enough insignificants available?
				If Not person
					Local useRandom:Int = True
					'ignore a requested country and use a local one? (10% chance)
					If jobCountry And RandRange(0, 100) <= 90
						useRandom = False
						jobCountry = GetStationMapCollection().GetMapISO3166Code().ToUpper()
					EndIf

					'also return random if no or no supported country
					'is set - else the person generator falls back to 
					'the fallback country (here "de" for Germany) 
					If useRandom Or Not GetPersonGenerator().HasProvider(jobCountry)
						jobCountry = GetPersonGenerator().GetRandomCountryCode()
					EndIf

					person = GetPersonBaseCollection().CreateRandom(jobCountry, Max(0, job.gender))
				EndIf
			EndIf

			person = OptimizeCast(person, productionConcept, job, jobCountry, usedPersonIDs)

			'store used cast selections so amateurs sooner become celebs
			'with specialization
			Local favoriteIndex:Int = MathHelper.GetIntArrayIndex(person.GetID(), castFavoritesIDs)
			If favoriteIndex = -1
				castFavoritesIDs :+ [person.GetID()]
				castFavorites :+ [person]
				castFavoritesUsageCount :+ [0]
				favoriteIndex = castFavorites.length - 1
			EndIf
			castFavoritesUsageCount[favoriteIndex] :+ 1

'Print "  cast #"+i+"= "  + person.GetFullName() +"   job="+job.job + "  used=" + castFavoritesUsageCount[favoriteIndex]

			'produced often enough with this cast?
			'remove from favorites again
			If castFavoritesUsageCount[favoriteIndex] > 10
				castFavorites = castFavorites[.. favoriteIndex] + castFavorites[favoriteIndex + 1 ..]
				castFavoritesIDs = castFavoritesIDs[.. favoriteIndex] + castFavoritesIDs[favoriteIndex + 1 ..]
				castFavoritesUsageCount = castFavoritesUsageCount[.. favoriteIndex] + castFavoritesUsageCount[favoriteIndex + 1 ..]
			EndIf

			productionConcept.SetCast(i, person)

			If Not MathHelper.InIntArray(person.GetID(), usedPersonIDs)
				usedPersonIDs :+ [person.GetID()]
			EndIf
		Next

		'pc.CalculateCastFit()


		Function passesAgeRestriction:Int(person:TPersonBase)
			If person.GetAge() < 20 Then Return False
			Return True
		End Function

		'try to find a better fit: equally good but less expensive, better but only slightly more expensive
		Function OptimizeCast:TPersonBase(currentChoice:TPersonBase, productionConcept:TProductionConcept, job:TPersonProductionJob, jobCountry:String, usedPersonIDs:Int[])
			'do not replace if insignificant was chosen
			If currentChoice.IsInsignificant() Then return currentChoice
			'print "    trying to optimize " + job.job + " currently " + currentChoice.GetFullName()

			Local result:TPersonBase = currentChoice
			'TODO check if these calls give the same set of persons available in the supermarket
			Local alternatives:TPersonBase[] = GetPersonBaseCollection().GetRandomCelebrities(Null, 20, True, True, job.job, job.gender, True, jobCountry, Null, usedPersonIDs)
			If alternatives.length < 10
				'no job restriction if there are too few alternatives
				alternatives:+ GetPersonBaseCollection().GetRandomCelebrities(Null, 20, True, True, 0, job.gender, True, jobCountry, Null, usedPersonIDs)
			End If
			Local script:TScript = productionConcept.script
			Local genreID:Int = script.mainGenre
			Local genreDefinition:TMovieGenreDefinition = GetMovieGenreDefinition( [genreID] +script.subgenres)

			For Local i:Int = 0 Until alternatives.length
				Local alternative:TPersonBase = alternatives[i]
				If Not alternative Or Not alternative.IsCastable() Or Not alternative.IsBookable() Or Not passesAgeRestriction(alternative) Then Continue
				If IsBetterFit(result, alternative, job.job, genreDefinition) Then result = alternative
			Next

			return result
		End Function

		Function IsBetterFit:Int(current:TPersonBase, alternative:TPersonBase, jobId:Int, genreDefinition:TMovieGenreDefinition)
			Local xpCurrent:Float = current.GetEffectiveJobExperiencePercentage(jobId)
			Local xpAlternative:Float = alternative.GetEffectiveJobExperiencePercentage(jobId)
			'adapted from screen.supermarket
			Local attributes:Int[] = [TVTPersonPersonalityAttribute.FAME, ..
			                          TVTPersonPersonalityAttribute.POWER, ..
			                          TVTPersonPersonalityAttribute.HUMOR, ..
			                          TVTPersonPersonalityAttribute.CHARISMA, ..
			                          TVTPersonPersonalityAttribute.APPEARANCE ..
			                         ]
			Local feeCurrent:Int = current.GetJobBaseFee(jobId, 1, -1)
			Local feeAlternative:Int = alternative.GetJobBaseFee(jobId, 1, -1)
			Local sumCurrent:Float = 2 * xpCurrent
			Local sumAlternative:Float = 2 * xpAlternative
			'TODO genre fit; reduce score if job does not fit? (due to too few alternatives)
			For Local attributeID:Int = EachIn attributes
				Local attributeGenre:Float = genreDefinition.GetCastAttribute(jobID, attributeID)
				If attributeGenre > 0
					sumCurrent:+ 4 * current.GetPersonalityData().GetAttributeValue(attributeID)
					sumAlternative:+ 4 * alternative.GetPersonalityData().GetAttributeValue(attributeID)
				Else
					sumCurrent:+ current.GetPersonalityData().GetAttributeValue(attributeID)
					sumAlternative:+ alternative.GetPersonalityData().GetAttributeValue(attributeID)
				End If
			Next
			Local result:Int=False
			'better and not too expensive
			If sumAlternative > sumCurrent * 1.1 and feeAlternative < feeCurrent * 1.1 Then result = True
			'not much worse but cheaper
			If sumAlternative > sumCurrent * 0.9 and feeAlternative < feeCurrent Then result = True
			If result = True
				'print "  using alternative "+alternative.GetFullName() + " xp "+ xpAlternative + " fee "+ feeAlternative + " atts "+ sumAlternative
			EndIf
			return result
		End Function
	End Method


	Method ChooseProductionCompany(productionConcept:TProductionConcept, script:TScript)
		'choose a suiting one - do we need many focus points?
		'maybe just choose one of the beginners to support them?
		'GetProductionCompanyBaseCollection().GetRandom()
		Local productionCompany:TProductionCompanyBase = GetProductionCompanyBaseCollection().GetAmateurs()
		Local requiredFocusPoints:Int = 5
		
		'to understand the script potential, experience is valuable
		Local estimatedPotential:Int = (100 * script.potential + 0.5)
		'the less experience, the more blurry the potential is
		estimatedPotential = Min(100, Max(0,  estimatedPotential + estimatedPotential * RandRange(-(100 - experience)/2, +(100 - experience)/2) / 100 ))

		If estimatedPotential > 10 Then requiredFocusPoints :+ 1 
		If estimatedPotential > 30 Then requiredFocusPoints :+ 4 
		If estimatedPotential > 50 Then requiredFocusPoints :+ 5 
		If estimatedPotential > 70 Then requiredFocusPoints :+ 7 
		If estimatedPotential > 90 Then requiredFocusPoints :+ 9 
		If script.requiredStudioSize > 1 Then requiredFocusPoints :+ 2 
		If script.requiredStudioSize > 2 Then requiredFocusPoints :+ 5 
		'budget
		If budget > 1000000 Then requiredFocusPoints :+ 2
		If budget > 2500000 Then requiredFocusPoints :+ 5
		If budget > 5000000 Then requiredFocusPoints :+ 8
		If budget >10000000 Then requiredFocusPoints :+ 10
		'limit price of chosen company
		If budget < 250000 Then requiredFocusPoints = Max(requiredFocusPoints, 11)

		If requiredFocusPoints > 5
			'print "looking for non amateur production company with focuspoints >= "+requiredFocusPoints
			Local bestFocusPoints:Int
			Local bestFee:Int
			Local bestCompany:TProductionCompanyBase = Null
			For Local p:TProductionCompanyBase = EachIn GetProductionCompanyBaseCollection().entries.Values()
				Local companyFee:Int = p.GetFee(script.owner,  script.GetBlocks(), script.productionBroadCastLimit)
				'better than what we found ?
				if bestCompany
					If p.GetFocusPoints() > bestFocusPoints and companyFee < budget * 0.7
						'if company is more far from requirements than 
						'current and also more expensive!
						If abs(p.GetFocusPoints() - requiredFocusPoints) > abs(bestFocusPoints - requiredFocusPoints) and companyFee > bestFee Then Continue
						'ignore company to give others a chance
						If RandRange(0, 100) > 75 Then Continue
						'alternative: if more than required, then only if cheaper
						'this wont choose a "bigger" company if it is more expensive
						'than the cheaper one which does not offer the required focus
						'points
						'If p.GetFocusPoints() > requiredFocusPoints and p.GetFee() > bestFee Then Continue

						bestCompany = p
						bestFocusPoints = p.GetFocusPoints()
						bestFee = companyFee
					Endif
				Else
					bestCompany = p
					bestFocusPoints = p.GetFocusPoints()
					bestFee = companyFee
				EndIf
			Next
			
			If bestCompany Then productionCompany = bestCompany
		EndIf
		If Not productionCompany Then Throw "No ProductionCompany"

		'print "ChooseProductionCompany: requiredFocusPoints="+requiredFocusPoints + "  script.potential="+script.potential + "  estimatedPotential="+estimatedPotential + "  companyFocusPoints=" + productionCompany.GetFocusPoints()

		productionConcept.SetProductionCompany(productionCompany)
	End Method


	Method ChooseFocusPoints(productionConcept:TProductionConcept, script:TScript)
		Local fpToSpend:Int = productionConcept.productionCompany.GetFocusPoints()
		'the lower the experience then the more the producer might set
		'too few or too much focus points (-25 to +25%)
		'(more points than available cannot be set...
		Local diff:Int = (100-experience)*25/100
		Local fpUsed:Int = fpToSpend * Max(0, Min(100, RandRange(100-diff, 100+diff))) / 100
		productionConcept.AssignEffectiveFocusPoints(fpUsed)
	End Method



	Method CreateProductionConcepts:TProductionConcept[](script:TScript = Null)
		Local result:TProductionConcept[]
		
		If Not script Then script = CreateScript()
		'add the script to the collection?
		'...
		'or just protect the title (for non-multi-production script) of being used again
		If script.GetProductionLimitMax() <= 1
			GetScriptCollection().AddTitleProtection(script.title, -1)
		EndIf

		'Print "CreateProductionConcept():"

		Local scripts:TScriptBase[] = [script]
		If script.IsSeries()
			scripts = script.subScripts
		EndIf
		
		Local chosenProductionCompany:TProductionCompanyBase
		For Local s:TScript = EachIn scripts
			'Print "  script: " + s.GetTitle()
			Local pc:TProductionConcept = New TProductionConcept.Initialize(-1, s)

			'multiple steps to fulfill:
			'1) Production company (use the same for all episodes)
			If Not chosenProductionCompany
				ChooseProductionCompany(pc, s)
			Else
				pc.SetProductionCompany(chosenProductionCompany)
			EndIf
			'Print "  production company: " + pc.productionCompany.name +"   focusPoints=" + pc.productionCompany.GetFocusPoints()

			'2) Cast
			ChooseCast(pc, s)

			'3) Focus points
			ChooseFocusPoints(pc, s)
			
			result :+ [pc]
		Next
		
		Return result
	End Method
End Type
