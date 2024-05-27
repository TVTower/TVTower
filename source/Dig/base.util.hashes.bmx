Rem
	====================================================================
	Hashes class
	====================================================================

	Various Hashes (for now MD5).


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2015 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
EndRem
SuperStrict
Import Brl.Retro 'hex()



Type Hashes
	'derived from: http://www.blitzbasic.com/codearcs/codearcs.php?code=1449
	'made superstrict and realigned code
	Function MD5:string(str:string)
		Local h0:int = $67452301
		Local h1:int = $EFCDAB89
		Local h2:int = $98BADCFE
		Local h3:int = $10325476
		
		Local r:int[] = [ ..
					7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,..
					5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,..
					4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,..
					6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21 ..
						]
					
		Local k:int[] = [	..
					$D76AA478, $E8C7B756, $242070DB, $C1BDCEEE, $F57C0FAF, $4787C62A,..
					$A8304613, $FD469501, $698098D8, $8B44F7AF, $FFFF5BB1, $895CD7BE,..
					$6B901122, $FD987193, $A679438E, $49B40821, $F61E2562, $C040B340,..
					$265E5A51, $E9B6C7AA, $D62F105D, $02441453, $D8A1E681, $E7D3FBC8,..
					$21E1CDE6, $C33707D6, $F4D50D87, $455A14ED, $A9E3E905, $FCEFA3F8,..
					$676F02D9, $8D2A4C8A, $FFFA3942, $8771F681, $6D9D6122, $FDE5380C,..
					$A4BEEA44, $4BDECFA9, $F6BB4B60, $BEBFBC70, $289B7EC6, $EAA127FA,..
					$D4EF3085, $04881D05, $D9D4D039, $E6DB99E5, $1FA27CF8, $C4AC5665,..
					$F4292244, $432AFF97, $AB9423A7, $FC93A039, $655B59C3, $8F0CCC92,..
					$FFEFF47D, $85845DD1, $6FA87E4F, $FE2CE6E0, $A3014314, $4E0811A1,..
					$F7537E82, $BD3AF235, $2AD7D2BB, $EB86D391 ..
						]
					
		Local intCount:int = (((str.length + 8) Shr 6) + 1) Shl 4
		Local data:int[intCount]
	  
		For Local c:int = 0 Until str.length
			data[c Shr 2] = data[c Shr 2] | ((str[c] & $FF) Shl ((c & 3) Shl 3))
		Next

		data[str.length Shr 2] = data[str.length Shr 2] | ($80 Shl ((str.length & 3) Shl 3)) 
		data[data.length - 2] = (Long(str.length) * 8) & $FFFFFFFF
		data[data.length - 1] = (Long(str.length) * 8) Shr 32
	  

		For Local chunkStart:int = 0 Until intCount Step 16
			Local a:int = h0
			local b:int = h1
			local c:int = h2
			local d:int = h3
			
			For Local i:int = 0 To 15
				Local f:int = d ~ (b & (c ~ d))
				Local t:int = d
		  
				d = c
				c = b
				b = Rol((a + f + k[i] + data[chunkStart + i]), r[i]) + b
				a = t
			Next
		
			For Local i:int = 16 To 31
				Local f:int = c ~ (d & (b ~ c))
				Local t:int = d

				d = c
				c = b
				b = Rol((a + f + k[i] + data[chunkStart + (((5 * i) + 1) & 15)]), r[i]) + b
				a = t
			Next
		
			For Local i:int = 32 To 47
				Local f:int = b ~ c ~ d
				Local t:int = d
		  
				d = c
				c = b
				b = Rol((a + f + k[i] + data[chunkStart + (((3 * i) + 5) & 15)]), r[i]) + b
				a = t
			Next
		
			For Local i:int = 48 To 63
				Local f:int = c ~ (b | ~d)
				Local t:int = d
		  
				d = c
				c = b
				b = Rol((a + f + k[i] + data[chunkStart + ((7 * i) & 15)]), r[i]) + b
				a = t
			Next
		
			h0 :+ a
			h1 :+ b
			h2 :+ c
			h3 :+ d
		Next
	  
		Return (LEHex(h0) + LEHex(h1) + LEHex(h2) + LEHex(h3)).ToLower()
	End Function


	Function Rol:int(val:int, shift:int)
		Return (val Shl shift) | (val Shr (32 - shift))
	End Function


	Function Ror:int(val:int, shift:int)
		Return (val Shr shift) | (val Shl (32 - shift))
	End Function


	Function LEHex:string(val:int)
		Local result:string = Hex(val)
	  
		Return result[6..8] + result$[4..6] + result[2..4] + result[0..2]
	End Function
End Type
