SuperStrict
Import "Dig/base.util.registry.bmx"
Import "game.broadcast.genredefinition.base.bmx"
Import "game.broadcastmaterial.base.bmx"
Import "game.popularity.bmx"

Type TNewsGenreDefinitionCollection
	Field definitions:TNewsGenreDefinition[]
	Global _instance:TNewsGenreDefinitionCollection


	Method New()
		_instance = self
	End Method


	Function GetInstance:TNewsGenreDefinitionCollection()
		if not _instance then _instance = new TNewsGenreDefinitionCollection
		return _instance
	End Function


	Method Initialize()
		'clear old definitions
		definitions = new TNewsGenreDefinition[0]

		Local genreMap:TMap = TMap(GetRegistry().Get("newsgenres"))
		if not genreMap then Throw "Registry misses ~qnewsgenres~q."
		For Local map:TMap = EachIn genreMap.Values()
			Local definition:TNewsGenreDefinition = New TNewsGenreDefinition
			definition.LoadFromMap(map)
			Set(definition.GenreId, definition)
		Next
	End Method


	Method Set:int(id:int=-1, definition:TNewsGenreDefinition)
		If definitions.length <= id Then definitions = definitions[..id+1]
		definitions[id] = definition
	End Method


	Method Get:TNewsGenreDefinition(id:Int)
		If id < 0 or id >= definitions.length Then return Null

		Return definitions[id]
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
Function GetNewsGenreDefinitionCollection:TNewsGenreDefinitionCollection()
	Return TNewsGenreDefinitionCollection.GetInstance()
End Function




Type TNewsGenreDefinition Extends TGenreDefinitionBase
	Method LoadFromMap(data:TMap)
		GenreId = String(data.ValueForKey("id")).ToInt()
		'GenreId = String(data.ValueForKey("name"))

		AudienceAttraction = New TAudience
		AudienceAttraction.Children = String(data.ValueForKey("Children")).ToFloat()
		AudienceAttraction.Teenagers = String(data.ValueForKey("Teenagers")).ToFloat()
		AudienceAttraction.HouseWifes = String(data.ValueForKey("HouseWifes")).ToFloat()
		AudienceAttraction.Employees = String(data.ValueForKey("Employees")).ToFloat()
		AudienceAttraction.Unemployed = String(data.ValueForKey("Unemployed")).ToFloat()
		AudienceAttraction.Manager = String(data.ValueForKey("Manager")).ToFloat()
		AudienceAttraction.Pensioners = String(data.ValueForKey("Pensioners")).ToFloat()
		AudienceAttraction.Women = String(data.ValueForKey("Women")).ToFloat()
		AudienceAttraction.Men = String(data.ValueForKey("Men")).ToFloat()

		Popularity = TGenrePopularity.Create(GenreId, RandRange(-10, 10), RandRange(-25, 25))
		GetPopularityManager().AddPopularity(Popularity) 'Zum Manager hinzufügen

		'Print "Load newsgenre " + GenreId + ": " + AudienceAttraction.ToString()
		'print "OutcomeMod: " + OutcomeMod + " | ReviewMod: " + ReviewMod + " | SpeedMod: " + SpeedMod
	End Method


	Method CalculateAudienceAttraction:TAudienceAttraction(news:TBroadcastMaterial, hour:Int, luckFactor:Int = 1)
		Throw "TODO"
		'Local result:TAudienceAttraction = Null

		'Local rawQuality:Float = news.GetQuality()
		'Local quality:Float = Max(0, Min(99, rawQuality))

		'result = CalculateQuotes(quality) 'Genre/Zielgruppe-Mod
		'result.Quality = rawQuality

		'Return result
	End Method

	Method GetAudienceFlowMod:TAudience(followerDefinition:TGenreDefinitionBase)
		Return TAudience.CreateAndInitValue(1) 'TODO: Prüfen ob hier auch was zu machen ist?
	End Method
End Type

