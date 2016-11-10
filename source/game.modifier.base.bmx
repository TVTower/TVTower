Rem
	Contains:
		TGameModifierBase
		TGameModifierGroup
		TGameModifier_TimeLimited extends TGameModifierBase
		TGameModifierTimeFrame
		TGameModifierBaseCreator
EndRem	
SuperStrict
Import "Dig/base.util.data.bmx"
Import "Dig/base.util.mersenne.bmx"
Import "game.world.worldtime.bmx"

'as game modifiers are stored in savegames, we need a way to decouple
'function pointers from saved objects
'We store all theses functions in a collection and retrieve them via
'individual keys/identifiers

Type TGameModifierFunctionsCollection
	Field functions:TMap = CreateMap()
	Global _instance:TGameModifierFunctionsCollection


	Function GetInstance:TGameModifierFunctionsCollection()
		if not _instance then _instance = new TGameModifierFunctionsCollection
		return _instance
	End Function


	Method RegisterRunFunction(key:string, func:int(source:TGameModifierBase, params:TData))
		key = "run_"+key.ToLower()
		if functions.Contains(key) then return

		functions.Insert(key, new TGameModifierRunFunction.Init(key, func))
	End Method


	Method RegisterUndoFunction(key:string, func:int(source:TGameModifierBase))
		key = "undo_"+key.ToLower()
		if functions.Contains(key) then return

		functions.Insert(key, new TGameModifierUndoFunction.Init(key, func))
	End Method


	Method GetRunFunction:TGameModifierRunFunction(key:string)
		return TGameModifierRunFunction(functions.ValueForKey("run_"+key.ToLower()))
	End Method


	Method GetUndoFunction:TGameModifierUndoFunction(key:string)
		return TGameModifierUndoFunction(functions.ValueForKey("undo_"+key.ToLower()))
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetGameModifierFunctionsCollection:TGameModifierFunctionsCollection()
	Return TGameModifierFunctionsCollection.GetInstance()
End Function




Type TGameModifierRunFunction
	Field key:string
	Field func:int(source:TGameModifierBase, params:TData)

	Method Init:TGameModifierRunFunction(key:string, func:int(source:TGameModifierBase, params:TData))
		self.key = key.ToLower()
		self.func = func
		return self
	End Method
End Type	




Type TGameModifierUndoFunction
	Field key:string
	Field func:int(source:TGameModifierBase)

	Method Init:TGameModifierUndoFunction(key:string, func:int(source:TGameModifierBase))
		self.key = key.ToLower()
		self.func = func
		return self
	End Method
End Type




'base effect class (eg. for newsevents, programmedata, adcontractbases)
Type TGameModifierBase
	Field data:TData
	'constant value of TVTGameModifierBase (CHANGETREND, TERRORISTATTACK, ...)
	Field modifierTypes:int = 0
	Field _customRunFuncKey:string
	Field _customUndoFuncKey:string


	Function CreateNewInstance:TGameModifierBase()
		return new TGameModifierBase
	End Function


	Method Copy:TGameModifierBase()
		local clone:TGameModifierBase = new TGameModifierBase
		clone.CopyBasefrom(self)
		return clone
	End Method


	Method CopyBaseFrom:TGameModifierBase(base:TGameModifierBase)
		'only works for numeric/strings!
		data = base.data.copy()
		modifierTypes = base.modifierTypes
	End Method



	Method Init:TGameModifierBase(data:TData, index:string="")	
		'by default ignore indexes <> "" (aka "children")
		if index <> "" and index <> "0" then return null
		
		return self
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
		return False
	End Method


	Method HasBegun:int()
		return True
	End Method


	Method Expire:int()
		'eg. undo things here
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


	Method SatisfiesConditions:int(params:TData)
		return True
	End Method


	'call to undo the changes - if possible
	Method Undo:int()
		if _customUndoFuncKey
			local wrapper:TGameModifierUndoFunction = GetGameModifierFunctionsCollection().GetUndoFunction(_customUndoFuncKey)
			if wrapper then return wrapper.func(self)
		endif

		return UndoFunc()
	End Method


	'call to handle/emit the modifier/effect
	Method Run:int(params:TData)
		if not SatisfiesConditions(params) then return False

		if _customRunFuncKey
			local wrapper:TGameModifierRunFunction = GetGameModifierFunctionsCollection().GetRunFunction(_customRunFuncKey)
			if wrapper then return wrapper.func(self, params)
		endif

		return RunFunc(params)
	End Method


	Method UndoFunc:int()
	End Method

	'override this function in custom types
	Method RunFunc:int(params:TData)
		print ToString()
		print "data: "+GetData().ToString()
		print "params: "+params.ToString()
	
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


	Method Init:TGameModifierChoice(data:TData, index:string)
		if data.GetString("choose").ToLower() = "or"
			chooseType = CHOOSETYPE_OR
		else
			chooseType = CHOOSETYPE_AND
		endif

		'only load child-options for the parental one
		if index = "" then LoadChoices(data)

		return self
	End Method
	

	Method LoadChoices:int(data:TData)
		'load children
		local childIndex:int = 0 
		local child:TGameModifierBase
		Repeat
			childIndex :+1
			'create the choice based on the defined type for the children
			child = CreateNewChoiceInstance().Init(data, childIndex)
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



'base modifier class (eg. for newsevents, programmedata, adcontractbases)
Type TGameModifier_TimeLimited extends TGameModifierBase
	Field timeFrame:TGameModifierTimeFrame = new TGameModifierTimeFrame
	Field expired:int = False


	Function CreateNewInstance:TGameModifier_TimeLimited()
		return new TGameModifier_TimeLimited
	End Function


	Method Copy:TGameModifier_TimeLimited()
		local clone:TGameModifier_TimeLimited = new TGameModifier_TimeLimited
		clone.CopyBaseFrom(self)
		clone.timeFrame = self.timeFrame.Copy()
		clone.expired = self.expired
		return clone
	End Method 


	Method HasExpired:int()
		if not timeFrame or expired then return True

		return timeFrame.HasExpired()
	End Method


	Method HasBegun:int()
		if not timeFrame or expired then return True

		return timeFrame.HasBegun()
	End Method
	

	Method Run:int(params:TData)
		if expired then return False
		
		if timeFrame and timeFrame.HasExpired()
			Undo()
			expired = True
		endif

		return Super.Run(params)
	End Method


	'override this function in custom types
	Method RunFunc:int(params:TData)
		if timeFrame and timeFrame.HasExpired() 
			Throw "Try to run an expired modifier"
			return False
		endif
		
		print ToString()
		print "params: "+params.ToString()
	
		return True
	End Method
End Type




Type TGameModifierTimeFrame
	Field timeBegin:Long = -1
	Field timeEnd:Long = -1
	Field timeDuration:int = -1


	Method Copy:TGameModifierTimeFrame()
		local clone:TGameModifierTimeFrame = new TGameModifierTimeFrame
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


	Method HasExpired:int()
		if timeEnd >= 0
			if timeEnd < GetWorldTime().GetTimeGone() then return True
		endif
		return False
	End Method


	Method HasBegun:int()
		if timeBegin >= 0 then return timeBegin < GetWorldTime().GetTimeGone()
		return True
	End Method
End Type



'anonymous creator of effects
'approach allows easy creation of effect-type-instances the caller
'does not need to know - allows sharing of effects between various
'classes
Type TGameModifierBaseCreator
	Field registeredModifiers:TMap = CreateMap()

	'register an effect by passing the name + creator function
	Method RegisterModifier(modifierName:string, modifier:TGameModifierBase)
		registeredModifiers.insert(modifierName.ToLower(), modifier)
	End Method


	Method CreateModifier:TGameModifierBase(modifierName:string, data:TData)
		local modifier:TGameModifierBase = TGameModifierBase(registeredModifiers.ValueForKey( modifierName.Tolower() ))
		if modifier
			'create/return a specific instance (of the same type)
			return modifier.CreateNewInstance().Init(data, "")
		endif
		return null
	End Method
End Type

Global GameModifierCreator:TGameModifierBaseCreator = New TGameModifierBaseCreator

