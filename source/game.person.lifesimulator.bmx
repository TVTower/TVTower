SuperStrict

Import "person.base.bmx"

Type TPersonBase
	Field job:Int
End Type


Type TPersonJob
	Const ACTOR ...
	Const SUPPORTINGACTOR ...
	Const MUSICIAN
	
	
	Const ARTIST:Int = 128
	Const SPORTSMEN:Int = 256
	Const POLITICIAN:Int = 512
End Type



Type TPersonLife
	Field person:TPersonBase
End Type


Type TPersonBase Extends TPersonBase
	Field producedGUIDs ...
End Type





Type TPersonSimulator
	'musicians: tours, new albums, ...
	'sportsmen: becoming sports show hosts later on?
	'politicians: talk show guests?
	Field lifes:TPersonLife[]
	Field personsIDs:TIntMap = New TIntMap

	Field musicianCount:Int = -1
	Field sportsmenCount:Int = -1
	Field politiciansCount:Int = -1
	Global simulatedJobs:Int[]
	
	
	Method IsSimulatedPerson:Int(p:TPersonBase)
		Return persons.Contains(p.GetID())
	End Method
	
	
	Method AddPerson:Int(p:TPersonBase)
		If IsSimulatedPerson(p) Return False

		personsIDs.Insert(p.GetID(), Null)
		Return True
	End Method


	Method RemovePerson:Int(p:TPersonBase)
		If Not IsSimulatedPerson(p) Return False

		personsIDs.Remove(p.GetID())
		Return True
	End Method


	
	Method Update:Int()
		'ensure enough of each group are simulated
		For Local i:Int = EachIn simulatedJobs
		GeTPersonBaseCollection().GetRandom(jobID)

		'update life simulation of the individuals
		
		
		
		'create random events?
		'- scandals
		'- births (check age of person first)
	End Method
End Type