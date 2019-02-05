SuperStrict
Import "game.gameobject.bmx"
Import "game.modifier.base.bmx"
Import "../source/Dig/base.util.data.bmx"
Import "../source/Dig/base.util.event.bmx"
Import "../source/Dig/base.util.localization.bmx"
Import "game.world.worldtime.bmx"


Type TAchievementCollection
	Field achievements:TGameObjectCollection = new TGameObjectCollection
	Field tasks:TGameObjectCollection = new TGameObjectCollection
	Field rewards:TGameObjectCollection = new TGameObjectCollection

	Global _instance:TAchievementCollection
	'as achievements / tasks / rewards base on TAchievementBaseType
	'they can share a map
	Global registeredElements:TMap = CreateMap()
	Global eventListeners:TLink[] {nosave}


	Function GetInstance:TAchievementCollection()
		If Not _instance Then _instance = New TAchievementCollection
		Return _instance
	End Function


	Method New()
		if not eventListeners or eventListeners.length = 0
			'handle savegame loading (assign sprites)
			eventListeners :+ [EventManager.registerListenerFunction("SaveGame.OnLoad", onSaveGameLoad)]
		endif
	End Method


	'reset contents
	Method Initialize:int()
		achievements.Initialize()
		tasks.Initialize()
		rewards.Initialize()
	End Method


	'=== ACHIEVEMENTS ===

	Method GetAchievement:TAchievement(guid:string)
		return TAchievement(achievements.GetByGUID(guid))
	End Method


	Method AddAchievement:int(obj:TGameObject)
		if TAchievement(obj) then return achievements.Add(obj)
		return False
	End Method


	Method RemoveAchievement:int(obj:TGameObject)
		if TAchievement(obj) then return achievements.Remove(obj)
		return False
	End Method


	Method RemoveAchievementByGuid:int(guid:string)
		return achievements.RemoveByGuid(guid)
	End Method


	'=== TASKS ===

	Method GetTask:TAchievementTask(guid:string)
		return TAchievementTask(tasks.GetByGUID(guid))
	End Method


	Method AddTask:int(obj:TGameObject)
		if TAchievementTask(obj) then return tasks.Add(obj)
		return False
	End Method


	Method RemoveTask:int(obj:TGameObject)
		if TAchievementTask(obj) then return tasks.Remove(obj)
		return False
	End Method


	Method RemoveTaskByGuid:int(guid:string)
		return tasks.RemoveByGuid(guid)
	End Method



	'=== REWARDS ===

	Method GetReward:TAchievementReward(guid:string)
		return TAchievementReward(rewards.GetByGUID(guid))
	End Method


	Method AddReward:int(obj:TGameObject)
		if TAchievementReward(obj) then return rewards.Add(obj)
		return False
	End Method


	Method RemoveReward:int(obj:TGameObject)
		if TAchievementReward(obj) then return rewards.Remove(obj)
		return False
	End Method


	Method RemoveRewardByGuid:int(guid:string)
		return rewards.RemoveByGuid(guid)
	End Method



	'=== ELEMENT CREATOR ===

	'register an achievement/task/reward by passing the name + creator function
	Function RegisterElement(elementName:string, baseType:TAchievementBaseType)
		registeredElements.insert(elementName.ToLower(), basetype)
	End Function


	Function CreateElement:TAchievementBaseType(elementName:string, data:TData)
		local element:TAchievementBaseType = TAchievementBaseType(registeredElements.ValueForKey( elementName.Tolower() ))
		if element
			'create/return a specific instance (of the same type)
			return element.CreateNewInstance().Init(data)
		endif
		return null
	End Function


	Function CreateTask:TAchievementTask(elementName:string, data:TData)
		return TAchievementTask(CreateElement(elementName, data))
	End Function


	Function CreateReward:TAchievementReward(elementName:string, data:TData)
		return TAchievementReward(CreateElement(elementName, data))
	End Function



	'=== GENERIC STUFF ===

	Method Reset:int()
		For local a:TAchievement = EachIn achievements.entries.Values()
			a.Reset()
		Next
		For local at:TAchievementTask = EachIn tasks.entries.Values()
			at.Reset()
		Next
		For local ar:TAchievementReward = EachIn rewards.entries.Values()
			ar.Reset()
		Next
	End Method


	Method Update:int(time:Long)
		For local a:TAchievement = EachIn achievements.entries.Values()
			a.Update(time)
		Next
	End Method


	'run when loading finished
	Function onSaveGameLoad:int(triggerEvent:TEventBase)
		TLogger.Log("TFigureBaseCollection", "Savegame loaded - reassigning achievement event listeners", LOG_DEBUG | LOG_SAVELOAD)
		For local a:TAchievement = eachin _instance.achievements
			a.onLoad()
		Next
		For local at:TAchievementTask = eachin _instance.tasks
			at.onLoad()
		Next
		For local ar:TAchievementReward = eachin _instance.rewards
			ar.onLoad()
		Next
	End Function
End Type


'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetAchievementCollection:TAchievementCollection()
	Return TAchievementCollection.GetInstance()
End Function




Type TAchievementBaseType Extends TGameObject
	Field title:TLocalizedString
	Field text:TLocalizedString
	Field flags:int

	Function CreateNewInstance:TAchievementBaseType()
		return null
'		return new TAchievementBaseType
	End Function

	Method GenerateGUID:string()
		return "achievementbasetype-"+id
	End Method


	Method Init:TAchievementBaseType(data:object)
		'stub
	End Method


	Method Reset:int() abstract


	Method onLoad:int()
		'stub
	End Method


	Method GetTitle:string()
		if title then return title.Get()
		return ""
	End Method


	Method SetTitle:TAchievementBaseType(title:TLocalizedString)
		self.title = title
		return self
	End Method


	Method GetText:string()
		if text then return text.Get()
		return ""
	End Method


	Method SetText:TAchievementBaseType(text:TLocalizedString)
		self.text = text
		return self
	End Method


	Method HasFlag:Int(flag:Int) {_exposeToLua}
		Return flags & flag
	End Method


	Method SetFlag(flag:Int, enable:Int=True)
		If enable
			flags :| flag
		Else
			flags :& ~flag
		EndIf
	End Method
End Type



Type TAchievement Extends TAchievementBaseType
	Field rewardGUIDs:string[]
	Field taskGUIDs:string[]
	Field index:int = 0
	Field group:int = 0
	Field category:int = 0
	Field stateSet:TAchievementStateSet = new TAchievementStateSet

	Field spriteFinished:string = ""
	Field spriteUnfinished:string = ""

	'cache
	Field _rewards:TAchievementReward[] {nosave}
	Field _tasks:TAchievementTask[] {nosave}

	Const FLAG_CANFAIL:int = 1
	Const FLAG_EXCLUSIVEWINNER:int = 2


	Method GenerateGUID:string()
		return "gameachievement-"+id
	End Method


	Method New()
		flags = FLAG_CANFAIL
	End Method


	Function CreateNewInstance:TAchievement()
		return new TAchievement
	End Function


	Method Init:TAchievement(data:object)
		return self
	End Method


	Method Reset:int()
		stateSet.Initialize()
	End Method


	Method ToString:string()
		local res:string = ""
		res :+ "Achievement ~q" + GetTitle() + "~q (" + GetGuid() + ")" + "~n"
		local tasks:TAchievementTask[] = GetTasks()
		if not tasks or tasks.length = 0
			res :+ "  Tasks:" + "~n"
			res :+ "    -/-" + "~n"
		else
			res :+ "  Tasks ("+tasks.length+"):" + "~n"
			for local i:int = 0 Until tasks.length
				local taskRes:string = ""
				if not tasks[i]
					taskRes = "undefined"
				else
					taskRes = tasks[i].ToString().Trim()
				endif

				local prefix:string = "    "
				local taskResSubs:string[] = taskRes.Split("~n")
				taskRes = ""
				for local sub:string = EachIn taskResSubs
					if taskRes <> "" then taskRes :+ RSet("", prefix.length)
					taskRes :+ sub + "~n"
				Next
				taskRes = prefix + taskres
				'taskRes.replace("~n", RSet("", prefix.length)) + "~n"

				res :+ taskRes
			next
		endif

		return res
	End Method


	'override
	Method GetText:string()
		local res:string = Super.GetText()
		if res then return res

		For local at:TAchievementTask = Eachin GetTasks()
'			res :+ Chr(183)+" " +at.GetTitle() + "~n"
			if res <> "" then res :+ " / "
			res :+ at.GetTitle()
		Next
		return res
	End Method


	'=== REWARDS ===
	Method GetRewards:TAchievementReward[]()
		if not _rewards and rewardGUIDs
			_rewards = new TAchievementReward[ 0 ]
			for local guid:string = EachIn rewardGUIDs
				local r:TAchievementReward = GetAchievementCollection().GetReward( guid )
				if r then _rewards :+ [r]
			next
		endif
		return _rewards
	End Method


	Method AddReward:TAchievement(guid:string)
		If guid And Not HasReward(null, guid)
			rewardGUIDs :+ [guid]
			'invalidate cache
			_rewards = null
		EndIf
		Return Self
	End Method


	Method GetReward:TAchievementReward(rewardGUID:string, index:int = 0)
		if rewardGUID then index = GetRewardIndex(null, rewardGUID)
		if index < 0 or index >= rewardGUIDs.length then return Null
		return GetRewards()[index]
	End Method


	Method GetRewardIndex:Int(reward:TAchievementReward=null, rewardGUID:String="")
		if not rewardGUIDs then return -1 'this also is "not" for rewardGUIDs.length = 0
		If reward then rewardGUID = reward.GetGUID()

		For Local index:Int = 0 Until rewardGUIDs.length
			If rewardGUIDs[index] = rewardGUID Then Return index
		Next
		Return -1
	End Method


	Method HasReward:Int(reward:TAchievementReward, rewardGUID:String="")
		Return GetRewardIndex(reward, rewardGUID) >= 0
	End Method


	Method RemoveReward:TAchievement(reward:TAchievementReward, rewardGUID:String="")
		Local removeIndex:Int = GetRewardIndex(reward, rewardGUID)
		If removeIndex = -1 Then Return Self

		If not rewardGUIDs 'includes rewardGUIDs.length = 0
			Return Self
		ElseIf rewardGUIDs.length = 1
			rewardGUIDs = New string[0]
		Else
			rewardGUIDs = rewardGUIDs[.. removeIndex] + rewardGUIDs[removeIndex+1 ..]
		EndIf

		'invalidate cache
		_rewards = null
	End Method



	'=== TASKS ===
	Method GetTasks:TAchievementTask[]()
		if not _tasks and taskGUIDs
			for local guid:string = EachIn taskGUIDs
				local t:TAchievementTask = GetAchievementCollection().GetTask( guid )
				if t then _tasks :+ [t]
			next
		endif
		return _tasks
	End Method


	Method AddTask:TAchievement(guid:string)
		If guid And Not HasTask(null, guid)
			taskGUIDs :+ [guid]
			'invalidate cache
			_tasks = null
		EndIf
		Return Self
	End Method


	Method GetTask:TAchievementTask(taskGUID:string, index:int = 0)
		if taskGUID then index = GetTaskIndex(null, taskGUID)
		if index < 0 or index >= taskGUIDs.length then return Null
		return GetTasks()[index]
	End Method


	Method GetTaskIndex:Int(task:TAchievementTask=null, taskGUID:String="")
		if not taskGUIDs then return -1 'this also is "not" for taskGUIDs.length = 0
		If task then taskGUID = task.GetGUID()

		For Local index:Int = 0 Until taskGUIDs.length
			If taskGUIDs[index] = taskGUID Then Return index
		Next
		Return -1
	End Method


	Method HasTask:Int(task:TAchievementTask, taskGUID:String="")
		Return GetTaskIndex(task, taskGUID) >= 0
	End Method


	Method RemoveTask:TAchievement(task:TAchievementTask, taskGUID:String="")
		Local removeIndex:Int = GetTaskIndex(task, taskGUID)
		If removeIndex = -1 Then Return Self

		If not taskGUIDs 'includes taskGUIDs.length = 0
			Return Self
		ElseIf taskGUIDs.length = 1
			taskGUIDs = New string[0]
		Else
			taskGUIDs = taskGUIDs[.. removeIndex] + taskGUIDs[removeIndex+1 ..]
		EndIf

		'invalidate cache
		_tasks = null
	End Method



	Method GiveRewards:int(playerID:int, time:Long=0)
		'print "  Achievement.GiveRewards: "+playerID
		For local r:TAchievementReward = eachin GetRewards()
			'print "       reward:" + r.GetTitle()
			r.GiveToPlayer(playerID)
		Next
	End Method


	Method IsCompleted:int(playerID:int, time:Long=0)
		return stateSet.IsCompleted(playerID, time)
	End Method


	Method IsFailed:int(playerID:int, time:Long=0)
		if not CanFail() then return False

		return stateSet.IsFailed(playerID, time)
	End Method


	Method IsExclusive:int()
		return flags & FLAG_EXCLUSIVEWINNER > 0
	End Method

	Method CanFail:int()
		return flags & FLAG_CANFAIL > 0
	End Method


	Method OnComplete:int(playerID:int, time:Long=0)
		EventManager.triggerEvent(TEventSimple.Create("Achievement.OnComplete", New TData.addNumber("playerID", playerID).addNumber("time", time), Self))
'		print "  Achievement.OnComplete: "+playerID
	End Method


	'called if a one-time-chance-achievement fails
	Method OnFail:int(playerID:int, time:Long=0)
		EventManager.triggerEvent(TEventSimple.Create("Achievement.OnFail", New TData.addNumber("playerID", playerID).addNumber("time", time), Self))
'		print "  Achievement.OnFail: "+playerID
	End Method


	Method SetCompleted:int(playerID:int, time:long, overrideCompleted:int=False)
		'skip setting again
		if not overrideCompleted and stateSet.GetState(playerID, time) = stateSet.STATE_COMPLETED then return False

		stateSet.SetState(playerID, time, True)

		OnComplete(playerID, time)
		GiveRewards(playerID, time)

		return True
	End Method


	Method SetFailed:int(playerID:int, time:long, overrideCompleted:int=False)
		'skip setting again
		if not overrideCompleted and stateSet.GetState(playerID, time) = stateSet.STATE_FAILED then return False

		stateSet.SetState(playerID, time, False)

		OnFail(playerID, time)

		return True
	End Method



	Method Update(time:Long = 0)
		'you cannot complete or fail an achievement if there is no task
		if taskGUIDs.length = 0 then return

		'=== UPDATE & CHECK TASK COMPLETITION ===
		For local t:TAchievementTask = eachIn GetTasks()
			t.Update(time)
		Next

		For local i:int = 1 to 4
			local state:int = stateSet.GetState(i, time)
			'already completed - you cannot fail afterwards
			if state = stateSet.STATE_COMPLETED then continue

			local completedCount:int = 0
			local failedCount:int = 0
			For local t:TAchievementTask = eachIn GetTasks()
				if t.IsCompleted(i, time) then completedCount :+ 1
				if t.IsFailed(i, time) then failedCount :+ 1
			Next

			if completedCount = taskGUIDs.length and state <> stateSet.STATE_COMPLETED
				SetCompleted(i, time)
			elseif failedCount = taskGUIDs.length and CanFail() and state <> stateSet.STATE_FAILED
				SetFailed(i, time, False)
			endif
		Next

	End Method


	Function SortByGUID:int(o1:Object, o2:Object)
		Local a1:TAchievement = TAchievement(o1)
		Local a2:TAchievement = TAchievement(o2)
		If Not a2 Then Return 1
		If Not a1 Then Return -1
		if a1.GetGUID() = a2.GetGUID()
			'shouldnt happen at all
			return 0
		endif
        If a1.GetGUID() > a2.GetGUID()
			return 1
        elseif a1.GetGUID() < a2.GetGUID()
			return -1
		endif
		return 0
	End Function


	Function SortByIndex:Int(o1:Object, o2:Object)
		Local a1:TAchievement = TAchievement(o1)
		Local a2:TAchievement = TAchievement(o2)
		if a1 and a2
			If a1.index > a2.index
				return 1
			elseif a1.index < a2.index
				return -1
			endif
		endif
		return SortByGUID(o1,o2)
	End Function


	Function SortByName:Int(o1:Object, o2:Object)
		Local a1:TAchievement = TAchievement(o1)
		Local a2:TAchievement = TAchievement(o2)
		if a1 and a2
			If a1.GetTitle().ToLower() > a2.GetTitle().ToLower()
				return 1
			elseif a1.GetTitle().ToLower() < a2.GetTitle().ToLower()
				return -1
			endif
		endif
		return SortByIndex(o1,o2)
	End Function


	Function SortByGroup:int(o1:object, o2:object)
		Local a1:TAchievement = TAchievement(o1)
		Local a2:TAchievement = TAchievement(o2)
		If a2 and a1
			if a1.group < a2.group
				return -1
			elseif a1.group > a2.group
				return 1
			endif
		Endif
		return SortByIndex(o1, o2)
	End Function


	Function SortByCategory:int(o1:object, o2:object)
		Local a1:TAchievement = TAchievement(o1)
		Local a2:TAchievement = TAchievement(o2)
		If a2 and a1
			if a1.category < a2.category
				return -1
			elseif a1.category > a2.category
				return 1
			endif
		Endif
		return SortByGroup(o1, o2)
	End Function
End Type




'the individual jobs which have to get done for a specific achievement
Type TAchievementTask Extends TAchievementBaseType
	Field stateSet:TAchievementStateSet = new TAchievementStateSet
	Field timeCreated:Long = -1
	Field timeLimit:Long = -1
	Field eventListeners:TLink[] {nosave}


	'DO NOT DO THIS as this also would register listeners for the "creator"
	'instances
	'Method New()
	'	RegisterEventListeners()
	'End Method


	Method Delete()
		EventManager.unregisterListenersByLinks(eventListeners)
	End Method


	Function CreateNewInstance:TAchievementTask()
		return new TAchievementTask
	End Function


	Method Init:TAchievementTask(config:object)
		'stub
	End Method


	Method RegisterEventListeners:int()
		'remove old ones
		EventManager.unregisterListenersByLinks(eventListeners)

		return True
	End Method


	'override
	Method onLoad:int()
		RegisterEventListeners()
	End Method


	Method Reset:int()
		stateSet.Initialize()
		timeCreated = -1
		timeLimit = -1
	End Method


	Method ToString:string()
		local res:string = ""
		res :+ "Task (" + GetGuid() + ")" + "~n"

		local completedString:string = ""
		for local i:int = 0 until stateSet.stateTime.length 'include 0 + arrayLength
			if completedString then completedString :+ "  "
			if IsCompleted(i)
				completedString :+ i+"=Y"
			else
				completedString :+ i+"=N"
			endif
		Next

		res :+ "  completed: "+completedString + "~n"

		return res
	End Method


	Method HasTimeLimit:int()
		return timeLimit > 0
	End Method


	Method IsWithinTimeLimit:int(time:long = 0)
		if timeLimit <= 0 then return True

		return (timeCreated + timeLimit) >= time
	End Method


	Method SetCompleted:TAchievementTask(playerID:int=0, time:long)
		stateSet.SetState(playerID, time, True)
		return self
	End Method


	Method SetFailed:TAchievementTask(playerID:int=0, time:long)
		stateSet.SetState(playerID, time, False)
		return self
	End Method


	'without playerID, it returns whether ALL have completed the task
	Method IsCompleted:Int(playerID:Int=0, time:Long=0)
		return stateSet.IsCompleted(playerID, time)
	End Method


	'without playerID, it returns whether ALL have failed the task
	Method IsFailed:Int(playerID:Int=0, time:Long=0)
		return stateSet.IsFailed(playerID, time)
	End Method


	Method isStateChanged:int(playerID:int=-1)
		return stateSet.IsStateChanged(playerID)
	End Method



	Method OnComplete:int(playerID:int, time:Long)
		EventManager.triggerEvent(TEventSimple.Create("AchievementTask.OnComplete", New TData.addNumber("playerID", playerID).addNumber("time", time), Self))
		print " Task.OnComplete ("+GetGUID()+"): "+playerID
	End Method


	Method OnFail:int(playerID:int, time:Long)
		EventManager.triggerEvent(TEventSimple.Create("AchievementTask.OnFail", New TData.addNumber("playerID", playerID).addNumber("time", time), Self))
		print " Task.OnFail ("+GetGUID()+"): "+playerID
	End Method


	Method Update:int(time:long)
		'check all entries/player whether they just completed/failed a
		'task
		'if so, run a custom method
		stateSet.ResetStateChanged()
		stateSet.Update(time)

		'someone changed their state...
		if stateSet.GetStateChanged(0) <> stateSet.STATE_UNKNOWN
			For local playerID:int = 1 to 4
				if not stateSet.IsCompleted(playerID, time) and stateSet.GetStateChanged(playerID) = stateSet.STATE_COMPLETED
					OnComplete(playerID, time)
				elseif not stateSet.IsFailed(playerID, time) and stateSet.GetStateChanged(playerID) = stateSet.STATE_FAILED
					OnFail(playerID, time)
				endif
			Next
		endif
	End Method
End Type




Type TAchievementReward Extends TAchievementBaseType
	Field gameModifier:TGameModifierBase
	Field rewardGiven:Long[] = [-1:Long,-1:Long,-1:Long,-1:Long]

	'players can only get this reward once in a game
	Const FLAG_ONETIMEREWARD:int = 1


	Function CreateNewInstance:TAchievementReward()
		return new TAchievementReward
	End Function


	Method Init:TAchievementReward(config:object)
		'stub
	End Method


	Method Reset:int()
		rewardGiven = [-1:Long,-1:Long,-1:Long,-1:Long]
	End Method


	Method GiveToPlayer:int(playerID:int, time:Long=0)
		If playerID < 1 or playerID > rewardGiven.length Then Return False

		'only reward once?
		if HasFlag(FLAG_ONETIMEREWARD)
			if rewardGiven[playerID-1] >=0 then return False
		endif

		rewardGiven[playerID-1] = time

		EventManager.triggerEvent(TEventSimple.Create("AchievementReward.OnBeginGiveToPlayer", New TData.addNumber("playerID", playerID), Self))

		if gameModifier then gameModifier.Run( GetGameModifierParams(playerID) )
		CustomGiveToPlayer(playerID)

		EventManager.triggerEvent(TEventSimple.Create("AchievementReward.OnGiveToPlayer", New TData.addNumber("playerID", playerID), Self))

		return True
	End Method


	'override in custom implementations
	Method GetGameModifierParams:TData(playerID:int)
		return null
	End Method


	'override this method for custom implementations/actions
	Method CustomGiveToPlayer:int(playerID:int)
		'
	End Method


	Method OnReward:Int(data:TData)
		Local playerID:Int = data.GetInt("playerID", 0)
		return GiveToPlayer(playerID)
	End Method
End Type




Type TAchievementStateSet
	Field state:Int[] = [0,0,0,0,0]
	'time of when a player completed/failed that achievement
	Field stateTime:Long[] = [-1:Long,-1:Long,-1:Long,-1:Long,-1:Long]
	'indicators whether the state just changed
	Field stateChanged:int[] = [0,0,0,0,0]

	Const STATE_UNKNOWN:int = 0
	Const STATE_COMPLETED:int = 1
	Const STATE_FAILED:int = 2


	Method Initialize:TAchievementStateSet()
		state = [0,0,0,0,0]
		stateTime = [-1:Long,-1:Long,-1:Long,-1:Long,-1:Long]
		stateChanged = [0,0,0,0,0]
	End Method



	Method GetStates:int[]()
		return state
	End Method


	'for playerID=0 it sets the state for all
	Method SetState:TAchievementStateSet(playerID:int=0, time:long, bool:int=True)
		If stateTime.length < playerID Then Return self

		if playerID < 0 then playerID = 0

		if playerID = 0
			For local i:int = 1 until stateTime.length-1 'skip [0]
				stateTime[playerID] = time
				'instead of calling SetCompleted recursively we avoid
				'multiple cache-resets by just adjusting the required
				'values here
				if bool
					state[playerID] = STATE_COMPLETED
				else
					state[playerID] = STATE_FAILED
				endif
			Next
		endif

		stateTime[playerID] = time

		if bool
			state[playerID] = STATE_COMPLETED
		else
			state[playerID] = STATE_FAILED
		endif

		return self
	End Method


	'for playerID=0 it returns if _all_ have the same value
	Method GetState:int(playerID:int, time:long)
		If stateTime.length <= playerID Then Return False
		If playerID < 0 then playerID = 0


		If playerID = 0
			'loop over all players and if they have a specific state
			'add this to the bitmask
			'set the state to a defined one if _all_ have the same state
			'(so stateMask is exactly the option's value)
			local stateMask:int = 0
			For Local i:Int = 1 until state.length 'skip [0]
				local s:int = GetState(i, time)
				if s = STATE_UNKNOWN
					stateMask = 0
					exit
				endif

				stateMask :| s
			Next

			if stateMask = STATE_COMPLETED
				state[0] = STATE_COMPLETED
			elseif stateMask = STATE_FAILED
				state[0] = STATE_FAILED
			else
				state[0] = STATE_UNKNOWN
			endif
		EndIf

		'did the adjustment happen already?
		if (stateTime[playerID] >= 0 and stateTime[playerID] <= time)
			Return state[playerID]
		else
			Return STATE_UNKNOWN
		endif
	End Method


	Method GetStateChanged:int(playerID:int)
		If stateChanged.length <= playerID Then Return 0
		If playerID < 0 then playerID = 0

		return stateChanged[playerID]
	End Method


	Method ResetStateChanged:int()
		For local i:Int = 0 until stateTime.length
			stateChanged[i] = STATE_UNKNOWN
		Next
	End Method


	Method IsCompleted:int(playerID:int, time:Long = 0)
		if time = 0 then time = GetWorldTime().GetTimeGone()
		return GetState(playerID, time) = STATE_COMPLETED
	End Method


	Method IsFailed:int(playerID:int, time:Long = 0)
		if time = 0 then time = GetWorldTime().GetTimeGone()
		return GetState(playerID, time) = STATE_FAILED
	End Method


	Method IsStateChanged:int(playerID:int)
		return GetStateChanged(playerID) <> STATE_UNKNOWN
	End Method


	Method Update:int(time:long)
		'check all entries/player whether they just completed/failed a
		'task
		'if so, run a custom method
		For local i:Int = 1 until stateTime.length
			if stateChanged[i] <> STATE_COMPLETED
				if IsCompleted(i, time)
					'generic and specific indicators
					stateChanged[0] = STATE_COMPLETED
					stateChanged[i] = STATE_COMPLETED
				endif
			endif
			'you can only fail if you completed before...
			if stateChanged[i] <> STATE_FAILED
				if IsFailed(i, time)
					'generic and specific indicators
					stateChanged[0] = STATE_FAILED
					stateChanged[i] = STATE_FAILED
				endif
			endif
		Next
	End Method
End Type