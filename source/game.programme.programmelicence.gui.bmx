SuperStrict
Import "Dig/base.gfx.gui.list.base.bmx"
Import "common.misc.gamegui.bmx"
Import "game.programme.programmelicence.bmx"
Import "game.production.productionmanager.bmx"


Type TGUIProgrammeLicenceSlotList Extends TGUISlotList
	Field  acceptType:Int		= 0	'accept all
	Global acceptAll:Int		= 0
	Global acceptMovies:Int		= 1
	Global acceptSeries:Int		= 2

    Method Create:TGUIProgrammeLicenceSlotList(position:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(position, dimension, limitState)

		'albeit the list base already handles drop on itself
		'we want to intercept too -- to stop dropping if not
		'enough money is available
		'---alternatively we could intercept programmeblocks-drag-event
		'EventManager.registerListenerFunction( GUIEventKeys.GUIObject_OnTryDrop, self.onTryDrop, accept, self)

		Return Self
	End Method


	Method ContainsLicence:Int(licence:TProgrammeLicence)
		For Local i:Int = 0 To Self.GetSlotAmount()-1
			Local block:TGUIProgrammeLicence = TGUIProgrammeLicence(Self.GetItemBySlot(i))
			If block And block.licence = licence Then Return True
		Next
		Return False
	End Method


	'overriden Method: so it does not accept a certain
	'kind of programme (movies - series)
	Method AddItem:Int(item:TGUIobject, extra:Object=Null)
		Local coverBlock:TGUIProgrammeLicence = TGUIProgrammeLicence(item)
		If Not coverBlock Then Return False

		'something odd happened - no licence
		If Not coverBlock.licence Then Return False

		If acceptType > 0
			'movies and series do not accept collections or episodes
			If acceptType = acceptMovies And coverBlock.licence.isSeries() Then Return False
			If acceptType = acceptSeries And coverBlock.licence.isSingle() Then Return False
		EndIf

		If Super.AddItem(item,extra)
			'print "added an item ... slot state:" + self.GetUnusedSlotAmount()+"/"+self.GetSlotAmount()
			Return True
		EndIf

		Return False
	End Method
End Type



'a graphical representation of programmes to buy/sell/archive...
Type TGUIProgrammeLicence Extends TGUIGameListItem
	Field licence:TProgrammeLicence


	Method New()
		SetListItemOption(GUILISTITEM_AUTOSIZE_WIDTH, False)
	End Method


    Method Create:TGUIProgrammeLicence(pos:SVec2I, dimension:SVec2I, value:String="")
		Super.Create(pos, dimension, value)

		'override defaults - with the default genre identifier
		'(eg. "undefined" -> "gfx_movie_undefined")
		Self.assetNameDefault = "gfx_movie_"+TVTProgrammeGenre.GetAsString(-1)
		Self.assetNameDragged = "gfx_movie_"+TVTProgrammeGenre.GetAsString(-1)

		Return Self
	End Method


	Method CreateWithLicence:TGUIProgrammeLicence(licence:TProgrammeLicence)
		Self.Create(New SVec2I(0,0), New SVec2I(0,0))
		Self.setProgrammeLicence(licence)
		Return Self
	End Method


	Method SetProgrammeLicence:TGUIProgrammeLicence(licence:TProgrammeLicence)
		Self.licence = licence

		'get the string identifier of the genre (eg. "adventure" or "action")
		Local genreString:String = TVTProgrammeGenre.GetAsString(licence.GetGenre())
		Local assetName:String = ""

		'if it is a collection or series
		If licence.isCollection()
			assetName = "gfx_movie_" + genreString
		ElseIf licence.isSeries()
			assetName = "gfx_series_" + genreString
		Else
			assetName = "gfx_movie_" + genreString
		EndIf

		'use the name of the returned sprite - default or specific one
		if not GetSpriteFromRegistry(assetName, assetNameDefault)
			print "assetName:"+assetName+"  assetNameDefault:"+assetNameDefault
		endif
		assetName = GetSpriteFromRegistry(assetName, assetNameDefault).GetName()

		'check if "dragged" exists
		Local assetNameDragged:String = assetName+".dragged"
		local assetDragged:TSprite = GetSpriteFromRegistry(assetNameDragged)
		if not assetDragged then print "assetDragged failed"
		If assetDragged and assetDragged.GetName() <> assetNameDragged
			assetNameDragged = assetName
		EndIf

		Self.InitAssets(assetName, assetNameDragged)

		Return Self
	End Method


	'override to only allow dragging for affordable or own licences
	Method IsDragable:Int()
		If Super.IsDragable()
			Return (licence.owner = GetPlayerBaseCollection().playerID Or (licence.owner <= 0 And IsAffordable()))
		Else
			Return False
		EndIf
	End Method


	Method IsAffordable:Int()
		Return GetPlayerBase().getFinance().canAfford(licence.getPriceForPlayer( GetObservedPlayerID() ))
	End Method


	Method DrawSheet(x:Int = 30, y:Int = 20, alignment:Float)
		Local sheetWidth:Int = 330
		local baseX:Int = int(x - alignment * sheetWidth)

		local oldA:Float = GetAlpha()
		local oldCol:SColor8
		GetColor(oldCol)
		SetColor 0,0,0
		SetAlpha 0.2 * oldA
		TFunctions.DrawBaseTargetRect(baseX + sheetWidth/2, ..
		                              y + 70, ..
		                              Self.GetScreenRect().GetX() + Self.GetScreenRect().GetW()/2.0, ..
		                              Self.GetScreenRect().GetY() + Self.GetScreenRect().GetH()/2.0, ..
		                              20, 3)
		SetColor(oldCol)
		SetAlpha oldA


		local forPlayerID:int = licence.owner
		if forPlayerID <= 0 then forPlayerID = GetObservedPlayerID()
		
		if Self.licence.GetData().IsCustomProduction() and Self.licence.IsLive() and not GameRules.payLiveProductionInAdvance
			'for live the production is also in the live list of the manager...
			'so we could skip a more intense search in the ProductionCollection
			Local production:TProduction = GetProductionManager().GetLiveProduction(Self.licence.GetData().GetProductionID())
			if production
				local toPay:int = production.productionConcept.GetTotalCost() - production.productionConcept.GetDepositCost()
				local extraData:TData = new TData
				extraData.Add("productionCostsLeft", toPay)
				Self.licence.ShowSheet(x, y, alignment, TVTBroadcastMaterialType.PROGRAMME, forPlayerID, extraData)
			else
				Self.licence.ShowSheet(x, y, alignment, TVTBroadcastMaterialType.PROGRAMME, forPlayerID)
			endif
		Else
			Self.licence.ShowSheet(x, y, alignment, TVTBroadcastMaterialType.PROGRAMME, forPlayerID)
		EndIf
			
	End Method


	Method Draw()
		SetColor 255,255,255
		Local oldCol:SColor8
		Local oldA:Float = GetAlpha()
		GetColor(oldCol)

		local markFaded:int = False
		'make faded as soon as not "dragable" for us
		If licence.owner <> GetPlayerBaseCollection().playerID And (licence.owner<=0 And Not IsAffordable())
			markFaded = True
		endif

		if licence.owner = GetPlayerBaseCollection().playerID and not licence.IsTradeable()
			markFaded = True
		endif
		if markFaded then SetAlpha oldA * 0.75

		Super.Draw()

		if markFaded
			SetAlpha oldA * 0.75 * 0.90
		else
			SetAlpha oldA * 0.9
		endif
		if licence.IsPaid() then GetSpriteFromRegistry("gfx_movie_flag_paid").Draw(GetScreenRect().GetX(), GetScreenRect().GetY() + GetScreenRect().GetH() - 14, -1, ALIGN_LEFT_BOTTOM)
		if licence.IsXRated() then GetSpriteFromRegistry("gfx_movie_flag_xrated").Draw(GetScreenRect().GetX(), GetScreenRect().GetY() + GetScreenRect().GetH()  - 20, -1, ALIGN_LEFT_BOTTOM)
		if licence.IsLive() then GetSpriteFromRegistry("gfx_movie_flag_live").Draw(GetScreenRect().GetX(), GetScreenRect().GetY() + GetScreenRect().GetH()  - 26, -1, ALIGN_LEFT_BOTTOM)

		SetColor(oldCol)
		SetAlpha oldA
	End Method
End Type
