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
	Field modifiers:TList = New TList
	'functions cannot get serialized, so they need to be created in
	'advance - and cross all old and coming instances
	Global functions:TStringMap = new TStringMap {nosave}
	Global createFunctions:TStringMap = new TStringMap {nosave}
	Global runFunctions:TStringMap = new TStringMap {nosave}
	Global undoFunctions:TStringMap = new TStringMap {nosave}
	Global _instance:TGameModifierManager


	Function GetInstance:TGameModifierManager()
		If Not _instance Then _instance = New TGameModifierManager
		Return _instance
	End Function


	Method Initialize:Int()
		modifiers.Clear()
	End Method


	Method Add:Int(modifier:TGameModifierBase)
		If modifiers.Contains(modifier) Then Return False

		modifiers.AddLast(modifier)
		Return True
	End Method


	Method ContainsModifier:Int(modifier:TGameModifierBase)
		Return modifiers.Contains(modifier)
	End Method


	Method Remove:Int(modifier:TGameModifierBase)
		Return modifiers.Remove(modifier)
	End Method


	Method GetCount:Int()
		Return modifiers.count()
	End Method



	'=== CREATORS ===
	'anonymous creator of effects
	'approach allows easy creation of effect-type-instances the caller
	'does not need to know - allows sharing of effects between various
	'classes

	'register an effect by passing the name + creator function
	Function RegisterCreateFunction(modifierName:String, func:TGameModifierBase())
		createFunctions.Insert(modifierName.ToLower(), New TGameModifierCreatorFunctionWrapper.Init(func))
	End Function


	Function Create:TGameModifierBase(modifierName:String)
		Local wrapper:TGameModifierCreatorFunctionWrapper = TGameModifierCreatorFunctionWrapper(createFunctions.ValueForKey(modifierName.Tolower() ))
		If wrapper
			Return wrapper.func()
		EndIf
		Return Null
	End Function


	Function CreateAndInit:TGameModifierBase(modifierName:String, params:TData, extra:TData=Null)
		Local wrapper:TGameModifierCreatorFunctionWrapper = TGameModifierCreatorFunctionWrapper(createFunctions.ValueForKey(modifierName.Tolower() ))
		If wrapper
			Return wrapper.func().Init(params, extra)
		EndIf
		Return Null
	End Function


	'=== FUNCTION-WRAPPER ===

	Function RegisterFunction(key:String, func:Int(source:TGameModifierBase, params:TData))
		'override a potentially existing one!
		functions.Insert(key.ToLower(), New TGameModifierFunctionWrapper.Init(func))
	End Function


	Function RegisterRunFunction(key:String, func:Int(source:TGameModifierBase, params:TData))
		runFunctions.Insert(key.ToLower(), New TGameModifierFunctionWrapper.Init(func))
	End Function


	Function RegisterUndoFunction(key:String, func:Int(source:TGameModifierBase, params:TData))
		undoFunctions.Insert(key.ToLower(), New TGameModifierFunctionWrapper.Init(func))
	End Function


	Function GetFunction:TGameModifierFunctionWrapper(key:String)
		Return TGameModifierFunctionWrapper(functions.ValueForKey(key.ToLower()))
	End Function


	Function GetRunFunction:TGameModifierFunctionWrapper(key:String)
		Return TGameModifierFunctionWrapper(runFunctions.ValueForKey(key.ToLower()))
	End Function


	Function GetUndoFunction:TGameModifierFunctionWrapper(key:String)
		Return TGameModifierFunctionWrapper(undoFunctions.ValueForKey(key.ToLower()))
	End Function


	Function RunFunction:Int(key:String, source:TGameModifierBase, params:TData)
		Local wrapper:TGameModifierFunctionWrapper = TGameModifierFunctionWrapper(functions.ValueForKey(key.ToLower()))
		If wrapper Then Return wrapper.func(source, params)
		Return False
	End Function


	Function RunRunFunction:Int(key:String, source:TGameModifierBase, params:TData)
		Local wrapper:TGameModifierFunctionWrapper = TGameModifierFunctionWrapper(runFunctions.ValueForKey(key.ToLower()))
		If wrapper Then Return wrapper.func(source, params)
		Return False
	End Function


	Function RunUndoFunction:Int(key:String, source:TGameModifierBase, params:TData)
		Local wrapper:TGameModifierFunctionWrapper = TGameModifierFunctionWrapper(undoFunctions.ValueForKey(key.ToLower()))
		If wrapper Then Return wrapper.func(source, params)
		Return False
	End Function


	'=== MODIFIER FUNCTIONS ===

	Method Update()
		Local toRemove:TGameModifierBase[]
		For Local modifier:TGameModifierBase = EachIn modifiers
			'execute run(), undo() and so on
			'pass "null" as param so cached params are kept
			modifier.Update(Null)

			If modifier.HasExpired() Then toRemove :+ [modifier]
		Next
		For Local modifier:TGameModifierBase = EachIn toRemove
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
	Field func:Int(source:TGameModifierBase, params:TData)

	Method Init:TGameModifierFunctionWrapper(func:Int(source:TGameModifierBase, params:TData))
		Self.func = func
		Return Self
	End Method
End Type

Type TGameModifierCreatorFunctionWrapper
	Field func:TGameModifierBase()

	Method Init:TGameModifierCreatorFunctionWrapper(func:TGameModifierBase())
		Self.func = func
		Return Self
	End Method
End Type




'base effect class (eg. for newsevents, programmedata, adcontractbases)
Type TGameModifierBase
	Field data:TData
	'data passed during an update-call
	Field passedParams:TData
	Field conditions:TGameModifierCondition[]
	'constant value of TVTGameModifierBase (CHANGETREND, TERRORISTATTACK, ...)
	Field modifierTypes:Int = 0
	Field _flags:Int = 0
	Global lsKeyChildIndex:TLowerString = New TLowerString.Create("childIndex")
	Global lsKey_name:TLowerString = New TLowerString.Create("_name")
	Global lsKeyDelayExecutionUntilTime:TLowerString = New TLowerString.Create("delayExecutionUntilTime")
	Global lsKeyCustomUndoFuncKey:TLowerString = New TLowerString.Create("customUndoFuncKey")
	Global lsKeyCustomRunFuncKey:TLowerString = New TLowerString.Create("customRunFuncKey")


	'The modifier is not a one-time effect but a long-running one
	'whose effect is undone after a delay (or if a condition is not met anymore)
	'by default modifiers are permanent one-time effects
	Const FLAG_LONG_RUNNING_WITH_UNDO:Int = 1
	Const FLAG_ACTIVATED:Int = 2
	Const FLAG_EXPIRED:Int = 4
	Const FLAG_EXPIRATION_DISABLED:Int = 8
	'a delayed modifier is automatically added to the manager when
	'"run" and not in the the managers list
	Const FLAG_DELAYED_EXECUTION:Int = 16
	Const FLAG_DELAY_MANAGED_BY_MANAGER:Int = 32


	Function CreateNewInstance:TGameModifierBase()
		Return New TGameModifierBase
	End Function


	Method Init:TGameModifierBase(data:TData, extra:TData=Null)
		'by default ignore "children"
		If extra And extra.GetInt(lsKeyChildIndex) > 0 Then Return Null

		Return Self
	End Method


	Method InitTimeDataIfPresent(data:TData)
		If data And data.GetString("time") Then GetData().AddString("time", data.GetString("time"))
	End Method


	Method Copy:TGameModifierBase()
		'deprecated
		'local clone:TGameModifierBase = new self
		Local clone:TGameModifierBase = TGameModifierBase(TTypeId.ForObject(Self).NewObject())
		clone.CopyBasefrom(Self)
		Return clone
	End Method


	Method SetLongRunngingWithUndo()
		SetFlag(FLAG_LONG_RUNNING_WITH_UNDO)
	End Method


	Method CopyBaseFrom:TGameModifierBase(base:TGameModifierBase)
		'only works for numeric/strings!
		If base.data
			data = base.data.copy()
		Else
			data = Null
		EndIf
		modifierTypes = base.modifierTypes

		If Not base.conditions Or base.conditions.length = 0
			conditions = Null
		Else
			conditions = New TGameModifierCondition[base.conditions.length]
			For Local i:Int = 0 Until base.conditions.length
				conditions[i] = base.conditions[i].Copy()
			Next
		EndIf
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


	Method GetConditionIndex:Int(condition:TGameModifierCondition)
		If Not conditions Or conditions.length = 0 Then Return -1
		For Local i:Int = 0 Until conditions.length
			If conditions[i] = condition Then Return i
		Next
		Return -1
	End Method


	Method HasCondition:Int(condition:TGameModifierCondition)
		If Not conditions Or conditions.length = 0 Then Return False
		For Local i:Int = 0 Until conditions.length
			If conditions[i] = condition Then Return True
		Next
		Return False
	End Method


	Method AddCondition:Int(condition:TGameModifierCondition)
		If HasCondition(condition) Then Return False
		conditions :+ [condition]
		Return True
	End Method


	Method ConditionsFulfilled:Int()
		If Not conditions Then Return True
		For Local c:TGameModifierCondition = EachIn conditions
			If Not c.IsFulfilled() Then Return False
		Next
		Return True
	End Method


	Method ToString:String()
		Local name:String = "default"
		If data Then name = data.GetString(lsKey_name, name)
		Return "TGameModifierBase ("+name+")"
	End Method


	Method GetName:String()
		If data Then data.GetString(lsKey_name, "default")
		Return "default"
	End Method


	Method SetModifierType:TGameModifierBase(modifierType:Int, enable:Int=True)
		If enable
			modifierTypes :| modifierType
		Else
			modifierTypes :& ~modifierType
		EndIf
		Return Self
	End Method


	Method HasModifierType:Int(modifierType:Int)
		Return modifierTypes & modifierType
	End Method


	Method HasExpired:Int()
		Return HasFlag(FLAG_EXPIRED)
	End Method


	'set a point in time at which execution will happen
	'means an exact time in the future, not the time "until then"
	Method SetDelayedExecutionTime:Int(delayTime:Long)
		If delayTime > 0
			SetFlag(FLAG_DELAYED_EXECUTION, True)
			GetData().AddLong(lsKeyDelayExecutionUntilTime, delayTime)
		Else
			SetFlag(FLAG_DELAYED_EXECUTION, False)
			GetData().Remove(lsKeyDelayExecutionUntilTime)
		EndIf
		Return True
	End Method


	Method HasDelayedExecution:Int()
		Return HasFlag(FLAG_DELAYED_EXECUTION)
	End Method


	Method GetDelayedExecutionTime:Long()
		'return "now" or
		If Not HasDelayedExecution() Then Return GetWorldTime().GetTimeGone()
		Return GetData().GetLong(lsKeyDelayExecutionUntilTime, 0)
	End Method


	Method SetData(data:TData)
		Local oldName:String = GetName()
		Self.data = data

		'set back old name?
		If oldName <> "default" Then data.Add(lsKey_name, oldName)
	End Method


	Method GetData:TData()
		If Not data Then data = New TData
		Return data
	End Method


	Method Update:Int(params:TData)
		If params Then passedParams = params

		'check if data contains a time definition and apply it (once)
		If data And Not HasDelayedExecution()
			Local timeString:String = data.GetString("time")
			If timeString
				Local happenTime:Int[] = StringHelper.StringToIntArray(timeString, ",")
				Local timeStamp:Long = GetWorldTime().CalcTime_Auto(-1, happenTime[0], happenTime[1..])
				If timeStamp > 0 Then SetDelayedExecutionTime(timeStamp)
				data.remove("time")
			EndIf
		EndIf

		'if delayed and delay is in the future, set item to be managed
		'by the modifier manager (so it gets updated regularily until
		'delay is gone)
		If HasDelayedExecution() And GetDelayedExecutionTime() > GetWorldTime().GetTimeGone()
			If Not HasFlag(FLAG_DELAY_MANAGED_BY_MANAGER)
				If Not GetGameModifierManager().ContainsModifier(Self)
					GetGameModifierManager().Add(Self)
				EndIf
				SetFlag(FLAG_DELAY_MANAGED_BY_MANAGER, True)
			EndIf
			Return False
		EndIf

		'if HasDelayedExecution() then print "effect running now"


		Local conditionsOK:Int = ConditionsFulfilled()
		'run if not done yet and needed
		If Not HasFlag(FLAG_ACTIVATED)
			If conditionsOK
				Run(passedParams)
			EndIf
		EndIf

		'undo/expire if needed (might happen in same Update()-call as the
		'run() above
		If HasFlag(Flag_ACTIVATED)
			If Not HasFlag(FLAG_EXPIRATION_DISABLED) And (Not conditions Or Not conditionsOK)
				If HasFlag(FLAG_LONG_RUNNING_WITH_UNDO)
					Undo(passedParams)
				Else
					'unsetting flag necessary for running one-time event multiple times
					SetFlag(FLAG_ACTIVATED, False)
				EndIf

				If HasFlag(FLAG_EXPIRATION_DISABLED)
					Return True
				Else
					SetFlag(FLAG_EXPIRED, True)
					'reset params?
					passedParams = Null
					Return False
				EndIf
			EndIf
		EndIf

		Return True
	End Method


	'call to undo the changes - if possible
	Method Undo:Int(params:TData)
		'skip if not run before
		If Not HasFlag(FLAG_ACTIVATED) Then Return False

		Local result:Int
		If data And data.GetString(lsKeyCustomUndoFuncKey)
			result = GetGameModifierManager().RunUndoFunction(data.GetString(lsKeyCustomUndoFuncKey), Self, params)
		Else
			result = UndoFunc(params)
		EndIf

		'mark as not-run
		SetFlag(FLAG_ACTIVATED, False)

		Return result
	End Method


	'call to handle/emit the modifier/effect
	Method Run:Int(params:TData)
		'skip if already running
		If HasFlag(FLAG_ACTIVATED) Then Return False

		Local result:Int
		If data And data.GetString(lsKeyCustomRunFuncKey)
			result = GetGameModifierManager().RunRunFunction(data.GetString(lsKeyCustomRunFuncKey), Self, params)
		Else
			result = RunFunc(params)
		EndIf

		'mark as run
		SetFlag(FLAG_ACTIVATED, True)

		Return result
	End Method


	Method UndoFunc:Int(params:TData)
'		print "UndoFunc: " + ToString()
		Return True
	End Method


	'override this function in custom types
	Method RunFunc:Int(params:TData)
		Print "RunFunc: " +ToString()
		Print "   data: "+GetData().ToString()
		If params
			Print " params: "+params.ToString()
		EndIf

		Return True
	End Method
End Type




'modifier to modify GameConfig.data-values
'(this way other functions can access the information without needing
' knowledge about the modifiers)
Type TGameModifier_GameConfig Extends TGameModifierBase
	Global modKeyModifierKey:TLowerString = New TLowerString.Create("modifierKey")
	Global modKeyRelative:TLowerString = New TLowerString.Create("relative")
	Global modKeyValue:TLowerString = New TLowerString.Create("value")
	Global modKeyValueChange:TLowerString = New TLowerString.Create("value.change")
	Global modKeyValueBackup:TLowerString = New TLowerString.Create("value.backup")


	Function CreateNewInstance:TGameModifier_GameConfig()
		Return New TGameModifier_GameConfig
	End Function


	Method Init:TGameModifier_GameConfig(data:TData, extra:TData=Null)
		If Not Super.Init(data, extra) Then Return Null

		If data Then Self.data = data.copy()

		Return Self
	End Method


	Method ToString:String()
		Return "TGameModifier_GameConfig ("+GetName()+")"
	End Method


	Method UndoFunc:Int(params:TData)
		Local modKey:String = GetData().GetString(modKeyModifierKey)
		If Not modKey Then Return False

		Local valueChange:Float = GetData().GetFloat(modKeyValueChange, 0.0)
		If valueChange = 0.0 Then Return False

		'local valueBackup:Float = GetData().GetFloat("value.backup")
		Local value:Float = GameConfig.GetModifier(modKey)
		'local relative:Int = GetData().GetBool("relative")

		'restore
		GameConfig.SetModifier(modKey, value - valueChange)

		'print "TGameModifier_GameConfig: restored ~q"+modKey+"~q. value "+value+" => "+GameConfig.GetModifier(modKey)

		Return True
	End Method


	'override this function in custom types
	Method RunFunc:Int(params:TData)
		Local modKey:String = GetData().GetString(modKeyModifierKey)
		If Not modKey Then Return False

		Local value:Float = GetData().GetFloat(modKeyValue, 0.0)
		If value = 0.0 Then Return False

		Local valueBackup:Float = GameConfig.GetModifier(modKey)
		Local relative:Int = GetData().GetBool(modKeyRelative)

		'backup
		GetData().AddFloat(modKeyValueBackup, valueBackup)

		'adjust
		If relative
			GetData().AddFloat(modKeyValueChange, valueBackup * value)
			GameConfig.SetModifier(modKey, valueBackup * (1+value))
		Else
			GetData().AddFloat(modKeyValueChange, value)
			GameConfig.SetModifier(modKey, valueBackup + value)
		EndIf

		'print "TGameModifier_GameConfig: modified ~q"+modKey+"~q. value "+valueBackup+" => "+GameConfig.GetModifier(modKey)

		Return True
	End Method
End Type




Type TGameModifierGroup
	Field entries:TMap
	Global _nilNode:TNode = New TNode._parent

	Method Copy:TGameModifierGroup()
		Local c:TGameModifierGroup = New TGameModifierGroup
		If entries
			Local node:TNode = entries._FirstNode()
			While node And node <> _nilNode
				Local l:TList = TList(node._value)
				If Not l Then Continue

				For Local m:TGameModifierBase = EachIn l
					c.AddEntry(String(node._key), m.copy())
				Next

				'move on to next node
				node = node.NextNode()
			Wend
		EndIf

		Return c
	End Method


	Method GetList:TList(trigger:String)
		If Not entries Then Return Null
		Return TList(entries.ValueForKey(trigger.ToLower()))
	End Method


	Method RemoveList:Int(trigger:String)
		If Not entries Then Return False
		Return entries.Remove(trigger.ToLower())
	End Method


	Method RemoveOrphans:Int()
		Local emptyLists:String[]
		For Local trigger:String = EachIn entries.Keys()
			Local l:TList = GetList(trigger)
			If l And l.count() = 0 Then emptyLists :+ [trigger]
		Next
		For Local trigger:String = EachIn emptyLists
			RemoveList(trigger)
		Next
		Return emptyLists.Length
	End Method


	'checks if an certain modifier type is existent
	Method HasEntryWithModifierType:Int(trigger:String, modifierType:Int) {_exposeToLua}
		Local list:TList = GetList(trigger)
		If Not list Then Return False

		For Local modifier:TGameModifierBase = EachIn list
			If modifier.HasModifierType(modifierType) Then Return True
		Next
		Return False
	End Method


	'checks if an effect was already added before
	Method HasEntry:Int(trigger:String, entry:TGameModifierBase)
		If Not entry Then Return False
		Local list:TList = GetList(trigger)
		If Not list Then Return False

		Return list.contains(entry)
	End Method


	Method AddEntry:Int(trigger:String, entry:TGameModifierBase)
		'skip if already added
		If HasEntry(trigger, entry) Then Return False

		'add effect
		Local list:TList = GetList(trigger)
		If Not list
			list = CreateList()
			If Not entries Then entries = New TMap
			entries.Insert(trigger.ToLower(), list)
		Else
			'skip if already added
			If list.Contains(entry) Then Return False
		EndIf

		list.AddLast(entry)

		Return True
	End Method


	Method RemoveEntry:Int(trigger:String, entry:TGameModifierBase)
		If trigger
			Local l:TList = GetList(trigger)
			If Not l Then Return False

			l.Remove(entry)
			'remove empty list
			If l.count() = 0 Then RemoveList(trigger)
		Else
			For Local trigger:String = EachIn entries.Keys()
				RemoveEntry(trigger, entry)
			Next

			RemoveOrphans()
		EndIf
	End Method


	Method RemoveExpiredEntries:Int(trigger:String="")
		If trigger
			Local l:TList = GetList(trigger)
			If Not l Then Return False

			For Local entry:TGameModifierBase = EachIn l.Copy()
				If entry.HasExpired() Then l.Remove(entry)
			Next
		Else
			For Local trigger:String = EachIn entries.Keys()
				RemoveExpiredEntries(trigger)
			Next
		EndIf
	End Method


	Method Update:Int(trigger:String, params:TData)
		Local l:TList = GetList(trigger)
		If Not l Then Return 0

		For Local modifier:TGameModifierBase = EachIn l
			modifier.Update(params)
		Next

		Return l.Count()
	End Method


	Method Run:Int(trigger:String, params:TData)
		Local l:TList = GetList(trigger)
		If Not l Then Return 0

		For Local modifier:TGameModifierBase = EachIn l
			modifier.Run(params)
		Next

		Return l.Count()
	End Method
End Type


'grouping various triggers and triggering "all" or "one"
'of them
Type TGameModifierChoice Extends TGameModifierBase
	Field modifiers:TGameModifierBase[]
	Field modifiersProbability:Int[]
	'how child elements are choosen: "or" or "and" ?
	Field chooseType:String = 1

	Global lsKeyChildIndex:TLowerString = new TLowerString.Create("childIndex")

	Const CHOOSETYPE_OR:Int = 0
	Const CHOOSETYPE_AND:Int = 1


	Function CreateNewInstance:TGameModifierChoice()
		Return New TGameModifierChoice
	End Function


	Function CreateNewChoiceInstance:TGameModifierBase()
		Return New TGameModifierBase
	End Function


	Method Copy:TGameModifierChoice()
		Local clone:TGameModifierChoice = New TGameModifierChoice
		clone.CopyFromChoice(self)

		Return clone
	End Method


	Method CopyFromChoice:TGameModifierChoice(choice:TGameModifierChoice)
		Self.CopyBaseFrom(choice)
		Self.chooseType = choice.chooseType
		Self.modifiersProbability = choice.modifiersProbability[ .. ]
		Self.modifiers = New TGameModifierBase[ choice.modifiers.length ]
		For Local i:Int = 0 Until Self.modifiers.length
			If choice.modifiers[i] Then Self.modifiers[i] = choice.modifiers[i].Copy()
		next 
		Return Self
	End Method


	Method Init:TGameModifierChoice(data:TData, extra:TData=Null)
		If data.GetString("choose").ToLower() = "or"
			chooseType = CHOOSETYPE_OR
		Else
			chooseType = CHOOSETYPE_AND
		EndIf

		'only load child-options for the parental one
		If Not extra Or extra.GetInt(lsKeyChildIndex) = 0 Then LoadChoices(data)

		Return Self
	End Method


	Method LoadChoices:Int(data:TData)
		'load children
		Local childIndex:Int = 0
		Local child:TGameModifierBase
		Local extra:TData = New TData
		Repeat
			childIndex :+1
			extra.AddInt(lsKeyChildIndex, childIndex)
			'create the choice based on the defined type for the children
			child = CreateNewChoiceInstance().Init(data, extra)
			If child
				Self.modifiers :+ [child]
				Self.modifiersProbability :+ [1]
			EndIf
		Until Not child
	End Method


	'override to trigger a specific news
	Method RunFunc:Int(params:TData)
		If choosetype = CHOOSETYPE_OR
			'loop through all options and choose the one with the
			'probability below choosen one
			Local randValue:Int = RandRange(0,100)
			Local lastProbability:Int = 0
			Local currProbability:Int = 0
			For Local i:Int = 0 Until modifiers.length
				currProbability = modifiersProbability[i] + lastProbability

				'found the correct one - or trigger at least the last one
				If (randValue >= lastProbability And randValue < currProbability) Or i = modifiers.length -1
					modifiers[i].RunFunc(params)
					Exit
				EndIf

				lastProbability = currProbability
			Next
		Else
			For Local m:TGameModifierBase = EachIn modifiers
				m.RunFunc(params)
			Next
		EndIf
	End Method
End Type




Type TGameModifierCondition
	Field enabled:Int = True

	Method Copy:TGameModifierCondition()
		Local clone:TGameModifierCondition = New TGameModifierCondition
		clone.enabled = enabled

		Return clone
	End Method


	Method CopyBaseFrom:TGameModifierCondition(origin:TGameModifierCondition)
		If origin
			Self.enabled = origin.enabled
		EndIf

		Return Self
	End Method


	Method Disable:Int()
		enabled = False
	End Method


	Method IsFulfilled:Int()
		Return enabled = True
	End Method
End Type




Type TGameModifierCondition_TimeLimit Extends TGameModifierCondition
	Field timeBegin:Long = -1
	Field timeEnd:Long = -1
	Field timeDuration:Int = -1

	Method Copy:TGameModifierCondition_TimeLimit()
		Local clone:TGameModifierCondition_TimeLimit = New TGameModifierCondition_TimeLimit
		clone.CopyBaseFrom(Self)
		clone.timeBegin = Self.timeBegin
		clone.timeEnd = Self.timeEnd
		clone.timeDuration = Self.timeDuration

		Return clone
	End Method


	Method SetTimeEnd(time:Long)
		timeEnd = time
	End Method


	Method SetTimeBegin(time:Long)
		timeBegin = time
	End Method


	Method SetTimeBegin_Auto(timeType:Int, timeValues:Int[])
		SetTimeBegin( GetWorldTime().CalcTime_Auto(-1, timeType, timeValues) )
	End Method


	Method IsFulfilled:Int()
		If Not Super.IsFulfilled() Then Return False
		'started running?
		If timeBegin >= 0 And timeBegin > GetWorldTime().GetTimeGone() Then Return False
		'still running
		If timeEnd >= 0 And timeEnd < GetWorldTime().GetTimeGone() Then Return False
		Return True
	End Method
End Type
