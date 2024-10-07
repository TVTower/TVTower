SuperStrict
Import "Dig/base.util.scriptexpression.bmx"
Import "Dig/base.util.scriptexpression_ng.bmx"

Import "game.production.scripttemplate.bmx"
Import "game.stationmap.bmx"

Import Brl.Map


Global GameScriptExpression:TGameScriptExpressionBase = New TGameScriptExpressionBase

Type TGameScriptExpressionBase extends TScriptExpression
	Method New()
		'set custom config for variable handlers etc
		'self.config = New TScriptExpressionConfig(null, null, null )
		self.config.s.variableHandlerCB = TGameScriptExpressionBase.GameScriptVariableHandlerCB
	End Method
	
	
	Method ParseLocalizedText:TStringBuilder(text:String, context:SScriptExpressionContext)
		Return ParseNestedExpressionText(text, context)
	End Method

	Method ParseLocalizedText:TStringBuilder(text:TStringBuilder, context:SScriptExpressionContext)
		Return ParseNestedExpressionText(text, context)
	End Method

	Function GameScriptVariableHandlerCB:String(variable:String, context:SScriptExpressionContext var)
		Return "([ERROR] unhandled variable ~q" + variable+"~q)"
	End Function
End Type







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
	Method HandleVariable:string(variable:string, resultElementType:int var) override
		local wrapper:TGameScriptExpressionOLDFunctionWrapper = TGameScriptExpressionOLDFunctionWrapper(variableHandlers.ValueForKey(variable.ToLower()))
		if wrapper
			_lastCommandErrored = False
			return wrapper.func(variable, null, resultElementType)
		else
			_errorCount :+1
			_error.Append("Cannot handle variable ~q")
			_error.Append(variable)
			_error.Append("~q. Defaulting to 0.~n")
			_lastCommandErrored = True
			'print _error

			return "0"
		endif
	End Method


	'override
	Method HandleFunction:string(variable:string, params:string[], resultElementType:int var) override
		local wrapper:TGameScriptExpressionOLDFunctionWrapper = TGameScriptExpressionOLDFunctionWrapper(variableHandlers.ValueForKey(variable.ToLower()))
		if wrapper
			_lastCommandErrored = False
			return wrapper.func(variable, params, resultElementType)
		else
			_errorCount :+1
			_error.Append("Cannot handle function ~q")
			_error.Append(variable)
			_error.Append("~q. Defaulting to 0.~n")
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
