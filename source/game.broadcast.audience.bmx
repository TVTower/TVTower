SuperStrict
Import Brl.StringBuilder
Import "Dig/base.util.numbersortmap.bmx"
Import "Dig/base.util.helper.bmx" 'for roundInt()
Import "game.exceptions.bmx"
Import "game.gameconstants.bmx"

Type TAudienceManager
	Field currentAudienceBreakdown:TAudienceBase = Null
	Field currentGenderFemaleBreakdown:TAudienceBase = Null
	Field currentGenderMaleBreakdown:TAudienceBase = Null
	Field targetAudienceBreakdown:TAudienceBase = Null
	Field targetGenderBreakdown:TAudienceBase = Null
	Field defaultAudienceBreakdown:TAudienceBase = Null
	Field defaultGenderFemaleBreakdown:TAudienceBase = Null
	Field defaultGenderMaleBreakdown:TAudienceBase = Null

	Method Initialize:Int()
		currentAudienceBreakdown = Null
		currentGenderFemaleBreakdown = Null
		currentGenderMaleBreakdown = Null
		targetAudienceBreakdown = Null
		targetGenderBreakdown = Null
		defaultAudienceBreakdown = Null
		defaultGenderFemaleBreakdown = Null
		defaultGenderMaleBreakdown = Null
	End Method


	Method GetAudienceBreakdown:TAudienceBase()
		If Not defaultAudienceBreakdown
			defaultAudienceBreakDown = New TAudienceBase
			defaultAudienceBreakDown.Children   = 0.09  'Kinder (9%)
			defaultAudienceBreakDown.Teenagers	 = 0.1   'Teenager (10%)
			'adults 60%
			defaultAudienceBreakDown.HouseWives = 0.12  'Hausfrauen (20% von 60% Erwachsenen = 12%)
			defaultAudienceBreakDown.Employees  = 0.405 'Arbeitnehmer (67,5% von 60% Erwachsenen = 40,5%)
			defaultAudienceBreakDown.Unemployed = 0.045 'Arbeitslose (7,5% von 60% Erwachsenen = 4,5%)
			defaultAudienceBreakDown.Manager    = 0.03  'Manager (5% von 60% Erwachsenen = 3%)
			defaultAudienceBreakDown.Pensioners = 0.21  'Rentner (21%)
		EndIf
		'set current to default (reference!) if nothing set for now
		If Not currentAudienceBreakdown Then currentAudienceBreakdown = defaultAudienceBreakDown

		Return currentAudienceBreakdown
	End Method

Rem
	Method ModifyAudienceBreakdown:TAudienceBase(AudienceModifier:TAudienceBase, relativeChange:int = True)
		if relativeChange
			currentAudienceBreakdown = GetAudienceBreakdown().Copy().ModifySumRelative(AudienceModifier)
		else
			currentAudienceBreakdown = GetAudienceBreakdown().Copy().ModifySumAbsolute(AudienceModifier)
		endif
	End Method
endrem

	'returns the female percentage by default
	Method GetGenderBreakdown:TAudienceBase(gender:Int=-1)
		If Not defaultGenderFemaleBreakdown
			'based partially on data from:
			'http://www.bpb.de/wissen/X39RH6,0,0,Bev%F6lkerung_nach_Altersgruppen_und_Geschlecht.html
			'(of 2010)
			'and
			'http://statistik.arbeitsagentur.de/Statischer-Content/Statistische-Analysen/Analytikreports/Zentrale-Analytikreports/Monatliche-Analytikreports/Generische-Publikationen/Analyse-Arbeitsmarkt-Frauen-Maenner/Analyse-Arbeitsmarkt-Frauen-Maenner-201506.pdf
			'(of 2015)

			'value describes percentage of women in that group
			defaultGenderFemaleBreakdown = New TAudienceBase
			defaultGenderFemaleBreakdown.Children = 0.487
			defaultGenderFemaleBreakdown.Teenagers = 0.487
			defaultGenderFemaleBreakdown.HouseWives = 0.9
			defaultGenderFemaleBreakdown.Employees = 0.4
			defaultGenderFemaleBreakdown.Unemployed = 0.45
			defaultGenderFemaleBreakdown.Manager = 0.20
			defaultGenderFemaleBreakdown.Pensioners = 0.58 'the older the more women
		EndIf
		If Not defaultGenderMaleBreakdown
			defaultGenderMaleBreakdown = New TAudienceBase.InitValue(1).Subtract( defaultGenderFemaleBreakdown )
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
		Return GetGenderBreakdown(gender).GetWeightedAverage( GetAudienceBreakdown() )
	End Method


	Method GetGenderGroupPercentage:Float(genderID:Int, targetGroupIDs:Int)
		Local portion:Float = 0
		Local gBreakdown:TAudienceBase = GetGenderBreakdown(genderID)
		Local aBreakdown:TAudienceBase = GetAudienceBreakdown()
		For Local i:Int = 1 To TVTTargetGroup.baseGroupCount
			Local targetGroupID:Int = TVTTargetGroup.GetAtIndex(i)
			If targetGroupIDs & targetGroupID
				portion :+ gBreakdown.GetValue(targetGroupID) * aBreakdown.GetValue(targetGroupID)
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
			Return GetAudienceBreakdown().GetValue(targetGroups)
		EndIf

		Throw "unhandled GetTargetGroupAmount: targetGroups="+targetGroups
		Return 0
	End Method
End Type

Global AudienceManager:TAudienceManager = New TAudienceManager




'Diese Klasse repräsentiert das Publikum, dass die Summe seiner Zielgruppen ist.
'Die Klasse kann sowohl Zuschauerzahlen als auch Faktoren/Quoten beinhalten
'und stellt einige Methoden bereit die Berechnung mit Faktoren und anderen
'TAudience-Klassen ermöglichen.
Type TAudienceBase {_exposeToLua="selected"}
	Field Children:Float    = 0 'Kinder
	Field Teenagers:Float	= 0	'Teenager
	Field HouseWives:Float	= 0	'Hausfrauen
	Field Employees:Float	= 0	'Employees
	Field Unemployed:Float	= 0	'Arbeitslose
	Field Manager:Float		= 0	'Manager
	Field Pensioners:Float	= 0	'Rentner
	Global count:Int
	Global killcount:Int
	
	Method New()
		count :+ 1
		if count mod 25 = 0
'			print "TAudienceBase created: " + count + " (alive:" + (count - killcount)+")"
		EndIf
	End Method
	
	Method Delete()
		killcount :+ 1
		if killcount mod 25 = 0
'			print "TAudienceBase deleted: " + killcount + " (alive:" + (count - killcount)+")"
		EndIf
	End Method

	'=== CONSTRUCTORS ===

	Method Init:TAudienceBase(children:Float, teenagers:Float, HouseWives:Float, employees:Float, unemployed:Float, manager:Float, pensioners:Float)
		SetValues(children, teenagers, HouseWives, employees, unemployed, manager, pensioners)
		Return Self
	End Method


	Method InitValue:TAudienceBase(defaultValue:Float)
		Init(defaultValue, defaultValue, defaultValue, defaultValue, defaultValue, defaultValue, defaultValue)
		Return Self
	End Method


	Method InitWithBreakdown:TAudienceBase(audience:Int, breakdown:TAudienceBase)
		SetValuesFrom(breakdown)
		MultiplyFloat(audience)
		Return Self
	End Method


	'=== SERIALIZATION / DESERIALIZATION ===
	Method SerializeTAudienceBaseToString:String()
		Return f2i(Children) + "," +..
		       f2i(Teenagers) + "," +..
		       f2i(HouseWives) + "," +..
		       f2i(Employees) + "," +..
		       f2i(Unemployed) + "," +..
		       f2i(Manager) + "," +..
		       f2i(Pensioners)

		Function f2i:String(f:Float)
			If Float(Int(f)) = f Then Return Int(f)
			Return String(f).Replace(",",".")
		End Function
	End Method


	Method DeSerializeTAudienceBaseFromString(text:String)
		Local vars:String[] = text.split(",")
		If vars.length > 0 Then Children = Float(vars[0])
		If vars.length > 1 Then Teenagers = Float(vars[1])
		If vars.length > 2 Then HouseWives = Float(vars[2])
		If vars.length > 3 Then Employees = Float(vars[3])
		If vars.length > 4 Then Unemployed = Float(vars[4])
		If vars.length > 5 Then Manager = Float(vars[5])
		If vars.length > 6 Then Pensioners = Float(vars[6])
	End Method




	'=== PUBLIC ===

	Method Copy:TAudienceBase()
		Local result:TAudienceBase = New TAudienceBase
		result.SetValuesFrom(Self)
		Return result
	End Method


	Method SetValuesFrom:TAudienceBase(value:TAudienceBase)
		Self.SetValues(value.Children, value.Teenagers, value.HouseWives, value.Employees, value.Unemployed, value.Manager, value.Pensioners)
		Return Self
	End Method


	Method SetValues:TAudienceBase(children:Float, teenagers:Float, HouseWives:Float, employees:Float, unemployed:Float, manager:Float, pensioners:Float)
		Self.Children	= children
		Self.Teenagers	= teenagers
		Self.HouseWives	= HouseWives
		Self.Employees	= employees
		Self.Unemployed	= unemployed
		Self.Manager	= manager
		Self.Pensioners	= pensioners
		Return Self
	End Method


	Method GetAverage:Float() {_exposeToLua}
		Local result:Float = GetSum()
		If result = 0
			Return 0.0
		Else
			Return result / 7
		EndIf
	End Method



	Method CutBordersFloat:TAudienceBase(minimum:Float, maximum:Float)
		CutMinimumFloat(minimum)
		CutMaximumFloat(maximum)
		Return Self
	End Method


	Method CutBorders:TAudienceBase(minimum:TAudienceBase, maximum:TAudienceBase)
		CutMinimum(minimum)
		CutMaximum(maximum)
		Return Self
	End Method


	Method CutMinimumFloat:TAudienceBase(value:Float)
		CutMinimum(New TAudienceBase.InitValue(value))
		Return Self
	End Method


	Method CutMinimum:TAudienceBase(minimum:TAudienceBase)
		If Children < minimum.Children Then Children = minimum.Children
		If Teenagers < minimum.Teenagers Then Teenagers = minimum.Teenagers
		If HouseWives < minimum.HouseWives Then HouseWives = minimum.HouseWives
		If Employees < minimum.Employees Then Employees = minimum.Employees
		If Unemployed < minimum.Unemployed Then Unemployed = minimum.Unemployed
		If Manager < minimum.Manager Then Manager = minimum.Manager
		If Pensioners < minimum.Pensioners Then Pensioners = minimum.Pensioners
		Return Self
	End Method


	Method CutMaximumFloat:TAudienceBase(value:Float)
		CutMaximum(New TAudienceBase.InitValue(value))
		Return Self
	End Method


	Method CutMaximum:TAudienceBase(maximum:TAudienceBase)
		If Children > maximum.Children Then Children = maximum.Children
		If Teenagers > maximum.Teenagers Then Teenagers = maximum.Teenagers
		If HouseWives > maximum.HouseWives Then HouseWives = maximum.HouseWives
		If Employees > maximum.Employees Then Employees = maximum.Employees
		If Unemployed > maximum.Unemployed Then Unemployed = maximum.Unemployed
		If Manager > maximum.Manager Then Manager = maximum.Manager
		If Pensioners > maximum.Pensioners Then Pensioners = maximum.Pensioners
		Return Self
	End Method


	Method GetValue:Float(targetID:Int) {_exposeToLua}
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
			Case TVTTargetGroup.Manager
				Return Manager
			Case TVTTargetGroup.Pensioners
				Return Pensioners
			Case TVTTargetGroup.Men
				Return 0
			Case TVTTargetGroup.Women
				Return 0
			Default
				'check if we got a combination of multiple
				Return GetGroupValue(targetID)
		End Select
	End Method


	'returns the sum value of a group of targetIDS
	Method GetGroupValue:Float(targetIDs:Int) {_exposeToLua}
		'loop through all targetGroup-entries and add them if contained
		Local result:Float
		Local oneFound:Int = False
		'do NOT start with 0 ("all")
		For Local i:Int = 1 To TVTTargetGroup.count
			If targetIDs & TVTTargetGroup.GetAtIndex(i)
				result :+ GetValue(i)
				oneFound = True
			EndIf
		Next

		If Not oneFound
			'print "unknown targetID"
			Throw TTVTArgumentException.Create("targetID", String.FromInt(targetIDs))
		EndIf

		Return result
	End Method


	Method SetValue(targetID:Int, newValue:Float)
		Select targetID
			Case TVTTargetGroup.Children
				Children = newValue
			Case TVTTargetGroup.Teenagers
				Teenagers = newValue
			Case TVTTargetGroup.HouseWives
				HouseWives = newValue
			Case TVTTargetGroup.Employees
				Employees = newValue
			Case TVTTargetGroup.Unemployed
				Unemployed = newValue
			Case TVTTargetGroup.Manager
				Manager = newValue
			Case TVTTargetGroup.Pensioners
				Pensioners = newValue
			Default
				Throw TTVTArgumentException.Create("targetID", String.FromInt(targetID))
		End Select
	End Method


	Method GetSum:Float() {_exposeToLua}
		'ignore gender in base variant
		Return Children + Teenagers + HouseWives + Employees + Unemployed + Manager + Pensioners
	End Method


	Method GetAbsSum:Float() {_exposeToLua}
		'ignore gender in base variant
		Return Abs(Children) + Abs(Teenagers) + Abs(HouseWives) + Abs(Employees) + Abs(Unemployed) + Abs(Manager) + Abs(Pensioners)
	End Method


	Method GetWeightedAverage:Float(audienceBreakdown:TAudienceBase = Null) {_exposeToLua}
		'fetch current breakdown if nothing was given
		If Not audienceBreakdown Then audienceBreakdown = AudienceManager.GetAudienceBreakdown()

		Local result:Float = 0
		result :+ Children * audienceBreakdown.Children
		result :+ Teenagers * audienceBreakdown.Teenagers
		result :+ HouseWives * audienceBreakdown.HouseWives
		result :+ Employees * audienceBreakdown.Employees
		result :+ Unemployed * audienceBreakdown.Unemployed
		result :+ Manager * audienceBreakdown.Manager
		result :+ Pensioners * audienceBreakdown.Pensioners

		Return result
	End Method


	Method Add:TAudienceBase(audience:TAudienceBase)
		'skip adding if the param is "unset"
		If Not audience Then Return Self
		Children	:+ audience.Children
		Teenagers	:+ audience.Teenagers
		HouseWives	:+ audience.HouseWives
		Employees	:+ audience.Employees
		Unemployed	:+ audience.Unemployed
		Manager		:+ audience.Manager
		Pensioners	:+ audience.Pensioners
		Return Self
	End Method


	Method AddFloat:TAudienceBase(number:Float)
		Children	:+ number
		Teenagers	:+ number
		HouseWives	:+ number
		Employees	:+ number
		Unemployed	:+ number
		Manager		:+ number
		Pensioners	:+ number
		Return Self
	End Method


	Method Subtract:TAudienceBase(audience:TAudienceBase)
		'skip subtracting if the param is "unset"
		If Not audience Then Return Self
		Children	:- audience.Children
		Teenagers	:- audience.Teenagers
		HouseWives	:- audience.HouseWives
		Employees	:- audience.Employees
		Unemployed	:- audience.Unemployed
		Manager		:- audience.Manager
		Pensioners	:- audience.Pensioners

		Return Self
	End Method


	Method SubtractFloat:TAudienceBase(number:Float)
		Children	:- number
		Teenagers	:- number
		HouseWives	:- number
		Employees	:- number
		Unemployed	:- number
		Manager		:- number
		Pensioners	:- number
		Return Self
	End Method


	Method Multiply:TAudienceBase(audience:TAudienceBase)
		'skip multiplication if the param is "unset"
		If Not audience Then Return Self
		Children	:* audience.Children
		Teenagers	:* audience.Teenagers
		HouseWives	:* audience.HouseWives
		Employees	:* audience.Employees
		Unemployed	:* audience.Unemployed
		Manager		:* audience.Manager
		Pensioners	:* audience.Pensioners
		Return Self
	End Method

	'required until brl.reflection correctly handles "float parameters" 
	'in debug builds (same as "doubles" for 32 bit builds)
	'GREP-key: "brlreflectionbug"
	Method MultiplyString:TAudienceBase(factor:String) {_exposeToLua}
		Return MultiplyFloat(Float(factor))
	End Method
	

	'expose commented out because of above mentioned brl.reflection bug
	Method MultiplyFloat:TAudienceBase(factor:Float) ' {_exposeToLua}
		Children	:* factor
		Teenagers	:* factor
		HouseWives	:* factor
		Employees	:* factor
		Unemployed	:* factor
		Manager		:* factor
		Pensioners	:* factor
		Return Self
	End Method


	Method Divide:TAudienceBase(audience:TAudienceBase)
		If Not audience Then Return Self

		If audience.GetSum() = 0
			'set all values to 0 (new Audience has 0 as default)
			SetValuesFrom(New TAudienceBase)
		Else

			'check for div/0 first
			If audience.Children = 0
				If Abs(children - audience.Children) > 0.01
					Throw "TAudienceBase.Divide: Div/0 - audience.Children is 0. Children is " + Children
				Else
					Children = 0
				EndIf
			Else
				Children :/ audience.Children
			EndIf

			If audience.Teenagers = 0
				If Abs(Teenagers - audience.Teenagers) > 0.01
					Throw "TAudienceBase.Divide: Div/0 - audience.Teenagers is 0. Teenagers is " + Teenagers
				Else
					Teenagers = 0
				EndIf
			Else
				Teenagers :/ audience.Teenagers
			EndIf

			If audience.HouseWives = 0
				If Abs(HouseWives - audience.HouseWives) > 0.01
					Throw "TAudienceBase.Divide: Div/0 - audience.HouseWives is 0. HouseWives is " + HouseWives
				Else
					HouseWives = 0
				EndIf
			Else
				HouseWives :/ audience.HouseWives
			EndIf

			If audience.Employees = 0 And (Abs(Employees - audience.Employees) < 0.01)
				'TODO: this seems pretty useless
				If Abs(Employees - audience.Employees) > 0.01
					Throw "TAudienceBase.Divide: Div/0 - audience.Employees is 0. Employees is " + Employees
				Else
					Employees = 0
				EndIf
			Else
				Employees :/ audience.Employees
			EndIf

			If audience.Unemployed = 0 And (Abs(Unemployed - audience.Unemployed) < 0.01)
				'TODO: this seems pretty useless
				If Abs(Unemployed - audience.Unemployed) > 0.01
					Throw "TAudienceBase.Divide: Div/0 - audience.Unemployed is 0. Unemployed is " + Unemployed
				Else
					Unemployed = 0
				EndIf
			Else
				Unemployed :/ audience.Unemployed
			EndIf

			If audience.Manager = 0 And (Abs(Manager - audience.Manager) < 0.01)
				'TODO: this seems pretty useless
				If Abs(Manager - audience.Manager) > 0.01
					Throw "TAudienceBase.Divide: Div/0 - audience.Manager is 0. Manager is " + Manager
				Else
					Manager = 0
				EndIf
			Else
				Manager :/ audience.Manager
			EndIf

			If audience.Pensioners = 0 And (Abs(Pensioners - audience.Pensioners) < 0.01)
				'TODO: this seems pretty useless
				If Abs(Pensioners - audience.Pensioners) > 0.01
					Throw "TAudienceBase.Divide: Div/0 - audience.Pensioners is 0. Pensioners is " + Pensioners
				Else
					Pensioners = 0
				EndIf
			Else
				Pensioners :/ audience.Pensioners
			EndIf
		EndIf
		Return Self
	End Method


	Method DivideFloat:TAudienceBase(number:Float)
		If number = 0 Then Throw "TAudienceBase.DivideFloat(): Division by zero."

		Children	:/ number
		Teenagers	:/ number
		HouseWives	:/ number
		Employees	:/ number
		Unemployed	:/ number
		Manager		:/ number
		Pensioners	:/ number
		Return Self
	End Method


	Method Round:TAudienceBase()
		Children	= MathHelper.RoundInt(Children)
		Teenagers	= MathHelper.RoundInt(Teenagers)
		HouseWives	= MathHelper.RoundInt(HouseWives)
		Employees	= MathHelper.RoundInt(Employees)
		Unemployed	= MathHelper.RoundInt(Unemployed)
		Manager		= MathHelper.RoundInt(Manager)
		Pensioners	= MathHelper.RoundInt(Pensioners)
		Return Self
	End Method


	Method ToNumberSortMap:TNumberSortMap()
		Local amap:TNumberSortMap = New TNumberSortMap
		amap.Add(TVTTargetGroup.Children, Children)
		amap.Add(TVTTargetGroup.Teenagers, Teenagers)
		amap.Add(TVTTargetGroup.HouseWives, HouseWives)
		amap.Add(TVTTargetGroup.Employees, Employees)
		amap.Add(TVTTargetGroup.Unemployed, Unemployed)
		amap.Add(TVTTargetGroup.Manager, Manager)
		amap.Add(TVTTargetGroup.Pensioners, Pensioners)
		Return amap
	End Method


	Method ToStringPercentage:String(dec:Int = 0) {_exposeToLua}
        Local sb:TStringBuilder = New TStringBuilder
        Local splitter:string = "% /"
        sb.Append("C:").Append(MathHelper.NumberToString(Children*100, dec, True)).Append(splitter)
        sb.Append("T:").Append(MathHelper.NumberToString(Teenagers*100, dec, True)).Append(splitter)
        sb.Append("H:").Append(MathHelper.NumberToString(HouseWives*100, dec, True)).Append(splitter)
        sb.Append("E:").Append(MathHelper.NumberToString(Employees*100, dec, True)).Append(splitter)
        sb.Append("U:").Append(MathHelper.NumberToString(Unemployed*100, dec, True)).Append(splitter)
        sb.Append("M:").Append(MathHelper.NumberToString(Manager*100, dec, True)).Append(splitter)
        sb.Append("P:").Append(MathHelper.NumberToString(Pensioners*100, dec, True)).Append("%")
        Return sb.ToString()
	End Method


	Method ToStringMinimal:String(dec:Int = 0) {_exposeToLua}
        Local sb:TStringBuilder = New TStringBuilder
        Local splitter:string = "/"
        sb.Append("C:").Append(MathHelper.NumberToString(Children, dec, True)).Append(splitter)
        sb.Append("T:").Append(MathHelper.NumberToString(Teenagers, dec, True)).Append(splitter)
        sb.Append("H:").Append(MathHelper.NumberToString(HouseWives, dec, True)).Append(splitter)
        sb.Append("E:").Append(MathHelper.NumberToString(Employees, dec, True)).Append(splitter)
        sb.Append("U:").Append(MathHelper.NumberToString(Unemployed, dec, True)).Append(splitter)
        sb.Append("M:").Append(MathHelper.NumberToString(Manager, dec, True)).Append(splitter)
        sb.Append("P:").Append(MathHelper.NumberToString(Pensioners, dec, True))
        Return sb.ToString()
	End Method


	Method ToString:String() {_exposeToLua}
		Local dec:Int = 4
		Return "Sum = " + MathHelper.NumberToString(GetSum(), dec, True) + "  ( " + ToStringMinimal(0) +" )"
		'Return "Sum =" + Int(Ceil(GetSum())) + "  ( 0=" + MathHelper.NumberToString(Children,dec, True) + "  1=" + MathHelper.NumberToString(Teenagers,dec, True) + "  2=" + MathHelper.NumberToString(HouseWives,dec, True) + "  3=" + MathHelper.NumberToString(Employees,dec, True) + "  4=" + MathHelper.NumberToString(Unemployed,dec, True) + "  5=" + MathHelper.NumberToString(Manager,dec, True) + "  6=" + MathHelper.NumberToString(Pensioners,dec, True) + " )"
	End Method


	Method ToStringAverage:String(dec:Int = 4)
		Return "Avg = " + MathHelper.NumberToString(GetAverage(),3, True) + "  ( " + ToStringMinimal(dec) +" )"
		'Return "Avg = " + MathHelper.NumberToString(GetAverage(),3, True) + "  ( 0=" + MathHelper.NumberToString(Children,3, True) + "  1=" + MathHelper.NumberToString(Teenagers,3, True) + "  2=" + MathHelper.NumberToString(HouseWives,3, True) + "  3=" + MathHelper.NumberToString(Employees,3, True) + "  4=" + MathHelper.NumberToString(Unemployed,3, True) + "  5=" + MathHelper.NumberToString(Manager,3, True) + "  6=" + MathHelper.NumberToString(Pensioners,3, True) + " )"
	End Method


	Function InnerSort:Int(targetId:Int, o1:Object, o2:Object)
		Local s1:TAudienceBase = TAudienceBase(o1)
		Local s2:TAudienceBase = TAudienceBase(o2)
		' Objekt nicht gefunden, an das Ende der Liste setzen
		If Not s2 Then Return 1
        Return 1000 * (s1.GetValue(targetId) - s2.GetValue(targetId))
	End Function


	Function AllSort:Int(o1:Object, o2:Object)
		Local s1:TAudienceBase = TAudienceBase(o1)
		Local s2:TAudienceBase = TAudienceBase(o2)
		If Not s2 Then Return 1
        Return s1.GetSum() - s2.GetSum()
	End Function


	Function ChildrenSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Children, o1, o2)
	End Function


	Function TeenagersSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Teenagers, o1, o2)
	End Function


	Function HouseWivesSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.HouseWives, o1, o2)
	End Function


	Function EmployeesSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Employees, o1, o2)
	End Function


	Function UnemployedSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Unemployed, o1, o2)
	End Function


	Function ManagerSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Manager, o1, o2)
	End Function


	Function PensionersSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Pensioners, o1, o2)
	End Function
End Type




Type TAudience {_exposeToLua="selected"}
	'Optional: Eine Id zur Identifikation (z.B. PlayerId). Nur bei Bedarf füllen!
	Field Id:Int
	Field audienceMale:TAudienceBase
	Field audienceFemale:TAudienceBase


	'=== Constructors ===
	Method Init:TAudience(gender:Int, children:Float, teenagers:Float, HouseWives:Float, employees:Float, unemployed:Float, manager:Float, pensioners:Float)
		If gender = -1 Or gender = TVTPersonGender.FEMALE
			GetAudienceFemale().Init(children, teenagers, HouseWives, employees, unemployed, manager, pensioners)
		EndIf
		If gender = -1 Or gender = TVTPersonGender.MALE
			GetAudienceMale().Init(children, teenagers, HouseWives, employees, unemployed, manager, pensioners)
		EndIf

		Return Self
	End Method


	Method InitBase:TAudience(male:TAudienceBase, female:TAudienceBase)
		If Not male Then male = New TAudienceBase.InitValue(0)
		If Not female Then female = New TAudienceBase.InitValue(0)

		If Not audienceMale Then audienceMale = New TAudienceBase
		If Not audienceFemale Then audienceFemale = New TAudienceBase

		audienceMale.SetValuesFrom(male)
		audienceFemale.SetValuesFrom(female)

		Return Self
	End Method


	Method InitValue:TAudience(valueMale:Float, valueFemale:Float) {_exposeToLua}
		Init(TVTPersonGender.Male, valueMale, valueMale, valueMale, valueMale, valueMale, valueMale, valueMale)
		Init(TVTPersonGender.Female, valueFemale, valueFemale, valueFemale, valueFemale, valueFemale, valueFemale, valueFemale)
		Return Self
	End Method


	Method InitWithBreakdown:TAudience(audience:Int) {_exposeToLua}
		Local breakdown:TAudienceBase = New TAudienceBase.InitValue(1)
		breakdown.Multiply( AudienceManager.GetAudienceBreakdown() )

		GetAudienceFemale().InitWithBreakdown(audience, breakdown)
		GetAudienceFemale().Multiply( AudienceManager.GetGenderBreakdown( TVTPersonGender.FEMALE ) )

		GetAudienceMale().InitWithBreakdown(audience, breakdown)
		GetAudienceMale().Multiply( AudienceManager.GetGenderBreakdown( TVTPersonGender.MALE ) )

		Return Self
	End Method


	Method CopyFrom:TAudience(other:TAudience)
		Self.InitBase(other.audienceMale, other.audienceFemale)
		Return Self
	End Method


	'=== SERIALIZATION / DESERIALIZATION ===

	Method SerializeTAudienceToString:String()
		Local sb:TStringBuilder = New TStringBuilder
		sb.Append(id)

		sb.Append("::ab=")
		If audienceMale Then sb.Append( audienceMale.SerializeTAudienceBaseToString() )

		sb.Append("::ab=")
		If audienceFemale Then sb.Append( audienceFemale.SerializeTAudienceBaseToString() )

		Return sb.ToString()
	End Method


	Method DeSerializeTAudienceFromString(text:String)
		Local parts:String[] = text.split("::ab=")
		id = Int(parts[0])
		If parts.length > 1
			GetAudienceMale().InitValue(0)
			audienceMale.DeSerializeTAudienceBaseFromString(parts[1])
		EndIf
		If parts.length > 2
			If Not audienceFemale Then audienceFemale = New TAudienceBase
			GetAudienceFemale().InitValue(0)
			audienceFemale.DeSerializeTAudienceBaseFromString(parts[2])
		EndIf
	End Method




	'=== PUBLIC ===
	Method GetAudienceFemale:TAudienceBase() {_exposeToLua}
		If Not audienceFemale Then audienceFemale = New TAudienceBase
		Return audienceFemale
	End Method


	Method GetAudienceMale:TAudienceBase() {_exposeToLua}
		If Not audienceMale Then audienceMale = New TAudienceBase
		Return audienceMale
	End Method


	Method Copy:TAudience() {_exposeToLua}
		Local result:TAudience = New TAudience
		result.Id = Id
		result.SetValuesFrom(Self)
		Return result
	End Method


	Method SetValuesFrom:TAudience(value:TAudience)
		SetValues(value.audienceMale, value.audienceFemale)
		Return Self
	End Method


	Method SetValues:TAudience(audienceMale:TAudienceBase, audienceFemale:TAudienceBase)
		If audienceMale Then Self.audienceMale = audienceMale.Copy()
		If audienceFemale Then Self.audienceFemale = audienceFemale.Copy()
		Return Self
	End Method


	Method GetWeightedValue:Float(targetID:Int, genderID:Int = 0) {_exposeToLua}
		Local femaleGenderRatio:Float = AudienceManager.GetGenderBreakdown(TVTPersonGender.FEMALE).GetValue(targetID)
		Local targetgroupRatio:Float = AudienceManager.GetAudienceBreakdown().GetValue(targetID)
		Local result:Float
		If genderID <> TVTPersonGender.MALE
			result :+ GetGenderValue(targetID, TVTPersonGender.FEMALE) * targetgroupRatio * femaleGenderRatio
		EndIf
		If genderID <> TVTPersonGender.FEMALE
			result :+ GetGenderValue(targetID, TVTPersonGender.MALE) * targetgroupRatio * (1 - femaleGenderRatio)
		EndIf
		
		Return result
	End Method


	Method GetTotalValue:Float(targetID:Int) {_exposeToLua}
		If targetID <= 0 Then Return GetTotalSum()

		If targetID = TVTTargetGroup.Women
			Return GetGenderValue(targetID, TVTPersonGender.FEMALE)
		ElseIf targetID = TVTTargetGroup.Men
			Return GetGenderValue(targetID, TVTPersonGender.MALE)
		Else
			Local res:Float = 0
			If audienceMale Then res :+ audienceMale.GetValue(targetID)
			If audienceFemale Then res :+ audienceFemale.GetValue(targetID)
			Return res
		EndIf
	End Method


	Method GetGenderValue:Float(targetID:Int, gender:Int) {_exposeToLua}
		If targetID = TVTTargetGroup.Women
			If Not audienceFemale Or gender = TVTPersonGender.MALE Then Return 0
			Return audienceFemale.GetSum()
		ElseIf targetID = TVTTargetGroup.Men
			If Not audienceMale Or gender = TVTPersonGender.FEMALE  Then Return 0
			Return audienceMale.GetSum()
		EndIf

		If gender = TVTPersonGender.MALE
			If Not audienceMale Then Return 0
			Return audienceMale.GetValue(targetID)
		ElseIf gender = TVTPersonGender.FEMALE
			If Not audienceFemale Then Return 0
			Return audienceFemale.GetValue(targetID)
		EndIf
		Return 0
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
					GetAudienceMale().SetValue(targetID, newValue)
				ElseIf gender = TVTPersonGender.FEMALE
					GetAudienceFemale().SetValue(targetID, newValue)
				Else
					GetAudienceMale().SetValue(targetID, newValue)
					GetAudienceFemale().SetValue(targetID, newValue)
				EndIf
		End Select
	End Method


	Method GetTotalSum:Float() {_exposeToLua}
		Local res:Float = 0
		If audienceFemale Then res :+ audienceFemale.GetSum()
		If audienceMale Then res :+ audienceMale.GetSum()
		Return res
	End Method


	Method GetTotalAbsSum:Float() {_exposeToLua}
		Local res:Float = 0
		If audienceFemale Then res :+ audienceFemale.GetAbsSum()
		If audienceMale Then res :+ audienceMale.GetAbsSum()
		Return res
	End Method


	Method GetGenderSum:Float(gender:Int) {_exposeToLua}
		If gender = TVTPersonGender.MALE
			If audienceMale Then Return audienceMale.GetSum()
		ElseIf gender = TVTPersonGender.FEMALE
			If audienceFemale Then Return audienceFemale.GetSum()
		EndIf
		Return 0
	End Method


	Method GetTotalAverage:Float() {_exposeToLua}
		Return 0.5 * (GetAudienceMale().GetAverage() + GetAudienceFemale().GetAverage())
	End Method


	Method GetGenderAverage:Float(gender:Int) {_exposeToLua}
		If gender = TVTPersonGender.MALE
			Return GetAudienceMale().GetAverage()
		ElseIf gender = TVTPersonGender.FEMALE
			Return GetAudienceFemale().GetAverage()
		EndIf
		Return 0
	End Method


	Method GetWeightedAverage:Float(audienceBreakdown:TAudienceBase = Null, audienceFemaleGenderBreakdown:TAudienceBase = Null) {_exposeToLua}
		'fetch current breakdown if nothing was given
		If Not audienceBreakdown Then audienceBreakdown = AudienceManager.GetAudienceBreakdown()
		If Not audienceFemaleGenderBreakdown Then audienceFemaleGenderBreakdown = AudienceManager.GetGenderBreakdown(TVTPersonGender.FEMALE)

		'multiply the value by their share on the total amount of people
		'so "male children", "female managers"

		Local result:Float = 0
		If audienceMale
			result :+ audienceMale.Children * audienceBreakdown.Children * (1 - audienceFemaleGenderBreakdown.Children)
			result :+ audienceMale.Teenagers * audienceBreakdown.Teenagers * (1 - audienceFemaleGenderBreakdown.Teenagers)
			result :+ audienceMale.HouseWives * audienceBreakdown.HouseWives * (1 - audienceFemaleGenderBreakdown.HouseWives)
			result :+ audienceMale.Employees * audienceBreakdown.Employees * (1 - audienceFemaleGenderBreakdown.Employees)
			result :+ audienceMale.Unemployed * audienceBreakdown.Unemployed * (1 - audienceFemaleGenderBreakdown.Unemployed)
			result :+ audienceMale.Manager * audienceBreakdown.Manager * (1 - audienceFemaleGenderBreakdown.Manager)
			result :+ audienceMale.Pensioners * audienceBreakdown.Pensioners * (1 - audienceFemaleGenderBreakdown.Pensioners)
		EndIf
		If audienceFemale
			result :+ audienceFemale.Children * audienceBreakdown.Children * audienceFemaleGenderBreakdown.Children
			result :+ audienceFemale.Teenagers * audienceBreakdown.Teenagers * audienceFemaleGenderBreakdown.Teenagers
			result :+ audienceFemale.HouseWives * audienceBreakdown.HouseWives * audienceFemaleGenderBreakdown.HouseWives
			result :+ audienceFemale.Employees * audienceBreakdown.Employees * audienceFemaleGenderBreakdown.Employees
			result :+ audienceFemale.Unemployed * audienceBreakdown.Unemployed * audienceFemaleGenderBreakdown.Unemployed
			result :+ audienceFemale.Manager * audienceBreakdown.Manager * audienceFemaleGenderBreakdown.Manager
			result :+ audienceFemale.Pensioners * audienceBreakdown.Pensioners * audienceFemaleGenderBreakdown.Pensioners
		EndIf

		Return result
	End Method


	Method Add:TAudience(audience:TAudience)
		'skip adding if the param is "unset"
		If Not audience Then Return Self

		GetAudienceMale().Add(audience.audienceMale)
		GetAudienceFemale().Add(audience.audienceFemale)
		Return Self
	End Method


	Method AddFloat:TAudience(number:Float)
		GetAudienceMale().AddFloat(number)
		GetAudienceFemale().AddFloat(number)
		Return Self
	End Method


	Method AddGenderFloat:TAudience(number:Float, gender:Int)
		If gender = TVTPersonGender.MALE
			GetAudienceFemale().AddFloat(number)
		Else
			GetAudienceMale().AddFloat(number)
		EndIf
		Return Self
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
					For Local i:Int = 1 To TVTTargetGroup.baseGroupCount
						ModifyGenderValue( TVTTargetGroup.GetAtIndex(i), addValue, TVTPersonGender.FEMALE )
					Next
				Case TVTTargetGroup.Men
					If gender = TVTPersonGender.FEMALE Then Return
					For Local i:Int = 1 To TVTTargetGroup.baseGroupCount
						ModifyGenderValue( TVTTargetGroup.GetAtIndex(i), addValue, TVTPersonGender.MALE  )
					Next

				Default
					If gender = TVTPersonGender.MALE
						GetAudienceMale().SetValue(targetID, GetAudienceMale().GetValue(targetID) + addValue)
					ElseIf gender = TVTPersonGender.FEMALE
						GetAudienceFemale().SetValue(targetID, GetAudienceFemale().GetValue(targetID) + addValue)
					EndIf
			End Select
		Next
	End Method


	Method Subtract:TAudience(audience:TAudience)
		'skip subtracting if the param is "unset"
		If Not audience Then Return Self

		GetAudienceMale().Subtract(audience.audienceMale)
		GetAudienceFemale().Subtract(audience.audienceFemale)
		Return Self
	End Method


	Method SubtractFloat:TAudience(number:Float)
		GetAudienceMale().SubtractFloat(number)
		GetAudienceFemale().SubtractFloat(number)
		Return Self
	End Method


	Method Multiply:TAudience(audience:TAudience)
		'skip if the param is "unset"
		If Not audience Then Return Self

		GetAudienceMale().Multiply(audience.audienceMale)
		GetAudienceFemale().Multiply(audience.audienceFemale)
		Return Self
	End Method


	'required until brl.reflection correctly handles "float parameters" 
	'in debug builds (same as "doubles" for 32 bit builds)
	'GREP-key: "brlreflectionbug"
	Method MultiplyString:TAudience(factor:String) {_exposeToLua}
		Return MultiplyFloat(Float(factor))
	End Method
	

	'expose commented out because of above mentioned brl.reflection bug
	Method MultiplyFloat:TAudience(factor:Float) '{_exposeToLua}
		GetAudienceMale().MultiplyFloat(factor)
		GetAudienceFemale().MultiplyFloat(factor)
		Return Self
	End Method


	Method Divide:TAudience(audience:TAudience)
		If Not audience Then Return Self

		GetAudienceMale().divide(audience.GetAudienceMale())
		GetAudienceFemale().divide(audience.GetAudienceFemale())
		Return Self
	End Method


	Method DivideFloat:TAudience(number:Float)
		GetAudienceMale().divideFloat(number)
		GetAudienceFemale().divideFloat(number)
		Return Self
	End Method


	Method Round:TAudience()
		If audienceMale Then audienceMale.Round()
		If audienceFemale Then audienceFemale.Round()
		Return Self
	End Method


	Method CutBordersFloat:TAudience(minimum:Float, maximum:Float)
		If audienceMale Then audienceMale.CutBordersFloat(minimum, maximum)
		If audienceFemale Then audienceFemale.CutBordersFloat(minimum, maximum)
		Return Self
	End Method


	Method CutBorders:TAudience(minimum:TAudience, maximum:TAudience)
		If Not minimum Or Not maximum Then Return Self

		If audienceMale Then audienceMale.CutBorders(minimum.audienceMale, maximum.audienceMale)
		If audienceFemale Then audienceFemale.CutBorders(minimum.audienceFemale, maximum.audienceFemale)
		Return Self
	End Method


	Method CutMinimumFloat:TAudience(value:Float)
		CutMinimum( New TAudience.InitValue(value, value) )
		Return Self
	End Method


	Method CutMinimum:TAudience(minimum:TAudience)
		If Not minimum Then Return Self

		If audienceMale Then audienceMale.CutMinimum(minimum.audienceMale)
		If audienceFemale Then audienceFemale.CutMinimum(minimum.audienceFemale)
		Return Self
	End Method


	Method CutMaximumFloat:TAudience(value:Float)
		CutMaximum( New TAudience.InitValue(value, value) )
		Return Self
	End Method


	Method CutMaximum:TAudience(maximum:TAudience)
		If Not maximum Then Return Self

		If audienceMale Then audienceMale.CutMaximum(maximum.audienceMale)
		If audienceFemale Then audienceFemale.CutMaximum(maximum.audienceFemale)
		Return Self
	End Method


	Method ToNumberSortMap:TNumberSortMap()
		Local amap:TNumberSortMap = New TNumberSortMap
		amap.Add(TVTTargetGroup.Children, GetTotalValue(TVTTargetGroup.Children))
		amap.Add(TVTTargetGroup.Teenagers, GetTotalValue(TVTTargetGroup.Teenagers))
		amap.Add(TVTTargetGroup.HouseWives, GetTotalValue(TVTTargetGroup.HouseWives))
		amap.Add(TVTTargetGroup.Employees, GetTotalValue(TVTTargetGroup.Employees))
		amap.Add(TVTTargetGroup.Unemployed, GetTotalValue(TVTTargetGroup.Unemployed))
		amap.Add(TVTTargetGroup.Manager, GetTotalValue(TVTTargetGroup.Manager))
		amap.Add(TVTTargetGroup.Pensioners, GetTotalValue(TVTTargetGroup.Pensioners))
		Return amap
	End Method


	'=== TO STRING ===

	Method ToStringPercentage:String(dec:Int = 0) {_exposeToLua}
        Local sb:TStringBuilder = New TStringBuilder
        sb.Append("C:").Append(MathHelper.NumberToString(GetAudienceMale().Children*100, dec, True)).Append("/").Append(MathHelper.NumberToString(GetAudienceFemale().Children*100, dec, True)).Append("% / ")
        sb.Append("T:").Append(MathHelper.NumberToString(GetAudienceMale().Teenagers*100, dec, True)).Append("/").Append(MathHelper.NumberToString(GetAudienceFemale().Teenagers*100, dec, True)).Append("% / ")
        sb.Append("H:").Append(MathHelper.NumberToString(GetAudienceMale().HouseWives*100, dec, True)).Append("/").Append(MathHelper.NumberToString(GetAudienceFemale().HouseWives*100, dec, True)).Append("% / ")
        sb.Append("E:").Append(MathHelper.NumberToString(GetAudienceMale().Employees*100, dec, True)).Append("/").Append(MathHelper.NumberToString(GetAudienceFemale().Employees*100, dec, True)).Append("% / ")
        sb.Append("U:").Append(MathHelper.NumberToString(GetAudienceMale().Unemployed*100, dec, True)).Append("/").Append(MathHelper.NumberToString(GetAudienceFemale().Unemployed*100, dec, True)).Append("% / ")
        sb.Append("M:").Append(MathHelper.NumberToString(GetAudienceMale().Manager*100, dec, True)).Append("/").Append(MathHelper.NumberToString(GetAudienceFemale().Manager*100, dec, True)).Append("% / ")
        sb.Append("P:").Append(MathHelper.NumberToString(GetAudienceMale().Pensioners*100, dec, True)).Append("/").Append(MathHelper.NumberToString(GetAudienceFemale().Pensioners*100, dec, True)).Append("%")
        Return sb.ToString()
	End Method


	Method ToStringMinimal:String(dec:Int=0) {_exposeToLua}
        Local sb:TStringBuilder = New TStringBuilder
        sb.Append("C:").Append(MathHelper.NumberToString(GetAudienceMale().Children, dec, True)).Append("/").Append(MathHelper.NumberToString(GetAudienceFemale().Children, dec, True)).Append(" / ")
        sb.Append("T:").Append(MathHelper.NumberToString(GetAudienceMale().Teenagers, dec, True)).Append("/").Append(MathHelper.NumberToString(GetAudienceFemale().Teenagers, dec, True)).Append(" / ")
        sb.Append("H:").Append(MathHelper.NumberToString(GetAudienceMale().HouseWives, dec, True)).Append("/").Append(MathHelper.NumberToString(GetAudienceFemale().HouseWives, dec, True)).Append(" / ")
        sb.Append("E:").Append(MathHelper.NumberToString(GetAudienceMale().Employees, dec, True)).Append("/").Append(MathHelper.NumberToString(GetAudienceFemale().Employees, dec, True)).Append(" / ")
        sb.Append("U:").Append(MathHelper.NumberToString(GetAudienceMale().Unemployed, dec, True)).Append("/").Append(MathHelper.NumberToString(GetAudienceFemale().Unemployed, dec, True)).Append(" / ")
        sb.Append("M:").Append(MathHelper.NumberToString(GetAudienceMale().Manager, dec, True)).Append("/").Append(MathHelper.NumberToString(GetAudienceFemale().Manager, dec, True)).Append(" / ")
        sb.Append("P:").Append(MathHelper.NumberToString(GetAudienceMale().Pensioners, dec, True)).Append("/").Append(MathHelper.NumberToString(GetAudienceFemale().Pensioners, dec, True))
        Return sb.ToString()
    End Method


	Method ToString:String() {_exposeToLua}
		Local dec:Int = 3
		Return "Sum = " + MathHelper.NumberToString(GetTotalSum(), dec, True) + "  ( " + ToStringMinimal(dec) +" )"
		'Return "Sum = " + Int(Ceil(GetSum())) + "  ( 0=" + MathHelper.NumberToString(GetValue(TVTTargetGroup.Children),dec, True) + "  1=" + MathHelper.NumberToString(GetValue(TVTTargetGroup.Teenagers),dec, True) + "  2=" + MathHelper.NumberToString(GetValue(TVTTargetGroup.HouseWives),dec, True) + "  3=" + MathHelper.NumberToString(GetValue(TVTTargetGroup.Employees),dec, True) + "  4=" + MathHelper.NumberToString(GetValue(TVTTargetGroup.Unemployed),dec, True) + "  5=" + MathHelper.NumberToString(GetValue(TVTTargetGroup.Manager),dec, True) + "  6=" + MathHelper.NumberToString(GetValue(TVTTargetGroup.Pensioners),dec, True) + " )  [[ W=" + MathHelper.NumberToString(GetSum(TVTPersonGender.FEMALE),dec, True) + "  M=" + MathHelper.NumberToString(GetSum(TVTPersonGender.FEMALE) ,dec, True) + " ]]"
	End Method


	Method ToStringAverage:String()
		Local dec:Int = 3
		Return "Avg = " + MathHelper.NumberToString(GetTotalAverage(), dec, True) + "  ( " + ToStringMinimal(dec) +" )"
		'Return "Avg = " + MathHelper.NumberToString(GetAverage(),3, True) + "  ( 0=" + MathHelper.NumberToString(GetValue(TVTTargetGroup.Children),3, True) + "  1=" + MathHelper.NumberToString(GetValue(TVTTargetGroup.Teenagers),3, True) + "  2=" + MathHelper.NumberToString(GetValue(TVTTargetGroup.HouseWives),3, True) + "  3=" + MathHelper.NumberToString(GetValue(TVTTargetGroup.Employees),3, True) + "  4=" + MathHelper.NumberToString(GetValue(TVTTargetGroup.Unemployed),3, True) + "  5=" + MathHelper.NumberToString(GetValue(TVTTargetGroup.Manager),3, True) + "  6=" + MathHelper.NumberToString(GetValue(TVTTargetGroup.Pensioners),3, True) + " )"
	End Method


	'=== SORTING FUNCTIONS ===

	Function InnerSort:Int(targetId:Int, o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
		If Not s2 Then Return 1
        Return 1000 * (s1.GetTotalValue(targetId) - s2.GetTotalValue(targetId))
	End Function


	Function AllSort:Int(o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
		If Not s2 Then Return 1
        Return s1.GetTotalSum() - s2.GetTotalSum()
	End Function


	Function ChildrenSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Children, o1, o2)
	End Function


	Function TeenagersSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Teenagers, o1, o2)
	End Function


	Function HouseWivesSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.HouseWives, o1, o2)
	End Function


	Function EmployeesSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Employees, o1, o2)
	End Function


	Function UnemployedSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Unemployed, o1, o2)
	End Function


	Function ManagerSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Manager, o1, o2)
	End Function


	Function PensionersSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Pensioners, o1, o2)
	End Function


	Function MenSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Men, o1, o2)
	End Function


	Function WomenSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Women, o1, o2)
	End Function
End Type