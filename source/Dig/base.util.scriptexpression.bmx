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
Type ScriptExpression
	global _expression:string
	global _expressionIndex:int = 0
	global _errorCount:int = 0
	global _error:string = ""
	global _variableHandler:int(variable:string)
	
	Function Eval:int(expression:string, variableHandler:int(variable:string) = null)
		_expression = expression
		_expressionIndex = 0
		_errorCount = 0
		_error = ""
		_variableHandler = variableHandler

		return ParseConnectors()
	End Function


	'check for "&&" and "||" connected conditions
	Function ParseConnectors:Int()
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
	End Function
	

	'check for conditionals (a ">, >=, <, <=, =" b)
	Function ParseConditionals:int()
		local num1:int = ParseElement()

		While True
			SkipSpaces()

			'Save the operation
			local op:string = GetCurrentChar()
			if (op <> ">" and op <> "<" and op <> "=")
				return num1
			endif
			_expressionIndex :+ 1
			'>= and <=
			if GetCharAtPos(_expressionIndex + 1) = "="
				op :+ "="
				_expressionIndex :+ 1
			endif
			
			if op <> ">=" and op <> "<=" and op <> "=" and op <> ">" and op <> "<"
				_errorCount :+ 1
				_error = "Incorrect conditional ~q"+op+"~q. Valid are ~q>=~q, ~q<=q, ~q=~q, ~q>~q and ~q<~q."
				return False
			endif


			local num2:int = ParseElement()
			'apply saved operation
			Select op
				case ">="  return num1 >= num2
				case ">"   return num1 >  num2
				case "<="  return num1 <= num2
				case "<"   return num1 <  num2
				case "="   return num1 =  num2
			End Select
		Wend
	End Function


	'parse single element or an expression within brackets
	Function ParseElement:int()
		SkipSpaces()

		'starting bracket - parse for contained expression/element
		if GetCurrentChar() = "("
			_expressionIndex :+ 1
			local res:int = ParseConnectors()
			if GetCurrentChar() <> ")"
				_errorCount :+ 1
				_error = "Unmatched bracket. Make sure to close with ~q)~q."
				return -1
			else
				'skip ending bracket
				_expressionIndex :+1
			endif
			return int(res)
		endif


		'extract variables / "functions"
		if IsAlpha( GetCurrentCharCode() )
			local variable:string = ""
			local openBracket:int = false
			local char:string
			while GetCurrentChar() <> "" and (openBracket or not IsSpace( GetCurrentCharcode() ))
				char = GetCurrentChar()
				if char = "("
					openBracket = true
				elseif char = ")"
					openBracket = false
				'ignore spaced within the function bracket
				elseif openBracket and IsSpace(Asc(char))
					_expressionIndex :+ 1
					continue
				endif
				variable :+ char
				_expressionIndex :+ 1
			wend
			'print "variable: "+variable + " = " + HandleVariable(variable)

			return HandleVariable(variable)
		endif

		
		'extract integer
		if IsDigit( GetCurrentCharCode() )
			local variable:string = ""
			while IsDigit(GetCurrentCharCode())
				variable :+ GetCurrentChar()
				_expressionIndex :+ 1
			wend
			'print "numeric: "+ variable
			return Int(variable)
		endif

		_errorCount :+ 1
		_error = "Invalid characters used. Allowed: alphanumeric characters, brackets, comparators (<, >, =, >=, <=) and connectors (&&, ||)."

		return -1
	End Function


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


	Function HandleVariable:int(variable:string)
		if _variableHandler then return _variableHandler(variable)

		_errorCount :+1
		_error = "Cannot handle variable ~q"+variable+"~q. Defaulting to 0."
		print _error
		return 0
	End Function


	Function IsValid:int(expression:string)
		Eval(expression)
		return _errorCount = 0
	End Function
End Type
