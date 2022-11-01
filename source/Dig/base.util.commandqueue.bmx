SuperStrict
Framework Brl.StandardIO
Import Brl.Threads
Import Brl.ObjectList


Enum ECommandStatus
	OPEN     ' not yet run
	RUNNING  ' currently running
	FINISHED ' finished execution
End Enum


Struct SCommandResult
	Field status:Int
	Field data:object
	
	Method New(status:Int, data:object = Null)
		self.status = status
		self.data = data
	End Method
End Struct


Type TCommand
	Field status:ECommandStatus
	Field payload:object[]
	Field semaphore:TSemaphore
	Field runCallback(payload:object[])
	Field resultCallback(result:SCommandResult)
	

	Method New()
		self.status = ECommandStatus.OPEN
	End Method

	Method New(payload:object[], resultCallback(result:SCommandResult) = Null)
		self.status = ECommandStatus.OPEN
		self.resultCallback = resultCallback
	End Method

	Method New(payload:object[], runCallback(payload:object[]), resultCallback(result:SCommandResult) = Null)
		self.status = ECommandStatus.OPEN
		self.payload = payload
		self.runCallback = runCallback
		self.resultCallback = resultCallback
	End Method
	

	'the customizable element any TCommand-extension should individualize
	Method CustomRun()
	End Method

	
	Method Run:SCommandResult()
		Local result:SCommandResult
		self.status = ECommandStatus.RUNNING
		
		'TODO: have pool and reuse semaphores? 
		self.semaphore = CreateSemaphore(1)
		self.semaphore.Post()

		'execute a callback if defined
		if self.runCallback Then self.runCallback(payload)
		'execute a customized method (individualized in extending types)
		CustomRun()

		self.status = ECommandStatus.FINISHED

		'inform potentially interested callback (eg an "onDidSomething()")
		if self.resultCallback then self.resultCallback(result)
		Return result
	End Method
	
	
	Method WaitTillFinished:Int(timeOut:int = -1)
		If self.status = ECommandStatus.FINISHED Then Return True

		'semaphore version
		If not self.semaphore Then Return False
		self.semaphore.TimedWait(timeOut)

		'simple "delay" version
		'Local now:Int = Millisecs()
		'Repeat
		'	Delay(1)
		'Until self.status = ECommandStatus.FINISHED or (timeOut > 0 and Millisecs() > now + timeOut)

		Return True
	End Method

	
	Method Serialize:String()
		'enum to String etc
	End Method
End Type




Type TCommandQueue
	'storage for all "to run" commands
	Field enqueuedCommands:TObjectList = new TObjectList
	'storage for commands while iterating over it (not blocking adding
	'to the normal storage)
	Field _enqueuedCommandsCopy:TObjectList = new TObjectList
	Field listMutex:TMutex = CreateMutex()
	
	Method Add(c:TCommand)
		LockMutex(listMutex)
		enqueuedCommands.AddLast(c)
		UnlockMutex(listMutex)
	End Method

	'processes all enqueued commands
	Method Process:Int()
		'this - or assigning a thread and comparing against it
		'which would allow to have command queues in specific child 
		'threads too
		'If CurrentThread() <> MainThread() 
		'	Throw "Only run TCommandQueue.Process from MainThread"
		'EndIf
		
		LockMutex(listMutex)
		'copy queue so we can clear it right here ...
		'allowing other threads to enqueue new commands while
		'we process the current ones
		Local queueSize:Int = enqueuedCommands.Count() 'compacts array inside
		If queueSize = 0
			UnlockMutex(listMutex)
		Else
			'copy current command list into our working list to iterate
			'over, then clear the command list so it is ready to
			'retrieve new ones
			_enqueuedCommandsCopy.Clear()
			'from "TObjectList.Copy()"
			enqueuedCommands.Compact()
			For Local i:Int = 0 Until enqueuedCommands.size
				_enqueuedCommandsCopy.AddLast(enqueuedCommands.data[i])
			Next
			enqueuedCommands.clear()
			
			'now other threads could already add new commands
			UnlockMutex(listMutex)

			'actually start processing the commands
			For local c:TCommand = EachIn _enqueuedCommandsCopy
				c.Run()
			Next
		Endif

		Return queueSize
	End Method
End Type
