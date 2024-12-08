SuperStrict
Import "game.broadcastmaterial.base.bmx"
Import "game.broadcast.base.bmx"
Import "game.broadcast.audienceresult.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.player.finance.bmx"
Import "game.person.base.bmx"
Import "game.popularity.person.bmx"
Import "game.publicimage.bmx"
'Import "game.gameevents.bmx"


'parent of movies, series and so on
Type TProgramme Extends TBroadcastMaterialDefaultImpl {_exposeToLua="selected"}
	Field licence:TProgrammeLicence			{_exposeToLua}
	Field data:TProgrammeData				{_exposeToLua}
	Field maxWholeMarketAudiencePercentage:Float = 0.0

	Method GenerateGUID:String()
		Return "broadcastmaterial-programme-"+id
	End Method


	Function Create:TProgramme(licence:TProgrammeLicence)
		Local obj:TProgramme = New TProgramme
		obj.licence = licence

		If Not licence.isOwnedByPlayer()
			TLogger.Log("TProgramme.Create", "===========", LOG_ERROR)
			TLogger.Log("TProgramme.Create", "Creating programme ~q"+licence.GetTitle()+"~q of licence not owned by a player! Report to developers asap.", LOG_ERROR)
			TLogger.Log("TProgramme.Create", "===========", LOG_ERROR)
		EndIf

		If licence.GetSubLicenceCount() > 0
			TLogger.Log("TProgramme.Create", "===========", LOG_ERROR)
			TLogger.Log("TProgramme.Create", "Creating programme ~q"+licence.GetTitle()+"~q of header licence! Report to developers asap.", LOG_ERROR)
			TLogger.Log("TProgramme.Create", "===========", LOG_ERROR)
			DebugStop
			Return Null
		EndIf


		'store the owner in that moment (later on it might differ as
		'the player sold a licence while the broadcast stays forever)
		obj.SetOwner(licence.owner)
		obj.data = licence.getData()

		obj.setMaterialType(TVTBroadcastMaterialType.PROGRAMME)
		'by default a freshly created programme is of its own type
		obj.setUsedAsType(TVTBroadcastMaterialType.PROGRAMME)

		'someone just gave collection or series header
		If Not obj.data Then Return Null

		Return obj
	End Function


	'override
	Method SourceHasBroadcastFlag:Int(flag:Int) {_exposeToLua}
		'do not ask programmedata but licence
		Return licence.HasBroadcastFlag(flag)
	End Method


	Method IsControllable:Int() {_exposeToLua}
		Return licence.IsControllable()
	End Method


	Method CheckHourlyBroadcastingRevenue:Int(audience:TAudience)
		If Not audience Then Return False

		'callin-shows earn for each sent block... so BREAKs and FINISHs
		'same for "sponsored" programmes
		If Self.usedAsType = TVTBroadcastMaterialType.PROGRAMME
			'fetch the rounded revenue for broadcasting this programme
			Local revenue:Int = audience.GetTotalSum() * Max(0, data.GetPerViewerRevenue(owner))

			If revenue > 0
				'earn revenue for callin-shows
				If data.HasFlag(TVTProgrammeDataFlag.PAID)
					GetPlayerFinance(owner).EarnCallerRevenue(revenue, Self)
				'all others programmes get "sponsored"
				Else
					GetPlayerFinance(owner).EarnSponsorshipRevenue(revenue, Self)
				EndIf
			EndIf
		EndIf
	End Method


	'override
	Method FinishBroadcasting:Int(day:Int, hour:Int, minute:Int, audienceData:Object)
		Super.FinishBroadcasting(day, hour, minute, audienceData)

		'inform data that it got broadcasted by a player
		data.doFinishBroadcast(owner, usedAsType)
		'inform licence that it got broadcasted by a player
		licence.doFinishBroadcast(owner, usedAsType)

		Local audienceResult:TAudienceResult = TAudienceResult(audienceData)

		'calculate outcome for TV
		'but only when broadcasted as normal programme, not trailer
		If usedAsType = TVTBroadcastMaterialType.PROGRAMME
			If data.IsTVDistribution() And data.GetOutcomeTV() < 0
				Local quote:Float = 0
				If audienceResult Then quote = audienceResult.GetWholeMarketAudienceQuotePercentage()
				'base it partially on te production (script) outcome but
				'also on the quote achieved on its first broadcast
				'(this makes it dependend on the managers knowledge on when
				' to best send a specific programme genre)
				data.outcomeTV = 0.4 * quote + 0.6 * data.GetOutcome()
			EndIf
		EndIf


		If Not isOwnedByPlayer()
			TLogger.Log("FinishBroadcastingAsProgramme", "===========", LOG_ERROR)
			TLogger.Log("FinishBroadcastingAsProgramme", "Finishing programme ~q"+GetTitle()+"~q which is not owned by a player! Report to developers asap.", LOG_ERROR)
			TLogger.Log("FinishBroadcastingAsProgramme", "===========", LOG_ERROR)
			Return False
		EndIf


		'store maximum
		If audienceResult
			maxWholeMarketAudiencePercentage = Max(maxWholeMarketAudiencePercentage, audienceResult.GetWholeMarketAudienceQuotePercentage())
		EndIf


		If usedAsType = TVTBroadcastMaterialType.PROGRAMME
			FinishBroadcastingAsProgramme(day, hour, minute, audienceData)
			'aired count is stored in programmedata for now
			'GetBroadcastInformationProvider().SetProgrammeAired(owner, GetBroadcastInformationProvider().GetTrailerAired(owner) + 1, GetWorldTime.GetTimeGoneForGameTime(0,day,hour,minute) )

			'inform others
			TriggerBaseEvent(GameEventKeys.Broadcast_Programme_FinishBroadcasting, New TData.Add("day", day).Add("hour", hour).Add("minute", minute).Add("audienceData", audienceData), Self)
		'sent a trailer
		ElseIf usedAsType = TVTBroadcastMaterialType.ADVERTISEMENT
			FinishBroadcastingAsAdvertisement(day, hour, minute, audienceData)

			'inform others
			TriggerBaseEvent(GameEventKeys.Broadcast_Programme_FinishBroadcastingAsAdvertisement, New TData.Add("day", day).Add("hour", hour).Add("minute", minute).Add("audienceData", audienceData), Self)
'			GetBroadcastInformationProvider().SetTrailerAired(owner, GetBroadcastInformationProvider().GetTrailerAired(owner) + 1, GetWorldTime.GetTimeGoneForGameTime(0,day,hour,minute) )
		Else
			Self.SetState(Self.STATE_OK)
			TLogger.Log("FinishBroadcasting", "Finishing programme broadcast with unknown usedAsType="+usedAsType, LOG_ERROR)
		EndIf

		Return True
	End Method


	'override
	Method AbortBroadcasting:Int(day:Int, hour:Int, minute:Int, audienceData:Object)
		Super.AbortBroadcasting(day, hour, minute, audienceData)

		data.doAbortBroadcast(owner, usedAsType)
	End Method


	'override
	Method BeginBroadcasting:Int(day:Int, hour:Int, minute:Int, audienceData:Object)
		Super.BeginBroadcasting:Int(day, hour, minute, audienceData)

		'inform licence and data that it gets broadcasted by a player
		licence.doBeginBroadcast(owner, usedAsType)
		data.doBeginBroadcast(owner, usedAsType)

		'reset stat
		maxWholeMarketAudiencePercentage = 0.0

		Local audienceResult:TAudienceResult = TAudienceResult(audienceData)


		'only fetch new audience stats when send as programme (ignore trailer)
		If Self.usedAsType = TVTBroadcastMaterialType.PROGRAMME
			'remove old "last audience" data to avoid wrong "average values"
			licence.GetBroadcastStatistic().RemoveLastAudienceResult(owner)
			'store audience for this block
			licence.GetBroadcastStatistic().SetAudienceResult(owner, currentBlockBroadcasting, audienceResult)

			If licence And licence.effects
				Local effectParams:TData = New TData.Add("programmeId", Self.licence.GetId())
				licence.effects.Update("broadcast", effectParams)
				'very first broadcast - not owner dependent
				If licence.data.GetTimesBroadcasted(-1) = 0 Then licence.effects.Update("broadcastFirstTime", effectParams)
			EndIf

			'inform others
			TriggerBaseEvent(GameEventKeys.Broadcast_Programme_BeginBroadcasting, New TData.Add("day", day).Add("hour", hour).Add("minute", minute).Add("audienceData", audienceData), Self)
		ElseIf usedAsType = TVTBroadcastMaterialType.ADVERTISEMENT
			'inform others
			TriggerBaseEvent(GameEventKeys.Broadcast_Programme_BeginBroadcastingAsAdvertisement, New TData.Add("day", day).Add("hour", hour).Add("minute", minute).Add("audienceData", audienceData), Self)
		EndIf
	End Method


	'override
	Method ContinueBroadcasting:Int(day:Int, hour:Int, minute:Int, audienceData:Object)
		Super.ContinueBroadcasting(day, hour, minute, audienceData)

		Local audienceResult:TAudienceResult = TAudienceResult(audienceData)

		'store audience for this block
		licence.GetBroadcastStatistic().SetAudienceResult(owner, currentBlockBroadcasting, audienceResult)
	End Method


	'override
	Method BreakBroadcasting:Int(day:Int, hour:Int, minute:Int, audienceData:Object)
		Super.BreakBroadcasting:Int(day, hour, minute, audienceData)

		Local audienceResult:TAudienceResult = TAudienceResult(audienceData)

		'store maximum
		maxWholeMarketAudiencePercentage = Max(maxWholeMarketAudiencePercentage, audienceResult.GetWholeMarketAudienceQuotePercentage())

		'check if revenues have to get paid (call-in-shows, sponsorships)
		CheckHourlyBroadcastingRevenue(audienceResult.audience)
	End Method


	Method FinishBroadcastingAsAdvertisement:Int(day:Int, hour:Int, minute:Int, audienceData:Object)
		Self.SetState(Self.STATE_OK)
		Local audienceResult:TAudienceResult = TAudienceResult(audienceData)

		'=== ADJUST TRAILER EFFECT ===
		'adjust topicality relative to possible audience
		'do not use "maxWholeMarketAudiencePercentage" here, as a trailer
		'is only send during one block
		data.CutTrailerTopicality(GetTrailerTopicalityCutModifier( audienceResult.GetWholeMarketAudienceQuotePercentage() ))
		data.trailerAired:+1
		data.SetTimesTrailerAiredSinceLastBroadcast( data.GetTimesTrailerAiredSinceLastBroadcast(owner) + 1 )

		'the more often a trailer got aired for an upcoming programme,
		'the less effective it gets (eg. people who see it again get
		'annoyed and loose interest in the programme)
		'regardless of this, a trailer can never be more effective than
		'90% (some people just do ignore trailers)
		Local trailerEffectiveness:Float = 0.90 * Float(0.98^Min(8, data.GetTimesTrailerAiredSinceLastBroadcast(owner)))
		Local effectiveAudience:TAudience = audienceResult.GetWholeMarketAudienceQuote().Copy().Multiply(trailerEffectiveness)
		data.GetTrailerMod(owner, True).Add( effectiveAudience )
		'avoid the mod to become bigger than 1.0
		data.GetTrailerMod(owner, True).CutBorders(0.0, 1.0)
	End Method


	Method FinishBroadcastingAsProgramme:Int(day:Int, hour:Int, minute:Int, audienceData:Object)
		If Not isOwnedByPlayer()
			TLogger.Log("FinishBroadcastingAsProgramme", "===========", LOG_ERROR)
			TLogger.Log("FinishBroadcastingAsProgramme", "Finishing a programme not owned by a player! Report to developers asap.", LOG_ERROR)
			TLogger.Log("FinishBroadcastingAsProgramme", "===========", LOG_ERROR)
		EndIf

		Self.SetState(Self.STATE_OK)

		Local audienceResult:TAudienceResult = TAudienceResult(audienceData)


		'=== PAY REVENUES ===
		'check if revenues have to get paid (call-in-shows, sponsorships)
		CheckHourlyBroadcastingRevenue(audienceResult.audience)


		'=== ADJUST TRENDS / POPULARITY ===
		Local popularity:TGenrePopularity = data.GetGenreDefinition().GetPopularity()
		Local popData:TData = New TData
		popData.Add("attractionQuality", audienceResult.AudienceAttraction.Quality)
		popData.Add("audienceSum", audienceResult.Audience.GetTotalSum())
		popData.Add("audienceWholeMarketQuote", audienceResult.GetWholeMarketAudienceQuotePercentage())
		popData.Add("broadcastTopAudience", GetBroadcastManager().GetCurrentBroadcast().GetTopAudience())

		popularity.FinishBroadcastingProgramme(popData, GetBlocks())

		'adjust popularity of cast too
		For Local job:TPersonProductionJob = EachIn data.cast
			Local p:TPersonBase = GetPersonBase(job.personID)
			'skip invalid data or "insignificant persons"
			If Not p Then Continue
			Local pPop:TPersonPopularity = TPersonPopularity(p.GetPopularity())
			If Not pPop Then Continue
			pPop.FinishBroadcastingProgramme(popData)
		Next


		'=== ADJUST PRESSURE GROUPS ===
		'TODO: aehnlich wie attractionmods fuer zielgruppen, muss definiert werden, welche
		'      Genre Einfluss auf die Lobbygruppen nehmen (bzw. "ob")
		'      Alternativ - aehnlich einem Flag "definieren", dass dieses Programm ueberhaupt
		'      Einfluss hat ("Werbefilm")
'Print "game.broadcastmaterial.programme.bmx:  adjust pressure groups!"


		'=== ADJUST CHANNEL IMAGE ===
		'Image-Penalty
		If data.IsPaid()
			TLogger.Log("ChangePublicImage()", "Player #"+owner+": image change for paid programme.", LOG_DEBUG)
			'-1 = for both genders
			Local penalty:SAudience = New SAudience(-1,  -0.25, -0.25, -0.15, -0.35, -0.15, -0.55, -0.15)
			penalty.Multiply(data.blocks)
			GetPublicImage(owner).ChangeImage(penalty)
			TLogger.Log("TAdvertisement.FinishBroadcastingAsProgramme", "Player #"+owner+": image change for paid programme: " + penalty.ToString(), LOG_DEBUG)
		EndIf
		If data.IsTrash()
			TLogger.Log("ChangePublicImage()", "Player #"+owner+": image change for trash programme.", LOG_DEBUG)
			Local penalty:SAudience = New SAudience(-1,  0, 0, +0.2, -0.2, +0.2, -0.5, -0.1)
			penalty.Multiply(data.blocks)
			GetPublicImage(owner).ChangeImage(penalty)
		End If


		'=== MISC ===
		'adjust topicality relative to possible audience
		'using the maximum of all blocks here (as this is the maximum
		'audience knowing about that movie)
		If TProgrammeLicenceCollection.GetInstance().IsLicenceDataUsedMultipleTimes(data.GetID())
			'print "did non use difficulty for topicality cut because the data is used by multiple licences"
			data.CutTopicality(GetTopicalityCutModifier(maxWholeMarketAudiencePercentage))
		Else
			'If the programme data is unique to the owned licence, use player difficulty modifier
			Local difficultyMod:Float = GetPlayerDifficulty(GetOwner()).programmeTopicalityCutMod
			data.CutTopicality(GetTopicalityCutModifier( maxWholeMarketAudiencePercentage ) / difficultyMod)
		EndIf


		'if someone can watch that movie, increase the aired amount
		'for data and licence
		data.SetTimesBroadcasted(data.GetTimesBroadcasted(owner)+1, owner)
		licence.SetTimesBroadcasted(licence.GetTimesBroadcasted(owner)+1, owner)


		'reset trailer count
		data.SetTimesTrailerAiredSinceLastBroadcast(0, owner)
		'reset trailerMod
		data.RemoveTrailerMod(owner)

		'now the trailer is for the next broadcast...
		'instead of just setting back topicality, just refresh it "once"
		'data.trailerTopicality = 1.0
		data.RefreshTrailerTopicality()

		If licence And licence.effects
			Local effectParams:TData = New TData.Add("programmeId", Self.licence.GetId()).Add("playerID", Self.licence.GetOwner())
			licence.effects.Update("broadcastDone", effectParams)
			'very first broadcast - not owner dependent
			If data.GetTimesBroadcasted(-1) = 1 Then licence.effects.Update("broadcastFirstTimeDone", effectParams)
		EndIf

		'print "aired programme "+GetTitle()+" "+data.GetTimesAired(owner)+"x."
		'print self.GetTitle() + "  finished at day="+day+" hour="+hour+" minute="+minute + " aired="+data.timesAired + " topicality="+data.topicality+" oldTop="+oldTop
	End Method


	Method HasProgrammeFlag:Int(flag:Int) {_exposeToLua}
		Return data.HasFlag(flag)
	End Method


	Method GetProgrammeFlags:Int() {_exposeToLua}
		Return data.flags
	End Method


	Method GetQuality:Float() {_exposeToLua}
		Return data.GetQuality()
	End Method

	'override
	'reduce movie quality if not sent with maximal topicality
	Method GetTopicalityModifier:Float()
		Local topicality:Float = data.GetTopicality()
		Local diff:Float = data.maxTopicalityCache - topicality
		If diff <= 0
			Return 1.05
		ElseIf diff > 0.2
			Return 0.6
		ElseIf diff > 0.1
			Return 0.75
		ElseIf diff > 0.05
			Return 0.9
		EndIf
		Return 1.0
	End Method


	'override
	Method GetCastMod:Float()
		Local result:Float = 1.0
		'cast popularity has influence of up to 75%
		result :+ 0.75 * data.GetCastPopularity()
		'cast base fame has an influence too (even if unpopular!)
		result :+ 0.25 * data.GetCastFame()

		'print "castmod: "+result +"  pop: "+ data.GetCastPopularity()
		Return result
	End Method


	'add targetgroup bonus (25% attractivity bonus)
	Method GetTargetGroupAttractivityMod:SAudience() override
		Local result:SAudience = Super.GetTargetGroupAttractivityMod()

		'for all defined targetgroups, increase interest
		If data.GetTargetGroups() > 0
			Local tgAudience:SAudience = New SAudience(1, 1)
			For Local targetGroup:Int = 1 To TVTTargetGroup.count
				Local targetGroupID:Int = TVTTargetGroup.GetAtIndex(targetGroup)
				If data.HasTargetGroup(targetGroupID)
					'print "GetMiscMod: bonus for: "+ TVTTargetGroup.GetAsString(targetGroupID)

					'for women/men this only is run for the
					'female/male portion of the audience
					tgAudience.ModifyTotalValue(targetGroupID, 0.25)
				EndIf
			Next
			'print "multplying with: " + tgAudience.TosTring()
			result.Multiply(tgAudience)
		EndIf

		'modify with a complete fine grained target group setup
		result.Multiply( licence.GetTargetGroupAttractivityMod() )

		Return result
	End Method


	'override
	Method GetTrailerMod:TAudience()
		'return an existing trailerMod or create a new one
		If data Then Return data.GetTrailerMod(owner, True)

		Return Super.GetTrailerMod()
	End Method


	'generate average of all flags
	Method GetFlagsTargetGroupMod:SAudience() override
		Local definitions:TGenreDefinitionBase[] = _GetFlagDefinitions()
		Local audienceMod:SAudience = New SAudience(1, 1)

		If definitions.length > 0
			For Local definition:TMovieFlagDefinition = EachIn definitions
				audienceMod.Multiply( GetFlagTargetGroupMod(definition) )
			Next
			audienceMod.Divide(definitions.length)

			audienceMod.CutBorders(0.0, 2.0)
		EndIf

		Return audienceMod
	End Method


	'override
	'generate average of all flags
	Method GetFlagsPopularityMod:Float()
		Local definitions:TGenreDefinitionBase[] = _GetFlagDefinitions()
		Local valueMod:Float = 1.0

		If definitions.length > 0
			valueMod = 0.0
			For Local definition:TMovieFlagDefinition = EachIn definitions
				valueMod :+ GetFlagPopularityMod(definition)
			Next
			valueMod :/ definitions.length
		EndIf

		MathHelper.Clamp(valueMod, 0.0, 2.0)
		Return valueMod
	End Method


	'override
	'generate average of all flags
	Method GetFlagsTimeMod:Float(hour:Int)
		Local definitions:TGenreDefinitionBase[] = _GetFlagDefinitions()
		Local valueMod:Float = 1.0

		If definitions.length > 0
			valueMod = 0.0
			For Local definition:TMovieFlagDefinition = EachIn definitions
				valueMod :+ GetGenreTimeMod(definition, hour)
			Next
			valueMod :/ definitions.length
		EndIf
		'TODO bias for erotic programmes during the day
		If data.HasSubGenre(TVTProgrammeGenre.Erotic) And hour > 5 And hour < 20
			valueMod:* 0.9
		EndIf

		MathHelper.Clamp(valueMod, 0.0, 2.0)
		Return valueMod
	End Method


	'override
	'add game modifier support
	Method GetFlagsMod:Float()
		Local valueMod:Float = Super.GetFlagsMod()
		For Local i:Int = 0 Until TVTProgrammeDataFlag.count
			If data.HasFlag(TVTProgrammeDataFlag.GetAtIndex(i))
'TODO: write all of them as TLowerString Keys?
				valueMod :* GameConfig.GetModifier("Attractivity.ProgrammeDataFlag."+TVTProgrammeDataFlag.GetAtIndex(i))
				valueMod :* GameConfig.GetModifier("Attractivity.ProgrammeDataFlag.player"+GetOwner()+"."+TVTProgrammeDataFlag.GetAtIndex(i))
			EndIf
		Next

		Return valueMod
	End Method


	'override
	'add game modifier support
	Method GetGenreMod:Float()
		Local valueMod:Float = Super.GetGenreMod()

		valueMod :* GameConfig.GetModifier("Attractivity.ProgrammeGenre."+data.GetGenre())
		valueMod :* GameConfig.GetModifier("Attractivity.ProgrammeGenre.player"+GetOwner()+"."+data.GetGenre())

		Return valueMod
	End Method


	'helper
	Method _GetFlagDefinitions:TGenreDefinitionBase[]()
		Local definitions:TMovieFlagDefinition[]
		Local definition:TMovieFlagDefinition

		'Genereller Quotenbonus!
		If data.IsLive()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.LIVE)
			If definition Then definitions :+ [definition]
		EndIf


		'Bonus bei Kindern / Jugendlichen. Malus bei Rentnern / Managern.
		If data.IsAnimation()
			'Da es jetzt doch ein Genre gibt, brauchen wir Animation nicht mehr.
			'Eventuell kann man daraus ein Kids-Genre machen... aber das kann man auch eventuell über Zielgruppen regeln.
			'Dennoch ist Kids wohl besser als Animation. Animation kann nämlich sowohl Southpark als auch Biene Maja sein. Das hat definitiv andere Zielgruppen.
		EndIf


		'Bonus bei Betty und bei Managern
		If data.IsCulture()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.CULTURE)
			If definition Then definitions :+ [definition]
		EndIf


		'Verringert die Nachteile des Filmalters. Bonus bei Rentnern.
		'Höhere Serientreue bei Serien.
		If data.IsCult()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.CULT)
			If definition Then definitions :+ [definition]
		EndIf


		'Bonus bei Arbeitslosen und Hausfrauen. Malus bei Arbeitnehmern
		'und Managern. Trash läuft morgens und mittags gut => Bonus!
		If data.IsTrash()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.TRASH)
			If definition Then definitions :+ [definition]
		EndIf


		'Nochmal deutlich verringerter Preis. Verringert die Nachteile
		'des Filmalters. Bonus bei Jugendlichen. Malus bei allen anderen
		'Zielgruppen. Bonus in der Nacht!
		If data.IsBMovie()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.BMOVIE)
			If definition Then definitions :+ [definition]
		EndIf


		'Kleiner Bonus für Jugendliche, Arbeitnehmer, Arbeitslose, Männer.
		'Kleiner Malus für Kinder, Hausfrauen, Rentner, Frauen.
		If data.IsXRated()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.XRATED)
			If definition Then definitions :+ [definition]
		EndIf


		If data.IsScripted()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.SCRIPTED)
			If definition Then definitions :+ [definition]
		EndIf


		If data.IsPaid()
			definition = GetMovieGenreDefinitionCollection().GetFlag(TVTProgrammeDataFlag.PAID)
			If definition Then definitions :+ [definition]
		EndIf

		Return definitions
	End Method




	Method GetAudienceFlowBonus:TAudience(block:Int, result:TAudienceAttraction, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction) {_exposeToLua}
		'calculate the audienceflow from one programme to another one

		If block = 1 And lastMovieBlockAttraction And lastNewsBlockAttraction
			Return GetAudienceFlowBonusIntern(lastMovieBlockAttraction, result, lastNewsBlockAttraction)
		EndIf

		Return Super.GetAudienceFlowBonus(block, result, lastMovieBlockAttraction, lastNewsBlockAttraction)
	End Method


	Function GetAudienceFlowBonusIntern:TAudience(lastMovieBlockAttraction:TAudienceAttraction, currentAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction )
		If not lastMovieBlockAttraction.GenreDefinition
			Return New TAudience.Set(0, 0) 'Ganze schlechter Follower
		EndIf

		Local flowModBase:TAudience = New TAudience
		Local flowModBaseTemp:Float

		'AudienceFlow anhand der Differenz und ob steigend oder sinkend. Nur sinkend gibt richtig AudienceFlow
		For Local targetGroupID:Int = EachIn TVTTargetGroup.GetBaseGroupIDs()
			For Local genderIndex:Int = 0 To 1
				Local gender:Int = TVTPersonGender.FEMALE
				If genderIndex = 1 Then gender = TVTPersonGender.MALE
				Local predecessorValue:Float = Min(lastMovieBlockAttraction.FinalAttraction.GetGenderValue(targetGroupID, gender), lastNewsBlockAttraction.FinalAttraction.GetGenderValue(targetGroupID, gender))
				'FinalAttraction ist noch nicht verfügbar. BaseAttraction ist also akzeptabel.
				Local successorValue:Float = currentAttraction.BaseAttraction.GetGenderValue(targetGroupID, gender)

				If (predecessorValue < successorValue) 'Steigende Quote = kaum AudienceFlow
					flowModBaseTemp = predecessorValue * 0.05
				Else 'Sinkende Quote
					flowModBaseTemp = (predecessorValue - successorValue) * 0.75
				EndIf

				flowModBase.SetGenderValue(targetGroupID, Max(0.05, flowModBaseTemp), gender)
			Next
		Next

		'Wie gut ist der Follower? Gleiche Genre passen perfekt zusammen, aber es gibt auch gute und schlechte Followerer anderer genre
		Local flowMod:SAudience = lastMovieBlockAttraction.GenreDefinition.GetAudienceFlowMod(currentAttraction.GenreDefinition)

		'Ermittlung des Maximalwertes für den Bonus. Wird am Schluss gebraucht
		Local flowMaximum:SAudience = currentAttraction.BaseAttraction.data 'struct copy!
		Local lastNewsBlockFlowMax:SAudience = lastNewsBlockAttraction.FinalAttraction.data 'struct copy
		lastNewsBlockFlowMax.Divide(2)
		flowMaximum.Divide(2)
		flowMaximum.CutMaximum( lastNewsBlockFlowMax ) 'Die letzte News-Show gibt an, wie viel überhaupt noch dran sind um in den Flow zu kommen.
		flowMaximum.CutBorders(0.1, 0.35)

		'Der Flow hängt nicht nur von den zuvorigen Zuschauern ab, sondern zum Teil auch von der Qualität des Nachfolgeprogrammes.
		Local attrMod:SAudience = currentAttraction.BaseAttraction.data
		attrMod.Divide(2)
		attrMod.CutBorders(0, 0.6)
		attrMod.Add(0.6) '0.6 - 1.2

		flowModBase.data.CutMaximum(flowMaximum)
		flowModBase.data.Multiply(attrMod) '0.6 - 1.2
		flowModBase.data.Multiply(flowMod) '0.1 - 1
		flowModBase.data.CutMaximum(flowMaximum)
		Return flowModBase
	End Function


	'for details check game.broadcastmaterial.base.bmx: GetTopicalityCutModifier()
	Method GetTrailerTopicalityCutModifier:Float(audienceQuote:Float = 1.0) {_exposeToLua}
		Return GetTopicalityCutModifier( audienceQuote )
	End Method


	'override default to use blocksamount of programme instead
	Method GetBlocks:Int(broadcastType:Int=0) {_exposeToLua}
		If broadcastType = 0 Then broadcastType = usedAsType

		Return licence.GetBlocks(broadcastType)
	End Method


	'override default getter
	Method GetDescription:String() {_exposeToLua}
		Return data.GetDescription()
	End Method


	'get the title
	Method GetTitle:String() {_exposeToLua}
		Return data.GetTitle()
	End Method


	'override default
	Method GetReferenceID:Int() {_exposeToLua}
		Return licence.GetReferenceID()
	End Method


	Method HasSource:Int(obj:Object) {_exposeToLua}
		If TProgrammeLicence(obj)
			Return TProgrammeLicence(obj) = licence
		EndIf
		Return Super.HasSource(obj)
	End Method


	Method GetSource:TBroadcastMaterialSource() {_exposeToLua}
		Return Self.licence
	End Method


	Method GetEpisodeNumber:Int() {_exposeToLua}
		Return licence.GetEpisodeNumber()
	End Method


	Method GetEpisodeCount:Int() {_exposeToLua}
		Return licence.GetEpisodeCount()
	End Method


	Method IsSeriesEpisode:Int()
		Return Self.licence.isEpisode()
	End Method


	Method IsCollectionElement:Int()
		Return Self.licence.isCollectionElement()
	End Method


	Method ShowSheet:Int(x:Int,y:Int, align:Float=  0.5) override
		Local extra:TData = New TData
		extra.Add("programmedDay", programmedDay)
		extra.Add("programmedHour", programmedHour)

		'show sheet with stats of the broadcast owner, not the current
		'licence owner
		Self.licence.ShowSheet(x, y, align, Self.usedAsType, owner, extra)
	End Method


	'override
	Method GetGenreDefinition:TGenreDefinitionBase()
		Return data.GetGenreDefinition()
	End Method
End Type
