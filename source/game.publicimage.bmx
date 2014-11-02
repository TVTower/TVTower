SuperStrict
Import "Dig/base.util.logger.bmx"
Import "game.broadcast.audience.bmx"

Type TPublicImageCollection
	Field entries:TPublicImage[]
	Global _instance:TPublicImageCollection


	Function GetInstance:TPublicImageCollection()
		if not _instance then _instance = new TPublicImageCollection
		return _instance
	End Function


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




Type TPublicImage {_exposeToLua="selected"}
	Field playerID:int
	Field ImageValues:TAudience

	Function Create:TPublicImage(playerID:int)
		Local obj:TPublicImage = New TPublicImage
		obj.playerID = playerID

		'we start with an image of 0 in all target groups
		obj.ImageValues = TAudience.CreateAndInit(0, 0, 0, 0, 0, 0, 0, 0, 0)
		'obj.ImageValues = TAudience.CreateAndInit(100, 100, 100, 100, 100, 100, 100, 100, 100)
		'add to collection
		GetPublicImageCollection().Set(playerID, obj)
		Return obj
	End Function


	Method GetAttractionMods:TAudience()
		'a mod is a modifier - so "1.0" does modify nothing, "2.0" doubles
		'and "0.5" halves
		'our image ranges between 0 and 100 so adding 100 results in
		'a value a bit bigger than 1.0
		'ex: teenager-image of "2": (2+100)/100 = 1.02 
		Return ImageValues.Copy().AddFloat(100).DivideFloat(100)
	End Method


	'returns the average image of all target groups
	Method GetAverageImage:Float()
		return ImageValues.GetAverage()
	End Method


	Method ChangeImage(imageChange:TAudience)
		if not imageChange
			print "ChangeImage(): imageChange missing !"
			end
		endif

		ImageValues.Add(imageChange)
		'avoid negative values -> cut to at least 0
		'also avoid values > 100
		ImageValues.CutMinimumFloat(0).CutMaximumFloat(100)
		
		TLogger.Log("ChangePublicImage()", "Change player '" + playerID + "' public image: " + imageChange.ToString(), LOG_DEBUG)
	End Method


	Function ChangeForTargetGroup(playerAudience:TMap, targetGroup:Int, attrList:TList, compareFunc( o1:Object,o2:Object )=CompareObjects)
		Local tempList:TList = attrList.Copy()
		SortList(tempList,False,compareFunc)
		'RONNY:
		'instead of subtracting won image from other players ("sum stays constant")
		'we subtract only a portion from others - so every broadcast should be a
		'potential gain to the image of each player.
		'BUT ... there should be situations in which image gets lost (broadcasting
		'outtage, sending Xrated before 22:00, sending infomercials ...)
		If (tempList.Count() = 4)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(0)).Id) )).SetValue(targetGroup, 0.7)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(1)).Id) )).SetValue(targetGroup, 0.4)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(2)).Id) )).SetValue(targetGroup, 0.1)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(3)).Id) )).SetValue(targetGroup, -0.2)
		Elseif (tempList.Count() = 3) Then
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(0)).Id) )).SetValue(targetGroup, 0.7)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(1)).Id) )).SetValue(targetGroup, 0.3)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(2)).Id) )).SetValue(targetGroup, -0.2)
		Elseif (tempList.Count() = 2) Then
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(0)).Id) )).SetValue(targetGroup, 0.75)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(1)).Id) )).SetValue(targetGroup, -0.2)
		EndIf

		rem
		old
		If (tempList.Count() = 4) Then
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(0)).Id) )).SetValue(targetGroup, 1)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(1)).Id) )).SetValue(targetGroup, 0.5)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(2)).Id) )).SetValue(targetGroup, -0.5)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(3)).Id) )).SetValue(targetGroup, -1)
		Elseif (tempList.Count() = 3) Then
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(0)).Id) )).SetValue(targetGroup, 1)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(1)).Id) )).SetValue(targetGroup, 0)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(2)).Id) )).SetValue(targetGroup, -1)
		Elseif (tempList.Count() = 2) Then
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(0)).Id) )).SetValue(targetGroup, 1)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(1)).Id) )).SetValue(targetGroup, -1)
		EndIf
		EndRem
	End Function
End Type
