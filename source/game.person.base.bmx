SuperStrict
Import Brl.ObjectList
Import "Dig/base.util.longmap.bmx"
Import "Dig/external/string_comp.bmx"
Import "Dig/base.util.string.bmx"
Import "Dig/base.util.localization.bmx"
Import "Dig/base.util.persongenerator.bmx"
Import "basefunctions.bmx"
Import "game.gameobject.bmx"
Import "game.gameconstants.bmx"
Import "game.popularity.bmx"


Type TPersonBaseCollection Extends TGameObjectCollection
	'there are a multitude of types a person can be
	'insignificant: unimportant person / no news ...
	'celebrity: a person which has birthday, can create scandals
	'castable: all persons which can be used in custom productions

	'these maps act as filtered caches to speed up
	'lookup times if a specific restriction is needed
	'- TIntMaps for fast ID-lookups
	'- TObjectList for fast random retrieval
	'- count for easy counting (not available in TIntMap)
	Field filteredIDMaps:TIntMap[5] {nosave}
	Field filteredLists:TObjectList[5] {nosave}
	Field filteredCounts:Int[5] {nosave}
	
	'Indices in the cache arrays
	Const FILTER_INSIGNIFICANT:Int = 0
	Const FILTER_CELEBRITY:Int = 1
	Const FILTER_CASTABLE:Int = 2
	Const FILTER_CASTABLE_INSIGNIFICANT:Int = 3
	Const FILTER_CASTABLE_CELEBRITY:Int = 4
	Const FILTER_COUNT:Int = 5
	Global _instance:TPersonBaseCollection


	Function GetInstance:TPersonBaseCollection()
		If Not TPersonBaseCollection(_instance) Then _instance = New TPersonBaseCollection
		Return TPersonBaseCollection(_instance)
	End Function


	Method Initialize:TPersonBaseCollection()
		Super.Initialize()

		For Local i:Int = 0 Until filteredIDMaps.length
			If filteredIDMaps[i] Then filteredIDMaps[i].Clear()
			If filteredLists[i] Then filteredLists[i].Clear()
			filteredCounts[i] = 0
		Next

		Return Self
	End Method


	'override
	Method GetByGUID:TPersonBase(GUID:String)
		Return TPersonBase( Super.GetByGUID(GUID) )
	End Method


	'override
	Method GetByID:TPersonBase(ID:Int)
		Return TPersonBase( Super.GetByID(ID) )
	End Method


	Method CreateRandom:TPersonBase(countryCode:String, gender:Int=0)
		Local pg:TPersonGeneratorEntry = GetPersonGenerator().GetUniqueDataset(countryCode, gender)
		If Not pg Then Return Null

		Local person:TPersonBase = New TPersonBase

		person.firstName = pg.firstName
		person.lastName = pg.lastName
		person.countryCode = pg.countryCode
		person.SetFlag(TVTPersonFlag.FICTIONAL, True)
		person.SetFlag(TVTPersonFlag.BOOKABLE, True)
		person.SetFlag(TVTPersonFlag.CAN_LEVEL_UP, True)

		'avoid others of same name
		GetPersonGenerator().ProtectDataset(pg)

		GetPersonBaseCollection().Add(person)

		Return person
	End Method
	
	
	Method _UpdateFiltered:Int(filterIndex:Int=-1, force:Int=False)
		If filterIndex < 0 Or filterIndex >= filteredIDMaps.length Then Return False

		If force Or Not filteredIDMaps[filterIndex]
			If Not filteredIDMaps[filterIndex]
				filteredIDMaps[filterIndex] = New TIntMap
			Else
				filteredIDMaps[filterIndex].Clear()
			EndIf
			If Not filteredLists[filterIndex]
				filteredLists[filterIndex] = New TObjectList
			Else
				filteredLists[filterIndex].Clear()
			EndIf

			Local insignificant:Int, celebrity:Int, castable:Int
			_FillPersonMeetsRequirementsVariables(filterIndex, insignificant, celebrity, castable)

			'store in variable so we skip having an array lookup
			'during person iteration
			Local map:TIntMap = filteredIDMaps[filterIndex]
			Local list:TObjectList = filteredLists[filterIndex]
			Local count:Int = 0

'If insignificant = 0 Then Print "====== Update unfiltered ======"
'print "insignificant=" + insignificant + "   celebrity="+celebrity + "   castable="+castable
			For Local p:TPersonBase = EachIn entries.Values()
				'skip non-suiting ones
				If Not _PersonMeetsRequirements(p, insignificant, celebrity, castable, -1) 
'					If p.IsFictional() then Print p.GetFullName() + " FAIL"
					Continue
'				Else
'					If p.IsFictional() then Print p.GetFullName() + " OK"
				EndIf

				map.Insert(p.GetID(), p)
				list.AddLast(p)
				count :+ 1
			Next
			
			filteredCounts[filterIndex] = count
		EndIf

		Return True
	End Method
	
	
	Function _FillPersonMeetsRequirementsVariables(filterIndex:Int, insignificant:Int Var, celebrity:Int Var, castable:Int Var)
		'adders: 0 only if not of type
		'        1 only if of type
		'       -1 ignore
		Select filterIndex
			Case FILTER_INSIGNIFICANT
				insignificant = 1
				celebrity = 0
				castable = -1
			Case FILTER_CELEBRITY
				insignificant = 0
				celebrity = 1
				castable = -1
			Case FILTER_CASTABLE
				insignificant = -1
				celebrity = -1
				castable = 1
			Case FILTER_CASTABLE_INSIGNIFICANT
				insignificant = 1
				celebrity = 0
				castable = 1
			Case FILTER_CASTABLE_CELEBRITY
				insignificant = 0
				celebrity = 1
				castable = 1
			Default
				insignificant = -1
				celebrity = -1
				castable = -1
		End Select
	End Function
	

	'returns False for persons _NOT_ having the desired properties.
	Function _PersonMeetsRequirements:Int(p:TPersonBase, insignificant:Int = -1, celebrity:Int = -1, castable:Int = -1, gender:Int = -1)
		If insignificant <> -1 And insignificant <> p.IsInsignificant() Then Return False
		If celebrity <> -1 And celebrity <> p.IsCelebrity() Then Return False
		If castable <> -1 And castable <> p.IsCastable() Then Return False

		If gender <> -1 And p.gender <> gender Then Return False

		Return True
	End Function

	
	Function _FilterList:TPersonBase[](list:TObjectList, filterIndex:Int= -1, onlyFictional:Int = False, onlyBookable:Int = False, productionJob:Int = 0, gender:Int = -1, forbiddenGUIDs:String[] = Null, forbiddenIDs:Int[] = Null)
		If Not list Then Return Null

		Local result:TPersonBase[] = New TPersonBase[10]
		Local found:Int = 0
		Local insignificant:Int=-1, celebrity:Int=-1, castable:Int=-1
		_FillPersonMeetsRequirementsVariables(filterIndex, insignificant, celebrity, castable)

		For Local p:TPersonBase = EachIn list
			If Not _PersonMeetsRequirements(p, insignificant, celebrity, castable, gender) Then Continue
			If onlyFictional And Not p.IsFictional() Then Continue
			If onlyBookable And Not p.IsBookable() Then Continue
			If productionJob > 0 And Not p.HasJob(productionJob) Then Continue
			If forbiddenIDs And MathHelper.InIntArray(p.GetID(), forbiddenIDs) Then Continue
			If forbiddenGUIDs And StringHelper.InArray(p.GetGUID(), forbiddenGUIDs) Then Continue

			result[found] = p
			found :+ 1
			If found = result.length Then result = result[.. found + 10]
		Next
		If found <> result.length Then result = result[.. found]

		Return result
	End Function
	
	
	Function _FilterMap:TPersonBase[](map:TIntMap, filterIndex:Int = -1, onlyFictional:Int = False, onlyBookable:Int = False, productionJob:Int = 0, gender:Int = -1, forbiddenGUIDs:String[] = Null, forbiddenIDs:Int[] = Null)
		If Not map Then Return Null

		Local result:TPersonBase[] = New TPersonBase[10]
		Local found:Int = 0
		Local insignificant:Int=-1, celebrity:Int=-1, castable:Int=-1
		_FillPersonMeetsRequirementsVariables(filterIndex, insignificant, celebrity, castable)

		For Local p:TPersonBase = EachIn map.Values()
			If Not _PersonMeetsRequirements(p, insignificant, celebrity, castable, gender) Then Continue
			If onlyFictional And Not p.IsFictional() Then Continue
			If onlyBookable And Not p.IsBookable() Then Continue
			If productionJob > 0 And Not p.HasJob(productionJob) Then Continue
			If forbiddenIDs And MathHelper.InIntArray(p.GetID(), forbiddenIDs) Then Continue
			If forbiddenGUIDs And StringHelper.InArray(p.GetGUID(), forbiddenGUIDs) Then Continue

			result[found] = p
			found :+ 1
			If found = result.length Then result = result[.. found + 10]
		Next
		If found <> result.length Then result = result[.. found]

		Return result
	End Function


	Function _FilterArray:TPersonBase[](array:TPersonBase[], filterIndex:Int = -1, onlyFictional:Int = False, onlyBookable:Int = False, productionJob:Int = 0, gender:Int = -1, forbiddenGUIDs:String[] = Null, forbiddenIDs:Int[] = Null)
		If Not array Or array.length = 0 Then Return Null

		Local result:TPersonBase[] = New TPersonBase[Min(10, array.length)]
		Local found:Int = 0
		Local insignificant:Int=-1, celebrity:Int=-1, castable:Int=-1
		_FillPersonMeetsRequirementsVariables(filterIndex, insignificant, celebrity, castable)

		For Local p:TPersonBase = EachIn array
			If Not _PersonMeetsRequirements(p, insignificant, celebrity, castable, gender) Then Continue
			If onlyFictional And Not p.IsFictional() Then Continue
			If onlyBookable And Not p.IsBookable() Then Continue
			If productionJob > 0 And Not p.HasJob(productionJob) Then Continue
			If forbiddenIDs And MathHelper.InintArray(p.GetID(), forbiddenIDs) Then Continue
			If forbiddenGUIDs And StringHelper.InArray(p.GetGUID(), forbiddenGUIDs) Then Continue

			result[found] = p
			found :+ 1
			If found = result.length Then result = result[.. found + 10]
		Next
		If found <> result.length Then result = result[.. found]

		Return result
	End Function


	Method GetFilteredMap:TIntMap(filterIndex:Int=-1)
		If Not _UpdateFiltered(filterIndex) Then Return Null

		Return filteredIDMaps[filterIndex]
	End Method

	
	Method GetFilteredList:TObjectList(filterIndex:Int=-1)
		If Not _UpdateFiltered(filterIndex) Then Return Null

		Return filteredLists[filterIndex]
	End Method
	
	
	Method GetFilteredCount:Int(filterIndex:Int=-1)
		If Not _UpdateFiltered(filterIndex) Then Return Null

		Return filteredLists[filterIndex].Count()
	End Method

	
	Method GetInsignificantsList:TObjectList()
		Return GetFilteredList(FILTER_INSIGNIFICANT)
	End Method
	
	Method GetCelebritiesList:TObjectList()
		Return GetFilteredList(FILTER_CELEBRITY)
	End Method

	Method GetCastablesList:TObjectList()
		Return GetFilteredList(FILTER_CASTABLE)
	End Method

	Method GetCastableInsignificantsList:TObjectList()
		Return GetFilteredList(FILTER_CASTABLE_INSIGNIFICANT)
	End Method

	Method GetCastableCelebritiesList:TObjectList()
		Return GetFilteredList(FILTER_CASTABLE_CELEBRITY)
	End Method

	Method GetInsignificant:TPersonBase(ID:Int)
		Return TPersonBase( GetFilteredMap(FILTER_INSIGNIFICANT).ValueForKey(ID) )
	End Method

	Method GetCelebrity:TPersonBase(ID:Int)
		Return TPersonBase( GetFilteredMap(FILTER_CELEBRITY).ValueForKey(ID) )
	End Method

	Method GetCastable:TPersonBase(ID:Int)
		Return TPersonBase( GetFilteredMap(FILTER_CASTABLE).ValueForKey(ID) )
	End Method

	Method GetCastableCelebrity:TPersonBase(ID:Int)
		Return TPersonBase( GetFilteredMap(FILTER_CASTABLE_CELEBRITY).ValueForKey(ID) )
	End Method

	Method GetCastableInsignificant:TPersonBase(ID:Int)
		Return TPersonBase( GetFilteredMap(FILTER_CASTABLE_INSIGNIFICANT).ValueForKey(ID) )
	End Method

	
	'=== Random retrievers ===
	'retrieve a person by filterIndex, list or map + additional filters
	
	Method GetRandomByFilter:TPersonBase(filterIndex:Int, onlyFictional:Int = False, onlyBookable:Int = False, job:Int = 0, gender:Int = -1, forbiddenGUIDs:String[] = Null, forbiddenIDs:Int[] = Null)
		Local list:TObjectList = GetFilteredList(filterIndex)
		If Not list Then Return Null
		
		Return GetRandomFromList(list, filterIndex, onlyFictional, onlyBookable, job, gender, forbiddenGUIDs, forbiddenIDs)
	End Method 

	
	Method GetRandomFromList:TPersonBase(list:TObjectList, filterIndex:Int = -1, onlyFictional:Int = False, onlyBookable:Int = False, job:Int = 0, gender:Int = -1, forbiddenGUIDs:String[] = Null, forbiddenIDs:Int[] = Null)
		If Not list Then Return Null
		
		'unfiltered - use raw list to save additional computation/memory ?
		If filterIndex = -1 And Not onlyFictional And Not onlyBookable And job = 0 And gender = -1 And (Not forbiddenGUIDs Or forbiddenGUIDs.length = 0) And (Not forbiddenIDs Or forbiddenIDs.length = 0)
			Return TPersonBase(list.ValueAtIndex( RandRange(0, list.Count()-1) ))
		Else
			Local effectiveArray:TPersonBase[] = _FilterList(list, filterIndex, onlyFictional, onlyBookable, job, gender, forbiddenGUIDs, forbiddenIDs)
			If effectiveArray.length = 0 Then Return Null

			'RandRange - so it is the same over network
			Return effectiveArray[(RandRange(0, effectiveArray.length-1))]
		EndIf
	End Method 
	

	Method GetRandomFromArray:TPersonBase(array:TPersonBase[], filterIndex:Int = -1, onlyFictional:Int = False, onlyBookable:Int = False, job:Int = 0, gender:Int = -1, forbiddenGUIDs:String[] = Null, forbiddenIDs:Int[] = Null)
		If Not array Or array.length = 0 Then Return Null

		'unfiltered - use raw list to save additional computation/memory ?
		If filterIndex =-1 And Not onlyFictional And Not onlyBookable And job = 0 And gender = -1 And (Not forbiddenGUIDs Or forbiddenGUIDs.length = 0) And (Not forbiddenIDs Or forbiddenIDs.length = 0)
			Return array[ RandRange(0, array.length-1) ]
		Else
			Local effectiveArray:TPersonBase[] = _FilterArray(array, filterIndex, onlyFictional, onlyBookable, job, gender, forbiddenGUIDs, forbiddenIDs)
			If effectiveArray.length = 0 Then Return Null

			'RandRange - so it is the same over network
			Return effectiveArray[(RandRange(0, effectiveArray.length-1))]
		EndIf
	End Method
	
	
	Method GetRandomFromArrayOrFilter:TPersonBase(array:TPersonBase[] = Null, filterIndex:Int=-1, onlyFictional:Int = False, onlyBookable:Int = False, job:Int = 0, gender:Int = -1, forbiddenGUIDs:String[] = Null, forbiddenIDs:Int[] = Null)
		If Not array
			Return GetRandomByFilter(filterIndex, onlyFictional, onlyBookable, job, gender, forbiddenGUIDs, forbiddenIDs)
		ElseIf array.length = 0
			Return Null
		Else
			Return GetRandomFromArray(array, filterIndex, onlyFictional, onlyBookable, job, gender, forbiddenGUIDs, forbiddenIDs)
		EndIf
	End Method
	

	'useful to fetch a random "amateur" (aka "layman")
	Method GetRandomInsignificant:TPersonBase(array:TPersonBase[] = Null, onlyFictional:Int = False, onlyBookable:Int = False, job:Int = 0, gender:Int = -1, forbiddenGUIDs:String[] = Null, forbiddenIDs:Int[] = Null)
		Return GetRandomFromArrayOrFilter(array, FILTER_INSIGNIFICANT, onlyFictional, onlyBookable, job, gender, forbiddenGUIDs, forbiddenIDs)
	End Method


	Method GetRandomCelebrity:TPersonBase(array:TPersonBase[] = Null, onlyFictional:Int = False, onlyBookable:Int = False, job:Int = 0, gender:Int = -1, forbiddenGUIDs:String[] = Null, forbiddenIDs:Int[] = Null)
		Return GetRandomFromArrayOrFilter(array, FILTER_CELEBRITY, onlyFictional, onlyBookable, job, gender, forbiddenGUIDs, forbiddenIDs)
	End Method

	
	Method GetRandomCastable:TPersonBase(array:TPersonBase[] = Null, onlyFictional:Int = False, onlyBookable:Int = False, job:Int = 0, gender:Int = -1, forbiddenGUIDs:String[] = Null, forbiddenIDs:Int[] = Null)
		Return GetRandomFromArrayOrFilter(array, FILTER_CASTABLE, onlyFictional, onlyBookable, job, gender, forbiddenGUIDs, forbiddenIDs)
	End Method


	Method GetFilteredInsignificantsArray:TPersonBase[](onlyFictional:Int = False, onlyBookable:Int = False, job:Int=0, gender:Int=-1, forbiddenGUIDs:String[] = Null, forbiddenIDs:Int[] = Null)
		Return _FilterList( GetFilteredList(FILTER_INSIGNIFICANT), -1, onlyFictional, onlyBookable, job, gender, forbiddenGUIDs, forbiddenIDs)
	End Method


	Method GetFilteredCelebritiesArray:TPersonBase[](onlyFictional:Int = False, onlyBookable:Int = False, job:Int=0, gender:Int=-1, forbiddenGUIDs:String[] = Null, forbiddenIDs:Int[] = Null)
		Return _FilterList( GetFilteredList(FILTER_CELEBRITY), -1, onlyFictional, onlyBookable, job, gender, forbiddenGUIDs, forbiddenIDs)
	End Method


	Method GetFilteredCastablesArray:TPersonBase[](onlyFictional:Int = False, onlyBookable:Int = False, job:Int=0, gender:Int=-1, forbiddenGUIDs:String[] = Null, forbiddenIDs:Int[] = Null)
		Return _FilterList( GetFilteredList(FILTER_CASTABLE), -1, onlyFictional, onlyBookable, job, gender, forbiddenGUIDs, forbiddenIDs)
	End Method


	Method GetInsignificantCount:Int()
		Return GetFilteredCount(FILTER_INSIGNIFICANT)
	End Method


	Method GetCelebrityCount:Int()
		Return GetFilteredCount(FILTER_CELEBRITY)
	End Method


	Method Remove:Int(obj:TGameObject)
		If Super.Remove(obj)
			For Local index:Int = 0 Until FILTER_COUNT
				If GetFilteredMap(index).Remove(obj.GetID())
					GetFilteredList(index).Remove(obj)			
				EndIf
			Next
						
			Return True
		EndIf

		Return False
	End Method
			

	Method Add:Int(obj:TGameObject)
		Local p:TPersonBase = TPersonBase(obj)
		If Not p Then Return False

		Super.Add(obj)
		
		Local insignificant:Int, celebrity:Int, castable:Int
		For Local index:Int = 0 Until FILTER_COUNT
			_FillPersonMeetsRequirementsVariables(index, insignificant, celebrity, castable)
			If Not _PersonMeetsRequirements(p, insignificant, celebrity, castable, -1) Then Continue
			
			GetFilteredList(index).AddLast(p)
			GetFilteredMap(index).Insert(p.GetID(), p)
		Next
		
		Return True
	End Method
	

	Function SortByName:Int(o1:Object, o2:Object)
		Local p1:TPersonBase = TPersonBase(o1)
		Local p2:TPersonBase = TPersonBase(o2)
		If Not p2 Then Return 1
		If p1.GetFullName() = p2.GetFullName()
			Return p1.GetGUID() > p2.GetGUID()
		EndIf
        If p1.GetFullName().ToLower() > p2.GetFullName().ToLower()
			Return 1
        ElseIf p1.GetFullName().ToLower() < p2.GetFullName().ToLower()
			Return -1
		EndIf
		Return 0
	End Function
End Type
'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetPersonBaseCollection:TPersonBaseCollection()
	Return TPersonBaseCollection.GetInstance()
End Function

Function GetPersonBase:TPersonBase(ID:Int)
	Return TPersonBaseCollection.GetInstance().GetByID(ID)
End Function
Function GetPerson:TPersonBase(ID:Int)
	Return TPersonBaseCollection.GetInstance().GetByID(ID)
End Function
Function GetPersonByGUID:TPersonBase(GUID:String)
	Return TPersonBaseCollection.GetInstance().GetByGUID(GUID)
End Function




Type TPersonBase Extends TGameObject
	Field lastName:String = ""
	Field firstName:String = ""
	Field nickName:String = ""
	Field countryCode:String = ""
	Field gender:Int = 0
	'a text code representing the config for the figure generator
	Field faceCode:String
	'bitmask containing "castable", "active", "celebrity", ..
	'and also "fictional" (is this an real existing person 
	'or someone we imaginated for the game?)
	Field _flags:Int
	'bitmask containing current job(s)
	Field _jobs:Int

	'storage of celebrity, production, ... data sets
	Field data:TMap

	'cache for often used Data
	Field _personalityData:TPersonPersonalityBaseData {nosave}
	Field _productionData:TPersonProductionBaseData {nosave}
	
	Global dataKeyPersonality:String = "personality"
	Global dataKeyProduction:String = "production"
	
	
	Method New()
		'by default they can level up
		SetFlag(TVTPersonFlag.ACTIVE)
		SetFlag(TVTPersonFlag.BOOKABLE)
		SetFlag(TVTPersonFlag.CASTABLE)
		SetFlag(TVTPersonFlag.CAN_LEVEL_UP)
	End Method


	Method SetFirstName:Int(firstName:String)
		Self.firstName = firstName
	End Method


	Method SetLastName:Int(lastName:String)
		Self.lastName = lastName
	End Method


	Method SetNickName:Int(nickName:String)
		Self.nickName = nickName
	End Method


	Method GetNickName:String()
		If nickName = "" Then Return firstName
		Return nickName
	End Method


	Method GetFirstName:String()
		Return firstName
	End Method


	Method GetLastName:String()
		Return lastName
	End Method


	Method GetFullName:String()
		If Self.lastName<>""
			If Self.firstName <> "" Then Return Self.firstName + " " + Self.lastName
			Return Self.lastName
		EndIf
		Return Self.firstName
	End Method


	Method GetAge:Int()
		Return GetPersonalityData().GetAge()
	End Method


	Method IsAlive:Int()
		Return True
	End Method


	Method IsBorn:Int()
		Return True
	End Method
	

	Method GetCountryCode:String()
		Return GetPersonalityData().GetCountryCode()
	End Method


	Method GetCountry:String()
		Return GetPersonalityData().GetCountry()
	End Method


	Method GetCountryLong:String()
		GetPersonalityData().GetCountryLong()
	End Method
	

	Method GetPopularity:TPopularity()
		Return GetPersonalityData().GetPopularity()
	End Method


	Method GetPopularityValue:Float()
		Local p:TPopularity = GetPopularity()
		If Not p Then Return 0

		Return p.Popularity
	End Method
	
	
	Method GetPersonalityAttribute:Float(attributeID:Int, jobID:Int = -1, genreID:Int = -1)
		Return GetPersonalityData().GetAttributeValue(attributeID, jobID, genreID)
	End Method


	Method SetChannelSympathy:Int(channel:Int, newSympathy:Float)
		Return GetPersonalityData().SetChannelSympathy(channel, newSympathy)
	End Method


	Method GetChannelSympathy:Float(channel:Int)
		Return GetPersonalityData().GetChannelSympathy(channel)
	End Method


	Method GetTotalProductionJobsDone:Int()
		If GetProductionData()
			Return GetProductionData().GetProductionJobsDone(0)
		EndIf
		Return 0
	End Method


	Method GetProductionJobsDone:Int(jobID:Int)
		Return GetJobsDone(jobID)
	End Method
	
	
	Method GetJobsDone:Int(jobID:Int)
		If TVTPersonJob.IsCastJob(jobID) And GetProductionData()
			Return GetProductionData().GetProductionJobsDone(jobID)
		Else
			'TODO: Other jobs ?
			Return 0
		EndIf
	End Method


	Method GetJobBaseFee:Int(jobID:Int, blocks:Int, channel:Int=-1)
		If TVTPersonJob.IsCastJob(jobID) And GetProductionData()
			Return GetProductionData().GetBaseFee(jobID, blocks, channel)
		Else
			'TODO: Other getters for other jobs ? 
			Return 1000
		EndIf
	End Method
	
	
	Method GetJobExperiencePercentage:Float(jobID:Int)
		If TVTPersonJob.IsCastJob(jobID) And GetProductionData()
			Return GetProductionData().GetJobExperiencePercentage(jobID)
		Else
			'TODO: Other getters for other jobs ? 
			Return 0
		EndIf
	End Method


	Method GetEffectiveJobExperiencePercentage:Float(jobID:Int)
		If TVTPersonJob.IsCastJob(jobID) And GetProductionData()
			Return GetProductionData().GetEffectiveJobExperiencePercentage(jobID)
		Else
			'TODO: Other getters for other jobs ? 
			Return 0.0
		EndIf
	End Method


	Method SetFlag(flag:Int, enable:Int = True)
		If enable
			_flags :| flag
		Else
			_flags :& ~flag
		EndIf
	End Method


	Method HasFlag:Int(flag:Int)
		Return (_flags & flag) > 0
	End Method


	Method SetJob(job:Int, enable:Int = True)
		If enable
			_jobs :| job
		Else
			_jobs :& ~job
		EndIf
	End Method


	Method GetJobs:Int()
		Return _jobs
	End Method


	Method HasJob:Int(job:Int)
		Return (_jobs & job) > 0
	End Method


	Method IsCelebrity:Int()
		Return (_flags & TVTPersonFlag.CELEBRITY) > 0
	End Method


	Method IsInsignificant:Int()
		Return Not (_flags & TVTPersonFlag.CELEBRITY)
	End Method
	
	
	Method IsCastable:Int()
		Return (_flags & TVTPersonFlag.CASTABLE) > 0
	End Method

	
	Method IsBookable:Int()
		Return (_flags & TVTPersonFlag.BOOKABLE) > 0
	End Method


	Method CanLevelUp:Int()
		Return (_flags & TVTPersonFlag.CAN_LEVEL_UP) > 0
	End Method

	
	Method IsFictional:Int()
		Return (_flags & TVTPersonFlag.FICTIONAL) > 0
	End Method


	Method IsPolitician:Int()
		Return (_jobs & TVTPersonJob.POLITICIAN) > 0
	End Method


	Method IsMusician:Int()
		Return (_jobs & TVTPersonJob.MUSICIAN) > 0
	End Method


	Method IsPainter:Int()
		Return (_jobs & TVTPersonJob.PAINTER) > 0
	End Method


	Method IsWriter:Int()
		Return (_jobs & TVTPersonJob.WRITER) > 0
	End Method


	Method IsArtist:Int()
		Return (_jobs & TVTPersonJob.MUSICIAN | TVTPersonJob.PAINTER | TVTPersonJob.WRITER) > 0
	End Method


	Method IsModel:Int()
		Return (_jobs & TVTPersonJob.MODEL) > 0
	End Method


	Method IsSportsman:Int()
		Return (_jobs & TVTPersonJob.SPORTSMAN) > 0
	End Method


	Method IsAdult:Int()
		Return GetAge() >= 18
	End Method




	'Custom production helpers 
	
	Method StartProduction:Int(programmeDataID:Int)
		If GetProductionData()
			_productionData.StartProduction(programmeDataID)
		EndIf

		'emit event so eg. news agency could react to it ("bla has a new job")
		'-> or to set them on the "scandals" list
		EventManager.triggerEvent(TEventSimple.Create("personbase.onStartProduction", New TData.addNumber("programmeDataID", programmeDataID), Self))
	End Method


	Method FinishProduction:Int(programmeDataID:Int, job:Int)
		If GetProductionData()
			_productionData.FinishProduction(programmeDataID, job)
		EndIf

		'emit event so eg. news agency could react to it ("bla goes on holiday")
		EventManager.triggerEvent(TEventSimple.Create("personbase.onFinishProduction", New TData.addNumber("programmeDataID", programmeDataID), Self))
	End Method
	


	
	' Custom data getters / setters
	
	Method SetPersonalityData:Int(data:TPersonPersonalityBaseData)
		_personalityData = data
		AddData(dataKeyPersonality, data)

		Return True
	End Method


	Method SetProductionData:Int(data:TPersonProductionBaseData)
		_productionData = data
		
		AddData(dataKeyProduction, data)

		Return True
	End Method

	
	Method HasCustomPersonality:Int()
		If GetPersonalityData() = TPersonPersonalityBaseData.stub Then Return False
		Return GetPersonalityData() <> Null
	End Method


	Method GetPersonalityData:TPersonPersonalityBaseData()
		If Not _personalityData And data Then _personalityData = TPersonPersonalityBaseData(data.ValueForKey(dataKeyPersonality))
		'return a basic personality all "insignificant" can share
		'it is there to keep "base" from the real implementation
		'ATTENTION: the last assigned person is stored in the stub!
		If Not _personalityData Then Return TPersonPersonalityBaseData.GetStub()

		Return _personalityData
	End Method


	Method GetProductionData:TPersonProductionBaseData()
		If Not _productionData And data Then _productionData = TPersonProductionBaseData(data.ValueForKey(dataKeyProduction))
		Return _productionData
	End Method


	Method GetData:TPersonBaseData(key:String)
		If data Then Return TPersonBaseData(data.ValueForKey(key))
		Return Null
	End Method
	
	
	Method AddData:Int(key:String, d:TPersonBaseData)
		If Not data Then data = New TMap

		d.personID = Self.GetID()
		data.Insert(key, d)
	End Method
	
	
	


	'=== SORT FUNCTIONS ===
	Method Compare:int(other:object)
		Return CompareByName(other)
	End Method


	Method CompareByName:int(other:object)
		Local p2:TPersonBase = TPersonBase(other)
		If Not p2 Then Return 1

		if GetFullName().ToLower() = p2.GetFullName().ToLower()
			'publishtime is NOT happened time
			return GetID() > p2.GetID()
		elseif GetFullName().ToLower() > p2.GetFullName().ToLower()
			return 1
		endif
		return -1
	End Method


	Function SortByName:Int(o1:Object, o2:Object)
		if not TPersonBase(o1) Then Return -1
		return TPersonBase(o1).CompareByName(o2)
	End Function
End Type




'base for politicians, musicians, ...
Type TPersonBaseData
	Field personID:Int
	Field _person:TPersonBase {nosave}
	
	Method GetPerson:TPersonBase()
		If Not _person Then _person = GetPersonBase(personID)
		Return _person
	End Method
	
	'can be called by life simulation
	Method Update:Int()
	End Method
End Type




Type TPersonPersonalityAttribute
	Field value:Float = 0.0
	Field minValue:Float = 0.0
	Field maxValue:Float = 1.0
	
	Method New(value:Float, minValue:Float = 0.0, maxValue:Float = 1.0)
		Initialize(value, minValue, maxValue)
	End Method


	Method Initialize:TPersonPersonalityAttribute(value:Float, minValue:Float, maxValue:Float)
		self.value = value
		self.minValue = minValue
		self.maxValue = maxValue
		
		Return self
	End Method
	
	
	Method Copy:TPersonPersonalityAttribute()
		Return New TPersonPersonalityAttribute.Initialize(value, minValue, maxValue)
	End Method
	

	Method Reset:TPersonPersonalityAttribute()
		value = 0
		minValue = 0
		maxValue = 1.0
		Return Self
	End Method


	Method SetRandomMin:TPersonPersonalityAttribute(minimum:Float, maximum:Float, bias:Float=0.5)
		self.minValue = 0.01 * BiasedRandRange(Int(100 * minimum), Int(100 * maximum), bias)
		Return self
	End Method


	Method SetRandomMax:TPersonPersonalityAttribute(minimum:Float, maximum:Float, bias:Float=0.5)
		self.maxValue = 0.01 * BiasedRandRange(Int(100 * minimum), Int(100 * maximum), bias)
		Return self
	End Method


	Method SetRandom:TPersonPersonalityAttribute(bias:Float=0.5)
		self.value = 0.01 * BiasedRandRange(Int(100 * minValue), Int(100 * maxValue), bias)
		Return self
	End Method


	Method SetMin:TPersonPersonalityAttribute(minimum:Float)
		self.minValue = minimum
		Return self
	End Method


	Method SetMax:TPersonPersonalityAttribute(maximum:Float)
		self.maxValue = maximum
		Return self
	End Method


	Method GetMin:Float()
		Return minValue
	End Method


	Method GetMax:Float()
		Return maxValue
	End Method
	
	
	Method Get:Float()
		Return value
	End Method
	
	
	Method Set:TPersonPersonalityAttribute(value:Float, ignoreLimits:Int = False)
		if not ignoreLimits
			self.value = Float(Min( Max(minValue, value), maxValue))
		Else
			self.value = value
		EndIf
		Return Self
	End Method
	
	
	Method Multiply:TPersonPersonalityAttribute(multiplier:Float)
		value = Min( Max(minValue, value * multiplier), maxValue )
		Return Self
	End Method


	Method Add:TPersonPersonalityAttribute(summand:Float)
		value = Min( Max(minValue, value + summand), maxValue )
		Return Self
	End Method


	Method SerializeTPersonPersonalityAttributeToString:string()
		return value + " " + minValue + " " + maxValue
	End Method


	Method DeSerializeTPersonPersonalityAttributeFromString(text:String)
		local vars:string[] = text.split(" ")
		if vars.length > 0 then value = Float(vars[0])
		if vars.length > 1 then minValue = Float(vars[1])
		if vars.length > 2 then maxValue = Float(vars[2])
	End Method
End Type




Type TPersonPersonalityAttributes
	'core attributes (ignoring job, genre ...)
	Field attributes:TPersonPersonalityAttribute[]
	'individual attributes (for attribute-job-genre combinations)
	Field individualAttributes:TLongMap

rem
	SKILL:
		income +, reviews +++, bonus in some genres (drama!)
	    directors, musicians: how good is he doing his "craftmanships"
	POWER:
		income +, speed +++, bonus in some genres (action)
	HUMOR:
		income +, speed +++, bonus in some genres (comedy)
	CHARISMA:
		income +, reviews ++, bonus in some genres (love, drama, comedy)
	APPEARANCE:
		income ++, speed +, bonus in some genres (erotic, love, action)
	FAME:
		income +++
		how famous is this person?
	SCANDALIZING:
		of interest for shows or special events / trigger for news / 0-1.0
endrem

	
	Method New()
		'"basic" attributes always have to exist 
		attributes = new TPersonPersonalityAttribute[ TVTPersonPersonalityAttribute.count ]
		For local i:int = 0 until attributes.length
			attributes[i] = new TPersonPersonalityAttribute(0, 0, 1.0)
		Next
	End Method
	
	
	Method Copy:TPersonPersonalityAttributes()
		local c:TPersonPersonalityAttributes = new TPersonPersonalityAttributes()
		if self.attributes
			c.attributes = new TPersonPersonalityAttribute[ self.attributes.length ]
			For local i:int = 0 until c.attributes.length
				c.attributes[i] = self.attributes[i].Copy()
			Next
		endif
		if self.individualAttributes
			'ensure we only create a map if not empty...
			'so check in the loop
			For local key:TLongKey = EachIn self.individualAttributes.Keys()
				if not c.individualAttributes then c.individualAttributes = new TLongMap
				
				local p:TPersonPersonalityAttribute = TPersonPersonalityAttribute(self.individualAttributes.ValueForKey(key.value))
				if p Then c.individualAttributes.Insert(key.value, p.Copy())
			Next
		endif
	End Method


	Method GetAttribute:TPersonPersonalityAttribute(attributeID:Int, jobID:Int = -1, genreID:Int = -1)
		if jobID = -1 and genreID = -1
			Return attributes[attributeID-1]
		else
			if individualAttributes 
				Local key:Long = _GetKey(attributeID, jobID, genreID)
				Return TPersonPersonalityAttribute( individualAttributes.ValueForKey(key) )
			EndIf
		endif
		Return Null
	End Method


	Method SetAttribute(attribute:TPersonPersonalityAttribute, attributeID:Int, jobID:Int = -1, genreID:Int = -1)
		if jobID = -1 and genreID = -1
			attributes[attributeID-1] = attribute
		else
			if not individualAttributes then individualAttributes = new TLongMap
			Local key:Long = _GetKey(attributeID, jobID, genreID)
			individualAttributes.Insert(key, attribute)
		endif
	End Method

	
	Method GetAttributeValue:Float(attributeID:Int, jobID:Int = -1, genreID:Int = -1)
		local a:TPersonPersonalityAttribute = GetAttribute(attributeID, jobID, genreID)
		If a
			Return a.Get()
		Else
			Return 0
		EndIf
	End Method

	
	Method SetAttributeValue(value:Float, attributeID:Int, jobID:Int = -1, genreID:Int = -1)
		if jobID = -1 and genreID = -1
			attributes[attributeID-1].Set(value)
		else
			if not individualAttributes then individualAttributes = new TLongMap

			Local key:Long = _GetKey(attributeID, jobID, genreID)
			Local attribute:TPersonPersonalityAttribute = TPersonPersonalityAttribute(individualAttributes.ValueForKey(key))
			If not attribute 
				attribute = new TPersonPersonalityAttribute
				SetAttribute(attribute, attributeID, jobID, genreID)
			EndIf
			
			attribute.Set(value)
		Endif
	End Method
	
	
	Method _GetKey:Long(attributeID:Int, jobID:Int, genreID:Int)
		'so key is now "long" - allowing for 64 bits to pack numbers
		'- attribute:  8 bit (0-255)    -- 4bit would be enough too)
		'- genre    : 12 bit (0-4095)   -- albeit we only use <999 for now)
		'- job      : 32 bit            -- up to 32 job flags)
		'- ? ... 12 bits left for other elements
		
		Return Long(attributeID) Shl 56 | Long(genreID) Shl 44 | Long(jobID) Shl 12

		'if there were no more jobs.. we could fit them into an integer
		'attributeID = 0-15 = 2^4 = 4 bit
		'genreID = 0 - 4096 = 2^12= 12 bit
		'jobID = 0 - 65335 = 2^16
		'Return (attributeID) Shl 28 | Long(genreID) Shl 16 | Long(jobID)
	End Method
	

	Method _UnpackKey(key:Long, attributeID:Int Var, jobID:Int Var, genreID:Int Var)
		'$F   =  4 bit
		'$FF  =  8 bit
		'$FFF = 12 bit
		'$FFFF= 16 bit ...
		'Print "attributeID: " + ((key Shr 56) & $FF)
		'Print "genreID:     " + ((key Shr 44) & $FFF)
		'Print "jobID:       " + ((key Shr 12) & $FFFFFF)

		attributeID = ((key Shr 56) & $FF)
		jobID       = ((key Shr 44) & $FFF)
		genreID     = ((key Shr 12) & $FFFFFF)
	End Method


	Method RandomizeAttribute(attributeID:Int, jobID:Int = -1, genreID:Int = -1)
		Local attribute:TPersonPersonalityAttribute = GetAttribute(attributeID, jobID, genreID)
		If not attribute 
			attribute = new TPersonPersonalityAttribute
			SetAttribute(attribute, attributeID, jobID, genreID)
		EndIf

		'for now base has the same initialization values than individual
		'attribute-job-genre combinations
		
		Select attributeID	
			Case TVTPersonPersonalityAttribute.SKILL
				attribute.SetRandomMin(0.05, 0.15).SetRandomMax(0.60, 0.85, 0.2).SetRandom(0.25)

			Case TVTPersonPersonalityAttribute.POWER
				attribute.SetRandomMin(0.05, 0.15).SetRandomMax(0.65, 0.90).SetRandom(0.35)
				
			Case TVTPersonPersonalityAttribute.HUMOR
				attribute.SetRandomMin(0.05, 0.15).SetRandomMax(0.70, 0.90, 0.2).SetRandom(0.35)
		
			Case TVTPersonPersonalityAttribute.CHARISMA
				attribute.SetRandomMin(0.05, 0.15).SetRandomMax(0.60, 0.90, 0.1).SetRandom(0.30)

			'given at birth (or by a doctor :-))
			Case TVTPersonPersonalityAttribute.APPEARANCE
				attribute.SetRandomMin(0.05, 0.15).SetRandomMax(0.65, 0.90, 0.2).SetRandom(0.35)

			
			'things which might change later on
			Case TVTPersonPersonalityAttribute.FAME
				'set a random value between 0 and 25
				attribute.SetRandomMin(0.00, 0.15, 0.2).SetMax(0.25).SetRandom(0.2).SetMax(0.75)
				'the beautiful tend to have more fame (poster boys and girls)
				attribute.Multiply(1 + 0.15 * GetAttributeValue(TVTPersonPersonalityAttribute.APPEARANCE))

			Case TVTPersonPersonalityAttribute.SCANDALIZING
				'set a random value between 0 and 25
				attribute.SetRandomMin(0,15, 0.2).SetMax(0.25).SetRandom(0.2).SetMax(0.75)
				'the beautiful tend to be more scandalizing (up to +10%)
				attribute.Multiply(1 + 0.10 * GetAttributeValue(TVTPersonPersonalityAttribute.APPEARANCE))
		End Select
	End Method


	Method RandomizeAttributes:Int(onlyEmpty:Int = False)
		'reset attributes, so they get all refilled
		If Not onlyEmpty
			For local i:int = 0 until attributes.length
				attributes[i].Reset()
			Next
		EndIf

		'base values
		If GetAttributeValue(TVTPersonPersonalityAttribute.SKILL) = 0 Then RandomizeAttribute(TVTPersonPersonalityAttribute.SKILL)
		If GetAttributeValue(TVTPersonPersonalityAttribute.POWER) = 0 Then RandomizeAttribute(TVTPersonPersonalityAttribute.POWER)
		If GetAttributeValue(TVTPersonPersonalityAttribute.HUMOR) = 0 Then RandomizeAttribute(TVTPersonPersonalityAttribute.HUMOR)
		If GetAttributeValue(TVTPersonPersonalityAttribute.CHARISMA) = 0 Then RandomizeAttribute(TVTPersonPersonalityAttribute.CHARISMA)
		If GetAttributeValue(TVTPersonPersonalityAttribute.APPEARANCE) = 0 Then RandomizeAttribute(TVTPersonPersonalityAttribute.APPEARANCE)
		'stuff changed later (depends on aboves attributes)
		If GetAttributeValue(TVTPersonPersonalityAttribute.FAME) = 0 Then RandomizeAttribute(TVTPersonPersonalityAttribute.FAME)
		If GetAttributeValue(TVTPersonPersonalityAttribute.SCANDALIZING) = 0 Then RandomizeAttribute(TVTPersonPersonalityAttribute.SCANDALIZING)
	End Method

End Type



Type TPersonPersonalityBaseData Extends TPersonBaseData
	Field dayOfBirth:String	= "0000-00-00"
	Field dayOfDeath:String	= "0000-00-00"
	
	Field attributes:TPersonPersonalityAttributes

	Field channelSympathy:Float[4]
	
	Global stub:TPersonPersonalityBaseData

	Global daysPerMonth:Int[] = [31,28,31,30,31,30,31,30,31,30,31,30,31]
	Global daysPerMonthLeap:Int[] = [31,29,31,30,31,30,31,30,31,30,31,30,31]


	Function GetStub:TPersonPersonalityBaseData()
		If Not stub
			stub = New TPersonPersonalityBaseData
		EndIf
		Return stub
	End Function
	
	
	Method InitAttributes()
		attributes = new TPersonPersonalityAttributes
		attributes.RandomizeAttributes()
	End Method


	Method GetAttributes:TPersonPersonalityAttributes(generateDefault:Int = True)
		if not attributes and generateDefault Then InitAttributes

		Return attributes
	End Method

	
	Method GetAttributeValue:Float(attributeID:Int, jobID:Int = -1, genreID:Int = -1, generateDefault:Int = True)
		if not attributes and generateDefault Then InitAttributes
		if not attributes Then Return 0
		
		Return attributes.GetAttributeValue(attributeID)
	End Method


	Method SetDayOfBirth:Int(date:String="")
		If date = ""
			date = "0000-00-00"
		Else
			Local parts:String[] = date.split("-")
			'feeding "0" will make it auto-correct (wrong length)
			If parts.length < 2 Then parts :+ ["0"]
			If parts.length < 3 Then parts :+ ["0"]
			date = "-".Join(parts)
		EndIf

		Self.dayOfBirth = date
	End Method


	Method SetDayOfDeath:Int(date:String="")
		If date = ""
			date = "0000-00-00"
		Else
			Local parts:String[] = date.split("-")
			If parts.length < 2 Then parts :+ ["0"]
			If parts.length < 3 Then parts :+ ["0"]
			date = "-".Join(parts)
		EndIf

		Self.dayOfDeath = date
	End Method


	Method GetEarliestProductionYear:Int()
		Return GetWorldTime().GetYear()
	End Method
	

	Method _FixDate:String(dateText:String = "", earliestYear:Int = -1, year:Int = -1, month:Int = -1, day:Int = -1)
		'required for "fixed randomness"
		if not GetPerson() then Return dateText
		
		if dateText
			local split:String[] = dateText.split("-")
			if year = -1 Then year = int(split[0])
			if month = -1 and split.length > 1 Then month = int(split[1])
			if day = -1 and split.length > 2 Then day = int(split[2])
			
			if year = 0 then year = -1
			if month = 0 then month = -1
			if day = 0 then day = -1
		endif

		'maybe first movie was done at age of 10 - 40
		'also avoid days 29,30,31 - not possible in all months
		'dayOfBirth = (earliestYear - RandRange(10,40))+"-"+RandRange(1,12)+"-"+RandRange(1,28)

		'do not use randomness - stay same each time
		Local fName:String = GetPerson().GetFullName()
		'hash might be negative - think positive now
		Local hash:Long = Abs(StringHelper.StringHash(fName))
		Rem
		If hash > 0
			For local i:int = 0 until fName.length
				hash :+ fName[i]
			Next
		EndIf
		endrem

		If year = -1 
			if earliestYear = -1 Then earliestYear = GetEarliestProductionYear()
			year = earliestYear - ((hash + 1) Mod 30 + 10 ) 'subtract 10-40 years
		EndIf
		If month = -1
			month = (hash + 5) Mod 12 + 1 '1 - 12
		EndIf
		If day = -1
			Local daysInMonth:Int
			If (year Mod 400 = 0) Or (year Mod 4 = 0 And year Mod 100 <> 0)
				daysInMonth = daysPerMonthLeap[month -1]
			Else
				daysInMonth = daysPerMonth[month -1]
			EndIf
			day = (hash + 7) Mod daysInMonth + 1
		EndIf
		
		local monthStr:String = month
		if month < 10 Then monthStr = "0" + monthStr
		local dayStr:String = day
		if day < 10 Then dayStr = "0" + dayStr

		Return year + "-" + monthStr + "-" + dayStr
	End Method


	Method GetAge:Int()
		Return 0
	End Method


	Method IsAlive:Int()
		Return IsBorn()
	End Method


	Method GetDOB:Long()
		Return 0
	End Method


	Method GetDOD:Long()
		Return 0
	End Method


	Method IsBorn:Int()
		Return True
	End Method

rem
	Method GetSkill:Float()
		Return skill
	End Method


	Method GetPower:Float()
		Return power
	End Method


	Method GetHumor:Float()
		Return humor
	End Method


	Method GetCharisma:Float()
		Return charisma
	End Method


	Method GetAppearance:Float()
		Return appearance
	End Method


	Method GetFame:Float()
		Return fame
	End Method


	Method GetScandalizing:Float()
		Return scandalizing
	End Method
endrem

	Method GetCountryCode:String()
		Return GetPerson().countryCode
	End Method


	Method GetCountry:String()
		If GetPerson().countryCode <> ""
			Return GetLocale("COUNTRY_CODE_" + GetPerson().countryCode)
		Else
			Return ""
		EndIf
	End Method


	Method GetCountryLong:String()
		If GetPerson().countryCode <> ""
			Return GetLocale("COUNTRY_NAME_" + GetPerson().countryCode)
		Else
			Return ""
		EndIf
	End Method


	Method GetPopularity:TPopularity()
		Return Null
	End Method
	
	
	Method GetPopularityValue:Float()
		If GetPopularity() Then Return GetPopularity().Popularity
		Return 0.0
	End Method


	Method SetChannelSympathy:Int(channel:Int, newSympathy:Float)
		Return False
	End Method


	Method GetChannelSympathy:Float(channel:Int)
		Return 0.0
	End Method


	Method GetFigureImage:Object()
		Return Null
	End Method
End Type



'for insignificant actors/directors/...
Type TPersonProductionBaseData Extends TPersonBaseData
	'indicator for potential "upgrades" to become a celebrity
	'index 0 contains "total", others the genre count
	Field jobsDone:Int[]
	'is the person currently filming something?
	Field producingIDs:Int[]

	'price manipulation. varying price but constant "quality"
	Field priceModifier:Float = 1.0

	Global stub:TPersonProductionBaseData


	Function GetStub:TPersonProductionBaseData()
		If Not stub
			stub = New TPersonProductionBaseData
		EndIf
		Return stub
	End Function


	Method New()
		jobsDone = New Int[TVTPersonJob.castCount + 1]
		producingIDs = New Int[0]
	End Method


	Method SetRandomAttributes:Int(onlyEmpty:Int=False)
		'reset attributes, so they get all refilled
		If Not onlyEmpty
			priceModifier = 0
		EndIf

		If priceModifier = 0 Then priceModifier = 0.85 + 0.3*(RandRange(0,100) / 100.0)
	End Method


	Method GetTopGenre:Int()
		'base persons does not have top genres (-> unspecified)
		Return TVTProgrammeGenre.undefined
	End Method


	Method GetProducedGenreCount:Int(genre:Int)
		Return 0
	End Method


	Method GetProductionJobsDone:Int(job:Int)
		'total count?
		If job <= 0
			Return Self.jobsDone[0]
		Else
			Local jobIndex:Int = TVTPersonJob.GetIndex(job)
			If jobIndex = 0 And job <> 0
				TLogger.Log("GetProductionJobsDone()", "unsupported job-param.", LOG_ERROR)
				Return 0
			EndIf

			Return Self.jobsDone[jobIndex]
		EndIf
	End Method


	Method GetBaseFee:Int(jobID:Int, blocks:Int, channel:Int=-1)
		'1 = 1, 2 = 1.75, 3 = 2.5, 4 = 3.25, 5 = 4 ...
		Local blocksMod:Float = 0.25 + blocks * 0.75
		Local baseFee:Int

		Select jobID
			Case TVTPersonJob.ACTOR
				baseFee = 7000
			Case TVTPersonJob.SUPPORTINGACTOR
				baseFee = 3000
			Case TVTPersonJob.HOST
				baseFee = 2500
			Case TVTPersonJob.DIRECTOR
				baseFee = 6000
			Case TVTPersonJob.SCRIPTWRITER
				baseFee = 3000
			Case TVTPersonJob.MUSICIAN
				baseFee = 3500
			Case TVTPersonJob.REPORTER
				baseFee = 2500
			Case TVTPersonJob.GUEST
				baseFee = 1000
			Default
				baseFee = 1000
		End Select

		Return TFunctions.RoundToBeautifulValue(baseFee * blocksMod)
	End Method


	Method GetJobExperiencePercentage:Float(job:Int)
		Return 0
	End Method


	Method GetEffectiveJobExperiencePercentage:Float(job:Int)
		Return 0
	End Method


	Method GetProducedProgrammeIDs:Int[]()
		Return New Int[0]
	End Method


	Method IsProducing:Int(programmeDataID:Int)
		For Local ID:Int = EachIn producingIDs
			If ID = programmeDataID Then Return True
		Next
		Return False
	End Method


	Method StartProduction:Int(programmeDataID:Int)
		If Not IsProducing(programmeDataID)
			producingIDs :+ [programmeDataID]
		EndIf
	End Method


	Method FinishProduction:Int(programmeDataID:Int, job:Int)
		jobsDone[0] :+ 1
		For Local jobIndex:Int = 1 To TVTPersonJob.count
			If (job & TVTPersonJob.GetAtIndex(jobIndex)) > 0
				jobsDone[jobIndex] :+ 1
			EndIf
		Next

		Local newProducingIDs:Int[]
		For Local ID:Int = EachIn producingIDs
			If ID = programmeDataID Then Continue
			newProducingIDs :+ [ID]
		Next
		producingIDs = newProducingIDs
	End Method	
End Type



'role/function a person had in a movie/series
Type TPersonProductionJob
	'the person having done this job
	Field personID:Int

	'job is a bitmask for values defined in TVTPersonJob
	Field job:Int = 0
	'maybe only female directors are allowed?
	Field gender:Int = 0
	'allows limiting the job to specific heritages
	Field country:String = ""

	'only valid for actors
	Field roleID:Int = 0
	
	
	Method Init:TPersonProductionJob(personID:Int, job:Int, gender:Int=0, country:String="", roleID:Int=0)
		Self.personID = personID
		Self.job = job
		Self.gender = gender
		Self.country = country

		Self.roleID = roleID

		Return Self
	End Method


	Method SerializeTPersonProductionJobToString:String()
		Return personID + "::" +..
		       job + "::" +..
		       gender + "::" +..
		       StringHelper.EscapeString(country, ":") + "::" + ..
		       roleID
	End Method


	Method DeSerializeTPersonProductionJobFromString(text:String)
		Local vars:String[] = text.split("::")
		If vars.length > 0 Then personID = Int(vars[0])
		If vars.length > 1 Then job = Int(vars[1])
		If vars.length > 2 Then gender = Int(vars[2])
		If vars.length > 3 Then country = StringHelper.UnEscapeString(vars[3])
		If vars.length > 4 Then roleID = Int(vars[4])
	End Method


	Method IsSimilar:Int(otherJob:TPersonProductionJob)
		If job <> otherJob.job Then Return False
		If personID <> otherJob.personID Then Return False
		If roleID <> otherJob.roleID Then Return False
		If gender <> otherJob.gender Then Return False
		If country <> otherJob.country Then Return False
		Return True
	End Method
End Type