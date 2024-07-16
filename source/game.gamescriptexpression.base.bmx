SuperStrict
Import "Dig/base.util.scriptexpression.bmx"
Import Brl.Map

'initialize on import
GetGameScriptExpressionOLD()

Type TGameScriptExpressionOLD extends TScriptExpressionOLD
	Global variableHandlers:TMap = CreateMap()


	Function GetInstance:TGameScriptExpressionOLD()
		if not _instance
			_instance = new TGameScriptExpressionOLD
		'if the instance was created, but was a "base" one, create
		'a new and take over the values
		elseif not TGameScriptExpressionOLD(_instance)
			local newInstance:TGameScriptExpressionOLD = new TGameScriptExpressionOLD
			'newInstance.XX = _instance.XX
			_instance = newInstance
		endif
		return TGameScriptExpressionOLD(_instance)
	End Function


	Function RegisterHandler(variable:string, handler:string(variable:string, params:string[], resultElementType:int var))
		variableHandlers.insert(variable.toLower(), TGameScriptExpressionOLDFunctionWrapper.Create(handler))
	End Function

rem
	Function RunHandler:int(variable:string, params:string[], resultElementType:int var)
		local wrapper:GameScriptExpressionFunctionWrapper = GameScriptExpressionFunctionWrapper(variableHandlers.ValueForKey(variable.ToLower()))
		if wrapper then return wrapper.func(variable, params, resultElementType)
	End Function
endrem

	'override
	Method HandleVariable:string(variable:string, resultElementType:int var)
		local wrapper:TGameScriptExpressionOLDFunctionWrapper = TGameScriptExpressionOLDFunctionWrapper(variableHandlers.ValueForKey(variable.ToLower()))
		if wrapper
			_lastCommandErrored = False
			return wrapper.func(variable, null, resultElementType)
		else
			_errorCount :+1
			_error :+ "Cannot handle variable ~q"+variable+"~q. Defaulting to 0.~n"
			_lastCommandErrored = True
			'print _error

			return "0"
		endif
	End Method


	'override
	Method HandleFunction:string(variable:string, params:string[], resultElementType:int var)
		local wrapper:TGameScriptExpressionOLDFunctionWrapper = TGameScriptExpressionOLDFunctionWrapper(variableHandlers.ValueForKey(variable.ToLower()))
		if wrapper
			_lastCommandErrored = False
			return wrapper.func(variable, params, resultElementType)
		else
			_errorCount :+1
			_error :+ "Cannot handle function ~q"+variable+"~q. Defaulting to 0.~n"
			_lastCommandErrored = True
			'print _error

			return "0"
		endif
	End Method
End Type


Type TGameScriptExpressionOLDFunctionWrapper
	Field func:string(variable:string, params:string[], resultElementType:int var)

	Function Create:TGameScriptExpressionOLDFunctionWrapper(func:string(variable:string, params:string[], resultElementType:int var))
		local obj:TGameScriptExpressionOLDFunctionWrapper = new TGameScriptExpressionOLDFunctionWrapper
		obj.func = func
		return obj
	End Function
End Type


Function GetGameScriptExpressionOLD:TGameScriptExpressionOLD()
	return TGameScriptExpressionOLD.GetInstance()
End Function
