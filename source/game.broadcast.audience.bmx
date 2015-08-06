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
	Global audienceBreakdown:TAudience = null
	Global genderBreakdown:TAudience = null
	
	'=== Constructors ===

	Function CreateAndInit:TAudience(children:Float, teenagers:Float, HouseWives:Float, employees:Float, unemployed:Float, manager:Float, pensioners:Float, women:Float=-1, men:Float=-1)
		Local obj:TAudience = New TAudience
		obj.SetValues(children, teenagers, HouseWives, employees, unemployed, manager, pensioners, women, men)
		If (women = -1 Or men = -1) Then obj.FixGenderCount()
		Return obj
	End Function


	Function CreateAndInitValue:TAudience(defaultValue:Float)
		Local obj:TAudience = New TAudience
		obj.AddFloat(defaultValue)
		Return obj
	End Function


	Function GetAudienceBreakdown:TAudience()
		if not audienceBreakdown
			audienceBreakDown = New TAudience
			audienceBreakDown.Children   = 0.09  'Kinder (9%)
			audienceBreakDown.Teenagers	 = 0.1   'Teenager (10%)
			'adults 60%
			audienceBreakDown.HouseWives = 0.12  'Hausfrauen (20% von 60% Erwachsenen = 12%)
			audienceBreakDown.Employees  = 0.405 'Arbeitnehmer (67,5% von 60% Erwachsenen = 40,5%)
			audienceBreakDown.Unemployed = 0.045 'Arbeitslose (7,5% von 60% Erwachsenen = 4,5%)
			audienceBreakDown.Manager    = 0.03  'Manager (5% von 60% Erwachsenen = 3%)
			audienceBreakDown.Pensioners = 0.21  'Rentner (21%)
			'gender
			audienceBreakDown.CalcGenderBreakdown()
		endif
		return audienceBreakDown
	End Function


	Function GetGenderBreakdown:Taudience()
		if not genderBreakdown
			'based partially on data from:
			'http://www.bpb.de/wissen/X39RH6,0,0,Bev%F6lkerung_nach_Altersgruppen_und_Geschlecht.html
			'(of 2010)
			'and
			'http://statistik.arbeitsagentur.de/Statischer-Content/Statistische-Analysen/Analytikreports/Zentrale-Analytikreports/Monatliche-Analytikreports/Generische-Publikationen/Analyse-Arbeitsmarkt-Frauen-Maenner/Analyse-Arbeitsmarkt-Frauen-Maenner-201506.pdf
			'(of 2015)

			'value describes percentage of women in that group
			genderBreakdown = New TAudience
			genderBreakdown.Children = 0.487
			genderBreakdown.Teenagers = 0.487
			genderBreakdown.HouseWives = 0.9
			genderBreakdown.Employees = 0.4
			genderBreakdown.Unemployed = 0.45
			genderBreakdown.Manager = 0.20
			genderBreakdown.Pensioners = 0.58 'the older the more women
		endif
		return genderBreakdown
	End Function


	Function CreateWithBreakdown:TAudience(audience:Int)
		return GetAudienceBreakDown().Copy().MultiplyFloat(audience)
	End Function


	Function CreateForSingleGender:TAudience(audience:Int, returnWomen:int=True)
		if returnWomen
			return GetGenderBreakdown().Copy().MultiplyFloat(audience)
		else
			return CreateAndInitValue(1).Subtract(GetGenderBreakdown()).MultiplyFloat(audience)
		endif
	End Function


	'=== PUBLIC ===

	'only possible when also serializing "TAudienceAttraction"
	'!!!!!!
	rem
	Method SerializeToString:string()
		'convert FloatToInt
		return iD + "," +..
		       f2i(Children) + "," +..
		       f2i(Teenagers) + "," +..
		       f2i(HouseWives) + "," +..
		       f2i(Employees) + "," +..
		       f2i(Unemployed) + "," +..
		       f2i(Manager) + "," +..
		       f2i(Pensioners) + "," +..
		       f2i(Women) + "," +..
		       f2i(Men)

		Function f2i:String(f:float)
			if float(int(f)) = f then return int(f)
			return f
		End Function
	End Method


	Method DeSerializeFromString(text:String)
		local vars:string[] = text.split(",")
		if vars.length > 0 then iD = int(vars[0])
		if vars.length > 1 then Children = float(vars[1])
		if vars.length > 2 then Teenagers = float(vars[2])
		if vars.length > 3 then HouseWives = float(vars[3])
		if vars.length > 4 then Employees = float(vars[4])
		if vars.length > 5 then Unemployed = float(vars[5])
		if vars.length > 6 then Manager = float(vars[6])
		if vars.length > 7 then Pensioners = float(vars[7])
		if vars.length > 8 then Women = float(vars[8])
		if vars.length > 9 then Men = float(vars[9])
	End Method
	endrem

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
		local result:Float = GetSum()
		if result = 0
			return 0.0
		else
			return result / 7
		endif
	End Method


	Method GetWeightedAverage:Float()
		rem
		local result:Float = 0
		result :+ Children * GetAudienceBreakdown().Children
		result :+ Teenagers * GetAudienceBreakdown().Teenagers
		result :+ HouseWives * GetAudienceBreakdown().HouseWives
		result :+ Employees * GetAudienceBreakdown().Employees
		result :+ Unemployed * GetAudienceBreakdown().Unemployed
		result :+ Manager * GetAudienceBreakdown().Manager
		result :+ Pensioners * GetAudienceBreakdown().Pensioners
		endrem

		'results in nearly the same
		local result:Float = 0
		If (Women = -1 Or Men = -1) Then FixGenderCount()
		result :+ Women * GetAudienceBreakdown().Women
		result :+ Men * GetAudienceBreakdown().Men
		return result
	End Method
	

	Method CalcGenderBreakdown()
'old
'		Women = Children * 0.5 + Teenagers * 0.5 + HouseWives * 0.9 + Employees * 0.4 + Unemployed * 0.4 + Manager * 0.25 + Pensioners * 0.55
'		Men   = Children * 0.5 + Teenagers * 0.5 + HouseWives * 0.1 + Employees * 0.6 + Unemployed * 0.6 + Manager * 0.75 + Pensioners * 0.45

		Women = 0
		Women :+ Children * GetGenderBreakdown().Children
		Women :+ Teenagers * GetGenderBreakdown().Teenagers
		Women :+ HouseWives * GetGenderBreakdown().HouseWives
		Women :+ Employees * GetGenderBreakdown().Employees
		Women :+ Unemployed * GetGenderBreakdown().Unemployed
		Women :+ Manager * GetGenderBreakdown().Manager
		Women :+ Pensioners * GetGenderBreakdown().Pensioners

		Men = 0
		Men :+ Children * (1.0 - GetGenderBreakdown().Children)
		Men :+ Teenagers * (1.0 - GetGenderBreakdown().Teenagers)
		Men :+ HouseWives * (1.0 - GetGenderBreakdown().HouseWives)
		Men :+ Employees * (1.0 - GetGenderBreakdown().Employees)
		Men :+ Unemployed * (1.0 - GetGenderBreakdown().Unemployed)
		Men :+ Manager * (1.0 - GetGenderBreakdown().Manager)
		Men :+ Pensioners * (1.0 - GetGenderBreakdown().Pensioners)
	End Method


	'repairs broken men/women-values of attraction-object
	Method CalcWeightedGenderModifier()
		Women = 0
		'add the portion of each group * audience percentage (so it gets
		'a weighted average)
		Women :+ Children * GetGenderBreakdown().Children * GetAudienceBreakdown().Children
		Women :+ Teenagers * GetGenderBreakdown().Teenagers * GetAudienceBreakdown().Teenagers
		Women :+ HouseWives * GetGenderBreakdown().HouseWives * GetAudienceBreakdown().HouseWives
		Women :+ Employees * GetGenderBreakdown().Employees * GetAudienceBreakdown().Employees
		Women :+ Unemployed * GetGenderBreakdown().Unemployed * GetAudienceBreakdown().Unemployed
		Women :+ Manager * GetGenderBreakdown().Manager * GetAudienceBreakdown().Manager
		Women :+ Pensioners * GetGenderBreakdown().Pensioners * GetAudienceBreakdown().Pensioners

		Men = 0
		'add the portion of each group * audience percentage (so it gets
		'a weighted average)
		Men :+ Children * (1.0 - GetGenderBreakdown().Children) * GetAudienceBreakdown().Children
		Men :+ Teenagers * (1.0 - GetGenderBreakdown().Teenagers) * GetAudienceBreakdown().Teenagers
		Men :+ HouseWives * (1.0 - GetGenderBreakdown().HouseWives) * GetAudienceBreakdown().HouseWives
		Men :+ Employees * (1.0 - GetGenderBreakdown().Employees) * GetAudienceBreakdown().Employees
		Men :+ Unemployed * (1.0 - GetGenderBreakdown().Unemployed) * GetAudienceBreakdown().Unemployed
		Men :+ Manager * (1.0 - GetGenderBreakdown().Manager) * GetAudienceBreakdown().Manager
		Men :+ Pensioners * (1.0 - GetGenderBreakdown().Pensioners) * GetAudienceBreakdown().Pensioners
	End Method

	

	Method FixGenderCount()
		'fix gender count if needed
		if Women < 0 or Men < 0 then CalcGenderBreakdown()

		Local GenderSum:Float = Women + Men
		Local AudienceSum:Int = GetSum()

		'skip division (potential div by zero) without women or men
		'gendersum = 0 allows "-1 and 1" or "0 and 0"
		if GenderSum = 0 or women = 0 or men = 0 then return

		Women = int(Min(AudienceSum, Ceil(AudienceSum / GenderSum * Women)))
		'Men = Ceil(AudienceSum / GenderSum * Men)
		'add remainder (because of rounding) to men
		'Men :+ AudienceSum - Women - Men
		'shorter :-)
		Men = AudienceSum - Women
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
				'check if we got a combination of multiple
				Return GetGroupValue(targetID)
		End Select
	End Method


	'returns the sum value of a group of targetIDS
	Method GetGroupValue:Float(targetIDs:int)
		'loop through all targetGroup-entries and add them if contained
		local result:Float
		local oneFound:int = false
		'do NOT start with 0 ("all")
		For local i:int = 1 to TVTTargetGroup.count
			if targetIDs & TVTTargetGroup.GetAtIndex(i)
				result :+ GetValue(i)
				oneFound = True
			endif
		Next

		if not oneFound
			'print "unknown targetID"
			Throw TArgumentException.Create("targetID", String.FromInt(targetIDs))
		endif
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
			'check for div/0 first 
			if audience.Children = 0 then throw "TAudience.Divide: Div/0 - audience.Children is 0"
			if audience.Teenagers = 0 then throw "TAudience.Divide: Div/0 - audience.Teenagers is 0"
			if audience.HouseWives = 0 then throw "TAudience.Divide: Div/0 - audience.HouseWives is 0"
			if audience.Employees = 0 then throw "TAudience.Divide: Div/0 - audience.Employees is 0"
			if audience.Unemployed = 0 then throw "TAudience.Divide: Div/0 - audience.Unemployed is 0"
			if audience.Manager = 0 then throw "TAudience.Divide: Div/0 - audience.Manager is 0"
			if audience.Pensioners = 0 then throw "TAudience.Divide: Div/0 - audience.Pensioners is 0"
			if audience.Women = 0 then throw "TAudience.Divide: Div/0 - audience.Women is 0"
			if audience.Men = 0 then throw "TAudience.Divide: Div/0 - audience.Men is 0"

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
		if number = 0 then Throw "TAudience.DivideFloat(): Division by zero."

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
		FixGenderCount()
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
		Return "C:" + MathHelper.NumberToString(Children,dec) + " / T:" + MathHelper.NumberToString(Teenagers,dec) + " / H:" + MathHelper.NumberToString(HouseWives,dec) + " / E:" + MathHelper.NumberToString(Employees,dec) + " / U:" + MathHelper.NumberToString(Unemployed,dec) + " / M:" + MathHelper.NumberToString(Manager,dec) + " /P:" + MathHelper.NumberToString(Pensioners,dec)
	End Method

	Method ToString:String()
		Local dec:Int = 4
		Return "Sum: " + Int(Ceil(GetSum())) + "  ( 0: " + MathHelper.NumberToString(Children,dec) + "  - 1: " + MathHelper.NumberToString(Teenagers,dec) + "  - 2: " + MathHelper.NumberToString(HouseWives,dec) + "  - 3: " + MathHelper.NumberToString(Employees,dec) + "  - 4: " + MathHelper.NumberToString(Unemployed,dec) + "  - 5: " + MathHelper.NumberToString(Manager,dec) + "  - 6: " + MathHelper.NumberToString(Pensioners,dec) + ") - [[ W: " + MathHelper.NumberToString(Women,dec) + "  - M: " + MathHelper.NumberToString(Men ,dec) + " ]]"
	End Method


	Method ToStringAverage:String()
		Return "Avg: " + MathHelper.NumberToString(GetAverage(),3) + "  ( 0: " + MathHelper.NumberToString(Children,3) + "  - 1: " + MathHelper.NumberToString(Teenagers,3) + "  - 2: " + MathHelper.NumberToString(HouseWives,3) + "  - 3: " + MathHelper.NumberToString(Employees,3) + "  - 4: " + MathHelper.NumberToString(Unemployed,3) + "  - 5: " + MathHelper.NumberToString(Manager,3) + "  - 6: " + MathHelper.NumberToString(Pensioners,3) + ")"
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