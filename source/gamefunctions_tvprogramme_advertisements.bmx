REM
	===========================================================
	code for advertisement-objects in programme planning
	===========================================================

	As we have to know broadcast states (eg. "this spot failed/run OK"),
	we have to create individual "TAdvertisement"/spots.
	This way these objects can store that states.

	Another benefit is: TAdvertisement is "TBroadcastMaterial" which would
	make it exchangeable with other material... This could be eg. used
	to make them placeable as "programme" - which creates shoppingprogramme
	or other things. (while programme as advertisement could generate Trailers)

	The normal contract data is splitted into "contractBase" and "contract".
	So the resulting contract can differ to the raw database contract
	(eg. discounts, special prices...). Also you can have the same contract
	data with different ids ... so multiple incarnations of a contract are
	possible.
ENDREM


'===== ADVERTISEMENT-CONTRACTS =====


'contracts bases for advertisement - straight from the DB
'they just contain data to base new contracts of
Type TAdContractBase Extends TGameObject {_exposeToLua}
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
Type TAdContract extends TGameObject {_exposeToLua="selected"}
	Field base:TAdContractBase			= Null					' holds raw contract data
	Field spotsSent:Int					= 0						' how many spots were succesfully sent up to now
	Field owner:Int						= 0
	Field daySigned:Int					= -1					' day the contract has been taken from the advertiser-room
	Field profit:Int					= -1					' calculated profit value (on sign)
	Field penalty:Int					= -1					' calculated penalty value (on sign)
	Field minAudience:Int		 		= -1					' calculated minimum audience value (on sign)
	Field attractiveness:Float			= -1					' KI: Wird nur in der Lua-KI verwendet du die Filme zu bewerten
	'for infomercials / shopping shows
	Field infomercialTopicality:float	= 1.0
	Field infomercialMaxTopicality:float= 1.0

	global List:TList					= CreateList()			' holding all Tcontracts


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
		If day < 0 Then day = game.GetDay()
		self.daySigned = day

		TDevHelper.log("TAdContract.Sign", "Player "+owner+" signed a contract.  Profit: "+profit+",  Penalty: "+penalty+ ",  MinAudience: "+minAudience+",  Title: "+GetTitle(), LOG_DEBUG)
		'TDevHelper.log("TAdContract.Sign", "       "+owner+"                     Profit: "+GetProfit()+",  Penalty: "+GetPenalty()+ ",  MinAudience: "+GetMinAudience()+",  Title: "+GetTitle(), LOG_DEBUG)
		return TRUE
	End Method


	Function GetRandomFromList:TAdvertisement(_list:TList, playerID:Int =-1)
		If _list = Null Then Return Null
		If _list.count() > 0
			Local obj:TAdvertisement = TAdvertisement(_list.ValueAtIndex((randRange(0, _list.Count() - 1))))
			If obj <> Null
				obj.owner = playerID
				Return obj
			EndIf
		EndIf
		Print "TAdvertisement list empty - wrong filter ?"
		Return Null
	End Function


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
			quality = quality * 0.98 + Float(RandRange(10, 20)) / 1000.0 '1%-Punkte bis 2%-Punkte Basis-QualitÃ¤t
		Else
			quality = quality * 0.99 + 0.01 'Mindestens 1% QualitÃ¤t
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

		local devConfig:TData = Assets.GetData("DEV_CONFIG", new TData.Init())
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
		local useAudience:int = Game.GetMaxAudience(playerID)

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
		Return ( base.daysToFinish - (Game.GetDay() - daySigned) )
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


	'amount of spots planned in programmeplanner
	Method GetSpotsPlanned:int() {_exposeToLua}
		return Game.getPlayer(owner).ProgrammePlan.GetAdvertisementsPlanned(self)
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
		Local normalFont:TGW_BitmapFont	= Assets.fonts.baseFont

		if align = 1 then x :- Assets.GetSprite("gfx_datasheets_specials").area.GetW()
		Assets.GetSprite("gfx_datasheets_specials").Draw(x,y)
		SetColor 0,0,0
		Assets.fonts.basefontBold.drawBlock(self.GetTitle(), x + 10, y + 11, 278, 20)
		normalFont.drawBlock("Dauerwerbesendung", x + 10, y + 34, 278, 20)

		'convert back cents to euros and round it
		'value is "per 1000" - so multiply with that too
		local profitFormatted:string = int(1000*GetPerViewerRevenue())+" "+CURRENCYSIGN
		normalFont.drawBlock(getLocale("AD_INFOMERCIAL")  , x+10, y+55, 278, 60)
		Assets.fonts.basefontBold.drawBlock(getLocale("AD_INFOMERCIAL_PROFIT").replace("%PROFIT%", profitFormatted), x+10, y+105, 278, 20)
		normalFont.drawBlock(GetLocale("MOVIE_TOPICALITY"), x+222, y+131,  40, 16)
		SetColor 255,255,255

		SetAlpha 0.3
		Assets.GetSprite("gfx_datasheets_bar").DrawClipped(TPoint.Create(x+13,y+131), TRectangle.Create(0, 0, 200, 12))
		SetAlpha 1.0
		if infomercialTopicality > 0.1 then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(TPoint.Create(x+13,y+131), TRectangle.Create(0, 0, infomercialTopicality*200, 12))
	End Method


	Method ShowAdvertisementSheet:Int(x:Int,y:Int, align:int=0)

		if align=1 then x :- Assets.GetSprite("gfx_datasheets_contract").area.GetW()

		Local playerID:Int = owner
		'nobody owns it or unsigned contract
		If playerID <= 0 or self.daySigned < 0 Then playerID = Game.playerID

		Assets.GetSprite("gfx_datasheets_contract").Draw(x,y)

		SetColor 0,0,0
		Local font:TGW_BitmapFont = Assets.fonts.basefont
		Assets.fonts.basefontBold.drawBlock(GetTitle()	, x+10 , y+11 , 270, 70)
		font.drawBlock(GetDescription()   		 		, x+10 , y+33 , 270, 70)
		font.drawBlock(getLocale("AD_PROFIT")+": "			, x+10 , y+94 , 130, 16)
		font.drawBlock(TFunctions.convertValue(GetProfit(), 2)+" "+CURRENCYSIGN , x+10 , y+94 , 130, 16,TPoint.Create(ALIGN_RIGHT))
		font.drawBlock(getLocale("AD_PENALTY")+": "       , x+10 , y+117, 130, 16)
		font.drawBlock(TFunctions.convertValue(GetPenalty(), 2)+" "+CURRENCYSIGN, x+10 , y+117, 130, 16,TPoint.Create(ALIGN_RIGHT))
		font.drawBlock(getLocale("AD_MIN_AUDIENCE")+": "    , x+10, y+140, 127, 16)
		font.drawBlock(TFunctions.convertValue(GetMinAudience(), 2), x+10, y+140, 127, 16,TPoint.Create(ALIGN_RIGHT))

		font.drawBlock(getLocale("AD_TOSEND")+": "    , x+150, y+94 , 127, 16)
		font.drawBlock(GetSpotsToSend()+"/"+GetSpotCount() , x+150, y+94 , 127, 16,TPoint.Create(ALIGN_RIGHT))
		font.drawBlock(getLocale("AD_PLANNED")+": "    , x+150, y+117 , 127, 16)
		if self.owner > 0
			font.drawBlock( GetSpotsPlanned() + "/" + GetSpotCount() , x+150, y+117 , 127, 16,TPoint.Create(ALIGN_RIGHT))
		else
			font.drawBlock( "-" , x+150, y+117 , 127, 16,TPoint.Create(ALIGN_RIGHT))
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
	'Wird dafÃ¼r gebraucht um die Wichtigkeit des Spots zu bewerten
	Method GetFinanceWeight:float() {_exposeToLua}
		Return (self.GetProfit() + self.GetPenalty()) / self.GetSpotCount()
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Berechnet wie Zeitkritisch die ErfÃ¼llung des Vertrages ist (Gesamt)
	Method GetPressure:float() {_exposeToLua}
		local _daysToFinish:int = self.GetDaysToFinish() + 1 'In diesem Zusammenhang nicht 0-basierend
		Return self.GetSpotCount() / _daysToFinish * _daysToFinish
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Berechnet wie Zeitkritisch die ErfÃ¼llung des Vertrages ist (tatsÃ¤chlich / aktuell)
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




'a graphical representation of contracts at the ad-agency ...
Type TGuiAdContract extends TGUIGameListItem
	Field contract:TAdContract


    Method Create:TGuiAdContract(label:string="",x:float=0.0,y:float=0.0,width:int=120,height:int=20)
		Super.Create(label,x,y,width,height)

		self.assetNameDefault = "gfx_contracts_0"
		self.assetNameDragged = "gfx_contracts_0_dragged"

		return self
	End Method


	Method CreateWithContract:TGuiAdContract(contract:TAdContract)
		self.Create()
		self.setContract(contract)
		return self
	End Method


	Method SetContract:TGuiAdContract(contract:TAdContract)
		self.contract		= contract
		'targetgroup is between 0-9
		self.InitAssets(GetAssetName(contract.GetTargetGroup(), FALSE), GetAssetName(contract.GetTargetGroup(), TRUE))

		return self
	End Method


	Method GetAssetName:string(targetGroup:int=-1, dragged:int=FALSE)
		if targetGroup < 0 and contract then targetGroup = contract.GetTargetGroup()
		local result:string = "gfx_contracts_" + Min(9,Max(0, targetGroup))
		if dragged then result = result + "_dragged"
		return result
	End Method


	'override default update-method
	Method Update:int()
		super.Update()

		'set mouse to "hover"
		if contract.owner = Game.playerID or contract.owner <= 0 and mouseover then Game.cursorstate = 1
		'set mouse to "dragged"
		if isDragged() then Game.cursorstate = 2
	End Method


	Method DrawSheet(leftX:int=30, rightX:int=30)
		local sheetY:float 	= 20
		local sheetX:float 	= leftX
		local sheetAlign:int= 0
		'if mouse on left side of screen - align sheet on right side
		'METHOD 1
		'instead of using the half screen width, we use another
		'value to remove "flipping" when hovering over the desk-list
		'if MouseManager.x < RoomHandler_AdAgency.suitcasePos.GetX()
		'METHOD 2
		'just use the half of a screen - ensures the data sheet does not overlap
		'the object
		if MouseManager.x < App.settings.GetWidth()/2
			sheetX = App.settings.GetWidth() - rightX
			sheetAlign = 1
		endif

		SetColor 0,0,0
		SetAlpha 0.2
		Local x:Float = self.GetScreenX()
		Local tri:Float[]=[sheetX+20,sheetY+25,sheetX+20,sheetY+90,self.GetScreenX()+self.GetScreenWidth()/2.0+3,self.GetScreenY()+self.GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		self.contract.ShowSheet(sheetX,sheetY, sheetAlign, TBroadcastMaterial.TYPE_ADVERTISEMENT)
	End Method


	Method DrawGhost()
		'by default a shaded version of the gui element is drawn at the original position
		self.SetOption(GUI_OBJECT_IGNORE_POSITIONMODIFIERS, TRUE)
		SetAlpha 0.5

		local backupAssetName:string = self.asset.getName()
		self.asset = Assets.GetSprite(assetNameDefault)
		self.Draw()
		self.asset = Assets.GetSprite(backupAssetName)

		SetAlpha 1.0
		self.SetOption(GUI_OBJECT_IGNORE_POSITIONMODIFIERS, FALSE)
	End Method


	Method Draw()
		SetColor 255,255,255
		local oldAlpha:float = GetAlpha()

		'make faded as soon as not "dragable" for us
		if contract.owner <> Game.playerID and contract.owner>0 then SetAlpha 0.75*oldAlpha
		if not isDragable() then SetColor 200,200,200
		Super.Draw()
		SetAlpha oldalpha
		SetColor 255,255,255
	End Method
End Type




Type TGUIAdContractSlotList extends TGUISlotList

    Method Create:TGUIAdContractSlotList(x:Int, y:Int, width:Int, height:Int = 50, State:String = "")
		Super.Create(x,y,width,height,state)
		return self
	End Method

	Method ContainsContract:int(contract:TAdContract)
		for local i:int = 0 to self.GetSlotAmount()-1
			local block:TGuiAdContract = TGuiAdContract( self.GetItemBySlot(i) )
			if block and block.contract = contract then return TRUE
		Next
		return FALSE
	End Method

	'override to add sort
	Method AddItem:int(item:TGUIobject, extra:object=null)
		if super.AddItem(item, extra)
			GUIManager.sortLists()
			return TRUE
		endif
		return FALSE
	End Method

	'override default event handler
	Function onDropOnTarget:int( triggerEvent:TEventBase )
		local item:TGUIListItem = TGUIListItem(triggerEvent.GetSender())
		if item = Null then return FALSE

		'ATTENTION:
		'Item is still in dragged state!
		'Keep this in mind when sorting the items

		'only handle if coming from another list ?
		local parent:TGUIobject = item._parent
		if TGUIPanel(parent) then parent = TGUIPanel(parent)._parent
		local fromList:TGUIListBase = TGUIListBase(parent)
		if not fromList then return FALSE

		local toList:TGUIListBase = TGUIListBase(triggerEvent.GetReceiver())
		if not toList then return FALSE

		local data:TData = triggerEvent.getData()
		if not data then return FALSE

		'move item if possible
		fromList.removeItem(item)
		'try to add the item, if not able, readd
		if not toList.addItem(item, data)
			if fromList.addItem(item) then return TRUE

			'not able to add to "toList" but also not to "fromList"
			'so set veto and keep the item dragged
			triggerEvent.setVeto()
		endif


		return TRUE
	End Function
End Type




'===== ADVERTISEMENTS =====


'ad spot
Type TAdvertisement Extends TBroadcastMaterial {_exposeToLua="selected"}
	Field contract:TAdContract	= Null
	'Eventuell den "state" hier als reine visuelle Hilfe nehmen.
	'Dinge wie "Spot X von Y" koennen auch dynamisch erfragt werden
	'
	'Auch sollte ein AdContract einen Event aussenden, wenn erfolgreich
	'gesendet worden ist ... dann koennen die "GUI"-Bloecke darauf reagieren
	'und ihre Werte aktualisieren

	Global List:TList			= CreateList()


	Method Create:TAdvertisement(contract:TAdContract)
		self.contract = contract

		self.setMaterialType(TYPE_ADVERTISEMENT)
		'by default a freshly created programme is of its own type
		self.setUsedAsType(TYPE_ADVERTISEMENT)

		self.owner = self.contract.owner

		List.AddLast(self)
		Return self
	End Method


	'override default getter to make contract id the reference id
	Method GetReferenceID:int() {_exposeToLua}
		return self.contract.id
	End Method


	'override default getter
	Method GetDescription:string() {_exposeToLua}
		Return contract.GetDescription()
	End Method


	'get the title
	Method GetTitle:string() {_exposeToLua}
		Return contract.GetTitle()
	End Method


	Method GetBlocks:int(broadcastType:int=0) {_exposeToLua}
		Return contract.GetBlocks()
	End Method


	'returns which number that spot will have
	Method GetSpotNumber:Int() {_exposeToLua}
		'if programmed - we count all non-failed ads up to the programmed date
		if self.isProgrammed()
			return 1 + Game.getPlayer(owner).ProgrammePlan.GetAdvertisementsCount(self.contract, self.programmedDay, self.programmedHour-1, TRUE, TRUE)
		'if not programmed we just count ALL existing non-failed ads
		else
			return 1 + Game.getPlayer(owner).ProgrammePlan.GetAdvertisementsCount(self.contract, -1, -1, TRUE, TRUE)
		endif
	End Method


	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction )
		'TODO: @Manuel - hier brauchen wir eine geeignete Berechnung :D
		If lastMovieBlockAttraction then return lastMovieBlockAttraction

		Local result:TAudienceAttraction = New TAudienceAttraction
		result.BroadcastType = 1
		result.Genre = 20 'paid programming
		Local genreDefintion:TMovieGenreDefinition = Game.BroadcastManager.GetMovieGenreDefinition(result.Genre)

		'copied and adjusted from "programme"
		If block = 1 Then
			'1 - Qualität des Programms
			result.Quality = GetQuality()

			'2 - Mod: Genre-Popularität / Trend
			result.GenrePopularityMod = (genreDefintion.Popularity.Popularity / 100) 'Popularity => Wert zwischen -50 und +50

			'3 - Genre <> Zielgruppe
			result.GenreTargetGroupMod = genreDefintion.AudienceAttraction.Copy()
			result.GenreTargetGroupMod.SubtractFloat(0.5)

			'4 - Image
			result.PublicImageMod = Game.getPlayer(owner).PublicImage.GetAttractionMods()
			result.PublicImageMod.SubtractFloat(1)

			'5 - Trailer - gibt es nicht fuer Werbesendungen (die
			'              waeren ja dann wieder Werbung)

			'6 - Flags
			result.FlagsMod = TAudience.CreateAndInit(1, 1, 1, 1, 1, 1, 1, 1, 1)
			result.FlagsMod.SubtractFloat(1)

			result.CalculateBaseAttraction()
		Else
			result.CopyBaseAttractionFrom(lastMovieBlockAttraction)
		Endif

		'8 - Stetige Auswirkungen der Film-Quali. Gute Filme bekommen mehr Attraktivität, schlechte Filme animieren eher zum Umschalten
		result.QualityOverTimeEffectMod = ((result.Quality - 0.5)/2.5) * (block - 1)

		'9 - Genres <> Sendezeit
		result.GenreTimeMod = genreDefintion.TimeMods[hour] - 1 'Genre/Zeit-Mod

		'10 - News-Mod
		result.NewsShowBonus = lastNewsBlockAttraction.Copy().MultiplyFloat(0.2)

		result.CalculateBlockAttraction()

		result.SequenceEffect = genreDefintion.GetSequence(lastNewsBlockAttraction, result, 0.1, 0.5)

		result.CalculateFinalAttraction()

		result.CalculatePublicImageAttraction()

		Return result
	End Method


	'override
	Method FinishBroadcasting:int(day:int, hour:int, minute:int)
		Super.FinishBroadcasting(day,hour,minute)

		If not Game.GetPlayer(self.owner) then return FALSE

		if self.usedAsType = TBroadcastMaterial.TYPE_PROGRAMME
			self.FinishBroadcastingAsProgramme(day, hour, minute)
		elseif self.usedAsType = TBroadcastMaterial.TYPE_ADVERTISEMENT
			'nothing happening - ads get paid on "beginBroadcasting"
		endif

		return TRUE
	End Method


	'ad got send as infomercial
	Method FinishBroadcastingAsProgramme:int(day:int, hour:int, minute:int)
		local player:TPlayer = Game.getPlayer(owner)
		if not player then return FALSE

		self.SetState(self.STATE_OK)
		'give money
		local earn:int = player.GetAudience() * contract.GetPerViewerRevenue()
		TDevHelper.Log("TAdvertisement.FinishBroadcastingAsProgramme", "Infomercial sent, earned "+earn+CURRENCYSIGN+" with an audience of "+player.GetAudience(), LOG_DEBUG)
		player.GetFinance().EarnAdProfit(earn, contract)
	End Method


	Method BeginBroadcasting:int(day:int, hour:int, minute:int)
		local player:TPlayer = Game.getPlayer(owner)
		if not player then return FALSE

		Super.BeginBroadcasting(day,hour,minute)
		'run as infomercial
		if self.usedAsType = TBroadcastMaterial.TYPE_PROGRAMME
			'no need to do further checks
			return TRUE
		endif

		'ad failed (audience lower than needed)
		If player.audience.Audience.GetSum() < contract.GetMinAudience()
			setState(STATE_FAILED)
			'TDevHelper.Log("TAdvertisement.BeginBroadcasting", "Player "+contract.owner+" sent FAILED spot "+contract.spotsSent+"/"+contract.GetSpotCount()+". Title: "+contract.GetTitle()+". Time: day "+(day-Game.GetStartDay())+", "+hour+":"+minute+".", LOG_DEBUG)
		'ad is ok
		Else
			setState(STATE_OK)
			'successful sent - so increase the value the contract
			contract.spotsSent:+1
			'TDevHelper.Log("TAdvertisement.BeginBroadcasting", "Player "+contract.owner+" sent SUCCESSFUL spot "+contract.spotsSent+"/"+contract.GetSpotCount()+". Title: "+contract.GetTitle()+". Time: day "+(day-Game.GetStartDay())+", "+hour+":"+minute+".", LOG_DEBUG)

			'successful sent all needed spots?
			If contract.isSuccessful()
				TDevHelper.Log("TAdvertisement.BeginBroadcasting", "Player "+contract.owner+" finished ad contract, earned "+contract.GetProfit()+CURRENCYSIGN+" with an audience of "+player.GetAudience(), LOG_DEBUG)
				'give money
				player.GetFinance().EarnAdProfit(contract.GetProfit(), contract)

				'removes ads which are more than needed (eg 3 of 2 to be shown ads)
				player.ProgrammePlan.RemoveAdvertisementInstances(self, FALSE)
				'removes them also from programmes (shopping show)
				player.ProgrammePlan.RemoveProgrammeInstances(self, FALSE)

				'remove contract from collection (and suitcase)
				'contract is still stored within advertisements (until they get deleted)
				player.ProgrammeCollection.RemoveAdContract(contract)
			EndIf
		EndIf
		return TRUE
	End Method


	Method GetQuality:Float() {_exposeToLua}
		return contract.GetQuality()
	End Method


	Method ShowSheet:int(x:int,y:int,align:int)
		self.contract.ShowSheet(x, y, align, self.usedAsType)
	End Method
End Type
