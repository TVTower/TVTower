SuperStrict
Import "game.gameconstants.bmx"
Import "game.modifier.base.bmx"
Import "game.world.worldtime.bmx"



Type TPressureGroupCollection
	Field pressureGroups:TPressureGroup[]
	Field _initialized:int = false
	Field archivedSympathies:TPressureGroupSympathyArchive[]
	Global _instance:TPressureGroupCollection
	Const archiveLimit:int = 100


	Function GetInstance:TPressureGroupCollection()
		If Not _instance Then _instance = New TPressureGroupCollection
		Return _instance
	End Function


	Method New()
		'event registration
	End Method


	Method Initialize:Int()
		pressureGroups = new TPressureGroup[TVTPressureGroup.count + 1] 'keep "0" empty
		For local i:int = 1 until pressureGroups.length
			pressureGroups[i] = new TPressureGroup.Init( TVTPressureGroup.GetAtIndex(i) )
		Next

		_initialized = True

		return True
	End Method


	Method Set:int(index:int=-1, pressureGroup:TPressureGroup)
		if not _initialized then Initialize()
		If pressureGroups.length <= index Then pressureGroups = pressureGroups[.. index+1]

		pressureGroups[index] = pressureGroup

		return True
	End Method


	Method Get:TPressureGroup(index:int)
		if not _initialized then Initialize()
		If index < 0 or index >= pressureGroups.length Then return Null

		Return pressureGroups[index]
	End Method


	Method GetByID:TPressureGroup(id:int)
		local index:int = TVTPressureGroup.GetIndex(id)
		Return Get(index)
	End Method


	Method GetChannelSympathy:Float(channelID:int, pressureGroupID:int, archivedBefore:int = 0)
		if not _initialized then Initialize()
		local result:Float
		local indices:int[] = TVTPressureGroup.GetIndexes(pressureGroupID)
		if not indices or indices.length = 0 then return 0

		if archivedBefore > 0 and archivedSympathies.length >= archivedBefore
			For local index:int = EachIn indices
				result :+ archivedSympathies[archivedBefore-1].GetChannelSympathy(channelID, index)
			Next
		elseif archivedBefore > 0 and archivedSympathies.length > 0
			For local index:int = EachIn indices
				result :+ archivedSympathies[archivedSympathies.length-1].GetChannelSympathy(channelID, index)
			Next
		else
			For local index:int = EachIn indices
				result :+ Get(index).GetChannelSympathy(channelID)
			Next
		endif

		return result / indices.length
	End Method


	Method SetChannelSympathy(channelID:int, pressureGroupID:int, value:Float, time:Long = -1)
		if time = -1 then time = GetWorldTime().GetTimeGone()

		if not _initialized then Initialize()

		For local index:int = EachIn TVTPressureGroup.GetIndexes(pressureGroupID)
			Get(index).SetChannelSympathy(channelID, value, time)
		Next
	End Method


	Method AddChannelSympathy(channelID:int, pressureGroupID:int, value:Float, time:Long = -1)
		if time = -1 then time = GetWorldTime().GetTimeGone()

		if not _initialized then Initialize()
		For local index:int = EachIn TVTPressureGroup.GetIndexes(pressureGroupID)
			Get(index).AddChannelSympathy(channelID, value, time)
		Next
	End Method


	'The PUBLIC archived sympathies (done each day or so)
	'PRIVATE archives should be stored elsewhere (eg. at TPlayer)
	Method ArchiveSympathies()
		if not archivedSympathies
			archivedSympathies = [ new TPressureGroupSympathyArchive.Init() ]
		else
			if archivedSympathies.length >= archiveLimit + 1
				archivedSympathies = [ new TPressureGroupSympathyArchive.Init() ] + archivedSympathies[.. archiveLimit-1]
			else
				archivedSympathies = [ new TPressureGroupSympathyArchive.Init() ] + archivedSympathies
			endif
		endif
		print "ArchiveSympathies: count=" + archivedSympathies.length
	End Method
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetPressureGroupCollection:TPressureGroupCollection()
	Return TPressureGroupCollection.GetInstance()
End Function

Function GetPressureGroupByID:TPressureGroup(pressureGroupID:Int)
	Return TPressureGroupCollection.GetInstance().GetByID(pressureGroupID)
End Function

Function GetPressureGroup:TPressureGroup(collectionIndex:Int)
	Return TPressureGroupCollection.GetInstance().Get(collectionIndex)
End Function




'Storage of sympathies for all pressure groups regarding all channels
Type TPressureGroupSympathyArchive
	'owner of the channel
	'0 = for all, else for specific channel
'	Field channelID:int = 0
	'array containing sympathies of each pressure group for each channel
	Field sympathies:TPressureGroupSympathy[]
	'time of last change within all sympathies
	Field time:Long


	Method Init:TPressureGroupSympathyArchive()
		sympathies = new TPressureGroupSympathy[GetPressureGroupCollection().pressureGroups.length] '0 is empty

		For local i:int = 1 until GetPressureGroupCollection().pressureGroups.length
			'create a copy (not referencing values)
			sympathies[i] = new TPressureGroupSympathy.CopyFrom( GetPressureGroup(i).channelSympathy )
			'store time of most current
			time = Max(time, sympathies[i].time)
		Next

		return self
	End Method


	Method GetChannelSympathy:float(channelID:int, pressureGroupIndex:int)
		if pressureGroupIndex < 0 or pressureGroupIndex >= sympathies.length then return -1
		if channelID <= 0 or channelID > 4 then return -1

		return sympathies[pressureGroupIndex].Get(channelID)
	End Method
End Type




'Stores sympathies of a pressure group for each channel
Type TPressureGroupSympathy
	'sympathies of each channel
	Field sympathies:Float[] = [0.0, 0.0, 0.0, 0.0]
	'when were the values archived / last updated?
	Field time:Long


	Method Reset()
		sympathies = new Float[4]
		time = 0
	End Method


	Method CopyFrom:TPressureGroupSympathy(other:TPressureGroupSympathy)
		self.sympathies = other.sympathies[ .. ] 'copy floats
		self.time = other.time
		return self
	End Method


	Method Set:int(channelID:int, value:Float, time:Long = -1)
		if time = -1 then time = GetWorldTime().GetTimeGone()

		if channelID <= 0
			For local i:int = 0 until sympathies.length
				sympathies[i] = value
			Next
		elseif channelID <= sympathies.length
			sympathies[channelID-1] = value
		else
			return False
		endif

		self.time = time

		return True
	End Method


	Method Add:int(channelID:int, value:Float, time:Long = -1)
		if time = -1 then time = GetWorldTime().GetTimeGone()

		if channelID <= 0
			For local i:int = 0 until sympathies.length
				sympathies[i] :+ value
			Next
		elseif channelID <= sympathies.length
			sympathies[channelID-1] :+ value
		else
			return False
		endif

		self.time = time

		return True
	End Method


	Method Get:Float(channelID:int)
		if channelID > 0 and channelID <= sympathies.length
			return sympathies[channelID-1]
		else
			return 0.0
		endif
	End Method


	'return last time a value was changed
	Method GetTime:Long()
		return time
	End Method
End Type



rem
Type TPressureGroupSympathyArchive
	'archived entries
	Field entries:TPressureGroupSympathy[]
	'who owns the entries
	Field ownership:int[]
	'value of the sympathy
	Field sympathy:Float[]
	'when was the sympathy updated the last time
	Field time:Long[]
	Const archiveLimit:int = 100


	Method Reset()
		sympathy = new Float[0]
		time = new Long[0]
	End Method


	Method SetSympathy:int(value:Float, time:Long)
		if not sympathy or sympathy.length <= 0
			sympathy = [value]
			self.time = [time]
		else
			sympathy[0] = value
			self.time[0] = time
		endif

		return True
	End Method


	Method AddSympathy:int(value:Float, time:Long)
		if not sympathy or sympathy.length <= 0
			sympathy = [value]
			self.time = [time]
		else
			sympathy[0] :+ value
			self.time[0] = time
		endif

		return True
	End Method


	Method GetSympathy:float(archivedBefore:int = 0, returnFirstPossible:int = True)
		if archivedBefore = 0
			if not sympathy or sympathy.length <= 0 then return 0.0
			return sympathy[0]
		else
			if sympathy and (returnFirstPossible or sympathy.length >= archivedBefore)
				return sympathy[Min(archivedBefore, sympathy.length) - 1]
			endif

			'nothing archived yet
			return 0.0
		endif
	End Method


	Method GetTime:Long(archivedBefore:int = 0, returnFirstPossible:int = True)
		if archivedBefore = 0
			if not time or time.length <= 0 then return 0
			return time[0]
		else
			if time and (returnFirstPossible or time.length >= archivedBefore)
				return time[Min(archivedBefore, time.length) - 1]
			endif

			'nothing archived yet
			return 0
		endif
	End Method


	Method ArchiveCurrent(archiveTime:Long)
		if not sympathy
			'store copy of values to avoid manipulating archived data
			sympathy = [ 0.0 ]
			time = [ GetWorldTime().GetTimeGone() ]
		else
			if sympathy.length >= archiveLimit + 1
				'copy first entry into new "0" position
				sympathy = [ sympathy[0] ] + sympathy[.. archiveLimit-1]
				time = [ archiveTime ] + time[.. archiveLimit-1]
			else
				sympathy = [ sympathy[0] ] + sympathy
				time = [ archiveTime ] + time
			endif
		endif
	End Method
End Type
endrem


Type TPressureGroup
	Field pressureGroupID:int
	'single entry containing sympathies for each channel
	Field channelSympathy:TPressureGroupSympathy


	Method Init:TPressureGroup(pressureGroupID:int)
		self.pressureGroupID = pressureGroupID
		self.channelSympathy = new TPressureGroupSympathy
		return self
	End Method


	Method Reset(channelID:int = -1)
		channelSympathy.Set(channelID, 0, 0)
	End Method


	Method SetChannelSympathy:int(channelID:int, value:Float, time:Long = -1)
		if time = -1 then time = GetWorldTime().GetTimeGone()

		return channelSympathy.Set(channelID, value, time)
	End Method


	Method AddChannelSympathy:int(channelID:int, value:Float, time:Long = -1)
		if time = -1 then time = GetWorldTime().GetTimeGone()

		return channelSympathy.Add(channelID, value, time)
	End Method


	Method GetChannelSympathy:float(channelID:int)
		return channelSympathy.Get(channelID)
	End Method

rem
	Field channelSympathyArchive:Float[][]
	Field channelSympathyArchiveTime:Long[][]
	Const archiveLimit:int = 10


	Method Init:TPressureGroup(pressureGroupID:int)
		self.pressureGroupID = pressureGroupID
		return self
	End Method


	Method Reset(playerID:int = -1)
		if playerID <= 0
			For local i:int = 0 until channelSympathy.length
				Reset(i+1)
			Next
		else
			channelSympathy[playerID-1] = 0
			channelSympathyArchive[playerID-1] = new Float[0]
		endif
	End Method


	Method ArchiveSympathy(time:Long)
		if not channelSympathyArchive
			'store copy of values to avoid manipulating archived data
			channelSympathyArchive = [ channelSympathy[..] ]
			channelSympathyArchiveTime = [ GetWorldTime().GetTimeGone() ]
		else
			if channelSympathyArchive.length >= archiveLimit + 1
				channelSympathyArchive = [ channelSympathy[..] ] + channelSympathyArchive[.. archiveLimit-1]
				channelSympathyArchiveTime = [ GetWorldTime().GetTimeGone() ] + channelSympathyArchiveTime[.. archiveLimit-1]
			else
				channelSympathyArchive = [ channelSympathy[..] ] + channelSympathyArchive
				channelSympathyArchiveTime = [ GetWorldTime().GetTimeGone() ] + channelSympathyArchiveTime
			endif
		endif
	End Method


	Method SetChannelSympathy:int(channelID:int, value:Float)
		if channelID < 0 or channelID >= channelSympathy.length then return False

		channelSympathy[channelID -1] = value

		return True
	End Method


	Method AddChannelSympathy:int(channelID:int, value:Float)
		if channelID < 0 or channelID >= channelSympathy.length then return False

		channelSympathy[channelID -1] :+ value

		return True
	End Method


	Method GetChannelSympathy:float(channelID:int, archivedBefore:int = 0, returnFirstPossible:int = True)
		if channelID < 0 or channelID >= channelSympathy.length then return 0.0

		if archivedBefore = 0
			return channelSympathy[channelID -1]
		else
			local arr:float[]
			if channelSympathyArchive and (returnFirstPossible or channelSympathyArchive.length >= archivedBefore)
				arr = channelSympathyArchive[Min(archivedBefore, channelSympathyArchive.length) - 1]
			endif

			'nothing archived yet
			if not arr or channelID >= arr.length then return 0.0

			return arr[channelID]
		endif
	End Method
endrem
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
				GetPressureGroupCollection().AddChannelSympathy(i, pressureGroup, modifyValue, Long(GetWorldTime().GetTimeGone()))
			Next
		else
			GetPressureGroupCollection().AddChannelSympathy(playerID, pressureGroup, modifyValue, Long(GetWorldTime().GetTimeGone()))
		endif
print "TGameModifierPressureGroup_ModifyChannelSympathy : Adjusted pressuregroup value"

		return True
	End Method
End Type



GetGameModifierManager().RegisterCreateFunction("ModifyPressureGroupChannelSympathy", TGameModifierPressureGroup_ModifyChannelSympathy.CreateNewInstance)
