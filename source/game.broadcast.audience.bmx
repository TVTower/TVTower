SuperStrict
Import "Dig/base.util.numbersortmap.bmx"
Import "Dig/base.util.helper.bmx" 'for roundInt()
Import "game.exceptions.bmx"

'Diese Klasse repräsentiert das Publikum, dass die Summe seiner Zielgruppen ist.
'Die Klasse kann sowohl Zuschauerzahlen als auch Faktoren/Quoten beinhalten
'und stellt einige Methoden bereit die Berechnung mit Faktoren und anderen
'TAudience-Klassen ermöglichen.
Type TAudience
	Field Id:Int				'Optional: Eine Id zur Identifikation (z.B. PlayerId). Nur bei Bedarf füllen!
	Field Children:Float	= 0	'Kinder
	Field Teenagers:Float	= 0	'Teenager
	Field HouseWifes:Float	= 0	'Hausfrauen
	Field Employees:Float	= 0	'Employees
	Field Unemployed:Float	= 0	'Arbeitslose
	Field Manager:Float		= 0	'Manager
	Field Pensioners:Float	= 0	'Rentner
	Field Women:Float		= 0	'Frauen
	Field Men:Float			= 0	'Männer

	'=== Constructors ===

	Function CreateAndInit:TAudience(children:Float, teenagers:Float, houseWifes:Float, employees:Float, unemployed:Float, manager:Float, pensioners:Float, women:Float=-1, men:Float=-1)
		Local obj:TAudience = New TAudience
		obj.SetValues(children, teenagers, houseWifes, employees, unemployed, manager, pensioners, women, men)
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
		obj.HouseWifes	= audience * 0.12	'Hausfrauen (20% von 60% Erwachsenen = 12%)
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
		Self.SetValues(value.Children, value.Teenagers, value.HouseWifes, value.Employees, value.Unemployed, value.Manager, value.Pensioners, value.Women, value.Men)
		Return Self
	End Method


	Method SetValues:TAudience(children:Float, teenagers:Float, houseWifes:Float, employees:Float, unemployed:Float, manager:Float, pensioners:Float, women:Float=-1, men:Float=-1)
		Self.Children	= children
		Self.Teenagers	= teenagers
		Self.HouseWifes	= houseWifes
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
		Return (Children + Teenagers + HouseWifes + Employees + Unemployed + Manager + Pensioners) / 7
	End Method


	Method CalcGenderBreakdown()
		Women		= Children * 0.5 + Teenagers * 0.5 + HouseWifes * 0.9 + Employees * 0.4 + Unemployed * 0.4 + Manager * 0.25 + Pensioners * 0.55
		Men			= Children * 0.5 + Teenagers * 0.5 + HouseWifes * 0.1 + Employees * 0.6 + Unemployed * 0.6 + Manager * 0.75 + Pensioners * 0.45
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
		If HouseWifes < minimum.HouseWifes Then HouseWifes = minimum.HouseWifes
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
		If HouseWifes > maximum.HouseWifes Then HouseWifes = maximum.HouseWifes
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
			Case 1	Return Children
			Case 2	Return Teenagers
			Case 3	Return HouseWifes
			Case 4	Return Employees
			Case 5	Return Unemployed
			Case 6	Return Manager
			Case 7	Return Pensioners
			Case 8 	Return Women
			Case 9	Return Men
			Default
				Throw TArgumentException.Create("targetID", String.FromInt(targetID))
		End Select
	End Method


	Method SetValue(targetID:Int, newValue:Float)
		Select targetID
			Case 1	Children = newValue
			Case 2	Teenagers = newValue
			Case 3	HouseWifes = newValue
			Case 4	Employees = newValue
			Case 5	Unemployed = newValue
			Case 6	Manager = newValue
			Case 7	Pensioners = newValue
			Case 8	Women = newValue
			Case 9	Men = newValue
			Default
				Throw TArgumentException.Create("targetID", String.FromInt(targetID))
		End Select
	End Method


	Method GetSum:Float()
		Return Children + Teenagers + HouseWifes + Employees + Unemployed + Manager + Pensioners
	End Method


	Method Add:TAudience(audience:TAudience)
		'skip adding if the param is "unset"
		If Not audience Then Return Self
		Children	:+ audience.Children
		Teenagers	:+ audience.Teenagers
		HouseWifes	:+ audience.HouseWifes
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
		HouseWifes	:+ number
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
		HouseWifes	:- audience.HouseWifes
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
		HouseWifes	:- number
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
		HouseWifes	:* audience.HouseWifes
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
		HouseWifes	:* factor
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
			HouseWifes	:/ audience.HouseWifes
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
		HouseWifes	:/ number
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
		HouseWifes	= MathHelper.RoundInt(HouseWifes)
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
		amap.Add("1", Children)
		amap.Add("2", Teenagers)
		amap.Add("3", HouseWifes)
		amap.Add("4", Employees)
		amap.Add("5", Unemployed)
		amap.Add("6", Manager)
		amap.Add("7", Pensioners)
		If withSubGroups Then
			amap.Add("8", Women)
			amap.Add("9", Men)
		EndIf
		Return amap
	End Method

	Method ToStringMinimal:String()
		Local dec:Int = 0
		Return "C:" + MathHelper.floatToString(Children,dec) + " / T:" + MathHelper.floatToString(Teenagers,dec) + " / H:" + MathHelper.floatToString(HouseWifes,dec) + " / E:" + MathHelper.floatToString(Employees,dec) + " / U:" + MathHelper.floatToString(Unemployed,dec) + " / M:" + MathHelper.floatToString(Manager,dec) + " /P:" + MathHelper.floatToString(Pensioners,dec)
	End Method

	Method ToString:String()
		Local dec:Int = 4
		Return "Sum: " + Int(Ceil(GetSum())) + "  ( 0: " + MathHelper.floatToString(Children,dec) + "  - 1: " + MathHelper.floatToString(Teenagers,dec) + "  - 2: " + MathHelper.floatToString(HouseWifes,dec) + "  - 3: " + MathHelper.floatToString(Employees,dec) + "  - 4: " + MathHelper.floatToString(Unemployed,dec) + "  - 5: " + MathHelper.floatToString(Manager,dec) + "  - 6: " + MathHelper.floatToString(Pensioners,dec) + ") - [[ W: " + MathHelper.floatToString(Women,dec) + "  - M: " + MathHelper.floatToString(Men ,dec) + " ]]"
	End Method


	Method ToStringAverage:String()
		Return "Avg: " + MathHelper.floatToString(GetAverage(),3) + "  ( 0: " + MathHelper.floatToString(Children,3) + "  - 1: " + MathHelper.floatToString(Teenagers,3) + "  - 2: " + MathHelper.floatToString(HouseWifes,3) + "  - 3: " + MathHelper.floatToString(Employees,3) + "  - 4: " + MathHelper.floatToString(Unemployed,3) + "  - 5: " + MathHelper.floatToString(Manager,3) + "  - 6: " + MathHelper.floatToString(Pensioners,3) + ")"
	End Method


	Function InnerSort:Int(targetId:Int, o1:Object, o2:Object)
		Local s1:TAudience = TAudience(o1)
		Local s2:TAudience = TAudience(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.GetValue(targetId)*1000)-(s2.GetValue(targetId)*1000)
	End Function


	Function ChildrenSort:Int(o1:Object, o2:Object)
		Return InnerSort(1, o1, o2)
	End Function


	Function TeenagersSort:Int(o1:Object, o2:Object)
		Return InnerSort(2, o1, o2)
	End Function


	Function HouseWifesSort:Int(o1:Object, o2:Object)
		Return InnerSort(3, o1, o2)
	End Function

	Function EmployeesSort:Int(o1:Object, o2:Object)
		Return InnerSort(4, o1, o2)
	End Function


	Function UnemployedSort:Int(o1:Object, o2:Object)
		Return InnerSort(5, o1, o2)
	End Function

	Function ManagerSort:Int(o1:Object, o2:Object)
		Return InnerSort(6, o1, o2)
	End Function


	Function PensionersSort:Int(o1:Object, o2:Object)
		Return InnerSort(7, o1, o2)
	End Function

	Function WomenSort:Int(o1:Object, o2:Object)
		Return InnerSort(8, o1, o2)
	End Function


	Function MenSort:Int(o1:Object, o2:Object)
		Return InnerSort(9, o1, o2)
	End Function
End Type