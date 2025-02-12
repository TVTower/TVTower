SuperStrict
Framework Brl.StandardIO
Import Brl.Map
Import brl.retro	' Hex() in SToken.reveal()
Import Brl.StringBuilder
Import "base.util.longmap.bmx"
Import "base.util.string.bmx"

Import "base.util.scriptexpression_ng.c"
Extern "C"
    Function SubStringHash:ULong(s:String, start:Int, length:Int)="BBULONG bbSubStringHash( BBSTRING, BBINT, BBINT)"
    Function SubAsciiStringHashLC:ULong(s:String, start:Int, length:Int)="BBULONG bbSubAsciiStringHashLC( BBSTRING, BBINT, BBINT)"
End Extern


Global ScriptExpression:TScriptExpression = New TScriptExpression
Function GetScriptExpressionFunctionHandler:TSEFN_Handler( functionName:String ) inline
	Return ScriptExpression.GetFunctionHandler( functionName )
End Function

Function GetScriptExpressionFunctionHandler:TSEFN_Handler( functionNameLowerHash:ULong ) inline
	Return ScriptExpression.GetFunctionHandler( functionNameLowerHash )
End Function

Function GetScriptExpressionFunctionHandler:TSEFN_Handler( functionNameLowerHash:Long ) inline
	Return ScriptExpression.GetFunctionHandler( functionNameLowerHash )
End Function



' VERSION 7.1, 1 JUN 2024

Rem VERSION 7.1 / Scaremonger (Si)
* Added Constants for SYM_LSS, SYM_EQUAL, SYM_GTR and TK_OPERATOR
* Updated TokenName() to return "Operator" for TK_OPERATOR
* Updated SScriptExpressionLexer.getNext() to detect "<", "=", ">", "==", "<=", "<>", ">=" tokens
* Split SScriptExpressionParser.readWrapper() into readStatement(), readBlock() and readFunction()
* Updated SScriptExpressionParser.readBlock() to add TK_OPERATOR
* Added STokenGroup.New()
* Added STokenGroup.GetTokenGroup()
* Added STokenGroup.reveal() for debugging
* Created function SEFN_NEq()
* Created function SEFN_Hour()
* Registered function SEFN_Eq() as "=="
* Registered function SEFN_Gt() as ">"
* Registered function SEFN_Gte() as ">="
* Registered function SEFN_Lt() as "<"
* Registered function SEFN_Lte() as "<="
* Registered function SEFN_NEq() as "<>"
* Registered function SEFN_Hour() as "hour"

NOTE ON PARSING:

	root       <- "$" wrapper
	wrapper    <- "{" expression "}"
	expression <- (block ":")* block
	block      <- (expression|function|identifier|qstring|number|boolean|variable) (operator block)?
	operator   <- ("<"|">" "=")|"<>"|"=="
	function   <- "." identifier
	identifier <- [a-zA-Z]*
	qstring    <- '"' (!'"')* '"'
	number     <- "-"? [0-9]* ("." [0-9]*)
	boolean    <- true|false
	variable   <- [0-9]*
	

EndRem

Rem VERSION 6 CHANGES / Scaremonger (Si)
* Moved try-catch from parse() and parsetext() up into expect()
* Modified GetToken() to parse SYM_PERIOD followed by an identifier as a TK_FUNCTION, freeing up identifers to be variables.
* Modified readWrapper() to process TK_FUNCTION instead of SYM_PERIOD
* Modifier readWrapper() to process TK_IDENTIFIER seperate from TK_QSTRING, TK_NUMBER and TK_BOOLEAN
* Added TScriptExpressionConfig argument to SScriptExpressionParser.new() so it can access field "config"
* Fixed bug in getNext() where 4 character identifiers were mis-read.
* Fixed bug with escaped quotes in ExtractQuotedString()
End Rem

Rem
${.functionName:param1:${.otherFunctionName:param1:param2}}

${.roleName:&quot;die-guid-von-interesse&quot;}
${.roleLastName:&quot;die-guid-von-interesse&quot;}

${.roleLastName:${.castGUID:1}}
-> castGUID:1 -> cast 1 abrufen und dessen GUID ist das Ergebnis
-> roleLastName:ErgebnisGUID -> role "ErgebnisGUID" abrufen und dessen LastName ist das Ergebnis

${.gt:${.worldtimeYear}:2022:&quot;nach 2022&quot;:&quot;2022 oder eher&quot;}
End Rem

	
Const SYM_SPACE:Int 		= 32	' space
Const SYM_DQUOTE:Int 		= 34	' "
Const SYM_DOLLAR:Int		= 36	' $
Const SYM_LPAREN:Int		= 40	' (
Const SYM_RPAREN:Int		= 41	' )
Const SYM_HYPHEN:Int 		= 45	' -
Const SYM_PERIOD:Int 		= 46	' .
Const SYM_COLON:Int 		= 58	' :
Const SYM_LSS:Int 			= 60	' <
Const SYM_EQUAL:Int 		= 61	' =
Const SYM_GTR:Int 			= 62	' >
Const SYM_BACKSLASH:Int 	= 92	' \
Const SYM_UNDERSCORE:Int	= 95	' _
Const SYM_LBRACE:Int		= 123	' {
Const SYM_RBRACE:Int		= 125	' }

Const TK_ERROR:Int			= -1	' Invalid token / Error condition
Const TK_EOF:Int 			= 0		' End of File
Const TK_IDENTIFIER:Int		= 1		' Identifier (STRING)
Const TK_NUMBER:Int 		= 2		' Number
Const TK_QSTRING:Int 		= 3		' Quoted String
Const TK_FUNCTION:Int 		= 4		' Function (hash)
Const TK_BOOLEAN:Int 		= 5		' Boolean identifiers (true/false)
Const TK_TEXT:Int 			= 6		' Text String
Const TK_OPERATOR:Int 		= 7		' Operator "<","=",">","<=", ">=","<>"

Const TK_TAB:Int 			= 9		' /t
Const TK_LF:Int 			= 10	' /n
Const TK_CR:Int 			= 13	' /r

Function TokenName:String( id:Int )
	If id<32
		Select id
			Case TK_ERROR;	Return "Error"
			Case TK_EOF;		Return "EOF"
			Case TK_IDENTIFIER;	Return "Identifier"
			Case TK_NUMBER;		Return "Number"
			Case TK_TEXT;		Return "Text"
			Case TK_QSTRING;	Return "String"
			Case TK_FUNCTION;	Return "Function"
			Case TK_BOOLEAN;	Return "Bool"
			Case TK_TAB;		Return "TAB"
			Case TK_LF;			Return "LF"
			Case TK_CR;			Return "CR"
			Case TK_OPERATOR;   Return "Operator"
		Default
			Return "n/a ("+id+")"
		End Select
	Else
		Return "CHR='"+Chr(id)+"'"
	End If
End Function

Struct STokenGroup
	Field StaticArray token:SToken[10]
	Field dynamicToken:SToken[]
	Field added:Int
	
	' Creates a Token group seeded with it's first member
	Method New( token:SToken )
		addToken( token )
	End Method

	' Was a token added at the given index? 
	Method HasToken:Int(index:Int)
		Return (index >= 0 and index < added)
	End Method
	
	' Was a specific type of token added at the given index?
	Method HasToken:Int(index:Int, valueType:ETokenValueType)
		If index >= 0 and index < added
			If index < token.Length
				Return token[index].valueType = valueType
			ElseIf index < dynamicToken.Length + token.Length
				Return dynamicToken[index - token.Length].valueType = valueType
			EndIf
		Else
			Return False
		EndIf
	End Method 
	
	' Return the token at the given index
	' (attention: invalid indices lead to "default" tokens (as they are structs)
	Method GetToken:SToken(index:Int)
		'TODO shouldn't added be checked
		If index < token.Length
			Return token[index]
		ElseIf index < dynamicToken.Length + token.Length
			Return dynamicToken[index - token.Length]
		EndIf
	End Method

	' Identical to GetToken, except it returns a new group
	' containing only the requested token. This is used when calling
	' a function when you only have the name and no arguments.
	Method GetTokenGroup:STokenGroup(index:Int)
		'TODO shouldn't added be checked
		If index < token.Length
			Return New STokenGroup( token[index] )
		ElseIf index < dynamicToken.Length + token.Length
			Return New STokenGroup( dynamicToken[index - token.Length] )
		EndIf
	End Method

	Method AddToken(s:SToken)
		If added < token.Length
			token[added] = s
		Else
			Local dynamicArrayIndex:Int = added - token.Length
			'resize dynamic array if needed
			If dynamicArrayIndex >= dynamicToken.Length Then dynamicToken = dynamicToken[..dynamicArrayIndex + 5]

			dynamicToken[dynamicArrayIndex] = s
		EndIf
		added :+ 1
	End Method

	Method SetToken(index:Int, s:SToken)
		If index < 0 Then Return
		If index < token.Length
			token[index] = s
		Else
			Local dynamicArrayIndex:Int = added - token.Length
			If dynamicArrayIndex >= dynamicToken.Length Then dynamicToken = dynamicToken[..dynamicArrayIndex + 5]
			dynamicToken[dynamicArrayIndex] = s
		EndIf
	End Method
	
	' TokenGroup Debugging
	Method reveal:String( title:String="")
		Local str:String
		If title; str :+ title + "~n"
		For Local n:Int = 0 Until added
			str :+ n+") "+token[n].reveal()+"~n"
		Next
		Return str
	End Method
End Struct


Struct SIdentifier
	Field text:SScriptExpressionSubstring
	Field hash:ULong
	Field _value:String 'cache - in case it is calculated at least
	Field _valueCached:Int = False 'cache - in case it is calculated at least
	
	Method New(text:SScriptExpressionSubstring var)
		self.hash = text.GetHash() 'cache in case of changes
		self.text = text
	End Method
	

	Method GetValue:String()
		if not _valueCached 
			_value = text.GetValue()
			_valueCached = True
		EndIf
		return _value
	End Method
End Struct


Enum ETokenValueType
	Text = 0
	Integer = 1  'int, long
	FloatingPoint = 2 'float, double
	Identifier = 3
	LowerCaseHash = 4
End Enum


Struct SToken
	Field id:Int = TK_ERROR
	'0=string, 1=Long, 2=int
	Field valueType:ETokenValueType
	Field value:String
	Field valueLong:Long
	Field valueDouble:Double
	Field valueIdentifier:SIdentifier
	Field valueLowerCaseHash:ULong
	
	Field linenum:Int, linepos:Int
	
	Method New( id:Int, value:String, linenum:Int, linepos:Int = 0 )
		Self.id = id
		Self.value = value
		Self.valueType = ETokenValueType.Text
		Self.linenum = linenum
		Self.linepos = linepos
	End Method

	Method New( id:Int, valueInt:Int, linenum:Int, linepos:Int = 0 )
		Self.id = id
		Self.valueLong = valueInt
		Self.valueType = ETokenValueType.Integer
		Self.linenum = linenum
		Self.linepos = linepos
	End Method

	Method New( id:Int, valueLong:Long, linenum:Int, linepos:Int = 0 )
		Self.id = id
		Self.valueLong = valueLong
		Self.valueType = ETokenValueType.Integer
		Self.linenum = linenum
		Self.linepos = linepos
	End Method

	Method New( id:Int, valueIdentifier:SScriptExpressionSubstring var, linenum:Int, linepos:Int = 0 )
		Self.id = id
		Self.valueIdentifier = new SIdentifier(valueIdentifier)
		Self.valueType = ETokenValueType.Identifier
		Self.linenum = linenum
		Self.linepos = linepos
	End Method

	Method New( id:Int, valueLowerCaseHash:ULong, linenum:Int, linepos:Int = 0 )
		Self.id = id
		Self.valueLowerCaseHash = valueLowerCaseHash
		Self.valueType = ETokenValueType.LowerCaseHash
		Self.linenum = linenum
		Self.linepos = linepos
	End Method
	
	Method New( id:Int, valueDouble:Double, linenum:Int, linepos:Int = 0 )
		Self.id = id
		Self.valueDouble = valueDouble
		Self.valueType = ETokenValueType.FloatingPoint
		Self.linenum = linenum
		Self.linepos = linepos
	End Method

	Method New( id:Int, valueInt:Int, token:SToken )
		Self.id = id
		Self.valueLong = valueInt
		Self.valueType = ETokenValueType.Integer
		Self.linenum = token.linenum
		Self.linepos = token.linepos
	End Method

	Method New( id:Int, valueLong:Long, token:SToken )
		Self.id = id
		Self.valueLong = valueLong
		Self.valueType = ETokenValueType.Integer
		Self.linenum = token.linenum
		Self.linepos = token.linepos
	End Method


	Method New( id:Int, valueDouble:Double, token:SToken)
		Self.id = id
		Self.valueDouble = valueDouble
		Self.valueType = ETokenValueType.FloatingPoint
		Self.linenum = token.linenum
		Self.linepos = token.linepos
	End Method

	
	Method New( id:Int, value:String, token:SToken )
		Self.id = id
		Self.value = value
		Self.valueType = ETokenValueType.Text
		Self.linenum = token.linenum
		Self.linepos = token.linepos
	End Method


	'set strictTypeCheck to True to evaluate only same types
	'"123" vs 123 -> False
	'123:Long vs 123.0:Double -> False ...
	Method CompareWith:Int(other:SToken, strictTypeCheck:Int = False)
		Local r:Double
		If Self.valueType = ETokenValueType.Integer
			If other.valueType = ETokenValueType.Integer
				r = Self.valueLong - other.valueLong
			ElseIf Not strictTypeCheck
				If other.valueType = ETokenValueType.FloatingPoint
					r = Self.valueLong - other.valueDouble
				ElseIf other.valueType = ETokenValueType.Text
					Local containsNumber:Int
					Local comparison:Int = StringHelper.StringNumberComparison(other.value, self.valueLong, containsNumber)
					if not containsNumber
						r = -1 'at least not equal
					Else
						r = comparison
					EndIf
				EndIf
			EndIf
		ElseIf Self.valueType = ETokenValueType.FloatingPoint
			If other.valueType = ETokenValueType.Integer
				r = Self.valueDouble - other.valueLong
			ElseIf Not strictTypeCheck
				If other.valueType = ETokenValueType.Integer
					r = Self.valueDouble - other.valueDouble
				ElseIf other.valueType = ETokenValueType.Text
					Local containsNumber:Int
					Local comparison:Int = StringHelper.StringNumberComparison(other.value, self.valueDouble, containsNumber)
					if not containsNumber
						r = -1 'at least not equal
					Else
						r = comparison
					EndIf
				EndIf
			EndIf
		ElseIf Self.valueType = ETokenValueType.Text
			If other.valueType = ETokenValueType.Text
				If (self.value = other.value) '"=" allows hash comparison
					r = 0
				ElseIf self.value > other.value
					r = 1
				Else
					r = -1
				EndIf
			ElseIf Not strictTypeCheck
				If other.valueType = ETokenValueType.Integer
					Local containsNumber:Int
					Local comparison:Int = StringHelper.StringNumberComparison(self.value, other.valueLong, containsNumber)
					if not containsNumber
						r = -1 'at least not equal
					Else
						r = comparison
					EndIf
				ElseIf other.valueType = ETokenValueType.FloatingPoint
					Local containsNumber:Int
					Local comparison:Int = StringHelper.StringNumberComparison(self.value, other.valueDouble, containsNumber)
					if not containsNumber
						r = -1 'at least not equal
					Else
						r = comparison
					EndIf
				EndIf
			EndIf
		ElseIf Self.valueType = ETokenValueType.Identifier
			Local selfValue:String = self.valueIdentifier.GetValue()
			Local otherValue:String = other.valueIdentifier.GetValue()
			If selfValue > otherValue
				r = 1
			ElseIf selfValue = otherValue
				r = 1
			Else
				r = -1
			EndIf
		ElseIf Self.valueType = ETokenValueType.LowerCaseHash
			If self.valueLowerCaseHash > other.valueLowerCaseHash
				r = 1
			ElseIf self.valueLowerCaseHash = other.valueLowerCaseHash
				r = 1
			Else
				r = -1
			EndIf
		EndIf

		If r > 0
			Return 1
		ElseIf r = 0
			Return 0
		Else
			Return -1
		EndIf
	End Method


	Method GetValueText:String()
		Select id
		Case TK_ERROR
			Return "([ERROR] " + value + ")"
		Case TK_EOF
			Return "EOF"
		Default
			Select valueType
				Case ETokenValueType.Text
					Return value
				Case ETokenValueType.Integer
					Return valueLong
				Case ETokenValueType.FloatingPoint
					Return valueDouble
				Case ETokenValueType.Identifier
					Return valueIdentifier.GetValue()
				Case ETokenValueType.LowerCaseHash
					Return valueLowerCaseHash
			End Select
		End Select
	End Method


	Method GetValueBool:Int()
		Select id
			Case TK_NUMBER
				If valueType = ETokenValueType.Integer And valueLong > 0
					Return True
				ElseIf valueType = ETokenValueType.FloatingPoint And valueDouble > 0
					Return True
				EndIf
			Case TK_IDENTIFIER
				If value Then Return True
			Case TK_QSTRING
				If value Then Return True
			Case TK_BOOLEAN
				If valueLong = 1 Then Return True
		EndSelect
		Return False
	End Method


	Method GetValueLong:Long()
		Select id
		Case TK_ERROR
			Return -1
		Case TK_EOF
			Return -2
		Default
			Select valueType
				Case ETokenValueType.Integer
					Return valueLong
				Case ETokenValueType.Text
					Return Long(value)
				Case ETokenValueType.FloatingPoint
					Return Long(valueDouble)
				Case ETokenValueType.Identifier
					Return -3
				Case ETokenValueType.LowerCaseHash
					Return -4
			End Select
		End Select
		Return -5
	End Method


	' Debugging
	Method reveal:String()
		If id=TK_ERROR Then Return "h"+Hex(id)+" = ERROR:"+value+" at ["+linenum+","+linepos+"]"
		Select valueType
			Case ETokenValueType.Text
				Return "h"+Hex(id)+" = '"+value+"' (text, " + TokName()+") at ["+linenum+","+linepos+"]"
			Case ETokenValueType.Integer
				Return "h"+Hex(id)+" = '"+valueLong+"' (integer, " + TokName()+") at ["+linenum+","+linepos+"]"
			Case ETokenValueType.FloatingPoint
				Return "h"+Hex(id)+" = '"+valueDouble+"' (floating point, " + TokName()+") at ["+linenum+","+linepos+"]"
			Case ETokenValueType.Identifier
				Return "h"+Hex(id)+" = '"+valueIdentifier.GetValue()+"' (identifier, " + TokName()+") at ["+linenum+","+linepos+"]"
			Case ETokenValueType.LowerCaseHash
				Return "h"+Hex(id)+" = '"+valueLowerCaseHash+"' (lower case hash, " + TokName()+") at ["+linenum+","+linepos+"]"
		End Select
	End Method

	
	Method TokName:String()
		Return TokenName( id )
	End Method
End Struct

' 27/FEB/23, SCAREMONGER, Throw returned back to Return
'Type TParseException
'	Field error:String
'	Field linenum:Int
'	Field linepos:Int
'	Field extra:String

'	Method New( error:String, linenum:Int, linepos:Int, extra:String )
'		Self.error = error
'		Self.linenum = linenum
'		Self.linepos = linepos
'		Self.extra = extra
'	End Method

'	Method New( error:String, token:SToken, extra:String )
'		Self.error = error
'		Self.linenum = token.linenum
'		Self.linepos = token.linepos
'		Self.extra = extra
'	End Method


'	Method reveal:String()
'		Local str:String = error + " at " + linenum + ":" + linepos
'		If extra Then str :+ " ("+extra+")"
'		Return Str
'	End Method
'End Type


Struct SScriptExpressionContext
	Field context:Object
	Field contextNumeric:Int
	Field extra:Object
	
	Method New(context:Object, contextNumeric:Int, extra:Object)
		self.context = context
		self.contextNumeric = contextNumeric
		self.extra = extra
	End Method
End Struct


Struct SScriptExpression
	'parse a raw expression ("${bla}")
	Method Parse:SToken( expression:String, config:SScriptExpressionConfig var, context:SScriptExpressionContext var)
		'DebugStop
		Local parser:SScriptExpressionParser = New SScriptExpressionParser( config, expression, context)
		Local result:SToken = parser.readWrapper()
		'check if something was NOT evaluated (indicator of missing ${ }
		'wrapper - eg when using operators) 
		If parser.lexer.cursor < expression.length
			Local nonEvaluated:String = expression[parser.lexer.cursor ..]
			If nonEvaluated.Trim() 'ignore whitespace
				'adjust line pos to cursor (handled until "there")
				result.linepos = parser.lexer.cursor
				Return New SToken( TK_ERROR, "Non-evaluated content ~q" + nonEvaluated+"~q found. Missing ${...}?", result )
			EndIf
		EndIf
		Return result

		'Try
		'	Return parser.readWrapper()
		'Catch e:TParseException
		'	DebugLog e.reveal()
		'End Try
		'Return New SToken( TK_BOOLEAN, False, 0, 0 )
	End Method


	'parse a text which can contain expressions ("your name is ${bla} ?")
	Method ParseText:String( mixedTextWithExpressions:String, config:SScriptExpressionConfig var, context:SScriptExpressionContext var)
		Local parser:SScriptExpressionParser = New SScriptExpressionParser( config, mixedTextWithExpressions, context, False )
		Local foundValidTokenCount:Int
		Return parser.expandText(foundValidTokenCount)
		'Try
		'	Return parser.expandText()
		'Catch e:TParseException
		'	DebugLog e.reveal()
		'	Return e.reveal()
		'End Try
	End Method


	Method ParseText:String( mixedTextWithExpressions:String, config:SScriptExpressionConfig var, context:SScriptExpressionContext var, foundValidTokenCount:Int var)
		Local parser:SScriptExpressionParser = New SScriptExpressionParser( config, mixedTextWithExpressions, context, False )
		Return parser.expandText(foundValidTokenCount)
	End Method


	
	Method ParseNestedExpressionText:TStringBuilder(mixedTextWithExpressions:String, config:SScriptExpressionConfig var, context:SScriptExpressionContext var)
		Local sb:TStringBuilder = New TStringBuilder(mixedTextWithExpressions)
		Return ParseNestedExpressionText(sb, config, context)
	End Method
	

	Method ParseNestedExpressionText:TStringBuilder(mixedTextWithExpressions:TStringBuilder, config:SScriptExpressionConfig var, context:SScriptExpressionContext var)
		Local iterations:Int = 0

		'resolve (sub-)expressions eg. "${variant}" in "${name_${variant}}" and 
		'single-level-expressions until none is left

		Local replacedSomething:Int = False
		Local dollarSymbolsFound:Int = 0
		Repeat
			dollarSymbolsFound = 0
			replacedSomething = False

			Local escapeCharFound:Int = False
			Local expressionStartPos:Int = -1
			Local charCode:Int
			Local charPos:int
			Local textLength:Int = mixedTextWithExpressions.Length()

			'print "Process: " + mixedTextWithExpressions.ToString()
			'print "pos      " + Rset("^", charPos + 1) + Rset("|", charPos + 1 + textLength - 1 - 1)

			While charPos < textLength' - 1
				charCode = mixedTextWithExpressions.CharAt(charPos)
				
				'found the start of an escape char: "\${}"
				If charCode = Asc("\") And Not escapeCharFound
					escapeCharFound = True
					charPos :+ 1
					Continue
				EndIf

				'found a expression start ("$") but not an escaped one ("\$")
				If charCode = SYM_DOLLAR And Not escapeCharFound
					dollarSymbolsFound :+ 1

					'and also found the opener ("{")
					If charPos < textLength and mixedTextWithExpressions.CharAt(charPos + 1) = SYM_LBRACE
						expressionStartPos = charPos
						charPos :+ 1
					EndIf

				'closing the "inner" one? ("${hello${world}}" - close on last but one "}")
				'-> so finds "${world}"
				ElseIf charCode = SYM_RBRACE 
					'found expression -> handle it
					If expressionStartPos > -1
						'print "         " + ""[..expressionStartPos] + "^--begin"
						'print "         " + ""[..charPos] + "^--end"
						
						Local expression:String = mixedTextWithExpressions.Substring(expressionStartPos, charPos +1) 'sb.substring endindex is exclusive -> +1
						Local newValue:String = parseText( expression, config, context)

						rem
						Local containsExpression:int = newValue.Find("${") >= 0
						'try to replace further expressions returned by just
						'this expression ${town} => "the town is ${.stationmap_randomcity}" => "the town is Bremen"
						'this avoid iterating over a lengthier string over and over
						while containsExpression
							Local newNewValue:String = parseText( newValue, config, context )
							if newNewValue = newValue
								containsExpression = False
							Else
								newValue = newNewValue
								containsExpression = newValue.Find("${") >= 0
							endif
						Wend
						endrem
						
						
						'print "Replace: ~q" + expression + "~q -> ~q" + newValue +"~q"

						'either replace (all occourenced - eg ${index} used more than once)
						'or do a mixedTextWithExpressions.Remove(index,index+length) and text.insert(index, newValue)
						'depends on what is more likely
						mixedTextWithExpressions.Replace(expression, newValue)
						'mixedTextWithExpressions.Remove(expressionStartPos, charPos +1)
						'mixedTextWithExpressions.insert(expressionStartPos, newValue)

						'update length and move charpos
						textLength = mixedTextWithExpressions.Length()
						charPos :+ newValue.length - expression.Length

						'print "Process: " + mixedTextWithExpressions.ToString()
						'print "         " + ""[..charPos] + "^--charpos"

						replacedSomething = True

						dollarSymbolsFound :- 1
						if newValue.Find("$") >= 0 Then dollarSymbolsFound :+ 1

						expressionStartPos = -1
					EndIf
				EndIf
				
				escapeCharFound = False
				charPos :+ 1
			Wend
			'print "dollarSymbolsLeft: " + dollarSymbolsFound  +"  -> " + text.ToString()
			
			iterations :+ 1
			If iterations > 20 'avoid doing more than 20 cycles (eg. deadloops / bugs)
				Print "ParseMultiLevelExpressionText: iterated more than 20 times over the given text. Avoid deep nesting - or found a bug?"
				Print "Text: " + mixedTextWithExpressions.toString()
				exit
			EndIf
		Until not replacedSomething or dollarSymbolsFound = 0
		
		Return mixedTextWithExpressions
	End Method

rem
'unused

	Method GetVariableContent:String(variableKey:String, result:Int Var)
		result = True
		Return variableKey
	End Method
endrem
End Struct




Type TScriptExpression
	Global functionHandlers:TStringMap = New TStringMap()
	Global functionHandlersByHash:TLongMap = New TLongMap()

	Field config:TScriptExpressionConfig 


	Method New()
		config = New TScriptExpressionConfig()
	End Method
		

	Method New( config:TScriptExpressionConfig )
		If Not config Then config = New TScriptExpressionConfig()	' Default!
		Self.config = config
	End Method


	Method ParseToTrue:Int(expression:String)
		Local context:SScriptExpressionContext
		Local parsedToken:SToken = New SScriptExpression.Parse(expression, Self.config.s, context)
		'true: any unempty string, numbers <> 0, bool (true, false), ...
		Return _IsTrueValue( parsedToken )
	End Method

	Method ParseToTrue:Int(expression:String, context:SScriptExpressionContext var)
		Local parsedToken:SToken = New SScriptExpression.Parse(expression, Self.config.s, context)
		'true: any unempty string, numbers <> 0, bool (true, false), ...
		Return _IsTrueValue( parsedToken )
	End Method

	Method ParseToTrue:Int(expression:String, contextObject:object)
		Local context:SScriptExpressionContext = new SScriptExpressionContext(contextObject, 0, Null)
		Local parsedToken:SToken = New SScriptExpression.Parse(expression, Self.config.s, context)
		'true: any unempty string, numbers <> 0, bool (true, false), ...
		Return _IsTrueValue( parsedToken )
	End Method


	Method ParseToTrue:Int(expression:String, contextObject:object, parsedToken:SToken var)
		Local context:SScriptExpressionContext = new SScriptExpressionContext(contextObject, 0, Null)
		parsedToken = New SScriptExpression.Parse(expression, Self.config.s, context)
		'true: any unempty string, numbers <> 0, bool (true, false), ...
		Return _IsTrueValue( parsedToken )
	End Method


	Method Parse:SToken(expression:String)
		Local context:SScriptExpressionContext
		Return New SScriptExpression.Parse(expression, Self.config.s, context)
	End Method

	Method Parse:SToken(expression:String, context:SScriptExpressionContext var)
		Return New SScriptExpression.Parse(expression, Self.config.s, context)
	End Method

	Method Parse:SToken(expression:String, config:SScriptExpressionConfig var)
		Local context:SScriptExpressionContext
		Return New SScriptExpression.Parse(expression, config, context)
	End Method

	Method Parse:SToken(expression:String, config:TScriptExpressionConfig, context:SScriptExpressionContext var)
		Return New SScriptExpression.Parse(expression, config.s, context)
	End Method


	Method ParseText:String(expression:String, config:TScriptExpressionConfig, context:SScriptExpressionContext var)
		Return New SScriptExpression.ParseText(expression, config.s, context)
	End Method

	Method ParseText:String(expression:String, config:TScriptExpressionConfig, context:SScriptExpressionContext var, foundValidTokenCount:Int var)
		Return New SScriptExpression.ParseText(expression, config.s, context, foundValidTokenCount)
	End Method


	Method ParseNestedExpressionText:TStringBuilder(text:String)
		Local context:SScriptExpressionContext
		Return New SScriptExpression.ParseNestedExpressionText(text, self.config.s, context)
	End Method

	Method ParseNestedExpressionText:TStringBuilder(text:String, context:SScriptExpressionContext var)
		Return New SScriptExpression.ParseNestedExpressionText(text, self.config.s, context)
	End Method

	Method ParseNestedExpressionText:TStringBuilder(text:String, config:TScriptExpressionConfig, context:SScriptExpressionContext var)
		Return New SScriptExpression.ParseNestedExpressionText(text, config.s, context)
	End Method

	Method ParseNestedExpressionText:TStringBuilder(text:String, config:TScriptExpressionConfig)
		Local context:SScriptExpressionContext
		Return New SScriptExpression.ParseNestedExpressionText(text, config.s, context)
	End Method

	Method ParseNestedExpressionText:TStringBuilder(text:TStringBuilder, context:SScriptExpressionContext var)
		Return New SScriptExpression.ParseNestedExpressionText(text, self.config.s, context)
	End Method

	Method ParseNestedExpressionText:TStringBuilder(text:TStringBuilder, config:TScriptExpressionConfig, context:SScriptExpressionContext var)
		Return New SScriptExpression.ParseNestedExpressionText(text, config.s, context)
	End Method
	

	Function RegisterFunctionHandler( functionName:String, callback:SToken(params:STokenGroup Var, context:SScriptExpressionContext var), paramMinCount:Int = -1, paramMaxCount:Int = -1)
		Local fnLower:String = functionName.ToLower()
		Local handler:TSEFN_Handler = New TSEFN_Handler(callback, paramMinCount, paramMaxCount)
		functionHandlers.Insert(fnLower, handler)
		functionHandlersByHash.Insert(Long(fnLower.Hash()), handler)
		'functionHandlersByHash.Insert(Long(SubStringHash(fnLower, 0, fnLower.length)), handler)
	End Function


	Function GetFunctionHandler:TSEFN_Handler( functionName:String )
		Return TSEFN_Handler( functionHandlers.ValueForKey( functionName.ToLower() ))
	End Function 


	Function GetFunctionHandler:TSEFN_Handler( functionNameLowerHash:Long )
		Return TSEFN_Handler( functionHandlersByHash.ValueForKey( functionNameLowerHash ))
	End Function 

	Function GetFunctionHandler:TSEFN_Handler( functionNameLowerHash:ULong )
		Return TSEFN_Handler( functionHandlersByHash.ValueForKey( Long(functionNameLowerHash) ))
	End Function 


	'returns how many elements in the passed array are "true"
	Function _CountTrueValues:Int(tokens:STokenGroup Var, startIndex:Int = 0)
		If tokens.added = 0 Then Return 0

		Local trueCount:Int 
		For Local i:Int = startIndex Until tokens.added
			Local t:SToken = tokens.GetToken(i)
			Select t.id
				Case TK_NUMBER
					If t.valueType = ETokenValueType.Integer And t.valueLong > 0
						trueCount :+ 1
					ElseIf t.valueType = ETokenValueType.FloatingPoint And t.valueDouble > 0
						trueCount :+ 1
					EndIf
				Case TK_IDENTIFIER
					If t.value Then trueCount :+ 1
				Case TK_QSTRING
					If t.value Then trueCount :+ 1
				Case TK_BOOLEAN
					If t.valueLong = 1 Then trueCount :+ 1	' Quicker in Production
			EndSelect
		Next
	
		'count = 0: none true,
		'0 < count < arr.length: not all are true (but at least one)
		'count = arr.length: all true
		Return trueCount
	End Function	


	Function _IsTrueValue:Int(t:SToken Var)
		Select t.id
			Case TK_NUMBER
				If t.valueType = ETokenValueType.Integer And t.valueLong > 0
					Return 1
				ElseIf t.valueType = ETokenValueType.FloatingPoint And t.valueDouble > 0
					Return 1
				EndIf
			Case TK_IDENTIFIER
				If t.value Then Return 1
			Case TK_QSTRING
				If t.value Then Return 1
			Case TK_BOOLEAN
				If t.valueLong = 1 Then Return 1	' Quicker in Production
		End Select
	
		Return 0
	End Function	


	'returns how many elements are equal to the first passed value
	Function _CountEqualValues:Int(tokens:STokenGroup Var, startIndex:Int = 0)
		If tokens.added = 0 Then Return 0

		Local equalCount:Int = 1 'is equal with itself
		Local firstT:SToken = tokens.GetToken(startIndex)
		If firstT.id = TK_NUMBER Or firstT.id = TK_BOOLEAN
			If firstT.valueType = ETokenValueType.Integer 
				For Local i:Int = startIndex + 1 Until tokens.added
					Local t:SToken = tokens.GetToken(i)
					If t.id = firstT.id And ((t.valueType = ETokenValueType.Integer And t.valueLong = firstT.valueLong) Or (t.valueType = ETokenValueType.FloatingPoint And t.valueDouble = firstT.valueLong))
						equalCount :+ 1
					EndIf
				Next
			ElseIf firstT.valueType = ETokenValueType.FloatingPoint
				For Local i:Int = startIndex + 1 Until tokens.added
					Local t:SToken = tokens.GetToken(i)
					If t.id = firstT.id And ((t.valueType = ETokenValueType.Integer And t.valueLong = firstT.valueDouble) Or (t.valueType = ETokenValueType.FloatingPoint And t.valueDouble = firstT.valueDouble))
						equalCount :+ 1
					EndIf
				Next
			EndIf
		Else
			Local firstIsText:int = (firstT.id = TK_IDENTIFIER or firstT.id = TK_QSTRING)
			For Local i:Int = startIndex + 1 Until tokens.added
				Local t:SToken = tokens.GetToken(i)
				If ((t.id = firstT.id) or (t.id <> firstT.id and firstIsText and (t.id = TK_IDENTIFIER or t.id = TK_QSTRING))) ..
				   and t.value = firstT.value
						equalCount :+ 1
				EndIf
			Next
		EndIf
		Return equalCount
	End Function
End Type





Struct SScriptExpressionConfig
	Field functionHandlerCB:TSEFN_Handler(functionName:String)
	Field functionLowerHashHandlerCB:TSEFN_Handler(functionNameLowerHash:ULong)
	Field variableIdentifierHandlerCB:String(variableIdentifier:SIdentifier var, context:SScriptExpressionContext var)
	Field variableLowerCaseHashHandlerCB:String(variableLowerCaseHash:ULong, context:SScriptExpressionContext var)
	Field variableHandlerCB:String(variableName:String, context:SScriptExpressionContext var)
	Field errorHandler:String(t:String, context:SScriptExpressionContext var)


	Method New( functionHandlerCB:TSEFN_Handler(functionName:String), variableHandlerCB:String(variableName:String, context:SScriptExpressionContext var), errorHandler:String(t:String, context:SScriptExpressionContext var) )
		Self.functionHandlerCB = functionHandlerCB
		Self.variableHandlerCB = variableHandlerCB
		Self.errorHandler = errorHandler
	End Method

	
	Method GetFunctionHandler:TSEFN_Handler(functionName:String)
		If functionHandlerCB Then Return functionHandlerCB(functionName)
		'fall back to default
		Return TScriptExpression.GetFunctionHandler(functionName)
	End Method


	Method GetFunctionHandler:TSEFN_Handler(functionNameLowerHash:ULong)
		If functionLowerHashHandlerCB Then Return functionLowerHashHandlerCB(functionNameLowerHash)
		'fall back to default
		Return TScriptExpression.GetFunctionHandler(functionNameLowerHash)
	End Method


	Method GetFunctionHandler:TSEFN_Handler(functionNameLowerHash:Long)
		If functionLowerHashHandlerCB Then Return functionLowerHashHandlerCB(Ulong(functionNameLowerHash))
		'fall back to default
		Return TScriptExpression.GetFunctionHandler(functionNameLowerHash)
	End Method


	' Example 
	Method EvaluateVariable( identifier:SToken Var, context:SScriptExpressionContext var)
		if identifier.valueType = ETokenValueType.Identifier
			If variableIdentifierHandlerCB
				identifier.value = variableIdentifierHandlerCB(identifier.valueIdentifier, context)
				identifier.valueType = ETokenValueType.Text
				Return
			ElseIf variableLowerCaseHashHandlerCB
				identifier.value = variableLowerCaseHashHandlerCB(identifier.valueIdentifier.hash, context)
				identifier.valueType = ETokenValueType.Text
				Return
			EndIf
		EndIf
		
		If variableLowerCaseHashHandlerCB and identifier.valueType = ETokenValueType.LowerCaseHash
			identifier.value = variableLowerCaseHashHandlerCB(identifier.valueLowerCaseHash, context)
			identifier.valueType = ETokenValueType.Text
		ElseIf variableHandlerCB
			identifier.value = variableHandlerCB(identifier.GetValueText(), context)
			identifier.valueType = ETokenValueType.Text
		Else
			identifier.value="<"+identifier.value+">"
		EndIf
	End Method
End Struct




Type TScriptExpressionConfig Final
	Field s:SScriptExpressionConfig
	Field sIsSet:Int

	Method New(config:SScriptExpressionConfig)
		Self.s = config
		Self.sIsSet = True
	End Method

	
	Method New( functionHandlerCB:TSEFN_Handler(functionName:String), variableHandlerCB:String(variableName:String, context:SScriptExpressionContext var), errorHandler:String(t:String, context:SScriptExpressionContext var) )
		Self.s = New SScriptExpressionConfig(functionHandlerCB, variableHandlerCB, errorHandler)
		Self.sIsSet = True
	End Method


	Method GetFunctionHandler:TSEFN_Handler(functionName:String)
		If sIsSet Then Return Self.s.GetFunctionHandler(functionName)
	End Method


	Method GetFunctionHandler:TSEFN_Handler(functionName:ULong)
		If sIsSet Then Return Self.s.GetFunctionHandler(functionName)
	End Method


	Method GetFunctionHandler:TSEFN_Handler(functionName:Long)
		If sIsSet Then Return Self.s.GetFunctionHandler(functionName)
	End Method

	
	Method EvaluateVariable( identifier:SToken Var, context:SScriptExpressionContext var)
		If sIsSet Then Self.s.EvaluateVariable(identifier, context)
		'TODO: Throw exception about unset SScriptExpressionConfig
	End Method
End Type


Struct SScriptExpressionSubstring
	Field s:String
	Field start:Int
	Field length:Int
	Field isSet:Int = False
	Field hash:ULong
	
	Method New(s:String, start:Int, length:Int)
		Self.s = s
		Self.start = start
		Self.length = length
		isSet = True
	End Method

	
	Method Set(s:String, start:Int, length:Int)
		Self.s = s
		Self.start = start
		Self.length = length
		isSet = True
	End Method
	

	Method Matches:Int(other:String)
		If length <> other.length Return False
		Local i:Int = 0
		While i < length
			If s[start + i] <> other[i] Return False
			i :+ 1
		Wend
		Return True
	End Method


	Method MatchesCaseInsensitive:Int(other:String)
		If length <> other.length Return False
		Local i:Int = 0
		Local char:int
		Local otherChar:Int
		While i < length
			char = s[start + i]
			otherChar = other[i]

			'char is lowercase? make it uppercase
			If char >= 97 and char <= 122 Then char :- 32
			'other char is lowercase? make it uppercase
			if otherChar >= 97 and otherChar <= 122 Then otherchar :- 32
			if char <> otherChar Then Return False

			i :+ 1
		Wend
		Return True
	End Method

	Method GetValue:String()
		Return s[start .. start + length]
	End Method

	Method GetHash:ULong()
		if not hash then hash = SubAsciiStringHashLC(s, start, length) 
		return hash
		'Return s[start .. start + length]
	End Method
End Struct



' Expression Tokeniser
Struct SScriptExpressionLexer
	Field cursor:Int
	Field linenum:Int
	Field linepos:Int
	Field expression:String
	
	Method New( expression:String )
		Self.expression = expression	'New TStringBuilder( expression )
		cursor = 0
		linenum = 0
		linepos = 1
	End Method
	
	Private

	Method PeekChar:Int()
		If cursor >= expression.Length Then Return 0
		Return expression[ cursor ]
	End Method

	' Pops next character moving the cursor forward
	Method PopChar:Int()
		If cursor >= expression.Length Then Return TK_EOF
		Local ch:Int = expression[ cursor ]
		' Move the cursor forward
		If ch = TK_LF	' \n
			linenum :+ 1
			linepos = 1
			cursor :+ 1
		Else
			linepos :+ 1
			cursor :+ 1
		End If
		Return ch
	End Method


	' Retrieves the current token (At the cursor)
	Method GetNext:SToken()
		Repeat
			Local ch:Int = PeekChar()
'If ch>=60 And ch<=62; DebugStop
			' Save the line number and position so we can use it later
			Local linenumstart:Int = linenum
			Local lineposstart:Int = linepos
			'DebugStop
			Select True
				' End of file
				Case ch = 0
					Return New SToken( TK_EOF, 1, linenum, linepos )

				' Whitespace or control codes
				Case ch <= SYM_SPACE Or ch >=126
					PopChar()

				' FUNCTION
				Case ch = SYM_PERIOD
					'DebugStop
					' Strip function identifier 
					Popchar()
					'eat( SYM_PERIOD )

					Local ident:SScriptExpressionSubstring = ExtractIdent()

					'If token.id <> TK_IDENTIFIER Then Throw New TParseException( "Identifier expected", token, "readWrapper()" )
					'token.id = TK_FUNCTION
					'result.AddToken(token)

					'advance()
					'Return New SToken( TK_FUNCTION, ident.GetHash(), linenumstart, lineposstart )					
					Return New SToken( TK_FUNCTION, ident, linenumstart, lineposstart )

				' QUOTED STRING
				Case ch = SYM_DQUOTE
					Return New SToken( TK_QSTRING, ExtractQuotedString(), linenumstart, lineposstart )

				' NUMBER
				Case ch = 45 Or ( ch >= 48 And ch <= 57 )
					Local valueLong:Long, valueDouble:Double, valueType:Int
					valueType = ExtractNumber(valueLong, valueDouble)
					If valueType = 1
						Return New SToken( TK_NUMBER, valueLong, linenumstart, lineposstart )
					ElseIf valueType = 2
						Return New SToken( TK_NUMBER, valueDouble, linenumstart, lineposstart )
					EndIf

				' LETTER
				Case ( ch >= 97 And ch <= 122 ) Or ( ch >= 65 And ch <= 90 )
					'DebugStop
					Local ident:SScriptExpressionSubstring = ExtractIdent()
					If ident.MatchesCaseInsensitive("true")
						Return New SToken( TK_BOOLEAN, True, linenumstart, lineposstart )
					ElseIf ident.MatchesCaseInsensitive("false") 
						Return New SToken( TK_BOOLEAN, False, linenumstart, lineposstart )
					Else
						'Return New SToken( TK_IDENTIFIER, ident.GetValue(), linenumstart, lineposstart )
						Return New SToken( TK_IDENTIFIER, ident, linenumstart, lineposstart )
					EndIf
				
				' OPERATORS	"<", "<=", "==", ">", ">=" and "<>"
				Case ( ch >= 60 And ch <= 62)
					Local opcode:Int = popChar()
					'
					ch = peekChar()
					If opcode = SYM_LSS
						Select ch
						Case SYM_EQUAL		' LESS THAN OR EQUAL
							popChar()
							Return New SToken( TK_OPERATOR, "<=", linenumstart, lineposstart )						
						Case SYM_GTR		' NOT EQUAL
							popChar()
							Return New SToken( TK_OPERATOR, "<>", linenumstart, lineposstart )						
						Default				' LESS THAN
							Return New SToken( TK_OPERATOR, "<", linenumstart, lineposstart )
						End Select
					Else If opcode = SYM_EQUAL 
						If ch = SYM_EQUAL	' EQUAL
							popChar()
							Return New SToken( TK_OPERATOR, "==", linenumstart, lineposstart )
						Else				' ASSIGNMENT
							'Return New SToken( TK_ASSIGNMENT, "=", linenumstart, lineposstart )
							Return New SToken( TK_OPERATOR, "=", linenumstart, lineposstart )
						EndIf
					Else 'if opcode = SYM_GTR
						If ch = SYM_EQUAL	' GREATER THAN OR EQUAL
							popChar()
							Return New SToken( TK_OPERATOR, ">=", linenumstart, lineposstart )						
						Else				' GREATER THAN
							Return New SToken( TK_OPERATOR, ">", linenumstart, lineposstart )
						End If
					End If
				
				' SYMBOLS
				Default ' ch = SYM_COLON Or ch = SYM_PERIOD
					Return New SToken( ch, PopChar(), linenum, linepos )
			End Select	
		Forever
	End Method
		
	' Read text until it hits a group-wrapper '$' symbol
	Method GetBlock:String()
		'DebugStop
		Local start:Int = cursor	', finish:Int = cursor
		While cursor<expression.Length ..
			And expression[cursor] <> SYM_DOLLAR
			cursor :+ 1
			linepos :+ 1
		Wend
		'Local temp:String = expression[ start..cursor ]		
		'DebugStop
		Return expression[ start..cursor ]		
	End Method

	' SCAREMONGER / Replaced as "ch" not being updated!
	' Identifier starts with a letter, but can contain "_" and numbers
	'Method ExtractIdent:String()
	'	Local start:Int = cursor
	'	If cursor = expression.length Then Return ""
	'	Local ch:Int = expression[cursor]
	'	While ch = SYM_UNDERSCORE ..
	'		Or ( ch >= 48 And ch <= 57 ) ..     ' NUMBER
	'		Or ( ch >= 65 And ch <= 90 ) ..     ' UPPERCASE
	'		Or ( ch >= 97 And ch <= 122 )       ' LOWERCASE
	'		cursor :+ 1
	'		If cursor = expression.length Then Exit
	'	Wend
	'	Return expression[ start..cursor ]
	'End Method
	' SCAREMONGER - END
	
	' Identifier starts with a letter, but can contain "_" and numbers
	Method ExtractIdent:SScriptExpressionSubstring()
		'DebugStop
		Local start:Int = cursor	', finish:Int = cursor
		While cursor<expression.length ..
			And ( expression[cursor] = SYM_UNDERSCORE ..
				Or ( expression[cursor] >= 48 And expression[cursor] <= 57 ) ..		' NUMBER
				Or ( expression[cursor] >= 65 And expression[cursor] <= 90 ) ..		' UPPERCASE
				Or ( expression[cursor] >= 97 And expression[cursor] <= 122 ) ..	' LOWERCASE
			)		
			cursor :+ 1
			linepos :+ 1
		Wend
		Return New SScriptExpressionSubstring(expression, start, cursor-start)
		'Return expression[ start..cursor ]
	End Method


	Method ExtractNumber:Int(longValue:Long Var, doubleValue:Double Var)
		longValue = 0
		doubleValue = 0
		If cursor = expression.Length Then Return False

		'DebugStop
		Local negative:Int = False
		Local decimalDivider:Long=10
		Local ch:Int = PeekChar()

		' Leading "-" (Negative number)
		If ch = SYM_HYPHEN	
			negative = True
			cursor :+ 1
			linepos :+ 1
			ch = PeekChar()
		End If
		' Number
		While ch<>0 And ( ch>=48 And ch<=57 )
			longValue = longValue * 10 + (ch-48)
			cursor :+ 1
			linepos :+ 1
			ch = PeekChar()
		Wend

		' Decimal
		If ch = SYM_PERIOD
			doubleValue = longValue
			cursor :+ 1
			linepos :+ 1

			ch = PeekChar()
			While ch<>0 And ( ch>=48 And ch<=57 ) And decimalDivider < 10000000000:Long
				doubleValue :+ Double(ch-48) / decimalDivider
				decimalDivider :* 10
				cursor :+ 1
				linepos :+ 1
				ch = PeekChar()
			Wend
			If negative Then doubleValue :* -1
			Return 2
		End If
		If negative Then longValue :* -1
		Return 1
	End Method


	' Identifier starts with a letter, but can contain "_" and numbers
	Method ExtractQuotedString:String()
		' Skip leading quote
		'DebugStop
		popchar()
		
		Local start:Int = cursor
		While expression[cursor] <> TK_EOF And expression[cursor] <> SYM_DQUOTE
			Select True
			'escape next
			Case expression[cursor] = Asc("\")
			'DebugStop
				cursor :+ 2
				linepos :+ 2
			Case expression[cursor] = TK_LF	'\n
				linenum :+ 1
				linepos = 1
				cursor :+ 1
			Default
				linepos :+ 1
				cursor :+ 1
			End Select
		Wend
		'do not include trailing quote, so subtract in slice again
		popchar()
'		Local temp:String = expression[ start..cursor - 1].Replace("\~q","~q")
'DebugStop
		Return expression[ start..cursor - 1].Replace("\~q","~q")
	End Method
End Struct



' Expression Parser
Struct SScriptExpressionParser
	Field context:SScriptExpressionContext
	Field lexer:SScriptExpressionLexer
	' Current token
	Field token:SToken
	Field config:SScriptExpressionConfig
	Field configIsSet:Int
	Field extra:Object
	
	Method New( config:SScriptExpressionConfig, expression:String, context:SScriptExpressionContext var, readFirst:Int = True )
		Self.config = config
		Self.configIsSet = True

		Self.context = context
		lexer = New SScriptExpressionLexer( expression )
		
		' Read first token
		' We only do this when parsing a token
		' for strings we need to use the start of line
		If readFirst Then advance()
	End Method

	Method expandText:String(foundValidTokenCount:Int var)
		foundValidTokenCount = 0
		
		Local result:TStringBuilder = New TStringBuilder()
'		Local result:String
		'DebugStop
		Repeat
			Local block:String = lexer.getBlock()
'			result :+ block
			result.append(block)
			advance()
			Select token.id
				Case TK_EOF
'					Return result
					Return result.ToString()
				Case SYM_DOLLAR
					Local token:SToken = readWrapper()
'					print token.id + " -> " + token.GetValueText()
'					if token.id <> TK_ERROR
						foundValidTokenCount :+ 1
'					EndIf
'					result :+ token.GetValueText()
					result.Append(token.GetValueText())
			End Select
		Forever
	End Method

	' Read a readWrapper ${..}
	Method readWrapper:SToken()
		' Skip leading Dollar symbol
		eat( SYM_DOLLAR )
		Return readStatement()
	End Method
	
	' Read Statement {..}
	Method readStatement:SToken()
		Local result:STokenGroup
		' Skip leading Opening Brace
		If token.id <> SYM_LBRACE Then Return New SToken( TK_ERROR, "Expected '{'", token )
		eat( SYM_LBRACE )
		' Termination
		If token.id = TK_EOF Then Return New SToken( TK_ERROR, "Unexpected end of file", token )
		' Empty Wrapper
		If token.id = SYM_RBRACE Then Return New SToken( TK_ERROR, "Empty group", token )
		
		' Next are one or more arguments
		Repeat
			' Get next block
			'DebugStop
			Local block:SToken = readBlock()
			If block.id = TK_ERROR Then Return block

			' V7.2, Single argument functions need to be evaluated
			If block.id = TK_FUNCTION And result.added>0
				'DebugStop
				Local func:STokenGroup = New STokenGroup()
				func.addToken( block )
				result.addToken( Eval( func ) )
			Else
				result.addToken( block )
				'Print block.reveal()
				'DebugStop
			End If
									
			' If we have finished, evaluate the wrapper and return the result
			If token.id = SYM_RBRACE Then Return eval( result )

			' Next symbol should be a colon
			eat( SYM_COLON )
			If token.id = TK_ERROR Then Return block
			
		Forever			
	End Method
	
	' Read a block of tokens (Between Colons)
	Method readBlock:SToken()
		Local result:STokenGroup
		Repeat
		'Print lexer.expression
			'Print " "[..(lexer.cursor-1)]+"^  {"+lexer.linenum+":"+lexer.linepos+"} "+tokenName( token.id )
			Select token.id
				Case TK_EOF
					'Throw New TParseException( "Unexpected end of expression", token, "readWrapper().params" )
					Return New SToken( TK_ERROR, "Unexpected end of expression", token )
					
				Case SYM_DOLLAR		' Embedded Script Expression
					result.AddToken(readWrapper())
					advance()

				Case SYM_LBRACE		' Embedded function
					result.AddToken(readStatement())
					advance()

				Case TK_FUNCTION	' Function
					result.AddToken(token)
					advance()			
					
				Case TK_IDENTIFIER	' Identifiers on their own are variables!
					' Replace the identifier
					If configIsSet Then config.evaluateVariable( token, context ) 
					result.AddToken(token)
					advance()

				Case TK_QSTRING, TK_NUMBER, TK_BOOLEAN
					result.AddToken(token)
					advance()

				Case TK_OPERATOR
					'DebugStop
					result.AddToken(token)
					advance()

				Default
					'DebugLog( "ReadWrapper() ["+token.id+"] "+token.GetValueText()+", error" )
					'Throw New TParseException( "Unexpected token", token, "readWrapper()" )
					Return New SToken( TK_ERROR, "Unexpected token", token )
			End Select
			
			If token.id = SYM_COLON Or token.id = SYM_RBRACE Or token.id=TK_EOF
				' Single item in the block is returned as an argument
				If result.added = 1 Then Return result.getToken(0)
				
				' Multiple items in a block need to be evaluated
				'DebugStop
			
				' Check for an operator
				'Print result.reveal()
				'debugstop
				If result.added = 3 And result.getToken(1).id = TK_OPERATOR
					'Print result.reveal()
					'DebugStop
					' Convert operator to a function
					Local optoken:SToken = result.getToken(1)
					optoken.id = TK_FUNCTION
					Local LExpression:STokenGroup = result.GetTokenGroup(0) ' Left expression
					Local RExpression:STokenGroup = result.GetTokenGroup(2) ' Right expression

					'Print( LExpression.reveal("LEFT EXPRESSION:") )
					'Print( RExpression.reveal("RIGHT EXPRESSION:") )
					' Build new function defintion
					Local func:STokenGroup = New STokenGroup()
					func.addToken( optoken )
					func.addToken( eval( LExpression ) )	
					func.addToken( eval( RExpression ) )
					'Print func.reveal("FUNCTION:")
					'DebugStop
					Return eval(func)
				End If				
			End If
			
		Forever
		
	End Method
	
	Method readFunction:SToken()
	End Method
	
	' Advances the token
	Method advance()
		'DebugStop
		'Local savecursor:Int = lexer.cursor
		token = lexer.getNext()
		'Print lexer.expression
		'Print " "[..(savecursor)]+"^  {"+token.linenum+":"+token.linepos+"} "+tokenName( token.id )
		'DebugStop
	End Method


	' Consume an expected symbol.
	' If symbol does not exist, create a missing node in it's place
	Method eat:SToken( expectation:Int ) 
		If token.id = expectation
			'DebugStop
			advance()
			Return token
		EndIf
'DebugStop
		'Throw New TParseException( token.GetValueText() + " was unexpected", token, "eat()" )
		Return New SToken( TK_ERROR, token.GetValueText() + " was unexpected", token )
	End Method		

	' Evaluate a Token group
	Method eval:SToken( tokens:STokenGroup Var )
		Local firstToken:SToken = tokens.GetToken(0)

		Select firstToken.id
			Case TK_FUNCTION
				'DebugStop
				Local fn:TSEFN_Handler
				' using an if-else here so config's GetFunctionHandler (or more likely the callback
				' there) could return Null (so "overriding" the existence of defined default functions
				' so the developer recognizes they need to implement it in their custom config)
				If configIsSet
					if firstToken.valueType = ETokenValueType.LowerCaseHash
						fn = config.GetFunctionHandler( firstToken.valueLowerCaseHash ) 
					else
						fn = config.GetFunctionHandler( firstToken.GetValueText() ) 
					endif
				' automatic fallback only if NO config is set
				Else
					if firstToken.valueType = ETokenValueType.LowerCaseHash
						fn = TScriptExpression.GetFunctionHandler( firstToken.valueLowerCaseHash )
					else
						fn = TScriptExpression.GetFunctionHandler( firstToken.GetValueText() ) 
					endif
				EndIf
				If Not fn Then Return New SToken( TK_ERROR, "Undefined function ~q"+firstToken.GetValueText()+"~q", firstToken )

				Return fn.run( tokens, context )

			Case TK_IDENTIFIER, TK_BOOLEAN, TK_NUMBER, TK_QSTRING
				If tokens.added > 1 Then Return New SToken( TK_ERROR, "Invalid parameters", tokens.GetToken(1) )

				Return firstToken
		End Select
	End Method

End Struct




Type TSEFN_Handler
	Field paramMinCount:Int = -1
	Field paramMaxCount:Int = -1
	Field callback:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)

	Method New(callback:SToken( params:STokenGroup Var, context:SScriptExpressionContext var), paramMinCount:Int, paramCount:Int)
		Self.callback = callback
		Self.paramMinCount = paramMinCount
		Self.paramMaxCount = paramMaxCount
	End Method


	Method Run:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
		If callback Then Return callback(params, context)
	End Method
End Type

' Register default functions
Function SEFN_Or:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local first:SToken = params.GetToken(0)
	Return New SToken( TK_BOOLEAN, TScriptExpression._CountTrueValues(params, 1) > 0, first.linenum, first.linepos )
End Function

Function SEFN_And:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local first:SToken = params.GetToken(0)
	Return New SToken( TK_BOOLEAN, TScriptExpression._CountTrueValues(params, 1) = params.added - 1, first.linenum, first.linepos )
End Function

Function SEFN_Not:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local first:SToken = params.GetToken(0)
	Return New SToken( TK_BOOLEAN, TScriptExpression._CountTrueValues(params, 1) = 0, first.linenum, first.linepos )
End Function

Function SEFN_If:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	' Get the IF token so we can use the line number and position
	Local first:SToken = params.GetToken(0)
	
	' Process results
	If params.added > 1
		Local t:SToken = params.GetToken(1)
		'Print t.reveal()
		If TScriptExpression._IsTrueValue(t)
			' Expression is TRUE
			If params.added < 3
				Return New SToken( TK_BOOLEAN, True, first.linenum, first.linepos )
			Else
				Return params.GetToken(2)
			EndIf
		Else
			' Expression is FALSE
			If params.added < 4
				Return New SToken( TK_BOOLEAN, False, first.linenum, first.linepos )
			Else
				Return params.GetToken(3)
			EndIf
		EndIf
	EndIf
End Function

Function SEFN_Select:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local first:SToken = params.GetToken(0)
	If params.added Mod 2 <> 1 Then Return New SToken( TK_ERROR, "even number of parameters expected", first )

	Local key:SToken = params.GetToken(1)
	Local i:Int = 2
	Repeat
		If key.CompareWith(params.GetToken(i)) = 0 Then Return params.GetToken(i+1)
		i:+2
	Until  i >= params.added - 1
	Return params.GetToken(i)
End Function

Function SEFN_Eq:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local first:SToken = params.GetToken(0)
	If params.added = 3 Then Return New SToken( TK_BOOLEAN, params.GetToken(1).CompareWith(params.GetToken(2)) = 0, first.linenum, first.linepos )
	If params.added = 5
		If params.GetToken(1).CompareWith(params.GetToken(2)) = 0
			Return params.GetToken(3)
		Else
			Return params.GetToken(4)
		EndIf
	EndIf
	Return New SToken( TK_ERROR, "2 or 4 parameters expected", first )
End Function

Function SEFN_NEq:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local first:SToken = params.GetToken(0)
	If params.added = 3 Then Return New SToken( TK_BOOLEAN, params.GetToken(1).CompareWith(params.GetToken(2)) <> 0, first.linenum, first.linepos )
	If params.added = 5
		If params.GetToken(1).CompareWith(params.GetToken(2)) <> 0
			Return params.GetToken(3)
		Else
			Return params.GetToken(4)
		EndIf
	EndIf
	Return New SToken( TK_ERROR, "2 or 4 parameters expected", first )
End Function

Function SEFN_Gt:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local first:SToken = params.GetToken(0)
	If params.added = 3 Then Return New SToken( TK_BOOLEAN, params.GetToken(1).CompareWith(params.GetToken(2)) > 0, first.linenum, first.linepos )
	If params.added = 5
		If params.GetToken(1).CompareWith(params.GetToken(2)) > 0
			Return params.GetToken(3)
		Else
			Return params.GetToken(4)
		EndIf
	EndIf
	Return New SToken( TK_ERROR, "2 or 4 parameters expected", first )
End Function

Function SEFN_Gte:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local first:SToken = params.GetToken(0)
	If params.added = 3 Then Return New SToken( TK_BOOLEAN, params.GetToken(1).CompareWith(params.GetToken(2)) => 0, first.linenum, first.linepos )
	If params.added = 5
		If params.GetToken(1).CompareWith(params.GetToken(2)) => 0
			Return params.GetToken(3)
		Else
			Return params.GetToken(4)
		EndIf
	EndIf
	Return New SToken( TK_ERROR, "2 or 4 parameters expected", first )
End Function

Function SEFN_Lt:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local first:SToken = params.GetToken(0)
	If params.added = 3 Then Return New SToken( TK_BOOLEAN, params.GetToken(1).CompareWith(params.GetToken(2)) < 0, first.linenum, first.linepos )
	If params.added = 5
		If params.GetToken(1).CompareWith(params.GetToken(2)) < 0
			Return params.GetToken(3)
		Else
			Return params.GetToken(4)
		EndIf
	EndIf
	Return New SToken( TK_ERROR, "2 or 4 parameters expected", first )
End Function

Function SEFN_Lte:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local first:SToken = params.GetToken(0)
	If params.added = 3 Then Return New SToken( TK_BOOLEAN, params.GetToken(1).CompareWith(params.GetToken(2)) <= 0, first.linenum, first.linepos )
	If params.added = 5
		If params.GetToken(1).CompareWith(params.GetToken(2)) <= 0
			Return params.GetToken(3)
		Else
			Return params.GetToken(4)
		EndIf
	EndIf
	Return New SToken( TK_ERROR, "2 or 4 parameters expected", first )
End Function

Function SEFN_Concat:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	'DebugStop
	Local first:SToken = params.GetToken(0)
	Local result:String
	
	For Local n:Int = 1 Until params.added
		result :+ params.getToken(n).value
	Next
		
	Return New SToken( TK_TEXT, result, first.linenum, first.linepos )
End Function


Function SEFN_UCFirst:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	Local value:String = params.GetToken(1).GetValueText()
	Return New SToken( TK_Text, StringHelper.UCFirst(value), params.GetToken(0) )
End Function


Function SEFN_Csv:SToken(params:STokenGroup Var, context:SScriptExpressionContext var)
	If params.added <= 1 
		Return New SToken( TK_ERROR, "No CSV-Entries passed", params.GetToken(0) )
	EndIf

	Local values:TStringBuilder
	Local index:Int
	Local separator:String = ";"
	Local doTrim:Int = True

	If params.added >= 5
		local token:SToken = params.GetToken(4)
		doTrim = TScriptExpression._IsTrueValue( token )
	EndIf
	If params.added >= 4
		separator = String(params.GetToken(3).GetValueText())
	EndIf
	If params.added >= 3
		index = Int(params.GetToken(2).GetValueLong())
	EndIf

	If doTrim
		'SB's trim() avoids new string creation, so prefer it over string.trim()
		values = New TStringBuilder(params.GetToken(1).GetValueText()).Trim()
	Else
		values = New TStringBuilder(params.GetToken(1).GetValueText())
	EndIf

	Local splitBuffer:TSplitBuffer = values.Split(separator)
	If splitBuffer.Length() <= index
		Return New SToken( TK_ERROR, "CSV-Index too big (" + index + " passed, " + (splitBuffer.Length()+1) + " allowed)", params.GetToken(0) )
	Else
		Return New SToken( TK_Text, splitBuffer.Text(index), params.GetToken(0) )
	EndIf
End Function


' Register the functions
' The two numbers are minimum and maximum number of allowed parameters
TScriptExpression.RegisterFunctionHandler( "not", SEFN_Not, 1, -1)
TScriptExpression.RegisterFunctionHandler( "and", SEFN_And, 1, -1)
TScriptExpression.RegisterFunctionHandler( "or",  SEFN_Or,  1, -1)
TScriptExpression.RegisterFunctionHandler( "if",  SEFN_If,  1,  3)

'.select:key:case1:result1:...:casen:resultn:defaultresult
'-> if key == casei then return resulti
'one case and default result required
TScriptExpression.RegisterFunctionHandler( "select", SEFN_Select,  4,  -1)

'2 or 4 parameters
'.cmp:x:y -> result of comparison
'.cmp:x:y:a:b is short for .if:${.cmp:x:y}:a:b
TScriptExpression.RegisterFunctionHandler( "neq", SEFN_NEq, 2, 4)
TScriptExpression.RegisterFunctionHandler( "eq",  SEFN_Eq,  2, 4)
TScriptExpression.RegisterFunctionHandler( "gt",  SEFN_Gt,  2, 4)
TScriptExpression.RegisterFunctionHandler( "gte", SEFN_Gte, 2, 4)
TScriptExpression.RegisterFunctionHandler( "lt",  SEFN_Lt,  2, 4)
TScriptExpression.RegisterFunctionHandler( "lte", SEFN_Lte, 2, 4)

TScriptExpression.RegisterFunctionHandler( "concat", SEFN_Concat, 2,  2)
TScriptExpression.RegisterFunctionHandler( "ucfirst", SEFN_UCFirst, 1,  1)
TScriptExpression.RegisterFunctionHandler( "csv", SEFN_Csv, 2,  3)

' Boolean operators
TScriptExpression.RegisterFunctionHandler( "==", SEFN_Eq,  2, 2)
TScriptExpression.RegisterFunctionHandler( ">",  SEFN_Gt,  2, 2)
TScriptExpression.RegisterFunctionHandler( ">=", SEFN_Gte, 2, 2)
TScriptExpression.RegisterFunctionHandler( "<",  SEFN_Lt,  2, 2)
TScriptExpression.RegisterFunctionHandler( "<=", SEFN_Lte, 2, 2)
TScriptExpression.RegisterFunctionHandler( "<>", SEFN_NEq, 2, 2)
' ASSIGNMENT - Reserved for future expansion
'TScriptExpression.RegisterFunctionHandler( "=", SEFN_SetVariable,  2, 2)
