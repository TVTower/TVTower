SuperStrict

Framework brl.StandardIO
Import "../source/Dig/base.util.math.bmx"
Import "../source/game.gameconstants.bmx"
Import "../source/game.registry.loaders.bmx"
Import "../source/game.broadcast.genredefinition.movie.bmx"

Local registryLoader:TRegistryLoader = New TRegistryLoader
registryLoader.LoadFromXML("../config/programmedatamods.xml", true)

Global col:TMovieGenreDefinitionCollection=TMovieGenreDefinitionCollection.GetInstance()
col.Initialize()

'printDefinition([TVTProgrammeGenre.Adventure])

printDefinition2([TVTProgrammeGenre.Adventure, TVTProgrammeGenre.Erotic])

Function printDefinition(genres:Int[])
	Local main:TMovieGenreDefinition = col.Get([genres[0]])

	print TVTProgrammeGenre.GetAsString(genres[0])
	print ""
	print "  id     : "+n2(main.referenceId)
	print "  outcome: "+n2(main.outcomeMod)
	print "  review : "+n2(main.ReviewMod)
	print "  speed  : "+n2(main.SpeedMod)
	print ""
	For Local hour:Int = 0 to 9
		print "  time  "+hour+": "+n2(main.TimeMods[hour])
	Next
	For Local hour:Int = 10 to 23
		print "  time "+hour+": "+n2(main.TimeMods[hour])
	Next
End Function

Function printDefinition2(genres:Int[])
	If genres.length<>2 Then throw "expecting two genres "
	Local main:TMovieGenreDefinition = col.Get([genres[0]])
	Local sub:TMovieGenreDefinition = col.Get([genres[1]])
	Local agg:TMovieGenreDefinition = col.Get(genres)

	print TVTProgrammeGenre.GetAsString(genres[0]) + "+"+TVTProgrammeGenre.GetAsString(genres[1])
	print ""
	print "  id     : "+main.referenceId + " .. " +sub.referenceId + " = " +agg.referenceId
	print "  outcome: "+n2(main.outcomeMod) + " .. " +n2(sub.outcomeMod) + " = " +n2(agg.outcomeMod)
	print "  review : "+n2(main.ReviewMod) + " .. " +n2(sub.ReviewMod) + " = " +n2(agg.ReviewMod)
	print "  speed  : "+n2(main.SpeedMod) + " .. " +n2(sub.SpeedMod) + " = " +n2(agg.SpeedMod)
	print ""
	rem
		For Local hour:Int = 0 to 9
			print "  time  "+hour+": "+n2(main.TimeMods[hour])+ " .. " +n2(sub.TimeMods[hour]) + " = " +n2(agg.TimeMods[hour])
		Next
		For Local hour:Int = 10 to 23
			print "  time "+hour+": "+n2(main.TimeMods[hour])+ " .. " +n2(sub.TimeMods[hour]) + " = " +n2(agg.TimeMods[hour])
		Next
	endrem

	rem
		print main.AudienceAttraction.ToString()
		print sub.AudienceAttraction.ToString()
		print agg.AudienceAttraction.ToString()
	endrem

	print ""
	printFocusPoints("main", main)
	printFocusPoints("sub", sub)
	printFocusPoints("aggregate", agg)

	print ""
	printCastAttributes("main", main)
	printCastAttributes("sub", sub)
	printCastAttributes("aggregate", agg)
End Function

Function n2:String(value:Float)
	return MathHelper.NumberToString(value, 2)
End Function

Function printFocusPoints(id:String, def:TMovieGenreDefinition)
	print "focus points "+id
	For Local key:String = EachIn def.focusPointPriorities.Keys()
		print key+ " : "+ String(def.focusPointPriorities.ValueForKey(key))
	Next
EndFunction

Function printCastAttributes(id:String, def:TMovieGenreDefinition)
	print "cast attributes "+id
	For Local key:String = EachIn def.castAttributes.Keys()
		print key+ " : "+ String(def.castAttributes.ValueForKey(key))
	Next
EndFunction