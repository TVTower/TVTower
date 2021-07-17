SuperStrict
Import "Dig/base.util.math.bmx"
Import "game.gameobject.bmx"
Import "game.gameconstants.bmx"
Import "game.modifier.base.bmx"
Import "game.gameinformation.base.bmx"
Import "Dig/base.util.scriptexpression.bmx"
Import "Dig/base.util.string.bmx"
Import "Dig/base.util.bitmask.bmx"


'could be done as "interface"
Type TBroadcastMaterialSourceBase Extends TNamedGameObject {_exposeToLua="selected"}
	Field title:TLocalizedString
	Field description:TLocalizedString

	'contains "numeric" modifiers (simple key:num-pairs)
	Field modifiers:TData = New TData
	Field effects:TGameModifierGroup = New TGameModifierGroup

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
		Return modifiers.GetFloat(modifierKey, defaultValue)
	End Method


	'stores a modifier value
	Method SetModifier:Int(modifierKey:Object, value:Float)
		'skip adding the modifier if it is the same - or a default value
		'-> keeps datasets smaller
		If GetModifier(modifierKey) = value Then Return False

		modifiers.AddNumber(modifierKey, value)
		Return True
	End Method


	Global _nilNode:TNode = New TNode._parent
	Method CopyModifiers:TData()
		If Not modifiers Then Return Null

		Local clone:TData = New TData

		'find first hit
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

		Return clone
	End Method


	Method CopyEffects:TGameModifierGroup()
		If Not effects Then Return Null

		Return effects.Copy()
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

		Local effectName:String = effectData.GetString("type").ToLower()
		Local effectTrigger:String = effectData.GetString("trigger").ToLower()
		If Not effectName Or Not effectTrigger Then Return False

		Local effect:TGameModifierBase = GetGameModifierManager().CreateAndInit(effectName, effectData)
		If Not effect Then Return False

		effects.AddEntry(effectTrigger, effect)
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
	Field broadcastLimitMax:Int = 0

	'from when to when you are allowed to broadcast this material
	Field broadcastTimeSlotStart:Int = -1
	Field broadcastTimeSlotEnd:Int = -1

	'maximum reachLevel a material was licenced for
	'< 0 disables any level limitation
	Field licencedReachLevel:Int = -1

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


	Method _ReplacePlaceholders:TLocalizedString(text:TLocalizedString, useTime:Long = 0)
		Local result:TLocalizedString = text.copy()
		if useTime = 0 then useTime = GetWorldTime().GetTimeGone()

		'print "_ReplacePlaceholders: " + text.Get()
		'for each defined language we check for existent placeholders
		'which then get replaced by a random string stored in the
		'variable with the same name
		For Local langID:Int = EachIn text.GetLanguageIDs()
			Local value:String = text.Get(langID)
			Local placeHolders:String[] = StringHelper.ExtractPlaceholders(value, "%", True)
			If placeHolders.length = 0 Then Continue

			For Local placeHolder:String = EachIn placeHolders
				Local replacement:String = ""
				Local replaced:Int = False
				If Not replaced Then replaced = ReplaceTextWithGameInformation(placeHolder, replacement, useTime)
				If Not replaced Then replaced = ReplaceTextWithScriptExpression(placeHolder, replacement)
				'replace if some content was filled in
				If replaced Then value = value.Replace("%"+placeHolder+"%", replacement)
				'print "check placeholder: ~q"+placeholder+"~q => ~q"+replacement+"~q"
			Next

			result.Set(value, langID)
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
		SetBroadcastFlag(TVTBroadcastMaterialSourceFlag.HAS_BROADCAST_LIMIT, broadcastLimit > 0)

		Self.broadcastLimitMax = broadcastLimit
		Self.broadcastLimit = broadcastLimit
	End Method


	Method CanBroadcastAtTime:int(broadcastType:int, day:int, hour:int) {_exposeToLua}
		Return True
	End Method


	Method CanBroadcastAtTimeSlot:Int(broadcastType:Int, hour:Int) {_exposeToLua}
		'check timeslot limits
		if broadcastType = TVTBroadcastMaterialType.PROGRAMME
			if HasBroadcastTimeSlot()

				'check if hour is inside of the timespan?
				'check for inside when :  2:00 to 11:00
				'check for outside when: 11:00 to  2:00
				local checkForInside:int = GetBroadcastTimeSlotStart() < GetBroadcastTimeSlotEnd()
				local startSlot:int, endslot:int
				If checkForInside
					startSlot = GetBroadcastTimeSlotStart()
					endSlot = GetBroadcastTimeSlotEnd()
				Else
					startSlot = GetBroadcastTimeSlotEnd()
					endSlot = GetBroadcastTimeSlotStart()
				EndIf

				local isInside:Int = True
				'begin is outside
				if isInside and hour < startSlot Then isInside = False
				'outside "right"
				'alternatively subtract 1 to include "slotEnd" as allowed
				'hour to broadcast a programme in (22-23 would allow a 2 block programme)
				'if isInside and (hour + GetBlocks(broadcastType)-1) > endSlot Then isInside = False
				if isInside and (hour + GetBlocks(broadcastType)) > endSlot Then isInside = False

				if isInside <> checkForInside then Return False
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


	Method HasBroadcastLimit:Int() {_exposeToLua}
		Return HasBroadcastFlag(TVTBroadcastMaterialSourceFlag.HAS_BROADCAST_LIMIT)
	End Method


	Method isExceedingBroadcastLimit:Int() {_exposeToLua}
		Return GetBroadcastLimit() <= 0 And HasBroadcastLimit()
	End Method


	Method GetBroadcastTimeSlotStart:Int() {_exposeToLua}
		Return Self.broadcastTimeSlotStart
	End Method


	Method GetBroadcastTimeSlotEnd:Int() {_exposeToLua}
		Return Self.broadcastTimeSlotEnd
	End Method


	Method HasBroadcastTimeSlot:Int()
		'both need to be set!
		Return broadcastTimeSlotStart >= 0 And broadcastTimeSlotEnd >= 0
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