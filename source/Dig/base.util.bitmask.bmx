SuperStrict

rem
SuperStrict
Framework Brl.StandardIO
Import Brl.Retro

Local base:Int = 0
Local mask:Int = 0
Local overlay:Int = 0

base    :| (1 + 2 + 4 + 8     )  '1-4 active
mask    :| (    2         + 16)  '2, 5 = manually set in overlay
overlay :| (1             + 16)  '1 = active, 2 = inactive (manually set so), 5 = active
Print "base : " + Bin(base)
Print "mask : " + Bin(mask)
Print "ovrl : " + Bin(overlay)
'Print Bin(base & ~mask)
Print "res  : " + Bin((base & ~mask) | overlay)
endrem


Type TBitmaskBase
	Method GetMask:Int() abstract
	Method Has:Int(bit:Int) abstract
	Method HasByIndex:Int(i:Int) abstract
	Method Set(bit:Int, enable:Int = True) abstract
	Method Reset() abstract

	Method IsModified:Int(bit:Int) 
		Return True
	End Method
End Type



Type TIntBitmask extends TBitmaskBase
	Field mask:Int

	Method GetMask:Int() 
		Return mask
	End Method

	
	Method Has:Int(bit:Int) override
		Return (mask & bit) > 0
	End Method
	
	
	Method HasByIndex:Int(i:Int) override
		If i <= 0 or i > 32 Then Return False
		Return mask & (1 Shl (i-1)) > 0
	End Method


	Method Set(bit:Int, enable:Int = True) override
		If enable
			mask :| bit
		Else
			mask :& ~bit
		EndIf
	End Method


	Method Reset() 
		mask = 0
	End Method
End Type



'a tri state bitmask knows if a flag was 
'set (off/on) or not (neither off nor on)
Type TTriStateIntBitmask extends TIntBitmask
	Field modified:Int


	Method Set(bit:Int, enable:Int = True) override
		modified :| bit
		
		If enable
			mask :| bit
		Else
			mask :& ~bit
		EndIf	
	End Method

	
	Method SetModified(bit:Int, enable:int)
		If modified
			modified :| bit
		Else
			modified :& ~bit
		EndIf
	End Method

	
	Method IsModified:Int(bit:Int) override
		Return (modified & bit) > 0
	End Method


	Method HasModified:Int()
		Return modified <> 0
	End Method
	
	
	Method ResetModified()
		modified = 0
	End Method
	
	
	Method SetAllModified()
		'use "modified & 0" so it uses the correct numeric type
		modified = ~(modified & 0)
	End Method
	
	
	Method GetMixMask:Int(other:TTriStateIntBitmask)
		if not other then return mask
		'overlay every bit of "other" which (manually set) (so can be "off" too)
		'result contains "off/on" of the current mask overlaid with all
		'bits (on/off) which were set as "modified" in the "other" mask
		
		Return (mask & ~other.modified) | other.mask
	End Method


	Method Reset() 
		modified = 0
		mask = 0
	End Method
		
	
	Method Copy:TTriStateIntBitmask()
		Local c:TTriStateIntBitmask = new TTriStateIntBitmask
		c.mask = self.mask
		c.modified = self.modified
		return c
	End Method


	Method SerializeTTriStateIntBitmaskToString:String()
		Return mask+","+modified
	End Method


	Method DeSerializeTTriStateIntBitmaskFromString(text:String)
		Local vars:String[] = text.split(",")
		If vars.length > 0 Then mask = Int(vars[0])
		If vars.length > 1 Then modified = Int(vars[1])
	End Method
End Type