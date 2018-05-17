Rem
	====================================================================
	Simple Conditional Script Evaluator
	====================================================================

	Class allowing to evaluate given conditional expressions.

	Using a callback-function (or extending the type) allows to handle
	variable names.

	Example: "(MyVar > 0 && MyOtherVar <= 0) || (MyLastVar > 100)"


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
End Rem
SuperStrict

Import Brl.StandardIO
Import Brl.Retro

'based on the approach described at
'http://www.strchr.com/expression_evaluator (author: Peter Kankowski)
'
Type TScriptExpression
	global _expression:string
	global _expressionIndex:int = 0
	global _errorCount:int = 0
	global _lastCommandErrored:int = False
	global _error:string = ""
	global _variableHandler:string(variable:string, params:string[], resultType:int var)

	global _instance:TScriptExpression

	Const ELEMENTTYPE_NONE:int = 0
	Const ELEMENTTYPE_NUMERIC:int = 1
	Const ELEMENTTYPE_STRING:int = 2
	Const ELEMENTTYPE_VARIABLE:int = 3
	Const ELEMENTTYPE_OBJECT:int = 4


	Function GetInstance:TScriptExpression()
		if not _instance then _instance = new TScriptExpression
		return _instance
	End Function


	Method Eval:int(expression:string, variableHandler:string(variable:string, params:string[], resultType:int var) = null)
		_expression = expression
		_expressionIndex = 0
		_errorCount = 0
		_error = ""
		_variableHandler = variableHandler

		return ParseConnectors()
	End Method


	Method EvalString:string(expression:string)
		local expressionResultType:int
		local paramsStart:int = expression.Find("(")
		if paramsStart >= 0
			local payload:string = expression[paramsStart+1 .. ]
			payload = payload[.. payload.Find(")")]
			local params:string[] = payload.Split(",")
			local functionName:string = expression[.. paramsStart]
			'print " - found function: "+functionname+"  params: ~q" + ",".join(params)+"~q  payload: ~q"+payload+"~q"
			return string(GetScriptExpression().HandleFunction(functionName, params, expressionResultType))
		else
			return string(GetScriptExpression().HandleVariable(expression, expressionResultType))
		endif
	End Method


	'check for "&&" and "||" connected conditions
	Method ParseConnectors:int()
		local cond1:int = ParseConditionals()

		While True
			SkipSpaces()
			local op:string = GetCurrentChar()

			if (op <> "&" and op <> "|")
				return cond1
			endif

			op :+ GetCharAtPos( _expressionIndex + 1)
			if op <> "&&" and op <> "||"
				_errorCount :+ 1
				_error = "Incorrect operator ~q"+op+"~q. Valid are ~q&&~q and ~q||~q."
				return False
			endif
			'next token
			_expressionIndex :+ 2


			local cond2:int = ParseConditionals()
			if op = "&&"
				cond1 = cond1 and cond2
			else ' op = "|"
				cond1 = cond1 or cond2
			endif
		Wend

		'level :- 1
	End Method


	'check for conditionals (a ">, >=, <, <=, =" b)
	Method ParseConditionals:int()
		local elementType1:int = 0
		local element1:object = object(ParseElement(elementType1))
		'print "e1: " + string(element1)
		While True
			SkipSpaces()

			'Save the operation
			local op:string = GetCurrentChar()
			if (op <> ">" and op <> "<" and op <> "=")
				'print "op: n.a."
				return (element1 <> null)
			endif
			_expressionIndex :+ 1
			'>= and <=
			if GetCharAtPos(_expressionIndex) = "="
				op :+ "="
				_expressionIndex :+ 1
			'<>
			elseif GetCharAtPos(_expressionIndex) = ">"
				op :+ ">"
				_expressionIndex :+ 1
			endif
			'print "op: "+op

			if op <> ">=" and op <> "=>" and op <> "=<" and op <> "<=" and op <> "=" and op <> ">" and op <> "<" and op <> "<>"
				_errorCount :+ 1
				_error :+ "Incorrect conditional ~q"+op+"~q. Valid are ~q>=~q, ~q<=q, ~q=~q, ~q>~q and ~q<~q.~n"
				return False
			endif


			local elementType2:int = 0
			local element2:object = object(ParseElement(elementType2))
			'print "e2: " + string(element2)

			'apply saved operation

			'if at least one is a string, use string comparison
			if elementType1 = ELEMENTTYPE_STRING or elementType2 = ELEMENTTYPE_STRING
				Select op
					case ">=", "=>"
						return string(element1) >= string(element2)
					case ">"
						return string(element1) >  string(element2)
					case "<=", "=<"
						return string(element1) <= string(element2)
					case "<"
						return string(element1) <  string(element2)
					case "<>"
						return string(element1) <>  string(element2)
					case "="
						return (string(element1) =  string(element2))
				End Select

			'both not "strings", so check if both are numeric
			elseif elementType1 = ELEMENTTYPE_NUMERIC and elementType2 = ELEMENTTYPE_NUMERIC
				Select op
					case ">=", "=>"
						return double(string(element1)) >= double(string(element2))
					case ">"
						return double(string(element1)) >  double(string(element2))
					case "<=", "=<"
						return double(string(element1)) <= double(string(element2))
					case "<"
						return double(string(element1)) <  double(string(element2))
					case "<>"
						return double(string(element1)) <>  double(string(element2))
					case "="
						return double(string(element1)) =  double(string(element2))
				End Select

			'object comparison
			else
				Select op
					case "<>"
						return element1 <> element2
					case "="
						return element1 =  element2
				End Select
			endif
		Wend
	End Method


	'parse single element or an expression within brackets
	Method ParseElement:string(elementType:int var)
		SkipSpaces()

		'opened an string
		if GetCurrentChar() = "'"
			_expressionIndex :+1
			local variable:string = ""
			local escapeNext:int = False
			local char:string = GetCurrentChar()
			while char <> "" and (char <> "'" or escapeNext)
				if char = "\"
					if not escapeNext
						escapeNext = true

						_expressionIndex :+1
						char = GetCurrentChar()
						continue
					endif
				else
					escapeNext = false
				endif

				variable :+ char
				_expressionIndex :+1
				char = GetCurrentChar()
			wend
			 'eat the "'" sign
			_expressionIndex :+1

			elementType = ELEMENTTYPE_STRING
			'print "string: ~q"+ variable+"~q"
			return variable
		endif


		'starting bracket - parse for contained expression/element
		if GetCurrentChar() = "("
			_expressionIndex :+ 1
			local res:int = ParseConnectors()
			if GetCurrentChar() <> ")"
				_errorCount :+ 1
				_error :+ "Unmatched bracket. Make sure to close with ~q)~q.~n"
				return -1
			else
				'skip ending bracket
				_expressionIndex :+1
			endif
			return int(res)
		endif

		'extract variables / "functions"
		if IsAlpha( GetCurrentCharCode() ) or GetCurrentChar() = "_"
			local openBracket:int = false
			local variable:string = ""
			local char:string
			local charCode:int
			local validChar:int = True
			while validChar
				char = GetCurrentChar()
				if char = "" then exit

				charCode = GetCurrentCharcode()

				'outside of a function() only "a-z0-9_(" are allowed
				if not openBracket
					if not (IsDigit(charCode) or IsAlpha(charCode) or char="_" or char="(")
						exit
					endif
				endif

				if char = "("
					openBracket = true
				elseif char = ")"
					openBracket = false
				'ignore spaces within the function bracket
				elseif openBracket and IsSpace(charCode)
					_expressionIndex :+ 1
					continue
				endif
				variable :+ char
				_expressionIndex :+ 1
			wend
			'elementType = ELEMENTTYPE_VARIABLE
			local res:string
			local variableParts:string[] = variable.split("(")
			if variableParts.length > 1
				local functionName:string = variableParts[0]
				local functionParams:string[] = null

				local p:string[] = variableParts[1].Split(")")
				functionParams = p[0].Split(",")
				for local i:int = 0 until functionParams.length
					functionParams[i] = functionParams[i].trim()
					if functionParams[i].length = 0 then continue

					local escapeNextC:int = False
					local newValue:string
					for local cIndex:int = 0 until functionParams[i].length
						local c:string = chr(functionParams[i][cIndex])
						if c = "'" and not escapeNextC
							continue
						endif
						if c = "\"
							if not escapeNextC
								escapeNextC = True
								continue
							endif
						else
							escapeNextC = false
						endif

						newValue :+ c
					next
					'print "old: ~q"+ functionParams[i]+"~q   new: ~q"+newValue+"~q"
					functionParams[i] = newValue
				Next



				res = HandleFunction(functionName, functionParams, elementType)
				'print "function(): ~q" + functionName + "~q with params ~q" + ",".Join(functionParams) + "~q  (result=" + res+")"
			else
				res = HandleVariable(variableParts[0], elementType)
				'print "variable: ~q" + variableParts[0] + "~q  (result=" + res+")"
			endif

			return res
		endif


		'extract integer
		if IsDigit( GetCurrentCharCode() )
			local variable:string = ""
			while IsDigit(GetCurrentCharCode())
				variable :+ GetCurrentChar()
				_expressionIndex :+ 1
			wend
			elementType = ELEMENTTYPE_NUMERIC
			'print "numeric: "+ variable
			return variable
		endif

		_errorCount :+ 1
		_error :+ "Invalid characters used. Allowed: alphanumeric characters, brackets, comparators (<, >, =, >=, <=) and connectors (&&, ||).~n"

		return -1
	End Method


	'=== HELPER FUNCTIONS ===

	Function GetCurrentChar:string()
		if _expressionIndex < _expression.length
			return chr(_expression[_expressionIndex])
		else
			return ""
		endif
	End Function


	Function GetCurrentCharCode:int()
		if _expressionIndex < _expression.length
			return _expression[_expressionIndex]
		else
			return -1
		endif
	End Function


	Function GetCharAtPos:string(position:int)
		if position < _expression.length
			return chr(_expression[position])
		else
			return ""
		endif
	End Function


	Function SkipSpaces()
		'skip spaces
		While IsSpace( GetCurrentCharCode() )
			_expressionIndex :+1
		Wend
	End Function


	Function IsSpace:Int( ch:Int )
		'systemchars or space or non-breaking-space
		Return ch >= 0 and (ch <= Asc(" ") Or ch=$A0)
	End Function


	Function IsDigit:Int( ch:Int )
		Return ch >= Asc("0") And ch <= Asc("9")
	End Function


	Function IsAlpha:Int( ch:Int )
		Return (ch >= Asc("A") And ch <= Asc("Z")) Or (ch >= Asc("a") And ch <= Asc("z"))
	End Function


	Method HandleVariable:string(variable:string, resultType:int var)
		_lastCommandErrored = False
		if _variableHandler then return _variableHandler(variable, null, resultType)

		_errorCount :+1
		_error :+ "Cannot handle variable ~q"+variable+"~q. Defaulting to 0.~n"
		_lastCommandErrored = True
		'print _error

		return "0"
	End Method


	Method HandleFunction:string(variable:string, params:string[], resultType:int var)
		_lastCommandErrored = False
		if _variableHandler then return _variableHandler(variable, params, resultType)

		_errorCount :+1
		_error :+ "Cannot handle function ~q"+variable+"~q with params ~q" + ",".Join(params) +"~q. Defaulting to 0.~n"
		_lastCommandErrored = True
		'print _error

		return "0"
	End Method


	Method IsValid:int(expression:string)
		Eval(expression)
		return _errorCount = 0
	End Method
End Type


Function GetScriptExpression:TScriptExpression()
	return TScriptExpression.GetInstance()
End Function




Function ReplaceTextWithScriptExpression:int(text:string, replacement:string var)
	local expressionResult:string = GetScriptExpression().EvalString(text)

	'found something valid?
	if TScriptExpression._lastCommandErrored
		replacement = TScriptExpression._error
		return False
	else
		replacement = expressionResult
		return True
	endif
End Function