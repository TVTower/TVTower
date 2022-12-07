SuperStrict

Import "Dig/base.util.data.bmx"
?bmxng
Import "Dig/external/persistence.mod/persistence_mxml.bmx"
?not bmxng
Import "Dig/external/persistence.mod/persistence.bmx"
?
Import "game.mission.base.bmx"

Type TMissionHighscorePlayerData
	'metadata
	Field playerID:Int
	Field playerName:String
	Field channelName:String
	Field aiPlayer:Int = False
	Field difficulty:String

	'achieved
	Field accountBalance:Int 'money - credit
	Field reach:Float
	Field image:Float
	Field betty:Int
	'additional data?
	'Field data:TData
End Type

Type TMissionHighscore
	Field gameId:Int
	Field realDate:String
	Field primaryPlayer:Int
	Field winningPlayer:Int
	Field gameMinutes:Long
	Field missionAccomplished:Int = False
	Field startYear:Int
	Field playerData:TMissionHighscorePlayerData[]
	Field data:TData
End Type

'TODO incorporate number of days per season in missionID (different lists) or highscore itself
Type TMissionHighscores
	Field missionID:String
	Field missiondifficulty:Int 'enum not persisted
	Field scores:TMissionHighscore[] = new TMissionHighscore[0]
End Type

Type TAllHighscores
	Field scores:TMissionHighscores[] = new TMissionHighscores[0]
	Global lastID:String {nosave}
	Global lastDifficulty:String {nosave}
	Global lastScore:TMissionHighscore {nosave}

	Function addEntry(missionID:String, difficulty:Int, score:TMissionHighscore)
		score.realDate = CurrentDate("%Y-%m-%d %H:%M:%S")
		TPersist.format=True
		TPersist.maxDepth = 4096
		Local p:TPersist = New TXMLPersistenceBuilder.Build()
		'TODO file location
		Local file:String = "missionScores.xml"
		Local persistedScores:TAllHighscores

		If FileType(file) = 1
			persistedScores = TAllHighscores(p.DeSerializeFromFile(file))
		Else
			persistedScores = new TAllHighscores()
		EndIf
		Local highScoreExisted:Int = False
		Local missionScore:TMissionHighscores
		For Local index:Int = 0 Until persistedScores.scores.length
			missionScore = persistedScores.scores[index]
			If missionScore and missionScore.missionID = missionID and missionScore.missiondifficulty = difficulty
				highScoreExisted = True
				missionScore.scores:+ [score]
				persistedScores.scores[index] = missionScore
				Exit
			EndIf
		Next
		If Not highScoreExisted
			missionScore = new TMissionHighscores
			missionScore.missionID = missionID
			missionScore.missiondifficulty = difficulty
			missionScore.scores = [score]
			persistedScores.scores:+ [missionScore]
		EndIf

		p.SerializeToFile(persistedScores, file)
	End Function
End Type