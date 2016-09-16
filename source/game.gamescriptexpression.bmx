SuperStrict
Import "Dig/base.util.scriptexpression.bmx"
Import Brl.Map


Type TGameScriptExpression extends TScriptExpression
	Global variableHandlers:TMap = CreateMap()


	Function RegisterHandler(variable:string, handler:string(variable:string, params:string[], resultElementType:int var))
		variableHandlers.insert(variable.toLower(), TGameScriptExpressionFunctionWrapper.Create(handler))
	End Function

rem
	Function RunHandler:int(variable:string, params:string[], resultElementType:int var)
		local wrapper:GameScriptExpressionFunctionWrapper = GameScriptExpressionFunctionWrapper(variableHandlers.ValueForKey(variable.ToLower()))
		if wrapper then return wrapper.func(variable, params, resultElementType)
	End Function
endrem

	'override
	Method HandleVariable:string(variable:string, resultElementType:int var)
		local wrapper:TGameScriptExpressionFunctionWrapper = TGameScriptExpressionFunctionWrapper(variableHandlers.ValueForKey(variable.ToLower()))
		if wrapper
			return wrapper.func(variable, null, resultElementType)
		else
			_errorCount :+1
			_error = "Cannot handle variable ~q"+variable+"~q. Defaulting to 0."
			print _error

			return "0"
		endif
	End Method


	'override
	Method HandleFunction:string(variable:string, params:string[], resultElementType:int var)
		local wrapper:TGameScriptExpressionFunctionWrapper = TGameScriptExpressionFunctionWrapper(variableHandlers.ValueForKey(variable))
		if wrapper
			return wrapper.func(variable, params, resultElementType)
		else
			_errorCount :+1
			_error = "Cannot handle function ~q"+variable+"~q. Defaulting to 0."
			print _error

			return "0"
		endif
	End Method
End Type


Type TGameScriptExpressionFunctionWrapper
	Field func:string(variable:string, params:string[], resultElementType:int var)

	Function Create:TGameScriptExpressionFunctionWrapper(func:string(variable:string, params:string[], resultElementType:int var))
		local obj:TGameScriptExpressionFunctionWrapper = new TGameScriptExpressionFunctionWrapper
		obj.func = func
		return obj
	End Function
End Type


Global GameScriptExpression:TGameScriptExpression = new TGameScriptExpression