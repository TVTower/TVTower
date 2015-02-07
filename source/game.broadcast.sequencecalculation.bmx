SuperStrict
Import "game.broadcast.audienceattraction.bmx"

Type TSequenceCalculation
	Field Predecessor:TAudienceAttraction
	Field Successor:TAudienceAttraction
	Field PredecessorShareOnRise:TAudience
	Field PredecessorShareOnShrink:TAudience


	Method GetSequenceDefault:TAudience( riseMod:TAudience = null, shrinkMod:TAudience = null)
		Local result:TAudience = new TAudience
		Local predecessorValue:Float
		Local successorValue:Float
		Local riseModCopy:TAudience
		Local shrinkModCopy:TAudience

		If riseMod <> null Then riseModCopy = riseMod.Copy().CutBordersFloat(0.8, 1.25)
		If shrinkMod <> null Then shrinkModCopy = shrinkMod.Copy().CutBordersFloat(0.25, 1.25)

		For Local i:Int = 1 To TVTTargetGroup.count
			Local targetGroupID:int = TVTTargetGroup.GetAtIndex(i)
			If Predecessor
				predecessorValue = Predecessor.FinalAttraction.GetValue(targetGroupID)
			Else
				predecessorValue = 0
			EndIf
			successorValue = Successor.BaseAttraction.GetValue(targetGroupID)

			Local riseModTemp:Float = 1
			If riseModCopy Then riseModTemp = riseModCopy.GetValue(targetGroupID)
			Local shrinkModTemp:Float = 1
			If shrinkModCopy Then shrinkModTemp = shrinkModCopy.GetValue(targetGroupID)

			Local predShareOnRiseForTG:Float = PredecessorShareOnRise.GetValue(targetGroupID)
			Local predShareOnShrinkForTG:Float = PredecessorShareOnShrink.GetValue(targetGroupID)
			Local sequence:Float = CalcSequenceCase(predecessorValue, successorValue, riseModTemp, shrinkModTemp, predShareOnRiseForTG, predShareOnShrinkForTG)

			result.SetValue(targetGroupID, sequence)
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
End Type