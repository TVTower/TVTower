SuperStrict
Import "Dig/base.gfx.gui.list.base.bmx"
Import "common.misc.gamelist.bmx"
Import "game.programme.programmelicence.bmx"


Type TGUIProgrammeLicenceSlotList Extends TGUISlotList
	Field  acceptType:Int		= 0	'accept all
	Global acceptAll:Int		= 0
	Global acceptMovies:Int		= 1
	Global acceptSeries:Int		= 2

    Method Create:TGUIProgrammeLicenceSlotList(position:TVec2D = Null, dimension:TVec2D = Null, limitState:String = "")
		Super.Create(position, dimension, limitState)

		'albeit the list base already handles drop on itself
		'we want to intercept too -- to stop dropping if not
		'enough money is available
		'---alternatively we could intercept programmeblocks-drag-event
		'EventManager.registerListenerFunction( "guiobject.onDropOnTarget", self.onDropOnTarget, accept, self)

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


    Method Create:TGUIProgrammeLicence(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		Super.Create(pos, dimension, value)

		'override defaults - with the default genre identifier
		'(eg. "undefined" -> "gfx_movie_undefined")
		Self.assetNameDefault = "gfx_movie_"+TVTProgrammeGenre.GetAsString(-1)
		Self.assetNameDragged = "gfx_movie_"+TVTProgrammeGenre.GetAsString(-1)

		Return Self
	End Method


	Method CreateWithLicence:TGUIProgrammeLicence(licence:TProgrammeLicence)
		Self.Create()
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
		Return GetPlayerBase().getFinance().canAfford(licence.getPrice())
	End Method


	Method DrawSheet(leftX:Int=30, rightX:Int=30)
'		self.parentBlock.DrawSheet()
		Local sheetY:Int = 20
		Local sheetX:Int = leftX
		Local sheetAlign:Int= 0
		'if mouse on left side of screen - align sheet on right side
		If MouseManager.x < GetGraphicsManager().GetWidth()/2
			sheetX = GetGraphicsManager().GetWidth() - rightX
			sheetAlign = 1
		EndIf

		SetColor 0,0,0
		SetAlpha 0.2
		Local x:Float = Self.GetScreenX()
		Local tri:Float[]=[Float(sheetX+20),Float(sheetY+25),Float(sheetX+20),Float(sheetY+90),Self.GetScreenX()+Self.GetScreenWidth()/2.0+3,Self.GetScreenY()+Self.GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		Self.licence.ShowSheet(sheetX,sheetY, sheetAlign, TVTBroadcastMaterialType.PROGRAMME)
	End Method


	Method Draw()
		SetColor 255,255,255
		local oldCol:TColor = new TColor.get()

		local markFaded:int = False
		'make faded as soon as not "dragable" for us
		If licence.owner <> GetPlayerBaseCollection().playerID And (licence.owner<=0 And Not IsAffordable())
			markFaded = True
		endif
		if licence.owner = GetPlayerBaseCollection().playerID and not licence.IsTradeable()
			markFaded = True
		endif


		if markFaded then SetAlpha oldCol.a * 0.75

		Super.Draw()

		if markFaded
			SetAlpha oldCol.a * 0.75 * 0.90
		else
			SetAlpha oldCol.a * 0.9
		endif
		if licence.HasDataFlag(TVTProgrammeDataFlag.PAID) then GetSpriteFromRegistry("gfx_movie_flag_paid").Draw(GetScreenX(), GetScreenY() + GetScreenHeight() - 3, ALIGN_BOTTOM)
		if licence.HasDataFlag(TVTProgrammeDataFlag.XRATED) then GetSpriteFromRegistry("gfx_movie_flag_xrated").Draw(GetScreenX(), GetScreenY() + GetScreenHeight()  - 36, ALIGN_BOTTOM)
		if licence.HasDataFlag(TVTProgrammeDataFlag.LIVE) then GetSpriteFromRegistry("gfx_movie_flag_live").Draw(GetScreenX(), GetScreenY() + GetScreenHeight()  - 7, ALIGN_BOTTOM)

		SetAlpha oldCol.a
	End Method
End Type