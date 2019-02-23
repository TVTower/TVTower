SuperStrict
Import "Dig/base.util.logger.bmx"
Import "game.broadcast.audience.bmx"
Import "game.modifier.base.bmx"


Type TPublicImageCollection
	Field entries:TPublicImage[]
	'these entries only contain "channel"
	Field archivedImages:TPublicImageArchive[]
	'these entries contain "channel" + "for all"
	Field archivedImagesGlobal:TPublicImageArchive[]
	Global _instance:TPublicImageCollection
	Global archiveLimit:Int = 50


	Function GetInstance:TPublicImageCollection()
		If Not _instance Then _instance = New TPublicImageCollection
		Return _instance
	End Function


	Method Initialize:Int()
		entries = New TPublicImage[0]
	End Method


	Method Set:Int(playerID:Int, image:TPublicImage)
		If playerID <= 0 Then Return False
		If playerID > entries.length Then entries = entries[.. playerID]
		entries[playerID-1] = image
	End Method


	Method Get:TPublicImage(playerID:Int)
		If playerID <= 0 Or playerID > entries.length Then Return Null
		Return entries[playerID-1]
	End Method


	'returns the average publicimage of all players
	Method GetAverage:TPublicImage()
		Local avgImage:TPublicImage = New TPublicImage
		Local players:Int = 0
		avgImage.playerID = -1
		avgImage.ImageValues = New TAudience
		For Local i:Int = 1 To 4
			If Get(i)
				avgImage.ImageValues.Add(Get(i).ImageValues)
				players :+ 1
			EndIf
		Next
		If players > 0 Then avgImage.ImageValues.DivideFloat(players)
		Return avgImage
	End Method


	Method GetChannelExclusiveImageValues:TAudience(owningChannelID:Int, forChannelID:Int, archivedBefore:Int = 0, returnFirstPossible:Int = True)
		Local selectedImageValues:TAudience

		If archivedBefore = 0
			selectedImageValues = GetPublicImage(forChannelID).imageValues
		Else
			If owningChannelID >= 0 And owningChannelID < archivedImages.length
				Local archive:TPublicImageArchive = archivedImages[owningChannelID]
				If archive
					selectedImageValues = archive.Get(archivedBefore, returnFirstPossible).GetImage(forChannelID)
				EndIf
			EndIf

			'nothing archived yet
			If Not selectedImageValues
				selectedImageValues = New TAudience
				selectedImageValues.InitValue(0, 0)
			EndIf
		EndIf
		Return selectedImageValues
	End Method


	'returns image values acquired by channel itself - or by global events
	Method GetImageValues:TAudience(owningChannelID:Int, forChannelID:Int, archivedBefore:Int = 0, returnFirstPossible:Int = True)
		Local selectedImageValues:TAudience

		If archivedBefore = 0
'			Print "get current -- archivedBefore="+archivedBefore + "  object="+GetPublicImage(forChannelID).imageValues.ToString()
			selectedImageValues = GetPublicImage(forChannelID).imageValues
		Else
			If owningChannelID > 0 And owningChannelID <= archivedImagesGlobal.length
				Local archive:TPublicImageArchive = archivedImagesGlobal[owningChannelID]
				If archive
					Local test:TAudience = GetPublicImage(forChannelID).imageValues
					Local testarchive:TPublicImageArchiveEntry = archive.Get(archivedBefore, returnFirstPossible)
					Local test2:TAudience = archive.Get(archivedBefore, returnFirstPossible).images[0].ImageValues
'					Print "get archived -- archivedBefore="+archivedBefore + "  object="+archive.Get(archivedBefore, returnFirstPossible).GetImage(forChannelID).ToString()
					selectedImageValues = archive.Get(archivedBefore, returnFirstPossible).GetImage(forChannelID)
'DebugStop
				EndIf
			EndIf

			'nothing archived yet
			If Not selectedImageValues
				selectedImageValues = New TAudience
				selectedImageValues.InitValue(0, 0)
			EndIf
		EndIf
		Return selectedImageValues
	End Method


	'archive images in the name of the given channel
	'each archive still contains image data for al channels, the owner-
	'ship is of interest for access by the players
	Method ArchiveImages(channelID:Int = 0)
		If Not archivedImages Then archivedImages = New TPublicImageArchive[4 + 1] 'players + "all"
		If Not archivedImagesGlobal Then archivedImagesGlobal = New TPublicImageArchive[4] 'players
		channelID = Max(0, channelID)

		If Not archivedImages[channelID] Then archivedImages[channelID] = New TPublicImageArchive
		'archive for this channel (or all if channelID = 0)
		Local latest:TPublicImageArchiveEntry = archivedImages[channelID].AddCurrentImage()

		'for all? store for each channel too
		If channelID = 0
			For Local cID:Int = 0 Until archivedImagesGlobal.length
				If Not archivedImagesGlobal[cID] Then archivedImagesGlobal[cID] = New TPublicImageArchive
				'add a reference to each channels array of images
				archivedImagesGlobal[cID].Add( latest )
			Next
		EndIf

		For Local i:Int = 0 Until 5
			If i = 0 And archivedImages[i]
				Print "ArchiveImage count: ["+i+"]=" + archivedImages[i].entries.length
			ElseIf i > 0 And archivedImages[i] And archivedImagesGlobal[i-1]
				Print "ArchiveImage count: ["+i+"]=" + archivedImages[i].entries.length +"  global="+archivedImagesGlobal[i-1].entries.length
			EndIf
		Next
'		For local img:TPublicImage = eachIn entries
'			img.ArchiveImageValues()
'		Next
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
Function GetPublicImageCollection:TPublicImageCollection()
	Return TPublicImageCollection.GetInstance()
End Function


Function GetPublicImage:TPublicImage(playerID:Int)
	Return TPublicImageCollection.GetInstance().Get(playerID)
End Function



'collection of archive entries
Type TPublicImageArchive
	Field entries:TPublicImageArchiveEntry[]
	Field entriesLimit:Int = 100


	Method Add:Int(entry:TPublicImageArchiveEntry)
		If Not entries
			entries = [ entry ]
		ElseIf entriesLimit > 0 And entries.length >= entriesLimit + 1
			entries = [ entry ] + entries[.. entriesLimit-1]
		Else
			entries = [ entry ] + entries
		EndIf
		Return True
	End Method


	Method AddCurrentImage:TPublicImageArchiveEntry()
		Add( New TPublicImageArchiveEntry.Init() )
		Return entries[ entries.length - 1]
	End Method


	'convenience function instead of
	Method GetImageValues:TAudience(channelID:Int, archivedBefore:Int = 0, returnFirstPossible:Int = True)
		If entries And (returnFirstPossible Or entries.length >= archivedBefore)
			Return entries[Min(archivedBefore, entries.length) - 1].GetImage(channelID)
		EndIf
	End Method


	'returns the entry itself
	Method Get:TPublicImageArchiveEntry(archivedBefore:Int = 0, returnFirstPossible:Int = True)
		If entries And (returnFirstPossible Or entries.length >= archivedBefore)
			Return entries[Min(archivedBefore, entries.length) - 1]
		EndIf
	End Method
End Type




'Storage of sympathies for all pressure groups regarding all channels
Type TPublicImageArchiveEntry
	'array containing public images of each target group for each channel
	Field images:TPublicImage[]
	'time of last change within all images
	Field time:Long


	Method Init:TPublicImageArchiveEntry()
		images = New TPublicImage[4]

		For Local i:Int = 0 Until images.length
			Local publicImage:TPublicImage = GetPublicImage(i+1)
			'create a copy (not referencing values)
			images[i] = New TPublicImage
			images[i].playerID = publicImage.playerID
			images[i].imageValues = New TAudience.CopyFrom( publicImage.imageValues )
			images[i].time = publicImage.time
			'store time of most current
			time = Max(time, images[i].time)
		Next

		Return Self
	End Method


	Method GetImage:TAudience(channelID:Int)
		If channelID <= 0 Or channelID > images.length Then Return Null

		Return images[channelID-1].imageValues
	End Method
End Type



Type TPublicImage {_exposeToLua="selected"}
	Field playerID:Int
	'image is audience (id + audienceBase + genderDistribution)
	Field ImageValues:TAudience
	'time of last change
	Field time:Long


	Function Create:TPublicImage(playerID:Int)
		Local obj:TPublicImage = New TPublicImage
		obj.playerID = playerID

		'we start with an image of 0 in all target groups
		obj.ImageValues = New TAudience.InitValue(0, 0)

		'add to collection
		GetPublicImageCollection().Set(playerID, obj)
		Return obj
	End Function


	Method GetImageValues:TAudience()
		Return imageValues
	End Method


	Method GetAttractionMods:TAudience()
		'a mod is a modifier - so "1.0" does modify nothing, "2.0" doubles
		'and "0.5" cuts into halves
		'our image ranges between 0 and 100 so dividing by 100 results
		'in a value of 0-1.0, adding 1.0 makes it a modifier
		'ex: teenager-image of "2": 2/100 + 1.0 = 1.02
		Return imageValues.Copy().DivideFloat(100).AddFloat(1)
	End Method


	'returns the average image of all target groups
	'ATTENTION: return weighted average as some target groups consist
	'           of less people than other groups)
	Method GetAverageImage:Float()
		Return imageValues.GetWeightedAverage()
	End Method


	Method ChangeImageRelative(imageChange:TAudience)
		If Not imageChange
			TLogger.Log("ChangePublicImageRelative()", "Change player" + playerID + "'s public image failed: no parameter given.", LOG_ERROR)
			Return
		EndIf

		'skip changing if there is nothing to change
		If imageChange.GetTotalAbsSum() = 0 Then Return

		ImageValues.Multiply( New TAudience.InitValue(1.0, 1.0).Add(imageChange) )
		'avoid negative values -> cut to at least 0
		'also avoid values > 100
		ImageValues.CutMinimumFloat(0).CutMaximumFloat(100)

		TLogger.Log("ChangePublicImageRelative()", "Change player" + playerID + "'s public image: " + imageChange.ToString(), LOG_DEBUG)
	End Method


	Method ChangeImage(imageChange:TAudience)
		If Not imageChange
			TLogger.Log("ChangePublicImage()", "Change player" + playerID + "'s public image failed: no parameter given.", LOG_ERROR)
			Return
		EndIf

		'skip changing if there is nothing to change
		If imageChange.GetTotalAbsSum() = 0 Then Return

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
			Case TVTTargetGroup.CHILDREN
				channelAudiencesList.Sort(False, TAudience.ChildrenSort)
			Case TVTTargetGroup.TEENAGERS
				channelAudiencesList.Sort(False, TAudience.TeenagersSort)
			Case TVTTargetGroup.HOUSEWIVES
				channelAudiencesList.Sort(False, TAudience.HousewivesSort)
			Case TVTTargetGroup.EMPLOYEES
				channelAudiencesList.Sort(False, TAudience.EmployeesSort)
			Case TVTTargetGroup.UNEMPLOYED
				channelAudiencesList.Sort(False, TAudience.UnemployedSort)
			Case TVTTargetGroup.MANAGER
				channelAudiencesList.Sort(False, TAudience.ManagerSort)
			Case TVTTargetGroup.PENSIONERS
				channelAudiencesList.Sort(False, TAudience.PensionersSort)
			Default
				Throw "ChangeForTargetGroup: unknown targetgroup ~q"+targetGroup+"~q."
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
		Local differentAudienceNumbers:Int = 0
		Local lastNumber:Int = 0
		Local audienceIndex:Int = 0
		Local audienceRank:Int[] = New Int[channelAudiencesList.Count()]
		For Local a:TAudience = EachIn channelAudiencesList
			Local currentNumber:Int = a.GetTotalValue(targetGroup)

			'nothing set yet or worse than before, increase rank
			If currentNumber < lastNumber Or audienceIndex = 0
				differentAudienceNumbers :+ 1
				lastNumber = currentNumber
			EndIf

			audienceRank[audienceIndex] = differentAudienceNumbers
			'print "player #"+(audienceIndex+1)+":  audience="+currentNumber+"  rank="+differentAudienceNumbers

			audienceIndex :+ 1
		Next

		Local modifiers:Float[]
		If (differentAudienceNumbers = 4) Then modifiers = [0.7, 0.4, 0.1, -0.2]
		If (differentAudienceNumbers = 3) Then modifiers = [0.7, 0.3, -0.2]
		If (differentAudienceNumbers = 2) Then modifiers = [0.75, -0.2]
		'no winner, no change
		If (differentAudienceNumbers <= 1) Then modifiers = [0.0]

		'print "ranks: "+ audienceRank[0]+", "+ audienceRank[1]+", "+ audienceRank[2]+", "+ audienceRank[3]
		For Local i:Int = 0 Until channelAudiencesList.Count()
			Local channelID:Int = TAudience(channelAudiencesList.ValueAtIndex(i)).Id
			If channelID <= 0 Then Continue

			Local modifier:Float = 0.0
			If audienceRank[i] <= modifiers.length Then modifier = modifiers[ audienceRank[i]-1 ]

			If modifier <> 0.0 Then channelImageChanges[ channelID-1 ].SetTotalValue(targetGroup, modifier * weightModifier)
		Next
	End Function
End Type




Type TGameModifierPublicImage_Modify Extends TGameModifierBase
	Field playerID:Int = 0
	Field value:TAudience
	Field valueIsRelative:Int = False
	Field paramConditions:TData
	Field logText:String


	Function CreateNewInstance:TGameModifierPublicImage_Modify()
		Return New TGameModifierPublicImage_Modify
	End Function


	Method Copy:TGameModifierPublicImage_Modify()
		Local clone:TGameModifierPublicImage_Modify = New TGameModifierPublicImage_Modify
		clone.CopyBaseFrom(Self)
		clone.playerID = Self.playerID
		clone.value = New TAudience.SetValuesFrom(value)
		clone.valueIsRelative = Self.valueIsRelative
		If Self.paramConditions
			clone.paramConditions = Self.paramConditions.copy()
		EndIf
		Return clone
	End Method


	Method Init:TGameModifierPublicImage_Modify(data:TData, extra:TData=Null)
		If Not data Then Return Null

		Local valueSimple:Float = data.GetFloat("value", 0)
		Local valueMale:Float = data.GetFloat("valueMale", 0)
		Local valueFemale:Float = data.GetFloat("valueFemale", 0)
		Local valueComplexBase:TAudienceBase = TAudienceBase(data.Get("value", Null))
		Local valueComplex:TAudience = TAudience(data.Get("value", Null))

		If valueComplex
			value = valueComplex.Copy()
		ElseIf valueComplexBase
			value = New TAudience.InitBase(valueComplexBase, valueComplexBase)
		ElseIf valueMale <> 0 Or valueFemale <> 0
			value = New TAudience.InitValue(valueMale, valueFemale)
		ElseIf valueSimple <> 0.0
			value = New TAudience.InitValue(valueSimple*0.5, valueSimple*0.5)
		EndIf
		If Not value
			TLogger.Log("TGameModifierPublicImage_Modify.Init()", "No valid ~qvalue~q-value provided. Modifier not created.", LOG_DEBUG)
			Return Null
		EndIf

		valueIsRelative = data.GetBool("valueIsRelative", False)
		playerID = data.GetInt("playerID", 0)
		paramConditions = data.GetData("conditions", Null)
		logText = data.GetString("log", "")

		Return Self
	End Method


	Method ParamConditionsFulfilled:Int(params:TData)
		If Not paramConditions Then Return True

		Local broadcastingPlayerID:Int = params.GetInt("playerID", 0)

		'broadcaster specific conditions
		If broadcastingPlayerID > 0
			Local playerIDs:String = paramConditions.GetString("broadcaster_inPlayerIDs", "")
			If playerIDs <> ""
				If Not StringHelper.InArray(String(broadcastingPlayerID), playerIDs.Replace(" ", "").split(","))
					Return False
				EndIf
			EndIf

			Local notPlayerIDs:String = paramConditions.GetString("broadcaster_notInPlayerIDs", "")
			If notPlayerIDs <> ""
				If StringHelper.InArray(String(broadcastingPlayerID), notPlayerIDs.Replace(" ", "").split(","))
					Return False
				EndIf
			EndIf
		EndIf

		Return True
	End Method


	Method Run:Int(params:TData)
		If Not ParamConditionsFulfilled(params) Then Return False

		Return Super.Run(params)
	End Method


	'override to trigger a specific news
	Method RunFunc:Int(params:TData)
		Local targetPlayerID:Int = playerID
		If playerID = 0 Then targetPlayerID = params.GetInt("playerID", 0)

		Local publicImage:TPublicImage = GetPublicImage(targetPlayerID)
		If Not publicImage
			TLogger.Log("TGameModifierPublicImage_Modify.Run()", "Failed, public image for channel ~q"+targetPlayerID+"~q not found.", LOG_ERROR)
			Return False
		EndIf
		If Not value
			TLogger.Log("TGameModifierPublicImage_Modify.Run()", "Failed, invalid value set.", LOG_ERROR)
			Return False
		EndIf

		If logText Then TLogger.Log("TGameModifierPublicImage_Modify.Run()", logText, LOG_DEBUG)

		If valueIsRelative
			publicImage.ChangeImageRelative( value )
		Else
			publicImage.ChangeImage( value )
		EndIf
		Return True
	End Method
End Type


GetGameModifierManager().RegisterCreateFunction("ModifyChannelPublicImage", TGameModifierPublicImage_Modify.CreateNewInstance)