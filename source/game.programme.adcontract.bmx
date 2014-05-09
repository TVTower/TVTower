Rem
	====================================================================
	AdContract data - contracts of broadcastable advertisements
	====================================================================

	The normal contract data is splitted into "contractBase" and
	"contract". So the resulting contract can differ to the raw database
	contract (eg. discounts, special prices...). Also you can have the
	same contract data with different ids ... so multiple incarnations
	of a contract are possible.
EndRem
SuperStrict
Import "game.gameobject.bmx"
Import "game.gametime.bmx"
'to fetch maximum audience
Import "game.stationmap.bmx"
Import "game.broadcastmaterial.base.bmx"



'contracts bases for advertisement - straight from the DB
'they just contain data to base new contracts of
Type TAdContractBase extends TGameObject {_exposeToLua}
	Field title:string			= ""
	Field description:string	= ""
	Field daysToFinish:Int					' days to fullfill a (signed) contract
	Field spotCount:Int						' spots to send
	Field blocks:int = 1					' blocklength
	Field targetGroup:Int					' target group of the spot
	Field minAudienceBase:Float				' minimum audience (real value calculated on sign)
	Field minImageBase:Float				' minimum image base value (real value calculated on sign)
	Field hasFixedPrice:Int					' flag wether price is fixed
	Field profitBase:Float					' base of profit (real value calculated on sign)
	Field penaltyBase:Float					' base of penalty (real value calculated on sign)
	Field infomercialAllowed:int = TRUE		' is the broadcast of an infomercial allowed?
	global List:TList = CreateList()		' holding all TContractBases


	Method Create:TAdContractBase(title:String, description:String, daystofinish:Int, spotcount:Int, targetgroup:Int, minaudience:Int, minimage:Int, fixedPrice:Int, profit:Int, penalty:Int)
		self.title			= title
		self.description	= description
		self.daysToFinish	= daystofinish
		self.spotCount		= spotcount
		self.targetGroup	= targetgroup
		self.minAudienceBase= Float(minaudience) / 10.0
		self.minImageBase	= Float(minimage) / 10.0
		self.hasFixedPrice	= fixedPrice
		self.profitBase		= Float(profit)
		self.penaltyBase 	= Float(penalty)

		List.AddLast(self)
		Return self
	End Method


	Function Get:TAdContractBase(id:Int) {_exposeToLua}
		For Local obj:TAdContractBase = EachIn List
			If obj.id = id Then Return obj
		Next
		Return Null
	End Function


	Function GetRandom:TAdContractBase(_list:TList = null)
		if _list = Null then _list = List
		If _list = Null Then Return Null
		If _list.count() > 0
			Local obj:TAdContractBase = TAdContractBase(_list.ValueAtIndex((randRange(0, _list.Count() - 1))))
			if obj then return obj
		endif
		return Null
	End Function


	Function GetRandomWithLimitedAudienceQuote:TAdContractBase(minAudienceQuote:float=0.0, maxAudienceQuote:Float=0.35)
		'maxAudienceQuote - xx% market share as maximum
		'filter to entries we need
		Local resultList:TList = CreateList()
		For local obj:TAdContractBase = EachIn TAdContractBase.list
			If obj.minAudienceBase >= minAudienceQuote AND obj.minAudienceBase <= maxAudienceQuote
				resultList.addLast(obj)
			EndIf
		Next
		Return TAdContractBase.GetRandom(resultList)
	End Function


	Method GetTitle:string() {_exposeToLua}
		return self.title
	End Method


	Method GetDescription:string() {_exposeToLua}
		return self.description
	End Method


	Method GetBlocks:int() {_exposeToLua}
		return self.blocks
	End Method
End Type




'the useable contract for advertisements used in the playercollections
Type TAdContract extends TNamedGameObject {_exposeToLua="selected"}
	'holds raw contract data
	Field base:TAdContractBase = Null
	'how many spots were successfully sent up to now
	Field spotsSent:Int = 0
	'how many spots were planned up to now
	Field spotsPlanned:Int = 0
	'day the contract has been taken from the advertiser-room
	Field daySigned:Int = -1
	'calculated profit value (on sign)
	Field profit:Int = -1
	'calculated penalty value (on sign)
	Field penalty:Int = -1
	'calculated minimum audience value (on sign)
	Field minAudience:Int = -1
	' KI: Wird nur in der Lua-KI verwendet du die Filme zu bewerten
	Field attractiveness:Float = -1
	'for infomercials / shopping shows
	Field infomercialTopicality:float = 1.0
	Field infomercialMaxTopicality:float= 1.0

	'holding all TAdContracts
	global List:TList = CreateList()


	'create UNSIGNED (adagency)
	Method Create:TAdContract(baseContract:TAdContractBase)
		self.base = baseContract

		List.AddLast(self)
		Return self
	End Method


	'what to earn each hour for each viewer
	'(broadcasted as "infomercial")
	Method GetPerViewerRevenue:Float() {_exposeToLua}
		if not isInfomercialAllowed() then return 0.0

		local result:float = 0.0

		'calculate
		result = CalculatePrices(base.profitBase)
		result :/ GetSpotCount()
		result :* 0.001 'way down for reasonable prices
		'so currently we end up with the price equal to
		'the price of a successful contract / GetSpotCount()

		'less revenue with less topicality
		if infomercialMaxTopicality > 0
			result :* (infomercialTopicality/infomercialMaxTopicality)
		endif
		return result
	End Method


	'overwrite method from base
	Method GetTitle:string() {_exposeToLua}
		Return base.GetTitle()
	End Method


	'overwrite method from base
	Method GetDescription:string() {_exposeToLua}
		Return base.GetDescription()
	End Method


	'overwrite method from base
	Method GetBlocks:int() {_exposeToLua}
		Return base.GetBlocks()
	End Method


	'sign the contract -> calculate values and change owner
	Method Sign:int(owner:int, day:int=-1)
		if self.owner = owner then return FALSE

		'attention: GetProfit/GetPenalty/GetMinAudience default to "owner"
		'           if we set the owner BEFORE, the functions wont use
		'           the "average" of all players -> set owner afterwards
		self.profit	= GetProfit()
		self.penalty = GetPenalty()
		self.minAudience = GetMinAudience()

		self.owner = owner
		If day < 0 Then day = GetGameTime().GetDay()
		self.daySigned = day

		TLogger.log("TAdContract.Sign", "Player "+owner+" signed a contract.  Profit: "+profit+",  Penalty: "+penalty+ ",  MinAudience: "+minAudience+",  Title: "+GetTitle(), LOG_DEBUG)
		'TLogger.log("TAdContract.Sign", "       "+owner+"                     Profit: "+GetProfit()+",  Penalty: "+GetPenalty()+ ",  MinAudience: "+GetMinAudience()+",  Title: "+GetTitle(), LOG_DEBUG)
		return TRUE
	End Method


	Method IsAvailableToSign:Int() {_exposeToLua}
		'maybe add other checks here - even if something
		'is not signed yet, it might not be able to get signed...
		Return (not IsSigned())
	End Method


	Method IsSigned:int() {_exposeToLua}
		return (owner > 0 and daySigned >= 0)
	End Method


	'percents = 0.0 - 1.0 (0-100%)
	Method GetMinAudiencePercentage:Float(dbvalue:Float = -1) {_exposeToLua}
		If dbvalue < 0 Then dbvalue = Self.base.minAudienceBase
		Return Max(0.0, Min(1.0, dbvalue / 100.0)) 'from 75% to 0.75
	End Method


	'the quality is higher for "better paid" advertisements with
	'higher audience requirements... no cheap "car seller" ad :D
	Method GetQuality:Float(luckFactor:Int = 1) {_exposeToLua}
		Local quality:Float = 0.05

		if GetMinAudience() >   1000 then quality :+ 0.01		'+0.06
		if GetMinAudience() >   5000 then quality :+ 0.025		'+0.085
		if GetMinAudience() >  10000 then quality :+ 0.05		'+0.135
		if GetMinAudience() >  50000 then quality :+ 0.075		'+0.21
		if GetMinAudience() > 250000 then quality :+ 0.1		'+0.31
		if GetMinAudience() > 750000 then quality :+ 0.19		'+0.5
		if GetMinAudience() >1500000 then quality :+ 0.25		'+0.75
		if GetMinAudience() >5000000 then quality :+ 0.25		'+1.00

		If luckFactor = 1 Then
			quality = quality * 0.98 + Float(RandRange(10, 20)) / 1000.0 '1%-Punkte bis 2%-Punkte Basis-Qualität
		Else
			quality = quality * 0.99 + 0.01 'Mindestens 1% Qualität
		EndIf

		'no minus quote
		quality = Max(0, quality)
		Return quality
	End Method


	Method isInfomercialAllowed:int() {_exposeToLua}
		return base.infomercialAllowed
	End Method


	'multiplies basevalues of prices, values are from 0 to 255 for 1 spot... per 1000 people in audience
	'if targetgroup is set, the price is doubled
	Method GetProfit:Int(playerID:Int= -1) {_exposeToLua}
		'already calculated and data for owner requested
		If playerID=-1 and profit >= 0 Then Return profit

		'calculate
		Return CalculatePrices(base.profitBase, playerID)
	End Method


	'returns the penalty for this contract
	Method GetPenalty:Int(playerID:Int=-1) {_exposeToLua}
		'already calculated and data for owner requested
		If playerID=-1 and penalty >= 0 Then Return penalty

		'calculate
		Return CalculatePrices(base.penaltyBase, playerID)
	End Method


	'calculate prices (profits, penalties...)
	Method CalculatePrices:Int(baseprice:Int=0, playerID:Int=-1) {_exposeToLua}
		'price is for each spot
		Local price:Float = baseprice * Float( GetSpotCount() )

		'ad is with fixed price - only available without minimum restriction
		If base.hasFixedPrice
			'print self.contractBase.title + " has fixed price : "+ price + " base:"+baseprice + " profitbase:"+self.contractBase.profitBase
			Return price
		endif

		local devConfig:TData = TData(GetRegistry().Get("DEV_CONFIG", new TData.Init()))
		local factor1:float =  devConfig.GetFloat("DEV_AD_FACTOR1", 4.0)
		local minCPM:float = devConfig.GetFloat("DEV_AD_MINIMUM_CPM", 7.5)
		local limitedGenreMultiplier:float = devConfig.GetFloat("DEV_AD_LIMITED_GENRE_MULTIPLIER", 2.0)

		'price :* 4.0 'increase price by 400% - community says, price to low
		price :* factor1

		'dynamic price
		'----
		'price we would get if 100% of audience is watching
		'-> multiply with an "euros per 1000 people watching"
		'price :* Max(7.5, getRawMinAudience(playerID)/1000)
		price :* Max(minCPM, getRawMinAudience(playerID)/1000)

		'specific targetgroups change price
		'If Self.GetTargetGroup() > 0 Then price :*2.0
		If GetTargetGroup() > 0 Then price :* limitedGenreMultiplier

		'return "beautiful" prices
		Return TFunctions.RoundToBeautifulValue(price)
	End Method


	'returns the non rounded minimum audience
	Method GetRawMinAudience:Int(playerID:int=-1) {_exposeToLua}
		'if no special player is requested -
		if playerID <= 0 and IsSigned() then playerID = owner
		'if contract has no owner the avg audience maximum is returned
		local useAudience:int = GetStationMapCollection().GetAverageReach()

		'0.5 = more than 50 percent of whole germany wont watch TV the same time
		'therefor: maximum of half the audience can be "needed"
		Return Floor(useAudience*0.5 * GetMinAudiencePercentage())
	End Method


	'Gets minimum needed audience in absolute numbers
	Method GetMinAudience:Int(playerID:int=-1) {_exposeToLua}
		'already calculated and data for owner requested
		If playerID=-1 and minAudience >=0 Then Return minAudience

		Return TFunctions.RoundToBeautifulValue( GetRawMinAudience(playerID) )
	End Method


	'days left for sending all contracts from today
	Method GetDaysLeft:Int() {_exposeToLua}
		Return ( base.daysToFinish - (GetGameTime().GetDay() - daySigned) )
	End Method


	'get the contract (to access its ID or title by its GetXXX() )
	Method GetBase:TAdContractBase() {_exposeToLua}
		Return base
	End Method


	'returns whether the contract was fulfilled
	Method isSuccessful:int() {_exposeToLua}
		Return (base.spotCount <= spotsSent)
	End Method


	'amount of spots still missing
	Method GetSpotsToSend:int() {_exposeToLua}
		Return (base.spotCount - spotsSent)
	End Method


	Method SetSpotsPlanned:int(value:int)
		spotsPlanned = value
	End Method


	'amount of spots planned (adjusted by programmeplanner)
	Method GetSpotsPlanned:int() {_exposeToLua}
		return spotsPlanned
	End Method


	'amount of spots which have already been successfully broadcasted
	Method GetSpotsSent:int() {_exposeToLua}
		Return spotsSent
	End Method


	'amount of total spots to send
	Method GetSpotCount:Int() {_exposeToLua}
		Return base.spotCount
	End Method


	'total days to send contract from date of sign
	Method GetDaysToFinish:Int() {_exposeToLua}
		Return base.daysToFinish
	End Method


	Method GetTargetGroup:Int() {_exposeToLua}
		Return base.targetGroup
	End Method


	Method GetTargetGroupString:String(group:Int=-1) {_exposeToLua}
		'if no group given, use the one of the object
		if group < 0 then group = self.base.targetGroup

		If group >= 1 And group <=9
			Return GetLocale("AD_GENRE_"+group)
		else
			Return GetLocale("AD_GENRE_NONE")
		EndIf
	End Method


	Method ShowSheet:Int(x:Int,y:Int, align:int=0, showMode:int=0)
		'set default mode
		if showMode = 0 then showMode = TBroadcastMaterial.TYPE_ADVERTISEMENT

		if KeyManager.IsDown(KEY_LALT) or KeyManager.IsDown(KEY_RALT)
			if showMode = TBroadcastMaterial.TYPE_PROGRAMME
				showMode = TBroadcastMaterial.TYPE_ADVERTISEMENT
			else
				showMode = TBroadcastMaterial.TYPE_PROGRAMME
			endif
		Endif

		if showMode = TBroadcastMaterial.TYPE_PROGRAMME
			ShowInfomercialSheet(x, y, align)
		elseif showMode = TBroadcastMaterial.TYPE_ADVERTISEMENT
			ShowAdvertisementSheet(x, y, align)
		endif
	End Method


	Method ShowInfomercialSheet:Int(x:Int,y:Int, align:int=0)
		Local normalFont:TBitmapFont	= GetBitmapFontManager().baseFont

		if align = 1 then x :- GetSpriteFromRegistry("gfx_datasheets_specials").area.GetW()
		GetSpriteFromRegistry("gfx_datasheets_specials").Draw(x,y)
		SetColor 0,0,0
		GetBitmapFontManager().basefontBold.drawBlock(self.GetTitle(), x + 10, y + 11, 278, 20)
		normalFont.drawBlock("Dauerwerbesendung", x + 10, y + 34, 278, 20)

		'convert back cents to euros and round it
		'value is "per 1000" - so multiply with that too
		local profitFormatted:string = int(1000*GetPerViewerRevenue())+" "+CURRENCYSIGN
		normalFont.drawBlock(getLocale("AD_INFOMERCIAL")  , x+10, y+55, 278, 60)
		GetBitmapFontManager().basefontBold.drawBlock(getLocale("AD_INFOMERCIAL_PROFIT").replace("%PROFIT%", profitFormatted), x+10, y+105, 278, 20)
		normalFont.drawBlock(GetLocale("MOVIE_TOPICALITY"), x+222, y+131,  40, 16)
		SetColor 255,255,255

		SetAlpha 0.3
		GetSpriteFromRegistry("gfx_datasheets_bar").DrawClipped(new TPoint.Init(x+13,y+131), new TRectangle.Init(0, 0, 200, 12))
		SetAlpha 1.0
		if infomercialTopicality > 0.1 then GetSpriteFromRegistry("gfx_datasheets_bar").DrawClipped(new TPoint.Init(x+13,y+131), new TRectangle.Init(0, 0, infomercialTopicality*200, 12))
	End Method


	Method ShowAdvertisementSheet:Int(x:Int,y:Int, align:int=0)

		if align=1 then x :- GetSpriteFromRegistry("gfx_datasheets_contract").area.GetW()

		GetSpriteFromRegistry("gfx_datasheets_contract").Draw(x,y)

		SetColor 0,0,0
		Local font:TBitmapFont = GetBitmapFontManager().basefont
		GetBitmapFontManager().basefontBold.drawBlock(GetTitle()	, x+10 , y+11 , 270, 70)
		font.drawBlock(GetDescription()   		 		, x+10 , y+33 , 270, 70)
		font.drawBlock(getLocale("AD_PROFIT")+": "			, x+10 , y+94 , 130, 16)
		font.drawBlock(TFunctions.convertValue(GetProfit(), 2)+" "+CURRENCYSIGN , x+10 , y+94 , 130, 16,new TPoint.Init(ALIGN_RIGHT))
		font.drawBlock(getLocale("AD_PENALTY")+": "       , x+10 , y+117, 130, 16)
		font.drawBlock(TFunctions.convertValue(GetPenalty(), 2)+" "+CURRENCYSIGN, x+10 , y+117, 130, 16,new TPoint.Init(ALIGN_RIGHT))
		font.drawBlock(getLocale("AD_MIN_AUDIENCE")+": "    , x+10, y+140, 127, 16)
		font.drawBlock(TFunctions.convertValue(GetMinAudience(), 2), x+10, y+140, 127, 16,new TPoint.Init(ALIGN_RIGHT))

		font.drawBlock(getLocale("AD_TOSEND")+": "    , x+150, y+94 , 127, 16)
		font.drawBlock(GetSpotsToSend()+"/"+GetSpotCount() , x+150, y+94 , 127, 16,new TPoint.Init(ALIGN_RIGHT))
		font.drawBlock(getLocale("AD_PLANNED")+": "    , x+150, y+117 , 127, 16)
		if self.owner > 0
			font.drawBlock( GetSpotsPlanned() + "/" + GetSpotCount() , x+150, y+117 , 127, 16,new TPoint.Init(ALIGN_RIGHT))
		else
			font.drawBlock( "-" , x+150, y+117 , 127, 16,new TPoint.Init(ALIGN_RIGHT))
		endif

		font.drawBlock(getLocale("AD_TARGETGROUP")+": "+GetTargetgroupString()   , x+10 , y+163 , 270, 16)
		If owner <= 0
			If GetDaysToFinish() > 1
				font.drawBlock(getLocale("AD_TIME")+": "+GetDaysToFinish() +" "+ getLocale("DAYS"), x+86 , y+186 , 122, 16)
			Else
				font.drawBlock(getLocale("AD_TIME")+": "+GetDaysToFinish() +" "+ getLocale("DAY"), x+86 , y+186 , 122, 16)
			EndIf
		Else
			if GetDaysLeft() < 0
				font.drawBlock(getLocale("AD_TIME")+": "+getLocale("AD_TILL_TOLATE") , x+86 , y+186 , 126, 16)
			else
				Select GetDaysLeft()
					Case 0	font.drawBlock(getLocale("AD_TIME")+": "+getLocale("AD_TILL_TODAY") , x+86 , y+186 , 126, 16)
					Case 1	font.drawBlock(getLocale("AD_TIME")+": "+getLocale("AD_TILL_TOMORROW") , x+86 , y+186 , 126, 16)
					Default	font.drawBlock(getLocale("AD_TIME")+": "+Replace(getLocale("AD_STILL_X_DAYS"),"%1", Self.GetDaysLeft()), x+86 , y+186 , 122, 16)
				EndSelect
			endif
		EndIf
		SetColor 255,255,255
	End Method


	Function Get:TAdContract(id:Int)
		For Local contract:TAdContract = EachIn List
			If contract.id = id Then Return contract
		Next
		Return Null
	End Function


	'===== AI-LUA HELPER FUNCTIONS =====

	'Wird bisher nur in der LUA-KI verwendet
	Method GetAttractiveness:Float() {_exposeToLua}
		Return Self.attractiveness
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	Method SetAttractiveness(value:Float) {_exposeToLua}
		Self.attractiveness = value
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Wie hoch ist das finanzielle Gewicht pro Spot?
	'Wird dafür gebraucht um die Wichtigkeit des Spots zu bewerten
	Method GetFinanceWeight:float() {_exposeToLua}
		Return (self.GetProfit() + self.GetPenalty()) / self.GetSpotCount()
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Berechnet wie Zeitkritisch die Erfüllung des Vertrages ist (Gesamt)
	Method GetPressure:float() {_exposeToLua}
		local _daysToFinish:int = self.GetDaysToFinish() + 1 'In diesem Zusammenhang nicht 0-basierend
		Return self.GetSpotCount() / _daysToFinish * _daysToFinish
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Berechnet wie Zeitkritisch die Erfüllung des Vertrages ist (tatsächlich / aktuell)
	Method GetCurrentPressure:float() {_exposeToLua}
		local _daysToFinish:int = self.GetDaysToFinish() + 1 'In diesem Zusammenhang nicht 0-basierend
		Return self.GetSpotsToSend() / _daysToFinish * _daysToFinish
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Wie dringend ist es diese Spots zu senden
	Method GetAcuteness:float() {_exposeToLua}
		Local spotsToBroadcast:int = self.GetSpotCount() - self.GetSpotsToSend()
		Local daysLeft:int = self.getDaysLeft() + 1 'In diesem Zusammenhang nicht 0-basierend
		If daysLeft <= 0 then return 0 'no "acuteness" for obsolete contracts
		Return spotsToBroadcast  / daysLeft * daysLeft  * 100
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Wie viele Spots sollten heute mindestens gesendet werden
	Method SendMinimalBlocksToday:int() {_exposeToLua}
		Local spotsToBroadcast:int = self.GetSpotCount() - self.GetSpotsToSend()
		Local acuteness:int = self.GetAcuteness()
		Local daysLeft:int = self.getDaysLeft() + 1 'In diesem Zusammenhang nicht 0-basierend
		If daysLeft <= 0 then return 0 'no "blocks" for obsolete contracts

		If (acuteness >= 100)
			Return int(spotsToBroadcast / daysLeft) 'int rundet
		Elseif (acuteness >= 70)
			Return 1
		Else
			Return 0
		Endif
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Wie viele Spots sollten heute optimalerweise gesendet werden
	Method SendOptimalBlocksToday:int() {_exposeToLua}
		Local spotsToBroadcast:int = self.GetSpotCount() - self.GetSpotsToSend()
		Local daysLeft:int = self.getDaysLeft() + 1 'In diesem Zusammenhang nicht 0-basierend
		If daysLeft <= 0 then return 0 'no "blocks" for obsolete contracts

		Local acuteness:int = self.GetAcuteness()
		Local optimumCount:int = Int(spotsToBroadcast / daysLeft) 'int rundet

		If (acuteness >= 100) and (spotsToBroadcast > optimumCount)
			optimumCount = optimumCount + 1
		Endif

		If (acuteness >= 100)
			return Int(spotsToBroadcast / daysLeft)  'int rundet
		Endif
	End Method
	'===== END AI-LUA HELPER FUNCTIONS =====
End Type
