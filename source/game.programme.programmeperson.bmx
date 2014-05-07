'a person connected to a programme - directors, writers, actors...
Type TProgrammePerson
	field lastName:string	= ""
	field firstName:string	= ""
	field dayOfBirth:string	= "0000-00-00"
	field dayOfDeath:string	= "0000-00-00"
	field job:int			= 0
	field realPerson:int	= FALSE
	field ID:int			= 0

	const JOB_ACTOR:int		= 1
	const JOB_DIRECTOR:int	= 2
	const JOB_WRITER:int	= 4

	Global lastID:int		= 0
	'arrays holding all entries + already filtered (actors, directors, ...)
	'the filtered are lists for easy management, persons is array for fast search access
	Global persons:TProgrammePerson[]
	Global actors:TList		= CreateList()
	Global directors:TList	= CreateList()
	Global writers:TList	= CreateList()


	Method New()
		lastID:+1
		ID = lastID
	End Method


	Function Create:TProgrammePerson(firstName:string, lastName:string, job:int, dayOfBirth:string="", dayOfDeath:string="")
		if dayOfBirth = "" then dayOfBirth = "0000-00-00"
		if dayOfDeath = "" then dayOfDeath = "0000-00-00"

		local person:TProgrammePerson = new TProgrammePerson
		person.firstName	= firstName
		person.lastName		= lastName
		person.dayOfBirth	= dayOfBirth
		person.dayOfDeath	= dayOfDeath
		person.AddJob(job)

		return person
	End Function


	Function Add:int(person:TProgrammePerson)
		'resize if needed - at least to ID+1
		if person.ID > persons.length then persons = persons[..person.ID+1]
		'add to array and corresponding list
		persons[person.ID-1] = person

		return True
	End Function


	Function Get:TProgrammePerson(id:int)
		if id > persons.length or id < 0 then return Null

		return persons[id-1]
	End Function


	Function GetByName:TProgrammePerson(firstName:string, lastName:string)
		firstName = firstName.toLower()
		lastName = lastName.toLower()

		For local person:TProgrammePerson = eachin persons
			if person.firstName.toLower() <> firstName then continue
			if person.lastName.toLower() <> lastName then continue
			return person
		Next
		return Null
	End Function


	Method GetFullName:string()
		if self.lastName<>"" then return self.firstName + " " + self.lastName
		return self.firstName
	End Method


	Method AddJob:int(job:int)
		'already done?
		if self.job & job then return FALSE

		'add job
		self.job :| job

		'add to list
		if job & JOB_ACTOR then actors.AddLast(self)
		if job & JOB_DIRECTOR then directors.AddLast(self)
		if job & JOB_WRITER then writers.AddLast(self)
	End Method
End Type