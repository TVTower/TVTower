SuperStrict
Import "Dig/base.util.math.bmx"
Import "game.gameobject.bmx"
Import "game.gameconstants.bmx"
Import "game.modifier.base.bmx"
Import "game.gameinformation.base.bmx"
Import "Dig/base.framework.entity.spriteentity.bmx" 'for sprite cache
Import "Dig/base.util.string.bmx"
Import "Dig/base.util.bitmask.bmx"
Import "common.misc.templatevariables.bmx" 'for replacement function
Import "game.gamescriptexpression.base.bmx"


'could be done as "interface"
Type TBroadcastMaterialSourceBase Extends TNamedGameObject {_exposeToLua="selected"}
	Field title:TLocalizedString
	Field description:TLocalizedString

	'contains "numeric" modifiers (simple key:num-pairs)
	Field modifiers:TData
	Field effects:TGameModifierGroup

	Field topicality:Float = 1.0
	Field flags:Int = 0
	Field broadcastFlags:TTriStateIntBitmask

	Method GenerateGUID:String()
		Return "broadcastmaterialsource-base-"+id
	End Method


	Method GetMaterialSourceType:Int() {_exposeToLua}
		Return TVTBroadcastMaterialSourceType.UNKNOWN
	End Method


	Method CopyBaseFrom:TBroadcastMaterialSourceBase(base:TBroadcastMaterialSourceBase)
		title = base.title.copy()
		description = base.description.copy()
		modifiers = base.CopyModifiers()
		effects = base.CopyEffects()
		topicality = base.topicality
		flags = base.flags
		If base.broadcastFlags
			broadcastFlags = base.broadcastFlags.Copy()
		EndIf

		Return Self
	End Method


	'returns the stored value for a modifier - defaults to "100%"
	Method GetModifier:Float(modifierKey:Object, defaultValue:Float = 1.0)
		If not modifiers then Return defaultValue
		Return modifiers.GetFloat(modifierKey, defaultValue)
	End Method


	'stores a modifier value
	Method SetModifier:Int(modifierKey:Object, value:Float)
		'skip adding the modifier if it is the same - or a default value
		'-> keeps datasets smaller
		If modifiers
			If GetModifier(modifierKey) = value Then Return False
		Else
			modifiers = new TData
		EndIf

		modifiers.AddNumber(modifierKey, value)
		Return True
	End Method


	Global _nilNode:TNode = New TNode._parent
	Method CopyModifiers:TData()
		If Not modifiers Then Return Null

		Local clone:TData = New TData

		'find first hit
		if modifiers.data
			Local node:TNode = modifiers.data._FirstNode()
			While node And node <> _nilNode
				If TGameModifierBase(node._value)
					clone.Add(node._key, TGameModifierBase(node._value).Copy())
				Else
					clone.Add(node._key, node._value)
				EndIf

				'move on to next node
				node = node.NextNode()
			Wend
		EndIf

		Return clone
	End Method


	Method CopyEffects:TGameModifierGroup()
		If Not effects Then Return Null

		Return effects.Copy()
	End Method
	
	
	Method GetEffectsList:TList(name:String)
		if not effects then Return Null
		Return effects.GetList(name)
	End Method


	Method GetEffectsCount:Int(name:String)
		if Not effects Then Return 0
		Local l:TList = effects.GetList(name)
		If l Then Return l.Count()
		Return 0
	End Method


	Method GetEffects:TGameModifierGroup(createIfMissing:Int = True)
		if not effects and createIfMissing Then effects = New TGameModifierGroup
		Return effects
	End Method
	
	
	Method UpdateEffects:Int(name:String, params:TData)
		If Not effects Then Return False
		Return effects.Update(name, params)
	End Method


	Method GetTitle:String() {_exposeToLua}
		If title Then Return title.Get()
		Return ""
	End Method


	Method GetDescription:String() {_exposeToLua}
		If description Then Return description.Get()
		Return ""
	End Method



	Method HasFlag:Int(flag:Int) {_exposeToLua}
		Return (flags & flag) > 0
	End Method


	Method SetFlag(flag:Int, enable:Int=True)
		If enable
			flags :| flag
		Else
			flags :& ~flag
		EndIf
	End Method


	Method HasBroadcastFlag:Int(flag:Int) {_exposeToLua}
		If not broadcastFlags then Return False
		Return broadcastFlags.Has(flag)
'		Return (broadcastFlags & flag) > 0
	End Method


	Method SetBroadcastFlag(flag:Int, enable:Int=True)
		If not broadcastFlags then broadcastFlags = new TTriStateIntBitmask
		broadcastFlags.Set(flag, enable)
rem
		If enable
			broadcastFlags :| flag
		Else
			broadcastFlags :& ~flag
		EndIf
endrem
	End Method


	'add an effect defined in a data container
	'effectData should be consisting of:
	'trigger = "broadcast", "firstbroadcast", "happen"...
	'type = "triggernews" (the key under which the desired effect was registered)
	'news-5
	Method AddEffectByData:Int(effectData:TData)
		If Not effectData Then Return False

		Local effectName:String = effectData.GetString("type")
		Local effectTrigger:String = effectData.GetString("trigger")
		If Not effectName Or Not effectTrigger Then Return False

		Local effect:TGameModifierBase = GetGameModifierManager().CreateAndInit(effectName, effectData)
		If Not effect Then Return False
		
		GetEffects(True).AddEntry(effectTrigger, effect)
		Return True
	End Method


	Method GetQuality:Float() {_exposeToLua}
		Return 0
	End Method
End Type


'could be done as "interface"
Type TBroadcastMaterialSource Extends TBroadcastMaterialSourceBase {_exposeToLua="selected"}
	'how many times that source was broadcasted
	'(per player, 0 = unknown - allows to adjust "before game start" value)
	Field timesBroadcasted:Int[] = [0]
	'the maximum _current_ amount of broadcasts possible for this licence
	Field broadcastLimit:Int = 0
	'the maximum amount of broadcasts possible for this licence after reset
	Field broadcastLimitMax:Int = -1

	'from when to when you are allowed to broadcast this material
	Field broadcastTimeSlotStart:Int = -1
	Field broadcastTimeSlotEnd:Int = -1

	'maximum reachLevel a material was licenced for
	'< 0 disables any level limitation
	Field licencedReachLevel:Int = -1

	'unpersisted fields for custom images
	Field customImagePresent:Int = 0 {nosave}
	Field customSprite:TSprite {nosave}


	Global modKeyTopicality_AgeLS:TLowerString = New TLowerString.Create("topicality::age")
	Global modKeyTopicality_TimesBroadcastedLS:TLowerString = New TLowerString.Create("topicality::timesBroadcasted")
	Global modKeyTopicality_WearoffLS:TLowerString = New TLowerString.Create("topicality::wearoff")
	Global modKeyPriceLS:TLowerString = New TLowerString.Create("price")


	Method GenerateGUID:String()
		Return "broadcastmaterialsource-"+id
	End Method


	Method Initialize:Int()
		timesBroadcasted = [0]
	End Method


	Method _ReplaceScriptExpressions:TLocalizedString(text:TLocalizedString, useTime:Long = 0)
		Local result:TLocalizedString = text.copy()
		if useTime = 0 then useTime = GetWorldTime().GetTimeGone()

		'print "_ReplaceScriptExpressions: " + text.Get()
		'for each defined language we check for existent script expressions
		'which can contain variables or other logic.
		For Local langID:Int = EachIn text.GetLanguageIDs()
			Local valueOld:String = text.Get(langID)
			Local context:SScriptExpressionContext = new SScriptExpressionContext(self, langID, Null)
			Local valueNew:TStringBuilder = GameScriptExpression.ParseLocalizedText(valueOld, context)
			If valueOLD <> valueNew.HashCode()
				result.Set(valueNew.ToString(), langID)
			EndIf
		Next
		Return result
	End Method


	Method GetLicencedReachLevel:Int()
		Return licencedReachLevel
	End Method


	'return price for a potential relicencing
	Method GetRelicenceForReachLevelPrice:Int(reachLevel:Int)
		Return 0
	End Method


	'extending classes might add custom restrictions here (payment)
	Method CanRelicenceForReachLevel:Int(reachLevel:Int)
		Return True
	End Method


	'set a new reach level limitation
	Method RelicenceForReachLevel:Int(reachLevel:Int)
		Self.licencedReachLevel = reachLevel
		Return True
	End Method


	'playerID < 0 means "get all"
	Method GetTimesBroadcasted:Int(playerID:Int = -1)
		If playerID >= timesBroadcasted.length Then Return 0
		If playerID >= 0 Then Return timesBroadcasted[playerID]

		Local result:Int = 0
		For Local i:Int = 0 Until timesBroadcasted.length
			result :+ timesBroadcasted[i]
		Next
		Return result
	End Method


	Method SetTimesBroadcasted:Int(times:Int, playerID:Int)
		If playerID < 0 Then playerID = 0

		'resize array if player has no entry yet
		If playerID >= timesBroadcasted.length
			timesBroadcasted = timesBroadcasted[.. playerID + 1]
		EndIf

		timesBroadcasted[playerID] = times
	End Method


	Method SetBroadcastLimit:Int(broadcastLimit:Int = -1)
		SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_LIMIT_ENABLED, broadcastLimit > 0)

		Self.broadcastLimitMax = broadcastLimit
		Self.broadcastLimit = broadcastLimit
	End Method


	Method CanStartBroadcastAtTime:int(broadcastType:int, day:int, hour:int) {_exposeToLua}
		Return True
	End Method


	Method CanStartBroadcastAtTimeSlot:Int(broadcastType:Int, day:int, hour:Int) {_exposeToLua}
		'check timeslot limits
		if broadcastType = TVTBroadcastMaterialType.PROGRAMME
			if HasBroadcastTimeSlot()
				Local slotStart:Int = GetBroadcastTimeSlotStart()
				Local slotEnd:Int = GetBroadcastTimeSlotEnd()
				'in case of over night (11:00 - 01:00)
				'convert end time to "absolute" (1:00 becomes 25:00)
				If slotStart > slotEnd Then slotEnd :+ 24
				'hour might be "of next day" (even if only 1 hour before start)
				If hour <  slotStart Then hour :+ 24
				

				'subtract 1 as this is the hour in which the programme will end
				'2 blocks movie at 20:00 will end 21:55
				'and broadcastSlotEnd is "exclusive" not "inclusive"
				'ex: 
				'1 - 0, begin 23, blocks 1:   (23 >= 1 and (23 + 1 - 1) < 0+24 -> True
				'6 - 10, begin 5, blocks 3:   (5+24 >= 6 and (5+24 + 3 - 1) < 10 -> False
				'6 - 10, begin 6, blocks 3:   (6 >= 6 and (6 + 3 - 1) < 10 -> True
				'6 - 10, begin 7, blocks 3:   (7 >= 6 and (7 + 3 - 1) < 10 -> True
				'6 - 10, begin 8, blocks 3:   (8 >= 6 and (8 + 3 - 1) < 10 -> False
				'21 - 1, begin 20, blocks 3:   (20+24 >= 21 and (20+24 + 3 - 1) < 1+24 -> False
				'21 - 1, begin 21, blocks 3:   (21 >= 21 and (21 + 3 - 1) < 1+24 -> True
				'21 - 1, begin 22, blocks 3:   (22 >= 21 and (22 + 3 - 1) < 1+24 -> True
				'21 - 1, begin 23, blocks 3:   (23 >= 21 and (23 + 3 - 1) < 1+24 -> False
				'22 - 4, begin 0, blocks 3 :   (0+24 >= 22 and (0+24 + 3 - 1) < 4+24 -> True
				'22 - 4, begin 1, blocks 3 :   (1+24 >= 22 and (1+24 + 3 - 1) < 4+24 -> True
				'22 - 4, begin 2, blocks 3 :   (2+24 >= 22 and (2+24 + 3 - 1) < 4+24 -> False
				
				Return hour >= slotStart and (hour + GetBlocks(broadcastType) - 1) < slotEnd
			endif
		endif

		Return True
	End Method


	Method GetBroadcastLimitMax:Int() {_exposeToLua}
		Return Self.broadcastLimitMax
	End Method


	Method GetBroadcastLimit:Int() {_exposeToLua}
		Return Self.broadcastLimit
	End Method


	Method HasBroadcastLimitEnabled:Int() Final {_exposeToLua}
		Return HasBroadcastFlag(TVTBroadcastMaterialSourceFlag.BROADCAST_LIMIT_ENABLED)
	End Method


	Method HasBroadcastLimitDefined:Int() Final {_exposeToLua}
		Return Self.broadcastLimitMax >= 0
	End Method


	Method HasBroadcastLimit:Int() {_exposeToLua}
		Return HasBroadcastLimitDefined() and HasBroadcastLimitEnabled()
	End Method


	Method isExceedingBroadcastLimit:Int() {_exposeToLua}
		Return GetBroadcastLimit() <= 0 and GetBroadcastLimitMax() >= 0 And HasBroadcastLimit()
	End Method


	Method GetBroadcastTimeSlotStart:Int() {_exposeToLua}
		Return Self.broadcastTimeSlotStart
	End Method


	Method GetBroadcastTimeSlotEnd:Int() {_exposeToLua}
		Return Self.broadcastTimeSlotEnd
	End Method


	Method HasBroadcastTimeSlot:Int()
		Return self.broadcastTimeSlotEnd >= 0 and self.broadcastTimeSlotStart >= 0
	End Method


	Method GetMaxTopicality:Float()
		Return 1.0
	End Method


	'when used as programme
	Method GetProgrammeTopicality:Float() {_exposeToLua}
		Return GetTopicality()
	End Method


	'when used as ad
	Method GetAdTopicality:Float() {_exposeToLua}
		Return GetTopicality()
	End Method


	Method GetTopicality:Float() {_exposeToLua}
		If topicality < 0 Then topicality = GetMaxTopicality()

		'refresh topicality on each request
		'-> avoids a "topicality > MaxTopicality" when MaxTopicality
		'   shrinks because of aging/airing
		topicality = MathHelper.Clamp(topicality, 0, GetMaxTopicality())

		Return topicality
	End Method


	Method CutTopicality:Float(cutModifier:Float=1.0) {_private}
		topicality = MathHelper.Clamp(topicality * cutModifier, 0, GetMaxTopicality())

		Return topicality
	End Method


	Method SetTopicality:Int(topicality:Float)
		Self.topicality = MathHelper.Clamp(topicality, 0, GetMaxTopicality())
	End Method


	'by default (mod = 1.0) this does not refresh at all
	Method RefreshTopicality:Float(refreshModifier:Float = 1.0) {_private}
		topicality = MathHelper.Clamp(topicality * refreshModifier, 0, GetMaxTopicality())

		Return topicality
	End Method


	Method GetBlocks:Int(broadcastType:Int = -1)
		Return 1
	End Method


	Method IsNewBroadcastPossible:Int() {_exposeToLua}
		'false if not controllable
		If Not IsControllable() Then Return False
		'false if licence/contract is not available (temporary, or
		'because broadcast limit was exceeded)
		If Not isAvailable() Then Return False

		Return True
	End Method


	Method IsAvailable:Int()
		Return Not HasBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_AVAILABLE)
	End Method


	Method IsControllable:Int()
		Return Not HasBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_CONTROLLABLE)
	End Method


	Method SetControllable(bool:Int = True)
		SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.NOT_CONTROLLABLE, Not bool)
	End Method


	Method IsProgrammeLicence:Int() {_exposeToLua}
		Return GetMaterialSourceType() = TVTBroadcastMaterialSourceType.PROGRAMMELICENCE
	End Method


	Method IsAdContract:Int() {_exposeToLua}
		Return GetMaterialSourceType() = TVTBroadcastMaterialSourceType.ADCONTRACT
	End Method


	Method IsNews:Int() {_exposeToLua}
		Return GetMaterialSourceType() = TVTBroadcastMaterialSourceType.NEWS
	End Method


	'=== LISTENERS ===
	'methods called when special events happen

	Method doBeginBroadcast(playerID:Int = -1, broadcastType:Int = 0)
		'
	End Method

	Method doFinishBroadcast(playerID:Int = -1, broadcastType:Int = 0)
		'
	End Method
End Type
