SuperStrict
Import "Dig/base.util.scriptexpression_ng.bmx"

Global _GameScriptExpression:TGameScriptExpressionBase = New TGameScriptExpressionBase

Function GetGameScriptExpression:TGameScriptExpressionBase()
	Return _GameScriptExpression
End Function


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
