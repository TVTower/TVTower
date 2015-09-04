SuperStrict
Import "game.gameobject.bmx"
Import "game.broadcastmaterial.base.bmx"


'could be done as "interface"
Type TBroadcastMaterialSourceBase extends TNamedGameObject {_exposeToLua="selected"}
	Field modifiers:TData = new TData
	Field effects:TGameObjectEffectCollection = New TGameObjectEffectCollection
	'how many times that source was broadcasted
	'(per player, 0 = unknown - allows to adjust "before game start" value)
	Field timesBroadcasted:int[] = [0]
	Field topicality:Float = 1.0
	Field flags:int = 0
	

	Method Initialize:int()
		timesBroadcasted = [0]
	End Method


	'playerID < 0 means "get all"
	Method GetTimesBroadcasted:Int(playerID:int = -1)
		if playerID >= timesBroadcasted.length then Return 0
		if playerID >= 0 then Return timesBroadcasted[playerID]

		local result:int = 0
		For local i:int = 0 until timesBroadcasted.length
			result :+ timesBroadcasted[i]
		Next
		Return result
	End Method


	Method SetTimesBroadcasted:Int(times:int, playerID:int)
		if playerID < 0 then playerID = 0

		'resize array if player has no entry yet
		if playerID >= timesBroadcasted.length
			timesBroadcasted = timesBroadcasted[.. playerID + 1]
		endif

		timesBroadcasted[playerID] = times
	End Method



	'returns the stored value for a modifier - defaults to "100%"
	Method GetModifier:Float(modifierKey:string, defaultValue:Float = 1.0)
		Return modifiers.GetFloat(modifierKey, defaultValue)
	End Method


	'stores a modifier value
	Method SetModifier:int(modifierKey:string, value:Float)
		'skip adding the modifier if it is the same - or a default value
		'-> keeps datasets smaller
		if GetModifier(modifierKey) = value then Return False
		
		modifiers.AddNumber(modifierKey, value)
		Return True
	End Method


	Method GetMaxTopicality:Float()
		Return 1.0
	End Method
	

	Method GetTopicality:Float()
		if topicality < 0 then topicality = GetMaxTopicality()

		'refresh topicality on each request
		'-> avoids a "topicality > MaxTopicality" when MaxTopicality
		'   shrinks because of aging/airing
		topicality = MathHelper.Clamp(topicality, 0, GetMaxTopicality())
		
		Return topicality
	End Method


	Method CutTopicality:Float(cutModifier:float=1.0) {_private}
		topicality = MathHelper.Clamp(topicality * cutModifier, 0, GetMaxTopicality())

		Return topicality
	End Method


	'by default (mod = 1.0) this does not refresh at all
	Method RefreshTopicality:Float(refreshModifier:Float = 1.0) {_private}
		topicality = MathHelper.Clamp(topicality * refreshModifier, 0, GetMaxTopicality())

		Return topicality
	End Method


	Method hasFlag:Int(flag:Int) {_exposeToLua}
		Return flags & flag
	End Method


	Method setFlag(flag:Int, enable:Int=True)
		If enable
			flags :| flag
		Else
			flags :& ~flag
		EndIf
	End Method


	'add an effect defined in a data container
	'effectData should be consisting of:
	'trigger = "broadcast", "firstbroadcast", "happen"...
	'type = "triggernews" (the key under which the desired effect was registered)
	'parameter1-5
	Method AddEffectByData:int(effectData:TData)
		if not effectData then return False

		local effectName:string = effectData.GetString("type").ToLower()
		local effectTrigger:string = effectData.GetString("trigger").ToLower()
		if not effectName or not effectTrigger then return False

		local effect:TGameObjectEffect = GameObjectEffectCreator.CreateEffect(effectName, effectData)
		if not effect then return False

		effects.AddEffect(effectTrigger, effect)
		return True
	End Method



	'=== LISTENERS ===
	'methods called when special events happen

	Method doBeginBroadcast(playerID:int = -1, broadcastType:int = 0)
		'
	End Method

	Method doFinishBroadcast(playerID:int = -1, broadcastType:int = 0)
		'
	End Method
End Type