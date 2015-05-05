Type BroadcastTest Extends TTest
	Field TestPlayer:TPlayer
	Field BroadcastManager:TBroadcastManager

	Method InitTest() { before }
		TTestKit.SetGame()		
		TestPlayer = TTestKit.SetPlayer()
		BroadcastManager = New TBroadcastManager
	End Method
	
	Method ExitTest() { after }
		TTestKit.RemoveGame()
	End Method

    Method TestBroadcastProgramme() { test }
		Local programme1:TProgramme = TTestKit.CrProgrammeSmall("abc", 1)
		programme1.owner = 1

    	BroadcastManager.SetCurrentBroadcastMaterial(1, programme1, TBroadcastMaterial.TYPE_PROGRAMME)
		Local bc:TBroadcast = new TBroadcast	
		bc.AudienceMarkets.AddLast(TTestKit.CrAudienceMarketCalculation(1000000, True))		
		BroadcastManager.BroadcastProgramme(1, 1, 0, bc)
    	Local audienceResult:TAudienceResult = BroadcastManager.GetAudienceResult(1)
		
		TestAssert.assertEqualsAud(TAudience.CreateAndInit(345, 3067, 6440, 21735, 5175, 2070, 20930, 30240, 29522), audienceResult.Audience)
    End Method	
	
    Method TestSetBroadcastMalfunction() { test }
		Local programme1:TProgramme = TTestKit.CrProgrammeSmall("abc", 1)
		programme1.owner = 1

    	BroadcastManager.SetCurrentBroadcastMaterial(1, programme1, TBroadcastMaterial.TYPE_PROGRAMME)
		Local bc:TBroadcast = new TBroadcast	
		bc.AudienceMarkets.AddLast(TTestKit.CrAudienceMarketCalculation(1000000, True))		
		BroadcastManager.BroadcastProgramme(1, 1, 0, bc)
    	Local audienceResult:TAudienceResult = BroadcastManager.GetAudienceResult(1)
		
		TestAssert.assertEqualsAud(TAudience.CreateAndInit(345, 3067, 6440, 21735, 5175, 2070, 20930, 30240, 29522), audienceResult.Audience)
		
		BroadcastManager.SetBroadcastMalfunction(1)
		audienceResult = BroadcastManager.GetAudienceResult(1)
		
		TestAssert.assertEqualsAud(TAudience.CreateAndInitValue(0), audienceResult.Audience)
    End Method

End Type