SuperStrict
Import "Dig/base.util.math.bmx"



Type TXPContainer
	Field values:Int[]
	'average of "all values"
	Field average:Float
	'average of values > 0
	Field averageUsed:Float
	Const MAX_XP:Int = 10000
	
	Method GetValueIndex:Int(key:Int) abstract
	Method GetValueKey:Int(index:Int) abstract
	'takes into consideration OTHER ids too 
	'(eg "actor" for "supportingactor")
	Method GetEffectivePercentage:Float(key:Int) abstract
	'defines the amount of "to add" XP (based on the passed "extra" or
	'a constant value?)
	Method GetNextGain:Int(key:Int, extra:object, affinity:Float) abstract


	Method Set(key:Int, value:Int)
		'limit experience
		value = MathHelper.Clamp(value, 0, MAX_XP)

		Local index:Int = GetValueIndex(key)
		If values.length <= index Then values = values[ .. index + 1]
		values[index] = value

		'recalculate total (average)
		RecalculateAverage()
	End Method


	Method Get:Int(key:Int)
		Local index:Int = GetValueIndex(key)
		If values.length <= index Then Return 0

		Return values[index]
	End Method
	

	Method GetPercentage:Float(key:Int)
		Return Get(key) / Float(MAX_XP)
	End Method


	Method GetBestKey:Int()
		If values.length = 0 Then Return 0

		Local bestIndex:Int = -1
		Local bestValue:Int
		For Local index:Int = 0 Until values.length
			If index = -1 Or bestValue < values[index] 
				bestIndex = index
				bestValue = values[index]
			EndIf
		Next

		Return GetValueKey(bestIndex)
	End Method


	'returns best xp value
	Method GetBest:Int()
		If values.length = 0 Then Return 0

		Local bestIndex:Int = -1
		Local bestValue:Int
		For Local index:Int = 0 Until values.length
			If bestIndex = -1 Or bestValue < values[index] 
				bestIndex = index
				bestValue = values[index]
			EndIf
		Next
		
		Return bestValue
	End Method


	'returns xp percentage of best value
	Method GetBestPercentage:Float()
		Return GetBest() / Float(MAX_XP)
	End Method
	
	Method RecalculateAverage()
		If values.length = 0 
			average = 0
			averageUsed = 0
			Return
		EndIf
		
		Local totalCount:Int = 0
		Local usedCount:Int = 0
		For Local xp:Int = EachIn values
			If xp > 0
				usedCount :+ 1
				averageUsed :+ xp
			EndIf
			totalCount :+ 1
			average :+ xp
		Next
		If totalCount > 0 Then average :/ totalCount
		If usedCount > 0 Then averageUsed :/ usedCount
	End Method
End Type