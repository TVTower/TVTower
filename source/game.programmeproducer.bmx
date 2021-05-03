SuperStrict
Import "game.programmeproducer.base.bmx"

Import "game.programme.programmedata.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.production.bmx"
Import "game.production.script.bmx"
Import "game.production.productionconcept.bmx"
Import "game.gamescriptexpression.bmx"


'register self to producer collection
rem
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
	Field productionsRunning:Int = 0
	Field nextProductionTime:Long
	Field updateCycle:int = 0
	Field budgetIncrease:Int = 1000


	Method New()
		_producerName:String = "PP_Programmes"
	End Method


	Method RandomizeCharacteristics:int()
		Super.RandomizeCharacteristics()

		budgetIncrease = RandRange(3, 8) * 250
		nextProductionTime = GetWorldTime().GetTimeGone() + RandRange(12, 48) * TWorldTime.HOURLENGTH
		
		'TODO: greed, favorite genres...
	End Method


	Method Remove() override
		'remove instance specific event listeners...
	End Method	

	
	Method Update:Int()
		budget :+ budgetIncrease 'update every 15minutes = 96x a day ...
		
		updateCycle :+ 1

		If productionsRunning = 0 and nextProductionTime < GetWorldTime().GetTimeGone()
			CreateProgrammeLicence(Null)

			nextProductionTime = GetWorldTime().GetTimeGone() + TWorldTime.HOURLENGTH * RandRange(32, 72)
		EndIf		



		'too many favororites? - clean up every 48*15 minutes = 12 hours
		if updateCycle mod 48 = 0
			while castFavorites.length > 20
				local favoriteIndex:Int = RandRange(0, castFavorites.length - 1)
				castFavorites = castFavorites[.. favoriteIndex] + castFavorites[favoriteIndex + 1 ..]
				castFavoritesIDs = castFavoritesIDs[.. favoriteIndex] + castFavoritesIDs[favoriteIndex + 1 ..]
				castFavoritesUsageCount = castFavoritesUsageCount[.. favoriteIndex] + castFavoritesUsageCount[favoriteIndex + 1 ..]
			Wend
		endif
	End Method


	Method CreateProgrammeLicence:Object(params:TData)
		Local result:TProgrammeLicence 
		
		productionsRunning :+ 1

		Local productionConcepts:TProductionConcept[] = CreateProductionConcepts()

		For local productionConcept:TProductionConcept = EachIn productionConcepts
			Local production:TProduction = New TProduction
			production.SetProductionConcept(productionConcept)
			production.SetStudio(0)
			'production.PayProduction()
			production.Start()
			production.Finalize() 'skip waiting
			production.AddProgrammeLicence() 'make licence available

			If production.producedLicenceID
				result = GetProgrammeLicenceCollection().Get(production.producedLicenceID )
			'TODO: DEPRECATED - can be removed after v0.7.1
			ElseIf production.producedLicenceGUID
				result = GetProgrammeLicenceCollection().GetByGUID( production.producedLicenceGUID )
			Endif
			If Not result
				TLogger.Log("TProgrammeProducer.CreateProgrammeLicence()", "Unable to fetch produced programmelicence (id="+production.producedLicenceID+", guid="+production.producedLicenceGUID+")", LOG_ERROR)
				Throw "TProgrammeProducer.CreateProgrammeLicence() : Unable to fetch produced programmelicence (id="+production.producedLicenceID+", guid="+production.producedLicenceGUID+")"
			EndIf
			
			If Not result.data.extra Then result.data.extra = New TData
			result.data.extra.AddString("producerName", _producerName)


			budget :- production.productionConcept.GetTotalCost()
			'TODO: cinema simulation?
			'sell it in game country
			local nationalSale:Int = result.GetSellPrice(-1)
			'sell it into some other countries
			local internationalSale:Int
			if result.data.GetQualityRaw() > 0.1 Then internationalSale :+ result.GetSellPrice(-1) / 6
			if result.data.GetQualityRaw() > 0.2 Then internationalSale :+ result.GetSellPrice(-1) / 2
			if result.data.GetQualityRaw() > 0.3 Then internationalSale :+ result.GetSellPrice(-1)
			if result.data.GetQualityRaw() > 0.4 Then internationalSale :+ result.GetSellPrice(-1) * 1
			if result.data.GetQualityRaw() > 0.6 Then internationalSale :+ result.GetSellPrice(-1) * 3
			if result.data.GetQualityRaw() > 0.8 Then internationalSale :+ result.GetSellPrice(-1) * 5

			budget = Min(budget + nationalSale + internationalSale, 2000000000)


			local oldExperience:Int = experience
			GainExperienceForProgrammeLicence(result)

			print "Programme producer ~q"+name+"~q produced ~q" + result.GetTitle() +"~q. Cost="+production.productionConcept.GetTotalCost() +"  Earned="+(nationalSale+internationalSale) + "(nat="+nationalSale+"  int="+internationalSale+"). New budget="+budget + ". Experience=" + oldExperience +" + " + (experience - oldExperience)

			productionsRunning = Max(0, productionsRunning - 1)
		Next
		
		'if it was a series episode, return licence of complete series 
		if result then result = result.GetParentLicence()

		Return result
	End Method



	Method CreateScript:TScript()
		Local scriptTemplate:TScriptTemplate = GetScriptTemplateCollection().GetRandomByFilter(True, True)
		If Not scriptTemplate 
			Throw "CreateScript(): Failed to fetch a random script template. All reached their limits?"
			Return Null
		EndIf

		'adds the script to the collection and also sets owner
		Local script:TScript = GetScriptCollection().GenerateFromTemplate(scriptTemplate)
		

		Return script
	End Method



	Method ChooseCast(productionConcept:TProductionConcept, script:TScript)
'		local castFavorites:TPersonBase[] = new TPersonBase[castFavoriteIDs.length]
'		for local i:int = 0 until castFavoriteIDs.length
'			castFavorites[i] = GetPersonBaseCollection().GetByID(castFavoritesIDs[i])
'		next

		'choose some cast suiting to the requirements of the script
		Local usedPersonIDs:Int[]
		For Local i:Int = 0 Until script.jobs.length
			Local job:TPersonProductionJob = script.jobs[i]
			Local jobCountry:String
			Local person:TPersonBase

			if script.IsLive() and job.job & TVTPersonJob.VISIBLECAST_MASK > 0 
				jobCountry = GetStationMapCollection().GetMapISO3166Code().ToUpper()
			Elseif not job.country
				jobCountry = ""
			Elseif job.country = "LOCAL"
				jobCountry = GetStationMapCollection().GetMapISO3166Code().ToUpper()
			Else
				jobCountry = job.country
			EndIf
			'find best suiting country code
			if jobCountry then jobCountry = GetProgrammeProducerCollection().GetBestFitPersonGeneratorCountryCode(jobCountry)

			'try to reuse someone
			If castFavoritesIDs.length > 0
				person = GetPersonBaseCollection().GetRandomFromArray(castFavorites, -1, True, True, job.job, job.gender, True, jobCountry, Null, usedPersonIDs)
				'if person print "would reuse: " + person.GetFullName()
				'slight chance to ignore the given one?
				'and to look for a new one
				If person and RandRange(0,100) < 10 Then person = Null
			EndIf


			'nobody to reuse now - fetch a new one
			If Not person
				If RandRange(0, 100) <= preferCelebrityCastRate
					person = GetPersonBaseCollection().GetRandomCelebrity(Null, True, True, job.job, job.gender, True, jobCountry, Null, usedPersonIDs)
				Else
					person = GetPersonBaseCollection().GetRandomInsignificant(Null, True, True, job.job, job.gender, True, jobCountry, Null, usedPersonIDs)
				EndIf

				'not enough insignificants available?
				If Not person
					Local useRandom:Int = True
					'ignore a requested country and use a local one? (10% chance)
					If jobCountry and RandRange(0, 100) <= 90
						useRandom = False
						jobCountry = GetStationMapCollection().GetMapISO3166Code().ToUpper()
					EndIf

					'also return random if no or no supported country
					'is set - else the person generator falls back to 
					'the fallback country (here "de" for Germany) 
					If useRandom or not GetPersonGenerator().HasProvider(jobCountry)
						jobCountry = GetPersonGenerator().GetRandomCountryCode()
					EndIf

					person = GetPersonBaseCollection().CreateRandom(jobCountry, Max(0, job.gender))
				EndIf
			EndIf

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
	End Method



	Method ChooseProductionCompany(productionConcept:TProductionConcept, script:TScript)
		'choose a suiting one - do we need many focus points?
		'maybe just choose one of the beginners to support them?
		'GetProductionCompanyBaseCollection().GetRandom()
		Local productionCompany:TProductionCompanyBase = GetProductionCompanyBaseCollection().GetAmateurs()
		Local requiredFocusPoints:Int = 5
		
		'to understand the script potential, experience is valuable
		local estimatedPotential:Int = (100 * script.potential + 0.5)
		'the less experience, the more blurry the potential is
		estimatedPotential = Min(100, Max(0, estimatedPotential + RandRange(-(100 - experience)/2, +(100 - experience)/2) ))
		
		if script.potential > 0.3 then requiredFocusPoints :+ 2 
		if script.potential > 0.5 then requiredFocusPoints :+ 3 
		if script.potential > 0.7 then requiredFocusPoints :+ 5 
		if script.potential > 0.9 then requiredFocusPoints :+ 7 
		if script.requiredStudioSize > 1 then requiredFocusPoints :+ 2 
		if script.requiredStudioSize > 2 then requiredFocusPoints :+ 5 
		'budget
		if budget > 1000000 then requiredFocusPoints :+ 2
		if budget > 2500000 then requiredFocusPoints :+ 5
		if budget > 5000000 then requiredFocusPoints :+ 8
		if budget >10000000 then requiredFocusPoints :+ 10
		
		'print "ChooseProductionCompany: requiredFocusPoints="+requiredFocusPoints + "  script.potential="+script.potential

		If requiredFocusPoints > 5
			'print "looking for non amateur production company with focuspoints >= "+requiredFocusPoints
			Local bestFocusPoints:Int
			Local bestFee:Int
			Local bestCompany:TProductionCompanyBase = Null
			For Local p:TProductionCompanyBase = EachIn GetProductionCompanyBaseCollection().entries.Values()
				'find a one with enough focus points
				If p.GetFocusPoints() < requiredFocusPoints Then continue

				'ignore more expensive ones (all of them fulfill 
				'requirements already)
				'This does NOT find the "best bet for the price"! 
				If bestCompany and p.GetFee() > bestFee Then continue

				bestCompany = p
				bestFocusPoints = p.GetFocusPoints()
				bestFee = p.GetFee()
			Next
			
			if bestCompany then productionCompany = bestCompany
		EndIf
		If Not productionCompany Then Throw "No ProductionCompany"

		productionConcept.SetProductionCompany(productionCompany)
	End Method



	Method ChooseFocusPoints(productionConcept:TProductionConcept, script:TScript)
		Local fpToSpend:Int = productionConcept.productionCompany.GetFocusPoints()
		'the lower the experience then the more the producer might set
		'too few or too much focus points (-25 to +25%)
		Local fpUsed:Int = fpToSpend * Max(0, Min(100, ((100-experience) * RandRange(75, 125))/100)) / 100

		productionConcept.AssignEffectiveFocusPoints(fpUsed)
	End Method



	Method CreateProductionConcepts:TProductionConcept[](script:TScript = Null)
		Local result:TProductionConcept[]
		
		If Not script Then script = CreateScript()
		'add the script to the collection?
		'...
		'or just protect the title of being used again
		GetScriptCollection().AddTitleProtection(script.title, -1)

		'Print "CreateProductionConcept():"

		Local scripts:TScriptBase[] = [script]
		if script.IsSeries()
			scripts = script.subScripts
		endif
		
		Local chosenProductionCompany:TProductionCompanyBase
		For local s:TScript = EachIn scripts
			'Print "  script: " + s.GetTitle()
			Local pc:TProductionConcept = New TProductionConcept.Initialize(-1, s)

			'multiple steps to fulfill:
			'1) Production company (use the same for all episodes)
			if not chosenProductionCompany
				ChooseProductionCompany(pc, s)
			else
				pc.SetProductionCompany(chosenProductionCompany)
			endif
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
