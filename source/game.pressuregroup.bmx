SuperStrict
Import "game.gameconstants.bmx"
Import "game.modifier.base.bmx"



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



Type TGameModifierPressureGroup_ModifyChannelSympathy extends TGameModifierBase
	Field pressureGroup:int
	Field modifyProbability:Int = 100
	Field modifyValue:int


	'override to create this type instead of the generic one
	Function CreateNewInstance:TGameModifierPressureGroup_ModifyChannelSympathy()
		return new TGameModifierPressureGroup_ModifyChannelSympathy
	End Function


	Method Copy:TGameModifierPressureGroup_ModifyChannelSympathy()
		local clone:TGameModifierPressureGroup_ModifyChannelSympathy = new TGameModifierPressureGroup_ModifyChannelSympathy
		clone.CopyBaseFrom(self)
		clone.pressureGroup = self.pressureGroup
		clone.modifyProbability = self.modifyProbability
		clone.modifyValue = self.modifyValue

		return clone
	End Method
	

	Method Init:TGameModifierPressureGroup_ModifyChannelSympathy(data:TData, extra:TData=null)
		if not data then return null

		pressureGroup = data.GetInt("pressureGroup", 0)
		modifyProbability = data.GetInt("probability", 100)
		modifyValue = data.GetInt("value", 0)

		return self
	End Method
	
	
	Method ToString:string()
		local name:string = "default"
		if data then name = data.GetString("name", name)

		return "TGameModifierPressureGroup_ModifyChannelSympathy ("+name+")"
	End Method



	'override to trigger a specific news
	Method RunFunc:int(params:TData)
		'skip if probability is missed
		if modifyProbability <> 100 and RandRange(0, 100) > modifyProbability then return False

		local playerID:int = params.GetInt("playerID", 0)

		if playerID = 0
			For local i:int = 0 until 4
				GetPressureGroupCollection().AddChannelSympathy(i, pressureGroup, modifyValue)
			Next
		else
			GetPressureGroupCollection().AddChannelSympathy(playerID, pressureGroup, modifyValue)
		endif
print "TGameModifierPressureGroup_ModifyChannelSympathy : Adjusted pressuregroup value"

		return True
	End Method
End Type



GetGameModifierManager().RegisterCreateFunction("ModifyPressureGroupChannelSympathy", TGameModifierPressureGroup_ModifyChannelSympathy.CreateNewInstance)
