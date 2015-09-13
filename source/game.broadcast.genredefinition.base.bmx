Import "game.broadcast.audience.bmx" 'has no other game dependencies
Import "game.popularity.genre.bmx"
Import "game.gameobject.bmx"

Type TGenreDefinitionBase extends TGameObject
	Field referenceId:Int
	Field AudienceAttraction:TAudience
	Field TimeMods:Float[]
	'cache popularity (possible because the genre exists the whole game)
	Field _popularity:TPopularity {nosave}


	'override
	Method SetGUID:Int(GUID:String)
		if GUID="" then GUID = GetGUIDBaseName()+"-"+id
		self.GUID = GUID
	End Method


	Method GetGUIDBaseName:string()
		return "genredefinitionbase"
	End Method
	

	Method LoadFromMap(data:TMap)
		local mapData:TData = new TData.Init(data.Copy())
		InitBasic(mapData.GetInt("id"), mapData)
	End Method


	Method InitBasic:TGenreDefinitionBase(referenceID:int, data:TData = null)
		if not data then data = new TData

		SetGUID(GetGUIDBaseName() +"-"+ referenceID)
		self.referenceID = referenceID

		TimeMods = TimeMods[..24]
		For Local i:Int = 0 To 23
			TimeMods[i] = data.GetFloat("timeMod_" + i, 1.0)
		Next

		AudienceAttraction = New TAudience
		AudienceAttraction.Children = data.GetFloat("Children", 0.5)
		AudienceAttraction.Teenagers = data.GetFloat("Teenagers", 0.5)
		AudienceAttraction.HouseWives = data.GetFloat("HouseWives", 0.5)
		AudienceAttraction.Employees = data.GetFloat("Employees", 0.5)
		AudienceAttraction.Unemployed = data.GetFloat("Unemployed", 0.5)
		AudienceAttraction.Manager = data.GetFloat("Manager", 0.5)
		AudienceAttraction.Pensioners = data.GetFloat("Pensioners", 0.5)
		AudienceAttraction.Women = data.GetFloat("Women", 0.5)
		AudienceAttraction.Men = data.GetFloat("Men", 0.5)

		return self
	End Method


	Method GetPopularity:TPopularity()
		if not _popularity
			_popularity = GetPopularityManager().GetByGUID(GetGUID())
			if not _popularity
				_popularity = TGenrePopularity.Create(GetGUID(), RandRange(-10, 10), RandRange(-25, 25))
				GetPopularityManager().AddPopularity(_popularity)
			endif
		endif
		return _popularity
	End Method
	

	Method GetAudienceFlowMod:TAudience(followerDefinition:TGenreDefinitionBase) Abstract
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

		For Local i:Int = 1 To TVTTargetGroup.count
			Local targetGroupID:int = TVTTargetGroup.GetAtIndex(i)
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