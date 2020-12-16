SuperStrict
Import Brl.Clipboard


'default clipboard (eg to share app-internal or with system)
Global clipboard:TDigClipboard = new TDigClipboard


Type TDigClipboard
	Field data:object
	Field source:object
	Field isUsed:Int
	
	' create a clipboard manager to access the system wide clipboard
	Global OSclipboard:TClipboard = CreateClipboard()


	Function GetOSClipboard:String()
		Return OSclipboard.Text()
	End Function


	Function SetOSClipboard:String(value:String)
		Return OSclipboard.SetText(value)
	End Function
	
	
	Method New(data:object, source:object)
		self.data = data
		self.source = source
		self.isUsed = True
	End Method
	
	
	Method GetSource:object()
		return source
	End Method
	
	
	Method Get:Object()
		Return data
	End Method
	
	
	Method Set(data:Object)
		self.data = data
		If data
			self.isUsed = True
		Else
			self.isUsed = False
		EndIf
	End Method
	
	
	Method SetSource(source:Object)
		self.source = source
	End Method
	
	
	Method Clear()
		isUsed = False
		source = Null
		data = Null
	End Method
End Type


Function SetOSClipboard(value:String)
	clipboard.SetOSClipboard(value)
End Function

Function GetOSClipboard:String()
	Return clipboard.GetOSClipboard()
End Function

Function SetAppClipboard(value:object, source:object)
	clipboard.Set(value)
	clipboard.SetSource(source)
End Function

Function GetAppClipboard:Object()
	Return clipboard.Get()
End Function

Function GetAppClipboardSource:Object()
	clipboard.GetSource()
End Function

Function ClearAppClipboard()
	clipboard.Clear()
End Function

Function IsAppClipboardUsed()
	clipboard.isUsed = True
End Function
