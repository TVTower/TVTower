SuperStrict
Import "game.gameobject.bmx"
Import "../source/Dig/base.util.data.bmx"
Import "../source/Dig/base.util.event.bmx"
Import "../source/Dig/base.util.localization.bmx"


Type TAchievementCollection Extends TGameObjectCollection
	Global _instance:TAchievementCollection


	Function GetInstance:TAchievementCollection()
		If Not _instance Then _instance = New TAchievementCollection
		Return _instance
	End Function


	Method Update:int(time:Long)
		For local a:TAchievement = EachIn entries.Values()
			a.Update(time)
		Next
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetAchievementCollection:TAchievementCollection()
	Return TAchievementCollection.GetInstance()
End Function


Type TAchievementBaseType Extends TGameObject
	Field title:TLocalizedString
	Field flags:int

	Const STATE_UNKNOWN:int = 0
	Const STATE_COMPLETED:int = 1
	Const STATE_FAILED:int = 2


	Method GetTitle:string()
		if title then return title.Get()
		return ""
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

	Field rewards:TAchievementReward[]
	Field tasks:TAchievementTask[]
	Field state:Int[] = [0,0,0,0]
	'time of when a player completed/failed that achievement
	Field stateTime:Long[] = [--1:Long,-1:Long,-1:Long,-1:Long]

	Const FLAG_CANFAIL:int = 1
	Const FLAG_EXCLUSIVEWINNER:int = 2


	Method New()
		flags = FLAG_CANFAIL
	End Method
	

	Method SetGUID:Int(GUID:String)
		If GUID="" Then GUID = "gameachievement-"+id
		Self.GUID = GUID
	End Method


	Method ToString:string()
		local res:string = ""
		res :+ "Achievement ~q" + GetTitle() + "~q (" + GetGuid() + ")" + "~n"
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


	Method AddReward:TAchievement(reward:TAchievementReward)
		If reward And Not HasReward(reward) Then rewards :+ [reward]
		Return Self
	End Method


	Method GetReward:TAchievementReward(rewardGUID:string, index:int = 0)
		if rewardGUID then index = GetRewardIndex(null, rewardGUID)
		if index < 0 then return Null
		return rewards[index]
	End Method


	Method GetRewardIndex:Int(reward:TAchievementReward=null, rewardGUID:String="")
		if not rewards or rewards.length = 0 then return -1
		If reward
			For Local index:Int = 0 Until rewards.length
				If rewards[index] = reward Then Return index
			Next
		ElseIf rewardGUID
			For Local index:Int = 0 Until rewards.length
				If rewards[index] And rewards[index].GetGUID() = rewardGUID Then Return index
			Next
		EndIf
		Return -1
	End Method


	Method HasReward:Int(reward:TAchievementReward, rewardGUID:String="")
		Return GetRewardIndex(reward, rewardGUID) >= 0
	End Method


	Method RemoveReward:TAchievement(reward:TAchievementReward, rewardGUID:String="")
		Local removeIndex:Int = GetRewardIndex(reward, rewardGUID)
		If removeIndex = -1 Then Return Self

		If rewards.length = 0
			Return Self
		ElseIf rewards.length = 1
			rewards = New TAchievementReward[0]
		Else
			rewards = rewards[.. removeIndex] + rewards[removeIndex+1 ..]
		EndIf
	End Method



	Method AddTask:TAchievement(task:TAchievementTask)
		If task And Not HasTask(task) Then tasks :+ [task]
		Return Self
	End Method


	Method GetTask:TAchievementTask(taskGUID:string, index:int = 0)
		if taskGUID then index = GetTaskIndex(null, taskGUID)
		if index < 0 then return Null
		return tasks[index]
	End Method


	Method GetTaskIndex:Int(task:TAchievementTask=null, taskGUID:String="")
		if not tasks or tasks.length = 0 then return -1
		If task
			For Local index:Int = 0 Until tasks.length
				If tasks[index] = task Then Return index
			Next
		ElseIf taskGUID
			For Local index:Int = 0 Until tasks.length
				If tasks[index] And tasks[index].GetGUID() = taskGUID Then Return index
			Next
		EndIf
		Return -1
	End Method


	Method HasTask:Int(task:TAchievementTask, taskGUID:String="")
		Return GetTaskIndex(task, taskGUID) >= 0
	End Method


	Method RemoveTask:TAchievement(task:TAchievementTask, taskGUID:String="")
		Local removeIndex:Int = GetTaskIndex(task, taskGUID)
		If removeIndex = -1 Then Return Self

		If tasks.length = 0
			Return Self
		ElseIf tasks.length = 1
			tasks = New TAchievementTask[0]
		Else
			tasks = tasks[.. removeIndex] + tasks[removeIndex+1 ..]
		EndIf
	End Method


	Method GiveRewards:int(playerID:int, time:Long=0)
		print "  Achievement.GiveRewards: "+playerID
		For local r:TAchievementReward = eachin rewards
			r.GiveToPlayer(playerID)
		Next
	End Method


	Method IsExclusive:int()
		return flags & FLAG_EXCLUSIVEWINNER > 0
	End Method

	Method CanFail:int()
		return flags & FLAG_CANFAIL > 0
	End Method


	Method OnComplete:int(playerID:int, time:Long=0)
		EventManager.triggerEvent(TEventSimple.Create("Achievement.OnComplete", New TData.addNumber("playerID", playerID).addNumber("time", time), Self))
		print "  Achievement.OnComplete: "+playerID
	End Method


	'called if a one-time-chance-achievement fails
	Method OnFail:int(playerID:int, time:Long=0)
		EventManager.triggerEvent(TEventSimple.Create("Achievement.OnFail", New TData.addNumber("playerID", playerID).addNumber("time", time), Self))
		print "  Achievement.OnFail: "+playerID
	End Method


	Method Update(time:Long = 0)
		'=== UPDATE & CHECK TASK COMPLETITION ===
		For local t:TAchievementTask = eachIn tasks
			t.Update(time)
		Next

		For local i:int = 1 to 4
			'already completed - you cannot fail afterwards
			if stateTime[i-1] >= 0 and state[i-1] = STATE_COMPLETED then continue
			
			local completedCount:int = 0
			local failedCount:int = 0
			For local t:TAchievementTask = eachIn tasks
				if t.IsCompleted(i, time) then completedCount :+ 1
				if t.IsFailed(i, time) then failedCount :+ 1
			Next

			if completedCount = tasks.length and state[i-i] <> STATE_COMPLETED
				stateTime[i-1] = time
				state[i-1] = STATE_COMPLETED

				OnComplete(i, time)
				GiveRewards(i, time)
			elseif failedCount = tasks.length and CanFail() and state[i-1] <> STATE_FAILED
				stateTime[i-1] = time
				state[i-1] = STATE_FAILED

				OnFail(i, time)
			endif
		Next
	
	End Method
End Type




'the individual jobs which have to get done for a specific achievement
Type TAchievementTask Extends TAchievementBaseType
	'ALL ARRAYS: 0=generic, 1-4 = players

	'current states
	Field state:Int[] = [0,0,0,0,0]
	'time of when a player completed that task
	Field stateTime:Long[] = [-1:Long, -1:Long,-1:Long,-1:Long,-1:Long]
	'indicators whether the state just changed
	Field stateChanged:int[] = [0,0,0,0,0]

	Field timeCreated:Long = -1
	Field timeLimit:Long = -1


	Method ToString:string()
		local res:string = ""
		res :+ "Task (" + GetGuid() + ")" + "~n"

		local completedString:string = ""
		for local i:int = 0 To stateTime.length 'include 0 + arrayLength
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


	Method Init:TAchievementTask(config:object)
		'stub
	End Method


	Method HasTimeLimit:int()
		return timeLimit > 0
	End Method


	Method IsWithinTimeLimit:int(time:long = 0)
		if timeLimit <= 0 then return True
		
		return (timeCreated + timeLimit) >= time
	End Method


	Method SetCompleted:TAchievementTask(playerID:int=0, time:long)
		return SetState(playerID, time, True)
	End Method


	Method SetFailed:TAchievementTask(playerID:int=0, time:long)
		return SetState(playerID, time, False)
	End Method


	Method SetState:TAchievementTask(playerID:int=0, time:long, bool:int=True)
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


	Method GetState:int(playerID:int, time:long)
		If state[0] <> STATE_UNKNOWN then return state[0]

		If stateTime.length < playerID Then Return False
		If playerID < 0 then playerID = 0


		If playerID = 0
			local stateMask:int = 0
			For Local i:Int = 1 until state.length 'skip [0]
				stateMask :| GetState(i, time)
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
		

	'without playerID, it returns whether ALL have completed the task
	Method IsCompleted:Int(playerID:Int=0, time:Long=0)
		return GetState(playerID, time) = STATE_COMPLETED
	End Method


	'without playerID, it returns whether ALL have failed the task
	Method IsFailed:Int(playerID:Int=0, time:Long=0)
		return GetState(playerID, time) = STATE_FAILED
	End Method


	Method isStateChanged:int(playerID:int=-1)
		if playerID <= 0 or playerID >= stateChanged.length
			playerID = 0
		endif

		return stateChanged[playerID] <> STATE_UNKNOWN
	End Method


	Method GetStates:int[]()
		return state
	End Method


	Method OnComplete:int(playerID:int, time:Long)
		EventManager.triggerEvent(TEventSimple.Create("AchievementTask.OnComplete", New TData.addNumber("playerID", playerID).addNumber("time", time), Self))
		print " Task.OnComplete ("+GetGUID()+"): "+playerID
	End Method


	Method OnFail:int(playerID:int, time:Long)
		EventManager.triggerEvent(TEventSimple.Create("AchievementTask.OnFail", New TData.addNumber("playerID", playerID).addNumber("time", time), Self))
		print " Task.OnFail ("+GetGUID()+"): "+playerID
	End Method


	Method Update(time:long)
		'check all entries/player whether they just completed/failed a
		'task
		'if so, run a custom method
		For local i:Int = 1 until stateTime.length
			if stateChanged[i] <> STATE_COMPLETED
				if IsCompleted(i, time)
					'generic and specific indicators
					stateChanged[0] = STATE_COMPLETED
					stateChanged[i] = STATE_COMPLETED

					OnComplete(i, time)
				endif
			else 'if stateChanged[i] = STATE_COMPLETED)
				if IsFailed(i, time)
					'generic and specific indicators
					stateChanged[0] = STATE_FAILED
					stateChanged[i] = STATE_FAILED

					OnFail(i, time)
				endif
			endif
		Next
	End Method
End Type




Type TAchievementReward Extends TAchievementBaseType
	Field rewardGiven:Long[] = [-1:Long,-1:Long,-1:Long,-1:Long]

	'players can only get this reward once in a game
	Const FLAG_ONETIMEREWARD:int = 1


	Method GiveToPlayer:int(playerID:int, time:Long=0)
		If playerID <= 0 or playerID > rewardGiven.length Then Return False

		'only reward once?
		if HasFlag(FLAG_ONETIMEREWARD)
			if rewardGiven[playerID] >=0 then return False
		endif

		rewardGiven[playerID] = time

		EventManager.triggerEvent(TEventSimple.Create("AchievementReward.OnBeginGiveToPlayer", New TData.addNumber("playerID", playerID), Self))
		CustomGiveToPlayer(playerID)
		EventManager.triggerEvent(TEventSimple.Create("AchievementReward.OnGiveToPlayer", New TData.addNumber("playerID", playerID), Self))

		return True
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


