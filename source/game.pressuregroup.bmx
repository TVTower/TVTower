SuperStrict
Import "game.gameconstants.bmx"



Type TPressureGroupCollection
	Field pressureGroups:TPressureGroup[]
	Global _instance:TPressureGroupCollection


	Function GetInstance:TPressureGroupCollection()
		If Not _instance Then _instance = New TPressureGroupCollection
		Return _instance
	End Function


	Method New()
		'event registration
	End Method


	Method Initialize:Int()
		pressureGroups = new TPressureGroup[TVTPressureGroup.count]
		For local i:int = 0 until pressureGroups.length
			pressureGroups[i] = new TPressureGroup.Init( TVTPressureGroup.GetAtIndex(i) )
		Next
	End Method



	Method Set:int(id:int=-1, pressureGroup:TPressureGroup)
		If pressureGroups.length <= id Then pressureGroups = pressureGroups[..id+1]
		pressureGroups[id] = pressureGroup
	End Method


	Method Get:TPressureGroup(id:int)
		If id < 0 or id >= pressureGroups.length Then return Null

		Return pressureGroups[id]
	End Method


	Method GetChannelSympathy:Float(channelID:int, pressureGroupID:int)
		local result:Float
		local indices:int[] = TVTPressureGroup.GetIndexes(pressureGroupID)
		For local index:int = EachIn indices
			result :+ Get(index).GetChannelSympathy(channelID)
		Next
		if not indices or indices.length = 0 then return 0
		return result / indices.length
	End Method


	Method SetChannelSympathy(channelID:int, pressureGroupID:int, value:Float)
		For local index:int = EachIn TVTPressureGroup.GetIndexes(pressureGroupID)
			Get(index).SetChannelSympathy(channelID, value)
		Next
	End Method


	Method AddChannelSympathy(channelID:int, pressureGroupID:int, value:Float)
		For local index:int = EachIn TVTPressureGroup.GetIndexes(pressureGroupID)
			Get(index).SetChannelSympathy(channelID, Get(index).GetChannelSympathy(channelID) + value)
		Next
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetPressureGroupCollection:TPressureGroupCollection()
	Return TPressureGroupCollection.GetInstance()
End Function

Function GetPressureGroup:TPressureGroup(pressureGroup:Int)
	Return TPressureGroupCollection.GetInstance().Get(pressureGroup)
End Function




Type TPressureGroup
	Field pressureGroupID:int
	Field channelSympathy:Float[4]


	Method Init:TPressureGroup(pressureGroupID:int)
		self.pressureGroupID = pressureGroupID
		return self
	End Method


	Method SetChannelSympathy:int(channelID:int, value:Float)
		if channelID < 0 or channelID >= channelSympathy.length then return False

		channelSympathy[channelID -1] = value

		return True
	End Method
	

	Method GetChannelSympathy:float(channelID:int)
		if channelID < 0 or channelID >= channelSympathy.length then return 0.0

		return channelSympathy[channelID -1]
	End Method
End Type