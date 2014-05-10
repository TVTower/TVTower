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
		obj.ImageValues = TAudience.CreateAndInit(100, 100, 100, 100, 100, 100, 100, 100, 100)
		'add to collection
		GetPublicImageCollection().Set(playerID, obj)
		Return obj
	End Function


	Method GetAttractionMods:TAudience()
		Return ImageValues.Copy().DivideFloat(100)
	End Method


	Method ChangeImage(imageChange:TAudience)
		ImageValues.Add(imageChange)
		TLogger.Log("ChangePublicImage()", "Change player '" + playerID + "' public image: " + imageChange.ToString(), LOG_DEBUG)
	End Method


	Function ChangeForTargetGroup(playerAudience:TMap, targetGroup:Int, attrList:TList, compareFunc( o1:Object,o2:Object )=CompareObjects)
		Local tempList:TList = attrList.Copy()
		SortList(tempList,False,compareFunc)

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
	End Function
End Type
