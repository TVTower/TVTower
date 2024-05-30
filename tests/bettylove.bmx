SuperStrict

Framework brl.StandardIO
Import "../source/game.betty.bmx"


For local i:int = 0 to 10
	GetBetty().AdjustLove(1, 100)
	print GetLoveSummary()

	GetBetty().AdjustLove(2, 100)
	print GetLoveSummary()

	GetBetty().AdjustLove(3, 100)
	print GetLoveSummary()

	GetBetty().AdjustLove(4, 100)
	print GetLoveSummary()
Next

global playerMoney:Long[4]
For local i:int = 0 to 100
	local playerID:int = Rand(1,4)
	local present:TBettyPresent
	repeat
		present = TBettyPresent.GetPresent(Rand(0,9))
	until present.bettyValue > 0

	playerMoney[playerID -1] :+ present.price

	GetBetty().AdjustLove(playerID, present.bettyValue)
	print "player "+playerID+": "+ Rset(present.price,8)+"  "+present.GetName()
	print "  "+GetLoveSummary()
Next
print "player 1 spend: "+playerMoney[0]
print "player 2 spend: "+playerMoney[1]
print "player 3 spend: "+playerMoney[2]
print "player 4 spend: "+playerMoney[3]



Function GetLoveSummary:string()
	local res:string
	res :+ RSet(GetBetty().GetInLove(1),5)+" ("+RSet(LSet(GetBetty().GetInLoveShare(1),4)+"%",7)+")~t"
	res :+ RSet(GetBetty().GetInLove(2),5)+" ("+RSet(LSet(GetBetty().GetInLoveShare(2),4)+"%",7)+")~t"
	res :+ RSet(GetBetty().GetInLove(3),5)+" ("+RSet(LSet(GetBetty().GetInLoveShare(3),4)+"%",7)+")~t"
	res :+ RSet(GetBetty().GetInLove(4),5)+" ("+RSet(LSet(GetBetty().GetInLoveShare(4),4)+"%",7)+")~t"
	return res
End Function