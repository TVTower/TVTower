SuperStrict
Import Brl.Map
Import Brl.Retro
Import "base.util.mersenne.bmx"


'SeedRand(Millisecs())
GetPersonGenerator().fallbackCountryCode = "de"
GetPersonGenerator().AddProvider( new TPersonGeneratorCountry_Austria )
GetPersonGenerator().AddProvider( new TPersonGeneratorCountry_Germany )
GetPersonGenerator().AddProvider( new TPersonGeneratorCountry_UK )
GetPersonGenerator().AddProvider( new TPersonGeneratorCountry_China	 )
GetPersonGenerator().AddProvider( new TPersonGeneratorCountry_Russia )
GetPersonGenerator().AddProvider( new TPersonGeneratorCountry_Turkey )
GetPersonGenerator().AddProvider( new TPersonGeneratorCountry_USA )
GetPersonGenerator().AddProvider( new TPersonGeneratorCountry_Denmark )
GetPersonGenerator().AddProvider( new TPersonGeneratorCountry_Greek )
GetPersonGenerator().AddProvider( new TPersonGeneratorCountry_Uganda )
GetPersonGenerator().AddProvider( new TPersonGeneratorCountry_Spain )



Type TPersonGenerator
	Field providers:TMap = CreateMap()
	Field baseProvider:TPersonGeneratorCountry = new TPersonGeneratorCountry
	Field fallbackCountryCode:string = ""
	Field protectedNames:TMap = CreateMap()
	Field _countryCodes:string[] {nosave}
	Global _instance:TPersonGenerator = new TPersonGenerator
	Const GENDER_UNDEFINED:int = 0
	Const GENDER_MALE:int = 1
	Const GENDER_FEMALE:int = 2


	Method Initialize:int()
		protectedNames.Clear()
		_countryCodes = null
	End Method


	Method GetUniqueDataset:TPersonGeneratorEntry(countryCode:string, gender:int)
		local provider:TPersonGeneratorCountry = GetProvider(countryCode)
		if gender = 0 then gender = RandRange(1, 2) 'male or female

		local firstName:string, lastName:string
		Repeat
			firstName = provider.GetFirstName(gender)
			lastName = provider.GetLastName(gender)
		Until firstName and lastName and not protectedNames.Contains(firstName.ToLower()+"|"+lastName.ToLower())

		local person:TPersonGeneratorEntry = new TPersonGeneratorEntry
		person.firstName = firstName
		person.lastName = lastName
		person.gender = gender
		person.title = provider.GetTitle(gender)
		person.suffix = provider.GetSuffix(gender)
		person.prefix = provider.GetPrefix(gender)
		person.countryCode = provider.countryCode.toLower()

		return person
	End Method


	Method GetUniqueDatasetFromString:TPersonGeneratorEntry(config:string)
		local parts:string[] = config.split(",")
		local countries:string[] = parts[0].split(" ")
		local gender:int = GENDER_MALE
		if parts.length > 1
			gender = GetGenderFromString(parts[1])
		endif

		For local countryCode:string = EachIn countries
			if countryCode.trim() = "" then continue
			
			'check existence to avoid usage of fallback provider
			if HasProvider(countryCode)
				return GetUniqueDataset(countryCode, gender)
			endif
		Next
		
		return GetUniqueDataset(fallbackCountryCode, gender)
	End Method


	Function GetRandomGender:int()
		if RandRange(1,2) = 2
			return GENDER_FEMALE
		else
			return GENDER_MALE
		endif
	End Function


	Method GetRandomCountryCode:string()
		local countries:string[] = GetCountryCodes()
		if countries.length then return ""
		return countries[ RandRange(0, countries.length) ]
	End Method


	Function GetGenderFromString:int(str:string)
		Select str.Trim()
			case "m", "1"
				return GENDER_MALE
			case "f", "w", "2"
				return GENDER_FEMALE
			default
				return GetRandomGender()
		End Select
	End Function
		

	Method GetFirstName:string(countryCode:string, gender:int)
		if gender = 0 then gender = GetRandomGender()
		return GetProvider(countryCode).GetFirstName(gender)
	End Method


	Method GetLastName:string(countryCode:string, gender:int)
		if gender = 0 then gender = GetRandomGender()
		return GetProvider(countryCode).GetLastName(gender)
	End Method


	Method GetTitle:string(countryCode:string, gender:int)
		if gender = 0 then gender = GetRandomGender()
		return GetProvider(countryCode).GetTitle(gender)
	End Method


	Method GetCountryCodes:string[]()
		if not _countryCodes
			_countryCodes = new string[0]
			For local code:string = EachIn providers.Keys()
				_countryCodes :+ [code]
			Next
		endif
		return _countrycodes
	End Method


	Method ProtectName:TPersonGenerator(firstName:string, lastName:string)
		protectedNames.insert(firstName.ToLower()+"|"+lastName.ToLower(), "1")
	End Method


	Method ProtectDataset:TPersonGenerator(set:TPersonGeneratorEntry)
		protectedNames.insert(set.firstName.ToLower()+"|"+set.lastName.ToLower(), "1")
	End Method


	Method AddProvider:TPersonGenerator(country:TPersonGeneratorCountry)
		if country then providers.Insert(country.countryCode.ToLower(), country)
		_countryCodes = Null
		return self
	End Method


	Method HasProvider:int(countryCode:string)
		return providers.contains(countryCode.ToLower())
	End Method


	Method GetProvider:TPersonGeneratorCountry(countryCode:string)
		countryCode = countryCode.ToLower()
		if providers.contains(countryCode) 
			return TPersonGeneratorCountry(providers.ValueForKey(countryCode))
		elseif countryCode <> fallbackCountryCode
			return GetProvider(fallbackCountryCode)
		else
			return baseProvider
		endif
	End Method

End Type

Function GetPersonGenerator:TPersonGenerator()
	return TPersonGenerator._instance 
End Function




Type TPersonGeneratorEntry
	Field firstName:string
	Field lastName:string
	Field prefix:string
	Field suffix:string
	Field title:string
	Field gender:int
	Field countryCode:string
End Type




'template for all countries
Type TPersonGeneratorCountry
	Field countryCode:string = "default"
	Field lastNames:string[] = ["Mustermann"]
	Field firstNamesFemale:string[] = ["Erika"]
	Field firstNamesMale:string[] = ["Max"]
	Field titleMale:string[] = ["Herr", "Dr.", "Prof."]
	Field titleFemale:string[] = ["Frau", "Dr.", "Prof."]


	Method GetFirstName:string(gender:int)
		Select gender
			case TPersonGenerator.GENDER_FEMALE
				return GetFirstNameFemale()
			'case TPersonGenerator.GENDER_MALE
			Default
				return GetFirstNameMale()
		End Select
	End Method


	Method GetLastName:string(gender:int)
		return GetRandom(lastNames)
	End Method


	Method GetTitle:string(gender:int)
		Select gender
			case TPersonGenerator.GENDER_FEMALE
				return GetTitleFemale()
			'case TPersonGenerator.GENDER_MALE
			Default
				return GetTitleMale()
		End Select
	End Method


	Method GetPrefix:string(gender:int)
		return ""
	End Method


	Method GetSuffix:string(gender:int)
		return ""
	End Method


	Method GetFirstNameFemale:string()
		return GetRandom(firstNamesFemale)
	End Method

	Method GetFirstNameMale:string()
		return GetRandom(firstNamesMale)
	End Method


	Method GetTitleFemale:string()
		return GetRandom(titleFemale)
	End Method

	Method GetTitleMale:string()
		return GetRandom(titleMale)
	End Method
	

	Function GetRandom:string(arr:string[])
		if not arr or arr.length = 0 then return ""

		'RandRange is a "mersenne twister"-random number: so the same
		'on all computers (if seed is the same!)
		return arr[ RandRange(0, arr.length-1) ]
	End Function
End Type



'Austria
Type TPersonGeneratorCountry_Austria extends TPersonGeneratorCountry
	Method New()
		self.countryCode = "aut"
		
		self.firstNamesMale = [..
			"Abel", "Abraham", "Adalbero", "Adam", "Adamo", "Adolfo", "Adrian", "Adriano", "Adrianus", "Adrien", "Alain", "Alajos", "Alan", "Albain", "Alban", "Albano", "Alberto", "Albin", "Alec", "Alejandro", "Alessandro", "Alessio", "Alex", "Alexander", "Alexandre", "Alexandros", "Alexej", "Alexis", "Alfons", "Alfonso", "Aljoscha", "Allan", "Allen", "Alois", "Alon", "Alonzo", "Alphonse", "Alwin", "Amadeo", "Amadeus", "Amandus", "Amos", "Anatol", "Anatole", "Anatolij", "Anders", "Andi", "Andor", "Andre", "Andreas", "Andrej", "Andrew", "Andrijan", "Andy", "Angelus", "Ansgar", "Anthony", "Antoine", "Anton", "Antonio", "Araldo", "Aram", "Argus", "Arjan", "Armin", "Arminio", "Arnaldo", "Arnault", "Arndt", "Arne", "Arno", "Arnold", "Arrigo", "Art", "Arthur", "Artur", "Arturo", "August", "Auguste", "Augustin", "Aurelius", "Axel",..
			"Balduin", "Balthasar", "Bardo", "Barnabas", "Barnard", "Barney", "Baruch", "Basil", "Basilius", "Bastian", "Bastien", "Battista", "Beatus", "Beltrame", "Beltran", "Ben", "Benedetto", "Benedict", "Benedikt", "Bengt", "Beniamino", "Benignus", "Benito", "Benjamin", "Benjy", "Bennett", "Benno", "Benny", "Benoit", "Beppe", "Bernard", "Bernardo", "Bernd", "Bernhard", "Bernie", "Bert", "Berthold", "Bertoldo", "Bertram", "Bertrame", "Bill", "Billy", "Birger", "Bjarne", "Björn", "Bob", "Bobby", "Bodo", "Bonifatius", "Boris", "Bosco", "Brendan", "Brian", "Bruno", "Bryan", "Burkhard",..
			"Camillo", "Camilo", "Carl", "Carlo", "Carlos", "Carol", "Carsten", "Cäsar", "Casimir", "Caspar", "Cecil", "Ceddric", "Cedric", "Celestino", "Charles", "Charlie", "Chico", "Chip", "Chris", "Christian", "Christoph", "Christophe", "Christopher", "Christy", "Chuck", "Cian", "Cillian", "Clarence", "Clark", "Clas", "Claude", "Claudio", "Claudius", "Claus", "Clayton", "Clemens", "Cliff", "Clifford", "Clint", "Clinton", "Cody", "Colin", "Collin", "Conan", "Connor", "Conny", "Conor", "Conrad", "Constantine", "Cooper", "Cordell", "Cornelius", "Corvinus", "Cristobal", "Curd", "Curt", "Curtis", "Curtiz", "Cyril", "Cyrill",..
			"Damian", "Damon", "Dan", "Daniel", "Daniele", "Danilo", "Danny", "Dario", "Darius", "Dave", "David", "Davide", "Dawson", "Dean", "Demetrius", "Denis", "Deniz", "Dennis", "Derek", "Desiderius", "Detlef", "Detlev", "Dick", "Diego", "Dieter", "Dimitrij", "Dirk", "Dolf", "Domenico", "Domingo", "Dominic", "Dominik", "Dominikus", "Dominique", "Donald", "Donatello", "Donato", "Donatus", "Dorian", "Douglas", "Dragan", "Duarte", "Duncan", "Dylan",..
			"Earnest", "Earvin", "Eike", "Eleasar", "Elia", "Elian", "Elias", "Elijah", "Ellison", "Elmar", "Elroy", "Emanuel", "Emanuele", "Emil", "Emile", "Emilian", "Emiliano", "Emilio", "Emmanuel", "Endrik", "Enrico", "Enrique", "Enzo", "Ephraim", "Erasmus", "Eric", "Erik", "Ermanno", "Ernest", "Ernestin", "Ernesto", "Eros", "Errol", "Etienne", "Eugen", "Eugene", "Eugenio", "Eusebius", "Everett", "Ezra",..
			"Fabiano", "Fabien", "Fabio", "Fabius", "Fabrice", "Fabricius", "Fabrizio", "Falco", "Falk", "Falko", "Faruk", "Faustus", "Favian", "Federico", "Federigo", "Fedor", "Felice", "Feliciano", "Felicien", "Felipe", "Felix", "Felton", "Feodor", "Ferdinand", "Fergus", "Fernand", "Fernando", "Ferrante", "Ferris", "Fidel", "Fidelio", "Fidelis", "Fidelius", "Filippo", "Finan", "Finn", "Fiore", "Fjodor", "Flavian", "Flemming", "Fletcher", "Flint", "Florens", "Florentin", "Florian", "Florin", "Florus", "Floyd", "Forrest", "Forrester", "Forster", "Foster", "Fox", "Francesco", "Francis", "Francisco", "Franco", "Francois", "Franek", "Frank", "Frankie", "Franklin", "Franziskus", "Frasier", "Frayne", "Fred", "Freddy", "Frederic", "Frederick", "Frederik", "Freeman", "Fremont", "Fridericus", "Fridolin", "Friedel", "Frye",..
			"Gabriel", "Gaetan", "Gaetano", "Gallus", "Garcia", "Garfield", "Garin", "Garnier", "Garrick", "Garrison", "Garron", "Garry", "Garson", "Gaspar", "Gaspard", "Gaspare", "Gaston", "Gastonne", "Gates", "Gauthier", "Gavin", "Gene", "Geoffrey", "Geoffroy", "Geordi", "Georg", "George", "Georges", "Gerald", "Geraldo", "Gerard", "Geraud", "Gerd", "Gereon", "Germain", "German", "Germano", "Gernot", "Gerold", "Geronimo", "Gerrit", "Gerry", "Gert", "Gerulf", "Gerwin", "Giacomo", "Gian", "Giancarlo", "Gianni", "Gibson", "Gideon", "Gil", "Gilbert", "Gilberto", "Gilles", "Gillian", "Gino", "Gioacchino", "Giorgio", "Giovanni", "Giraldo", "Gisbert", "Gitano", "Giuliano", "Giulio", "Giuseppe", "Giusto", "Glen", "Glenn", "Goliath", "Goran", "Gordon", "Gordy", "Goswin", "Götz", "Graciano", "Graham", "Grayson", "Greg", "Gregg", "Gregoire", "Gregor", "Gregory", "Griffin", "Grover", "Gualtier", "Gualtiero", "Guglielmo", "Guido", "Guillaume", "Guillermo", "Gunnar", "Gunter", "Günter", "Gunther", "Günther", "Gus", "Gustavo", "Gustl", "Gutierre", "Guy",..
			"Hajo", "Hamilton", "Hamlet", "Hampton", "Hanley", "Hannes", "Hans", "Harald", "Hardy", "Harley", "Harlow", "Harold", "Haroun", "Harrison", "Harry", "Harvey", "Hasso", "Hauke", "Havel", "Hector", "Heiko", "Heiner", "Heino", "Hektor", "Helge", "Helmut", "Helmuth", "Hendrick", "Hendrik", "Hennes", "Henning", "Henri", "Henrick", "Henrik", "Henry", "Herald", "Herbie", "Hercules", "Herold", "Herwig", "Hieronymus", "Hilarius", "Holger", "Holm", "Homer", "Horace", "Horatio", "Horaz", "Howard", "Howie", "Hugh", "Hugo", "Humphrey", "Hunter",..
			"Ignatius", "Ignaz", "Ignazio", "Igor", "Ilian", "Ilja", "Immanuel", "Ingo", "Ingolf", "Ingvar", "Irenäus", "Irvin", "Irving", "Irwin", "Isaac", "Isaak", "Isai", "Isaiah", "Isidor", "Istvan", "Ivan", "Ivo",..
			"Jackson", "Jacky", "Jacob", "Jacques", "Jacquin", "Jadon", "Jago", "Jaime", "Jake", "Jakob", "Jamal", "James", "Jan", "Janis", "Jannes", "Jannik", "Janning", "Janos", "Janosch", "Jaques", "Jared", "Jarik", "Jarl", "Jarno", "Jaro", "Jaromir", "Jarrett", "Jascha", "Jason", "Jasper", "Jay", "Jean", "Jeff", "Jefferson", "Jeffrey", "Jendrick", "Jens", "Jered", "Jeremiah", "Jeremias", "Jeremie", "Jeremy", "Jerold", "Jerom", "Jerome", "Jerrick", "Jerry", "Jesaja", "Jesko", "Jesse", "Jim", "Jimmy", "Jirko", "Jo", "Joakim", "Joao", "Joaquin", "Joe", "Joel", "Joey", "John", "Johnny", "Jokim", "Jonah", "Jonas", "Jonathan", "Jonny", "Jordan", "Jordano", "Jörg", "Jorge", "Jose", "Josef", "Joseph", "Josh", "Joshua", "Josias", "Jost", "Josua", "Josue", "Jourdain", "Juan", "Juanito", "Jud", "Jules", "Julien", "Julio", "Julius", "Jürgen", "Jurij", "Justin", "Justinian", "Justus",..
			"Kain", "Kaj", "Kajetan", "Kallistus", "Karsten", "Kasimir", "Kaspar", "Keamon", "Keith", "Ken", "Kenan", "Kenneth", "Keno", "Kersten", "Kerwin", "Kevin", "Kian", "Kilian", "Kim", "Kiran", "Klaas", "Klaus", "Klemens", "Kleopas", "Knud", "Knut", "Kolja", "Konrad", "Konstantin", "Korbin", "Korbinian", "Kordt", "Kristian", "Kristof", "Kristoffer", "Kuno", "Kurt", "Kyros", "Lajos",..
			"Lambert", "Lamberto", "Larry", "Lars", "Laslo", "Lasse", "Laurent", "Laurente", "Laurentius", "Laurenz", "Laurenzo", "Lawrence", "Lazarus", "Lazlo", "Leander", "Lee", "Leif", "Leigh", "Lennart", "Lenny", "Lenz", "Leo", "Leon", "Leonard", "Leonardo", "Leonce", "Leone", "Leonello", "Leonhard", "Leopold", "Leopoldo", "Leroy", "Lesley", "Lester", "Leverett", "Levi", "Lew", "Lewis", "Lex", "Liborius", "Lienhard", "Linus", "Lion", "Lionel", "LLoyd", "Lobo", "Loic", "Lorenz", "Lorenzo", "Loris", "Lothaire", "Lou", "Louie", "Louis", "Lovis", "Luc", "Luca", "Lucan", "Lucas", "Luciano", "Lucien", "Lucius", "Ludovico", "Ludwig", "Luigi", "Luis", "Lukas", "Luke", "Lutger", "Luther", "Lutz", "Lyonel",..
			"Maik", "Malte", "Malwin", "Manolito", "Manolo", "Manuel", "Marc", "Marcel", "Marcello", "Marcellus", "Marco", "Marcus", "Marek", "Marian", "Marin", "Marino", "Marinus", "Mario", "Marius", "Mark", "Markus", "Marlon", "Maro", "Marten", "Martin", "Marvin", "Massimo", "Mathias", "Mathieu", "Mathis", "Matt", "Matteo", "Matthäus", "Matthes", "Matthew", "Matthias", "Matthieu", "Maurice", "Mauritius", "Mauritz", "Maurizio", "Mauro", "Maurus", "Max", "Maxence", "Maxi", "Maxime", "Maximilian", "Maximilien", "Melchior", "Merlin", "Michael", "Michail", "Michel", "Michele", "Mick", "Mickey", "Miguel", "Mika", "Mikael", "Mike", "Mikel", "Miklos", "Milan", "Milo", "Mirko", "Miro", "Miroslav", "Mischa", "Mitja", "Morgan", "Moritz", "Morris", "Morten",..
			"Nat", "Nathan", "Nathanael", "Nathaniel", "Nepomuk", "Nero", "Neron", "Newton", "Niccolo", "Nicholas", "Nick", "Nicki", "Nico", "Nicola", "Nicolai", "Nicolaj", "Nicolas", "Niels", "Nigel", "Nikita", "Niklas", "Niklaus", "Niko", "Nikodemus", "Nikolai", "Nikolaus", "Nils", "Noah", "Noel", "Norbert", "Norberto", "Norman",..
			"Odin", "Odo", "Odysseus", "Olaf", "Oleg", "Oliver", "Olivier", "Oliviero", "Olof", "Oluf", "Omar", "Omer", "Orlando", "Orson", "Oskar", "Osvaldo", "Oswin", "Otello", "Othello", "Otto", "Ove", "Owain", "Owen",..
			"Paco", "Paddy", "Palmiro", "Pancho", "Paolo", "Pascal", "Pat", "Patrice", "Patricio", "Patricius", "Patrick", "Patrizio", "Patrizius", "Paul", "Paulin", "Paulus", "Pawel", "Pedro", "Peer", "Pepe", "Pepito", "Peppone", "Per", "Percy", "Perez", "Pete", "Peter", "Phil", "Philip", "Philipp", "Philippe", "Philo", "Piedro", "Pier", "Piero", "Pierre", "Piet", "Pieter", "Pietro", "Pinkus", "Pippin", "Pitt", "Pius", "Placide", "Placido", "Placidus", "Poldi",..
			"Quint", "Quintin", "Quintinus", "Quintus", "Quirin", "Quirino",..
			"Raffaele", "Raffaello", "Raffaelo", "Raimondo", "Raimund", "Raimundo", "Rainer", "Rainier", "Ralf", "Ralph", "Ramon", "Randolf", "Randolph", "Randy", "Raoul", "Raphael", "Rasmus", "Rasul", "Raul", "Ray", "Raymond", "Regnier", "Reik", "Reiner", "Remo", "Renato", "Renatus", "Renaud", "Rene", "Renja", "Reto", "Reynold", "Ricardo", "Riccardo", "Rick", "Ricky", "Rico", "Rinaldo", "Robby", "Robert", "Roberto", "Robin", "Rocco", "Rock", "Rocky", "Rod", "Rodolfo", "Rodolphe", "Rodrigo", "Rodrigue", "Rodrique", "Roger", "Roland", "Rolando", "Rolf", "Romain", "Roman", "Romano", "Romeo", "Romero", "Ronald", "Ronan", "Ronny", "Rory", "Ross", "Rowan", "Rowland", "Roy", "Ruben", "Rudolf", "Rudolph", "Ruggero", "Rupert", "Ryan",..
			"Salomon", "Salomone", "Salvador", "Salvator", "Salvatore", "Sam", "Sammy", "Samuel", "Samuele", "Sander", "Sandor", "Sandro", "Sandy", "Sascha", "Sauveur", "Schorsch", "Scipio", "Scott", "Sean", "Sebastian", "Sebastiano", "Sebastien", "Selim", "Semjon", "Sepp", "Serenus", "Serge", "Sergej", "Sergio", "Sergius", "Servatius", "Severiano", "Severin", "Severo", "Sidney", "Sidonius", "Silas", "Silvain", "Silvan", "Silvano", "Silvanus", "Silverio", "Silverius", "Silvester", "Silvestro", "Silvio", "Silvius", "Simjon", "Simon", "Simone", "Sinclair", "Sixt", "Sixtus", "Slade", "Solomon", "Söncke", "Sören", "Spencer", "Stan", "Stanislaus", "Stanislaw", "Stanley", "Stefan", "Stefano", "Steffen", "Sten", "Stephan", "Stephen", "Steve", "Steven", "Stewart", "Stig", "Stuart", "Sven", "Sylvain", "Sylvester",..
			"Tam", "Tarek", "Tassilo", "Tasso", "Ted", "Teddy", "Teobaldo", "Thaddäus", "Theo", "Theodor", "Theodore", "Thierry", "Thimotheus", "Thomas", "Thommy", "Thoralf", "Thorben", "Thore", "Thorsten", "Tiberio", "Tiberius", "Tibor", "Till", "Tim", "Timmy", "Timo", "Timofej", "Timon", "Timoteo", "Timothee", "Timotheus", "Timothy", "Tin", "Tito", "Titus", "Tizian", "Tiziano", "Tjade", "Tjark", "Tobi", "Tobia", "Tobiah", "Tobias", "Tobie", "Tobis", "Toby", "Tom", "Tommaso", "Tommy", "Toni", "Tonio", "Tony", "Torben", "Torin", "Torsten", "Tristan", "Tycho", "Tyler", "Tyson",..
			"Udo", "Ugo", "Ugolino", "Ulf", "Uli", "Ulli", "Ulric", "Ulrich", "Ulrico", "Umberto", "Urbain", "Urban", "Urbano", "Urias", "Uriel", "Ursus", "Uwe",..
			"Valentiano", "Valentin", "Valentino", "Valerian", "Valerio", "Valerius", "Valery", "Vasco", "Veit", "Veltin", "Vernon", "Vicente", "Vico", "Victor", "Viktor", "Vincent", "Vincenzo", "Vinzenez", "Vinzenz", "Virgil", "Vitalis", "Vito", "Vittore", "Vittoriano", "Vittorio", "Volker",..
			"Wallace", "Walt", "Warner", "Warren", "Wido", "Wigand", "Wilbur", "Willi", "William", "Wilpert", "Winston", "Wolf", "Wolfgang", "Woodrow", "Woody",..
			"Xaver" ..
			]

		self.firstNamesFemale = [..
			"Abby", "Abelina", "Abigail", "Adelaide", "Adeline", "Adina", "Adriana", "Adrienne", "Afra", "Agatha", "Agnes", "Aida", "Aimee", "Aischa", "Albertine", "Alea", "Aleksandra", "Alena", "Alessa", "Alessandra", "Alessia", "Alexa", "Alexandra", "Alexia", "Alexis", "Alice", "Alicia", "Alida", "Alina", "Aline", "Alisa", "Alissa", "Alisson", "Amabella", "Amadea", "Amanda", "Amelia", "Amelie", "Amina", "Amy", "Ana", "Anastasia", "Andrea", "Andrina", "Anette", "Angela", "Angelika", "Angelina", "Angelique", "Anina", "Anine", "Anita", "Anja", "Anjalie", "Anke", "Ann", "Anna", "Annabel", "Annabell", "Annabella", "Annabelle", "Anne", "Annett", "Annette", "Annika", "Annina", "Antje", "Antoinette", "Antonella", "Antonia", "Arabella", "Ariadne", "Ariana", "Ariane", "Arianna", "Ariella", "Arielle", "Arlene", "Arlette", "Arwenna", "Ashley", "Asta", "Astrid", "Audrey", "Aurelia",..
			"Barbara", "Bärbel", "Bastiane", "Bea", "Beata", "Beatrice", "Beatrix", "Becky", "Belinda", "Bella", "Bellana", "Belle", "Benedikta", "Benita", "Bente", "Beppina", "Berenike", "Berit", "Bernadett", "Bernadette", "Bernadine", "Betina", "Betsy", "Bettina", "Betty", "Bianca", "Bianka", "Bibiana", "Bibiane", "Birgit", "Birgitt", "Bodil", "Bridget", "Brigitta", "Brigitte", "Britta",..
			"Caitlin", "Cameron", "Camilla", "Camille", "Cammy", "Cara", "Carin", "Carina", "Carinna", "Carla", "Carmela", "Carmelia", "Carmen", "Carol", "Carola", "Carole", "Carolin", "Carolina", "Caroline", "Carolyn", "Carolyne", "Cassandra", "Cassie", "Catalin", "Caterina", "Catharina", "Catherine", "Cathrin", "Cathrine", "Cathy", "Catina", "Catrin", "Catriona", "Cecile", "Cecilia", "Cecilie", "Celeste", "Celestine", "Celina", "Celine", "Chantal", "Charleen", "Charlotte", "Chatrina", "Chelsea", "Chiara", "Chloe", "Chrissy", "Christa", "Christiana", "Christiane", "Christin", "Christina", "Christine", "Chyna", "Ciara", "Cinderella", "Cindy", "Cinja", "Cira", "Claire", "Clara", "Clarissa", "Claudette", "Claudia", "Claudine", "Clea", "Cleannis", "Clementia", "Clementine", "Cleo", "Clio", "Cliona", "Clodia", "Cloris", "Coletta", "Colette", "Connie", "Conny", "Constance", "Constanze", "Cora", "Coral", "Coralie", "Cordelia", "Cordula", "Corin", "Corina", "Corinna", "Corinne", "Cornelia", "Cosette", "Cosima", "Cynthia",..
			"Daisy", "Dajana", "Daliah", "Damaris", "Damia", "Damiana", "Dana", "Dania", "Danica", "Daniela", "Daniele", "Daniella", "Danielle", "Danja", "Daphne", "Darcie", "Daria", "Darina", "Dawn", "Dayna", "Debbie", "Debby", "Debora", "Deborah", "Deetya", "Delia", "Delphine", "Dena", "Denise", "Desdemona", "Desideria", "Desiree", "Diana", "Diane", "Didina", "Dina", "Dinah", "Dolly", "Dolores", "Domenica", "Dominika", "Dominique", "Donna", "Dora", "Doreen", "Dorina", "Doris", "Dorit", "Doro", "Dorothea", "Dorothee", "Dorothy", "Dunja",..
			"Ebony", "Edda", "Edita", "Edvige", "Edwina", "Eike", "Eila", "Eileen", "Ela", "Elaine", "Eleanor", "Elektra", "Elena", "Eleonora", "Eleonore", "Eliane", "Elisa", "Elisabeth", "Elise", "Elizabeth", "Elke", "Ella", "Ellen", "Elly", "Eloise", "Elsa", "Elsbeth", "Elvira", "Elvire", "Emanuela", "Emanuelle", "Emilia", "Emilie", "Emily", "Emma", "Enrica", "Enya", "Erika", "Erin", "Ernesta", "Ernestina", "Ernestine", "Esmerelda", "Esra", "Estella", "Estelle", "Ester", "Esther", "Etiennette", "Eudoxia", "Eugenia", "Eunike", "Euphemia", "Euphrasia", "Eusebia", "Eva", "Evangelina", "Evania", "Eve", "Evelien", "Evelin", "Eveline", "Evelyn", "Evelyne", "Evette", "Evi", "Evita",..
			"Fabiane", "Fabienne", "Fabiola", "Faith", "Fanny", "Farrah", "Fatima", "Faustina", "Faustine", "Fay", "Faye", "Faylinn", "Federica", "Fedora", "Fee", "Feli", "Felice", "Felicia", "Felicitas", "Felicity", "Felizitas", "Feodora", "Fergie", "Fidelia", "Filia", "Filiz", "Finetta", "Finja", "Fiona", "Fjodora", "Flavia", "Fleur", "Fleur", "Flo", "Flora", "Florence", "Florentina", "Florentine", "Floria", "Floriane", "Florida", "Florinda", "Floris", "Fortuna", "Frances", "Francesca", "Francisca", "Franka", "Franzi", "Franziska", "Frauke", "Freya", "Friederike",..
			"Gabriela", "Gabriele", "Gabriella", "Gabrielle", "Gaby", "Gail", "Galatea", "Galina", "Gazelle", "Gela", "Geneva", "Genoveva", "Georgette", "Georgia", "Georgina", "Geraldene", "Geraldine", "Germain", "Germaine", "Germana", "Ghita", "Gianna", "Gigi", "Gill", "Gillian", "Gina", "Ginevra", "Ginger", "Ginny", "Giovanna", "Gisela", "Gisele", "Gisella", "Giselle", "Gitta", "Giulia", "Giuliana", "Giulietta", "Giuseppa", "Giuseppina", "Giustina", "Gladys", "Gloria", "Glory", "Goldie", "Goldy", "Grace", "Gratia", "Gratiana", "Grazia", "Greta", "Gretel", "Gunda", "Gwen", "Gwenda", "Gwendolin", "Gwendolyn", "Gypsy",..
			"Hannah", "Hanne", "Harmony", "Harriet", "Hazel", "Hedi", "Hedy", "Heide", "Heidi", "Heike", "Helen", "Helena", "Helene", "Helin", "Hella", "Hemma", "Henrietta", "Henriette", "Henrike", "Hera", "Hetty", "Hilary", "Hilda", "Hilde", "Holiday", "Holli", "Holly", "Hope",..
			"Ilana", "Ilaria", "Iliana", "Iljana", "Ilka", "Ilona", "Ilse", "Ilyssa", "Imke", "Ina", "India", "Indira", "Indra", "Ines", "Inga", "Inge", "Ingrid", "Inka", "Inken", "Innozentia", "Iona", "Ira", "Irena", "Irene", "Irina", "Iris", "Irisa", "Irma", "Isabel", "Isabell", "Isabella", "Isabelle", "Isis", "Iva", "Ivana", "Ivona", "Ivonne",..
			"Jaclyn", "Jacqueline", "Jacqui", "Jael", "Jamari", "Jan", "Jana", "Jane", "Janet", "Janette", "Janin", "Janina", "Janine", "Janique", "Janna", "Jannine", "Jarla", "Jasmin", "Jasmina", "Jasmine", "Jeanette", "Jeanine", "Jeanne", "Jeannette", "Jeannine", "Jekaterina", "Jelena", "Jenifer", "Jenna", "Jennelle", "Jennessa", "Jennie", "Jennifer", "Jenny", "Jennyfer", "Jess", "Jessica", "Jessie", "Jessika", "Jill", "Joan", "Joana", "Joann", "Joanna", "Joelle", "Johanna", "Jolanda", "Jona", "Jordana", "Jördis", "Josee", "Josefa", "Josefina", "Josefine", "Josepha", "Josephine", "Josiane", "Josie", "Jovita", "Joy", "Joyce", "Juana", "Juanita", "Judith", "Judy", "Julia", "Juliana", "Juliane", "Julianne", "Julie", "Juliet", "Juliette", "July", "June", "Justina", "Justine", "Justise", "Jutta",..
			"Kamilia", "Kamilla", "Karen", "Karima", "Karin", "Karina", "Karla", "Karola", "Karolin", "Karolina", "Karoline", "Kassandra", "Katalin", "Katarina", "Kate", "Katharina", "Katharine", "Käthe", "Katherina", "Katherine", "Kathleen", "Kathrin", "Kathrina", "Kathryn", "Kathy", "Katinka", "Katja", "Katjana", "Katrin", "Katrina", "Katrine", "Kayla", "Keala", "Keelin", "Kendra", "Kerstin", "Kiana", "Kiara", "Kim", "Kira", "Kirsten", "Kirstin", "Kita", "Klara", "Klarissa", "Klaudia", "Kleopatra", "Kolina", "Konstanze", "Kora", "Kordula", "Kori", "Kornelia", "Krista", "Kristiane", "Kristin", "Kristina", "Kristine", "Kyra",..
			"Laila", "Lana", "Lara", "Laria", "Larissa", "Lätizia", "Laurel", "Lauren", "Laurence", "Laurentia", "Lauretta", "Lavina", "Laya", "Lea", "Leah", "Leandra", "Lee", "Leigh", "Leila", "Lena", "Leona", "Leonie", "Leontine", "Leopoldine", "Lesley", "Leslie", "Levana", "Levia", "Lia", "Liane", "Libusa", "Licia", "Lidia", "Liesa", "Liesbeth", "Liese", "Liesel", "Lilian", "Liliane", "Lilith", "Lilli", "Lillian", "Lilo", "Lily", "Lina", "Linda", "Lioba", "Lisa", "Lisbeth", "Lise", "Lisette", "Liv", "Livana", "Livia", "Liz", "Liza", "Lizzie", "Lola", "Lora", "Lorena", "Loretta", "Lori", "Lorraine", "Lotte", "Lotus", "Louise", "Luana", "Luca", "Lucia", "Luciana", "Lucie", "Lucy", "Luigia", "Luisa", "Luise", "Luna", "Luzia", "Lydia", "Lydie", "Lynette", "Lynn",..
			"Maddalena", "Madelaine", "Madeleine", "Madeline", "Madison", "Madita", "Madleine", "Madlen", "Madlene", "Mae", "Magda", "Magdalena", "Maggy", "Magret", "Maia", "Maike", "Maiken", "Mailin", "Maja", "Malea", "Malee", "Malin", "Malina", "Mandy", "Manja", "Manon", "Manuela", "Mara", "Maraike", "Marcella", "Marcelle", "Marcia", "Mareike", "Maren", "Margaret", "Margareta", "Margarete", "Margaretha", "Margarita", "Margaritha", "Margherita", "Margit", "Margitta", "Margot", "Margret", "Margreth", "Marguerite", "Maria", "Mariam", "Marian", "Mariana", "Marianna", "Marianne", "Marie", "Marieke", "Mariella", "Marielle", "Marietta", "Marija", "Marika", "Marilies", "Marilyn", "Marina", "Marion", "Marisa", "Marissa", "Marita", "Maritta", "Marjorie", "Marla", "Marleen", "Marlen", "Marlena", "Marlene", "Marlies", "Marlis", "Marsha", "Martha", "Marthe", "Martina", "Mary", "Maryse", "Mascha", "Mathilda", "Mathilde", "Matilde", "Mattea", "Maude", "Maura", "Maureen", "Maximiliane", "May", "Maya", "Meg", "Megan", "Meike", "Melanie", "Melia", "Melina", "Melinda", "Melissa", "Melitta", "Melodie", "Meloney", "Mercedes", "Meret", "Meri", "Merle", "Merline", "Meryem", "Mia", "Micaela", "Michaela", "Michele", "Michelle", "Milena", "Milla", "Milva", "Mimi", "Minerva", "Minna", "Mira", "Mirabella", "Mireille", "Mirella", "Mireya", "Miriam", "Mirijam", "Mirjam", "Moesha", "Moira", "Mona", "Moni", "Monica", "Monika", "Monique", "Monja", "Morgane", "Muriel", "Myriam",..
			"Nadin", "Nadine", "Nadja", "Nadjana", "Naemi", "Nancy", "Nanette", "Nani", "Naomi", "Nastasja", "Natalia", "Natalie", "Natanja", "Natascha", "Nathalie", "Neeja", "Nena", "Neria", "Nerine", "Nicol", "Nicola", "Nicole", "Nicoletta", "Nicolette", "Nike", "Nikola", "Nina", "Ninja", "Ninon", "Noa", "Noelle", "Noemi", "Noemie", "Nora", "Norma", "Nuala",..
			"Olga", "Olivia", "Ophelia", "Orania", "Orla", "Ornella", "Orsola", "Ottilie",..
			"Paloma", "Pam", "Pamela", "Pandora", "Paola", "Paolina", "Pascale", "Pat", "Patrice", "Patricia", "Patrizia", "Patsy", "Patty", "Paula", "Paulette", "Paulina", "Pauline", "Penelope", "Pepita", "Petra", "Philine", "Philippa", "Philomele", "Philomena", "Phoebe", "Phyllis", "Pia", "Pier", "Prica", "Prisca", "Priscilla", "Priscille", "Priska",..
			"Rachel", "Rachel", "Rachelle", "Radomila", "Rafaela", "Raffaela", "Raffaella", "Ragna", "Rahel", "Raja", "Ramona", "Raphaela", "Raquel", "Rebecca", "Rebekka", "Regina", "Regine", "Reisha", "Renata", "Renate", "Renee", "Resi", "Rhea", "Rhoda", "Rhonda", "Ricarda", "Riccarda", "Rike", "Rita", "Roberta", "Romana", "Romina", "Romy", "Ronja", "Rosa", "Rosalia", "Rosalie", "Rosalinda", "Rosalinde", "Rosaline", "Rose", "Roseline", "Rosetta", "Rosette", "Rosi", "Rosina", "Rosine", "Rossana", "Roswitha", "Roxana", "Roxane", "Roxanne", "Roxy", "Rubina", "Ruth",..
			"Sabine", "Sabrina", "Sahra", "Sally", "Salome", "Salvina", "Samanta", "Samantha", "Samira", "Sandra", "Sandrina", "Sandrine", "Sandy", "Sanne", "Sanya", "Saphira", "Sara", "Sarah", "Sarina", "Sascha", "Saskia", "Scarlet", "Scarlett", "Schirin", "Selina", "Selma", "Serafina", "Seraina", "Seraphin", "Seraphina", "Seraphine", "Serena", "Severina", "Severine", "Shana", "Shanaya", "Shantala", "Shari", "Sharlene", "Sharon", "Sheena", "Sheila", "Sheryl", "Shirin", "Shirley", "Shirlyn", "Sibilla", "Sibyl", "Sibylle", "Siegrid", "Sigrid", "Sigrun", "Silja", "Silke", "Silvana", "Silvia", "Silviane", "Simona", "Simone", "Simonette", "Simonne", "Sina", "Sindy", "Sinja", "Sissy", "Skyla", "Smarula", "Smilla", "Sofia", "Sofie", "Sonia", "Sonja", "Sonnele", "Sonya", "Sophia", "Sophie", "Soraya", "Stefanie", "Steffi", "Stella", "Stephanie", "Sumehra", "Summer", "Susan", "Susanna", "Susanne", "Susi", "Suzan", "Suzanne", "Suzette", "Svea", "Svenja", "Swane", "Sybilla", "Sybille", "Sydney", "Sylvana", "Sylvia", "Sylvie",..
			"Tabitha", "Taissa", "Tamara", "Tamina", "Tania", "Tanita", "Tanja", "Tara", "Tatiana", "Tatjana", "Taya", "Tecla", "Telka", "Teodora", "Teona", "Teresa", "Terry", "Tess", "Tessa", "Tessie", "Thea", "Thekla", "Theodora", "Theres", "Theresa", "Therese", "Theresia", "Tiana", "Tiffany", "Tilly", "Timna", "Tina", "Tiziana", "Tonja", "Toril", "Tosca", "Tracey", "Traudl", "Trixi", "Tycho", "Tyra",..
			"Ulla", "Ulli", "Ulrica", "Ulrike", "Undine", "Urania", "Ursel", "Ursina", "Ursula", "Ursule", "Uschi", "Uta", "Ute",..
			"Valentina", "Valentine", "Valeria", "Valerie", "Valeska", "Vanadis", "Vanessa", "Vanja", "Varinka", "Venetia", "Vera", "Verena", "Verona", "Veronica", "Veronika", "Veronique", "Vesla", "Vicky", "Victoire", "Victoria", "Viki", "Viktoria", "Vilja", "Viola", "Violet", "Violetta", "Violette", "Virginia", "Virginie", "Vittoria", "Viviana", "Viviane", "Vivien", "Vivienne", "Vreneli", "Vreni", "Vroni",..
			"Wencke", "Weneke", "Wibke", "Wilja", "Willow", "Wilma" ..
			]

		self.lastNames = [ ..
			"Ackermann", "Adler", "Adolph", "Albers", "Anders", "Atzler", "Aumann", "Austermühle",..
			"Bachmann", "Bähr", "Bärer", "Barkholz", "Barth", "Bauer", "Baum", "Becker", "Beckmann", "Beer", "Beier", "Bender", "Benthin", "Berger", "Beyer", "Bien", "Biggen", "Binner", "Birnbaum", "Bloch", "Blümel", "Bohlander", "Bonbach", "Bolander", "Bolnbach", "Bolzmann", "Börner", "Bohnbach", "Boucsein", "Briemer", "Bruder", "Buchholz", "Budig", "Butte",..
			"Carsten", "Caspar", "Christoph", "Cichorius", "Conradi",..
			"Davids", "Dehmel", "Dickhard", "Dietz", "Dippel", "Ditschlerin", "Dobes", "Döhn", "Döring", "Dörr", "Dörschner", "Dowerg", "Drewes", "Drub", "Drubin", "Dussen van",..
			"Eberhardt", "Ebert", "Eberth", "Eckbauer", "Ehlert", "Eigenwillig", "Eimer", "Ernst", "Etzler", "Etzold",..
			"Faust", "Fechner", "Fiebig", "Finke", "Fischer", "Flantz", "Fliegner", "Förster", "Franke", "Freudenberger", "Fritsch", "Fröhlich",..
			"Gehringer", "Geisel", "Geisler", "Geißler", "Gerlach", "Gertz", "Gierschner", "Gieß", "Girschner", "Gnatz", "Gorlitz", "Gotthard", "Graf", "Grein Groth", "Gröttner", "Gude", "Gunpf", "Gumprich", "Gute", "Gutknecht",..
			"Haase", "Haering", "Hänel", "Häring", "Hahn", "Hamann", "Hande", "Harloff", "Hartmann", "Hartung", "Hauffer", "Hecker", "Heidrich", "Hein", "Heinrich", "Heintze", "Heinz", "Hellwig", "Henck", "Hendriks", "Henk", "Henschel", "Hentschel", "Hering", "Hermann", "Herrmann", "Hermighausen", "Hertrampf", "Heser", "Heß", "Hesse", "Hettner", "Hethur", "Heuser", "Hiller", "Heydrich", "Höfig", "Hofmann", "Holsten", "Holt", "Holzapfel", "Hölzenbecher", "Hörle", "Hövel", "Hoffmann", "Hornich", "Hornig", "Hübel", "Huhn",..
			"Jacob", "Jacobi Jäckel", "Jähn", "Jäkel", "Jäntsch", "Jessel", "Jockel", "Johann", "Jopich", "Junck", "Juncken", "Jungfer", "Junitz", "Junk", "Junken", "Jüttner",..
			"Kabus", "Kade", "Käster", "Kallert", "Kambs", "Karge", "Karz", "Kaul", "Kensy", "Keudel", "Killer", "Kitzmann", "Klapp", "Klemm", "Klemt", "Klingelhöfer", "Klotz", "Knappe", "Kobelt", "Koch", "Koch II", "Köhler", "Köster", "Kohl", "Kostolzin", "Kramer", "Kranz", "Krause", "Kraushaar", "Krebs", "Krein", "Kreusel", "Kroker", "Kruschwitz", "Kuhl", "Kühnert", "Kusch",..
			"Lachmann", "Ladeck", "Lange", "Langern", "Lehmann", "Liebelt", "Lindau", "Lindner", "Linke", "Löchel", "Löffler", "Loos", "Lorch", "Losekann", "Löwer", "Lübs",..
			"Mälzer", "Mangold", "Mans", "Margraf", "Martin", "Matthäi", "Meister", "Mende", "Mentzel", "Metz", "Meyer", "Mielcarek", "Mies", "Misicher", "Mitschke", "Mohaupt", "Mosemann", "Möchlichen", "Mude", "Mühle", "Mülichen", "Müller",..
			"Naser", "Nerger", "Nette", "Neureuther", "Neuschäfer", "Niemeier", "Noack", "Nohlmans",..
			"Oderwald", "Oestrovsky", "Ortmann", "Otto",..
			"Paffrath", "Pärtzelt", "Patberg", "Pechel", "Pergande", "Peukert", "Pieper", "Plath", "Pohl", "Pölitz", "Preiß", "Pruschke", "Putz",..
			"Rädel", "Radisch", "Reichmann", "Reinhardt", "Reising", "Renner", "Reuter", "Riehl", "Ring", "Ritter", "Rogge", "Rogner", "Rohleder", "Röhrdanz", "Röhricht", "Roht", "Römer", "Rörricht", "Rose", "Rosemann", "Rosenow", "Roskoth", "Rudolph", "Ruppersberger", "Ruppert", "Rust",..
			"Sager", "Salz", "Säuberlich", "Sauer", "Schaaf", "Schacht", "Schäfer", "Scheel", "Scheibe", "Schenk", "Scheuermann", "Schinke", "Schleich", "Schleich", "auch Schlauchin", "Schlosser", "Schmidt", "Schmidtke", "Schmiedecke", "Schmiedt", "Schönland", "Scholl", "Scholtz", "Scholz", "Schomber", "Schottin", "Schuchhardt", "Schüler", "Schulz", "Schuster", "Schweitzer", "Schwital", "Segebahn", "Seifert", "Seidel", "Seifert", "Seip", "Siering", "Söding", "Sölzer", "Sontag", "Sorgatz", "Speer", "Spieß", "Stadelmann", "Stahr", "Staude", "Steckel", "Steinberg", "Stey", "Stiebitz", "Stiffel", "Stoll", "Stolze", "Striebitz", "Stroh", "Stumpf", "Sucker", "Süßebier",..
			"Täsche", "Textor", "Thanel", "Thies", "Tintzmann", "Tlustek", "Trapp", "Trommler", "Tröst", "Trub", "Trüb", "Trubin", "Trupp", "Tschentscher",..
			"Ullmann", "Ullrich",..
			"van der Dussen", "Vogt", "Vollbrecht",..
			"Wagenknecht", "Wagner", "Wähner", "Walter", "Warmer", "Weihmann", "Weimer", "Weinhage", "Weinhold", "Weiß", "Weitzel", "Weller", "Wende", "Wernecke", "Werner", "Wesack", "Wiek", "Wieloch", "Wilms", "Wilmsen", "Winkler", "Wirth", "Wohlgemut", "Wulf", "Wulff",..
			"Zahn", "Zänker", "Ziegert", "Zimmer", "Zirme", "Zobel", "Zorbach" ..
			]
	End Method
End Type


'Germany
Type TPersonGeneratorCountry_Germany extends TPersonGeneratorCountry
	Method New()
		self.countryCode = "de"
		
		self.firstNamesMale = [..
			"Abbas", "Abdul", "Abdullah", "Abraham", "Abram", "Achim", "Ada", "Adalbert", "Adam", "Adelbert", "Adem", "Adolf", "Adrian", "Ahmad", "Ahmed", "Ahmet", "Alan", "Alban", "Albert", "Alberto", "Albin", "Albrecht", "Aldo", "Aleksandar", "Aleksander", "Aleksandr", "Aleksej", "Alessandro", "Alex", "Alexander", "Alexandre", "Alexandros", "Alexei", "Alexej", "Alf", "Alfons", "Alfonso", "Alfred", "Alfredo", "Ali", "Alois", "Aloys", "Alwin", "Amir", "Anastasios", "Anatol", "Anatoli", "Anatolij", "Andre", "Andreas", "Andree", "Andrei", "Andrej", "Andres", "Andrew", "Andrey", "Andrzej", "André", "Andy", "Angelo", "Anselm", "Ansgar", "Ante", "Anthony", "Anto", "Anton", "Antonino", "Antonio", "Antonios", "Antonius", "Apostolos", "Aribert", "Arif", "Armin", "Arnd", "Arndt", "Arne", "Arnfried", "Arnim", "Arno", "Arnold", "Arnulf", "Arthur", "Artur", "Athanasios", "Attila", "August", "Augustin", "Axel", "Aziz",..
			"Baldur", "Balthasar", "Baptist", "Bartholomäus", "Bastian", "Bayram", "Bekir", "Bela", "Ben", "Benedikt", "Benjamin", "Benno", "Berend", "Bernard", "Bernd", "Bernd-Dieter", "Berndt", "Bernfried", "Bernhard", "Bernt", "Bernward", "Bert", "Berthold", "Bertold", "Bertram", "Birger", "Björn", "Bodo", "Bogdan", "Boris", "Branko", "Brian", "Bruno", "Burckhard", "Burghard", "Burkard", "Burkhard", "Burkhardt",..
			"Calogero", "Carl", "Carl-Heinz", "Carlo", "Carlos", "Carmelo", "Carsten", "Celal", "Cemal", "Cemil", "Cengiz", "Cetin", "Charles", "Christian", "Christof", "Christoph", "Christopher", "Christos", "Claas", "Claudio", "Claudius", "Claus", "Claus-Dieter", "Claus-Peter", "Clemens", "Conrad", "Constantin", "Cord", "Cornelius", "Cosimo", "Curt", "Czeslaw",..
			"Dagobert", "Damian", "Dan", "Daniel", "Daniele", "Danilo", "Danny", "Darius", "Dariusz", "Darko", "David", "Denis", "Dennis", "Denny", "Detlef", "Detlev", "Diedrich", "Dierk", "Dieter", "Diethard", "Diethelm", "Diether", "Dietmar", "Dietrich", "Dimitri", "Dimitrios", "Dino", "Dirk", "Ditmar", "Dittmar", "Dogan", "Domenico", "Dominic", "Dominik", "Donald", "Dragan", "Drago", "Dursun", "Dusan",..
			"Eberhard", "Eberhardt", "Eckard", "Eckart", "Eckehard", "Eckhard", "Eckhardt", "Eckhart", "Edelbert", "Edgar", "Edmund", "Eduard", "Edward", "Edwin", "Egbert", "Eggert", "Egon", "Ehrenfried", "Ehrhard", "Eitel", "Ekkehard", "Ekkehart", "Ekrem", "Elias", "Elmar", "Emanuel", "Emil", "Emin", "Emmerich", "Engelbert", "Engin", "Enno", "Enrico", "Enver", "Ercan", "Erdal", "Erdogan", "Erhard", "Erhardt", "Eric", "Erich", "Erik", "Erkan", "Ernest", "Ernst", "Ernst-August", "Ernst-Dieter", "Ernst-Otto", "Erol", "Erwin", "Eugen", "Evangelos", "Ewald",..
			"Fabian", "Falk", "Falko", "Faruk", "Fatih", "Fedor", "Felix", "Ferdi", "Ferdinand", "Ferenc", "Fernando", "Filippo", "Florian", "Folker", "Folkert", "Francesco", "Francis", "Francisco", "Franco", "Franjo", "Frank", "Frank-Michael", "Frank-Peter", "Franz", "Franz Josef", "Franz-Josef", "Franz-Peter", "Franz-Xaver", "Fred", "Freddy", "Frederic", "Frederik", "Fredi", "Fredo", "Fredy", "Fridolin", "Friedbert", "Friedemann", "Frieder", "Friedhelm", "Friedhold", "Friedo", "Friedrich", "Friedrich-Karl", "Friedrich-Wilhelm", "Frithjof", "Fritz",..
			"Gabor", "Gabriel", "Gaetano", "Gebhard", "Geert", "Georg", "George", "Georgios", "Gerald", "Gerard", "Gerd", "Gereon", "Gerfried", "Gerhard", "Gerhardt", "Gerhart", "German", "Gernot", "Gero", "Gerold", "Gerolf", "Gert", "Gerwin", "Gilbert", "Gino", "Giorgio", "Giovanni", "Gisbert", "Giuseppe", "Goran", "Gordon", "Gottfried", "Gotthard", "Gotthilf", "Gotthold", "Gottlieb", "Gottlob", "Gregor", "Grzegorz", "Guenter", "Guenther", "Guido", "Guiseppe", "Gunar", "Gundolf", "Gunnar", "Gunter", "Gunther", "Guntram", "Gustav", "Götz", "Günter", "Günther",..
			"H.-Dieter", "Hagen", "Hajo", "Hakan", "Halil", "Hannes", "Hanni", "Hanno", "Hanns", "Hans", "Hans D.", "Hans Dieter", "Hans Georg", "Hans Josef", "Hans Jörg", "Hans Jürgen", "Hans Peter", "Hans-Adolf", "Hans-Albert", "Hans-Bernd", "Hans-Christian", "Hans-Detlef", "Hans-Dieter", "Hans-Dietrich", "Hans-Eberhard", "Hans-Erich", "Hans-Friedrich", "Hans-Georg", "Hans-Gerd", "Hans-Gerhard", "Hans-Günter", "Hans-Günther", "Hans-H.", "Hans-Heinrich", "Hans-Helmut", "Hans-Henning", "Hans-Herbert", "Hans-Hermann", "Hans-Hinrich", "Hans-J.", "Hans-Joachim", "Hans-Jochen", "Hans-Josef", "Hans-Jörg", "Hans-Jürgen", "Hans-Karl", "Hans-Ludwig", "Hans-Martin", "Hans-Michael", "Hans-Otto", "Hans-Peter", "Hans-Rainer", "Hans-Rudolf", "Hans-Theo", "Hans-Ulrich", "Hans-Uwe", "Hans-Walter", "Hans-Werner", "Hans-Wilhelm", "Hans-Willi", "Hans-Wolfgang", "Hansgeorg", "Hansjoachim", "Hansjörg", "Hansjürgen", "Hanspeter", "Harald", "Hardy", "Harm", "Harold", "Harri", "Harro", "Harry", "Hartmut", "Hartmuth", "Hartwig", "Hasan", "Hassan", "Hasso", "Heiko", "Heimo", "Heiner", "Heinfried", "Heini", "Heino", "Heinrich", "Heinz", "Heinz Dieter", "Heinz-Dieter", "Heinz-Georg", "Heinz-Gerd", "Heinz-Günter", "Heinz-Günther", "Heinz-Joachim", "Heinz-Josef", "Heinz-Jürgen", "Heinz-Otto", "Heinz-Peter", "Heinz-Walter", "Heinz-Werner", "Heinz-Wilhelm", "Heinz-Willi", "Helfried", "Helge", "Hellmut", "Hellmuth", "Helmar", "Helmut", "Helmuth", "Hendrik", "Henner", "Henning", "Henrik", "Henry", "Henryk", "Herbert", "Heribert", "Hermann", "Hermann Josef", "Hermann-Josef", "Herrmann", "Herwig", "Hilmar", "Hinrich", "Holger", "Holm", "Horst", "Horst-Dieter", "Horst-Günter", "Horst-Peter", "Hubert", "Hubertus", "Hugo", "Hüseyin",..
			"Ian", "Ibrahim", "Ignatz", "Ignaz", "Igor", "Ilhan", "Ilias", "Ilija", "Ilja", "Immo", "Imre", "Ingbert", "Ingmar", "Ingo", "Ingolf", "Ioannis", "Isidor", "Ismail", "Ismet", "Istvan", "Ivan", "Ivo", "Iwan",..
			"Jacek", "Jacob", "Jakob", "James", "Jan", "Jan-Peter", "Janko", "Jann", "Janos", "Janus", "Janusz", "Jaroslav", "Jaroslaw", "Jens", "Jens-Peter", "Jens-Uwe", "Jerzy", "Jiri", "Joachim", "Jobst", "Jochem", "Jochen", "Joerg", "Johan", "Johann", "Johannes", "John", "Jonas", "Jonas", "Jonathan", "Jorge", "Jose", "Josef", "Joseph", "Josip", "Jost", "José", "Jovan", "Jozef", "Juan", "Juergen", "Julian", "Julius", "Juri", "Jurij", "Justus", "Jörg", "Jörg-Peter", "Jörgen", "Jörn", "Jürgen",..
			"Kai-Uwe", "Kamil", "Karl", "Karl Heinz", "Karl-August", "Karl-Dieter", "Karl-Ernst", "Karl-Friedrich", "Karl-Georg", "Karl-Hans", "Karl-Heinrich", "Karl-Heinz", "Karl-Hermann", "Karl-Josef", "Karl-Jürgen", "Karl-Ludwig", "Karl-Otto", "Karl-Peter", "Karl-Werner", "Karl-Wilhelm", "Karlfried", "Karlheinz", "Karsten", "Kasimir", "Kaspar", "Kay-Uwe", "Kazim", "Kemal", "Kenan", "Kenneth", "Kevin", "Kilian", "Klaas", "Klaus", "Klaus Dieter", "Klaus Peter", "Klaus-D.", "Klaus-Dieter", "Klaus-Günter", "Klaus-Jürgen", "Klaus-Michael", "Klaus-Peter", "Klaus-Ulrich", "Klaus-Werner", "Klemens", "Knud", "Knut", "Konrad", "Konstantin", "Konstantinos", "Korbinian", "Kornelius", "Kristian", "Krzysztof", "Kunibert", "Kuno", "Kurt",..
			"Ladislaus", "Lambert", "Lars", "Laszlo", "Laurenz", "Leander", "Leif", "Leo", "Leon", "Leonard", "Leonardo", "Leonhard", "Leonid", "Leopold", "Leszek", "Linus", "Lorenz", "Lorenzo", "Lothar", "Louis", "Luciano", "Ludger", "Ludwig", "Luigi", "Luis", "Lukas", "Lutz",..
			"Magnus", "Mahmoud", "Mahmut", "Maik", "Malte", "Manfred", "Manuel", "Marc", "Marcel", "Marco", "Marcus", "Marek", "Marian", "Marijan", "Mario", "Marius", "Mariusz", "Mark", "Marko", "Markus", "Marten", "Martin", "Marvin", "Massimo", "Mathias", "Mato", "Matteo", "Matthias", "Matthäus", "Mattias", "Maurice", "Maurizio", "Max", "Maxim", "Maximilian", "Mehdi", "Mehmet", "Meik", "Meinhard", "Meinolf", "Meinrad", "Mesut", "Metin", "Micha", "Michael", "Michail", "Michel", "Miguel", "Mijo", "Mike", "Mikhail", "Milan", "Milos", "Miodrag", "Mirco", "Mirko", "Miroslav", "Miroslaw", "Mohamed", "Mohammad", "Mohammed", "Moritz", "Muharrem", "Murat", "Mustafa", "Muzaffer",..
			"Necati", "Nick", "Nico", "Nicolai", "Nicolas", "Nicolaus", "Niels", "Niklas", "Niko", "Nikola", "Nikolai", "Nikolaj", "Nikolaos", "Nikolas", "Nikolaus", "Nils", "Norbert", "Norman", "Nurettin", "Nuri",..
			"Olaf", "Ole", "Oliver", "Orhan", "Ortwin", "Oscar", "Oskar", "Osman", "Oswald", "Oswin", "Otfried", "Othmar", "Otmar", "Ottfried", "Ottmar", "Otto", "Ottokar", "Ottomar",..
			"Paolo", "Pascal", "Pasquale", "Patric", "Patrick", "Patrik", "Paul", "Paul-Gerhard", "Paul-Heinz", "Paulo", "Pavel", "Pawel", "Pedro", "Peer", "Pero", "Petar", "Peter", "Peter-Michael", "Petros", "Philip", "Philipp", "Philippe", "Phillip", "Pierre", "Pietro", "Piotr", "Pirmin", "Pius",..
			"Rafael", "Raik", "Raimund", "Rainer", "Ralf", "Ralf-Dieter", "Ralf-Peter", "Ralph", "Ramazan", "Ramon", "Randolf", "Raphael", "Raymond", "Raymund", "Recep", "Reginald", "Reimar", "Reimer", "Reimund", "Reinald", "Reiner", "Reinhard", "Reinhardt", "Reinhart", "Reinhold", "Remo", "Renato", "Rene", "René", "Reza", "Ricardo", "Richard", "Rico", "Rigo", "Riza", "Robby", "Robert", "Roberto", "Robin", "Rocco", "Rochus", "Roderich", "Roger", "Roland", "Rolf", "Rolf-Dieter", "Rolf-Peter", "Roman", "Romuald", "Ron", "Ronald", "Ronny", "Rouven", "Roy", "Ruben", "Rudi", "Rudolf", "Rudolph", "Rupert", "Ryszard", "Rüdiger",..
			"Saban", "Sabri", "Sahin", "Salih", "Salvatore", "Sami", "Samir", "Samuel", "Sandor", "Sandro", "Sebastian", "Sebastiano", "Sedat", "Selim", "Senol", "Sepp", "Serge", "Sergei", "Sergej", "Sergio", "Severin", "Siegbert", "Siegfried", "Sieghard", "Siegmar", "Siegmund", "Siegward", "Sigfried", "Sigismund", "Sigmar", "Sigmund", "Sigurd", "Silvester", "Silvio", "Simon", "Slavko", "Slawomir", "Slobodan", "Stanislaus", "Stanislav", "Stanislaw", "Stavros", "Stefan", "Stefano", "Steffen", "Stephan", "Stephen", "Steve", "Steven", "Stjepan", "Sven", "Swen", "Sylvester", "Sylvio", "Sönke", "Sören", "Sükrü", "Süleyman",..
			"Tadeusz", "Tassilo", "Thaddäus", "Theo", "Theobald", "Theodor", "Theodoros", "Thies", "Thilo", "Thomas", "Thoralf", "Thorben", "Thorsten", "Tibor", "Till", "Tillmann", "Tilman", "Tilmann", "Tilo", "Tim", "Timm", "Timo", "Tino", "Tobias", "Tom", "Tomas", "Tomasz", "Tomislav", "Toni", "Tony", "Toralf", "Torben", "Torsten", "Traugott",..
			"Udo", "Ulf", "Uli", "Ullrich", "Ulrich", "Urban", "Urs", "Utz", "Uwe",..
			"Vadim", "Valentin", "Valerij", "Vassilios", "Veit", "Veli", "Victor", "Viktor", "Vincent", "Vincenzo", "Vinko", "Vinzenz", "Vitali", "Vito", "Vittorio", "Vitus", "Vladimir", "Vlado", "Volker", "Volkhard", "Volkmar",..
			"Waldemar", "Walfried", "Walter", "Walther", "Wenzel", "Werner", "Wieland", "Wieslaw", "Wigbert", "Wilfried", "Wilhelm", "Willfried", "Willi", "William", "Willibald", "Willibert", "Willy", "Winfried", "Witold", "Wladimir", "Wojciech", "Woldemar", "Wolf", "Wolf-Dieter", "Wolf-Dietrich", "Wolf-Rüdiger", "Wolfgang", "Wolfhard", "Wolfram", "Wulf",..
			"Xaver",..
			"Yilmaz", "Yusuf",..
			"Zbigniew", "Zdravko", "Zeki", "Zeljko", "Zenon", "Zlatko", "Zoltan", "Zoran" ..
			]

		self.firstNamesFemale = [..
			"Adele", "Adelgunde", "Adelheid", "Adelinde", "Adeline", "Adina", "Adolfine", "Adriana", "Adriane", "Aenne", "Änne", "Agata", "Agatha", "Agathe", "Agnes", "Agnieszka", "Albertine", "Albina", "Aleksandra", "Alena", "Alexa", "Alexandra", "Alice", "Alicia", "Alicja", "Alida", "Alina", "Aline", "Alla", "Alma", "Almut", "Almuth", "Aloisia", "Alwina", "Alwine", "Amalia", "Amalie", "Amanda", "Amelie", "Ana", "Anastasia", "Andrea", "Aneta", "Anett", "Anette", "Angela", "Angelica", "Angelika", "Angelina", "Angelique", "Anica", "Anika", "Anita", "Anja", "Anka", "Anke", "Ann", "Ann-Kathrin", "Anna", "Anna-Lena", "Anna-Luise", "Anna-Maria", "Anna-Marie", "Annaliese", "Annamaria", "Anne", "Anne-Kathrin", "Anne-Katrin", "Anne-Marie", "Anne-Rose", "Annedore", "Annegret", "Annegrete", "Annekatrin", "Anneke", "Annelene", "Anneli", "Annelie", "Annelies", "Anneliese", "Annelise", "Annelore", "Annemarie", "Annemie", "Annerose", "Annett", "Annette", "Anni", "Annie", "Annika", "Annita", "Anny", "Antje", "Antoinette", "Antonia", "Antonie", "Antonietta", "Antonina", "Apollonia", "Ariane", "Arzu", "Asta", "Astrid", "Augusta", "Auguste", "Aurelia", "Aynur", "Ayse", "Aysel", "Ayten",..
			"Babett", "Babette", "Barbara", "Beata", "Beate", "Beatrice", "Beatrix", "Belinda", "Benita", "Berit", "Bernadette", "Bernhardine", "Berta", "Bertha", "Betina", "Betti", "Bettina", "Betty", "Bianca", "Bianka", "Birgid", "Birgit", "Birgitt", "Birgitta", "Birte", "Birthe", "Blanka", "Bozena", "Branka", "Brigitta", "Brigitte", "Brit", "Brita", "Britt", "Britta", "Brunhild", "Brunhilde", "Bruni", "Bärbel",..
			"Camilla", "Canan", "Caren", "Carin", "Carina", "Carla", "Carmela", "Carmen", "Carmine", "Carola", "Carolin", "Carolina", "Caroline", "Caterina", "Catharina", "Catherine", "Cathleen", "Cathrin", "Catrin", "Cecilia", "Centa", "Chantal", "Charlotte", "Christa", "Christa-Maria", "Christel", "Christiana", "Christiane", "Christin", "Christina", "Christine", "Christl", "Cilli", "Cilly", "Cindy", "Claire", "Clara", "Clarissa", "Claudia", "Cläre", "Concetta", "Conny", "Constance", "Constanze", "Cora", "Cordula", "Corina", "Corinna", "Corinne", "Cornelia", "Cosima", "Cristina", "Cynthia", "Cäcilia", "Cäcilie",..
			"Dagmar", "Dajana", "Damaris", "Dana", "Danica", "Daniela", "Danielle", "Danuta", "Daria", "Deborah", "Delia", "Denise", "Desiree", "Diana", "Diane", "Dietlind", "Dietlinde", "Dina", "Dolores", "Donata", "Dora", "Doreen", "Dorina", "Doris", "Dorit", "Dorle", "Dorota", "Dorothe", "Dorothea", "Dorothee", "Dragica", "Dunja", "Dörte", "Dörthe",..
			"Edda", "Edelgard", "Edeltraud", "Edeltraut", "Edeltrud", "Edit", "Edith", "Editha", "Ehrentraud", "Eileen", "Ekaterina", "Elena", "Eleni", "Elenore", "Eleonora", "Eleonore", "Elfi", "Elfie", "Elfriede", "Elif", "Elisa", "Elisabet", "Elisabeth", "Elise", "Elizabeth", "Elke", "Ella", "Ellen", "Elli", "Ellinor", "Elly", "Elma", "Elsa", "Elsbeth", "Else", "Elvira", "Elwira", "Elzbieta", "Emilia", "Emilie", "Emine", "Emma", "Emmi", "Emmy", "Erdmute", "Erica", "Erika", "Erna", "Ernestine", "Ester", "Esther", "Etta", "Eugenia", "Eugenie", "Eva", "Eva-Maria", "Eva-Marie", "Evamaria", "Evangelia", "Evelin", "Eveline", "Evelyn", "Evelyne", "Evi", "Ewa",..
			"Fabienne", "Fadime", "Fanny", "Fatima", "Fatma", "Felicia", "Felicitas", "Felizitas", "Filiz", "Flora", "Florence", "Florentine", "Franca", "Francesca", "Francoise", "Franka", "Franziska", "Frauke", "Frederike", "Freia", "Freya", "Frida", "Frieda", "Friedericke", "Friederike", "Friedhilde", "Friedl", "Friedlinde",..
			"Gabi", "Gabriela", "Gabriele", "Gabriella", "Gaby", "Galina", "Genoveva", "Georgia", "Georgine", "Geraldine", "Gerda", "Gerdi", "Gerhild", "Gerlind", "Gerlinde", "Gerta", "Gerti", "Gertraud", "Gertraude", "Gertraut", "Gertrud", "Gertrude", "Gesa", "Gesche", "Gesine", "Geza", "Giesela", "Gilda", "Gina", "Giovanna", "Gisa", "Gisela", "Gislinde", "Gitta", "Gitte", "Giuseppina", "Gloria", "Gordana", "Grazyna", "Greta", "Gretchen", "Grete", "Gretel", "Gretl", "Grit", "Gudrun", "Gudula", "Gunda", "Gundel", "Gundi", "Gundula", "Gunhild", "Gusti", "Gönül", "Gülay", "Gülsen", "Gülten",..
			"Halina", "Hanife", "Hanna", "Hannah", "Hannchen", "Hanne", "Hanne-Lore", "Hannelore", "Hanny", "Harriet", "Hatice", "Hedda", "Hedi", "Hedwig", "Hedy", "Heide", "Heide-Marie", "Heidelinde", "Heidelore", "Heidemarie", "Heiderose", "Heidi", "Heidrun", "Heike", "Helen", "Helena", "Helene", "Helga", "Hella", "Helma", "Helmtrud", "Henni", "Henny", "Henri", "Henriette", "Henrike", "Herlinde", "Herma", "Hermine", "Herta", "Hertha", "Hilda", "Hildburg", "Hilde", "Hildegard", "Hildegart", "Hildegund", "Hildegunde", "Hilma", "Hiltraud", "Hiltrud", "Hubertine", "Hulda", "Hülya",..
			"Ida", "Ildiko", "Ilka", "Ilona", "Ilonka", "Ilse", "Imelda", "Imke", "Ina", "Ines", "Inga", "Inge", "Ingeborg", "Ingeburg", "Ingelore", "Ingetraud", "Ingetraut", "Ingrid", "Ingried", "Inka", "Inken", "Inna", "Insa", "Ira", "Irena", "Irene", "Irina", "Iris", "Irma", "Irmela", "Irmengard", "Irmgard", "Irmhild", "Irmi", "Irmingard", "Irmtraud", "Irmtraut", "Irmtrud", "Isa", "Isabel", "Isabell", "Isabella", "Isabelle", "Isolde", "Ivana", "Ivanka", "Ivonne", "Iwona",..
			"Jacqueline", "Jadwiga", "Jana", "Jane", "Janet", "Janett", "Janette", "Janin", "Janina", "Janine", "Janna", "Jaqueline", "Jasmin", "Jasmina", "Jeanette", "Jeannette", "Jeannine", "Jelena", "Jennifer", "Jenny", "Jessica", "Jessika", "Jo", "Joana", "Joanna", "Johanna", "Johanne", "Jolanda", "Jolanta", "Jolanthe", "Josefa", "Josefine", "Josephine", "Judith", "Julia", "Juliana", "Juliane", "Julie", "Justina", "Justine", "Jutta",..
			"Karen", "Karin", "Karina", "Karla", "Karola", "Karolin", "Karolina", "Karoline", "Kata", "Katalin", "Katarina", "Katarzyna", "Katerina", "Katharina", "Katharine", "Katherina", "Kathi", "Kathleen", "Kathrin", "Kathy", "Kati", "Katja", "Katrin", "Katy", "Kerstin", "Kira", "Kirsten", "Kirstin", "Klara", "Klaudia", "Klothilde", "Kläre", "Konstanze", "Kordula", "Korinna", "Kornelia", "Kreszentia", "Kreszenz", "Kriemhild", "Krista", "Kristiane", "Kristin", "Kristina", "Kristine", "Krystyna", "Kunigunda", "Kunigunde", "Käte", "Käthe", "Käthi",..
			"Laila", "Lara", "Larissa", "Laura", "Lea", "Leila", "Lena", "Lene", "Leni", "Leokadia", "Leonie", "Leonore", "Leopoldine", "Leyla", "Lia", "Liane", "Lidia", "Lidija", "Lidwina", "Liesa", "Liesbeth", "Lieschen", "Liesel", "Lieselotte", "Lili", "Lilian", "Liliana", "Liliane", "Lilija", "Lilli", "Lilly", "Lilo", "Lina", "Linda", "Lioba", "Lisa", "Lisbeth", "Liselotte", "Lisette", "Lissi", "Lissy", "Ljiljana", "Ljubica", "Ljudmila", "Loni", "Lore", "Loretta", "Lotte", "Lotti", "Louise", "Lucia", "Lucie", "Ludmila", "Ludmilla", "Ludwina", "Luisa", "Luise", "Luitgard", "Luka", "Luzia", "Luzie", "Lydia",..
			"Madeleine", "Madlen", "Magarete", "Magda", "Magdalena", "Magdalene", "Magret", "Magrit", "Maike", "Maja", "Malgorzata", "Mandy", "Manja", "Manuela", "Mara", "Marcella", "Mareen", "Mareike", "Mareile", "Maren", "Marga", "Margaret", "Margareta", "Margarete", "Margaretha", "Margarethe", "Margarita", "Margit", "Margita", "Margitta", "Margot", "Margret", "Margrit", "Maria", "Maria-Luise", "Maria-Theresia", "Mariana", "Marianna", "Marianne", "Marica", "Marie", "Marie-Louise", "Marie-Luise", "Marie-Theres", "Marie-Therese", "Mariechen", "Mariele", "Marieluise", "Marietta", "Marija", "Marika", "Marina", "Mariola", "Marion", "Marisa", "Marit", "Marita", "Maritta", "Marjan", "Marleen", "Marlen", "Marlene", "Marlies", "Marliese", "Marlis", "Marta", "Martha", "Martina", "Martine", "Mary", "Marzena", "Mathilde", "Maya", "Mechthild", "Mechthilde", "Mechtild", "Meike", "Melanie", "Melissa", "Melita", "Melitta", "Meral", "Mercedes", "Meryem", "Meta", "Mia", "Michaela", "Michaele", "Michelle", "Milena", "Milica", "Milka", "Mina", "Minna", "Mira", "Mirella", "Miriam", "Mirja", "Mirjam", "Mirjana", "Miroslawa", "Mona", "Monica", "Monika", "Monique", "Monja", "Myriam",..
			"Nada", "Nadeschda", "Nadeshda", "Nadia", "Nadin", "Nadine", "Nadja", "Nancy", "Natali", "Natalia", "Natalie", "Natalija", "Natalja", "Natascha", "Nathalie", "Nelli", "Nelly", "Nermin", "Nevenka", "Nicole", "Nina", "Nora", "Norma", "Notburga", "Nuran", "Nuray", "Nurten",..
			"Oda", "Olav", "Olena", "Olga", "Olivia", "Ortrud", "Ortrun", "Ottilie", "Oxana",..
			"Pamela", "Paola", "Pascale", "Patricia", "Patrizia", "Paula", "Paulina", "Pauline", "Peggy", "Petra", "Philomena", "Pia", "Polina", "Priska",..
			"Rabea", "Radmila", "Rahel", "Raisa", "Raissa", "Ramona", "Raphaela", "Rebecca", "Rebekka", "Regina", "Regine", "Reingard", "Reinhild", "Reinhilde", "Rena", "Renata", "Renate", "Reni", "Resi", "Ria", "Ricarda", "Rita", "Romana", "Romy", "Rosa", "Rosa-Maria", "Rosalia", "Rosalie", "Rosalinde", "Rose", "Rose-Marie", "Rosel", "Roselinde", "Rosemarie", "Rosi", "Rosina", "Rosita", "Rosl", "Rosmarie", "Roswita", "Roswitha", "Rotraud", "Rotraut", "Ruth", "Ruthild",..
			"Sabina", "Sabine", "Sabrina", "Samira", "Sandra", "Sandy", "Sara", "Sarah", "Sarina", "Saskia", "Selma", "Semra", "Senta", "Serpil", "Sevim", "Sibel", "Sibilla", "Sibille", "Sibylla", "Sibylle", "Sieglinde", "Siegrid", "Siegried", "Siegrun", "Siglinde", "Sigrid", "Sigrun", "Silja", "Silke", "Silva", "Silvana", "Silvia", "Simona", "Simone", "Sina", "Sinaida", "Slavica", "Sofia", "Sofie", "Solveig", "Songül", "Sonia", "Sonja", "Sophia", "Sophie", "Stefani", "Stefania", "Stefanie", "Steffi", "Stella", "Stephanie", "Stilla", "Susan", "Susana", "Susann", "Susanna", "Susanne", "Suse", "Susi", "Suzanne", "Svea", "Svenja", "Svetlana", "Swantje", "Swetlana", "Sybilla", "Sybille", "Sylke", "Sylvana", "Sylvia", "Sylvie", "Sylwia",..
			"Tabea", "Tamara", "Tania", "Tanja", "Tatiana", "Tatjana", "Telse", "Teresa", "Thea", "Theda", "Thekla", "Theodora", "Theres", "Theresa", "Therese", "Theresia", "Tilly", "Tina", "Traude", "Traudel", "Traudl", "Traute", "Trude", "Trudel", "Trudi", "Tülay", "Türkan",..
			"Ulla", "Ulrike", "Undine", "Ursel", "Ursula", "Urszula", "Urte", "Uschi", "Uta", "Ute",..
			"Valentina", "Valentine", "Valeri", "Valeria", "Valerie", "Valeska", "Vanessa", "Vera", "Verena", "Veronica", "Veronika", "Veronique", "Vesna", "Victoria", "Viktoria", "Viola", "Violetta", "Virginia", "Viviane",..
			"Walburga", "Waldtraut", "Walentina", "Walli", "Wally", "Waltraud", "Waltraut", "Waltrud", "Wanda", "Wencke", "Wendelin", "Wenke", "Wera", "Wibke", "Wiebke", "Wilfriede", "Wilhelmine", "Wilma", "Wiltrud",..
			"Xenia",..
			"Yasemin", "Yasmin", "Yvette", "Yvonne",..
			"Zdenka", "Zehra", "Zenta", "Zeynep", "Zita", "Zofia" ..
			]

		self.lastNames = [ ..
			"Ackermann", "Adler", "Adolph", "Albers", "Anders", "Atzler", "Aumann", "Austermühle",..
			"Bachmann", "Bähr", "Bärer", "Barkholz", "Barth", "Bauer", "Baum", "Becker", "Beckmann", "Beer", "Beier", "Bender", "Benthin", "Berger", "Beyer", "Bien", "Biggen", "Binner", "Birnbaum", "Bloch", "Blümel", "Bohlander", "Bonbach", "Bolander", "Bolnbach", "Bolzmann", "Börner", "Bohnbach", "Boucsein", "Briemer", "Bruder", "Buchholz", "Budig", "Butte",..
			"Carsten", "Caspar", "Christoph", "Cichorius", "Conradi",..
			"Davids", "Dehmel", "Dickhard", "Dietz", "Dippel", "Ditschlerin", "Dobes", "Döhn", "Döring", "Dörr", "Dörschner", "Dowerg", "Drewes", "Drub", "Drubin", "Dussen van",..
			"Eberhardt", "Ebert", "Eberth", "Eckbauer", "Ehlert", "Eigenwillig", "Eimer", "Ernst", "Etzler", "Etzold",..
			"Faust", "Fechner", "Fiebig", "Finke", "Fischer", "Flantz", "Fliegner", "Förster", "Franke", "Freudenberger", "Fritsch", "Fröhlich",..
			"Gehringer", "Geisel", "Geisler", "Geißler", "Gerlach", "Gertz", "Gierschner", "Gieß", "Girschner", "Gnatz", "Gorlitz", "Gotthard", "Graf", "Grein Groth", "Gröttner", "Gude", "Gunpf", "Gumprich", "Gute", "Gutknecht",..
			"Haase", "Haering", "Hänel", "Häring", "Hahn", "Hamann", "Hande", "Harloff", "Hartmann", "Hartung", "Hauffer", "Hecker", "Heidrich", "Hein", "Heinrich", "Heintze", "Heinz", "Hellwig", "Henck", "Hendriks", "Henk", "Henschel", "Hentschel", "Hering", "Hermann", "Herrmann", "Hermighausen", "Hertrampf", "Heser", "Heß", "Hesse", "Hettner", "Hethur", "Heuser", "Hiller", "Heydrich", "Höfig", "Hofmann", "Holsten", "Holt", "Holzapfel", "Hölzenbecher", "Hörle", "Hövel", "Hoffmann", "Hornich", "Hornig", "Hübel", "Huhn",..
			"Jacob", "Jacobi Jäckel", "Jähn", "Jäkel", "Jäntsch", "Jessel", "Jockel", "Johann", "Jopich", "Junck", "Juncken", "Jungfer", "Junitz", "Junk", "Junken", "Jüttner",..
			"Kabus", "Kade", "Käster", "Kallert", "Kambs", "Karge", "Karz", "Kaul", "Kensy", "Keudel", "Killer", "Kitzmann", "Klapp", "Klemm", "Klemt", "Klingelhöfer", "Klotz", "Knappe", "Kobelt", "Koch", "Koch II", "Köhler", "Köster", "Kohl", "Kostolzin", "Kramer", "Kranz", "Krause", "Kraushaar", "Krebs", "Krein", "Kreusel", "Kroker", "Kruschwitz", "Kuhl", "Kühnert", "Kusch",..
			"Lachmann", "Ladeck", "Lange", "Langern", "Lehmann", "Liebelt", "Lindau", "Lindner", "Linke", "Löchel", "Löffler", "Loos", "Lorch", "Losekann", "Löwer", "Lübs",..
			"Mälzer", "Mangold", "Mans", "Margraf", "Martin", "Matthäi", "Meister", "Mende", "Mentzel", "Metz", "Meyer", "Mielcarek", "Mies", "Misicher", "Mitschke", "Mohaupt", "Mosemann", "Möchlichen", "Mude", "Mühle", "Mülichen", "Müller",..
			"Naser", "Nerger", "Nette", "Neureuther", "Neuschäfer", "Niemeier", "Noack", "Nohlmans",..
			"Oderwald", "Oestrovsky", "Ortmann", "Otto",..
			"Paffrath", "Pärtzelt", "Patberg", "Pechel", "Pergande", "Peukert", "Pieper", "Plath", "Pohl", "Pölitz", "Preiß", "Pruschke", "Putz",..
			"Rädel", "Radisch", "Reichmann", "Reinhardt", "Reising", "Renner", "Reuter", "Riehl", "Ring", "Ritter", "Rogge", "Rogner", "Rohleder", "Röhrdanz", "Röhricht", "Roht", "Römer", "Rörricht", "Rose", "Rosemann", "Rosenow", "Roskoth", "Rudolph", "Ruppersberger", "Ruppert", "Rust",..
			"Sager", "Salz", "Säuberlich", "Sauer", "Schaaf", "Schacht", "Schäfer", "Scheel", "Scheibe", "Schenk", "Scheuermann", "Schinke", "Schleich", "Schleich", "auch Schlauchin", "Schlosser", "Schmidt", "Schmidtke", "Schmiedecke", "Schmiedt", "Schönland", "Scholl", "Scholtz", "Scholz", "Schomber", "Schottin", "Schuchhardt", "Schüler", "Schulz", "Schuster", "Schweitzer", "Schwital", "Segebahn", "Seifert", "Seidel", "Seifert", "Seip", "Siering", "Söding", "Sölzer", "Sontag", "Sorgatz", "Speer", "Spieß", "Stadelmann", "Stahr", "Staude", "Steckel", "Steinberg", "Stey", "Stiebitz", "Stiffel", "Stoll", "Stolze", "Striebitz", "Stroh", "Stumpf", "Sucker", "Süßebier",..
			"Täsche", "Textor", "Thanel", "Thies", "Tintzmann", "Tlustek", "Trapp", "Trommler", "Tröst", "Trub", "Trüb", "Trubin", "Trupp", "Tschentscher",..
			"Ullmann", "Ullrich",..
			"van der Dussen", "Vogt", "Vollbrecht",..
			"Wagenknecht", "Wagner", "Wähner", "Walter", "Warmer", "Weihmann", "Weimer", "Weinhage", "Weinhold", "Weiß", "Weitzel", "Weller", "Wende", "Wernecke", "Werner", "Wesack", "Wiek", "Wieloch", "Wilms", "Wilmsen", "Winkler", "Wirth", "Wohlgemut", "Wulf", "Wulff",..
			"Zahn", "Zänker", "Ziegert", "Zimmer", "Zirme", "Zobel", "Zorbach" ..
			]
	End Method
End Type


'=== UK ===
'http://www.ons.gov.uk/ons/rel/vsob1/baby-names--england-and-wales/2013/index.html
'Germany
Type TPersonGeneratorCountry_UK extends TPersonGeneratorCountry
	Method New()
		self.countryCode = "uk"
		
		self.firstNamesMale = [..
			"Aaron", "Adam", "Adrian", "Aiden", "Alan", "Alex", "Alexander", "Alfie", "Andrew", "Andy", "Anthony", "Archie", "Arthur",..
			"Barry", "Ben", "Benjamin", "Bradley", "Brandon", "Bruce",..
			"Callum", "Cameron", "Charles", "Charlie", "Chris", "Christian", "Christopher", "Colin", "Connor", "Craig",..
			"Dale", "Damien", "Dan", "Daniel", "Darren", "Dave", "David", "Dean", "Dennis", "Dominic", "Duncan", "Dylan",..
			"Edward", "Elliot", "Elliott", "Ethan",..
			"Finley", "Frank", "Fred", "Freddie",..
			"Gary", "Gavin", "George", "Gordon", "Graham", "Grant", "Greg",..
			"Harley", "Harrison", "Harry", "Harvey", "Henry",..
			"Ian", "Isaac",..
			"Jack", "Jackson", "Jacob", "Jake", "James", "Jamie", "Jason", "Jayden", "Jeremy", "Jim", "Joe", "Joel", "John", "Jonathan", "Jordan", "Joseph", "Joshua",..
			"Karl", "Keith", "Ken", "Kevin", "Kieran", "Kyle",..
			"Lee", "Leo", "Lewis", "Liam", "Logan", "Louis", "Lucas", "Luke",..
			"Mark", "Martin", "Mason", "Matthew", "Max", "Michael", "Mike", "Mohammed", "Muhammad",..
			"Nathan", "Neil", "Nick", "Noah",..
			"Oliver", "Oscar", "Owen",..
			"Patrick", "Paul", "Pete", "Peter", "Philip",..
			"Quentin",..
			"Ray", "Reece", "Riley", "Rob", "Ross", "Ryan",..
			"Samuel", "Scott", "Sean", "Sebastian", "Stefan", "Stephen", "Steve",..
			"Theo", "Thomas", "Tim", "Toby", "Tom", "Tony", "Tyler",..
			"Wayne", "Will", "William",..
			"Zachary", "Zach" ..
			]

		self.firstNamesFemale = [..
			"Abbie", "Abigail", "Adele", "Alexa", "Alexandra", "Alice", "Alison", "Amanda", "Amber", "Amelia", "Amy", "Anna", "Ashley", "Ava",..
			"Beth", "Bethany", "Becky",..
			"Caitlin", "Candice", "Carlie", "Carmen", "Carole", "Caroline", "Carrie", "Charlotte", "Chelsea", "Chloe", "Claire", "Courtney",..
			"Daisy", "Danielle", "Donna",..
			"Eden", "Eileen", "Eleanor", "Elizabeth", "Ella", "Ellie", "Elsie", "Emily", "Emma", "Erin", "Eva", "Evelyn", "Evie",..
			"Faye", "Fiona", "Florence", "Francesca", "Freya",..
			"Georgia", "Grace",..
			"Hannah", "Heather", "Helen", "Helena", "Hollie", "Holly",..
			"Imogen", "Isabel", "Isabella", "Isabelle", "Isla", "Isobel",..
			"Jade", "Jane", "Jasmine", "Jennifer", "Jessica", "Joanne", "Jodie", "Julia", "Julie", "Justine",..
			"Karen", "Karlie", "Katie", "Keeley", "Kelly", "Kimberly", "Kirsten", "Kirsty",..
			"Laura", "Lauren", "Layla", "Leah", "Leanne", "Lexi", "Lilly", "Lily", "Linda", "Lindsay", "Lisa", "Lizzie", "Lola", "Lucy",..
			"Maisie", "Mandy", "Maria", "Mary", "Matilda", "Megan", "Melissa", "Mia", "Millie", "Molly",..
			"Naomi", "Natalie", "Natasha", "Nicole", "Nikki",..
			"Olivia",..
			"Patricia", "Paula", "Pauline", "Phoebe", "Poppy",..
			"Rachel", "Rebecca", "Rosie", "Rowena", "Roxanne", "Ruby", "Ruth",..
			"Sabrina", "Sally", "Samantha", "Sarah", "Sasha", "Scarlett", "Selina", "Shannon", "Sienna", "Sofia", "Sonia", "Sophia", "Sophie", "Stacey", "Stephanie","Suzanne", "Summer",..
			"Tanya", "Tara", "Teagan", "Theresa", "Tiffany", "Tina", "Tracy",..
			"Vanessa", "Vicky", "Victoria",..
			"Wendy",..
			"Yasmine", "Yvette", "Yvonne",..
			"Zoe" ..
			]

		self.lastNames = [ ..
			"Adams", "Allen", "Anderson",..
			"Bailey", "Baker", "Bell", "Bennett", "Brown", "Butler",..
			"Campbell", "Carter", "Chapman", "Clark", "Clarke", "Collins", "Cook", "Cooper", "Cox",..
			"Davies", "Davis",..
			"Edwards", "Ellis", "Evans",..
			"Fox",..
			"Graham", "Gray", "Green", "Griffiths",..
			"Hall", "Harris", "Harrison", "Hill", "Holmes", "Hughes", "Hunt", "Hunter",..
			"Jackson", "James", "Johnson", "Jones",..
			"Kelly", "Kennedy", "Khan", "King", "Knight",..
			"Lee", "Lewis", "Lloyd",..
			"Marshall", "Martin", "Mason", "Matthews", "Miller", "Mitchell", "Moore", "Morgan", "Morris", "Murphy", "Murray",..
			"Owen",..
			"Palmer", "Parker", "Patel", "Phillips", "Powell", "Price",..
			"Reid", "Reynolds", "Richards", "Richardson", "Roberts", "Robertson", "Robinson", "Rogers", "Rose", "Ross", "Russell",..
			"Saunders", "Scott", "Shaw", "Simpson", "Smith", "Stevens", "Stewart",..
			"Taylor", "Thomas", "Thompson", "Turner",..
			"Walker", "Walsh", "Ward", "Watson", "White", "Wilkinson", "Williams", "Wilson", "Wood", "Wright",..
			"Young" ..
			]
	End Method
End Type


'=== CHINA ===
Type TPersonGeneratorCountry_China extends TPersonGeneratorCountry
	Method New()
		self.countryCode = "cn"
		
		self.firstNamesMale = [..
			"Wei", "Lei", "Tao", "Peng", "Xin", "Ho", "Kay", "Asahi", ..
			"Huan", "Bo", "Nan", "Jianping", "Jiajun", "Hao", "Jianming", ..
			"Xinhua", "Xue-Ming", "Bo Tao", "Wenbin", "Yu", "Zhenguo", ..
			"Yi", "Yu Ran", "Zhe", "Sho", "Andrew", "Tetsuhiko", ..
			"Zhicheng", "Zhixin", "Zhiyong", "Victor", "Gordon", "Zhiwen", ..
			"Chi Ming", "Zhiyong", "Zhimin", "Zhiyuan" ..
			]

		self.firstNamesFemale = [..
			"Aryl", "Min Jing", "Xiuying,", "Juan", "Wenjuan", "Wenjun", "Jun", "Xia", ..
			"Mingxia", "Shirley", "Yan", "Guifen", "Ling", "Guiying", "Dan", "Ping", ..
			"Guilan", "Xiuzhen", "Lin", "Asahi", "Ting", "Xinyu", "Yuzhen", "Fengying", ..
			"Crystal", "Yuying", "Ying", "Lanying", "Shuzhen", "Chunmei", ..
			"Dongmei", "Xiurong", "Guizhen", "Xiuyun", "Guirong", "Xiumei", "Debbie", ..
			"Tingting", "Yuhua", "Lin", "Xuemei", "Shulan", "Lily", "Jade", ..
			"Shuying", "Kwai Fong", "Lihua", "Danny" , "Shuhua", "Xiuhua", "Guizhi", ..
			"Hongxia", "Yu", "Fenglan", "Yao", "Ka", "Yi", "Yumei", "Jie" ..
			]

		self.lastNames = [ ..
			"Lee", "King", "Zhang", "Liu", "Chen", "Yang", "Zhao", "Wu", "Xu", "Sun", "Hu", "Zhu", "Guo", "Law", ..
			"Zheng", "Dong", "Shaw", "Cao", "Yuan", "Deng", "Fu", "Shen", "Peng", "Lu", "Sue", "Lu", "Jiang", "Cai", "Jia", "Xue", "Yan", ..
			"Pan", "Wang", "Tin", "Ginger", "Fan", "Yao", "Tan", "Liao", "Zou", "Bear", "Hao", "Choi", "Qiu", "Qin", "Gu", "Hou", "Shao", ..
			"Wan", "Yin", "Ho", "Lai", "Gong", "Pang", "Fan", "Shi", "Zhai", "Ni", "Lo", "Yu", "Lu", "Ge", ..
			"Wu", "Wei", "Shen", "Nie", "Xing", "Qi", "Tu", "Shu", "Geng", "Mu", "Bu", ..
			"Ling", "Jin", "Sheng", "Zhen", "Pei", "Xi", "Tan", "Weng", "Sui", "Gan", "Bo", "Ke", "Nguyen", "Ouyang", ..
			"Chai", "Ran", "Gu", "Kat", "Rao", "Qu", "Teng", "Jin", "Zang", "Liao", "Gou", "Chu", "Lou", "Yan", "Lang", ..
			"Ji", "Gao", "Ao", "Mi", "Bian", "Sin", "Tong", "Sang", "Chen", "Ming" ..
			]
	End Method
End Type




'=== RUSSIA ===
Type TPersonGeneratorCountry_Russia extends TPersonGeneratorCountry
	Method New()
		self.countryCode = "ru"
		
		self.firstNamesMale = [..
			"Abram", "Awgust", "Adam", "Adrian", "Akim", "Aleksandr", "Aleksej", "Al'bert", "Ananij", "Anatolij", "Andrej", "Anton", "Antonin", ..
			"Apollon", "Arkadij", "Arsenij", "Artemij", "Artur", "Artjom", "Afanasij", "Bogdan", "Boleslaw", "Boris", "Bronislaw", "Wadim", ..
			"Walentin", "Walerian", "Walerij", "Wasilij", "Weniamin", "Wikentij", "Wiktor", "Wil", "Witalij", "Witold", "Wlad", "Wladimir", ..
			"Wladislaw", "Wladlen", "Wsewolod", "Wjatscheslaw", "Gawriil", "Garri", "Gennadij", "Georgij", "Gerasim", "German", "Gleb", "Gordej", ..
			"Grigorij", "Dawid", "Dan", "Daniil", "Danila", "Denis", "Dmitrij", "Dobrynja", "Donat", "Ewgenij", "Egor", "Efim", ..
			"Sachar", "Iwan", "Ignat", "Ignatij", "Igor", "Illarion", "Ilja", "Immanuil", "Innokentij", "Iosif", "Iraklij", "Kirill", ..
			"Klim", "Konstantin", "Kus'ma", "Lawrentij", "Lew", "Leonid", "Makar", "Maksim", "Marat", "Mark", "Matwej", "Milan", ..
			"Miroslaw", "Michail", "Nasar", "Nestor", "Nikita", "Nikodim", "Nikolaj", "Oleg", "Pawel", "Platon", "Prochor", "Pjotr", ..
			"Radislaw", "Rafail", "Robert", "Rodion", "Roman", "Rostislaw", "Ruslan", "Sawa", "Sawwa", "Swjatoslaw", "Semjon", "Sergej", ..
			"Spartak", "Stanislaw", "Stepan", "Stefan", "Taras", "Timofej", "Timur", "Tit", "Trofim", "Feliks", "Filipp", "Fjodor", ..
			"Eduard", "Erik", "Julian", "Julij", "Jurij", "Jakow", "Jan", "Jaroslaw", "Milan" ..
			]

		self.firstNamesFemale = [..
			"Aleksandra", "Alina", "Alisa", "Alla", "Albina", "Aljona", "Anastasija", "Anshelika", "Anna", "Antonina", "Anfisa", "Walentina", "Walerija", ..
			"Warwara", "Wasilisa", "Wera", "Weronika", "Wiktorija", "Wladlena", "Galina", "Darja", "Diana", "Dina", "Dominika", "Ewa", ..
			"Ewgenija", "Ekaterina", "Elena", "Elisaweta", "Shanna", "Sinaida", "Slata", "Soja", "Isabella", "Isolda", "Inga", "Inessa", ..
			"Inna", "Irina", "Iskra", "Kapitolina", "Klawdija", "Klara", "Klementina", "Kristina", "Ksenija", "Lada", "Larisa", "Lidija", ..
			"Lilija", "Ljubow", "Ljudmila", "Ljusja", "Majja", "Malwina", "Margarita", "Marina", "Marija", "Marta", "Nadeshda", "Natalja", ..
			"Nelli", "Nika", "Nina", "Nonna", "Oksana", "Olesja", "Olga", "Polina", "Rada", "Raisa", "Regina", "Renata", ..
			"Rosalina", "Swetlana", "Sofja", "Sofija", "Taisija", "Tamara", "Tatjana", "Uljana", "Faina", "Fedosja", "Florentina", "Elwira", "Emilija", ..
			"Emma", "Julija", "Jana", "Jaroslawa" ..
        	]

		self.lastNames = [ ..
			"Smirnow", "Iwanow", "Kusnezow", "Sokolow", "Popow", "Lebedew", "Koslow", ..
			"Nowikow", "Morosow", "Petrow", "Wolkow", "Solowjow", "Wasilew", "Sajzew", ..
			"Pawlow", "Semjonow", "Golubew", "Winogradow", "Bogdanow", "Worobjow", ..
			"Fjodorow", "Michajlow", "Beljaew", "Tarasow", "Below", "Komarow", "Orlow", ..
			"Kiseljow", "Makarow", "Andreew", "Kowaljow", "Ilin", "Gusew", "Titow", ..
			"Kusmin", "Kudrjawzew", "Baranow", "Kulikow", "Alekseew", "Stepanow", ..
			"Jakowlew", "Sorokin", "Sergeew", "Romanow", "Sacharow", "Borisow", "Koroljow", ..
			"Gerasimow", "Ponomarjow", "Grigorew", "Lasarew", "Medwedew", "Erschow", ..
			"Nikitin", "Sobolew", "Rjabow", "Poljakow", "Zwetkow", "Danilow", "Shukow", ..
			"Frolow", "Shurawljow", "Nikolaew", "Krylow", "Maksimow", "Sidorow", "Osipow", ..
			"Belousow", "Fedotow", "Dorofeew", "Egorow", "Matweew", "Bobrow", "Dmitriew", ..
			"Kalinin", "Anisimow", "Petuchow", "Antonow", "Timofeew", "Nikiforow", ..
			"Weselow", "Filippow", "Markow", "Bolschakow", "Suchanow", "Mironow", "Schirjaew", ..
			"Aleksandrow", "Konowalow", "Schestakow", "Kasakow", "Efimow", "Denisow", ..
			"Gromow", "Fomin", "Dawydow", "Melnikow", "Schtscherbakow", "Blinow", "Kolesnikow", ..
			"Karpow", "Afanasew", "Wlasow", "Maslow", "Isakow", "Tichonow", "Aksjonow", ..
			"Gawrilow", "Rodionow", "Kotow", "Gorbunow", "Kudrjaschow", "Bykow", "Suew", ..
			"Tretjakow", "Sawelew", "Panow", "Rybakow", "Suworow", "Abramow", "Woronow", ..
			"Muchin", "Archipow", "Trofimow", "Martynow", "Emeljanow", "Gorschkow", "Tschernow", ..
			"Owtschinnikow", "Selesnjow", "Panfilow", "Kopylow", "Micheew", "Galkin", "Nasarow", ..
			"Lobanow", "Lukin", "Beljakow", "Potapow", "Nekrasow", "Chochlow", "Shdanow", ..
			"Naumow", "Schilow", "Woronzow", "Ermakow", "Drosdow", "Ignatew", "Sawin", ..
			"Loginow", "Safonow", "Kapustin", "Kirillow", "Moiseew", "Eliseew", "Koschelew", ..
			"Kostin", "Gorbatschjow", "Orechow", "Efremow", "Isaew", "Ewdokimow", "Kalaschnikow", ..
			"Kabanow", "Noskow", "Judin", "Kulagin", "Lapin", "Prochorow", "Nesterow", ..
			"Charitonow", "Agafonow", "Murawjow", "Larionow", "Fedoseew", "Simin", "Pachomow", ..
			"Schubin", "Ignatow", "Filatow", "Krjukow", "Rogow", "Kulakow", "Terentew", ..
			"Moltschanow", "Wladimirow", "Artemew", "Gurew", "Sinowew", "Grischin", "Kononow", ..
			"Dementew", "Sitnikow", "Simonow", "Mischin", "Fadeew", "Komissarow", "Mamontow", ..
			"Nosow", "Guljaew", "Scharow", "Ustinow", "Wischnjakow", "Ewseew", "Lawrentew", ..
			"Bragin", "Konstantinow", "Kornilow", "Awdeew", "Sykow", "Birjukow", "Scharapow", ..
			"Nikonow", "Schtschukin", "Djatschkow", "Odinzow", "Sasonow", "Jakuschew", "Krasilnikow", ..
			"Gordeew", "Samojlow", "Knjasew", "Bespalow", "Uwarow", "Schaschkow", "Bobyljow", ..
			"Doronin", "Belosjorow", "Roshkow", "Samsonow", "Mjasnikow", "Lichatschjow", "Burow", ..
			"Sysoew", "Fomitschjow", "Rusakow", "Strelkow", "Guschtschin", "Teterin", "Kolobow", ..
			"Subbotin", "Fokin", "Blochin", "Seliwerstow", "Pestow", "Kondratew", "Silin", ..
			"Merkuschew", "Lytkin", "Turow" ..
			]
	End Method
End Type




'=== TURKEY ===
' http://tr.wikipedia.org/wiki/Kategori:T%C3%BCrk%C3%A7e_soyadlar%C4%B1
' http://www.guzelisimler.com/en_cok_aranan_erkek_isimleri.php
' http://www.guzelisimler.com/en_cok_aranan_kiz_isimleri.php
Type TPersonGeneratorCountry_Turkey extends TPersonGeneratorCountry
	Method New()
		self.countryCode = "tr"
		
		self.firstNamesMale = [..
			"Ahmet", "Ali", "Alp", "Armağan", "Atakan", "Aşkın", "Baran", "Bartu", "Berk", "Berkay", "Berke", "Bora", "Burak", "Canberk", ..
			"Cem", "Cihan", "Deniz", "Efe", "Ege", "Ege", "Emir", "Emirhan", "Emre", "Ferid", "Göktürk", "Görkem", "Güney", ..
			"Kağan", "Kerem", "Koray", "Kutay", "Mert", "Onur", "Ogün", "Polat", "Rüzgar", "Sarp", "Serhan", "Toprak", "Tuna", ..
			"Türker", "Utku", "Yağız", "Yiğit", "Çınar", "Derin", "Meriç", "Barlas", "Dağhan", "Doruk", "Çağan" ..
			]

		self.firstNamesFemale = [..
			"Ada", "Esma", "Emel", "Ebru", "Şahnur", "Ümran", "Sinem", "İrem", "Rüya", "Ece", "Burcu" ..
        	]

		self.lastNames = [ ..
			"Abacı", "Abadan", "Aclan", "Adal", "Adan", "Adıvar", "Akal", "Akan", "Akar", "Akay", ..
			"Akaydın", "Akbulut", "Akgül", "Akışık", "Akman", "Akyürek", "Akyüz", "Akşit", "Alnıaçık", ..
			"Alpuğan", "Alyanak", "Arıcan", "Arslanoğlu", "Atakol", "Atan", "Avan", "Ayaydın", "Aybar", ..
			"Aydan", "Aykaç", "Ayverdi", "Ağaoğlu", "Aşıkoğlu", "Babacan", "Babaoğlu", "Bademci", ..
			"Bakırcıoğlu", "Balaban", "Balcı", "Barbarosoğlu", "Baturalp", "Baykam", "Başoğlu", "Berberoğlu", ..
			"Beşerler", "Beşok", "Biçer", "Bolatlı", "Dalkıran", "Dağdaş", "Dağlaroğlu", "Demirbaş", "Demirel", ..
			"Denkel", "Dizdar", "Doğan", "Durak", "Durmaz", "Duygulu", "Düşenkalkar", "Egeli", "Ekici", "Ekşioğlu", ..
			"Eliçin", "Elmastaşoğlu", "Elçiboğa", "Erbay", "Erberk", "Erbulak", "Erdoğan", "Erez", "Erginsoy", ..
			"Erkekli", "Eronat", "Ertepınar", "Ertürk", "Erçetin", "Evliyaoğlu", "Fahri", "Gönültaş", "Gümüşpala", ..
			"Günday", "Gürmen", "Ilıcalı", "Kahveci", "Kaplangı", "Karabulut", "Karaböcek", "Karadaş", "Karaduman", ..
			"Karaer", "Kasapoğlu", "Kavaklıoğlu", "Kaya", "Keseroğlu", "Keçeci", "Kılıççı", "Kıraç", "Kocabıyık", ..
			"Korol", "Koyuncu", "Koç", "Koçoğlu", "Koçyiğit", "Kuday", "Kulaksızoğlu", "Kumcuoğlu", "Kunt", ..
			"Kunter", "Kurutluoğlu", "Kutlay", "Kuzucu", "Körmükçü", "Köybaşı", "Köylüoğlu", "Küçükler", "Limoncuoğlu", ..
			"Mayhoş", "Menemencioğlu", "Mertoğlu", "Nalbantoğlu", "Nebioğlu", "Numanoğlu", "Okumuş", "Okur", "Oraloğlu", ..
			"Orbay", "Ozansoy", "Paksüt", "Pekkan", "Pektemek", "Polat", "Poyrazoğlu", "Poçan", "Sadıklar", "Samancı", ..
			"Sandalcı", "Sarıoğlu", "Saygıner", "Sepetçi", "Sezek", "Sinanoğlu", "Solmaz", "Sözeri", "Süleymanoğlu", ..
			"Tahincioğlu", "Tanrıkulu", "Tazegül", "Taşlı", "Taşçı", "Tekand", "Tekelioğlu", "Tokatlıoğlu", "Tokgöz", ..
			"Topaloğlu", "Topçuoğlu", "Toraman", "Tunaboylu", "Tunçeri", "Tuğlu", "Tuğluk", "Türkdoğan", "Türkyılmaz", ..
			"Tütüncü", "Tüzün", "Uca", "Uluhan", "Velioğlu", "Yalçın", "Yazıcı", "Yetkiner", "Yeşilkaya", "Yıldırım", ..
			"Yıldızoğlu", "Yılmazer", "Yorulmaz", "Çamdalı", "Çapanoğlu", "Çatalbaş", "Çağıran", "Çetin", "Çetiner", ..
			"Çevik", "Çörekçi", "Önür", "Örge", "Öymen", "Özberk", "Özbey", "Özbir", "Özdenak", "Özdoğan", "Özgörkey", ..
			"Özkara", "Özkök", "Öztonga", "Öztuna" ..
			]
	End Method
End Type




'=== USA ===
Type TPersonGeneratorCountry_USA extends TPersonGeneratorCountry
	Method New()
		self.countryCode = "us"
		
		self.firstNamesMale = [..
			"Aaron", "Abdiel", "Abdul", "Abdullah", "Abe", "Abel", "Abelardo", "Abner", "Abraham", "Adalberto", "Adam", "Adan", "Adelbert", "Adolf", "Adolfo", "Adolph", "Adolphus", "Adonis", "Adrain", "Adrian", "Adriel", "Adrien", "Afton", "Agustin", "Ahmad", "Ahmed", "Aidan", "Aiden", "Akeem", "Al", "Alan", "Albert", "Alberto", "Albin", "Alden", "Alec", "Alejandrin", "Alek", "Alessandro", "Alex", "Alexander", "Alexandre", "Alexandro", "Alexie", "Alexis", "Alexys", "Alexzander", "Alf", "Alfonso", "Alfonzo", "Alford", "Alfred", "Alfredo", "Ali", "Allan", "Allen", "Alphonso", "Alvah", "Alvis", "Amani", "Amari", "Ambrose", "Americo", "Amir", "Amos", "Amparo", "Anastacio", "Anderson", "Andre", "Andres", "Andrew", "Andy", "Angel", "Angelo", "Angus", "Anibal", "Ansel", "Ansley", "Anthony", "Antone", "Antonio", "Antwan", "Antwon", "Arch", "Archibald", "Arden", "Arely", "Ari", "Aric", "Ariel", "Arjun", "Arlo", "Armand", "Armando", "Armani", "Arnaldo", "Arne", "Arno", "Arnold", "Arnoldo", "Arnulfo", "Aron", "Art", "Arthur", "Arturo", "Arvel", "Arvid", "Ashton", "August", "Augustus", "Aurelio", "Austen", "Austin", "Austyn", "Avery", "Axel", "Ayden", ..
			"Bailey", "Barney", "Baron", "Barrett", "Barry", "Bart", "Bartholome", "Barton", "Baylee", "Beau", "Bell", "Ben", "Benedict", "Benjamin", "Bennett", "Bennie", "Benny", "Benton", "Bernard", "Bernardo", "Bernhard", "Bernie", "Berry", "Berta", "Bertha", "Bertram", "Bertrand", "Bill", "Billy", "Blair", "Blaise", "Blake", "Blaze", "Bo", "Bobbie", "Bobby", "Boris", "Boyd", "Brad", "Braden", "Bradford", "Bradley", "Bradly", "Brady", "Braeden", "Brain", "Brando", "Brandon", "Brandt", "Brannon", "Branson", "Brant", "Braulio", "Braxton", "Brayan", "Brendan", "Brenden", "Brendon", "Brennan", "Brennon", "Brent", "Bret", "Brett", "Brian", "Brice", "Brock", "Broderick", "Brody", "Brook", "Brooks", "Brown", "Bruce", "Bryce", "Brycen", "Bryon", "Buck", "Bud", "Buddy", "Buford", "Burley", "Buster", ..
			"Cade", "Caden", "Caesar", "Cale", "Caleb", "Camden", "Cameron", "Camren", "Camron", "Camryn", "Candelario", "Candido", "Carey", "Carleton", "Carlo", "Carlos", "Carmel", "Carmelo", "Carmine", "Carol", "Carroll", "Carson", "Carter", "Cary", "Casey", "Casimer", "Casimir", "Casper", "Ceasar", "Cecil", "Cedrick", "Celestino", "Cesar", "Chad", "Chadd", "Chadrick", "Chaim", "Chance", "Chandler", "Charles", "Charley", "Charlie", "Chase", "Chauncey", "Chaz", "Chelsey", "Chesley", "Chester", "Chet", "Chris", "Christ", "Christian", "Christop", "Christophe", "Christopher", "Cicero", "Cielo", "Clair", "Clark", "Claud", "Claude", "Clay", "Clemens", "Clement", "Cleo", "Cletus", "Cleve", "Cleveland", "Clifford", "Clifton", "Clint", "Clinton", "Clovis", "Cloyd", "Clyde", "Coby", "Cody", "Colby", "Cole", "Coleman", "Colin", "Collin", "Colt", "Colten", "Colton", "Columbus", "Conner", "Connor", "Conor", "Conrad", "Constantin", "Consuelo", "Cooper", "Corbin", "Cordelia", "Cordell", "Cornelius", "Cornell", "Cortez", "Cory", "Coty", "Coy", "Craig", "Crawford", "Cristian", "Cristina", "Cristobal", "Cristopher", "Cruz", "Cullen", "Curt", "Curtis", "Cyril", "Cyrus", ..
			"Dagmar", "Dale", "Dallas", "Dallin", "Dalton", "Dameon", "Damian", "Damien", "Damion", "Damon", "Dan", "Dane", "D'angelo", "Dangelo", "Danial", "Danny", "Dante", "Daren", "Darian", "Darien", "Dario", "Darion", "Darius", "Daron", "Darrel", "Darrell", "Darren", "Darrick", "Darrin", "Darrion", "Darron", "Darryl", "Darwin", "Daryl", "Dashawn", "Dave", "David", "Davin", "Davion", "Davon", "Davonte", "Dawson", "Dax", "Dayne", "Dayton", "Dean", "Deangelo", "Declan", "Dedric", "Dedrick", "Dee", "Deion", "Dejon", "Dejuan", "Delaney", "Delbert", "Dell","Delmer", "Demarco", "Demarcus", "Demario", "Demetrius", "Demond", "Denis", "Dennis", "Deon", "Deondre", "Deontae", "Deonte", "Dereck", "Derek", "Derick", "Deron", "Derrick", "Deshaun", "Deshawn", "Desmond", "Destin", "Devan", "Devante", "Deven", "Devin", "Devon", "Devonte", "Devyn", "Dewayne", "Dewitt", "Dexter", "Diamond", "Diego", "Dillan", "Dillon", "Dimitri", "Dino", "Dion", "Dock","Domenic", "Domenick", "Domenico", "Domingo", "Dominic", "Don", "Donald", "Donato", "Donavon", "Donnell", "Donnie", "Donny", "Dorcas", "Dorian", "Doris", "Dorthy", "Doug", "Douglas", "Doyle", "Drake", "Dudley", "Duncan", "Durward", "Dustin", "Dusty", "Dwight", "Dylan", ..
			"Earl", "Earnest", "Easter", "Easton", "Ed", "Edd", "Eddie", "Edgar", "Edgardo", "Edison", "Edmond", "Edmund", "Eduardo", "Edward", "Edwardo", "Edwin", "Efrain", "Efren", "Einar", "Eino", "Eladio", "Elbert", "Eldon", "Eldred", "Eleazar", "Eli", "Elian", "Elias", "Eliezer", "Elijah", "Eliseo", "Elliot", "Elliott", "Ellis", "Ellsworth", "Elmer", "Elmo", "Elmore", "Eloy", "Elroy", "Elton", "Elvis", "Elwin", "Elwyn", "Emanuel", "Emerald", "Emerson", "Emery", "Emil", "Emile", "Emiliano", "Emilio", "Emmanuel", "Emmet", "Emmett", "Emmitt", "Emory", "Enid", "Enoch", "Enos", "Enrico", "Enrique", "Ephraim", "Eriberto", "Eric", "Erich", "Erick", "Erik", "Erin", "Erling", "Ernest", "Ernesto", "Ernie", "Ervin", "Erwin", "Esteban", "Estevan", "Ethan", "Ethel", "Eugene", "Eusebio", "Evan", "Evans", "Everardo", "Everett", "Evert", "Ewald", "Ewell", "Ezekiel", "Ezequiel", "Ezra", ..
			"Fabian", "Faustino", "Fausto", "Favian", "Federico", "Felipe", "Felix", "Felton", "Fermin", "Fern", "Fernando", "Ferne", "Fidel", "Filiberto",  "Finn", "Flavio","Fletcher", "Florencio", "Florian", "Floy", "Floyd", "Ford", "Forest", "Forrest", "Foster", "Francesco", "Francis", "Francisco", "Franco", "Frank", "Frankie", "Franz", "Fred", "Freddie", "Freddy", "Frederic", "Frederick", "Frederik", "Fredrick", "Fredy", "Freeman", "Friedrich", "Fritz", "Furman", ..
			"Gabe", "Gabriel", "Gaetano", "Gage", "Gardner", "Garett", "Garfield", "Garland", "Garnet", "Garnett", "Garret", "Garrett", "Garrick", "Garrison", "Garry", "Garth", "Gaston", "Gavin", "Gay", "Gayle", "Gaylord", "Gene", "General", "Gennaro", "Geo", "Geoffrey", "George", "Geovanni", "Geovanny", "Geovany", "Gerald", "Gerard", "Gerardo", "Gerhard", "German", "Gerson", "Gianni", "Gideon", "Gilbert", "Gilberto", "Giles", "Gillian", "Gino", "Giovani", "Giovanni", "Giovanny","Giuseppe", "Glen", "Glennie", "Godfrey", "Golden", "Gonzalo", "Gordon", "Grady", "Graham", "Grant", "Granville", "Grayce", "Grayson", "Green", "Greg", "Gregg", "Gregorio", "Gregory", "Greyson", "Griffin", "Grover", "Guido", "Guillermo", "Guiseppe", "Gunnar", "Gunner", "Gus", "Gussie", "Gust", "Gustave", "Guy", ..
			"Hadley", "Hailey", "Hal", "Haleigh", "Haley", "Halle", "Hank", "Hans", "Hardy", "Harley", "Harmon", "Harold", "Harrison", "Harry", "Harvey", "Haskell", "Hassan", "Hayden", "Hayley", "Hazel", "Hazle", "Heber", "Hector", "Helmer", "Henderson", "Henri", "Henry", "Herbert", "Herman", "Hermann", "Herminio", "Hershel", "Hester", "Hilario", "Hilbert", "Hillard", "Hilton", "Hipolito", "Hiram", "Hobart", "Holden", "Hollis", "Horace", "Horacio", "Houston", "Howard", "Howell", "Hoyt", "Hubert", "Hudson", "Hugh", "Humberto", "Hunter", "Hyman", ..
			"Ian", "Ibrahim", "Ignacio", "Ignatius", "Ike", "Imani", "Immanuel", "Irving", "Irwin", "Isaac", "Isac", "Isadore", "Isai", "Isaiah", "Isaias", "Isidro", "Ismael", "Isom", "Israel", "Issac", "Izaiah", ..
			"Jabari", "Jace", "Jacey", "Jacinto", "Jack", "Jackson", "Jacques", "Jaden", "Jadon", "Jaeden", "Jaiden", "Jaime", "Jairo", "Jake", "Jakob", "Jaleel", "Jalen", "Jalon", "Jamaal", "Jamal", "Jamar", "Jamarcus", "Jamel", "Jameson", "Jamey", "Jamie", "Jamil", "Jamir", "Jamison", "Jan", "Janick", "Jaquan", "Jared", "Jaren", "Jarod", "Jaron", "Jarred", "Jarrell", "Jarret", "Jarrett", "Jarrod", "Jarvis", "Jasen", "Jasmin", "Jason", "Jasper", "Javier", "Javon", "Javonte", "Jay", "Jayce", "Jaycee",  "Jayde", "Jayden", "Jaydon", "Jaylan", "Jaylen", "Jaylin", "Jaylon", "Jayme", "Jayson", "Jean", "Jed", "Jedediah", "Jedidiah", "Jeff", "Jefferey", "Jeffery", "Jeffrey", "Jeffry", "Jennings", "Jensen", "Jerad", "Jerald", "Jeramie", "Jeramy", "Jerel", "Jeremie", "Jeremy", "Jermain", "Jermey", "Jerod", "Jerome", "Jeromy", "Jerrell", "Jerrod", "Jerrold", "Jerry", "Jess", "Jesse", "Jessie", "Jessy", "Jesus", "Jett", "Jettie", "Jevon", "Jillian", "Jimmie", "Jimmy", "Jo", "Joan", "Joany", "Joaquin", "Jocelyn", "Joe", "Joel",  "Joesph", "Joey", "Johan", "Johann", "Johathan", "John", "Johnathan", "Johnathon", "Johnnie", "Johnny", "Johnpaul", "Johnson", "Jon", "Jonas", "Jonatan", "Jonathan", "Jonathon", "Jordan", "Jordi", "Jordon", "Jordy", "Jordyn", "Jorge", "Jose", "Joseph", "Josh", "Joshua", "Joshuah", "Josiah", "Josue", "Jovan", "Jovani", "Jovanny", "Jovany", "Judah", "Judd", "Judge", "Judson", "Jules", "Julian", "Julien", "Julio", "Julius", "Junior", "Junius", "Justen", "Justice", "Juston", "Justus", "Justyn", "Juvenal", "Juwan", ..
			"Kacey", "Kade", "Kaden", "Kadin", "Kale", "Kaleb", "Kaleigh", "Kaley", "Kameron", "Kamren", "Kamron", "Kamryn", "Kane", "Kareem", "Karl", "Karley", "Karson", "Kay", "Kayden", "Kayleigh", "Kayley", "Keagan", "Keanu", "Keaton", "Keegan", "Keeley", "Keenan", "Keith", "Kellen", "Kelley", "Kelton", "Kelvin", "Ken", "Kendall", "Kendrick", "Kennedi", "Kennedy", "Kenneth", "Kennith", "Kenny", "Kenton", "Kenyon", "Keon", "Keshaun", "Keshawn", "Keven", "Kevin", "Kevon", "Keyon", "Keyshawn", "Khalid", "Khalil", "Kian", "Kiel", "Kieran", "Kiley", "Kim", "King", "Kip", "Kirk", "Kobe", "Koby", "Kody", "Kolby", "Kole", "Korbin", "Korey", "Kory", "Kraig", "Kris", "Kristian", "Kristofer", "Kristoffer", "Kristopher", "Kurt", "Kurtis", "Kyle", "Kyleigh", "Kyler", ..
			"Ladarius", "Lafayette", "Lamar", "Lambert", "Lamont", "Lance", "Landen", "Lane", "Laron", "Larry", "Larue", "Laurel", "Lavern", "Laverna", "Laverne", "Lavon", "Lawrence", "Lawson", "Layne", "Lazaro", "Lee", "Leif", "Leland", "Lemuel", "Lennie", "Lenny", "Leo", "Leon", "Leonard", "Leonardo", "Leone", "Leonel", "Leopold", "Leopoldo", "Lesley", "Lester", "Levi", "Lew", "Lewis", "Lexus", "Liam", "Lincoln", "Lindsey", "Linwood", "Lionel", "Lisandro", "Llewellyn", "Lloyd", "Logan", "Lon", "London", "Lonnie", "Lonny", "Lonzo", "Lorenz", "Lorenza", "Lorenzo", "Louie", "Louisa", "Lourdes", "Louvenia", "Lowell", "Loy", "Loyal", "Lucas", "Luciano", "Lucio", "Lucious", "Lucius", "Ludwig", "Luigi", "Luis", "Lukas", "Lula", "Luther", "Lyric", ..
			"Mac", "Macey", "Mack", "Mackenzie", "Madisen", "Madison", "Madyson", "Magnus", "Major", "Makenna", "Malachi", "Malcolm", "Mallory", "Manley", "Manuel", "Manuela", "Marc", "Marcel", "Marcelino", "Marcellus", "Marcelo", "Marco", "Marcos", "Marcus", "Mariano", "Mario", "Mark", "Markus", "Marley", "Marlin", "Marlon", "Marques", "Marquis", "Marshall", "Martin", "Marty", "Marvin", "Mason", "Mateo", "Mathew", "Mathias", "Matt", "Matteo", "Maurice", "Mauricio", "Maverick", "Mavis", "Max", "Maxime", "Maximilian", "Maximillian", "Maximo", "Maximus", "Maxine", "Maxwell", "Maynard", "Mckenna", "Mckenzie", "Mekhi", "Melany", "Melvin", "Melvina", "Merl", "Merle", "Merlin", "Merritt", "Mervin", "Micah", "Michael", "Michale", "Micheal", "Michel", "Miguel", "Mike", "Mikel", "Milan", "Miles", "Milford", "Miller", "Milo", "Milton", "Misael", "Mitchel", "Mitchell", "Modesto", "Mohamed", "Mohammad", "Mohammed", "Moises", "Monroe", "Monserrat", "Monserrate", "Montana", "Monte", "Monty", "Morgan", "Moriah", "Morris", "Mortimer", "Morton", "Mose", "Moses", "Moshe", "Muhammad", "Murl", "Murphy", "Murray", "Mustafa", "Myles",  "Myrl", "Myron", ..
			"Napoleon", "Narciso", "Nash", "Nasir", "Nat", "Nathan", "Nathanael", "Nathanial", "Nathaniel", "Nathen", "Neal", "Ned", "Neil", "Nels", "Nelson", "Nestor", "Newell", "Newton", "Nicholas", "Nicholaus", "Nick", "Nicklaus", "Nickolas", "Nico", "Nicola", "Nicolas", "Nigel", "Nikko", "Niko", "Nikolas", "Nils", "Noah", "Noble", "Noe", "Noel", "Nolan", "Norbert", "Norberto", "Norris", "Norval", "Norwood", ..
			"Obie", "Oda", "Odell", "Okey", "Ola", "Olaf", "Ole", "Olen", "Olin", "Oliver", "Omari", "Omer", "Oral", "Oran", "Oren", "Orin", "Orion", "Orland", "Orlando", "Orlo", "Orrin", "Orval", "Orville", "Osbaldo", "Osborne", "Oscar", "Osvaldo", "Oswald", "Oswaldo", "Otho", "Otis", "Ottis", "Otto", "Owen", ..
			"Pablo", "Paolo", "Paris", "Parker", "Patrick", "Paul", "Paxton", "Payton", "Pedro", "Percival", "Percy", "Perry", "Pete", "Peter", "Peyton", "Philip", "Pierce", "Pierre", "Pietro", "Porter", "Presley", "Preston", "Price", "Prince", ..
			"Quentin", "Quincy", "Quinn", "Quinten", "Quinton", ..
			"Rafael", "Raheem", "Rahul", "Raleigh", "Ralph", "Ramiro", "Ramon", "Randal", "Randall", "Randi", "Randy", "Ransom", "Raoul", "Raphael", "Rashad", "Rashawn", "Rasheed", "Raul", "Raven", "Ray", "Raymond", "Raymundo", "Reagan", "Reece", "Reed", "Reese", "Regan", "Reggie", "Reginald", "Reid", "Reilly","Reinhold", "Remington", "Rene", "Reuben", "Rex", "Rey", "Reyes", "Reymundo", "Reynold", "Rhett", "Rhiannon", "Ricardo", "Richard", "Richie", "Richmond", "Rick", "Rickey", "Rickie", "Ricky", "Rico", "Rigoberto", "Riley", "Robb", "Robbie", "Robert", "Roberto", "Robin", "Rocio", "Rocky", "Rod", "Roderick", "Rodger", "Rodolfo", "Rodrick", "Rodrigo", "Roel", "Rogelio", "Roger", "Rogers", "Rolando", "Rollin", "Roman", "Ron", "Ronaldo", "Ronny", "Roosevelt", "Rory", "Rosario", "Roscoe", "Rosendo", "Ross", "Rowan", "Rowland", "Roy", "Royal", "Royce", "Ruben", "Rudolph", "Rudy", "Rupert", "Russ", "Russel", "Russell", "Rusty", "Ryan", "Ryann", "Ryder", "Rylan", "Ryleigh", "Ryley", ..
			"Sage", "Saige", "Salvador", "Salvatore", "Sam", "Samir", "Sammie", "Sammy", "Samson", "Sanford", "Santa", "Santiago", "Santino", "Santos", "Saul", "Savion", "Schuyler", "Scot", "Scottie", "Scotty", "Seamus", "Sean", "Sebastian", "Sedrick", "Selmer", "Seth", "Shad", "Shane", "Shaun", "Shawn", "Shayne", "Sheldon", "Sheridan", "Sherman", "Sherwood", "Sid", "Sidney", "Sigmund", "Sigrid", "Sigurd", "Silas", "Sim", "Simeon", "Skye", "Skylar", "Sofia", "Soledad", "Solon", "Sonny", "Spencer", "Stan", "Stanford", "Stanley", "Stanton", "Stefan", "Stephan", "Stephen", "Stephon", "Sterling", "Steve", "Stevie", "Stewart", "Stone", "Stuart", "Sven", "Sydney", "Sylvan", "Sylvester", ..
			"Tad", "Talon", "Tanner", "Tate", "Tatum", "Taurean", "Tavares", "Taylor", "Ted", "Terence", "Terrance", "Terrell", "Terrence", "Terrill", "Terry", "Tevin", "Thad", "Thaddeus", "Theo", "Theodore", "Theron", "Thomas", "Thurman", "Tillman", "Timmothy", "Timmy", "Timothy", "Tito", "Titus", "Tobin", "Toby", "Tod", "Tom", "Tomas", "Tommie", "Toney", "Toni", "Tony", "Torey", "Torrance", "Torrey", "Toy", "Trace", "Tracey", "Travis", "Travon", "Tre", "Tremaine", "Tremayne", "Trent", "Trenton", "Trever", "Trevion", "Trevor", "Trey",  "Tristian", "Tristin", "Triston", "Troy", "Trystan", "Turner","Tyler", "Tyree", "Tyreek", "Tyrel", "Tyrell", "Tyrese", "Tyrique", "Tyshawn", "Tyson", ..
			"Ubaldo", "Ulices", "Ulises", "Unique", "Urban", "Uriah", "Uriel", ..
			"Valentin", "Van", "Vance", "Vaughn", "Vern", "Verner", "Vernon", "Vicente", "Victor", "Vidal", "Vince", "Vincent", "Vincenzo", "Vinnie", "Virgil", "Vito", "Vladimir", ..
			"Wade", "Waino", "Waldo", "Walker", "Wallace", "Walter", "Walton", "Ward", "Warren", "Watson", "Waylon", "Wayne", "Webster", "Weldon", "Wellington", "Wendell", "Werner", "Westley", "Weston", "Wilber", "Wilbert", "Wilburn", "Wiley", "Wilford", "Wilfred", "Wilfredo", "Wilfrid", "Wilhelm", "Will", "Willard", "William", "Willis", "Willy", "Wilmer", "Wilson", "Wilton", "Winfield", "Winston", "Woodrow", "Wyatt", "Wyman", ..
			"Xavier", "Xzavier", "Xander", ..
			"Zachariah", "Zachary", "Zachery", "Zack", "Zackary", "Zackery", "Zakary", "Zander", "Zane", "Zechariah", "Zion" ..
			]

		self.firstNamesFemale = [..
			"Aaliyah", "Abagail", "Abbey", "Abbie", "Abbigail", "Abby", "Abigail", "Abigale", "Abigayle", "Ada", "Adah", "Adaline", "Addie", "Addison", "Adela", "Adele", "Adelia", "Adeline", "Adell", "Adella", "Adelle", "Aditya", "Adriana", "Adrianna", "Adrienne", "Aglae", "Agnes", "Agustina", "Aida", "Aileen", "Aimee", "Aisha", "Aiyana", "Alaina", "Alana", "Alanis", "Alanna", "Alayna", "Alba", "Alberta", "Albertha", "Albina", "Alda", "Aleen", "Alejandra", "Alena", "Alene", "Alessandra", "Alessia", "Aletha", "Alexa", "Alexandra", "Alexandrea", "Alexandria", "Alexandrine", "Alexane", "Alexanne", "Alfreda", "Alia", "Alice", "Alicia", "Alisa", "Alisha", "Alison", "Alivia", "Aliya", "Aliyah", "Aliza", "Alize", "Allene", "Allie", "Allison", "Ally", "Alta", "Althea", "Alva", "Alvena", "Alvera", "Alverta", "Alvina", "Alyce", "Alycia", "Alysa", "Alysha", "Alyson", "Alysson", "Amalia", "Amanda", "Amara", "Amaya", "Amber", "Amelia", "Amelie", "Amely", "America", "Amie", "Amina", "Amira", "Amiya", "Amy", "Amya", "Ana", "Anabel", "Anabelle", "Anahi", "Anais", "Anastasia", "Andreane", "Andreanne", "Angela", "Angelica", "Angelina", "Angeline", "Angelita", "Angie", "Anika", "Anissa", "Anita", "Aniya", "Aniyah", "Anjali", "Anna", "Annabel", "Annabell", "Annabelle", "Annalise", "Annamae", "Annamarie", "Anne", "Annetta", "Annette", "Annie", "Antoinette", "Antonetta", "Antonette", "Antonia", "Antonietta", "Antonina", "Anya", "April", "Ara", "Araceli", "Aracely", "Ardella", "Ardith", "Ariane", "Arianna", "Arielle", "Arlene", "Arlie", "Arvilla", "Aryanna", "Asa", "Asha", "Ashlee", "Ashleigh", "Ashley", "Ashly", "Ashlynn", "Ashtyn", "Asia", "Assunta", "Astrid", "Athena", "Aubree", "Aubrey", "Audie", "Audra", "Audreanne", "Audrey", "Augusta", "Augustine", "Aurelia", "Aurelie", "Aurore", "Autumn", "Ava", "Avis", "Ayana", "Ayla", "Aylin", ..
			"Baby", "Bailee", "Barbara", "Beatrice", "Beaulah", "Bella", "Belle", "Berenice", "Bernadette", "Bernadine", "Berneice", "Bernice", "Berniece", "Bernita", "Bert", "Beryl", "Bessie", "Beth", "Bethany", "Bethel", "Betsy", "Bette", "Bettie", "Betty", "Bettye", "Beulah", "Beverly", "Bianka", "Billie", "Birdie", "Blanca", "Blanche", "Bonita", "Bonnie", "Brandi", "Brandy", "Brandyn", "Breana", "Breanna", "Breanne", "Brenda", "Brenna", "Bria", "Briana", "Brianne", "Bridget", "Bridgette", "Bridie", "Brielle", "Brigitte", "Brionna", "Brisa", "Britney", "Brittany", "Brooke", "Brooklyn", "Bryana", "Bulah", "Burdette", "Burnice", ..
			"Caitlyn", "Caleigh", "Cali", "Calista", "Callie", "Camila", "Camilla", "Camille", "Camylle", "Candace", "Candice", "Candida", "Cara", "Carissa", "Carlee", "Carley", "Carli", "Carlie", "Carlotta", "Carmela", "Carmella", "Carmen", "Carolanne", "Carole", "Carolina", "Caroline", "Carolyn", "Carolyne", "Carrie", "Casandra", "Cassandra", "Cassandre", "Cassidy", "Cassie", "Catalina", "Caterina", "Catharine", "Catherine", "Cathrine", "Cathryn", "Cathy", "Cayla", "Cecelia", "Cecile", "Cecilia", "Celestine", "Celia", "Celine", "Chanel", "Chanelle", "Charity", "Charlene", "Charlotte", "Chasity", "Chaya", "Chelsea", "Chelsie", "Cheyanne", "Cheyenne", "Chloe", "Christa", "Christelle", "Christiana", "Christina", "Christine", "Christy", "Chyna", "Ciara", "Cierra", "Cindy", "Citlalli", "Claire", "Clara", "Clarabelle", "Clare", "Clarissa", "Claudia", "Claudie", "Claudine", "Clementina", "Clementine", "Clemmie", "Cleora", "Cleta", "Clotilde", "Colleen", "Concepcion", "Connie", "Constance", "Cora", "Coralie", "Cordia", "Cordie", "Corene", "Corine", "Corrine", "Cortney", "Courtney", "Creola", "Cristal", "Crystal", "Crystel", "Cydney", "Cynthia", ..
			"Dahlia", "Daija", "Daisha", "Daisy", "Dakota", "Damaris", "Dana", "Dandre", "Daniela", "Daniella", "Danielle", "Danika", "Dannie", "Danyka", "Daphne", "Daphnee", "Daphney", "Darby", "Dariana", "Darlene", "Dasia", "Dawn", "Dayana", "Dayna", "Deanna", "Deborah", "Deja", "Dejah", "Delfina", "Delia", "Delilah", "Della", "Delores", "Delpha", "Delphia", "Delphine", "Delta", "Demetris", "Dena", "Desiree", "Dessie", "Destany", "Destinee", "Destiney", "Destini", "Destiny", "Diana", "Dianna", "Dina", "Dixie", "Dolly", "Dolores", "Domenica", "Dominique", "Donna", "Dora", "Dorothea", "Dorothy", "Dorris", "Dortha", "Dovie", "Drew", "Duane", "Dulce", ..
			"Earlene", "Earline", "Earnestine", "Ebba", "Ebony", "Eda", "Eden", "Edna", "Edwina", "Edyth", "Edythe", "Effie", "Eileen", "Elaina", "Elda", "Eldora", "Eldridge", "Eleanora", "Eleanore", "Electa", "Elena", "Elenor", "Elenora", "Eleonore", "Elfrieda", "Eliane", "Elinor", "Elinore", "Elisa", "Elisabeth", "Elise", "Elisha", "Elissa", "Eliza", "Elizabeth", "Ella", "Ellen", "Ellie", "Elmira", "Elna", "Elnora", "Elody", "Eloisa", "Eloise", "Elouise", "Elsa", "Else", "Elsie", "Elta", "Elva", "Elvera", "Elvie", "Elyse", "Elyssa", "Elza", "Emelia", "Emelie", "Emely", "Emie", "Emilia", "Emilie", "Emily", "Emma", "Emmalee", "Emmanuelle", "Emmie", "Emmy", "Ena", "Enola", "Era", "Erica", "Ericka", "Erika", "Erna", "Ernestina", "Ernestine", "Eryn", "Esmeralda", "Esperanza", "Esta", "Estefania", "Estel", "Estell", "Estella", "Estelle", "Esther", "Estrella", "Etha", "Ethelyn", "Ethyl", "Ettie", "Eudora", "Eugenia", "Eula", "Eulah", "Eulalia", "Euna", "Eunice", "Eva", "Evalyn", "Evangeline", "Eve", "Eveline", "Evelyn", "Everette", "Evie", ..
			"Fabiola", "Fae", "Fannie", "Fanny", "Fatima", "Fay", "Faye", "Felicia", "Felicita", "Felicity", "Felipa", "Filomena", "Fiona", "Flavie", "Fleta", "Flo", "Florence", "Florida", "Florine", "Flossie", "Frances", "Francesca", "Francisca", "Freda", "Frederique", "Freeda", "Freida", "Frida", "Frieda", ..
			"Gabriella", "Gabrielle", "Gail", "Genesis", "Genevieve", "Genoveva", "Georgette", "Georgiana", "Georgianna", "Geraldine", "Gerda", "Germaine", "Gerry", "Gertrude", "Gia", "Gilda", "Gina", "Giovanna", "Gisselle", "Gladyce", "Gladys", "Glenda", "Glenna", "Gloria", "Golda", "Grace", "Gracie", "Graciela", "Gregoria", "Greta", "Gretchen", "Guadalupe", "Gudrun", "Gwen", "Gwendolyn", ..
			"Hailee", "Hailie", "Halie", "Hallie", "Hanna", "Hannah", "Harmony", "Hassie", "Hattie", "Haven", "Haylee", "Haylie", "Heath", "Heather", "Heaven", "Heidi", "Helen", "Helena", "Helene", "Helga", "Hellen", "Heloise", "Henriette", "Hermina", "Herminia", "Herta", "Hertha", "Hettie", "Hilda", "Hildegard", "Hillary", "Hilma", "Hollie", "Holly", "Hope", "Hortense", "Hosea", "Hulda", ..
			"Icie", "Ida", "Idell", "Idella", "Ila", "Ilene", "Iliana", "Ima", "Imelda", "Imogene", "Ines", "Irma", "Isabel", "Isabell", "Isabella", "Isabelle", "Isobel", "Itzel", "Iva", "Ivah", "Ivory", "Ivy", "Izabella", ..
			"Jacinthe", "Jackeline", "Jackie", "Jacklyn", "Jacky", "Jaclyn", "Jacquelyn", "Jacynthe", "Jada", "Jade", "Jadyn", "Jaida", "Jailyn", "Jakayla", "Jalyn", "Jammie", "Jana", "Janae", "Jane", "Janelle", "Janessa", "Janet", "Janice", "Janie", "Janis", "Janiya", "Jannie", "Jany", "Jaquelin", "Jaqueline", "Jaunita", "Jayda", "Jayne", "Jazlyn", "Jazmin", "Jazmyn", "Jazmyne", "Jeanette", "Jeanie", "Jeanne", "Jena", "Jenifer", "Jennie", "Jennifer", "Jennyfer", "Jermaine", "Jessica", "Jessika", "Jessyca", "Jewel", "Jewell", "Joana", "Joanie", "Joanne", "Joannie", "Joanny", "Jodie", "Jody", "Joelle", "Johanna", "Jolie", "Jordane", "Josefa", "Josefina", "Josephine", "Josiane", "Josianne", "Josie", "Joy", "Joyce", "Juana", "Juanita", "Jude", "Judy", "Julia", "Juliana", "Julianne", "Julie", "Juliet", "June", "Justina", "Justine", ..
			"Kaci", "Kacie", "Kaela", "Kaelyn", "Kaia", "Kailee", "Kailey", "Kailyn", "Kaitlin", "Kaitlyn", "Kali", "Kallie", "Kamille", "Kara", "Karelle", "Karen", "Kari", "Kariane", "Karianne", "Karina", "Karine", "Karlee", "Karli", "Karlie", "Karolann", "Kasandra", "Kasey", "Kassandra", "Katarina", "Katelin", "Katelyn", "Katelynn", "Katharina", "Katherine", "Katheryn", "Kathleen", "Kathlyn", "Kathryn", "Kathryne", "Katlyn", "Katlynn", "Katrina", "Katrine", "Kattie", "Kavon", "Kaya", "Kaycee", "Kayla", "Kaylah", "Kaylee", "Kayli", "Kaylie", "Kaylin", "Keara", "Keely", "Keira", "Kelli", "Kellie", "Kelly", "Kelsi", "Kelsie", "Kendra", "Kenna", "Kenya", "Kenyatta", "Kiana", "Kianna", "Kiara", "Kiarra", "Kiera", "Kimberly", "Kira", "Kirsten", "Kirstin", "Kitty", "Krista", "Kristin", "Kristina", "Kristy", "Krystal", "Krystel", "Krystina", "Kyla", "Kylee", "Kylie", "Kyra", ..
			"Lacey", "Lacy", "Laila", "Laisha", "Laney", "Larissa", "Laura", "Lauren", "Laurence", "Lauretta", "Lauriane", "Laurianne", "Laurie", "Laurine", "Laury", "Lauryn", "Lavada", "Lavina", "Lavinia", "Lavonne", "Layla", "Lea", "Leann", "Leanna", "Leanne", "Leatha", "Leda", "Leila", "Leilani", "Lela", "Lelah", "Lelia", "Lempi", "Lenna", "Lenora", "Lenore", "Leola", "Leonie", "Leonor", "Leonora", "Leora", "Lera", "Leslie", "Lesly", "Lessie", "Leta", "Letha", "Letitia", "Lexi", "Lexie", "Lia", "Liana", "Libbie", "Libby", "Lila", "Lilian", "Liliana", "Liliane", "Lilla", "Lillian", "Lilliana", "Lillie", "Lilly", "Lily", "Lilyan", "Lina", "Linda", "Lindsay", "Linnea", "Linnie", "Lisa", "Lisette", "Litzy", "Liza", "Lizeth", "Lizzie", "Lois", "Lola", "Lolita", "Loma", "Lonie", "Lora", "Loraine", "Loren", "Lorena", "Lori", "Lorine", "Lorna", "Lottie", "Lou", "Loyce", "Lucie", "Lucienne", "Lucile", "Lucinda", "Lucy", "Ludie", "Lue", "Luella", "Luisa", "Lulu", "Luna", "Lupe", "Lura", "Lurline", "Luz", "Lyda", "Lydia", "Lyla", "Lynn", "Lysanne", ..
			"Mabel", "Mabelle", "Mable", "Maci", "Macie", "Macy", "Madaline", "Madalyn", "Maddison", "Madeline", "Madelyn", "Madelynn", "Madge", "Madie", "Madilyn", "Madisyn", "Madonna", "Mae", "Maegan", "Maeve", "Mafalda", "Magali", "Magdalen", "Magdalena", "Maggie", "Magnolia", "Maia", "Maida", "Maiya", "Makayla", "Makenzie", "Malika", "Malinda", "Mallie", "Malvina", "Mandy", "Mara", "Marcelina", "Marcella", "Marcelle", "Marcia", "Margaret", "Margarete", "Margarett", "Margaretta", "Margarette", "Margarita", "Marge", "Margie", "Margot", "Margret", "Marguerite", "Maria", "Mariah", "Mariam", "Marian", "Mariana", "Mariane", "Marianna", "Marianne", "Maribel", "Marie", "Mariela", "Marielle", "Marietta", "Marilie", "Marilou", "Marilyne", "Marina", "Marion", "Marisa", "Marisol", "Maritza", "Marjolaine", "Marjorie", "Marjory", "Marlee", "Marlen", "Marlene", "Marquise", "Marta", "Martina", "Martine", "Mary", "Maryam", "Maryjane", "Maryse", "Mathilde", "Matilda", "Matilde", "Mattie", "Maud", "Maude", "Maudie", "Maureen", "Maurine", "Maxie", "Maximillia", "May", "Maya", "Maybell", "Maybelle", "Maye", "Maymie", "Mayra", "Mazie", "Mckayla", "Meagan", "Meaghan", "Meda", "Megane", "Meggie", "Meghan", "Melba", "Melisa", "Melissa", "Mellie", "Melody", "Melyna", "Melyssa", "Mercedes", "Meredith", "Mertie", "Meta", "Mia", "Micaela", "Michaela", "Michele", "Michelle", "Mikayla", "Millie", "Mina", "Minerva", "Minnie", "Miracle", "Mireille", "Mireya", "Missouri", "Misty", "Mittie", "Modesta", "Mollie", "Molly", "Mona", "Monica", "Monique", "Mossie", "Mozell", "Mozelle", "Muriel", "Mya", "Myah", "Mylene", "Myra", "Myriam", "Myrna", "Myrtice", "Myrtie", "Myrtis", "Myrtle", ..
			"Nadia", "Nakia", "Name", "Nannie", "Naomi", "Naomie", "Natalia", "Natalie", "Natasha", "Nayeli", "Nedra", "Neha", "Nelda", "Nella", "Nelle", "Nellie", "Neoma", "Nettie", "Neva", "Nia", "Nichole", "Nicole", "Nicolette", "Nikita", "Nikki", "Nina", "Noelia", "Noemi", "Noemie", "Noemy", "Nola", "Nona", "Nora", "Norene", "Norma", "Nova", "Novella", "Nya", "Nyah", "Nyasia", ..
			"Oceane", "Ocie", "Octavia", "Odessa", "Odie", "Ofelia", "Oleta", "Olga", "Ollie", "Oma", "Ona", "Onie", "Opal", "Ophelia", "Ora", "Orie", "Orpha", "Otha", "Otilia", "Ottilie", "Ova", "Ozella", ..
			"Paige", "Palma", "Pamela", "Pansy", "Pascale", "Pasquale", "Pat", "Patience", "Patricia", "Patsy", "Pattie", "Paula", "Pauline", "Pearl", "Pearlie", "Pearline", "Peggie", "Penelope", "Petra", "Phoebe", "Phyllis", "Pink", "Pinkie", "Piper", "Polly", "Precious", "Princess", "Priscilla", "Providenci", "Prudence", ..
			"Queen", "Queenie", ..
			"Rachael", "Rachel", "Rachelle", "Rae", "Raegan", "Rafaela", "Rahsaan", "Raina", "Ramona", "Raphaelle", "Raquel", "Reanna", "Reba", "Rebeca", "Rebecca", "Rebeka", "Rebekah", "Reina", "Renee", "Ressie", "Reta", "Retha", "Retta", "Reva", "Reyna", "Rhea", "Rhianna", "Rhoda", "Rita", "River", "Roberta", "Robyn", "Roma", "Romaine", "Rosa", "Rosalee", "Rosalia", "Rosalind", "Rosalinda", "Rosalyn", "Rosamond", "Rosanna", "Rose", "Rosella", "Roselyn", "Rosemarie", "Rosemary", "Rosetta", "Rosie", "Rosina", "Roslyn", "Rossie", "Rowena", "Roxane", "Roxanne", "Rozella", "Rubie", "Ruby", "Rubye", "Ruth", "Ruthe", "Ruthie", "Rylee", ..
			"Sabina", "Sabrina", "Sabryna", "Sadie", "Sadye", "Sallie", "Sally", "Salma", "Samanta", "Samantha", "Samara", "Sandra", "Sandrine", "Sandy", "Santina", "Sarah", "Sarai", "Sarina", "Sasha", "Savanah", "Savanna", "Savannah", "Scarlett", "Selena", "Selina", "Serena", "Serenity", "Shaina", "Shakira", "Shana", "Shanel", "Shanelle", "Shania", "Shanie", "Shaniya", "Shanna", "Shannon", "Shanny", "Shanon", "Shany", "Sharon", "Shawna", "Shaylee", "Shayna", "Shea", "Sheila", "Shemar", "Shirley", "Shyann", "Shyanne", "Sibyl", "Sienna", "Sierra", "Simone", "Sincere", "Sister", "Skyla", "Sonia", "Sonya", "Sophia", "Sophie", "Stacey", "Stacy", "Stefanie", "Stella", "Stephania", "Stephanie", "Stephany", "Summer", "Sunny", "Susan", "Susana", "Susanna", "Susie", "Suzanne", "Syble", "Sydnee", "Sydni", "Sydnie", "Sylvia", ..
			"Tabitha", "Talia", "Tamara", "Tamia", "Tania", "Tanya", "Tara", "Taryn", "Tatyana", "Taya", "Teagan", "Telly", "Teresa", "Tess", "Tessie", "Thalia", "Thea", "Thelma", "Theodora", "Theresa", "Therese", "Theresia", "Thora", "Tia", "Tiana", "Tianna", "Tiara", "Tierra", "Tiffany", "Tina", "Tomasa", "Tracy", "Tressa", "Tressie", "Treva", "Trinity", "Trisha", "Trudie", "Trycia", "Twila", "Tyra", ..
			"Una", "Ursula", ..
			"Vada", "Valentina", "Valentine", "Valerie", "Vallie", "Vanessa", "Veda", "Velda", "Vella", "Velma", "Velva", "Vena", "Verda", "Verdie", "Vergie", "Verla", "Verlie", "Verna", "Vernice", "Vernie", "Verona", "Veronica", "Vesta", "Vicenta", "Vickie", "Vicky", "Victoria", "Vida", "Vilma", "Vincenza", "Viola", "Violet", "Violette", "Virgie", "Virginia", "Virginie", "Vita", "Viva", "Vivian", "Viviane", "Vivianne", "Vivien", "Vivienne", ..
			"Wanda", "Wava", "Wendy", "Whitney", "Wilhelmine", "Willa", "Willie", "Willow", "Wilma", "Winifred", "Winnifred", "Winona", ..
			"Yadira", "Yasmeen", "Yasmin", "Yasmine", "Yazmin", "Yesenia", "Yessenia", "Yolanda", "Yoshiko", "Yvette", "Yvonne", ..
			"Zaria", "Zelda", "Zella", "Zelma", "Zena", "Zetta", "Zita", "Zoe", "Zoey", "Zoie", "Zoila", "Zola", "Zora", "Zula" ..
        	]

		self.lastNames = [ ..
			"Abbott", "Abernathy", "Abshire", "Adams", "Altenwerth", "Anderson", "Ankunding", "Armstrong", "Auer", "Aufderhar", ..
			"Bahringer", "Bailey", "Balistreri", "Barrows", "Bartell", "Bartoletti", "Barton", "Bashirian", "Batz", "Bauch", "Baumbach", "Bayer", "Beahan", "Beatty", "Bechtelar", "Becker", "Bednar", "Beer", "Beier", "Berge", "Bergnaum", "Bergstrom", "Bernhard", "Bernier", "Bins", "Blanda", "Blick", "Block", "Bode", "Boehm", "Bogan", "Bogisich", "Borer", "Bosco", "Botsford", "Boyer", "Boyle", "Bradtke", "Brakus", "Braun", "Breitenberg", "Brekke", "Brown", "Bruen", "Buckridge", ..
			"Carroll", "Carter", "Cartwright", "Casper", "Cassin", "Champlin", "Christiansen", "Cole", "Collier", "Collins", "Conn", "Connelly", "Conroy", "Considine", "Corkery", "Cormier", "Corwin", "Cremin", "Crist", "Crona", "Cronin", "Crooks", "Cruickshank", "Cummerata", "Cummings", ..
			"Dach", "D'Amore", "Daniel", "Dare", "Daugherty", "Davis", "Deckow", "Denesik", "Dibbert", "Dickens", "Dicki", "Dickinson", "Dietrich", "Donnelly", "Dooley", "Douglas", "Doyle", "DuBuque", "Durgan", ..
			"Ebert", "Effertz", "Eichmann", "Emard", "Emmerich", "Erdman", "Ernser", "Fadel", ..
			"Fahey", "Farrell", "Fay", "Feeney", "Feest", "Feil", "Ferry", "Fisher", "Flatley", "Frami", "Franecki", "Friesen", "Fritsch", "Funk", ..
			"Gaylord", "Gerhold", "Gerlach", "Gibson", "Gislason", "Gleason", "Gleichner", "Glover", "Goldner", "Goodwin", "Gorczany", "Gottlieb", "Goyette", "Grady", "Graham", "Grant", "Green", "Greenfelder", "Greenholt", "Grimes", "Gulgowski", "Gusikowski", "Gutkowski", "Gutmann", ..
			"Haag", "Hackett", "Hagenes", "Hahn", "Haley", "Halvorson", "Hamill", "Hammes", "Hand", "Hane", "Hansen", "Harber", "Harris", "Hartmann", "Harvey", "Hauck", "Hayes", "Heaney", "Heathcote", "Hegmann", "Heidenreich", "Heller", "Herman", "Hermann", "Hermiston", "Herzog", "Hessel", "Hettinger", "Hickle", "Hilll", "Hills", "Hilpert", "Hintz", "Hirthe", "Hodkiewicz", "Hoeger", "Homenick", "Hoppe", "Howe", "Howell", "Hudson", "Huel", "Huels", "Hyatt", ..
			"Jacobi", "Jacobs", "Jacobson", "Jakubowski", "Jaskolski", "Jast", "Jenkins", "Jerde", "Johns", "Johnson", "Johnston", "Jones", ..
			"Kassulke", "Kautzer", "Keebler", "Keeling", "Kemmer", "Kerluke", "Kertzmann", "Kessler", "Kiehn", "Kihn", "Kilback", "King", "Kirlin", "Klein", "Kling", "Klocko", "Koch", "Koelpin", "Koepp", "Kohler", "Konopelski", "Koss", "Kovacek", "Kozey", "Krajcik", "Kreiger", "Kris", "Kshlerin", "Kub", "Kuhic", "Kuhlman", "Kuhn", "Kulas", "Kunde", "Kunze", "Kuphal", "Kutch", "Kuvalis", ..
			"Labadie", "Lakin", "Lang", "Langosh", "Langworth", "Larkin", "Larson", "Leannon", "Lebsack", "Ledner", "Leffler", "Legros", "Lehner", "Lemke", "Lesch", "Leuschke", "Lind", "Lindgren", "Littel", "Little", "Lockman", "Lowe", "Lubowitz", "Lueilwitz", "Luettgen", "Lynch", ..
			"Macejkovic", "Maggio", "Mann", "Mante", "Marks", "Marquardt", "Marvin", "Mayer", "Mayert", "McClure", "McCullough", "McDermott", "McGlynn", "McKenzie", "McLaughlin", "Medhurst", "Mertz", "Metz", "Miller", "Mills", "Mitchell", "Moen", "Mohr", "Monahan", "Moore", "Morar", "Morissette", "Mosciski", "Mraz", "Mueller", "Muller", "Murazik", "Murphy", "Murray", ..
			"Nader", "Nicolas", "Nienow", "Nikolaus", "Nitzsche", "Nolan", ..
			"Oberbrunner", "O'Connell", "O'Conner", "O'Hara", "O'Keefe", "O'Kon", "Okuneva", "Olson", "Ondricka", "O'Reilly", "Orn", "Ortiz", "Osinski", ..
			"Pacocha", "Padberg", "Pagac", "Parisian", "Parker", "Paucek", "Pfannerstill", "Pfeffer", "Pollich", "Pouros", "Powlowski", "Predovic", "Price", "Prohaska", "Prosacco", "Purdy", ..
			"Quigley", "Quitzon", ..
			"Rath", "Ratke", "Rau", "Raynor", "Reichel", "Reichert", "Reilly", "Reinger", "Rempel", "Renner", "Reynolds", "Rice", "Rippin", "Ritchie", "Robel", "Roberts", "Rodriguez", "Rogahn", "Rohan", "Rolfson", "Romaguera", "Roob", "Rosenbaum", "Rowe", "Ruecker", "Runolfsdottir", "Runolfsson", "Runte", "Russel", "Rutherford", "Ryan", "Sanford", "Satterfield", "Sauer", "Sawayn", ..
			"Schaden", "Schaefer", "Schamberger", "Schiller", "Schimmel", "Schinner", "Schmeler", "Schmidt", "Schmitt", "Schneider", "Schoen", "Schowalter", "Schroeder", "Schulist", "Schultz", "Schumm", "Schuppe", "Schuster", "Senger", "Shanahan", "Shields", "Simonis", "Sipes", "Skiles", "Smith", "Smitham", "Spencer", "Spinka", "Sporer", "Stamm", "Stanton", "Stark", "Stehr", "Steuber", "Stiedemann", "Stokes", "Stoltenberg", "Stracke", "Streich", "Stroman", "Strosin", "Swaniawski", "Swift", ..
			"Terry", "Thiel", "Thompson", "Tillman", "Torp", "Torphy", "Towne", "Toy", "Trantow", "Tremblay", "Treutel", "Tromp", "Turcotte", "Turner", ..
			"Ullrich", "Upton", ..
			"Vandervort", "Veum", "Volkman", "Von", "VonRueden", ..
			"Waelchi", "Walker", "Walsh", "Walter", "Ward", "Waters", "Watsica", "Weber", "Wehner", "Weimann", "Weissnat", "Welch", "West", "White", "Wiegand", "Wilderman", "Wilkinson", "Will", "Williamson", "Willms", "Windler", "Wintheiser", "Wisoky", "Wisozk", "Witting", "Wiza", "Wolf", "Wolff", "Wuckert", "Wunsch", "Wyman", ..
			"Yost", "Yundt", ..
			"Zboncak", "Zemlak", "Ziemann", "Zieme", "Zulauf" ..
			]
	End Method
End Type




'=== DENMARK ===
Type TPersonGeneratorCountry_Denmark extends TPersonGeneratorCountry
	Method New()
		self.countryCode = "dk"
		
		self.firstNamesMale = [..
			"Aage", "Adam", "Adolf", "Ahmad", "Ahmed", "Aksel", "Albert", "Alex", "Alexander", "Alf", "Alfred", "Ali", "Allan", ..
			"Anders", "Andreas", "Anker", "Anton", "Arne", "Arnold", "Arthur", "Asbjørn", "Asger", "August", "Axel", "Benjamin", ..
			"Benny", "Bent", "Bernhard", "Birger", "Bjarne", "Bjørn", "Bo", "Brian", "Bruno", "Børge", "Carl", "Carlo", ..
			"Carsten", "Casper", "Charles", "Chris", "Christian", "Christoffer", "Christopher", "Claus", "Dan", "Daniel", "David", "Dennis", ..
			"Ebbe", "Edmund", "Edvard", "Egon", "Einar", "Ejvind", "Elias", "Emanuel", "Emil", "Erik", "Erland", "Erling", ..
			"Ernst", "Esben", "Ferdinand", "Finn", "Flemming", "Frank", "Freddy", "Frederik", "Frits", "Fritz", "Frode", "Georg", ..
			"Gerhard", "Gert", "Gunnar", "Gustav", "Hans", "Harald", "Harry", "Hassan", "Heine", "Heinrich", "Helge", "Helmer", ..
			"Helmuth", "Henning", "Henrik", "Henry", "Herman", "Hermann", "Holger", "Hugo", "Ib", "Ibrahim", "Ivan", "Jack", ..
			"Jacob", "Jakob", "Jan", "Janne", "Jens", "Jeppe", "Jesper", "Jimmi", "Jimmy", "Joachim", "Johan", "Johannes", ..
			"John", "Johnny", "Jon", "Jonas", "Jonathan", "Josef", "Jul", "Julius", "Jørgen", "Jørn", "Kai", "Kaj", ..
			"Karl", "Karlo", "Karsten", "Kasper", "Kenneth", "Kent", "Kevin", "Kjeld", "Klaus", "Knud", "Kristian", "Kristoffer", ..
			"Kurt", "Lars", "Lasse", "Leif", "Lennart", "Leo", "Leon", "Louis", "Lucas", "Lukas", "Mads", "Magnus", ..
			"Malthe", "Marc", "Marcus", "Marinus", "Marius", "Mark", "Markus", "Martin", "Martinus", "Mathias", "Max", "Michael", ..
			"Mikael", "Mike", "Mikkel", "Mogens", "Mohamad", "Mohamed", "Mohammad", "Morten", "Nick", "Nicklas", "Nicolai", "Nicolaj", ..
			"Niels", "Niklas", "Nikolaj", "Nils", "Olaf", "Olav", "Ole", "Oliver", "Oscar", "Oskar", "Otto", "Ove", ..
			"Palle", "Patrick", "Paul", "Peder", "Per", "Peter", "Philip", "Poul", "Preben", "Rasmus", "Rene", "René", ..
			"Richard", "Robert", "Rolf", "Rudolf", "Rune", "Sebastian", "Sigurd", "Simon", "Simone", "Steen", "Stefan", "Steffen", ..
			"Sten", "Stig", "Sune", "Sven", "Svend", "Søren", "Tage", "Theodor", "Thomas", "Thor", "Thorvald", "Tim", ..
			"Tobias", "Tom", "Tommy", "Tonny", "Torben", "Troels", "Uffe", "Ulrik", "Vagn", "Vagner", "Valdemar", "Vang", ..
			"Verner", "Victor", "Viktor", "Villy", "Walther", "Werner", "Wilhelm", "William", "Willy", "Åge", "Bendt", "Bjarke", ..
			"Chr", "Eigil", "Ejgil", "Ejler", "Ejnar", "Ejner", "Evald", "Folmer", "Gunner", "Gurli", "Hartvig", "Herluf", "Hjalmar", ..
			"Ingemann", "Ingolf", "Ingvard", "Keld", "Kresten", "Laurids", "Laurits", "Lauritz", "Ludvig", "Lynge", "Oluf", "Osvald", ..
			"Povl", "Richardt", "Sigfred", "Sofus", "Thorkild", "Viggo", "Vilhelm", "Villiam" ..
       		]

		self.firstNamesFemale = [..
			"Aase", "Agathe", "Agnes", "Alberte", "Alexandra", "Alice", "Alma", "Amalie", "Amanda", "Andrea", "Ane", "Anette", "Anita", ..
			"Anja", "Ann", "Anna", "Annalise", "Anne", "Anne-Lise", "Anne-Marie", "Anne-Mette", "Annelise", "Annette", "Anni", "Annie", ..
			"Annika", "Anny", "Asta", "Astrid", "Augusta", "Benedikte", "Bente", "Berit", "Bertha", "Betina", "Bettina", "Betty", ..
			"Birgit", "Birgitte", "Birte", "Birthe", "Bitten", "Bodil", "Britt", "Britta", "Camilla", "Carina", "Carla", "Caroline", ..
			"Cathrine", "Cecilie", "Charlotte", "Christa", "Christen", "Christiane", "Christina", "Christine", "Clara", "Conni", "Connie", "Conny", ..
			"Dagmar", "Dagny", "Diana", "Ditte", "Dora", "Doris", "Dorte", "Dorthe", "Ebba", "Edel", "Edith", "Eleonora", ..
			"Eli", "Elin", "Eline", "Elinor", "Elisa", "Elisabeth", "Elise", "Ella", "Ellen", "Ellinor", "Elly", "Elna", ..
			"Elsa", "Else", "Elsebeth", "Elvira", "Emilie", "Emma", "Emmy", "Erna", "Ester", "Esther", "Eva", "Evelyn", ..
			"Frede", "Frederikke", "Freja", "Frida", "Gerda", "Gertrud", "Gitte", "Grete", "Grethe", "Gudrun", "Hanna", "Hanne", ..
			"Hardy", "Harriet", "Hedvig", "Heidi", "Helen", "Helena", "Helene", "Helga", "Helle", "Henny", "Henriette", "Herdis", ..
			"Hilda", "Iben", "Ida", "Ilse", "Ina", "Inga", "Inge", "Ingeborg", "Ingelise", "Inger", "Ingrid", "Irene", ..
			"Iris", "Irma", "Isabella", "Jane", "Janni", "Jannie", "Jeanette", "Jeanne", "Jenny", "Jes", "Jette", "Joan", ..
			"Johanna", "Johanne", "Jonna", "Josefine", "Josephine", "Juliane", "Julie", "Jytte", "Kaja", "Kamilla", "Karen", "Karin", ..
			"Karina", "Karla", "Karoline", "Kate", "Kathrine", "Katja", "Katrine", "Ketty", "Kim", "Kirsten", "Kirstine", "Klara", ..
			"Krista", "Kristen", "Kristina", "Kristine", "Laila", "Laura", "Laurine", "Lea", "Lena", "Lene", "Lilian", "Lilli", ..
			"Lillian", "Lilly", "Linda", "Line", "Lis", "Lisa", "Lisbet", "Lisbeth", "Lise", "Liselotte", "Lissi", "Lissy", ..
			"Liv", "Lizzie", "Lone", "Lotte", "Louise", "Lydia", "Lykke", "Lærke", "Magda", "Magdalene", "Mai", "Maiken", ..
			"Maj", "Maja", "Majbritt", "Malene", "Maren", "Margit", "Margrethe", "Maria", "Mariane", "Marianne", "Marie", "Marlene", ..
			"Martha", "Martine", "Mary", "Mathilde", "Matilde", "Merete", "Merethe", "Meta", "Mette", "Mia", "Michelle", "Mie", ..
			"Mille", "Minna", "Mona", "Monica", "Nadia", "Nancy", "Nanna", "Nicoline", "Nikoline", "Nina", "Ninna", "Oda", ..
			"Olga", "Olivia", "Orla", "Paula", "Pauline", "Pernille", "Petra", "Pia", "Poula", "Ragnhild", "Randi", "Rasmine", ..
			"Rebecca", "Rebekka", "Rigmor", "Rikke", "Rita", "Rosa", "Rose", "Ruth", "Sabrina", "Sandra", "Sanne", "Sara", ..
			"Sarah", "Selma", "Severin", "Sidsel", "Signe", "Sigrid", "Sine", "Sofia", "Sofie", "Solveig", "Solvejg", "Sonja", ..
			"Sophie", "Stephanie", "Stine", "Susan", "Susanne", "Tanja", "Thea", "Theodora", "Therese", "Thi", "Thyra", "Tina", ..
			"Tine", "Tove", "Trine", "Ulla", "Vera", "Vibeke", "Victoria", "Viktoria", "Viola", "Vita", "Vivi", "Vivian", ..
			"Winnie", "Yrsa", "Yvonne", "Agnete", "Agnethe", "Alfrida", "Alvilda", "Anine", "Bolette", "Dorthea", "Gunhild", ..
			"Hansine", "Inge-Lise", "Jensine", "Juel", "Jørgine", "Kamma", "Kristiane", "Maj-Britt", "Margrete", "Metha", "Nielsine", ..
			"Oline", "Petrea", "Petrine", "Pouline", "Ragna", "Sørine", "Thora", "Valborg", "Vilhelmine" ..
        	]

		self.lastNames = [ ..
			"Jensen", "Nielsen", "Hansen", "Pedersen", "Andersen", "Christensen", "Larsen", "Sørensen", "Rasmussen", "Petersen", ..
			"Jørgensen", "Madsen", "Kristensen", "Olsen", "Christiansen", "Thomsen", "Poulsen", "Johansen", "Knudsen", "Mortensen", ..
			"Møller", "Jacobsen", "Jakobsen", "Olesen", "Frederiksen", "Mikkelsen", "Henriksen", "Laursen", "Lund", "Schmidt", ..
			"Eriksen", "Holm", "Kristiansen", "Clausen", "Simonsen", "Svendsen", "Andreasen", "Iversen", "Jeppesen", "Mogensen", ..
			"Jespersen", "Nissen", "Lauridsen", "Frandsen", "Østergaard", "Jepsen", "Kjær", "Carlsen", "Vestergaard", "Jessen", ..
			"Nørgaard", "Dahl", "Christoffersen", "Skov", "Søndergaard", "Bertelsen", "Bruun", "Lassen", "Bach", "Gregersen", ..
			"Friis", "Johnsen", "Steffensen", "Kjeldsen", "Bech", "Krogh", "Lauritsen", "Danielsen", "Mathiesen", "Andresen", ..
			"Brandt", "Winther", "Toft", "Ravn", "Mathiasen", "Dam", "Holst", "Nilsson", "Lind", "Berg", "Schou", "Overgaard", ..
			"Kristoffersen", "Schultz", "Klausen", "Karlsen", "Paulsen", "Hermansen", "Thorsen", "Koch", "Thygesen", "Bak", "Kruse", ..
			"Bang", "Juhl", "Davidsen", "Berthelsen", "Nygaard", "Lorentzen", "Villadsen", "Lorenzen", "Damgaard", "Bjerregaard", ..
			"Lange", "Hedegaard", "Bendtsen", "Lauritzen", "Svensson", "Justesen", "Juul", "Hald", "Beck", "Kofoed", "Søgaard", ..
			"Meyer", "Kjærgaard", "Riis", "Johannsen", "Carstensen", "Bonde", "Ibsen", "Fischer", "Andersson", "Bundgaard", ..
			"Johannesen", "Eskildsen", "Hemmingsen", "Andreassen", "Thomassen", "Schrøder", "Persson", "Hjorth", "Enevoldsen", ..
			"Nguyen", "Henningsen", "Jønsson", "Olsson", "Asmussen", "Michelsen", "Vinther", "Markussen", "Kragh", "Thøgersen", ..
			"Johansson", "Dalsgaard", "Gade", "Bjerre", "Ali", "Laustsen", "Buch", "Ludvigsen", "Hougaard", "Kirkegaard", "Marcussen", ..
			"Mølgaard", "Ipsen", "Sommer", "Ottosen", "Müller", "Krog", "Hoffmann", "Clemmensen", "Nikolajsen", "Brodersen", ..
			"Therkildsen", "Leth", "Michaelsen", "Graversen", "Frost", "Dalgaard", "Albertsen", "Laugesen", "Due", "Ebbesen", ..
			"Munch", "Svenningsen", "Ottesen", "Fisker", "Albrechtsen", "Axelsen", "Erichsen", "Sloth", "Bentsen", "Westergaard", ..
			"Bisgaard", "Nicolaisen", "Magnussen", "Thuesen", "Povlsen", "Thorup", "Høj", "Bentzen", "Johannessen", "Vilhelmsen", ..
			"Isaksen", "Bendixen", "Ovesen", "Villumsen", "Lindberg", "Thomasen", "Kjærsgaard", "Buhl", "Kofod", "Ahmed", "Smith", ..
			"Storm", "Christophersen", "Bruhn", "Matthiesen", "Wagner", "Bjerg", "Gram", "Nedergaard", "Dinesen", "Mouritsen", ..
			"Boesen", "Borup", "Abrahamsen", "Wulff", "Gravesen", "Rask", "Pallesen", "Greve", "Korsgaard", "Haugaard", "Josefsen", ..
			"Bæk", "Espersen", "Thrane", "Mørch", "Frank", "Lynge", "Rohde", "Larsson", "Hammer", "Torp", "Sonne", "Boysen", "Bay", ..
			"Pihl", "Fabricius", "Høyer", "Birch", "Skou", "Kirk", "Antonsen", "Høgh", "Damsgaard", "Dall", "Truelsen", "Daugaard", ..
			"Fuglsang", "Martinsen", "Therkelsen", "Jansen", "Karlsson", "Caspersen", "Steen", "Callesen", "Balle", "Bloch", "Smidt", ..
			"Rahbek", "Hjort", "Bjørn", "Skaarup", "Sand", "Storgaard", "Willumsen", "Busk", "Hartmann", "Ladefoged", "Skovgaard", ..
			"Philipsen", "Damm", "Haagensen", "Hviid", "Duus", "Kvist", "Adamsen", "Mathiassen", "Degn", "Borg", "Brix", "Troelsen", ..
			"Ditlevsen", "Brøndum", "Svane", "Mohamed", "Birk", "Brink", "Hassan", "Vester", "Elkjær", "Lykke", "Nørregaard", ..
			"Meldgaard", "Mørk", "Hvid", "Abildgaard", "Nicolajsen", "Bengtsson", "Stokholm", "Ahmad", "Wind", "Rømer", "Gundersen", ..
			"Carlsson", "Grøn", "Khan", "Skytte", "Bagger", "Hendriksen", "Rosenberg", "Jonassen", "Severinsen", "Jürgensen", ..
			"Boisen", "Groth", "Bager", "Fogh", "Hussain", "Samuelsen", "Pilgaard", "Bødker", "Dideriksen", "Brogaard", "Lundberg", ..
			"Hansson", "Schwartz", "Tran", "Skriver", "Klitgaard", "Hauge", "Højgaard", "Qvist", "Voss", "Strøm", "Wolff", "Krarup", ..
			"Green", "Odgaard", "Tønnesen", "Blom", "Gammelgaard", "Jæger", "Kramer", "Astrup", "Würtz", "Lehmann", "Koefoed", ..
			"Skøtt", "Lundsgaard", "Bøgh", "Vang", "Martinussen", "Sandberg", "Weber", "Holmgaard", "Bidstrup", "Meier", "Drejer", ..
			"Schneider", "Joensen", "Dupont", "Lorentsen", "Bro", "Bagge", "Terkelsen", "Kaspersen", "Keller", "Eliasen", "Lyberth", ..
			"Husted", "Mouritzen", "Krag", "Kragelund", "Nørskov", "Vad", "Jochumsen", "Hein", "Krogsgaard", "Kaas", "Tolstrup", ..
			"Ernst", "Hermann", "Børgesen", "Skjødt", "Holt", "Buus", "Gotfredsen", "Kjeldgaard", "Broberg", "Roed", "Sivertsen", ..
			"Bergmann", "Bjerrum", "Petersson", "Smed", "Jeremiassen", "Nyborg", "Borch", "Foged", "Terp", "Mark", "Busch", ..
			"Lundgaard", "Boye", "Yde", "Hinrichsen", "Matzen", "Esbensen", "Hertz", "Westh", "Holmberg", "Geertsen", "Raun", ..
			"Aagaard", "Kock", "Falk", "Munk" ..
			]
	End Method
End Type




'=== GREEK ===
Type TPersonGeneratorCountry_Greek extends TPersonGeneratorCountry
	Method New()
		self.countryCode = "gr"
		
		self.firstNamesMale = [..
			"Avraám", "Agathágyelos", "Agathoklís", "Agathónikos", "Agamémnon", "Agapitós", "Agápios", "Ágyelos", "Avisílaos", "Adám", "Adamántios", "Ádonis", "Athanásios", "Athinagóras", "Athinódoros", "Aimílios", "Akrivós", "Akrítas", "Aléxandros", "Aléxios", "Alkiviádis", "Amvrósios", "Anagnóstis", "Ananías", "Anaxagóras", "Anáryiros", "Anastásios", "Androklís", "Andrónikos", "Ánthimos", "Anthoúlis", "Antígonos", "Antípatros", "Antípas", "Antónios", "Apóllon", "Apóstolos", "Aryírios", "Áris", "Arístarkhos", "Aristóvoulos", "Aristoménis", "Áristos", "Aristotélis", "Aristophánis", "Artémios", "Arkhélaos", "Arkhimídis", "Asimís", "Asklipiós", "Astérios", "Afyéris", "Ávgoustos", "Afxéntios", "Aphéntis", "Akhilléas", .. 
			"Váios", "Valántis", "Valentínos", "Valérios", "Vardís", "Vartholomaíos", "Varsámos", "Vasílios", "Vasílis", "Velissários", "Venétios", "Veniamín", "Venizélos", "Vissaríon", "Vikéntios", "Vladímiros", "Vlásios", "Vrasídas", "Víron", ..
			"Gavriíl", "Galátios", "Galinós", "Garíphallos", "Yerásimos", "Yeóryios", "Gkíkas", "Grigórios", ..
			"Damaskinós", "Damianós", "Daniíl", "Dimítrios", "Dimokrátis", "Dimókritos", "Dímos", "Dimosthénis", "Díkaios", "Dioyénis", "Diomídis", "Dionísios", "Domínikos", "Drákon", "Drósos", "Dorótheos", ..
			"Irinaíos", "Éktoras", "Elefthérios", "Elissaíos", "Emmanoíl", "Éxarkhos", "Epaminóndas", "Ermís", "Ermólaos", "Erríkos", "Erotókritos", "Evágyelos", "Efyénios", "Efdóxios", "Efthímios", "Efklídis", "Evménios", "Evripídis", "Efsévios", "Efstáthios", "Efstrátios", "Eftíkhios", "Ephraím", ..
			"Zaphírios", "Zakharías", "Zinóvios", "Zínon", ..
			"Ilías", "Iraklís", "Iródotos", "Isaïas", ..
			"Thalís", "Themistoklís", "Theodósios", "Theódoulos", "Theódoros", "Theóklitos", "Theológos", "Theópistos", "Theotókis", "Theophánis", "Theóphilos", "Theóphrastos", "Theophílaktos", "Theokháris", "Thiséfs", "Thoukidídis", "Thrasívoulos", "Thomás", ..
			"Iákovos", "Iáson", "Ignátios", "Ieremías", "Ierótheos", "Ierónimos", "Íkaros", "Iordánis", "Ioulianós", "Ioúlios", "Ippokrátis", "Ippólitos", "Isaák", "Isídoros", "Ioakím", "Ioánnis", "Íon", "Ionás", "Iosíph", ..
			"Kallínikos", "Károlos", "Kiríkos", "Kímon", "Kleánthis", "Kléarkhos", "Kleóvoulos", "Kleoménis", "Kleópas", "Klímis", "Komninós", "Kornílios", "Kosmás", "Kristállis", "Kiprianós", "Kiriazís", "Kiriákos", "Kíros", "Konstantínos", ..
			"Laértis", "Lázaros", "Lámpros", "Laokrátis", "Láskaris", "Lavréntios", "Léandros", "Lemonís", "Leonárdos", "Léon", "Leonídas", "Logothétis", "Loudovíkos", "Loukás", "Loukianós", "Likoúrgos", "Lísandros", ..
			"Magdalinós", "Makários", "Marínos", "Mários", "Márkos", "Martínos", "Matthaíos", "Mavríkios", "Mavroidís", "Mávros", "Megaklís", "Methódios", "Melétios", "Ménandros", "Menélaos", "Merkoúrios", "Minás", "Miltiádis", "Mínoas", "Mikhaíl", ..
			"Nathanaíl", "Napoléon", "Néarkhos", "Nektários", "Neoklís", "Neóphitos", "Níkandros", "Nikítas", "Nikiphóros", "Nikódimos", "Nikólaos", "Níkon", ..
			"Xanthós", "Xenophón", ..
			"Odisséas", "Óthon", "Ómiros", "Oréstis", "Orphéas", ..
			"Panayiótis", "Panormítis", "Pantazís", "Pantelímon", "Paraskevás", "Paráskhos", "Páris", "Paskhális", "Pátroklos", "Páflos", "Pafsanías", "Pelopídas", "Periklís", "Pétros", "Píndaros", "Pláton", "Ploútarkhos", "Polívios", "Polídoros", "Polizóis", "Políkarpos", "Polikrátis", "Polikhrónios", "Praxitélis", "Pródromos", "Prokópios", "Promithéas", "Pithagóras", "Pírros", ..
			"Rállis", "Raphaíl", "Rígas", "Rízos", "Rodóphlos", "Romanós", ..
			"Sávvas", "Samoíl", "Sarántis", "Sevastianós", "Seraphím", "Séryios", "Solomón", "Sólon", "Sophoklís", "Spirídon", "Stamátios", "Stávros", "Stéryios", "Stéphanos", "Stilianós", "Simeón", "Sózon", "Sokrátis", "Sotírios", ..
			"Taxíarkhos", "Tilémakhos", "Timótheos", "Timoléon", "Tímon", "Títos", "Triantáphillos", "Tríphon", "Tsampíkos", ..
			"Iákinthos", ..
			"Phaídon", "Phanoúrios", "Philímon", "Phílippos", "Phívos", "Phrangískos", "Phrideríkos", "Phríxos", "Phokás", "Phokíon", "Photinós", "Phótios", ..
			"Kharálampos", "Kharílaos", "Kharítos", "Khrístos", "Khristódoulos", "Khristóphoros", "Khrísanthos", "Khrisovalántios", "Khrisóstomos" ..
			]

		self.firstNamesFemale = [..
			"Apostolía", "Afyí", "Agáthi", "Agápi", "Agyelikí", "Aglaïa", "Agní", "Agóro", "Adamantía", "Aidóna", "Athanasía", "Athiná", "Athinodóra", "Aikateríni", "Aimilía", "Akriví", "Alexándra", "Alexía", "Alíki", "Álkistis", "Alkinói", "Amalía", "Amvrosía", "Amphithéa", "Amphitríti", "Anáryiri", "Anastasía", "Anatolí", "Andrianí", "Andromákhi", "Androméda", "Androníki", "Anthí", "Ánna", "Antigóni", "Antonía", "Apollonía", "Apostolía", "Aryiró", "Aretí", "Ariádni", "Aristéa", "Ártemis", "Artemisía", "Arkhontía", "Asimína", "Aspasía", "Astéro", "Atalánti", "Avgoustína", "Aphéntra", "Aphrodíti", "Akhillía", ..
			"Váyia", "Valánto", "Valentína", "Valéria", "Varvára", "Varsamía", "Vasilía", "Vasilikí", "Veatríki", "Velissaría", "Venetía", "Verónika", "Vissaría", "Vikéntia", "Viktória", "Violéta", "Viryinía", "Vlasía", "Vrisiís", ..
			"Gavriélla", "Galátia", "Galíni", "Gariphalliá", "Yenovépha", "Yerakína", "Yerasimoúla", "Yesthimaní", "Yeoryía", "Yiasemí", "Gkólpho", "Gláfki", "Glikería", "Grammatikí", ..
			"Davidoúla", "Damaskiní", "Damianí", "Danái", "Dáphni", "Déspina", "Dímitra", "Dimoúla", "Dialektí", "Didó", "Dikaía", "Dionisía", "Dómna", "Drosiá", "Dorothéa", ..
			"Iríni", "Eléni", "Eleonóra", "Elefthería", "Elisávet", "Élli", "Elpís", "Emmanouéla", "Epistími", "Erasmía", "Erató", "Eriéta", "Eriphíli", "Ermióni", "Erophíli", "Éva", "Evagyelía", "Evanthía", "Efyenía", "Efdokía", "Efdoxía", "Efthalía", "Efthimía", "Éfklia", "Eflampía", "Evridíki", "Evríklia", "Efsevía", "Efstathía", "Efstratía", "Eftérpi", "Eftikhía", ..
			"Zampéta", "Zaphiría", "Zakharoúla", "Zinaïs", "Zinovía", "Zisoúla", "Zí", ..
			"Ívi", "Iléktra", "Ília", "Iliána", "Íra", "Iráklia", "Ió", ..
			"Thalassiní", "Thália", "Theanó", "Thékla", "Thémis", "Themistóklia", "Theodosía", "Theodóti", "Theodoúli", "Theodóra", "Theóklia", "Theoloyía", "Theopísti", "Theophanía", "Theophíli", "Theophílakti", "Theokharoúla", "Thétis", "Theóni", "Thiresía", "Thomaís", ..
			"Iakovína", "Ignatía", "Inó", "Iokásti", "Iordanía", "Ioulía", "Ioulianí", "Ippolíti", "Íris", "Isavélla", "Isidóra", "Ismíni", "Iphiyénia", "Ioánna", "Iosiphína", ..
			"Kalí", "Kallíniki", "Kalliópi", "Kallirrói", "Kalomíra", "Kalipsó", "Kanélla", "Kariophilliá", "Kassándra", "Kassianí", "Kerasiá", "Klaíri", "Klió", "Kleopátra", "Klimentíni", "Klitaimnístra", "Kokkóna", "Komniní", "Kondilía", "Koralía", "Kornilía", "Kósmia", "Krinió", "Kristallénia", "Kivéli", "Kidonía", "Kiparissía", "Kiprianí", "Kiriakí", "Konstantína", ..
			"Lazaría", "Lampriní", "Laskarína", "Lavrentía", "Lemoniá", "Lefkothéa", "Leóni", "Leonidiá", "Lída", "Litó", "Loíza", "Loukía", "Louloudénia", "Liyerí", "Lidía", ..
			"Magdaliní", "Makrína", "Malamaténia", "Malvína", "Mántha", "Mantó", "Margaríta", "Mártha", "María", "Mariánthi", "Marína", "Markélla", "Matthíldi", "Mávra", "Melénia", "Melétia", "Melína", "Melpoméni", "Merópi", "Metaxía", "Miliá", "Miránta", "Mikhaéla", "Móskha", "Mirsíni", ..
			"Nafsiká", "Nektaría", "Neóklia", "Neratziá", "Nephéli", "Níki", "Nikitía", "Nikoléta", ..
			"Xanthí", "Xanthíppi", "Xéni", ..
			"Odíssia", "Ólga", "Olímpia", "Ouranía", ..
			"Pagóna", "Panayía", "Panayióta", "Pandóra", "Pantelía", "Panoraía", "Paraskeví", "Parthéna", "Paskhaliá", "Patapía", "Paflína", "Pelayía", "Peristéra", "Persephóni", "Pétra", "Piyí", "Pinelópi", "Pothití", "Polívia", "Polídora", "Polímnia", "Polixéni", "Politími", "Polikhronía", "Poúlia", "Prodromía", ..
			"Rallía", "Réa", "Revékka", "Regyína", "Rigoúla", "Rodiá", "Róza", "Roumpíni", "Roúsa", "Roxáni", ..
			"Savvoúla", "Salómi", "Sapphó", "Sárra", "Sevastí", "Sevastianí", "Selíni", "Semína", "Seraphía", "Smarágda", "Soultána", "Souméla", "Sophía", "Spárti", "Spiridoúla", "Stamatína", "Stavroúla", "Steryianí", "Stephanía", "Stilianí", "Simeonía", "Sozoúsa", "Sotiría", "Sophronía", ..
			"Taxiarkhía", "Tatiána", "Terpsikhóri", "Timothéa", "Triantáphilli", "Triséfyeni", "Triphonía", "Tsampíka", ..
			"Iakínthi", "Ivónni", "Ipapantí", ..
			"Phaídra", "Phanouría", "Phevronía", "Phereníki", "Philaréti", "Philíppa", "Philippía", "Philió", "Philothéi", "Philomíla", "Phlóra", "Phlorentía", "Phívi", "Phrantzéska", "Phrideríki", "Phríni", "Photiní", ..
			"Kháido", "Khará", "Kharalampía", "Khári", "Kharíklia", "Khioniá", "Khlói", "Khristodoúla", "Khristóphili", "Khristophóra", "Khrisánthi", "Khrisafyí", "Khrisaphénia", "Khrisovalánto", "Khrisóstomi", "Khrisoúla" .. 
			]

		self.lastNames = [ ..
			"Avraám", "Agathágyelos", "Agathoklís", "Agathónikos", "Agamémnon", "Agapitós", "Agápios", "Ágyelos", "Avisílaos", "Adám", "Adamántios", "Ádonis", "Athanásios", "Athinagóras", "Athinódoros", "Aimílios", "Akrivós", "Akrítas", "Aléxandros", "Aléxios", "Alkiviádis", "Amvrósios", "Anagnóstis", "Ananías", "Anaxagóras", "Anáryiros", "Anastásios", "Androklís", "Andrónikos", "Ánthimos", "Anthoúlis", "Antígonos", "Antípatros", "Antípas", "Antónios", "Apóllon", "Apóstolos", "Aryírios", "Áris", "Arístarkhos", "Aristóvoulos", "Aristoménis", "Áristos", "Aristotélis", "Aristophánis", "Artémios", "Arkhélaos", "Arkhimídis", "Asimís", "Asklipiós", "Astérios", "Afyéris", "Ávgoustos", "Afxéntios", "Aphéntis", "Akhilléas", ..
			"Váios", "Valántis", "Valentínos", "Valérios", "Vardís", "Vartholomaíos", "Varsámos", "Vasílios", "Vasílis", "Velissários", "Venétios", "Veniamín", "Venizélos", "Vissaríon", "Vikéntios", "Vladímiros", "Vlásios", "Vrasídas", "Víron", ..
			"Gavriíl", "Galátios", "Galinós", "Garíphallos", "Yerásimos", "Yeóryios", "Gkíkas", "Grigórios", ..
			"Damaskinós", "Damianós", "Daniíl", "Dimítrios", "Dimokrátis", "Dimókritos", "Dímos", "Dimosthénis", "Díkaios", "Dioyénis", "Diomídis", "Dionísios", "Domínikos", "Drákon", "Drósos", "Dorótheos", ..
			"Irinaíos", "Éktoras", "Elefthérios", "Elissaíos", "Emmanoíl", "Éxarkhos", "Epaminóndas", "Ermís", "Ermólaos", "Erríkos", "Erotókritos", "Evágyelos", "Efyénios", "Efdóxios", "Efthímios", "Efklídis", "Evménios", "Evripídis", "Efsévios", "Efstáthios", "Efstrátios", "Eftíkhios", "Ephraím", ..
			"Zaphírios", "Zakharías", "Zinóvios", "Zínon", ..
			"Ilías", "Iraklís", "Iródotos", "Isaïas", ..
			"Thalís", "Themistoklís", "Theodósios", "Theódoulos", "Theódoros", "Theóklitos", "Theológos", "Theópistos", "Theotókis", "Theophánis", "Theóphilos", "Theóphrastos", "Theophílaktos", "Theokháris", "Thiséfs", "Thoukidídis", "Thrasívoulos", "Thomás", ..
			"Iákovos", "Iáson", "Ignátios", "Ieremías", "Ierótheos", "Ierónimos", "Íkaros", "Iordánis", "Ioulianós", "Ioúlios", "Ippokrátis", "Ippólitos", "Isaák", "Isídoros", "Ioakím", "Ioánnis", "Íon", "Ionás", "Iosíph", ..
			"Kallínikos", "Károlos", "Kiríkos", "Kímon", "Kleánthis", "Kléarkhos", "Kleóvoulos", "Kleoménis", "Kleópas", "Klímis", "Komninós", "Kornílios", "Kosmás", "Kristállis", "Kiprianós", "Kiriazís", "Kiriákos", "Kíros", "Konstantínos", ..
			"Laértis", "Lázaros", "Lámpros", "Laokrátis", "Láskaris", "Lavréntios", "Léandros", "Lemonís", "Leonárdos", "Léon", "Leonídas", "Logothétis", "Loudovíkos", "Loukás", "Loukianós", "Likoúrgos", "Lísandros", ..
			"Magdalinós", "Makários", "Marínos", "Mários", "Márkos", "Martínos", "Matthaíos", "Mavríkios", "Mavroidís", "Mávros", "Megaklís", "Methódios", "Melétios", "Ménandros", "Menélaos", "Merkoúrios", "Minás", "Miltiádis", "Mínoas", "Mikhaíl", ..
			"Nathanaíl", "Napoléon", "Néarkhos", "Nektários", "Neoklís", "Neóphitos", "Níkandros", "Nikítas", "Nikiphóros", "Nikódimos", "Nikólaos", "Níkon", ..
			"Xanthós", "Xenophóntis", ..
			"Odisséas", "Óthon", "Ómiros", "Oréstis", "Orphéas", ..
			"Panayiótis", "Panormítis", "Pantazís", "Pantelímon", "Paraskevás", "Paráskhos", "Páris", "Paskhális", "Pátroklos", "Páflos", "Pafsanías", "Pelopídas", "Periklís", "Pétros", "Píndaros", "Pláton", "Ploútarkhos", "Polívios", "Polídoros", "Polizóis", "Políkarpos", "Polikrátis", "Polikhrónios", "Praxitélis", "Pródromos", "Prokópios", "Promithéas", "Pithagóras", "Pírros", ..
			"Rállis", "Raphaíl", "Rígas", "Rízos", "Rodóphlos", "Romanós", ..
			"Sávvas", "Samoíl", "Sarántis", "Sevastianós", "Seraphím", "Séryios", "Solomón", "Sólon", "Sophoklís", "Spirídon", "Stamátios", "Stávros", "Stéryios", "Stéphanos", "Stilianós", "Simeón", "Sózon", "Sokrátis", "Sotírios", ..
			"Taxíarkhos", "Tilémakhos", "Timótheos", "Timoléon", "Tímon", "Títos", "Triantáphillos", "Tríphon", "Tsampíkos", ..
			"Iákinthos", ..
			"Phaídon", "Phanoúrios", "Philímon", "Phílippos", "Phívos", "Phrangískos", "Phrideríkos", "Phríxos", "Phokás", "Phokíon", "Photinós", "Phótios", ..
			"Kharálampos", "Kharílaos", "Kharítos", "Khrístos", "Khristódoulos", "Khristóphoros", "Khrísanthos", "Khrisovalántios", "Khrisóstomos", ..
			"Apostolía", "Afyí", "Agáthi", "Agápi", "Agyelikí", "Aglaïa", "Agní", "Agóro", "Adamantía", "Aidóna", "Athanasía", "Athiná", "Athinodóra", "Aikateríni", "Aimilía", "Akriví", "Alexándra", "Alexía", "Alíki", "Álkistis", "Alkinói", "Amalía", "Amvrosía", "Amphithéa", "Amphitríti", "Anáryiri", "Anastasía", "Anatolí", "Andrianí", "Andromákhi", "Androméda", "Androníki", "Anthí", "Ánna", "Antigóni", "Antonía", "Apollonía", "Apostolía", "Aryiró", "Aretí", "Ariádni", "Aristéa", "Ártemis", "Artemisía", "Arkhontía", "Asimína", "Aspasía", "Astéro", "Atalánti", "Avgoustína", "Aphéntra", "Aphrodíti", "Akhillía", ..
			"Váyia", "Valánto", "Valentína", "Valéria", "Varvára", "Varsamía", "Vasilía", "Vasilikí", "Veatríki", "Velissaría", "Venetía", "Verónika", "Vissaría", "Vikéntia", "Viktória", "Violéta", "Viryinía", "Vlasía", "Vrisiís", ..
			"Gavriélla", "Galátia", "Galíni", "Gariphalliá", "Yenovépha", "Yerakína", "Yerasimoúla", "Yesthimaní", "Yeoryía", "Yiasemí", "Gkólpho", "Gláfki", "Glikería", "Grammatikí", ..
			"Davidoúla", "Damaskiní", "Damianí", "Danái", "Dáphni", "Déspina", "Dímitra", "Dimoúla", "Dialektí", "Didó", "Dikaía", "Dionisía", "Dómna", "Drosiá", "Dorothéa", ..
			"Iríni", "Eléni", "Eleonóra", "Elefthería", "Elisávet", "Élli", "Elpís", "Emmanouéla", "Epistími", "Erasmía", "Erató", "Eriéta", "Eriphíli", "Ermióni", "Erophíli", "Éva", "Evagyelía", "Evanthía", "Efyenía", "Efdokía", "Efdoxía", "Efthalía", "Efthimía", "Éfklia", "Eflampía", "Evridíki", "Evríklia", "Efsevía", "Efstathía", "Efstratía", "Eftérpi", "Eftikhía", ..
			"Zampéta", "Zaphiría", "Zakharoúla", "Zinaïs", "Zinovía", "Zisoúla", "Zí", ..
			"Ívi", "Iléktra", "Ília", "Iliána", "Íra", "Iráklia", "Ió", ..
			"Thalassiní", "Thália", "Theanó", "Thékla", "Thémis", "Themistóklia", "Theodosía", "Theodóti", "Theodoúli", "Theodóra", "Theóklia", "Theoloyía", "Theopísti", "Theophanía", "Theophíli", "Theophílakti", "Theokharoúla", "Thétis", "Theóni", "Thiresía", "Thomaís", ..
			"Iakovína", "Ignatía", "Inó", "Iokásti", "Iordanía", "Ioulía", "Ioulianí", "Ippolíti", "Íris", "Isavélla", "Isidóra", "Ismíni", "Iphiyénia", "Ioánna", "Iosiphína", ..
			"Kalí", "Kallíniki", "Kalliópi", "Kallirrói", "Kalomíra", "Kalipsó", "Kanélla", "Kariophilliá", "Kassándra", "Kassianí", "Kerasiá", "Klaíri", "Klió", "Kleopátra", "Klimentíni", "Klitaimnístra", "Kokkóna", "Komniní", "Kondilía", "Koralía", "Kornilía", "Kósmia", "Krinió", "Kristallénia", "Kivéli", "Kidonía", "Kiparissía", "Kiprianí", "Kiriakí", "Konstantína", ..
			"Lazaría", "Lampriní", "Laskarína", "Lavrentía", "Lemoniá", "Lefkothéa", "Leóni", "Leonidiá", "Lída", "Litó", "Loíza", "Loukía", "Louloudénia", "Liyerí", "Lidía", ..
			"Magdaliní", "Makrína", "Malamaténia", "Malvína", "Mántha", "Mantó", "Margaríta", "Mártha", "María", "Mariánthi", "Marína", "Markélla", "Matthíldi", "Mávra", "Melénia", "Melétia", "Melína", "Melpoméni", "Merópi", "Metaxía", "Miliá", "Miránta", "Mikhaéla", "Móskha", "Mirsíni", ..
			"Nafsiká", "Nektaría", "Neóklia", "Neratziá", "Nephéli", "Níki", "Nikitía", "Nikoléta", ..
			"Xanthí", "Xanthíppi", "Xéni", ..
			"Odíssia", "Ólga", "Olímpia", "Ouranía", ..
			"Pagóna", "Panayía", "Panayióta", "Pandóra", "Pantelía", "Panoraía", "Paraskeví", "Parthéna", "Paskhaliá", "Patapía", "Paflína", "Pelayía", "Peristéra", "Persephóni", "Pétra", "Piyí", "Pinelópi", "Pothití", "Polívia", "Polídora", "Polímnia", "Polixéni", "Politími", "Polikhronía", "Poúlia", "Prodromía", ..
			"Rallía", "Réa", "Revékka", "Regyína", "Rigoúla", "Rodiá", "Róza", "Roumpíni", "Roúsa", "Roxáni", ..
			"Savvoúla", "Salómi", "Sapphó", "Sárra", "Sevastí", "Sevastianí", "Selíni", "Semína", "Seraphía", "Smarágda", "Soultána", "Souméla", "Sophía", "Spárti", "Spiridoúla", "Stamatína", "Stavroúla", "Steryianí", "Stephanía", "Stilianí", "Simeonía", "Sozoúsa", "Sotiría", "Sophronía", ..
			"Taxiarkhía", "Tatiána", "Terpsikhóri", "Timothéa", "Triantáphilli", "Triséfyeni", "Triphonía", "Tsampíka", ..
			"Iakínthi", "Ivónni", "Ipapantí", ..
			"Phaídra", "Phanouría", "Phevronía", "Phereníki", "Philaréti", "Philíppa", "Philippía", "Philió", "Philothéi", "Philomíla", "Phlóra", "Phlorentía", "Phívi", "Phrantzéska", "Phrideríki", "Phríni", "Photiní", ..
			"Kháido", "Khará", "Kharalampía", "Khári", "Kharíklia", "Khioniá", "Khlói", "Khristodoúla", "Khristóphili", "Khristophóra", "Khrisánthi", "Khrisafyí", "Khrisaphénia", "Khrisovalánto", "Khrisóstomi", "Khrisoúla" ..
			]
	End Method
End Type




'=== UGANDA ===
Type TPersonGeneratorCountry_Uganda extends TPersonGeneratorCountry
	Method New()
		self.countryCode = "ug"
		
		self.firstNamesMale = [..
			"Aaron", "Abdul", "Abdullah", "Abraham", "Adam", "Agustin", "Ahmad", "Ahmed", "Akeem", "Albert", "Alex", "Alfred", "Ali", "Allan", "Allen", "Alvin", "Amani", "Ambrose", "Amos", "Anderson", "Andrew", "Angel", "Anthony", "Arnold", "Arthur", "Austin",..
			"Barnet", "Barry", "Ben", "Benjamin", "Bennie", "Benny", "Bernard", "Berry", "Berta", "Bertha", "Bill", "Billy", "Bobby", "Boyd", "Bradley", "Brian", "Bruce",..
			"Caesar", "Caleb", "Carol", "Cecil", "Charles", "Charlie", "Chris", "Christian", "Christopher", "Cleveland", "Clifford", "Clinton", "Collin", "Conrad",..
			"Dan", "Daren", "Dave", "David", "Dax", "Denis", "Dennis", "Derek", "Derick", "Derrick", "Don", "Donald", "Douglas", "Dylan",..
			"Earnest", "Eddie", "Edgar", "Edison", "Edmond", "Edmund", "Edward", "Edwin", "Elias", "Elijah", "Elliot", "Emanuel", "Emmanuel", "Eric", "Ernest", "Ethan", "Eugene", "Ezra",..
			"Felix", "Francis", "Frank", "Frankie", "Fred",..
			"Gaetano", "Gaston", "Gavin", "Geoffrey", "George", "Gerald", "Gideon", "Gilbert", "Glen", "Godfrey", "Graham", "Gregory",..
			"Hans", "Harold", "Henry", "Herbert", "Herman", "Hillary", "Howard",..
			"Ian", "Isaac", "Isaiah", "Ismael",..
			"Jabari", "Jack", "Jackson", "Jacob", "Jamaal", "Jamal", "Jasper", "Jayson", "Jeff", "Jeffery", "Jeremy", "Jimmy", "Joe", "Joel", "Joesph", "Johathan", "John", "Johnathan", "Johnny", "Johnson", "Jonathan", "Jordan", "Joseph", "Joshua", "Julian", "Julio", "Julius", "Junior",..
			"Kaleb", "Keith", "Kelly", "Kelvin", "Ken", "Kennedy", "Kenneth", "Kevin", "Kim",..
			"Lawrence", "Lewis", "Lincoln", "Lloyd", "Luis", "Luther",..
			"Mackenzie", "Martin", "Marvin", "Mathew", "Mathias", "Matt", "Maurice", "Max", "Maxwell", "Mckenzie", "Micheal", "Mike", "Milton", "Mitchel", "Mitchell", "Mohamed", "Mohammad", "Mohammed", "Morris", "Moses", "Muhammad", "Myles",..
			"Nasir", "Nat", "Nathan", "Newton", "Nicholas", "Nick", "Nicklaus", "Nickolas", "Nicolas", "Noah", "Norbert",..
			"Oscar", "Owen",..
			"Patrick", "Paul", "Peter", "Philip",..
			"Rashad", "Rasheed", "Raul", "Ray", "Raymond", "Reagan", "Regan", "Richard", "Richie", "Rick", "Robb", "Robbie", "Robert", "Robin", "Roger", "Rogers", "Ronald", "Rowland", "Royal", "Ryan",..
			"Sam", "Samson", "Sean", "Shawn", "Sid", "Sidney", "Solomon", "Steve", "Stevie", "Stewart", "Stuart",..
			"Taylor", "Theodore", "Thomas", "Timmy", "Timothy", "Titus", "Tom", "Tony", "Travis", "Trevor", "Troy", "Trystan", "Tyler", "Tyson",..
			"Victor", "Vince", "Vincent", "Vinnie",..
			"Walter", "Warren", "Wilford", "Wilfred", "Will", "William", "Willis", "Willy", "Wilson" ..
        	]

		self.firstNamesFemale = [..
			"Abigail", "Adela", "Adrianna", "Adrienne", "Aisha", "Alice", "Alisha", "Alison", "Amanda", "Amelia", "Amina", "Amy", "Anabel", "Anabelle", "Angela", "Angelina", "Angie", "Anita", "Anna", "Annamarie", "Anne", "Annette", "April", "Arianna", "Ariela", "Asha", "Ashley", "Ashly", "Audrey", "Aurelia",..
			"Barbara", "Beatrice", "Bella", "Bernadette", "Beth", "Bethany", "Bethel", "Betsy", "Bette", "Bettie", "Betty", "Blanche", "Bonita", "Bonnie", "Brenda", "Bridget", "Bridgette", "Carissa", "Carol", "Carole", "Carolina", "Caroline", "Carolyn", "Carolyne", "Catharine", "Catherine", "Cathrine", "Cathryn", "Cathy", "Cecelia", "Cecile", "Cecilia", "Charity", "Charlotte", "Chloe", "Christina", "Christine", "Cindy", "Claire", "Clara", "Clarissa", "Claudine", "Cristal", "Crystal", "Cynthia",..
			"Dahlia", "Daisy", "Daniela", "Daniella", "Danielle", "Daphne", "Daphnee", "Daphney", "Darlene", "Deborah", "Destiny", "Diana", "Dianna", "Dina", "Dolly", "Dolores", "Donna", "Dora", "Dorothy", "Dorris",..
			"Edna", "Edwina", "Edyth", "Elizabeth", "Ella", "Ellen", "Elsa", "Elsie", "Emelia", "Emilia", "Emilie", "Emily", "Emma", "Emmanuelle", "Erica", "Esta", "Esther", "Estella", "Eunice", "Eva", "Eve", "Eveline", "Evelyn",..
			"Fabiola", "Fatima", "Fiona", "Flavia", "Flo", "Florence", "Frances", "Francesca", "Francisca", "Frida",..
			"Gabriella", "Gabrielle", "Genevieve", "Georgiana", "Geraldine", "Gertrude", "Gladys", "Gloria", "Grace", "Gracie",..
			"Helen", "Hellen", "Hilda", "Hillary", "Hope",..
			"Imelda", "Isabel", "Isabell", "Isabella", "Isabelle",..
			"Jackie", "Jacklyn", "Jacky", "Jaclyn", "Jacquelyn", "Jane", "Janelle", "Janet", "Jaquelin", "Jaqueline", "Jenifer", "Jennifer", "Jessica", "Joan", "Josephine", "Joy", "Joyce", "Juanita", "Julia", "Juliana", "Julie", "Juliet", "Justine",..
			"Katarina", "Katherine", "Katheryn", "Katrina",..
			"Laura", "Leah", "Leila", "Lilian", "Lillian", "Lilly", "Lina", "Linda", "Lisa", "Lora", "Loraine", "Lucie", "Lucy", "Lulu", "Lydia",..
			"Mabel", "Maggie", "Mandy", "Margaret", "Margarete", "Margret", "Maria", "Mariah", "Mariam", "Marian", "Mariana", "Mariane", "Marianna", "Marianne", "Marie", "Marilyne", "Marina", "Marion", "Marjorie", "Marjory", "Marlene", "Mary", "Matilda", "Maudie", "Maureen", "Maya", "Meagan", "Melisa", "Melissa", "Melody", "Michele", "Michelle", "Minerva", "Minnie", "Miracle", "Monica",..
			"Nadia", "Naomi", "Naomie", "Natalia", "Natalie", "Natasha", "Nichole", "Nicole", "Nina", "Nora",..
			"Pamela", "Patience", "Patricia", "Pauline", "Pearl", "Phoebe", "Phyllis", "Pink", "Pinkie", "Priscilla", "Prudence",..
			"Rachael", "Rachel", "Rebeca", "Rebecca", "Rhoda", "Rita", "Robyn", "Rose", "Rosemary", "Ruth", "Ruthe", "Ruthie",..
			"Sabina", "Sabrina", "Salma", "Samantha", "Sandra", "Sandy", "Sarah", "Serena", "Shakira", "Sharon", "Sheila", "Sierra", "Sonia", "Sonya", "Sophia", "Sophie", "Stacey", "Stacy", "Stella", "Susan", "Susana", "Susanna", "Susie", "Suzanne", "Sylvia",..
			"Tabitha", "Teresa", "Tess", "Theresa", "Tia", "Tiffany", "Tina", "Tracy", "Trinity", "Trisha", "Trudie", "Trycia",..
			"Ursula",..
			"Valentine", "Valerie", "Vanessa", "Veronica", "Vickie", "Vicky", "Victoria", "Viola", "Violet", "Violette", "Viva", "Vivian", "Viviane", "Vivianne", "Vivien", "Vivienne",..
			"Wanda", "Wendy", "Whitney", "Wilma", "Winifred",..
			"Yvette", "Yvonne",..
			"Zita", "Zoe" ..
        	]

		self.lastNames = [ ..
			"Abayisenga", "Agaba", "Ahebwe", "Aisu", "Akankunda", "Akankwasa", "Akashaba", "Akashabe", "Ampumuza", "Ankunda", "Asasira", "Asiimwe", "Atuhe", "Atuhire", "Atukunda", "Atukwase", "Atwine", "Aurishaba",..
			"Badru", "Baguma", "Bakabulindi", "Bamwiine", "Barigye", "Bbosa", "Bisheko", "Biyinzika", "Bugala", "Bukenya", "Buyinza", "Bwana", "Byanyima", "Byaruhanga",..
			"Ddamulira",..
			"Gamwera",..
			"Ijaga", "Isyagi",..
			"Kaaya", "Kabanda", "Kabuubi", "Kabuye", "Kafeero", "Kagambira", "Kakooza", "Kalumba", "Kanshabe", "Kansiime", "Kanyesigye", "Kareiga", "Kasekende", "Kasumba", "Kateregga", "Katusiime", "Kawooya", "Kawuki", "Kayemba", "Kazibwe", "Kibirige", "Kiconco", "Kiganda", "Kijjoba", "Kirabira", "Kirabo", "Kirigwajjo", "Kisitu", "Kitovu", "Kityamuwesi", "Kivumbi", "Kiwanuka", "Kyambadde",..
			"Lunyoro",..
			"Mbabazi", "Migisha", "Mugisa", "Mugisha", "Muhwezi", "Mukalazi", "Mulalira", "Munyagwa", "Murungi", "Mushabe", "Musinguzi", "Mutabuza", "Muyambi", "Mwesige", "Mwesigye",..
			"Nabasa", "Nabimanya", "Nankunda", "Natukunda", "Nayebare", "Nimukunda", "Ninsiima", "Nkoojo", "Nkurunungi", "Nuwagaba", "Nuwamanya", "Nyeko",..
			"Obol", "Odeke", "Okumu", "Okumuringa", "Opega", "Orishaba", "Osiki", "Ouma",..
			"Rubalema", "Rusiimwa", "Rwabyoma",..
			"Tamale", "Tendo", "Tizikara", "Tuhame", "Tumusiime", "Tumwebaze", "Tumwesigye", "Tumwiine", "Turyasingura", "Tusiime", "Twasiima", "Twesigomwe",..
			"Wasswa", "Wavamuno", "Were" ..
			]
	End Method
End Type



'=== SPAIN ===
'http://www.ine.es/daco/daco42/nombyapel/nombyapel.htm
Type TPersonGeneratorCountry_Spain extends TPersonGeneratorCountry
	Method New()
		self.countryCode = "es"
		
		self.firstNamesMale = [..
			"Aaron", "Adam", "Adria", "Adrian", "Aitor", "Alberto", "Aleix", "Alejandro", "Alex", "Alonso", "Alvaro", "Ander", "Andres",..
			"Angel", "Antonio", "Arnau", "Asier", "Biel", "Bruno", "Carlos", "Cesar", "Cristian", "Daniel", "Dario", "David",..
			"Diego", "Eduardo", "Enrique", "Eric", "Erik", "Fernando", "Francisco", "Francisco Javier", "Gabriel", "Gael", "Gerard", "Gonzalo",..
			"Guillem", "Guillermo", "Hector", "Hugo", "Ian", "Ignacio", "Iker", "Isaac", "Ismael", "Ivan", "Izan", "Jaime",..
			"Jan", "Javier", "Jesus", "Joel", "Jon", "Jordi", "Jorge", "Jose", "Jose Antonio", "Jose Manuel", "Juan", "Juan Jose",..
			"Leo", "Lucas", "Luis", "Manuel", "Marc", "Marco", "Marcos", "Mario", "Martin", "Mateo", "Miguel", "Miguel Angel",..
			"Mohamed", "Nicolas", "Oliver", "Omar", "Oriol", "Oscar", "Pablo", "Pedro", "Pol", "Rafael", "Raul", "Rayan",..
			"Roberto", "Rodrigo", "Ruben", "Samuel", "Santiago", "Saul", "Sergio", "Unai", "Victor", "Yago", "Yeray" ..
           	]

		self.firstNamesFemale = [..
			"Abril", "Adriana", "Africa", "Aina", "Ainara", "Ainhoa", "Aitana", "Alba", "Alejandra", "Alexandra", "Alexia", "Alicia", "Alma",..
			"Ana", "Andrea", "Ane", "Angela", "Anna", "Ariadna", "Aroa", "Aya", "Beatriz", "Berta", "Blanca", "Candela",..
			"Carla", "Carlota", "Carmen", "Carolina", "Celia", "Clara", "Claudia", "Cristina", "Daniela", "Diana", "Elena", "Elsa",..
			"Emma", "Erika", "Eva", "Fatima", "Gabriela", "Helena", "Ines", "Irene", "Iria", "Isabel", "Jana", "Jimena",..
			"Joan", "Julia", "Laia", "Lara", "Laura", "Leire", "Leyre", "Lidia", "Lola", "Lucia", "Luna", "Malak",..
			"Manuela", "Mar", "Mara", "Maria", "Marina", "Marta", "Marti", "Martina", "Mireia", "Miriam", "Nadia", "Nahia",..
			"Naia", "Naiara", "Natalia", "Nayara", "Nerea", "Nil", "Noa", "Noelia", "Nora", "Nuria", "Olivia", "Ona",..
			"Paola", "Patricia", "Pau", "Paula", "Raquel", "Rocio", "Salma", "Sandra", "Sara", "Silvia", "Sofia", "Teresa",..
			"Valentina", "Valeria", "Vega", "Vera", "Victoria", "Yaiza", "Zoe" ..
        	]

		self.lastNames = [ ..
			"Abad", "Abeyta", "Abrego", "Abreu", "Acevedo", "Acosta", "Acuña", "Adame", "Adorno", "Agosto", "Aguado", "Aguayo", "Aguilar", "Aguilera", "Aguirre", "Alanis", "Alaniz", "Alarcón", "Alba", "Alcala", "Alcaraz", "Alcántar", "Alejandro", "Alemán", "Alfaro", "Alfonso", "Alicea", "Almanza", "Almaraz", "Almonte", "Alonso", "Alonzo", "Altamirano", "Alva", "Alvarado", "Amador", "Amaya", "Anaya", "Andreu", "Andrés", "Anguiano", "Angulo", "Antón", "Aparicio", "Apodaca", "Aponte", "Aragón", "Aranda", "Araña", "Arce", "Archuleta", "Arellano", "Arenas", "Arevalo", "Arguello", "Arias", "Armas", "Armendáriz", "Armenta", "Armijo", "Arredondo", "Arreola", "Arriaga", "Arribas", "Arroyo", "Arteaga", "Asensio", "Atencio", "Avilés", "Ayala",..
			"Baca", "Badillo", "Baeza", "Bahena", "Balderas", "Ballesteros", "Banda", "Barajas", "Barela", "Barragán", "Barraza", "Barrera", "Barreto", "Barrientos", "Barrios", "Barroso", "Batista", "Bautista", "Bañuelos", "Becerra", "Beltrán", "Benavides", "Benavídez", "Benito", "Benítez", "Bermejo", "Bermúdez", "Bernal", "Berríos", "Blanco", "Blasco", "Blázquez", "Bonilla", "Borrego", "Botello", "Bravo", "Briones", "Briseño", "Brito", "Bueno", "Burgos", "Bustamante", "Bustos", "Báez", "Bétancourt",..
			"Caballero", "Cabello", "Cabrera", "Cabán", "Cadena", "Caldera", "Calderón", "Calero", "Calvillo", "Calvo", "Camacho", "Camarillo", "Campos", "Canales", "Candelaria", "Cano", "Cantú", "Caraballo", "Carbajal", "Carballo", "Carbonell", "Cardenas", "Cardona", "Carmona", "Caro", "Carranza", "Carrasco", "Carrasquillo", "Carrera", "Carrero", "Carretero", "Carreón", "Carrillo", "Carrion", "Carrión", "Carvajal", "Casado", "Casanova", "Casares", "Casas", "Casillas", "Castañeda", "Castaño", "Castellano", "Castellanos", "Castillo", "Castro", "Casárez", "Cavazos", "Cazares", "Ceballos", "Cedillo", "Ceja", "Centeno", "Cepeda", "Cerda", "Cervantes", "Cervántez", "Chacón", "Chapa", "Chavarría", "Chávez", "Cintrón", "Cisneros", "Clemente", "Cobo", "Collado", "Collazo", "Colunga", "Colón", "Concepción", "Conde", "Contreras", "Cordero", "Cornejo", "Corona", "Coronado", "Corral", "Corrales", "Correa", "Cortes", "Cortez", "Cortés", "Costa", "Cotto", "Covarrubias", "Crespo", "Cruz", "Cuellar", "Cuenca", "Cuesta", "Cuevas", "Curiel", "Córdoba", "Córdova",..
			"De la cruz", "De la fuente", "De la torre", "Del río", "Delacrúz", "Delafuente", "Delagarza", "Delao", "Delapaz", "Delarosa", "Delatorre", "Deleón", "Delgadillo", "Delgado", "Delrío", "Delvalle", "Diez", "Domenech", "Domingo", "Domínguez", "Domínquez", "Duarte", "Dueñas", "Duran", "Dávila", "Díaz",..
			"Echevarría", "Elizondo", "Enríquez", "Escalante", "Escamilla", "Escobar", "Escobedo", "Escribano", "Escudero", "Esparza", "Espinal", "Espino", "Espinosa", "Espinoza", "Esquibel", "Esquivel", "Esteban", "Esteve", "Estrada", "Estévez", "Expósito",..
			"Fajardo", "Farías", "Feliciano", "Fernández", "Ferrer", "Fierro", "Figueroa", "Flores", "Flórez", "Fonseca", "Font", "Franco", "Frías", "Fuentes",..
			"Gaitán", "Galarza", "Galindo", "Gallardo", "Gallego", "Gallegos", "Galván", "Galán", "Gamboa", "Gamez", "Gaona", "Garay", "García", "Garibay", "Garica", "Garrido", "Garza", "Gastélum", "Gaytán", "Gil", "Gimeno", "Giménez", "Girón", "Godoy", "Godínez", "Gonzales", "González", "Gracia", "Granado", "Granados", "Griego", "Grijalva", "Guajardo", "Guardado", "Guerra", "Guerrero", "Guevara", "Guillen", "Gurule", "Gutiérrez", "Guzmán", "Gálvez", "Gómez",..
			"Haro", "Henríquez", "Heredia", "Hernandes", "Hernando", "Hernádez", "Hernández", "Herrera", "Herrero", "Hidalgo", "Hinojosa", "Holguín", "Huerta", "Hurtado",..
			"Ibarra", "Ibáñez", "Iglesias", "Irizarry", "Izquierdo",..
			"Jaime", "Jaimes", "Jaramillo", "Jasso", "Jiménez", "Jimínez", "Juan", "Jurado", "Juárez", "Jáquez",..
			"Laboy", "Lara", "Laureano", "Leal", "Lebrón", "Ledesma", "Leiva", "Lemus", "Lerma", "Leyva", "León", "Limón", "Linares", "Lira", "Llamas", "Llorente", "Loera", "Lomeli", "Longoria", "Lorente", "Lorenzo", "Lovato", "Loya", "Lozada", "Lozano", "Lucas", "Lucero", "Lucio", "Luevano", "Lugo", "Luis", "Luján", "Luna", "Luque", "Lázaro", "López",..
			"Macias", "Macías", "Madera", "Madrid", "Madrigal", "Maestas", "Magaña", "Malave", "Maldonado", "Manzanares", "Manzano", "Marco", "Marcos", "Mares", "Marrero", "Marroquín", "Martos", "Martí", "Martín", "Martínez", "Marín", "Mas", "Mascareñas", "Mata", "Mateo", "Mateos", "Matos", "Matías", "Maya", "Mayorga", "Medina", "Medrano", "Mejía", "Melgar", "Meléndez", "Mena", "Menchaca", "Mendoza", "Menéndez", "Meraz", "Mercado", "Merino", "Mesa", "Meza", "Miguel", "Millán", "Miramontes", "Miranda", "Mireles", "Mojica", "Molina", "Mondragón", "Monroy", "Montalvo", "Montañez", "Montaño", "Montemayor", "Montenegro", "Montero", "Montes", "Montez", "Montoya", "Mora", "Moral", "Morales", "Moran", "Moreno", "Mota", "Moya", "Munguía", "Murillo", "Muro", "Muñiz", "Muñoz", "Muñóz", "Márquez", "Méndez",..
			"Naranjo", "Narváez", "Nava", "Navarrete", "Navarro", "Navas", "Nazario", "Negrete", "Negrón", "Nevárez", "Nieto", "Nieves", "Niño", "Noriega", "Nájera", "Núñez",..
			"Ocampo", "Ocasio", "Ochoa", "Ojeda", "Oliva", "Olivares", "Olivas", "Oliver", "Olivera", "Olivo", "Olivárez", "Olmos", "Olvera", "Ontiveros", "Oquendo", "Ordoñez", "Ordóñez", "Orellana", "Ornelas", "Orosco", "Orozco", "Orta", "Ortega", "Ortiz", "Ortíz", "Osorio", "Otero", "Ozuna",..
			"Pabón", "Pacheco", "Padilla", "Padrón", "Pagan", "Palacios", "Palomino", "Palomo", "Pantoja", "Pardo", "Paredes", "Parra", "Partida", "Pascual", "Pastor", "Patiño", "Paz", "Pedraza", "Pedroza", "Pelayo", "Peláez", "Perales", "Peralta", "Perea", "Pereira", "Peres", "Peña", "Pichardo", "Pineda", "Pizarro", "Piña", "Piñeiro", "Plaza", "Polanco", "Polo", "Ponce", "Pons", "Porras", "Portillo", "Posada", "Pozo", "Prado", "Preciado", "Prieto", "Puente", "Puga", "Puig", "Pulido", "Páez", "Pérez",..
			"Quesada", "Quezada", "Quintana", "Quintanilla", "Quintero", "Quiroz", "Quiñones", "Quiñónez",..
			"Rael", "Ramos", "Ramírez", "Ramón", "Rangel", "Rascón", "Raya", "Razo", "Redondo", "Regalado", "Reina", "Rendón", "Rentería", "Requena", "Reséndez", "Rey", "Reyes", "Reyna", "Reynoso", "Rico", "Riera", "Rincón", "Riojas", "Rivas", "Rivera", "Rivero", "Robledo", "Robles", "Roca", "Rocha", "Rodarte", "Rodrigo", "Rodrígez", "Rodríguez", "Rodríquez", "Roig", "Rojas", "Rojo", "Roldan", "Roldán", "Rolón", "Romero", "Romo", "Román", "Roque", "Ros", "Rosa", "Rosado", "Rosales", "Rosario", "Rosas", "Roybal", "Rubio", "Rueda", "Ruelas", "Ruiz", "Ruvalcaba", "Ruíz", "Ríos",..
			"Saavedra", "Saiz", "Salas", "Salazar", "Salcedo", "Salcido", "Saldaña", "Saldivar", "Salgado", "Salinas", "Salvador", "Samaniego", "Sanabria", "Sanches", "Sancho", "Sandoval", "Santacruz", "Santamaría", "Santana", "Santiago", "Santillán", "Santos", "Sanz", "Sarabia", "Sauceda", "Saucedo", "Sedillo", "Segovia", "Segura", "Sepúlveda", "Serna", "Serra", "Serrano", "Serrato", "Sevilla", "Sierra", "Silva", "Simón", "Sisneros", "Sola", "Solano", "Soler", "Soliz", "Solorio", "Solorzano", "Solís", "Soria", "Soriano", "Sosa", "Sotelo", "Soto", "Suárez", "Sáenz", "Sáez", "Sánchez",..
			"Tafoya", "Tamayo", "Tamez", "Tapia", "Tejada", "Tejeda", "Tello", "Terrazas", "Terán", "Tijerina", "Tirado", "Toledo", "Tomas", "Toro", "Torres", "Tovar", "Trejo", "Treviño", "Trujillo", "Téllez", "Tórrez",..
			"Ulibarri", "Ulloa", "Urbina", "Ureña", "Uribe", "Urrutia", "Urías",..
			"Vaca", "Valadez", "Valdez", "Valdivia", "Valdés", "Valencia", "Valentín", "Valenzuela", "Valero", "Valladares", "Valle", "Vallejo", "Valles", "Valverde", "Vanegas", "Varela", "Vargas", "Vega", "Vela", "Velasco", "Velásquez", "Velázquez", "Venegas", "Vera", "Verdugo", "Verduzco", "Vergara", "Vicente", "Vidal", "Viera", "Vigil", "Vila", "Villa", "Villagómez", "Villalba", "Villalobos", "Villalpando", "Villanueva", "Villar", "Villareal", "Villarreal", "Villaseñor", "Villegas", "Vásquez", "Vázquez", "Vélez", "Véliz", "Ybarra", "Yáñez", "Zambrano", "Zamora", "Zamudio", "Zapata", "Zaragoza", "Zarate", "Zavala", "Zayas", "Zelaya", "Zepeda", "Zúñiga", "de Anda", "de Jesús", "Águilar", "Álvarez", "Ávalos", "Ávila" ..
			]
	End Method

	'spanish people tend to have 2 family names (father + mother)
	Method GetLastName:string(gender:int)
		if RandRange(0,10) < 2
			return GetRandom(lastNames)
		else
			return GetRandom(lastNames) + " " + GetRandom(lastNames)
		endif
	End Method

End Type



