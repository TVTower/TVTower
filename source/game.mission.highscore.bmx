SuperStrict

Import "Dig/base.util.data.bmx"
?bmxng
Import "Dig/external/persistence.mod/persistence_mxml.bmx"
?not bmxng
Import "Dig/external/persistence.mod/persistence.bmx"
?
Import "game.mission.base.bmx"

Type TMissionHighscore
	'TODO how to access the local time for displaying when the game was played
	'Field realDate:Long
	Field playerID:Int
	Field playerName:String
	Field channelName:String
	Field gameMinutes:Long
	Field missionAccomplished:Int = False
	Field startYear:Int
	Field aiPlayer:Int = False
	Field playerDifficulties:String[]
	'encoded entry of the high score, the mission must be capable of translating it back
	'for presentation and ordering entries
	Field value:TData

	rem
	Method isDuplicate:Int(other:TMissionHighscore)
		If playerID <> other.playerID Then Return False
		If playerName <> other.playerName Then Return False
		If channelName <> other.channelName Then Return False
		If missionAccomplished <> other.missionAccomplished Then Return False
		If aiPlayer <> other.aiPlayer Then Return False
		If playerDifficulty <> other.playerDifficulty Then Return False
		If Abs(gameMinutes - other.gameMinutes) > 1 Then Return False
		'If Abs(realDate - other.realDate) > 500 Then Return False
		'TODO compare data?
		Return True
	End Method
	endrem
End Type

'TODO incorporate number of days per season in missionID (different lists) or highscore itself
Type TMissionHighscores
	Field missionID:String
	Field missiondifficulty:Int 'enum not persisted
	Field scores:TMissionHighscore[] = new TMissionHighscore[0]
End Type

Type TAllHighscores
	Field scores:TMissionHighscores[] = new TMissionHighscores[0]
	Global lastID:String {noSave}
	Global lastDifficulty:String {noSave}
	Global lastScore:TMissionHighscore {noSave}

	Function addEntry(missionID:String, difficulty:MissionDifficulty, score:TMissionHighscore)
		rem
		'prevent duplicate entries - originally cause be duplicate listener registration
		If lastID And lastID = missionID And lastDifficulty = difficulty
			If score.isDuplicate(lastScore) then Return
		EndIf
		lastID = missionID
		lastDifficulty = difficulty
		lastScore = score
		endrem

		TPersist.format=True
		TPersist.maxDepth = 4096
		Local p:TPersist = New TXMLPersistenceBuilder.Build()
		'TODO file location and name
		Local file:String = "highscores.xml"
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
			If missionScore and missionScore.missionID = missionID and missionScore.missiondifficulty = difficulty.ordinal()
				highScoreExisted = True
				missionScore.scores:+ [score]
				persistedScores.scores[index] = missionScore
				Exit
			EndIf
		Next
		If Not highScoreExisted
			missionScore = new TMissionHighscores
			missionScore.missionID = missionID
			missionScore.missiondifficulty = difficulty.ordinal()
			missionScore.scores = [score]
			persistedScores.scores:+ [missionScore]
		EndIf

		p.SerializeToFile(persistedScores, file)
	End Function
End Type