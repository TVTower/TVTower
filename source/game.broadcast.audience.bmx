SuperStrict
Import "Dig/base.util.numbersortmap.bmx"
Import "Dig/base.util.helper.bmx" 'for roundInt()
Import "game.exceptions.bmx"
Import "game.gameconstants.bmx"

'Diese Klasse repräsentiert das Publikum, dass die Summe seiner Zielgruppen ist.
'Die Klasse kann sowohl Zuschauerzahlen als auch Faktoren/Quoten beinhalten
'und stellt einige Methoden bereit die Berechnung mit Faktoren und anderen
'TAudience-Klassen ermöglichen.
Type TAudience
	Field Id:Int				'Optional: Eine Id zur Identifikation (z.B. PlayerId). Nur bei Bedarf füllen!
	Field Children:Float	= 0	'Kinder
	Field Teenagers:Float	= 0	'Teenager
	Field HouseWives:Float	= 0	'Hausfrauen
	Field Employees:Float	= 0	'Employees
	Field Unemployed:Float	= 0	'Arbeitslose
	Field Manager:Float		= 0	'Manager
	Field Pensioners:Float	= 0	'Rentner
	Field Women:Float		= 0	'Frauen
	Field Men:Float			= 0	'Männer

	'=== Constructors ===

	Function CreateAndInit:TAudience(children:Float, teenagers:Float, HouseWives:Float, employees:Float, unemployed:Float, manager:Float, pensioners:Float, women:Float=-1, men:Float=-1)
		Local obj:TAudience = New TAudience
		obj.SetValues(children, teenagers, HouseWives, employees, unemployed, manager, pensioners, women, men)
		If (women = -1 And men = -1) Then obj.CalcGenderBreakdown()
		Return obj
	End Function


	Function CreateAndInitValue:TAudience(defaultValue:Float)
		Local obj:TAudience = New TAudience
		obj.AddFloat(defaultValue)
		Return obj
	End Function


	Function CreateWithBreakdown:TAudience(audience:Int)
		Local obj:TAudience = New TAudience
		obj.Children	= audience * 0.09	'Kinder (9%)
		obj.Teenagers	= audience * 0.1	'Teenager (10%)
		'adults 60%
		obj.HouseWives	= audience * 0.12	'Hausfrauen (20% von 60% Erwachsenen = 12%)
		obj.Employees	= audience * 0.405	'Arbeitnehmer (67,5% von 60% Erwachsenen = 40,5%)
		obj.Unemployed	= audience * 0.045	'Arbeitslose (7,5% von 60% Erwachsenen = 4,5%)
		obj.Manager		= audience * 0.03	'Manager (5% von 60% Erwachsenen = 3%)
		obj.Pensioners	= audience * 0.21	'Rentner (21%)
		'gender
		obj.CalcGenderBreakdown()
		Return obj
	End Function


	'=== PUBLIC ===

	Method Copy:TAudience()
		Local result:TAudience = New TAudience
		result.Id = Id
		result.SetValuesFrom(Self)
		return result
	End Method


	Method SetValuesFrom:TAudience(value:TAudience)
		Self.SetValues(value.Children, value.Teenagers, value.HouseWives, value.Employees, value.Unemployed, value.Manager, value.Pensioners, value.Women, value.Men)
		Return Self
	End Method


	Method SetValues:TAudience(children:Float, teenagers:Float, HouseWives:Float, employees:Float, unemployed:Float, manager:Float, pensioners:Float, women:Float=-1, men:Float=-1)
		Self.Children	= children
		Self.Teenagers	= teenagers
		Self.HouseWives	= HouseWives
		Self.Employees	= employees
		Self.Unemployed	= unemployed
		Self.Manager	= manager
		Self.Pensioners	= pensioners
		'gender
		Self.Women		= women
		Self.Men		= men
		Return Self
	End Method


	Method GetAverage:Float()
		Return GetSum() / 7
	End Method


	Method CalcGenderBreakdown()
		Women = Children * 0.5 + Teenagers * 0.5 + HouseWives * 0.9 + Employees * 0.4 + Unemployed * 0.4 + Manager * 0.25 + Pensioners * 0.55
		Men   = Children * 0.5 + Teenagers * 0.5 + HouseWives * 0.1 + Employees * 0.6 + Unemployed * 0.6 + Manager * 0.75 + Pensioners * 0.45
	End Method


	Method FixGenderCount()
		Local GenderSum:Float = Women + Men
		Local AudienceSum:Int = GetSum();

		Women = Ceil(AudienceSum / GenderSum * Women)
		Men = Ceil(AudienceSum / GenderSum * Men)
		Men :+ AudienceSum - Women - Men 'Den Rest bei den Männern draufrechnen/abziehen
	End Method


	Method CutBordersFloat:TAudience(minimum:Float, maximum:Float)
		CutMinimumFloat(minimum)
		CutMaximumFloat(maximum)
		Return Self
	End Method


	Method CutBorders:TAudience(minimum:TAudience, maximum:TAudience)
		CutMinimum(minimum)
		CutMaximum(maximum)
		Return Self
	End Method


	Method CutMinimumFloat:TAudience(value:float)
		CutMinimum(TAudience.CreateAndInitValue(value))
		Return Self
	End Method


	Method CutMinimum:TAudience(minimum:TAudience)
		If Children < minimum.Children Then Children = minimum.Children
		If Teenagers < minimum.Teenagers Then Teenagers = minimum.Teenagers
		If HouseWives < minimum.HouseWives Then HouseWives = minimum.HouseWives
		If Employees < minimum.Employees Then Employees = minimum.Employees
		If Unemployed < minimum.Unemployed Then Unemployed = minimum.Unemployed
		If Manager < minimum.Manager Then Manager = minimum.Manager
		If Pensioners < minimum.Pensioners Then Pensioners = minimum.Pensioners
		If Women < minimum.Women Then Women = minimum.Women
		If Men < minimum.Men Then Men = minimum.Men
		Return Self
	End Method


	Method CutMaximumFloat:TAudience(value:float)
		CutMaximum(TAudience.CreateAndInitValue(value))
		Return Self
	End Method


	Method CutMaximum:TAudience(maximum:TAudience)
		If Children > maximum.Children Then Children = maximum.Children
		If Teenagers > maximum.Teenagers Then Teenagers = maximum.Teenagers
		If HouseWives > maximum.HouseWives Then HouseWives = maximum.HouseWives
		If Employees > maximum.Employees Then Employees = maximum.Employees
		If Unemployed > maximum.Unemployed Then Unemployed = maximum.Unemployed
		If Manager > maximum.Manager Then Manager = maximum.Manager
		If Pensioners > maximum.Pensioners Then Pensioners = maximum.Pensioners
		If Women > maximum.Women Then Women = maximum.Women
		If Men > maximum.Men Then Men = maximum.Men
		Return Self
	End Method


	Method GetValue:Float(targetID:int)
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
			Case TVTTargetGroup.Women
				Return Women
			Case TVTTargetGroup.Men
				Return Men
			Default
				print "unknown"
				Throw TArgumentException.Create("targetID", String.FromInt(targetID))
		End Select
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
			Case TVTTargetGroup.Women
				Women = newValue
			Case TVTTargetGroup.Men
				Men = newValue
			Default
				Throw TArgumentException.Create("targetID", String.FromInt(targetID))
		End Select
	End Method


	Method GetSum:Float()
		Return Children + Teenagers + HouseWives + Employees + Unemployed + Manager + Pensioners
	End Method


	Method Add:TAudience(audience:TAudience)
		'skip adding if the param is "unset"
		If Not audience Then Return Self
		Children	:+ audience.Children
		Teenagers	:+ audience.Teenagers
		HouseWives	:+ audience.HouseWives
		Employees	:+ audience.Employees
		Unemployed	:+ audience.Unemployed
		Manager		:+ audience.Manager
		Pensioners	:+ audience.Pensioners
		Women		:+ audience.Women
		Men			:+ audience.Men
		Return Self
	End Method


	Method AddFloat:TAudience(number:Float)
		Children	:+ number
		Teenagers	:+ number
		HouseWives	:+ number
		Employees	:+ number
		Unemployed	:+ number
		Manager		:+ number
		Pensioners	:+ number
		Women		:+ number
		Men			:+ number
		Return Self
	End Method


	Method Subtract:TAudience(audience:TAudience)
		'skip subtracting if the param is "unset"
		If Not audience Then Return Self
		Children	:- audience.Children
		Teenagers	:- audience.Teenagers
		HouseWives	:- audience.HouseWives
		Employees	:- audience.Employees
		Unemployed	:- audience.Unemployed
		Manager		:- audience.Manager
		Pensioners	:- audience.Pensioners
		Women		:- audience.Women
		Men			:- audience.Men

		Return Self
	End Method


	Method SubtractFloat:TAudience(number:Float)
		Children	:- number
		Teenagers	:- number
		HouseWives	:- number
		Employees	:- number
		Unemployed	:- number
		Manager		:- number
		Pensioners	:- number
		Women		:- number
		Men			:- number
		Return Self
	End Method


	Method Multiply:TAudience(audience:TAudience)
		Children	:* audience.Children
		Teenagers	:* audience.Teenagers
		HouseWives	:* audience.HouseWives
		Employees	:* audience.Employees
		Unemployed	:* audience.Unemployed
		Manager		:* audience.Manager
		Pensioners	:* audience.Pensioners
		Women		:* audience.Women
		Men			:* audience.Men
		Return Self
	End Method


	Method MultiplyFloat:TAudience(factor:Float)
		Children	:* factor
		Teenagers	:* factor
		HouseWives	:* factor
		Employees	:* factor
		Unemployed	:* factor
		Manager		:* factor
		Pensioners	:* factor
		Women		:* factor
		Men			:* factor
		Return Self
	End Method


	Method Divide:TAudience(audience:TAudience)
		if audience.GetSum() = 0
			'set all values to 0 (new Audience has 0 as default)
			SetValuesFrom(new TAudience)
		Else
			Children	:/ audience.Children
			Teenagers	:/ audience.Teenagers
			HouseWives	:/ audience.HouseWives
			Employees	:/ audience.Employees
			Unemployed	:/ audience.Unemployed
			Manager		:/ audience.Manager
			Pensioners	:/ audience.Pensioners
			Women		:/ audience.Women
			Men			:/ audience.Men
		EndIf
		Return Self
	End Method


	Method DivideFloat:TAudience(number:Float)
		Children	:/ number
		Teenagers	:/ number
		HouseWives	:/ number
		Employees	:/ number
		Unemployed	:/ number
		Manager		:/ number
		Pensioners	:/ number
		Women		:/ number
		Men			:/ number
		Return Self
	End Method


	Method Round:TAudience()
		Children	= MathHelper.RoundInt(Children)
		Teenagers	= MathHelper.RoundInt(Teenagers)
		HouseWives	= MathHelper.RoundInt(HouseWives)
		Employees	= MathHelper.RoundInt(Employees)
		Unemployed	= MathHelper.RoundInt(Unemployed)
		Manager		= MathHelper.RoundInt(Manager)
		Pensioners	= MathHelper.RoundInt(Pensioners)
		Women		= MathHelper.RoundInt(Women)
		Men			= MathHelper.RoundInt(Men)
		Return Self
	End Method


	Method ToNumberSortMap:TNumberSortMap(withSubGroups:Int=false)
		Local amap:TNumberSortMap = new TNumberSortMap
		amap.Add(TVTTargetGroup.Children, Children)
		amap.Add(TVTTargetGroup.Teenagers, Teenagers)
		amap.Add(TVTTargetGroup.HouseWives, HouseWives)
		amap.Add(TVTTargetGroup.Employees, Employees)
		amap.Add(TVTTargetGroup.Unemployed, Unemployed)
		amap.Add(TVTTargetGroup.Manager, Manager)
		amap.Add(TVTTargetGroup.Pensioners, Pensioners)
		If withSubGroups Then
			amap.Add(TVTTargetGroup.Women, Women)
			amap.Add(TVTTargetGroup.Men, Men)
		EndIf
		Return amap
	End Method

	Method ToStringMinimal:String()
		Local dec:Int = 0
		Return "C:" + MathHelper.floatToString(Children,dec) + " / T:" + MathHelper.floatToString(Teenagers,dec) + " / H:" + MathHelper.floatToString(HouseWives,dec) + " / E:" + MathHelper.floatToString(Employees,dec) + " / U:" + MathHelper.floatToString(Unemployed,dec) + " / M:" + MathHelper.floatToString(Manager,dec) + " /P:" + MathHelper.floatToString(Pensioners,dec)
	End Method

	Method ToString:String()
		Local dec:Int = 4
		Return "Sum: " + Int(Ceil(GetSum())) + "  ( 0: " + MathHelper.floatToString(Children,dec) + "  - 1: " + MathHelper.floatToString(Teenagers,dec) + "  - 2: " + MathHelper.floatToString(HouseWives,dec) + "  - 3: " + MathHelper.floatToString(Employees,dec) + "  - 4: " + MathHelper.floatToString(Unemployed,dec) + "  - 5: " + MathHelper.floatToString(Manager,dec) + "  - 6: " + MathHelper.floatToString(Pensioners,dec) + ") - [[ W: " + MathHelper.floatToString(Women,dec) + "  - M: " + MathHelper.floatToString(Men ,dec) + " ]]"
	End Method


	Method ToStringAverage:String()
		Return "Avg: " + MathHelper.floatToString(GetAverage(),3) + "  ( 0: " + MathHelper.floatToString(Children,3) + "  - 1: " + MathHelper.floatToString(Teenagers,3) + "  - 2: " + MathHelper.floatToString(HouseWives,3) + "  - 3: " + MathHelper.floatToString(Employees,3) + "  - 4: " + MathHelper.floatToString(Unemployed,3) + "  - 5: " + MathHelper.floatToString(Manager,3) + "  - 6: " + MathHelper.floatToString(Pensioners,3) + ")"
	End Method


	Function InnerSort:Int(targetId:Int, o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
		' Objekt nicht gefunden, an das Ende der Liste setzen
		If Not s2 Then Return 1
        Return 1000 * (s1.GetValue(targetId) - s2.GetValue(targetId))
	End Function

	
	Function AllSort:Int(o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
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


	Function WomenSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Women, o1, o2)
	End Function


	Function MenSort:Int(o1:Object, o2:Object)
		Return InnerSort(TVTTargetGroup.Men, o1, o2)
	End Function
End Type