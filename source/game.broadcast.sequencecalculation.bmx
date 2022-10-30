SuperStrict
Import "game.broadcast.audienceattraction.bmx"

Struct SSequenceCalculation
	Field Predecessor:TAudienceAttraction
	Field Successor:TAudienceAttraction
	Field PredecessorShareOnRise:SAudience
	Field PredecessorShareOnShrink:SAudience


	Method GetSequenceDefault:SAudience( riseMod:SAudience, shrinkMod:SAudience)
		Local result:SAudience
		Local predecessorValue:Float
		Local successorValue:Float

		riseMod.CutBorders(0.8, 1.25)
		shrinkMod.CutBorders(0.25, 1.25)

		For Local targetGroupID:Int = EachIn TVTTargetGroup.GetBaseGroupIDs()
			For local genderIndex:int = 0 to 1
				local gender:int = TVTPersonGender.FEMALE
				if genderIndex = 1 then gender = TVTPersonGender.MALE
				If Predecessor and Predecessor.FinalAttraction
					predecessorValue = Predecessor.FinalAttraction.GetGenderValue(targetGroupID, gender)
				Else
					predecessorValue = 0
				EndIf
				successorValue = Successor.BaseAttraction.GetGenderValue(targetGroupID, gender)

				Local riseModTemp:Float = riseMod.GetGenderValue(targetGroupID, gender)
				Local shrinkModTemp:Float = shrinkMod.GetGenderValue(targetGroupID, gender)

				Local predShareOnRiseForTG:Float = PredecessorShareOnRise.GetGenderValue(targetGroupID, gender)
				Local predShareOnShrinkForTG:Float = PredecessorShareOnShrink.GetGenderValue(targetGroupID, gender)
				Local sequence:Float = CalcSequenceCase(predecessorValue, successorValue, riseModTemp, shrinkModTemp, predShareOnRiseForTG, predShareOnShrinkForTG)

				result.SetGenderValue(targetGroupID, sequence, gender)
			Next
		Next

		Return result
	End Method


	Method CalcSequenceCase:Float(predecessorValue:Float, successorValue:Float, riseMod:Float, shrinkMod:Float, predShareOnRise:Float, predShareOnShrink:Float)
		Local rise:Int = false
		Local successorValueInitial:Float = successorValue

		If (predecessorValue < successorValue) 'Steigende Quote
			rise = true
			predecessorValue :* predShareOnRise
			successorValue :* (1 - predShareOnRise)
		Else 'Sinkende Quote
			predecessorValue :* predShareOnShrink
			successorValue :* (1 - predShareOnShrink)
		Endif

		'Um diese Berechnung zu verstehen, bitte den UnitTest "SequenceCalculationTest" anschauen
		Local sequence:Float = (predecessorValue + successorValue) - successorValueInitial
		If rise Then 'Wenn die Quote steigt, dann bremst der SequenceFactor aus: also negative Zahl
			'If riseMod > 1 Then
				sequence :* (1 / riseMod)
			'EndIf
		Else 'Wenn die Quote schrumpft, dann erhöht der SequenceFactor... er bremst den Fall siehe u.a. auch Audience Flow
			sequence :* shrinkMod
		End If
		Return sequence
	End Method
End Struct