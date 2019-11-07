SuperStrict
Import "game.programmeproducer.base.bmx"
Import "game.programme.programmedata.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.production.bmx"
Import "game.production.script.bmx"
Import "game.production.productionconcept.bmx"

'to know the short country name of the used map
Import "game.stationmap.bmx"

'register self to producer collection
GetProgrammeProducerCollection().Add( TProgrammeProducerMorningShows.GetInstance() )


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


Type TProgrammeProducerWithProduction Extends TProgrammeProducerBase
	Field castFavorites:TProgrammePersonBase[]
	Field castFavoritesGUIDs:String[]
	Field castFavoritesUsageCount:Int[]
	Field productionsRunning:Int = 0



	Method CreateProgrammeLicence:Object(params:TData)
		productionsRunning :+ 1

		Local productionConcept:TProductionConcept = CreateProductionConcept()

		Local production:TProduction = New TProduction
		production.SetProductionConcept(productionConcept)
		production.SetStudio("")
		production.PayProduction()
		production.Start()
		production.Finalize() 'skip waiting

		Local result:TProgrammeLicence = GetProgrammeLicenceCollection().GetByGUID( production.producedLicenceGUID )
		If result
			If Not result.data.extra Then result.data.extra = New TData
			result.data.extra.AddString("producerName", _producerName)
		EndIf

		productionsRunning = Max(0, productionsRunning - 1)

		Return result
	End Method



	Method CreateScript:TScript()
		Local scriptTemplate:TScriptTemplate = GetScriptTemplateCollection().GetRandomByFilter(True, True)
		If Not scriptTemplate Then Return Null

		Local script:TScript = TScript.CreateFromTemplate(scriptTemplate)
		script.SetOwner(-1)
		Return script
	End Method



	Method ChooseCast(productionConcept:TProductionConcept, script:TScript)
'		local castFavorites:TProgrammePersonBase[] = new TProgrammePersonBase[castFavoriteGUIDs.length]
'		for local i:int = 0 until castFavoriteGUIDs.length
'			castFavorites[i] = GetProgrammePersonBaseCollection().GetByGUID(castFavoritesGUIDs[i])
'		next

		'choose some cast suiting to the requirements of the script
		Local usedPersonGUIDs:String[]
		For Local i:Int = 0 Until script.cast.length
			Local job:TProgrammePersonJob = script.cast[i]
			Local person:TProgrammePersonBase
			'try to reuse someone
			If castFavoritesGUIDs.length > 0
				person = GetProgrammePersonBaseCollection().GetRandomFromArray(castFavorites, True, True, job.job, job.gender, usedPersonGUIDs)
				'slight chance to ignore the given one?
				'and to look for a new one
				If RandRange(0,100) < 10 Then person = Null
			EndIf
			'nobody to reuse now - fetch a new amateur/beginner
			If Not person
				person = GetProgrammePersonBaseCollection().GetRandomInsignificant(Null, True, True, job.job, job.gender, usedPersonGUIDs)

				'not enough insignificants available?
				If Not person
					Local countryCode:String = GetStationMapCollection().config.GetString("nameShort", "Unk")
					'try to use "map specific names"
					If RandRange(0,100) < 25 Or Not GetPersonGenerator().HasProvider(countryCode)
						countryCode = GetPersonGenerator().GetRandomCountryCode()
					EndIf
					person = CreateRandomInsignificantPerson(countryCode, Max(0, job.gender))
				EndIf
			EndIf

			'store used cast selections so amateurs sooner become celebs
			'with specialization
			Local favoriteIndex:Int = StringHelper.GetArrayIndex(person.GetGUID(), castFavoritesGUIDs)
			If favoriteIndex = -1
				castFavoritesGUIDs :+ [person.GetGUID()]
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
				castFavoritesGUIDs = castFavoritesGUIDs[.. favoriteIndex] + castFavoritesGUIDs[favoriteIndex + 1 ..]
				castFavoritesUsageCount = castFavoritesUsageCount[.. favoriteIndex] + castFavoritesUsageCount[favoriteIndex + 1 ..]
			EndIf

			productionConcept.SetCast(i, person)

			If Not StringHelper.InArray(person.GetGUID(), usedPersonGUIDs)
				usedPersonGUIDs :+ [person.GetGUID()]
			EndIf
		Next

		'pc.CalculateCastFit()
	End Method



	Method ChooseProductionCompany(productionConcept:TProductionConcept, script:TScript)
		'choose a suiting one - do we need many focus points?
		'maybe just choose one of the beginners to support them?
		'GetProductionCompanyBaseCollection().GetRandom()
		Local productionCompany:TProductionCompanyBase
		For Local pComp:TProductionCompanyBase = EachIn GetProductionCompanyBaseCollection().entries.Values()
			If Not productionCompany Or productionCompany.GetLevel() > pComp.GetLevel()
				productionCompany = pComp
			EndIf
		Next
		If Not productionCompany Then Throw "No ProductionCompany"

		productionConcept.SetProductionCompany(productionCompany)
Print "  production company: " + productionCompany.name +"   focusPoints=" + productionCompany.GetFocusPoints()
	End Method



	Method ChooseFocusPoints(productionConcept:TProductionConcept, script:TScript, focusPointPerfection:Float = 0.5)
		Local fpToSpend:Int = productionConcept.productionCompany.GetFocusPoints()
		Local fpUsed:Int = fpToSpend * Max(0, Min(100, focusPointPerfection * RandRange(75, 125)))/100.0

		'to make fp checks fulfilled:
		productionConcept.SetProductionFocus(0, fpToSpend)

		productionConcept._effectiveFocusPointsMax = fpToSpend
		productionConcept._effectiveFocusPoints = fpUsed
	End Method



	Method CreateProductionConcept:TProductionConcept(script:TScript = Null)
		If Not script Then script = CreateScript()
		'add the script to the collection?
		'...
		'or just protect the title of being used again
		GetScriptCollection().AddTitleProtection(script.title, -1)

Print "CreateProductionConcept():"
Print "  script: " + script.GetTitle()

		Local pc:TProductionConcept = New TProductionConcept.Initialize(-1, script)

		'multiple steps to fulfill:
		'1) Production company
		ChooseProductionCompany(pc, script)

		'2) Cast
		ChooseCast(pc, script)

		'3) Focus points
		ChooseFocusPoints(pc, script)

		Return pc
	End Method
End Type




Type TProgrammeProducerMorningShows Extends TProgrammeProducerWithProduction
	Global _eventListeners:TEventListenerBase[]
	Global _instance:TProgrammeProducerMorningShows


	Method New()
		_producerName:String = "PP_MorningShows"

		'=== remove all registered event listeners
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = New TEventListenerBase[0]

		'react to "finished" special programmes
		'_eventListeners :+ [ EventManager.registerListenerFunction("ProgrammeLicence.onGiveBackToLicencePool", onGiveBackLicenceToPool) ]
	End Method

	'override
	Method GenerateGUID:String()
		Return "programmeproducermorningshows-"+id
	End Method


	Function GetInstance:TProgrammeProducerMorningShows()
		If Not _instance Then _instance = New TProgrammeProducerMorningShows
		Return _instance
	End Function


	Method onGiveBackLicenceToPool:Int( licence:TProgrammeLicence )
		'reduce count of currently produced morning shows ...
	End Method


	Method Update:Int()
		'hier eventuell auf "Typ" limitieren aber mehrfache Simultanproduktion
		'ermoeglichen
		If productionsRunning = 0
			CreateProgrammeLicence(Null)
		EndIf
	End Method





Rem
		programmeData.GUID = "programmedata-programmeproducer-specialprogrammes-"+programmeData.id
		programmeData.productType = TVTProgrammeProductType.MISC
		programmeData.country = ProducerCountry
		programmeData.distributionChannel = TVTProgrammeDistributionChannel.TV
		programmeData.SetFlag(TVTProgrammeDataFlag.LIVE, True)
		programmeData.genre = TVTProgrammeGenre.SHOW
		'so the licence datasheet does expose that information
		programmeData.SetBroadcastLimit(10)
		'once sold, this programmelicence wont be buyable anylonger
		programmeLicence.setLicenceFlag(TVTProgrammeLicenceFlag.LICENCEPOOL_REMOVES_TRADEABILITY, True)

		return programmeLicence
endrem
End Type