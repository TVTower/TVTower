SuperStrict
Import "Dig/base.util.logger.bmx"
Import "game.broadcast.audience.bmx"
Import "game.modifier.base.bmx"


Type TPublicImageCollection
	Field entries:TPublicImage[]
	Global _instance:TPublicImageCollection


	Function GetInstance:TPublicImageCollection()
		if not _instance then _instance = new TPublicImageCollection
		return _instance
	End Function


	Method Initialize:int()
		entries = new TPublicImage[0]
	End Method


	Method Set:int(playerID:int, image:TPublicImage)
		if playerID <= 0 then return False
		if playerID > entries.length then entries = entries[.. playerID]
		entries[playerID-1] = image
	End Method


	Method Get:TPublicImage(playerID:int)
		if playerID <= 0 or playerID > entries.length then return null
		return entries[playerID-1]
	End Method


	'returns the average publicimage of all players
	Method GetAverage:TPublicImage()
		local avgImage:TPublicImage = new TPublicImage
		local players:int = 0
		avgImage.playerID = -1
		avgImage.ImageValues = new TAudience
		For local i:int = 1 to 4
			if Get(i)
				avgImage.ImageValues.Add(Get(i).ImageValues)
				players :+ 1
			endif
		Next
		if players > 0 then avgImage.ImageValues.DivideFloat(players)
		return avgImage
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetPublicImageCollection:TPublicImageCollection()
	Return TPublicImageCollection.GetInstance()
End Function


Function GetPublicImage:TPublicImage(playerID:int)
	Return TPublicImageCollection.GetInstance().Get(playerID)
End Function




Type TPublicImage {_exposeToLua="selected"}
	Field playerID:int
	'image is audience (id + audienceBase + genderDistribution)
	Field ImageValues:TAudience

	Function Create:TPublicImage(playerID:int)
		Local obj:TPublicImage = New TPublicImage
		obj.playerID = playerID

		'we start with an image of 0 in all target groups
		obj.ImageValues = new TAudience.InitValue(0, 0)
		'add to collection
		GetPublicImageCollection().Set(playerID, obj)
		Return obj
	End Function


	Method GetAttractionMods:TAudience()
		'a mod is a modifier - so "1.0" does modify nothing, "2.0" doubles
		'and "0.5" cuts into halves
		'our image ranges between 0 and 100 so dividing by 100 results
		'in a value of 0-1.0, adding 1.0 makes it a modifier
		'ex: teenager-image of "2": 2/100 + 1.0 = 1.02
		Return ImageValues.Copy().DivideFloat(100).AddFloat(1)
	End Method


	'returns the average image of all target groups
	'ATTENTION: return weighted average as some target groups consist
	'           of less people than other groups)
	Method GetAverageImage:Float()
		return ImageValues.GetWeightedAverage()
	End Method


	Method ChangeImageRelative(imageChange:TAudience)
		if not imageChange
			TLogger.Log("ChangePublicImageRelative()", "Change player" + playerID + "'s public image failed: no parameter given.", LOG_ERROR)
			return
		endif

		'skip changing if there is nothing to change
		if imageChange.GetTotalAbsSum() = 0 then return

		ImageValues.Multiply( new TAudience.InitValue(1.0, 1.0).Add(imageChange) )
		'avoid negative values -> cut to at least 0
		'also avoid values > 100
		ImageValues.CutMinimumFloat(0).CutMaximumFloat(100)
		
		TLogger.Log("ChangePublicImageRelative()", "Change player" + playerID + "'s public image: " + imageChange.ToString(), LOG_DEBUG)
	End Method
	

	Method ChangeImage(imageChange:TAudience)
		if not imageChange
			TLogger.Log("ChangePublicImage()", "Change player" + playerID + "'s public image failed: no parameter given.", LOG_ERROR)
			return
		endif

		'skip changing if there is nothing to change
		if imageChange.GetTotalAbsSum() = 0 then return

		ImageValues.Add(imageChange)
		'avoid negative values -> cut to at least 0
		'also avoid values > 100
		ImageValues.CutMinimumFloat(0).CutMaximumFloat(100)
		
		TLogger.Log("ChangePublicImage()", "Change player" + playerID + "'s public image: " + imageChange.ToString(), LOG_DEBUG)
	End Method


	'adjust given channelImageChanges by giving the best audience
	'positive image "portions" and the worse ones negative "portions"
	Function ChangeForTargetGroup(channelImageChanges:TAudience[], channelAudiencesList:TList, targetGroup:Int, weightModifier:Float = 1.0)
		'sort channel audiences for the given targetgroup
		'biggest amount on top
		Select targetGroup
			case TVTTargetGroup.CHILDREN
				channelAudiencesList.Sort(False, TAudience.ChildrenSort)
			case TVTTargetGroup.TEENAGERS
				channelAudiencesList.Sort(False, TAudience.TeenagersSort)
			case TVTTargetGroup.HOUSEWIVES
				channelAudiencesList.Sort(False, TAudience.HousewivesSort)
			case TVTTargetGroup.EMPLOYEES
				channelAudiencesList.Sort(False, TAudience.EmployeesSort)
			case TVTTargetGroup.UNEMPLOYED
				channelAudiencesList.Sort(False, TAudience.UnemployedSort)
			case TVTTargetGroup.MANAGER
				channelAudiencesList.Sort(False, TAudience.ManagerSort)
			case TVTTargetGroup.PENSIONERS
				channelAudiencesList.Sort(False, TAudience.PensionersSort)
			default
				throw "ChangeForTargetGroup: unknown targetgroup ~q"+targetGroup+"~q."
		End Select 

		'RONNY:
		'instead of subtracting won image from other players ("sum stays constant")
		'we subtract only a portion from others - so every broadcast should be a
		'potential gain to the image of each player.
		'BUT ... there should be situations in which image gets lost (broadcasting
		'outtage, sending Xrated before 22:00, sending infomercials ...)

		'we also have to take care to not subtract image for place 2 if
		'the audience is the same as for place 1
		'-> give points for each "PLACE" not "INDEX" of the list
		local differentAudienceNumbers:int = 0
		local lastNumber:int = 0
		local audienceIndex:int = 0
		local audienceRank:int[] = new Int[channelAudiencesList.Count()]
		for local a:TAudience = EachIn channelAudiencesList
			local currentNumber:int = a.GetTotalValue(targetGroup)

			'nothing set yet or worse than before, increase rank
			if currentNumber < lastNumber or audienceIndex = 0
				differentAudienceNumbers :+ 1
				lastNumber = currentNumber
			endif

			audienceRank[audienceIndex] = differentAudienceNumbers
			'print "player #"+(audienceIndex+1)+":  audience="+currentNumber+"  rank="+differentAudienceNumbers

			audienceIndex :+ 1
		next

		local modifiers:float[]
		If (differentAudienceNumbers = 4) then modifiers = [0.7, 0.4, 0.1, -0.2]
		If (differentAudienceNumbers = 3) then modifiers = [0.7, 0.3, -0.2]
		If (differentAudienceNumbers = 2) then modifiers = [0.75, -0.2]
		'no winner, no change
		If (differentAudienceNumbers <= 1) then modifiers = [0.0]

		'print "ranks: "+ audienceRank[0]+", "+ audienceRank[1]+", "+ audienceRank[2]+", "+ audienceRank[3]
		for local i:int = 0 until channelAudiencesList.Count()
			local channelID:int = TAudience(channelAudiencesList.ValueAtIndex(i)).Id
			if channelID <= 0 then continue 

			local modifier:Float = 0.0
			if audienceRank[i] <= modifiers.length then modifier = modifiers[ audienceRank[i]-1 ]

			if modifier <> 0.0 then channelImageChanges[ channelID-1 ].SetTotalValue(targetGroup, modifier * weightModifier)
		Next
	End Function
End Type




Type TGameModifierPublicImage_Modify extends TGameModifierBase
	Field playerID:Int = 0
	Field value:TAudience
	Field valueIsRelative:int = False
	Field conditions:TData
	Field logText:string


	Function CreateNewInstance:TGameModifierPublicImage_Modify()
		return new TGameModifierPublicImage_Modify
	End Function


	Method Init:TGameModifierPublicImage_Modify(data:TData, index:string="")
		if not data then return null

		local valueSimple:Float = data.GetFloat("value", 0)
		local valueMale:Float = data.GetFloat("valueMale", 0)
		local valueFemale:Float = data.GetFloat("valueFemale", 0)
		local valueComplexBase:TAudienceBase = TAudienceBase(data.Get("value", null))
		local valueComplex:TAudience = TAudience(data.Get("value", null))

		if valueComplex
			value = valueComplex.Copy()
		elseif valueComplexBase
			value = new TAudience.InitBase(valueComplexBase, valueComplexBase)
		elseif valueMale <> 0 or valueFemale <> 0
			value = new TAudience.InitValue(valueMale, valueFemale)
		elseif valueSimple <> 0.0
			value = new TAudience.InitValue(valueSimple, valueSimple)
		endif
		if not value
			TLogger.Log("TGameModifierPublicImage_Modify.Init()", "No valid ~qvalue~q-value provided. Modifier not created.", LOG_DEBUG)
			return null
		Endif

		valueIsRelative = data.GetBool("valueIsRelative", False)
		playerID = data.GetInt("playerID", 0)
		conditions = data.GetData("conditions", null)
		logText = data.GetString("log", "")

		return self
	End Method


	Method SatisfiesConditions:int(params:TData)
		if not conditions then return True

		local broadcastingPlayerID:int = params.GetInt("playerID", 0)

		'broadcaster specific conditions
		if broadcastingPlayerID > 0
			local playerIDs:string = conditions.GetString("broadcaster_inPlayerIDs", "")
			if playerIDs <> ""
				if not StringHelper.InArray(string(broadcastingPlayerID), playerIDs.Replace(" ", "").split(","))
					return False
				endif
			endif 

			local notPlayerIDs:string = conditions.GetString("broadcaster_notInPlayerIDs", "")
			if notPlayerIDs <> ""
				if StringHelper.InArray(string(broadcastingPlayerID), notPlayerIDs.Replace(" ", "").split(","))
					return False
				endif
			endif
		endif

		return True
	End Method


	'override to trigger a specific news
	Method RunFunc:int(params:TData)
		local targetPlayerID:int = playerID
		if playerID = 0 then targetPlayerID = params.GetInt("playerID", 0)

		local publicImage:TPublicImage = GetPublicImage(targetPlayerID)
		if not publicImage
			TLogger.Log("TGameModifierPublicImage_Modify.Run()", "Failed, public image for channel ~q"+targetPlayerID+"~q not found.", LOG_ERROR)
			return False
		endif
		if not value
			TLogger.Log("TGameModifierPublicImage_Modify.Run()", "Failed, invalid value set.", LOG_ERROR)
			return False
		endif

		if logText then TLogger.Log("TGameModifierPublicImage_Modify.Run()", logText, LOG_DEBUG)

		if valueIsRelative
			publicImage.ChangeImageRelative( value )
		else
			publicImage.ChangeImage( value )
		endif
		return True
	End Method
End Type
	

GameModifierCreator.RegisterModifier("ModifyChannelPublicImage", new TGameModifierPublicImage_Modify)