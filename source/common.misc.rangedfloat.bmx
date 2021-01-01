SuperStrict
Import "Dig/base.util.mersenne.bmx"


Type TRangedFloat
	Field value:Float = 0.0
	Field minValue:Float = 0.0
	Field maxValue:Float = 1.0
	
	Method New(value:Float, minValue:Float = 0.0, maxValue:Float = 1.0)
		Initialize(value, minValue, maxValue)
	End Method


	Method Initialize:TRangedFloat(value:Float, minValue:Float, maxValue:Float)
		self.value = value
		self.minValue = minValue
		self.maxValue = maxValue
		
		Return self
	End Method
	
	
	Method Copy:TRangedFloat()
		Return New TRangedFloat.Initialize(value, minValue, maxValue)
	End Method
	

	Method Reset:TRangedFloat()
		value = 0
		minValue = 0
		maxValue = 1.0
		Return Self
	End Method


	Method SetRandomMin:TRangedFloat(minimum:Float, maximum:Float, bias:Float=0.5)
		self.minValue = 0.01 * BiasedRandRange(Int(100 * minimum), Int(100 * maximum), bias)
		Return self
	End Method


	Method SetRandomMax:TRangedFloat(minimum:Float, maximum:Float, bias:Float=0.5)
		self.maxValue = 0.01 * BiasedRandRange(Int(100 * minimum), Int(100 * maximum), bias)
		Return self
	End Method


	Method SetRandom:TRangedFloat(bias:Float=0.5)
		self.value = 0.01 * BiasedRandRange(Int(100 * minValue), Int(100 * maxValue), bias)
		Return self
	End Method


	Method SetMin:TRangedFloat(minimum:Float)
		self.minValue = minimum
		Return self
	End Method


	Method SetMax:TRangedFloat(maximum:Float)
		self.maxValue = maximum
		Return self
	End Method


	Method GetMin:Float()
		Return minValue
	End Method


	Method GetMax:Float()
		Return maxValue
	End Method
	

	Method Get:Float()
		Return value
	End Method
	
	
	Method Set:TRangedFloat(value:Float, ignoreLimits:Int = False)
		if not ignoreLimits
			self.value = Float(Min(Max(value, minValue), maxValue))
		Else
			self.value = value
		EndIf
		Return Self
	End Method
	
	
	Method Multiply:TRangedFloat(multiplier:Float)
		value = Min( Max(minValue, value * multiplier), maxValue )
		Return Self
	End Method


	Method Add:TRangedFloat(summand:Float)
		value = Min( Max(minValue, value + summand), maxValue )
		Return Self
	End Method
public

	Method SerializeTRangedFloatToString:string()
		return value + " " + minValue + " " + maxValue
	End Method


	Method DeSerializeTRangedFloatFromString(text:String)
		local vars:string[] = text.split(" ")
		if vars.length > 0 then value = Float(vars[0])
		if vars.length > 1 then minValue = Float(vars[1])
		if vars.length > 2 then maxValue = Float(vars[2])
	End Method
End Type
