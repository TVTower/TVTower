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
	Field data:Object
	
	Method New(status:Int, data:Object = Null)
		Self.status = status
		Self.data = data
	End Method
End Struct




Type TCommand
	Field status:ECommandStatus = ECommandStatus.OPEN
	Field payload:Object
	Field runCallback:SCommandResult(payload:Object)
	Field resultCallback(result:SCommandResult)
	Field result:SCommandResult
	Field semaphore:TSemaphore
	

	Method New(runCallback:SCommandResult(payload:Object), payload:Object, resultCallback(result:SCommandResult) = Null)
		Self.payload = payload
		Self.runCallback = runCallback
		Self.resultCallback = resultCallback
	End Method
	

	'the customizable element any TCommand-extension could individualize
	Method CustomRun()
	End Method

	
	Method Run:SCommandResult()
		self.status = ECommandStatus.RUNNING

		'execute a callback if defined
		If Self.runCallback
			result = Self.runCallback(payload)
		EndIf
		
		'execute a customized method (individualized in extending types)
		CustomRun()

		'inform potentially interested callback (eg an "onDidSomething()")
		If Self.resultCallback
			Self.resultCallback(result)
		EndIf

		self.status = ECommandStatus.FINISHED

		Return result
	End Method


	Method IsFinished:Int()
		Return self.status = ECommandStatus.FINISHED
	End Method

	
	Method WaitTillFinished:Int(timeOut:Int = -1)
		If IsFinished() Then Return True

		If Self.semaphore
			Self.semaphore.TimedWait(timeOut)
		EndIf

		Return True
	End Method

	
	Method Serialize:String()
		'enum to String etc
	End Method
End Type




Type TCommandQueue
	Private
	Field activeList:TObjectList = New TObjectList
	Field inactiveList:TObjectList = New TObjectList
	Field listMutex:TMutex = CreateMutex()
	Field count:Int

	Public
	Method Reset()
		LockMutex(listMutex)

		activeList.Clear()
		inactiveList.Clear()
		count = 0

		UnlockMutex(listMutex)
	End Method

	
	Method Run:SCommandResult(c:TCommand, timeOut:Int = 0)
		LockMutex(listMutex)

		activeList.AddLast(c)
		count :+ 1

		'TODO: have pool and reuse semaphores? 
		c.semaphore = CreateSemaphore(0)

		UnlockMutex(listMutex)

		'now wait until the queue processed it
		If timeOut > 0
			c.semaphore.TimedWait(timeOut)
		Else
			c.semaphore.Wait()
		EndIf
		
		Return c.result
	End Method


	Method Run(runCallback:SCommandResult(payload:Object), payLoad:Object, resultCallback(result:SCommandResult) = Null, timeOut:Int = 0)
		Local c:TCommand = New TCommand(runCallback, payLoad, resultCallback)
		Run(c, timeOut)
	End Method



	'add a command but do not wait for execution and results
	Method RunDeferred(c:TCommand)
		LockMutex(listMutex)

		activeList.AddLast(c)
		count :+ 1

		UnlockMutex(listMutex)
	End Method

	
	Method RunDeferred(runCallback:SCommandResult(payload:Object), payLoad:Object, resultCallback(result:SCommandResult) = Null)
		Local c:TCommand = New TCommand(runCallback, payLoad, resultCallback)
		RunDeferred(c)
	EndMethod


	'processes all enqueued commands
	Method Process:Int()
		'this - or assigning a thread and comparing against it
		'which would allow to have command queues in specific child 
		'threads too
		'If CurrentThread() <> MainThread() 
		'	Throw "Only run TCommandQueue.Process from MainThread"
		'EndIf
		
		if count > 0
			LockMutex(listMutex)
			'switch active list so we can clear it right here ...
			'allowing other threads to enqueue new commands while
			'the others are processed here
			Local tmp:TObjectList = inactiveList
			inactiveList = activeList
			activeList = tmp
			count = 0

			'now other threads could already add new commands
			UnlockMutex(listMutex)

			'actually start processing the commands
			Local processedCount:Int
			For Local c:TCommand = EachIn inactiveList
				c.Run()

				'we are done with the command
				If c.semaphore
					c.semaphore.Post()
				EndIf
				
				processedCount :+ 1
			Next

			'done with all of them
			inactiveList.Clear()
			
			Return processedCount
		EndIf

		Return 0
	End Method
End Type
