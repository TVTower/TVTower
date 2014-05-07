Type TTVTException Extends TBlitzException
	Field message:String


	Method ToString:String()
		If message = Null
			Return GetDefaultMessage()
		Else
			Return message
		EndIf
	End Method


	Method GetDefaultMessage:String()
		Return "Undefined TTVTException!"
	End Method
End Type




Type TArgumentException Extends TTVTException
	Field argument:String
	Field value:String


	Method ToString:String()
		If argument = Null
			Super.ToString()
		Else
			If value = Null
				Return "The argument '" + argument + "' is not valid."
			Else
				Return "The argument '" + argument + "' with value '" + value + "' is not valid."
			EndIf
		EndIf
	End Method


	Method GetDefaultMessage:String()
		Return "An argument is not valid."
	End Method


	Function Create:TArgumentException( argument:String, value:String = null, message:String = Null )
		Local t:TArgumentException = New TArgumentException
		t.argument = argument
		t.value = value
		t.message = message
		Return t
	End Function
End Type



Type TNullObjectExceptionExt Extends TTVTException
	Function Create:TNullObjectExceptionExt( message:String = Null )
		Local t:TNullObjectExceptionExt = New TNullObjectExceptionExt
		t.message = message
		Return t
	End Function
End Type