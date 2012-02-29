
Type TPlannerList
	Field openState:int				= 0 '0=enabled 1=openedgenres 2=openedmovies 3=openedepisodes = 1
	Field currentGenre:Int			=-1
	Field enabled:Int				= 0
	Field Pos:TPosition 			= TPosition.Create()

	Method GetOpen:Int()
		return self.openState
	End Method
End Type

'the programmelist shown in the programmeplaner
Type TgfxProgrammelist extends TPlannerList
	Field gfxgenres:TGW_Sprites
	Field gfxmovies:TGW_Sprites
	Field gfxtape:TGW_Sprites
	Field gfxtapeseries:TGW_Sprites
	Field gfxtapeepisodes:TGW_Sprites
	Field gfxepisodes:TGW_Sprites

	Field currentseries:TProgramme	= Null

	Function Create:TgfxProgrammelist(x:Int, y:Int)
		Local NewObject:TgfxProgrammelist =New TgfxProgrammelist
		NewObject.gfxgenres			= Assets.GetSprite("genres")
		NewObject.gfxmovies			= Assets.GetSprite("pp_menu_werbung")   'Assets.GetSprite("") '  = gfxmovies
		NewObject.gfxtape			= Assets.GetSprite("pp_cassettes_movies")
		NewObject.gfxtapeseries		= Assets.GetSprite("pp_cassettes_series")
		NewObject.gfxtapeepisodes	= Assets.GetSprite("pp_cassettes_episodes")
		NewObject.gfxepisodes		= Assets.GetSprite("episodes")
		NewObject.Pos.SetXY(x, y)
		Return NewObject
	End Function

	Method Draw:Int(createProgrammeblock:Int=1)
		if not enabled then return 0

		If self.openState >=2
			gfxmovies.Draw(Pos.x - gfxmovies.w + 14, Pos.y)
			If currentgenre >= 0 	Then DrawTapes(currentgenre, createProgrammeblock)
			If currentSeries<> Null	Then DrawEpisodeTapes(currentseries, createProgrammeblock)
		EndIf
		If self.openState >=1
			gfxgenres.Draw(Pos.x, Pos.y)
			For local genres:int = 0 To 17 		'18 genres
				FontManager.baseFont.drawBlock (TProgramme.GetGenre(genres) + " (" + TProgramme.CountGenre(genres, Player[Game.playerID].ProgrammeCollection.List) + ")", Pos.x + 4, Pos.y + 18 * (genres + 1) - 1, 104, 16, 0)
			Next
			SetAlpha 0.6; SetColor 0, 255, 0
			For local genres:int = 0 To 17 		'18 genres
				Local genrecount:Int = TProgramme.CountGenre(genres, Player[Game.playerID].ProgrammeCollection.List)
				If genrecount > 0
					For Local i:Int = 0 To genrecount - 1
						DrawLine(Pos.x + 111 + i * 2, Pos.y + 18 + 18 * (Genres) - 1, Pos.x + 111 + i * 2, Pos.y + 32 + 18 * (Genres) - 1)
					Next
				EndIf
			Next
			SetAlpha 1.0SetColor 255, 255, 255
		EndIf
		If self.openState >=3 Then gfxepisodes.Draw(Pos.x - gfxepisodes.w, Pos.y + gfxmovies.h - 4)
	End Method

	Method DrawTapes:Int(genre:Int, createProgrammeblock:Int=1)
		Local locx:Int = Pos.x - gfxmovies.w + 25
		Local locy:Int = Pos.y+7 -19

		local font:TBitmapFont = FontManager.GetFont("Font10")
		For Local movie:TProgramme = EachIn Player[Game.playerID].ProgrammeCollection.List 'all programmes of one player
			If movie.genre = genre
				locy :+ 19
				If movie.isMovie
					gfxtape.Draw(locx, locy)
				else
					gfxtapeseries.Draw(locx, locy)
				endif
				font.DrawBlock(movie.title, locx + 13, locy + 1, 139, 16, 0, 0, 0, 0, True)
				If functions.isin(MouseX(), MouseY(), locx, locy, gfxtape.w, gfxtape.h)
					SetAlpha 0.2;
					If movie.isMovie
						DrawRect(locx, locy, gfxtape.w, gfxtape.h)
					else
						DrawRect(locx, locy, gfxtapeseries.w, gfxtapeseries.h)
					endif
					SetAlpha 1.0
					If Not MOUSEMANAGER.IsHit(1) then movie.ShowSheet(30,20)
				EndIf
			EndIf
		Next
	End Method

	Method UpdateTapes:Int(genre:Int, createProgrammeblock:Int=1)
		Local locx:Int = Pos.x - gfxmovies.w + 25
		Local locy:Int = Pos.y+7 -19

		For Local movie:TProgramme = EachIn Player[Game.playerID].ProgrammeCollection.List 'all programmes of one player
			If movie.genre = genre
				locy :+ 19
				If MOUSEMANAGER.IsHit(1) AND functions.isin(MouseX(), MouseY(), locx, locy, gfxtape.w, gfxtape.h)
					Game.cursorstate = 1
					If createProgrammeblock
						If movie.isMovie Then
							TProgrammeBlock.CreateDragged(movie)
							SetOpen(0)
						Else
							currentseries = movie
							SetOpen(3)
						EndIf
						MOUSEMANAGER.resetKey(1)
					Else
						TArchiveProgrammeBlocks.CreateDragged(movie, Game.playerID)
						SetOpen(0)
					EndIf
					Exit 'exit for local movie
				EndIf
			EndIf
		Next
	End Method

	Method DrawEpisodeTapes:Int(series:TProgramme, createProgrammeblock:Int=1)
		Local locx:Int = Pos.x - gfxepisodes.w + 8
		Local locy:Int = Pos.y + 5 + gfxmovies.h - 4 -12 '-4 as displacement for displaced the background
		local font:TBitmapFont = FontManager.GetFont("FontTapes")

		For Local i:Int = 0 To series.episodelist.Count()-1
			Local episode:TProgramme = TProgramme(series.episodeList.ValueAtIndex(i))   'all programmes of one player
			'	  Local episode:TProgramme = TProgramme(series.episodeList.Items[i]) 'all programmes of one player
			If episode <> Null
				locy :+ 12
				gfxtapeepisodes.Draw(locx, locy)
				font.DrawBlock("(" + episode.episodeNumber + "/" + series.episodecount + ") " + episode.title, locx + 10, locy + 1, 85, 12, 0, 0, 0, 0, True)
				If functions.IsIn(MouseX(),MouseY(), locx,locy, gfxtapeepisodes.w, gfxtapeepisodes.h)
					Game.cursorstate = 1
					SetAlpha 0.2;DrawRect(locx, locy, gfxtapeepisodes.w, gfxtapeepisodes.h) ;SetAlpha 1.0
					If Not MOUSEMANAGER.IsHit(1)
						episode.ShowEpisodeSheet(30,20, series)
					EndIf
				EndIf
			EndIf
		Next
	End Method

	Method UpdateEpisodeTapes:Int(series:TProgramme, createProgrammeblock:Int=1)
		'Local genres:Int
		Local tapecount:Int = 0
		Local locx:Int = Pos.x - gfxepisodes.w + 8
		Local locy:Int = Pos.y + 5 + gfxmovies.h - 4 -12 '-4 as displacement for displaced the background
		For Local i:Int = 0 To series.episodelist.Count()-1
			Local episode:TProgramme = TProgramme(series.episodeList.ValueAtIndex(i))	'all programmes of one player
			If episode <> Null
				locy :+ 12
				tapecount :+ 1
				If functions.IsIn(MouseX(),MouseY(), locx,locy, gfxtapeepisodes.w, gfxtapeepisodes.h)
					If MOUSEMANAGER.IsHit(1)
						TProgrammeBlock.CreateDragged(episode, series)
						SetOpen(0)
						MOUSEMANAGER.resetKey(1)
					EndIf
				EndIf
			EndIf
		Next
	End Method

	Method Update(createProgrammeblock:Int=1)
		If enabled
			If MOUSEMANAGER.IsHit(2)
				SetOpen(0)
				MOUSEMANAGER.resetKey(2)
			EndIf
			If MOUSEMANAGER.IsHit(1) AND functions.IsIn(MouseX(),MouseY(), Pos.x,Pos.y, gfxgenres.w, gfxgenres.h)
				SetOpen(2)
				currentgenre = Floor((MouseY() - Pos.y - 16) / 18)
			EndIf

			If self.openState >=2
				If currentgenre >= 0	Then UpdateTapes(currentgenre, createProgrammeblock)
				If currentSeries<> Null	Then UpdateEpisodeTapes(currentseries, createProgrammeblock)
			EndIf
		EndIf
	End Method

	Method SetOpen:Int(newState:Int)
		newState = Max(0, newState)
		If newState <= 0 Then enabled = 0;currentseries=Null;currentgenre=-1 else enabled = 1

		self.openState = newState
	End Method
End Type

'the adspot/contractlist shown in the programmeplaner
Type TgfxContractlist extends TPlannerList
	Field gfxcontracts:TGW_Sprites
	Field gfxtape:TGW_Sprites

	Function Create:TgfxContractlist(x:Int, y:Int)
		Local NewObject:TgfxContractlist =New TgfxContractlist
		NewObject.gfxcontracts	= Assets.GetSprite("pp_menu_werbung")
		NewObject.gfxtape 		= Assets.GetSprite("pp_cassettes_movies")
		NewObject.Pos.SetXY(x, y)
		Return NewObject
	End Function

	Method Draw:Int()
		If enabled And self.openState >= 1
			gfxcontracts.Draw(Pos.x - gfxcontracts.w, Pos.y)
			DrawTapes()
		EndIf
	End Method

	Method DrawTapes:Int()
		local boxHeight:int			= gfxtape.h + 2
		Local locx:Int 				= Pos.x - gfxcontracts.w + 10
		Local locy:Int 				= Pos.y+7 - boxHeight
		local font:TBitmapFont 		= FontManager.GetFont("Default", 10)
		For Local contract:TContract = EachIn Player[Game.playerID].ProgrammeCollection.ContractList 'all contracts of one player
			locy :+ boxHeight
			gfxtape.Draw(locx, locy)

			font.drawBlock(contract.title, locx + 13,locy + 3, 139,16,0,0,0,0,True)
			If functions.IsIn(MouseX(),MouseY(), locx,locy, gfxtape.w, gfxtape.h)
				Game.cursorstate = 1
				SetAlpha 0.2;DrawRect(locx, locy, gfxtape.w, gfxtape.h) ;SetAlpha 1.0
				If MOUSEMANAGER.IsHit(1)
					TAdBlock.CreateDragged(contract)
					self.SetOpen(0)
					MOUSEMANAGER.resetKey(1)
				Else
					contract.ShowSheet(30,20)
				EndIf
			EndIf
		Next
	End Method

	Method Update()
		If enabled
			If MOUSEMANAGER.IsHit(2)
				SetOpen(0)
				MOUSEMANAGER.resetKey(2)
			endif
			Draw()
		EndIf
	End Method

	Method SetOpen:Int(newState:Int)
		newState = Max(0, newState)
		If newState <= 0 Then enabled = 0 else enabled = 1
		self.openState = newState
	End Method
End Type



Type TAudienceQuotes
  Field title:String
  Field audience:Int
  Field audiencepercentage:Int
  Field playerID:Int
  Field sendhour:Int
  Field sendminute:Int
  Field senddate:Int
  Global List:TList = CreateList()  ' :TObjectList = TObjectList.Create(1000) {saveload = "nosave"}
  Global sheet:TTooltip = Null {saveload = "nosave"}


	Function Load:TAudienceQuotes(pnode:xmlNode)
  		Local audience:TAudienceQuotes = New TAudienceQuotes
		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(audience)
			For Local t:TField = EachIn typ.EnumFields()
				If (t.MetaData("saveload") <> "nosave" Or t.MetaData("saveload") = "normal") And Upper(t.name()) = NODE.name
					t.Set(audience, nodevalue)
				EndIf
			Next
			NODE = NODE.nextSibling()
		Wend
		TAudienceQuotes.List.AddLast(audience)
		Return audience
	End Function

	Function LoadAll()
		TAudienceQuotes.List.Clear()
		Local Children:TList = LoadSaveFile.NODE.ChildList
		For Local NODE:xmlNode = EachIn Children
			If NODE.name = "AUDIENCEQUOTE"
				TAudienceQuotes.Load(NODE)
			End If
		Next
		PrintDebug ("TAudienceQuotes.LoadAll()", "AudienceQuotes eingeladen", DEBUG_SAVELOAD)
	End Function

	Function SaveAll()
		'TFinancials.List.Sort()
		LoadSaveFile.xmlBeginNode("ALLAUDIENCEQUOTES")
			For Local i:Int = 0 To TAudienceQuotes.List.Count()-1
'				Local audience:TAudienceQuotes = TAudienceQuotes(TAudienceQuotes.List.Items[i] )
				Local audience:TAudienceQuotes = TAudienceQuotes(TAudienceQuotes.List.ValueAtIndex(i))
				If audience<> Null Then audience.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("AUDIENCEQUOTE")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "nosave" Or t.MetaData("saveload") = "normal"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
		LoadSaveFile.xmlCloseNode()
	End Method


  Function Create:TAudienceQuotes(title:String, audience:Double, audiencepercentage:Int, sendhour:Int, sendminute:Int,senddate:Int, playerID:Int)
    Local locObject:TAudienceQuotes = New TAudienceQuotes
	locObject.title    = title
	locObject.audience = audience
	locObject.audiencepercentage = Int(audiencepercentage)
	locObject.sendhour = sendhour
	locObject.sendminute = sendminute
	locObject.senddate = senddate
	locObject.playerID = playerID
	List.AddLast(locObject)
	Return locObject
  End Function

  Method ShowSheet(x:Int, y:Int)
	If Sheet = Null
	  Sheet = TTooltip.Create(title, Localization.GetString("AUDIENCE_RATING") + ": " + functions.convertValue(String(audience), 2, 0) + " (" + audiencepercentage + "%)", x, y, 200, 20)
    Else
	  Sheet.title = title
	  Sheet.text = Localization.GetString("AUDIENCE_RATING")+": "+functions.convertValue(String(audience), 2, 0)+" ("+(audiencepercentage/10)+"%)"
	  Sheet.enabled = 1
	  Sheet.pos.setXY(x,y)
	  Sheet.width = 0
	  Sheet.height = 0
	  Sheet.lifetime = 10
	End If
  End Method

	Function GetAudienceOfDate:TAudienceQuotes(playerID:int, day:Int, hour:Int, minute:Int)
		Local locObject:TAudienceQuotes
		For Local obj:TAudienceQuotes = EachIn TAudienceQuotes.List
			If obj.playerID = playerID And obj.senddate = day And obj.sendhour = hour And obj.sendminute = minute Then Return obj
  		Next
		Return Null
	End Function

  Function GetAudienceOfDay:TAudienceQuotes[](playerID:Int, day:Int)
    Local locObjects:TAudienceQuotes[]
	Local locObject:TAudienceQuotes

	For Local i:Int = 0 To TAudienceQuotes.List.Count()-1
	  locObject = TAudienceQuotes(TAudienceQuotes.List.ValueAtIndex(i))
	  If locObject <> Null
        If locObject.playerID = playerID And locObject.senddate = day
		  LocObjects=LocObjects[..LocObjects.length+1]
		  LocObjects[LocObjects.length-1] = locObject
        End If
	  EndIf
	Next
	Return locObjects
  End Function
End Type

'tooltips containing headline and text, updated and drawn by Tinterface
'extends TRenderableChild - could get attached to sprites
Type TTooltip extends TRenderableChild
  Field lifetime:float = 0.1
  Field startlifetime:float = 1.0
  Field title:String
  Field text:String
  Field oldtitle:String
  Field width:Int
  Field height:Int
  Field Image:TImage = Null
  Field DirtyImage:Byte =1
  Field tooltipimage:Int=-1
  Field TitleBGtype:Byte = 0
  Field enabled:Int = 0

  Global TooltipHeader:TGW_Sprites
  Global ToolTipIcons:TImage

  Global UseFontBold:TBitmapFont
  Global UseFont:TBitmapFont
  Global List:TList = CreateList()

	Function Create:TTooltip(title:String = "", text:String = "unknown", x:Int = 0, y:Int = 0, width:Int = -1, Height:Int = -1, lifetime:Int = 1000)
		Local tooltip:TTooltip = New TTooltip
		tooltip.title		= title
		tooltip.oldtitle	= title
		tooltip.text		= text
		tooltip.pos.setXY(x,y)
		tooltip.tooltipimage = -1
		tooltip.width = width
		tooltip.height= height
		tooltip.lifetime		= float(lifetime) / 1000.0
		tooltip.startlifetime	= float(lifetime) / 1000.0
		If not List Then List	= CreateList()
		List.AddLast(tooltip)
		SortList List
		'Print "Tooltip created:" + title + "ListCount: " + List.Count()

		Return tooltip
	End Function

	Method Update:Int(deltaTime:float=1.0)
'		print "update "+self.lifetime + " " + deltatime
		lifetime :- deltaTime
		if lifetime < 1.0 then lifetime :* 0.8 'speed up fade
		If lifetime <= 0 ' And enabled 'enabled - as pause sign?
			Self.Image		= Null
			Self.enabled	= False
			self.List.remove(Self)
		EndIf
	End Method

	Method GetWidth:Int()
		local txtWidth:int = self.useFontBold.getWidth(title)+6
		If tooltipimage >=0 Then txtwidth:+ ImageWidth(TTooltip.ToolTipIcons)+ 2
		If txtwidth < self.useFont.getWidth(text)+6 Then txtwidth = self.useFont.getWidth(text)+6
		Return txtwidth
	End Method

	Method DrawShadow(_width:float, _height:float)
		SetColor 0, 0, 0
		SetAlpha (Float(100*lifetime / startlifetime) / 100.0)-0.8
		DrawRect(self.pos.x+2,self.pos.y+2,_width,_height)

		SetAlpha (Float(100*lifetime / startlifetime) / 100.0)-0.5
		DrawRect(self.pos.x+1,self.pos.y+1,_width,_height)
	End Method

	Method Draw:Int(tweenValue:float=1.0)
		If Not enabled Then Return 0

		If Title <> oldTitle then self.DirtyImage = True

		If Self.DirtyImage = True Or Self.Image = Null
			Local boxWidth:Int		= self.width
			Local boxHeight:Int		= Self.height

			'auto width calculation
			If width <= 0
				'width from title + spacing
				boxWidth = self.UseFontBold.getWidth(title)+6
				'add icon to width
				If tooltipimage >=0 Then boxWidth:+ ImageWidth(TTooltip.ToolTipIcons)+ 2
				'compare with tex
				boxWidth = max(self.UseFont.getWidth(text)+6, boxWidth)
				boxWidth :+ 4 'extra spacing
			EndIf

			'auto height calculation
			if height <= 0
				boxHeight = Self.TooltipHeader.h
				If Len(text)>1 Then boxHeight :+ (self.UseFont.getHeight(text)+8)
				If tooltipimage >= 0 Then boxHeight :+ 2
			endif
			self.DrawShadow(boxWidth,boxHeight)

			SetAlpha Float(100*lifetime / startlifetime) / 100.0
			DrawRect(self.pos.x,self.pos.y, boxWidth,boxHeight)

			SetColor 255,255,255
			DrawRect(self.pos.x+1,self.pos.y+1,boxWidth-2,boxHeight-2)

			If TitleBGtype = 0 Then SetColor 250,250,250
			If TitleBGtype = 1 Then SetColor 200,250,200
			If TitleBGtype = 2 Then SetColor 250,150,150
			If TitleBGtype = 3 Then SetColor 200,200,250

			Self.TooltipHeader.TileDraw(self.pos.x+1,self.pos.y+1, boxWidth-2, Self.TooltipHeader.h)
			SetColor 255,255,255
			local displaceX:float = 0.0
			If tooltipimage >=0
				DrawImage(TTooltip.ToolTipIcons,self.pos.x+1,self.pos.y+1, tooltipimage)
				displaceX = ImageWidth(TTooltip.ToolTipIcons)
			endif

			SetAlpha Float(100*lifetime / startlifetime) / 100.0
			'caption
			self.useFontBold.drawStyled(title, self.pos.x+5+displaceX, self.pos.y+Self.TooltipHeader.h/2 - self.useFontBold.getHeight("ABC")/2 , 50,50,50, 2,0, 1, 0.1)
			SetColor 90,90,90
			'text
			If text <> "" Then self.Usefont.Draw(text, self.pos.x+5,self.pos.y+Self.TooltipHeader.h + 7)
			If self.pos.x > 20 And self.pos.y > 10 And self.pos.x + boxWidth < 760 And self.pos.y + boxHeight < 800 '383 'And lifetime = startlifetime
				Image = TImage.Create(boxWidth, boxHeight, 1, 0, 255, 0, 255)
				image.pixmaps[0] = GrabPixmap(self.pos.x, self.pos.y, boxWidth, boxHeight)
				DirtyImage = False
			Else
				self.pos.x = Max(21,self.pos.x)
				If self.pos.x + boxWidth < 760 Then self.pos.x = 759 - boxWidth
			EndIf
			oldTitle = title
			SetColor 255, 255, 255
			SetAlpha 1.0
		Else 'not dirty
			self.DrawShadow(ImageWidth(image),ImageHeight(image))
			SetAlpha Float(100.0  * lifetime / startlifetime) / 100
			SetColor 255,255,255
			DrawImage(image, self.pos.x, self.pos.y)
			SetAlpha 1.0
		EndIf
	End Method
End Type


	Function DrawDialog(gfx_Rect:TGW_SpritePack, x:Int, y:Int, width:Int, Height:Int, DialogStart:String = "StartDownLeft", DialogStartMove:Int = 0, DialogText:String = "", DialogFont:TBitmapFont = Null)
		Local dx:Float, dy:Float
		Local DialogSprite:TGW_Sprites = gfx_Rect.GetSprite(DialogStart)
		If DialogStart = "StartLeftDown" Then dx = x - 48;dy = y + (Height - DialogSprite.h)/2 + DialogStartMove;width:-48
		If DialogStart = "StartRightDown" Then dx = x + width - 12;dy = y + (Height - DialogSprite.h)/2 + DialogStartMove;width:-48
		If DialogStart = "StartDownRight" Then dx = x + (width - DialogSprite.w)/2 + DialogStartMove;dy = y + Height - 12;Height:-53
		If DialogStart = "StartDownLeft" Then dx = x + (width - DialogSprite.w)/2 + DialogStartMove;dy = y + Height - 12;Height:-53

		DrawGFXRect(gfx_Rect,x,y,width,height,"") ' "" = no nameBase

		DialogSprite.Draw(dx, dy)
		If DialogText <> "" then DialogFont.drawBlock(DialogText, x + 10, y + 10, width - 16, Height - 16, 0, 0, 0, 0)
	End Function

	'draws a rounded rectangle (blue border) with alphashadow
	Function DrawGFXRect(gfx_Rect:TGW_SpritePack, x:Int, y:Int, width:Int, Height:Int, nameBase:string="gfx_gui_rect_")
		gfx_Rect.GetSprite(nameBase+"TopLeft").Draw(x, y)
		gfx_Rect.GetSprite(nameBase+"TopRight").Draw(x + width, y,-1,0,1)
		gfx_Rect.GetSprite(nameBase+"BottomLeft").Draw(x, y + Height, -1,1)
		gfx_Rect.GetSprite(nameBase+"BottomRight").Draw(x + width, y + Height, -1, 1,1)

		gfx_Rect.GetSprite(nameBase+"BorderLeft").TileDraw(x, y + gfx_Rect.GetSprite(nameBase+"TopLeft").h, gfx_Rect.GetSprite(nameBase+"BorderLeft").w, Height - gfx_Rect.GetSprite(nameBase+"BottomLeft").h - gfx_Rect.GetSprite(nameBase+"TopLeft").h)
		gfx_Rect.GetSprite(nameBase+"BorderRight").TileDraw(x + width - gfx_Rect.GetSprite(nameBase+"BorderRight").w, y + gfx_Rect.GetSprite(nameBase+"TopLeft").h, gfx_Rect.GetSprite(nameBase+"BorderRight").w, Height - gfx_Rect.GetSprite(nameBase+"BottomRight").h - gfx_Rect.GetSprite(nameBase+"TopRight").h)
		gfx_Rect.GetSprite(nameBase+"BorderTop").TileDraw(x + gfx_Rect.GetSprite(nameBase+"TopLeft").w, y, width - gfx_Rect.GetSprite(nameBase+"TopLeft").w - gfx_Rect.GetSprite(nameBase+"TopRight").w, gfx_Rect.GetSprite(nameBase+"BorderTop").h)
		gfx_Rect.GetSprite(nameBase+"BorderBottom").TileDraw(x + gfx_Rect.GetSprite(nameBase+"BottomLeft").w, y + Height - gfx_Rect.GetSprite(nameBase+"BorderBottom").h, width - gfx_Rect.GetSprite(nameBase+"BottomLeft").w - gfx_Rect.GetSprite(nameBase+"BottomRight").w, gfx_Rect.GetSprite(nameBase+"BorderBottom").h)
		gfx_Rect.GetSprite(nameBase+"Back").TileDraw(x + gfx_Rect.GetSprite(nameBase+"TopLeft").w, y + gfx_Rect.GetSprite(nameBase+"TopLeft").h, width - gfx_Rect.GetSprite(nameBase+"TopLeft").w - gfx_Rect.GetSprite(nameBase+"TopRight").w, Height - gfx_Rect.GetSprite(nameBase+"TopLeft").h - gfx_Rect.GetSprite(nameBase+"BottomLeft").h)
	End Function

Type TBlockGraphical extends TBlock
	Field imageBaseName:string
	Field imageDraggedBaseName:string
	Field image:TGW_Sprites
	Field image_dragged:TGW_Sprites
End Type

Type TBlock
  Field dragable:Int = 1 {saveload = "normalExt"}
  Field dragged:Int = 0 {saveload = "normalExt"}
  Field Pos:TPosition = TPosition.Create(0, 0) {saveload = "normal"}
  Field OrigPos:TPosition = TPosition.Create(0, 0) {saveload = "normalExtB"}
  Field StartPos:TPosition = TPosition.Create(0, 0) {saveload = "normalExt"}
  Field StartPosBackup:TPosition = TPosition.Create(0, 0)
  Field owner:Int =0 {saveload="normalExt"}
  Field Height:Int {saveload = "normalExt"}
  Field width:Int {saveload = "normalExt"}

	'switches coords and state of blocks
	Method SwitchBlock(otherObj:TBlock)
		Local old:Int
		Self.SwitchCoords(otherObj)
		old = Self.dragged
		Self.dragged = otherObj.dragged
		otherObj.dragged = old
	End Method

	'switches current and startcoords of two blocks
	Method SwitchCoords(otherObj:TBlock)
		TPosition.SwitchPos(Self.Pos, 				otherObj.Pos)
		TPosition.SwitchPos(Self.StartPos,			otherObj.StartPos)
		TPosition.SwitchPos(Self.StartPosBackup,	otherObj.StartPosBackup)
	End Method

	'checks if _x, _y is within startposition+dimension
	Method ContainingCoord:Byte(_x:Int, _y:Int)
		If TFunctions.IsIn(_x,_y, Self.StartPos.x, Self.StartPos.y, Self.width, Self.height) Return True
		Return False
	End Method

	Method SetCoords(_x:Int=1000, _y:Int=1000, _startx:Int=1000, _starty:Int=1000)
      If _x<>1000 		 Then Self.pos.SetX(_x)
      If _y<>1000		 Then Self.pos.SetY(_y)
      If _startx <> 1000 Then Self.StartPos.setX(_startx)
      If _starty <> 1000 Then Self.StartPos.SetY(_starty)
	End Method

	Method SetBaseCoords(_x:Int = 1000, _y:Int = 1000)
      If _x <> 1000 Then Self.Pos.SetX(_x);Self.StartPos.SetX(_x)
      If _y <> 1000 Then Self.Pos.SetY(_y);Self.StartPos.SetY(_y)
	End Method

	Method IsAtStartPos:Int()
		If Abs(Self.pos.x - Self.StartPos.x)<=1 And Abs(Self.pos.y - Self.StartPos.y)<=1 Then Return True
		Return False
	End Method

End Type


Type TFader
	Field fadecount:Double	= 0
	Field fadeout:Int 		= False
	Field fadeenabled:Int	= False

	Method Enable()
		Self.fadecount = 1
		Self.fadeenabled = True
		Self.fadeout = False
	End Method

	Method EnableFadeout()
		Self.fadecount = 20
		Self.fadeenabled = True
		Self.fadeout = True
	End Method

	Method Update(deltaTime:float=1.0)
		If Self.fadecount > 20
			Self.fadecount = 20
		ElseIf Self.fadecount >= 0 And Self.fadeenabled
			Self.fadecount:+(0.75 - 1.5 * Self.fadeout)
		ElseIf Self.fadecount < 0
			Self.fadecount = -1
			Self.fadeenabled = False
		EndIf
	End Method

	Method Draw(deltaTime:float=1.0)
		If Self.fadecount >= 0 And Self.fadeenabled
			SetColor 0, 0, 0;SetAlpha Self.fadecount / 20
			DrawRect(20,10,380-(20-Self.fadecount)*19,190-(20-Self.fadecount)*19)
			DrawRect(400+(20-Self.fadecount)*19,10,380-(20-Self.fadecount)*19,190-(20-Self.fadecount)*19)
			DrawRect(20,195+(20-Self.fadecount)*19,380-(20-Self.fadecount)*19,190-(20-Self.fadecount)*19)
			DrawRect(400+(20-Self.fadecount)*19,195+(20-Self.fadecount)*19,380-(20-Self.fadecount)*19,190-(20-Self.fadecount)*19)
			SetColor 255,255,255;SetAlpha 1
		EndIf
	End Method
End Type

Type TError
  Field title:String
  Field message:String
  Field id:Int
  Field link:TLink
  Global List:TList = CreateList()
  Global LastID:Int=0

  Function Create:TError(title:String, message:String)
     Local error:TError =  New TError
     error.title = title
     error.message = message
     error.id = LastID
     LastID :+1
     error.link = List.AddLast(error)
     Game.error:+1
     Return error
  End Function

  Function CreateNotEnoughMoneyError()
    TError.Create(Localization.GetString("ERROR_NOT_ENOUGH_MONEY"),Localization.GetString("ERROR_NOT_ENOUGH_MONEY_TEXT"))
  End Function

  Function DrawErrors()
   If Game.error > 0
    If List = Null
	  List = CreateList()
    Else
  	  Local error:TError
	  If List.Count()>0 Then error= TError(List.Last())
      If error <> Null Then error.drawError()
	EndIf
   EndIf
  End Function

  Function UpdateErrors()
   If Game.error > 0
    If List = Null
	  List = CreateList()
    Else
  	  Local error:TError
	  If List.Count()>0 Then error= TError(List.Last())
      If error <> Null Then error.UpdateError()
	EndIf
   EndIf
  End Function

  Method UpdateError()
    If Mousemanager.IsHit(1)
	  If functions.IsIn(MouseX(),MouseY(), 400-Assets.GetSprite("gfx_errorbox").w/2 +6,200-Assets.GetSprite("gfx_errorbox").h/2 +6, Assets.GetSprite("gfx_errorbox").w, Assets.GetSprite("gfx_errorbox").h)
        link.Remove()
	    Game.error :-1
	    MouseManager.resetKey(1)
      Else
	    MouseManager.resetKey(1)
	  EndIf
	EndIf
    MouseManager.resetKey(2)
  End Method

  Function DrawNewError(str:String="unknown error")
		TError(TError.List.Last()).message = str
		TError.DrawErrors()
		Flip 0
  End Function

  Method DrawError()
    SetAlpha 0.5
    SetColor 0,0,0
	DrawRect(20,10,760, 373)
	SetAlpha 1.0
	Game.cursorstate = 0
	SetColor 255,255,255
    Local x:Int = 400-Assets.GetSprite("gfx_errorbox").w/2 +6
    Local y:Int = 200-Assets.GetSprite("gfx_errorbox").h/2 +6
	Assets.GetSprite("gfx_errorbox").Draw(x,y)
	FontManager.GetFont("Default", 15, BOLDFONT).DrawBlock(title, x + 12 + 6, y + 15, Assets.GetSprite("gfx_errorbox").w - 60, 40, 0, 150, 50, 50)
	FontManager.GetFont("Default", 12).DrawBlock(message, x+12+6,y+50,Assets.GetSprite("gfx_errorbox").w-40, Assets.GetSprite("gfx_errorbox").h-60,0,50,50,50)
  End Method
End Type


'Answer - objects for dialogues
Type TDialogueAnswer
	Field _text:String = ""
	Field _leadsTo:Int = 0
	Field _func:String(param:Int)
	Field _funcparam:Int = 0

	field _highlighted:int = 0

	Function Create:TDialogueAnswer (text:String, leadsTo:Int = 0, _func:String(param:Int) = Null, _funcparam:Int = 0)
		Local obj:TDialogueAnswer = New TDialogueAnswer
		obj._text = Text
		obj._leadsTo = leadsTo
		obj._func = _func
		obj._funcparam = _funcparam
		Return obj
	End Function

	Method Update:Int(x:Float, y:Float, w:Float, h:Float, clicked:Int = 0)
		self._highlighted = 0
		If functions.IsIn(MouseX(), MouseY(), x, y, w, FontManager.baseFont.getBlockHeight(Self._text, w, h))
			self._highlighted = 1
			If clicked
				If _func <> Null Then _func(Self._funcparam)
				Return _leadsTo
			EndIf
		EndIf
		Return - 1
	End Method

	Method Draw(x:Float, y:Float, w:Float, h:Float)
		FontManager.getFont("Default", 14).drawBlock(Self._text, x, y, w, h,, 200*self._highlighted, 100*self._highlighted, 100*self._highlighted)
	End Method
End Type

'Texts, maintext + list of answers to this said thing ;D
Type TDialogueTexts
	Field _text:String = ""
	Field _answers:TList = CreateList() 'of TDialogueAnswer
	Field _goTo:Int = -1

	Function Create:TDialogueTexts(text:String)
		Local obj:TDialogueTexts = New TDialogueTexts
		obj._text = Text
		Return obj
	End Function

	Method AddAnswer(answer:TDialogueAnswer)
		Self._answers.AddLast(answer)
	End Method

	Method Update:Int(x:Float, y:Float, w:Float, h:Float, clicked:Int = 0)
		Local ydisplace:Float = FontManager.getFont("Default", 14).drawBlock(Self._text, x, y, w, h)
		ydisplace:+15 'displace answers a bit

		_goTo = -1
		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			Local returnValue:Int = answer.Update(x + 9, y + ydisplace, w - 9, h, clicked)
			If returnValue <> - 1 Then _goTo = returnValue
			ydisplace:+FontManager.getFont("Default", 14).getHeight(answer._text) + 5
		Next
		Return _goTo
	End Method

	Method Draw(x:Float, y:Float, w:Float, h:Float)
		Local ydisplace:Float = FontManager.getFont("Default", 14).drawBlock(Self._text, x, y, w, h)
		ydisplace:+15 'displace answers a bit

		For Local answer:TDialogueAnswer = EachIn(Self._answers)
			DrawOval(x, y + ydisplace + 4, 6, 6)
			answer.Draw(x + 9, y + ydisplace, w - 9, h)
			ydisplace:+FontManager.getFont("Default", 14).getHeight(answer._text) + 5
		Next
	End Method
End Type

Type TDialogue
	Field _texts:TList = CreateList() 'of TDialogueTexts
	Field _currentText:Int = 0
	Field _x:Float, _y:Float
	Field _w:Float, _h:Float

	Function Create:TDialogue(x:Float, y:Float, w:Float, h:Float)
		Local obj:TDialogue = New TDialogue
		obj._x = x
		obj._y = y
		obj._w = w
		obj._h = h
		Return obj
	End Function

	Method AddText(Text:TDialogueTexts)
		Self._texts.AddLast(Text)
	End Method

	Method Update:Int(isMouseHit:Int = 0)
		Local clicked:Int = MouseManager.isHit(1) + MouseManager.IsDown(1)
		If clicked >= 1 Then clicked = 1;MouseManager.resetKey(1)
		Local nextText:Int = _currentText
		If Self._texts.Count() > 0
			Local returnValue:Int = TDialogueTexts(Self._texts.ValueAtIndex(Self._currentText)).Update(_x + 10, _y + 10, _w - 40, _h, clicked)
			If returnValue <> - 1 Then nextText = returnValue
		EndIf
		_currentText = nextText
		If _currentText = -2 Then _currentText = 0;Return 0
		Return 1
	End Method

	Method Draw()
		SetColor 255, 255, 255
	    DrawDialog(Assets.GetSpritePack("gfx_dialog"), _x, _y, _w, _h, "StartLeftDown", 0, "", FontManager.getFont("Default", 14))
		SetColor 0, 0, 0
		If Self._texts.Count() > 0 Then TDialogueTexts(Self._texts.ValueAtIndex(Self._currentText)).Draw(_x + 10, _y + 10, _w - 60, _h)
		SetColor 255, 255, 255
	End Method
End Type


Type TButton
    Field x:Int = 0
    Field y:Int = 0
    Field w:Int = 0
    Field h:Int = 0
    Field id:Int = 0
	Field Sprite:TGW_Sprites
    Field Caption:String = ""
    Field enabled:Int = 1
    Field Clicked:Int = 0
    Field fontr:Int = 100
    Field fontg:Int = 100
    Field fontb:Int = 100
    Global UseFont:TBitmapFont
    Global List:TList

    Method IsIn:Int(_x:Int, _y:Int)
		If _x >= x and _x <= x + w and _y >= y and _y <= y + h
			Return 1
		Else
			Return 0
		EndIf
    End Method

'    Method OnClick() Abstract

    Method Draw(tweenValue:float=1.0)
		local font:TBitmapFont = FontManager.getFont("Default", 10, BOLDFONT)
		local textWidth:int = font.getWidth(Caption)
        If Clicked <> 0
			SetColor(220, 220, 220)
			sprite.Draw(x + 1, y + 1)
			font.drawStyled(Caption, x + w/2 - textWidth/2 +1, y + 43, fontr - 50, fontg - 50, fontb - 50, 1)
    	Else
		  	sprite.Draw(x, y)
			font.drawStyled(Caption, x + w/2 - textWidth/2, y + 42, fontr, fontg, fontb, 1)
    	EndIf
        If Clicked <> 0 then SetColor(255,255,255)
	End Method
End Type





Type TPPbuttons Extends TButton
    Global List:TList

    Function Create:TPPbuttons(sprite:TGW_Sprites, _caption:String = "", x:Int, y:Int, id:Int)
		Local Button:TPPbuttons=New TPPbuttons
		Button.x = x
		Button.y = y
		Button.w = sprite.w
		Button.h = sprite.h
		Button.Sprite = sprite
		Button.Caption = _caption
		Button.enabled = 1
		Button.id = id
		Button.Clicked = 0
		If Not List Then List = CreateList()
		List.AddLast(Button)
		SortList List
		Return Button
    EndFunction

    Function DrawAll()
    	For Local Button:TPPbuttons = EachIn TPPbuttons.List
    		Button.Draw()
    	Next
    End Function

    Function UpdateAll()
    	For Local Button:TPPbuttons = EachIn TPPbuttons.List
    	    If Button.IsIn(MouseX(), MouseY()) And MOUSEMANAGER.IsDown(1)
				Button.Clicked = 1
			Else If Button.Clicked = 1
				Button.OnClick()
				Button.Clicked = 0
			EndIf
    	Next
    End Function

    Method OnClick()
		'close both
		PPcontractList.SetOpen(0)
		PPprogrammeList.SetOpen(0)

		'open others?
		If id = 0 Then PPcontractList.SetOpen(1)	'opens contractlist DebugLog("auf Werbung geklickt")
		If id = 1 Then PPprogrammeList.SetOpen(1)	'opens genrelist  DebugLog("auf Filme geklickt")
		If id = 3 Then Player[Game.playerID].Figure.inRoom = TRooms.GetRoom("financials", Player[Game.playerID].Figure.inRoom.owner)	'shows financials
		If id = 4 Then Player[Game.playerID].Figure.inRoom = TRooms.GetRoom("image", Player[Game.playerID].Figure.inRoom.owner)	'shows image and audiencequotes
    End Method

End Type 'Buttons in ProgrammePlanner

Type TNewsbuttons Extends TButton
    Global List:TList
    Field frameNr:Int =0
    Field genre:Int = 0
	Field owner:Int = 0
	Field clickstate:Int =0
	Field tooltip:TTooltip
	field spriteBaseName:string = ""

    Function Create:TNewsbuttons(frameNr:Int=0,genre:Int=0,_caption:String="", owner:Int=0, x:Int, y:Int, id:Int)
	  Local Button:TNewsbuttons=New TNewsbuttons
		genre = min(max(0,genre), 4)
	  Button.x			= x
	  Button.y			= y
	  Button.spriteBaseName = "gfx_news_btn"+genre
	  Button.w			= Assets.getSprite("gfx_news_btn"+genre).w
	  Button.h			= Assets.getSprite("gfx_news_btn"+genre).h
	  Button.genre		= genre
	  Button.owner		= owner
	  Button.frameNr	= frameNr
	  Button.Caption	= _caption
  	  Button.enabled	= 1
  	  Button.id = id
  	  Button.Clicked	= 0
  	  If Not List Then List = CreateList()
 	  List.AddLast(Button)
 	  SortList List
 	  Return Button
    EndFunction

	Function GetButton:TNewsbuttons(genre:Int, owner:Int)
	  For Local Button:TNewsbuttons = EachIn TNewsbuttons.List
	    If Button.genre = genre And Button.owner = owner Then Return Button
	  Next
	  Return Null
	End Function

	Function DrawAll(tweenValue:float=1.0)
		For Local Button:TNewsbuttons = EachIn TNewsbuttons.List
			If Button.owner = Player[Game.playerID].figure.inRoom.owner then Button.Draw(tweenValue)
    	Next
		'tooltips - later drawn to avoid z-order problems
		For Local Button:TNewsbuttons = EachIn TNewsbuttons.List
			If Button.owner = Player[Game.playerID].figure.inRoom.owner
				if Button.tooltip <> null then Button.tooltip.Draw(tweenValue)
			endif
		Next
	End Function

    Function UpdateAll(deltaTime:float=1.0)
		For Local Button:TNewsbuttons = EachIn TNewsbuttons.List
			If Button.owner = Game.playerID

				If Button.IsIn(MouseX(), MouseY())
					if MOUSEMANAGER.IsDown(1)
						if Button.clicked = 0
							print "set clicked"
							Button.Clicked =1
						endif
					Else if Button.clicked = 1
						print "on click"
						Button.OnClick()
						Button.Clicked = 0
					endif

					If Button.tooltip = Null
						'Min(21) - left<=20 moves tooltip to right side
						Button.tooltip = TTooltip.Create(Button.Caption, "", Max(21,Button.x), Button.y - 20,0,0,1010)
					else
						Button.tooltip.enabled = 1
						Button.tooltip.lifetime = Button.tooltip.startlifetime
					endif
				else
					Button.clicked = 0
				EndIf
			EndIf
			If Button.tooltip<> Null
				If Button.clickstate=0
					Button.tooltip.title = Button.Caption+" - "+Localization.GetString("NEWSSTUDIO_NOT_SUBSCRIBED")
					Button.tooltip.text = Localization.GetString("NEWSSTUDIO_SUBSCRIBE_GENRE_LEVEL")+" 1: "+ (Button.clickstate+1)*10000+"€"
				Else
					Button.tooltip.title = Button.Caption+" - "+Localization.GetString("NEWSSTUDIO_SUBSCRIPTION_LEVEL")+" "+Button.clickstate
					If Button.clickstate=3
						Button.tooltip.text = Localization.GetString("NEWSSTUDIO_DONT_SUBSCRIBE_GENRE_ANY_LONGER")+ "0€"
					Else
						Button.tooltip.text = Localization.GetString("NEWSSTUDIO_NEXT_SUBSCRIPTION_LEVEL")+": "+ (Button.clickstate+1)*10000+ "€"
					EndIf
				EndIf
				Button.tooltip.Update(deltaTime)
			EndIf
		Next
		'tooltips
    End Function

    Method OnClick()
	  self.clickstate:+1
	  If clickstate > 3 Then clickstate =0
	  Player[Game.playerID].newsabonnements[genre] = clickstate
	  If Game.networkgame Then If Network.IsConnected Then Network.SendNewsSubscriptionLevel(Game.playerID, genre, clickstate)
	  Mousemanager.resetKey(1)
    End Method

    Method Draw(tweenValue:float=1.0)
        If self.clicked > 0
			Assets.getSprite(self.spriteBaseName+"_clicked").draw(x,y)
    	Else
			Assets.getSprite(self.spriteBaseName).draw(x,y)
		endif
		SetColor 0,0,0
		SetAlpha 0.4
		For Local i:Int = 0 To clickstate-1
			DrawRect(x+8+i*10, y+ Assets.getSprite(self.spriteBaseName).h -7, 7,4)
		Next
		SetColor 255,255,255
		SetAlpha 1.0
    End Method
End Type 'GenreButtons im Nachrichtenstudio







'Interface, border, TV-antenna, audience-picture and number, watch...
'updates tv-images shown and so on
Type TInterface
  Field gfx_bottomRTT:TImage
  Field ActualProgram:TGW_Sprites
  Field ActualAudience:TImage
  Field ActualNoise:TGW_Sprites
  Field ActualProgramText:String
  Field ActualProgramToolTip:TTooltip
  Field ActualAudienceToolTip:TTooltip
  Field NoiseAlpha:Float	= 0.95
  Field ChangeNoiseTimer:float= 0.0
  Field ShowChannel:Byte 	= 1
  Field BottomImgDirty:Byte = 1
  Global InterfaceList:TList

	'creates and returns an interface
	Function Create:TInterface()
		Local Interface:TInterface = New TInterface
		Interface.ActualNoise			= Assets.GetSprite("gfx_interface_TVprogram_noise1")
		Interface.ActualProgram			= Assets.GetSprite("gfx_interface_TVprogram_none")
		Interface.ActualProgramToolTip	= TTooltip.Create("", "", 40, 395)
		Interface.ActualAudienceToolTip	= TTooltip.Create("", "", 385, 450)
		If Not InterfaceList Then InterfaceList = CreateList()
		InterfaceList.AddLast(Interface)
		SortList InterfaceList
		Return Interface
	End Function

	Method Update(deltaTime:float=1.0)
		GUIManager.Update("InGame")
		If ShowChannel <> 0
			If Game.minute >= 55
				Local contract:TContract = Player[ShowChannel].ProgrammePlan.GetActualContract()
				Interface.ActualProgram = Assets.GetSprite("gfx_interface_TVprogram_ads")
			    If contract <> Null
					ActualProgramToolTip.TitleBGtype 	= 1
					ActualProgramText 					= Localization.GetString("ADVERTISMENT")+": "+contract.title
				Else
					ActualProgramToolTip.TitleBGtype	= 2
					ActualProgramText					= Localization.GetString("BROADCASTING_OUTAGE")
				EndIf
			Else
				Local Programme:TProgramme = Player[ShowChannel].ProgrammePlan.GetActualProgramme()
				Interface.ActualProgram = Assets.GetSprite("gfx_interface_TVprogram_none")
				If Programme <> Null
					Interface.ActualProgram = Assets.GetSprite("gfx_interface_TVprogram_" + Programme.genre, "gfx_interface_TVprogram_none")
					'If Assets.GetSprite("gfx_interface_TVprogram_" + Programme.genre) <> Null Then Interface.ActualProgram = Assets.GetSprite("gfx_interface_TVprogram_" + Programme.genre)
					ActualProgramToolTip.TitleBGtype	= 0
					ActualProgramText					= Programme.title + " ("+Localization.GetString("BLOCK")+" "+(1+Game.GetActualHour()-Programme.sendtime)+"/"+Programme.blocks+")"
				Else
					ActualProgramToolTip.TitleBGtype	= 2
					ActualProgramText 					= Localization.GetString("BROADCASTING_OUTAGE")
				EndIf
			EndIf
			If Game.minute <= 5
				Interface.ActualProgram = Assets.GetSprite("gfx_interface_TVprogram_news")
				ActualProgramToolTip.TitleBGtype	= 3
				ActualProgramText 					= Localization.GetString("NEWS")
			EndIf
		Else
			ActualProgramToolTip.TitleBGtype	= 3
			ActualProgramText 					= Localization.GetString("TV_OFF")
		EndIf 'showchannel <>0
		If ActualProgramToolTip.enabled Then ActualProgramToolTip.Update(deltaTime)
		If ActualAudienceToolTip.enabled Then ActualAudienceToolTip.Update(deltaTime)

		'channel selection (tvscreen on interface)
		If MOUSEMANAGER.IsHit(1)
			For Local i:Int = 0 To 4
				If functions.IsIn(MouseX(), MouseY(), 75 + i * 33, 171 + 383, 33, 41)
					ShowChannel = i
					BottomImgDirty = True
				endif
			Next
		EndIf

		'noise on interface-tvscreen
		ChangeNoiseTimer :+ deltaTime
		If ChangeNoiseTimer >= 0.20
		    Local randomnoise:Int = Rand(0,3)
			If randomnoise = 0 Then ActualNoise = Assets.GetSprite("gfx_interface_TVprogram_noise1")
			If randomnoise = 1 Then ActualNoise = Assets.GetSprite("gfx_interface_TVprogram_noise2")
			If randomnoise = 2 Then ActualNoise = Assets.GetSprite("gfx_interface_TVprogram_noise3")
			If randomnoise = 3 Then ActualNoise = Assets.GetSprite("gfx_interface_TVprogram_noise4")
			ChangeNoiseTimer = 0.0
			NoiseAlpha = 0.45 - (Rand(0,10)*0.01)
		EndIf

		If functions.IsIn(MouseX(),MouseY(),20,385,280,200)
			ActualProgramToolTip.title 		= ActualProgramText
			If ShowChannel <> 0
				ActualProgramToolTip.text	= Localization.GetString("AUDIENCE_RATING")+": "+Player[ShowChannel].GetFormattedAudience()+ "("+Player[ShowChannel].GetAudiencePercentage()+"%)"
			Else
				ActualProgramToolTip.text	= Localization.GetString("TV_TURN_IT_ON")
			EndIf
			ActualProgramToolTip.enabled 	= 1
			ActualProgramToolTip.lifetime	= ActualProgramToolTip.startlifetime
	    EndIf
		If functions.IsIn(MouseX(),MouseY(),385,468,108,30)
			ActualAudienceToolTip.title 	= Localization.GetString("AUDIENCE_RATING")+": "+Player[Game.playerID].GetFormattedAudience()+ " ("+Player[Game.playerID].GetAudiencePercentage()+"%)"
			ActualAudienceToolTip.text  	= Localization.GetString("MAX_AUDIENCE_RATING")+": "+functions.convertValue(Int((Game.maxAudiencePercentage * Player[Game.playerID].maxaudience)),2,0)+ " ("+(Int(Ceil(1000*Game.maxAudiencePercentage)/10))+"%)"
			ActualAudienceToolTip.enabled 	= 1
			ActualAudienceToolTip.lifetime 	= ActualAudienceToolTip.startlifetime
		EndIf
	End Method

	'draws the interface
	Method Draw(tweenValue:float=1.0)
		gfx_interface_topbottom.renderInViewPort(0, - 217, 0, 0, 800, 20)
		Assets.GetSprite("gfx_interface_leftright").DrawClipped(0, 20, 0, 20, 27, 363, 0, 0)
		SetBlend SOLIDBLEND
		Assets.GetSprite("gfx_interface_leftright").DrawClipped(780 - 27, 20, 780, 20, 20, 363, 0, 0)

		If BottomImgDirty
			Local NoDX9moveY:Int = 383
			'RTT ausgeschalten mit 1=2
			If directx <> 2 And 1 = 2
				NoDX9moveY = 0
				BottomImgDirty = False
				If gfx_bottomRTT = Null Then gfx_bottomRTT = tRender.Create(800, 600, 0 | FILTEREDIMAGE)
				tRender.TextureRender_Begin(gfx_bottomRTT, False)
			EndIf
			SetBlend MASKBLEND
			gfx_interface_topbottom.renderInViewPort(0, 0 + NoDX9moveY, 0, 0 + NoDX9moveY, 800, 217)

			If ShowChannel <> 0 Then Assets.GetSprite("gfx_interface_audience_bg").Draw(520, 419 - 383 + NoDX9moveY)
			SetBlend ALPHABLEND
		    For Local i:Int = 0 To 4
				If i = ShowChannel
					Assets.GetSprite("gfx_interface_channelbuttons"+(i+5)).Draw(75 + i * 33, 171 + NoDX9moveY, i)
				Else
					Assets.GetSprite("gfx_interface_channelbuttons"+i).Draw(75 + i * 33, 171 + NoDX9moveY, i)
				EndIf
		    Next
			If ShowChannel <> 0
				'If ActualProgram = Null Then Print "ERROR: ActualProgram is missing"
				ActualProgram.Draw(49, 403 - 383 + NoDX9moveY)

				Local audiencerate:Float	= Float(Player[ShowChannel].audience / Float(Game.maxAudiencePercentage * Player[Game.playerID].maxaudience))
				Local girl_on:Int 			= 0
				Local grandpa_on:Int		= 0
				Local teen_on:Int 			= 0
				If audiencerate > 0.4 And (Game.GetActualHour() < 21 And Game.GetActualHour() > 6) Then girl_on = True
				If audiencerate > 0.1 Then grandpa_on = True
		  		If audiencerate > 0.3 And (Game.GetActualHour() < 2 Or Game.GetActualHour() > 11) Then teen_on = True
				If teen_on And grandpa_on
					Assets.GetSprite("gfx_interface_audience_teen").Draw(570, 419 - 383 + NoDX9moveY)    'teen
					Assets.GetSprite("gfx_interface_audience_grandpa").Draw(650, 419 - 383 + NoDX9moveY)      'teen
				ElseIf grandpa_on And girl_on And Not teen_on
					Assets.GetSprite("gfx_interface_audience_girl").Draw(570, 419 - 383 + NoDX9moveY)      'teen
					Assets.GetSprite("gfx_interface_audience_grandpa").Draw(650, 419 - 383 + NoDX9moveY)       'teen
				Else
					If teen_on Then Assets.GetSprite("gfx_interface_audience_teen").Draw(670, 419 - 383 + NoDX9moveY)
					If girl_on Then Assets.GetSprite("gfx_interface_audience_girl").Draw(550, 419 - 383 + NoDX9moveY)
					If grandpa_on Then Assets.GetSprite("gfx_interface_audience_grandpa").Draw(610, 419 - 383 + NoDX9moveY)
					If Not grandpa_on And Not girl_on And Not teen_on
						SetColor 50, 50, 50
						SetBlend MASKBLEND
						Assets.GetSprite("gfx_interface_audience_bg").Draw(520, 419 - 383 + NoDX9moveY)
						SetColor 255, 255, 255
		    	    EndIf
				EndIf
			EndIf 'showchannel <>0

	  		SetBlend MASKBLEND
	     	Assets.GetSprite("gfx_interface_audience_overlay").Draw(520, 419 - 383 + NoDX9moveY)
			SetBlend ALPHABLEND
			FontManager.getFont("Default", 13, BOLDFONT).drawBlock(Player[Game.playerID].GetFormattedMoney() + "  ", 377, 427 - 383 + NoDX9moveY, 103, 25, 2, 200,230,200, 0, 2)
			FontManager.getFont("Default", 13, BOLDFONT).drawBlock(Player[Game.playerID].GetFormattedAudience() + "  ", 377, 469 - 383 + NoDX9moveY, 103, 25, 2, 200,200,230, 0, 2)
		 	FontManager.getFont("Default", 11, BOLDFONT).drawBlock((Game.day) + ". Tag", 366, 555 - 383 + NoDX9moveY, 120, 25, 1, 180,180,180, 0, 2)
			If directx <> 2 And 1 = 2
				tRender.TextureRender_End()
			EndIf
		EndIf 'bottomimg is dirty
		If directx <> 2 And 1 = 2
			tRender.BackBufferRender_Begin()
			ClipImageToViewport(gfx_bottomRTT, 0, 383, 0, 383, 800, 217)
			tRender.BackBufferRender_End()
		EndIf

		SetBlend ALPHABLEND
		Assets.GetSprite("gfx_interface_antenna").Draw(111,329)

		If ShowChannel <> 0
			SetAlpha NoiseAlpha
			If ActualNoise = Null Then Print "ERROR: ActualNoise is missing"
			ActualNoise.Draw(50, 404)
			SetAlpha 1.0
		EndIf
		SetAlpha 0.25
		FontManager.getFont("Default", 13, BOLDFONT).drawBlock(Game.GetFormattedTime() + " Uhr", 366, 542, 120, 25, 1, 180, 180, 180)
		SetAlpha 0.9
		FontManager.getFont("Default", 13, BOLDFONT).drawBlock(Game.GetFormattedTime()+ " Uhr", 365,541,120,25,1, 40,40,40)
		SetAlpha 1.0
   		ActualProgramToolTip.Draw()
	    ActualAudienceToolTip.Draw()
	    GUIManager.Draw("InGame")

		If Game.error >=1 Then TError.DrawErrors()
		If Game.cursorstate = 0 Then DrawImage(gfx_mousecursor, MouseX()-7, MouseY(),0)
		If Game.cursorstate = 1 Then DrawImage(gfx_mousecursor, MouseX()-7, MouseY()-4,1)
		If Game.cursorstate = 2 Then DrawImage(gfx_mousecursor, MouseX() - 10, MouseY() - 12, 2)
	End Method

End Type








'----stations
'Stationmap
''provides the option to buy new stations
''functions are calculation of audiencesums and drawing of stations



Type TStation
 Field x:Int
 Field y:Int
 Field reach:Int=0
 Field price:Int
 Field owner:Int = 0
 Field id:Int = 0
 Global _lastID:Int = 0


 Function Create:TStation(x:Int,y:Int, reach:Int, price:Int, owner:Int)
 	Local _Station:TStation = New TStation
 	_Station.x = x
 	_Station.y = y
 	_Station.reach = reach
 	_Station.price = price
 	_Station.owner = owner
	_Station.id = _Station.GetNewID()
	Return _Station
 End Function

	Method GetNewID:Int()
	 	Self._lastID:+1
		Return Self._lastID
	End Method

	Function GetPrice:Int(summe:Int)
		Return Max(15000, Int(Ceil(summe / 10000)) * 25000)
	End Function

  Function Load:TStation(pnode:xmlNode)
	Local station:TStation= New TStation
		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(Station)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "extra" And Upper(t.name()) = NODE.name
					t.Set(Station, nodevalue)
				EndIf
			Next
			Node = Node.NextSibling()
		Wend
	Return station
  End Function


	Method Save()
		LoadSaveFile.xmlBeginNode("STATION")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "extra" Then LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
			Next
		LoadSaveFile.xmlCloseNode()
  End Method

	Method Draw()
		Local antennaNr:string = ""
		Local radius:Int = StationMap.radius
		SetAlpha 0.3
		Select owner
			Case 1 SetColor 200, 40, 40;antennaNr = "stationmap_antenna1"
			Case 2 SetColor 40, 200, 40;antennaNr = "stationmap_antenna2"
			Case 3 SetColor 100, 100, 200;antennaNr = "stationmap_antenna3"
			Case 4 SetColor 200, 200, 0 ;antennaNr = "stationmap_antenna4"
			Default SetColor 255, 255, 255;antennaNr = "stationmap_antenna"
		End Select
		DrawOval(x - radius + 20, y - radius + 10, 2 * radius, 2 * radius)
		SetColor 255,255,255
		SetAlpha 1.0
		Assets.GetSprite(antennaNr).Draw(x + 20 - Assets.GetSprite(antennaNr).w / 2, y + 10 + radius - Assets.GetSprite(antennaNr).h - 2)
	End Method


End Type

Type TStationPoint
	Field x:Int, y:Int, color:Int
	Function Create:TStationPoint(x:Int, y:Int, color:Int)
		Local obj:TStationPoint = New TStationPoint
		obj.x = x
		obj.y = y
		obj.color = color
		Return obj
	End Function
End Type

Type TStationMap
	Field StationList:TList=CreateList()
	Field radius:Int = 15 {saveload = "normal"}
	Field owner:TPlayer {saveload = "extra"}
	Field einwohner:Int = 0 {saveload = "normal"}
	Field LastStationX:Int = 0 {saveload = "normal"}
	Field LastStationY:Int = 0 {saveload = "normal"}
	Field summe:Int = 0 {saveload = "normal"}
	Field action:Int = 0 {saveload = "normal"}		'2= station buying (another click on the map buys the station)
						  							'1= searching a station
	Field pixmaparray:Int[stationmap_mainpix.width + 20, stationmap_mainpix.height + 20]
	Field bundesland:String = "" {saveload = "normal"}	'mouse over state
	Global List:TList = CreateList()
	Global LastCalculatedAudienceSum:Int = -10 {saveload = "normal"}
	Global LastCalculatedAudienceIncrease:Int = 0 {saveload = "normal"}
	Field outsideLand:Int = 0

	Field sellStation:TStation[5]
	Field buyStation:TStation[5]
	Field ShowStations:Int[5]
	Field StationShare:Int[4, 3]

	Function Load:TStationmap(pnode:xmlNode)
		Local StationMap:TStationMap = New TStationMap
		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(StationMap)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" And Upper(t.name()) = NODE.name
					t.Set(StationMap, nodevalue)
				EndIf
			Next
			Select NODE.name
				Case "OWNERPLAYERID"
								Local owner:Int = Int(nodevalue)
								If owner >= 0
									If Player[owner] <> Null Then
										StationMap.owner = Player[owner]
									Else
										StationMap.owner = Null
									EndIf
								EndIf
				Case "STATION"
							    Local station:TStation = TStation.Load(NODE)
		    					If station <> Null Then PrintDebug("TStationmap.load()", "Station zur Stationmap hinzugefuegt", DEBUG_SAVELOAD) ;StationMap.StationList.AddLast(station)
			End Select
			NODE = NODE.nextSibling()
		Wend
  End Function

	Function LoadAll()
		PrintDebug("TStationMap.LoadAll()", "Lade StationMaps", DEBUG_SAVELOAD)
		TStationMap.List.Clear()
		Local Children:TList = LoadSaveFile.NODE.ChildList
		For Local node:xmlNode = EachIn Children
			If NODE.name = "STATIONMAP"
			      TStationMap.Load(NODE)
			End If
		Next
	End Function

	Function SaveAll()
		LoadSaveFile.xmlBeginNode("ALLSTATIONMAPS")
			For Local StationMap:TStationMap = EachIn TStationMap.List
				LoadSaveFile.xmlBeginNode("STATIONMAP")
'					LoadSaveFile.xmlWrite("LASTCALCULATEDAUDIENCESUM", TStationMap.LastCalculatedAudienceSum)
'					LoadSaveFile.xmlWrite("LASTCALCULATEDAUDIENCEINCREASE", TStationMap.LastCalculatedAudienceIncrease)
		 			Local typ:TTypeId = TTypeId.ForObject(StationMap)
					For Local t:TField = EachIn typ.EnumFields()
						If t.MetaData("saveload") = "normal" Then LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(StationMap)))
					Next
					Local OwnerPlayerID:Int = -1;If StationMap.owner <> Null Then OwnerPlayerID = StationMap.owner.playerID
					LoadSaveFile.xmlWrite("OWNERPLAYERID", OwnerPlayerID)
					For Local station:TStation = EachIn StationMap.StationList
						If station <> Null Then station.Save()
					Next
				LoadSaveFile.xmlCloseNode()
		    Next
		LoadSaveFile.xmlCloseNode()
	End Function

  Function Create:TStationMap()
	Local _StationMap:TStationMap=New TStationMap

	'read all inhabitants of the map
	DebugLog MilliSecs()
	For Local i:Int = 0 To stationmap_mainpix.width-1
	  For Local j:Int = 0 To stationmap_mainpix.height-1
	    _StationMap.pixmaparray[i, j] = ReadPixel(stationmap_mainpix, i, j)
		Local r:Int = ARGB_Red(_StationMap.pixmaparray[i, j])
		Local g:Int = ARGB_Green(_StationMap.pixmaparray[i,j])
		Local b:Int = ARGB_Blue(_StationMap.pixmaparray[i,j])
		Local helligkeit:Int = (r+g+b) / 3
		If helligkeit >= 245 helligkeit = 255
		helligkeit = 255 - helligkeit
		If helligkeit > 200 Then helligkeit:*6.5
		_StationMap.einwohner:+9.5 * (helligkeit)
	  Next
	Next
	DebugLog "StationMap: alle Pixel eingelesen - Einwohner:" + _StationMap.einwohner
    If not List Then List = CreateList()
 	List.AddLast(_StationMap)
    SortList List
    Return _StationMap
  End Function

	Method AddStation(x:Int, y:Int, playerid:Int, valuetorefresh:Int Var)
		Local reach:Int = Self.CalculateAudienceIncrease(playerid, x, y)
		StationList.AddLast(TStation.Create(x, y, reach, TStation.GetPrice(reach), playerid))
		valuetorefresh = CalculateAudienceSum(playerid)
	End Method

    Method Buy(x:Float, y:Float, playerid:Int = 1)
		If Player[playerid].finances[TFinancials.GetDayArray(Game.day)].PayStation(TStation.GetPrice(summe))
			Local station:TStation = TStation.Create(LastStationX, LastStationY, summe, TStation.GetPrice(summe), playerid)
			StationList.AddLast(station)
			Print "Player" + playerid + " kauft Station für " + station.price + " Euro (" + station.reach + " Einwohner)"
			Player[playerid].maxaudience = CalculateAudienceSum(Game.playerID) 'auf entsprechenden Player umstellen
			'network
			if game.networkgame Then if Network.IsConnected Then Network.SendStationChange(game.playerid, station, Player[game.playerID].maxaudience,1)
			summe = 0
			Self.buyStation[playerid] = Null
		EndIf
    End Method


	Method Sell(station:TStation)
		If Player[station.owner].finances[TFinancials.GetDayArray(Game.day)].SellStation(Floor(station.price * 0.75))
			StationList.Remove(station)
	        Print "Player" + station.owner + " verkauft Station für " + TStation.GetPrice(Floor(station.price * 0.75)) + " Euro (" + station.reach + " Einwohner)"
			Player[station.owner].maxaudience = CalculateAudienceSum(station.owner) 'auf entsprechenden Player umstellen
			'network
			If Game.networkgame Then If Network.IsConnected Then Network.SendStationChange(station.owner, station, Player[station.owner].maxaudience, 0)
			summe = 0
			'when station is sold, audience will decrease, atm buy =/= increase ;D
			Player[station.owner].ComputeAudience(1)
		EndIf
    End Method

	Method CalculateStationCosts:Int(owner:Int=0)
		Local costs:Int = 0
		For Local Station:TStation = EachIn StationList
			If station.owner = owner Then costs:+1000 * Ceil(station.price / 50000) ' price / 50 = cost
		Next
		Return costs
	End Method



	Method Update()
		If action = 4 'sell finished?
			If Self.sellStation[Game.playerID] <> Null Then Self.Sell(Self.sellStation[Game.playerID])
			action = 0
		End If
		'buying stations
		If action = 1 'searching
			Local newsumme:Int = 0
			Local posX:Int, posY:Int
			If MOUSEMANAGER.MousePosChanged
				posX = MouseX()
				posY = MouseY()
				newsumme = Self.CalculateStationRange(posX, posY, radius, 20, 10, PixmapWidth(stationmap_mainpix), PixmapHeight(stationmap_mainpix))
			Else
				posX = LastStationX + 20
				posY = LastStationY + 10
			EndIf
			If newsumme > 0
				Self.outsideLand = False 'no antennagraphic in foreign countries
				summe = newsumme
				LastCalculatedAudienceIncrease = CalculateAudienceIncrease(Game.playerid, posX - 20, posY - 10)
			EndIf
			If summe = 0
				posX = LastStationX + 20
				posY = LastStationY + 10
				Self.outsideLand = True
				summe = Self.CalculateStationRange(posX, posY, radius, 20, 10, PixmapWidth(stationmap_mainpix), PixmapHeight(stationmap_mainpix))
'				LastCalculatedAudienceIncrease = CalculateAudienceIncrease(Game.playerid, posX - 20, posY - 10)
			End If
		End If
		If action = 2 And LastStationX <> 0 And LastStationX <> 0
			If MOUSEMANAGER.MousePosChanged Then summe = Self.CalculateStationRange(LastStationX + 20, LastStationY + 10, radius, 20, 10, PixmapWidth(stationmap_mainpix), PixmapHeight(stationmap_mainpix))
			Buy(LastStationX, LastStationY, Game.playerID)
			LastStationX = 0
			LastStationY = 0
			action = 0
		EndIf

	ResetCollisions(3)
	If functions.IsIn(MouseX(), MouseY(), 207, 91, Assets.GetSprite("gfx_officepack_topo_bremen").w, Assets.GetSprite("gfx_officepack_topo_bremen").h)
		CollideImage(stationmap_land_bremen, 207, 91, 0, 0, 1, stationmap_land_bremen)
	Else If functions.IsIn(MouseX(), MouseY(), 452, 118, Assets.GetSprite("gfx_officepack_topo_berlin").w, Assets.GetSprite("gfx_officepack_topo_berlin").h)
		CollideImage(stationmap_land_berlin, 452, 118, 0, 0, 1, stationmap_land_berlin)
	Else If functions.IsIn(MouseX(), MouseY(), 270, 69, Assets.GetSprite("gfx_officepack_topo_hamburg").w, Assets.GetSprite("gfx_officepack_topo_hamburg").h)
		CollideImage(stationmap_land_hamburg, 270, 69, 0, 0, 1, stationmap_land_hamburg)
	Else If functions.IsIn(MouseX(), MouseY(), 129, 258, Assets.GetSprite("gfx_officepack_topo_bawue").w, Assets.GetSprite("gfx_officepack_topo_bawue").h)
		CollideImage(stationmap_land_bawue, 129, 258, 0, 0, 1, stationmap_land_bawue)
	Else If functions.IsIn(MouseX(), MouseY(), 223, 221, Assets.GetSprite("gfx_officepack_topo_bayern").w, Assets.GetSprite("gfx_officepack_topo_bayern").h)
		CollideImage(stationmap_land_bayern, 223, 221, 0, 0, 1, stationmap_land_bayern)
	Else If functions.IsIn(MouseX(), MouseY(), 69, 263, Assets.GetSprite("gfx_officepack_topo_saarland").w, Assets.GetSprite("gfx_officepack_topo_saarland").h)
		CollideImage(stationmap_land_saarland, 69, 263, 0, 0, 1, stationmap_land_saarland)
	Else If functions.IsIn(MouseX(), MouseY(), 59, 203, Assets.GetSprite("gfx_officepack_topo_rheinlandpfalz").w, Assets.GetSprite("gfx_officepack_topo_rheinlandpfalz").h)
		CollideImage(stationmap_land_rheinlandpfalz, 59, 203, 0, 0, 1, stationmap_land_rheinlandpfalz)
	Else If functions.IsIn(MouseX(), MouseY(), 155, 169, Assets.GetSprite("gfx_officepack_topo_hessen").w, Assets.GetSprite("gfx_officepack_topo_hessen").h)
		CollideImage(stationmap_land_hessen, 155, 169, 0, 0, 1, stationmap_land_hessen)
	Else If functions.IsIn(MouseX(), MouseY(), 276, 169, Assets.GetSprite("gfx_officepack_topo_thueringen").w, Assets.GetSprite("gfx_officepack_topo_thueringen").h)
		CollideImage(stationmap_land_thueringen, 276, 169, 0, 0, 1, stationmap_land_thueringen)
	Else If functions.IsIn(MouseX(), MouseY(), 388, 167, Assets.GetSprite("gfx_officepack_topo_sachsen").w, Assets.GetSprite("gfx_officepack_topo_sachsen").h)
		CollideImage(stationmap_land_sachsen, 388, 167, 0, 0, 1, stationmap_land_sachsen)
	Else If functions.IsIn(MouseX(), MouseY(), 314, 103, Assets.GetSprite("gfx_officepack_topo_sachsenanhalt").w, Assets.GetSprite("gfx_officepack_topo_sachsenanhalt").h)
		CollideImage(stationmap_land_sachsenanhalt, 314, 103, 0, 0, 1, stationmap_land_sachsenanhalt)
	Else If functions.IsIn(MouseX(), MouseY(), 104, 61, Assets.GetSprite("gfx_officepack_topo_niedersachsen").w, Assets.GetSprite("gfx_officepack_topo_niedersachsen").h)
		CollideImage(stationmap_land_niedersachsen, 104, 61, 0, 0, 1, stationmap_land_niedersachsen)
	Else If functions.IsIn(MouseX(), MouseY(), 213, 12, Assets.GetSprite("gfx_officepack_topo_schleswigholstein").w, Assets.GetSprite("gfx_officepack_topo_schleswigholstein").h)
		CollideImage(stationmap_land_schleswigholstein, 213, 12, 0, 0, 1, stationmap_land_schleswigholstein)
	Else If functions.IsIn(MouseX(), MouseY(), 359, 78, Assets.GetSprite("gfx_officepack_topo_brandenburg").w, Assets.GetSprite("gfx_officepack_topo_brandenburg").h)
		CollideImage(stationmap_land_brandenburg, 359, 78, 0, 0, 1, stationmap_land_brandenburg)
	Else If functions.IsIn(MouseX(), MouseY(), 55, 127, Assets.GetSprite("gfx_officepack_topo_nrw").w, Assets.GetSprite("gfx_officepack_topo_nrw").h)
		CollideImage(stationmap_land_nrw, 55, 127, 0, 0, 1, stationmap_land_nrw)
	Else If functions.IsIn(MouseX(), MouseY(), 318, 21, Assets.GetSprite("gfx_officepack_topo_meckpom").w, Assets.GetSprite("gfx_officepack_topo_meckpom").h)
		CollideImage(stationmap_land_meckpom, 318, 21, 0, 0, 1, stationmap_land_meckpom)
	EndIf
    If action = 1 'placing a new station
      Local Collision_Layer:Int=1
	  Local p:Object[]=CollideImage(gfx_collisionpixel,MouseX(),MouseY(),0,Collision_Layer,0)
	  Bundesland = ""
  	  For Local i:TImage=EachIn p
	    Select i
	    Case stationmap_land_bremen				bundesland="Bremen"
	    Case stationmap_land_berlin		  		bundesland="Berlin"
	    Case stationmap_land_hamburg			bundesland="Hamburg"
	    Case stationmap_land_bawue				bundesland="Baden-Wuerttemberg"
	    Case stationmap_land_bayern				bundesland="Bayern"
	    Case stationmap_land_saarland			bundesland="Saarland"
	    Case stationmap_land_rheinlandpfalz		bundesland="Rheinland-Pfalz"
	    Case stationmap_land_hessen				bundesland="Hessen"
	    Case stationmap_land_thueringen			bundesland="Thueringen"
	    Case stationmap_land_sachsen			bundesland="Sachsen"
	    Case stationmap_land_sachsenanhalt		bundesland="Sachsen-Anhalt"
	    Case stationmap_land_niedersachsen		bundesland="Niedersachsen"
	    Case stationmap_land_schleswigholstein	bundesland="Schleswig-Holstein"
	    Case stationmap_land_brandenburg bundesland = "Brandenburg"
	    Case stationmap_land_nrw				bundesland="Nordrheinwestfahlen"
	    Case stationmap_land_meckpom			bundesland="Mecklenburg Vorpommern"
	    End Select
	  Next
	EndIf

  End Method

	Method DrawStations()
		For Local _Station:TStation = EachIn StationList
			If Self.ShowStations[_Station.owner] Then _Station.Draw()
		Next
		If LastStationX <> 0 and LastStationY <> 0
			SetAlpha 0.3
			SetColor 0,0,0 'replace with a playercolor
			DrawOval(  LastStationX+20- radius +1, LastStationY+10-radius,2*radius,2*radius +1)
			SetAlpha 0.5
			SetColor 255,255,255 'replace with a playercolor
			DrawOval(  LastStationX+20- radius, LastStationY+10-radius,2*radius,2*radius )
			SetAlpha 0.9
			DrawImage(Assets.GetImage("stationmap_antenna"), LastStationX+20-radius+ (2*radius - ImageWidth(Assets.GetImage("stationmap_antenna")))/2,LastStationY+10+radius-ImageHeight(Assets.GetImage("stationmap_antenna"))-2)
			SetAlpha 1.0
		EndIf
	End Method

  Method Draw()
	SetColor 255,255,255
	DrawStations()
    If action = 1 And Not Self.outsideLand 'placing a new station
  	  SetAlpha 0.5
	  DrawOval( MouseX()- radius,MouseY()-radius,2*radius,2*radius )
	  DrawImage( gfx_collisionpixel,MouseX(),MouseY())
      SetAlpha 0.9
	  DrawImage(Assets.GetImage("stationmap_antenna"),(2*radius - ImageWidth(Assets.GetImage("stationmap_antenna")))/2 + MouseX()-radius,MouseY()+radius-ImageHeight(Assets.GetImage("stationmap_antenna"))-2)
	  SetAlpha 1.0
    EndIf

    If action = 1 Then
  	  SetColor(0, 0, 0)
  	  FontManager.baseFont.Draw(bundesland, 595, 35)
  	  FontManager.baseFont.Draw("Reichweite: ", 595, 52) ;FontManager.baseFont.DrawBlock(functions.convertValue(String(summe), 2, 0), 660, 52, 102, 20, 2)
  	  FontManager.baseFont.Draw("Zuwachs: ", 595, 69) ;FontManager.baseFont.DrawBlock(functions.convertValue(String(LastCalculatedAudienceIncrease - LastCalculatedAudienceSum), 2, 0), 660, 69, 102, 20, 2)
  	  FontManager.baseFont.Draw("Preis: ", 595, 86) ; FontManager.GetFont("Default", 11, BOLDFONT).DrawBlock(functions.convertValue(TStation.GetPrice(summe), 2, 0), 660, 86, 102, 20, 2)
  	  SetColor(180, 180, 255)
	  FontManager.baseFont.Draw(bundesland, 594, 34)
 	  SetColor(255,255,255)
 	EndIf

	If Self.sellStation[Game.playerID] <> Null
		SetColor(0, 0, 0)
		FontManager.baseFont.Draw("Reichweite: ", 595, 197) ;FontManager.baseFont.DrawBlock(functions.convertValue(Self.sellStation[Game.playerID].reach, 2, 0), 660, 197, 102, 20, 2)
		FontManager.baseFont.Draw("Preis: ", 595, 214) ; FontManager.GetFont("Default", 11, BOLDFONT).DrawBlock(functions.convertValue(Self.sellStation[Game.playerID].price, 2, 0), 660, 214, 102, 20, 2)
		SetColor(255, 255, 255)
	EndIf
  End Method

	'summary: returns calculated distance between 2 points
	Method calculateDistance:Double(x1:Int, y1:Int, x2:Int, y2:Int)
	  	Local DiffX:Float = Abs(x1 - x2)
	  	Local DiffY:Float = Abs(y1 - y2)
		Return Sqr((DiffX * DiffX) + (DiffY * DiffY))
	End Method

	Method CalculateShareNOTFINISHED:Int(playerA:Int, playerB:Int)
		Local Points:TMap = New TMap
		Local PointsA:TMap = New TMap
		Local PointsB:TMap = New TMap
		Local returnValue:Int = 0
        Local x:Int = 0, y:Int = 0, posX:Int = 0, posY:Int = 0

		'add Stations of both players to their corresponding map
		For Local _Station:TStation = EachIn StationList
			If _Station.owner = playerA Or _Station.owner = playerB
				For posX = _Station.x - radius To _Station.x + radius
					For posY = _Station.y - radius To _Station.y + radius
						' noch innerhalb des Kreises?
						If Sqr((posX - _Station.x) ^ 2 + (posY - _Station.y) ^ 2) <= radius
							If _Station.owner = playerA
								pointsA.Insert(String((posX - x) + "," + (posY - y)), TStationPoint.Create((posX - x) , (posY - y), ARGB_Color(255, 255, 255, 255)))
							Else
								pointsB.Insert(String((posX - x) + "," + (posY - y)), TStationPoint.Create((posX - x) , (posY - y), ARGB_Color(255, 255, 255, 255)))
							EndIf
						End If
					Next
				Next
			End If
		Next
		'combine both maps
		For Local point:String = EachIn pointsA.Keys()
			Local obj:Object = pointsB.ValueForKey(point)
			If obj <> Null
				points.Insert(point, obj)
			EndIf
		Next

		Local pixel:Int
		Local r:Int
		Local g:Int
		Local b:Int
		Local helligkeit:Int

		For Local point:TStationPoint = EachIn points.Values()
			If ARGB_Red(point.color) = 0 And ARGB_Blue(point.color) = 255
				pixel = pixmaparray[point.x, point.y]
				r = ARGB_Red(pixel)
				g = ARGB_Green(pixel)
				b = ARGB_Blue(pixel)

				helligkeit = (r + g + b) / 3
				If helligkeit >= 245 Then helligkeit = 255
				helligkeit = 255 - helligkeit
				If helligkeit > 200 Then helligkeit = helligkeit * 6.5
				returnvalue:+9.5 * (helligkeit)
			EndIf
		Next
	'	Print (MilliSecs() - start) + "ms"
		Return returnvalue
	End Method

	Method CalculateAudienceIncrease:Int(owner:Int = 0, _x:Int, _y:Int)
		Local start:Int = MilliSecs()
		Local Points:TMap = New TMap
		Local returnValue:Int = 0
        Local x:Int = 0, y:Int = 0, posX:Int = 0, posY:Int = 0

		'add "new" station which may be bought
		If _x = 0 And _y = 0 Then _x = MouseX() - 20; _y = MouseY() - 10
	    For posX =  _x - radius To _x + radius
			For posY = _y - radius To _y + radius
				' noch innerhalb des Bildes?
				If posX >= x And posX < x + stationmap_mainpix.width And posY >= y And posY < y + stationmap_mainpix.height Then
					' noch innerhalb des Kreises?
					If Sqr((posX - _x) ^ 2 + (posY - _y) ^ 2) <= radius
						points.Insert(String((posX - x) + "," + (posY - y)), TStationPoint.Create((posX - x) , (posY - y), ARGB_Color(255, 0, 255, 255)))
					End If
				End If
			Next
		Next

		'overwrite with stations owner already has - red pixels get overwritten with white,
		'count red at the end for increase amount
		For Local _Station:TStation = EachIn StationList
			If _Station.owner = owner
				If _x > _station.x - 2 * radius And _x < _station.x + 2 * radius And _y > _station.y - 2 * radius And _y < _station.y + 2 * radius
					For posX = _Station.x - radius To _Station.x + radius
						For posY = _Station.y - radius To _Station.y + radius
							' noch innerhalb des Bildes?
							If posX >= x And posX < x + stationmap_mainpix.width And posY >= y And posY < y + stationmap_mainpix.height Then
								' noch innerhalb des Kreises?
								If Sqr((posX - _Station.x) ^ 2 + (posY - _Station.y) ^ 2) <= radius
									points.Insert(String((posX - x) + "," + (posY - y)), TStationPoint.Create((posX - x) , (posY - y), ARGB_Color(255, 255, 255, 255)))
								End If
							End If
						Next
					Next
				EndIf
			End If
		Next

		Local pixel:Int
		Local r:Int
		Local g:Int
		Local b:Int
		Local helligkeit:Int

		For Local point:TStationPoint = EachIn points.Values()
			If ARGB_Red(point.color) = 0 And ARGB_Blue(point.color) = 255
				pixel = pixmaparray[point.x, point.y]
				r = ARGB_Red(pixel)
				g = ARGB_Green(pixel)
				b = ARGB_Blue(pixel)

				helligkeit = (r + g + b) / 3
				If helligkeit >= 245 Then helligkeit = 255
				helligkeit = 255 - helligkeit
				If helligkeit > 200 Then helligkeit = helligkeit * 6.5
				returnvalue:+9.5 * (helligkeit)
			EndIf
		Next
	'	Print (MilliSecs() - start) + "ms"
		Return returnvalue
	End Method

	'summary: returns maximum audience a player has
	Method CalculateAudienceSum:Int(owner:Int = 0)
		Local start:Int = MilliSecs()
		Local Points:TMap = New TMap
        Local x:Int = 0, y:Int = 0, posX:Int = 0, posY:Int = 0
		For Local _Station:TStation = EachIn StationList
			If _Station.owner = owner
				For posX = _Station.x - radius To _Station.x + radius
					For posY = _Station.y - radius To _Station.y + radius
						' noch innerhalb des Bildes?
						If posX >= x And posX < x + stationmap_mainpix.width And posY >= y And posY < y + stationmap_mainpix.height
							'noch innerhalb des Kreises?
					  		If Sqr((posX - _Station.x) ^ 2 + (posY - _Station.y) ^ 2) <= radius
								points.Insert(String((posX - x) + "," + (posY - y)), TStationPoint.Create((posX - x) , (posY - y), ARGB_Color(255, 255, 255, 255)))
							End If
						End If
					Next
				Next
			End If
		Next
		Local pixel:Int
		Local r:Int
		Local g:Int
		Local b:Int
		Local helligkeit:Int
		Local returnvalue:Int = 0

		For Local point:TStationPoint = EachIn points.Values()
			If ARGB_Red(point.color) = 255 And ARGB_Blue(point.color) = 255
				pixel = pixmaparray[point.x, point.y]
				r = ARGB_Red(pixel)
				g = ARGB_Green(pixel)
				b = ARGB_Blue(pixel)

				helligkeit = (r + g + b) / 3
				If helligkeit >= 245 Then helligkeit = 255
				helligkeit = 255 - helligkeit
				If helligkeit > 200 Then helligkeit = helligkeit * 6.5
				returnvalue:+9.5 * (helligkeit)
			EndIf
		Next
	'	Print (MilliSecs() - start) + "ms für CalculateAudienceSum"
		Return returnvalue
	End Method

	'summary: returns a stations maximum audience reach
	Method CalculateStationRange:Int(mausX:Int, mausY:Int, radius:Int, x:Int, y:Int, width:Int, height:Int)
		Local r:Int, g:Int, b:Int
		Local helligkeit:Int
		Local posX:Int, posY:Int
		Local pixel:Int
		Local returnValue:Int = 0
		' für die aktuelle Koordinate die summe berechnen
		For posX = mausX - radius To mausX + radius
			For posY = mausY - radius To mausY + radius
			' noch innerhalb des Bildes?
				If posX >= x and posX < width and posY >= y and posY < Height
					' noch innerhalb des Kreises?
					If Sqr((posX - mausX) ^ 2 + (posY - mausY) ^ 2) <= radius
						If posX < width and posY < Height
						    pixel = StationMap.pixmaparray[posX - x, posY - y]
						    r = ARGB_Red(pixel)
						    g = ARGB_Green(pixel)
						    b = ARGB_Blue(pixel)
						    helligkeit = (r+g+b) / 3
						    If helligkeit >= 245 Then helligkeit = 255
						    helligkeit = 255 - helligkeit
						    If helligkeit > 200 Then helligkeit:*6.5
						    returnValue:+9.5 * (helligkeit)
						EndIf
					End If
				End If
			Next
		Next
		Return returnValue
	End Method

End Type
