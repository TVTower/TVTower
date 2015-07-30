SuperStrict
Import "Dig/base.util.scriptexpression.bmx"
Import Brl.Map


Type GameScriptExpression extends ScriptExpression
	Global variableHandlers:TMap = CreateMap()


	Function RegisterHandler(variable:string, handler:int(variable:string, params:string[]))
		variableHandlers.insert(variable.toLower(), GameScriptExpressionFunctionWrapper.Create(handler))
	End Function


	Function RunHandler:int(variable:string, params:string[])
		local wrapper:GameScriptExpressionFunctionWrapper = GameScriptExpressionFunctionWrapper(variableHandlers.ValueForKey(variable))
		if wrapper then return wrapper.func(variable, params)
	End Function


	'override
	Function HandleVariable:int(variable:string)
		'split function and params
		if variable.Find("(")
			... 
		endif
			
	
		local wrapper:GameScriptExpressionFunctionWrapper = GameScriptExpressionFunctionWrapper(variableHandlers.ValueForKey(variable))
		if wrapper
			return wrapper.func(variable, params)
		else
			_errorCount :+1
			_error = "Cannot handle variable ~q"+variable+"~q. Defaulting to 0."
			print _error
			return 0
		endif
	End Function
End Type


Type GameScriptExpressionFunctionWrapper
	Field func:int(variable:string, params:string[])

	Function Create:GameScriptExpressionFunctionWrapper(func:int(variable:string, params:string[]))
		local obj:GameScriptExpressionFunctionWrapper = new GameScriptExpressionFunctionWrapper
		obj.func = func
		return obj
	End Function
End Type