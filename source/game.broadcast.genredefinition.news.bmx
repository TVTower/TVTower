SuperStrict
Import "Dig/base.util.registry.bmx"
Import "game.broadcast.genredefinition.base.bmx"
Import "game.broadcastmaterial.base.bmx"
Import "game.popularity.bmx"

Type TNewsGenreDefinitionCollection
	Field definitions:TNewsGenreDefinition[]
	Global _instance:TNewsGenreDefinitionCollection


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
			Set(definition.referenceId, definition)
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

	'override
	Method GetGUIDBaseName:string()
		return "news-genre-definition"
	End Method


	Method InitBasic:TNewsGenreDefinition(genreId:int, data:TData)
		Super.InitBasic(genreId, data)

		return self
	End Method


	Method GetPopularity:TGenrePopularity()
		return TGenrePopularity(Super.GetPopularity())
	End Method

rem
	Method CalculateAudienceAttraction:TAudienceAttraction(news:TBroadcastMaterial, hour:Int, luckFactor:Int = 1)
		Throw "TODO"
		'Local result:TAudienceAttraction = Null

		'Local rawQuality:Float = news.GetQualityRaw()
		'Local quality:Float = Max(0, Min(99, rawQuality))

		'result = CalculateQuotes(quality) 'Genre/Zielgruppe-Mod
		'result.Quality = rawQuality

		'Return result
	End Method
endrem

	Method GetAudienceFlowMod:TAudience(followerDefinition:TGenreDefinitionBase)
		'TODO: Prüfen ob hier auch was zu machen ist?
		Return new TAudience.InitValue(1, 1)
	End Method
End Type

