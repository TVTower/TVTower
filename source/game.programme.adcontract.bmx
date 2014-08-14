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
Import "game.world.worldtime.bmx"
'to fetch maximum audience
Import "game.stationmap.bmx"
Import "game.broadcastmaterial.base.bmx"



Type TAdContractBaseCollection
	Field list:TList = CreateList()
	Global _instance:TAdContractBaseCollection


	Function GetInstance:TAdContractBaseCollection()
		if not _instance then _instance = new TAdContractBaseCollection
		return _instance
	End Function


	Method Get:TAdContractBase(id:Int)
		For Local base:TAdContractBase = EachIn list
			If base.id = id Then Return base
		Next
		Return Null
	End Method


	Method GetRandom:TAdContractBase(_list:TList = null)
		if _list = Null then _list = List
		If _list = Null Then Return Null
		If _list.count() > 0
			Local obj:TAdContractBase = TAdContractBase(_list.ValueAtIndex((randRange(0, _list.Count() - 1))))
			if obj then return obj
		endif
		return Null
	End Method


	Method GetRandomWithLimitedAudienceQuote:TAdContractBase(minAudienceQuote:float=0.0, maxAudienceQuote:Float=0.35)
		'maxAudienceQuote - xx% market share as maximum
		'filter to entries we need
		Local resultList:TList = CreateList()
		For local obj:TAdContractBase = EachIn list
			If obj.minAudienceBase >= minAudienceQuote AND obj.minAudienceBase <= maxAudienceQuote
				resultList.addLast(obj)
			EndIf
		Next
		Return GetRandom(resultList)
	End Method


	Method Remove:int(obj:TAdContractBase)
		return list.Remove(obj)
	End Method


	Method Add:int(obj:TAdContractBase)
		list.AddLast(obj)
		return TRUE
	End Method


	Method RefreshInfomercialTopicalities:int() {_private}
		For Local base:TAdContractBase = eachin list
			base.RefreshInfomercialTopicality()
		Next
	End Method
End Type
	
'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetAdContractBaseCollection:TAdContractBaseCollection()
	Return TAdContractBaseCollection.GetInstance()
End Function




Type TAdContractCollection
	Field list:TList = CreateList()
	Global _instance:TAdContractCollection


	Function GetInstance:TAdContractCollection()
		if not _instance then _instance = new TAdContractCollection
		return _instance
	End Function


	Method Get:TAdContract(id:Int)
		For Local contract:TAdContract = EachIn list
			If contract.id = id Then Return contract
		Next
		Return Null
	End Method


	Method Remove:int(obj:TAdContract)
		return list.Remove(obj)
	End Method


	Method Add:int(obj:TAdContract)
		list.AddLast(obj)
		return TRUE
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetAdContractCollection:TAdContractCollection()
	Return TAdContractCollection.GetInstance()
End Function





'contracts bases for advertisement - straight from the DB
'they just contain data to base new contracts of
Type TAdContractBase extends TGameObject {_exposeToLua}
	Field title:string = ""
	Field description:string = ""
	'days to fullfill a (signed) contract
	Field daysToFinish:Int
	'spots to send
	Field spotCount:Int
	'block length
	Field blocks:int = 1
	'target group of the spot
	Field targetGroup:Int
	'minimum audience (real value calculated on sign)
	Field minAudienceBase:Float
	'minimum image base value (real value calculated on sign)
	Field minImageBase:Float
	'flag wether price is fixed
	Field hasFixedPrice:Int
	'base of profit (real value calculated on sign)
	Field profitBase:Float
	'base of penalty (real value calculated on sign)
	Field penaltyBase:Float
	'=== infomercials / shopping shows ===
	'is the broadcast of an infomercial allowed?
	Field infomercialAllowed:int = TRUE
	'topicality for this contract base (all adcontracts of this base
	'share this topicality !)
	Field infomercialTopicality:float = 1.0
	Field infomercialMaxTopicality:float = 1.0

	Const TARGETGROUP_CHILDREN:Int = 1
	Const TARGETGROUP_TEENAGER:Int = 2
	Const TARGETGROUP_HOUSEWIFES:Int = 3
	Const TARGETGROUP_EMPLOYEES:Int = 4
	Const TARGETGROUP_UNEMPLOYED:Int = 5
	Const TARGETGROUP_MANAGER:Int = 6
	Const TARGETGROUP_PENSIONERS:Int = 7
	Const TARGETGROUP_WOMEN:Int = 8
	Const TARGETGROUP_MEN:Int = 9


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

		GetAdContractBaseCollection().Add(self)

		Return self
	End Method



	Method GetTitle:string() {_exposeToLua}
		return self.title
	End Method


	Method GetDescription:string() {_exposeToLua}
		return self.description
	End Method


	Method GetBlocks:int() {_exposeToLua}
		return self.blocks
	End Method


	Method GetInfomercialTopicality:Float() {_exposeToLua}
		return infomercialTopicality
	End Method


	Method GetMaxInfomercialTopicality:Float() {_exposeToLua}
		return infomercialMaxTopicality
	End Method


	Method CutInfomercialTopicality:Int(cutFactor:float=1.0) {_private}
		infomercialTopicality :* cutFactor
		'limit to 0-max
		infomercialTopicality = Max(0, Min(infomercialTopicality, GetMaxInfomercialTopicality()))
	End Method


	Method RefreshInfomercialTopicality:Int() {_private}
		'each day topicality refreshes by 15%
		infomercialTopicality :* 1.15
		'limit to 0-max
		infomercialTopicality = Max(0, Min(infomercialTopicality, GetMaxInfomercialTopicality()))
		Return infomercialTopicality
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


	'create UNSIGNED (adagency)
	Method Create:TAdContract(baseContract:TAdContractBase)
		self.base = baseContract

		GetAdContractCollection().Add(self)
		Return self
	End Method


	'what to earn each hour for each viewer
	'(broadcasted as "infomercial")
	Method GetPerViewerRevenue:Float() {_exposeToLua}
		if not isInfomercialAllowed() then return 0.0

		local result:float = 0.0

		'calculate
		result = profit / GetSpotCount()
		result :* 0.001 'way down for reasonable prices
		'so currently we end up with the price equal to
		'the price of a successful contract / GetSpotCount()

		'now cut this to 20%
		result :* 0.2

		'less revenue with less topicality
		if base.GetMaxInfomercialTopicality() > 0
			result :* (base.infomercialTopicality / base.GetMaxInfomercialTopicality())
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
		If day < 0 Then day = GetWorldTime().GetDay()
		self.daySigned = day

		'TLogger.log("TAdContract.Sign", "Player "+owner+" signed a contract.  Profit: "+profit+",  Penalty: "+penalty+ ",  MinAudience: "+minAudience+",  Title: "+GetTitle(), LOG_DEBUG)
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
		Return ( base.daysToFinish - (GetWorldTime().GetDay() - daySigned) )
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
		'=== DRAW BACKGROUND ===
		local sprite:TSprite
		local currX:Int = x
		local currY:int = y

		'move sheet to left when right-aligned
		if align = 1 then currX = x - GetSpriteFromRegistry("gfx_datasheet_title").area.GetW()
		
		sprite = GetSpriteFromRegistry("gfx_datasheet_title"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_series"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_content"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subTop"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		if owner > 0
			sprite = GetSpriteFromRegistry("gfx_datasheet_subMessageEarn"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()
		endif
		sprite = GetSpriteFromRegistry("gfx_datasheet_subTopicalityRating"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_bottom"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()



		'=== DRAW TEXTS / OVERLAYS ====
		currY = y + 8 'so position is within "border"
		currX :+ 7 'inside
		local textColor:TColor = TColor.CreateGrey(25)
		local textLightColor:TColor = TColor.CreateGrey(75)
		local textEarnColor:TColor = TColor.Create(45,80,10)
		Local fontNormal:TBitmapFont = GetBitmapFontManager().baseFont
		Local fontBold:TBitmapFont = GetBitmapFontManager().baseFontBold
		Local fontSemiBold:TBitmapFont = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)

		GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), currX + 6, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 18
		fontNormal.drawBlock(GetLocale("INFOMERCIAL"), currX + 6, currY, 280, 15, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 16

		'content description
		currY :+ 3	'description starts with offset
		fontNormal.drawBlock(getLocale("AD_INFOMERCIAL"), currX + 6, currY, 280, 64, null ,textColor)
		currY :+ 64 'content
		currY :+ 3	'description ends with offset

		currY :+ 4 'offset of subContent

		if owner > 0
			'convert back cents to euros and round it
			'value is "per 1000" - so multiply with that too
			local revenue:string = TFunctions.DottedValue(int(1000 * GetPerViewerRevenue()))+CURRENCYSIGN
			currY :+ 4 'top content padding of that line
			fontSemiBold.drawBlock(getLocale("MOVIE_CALLINSHOW").replace("%PROFIT%", revenue), currX + 35,  currY, 245, 15, ALIGN_CENTER_CENTER, textEarnColor, 0,1,1.0,True, True)
			currY :+ 15 + 8 'lineheight + bottom content padding
		endif
		
		'topicality
		fontSemiBold.drawBlock(GetLocale("MOVIE_TOPICALITY"), currX + 215, currY, 75, 15, null, textLightColor)

		if base.GetInfomercialTopicality() > 0.1
			SetAlpha GetAlpha()*0.25
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1, 200, 10))
			SetAlpha GetAlpha()*4.0
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1, base.GetInfomercialTopicality()*200, 10))
		endif
	End Method


	Method ShowAdvertisementSheet:Int(x:Int,y:Int, align:int=0)
		'=== DRAW BACKGROUND ===
		local sprite:TSprite
		local currX:Int = x
		local currY:int = y
		local daysLeft:int = GetDaysLeft()
		'not signed?
		if owner <= 0 then daysLeft = GetDaysToFinish()

		'move sheet to left when right-aligned
		if align = 1 then currX = x - GetSpriteFromRegistry("gfx_datasheet_title").area.GetW()
		
		sprite = GetSpriteFromRegistry("gfx_datasheet_title"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_content"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subTop"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()

		'warn if special target group
		If base.targetGroup > 0
			sprite = GetSpriteFromRegistry("gfx_datasheet_subMessageTargetGroup"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()
		EndIf

		'warn if short of time
		If daysLeft <= 1
			sprite = GetSpriteFromRegistry("gfx_datasheet_subMessageWarning"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()
		EndIf

		sprite = GetSpriteFromRegistry("gfx_datasheet_subAdContractAttributes"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_bottom"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()



		'=== DRAW TEXTS / OVERLAYS ====
		currY = y + 8 'so position is within "border"
		currX :+ 7 'inside
		local textColor:TColor = TColor.CreateGrey(25)
		local textProfitColor:TColor = TColor.Create(45,80,10)
		local textPenaltyColor:TColor = TColor.Create(80,45,10)
		local textWarningColor:TColor = TColor.Create(80,45,10)
		Local fontNormal:TBitmapFont = GetBitmapFontManager().baseFont
		Local fontBold:TBitmapFont = GetBitmapFontManager().baseFontBold
		Local fontSemiBold:TBitmapFont   = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)


		GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), currX + 6, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 18

		'content description
		currY :+ 3	'description starts with offset
		fontNormal.drawBlock(GetDescription(), currX + 6, currY, 280, 64, null ,textColor)
		currY :+ 64 'content
		currY :+ 3	'description ends with offset

		currY :+ 4 'offset of subContent


		'warn if special target group
		If base.targetGroup > 0
			currY :+ 4 'top content padding of that line
			fontSemiBold.drawBlock(getLocale("AD_TARGETGROUP")+": "+GetTargetgroupString(), currX + 35, currY, 245, 15, ALIGN_CENTER_CENTER, textWarningColor, 0,1,1.0,True, True)
			currY :+ 15 + 8 'lineheight + bottom content padding
		Endif

		'warn if short of time
		If daysLeft <= 1
			currY :+ 4 'top content padding of that line
			If daysLeft = 1
				fontSemiBold.drawBlock(getLocale("AD_SEND_TILL_TOMORROW"), currX + 35, currY, 245, 15, ALIGN_CENTER_CENTER, textWarningColor, 0,1,1.0,True, True)
			ElseIf daysLeft = 0
				fontSemiBold.drawBlock(getLocale("AD_SEND_TILL_MIDNIGHT"), currX + 35, currY, 245, 15, ALIGN_CENTER_CENTER, textWarningColor, 0,1,1.0,True, True)
			Else
				fontSemiBold.drawBlock(getLocale("AD_SEND_TILL_TOLATE"), currX + 35, currY, 245, 15, ALIGN_CENTER_CENTER, textWarningColor, 0,1,1.0,True, True)
			EndIf
			currY :+ 15 + 8 'lineheight + bottom content padding
		Endif


		currY :+ 4 'align to content portion of that line
		'days left for this contract
		If daysLeft > 1
			fontBold.drawBlock(daysLeft +" "+ getLocale("DAYS"), currX+34, currY , 62, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)
		Else
			fontBold.drawBlock(daysLeft +" "+ getLocale("DAY"), currX+34, currY , 62, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)
		EndIf
		'spots successfully sent
		if owner < 0
			'show how many we have to send
			fontBold.drawBlock(GetSpotCount() + "x", currX+131, currY , 58, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)
		else
			fontBold.drawBlock(GetSpotsSent() + "/" + GetSpotCount(), currX+131, currY , 58, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)
		endif
		'planend
		if owner > 0
			fontBold.drawBlock(GetSpotsPlanned() + "/" + GetSpotCount(), currX+224, currY , 58, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)
		endif
		currY :+ 15 + 8 'lineheight + bottom content padding


		currY :+ 4 'align to content portion of that line
		'minAudience
		fontBold.drawBlock(TFunctions.convertValue(GetMinAudience(), 2), currX+33, currY , 66, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)
		'penalty
		fontBold.drawBlock(TFunctions.convertValue(GetPenalty(), 2), currX+131, currY , 58, 15, ALIGN_RIGHT_CENTER, textPenaltyColor, 0,1,1.0,True, True)
		'profit
		fontBold.drawBlock(TFunctions.convertValue(GetProfit(), 2), currX+224, currY , 58, 15, ALIGN_RIGHT_CENTER, textProfitColor, 0,1,1.0,True, True)
		currY :+ 15 + 8 'lineheight + bottom content padding
	End Method


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
