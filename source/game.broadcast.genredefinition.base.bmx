SuperStrict

Import "game.broadcast.audience.bmx" 'has no other game dependencies
Import "game.popularity.genre.bmx"
Import "game.gameobject.bmx"

Type TGenreDefinitionBase extends TGameObject
	Field referenceId:Int
	Field AudienceAttraction:TAudience
	Field TimeMods:Float[]
	'cache popularity (possible because the genre exists the whole game)
	Field _popularity:TPopularity {nosave}


	Method GenerateGUID:string()
		return GetGUIDBaseName()+"-"+id
	End Method


	Method GetGUIDBaseName:string()
		return "genredefinition-base"
	End Method


	Method Reset:int()
		'reset popularity so it gets reconnected correctly
		'after a new game / savegame
		_popularity = null
	End Method


	Method LoadFromMap(data:TMap)
		local mapData:TData = new TData.Init(data)
		InitBasic(mapData.GetInt("id"), mapData)
	End Method


	Method InitBasic:TGenreDefinitionBase(referenceID:int, data:TData = null)
		if not data then data = new TData
		
		Local sb:TStringBuilder = New TStringBuilder
		sb.Append(GetGUIDBaseName()).Append("-").Append(referenceID)
		SetGUID(sb.ToString())

		self.referenceID = referenceID

		TimeMods = TimeMods[..24]
		For Local i:Int = 0 To 23
			sb.SetLength(0)
			sb.Append("timeMod_").Append(i)
			'data is stored as "-1 to +1", we want a multiplier
			'so add +1 to value
			TimeMods[i] = data.GetFloat(sb.ToString(), 0) + 1.0
		Next

		AudienceAttraction = New TAudience
		For local id:int = EachIn TVTTargetGroup.GetBaseGroupIDs()
			Local targetGroupString:String = TVTTargetGroup.GetAsString(id)
			sb.SetLength(0)
			sb.Append(targetGroupString).Append("_men")
			AudienceAttraction.SetGenderValue(id, data.GetFloat(sb.ToString(), 0.5), TVTPersonGender.MALE)

			sb.SetLength(0)
			sb.Append(targetGroupString).Append("_women")
			AudienceAttraction.SetGenderValue(id, data.GetFloat(sb.ToString(), 0.5), TVTPersonGender.FEMALE)
		Next

		return self
	End Method


	Method GetPopularity:TPopularity()
		if not _popularity
			_popularity = GetPopularityManager().GetByReferenceID( GetID() )
			if not _popularity
				_popularity = TGenrePopularity.Create(GetID(), RandRange(-10, 10), RandRange(-25, 25))
				GetPopularityManager().AddPopularity(_popularity)
			endif
		endif
		return _popularity
	End Method


	Method GetAudienceFlowMod:SAudience(followerDefinition:TGenreDefinitionBase) Abstract
	rem
	Method GetSequence:TAudience(predecessor:TAudienceAttraction, successor:TAudienceAttraction, effectRise:Float, effectShrink:Float)
		'genreDefintion.AudienceAttraction.Copy()
		Return TGenreDefinitionBase.GetSequenceDefault(predecessor, successor, effectRise, effectShrink)
	End Method

	Function GetSequenceDefault:TAudience(predecessor:TAudienceAttraction, successor:TAudienceAttraction, effectRise:Float, effectShrink:Float, riseMod:TAudience = null, shrinkMod:TAudience = null)
		Local result:TAudience = new TAudience
		Local predecessorValue:Float
		Local successorValue:Float
		Local rise:Int = false

		For Local targetGroupID:Int = EachIn TVTTargetGroup.GetBaseGroupIDs()
			If predecessor
				predecessorValue = predecessor.BlockAttraction.GetValue(targetGroupID)
			Else
				predecessorValue = 0
			EndIf
			successorValue = successor.BlockAttraction.GetValue(targetGroupID)
			If (predecessorValue < successorValue) 'Steigende Quote
				rise = true
				predecessorValue :* effectRise
				successorValue :* (1 - effectRise)
			Else 'Sinkende Quote
				predecessorValue :* effectShrink
				successorValue :* (1 - effectShrink)
			Endif
			Local sum:Float = predecessorValue + successorValue
			Local sequence:Float = sum - successor.BlockAttraction.GetValue(i)
			If rise Then
				sequence :* riseMod.GetValue(targetGroupID)
			Else
				sequence :* shrinkMod.GetValue(targetGroupID)
			End If
			'TODO: Faktoren berücksichtigen und Audience-Flow usw.
			result.SetValue(targetGroupID, sequence)
		Next
		Return result
	End Function
	endrem
End Type
