Type BroadcastSequence Extends TTest
	Method SetAndGet() { test }	
		Local sequence:TBroadcastSequence = New TBroadcastSequence
		
		Local newsShowBC:TBroadcast = new TBroadcast
		newsShowBC.BroadcastType = TBroadcastMaterial.TYPE_NEWSSHOW
		sequence.SetCurrentBroadcast(newsShowBC)
		
		Local programmeShowBC:TBroadcast = new TBroadcast
		programmeShowBC.BroadcastType = TBroadcastMaterial.TYPE_PROGRAMME
		sequence.SetCurrentBroadcast(programmeShowBC)

		Local newsShowBC2:TBroadcast = new TBroadcast
		newsShowBC2.BroadcastType = TBroadcastMaterial.TYPE_NEWSSHOW
		sequence.SetCurrentBroadcast(newsShowBC2)
		
		Local programmeShowBC2:TBroadcast = new TBroadcast
		programmeShowBC2.BroadcastType = TBroadcastMaterial.TYPE_PROGRAMME
		sequence.SetCurrentBroadcast(programmeShowBC2)				
		
		assertSame(programmeShowBC2, sequence.GetCurrentBroadcast(), "1")
		assertSame(newsShowBC2, sequence.GetBeforeBroadcast(), "2")
		assertSame(programmeShowBC, sequence.GetBeforeProgrammeBroadcast(), "3")
		assertSame(newsShowBC2, sequence.GetBeforeNewsShowBroadcast(), "4")
	End Method
End Type