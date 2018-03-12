SuperStrict
Import Brl.Map




Type TNumericPairInterpolator
	Field map:TMap = new TMap
	Field orderedKeys:Double[]
	Field _cacheInvalid:int = False
	Field interpolationFunction:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)  {nosave}

	Method GetValueForKey:Double(key:Double)
		return double(string(map.ValueForKey(string(key))))
	End Method


	Method Insert(key:Double, value:Double)
		map.Insert(string(key), string(value))

		_cacheInvalid = True
	End Method


	Method GetOrderedKeys:Double[]()
		if _cacheInvalid
			orderedKeys = new Double[0]
			For local k:string = EachIn map.Keys()
				orderedKeys :+ [double(k)]
			Next
			_cacheInvalid = False
		endif

		return orderedKeys
	End Method


	Method GetInterpolatedValue:Double(key:Double)
		local keyA:Double, valueA:Double, indexA:int 
		local keyB:Double, valueB:Double
		local found:int

		'create cache if needed
		GetOrderedKeys()
		
		'need at least 2 values for interpolation
		'else we can only "continue" with the single value
		if orderedKeys.length < 2
			if orderedKeys.length = 1 then return GetValueForKey(orderedKeys[0])
			return 0
		endif

		'find last key _below_ key
		For local i:int = 1 until orderedKeys.length
			if orderedKeys[i] < key then continue
			
			'all values are bigger, no "a" for an a-b interpolation
			'possible
			'if i = 0 then return 0

			'read previous one
			keyA = orderedKeys[i-1]
			'read current one
			keyB = orderedKeys[i]

			found = true
			exit
		Next
		'variant A
		'reached end? just extrapolate between last and its predecessor
		'-> can lead to <0 or >1.0 values (depending on rise)
		'if not found
		'	keyA = orderedKeys[orderedKeys.length-2]
		'	keyB = orderedKeys[orderedKeys.length-1]
		'endif

		'variant B
		'just return the last value
		if not found
			return GetValueForKey(orderedKeys[orderedKeys.length-1])
		endif

		valueA = GetValueForKey(keyA)
		valueB = GetValueForKey(keyB)

'		print "valueA="+valueA+"  valueB="+valueB+"  key="+key+"  keyA="+keyA+"  keyB="+keyB

		if not interpolationFunction
			return LinearInterpolation(valueA, valueB, key - keyA, keyB - keyA)
		else
			return interpolationFunction(valueA, valueB, key - keyA, keyB - keyA)
		endif
	End Method


	Function LinearInterpolation:Double(startValue:Double, endValue:Double, time:Double, timeTotal:Double)
		return (endValue - startValue) * (time / timeTotal) + startValue
	End Function
End Type


Rem
'sample

local bag:TNumericPairInterpolator = new TNumericPairInterpolator
bag.insert(1980, 0.0)
bag.insert(1985, 0.20)
bag.insert(1990, 0.50)

For local i:int = 1980 to 1990
	print i+": " + bag.GetInterpolatedValue(i)
Next
EndRem