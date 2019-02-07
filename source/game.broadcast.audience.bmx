SuperStrict
Import "Dig/base.util.numbersortmap.bmx"
Import "Dig/base.util.helper.bmx" 'for roundInt()
Import "game.exceptions.bmx"
Import "game.gameconstants.bmx"


Type TAudienceManager
	Field currentAudienceBreakdown:TAudienceBase = null
	Field currentGenderBreakdown:TAudienceBase = null
	Field targetAudienceBreakdown:TAudienceBase = null
	Field targetGenderBreakdown:TAudienceBase = null
	Field defaultAudienceBreakdown:TAudienceBase = null
	Field defaultGenderBreakdown:TAudienceBase = null

	Method Initialize:int()
		currentAudienceBreakdown = null
		currentGenderBreakdown = null
		targetAudienceBreakdown = null
		targetGenderBreakdown = null
		defaultAudienceBreakdown = null
		defaultGenderBreakdown = null
	End Method


	Method GetAudienceBreakdown:TAudienceBase()
		if not defaultAudienceBreakdown
			defaultAudienceBreakDown = New TAudienceBase
			defaultAudienceBreakDown.Children   = 0.09  'Kinder (9%)
			defaultAudienceBreakDown.Teenagers	 = 0.1   'Teenager (10%)
			'adults 60%
			defaultAudienceBreakDown.HouseWives = 0.12  'Hausfrauen (20% von 60% Erwachsenen = 12%)
			defaultAudienceBreakDown.Employees  = 0.405 'Arbeitnehmer (67,5% von 60% Erwachsenen = 40,5%)
			defaultAudienceBreakDown.Unemployed = 0.045 'Arbeitslose (7,5% von 60% Erwachsenen = 4,5%)
			defaultAudienceBreakDown.Manager    = 0.03  'Manager (5% von 60% Erwachsenen = 3%)
			defaultAudienceBreakDown.Pensioners = 0.21  'Rentner (21%)
		endif
		'set current to default (reference!) if nothing set for now
		if not currentAudienceBreakdown then currentAudienceBreakdown = defaultAudienceBreakDown

		return currentAudienceBreakdown
	End Method

rem
	Method ModifyAudienceBreakdown:TAudienceBase(AudienceModifier:TAudienceBase, relativeChange:int = True)
		if relativeChange
			currentAudienceBreakdown = GetAudienceBreakdown().Copy().ModifySumRelative(AudienceModifier)
		else
			currentAudienceBreakdown = GetAudienceBreakdown().Copy().ModifySumAbsolute(AudienceModifier)
		endif
	End Method
endrem

	'returns the female percentage by default
	Method GetGenderBreakdown:TAudienceBase(gender:int=-1)
		if not defaultGenderBreakdown
			'based partially on data from:
			'http://www.bpb.de/wissen/X39RH6,0,0,Bev%F6lkerung_nach_Altersgruppen_und_Geschlecht.html
			'(of 2010)
			'and
			'http://statistik.arbeitsagentur.de/Statischer-Content/Statistische-Analysen/Analytikreports/Zentrale-Analytikreports/Monatliche-Analytikreports/Generische-Publikationen/Analyse-Arbeitsmarkt-Frauen-Maenner/Analyse-Arbeitsmarkt-Frauen-Maenner-201506.pdf
			'(of 2015)

			'value describes percentage of women in that group
			defaultGenderBreakdown = New TAudienceBase
			defaultGenderBreakdown.Children = 0.487
			defaultGenderBreakdown.Teenagers = 0.487
			defaultGenderBreakdown.HouseWives = 0.9
			defaultGenderBreakdown.Employees = 0.4
			defaultGenderBreakdown.Unemployed = 0.45
			defaultGenderBreakdown.Manager = 0.20
			defaultGenderBreakdown.Pensioners = 0.58 'the older the more women
		endif
		'set current to default (reference!) if nothing set for now
		if not currentGenderBreakdown then currentGenderBreakdown = defaultGenderBreakdown

		if gender <> TVTPersonGender.MALE
			return currentGenderBreakdown
		else
			return new TAudienceBase.InitValue(1).Subtract( currentGenderBreakdown )
		endif
	End Method


	Method GetGenderPercentage:Float(gender:int)
		return GetGenderBreakdown(gender).GetWeightedAverage( GetAudienceBreakdown() )
	End Method


	Method GetGenderGroupPercentage:Float(gender:int, groups:int)
		local portion:float = 0
		local gBreakdown:TAudienceBase = GetGenderBreakdown(gender)
		local aBreakdown:TAudienceBase = GetAudienceBreakdown()
		For local i:int = 1 to TVTTargetGroup.baseGroupCount
			local targetGroupID:int = TVTTargetGroup.GetAtIndex(i)
			if groups & targetGroupID
				portion :+ gBreakdown.GetValue(targetGroupID) * aBreakdown.GetValue(targetGroupID)
			endif
		Next
		return portion
	End Method


	'returns the percentage/count of all persons in the group
	'a "MEN + TEENAGER + EMPLOYEES"-group just returns the amount
	'of all male teenager and male employees
	'---
	'In contrast to "GetGenderGroupPercentage" this allows to have
	'TVTTargetGroup.MEN / WOMEN recognized as gender
	Method GetTargetGroupPercentage:Float(targetGroups:int)
		'add target groups ignoring the gender
		if targetGroups & TVTTargetGroup.MEN
			'just men
			if targetGroups = TVTTargetGroup.MEN
				return GetGenderPercentage(TVTPersonGender.MALE)
			'male part of target groups
			else
				return GetGenderGroupPercentage(TVTPersonGender.MALE, targetGroups)
			endif
		elseif targetGroups & TVTTargetGroup.WOMEN
			'just women
			if targetGroups = TVTTargetGroup.WOMEN
				return GetGenderPercentage(TVTPersonGender.FEMALE)
			'female part of target groups
			else
				return GetGenderGroupPercentage(TVTPersonGender.FEMALE, targetGroups)
			endif
		else
			return GetAudienceBreakdown().GetValue(targetGroups)
		endif

		Throw "unhandled GetTargetGroupAmaount: targetGroups="+targetGroups
		return 0
	End Method
End Type

Global AudienceManager:TAudienceManager = new TAudienceManager




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


	'=== CONSTRUCTORS ===

	Method Init:TAudienceBase(children:Float, teenagers:Float, HouseWives:Float, employees:Float, unemployed:Float, manager:Float, pensioners:Float)
		SetValues(children, teenagers, HouseWives, employees, unemployed, manager, pensioners)
		Return self
	End Method


	Method InitValue:TAudienceBase(defaultValue:Float)
		Init(defaultValue, defaultValue, defaultValue, defaultValue, defaultValue, defaultValue, defaultValue)
		return self
	End Method


	Method InitWithBreakdown:TAudienceBase(audience:Int, breakdown:TAudienceBase)
		SetValuesFrom(breakdown)
		MultiplyFloat(audience)
		return self
	End Method


	'=== SERIALIZATION / DESERIALIZATION ===
	Method SerializeTAudienceBaseToString:string()
		return f2i(Children) + "," +..
		       f2i(Teenagers) + "," +..
		       f2i(HouseWives) + "," +..
		       f2i(Employees) + "," +..
		       f2i(Unemployed) + "," +..
		       f2i(Manager) + "," +..
		       f2i(Pensioners)

		Function f2i:String(f:float)
			if float(int(f)) = f then return int(f)
			return string(f).replace(",",".")
		End Function
	End Method


	Method DeSerializeTAudienceBaseFromString(text:String)
		local vars:string[] = text.split(",")
		if vars.length > 0 then Children = float(vars[0])
		if vars.length > 1 then Teenagers = float(vars[1])
		if vars.length > 2 then HouseWives = float(vars[2])
		if vars.length > 3 then Employees = float(vars[3])
		if vars.length > 4 then Unemployed = float(vars[4])
		if vars.length > 5 then Manager = float(vars[5])
		if vars.length > 6 then Pensioners = float(vars[6])
	End Method




	'=== PUBLIC ===

	Method Copy:TAudienceBase()
		Local result:TAudienceBase = New TAudienceBase
		result.SetValuesFrom(Self)
		return result
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
		local result:Float = GetSum()
		if result = 0
			return 0.0
		else
			return result / 7
		endif
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


	Method CutMinimumFloat:TAudienceBase(value:float)
		CutMinimum(new TAudienceBase.InitValue(value))
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


	Method CutMaximumFloat:TAudienceBase(value:float)
		CutMaximum(new TAudienceBase.InitValue(value))
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


	Method GetValue:Float(targetID:int) {_exposeToLua}
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
	Method GetGroupValue:Float(targetIDs:int) {_exposeToLua}
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

		return result
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
				Throw TArgumentException.Create("targetID", String.FromInt(targetID))
		End Select
	End Method


	Method GetSum:Float() {_exposeToLua}
		'ignore gender in base variant
		Return Children + Teenagers + HouseWives + Employees + Unemployed + Manager + Pensioners
	End Method


	Method GetAbsSum:Float() {_exposeToLua}
		'ignore gender in base variant
		Return abs(Children) + abs(Teenagers) + abs(HouseWives) + abs(Employees) + abs(Unemployed) + abs(Manager) + abs(Pensioners)
	End Method


	Method GetWeightedAverage:Float(audienceBreakdown:TAudienceBase = null) {_exposeToLua}
		'fetch current breakdown if nothing was given
		if not audienceBreakdown then audienceBreakdown = AudienceManager.GetAudienceBreakdown()

		local result:Float = 0
		result :+ Children * audienceBreakdown.Children
		result :+ Teenagers * audienceBreakdown.Teenagers
		result :+ HouseWives * audienceBreakdown.HouseWives
		result :+ Employees * audienceBreakdown.Employees
		result :+ Unemployed * audienceBreakdown.Unemployed
		result :+ Manager * audienceBreakdown.Manager
		result :+ Pensioners * audienceBreakdown.Pensioners

		return result
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


	Method MultiplyFloat:TAudienceBase(factor:Float)
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

		if audience.GetSum() = 0
			'set all values to 0 (new Audience has 0 as default)
			SetValuesFrom(new TAudienceBase)
		Else

			'check for div/0 first
			if audience.Children = 0
				if Abs(children - audience.Children) > 0.01
					throw "TAudienceBase.Divide: Div/0 - audience.Children is 0. Children is " + Children
				else
					Children = 0
				endif
			else
				Children :/ audience.Children
			endif

			if audience.Teenagers = 0
				if Abs(Teenagers - audience.Teenagers) > 0.01
					throw "TAudienceBase.Divide: Div/0 - audience.Teenagers is 0. Teenagers is " + Teenagers
				else
					Teenagers = 0
				endif
			else
				Teenagers :/ audience.Teenagers
			endif

			if audience.HouseWives = 0
				if Abs(HouseWives - audience.HouseWives) > 0.01
					throw "TAudienceBase.Divide: Div/0 - audience.HouseWives is 0. HouseWives is " + HouseWives
				else
					HouseWives = 0
				endif
			else
				HouseWives :/ audience.HouseWives
			endif

			if audience.Employees = 0 and (Abs(Employees - audience.Employees) < 0.01)
				'TODO: this seems pretty useless
				if Abs(Employees - audience.Employees) > 0.01
					throw "TAudienceBase.Divide: Div/0 - audience.Employees is 0. Employees is " + Employees
				else
					Employees = 0
				endif
			else
				Employees :/ audience.Employees
			endif

			if audience.Unemployed = 0 and (Abs(Unemployed - audience.Unemployed) < 0.01)
				'TODO: this seems pretty useless
				if Abs(Unemployed - audience.Unemployed) > 0.01
					throw "TAudienceBase.Divide: Div/0 - audience.Unemployed is 0. Unemployed is " + Unemployed
				else
					Unemployed = 0
				endif
			else
				Unemployed :/ audience.Unemployed
			endif

			if audience.Manager = 0 and (Abs(Manager - audience.Manager) < 0.01)
				'TODO: this seems pretty useless
				if Abs(Manager - audience.Manager) > 0.01
					throw "TAudienceBase.Divide: Div/0 - audience.Manager is 0. Manager is " + Manager
				else
					Manager = 0
				endif
			else
				Manager :/ audience.Manager
			endif

			if audience.Pensioners = 0 and (Abs(Pensioners - audience.Pensioners) < 0.01)
				'TODO: this seems pretty useless
				if Abs(Pensioners - audience.Pensioners) > 0.01
					throw "TAudienceBase.Divide: Div/0 - audience.Pensioners is 0. Pensioners is " + Pensioners
				else
					Pensioners = 0
				endif
			else
				Pensioners :/ audience.Pensioners
			endif
		EndIf
		Return Self
	End Method


	Method DivideFloat:TAudienceBase(number:Float)
		if number = 0 then Throw "TAudienceBase.DivideFloat(): Division by zero."

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
		Local amap:TNumberSortMap = new TNumberSortMap
		amap.Add(TVTTargetGroup.Children, Children)
		amap.Add(TVTTargetGroup.Teenagers, Teenagers)
		amap.Add(TVTTargetGroup.HouseWives, HouseWives)
		amap.Add(TVTTargetGroup.Employees, Employees)
		amap.Add(TVTTargetGroup.Unemployed, Unemployed)
		amap.Add(TVTTargetGroup.Manager, Manager)
		amap.Add(TVTTargetGroup.Pensioners, Pensioners)
		Return amap
	End Method


	Method ToStringPercentage:String(dec:int = 0)
		Return "C:" + MathHelper.NumberToString(Children*100,dec, True) + "% / " + ..
		       "T:" + MathHelper.NumberToString(Teenagers*100,dec, True) + "% / " + ..
		       "H:" + MathHelper.NumberToString(HouseWives*100,dec, True) + "% / " + ..
		       "E:" + MathHelper.NumberToString(Employees*100,dec, True) + "% / " + ..
		       "U:" + MathHelper.NumberToString(Unemployed*100,dec, True) + "% / " + ..
		       "M:" + MathHelper.NumberToString(Manager*100,dec, True) + "% / " + ..
		       "P:" + MathHelper.NumberToString(Pensioners*100,dec, True) +"%"
	End Method


	Method ToStringMinimal:String(dec:int = 0)
		Return "C:" + MathHelper.NumberToString(Children,dec, True) + " / " + ..
		       "T:" + MathHelper.NumberToString(Teenagers,dec, True) + " / " + ..
		       "H:" + MathHelper.NumberToString(HouseWives,dec, True) + " / " + ..
		       "E:" + MathHelper.NumberToString(Employees,dec, True) + " / " + ..
		       "U:" + MathHelper.NumberToString(Unemployed,dec, True) + " / " + ..
		       "M:" + MathHelper.NumberToString(Manager,dec, True) + " / " + ..
		       "P:" + MathHelper.NumberToString(Pensioners,dec, True)
	End Method


	Method ToString:String()
		Local dec:Int = 4
		Return "Sum = " + MathHelper.NumberToString(GetSum(), dec, True) + "  ( " + ToStringMinimal(0) +" )"
		'Return "Sum =" + Int(Ceil(GetSum())) + "  ( 0=" + MathHelper.NumberToString(Children,dec, True) + "  1=" + MathHelper.NumberToString(Teenagers,dec, True) + "  2=" + MathHelper.NumberToString(HouseWives,dec, True) + "  3=" + MathHelper.NumberToString(Employees,dec, True) + "  4=" + MathHelper.NumberToString(Unemployed,dec, True) + "  5=" + MathHelper.NumberToString(Manager,dec, True) + "  6=" + MathHelper.NumberToString(Pensioners,dec, True) + " )"
	End Method


	Method ToStringAverage:String(dec:int = 4)
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
	Method Init:TAudience(gender:int, children:Float, teenagers:Float, HouseWives:Float, employees:Float, unemployed:Float, manager:Float, pensioners:Float)
		if gender = -1 or gender = TVTPersonGender.FEMALE
			GetAudienceFemale().Init(children, teenagers, HouseWives, employees, unemployed, manager, pensioners)
		endif
		if gender = -1 or gender = TVTPersonGender.MALE
			GetAudienceMale().Init(children, teenagers, HouseWives, employees, unemployed, manager, pensioners)
		endif

		return self
	End Method


	Method InitBase:TAudience(male:TAudienceBase, female:TAudienceBase)
		if not male then male = new TAudienceBase.InitValue(0)
		if not female then female = new TAudienceBase.InitValue(0)

		if not audienceMale then audienceMale = new TAudienceBase
		if not audienceFemale then audienceFemale = new TAudienceBase

		audienceMale.SetValuesFrom(male)
		audienceFemale.SetValuesFrom(female)

		return self
	End Method


	Method InitValue:TAudience(valueMale:Float, valueFemale:Float) {_exposeToLua}
		Init(TVTPersonGender.Male, valueMale, valueMale, valueMale, valueMale, valueMale, valueMale, valueMale)
		Init(TVTPersonGender.Female, valueFemale, valueFemale, valueFemale, valueFemale, valueFemale, valueFemale, valueFemale)
		return self
	End Method


	Method InitWithBreakdown:TAudience(audience:Int) {_exposeToLua}
		local breakdown:TAudienceBase = new TAudienceBase.InitValue(1)
		breakdown.Multiply( AudienceManager.GetAudienceBreakdown() )

		GetAudienceFemale().InitWithBreakdown(audience, breakdown)
		GetAudienceFemale().Multiply( AudienceManager.GetGenderBreakdown( TVTPersonGender.FEMALE ) )

		GetAudienceMale().InitWithBreakdown(audience, breakdown)
		GetAudienceMale().Multiply( AudienceManager.GetGenderBreakdown( TVTPersonGender.MALE ) )

		return self
	End Method


	Method CopyFrom:TAudience(other:TAudience)
		self.InitBase(other.audienceMale, other.audienceFemale)
		return self
	End Method


	'=== SERIALIZATION / DESERIALIZATION ===

	Method SerializeTAudienceToString:string()
		local m:string = ""
		local w:string = ""
		if audienceMale then m = audienceMale.SerializeTAudienceBaseToString()
		if audienceFemale then w = audienceFemale.SerializeTAudienceBaseToString()
		'convert FloatToInt
		return id + "::ab=" +..
		       m  + "::ab=" +..
		       w
	End Method


	Method DeSerializeTAudienceFromString(text:String)
		local parts:string[] = text.split("::ab=")
		id = int(parts[0])
		if parts.length > 1
			GetAudienceMale().InitValue(0)
			audienceMale.DeSerializeTAudienceBaseFromString(parts[1])
		endif
		if parts.length > 2
			if not audienceFemale then audienceFemale = new TAudienceBase
			GetAudienceFemale().InitValue(0)
			audienceFemale.DeSerializeTAudienceBaseFromString(parts[2])
		endif
	End Method




	'=== PUBLIC ===
	Method GetAudienceFemale:TAudienceBase() {_exposeToLua}
		if not audienceFemale then audienceFemale = new TAudienceBase
		return audienceFemale
	End Method


	Method GetAudienceMale:TAudienceBase() {_exposeToLua}
		if not audienceMale then audienceMale = new TAudienceBase
		return audienceMale
	End Method


	Method Copy:TAudience() {_exposeToLua}
		Local result:TAudience = New TAudience
		result.Id = Id
		result.SetValuesFrom(Self)
		return result
	End Method


	Method SetValuesFrom:TAudience(value:TAudience)
		SetValues(value.audienceMale, value.audienceFemale)
		Return Self
	End Method


	Method SetValues:TAudience(audienceMale:TAudienceBase, audienceFemale:TAudienceBase)
		if audienceMale then self.audienceMale = audienceMale.Copy()
		if audienceFemale then self.audienceFemale = audienceFemale.Copy()
		return self
	End Method


	Method GetTotalValue:Float(targetID:int) {_exposeToLua}
		if targetID <= 0 then return GetTotalSum()

		if targetID = TVTTargetGroup.Women
			return GetGenderValue(targetID, TVTPersonGender.FEMALE)
		elseif targetID = TVTTargetGroup.Men
			return GetGenderValue(targetID, TVTPersonGender.MALE)
		else
			local res:Float = 0
			if audienceMale then res :+ audienceMale.GetValue(targetID)
			if audienceFemale then res :+ audienceFemale.GetValue(targetID)
			return res
		endif
	End Method


	Method GetGenderValue:Float(targetID:int, gender:int) {_exposeToLua}
		if targetID = TVTTargetGroup.Women
			if not audienceFemale or gender = TVTPersonGender.MALE then return 0
			return audienceFemale.GetSum()
		elseif targetID = TVTTargetGroup.Men
			if not audienceMale or gender = TVTPersonGender.FEMALE  then return 0
			return audienceMale.GetSum()
		endif

		if gender = TVTPersonGender.MALE
			if not audienceMale then return 0
			return audienceMale.GetValue(targetID)
		elseif gender = TVTPersonGender.FEMALE
			if not audienceFemale then return 0
			return audienceFemale.GetValue(targetID)
		endif
		return 0
	End Method


	'contrary to "SetGenderValue()" this SPLITS the value into female/male
	Method SetTotalValue(targetID:int, newValue:Float, femalePercentage:float = 0.5)
		SetGenderValue(targetID, newValue * femalePercentage, TVTPersonGender.FEMALE)
		SetGenderValue(targetID, newValue * (1.0 - femalePercentage), TVTPersonGender.MALE)
	End Method


	Method SetGenderValue(targetID:Int, newValue:Float, gender:int)
		Select targetID
			Case TVTTargetGroup.Women
				if gender = TVTPersonGender.MALE then return
			Case TVTTargetGroup.Men
				if gender = TVTPersonGender.FEMALE then return
			Default
				if gender = TVTPersonGender.MALE
					GetAudienceMale().SetValue(targetID, newValue)
				elseif gender = TVTPersonGender.FEMALE
					GetAudienceFemale().SetValue(targetID, newValue)
				else
					GetAudienceMale().SetValue(targetID, newValue)
					GetAudienceFemale().SetValue(targetID, newValue)
				endif
		End Select
	End Method


	Method GetTotalSum:Float() {_exposeToLua}
		local res:float = 0
		if audienceFemale then res :+ audienceFemale.GetSum()
		if audienceMale then res :+ audienceMale.GetSum()
		Return res
	End Method


	Method GetTotalAbsSum:Float() {_exposeToLua}
		local res:float = 0
		if audienceFemale then res :+ audienceFemale.GetAbsSum()
		if audienceMale then res :+ audienceMale.GetAbsSum()
		Return res
	End Method


	Method GetGenderSum:Float(gender:int) {_exposeToLua}
		if gender = TVTPersonGender.MALE
			if audienceMale then return audienceMale.GetSum()
		elseif gender = TVTPersonGender.FEMALE
			if audienceFemale then return audienceFemale.GetSum()
		endif
		return 0
	End Method


	Method GetTotalAverage:Float() {_exposeToLua}
		return 0.5 * (GetAudienceMale().GetAverage() + GetAudienceFemale().GetAverage())
	End Method


	Method GetGenderAverage:Float(gender:int) {_exposeToLua}
		if gender = TVTPersonGender.MALE
			return GetAudienceMale().GetAverage()
		elseif gender = TVTPersonGender.FEMALE
			return GetAudienceFemale().GetAverage()
		endif
		return 0
	End Method


	Method GetWeightedAverage:Float(audienceBreakdown:TAudienceBase = null) {_exposeToLua}
		'fetch current breakdown if nothing was given
		if not audienceBreakdown then audienceBreakdown = AudienceManager.GetAudienceBreakdown()

		local result:Float = 0
		if audienceMale
			result :+ audienceMale.Children * audienceBreakdown.Children
			result :+ audienceMale.Teenagers * audienceBreakdown.Teenagers
			result :+ audienceMale.HouseWives * audienceBreakdown.HouseWives
			result :+ audienceMale.Employees * audienceBreakdown.Employees
			result :+ audienceMale.Unemployed * audienceBreakdown.Unemployed
			result :+ audienceMale.Manager * audienceBreakdown.Manager
			result :+ audienceMale.Pensioners * audienceBreakdown.Pensioners
		endif
		if audienceFemale
			result :+ audienceFemale.Children * audienceBreakdown.Children
			result :+ audienceFemale.Teenagers * audienceBreakdown.Teenagers
			result :+ audienceFemale.HouseWives * audienceBreakdown.HouseWives
			result :+ audienceFemale.Employees * audienceBreakdown.Employees
			result :+ audienceFemale.Unemployed * audienceBreakdown.Unemployed
			result :+ audienceFemale.Manager * audienceBreakdown.Manager
			result :+ audienceFemale.Pensioners * audienceBreakdown.Pensioners
		endif

		return result
	End Method


	Method Add:TAudience(audience:TAudience)
		'skip adding if the param is "unset"
		If Not audience Then Return Self

		GetAudienceMale().Add(audience.audienceMale)
		GetAudienceFemale().Add(audience.audienceFemale)
		return self
	End Method


	Method AddFloat:TAudience(number:Float)
		GetAudienceMale().AddFloat(number)
		GetAudienceFemale().AddFloat(number)
		return self
	End Method


	Method AddGenderFloat:TAudience(number:Float, gender:int)
		if gender = TVTPersonGender.MALE
			GetAudienceFemale().AddFloat(number)
		else
			GetAudienceMale().AddFloat(number)
		endif
		return self
	End Method


	Method ModifyTotalValue(targetID:Int, addValue:Float)
		ModifyGenderValue(targetID, addValue, TVTPersonGender.MALE)
		ModifyGenderValue(targetID, addValue, TVTPersonGender.FEMALE)
	End Method


	Method ModifyGenderValue(targetID:Int, addValue:Float, gender:int)
		local targetIndexes:int[] = TVTTargetGroup.GetIndexes(targetID)

		for local targetIndex:int = EachIn targetIndexes
			targetID = TVTTargetGroup.GetAtIndex(targetIndex)

			Select targetID
				Case TVTTargetGroup.Women
					if gender = TVTPersonGender.MALE then return
					For local i:int = 1 to TVTTargetGroup.baseGroupCount
						ModifyGenderValue( TVTTargetGroup.GetAtIndex(i), addValue, TVTPersonGender.FEMALE )
					Next
				Case TVTTargetGroup.Men
					if gender = TVTPersonGender.FEMALE then return
					For local i:int = 1 to TVTTargetGroup.baseGroupCount
						ModifyGenderValue( TVTTargetGroup.GetAtIndex(i), addValue, TVTPersonGender.MALE  )
					Next

				Default
					if gender = TVTPersonGender.MALE
						GetAudienceMale().SetValue(targetID, GetAudienceMale().GetValue(targetID) + addValue)
					elseif gender = TVTPersonGender.FEMALE
						GetAudienceFemale().SetValue(targetID, GetAudienceFemale().GetValue(targetID) + addValue)
					endif
			End Select
		Next
	End Method


	Method Subtract:TAudience(audience:TAudience)
		'skip subtracting if the param is "unset"
		If Not audience Then Return Self

		GetAudienceMale().Subtract(audience.audienceMale)
		GetAudienceFemale().Subtract(audience.audienceFemale)
		return self
	End Method


	Method SubtractFloat:TAudience(number:Float)
		GetAudienceMale().SubtractFloat(number)
		GetAudienceFemale().SubtractFloat(number)
		return self
	End Method


	Method Multiply:TAudience(audience:TAudience)
		'skip if the param is "unset"
		If Not audience Then Return Self

		GetAudienceMale().Multiply(audience.audienceMale)
		GetAudienceFemale().Multiply(audience.audienceFemale)
		return self
	End Method


	Method MultiplyFloat:TAudience(factor:Float) {_exposeToLua}
		GetAudienceMale().MultiplyFloat(factor)
		GetAudienceFemale().MultiplyFloat(factor)
		return self
	End Method


	Method Divide:TAudience(audience:TAudience)
		If Not audience Then Return Self

		GetAudienceMale().divide(audience.GetAudienceMale())
		GetAudienceFemale().divide(audience.GetAudienceFemale())
		return self
	End Method


	Method DivideFloat:TAudience(number:Float)
		GetAudienceMale().divideFloat(number)
		GetAudienceFemale().divideFloat(number)
		return self
	End Method


	Method Round:TAudience()
		if audienceMale then audienceMale.Round()
		if audienceFemale then audienceFemale.Round()
		return self
	End Method


	Method CutBordersFloat:TAudience(minimum:Float, maximum:Float)
		if audienceMale then audienceMale.CutBordersFloat(minimum, maximum)
		if audienceFemale then audienceFemale.CutBordersFloat(minimum, maximum)
		Return Self
	End Method


	Method CutBorders:TAudience(minimum:TAudience, maximum:TAudience)
		if not minimum or not maximum then return self

		if audienceMale then audienceMale.CutBorders(minimum.audienceMale, maximum.audienceMale)
		if audienceFemale then audienceFemale.CutBorders(minimum.audienceFemale, maximum.audienceFemale)
		Return Self
	End Method


	Method CutMinimumFloat:TAudience(value:float)
		CutMinimum( new TAudience.InitValue(value, value) )
		Return Self
	End Method


	Method CutMinimum:TAudience(minimum:TAudience)
		if not minimum then return self

		if audienceMale then audienceMale.CutMinimum(minimum.audienceMale)
		if audienceFemale then audienceFemale.CutMinimum(minimum.audienceFemale)
		Return Self
	End Method


	Method CutMaximumFloat:TAudience(value:float)
		CutMaximum( new TAudience.InitValue(value, value) )
		Return Self
	End Method


	Method CutMaximum:TAudience(maximum:TAudience)
		if not maximum then return self

		if audienceMale then audienceMale.CutMaximum(maximum.audienceMale)
		if audienceFemale then audienceFemale.CutMaximum(maximum.audienceFemale)
		Return Self
	End Method


	Method ToNumberSortMap:TNumberSortMap()
		Local amap:TNumberSortMap = new TNumberSortMap
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

	Method ToStringPercentage:String(dec:int = 0)
		Return "C:" + MathHelper.NumberToString(GetAudienceMale().Children*100, dec, True) + "/" + MathHelper.NumberToString(GetAudienceFemale().Children*100, dec, True) + "% / " + ..
		       "T:" + MathHelper.NumberToString(GetAudienceMale().Teenagers*100, dec, True) + "/" + MathHelper.NumberToString(GetAudienceFemale().Teenagers*100, dec, True) + "% / " + ..
		       "H:" + MathHelper.NumberToString(GetAudienceMale().HouseWives*100, dec, True) + "/" + MathHelper.NumberToString(GetAudienceFemale().HouseWives*100, dec, True) + "% / " + ..
		       "E:" + MathHelper.NumberToString(GetAudienceMale().Employees*100, dec, True) + "/" + MathHelper.NumberToString(GetAudienceFemale().Employees*100, dec, True) + "% / " + ..
		       "U:" + MathHelper.NumberToString(GetAudienceMale().Unemployed*100, dec, True) + "/" + MathHelper.NumberToString(GetAudienceFemale().Unemployed*100, dec, True) + "% / " + ..
		       "M:" + MathHelper.NumberToString(GetAudienceMale().Manager*100, dec, True) + "/" + MathHelper.NumberToString(GetAudienceFemale().Manager*100, dec, True) + "% / " + ..
		       "P:" + MathHelper.NumberToString(GetAudienceMale().Pensioners*100, dec, True) + "/" + MathHelper.NumberToString(GetAudienceFemale().Pensioners*100, dec, True) +"%"
	End Method


	Method ToStringMinimal:String(dec:int=0)
		Return "C:" + MathHelper.NumberToString(GetAudienceMale().Children, dec, True) + "/" + MathHelper.NumberToString(GetAudienceFemale().Children, dec, True) + " / " + ..
		       "T:" + MathHelper.NumberToString(GetAudienceMale().Teenagers, dec, True) + "/" + MathHelper.NumberToString(GetAudienceFemale().Teenagers, dec, True) + " / " + ..
		       "H:" + MathHelper.NumberToString(GetAudienceMale().HouseWives, dec, True) + "/" + MathHelper.NumberToString(GetAudienceFemale().HouseWives, dec, True) + " / " + ..
		       "E:" + MathHelper.NumberToString(GetAudienceMale().Employees, dec, True) + "/" + MathHelper.NumberToString(GetAudienceFemale().Employees, dec, True) + " / " + ..
		       "U:" + MathHelper.NumberToString(GetAudienceMale().Unemployed, dec, True) + "/" + MathHelper.NumberToString(GetAudienceFemale().Unemployed, dec, True) + " / " + ..
		       "M:" + MathHelper.NumberToString(GetAudienceMale().Manager, dec, True) + "/" + MathHelper.NumberToString(GetAudienceFemale().Manager, dec, True) + " / " + ..
		       "P:" + MathHelper.NumberToString(GetAudienceMale().Pensioners, dec, True) + "/" + MathHelper.NumberToString(GetAudienceFemale().Pensioners, dec, True)
	End Method


	Method ToString:String()
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