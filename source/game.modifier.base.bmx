Rem
	Contains:
		TGameModifierBase
		TGameModifierBaseCreator
		TGameModifierGroup
		TGameModifierCondition
		TGameModifierCondition_TimeLimit extends TGameModifierCondition
EndRem
SuperStrict
Import Brl.Reflection
Import "Dig/base.util.data.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "game.world.worldtime.bmx"
Import "game.gameconfig.bmx"


TGameModifierManager.RegisterCreateFunction("Modifier.Base", TGameModifierBase.CreateNewInstance)
TGameModifierManager.RegisterCreateFunction("Modifier.GameConfig", TGameModifier_GameConfig.CreateNewInstance)


'handles managed game modifiers (eg. time constrained ones)
Type TGameModifierManager
	Field modifiers:TList = new TList
	'functions cannot get serialized, so they need to be created in
	'advance - and cross all old and coming instances
	Global functions:TMap = CreateMap() {nosave}
	Global _instance:TGameModifierManager


	Function GetInstance:TGameModifierManager()
		if not _instance then _instance = new TGameModifierManager
		return _instance
	End Function


	Method Initialize:int()
		modifiers.Clear()
	End Method


	Method Add:int(modifier:TGameModifierBase)
		if modifiers.Contains(modifier) then return False

		modifiers.AddLast(modifier)
		return True
	End Method


	Method ContainsModifier:int(modifier:TGameModifierBase)
		return modifiers.Contains(modifier)
	End Method


	Method Remove:Int(modifier:TGameModifierBase)
		return modifiers.Remove(modifier)
	End Method


	Method GetCount:int()
		return modifiers.count()
	End Method



	'=== CREATORS ===
	'anonymous creator of effects
	'approach allows easy creation of effect-type-instances the caller
	'does not need to know - allows sharing of effects between various
	'classes

	'register an effect by passing the name + creator function
	Function RegisterCreateFunction(modifierName:string, func:TGameModifierBase())
		functions.Insert("create_"+modifierName.ToLower(), new TGameModifierCreatorFunctionWrapper.Init(func))
	End Function


	Function Create:TGameModifierBase(modifierName:string)
		local wrapper:TGameModifierCreatorFunctionWrapper = TGameModifierCreatorFunctionWrapper(functions.ValueForKey("create_"+modifierName.Tolower() ))
		if wrapper
			return wrapper.func()
		endif
		return null
	End Function


	Function CreateAndInit:TGameModifierBase(modifierName:string, params:TData, extra:TData=null)
		local wrapper:TGameModifierCreatorFunctionWrapper = TGameModifierCreatorFunctionWrapper(functions.ValueForKey("create_"+modifierName.Tolower() ))
		if wrapper
			return wrapper.func().Init(params, extra)
		endif
		return null
	End Function


	'=== FUNCTION-WRAPPER ===

	Function RegisterFunction(key:string, func:int(source:TGameModifierBase, params:TData))
		'override a potentially existing one!
		functions.Insert(key.ToLower(), new TGameModifierFunctionWrapper.Init(func))
	End Function


	Function RegisterRunFunction(key:string, func:int(source:TGameModifierBase, params:TData))
		functions.Insert("run_"+key.ToLower(), new TGameModifierFunctionWrapper.Init(func))
	End Function


	Function RegisterUndoFunction(key:string, func:int(source:TGameModifierBase, params:TData))
		functions.Insert("undo_"+key.ToLower(), new TGameModifierFunctionWrapper.Init(func))
	End Function


	Function GetFunction:TGameModifierFunctionWrapper(key:string)
		return TGameModifierFunctionWrapper(functions.ValueForKey(key.ToLower()))
	End Function


	Function GetRunFunction:TGameModifierFunctionWrapper(key:string)
		return TGameModifierFunctionWrapper(functions.ValueForKey("run_"+key.ToLower()))
	End Function


	Function GetUndoFunction:TGameModifierFunctionWrapper(key:string)
		return TGameModifierFunctionWrapper(functions.ValueForKey("undo_"+key.ToLower()))
	End Function


	Function RunFunction:int(key:string, source:TGameModifierBase, params:TData)
		local wrapper:TGameModifierFunctionWrapper = TGameModifierFunctionWrapper(functions.ValueForKey(key.ToLower()))
		if wrapper then return wrapper.func(source, params)
		return False
	End Function


	Function RunRunFunction:int(key:string, source:TGameModifierBase, params:TData)
		local wrapper:TGameModifierFunctionWrapper = TGameModifierFunctionWrapper(functions.ValueForKey("run_"+key.ToLower()))
		if wrapper then return wrapper.func(source, params)
		return False
	End Function


	Function RunUndoFunction:int(key:string, source:TGameModifierBase, params:TData)
		local wrapper:TGameModifierFunctionWrapper = TGameModifierFunctionWrapper(functions.ValueForKey("undo_"+key.ToLower()))
		if wrapper then return wrapper.func(source, params)
		return False
	End Function


	'=== MODIFIER FUNCTIONS ===

	Method Update()
		local toRemove:TGameModifierBase[]
		For local modifier:TGameModifierBase = EachIn modifiers
			'execute run(), undo() and so on
			'pass "null" as param so cached params are kept
			modifier.Update(null)

			if modifier.HasExpired() then toRemove :+ [modifier]
		Next
		For local modifier:TGameModifierBase = EachIn toRemove
			modifiers.remove(modifier)
		Next
	End Method
End Type


'return collection instance
Function GetGameModifierManager:TGameModifierManager()
	Return TGameModifierManager.GetInstance()
End Function




'as game modifiers are stored in savegames, we need a way to decouple
'function pointers from saved objects
'We store all theses functions in a collection and retrieve them via
'individual keys/identifiers
Type TGameModifierFunctionWrapper
	Field func:int(source:TGameModifierBase, params:TData)

	Method Init:TGameModifierFunctionWrapper(func:int(source:TGameModifierBase, params:TData))
		self.func = func
		return self
	End Method
End Type

Type TGameModifierCreatorFunctionWrapper
	Field func:TGameModifierBase()

	Method Init:TGameModifierCreatorFunctionWrapper(func:TGameModifierBase())
		self.func = func
		return self
	End Method
End Type




'base effect class (eg. for newsevents, programmedata, adcontractbases)
Type TGameModifierBase
	Field data:TData
	'data passed during an update-call
	Field passedParams:TData
	Field conditions:TGameModifierCondition[]
	'constant value of TVTGameModifierBase (CHANGETREND, TERRORISTATTACK, ...)
	Field modifierTypes:int = 0
	Field _flags:int = 0

	Const FLAG_PERMANENT:int = 1
	Const FLAG_ACTIVATED:int = 2
	Const FLAG_EXPIRED:int = 4
	Const FLAG_EXPIRATION_DISABLED:int = 8
	'a delayed modifier is automatically added to the manager when
	'"run" and not in the the managers list
	Const FLAG_DELAYED_EXECUTION:int = 16
	Const FLAG_DELAY_MANAGED_BY_MANAGER:int = 32


	Function CreateNewInstance:TGameModifierBase()
		return new TGameModifierBase
	End Function


	Method Init:TGameModifierBase(data:TData, extra:TData=null)
		'by default ignore "children"
		if extra and extra.GetInt("childIndex") > 0 then return null

		return self
	End Method


	Method Copy:TGameModifierBase()
		'deprecated
		'local clone:TGameModifierBase = new self
		local clone:TGameModifierBase = TGameModifierBase(TTypeId.ForObject(self).NewObject())
		clone.CopyBasefrom(self)
		return clone
	End Method


	Method CopyBaseFrom:TGameModifierBase(base:TGameModifierBase)
		'only works for numeric/strings!
		if base.data
			data = base.data.copy()
		else
			data = null
		endif
		modifierTypes = base.modifierTypes

		if not base.conditions or base.conditions.length = 0
			conditions = null
		else
			conditions = new TGameModifierCondition[base.conditions.length]
			For local i:int = 0 until base.conditions.length
				conditions[i] = base.conditions[i].Copy()
			Next
		endif
	End Method


	Method HasFlag:Int(flag:Int)
		Return (_flags & flag) <> 0
	End Method


	Method SetFlag(flag:Int, enable:Int=True)
		If enable
			_flags :| flag
		Else
			_flags :& ~flag
		EndIf
	End Method


	Method GetConditionIndex:int(condition:TGameModifierCondition)
		if not conditions or conditions.length = 0 then return -1
		For local i:int = 0 until conditions.length
			if conditions[i] = condition then return i
		Next
		return -1
	End Method


	Method HasCondition:int(condition:TGameModifierCondition)
		if not conditions or conditions.length = 0 then return False
		For local i:int = 0 until conditions.length
			if conditions[i] = condition then return True
		Next
		return False
	End Method


	Method AddCondition:int(condition:TGameModifierCondition)
		if HasCondition(condition) then return False
		conditions :+ [condition]
		return True
	End Method


	Method ConditionsFulfilled:int()
		if not conditions then return True
		For local c:TGameModifierCondition = EachIn conditions
			if not c.IsFulfilled() then return False
		Next
		return True
	End Method


	Method ToString:string()
		local name:string = "default"
		if data then name = data.GetString("_name", name)
		return "TGameModifierBase ("+name+")"
	End Method


	Method GetName:string()
		if data then data.GetString("_name", "default")
		return "default"
	End Method


	Method SetModifierType:TGameModifierBase(modifierType:Int, enable:Int=True)
		If enable
			modifierTypes :| modifierType
		Else
			modifierTypes :& ~modifierType
		EndIf
		return self
	End Method


	Method HasModifierType:Int(modifierType:Int)
		Return modifierTypes & modifierType
	End Method


	Method HasExpired:int()
		return HasFlag(FLAG_EXPIRED)
	End Method


	'set a point in time at which execution will happen
	'means an exact time in the future, not the time "until then"
	Method SetDelayedExecutionTime:int(delayTime:Long)
		if delayTime > 0
			SetFlag(FLAG_DELAYED_EXECUTION, True)
			GetData().AddNumber("delayExecutionUntilTime", delayTime)
		else
			SetFlag(FLAG_DELAYED_EXECUTION, False)
			GetData().Remove("delayExecutionUntilTime")
		endif
		return True
	End Method


	Method HasDelayedExecution:int()
		return HasFlag(FLAG_DELAYED_EXECUTION)
	End Method


	Method GetDelayedExecutionTime:Long()
		'return "now" or
		if not HasDelayedExecution() then return GetWorldTime().GetTimeGone()
		return GetData().GetLong("delayExecutionUntilTime", 0)
	End Method


	Method SetData(data:TData)
		local oldName:string = GetName()
		self.data = data

		'set back old name?
		if oldName <> "default" then data.Add("_name", oldName)
	End Method


	Method GetData:TData()
		if not data then data = new TData
		return data
	End Method


	Method Update:int(params:TData)
		if params then passedParams = params

		'if delayed and delay is in the future, set item to be managed
		'by the modifier manager (so it gets updated regularily until
		'delay is gone)
		if HasDelayedExecution() and GetDelayedExecutionTime() > GetWorldTime().GetTimeGone()
			if not HasFlag(FLAG_DELAY_MANAGED_BY_MANAGER)
				if not GetGameModifierManager().ContainsModifier(self)
					GetGameModifierManager().Add(self)
				endif
				SetFlag(FLAG_DELAY_MANAGED_BY_MANAGER, True)
			endif
			return False
		endif

		'if HasDelayedExecution() then print "effect running now"


		local conditionsOK:int = ConditionsFulfilled()
		'run if not done yet and needed
		if not HasFlag(FLAG_ACTIVATED)
			if conditionsOK
				Run(passedParams)
			endif
		endif

		'undo/expire if needed (might happen in same Update()-call as the
		'run() above
		if HasFlag(Flag_ACTIVATED)
			if not HasFlag(FLAG_EXPIRATION_DISABLED) and (not conditions or not conditionsOK)
				if not HasFlag(FLAG_PERMANENT)
					Undo(passedParams)
				endif

				if HasFlag(FLAG_EXPIRATION_DISABLED)
					return True
				else
					SetFlag(FLAG_EXPIRED, True)
					'reset params?
					passedParams = null
					return False
				endif
			endif
		endif

		return True
	End Method


	'call to undo the changes - if possible
	Method Undo:int(params:TData)
		'skip if not run before
		if not HasFlag(FLAG_ACTIVATED) then return False

		local result:int
		if data and data.GetString("customUndoFuncKey")
			result = GetGameModifierManager().RunUndoFunction(data.GetString("customUndoFuncKey"), self, params)
		else
			result = UndoFunc(params)
		endif

		'mark as not-run
		SetFlag(FLAG_ACTIVATED, False)

		return result
	End Method


	'call to handle/emit the modifier/effect
	Method Run:int(params:TData)
		'skip if already running
		If HasFlag(FLAG_ACTIVATED) then return False

		local result:int
		if data and data.GetString("customRunFuncKey")
			result = GetGameModifierManager().RunRunFunction(data.GetString("customRunFuncKey"), self, params)
		else
			result = RunFunc(params)
		endif

		'mark as run
		SetFlag(FLAG_ACTIVATED, True)

		return result
	End Method


	Method UndoFunc:int(params:TData)
'		print "UndoFunc: " + ToString()
		return True
	End Method


	'override this function in custom types
	Method RunFunc:int(params:TData)
		print "RunFunc: " +ToString()
		print "   data: "+GetData().ToString()
		if params
			print " params: "+params.ToString()
		endif

		return True
	End Method
End Type




'modifier to modify GameConfig.data-values
'(this way other functions can access the information without needing
' knowledge about the modifiers)
Type TGameModifier_GameConfig extends TGameModifierBase
	Function CreateNewInstance:TGameModifier_GameConfig()
		return new TGameModifier_GameConfig
	End Function


	Method Init:TGameModifier_GameConfig(data:TData, extra:TData=null)
		if not super.Init(data, extra) then return null

		if data then self.data = data.copy()

		return self
	End Method


	Method ToString:string()
		return "TGameModifier_GameConfig ("+GetName()+")"
	End Method


	Method UndoFunc:int(params:TData)
		local modKey:string = GetData().GetString("modifierKey")
		if not modKey then return False

		local valueChange:Float = GetData().GetFloat("value.change", 0.0)
		if valueChange = 0.0 then return False

		'local valueBackup:Float = GetData().GetFloat("value.backup")
		local value:Float = GameConfig.GetModifier(modKey)
		'local relative:Int = GetData().GetBool("relative")

		'restore
		GameConfig.SetModifier(modKey, value - valueChange)

		'print "TGameModifier_GameConfig: restored ~q"+modKey+"~q. value "+value+" => "+GameConfig.GetModifier(modKey)

		return True
	End Method


	'override this function in custom types
	Method RunFunc:int(params:TData)
		local modKey:string = GetData().GetString("modifierKey")
		if not modKey then return False

		local value:Float = GetData().GetFloat("value", 0.0)
		if value = 0.0 then return False

		local valueBackup:Float = GameConfig.GetModifier(modKey)
		local relative:Int = GetData().GetBool("relative")

		'backup
		GetData().AddNumber("value.backup", valueBackup)

		'adjust
		if relative
			GetData().AddNumber("value.change", valueBackup * value)
			GameConfig.SetModifier(modKey, valueBackup * (1+value))
		else
			GetData().AddNumber("value.change", value)
			GameConfig.SetModifier(modKey, valueBackup + value)
		endif

		'print "TGameModifier_GameConfig: modified ~q"+modKey+"~q. value "+valueBackup+" => "+GameConfig.GetModifier(modKey)

		return True
	End Method
End Type




Type TGameModifierGroup
	Field entries:TMap
	Global _nilNode:TNode = New TNode._parent

	Method Copy:TGameModifierGroup()
		local c:TGameModifierGroup = new TGameModifierGroup
		if entries
			Local node:TNode = entries._FirstNode()
			While node And node <> _nilNode
				local l:TList = TList(node._value)
				if not l then continue

				for local m:TGameModifierBase = eachIn l
					c.AddEntry(string(node._key), m)
				next

				'move on to next node
				node = node.NextNode()
			Wend
		endif

		return c
	End Method


	Method GetList:TList(trigger:string)
		if not entries then return Null
		return TList(entries.ValueForKey(trigger.ToLower()))
	End Method


	Method RemoveList:int(trigger:string)
		if not entries then return False
		return entries.Remove(trigger.ToLower())
	End Method


	Method RemoveOrphans:int()
		local emptyLists:string[]
		For local trigger:string = EachIn entries.Keys()
			local l:TList = GetList(trigger)
			if l and l.count() = 0 then emptyLists :+ [trigger]
		Next
		for local trigger:string = EachIn emptyLists
			RemoveList(trigger)
		Next
		return emptyLists.Length
	End Method


	'checks if an certain modifier type is existent
	Method HasEntryWithModifierType:int(trigger:string, modifierType:int) {_exposeToLua}
		local list:TList = GetList(trigger)
		if not list then return false

		For local modifier:TGameModifierBase = eachin list
			if modifier.HasModifierType(modifierType) then return True
		Next
		return False
	End Method


	'checks if an effect was already added before
	Method HasEntry:int(trigger:string, entry:TGameModifierBase)
		if not entry then return False
		local list:TList = GetList(trigger)
		if not list then return False

		return list.contains(entry)
	End Method


	Method AddEntry:int(trigger:string, entry:TGameModifierBase)
		'skip if already added
		If HasEntry(trigger, entry) then return False

		'add effect
		local list:TList = GetList(trigger)
		if not list
			list = CreateList()
			if not entries then entries = New TMap
			entries.Insert(trigger.ToLower(), list)
		else
			'skip if already added
			if list.Contains(entry) then return False
		endif

		list.AddLast(entry)

		return True
	End Method


	Method RemoveEntry:int(trigger:String, entry:TGameModifierBase)
		if trigger
			local l:TList = GetList(trigger)
			if not l then return false

			l.Remove(entry)
			'remove empty list
			if l.count() = 0 then RemoveList(trigger)
		else
			For local trigger:string = EachIn entries.Keys()
				RemoveEntry(trigger, entry)
			Next

			RemoveOrphans()
		endif
	End Method


	Method RemoveExpiredEntries:int(trigger:string="")
		if trigger
			local l:TList = GetList(trigger)
			if not l then return False

			For local entry:TGameModifierBase = EachIn l.Copy()
				if entry.HasExpired() then l.Remove(entry)
			Next
		else
			For local trigger:string = EachIn entries.Keys()
				RemoveExpiredEntries(trigger)
			Next
		endif
	End Method


	Method Update:int(trigger:string, params:TData)
		local l:TList = GetList(trigger)
		if not l then return 0

		For local modifier:TGameModifierBase = eachin l
			modifier.Update(params)
		Next

		return l.Count()
	End Method


	Method Run:int(trigger:string, params:TData)
		local l:TList = GetList(trigger)
		if not l then return 0

		For local modifier:TGameModifierBase = eachin l
			modifier.Run(params)
		Next

		return l.Count()
	End Method
End Type


'grouping various triggers and triggering "all" or "one"
'of them
Type TGameModifierChoice extends TGameModifierBase
	Field modifiers:TGameModifierBase[]
	Field modifiersProbability:int[]
	'how child elements are choosen: "or" or "and" ?
	Field chooseType:string = 1

	Const CHOOSETYPE_OR:int = 0
	Const CHOOSETYPE_AND:int = 1


	Function CreateNewInstance:TGameModifierChoice()
		return new TGameModifierChoice
	End Function


	Function CreateNewChoiceInstance:TGameModifierBase()
		return new TGameModifierBase
	End Function


	Method Copy:TGameModifierChoice()
		local clone:TGameModifierChoice = new TGameModifierChoice
		clone.CopyBaseFrom(self)

		return clone
	End Method


	Method CopyFromChoice:TGameModifierChoice(choice:TGameModifierChoice)
		self.CopyBaseFrom(choice)
		self.chooseType = choice.chooseType
		For local p:int = EachIn choice.modifiersProbability
			self.modifiersProbability :+ [p]
		Next
		For local m:TGameModifierBase = EachIn choice.modifiers
			self.modifiers :+ [m.Copy()]
		Next
		return self
	End Method


	Method Init:TGameModifierChoice(data:TData, extra:TData=null)
		if data.GetString("choose").ToLower() = "or"
			chooseType = CHOOSETYPE_OR
		else
			chooseType = CHOOSETYPE_AND
		endif

		'only load child-options for the parental one
		if not extra or extra.GetInt("childIndex") = 0 then LoadChoices(data)

		return self
	End Method


	Method LoadChoices:int(data:TData)
		'load children
		local childIndex:int = 0
		local child:TGameModifierBase
		local extra:TData = new TData
		Repeat
			childIndex :+1
			extra.AddNumber("childIndex", childIndex)
			'create the choice based on the defined type for the children
			child = CreateNewChoiceInstance().Init(data, extra)
			if child
				self.modifiers :+ [child]
				self.modifiersProbability :+ [1]
			endif
		Until not child
	End Method


	'override to trigger a specific news
	Method RunFunc:int(params:TData)
		if choosetype = CHOOSETYPE_OR
			'loop through all options and choose the one with the
			'probability below choosen one
			local randValue:int = RandRange(0,100)
			local lastProbability:int = 0
			local currProbability:int = 0
			For local i:int = 0 until modifiers.length
				currProbability = modifiersProbability[i] + lastProbability

				'found the correct one - or trigger at least the last one
				if (randValue >= lastProbability and randValue < currProbability) or i = modifiers.length -1
					modifiers[i].RunFunc(params)
					exit
				endif

				lastProbability = currProbability
			Next
		else
			For local m:TGameModifierBase = Eachin modifiers
				m.RunFunc(params)
			Next
		endif
	End Method
End Type




Type TGameModifierCondition
	Field enabled:int = True

	Method Copy:TGameModifierCondition()
		local clone:TGameModifierCondition = new TGameModifierCondition
		clone.enabled = enabled

		return clone
	End Method


	Method CopyBaseFrom:TGameModifierCondition(origin:TGameModifierCondition)
		if origin
			self.enabled = origin.enabled
		endif

		return self
	End Method


	Method Disable:int()
		enabled = False
	End Method


	Method IsFulfilled:int()
		return enabled = True
	End Method
End Type




Type TGameModifierCondition_TimeLimit extends TGameModifierCondition
	Field timeBegin:Long = -1
	Field timeEnd:Long = -1
	Field timeDuration:int = -1

	Method Copy:TGameModifierCondition_TimeLimit()
		local clone:TGameModifierCondition_TimeLimit = new TGameModifierCondition_TimeLimit
		clone.CopyBaseFrom(self)
		clone.timeBegin = self.timeBegin
		clone.timeEnd = self.timeEnd
		clone.timeDuration = self.timeDuration

		return clone
	End Method


	Method SetTimeEnd(time:Long)
		timeEnd = time
	End Method


	Method SetTimeBegin(time:Long)
		timeBegin = time
	End Method


	Method SetTimeBegin_Auto(timeType:int, timeValues:int[])
		SetTimeBegin( GetWorldTime().CalcTime_Auto(timeType, timeValues) )
	End Method


	Method IsFulfilled:int()
		if not Super.IsFulfilled() then return False
		'started running?
		if timeBegin >= 0 and timeBegin > GetWorldTime().GetTimeGone() then return False
		'still running
		if timeEnd >= 0 and timeEnd < GetWorldTime().GetTimeGone() then return False
		return True
	End Method
End Type
