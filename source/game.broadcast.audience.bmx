SuperStrict
Import Brl.StringBuilder
Import "Dig/base.util.numbersortmap.bmx"
Import "Dig/base.util.helper.bmx" 'for roundInt()
Import "game.exceptions.bmx"
Import "game.gameconstants.bmx"

Type TAudienceManager
	'audience percentage for targetgroups split by gender
	Field currentAudienceBreakdown:TAudience = Null
	'audience percentage split by targetgroups
	Field currentTargetGroupBreakdown:TAudienceBase = Null
	'audience percentage amongst female
	Field currentGenderFemaleBreakdown:TAudienceBase = Null
	'audience percentage amongst male
	Field currentGenderMaleBreakdown:TAudienceBase = Null
	'default variants of above
	Field defaultAudienceBreakdown:TAudience = Null
	Field defaultTargetGroupBreakdown:TAudienceBase = Null
	Field defaultGenderFemaleBreakdown:TAudienceBase = Null
	Field defaultGenderMaleBreakdown:TAudienceBase = Null

	Method Initialize:Int()
		currentAudienceBreakdown = Null
		currentTargetGroupBreakdown = Null
		currentGenderFemaleBreakdown = Null
		currentGenderMaleBreakdown = Null
		defaultAudienceBreakdown = Null
		defaultTargetGroupBreakdown = Null
		defaultGenderFemaleBreakdown = Null
		defaultGenderMaleBreakdown = Null
	End Method
	
	
	Method GetAudienceBreakdown:TAudience()
		If Not defaultAudienceBreakdown
			defaultAudienceBreakdown = New TAudience
			'copy
			defaultAudienceBreakdown.data.audienceMale = GetTargetGroupBreakdown().data.Multiply(GetGenderBreakdown( TVTPersonGender.MALE ).data)
			defaultAudienceBreakdown.data.audienceFemale = GetTargetGroupBreakdown().data.Multiply(GetGenderBreakdown( TVTPersonGender.FEMALE ).data)
		EndIf
		'set current to default (reference!) if nothing set for now
		If Not currentAudienceBreakdown Then currentAudienceBreakdown = defaultAudienceBreakdown

		Return currentAudienceBreakdown
	End Method


	Method GetTargetGroupBreakdown:TAudienceBase()
		If Not defaultTargetGroupBreakdown
			'                                              Children (9%)
			'                                                      Teenagers (10%)
			'                                                             HouseWives (20% of 60% adults = 12%)
			'                                                                    Employees (67,5% of 60% adults = 40,5%)
			'                                                                           Unemployed (7,5% of 60% adults = 4,5%)
			'                                                                                  Managers (5% of 60% adults = 3%)
			'                                                                                         Pensioners (21%)
			defaultTargetGroupBreakdown = New TAudienceBase(0.090, 0.100, 0.120, 0.405, 0.045, 0.030, 0.210)
		EndIf
		'set current to default (reference!) if nothing set for now
		If Not currentTargetGroupBreakdown Then currentTargetGroupBreakdown = defaultTargetGroupBreakdown

		Return currentTargetGroupBreakdown
	End Method


	'returns the female percentage by default
	Method GetGenderBreakdown:TAudienceBase(gender:Int=-1)
		If Not defaultGenderFemaleBreakdown
			'based partially on data from:
			'http://www.bpb.de/wissen/X39RH6,0,0,Bev%F6lkerung_nach_Altersgruppen_und_Geschlecht.html
			'(of 2010)
			'and
			'http://statistik.arbeitsagentur.de/Statischer-Content/Statistische-Analysen/Analytikreports/Zentrale-Analytikreports/Monatliche-Analytikreports/Generische-Publikationen/Analyse-Arbeitsmarkt-Frauen-Maenner/Analyse-Arbeitsmarkt-Frauen-Maenner-201506.pdf
			'(of 2015)

			'value describes percentage of women in each group
			'                                                Children
			'                                                       Teenagers
			'                                                              HouseWives
			'                                                                     Employees
			'                                                                            Unemployed
			'                                                                                   Managers
			'                                                                                          Pensioners
			defaultGenderFemaleBreakdown = New TAudienceBase(0.487, 0.487, 0.900, 0.400, 0.450, 0.200, 0.580)
		EndIf
		If Not defaultGenderMaleBreakdown
			defaultGenderMaleBreakdown = New TAudienceBase
			defaultGenderMaleBreakdown.data = New SAudienceBase(1).Subtract( defaultGenderFemaleBreakdown.data )
		EndIf
		'set current to default (reference!) if nothing set for now
		If Not currentGenderFemaleBreakdown Then currentGenderFemaleBreakdown = defaultGenderFemaleBreakdown
		If Not currentGenderMaleBreakdown Then currentGenderMaleBreakdown = defaultGenderMaleBreakdown

		If gender <> TVTPersonGender.MALE
			Return currentGenderFemaleBreakdown
		Else
			Return currentGenderMaleBreakdown
		EndIf
	End Method


	Method GetGenderPercentage:Float(gender:Int)
		If gender = TVTPersonGender.FEMALE
			Return GetAudienceBreakdown().data.audienceFemale.GetSum()
		ElseIf gender = TVTPersonGender.MALE
			Return GetAudienceBreakdown().data.audienceMale.GetSum()
		EndIf
	End Method


	Method GetGenderGroupPercentage:Float(genderID:Int, targetGroupIDs:Int)
		Local portion:Float = 0
		Local gBreakdown:TAudienceBase = GetGenderBreakdown(genderID)
		Local aBreakdown:TAudienceBase = GetTargetGroupBreakdown()
		For Local targetGroupID:Int = EachIn TVTTargetGroup.GetBaseGroupIDs()
			If targetGroupIDs & targetGroupID
				portion :+ gBreakdown.data.Get(targetGroupID) * aBreakdown.data.Get(targetGroupID)
			EndIf
		Next
		Return portion
	End Method


	'returns the percentage/count of all persons in the group
	'a "MEN + TEENAGER + EMPLOYEES"-group just returns the amount
	'of all male teenager and male employees
	'---
	'In contrast to "GetGenderGroupPercentage" this allows to have
	'TVTTargetGroup.MEN / WOMEN recognized as gender
	Method GetTargetGroupPercentage:Float(targetGroups:Int)
		'add target groups ignoring the gender
		If targetGroups & TVTTargetGroup.MEN
			'just men
			If targetGroups = TVTTargetGroup.MEN
				Return GetGenderPercentage(TVTPersonGender.MALE)
			'male part of target groups
			Else
				Return GetGenderGroupPercentage(TVTPersonGender.MALE, targetGroups)
			EndIf
		ElseIf targetGroups & TVTTargetGroup.WOMEN
			'just women
			If targetGroups = TVTTargetGroup.WOMEN
				Return GetGenderPercentage(TVTPersonGender.FEMALE)
			'female part of target groups
			Else
				Return GetGenderGroupPercentage(TVTPersonGender.FEMALE, targetGroups)
			EndIf
		Else
			Return GetTargetGroupBreakdown().Get(targetGroups)
		EndIf

		Throw "unhandled GetTargetGroupAmount: targetGroups="+targetGroups
		Return 0
	End Method
End Type

Global AudienceManager:TAudienceManager = New TAudienceManager



Struct SAudienceBase
	Field Readonly Children:Float
	Field Readonly Teenagers:Float
	Field Readonly HouseWives:Float
	Field Readonly Employees:Float
	Field Readonly Unemployed:Float
	Field Readonly Managers:Float
	Field Readonly Pensioners:Float
	
	
	Method New(s:String)
		Local vars:String[] = s.split(",")
		If vars.length > 0 Then Children = Float(vars[0])
		If vars.length > 1 Then Teenagers = Float(vars[1])
		If vars.length > 2 Then HouseWives = Float(vars[2])
		If vars.length > 3 Then Employees = Float(vars[3])
		If vars.length > 4 Then Unemployed = Float(vars[4])
		If vars.length > 5 Then Managers = Float(vars[5])
		If vars.length > 6 Then Pensioners = Float(vars[6])
	End Method
	
	
	Method New(audience:Int, breakdown:SAudienceBase var)
		Self.Children = audience * breakdown.Children
		Self.Teenagers = audience * breakdown.Teenagers
		Self.HouseWives	= audience * breakdown.HouseWives
		Self.Employees = audience * breakdown.Employees
		Self.Unemployed	= audience * breakdown.Unemployed
		Self.Managers = audience * breakdown.Managers
		Self.Pensioners	= audience * breakdown.Pensioners
	End Method
	
	
	Method New(children:Float, teenagers:Float, HouseWives:Float, employees:Float, unemployed:Float, managers:Float, pensioners:Float)
		Self.Children = children
		Self.Teenagers = teenagers
		Self.HouseWives	= HouseWives
		Self.Employees = employees
		Self.Unemployed	= unemployed
		Self.Managers = managers
		Self.Pensioners	= pensioners
	End Method


	Method New(value:Float)
		Self.Children = value
		Self.Teenagers = value
		Self.HouseWives	= value
		Self.Employees = value
		Self.Unemployed	= value
		Self.Managers = value
		Self.Pensioners	= value
	End Method


	'Multiplies the audience base by @factor, returning a new audience base.
	Method Multiply:SAudienceBase(factor:Float)
		Return New SAudienceBase(Children * factor, ..
		                         Teenagers * factor, ..
		                         HouseWives * factor, ..
		                         Employees * factor, ..
		                         Unemployed * factor, ..
		                         Managers * factor, ..
		                         Pensioners * factor)
	End Method


	'Multiplies the audience base by @factors, returning a new audience base.
	Method Multiply:SAudienceBase(factors:SAudienceBase)
		Return New SAudienceBase(Children * factors.Children, ..
		                         Teenagers * factors.Teenagers, ..
		                         HouseWives * factors.HouseWives, ..
		                         Employees * factors.Employees, ..
		                         Unemployed * factors.Unemployed, ..
		                         Managers * factors.Managers, ..
		                         Pensioners * factors.Pensioners)
	End Method


	Method Set:SAudienceBase(targetGroupID:Int, value:Float)
		If targetGroupID = TVTTargetGroup.All Then Return Add(value)

		Local newChildren:Float = Children
		Local newTeenagers:Float = Teenagers
		Local newHouseWives:Float = HouseWives
		Local newEmployees:Float = Employees
		Local newUnemployed:Float = Unemployed
		Local newManagers:Float = Managers
		Local newPensioners:Float = Pensioners

		Select targetGroupID
			Case TVTTargetGroup.Children
				newChildren = value
			Case TVTTargetGroup.Teenagers
				newTeenagers = value
			Case TVTTargetGroup.HouseWives
				newHouseWives = value
			Case TVTTargetGroup.Employees
				newEmployees = value
			Case TVTTargetGroup.Unemployed
				newUnemployed = value
			Case TVTTargetGroup.Managers
				newManagers = value
			Case TVTTargetGroup.Pensioners
				newPensioners = value
			Default
				'loop through all targetGroup-entries and add them if contained
				Local subID:Int
				Local result:SAudienceBase = self
				'do NOT start with 0 ("all"), baseGroupCount is without men/women
				For Local i:Int = 1 To TVTTargetGroup.baseGroupCount
					 subID = 1 Shl (i-1) 'TVTTargetGroup.GetAtIndex(i)
					If targetGroupID & subID 
						result = result.Set(subID, value)
					EndIf
				Next
				Return result
		End Select

		Return New SAudienceBase(newChildren, newTeenagers, newHouseWives, ..
		                         newEmployees, newUnemployed, newManagers, ..
		                         newPensioners)
	End Method


	'Adds @value to each in the audience base, returning a new audience base.
	Method Add:SAudienceBase(value:Float)
		Return New SAudienceBase(Children + value, ..
		                         Teenagers + value, ..
		                         HouseWives + value, ..
		                         Employees + value, ..
		                         Unemployed + value, ..
		                         Managers + value, ..
		                         Pensioners + value)
	End Method


	'Adds @values to each according in the audience base, returning a new audience base.
	Method Add:SAudienceBase(audience:SAudienceBase)
		Return New SAudienceBase(Children + audience.Children, ..
		                         Teenagers + audience.Teenagers, ..
		                         HouseWives + audience.HouseWives, ..
		                         Employees + audience.Employees, ..
		                         Unemployed + audience.Unemployed, ..
		                         Managers + audience.Managers, ..
		                         Pensioners + audience.Pensioners)
	End Method


	Method Add:SAudienceBase(targetGroupID:Int, number:Float)
		If targetGroupID = TVTTargetGroup.All Then Return Add(number)

		Local newChildren:Float = Children
		Local newTeenagers:Float = Teenagers
		Local newHouseWives:Float = HouseWives
		Local newEmployees:Float = Employees
		Local newUnemployed:Float = Unemployed
		Local newManagers:Float = Managers
		Local newPensioners:Float = Pensioners

		Select targetGroupID
			Case TVTTargetGroup.Children
				newChildren :+ number
			Case TVTTargetGroup.Teenagers
				newTeenagers :+ number
			Case TVTTargetGroup.HouseWives
				newHouseWives :+ number
			Case TVTTargetGroup.Employees
				newEmployees :+ number
			Case TVTTargetGroup.Unemployed
				newUnemployed :+ number
			Case TVTTargetGroup.Managers
				newManagers :+ number
			Case TVTTargetGroup.Pensioners
				newPensioners :+ number
			Default
				'loop through all targetGroup-entries and add them if contained
				Local subID:Int
				Local result:SAudienceBase = self
				'do NOT start with 0 ("all"), baseGroupCount is without men/women
				For Local i:Int = 1 To TVTTargetGroup.baseGroupCount
					 subID = 1 Shl (i-1) 'TVTTargetGroup.GetAtIndex(i)
					If targetGroupID & subID 
						result = result.Add(subID, number)
					EndIf
				Next
				Return result
		End Select

		Return New SAudienceBase(newChildren, newTeenagers, newHouseWives, ..
		                         newEmployees, newUnemployed, newManagers, ..
		                         newPensioners)
	End Method


	Method Subtract:SAudienceBase(value:Float)
		Return Add(-value)
	End Method


	Method Subtract:SAudienceBase(audience:SAudienceBase)
		Return New SAudienceBase(Children - audience.Children, ..
		                         Teenagers - audience.Teenagers, ..
		                         HouseWives - audience.HouseWives, ..
		                         Employees - audience.Employees, ..
		                         Unemployed - audience.Unemployed, ..
		                         Managers - audience.Managers, ..
		                         Pensioners - audience.Pensioners)
	End Method


	Method Subtract:SAudienceBase(targetGroupID:Int, number:Float)
		Return Add(targetGroupID, -number)
	End Method


	Method Divide:SAudienceBase(audience:SAudienceBase)
		If audience.GetSum() = 0 Then Return New SAudienceBase()

		'check for div/0 first
		If audience.Children = 0 Then Throw "SAudienceBase.Divide: Div/0 - audience.Children is 0. Children is " + Children
		If audience.Teenagers = 0 Then Throw "SAudienceBase.Divide: Div/0 - audience.Teenagers is 0. Teenagers is " + Teenagers
		If audience.HouseWives = 0 Then Throw "SAudienceBase.Divide: Div/0 - audience.HouseWives is 0. HouseWives is " + HouseWives
		If audience.Employees = 0 Then Throw "SAudienceBase.Divide: Div/0 - audience.Employees is 0. Employees is " + Employees
		If audience.Unemployed = 0 Then Throw "SAudienceBase.Divide: Div/0 - audience.Unemployed is 0. Unemployed is " + Unemployed
		If audience.Managers = 0 Then Throw "SAudienceBase.Divide: Div/0 - audience.Managers is 0. Managers is " + Managers
		If audience.Pensioners = 0 Then Throw "SAudienceBase.Divide: Div/0 - audience.Pensioners is 0. Pensioners is " + Pensioners

		Return New SAudienceBase(Children / audience.Children, ..
		                         Teenagers / audience.Teenagers, ..
		                         HouseWives / audience.HouseWives, ..
		                         Employees / audience.Employees, ..
		                         Unemployed / audience.Unemployed, ..
		                         Managers / audience.Managers, ..
		                         Pensioners / audience.Pensioners)
	End Method


	Method Divide:SAudienceBase(number:Float)
		If number = 0 Then Throw "SAudienceBase.Divide(): Division by zero."

		Return New SAudienceBase(Children / number, ..
		                         Teenagers / number, ..
		                         HouseWives / number, ..
		                         Employees / number, ..
		                         Unemployed / number, ..
		                         Managers / number, ..
		                         Pensioners / number)
	End Method


	Method Round:SAudienceBase()
		Return New SAudienceBase(Int(Children + 0.5 * Sgn(Children)), ..
		                         Int(Teenagers + 0.5 * Sgn(Teenagers)), ..
		                         Int(HouseWives + 0.5 * Sgn(HouseWives)), ..
		                         Int(Employees + 0.5 * Sgn(Employees)), ..
		                         Int(Unemployed + 0.5 * Sgn(Unemployed)), ..
		                         Int(Managers + 0.5 * Sgn(Managers)), ..
		                         Int(Pensioners + 0.5 * Sgn(Pensioners)))
	End Method	


	Method GetAverage:Float()
		Local result:Float = GetSum()
		If result = 0
			Return 0.0
		Else
			Return result / 7
		EndIf
	End Method


	Method CutBorders:SAudienceBase(minimum:Float, maximum:Float)
		Return CutMinimum(minimum).CutMaximum(maximum)
	End Method


	Method CutBorders:SAudienceBase(minimum:SAudienceBase var, maximum:SAudienceBase var)
		Return CutMinimum(minimum).CutMaximum(maximum)
	End Method


	Method CutMinimum:SAudienceBase(value:Float)
		Local newChildren:Float = Children
		Local newTeenagers:Float = Teenagers
		Local newHouseWives:Float = HouseWives
		Local newEmployees:Float = Employees
		Local newUnemployed:Float = Unemployed
		Local newManagers:Float = Managers
		Local newPensioners:Float = Pensioners

		If Children < value Then newChildren = value
		If Teenagers < value Then newTeenagers = value
		If HouseWives < value Then newHouseWives = value
		If Employees < value Then newEmployees = value
		If Unemployed < value Then newUnemployed = value
		If Managers < value Then newManagers = value
		If Pensioners < value Then newPensioners = value

		Return New SAudienceBase(newChildren, newTeenagers, newHouseWives, ..
		                         newEmployees, newUnemployed, newManagers, ..
		                         newPensioners)
	End Method


	Method CutMinimum:SAudienceBase(minimum:SAudienceBase var)
		Local newChildren:Float = Children
		Local newTeenagers:Float = Teenagers
		Local newHouseWives:Float = HouseWives
		Local newEmployees:Float = Employees
		Local newUnemployed:Float = Unemployed
		Local newManagers:Float = Managers
		Local newPensioners:Float = Pensioners

		If Children < minimum.Children Then newChildren = minimum.Children
		If Teenagers < minimum.Teenagers Then newTeenagers = minimum.Teenagers
		If HouseWives < minimum.HouseWives Then newHouseWives = minimum.HouseWives
		If Employees < minimum.Employees Then newEmployees = minimum.Employees
		If Unemployed < minimum.Unemployed Then newUnemployed = minimum.Unemployed
		If Managers < minimum.Managers Then newManagers = minimum.Managers
		If Pensioners < minimum.Pensioners Then newPensioners = minimum.Pensioners

		Return New SAudienceBase(newChildren, newTeenagers, newHouseWives, ..
		                         newEmployees, newUnemployed, newManagers, ..
		                         newPensioners)
	End Method


	Method CutMaximum:SAudienceBase(value:Float)
		Local newChildren:Float = Children
		Local newTeenagers:Float = Teenagers
		Local newHouseWives:Float = HouseWives
		Local newEmployees:Float = Employees
		Local newUnemployed:Float = Unemployed
		Local newManagers:Float = Managers
		Local newPensioners:Float = Pensioners

		If Children > value Then newChildren = value
		If Teenagers > value Then newTeenagers = value
		If HouseWives > value Then newHouseWives = value
		If Employees > value Then newEmployees = value
		If Unemployed > value Then newUnemployed = value
		If Managers > value Then newManagers = value
		If Pensioners > value Then newPensioners = value

		Return New SAudienceBase(newChildren, newTeenagers, newHouseWives, ..
		                         newEmployees, newUnemployed, newManagers, ..
		                         newPensioners)
	End Method


	Method CutMaximum:SAudienceBase(maximum:SAudienceBase var)
		Local newChildren:Float = Children
		Local newTeenagers:Float = Teenagers
		Local newHouseWives:Float = HouseWives
		Local newEmployees:Float = Employees
		Local newUnemployed:Float = Unemployed
		Local newManagers:Float = Managers
		Local newPensioners:Float = Pensioners

		If Children > maximum.Children Then newChildren = maximum.Children
		If Teenagers > maximum.Teenagers Then newTeenagers = maximum.Teenagers
		If HouseWives > maximum.HouseWives Then newHouseWives = maximum.HouseWives
		If Employees > maximum.Employees Then newEmployees = maximum.Employees
		If Unemployed > maximum.Unemployed Then newUnemployed = maximum.Unemployed
		If Managers > maximum.Managers Then newManagers = maximum.Managers
		If Pensioners > maximum.Pensioners Then newPensioners = maximum.Pensioners

		Return New SAudienceBase(newChildren, newTeenagers, newHouseWives, ..
		                         newEmployees, newUnemployed, newManagers, ..
		                         newPensioners)
	End Method


	Method Get:Float(targetID:Int)
		Select targetID
			Case TVTTargetGroup.All
				Return GetSum()
			Case TVTTargetGroup.Children
				Return Children
			Case TVTTargetGroup.Teenagers
				Return Teenagers
			Case TVTTargetGroup.HouseWives
				Return HouseWives
			Case TVTTargetGroup.Employees
				Return Employees
			Case TVTTargetGroup.Unemployed
				Return Unemployed
			Case TVTTargetGroup.Managers
				Return Managers
			Case TVTTargetGroup.Pensioners
				Return Pensioners
			Case TVTTargetGroup.Men
				Return 0
			Case TVTTargetGroup.Women
				Return 0
			Default
				'check if we got a combination of multiple
				Return GetGroup(targetID)
		End Select
	End Method


	'returns the sum value of a group of targetIDS
	Method GetGroup:Float(targetIDs:Int)
		'loop through all targetGroup-entries and add them if contained
		Local result:Float
		Local oneFound:Int = False
		'do NOT start with 0 ("all")
		For Local i:Int = 1 To TVTTargetGroup.count
			If targetIDs & TVTTargetGroup.GetAtIndex(i)
				result :+ Get(i)
				oneFound = True
			EndIf
		Next

		If Not oneFound
			'print "unknown targetID"
			Throw TTVTArgumentException.Create("targetID", String.FromInt(targetIDs))
		EndIf

		Return result
	End Method


	Method GetSum:Float()
		'ignore gender in base variant
		Return Children + Teenagers + HouseWives + Employees + Unemployed + Managers + Pensioners
	End Method


	Method GetAbsSum:Float()
		'ignore gender in base variant
		Return Abs(Children) + Abs(Teenagers) + Abs(HouseWives) + Abs(Employees) + Abs(Unemployed) + Abs(Managers) + Abs(Pensioners)
	End Method


	Method GetWeightedAverage:Float()
		Local audienceBreakdown:TAudienceBase = AudienceManager.GetTargetGroupBreakdown()
		Return self.Multiply(audienceBreakdown.data).GetSum()
	End Method


	Method GetWeightedAverage:Float(audienceBreakdown:SAudienceBase)
		Return self.Multiply(audienceBreakdown).GetSum()
	End Method


	'=== SERIALIZATION / DESERIALIZATION ===
	Method SerializeSAudienceBaseToString:String()
		Return f2i(Children) + "," +..
		       f2i(Teenagers) + "," +..
		       f2i(HouseWives) + "," +..
		       f2i(Employees) + "," +..
		       f2i(Unemployed) + "," +..
		       f2i(Managers) + "," +..
		       f2i(Pensioners)

		Function f2i:String(f:Float)
			If Float(Int(f)) = f Then Return Int(f)
			Return String(f).Replace(",",".")
		End Function
	End Method


	'=== TOSTRING VARIANTS ===
	Method ToStringMinimal:String(dec:Int = 0)
        Local sb:TStringBuilder = New TStringBuilder
        Local splitter:string = "/"
        sb.Append("C:").Append(MathHelper.NumberToString(Children, dec, True)).Append(splitter)
        sb.Append("T:").Append(MathHelper.NumberToString(Teenagers, dec, True)).Append(splitter)
        sb.Append("H:").Append(MathHelper.NumberToString(HouseWives, dec, True)).Append(splitter)
        sb.Append("E:").Append(MathHelper.NumberToString(Employees, dec, True)).Append(splitter)
        sb.Append("U:").Append(MathHelper.NumberToString(Unemployed, dec, True)).Append(splitter)
        sb.Append("M:").Append(MathHelper.NumberToString(Managers, dec, True)).Append(splitter)
        sb.Append("P:").Append(MathHelper.NumberToString(Pensioners, dec, True))
        Return sb.ToString()
	End Method


	Method ToString:String()
		Local dec:Int = 4
		if Children > 2 or Teenagers > 2 or HouseWives > 2
			Return "Sum = " + MathHelper.NumberToString(GetSum(), dec, True) + "  ( " + ToStringMinimal(0) +" )"
		Else
			Return "Sum = " + MathHelper.NumberToString(GetSum(), dec, True) + "  ( " + ToStringMinimal(4) +" )"
		EndIf
	End Method
End Struct


'Diese Klasse repräsentiert das Publikum, dass die Summe seiner Zielgruppen ist.
'Die Klasse kann sowohl Zuschauerzahlen als auch Faktoren/Quoten beinhalten
'und stellt einige Methoden bereit die Berechnung mit Faktoren und anderen
'TAudience-Klassen ermöglichen.
Type TAudienceBase {_exposeToLua="selected"}
	Field data:SAudienceBase

	
	'=== CONSTRUCTORS ===
	Method New(children:Float, teenagers:Float, houseWives:Float, employees:Float, unemployed:Float, managers:Float, pensioners:Float)
		Set(children, teenagers, houseWives, employees, unemployed, managers, pensioners)
	End Method

	

	Method Set:TAudienceBase(children:Float, teenagers:Float, HouseWives:Float, employees:Float, unemployed:Float, managers:Float, pensioners:Float)
		data = new SAudienceBase(children, teenagers, HouseWives, employees, unemployed, managers, pensioners)
		Return Self
	End Method


	Method Set:TAudienceBase(value:Float)
		data = new SAudienceBase(value)
		Return Self
	End Method


	Method Set:TAudienceBase(audience:Int, breakdown:TAudienceBase)
		data = new SAudienceBase(audience, breakdown.data)
		Return Self
	End Method


	Method Set:TAudienceBase(audience:Int, breakdown:SAudienceBase)
		data = new SAudienceBase(audience, breakdown)
		Return Self
	End Method
	
	
	Method Set:TAudienceBase(values:TAudienceBase)
		'simply copy
		data = values.data
		Return Self
	End Method


	'=== SERIALIZATION / DESERIALIZATION ===
	Method SerializeTAudienceBaseToString:String()
		Return data.SerializeSAudienceBaseToString()
	End Method


	Method DeSerializeTAudienceBaseFromString(text:String)
		data = new SAudienceBase(text)
	End Method




	'=== PUBLIC ===

	Method Copy:TAudienceBase()
		Return New TAudienceBase.Set(Self)
	End Method


	Method GetAverage:Float() {_exposeToLua}
		Local result:Float = GetSum()
		If result = 0
			Return 0.0
		Else
			Return result / 7
		EndIf
	End Method


	Method CutBorders:TAudienceBase(minimum:Float, maximum:Float)
		data = data.CutBorders(minimum, maximum)
		Return Self
	End Method

	Method CutBorders:TAudienceBase(minimum:TAudienceBase, maximum:TAudienceBase)
		data = data.CutBorders(minimum.data, maximum.data)
		Return Self
	End Method

	Method CutBorders:TAudienceBase(minimum:SAudienceBase, maximum:SAudienceBase)
		data = data.CutBorders(minimum, maximum)
		Return Self
	End Method


	Method CutMinimum:TAudienceBase(value:Float)
		data = data.CutMinimum(value)
		Return Self
	End Method

	Method CutMinimum:TAudienceBase(values:TAudienceBase)
		data = data.CutMinimum(values.data)
		Return Self
	End Method

	Method CutMinimum:TAudienceBase(values:SAudienceBase)
		data = data.CutMinimum(values)
		Return Self
	End Method


	Method CutMaximum:TAudienceBase(value:Float)
		data = data.CutMaximum(value)
		Return Self
	End Method

	Method CutMaximum:TAudienceBase(values:TAudienceBase)
		data = data.CutMaximum(values.data)
		Return Self
	End Method

	Method CutMaximum:TAudienceBase(values:SAudienceBase)
		data = data.CutMaximum(values)
		Return Self
	End Method


	Method Get:Float(targetID:Int) {_exposeToLua}
		Return data.Get(targetID)
	End Method


	'returns the sum value of a group of targetIDS
	Method GetGroup:Float(targetIDs:Int) {_exposeToLua}
		Return data.GetGroup(targetIDs)
	End Method


	Method Set:TAudienceBase(targetID:Int, newValue:Float)
		data = data.Set(targetID, newValue)
		Return Self
	End Method


	Method GetSum:Float() {_exposeToLua}
		Return data.GetSum()
	End Method


	Method GetAbsSum:Float() {_exposeToLua}
		Return data.GetAbsSum()
	End Method


	Method GetWeightedAverage:Float(audienceBreakdown:TAudienceBase = Null) {_exposeToLua}
		Return data.GetWeightedAverage()
	End Method


	Method Add:TAudienceBase(value:Float)
		data = data.Add(value)
		Return Self
	End Method

	Method Add:TAudienceBase(audience:TAudienceBase)
		'skip if the param is "unset"
		If Not audience Then Return Self

		data = data.Add(audience.data)
		Return Self
	End Method

	Method Add:TAudienceBase(audience:SAudienceBase)
		data = data.Add(audience)
		Return Self
	End Method


	Method Subtract:TAudienceBase(value:Float)
		data = data.Subtract(value)
		Return Self
	End Method

	Method Subtract:TAudienceBase(audience:TAudienceBase)
		'skip if the param is "unset"
		If Not audience Then Return Self

		data = data.Subtract(audience.data)
		Return Self
	End Method

	Method Subtract:TAudienceBase(audience:SAudienceBase)
		data = data.Subtract(audience)
		Return Self
	End Method


	Method Multiply:TAudienceBase(audience:TAudienceBase)
		'skip if the param is "unset"
		If Not audience Then Return Self

		data = data.Multiply(audience.data)
		Return Self
	End Method

	Method Multiply:TAudienceBase(audience:SAudienceBase)
		data = data.Multiply(audience)
		Return Self
	End Method

	'required until brl.reflection correctly handles "float parameters" 
	'in debug builds (same as "doubles" for 32 bit builds)
	'GREP-key: "brlreflectionbug"
	Method MultiplyString:TAudienceBase(factor:String) {_exposeToLua}
		data = data.Multiply(Float(factor))
		Return Self
	End Method
	
	Method Multiply:TAudienceBase(factor:Float)
		data = data.Multiply(factor)
		Return Self
	End Method


	Method Divide:TAudienceBase(audience:TAudienceBase)
		If Not audience Then Return Self

		data = data.Divide(audience.data)
		Return Self
	End Method

	Method Divide:TAudienceBase(number:Float)
		data = data.Divide(number)
		Return Self
	End Method


	Method Round:TAudienceBase()
		data = data.Round()
		Return Self
	End Method


	'TODO: fixed size map ? ... (static) array instead of map? custom sort implementation ... ?
	Method ToNumberSortMap:TNumberSortMap()
		Local amap:TNumberSortMap = New TNumberSortMap
		amap.Add(TVTTargetGroup.Children, data.Children)
		amap.Add(TVTTargetGroup.Teenagers, data.Teenagers)
		amap.Add(TVTTargetGroup.HouseWives, data.HouseWives)
		amap.Add(TVTTargetGroup.Employees, data.Employees)
		amap.Add(TVTTargetGroup.Unemployed, data.Unemployed)
		amap.Add(TVTTargetGroup.Managers, data.Managers)
		amap.Add(TVTTargetGroup.Pensioners, data.Pensioners)
		Return amap
	End Method


	Method ToStringPercentage:String(dec:Int = 0) {_exposeToLua}
        Local sb:TStringBuilder = New TStringBuilder
        Local splitter:string = "% /"
        sb.Append("C:").Append(MathHelper.NumberToString(data.Children*100, dec, True)).Append(splitter)
        sb.Append("T:").Append(MathHelper.NumberToString(data.Teenagers*100, dec, True)).Append(splitter)
        sb.Append("H:").Append(MathHelper.NumberToString(data.HouseWives*100, dec, True)).Append(splitter)
        sb.Append("E:").Append(MathHelper.NumberToString(data.Employees*100, dec, True)).Append(splitter)
        sb.Append("U:").Append(MathHelper.NumberToString(data.Unemployed*100, dec, True)).Append(splitter)
        sb.Append("M:").Append(MathHelper.NumberToString(data.Managers*100, dec, True)).Append(splitter)
        sb.Append("P:").Append(MathHelper.NumberToString(data.Pensioners*100, dec, True)).Append("%")
        Return sb.ToString()
	End Method


	Method ToStringMinimal:String(dec:Int = 0) {_exposeToLua}
		Return data.ToStringMinimal(dec)
	End Method


	Method ToString:String() {_exposeToLua}
		Return data.ToString()
	End Method


	Method ToStringAverage:String(dec:Int = 4)
		Return "Avg = " + MathHelper.NumberToString(data.GetAverage(),3, True) + "  ( " + ToStringMinimal(dec) +" )"
	End Method


	Function InnerSort:Int(targetId:Int, o1:Object, o2:Object)
		Local s1:TAudienceBase = TAudienceBase(o1)
		Local s2:TAudienceBase = TAudienceBase(o2)
		' Objekt nicht gefunden, an das Ende der Liste setzen
		If Not s2 Then Return 1
        Return 1000 * (s1.data.Get(targetId) - s2.data.Get(targetId))
	End Function


	Function AllSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceBase = TAudienceBase(o1)
		Local s2:TAudienceBase = TAudienceBase(o2)
		If Not s2 Then Return 1
        Return s1.data.GetSum() - s2.data.GetSum()
	End Function


	Function ChildrenSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceBase = TAudienceBase(o1)
		Local s2:TAudienceBase = TAudienceBase(o2)
		's2 after s1
		If Not s2 Then Return 1
		'sort bigger to smaler values (1 on top, -1 to bottom)
		'1 if value1 > value2, -1 if value1 < value2
		Return 1 - 2 * (s1.data.Children < s2.data.Children) 
	End Function


	Function TeenagersSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceBase = TAudienceBase(o1)
		Local s2:TAudienceBase = TAudienceBase(o2)
		If Not s2 Then Return 1
		Return 1 - 2 * (s1.data.Teenagers < s2.data.Teenagers) 
	End Function


	Function HouseWivesSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceBase = TAudienceBase(o1)
		Local s2:TAudienceBase = TAudienceBase(o2)
		If Not s2 Then Return 1
		Return 1 - 2 * (s1.data.HouseWives < s2.data.HouseWives) 
	End Function


	Function EmployeesSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceBase = TAudienceBase(o1)
		Local s2:TAudienceBase = TAudienceBase(o2)
		If Not s2 Then Return 1
		Return 1 - 2 * (s1.data.Employees < s2.data.Employees) 
	End Function


	Function UnemployedSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceBase = TAudienceBase(o1)
		Local s2:TAudienceBase = TAudienceBase(o2)
		If Not s2 Then Return 1
		Return 1 - 2 * (s1.data.Unemployed < s2.data.Unemployed) 
	End Function


	Function ManagersSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceBase = TAudienceBase(o1)
		Local s2:TAudienceBase = TAudienceBase(o2)
		If Not s2 Then Return 1
		Return 1 - 2 * (s1.data.Managers < s2.data.Managers) 
	End Function


	Function PensionersSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceBase = TAudienceBase(o1)
		Local s2:TAudienceBase = TAudienceBase(o2)
		If Not s2 Then Return 1
		Return 1 - 2 * (s1.data.Pensioners < s2.data.Pensioners) 
	End Function
End Type




Struct SAudience
	Field audienceMale:SAudienceBase
	Field audienceFemale:SAudienceBase

	Method New(gender:Int, children:Float, teenagers:Float, HouseWives:Float, employees:Float, unemployed:Float, managers:Float, pensioners:Float)
		If gender = -1 Or gender = TVTPersonGender.FEMALE
			audienceFemale = New SAudienceBase(children, teenagers, HouseWives, employees, unemployed, managers, pensioners)
		EndIf
		If gender = -1 Or gender = TVTPersonGender.MALE
			audienceMale = New SAudienceBase(children, teenagers, HouseWives, employees, unemployed, managers, pensioners)
		EndIf
	End Method


	Method New(male:SAudienceBase, female:SAudienceBase)
		'structs assignment = copy!
		audienceFemale = female
		audienceMale = male
	End Method
	
	
	Method New(male:TAudienceBase, female:TAudienceBase)
		If Not female
			audienceFemale = new SAudienceBase()
		Else
			'structs assignment = copy!
			audienceFemale = female.data
		EndIf
		If Not male
			audienceMale = new SAudienceBase()
		Else
			'structs assignment = copy!
			audienceMale = male.data
		EndIf
	End Method


	Method New(valueMale:Float, valueFemale:Float)
		audienceFemale = New SAudienceBase(valueFemale, valueFemale, valueFemale, valueFemale, valueFemale, valueFemale, valueFemale)
		audienceMale = New SAudienceBase(valueMale, valueMale, valueMale, valueMale, valueMale, valueMale, valueMale)
	End Method


	Method New(audience:Int, audienceBreakdown:TAudience)
		audienceFemale = new SAudienceBase(audience, audienceBreakdown.data.audienceFemale)
		audienceMale = new SAudienceBase(audience, audienceBreakdown.data.audienceMale)
	End Method


	Method New(audience:Int, audienceTargetGroupBreakdown:SAudienceBase)
		Local base:SAudienceBase = new SAudienceBase(audience, audienceTargetGroupBreakdown)
		audienceFemale = base.Multiply( AudienceManager.GetGenderBreakdown( TVTPersonGender.FEMALE ).data)
		audienceMale = base.Multiply( AudienceManager.GetGenderBreakdown( TVTPersonGender.MALE ).data)
	End Method
	

	Method New()
	End Method
	
	


	Method GetWeightedValue:Float(targetID:Int, genderID:Int = 0)
'ddd
'Todo: hier koennte man GetAudienceBreakdown nutzen (Gender + Targetgroup)
		Local femaleGenderRatio:Float = AudienceManager.GetGenderBreakdown(TVTPersonGender.FEMALE).Get(targetID)
		Local targetgroupRatio:Float = AudienceManager.GetTargetGroupBreakdown().Get(targetID)
		Local result:Float
		If genderID <> TVTPersonGender.MALE
			result :+ GetGenderValue(targetID, TVTPersonGender.FEMALE) * targetgroupRatio * femaleGenderRatio
		EndIf
		If genderID <> TVTPersonGender.FEMALE
			result :+ GetGenderValue(targetID, TVTPersonGender.MALE) * targetgroupRatio * (1 - femaleGenderRatio)
		EndIf
		
		Return result
	End Method


	Method GetTotalValue:Float(targetID:Int)
		If targetID <= 0 Then Return GetTotalSum()

		If targetID = TVTTargetGroup.Women
			Return GetGenderValue(targetID, TVTPersonGender.FEMALE)
		ElseIf targetID = TVTTargetGroup.Men
			Return GetGenderValue(targetID, TVTPersonGender.MALE)
		Else
			Local res:Float = 0
			res :+ audienceMale.Get(targetID)
			res :+ audienceFemale.Get(targetID)
			Return res
		EndIf
	End Method


	Method GetGenderValue:Float(targetID:Int, gender:Int)
		If targetID = TVTTargetGroup.Women
			If gender = TVTPersonGender.MALE Then Return 0
			Return audienceFemale.GetSum()
		ElseIf targetID = TVTTargetGroup.Men
			If gender = TVTPersonGender.FEMALE  Then Return 0
			Return audienceMale.GetSum()
		EndIf

		If gender = TVTPersonGender.MALE
			Return audienceMale.Get(targetID)
		ElseIf gender = TVTPersonGender.FEMALE
			Return audienceFemale.Get(targetID)
		EndIf

		Return 0
	End Method


	Method GetTotalSum:Float()
		Return audienceFemale.GetSum() + audienceMale.GetSum()
	End Method


	Method GetTotalAbsSum:Float()
		Return audienceFemale.GetAbsSum() + audienceMale.GetAbsSum()
	End Method

	Method GetGenderSum:Float(gender:Int)
		If gender = TVTPersonGender.FEMALE
			Return audienceFemale.GetSum()
		ElseIf gender = TVTPersonGender.MALE
			Return audienceMale.GetSum()
		EndIf
		Return 0
	End Method


	Method GetTotalAverage:Float()
		Return 0.5 * (audienceFemale.GetAverage() + audienceMale.GetAverage())
	End Method


	Method GetGenderAverage:Float(gender:Int)
		If gender = TVTPersonGender.FEMALE
			Return audienceFemale.GetAverage()
		ElseIf gender = TVTPersonGender.MALE
			Return audienceMale.GetAverage()
		EndIf
		Return 0
	End Method

	
	Method GetWeightedAverage:Float()
		'fetch current breakdown if nothing was given
		Local audienceTargetGroupBreakdown:SAudienceBase = AudienceManager.GetTargetGroupBreakdown().data
		Local audienceFemaleGenderBreakdown:SAudienceBase = AudienceManager.GetGenderBreakdown(TVTPersonGender.FEMALE).data

		Return GetWeightedAverage(audienceTargetGroupBreakdown, audienceFemaleGenderBreakdown) 
	End Method

	Method GetWeightedAverage:Float(audienceBreakdown:SAudienceBase var)
		Local audienceFemaleGenderBreakdown:SAudienceBase = AudienceManager.GetGenderBreakdown(TVTPersonGender.FEMALE).data

		Return GetWeightedAverage(audienceBreakdown, audienceFemaleGenderBreakdown) 
	End Method

	Method GetWeightedAverage:Float(audienceBreakdown:SAudienceBase var, audienceFemaleGenderBreakdown:SAudienceBase var)
		'multiply the value by their share on the total amount of people
		'so "male children", "female managers"

		Local result:Float = 0
		If audienceMale
			result :+ audienceMale.Children * audienceBreakdown.Children * (1 - audienceFemaleGenderBreakdown.Children)
			result :+ audienceMale.Teenagers * audienceBreakdown.Teenagers * (1 - audienceFemaleGenderBreakdown.Teenagers)
			result :+ audienceMale.HouseWives * audienceBreakdown.HouseWives * (1 - audienceFemaleGenderBreakdown.HouseWives)
			result :+ audienceMale.Employees * audienceBreakdown.Employees * (1 - audienceFemaleGenderBreakdown.Employees)
			result :+ audienceMale.Unemployed * audienceBreakdown.Unemployed * (1 - audienceFemaleGenderBreakdown.Unemployed)
			result :+ audienceMale.Managers * audienceBreakdown.Managers * (1 - audienceFemaleGenderBreakdown.Managers)
			result :+ audienceMale.Pensioners * audienceBreakdown.Pensioners * (1 - audienceFemaleGenderBreakdown.Pensioners)
		EndIf
		If audienceFemale
			result :+ audienceFemale.Children * audienceBreakdown.Children * audienceFemaleGenderBreakdown.Children
			result :+ audienceFemale.Teenagers * audienceBreakdown.Teenagers * audienceFemaleGenderBreakdown.Teenagers
			result :+ audienceFemale.HouseWives * audienceBreakdown.HouseWives * audienceFemaleGenderBreakdown.HouseWives
			result :+ audienceFemale.Employees * audienceBreakdown.Employees * audienceFemaleGenderBreakdown.Employees
			result :+ audienceFemale.Unemployed * audienceBreakdown.Unemployed * audienceFemaleGenderBreakdown.Unemployed
			result :+ audienceFemale.Managers * audienceBreakdown.Managers * audienceFemaleGenderBreakdown.Managers
			result :+ audienceFemale.Pensioners * audienceBreakdown.Pensioners * audienceFemaleGenderBreakdown.Pensioners
		EndIf

		Return result
	End Method

		
	'contrary to "SetGenderValue()" this SPLITS the value into female/male
	Method SetTotalValue(targetID:Int, newValue:Float, femalePercentage:Float = 0.5)
		SetGenderValue(targetID, newValue * femalePercentage, TVTPersonGender.FEMALE)
		SetGenderValue(targetID, newValue * (1.0 - femalePercentage), TVTPersonGender.MALE)
	End Method


	Method SetGenderValue(targetID:Int, newValue:Float, gender:Int)
		Select targetID
			Case TVTTargetGroup.Women
				If gender = TVTPersonGender.MALE Then Return
			Case TVTTargetGroup.Men
				If gender = TVTPersonGender.FEMALE Then Return
			Default
				If gender = TVTPersonGender.MALE
					audienceMale = audienceMale.Set(targetID, newValue)
				ElseIf gender = TVTPersonGender.FEMALE
					audienceFemale = audienceFemale.Set(targetID, newValue)
				Else
					audienceMale = audienceMale.Set(targetID, newValue)
					audienceFemale = audienceFemale.Set(targetID, newValue)
				EndIf
		End Select
	End Method


	Method Add(audience:SAudience)
		audienceFemale = audienceFemale.Add(audience.audienceFemale)
		audienceMale = audienceMale.Add(audience.audienceMale)
	End Method

	Method Add(audience:TAudience)
		'skip adding if the param is "unset"
		If Not audience Then Return

		audienceFemale = audienceFemale.Add(audience.data.audienceFemale)
		audienceMale = audienceMale.Add(audience.data.audienceMale)
	End Method

	Method Add(number:Float)
		audienceFemale = audienceFemale.Add(number)
		audienceMale = audienceMale.Add(number)
	End Method


	Method AddGender(number:Float, gender:Int)
		If gender = TVTPersonGender.FEMALE
			audienceFemale = audienceFemale.Add(number)
		Else
			audienceMale = audienceMale.Add(number)
		EndIf
	End Method


	Method ModifyTotalValue(targetID:Int, addValue:Float)
		ModifyGenderValue(targetID, addValue, TVTPersonGender.MALE)
		ModifyGenderValue(targetID, addValue, TVTPersonGender.FEMALE)
	End Method


	Method ModifyGenderValue(targetID:Int, addValue:Float, gender:Int)
		Local targetIndexes:Int[] = TVTTargetGroup.GetIndexes(targetID)

		For Local targetIndex:Int = EachIn targetIndexes
			targetID = TVTTargetGroup.GetAtIndex(targetIndex)

			Select targetID
				Case TVTTargetGroup.Women
					If gender = TVTPersonGender.MALE Then Return
					For Local targetGroupID:Int = EachIn TVTTargetGroup.GetBaseGroupIDs()
						ModifyGenderValue( targetGroupID, addValue, TVTPersonGender.FEMALE )
					Next
				Case TVTTargetGroup.Men
					If gender = TVTPersonGender.FEMALE Then Return
					For Local targetGroupID:Int = EachIn TVTTargetGroup.GetBaseGroupIDs()
						ModifyGenderValue( targetGroupID, addValue, TVTPersonGender.MALE  )
					Next

				Default
					If gender = TVTPersonGender.MALE
						audienceMale = audienceMale.Add(targetID, addValue)
					ElseIf gender = TVTPersonGender.FEMALE
						audienceFemale = audienceFemale.Add(targetID, addValue)
					EndIf
			End Select
		Next
	End Method


	Method Subtract(audience:SAudience)
		audienceFemale = audienceFemale.Subtract(audience.audienceFemale)
		audienceMale = audienceMale.Subtract(audience.audienceMale)
	End Method

	Method Subtract(audience:TAudience)
		'skip subtracting if the param is "unset"
		If Not audience Then Return

		audienceFemale = audienceFemale.Subtract(audience.data.audienceFemale)
		audienceMale = audienceMale.Subtract(audience.data.audienceMale)
	End Method

	Method Subtract(number:Float)
		audienceFemale = audienceFemale.Subtract(number)
		audienceMale = audienceMale.Subtract(number)
	End Method


	Method Multiply(audience:SAudience)
		audienceFemale = audienceFemale.Multiply(audience.audienceFemale)
		audienceMale = audienceMale.Multiply(audience.audienceMale)
	End Method

	Method Multiply(audience:TAudience)
		'skip if the param is "unset"
		If Not audience Then Return

		audienceFemale = audienceFemale.Multiply(audience.data.audienceFemale)
		audienceMale = audienceMale.Multiply(audience.data.audienceMale)
	End Method

	Method Multiply(factor:Float)
		audienceFemale = audienceFemale.Multiply(factor)
		audienceMale = audienceMale.Multiply(factor)
	End Method


	Method Divide(audience:SAudience)
		If Not audience Then Return

		audienceFemale = audienceFemale.Divide(audience.audienceFemale)
		audienceMale = audienceMale.Divide(audience.audienceMale)
	End Method

	Method Divide(audience:TAudience)
		If Not audience Then Return

		audienceFemale = audienceFemale.Divide(audience.data.audienceFemale)
		audienceMale = audienceMale.Divide(audience.data.audienceMale)
	End Method

	Method Divide(number:Float)
		audienceFemale = audienceFemale.Divide(number)
		audienceMale = audienceMale.Divide(number)
	End Method


	Method Round()
		audienceFemale = audienceFemale.Round()
		audienceMale = audienceMale.Round()
	End Method


	Method CutBorders(minimum:Float, maximum:Float)
		audienceFemale = audienceFemale.CutBorders(minimum, maximum)
		audienceMale = audienceMale.CutBorders(minimum, maximum)
	End Method

	Method CutBorders(minimum:SAudience, maximum:SAudience)
		audienceFemale = audienceFemale.CutBorders(minimum.audienceFemale, maximum.audienceFemale)
		audienceMale = audienceMale.CutBorders(minimum.audienceMale, maximum.audienceMale)
	End Method

	Method CutBorders(minimum:TAudience, maximum:TAudience)
		If Not minimum Or Not maximum Then Return

		audienceFemale = audienceFemale.CutBorders(minimum.data.audienceFemale, maximum.data.audienceFemale)
		audienceMale = audienceMale.CutBorders(minimum.data.audienceMale, maximum.data.audienceMale)
	End Method


	Method CutMinimum(value:Float)
		audienceFemale = audienceFemale.CutMinimum(value)
		audienceMale = audienceMale.CutMinimum(value)
	End Method

	Method CutMinimum(minimum:SAudience)
		audienceFemale = audienceFemale.CutMinimum(minimum.audienceFemale)
		audienceMale = audienceMale.CutMinimum(minimum.audienceMale)
	End Method

	Method CutMinimum(minimum:TAudience)
		If Not minimum Then Return

		audienceFemale = audienceFemale.CutMinimum(minimum.data.audienceFemale)
		audienceMale = audienceMale.CutMinimum(minimum.data.audienceMale)
	End Method


	Method CutMaximum(value:Float)
		audienceFemale = audienceFemale.CutMaximum(value)
		audienceMale = audienceMale.CutMaximum(value)
	End Method

	Method CutMaximum(maximum:SAudience)
		If Not maximum Then Return

		audienceFemale = audienceFemale.CutMaximum(maximum.audienceFemale)
		audienceMale = audienceMale.CutMaximum(maximum.audienceMale)
	End Method

	Method CutMaximum(maximum:TAudience)
		If Not maximum Then Return

		audienceFemale = audienceFemale.CutMaximum(maximum.data.audienceFemale)
		audienceMale = audienceMale.CutMaximum(maximum.data.audienceMale)
	End Method


	Method ToStringPercentage:String(dec:Int = 0)
        Local sb:TStringBuilder = New TStringBuilder
        sb.Append("C:").Append(MathHelper.NumberToString(audienceMale.Children*100, dec, True)).Append("/").Append(MathHelper.NumberToString(audienceFemale.Children*100, dec, True)).Append("% / ")
        sb.Append("T:").Append(MathHelper.NumberToString(audienceMale.Teenagers*100, dec, True)).Append("/").Append(MathHelper.NumberToString(audienceFemale.Teenagers*100, dec, True)).Append("% / ")
        sb.Append("H:").Append(MathHelper.NumberToString(audienceMale.HouseWives*100, dec, True)).Append("/").Append(MathHelper.NumberToString(audienceFemale.HouseWives*100, dec, True)).Append("% / ")
        sb.Append("E:").Append(MathHelper.NumberToString(audienceMale.Employees*100, dec, True)).Append("/").Append(MathHelper.NumberToString(audienceFemale.Employees*100, dec, True)).Append("% / ")
        sb.Append("U:").Append(MathHelper.NumberToString(audienceMale.Unemployed*100, dec, True)).Append("/").Append(MathHelper.NumberToString(audienceFemale.Unemployed*100, dec, True)).Append("% / ")
        sb.Append("M:").Append(MathHelper.NumberToString(audienceMale.Managers*100, dec, True)).Append("/").Append(MathHelper.NumberToString(audienceFemale.Managers*100, dec, True)).Append("% / ")
        sb.Append("P:").Append(MathHelper.NumberToString(audienceMale.Pensioners*100, dec, True)).Append("/").Append(MathHelper.NumberToString(audienceFemale.Pensioners*100, dec, True)).Append("%")
        Return sb.ToString()
	End Method


	Method ToStringMinimal:String(dec:Int=0)
        Local sb:TStringBuilder = New TStringBuilder
        sb.Append("C:").Append(MathHelper.NumberToString(audienceMale.Children, dec, True)).Append("/").Append(MathHelper.NumberToString(audienceFemale.Children, dec, True)).Append(" / ")
        sb.Append("T:").Append(MathHelper.NumberToString(audienceMale.Teenagers, dec, True)).Append("/").Append(MathHelper.NumberToString(audienceFemale.Teenagers, dec, True)).Append(" / ")
        sb.Append("H:").Append(MathHelper.NumberToString(audienceMale.HouseWives, dec, True)).Append("/").Append(MathHelper.NumberToString(audienceFemale.HouseWives, dec, True)).Append(" / ")
        sb.Append("E:").Append(MathHelper.NumberToString(audienceMale.Employees, dec, True)).Append("/").Append(MathHelper.NumberToString(audienceFemale.Employees, dec, True)).Append(" / ")
        sb.Append("U:").Append(MathHelper.NumberToString(audienceMale.Unemployed, dec, True)).Append("/").Append(MathHelper.NumberToString(audienceFemale.Unemployed, dec, True)).Append(" / ")
        sb.Append("M:").Append(MathHelper.NumberToString(audienceMale.Managers, dec, True)).Append("/").Append(MathHelper.NumberToString(audienceFemale.Managers, dec, True)).Append(" / ")
        sb.Append("P:").Append(MathHelper.NumberToString(audienceMale.Pensioners, dec, True)).Append("/").Append(MathHelper.NumberToString(audienceFemale.Pensioners, dec, True))
        Return sb.ToString()
    End Method


	Method ToString:String()
		Local dec:Int = 3
		Return "Sum = " + MathHelper.NumberToString(GetTotalSum(), dec, True) + "  ( " + ToStringMinimal(dec) +" )"
	End Method


	Method ToStringAverage:String()
		Local dec:Int = 3
		Return "Avg = " + MathHelper.NumberToString(GetTotalAverage(), dec, True) + "  ( " + ToStringMinimal(dec) +" )"
	End Method
End Struct




Type TAudience {_exposeToLua="selected"}
	'Optional: Eine Id zur Identifikation (z.B. PlayerId). Nur bei Bedarf füllen!
	Field Id:Int
	Field data:SAudience


	'=== Constructors ===
	Method New(audience:SAudience)
		data = audience
	End Method
	
	
	Method Set:TAudience(gender:Int, children:Float, teenagers:Float, HouseWives:Float, employees:Float, unemployed:Float, managers:Float, pensioners:Float)
		data = new SAudience(gender, children, teenagers, houseWives, employees, unemployed, managers, pensioners)

		Return Self
	End Method


	Method Set:TAudience(male:SAudienceBase, female:SAudienceBase)
		data = new SAudience(male, female)

		Return Self
	End Method


	Method Set:TAudience(male:TAudienceBase, female:TAudienceBase)
		data = new SAudience(male, female)

		Return Self
	End Method


	Method Set:TAudience(valueMale:Float, valueFemale:Float)
		data = new SAudience(valueMale, valueFemale)

		Return Self
	End Method


	Method Set:TAudience(audience:Int, audienceBreakdown:TAudience)
		data = new SAudience(audience, audienceBreakdown)

		Return self
	End Method


	Method Set:TAudience(audience:Int, audienceTargetGroupBreakdown:TAudienceBase)
		data = new SAudience(audience, audienceTargetGroupBreakdown.data)

		Return Self
	End Method
	
	
	Method Set:TAudience(audience:TAudience)
		data = audience.data

		Return Self
	End Method



	'=== SERIALIZATION / DESERIALIZATION ===

	Method SerializeTAudienceToString:String()
		Local sb:TStringBuilder = New TStringBuilder
		sb.Append(id)

		sb.Append("::ab=")
		sb.Append( data.audienceMale.SerializeSAudienceBaseToString() )

		sb.Append("::ab=")
		sb.Append( data.audienceFemale.SerializeSAudienceBaseToString() )

		Return sb.ToString()
	End Method


	Method DeSerializeTAudienceFromString(text:String)
		Local audienceFemale:SAudienceBase
		Local audienceMale:SAudienceBase
		Local parts:String[] = text.split("::ab=")
		id = Int(parts[0])
		If parts.length > 1
			audienceMale = new SAudienceBase(parts[1])
		EndIf
		If parts.length > 2
			audienceFemale = new SAudienceBase(parts[2])
		EndIf
		data = new SAudience(audienceMale, audienceFemale)
	End Method




	'=== PUBLIC ===
	Method Copy:TAudience() {_exposeToLua}
		Local result:TAudience = New TAudience
		result.Id = Id
		result.data = self.data 'struct copy
		Return result
	End Method


	Method GetWeightedValue:Float(targetID:Int, genderID:Int = 0) {_exposeToLua}
		Return data.GetWeightedValue(targetID, genderID)
	End Method


	Method GetTotalValue:Float(targetID:Int) {_exposeToLua}
		Return data.GetTotalValue(targetID)
	End Method


	Method GetGenderValue:Float(targetID:Int, gender:Int) {_exposeToLua}
		Return data.GetGenderValue(targetID, gender)
	End Method


	Method GetTotalSum:Float() {_exposeToLua}
		Return data.GetTotalSum()
	End Method


	Method GetTotalAbsSum:Float() {_exposeToLua}
		Return data.GetTotalAbsSum()
	End Method


	Method GetGenderSum:Float(gender:Int) {_exposeToLua}
		Return data.GetGenderSum(gender)
	End Method


	Method GetTotalAverage:Float() {_exposeToLua}
		Return data.GetTotalAverage()
	End Method


	Method GetGenderAverage:Float(gender:Int) {_exposeToLua}
		Return data.GetGenderAverage(gender)
	End Method

	
	Method GetWeightedAverage:Float() {_exposeToLua}
		Return data.GetWeightedAverage()
	End Method

	Method GetWeightedAverage:Float(audienceBreakdown:SAudienceBase var)
		Return data.GetWeightedAverage(audienceBreakdown)
	End Method

	Method GetWeightedAverage:Float(audienceBreakdown:SAudienceBase var, audienceFemaleGenderBreakdown:SAudienceBase var)
		Return data.GetWeightedAverage(audienceBreakdown, audienceFemaleGenderBreakdown)
	End Method


	'contrary to "SetGenderValue()" this SPLITS the value into female/male
	Method SetTotalValue:TAudience(targetID:Int, newValue:Float, femalePercentage:Float = 0.5)
		data.SetTotalValue(targetID, newValue, femalePercentage)
		
		Return self
	End Method


	Method SetGenderValue:TAudience(targetID:Int, newValue:Float, gender:Int)
		data.SetGenderValue(targetID, newValue, gender)
		Return Self
	End Method


	Method Add(audience:SAudience)
		data.add(audience)
	End Method

	Method Add:TAudience(audience:TAudience)
		data.Add(audience)
		Return Self
	End Method

	Method Add:TAudience(number:Float)
		data.Add(number)
		Return Self
	End Method


	Method AddGender:TAudience(number:Float, gender:Int)
		data.AddGender(number, gender)
		Return Self
	End Method


	Method ModifyTotalValue:TAudience(targetID:Int, addValue:Float)
		data.ModifyTotalValue(targetID, addValue)
		Return Self
	End Method


	Method ModifyGenderValue:TAudience(targetID:Int, addValue:Float, gender:Int)
		data.ModifyGenderValue(targetID, addValue, gender)
		Return Self
	End Method


	Method Subtract:TAudience(audience:TAudience)
		data.Subtract(audience)
		Return Self
	End Method


	Method Subtract:TAudience(number:Float)
		data.Subtract(number)
		Return Self
	End Method


	Method Multiply:TAudience(audience:SAudience)
		data.Multiply(audience)
		Return Self
	End Method

	Method Multiply:TAudience(audience:TAudience)
		data.Multiply(audience)
		Return Self
	End Method


	'required until brl.reflection correctly handles "float parameters" 
	'in debug builds (same as "doubles" for 32 bit builds)
	'GREP-key: "brlreflectionbug"
	Method MultiplyString:TAudience(factor:String) {_exposeToLua}
		data.Multiply(Float(factor))
		Return Self
	End Method
	

	'expose commented out because of above mentioned brl.reflection bug
	Method Multiply:TAudience(factor:Float) '{_exposeToLua}
		data.Multiply(factor)
		Return Self
	End Method


	Method Divide:TAudience(audience:TAudience)
		data.Divide(audience)
		Return Self
	End Method


	Method Divide:TAudience(number:Float)
		data.Divide(number)
		Return Self
	End Method


	Method Round:TAudience()
		data.Round()
		Return Self
	End Method


	Method CutBorders:TAudience(minimum:Float, maximum:Float)
		data.CutBorders(minimum, maximum)
		Return Self
	End Method

	Method CutBorders:TAudience(minimum:TAudience, maximum:TAudience)
		data.CutBorders(minimum, maximum)
		Return Self
	End Method


	Method CutMinimum:TAudience(value:Float)
		data.CutMinimum(value)
		Return Self
	End Method

	Method CutMinimum:TAudience(minimum:TAudience)
		data.CutMinimum(minimum)
		Return Self
	End Method


	Method CutMaximum:TAudience(value:Float)
		data.CutMaximum(value)
		Return Self
	End Method

	Method CutMaximum:TAudience(maximum:TAudience)
		data.CutMaximum(maximum)
		Return Self
	End Method


	Method ToNumberSortMap:TNumberSortMap()
		Local amap:TNumberSortMap = New TNumberSortMap
		amap.Add(TVTTargetGroup.Children, data.audienceFemale.Children + data.audienceMale.Children)
		amap.Add(TVTTargetGroup.Teenagers, data.audienceFemale.Teenagers + data.audienceMale.Teenagers)
		amap.Add(TVTTargetGroup.HouseWives, data.audienceFemale.HouseWives + data.audienceMale.HouseWives)
		amap.Add(TVTTargetGroup.Employees, data.audienceFemale.Employees + data.audienceMale.Employees)
		amap.Add(TVTTargetGroup.Unemployed, data.audienceFemale.Unemployed + data.audienceMale.Unemployed)
		amap.Add(TVTTargetGroup.Managers, data.audienceFemale.Managers + data.audienceMale.Managers)
		amap.Add(TVTTargetGroup.Pensioners, data.audienceFemale.Pensioners + data.audienceMale.Pensioners)

		rem
		amap.Add(TVTTargetGroup.Children, GetTotalValue(TVTTargetGroup.Children))
		amap.Add(TVTTargetGroup.Teenagers, GetTotalValue(TVTTargetGroup.Teenagers))
		amap.Add(TVTTargetGroup.HouseWives, GetTotalValue(TVTTargetGroup.HouseWives))
		amap.Add(TVTTargetGroup.Employees, GetTotalValue(TVTTargetGroup.Employees))
		amap.Add(TVTTargetGroup.Unemployed, GetTotalValue(TVTTargetGroup.Unemployed))
		amap.Add(TVTTargetGroup.Managers, GetTotalValue(TVTTargetGroup.Managers))
		amap.Add(TVTTargetGroup.Pensioners, GetTotalValue(TVTTargetGroup.Pensioners))
		EndRem
		Return amap
	End Method


	'=== TO STRING ===

	Method ToStringPercentage:String(dec:Int = 0) {_exposeToLua}
		Return data.ToStringPercentage(dec)
	End Method


	Method ToStringMinimal:String(dec:Int=0) {_exposeToLua}
		Return data.ToStringMinimal(dec)
    End Method


	Method ToString:String() {_exposeToLua}
		Return data.ToString()
	End Method


	Method ToStringAverage:String()
		Return data.ToStringAverage()
	End Method


	'=== SORTING FUNCTIONS ===

	Function InnerSort:Int(targetId:Int, o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
		If Not s2 Then Return 1
        Return 1000 * (s1.data.GetTotalValue(targetId) - s2.data.GetTotalValue(targetId))
	End Function


	Function AllSort:Int(o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
		If Not s2 Then Return 1
        Return s1.data.GetTotalSum() - s2.data.GetTotalSum()
	End Function


	Function ChildrenSort:Int(o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
		's2 after s1
		If Not s2 Then Return 1
		'sort bigger to smaler values (1 on top, -1 to bottom)
		'1 if value1 > value2, -1 if value1 < value2
		Return 1 - 2 * ((s1.data.audienceFemale.Children + s1.data.audienceMale.Children) < (s2.data.audienceFemale.Children + s2.data.audienceMale.Children)) 
	End Function


	Function TeenagersSort:Int(o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
		If Not s2 Then Return 1
		Return 1 - 2 * ((s1.data.audienceFemale.Teenagers + s1.data.audienceMale.Teenagers) < (s2.data.audienceFemale.Teenagers + s2.data.audienceMale.Teenagers)) 
	End Function


	Function HouseWivesSort:Int(o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
		If Not s2 Then Return 1
		Return 1 - 2 * ((s1.data.audienceFemale.HouseWives + s1.data.audienceMale.HouseWives) < (s2.data.audienceFemale.HouseWives + s2.data.audienceMale.HouseWives)) 
	End Function


	Function EmployeesSort:Int(o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
		If Not s2 Then Return 1
		Return 1 - 2 * ((s1.data.audienceFemale.Employees + s1.data.audienceMale.Employees) < (s2.data.audienceFemale.Employees + s2.data.audienceMale.Employees)) 
	End Function


	Function UnemployedSort:Int(o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
		If Not s2 Then Return 1
		Return 1 - 2 * ((s1.data.audienceFemale.Unemployed + s1.data.audienceMale.Unemployed) < (s2.data.audienceFemale.Unemployed + s2.data.audienceMale.Unemployed)) 
	End Function


	Function ManagersSort:Int(o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
		If Not s2 Then Return 1
		Return 1 - 2 * ((s1.data.audienceFemale.Managers + s1.data.audienceMale.Managers) < (s2.data.audienceFemale.Managers + s2.data.audienceMale.Managers)) 
	End Function


	Function PensionersSort:Int(o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
		If Not s2 Then Return 1
		Return 1 - 2 * ((s1.data.audienceFemale.Pensioners + s1.data.audienceMale.Pensioners) < (s2.data.audienceFemale.Pensioners + s2.data.audienceMale.Pensioners)) 
	End Function


	Function MenSort:Int(o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
		If Not s2 Then Return 1
		Return 1 - 2 * (s1.data.audienceMale.GetSum() < s2.data.audienceMale.GetSum()) 
	End Function


	Function WomenSort:Int(o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
		If Not s2 Then Return 1
		Return 1 - 2 * (s1.data.audienceFemale.GetSum() < s2.data.audienceFemale.GetSum()) 
	End Function
End Type