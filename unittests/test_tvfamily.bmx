SuperStrict

Import BRL.MaxUnit
Import "../source/game.ingameinterface.bmx"

New TTestSuite.run()

Type TAudienceTest Extends TTest
	Global ue:String ="unemployed_male"
	Global members:String[] = [ue, "child_male","child_female", "teen_male","teen_female","housewife_male","housewife_female","employee_male","employee_female", "manager_male","manager_female","pensioner_male","pensioner_female"]
	Global pue:Int = 540
	Global p3l:Int = 550
	Global p2l:Int = 580
	Global pm:Int = 610
	Global p2r:Int = 640
	Global p3r:Int = 670

	Field f:TWatchingFamily
	'history of seating positions
	Field s1:String
	Field s2:String
	Field s3:String

	Method setup() { before }
		f = new TWatchingFamily()
		s1 = ""
		s2 = ""
		s3 = ""
	End Method

	'generate failing cases which can then be added as explicit test cases
	Method testRandomCouchPositions() { test }
		SeedRand(MilliSecs())
		Local memberCount:Int = members.length - 1
		'simulate programme changes
		For Local runs:Long = 1 Until 100000 '* 100
			If runs Mod 1000000 = 0 Then print runs
			'random number of watchers
			Local count:Int = RandRange(1,3)
			Local indexes:Int[]
			Local ms:String[count]
			If count > 0
				'random family members (in random order - analogous to audience count)
				indexes = RandRangeArray(0, memberCount,count)
				For local i:int = 0 until count
					ms:+ [members[indexes[i]]]
				Next
			EndIf
			'call productive couch position assignment code and check spots
			assign(ms)
		Next
	End Method

	Method testBrokenCase1() { test }
		assign(["a","b","c"])
		assign([ue,"a","b"])
	End Method

	Method positionTest1() { test }
		assign(["a"])
		assertPosition("a",pm)
	End Method

	Method positionTest2() { test }
		assign([ue])
		assertPosition(ue, pue)
	End Method

	Method positionTest3() { test }
		assign(["a","b"])
		assertPosition("a", p2l)
		assertPosition("b", p2r)
		'no change in position
		assign(["b","a"])
		assertPosition("a", p2l)
		assertPosition("b", p2r)
		assign(["c","a"])
		assertPosition("a", p2l)
		assertPosition("c", p2r)
		assign(["a",ue])
		assertPosition(ue, pue)
		assertPosition("a", p2r)
	End Method

	Method positionTest4() { test }
		assign(["a","b","c"])
		assertPosition("a", p3l)
		assertPosition("b", pm)
		assertPosition("c", p3r)
		'no change in position
		assign(["b","a"])
		assertPosition("a", p3l)
		assertPosition("b", pm)
	End Method

	Method assign(watchers:String[])
		f._assignSpots(watchers,0)
		'check overlapping positions
		checkSpots()
	End Method

	'check seating - family member at couch position
	Method assertPosition(member:String, position:Int)
		Local m:String[] = f.watchingMembers[0]
		Local s:Int[] = f.couchPositions[0]
		For local i:Int = 0 Until m.length
			If m[i] = member
				assertEqualsI(position, s[i], member +" at unexpected position")
				Return
			EndIf
		Next
		assertTrue(False, member + " at no position!?")
	End Method

	Method checkSpots()
		'obtain watching family members and their positions from productive code
		Local m:String[] = f.watchingMembers[0]
		Local s:Int[] = f.couchPositions[0]
		Local seating:String = ""
		Local fail:Int = 0
		For local i:Int = 0 Until m.length
			seating:+ (m[i] + " " + s[i] + " ")
			For local j:Int = 0 Until i
				If m[i] = m[j] Then fail:+ 1
				If s[i] = s[j] Then fail:+ 1
			Next
		Next
		'store history and add current position
		s1=s2
		s2=s3
		s3=seating.trim()
		'in case of an error print the history and fail
		If fail > 0
			print s1
			print s2
			print s3
			assertTrue(False)
		EndIf
	End Method
End Type