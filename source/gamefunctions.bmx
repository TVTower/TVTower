
Type TSaveFile
  Field xml:TXmlHelper
  Field node:TxmlNode
  Field currentnode:TxmlNode
  Field Nodes:TxmlNode[10]
  Field NodeDepth:Int = 0
  Field lastNode:TxmlNode

  Function Create:TSaveFile()
  	Local tmpobj:TSaveFile = New TSaveFile
	Return tmpobj
  End Function

  Method InitSave()
	self.xml		= new TXmlHelper
	self.xml.file	= TxmlDoc.newDoc("1.0")
	Self.xml.root 	= TxmlNode.newNode("tvtsavegame")
	self.xml.file.setRootElement(self.xml.root)
    Self.Nodes[0]	= xml.root
	Self.lastNode	= xml.root
  End Method

	Method InitLoad(filename:String="save.xml", zipped:Byte=0)
		self.xml		= new TXmlHelper
		self.xml.file	= TxmlDoc.parseFile(filename)
		Self.xml.root	= xml.file.getRootElement()
		Self.node		= Self.xml.root
	End Method

	Method xmlWrite(typ:String="unknown",str:String, newDepth:Byte=0, depth:Int=-1)
		If depth <=-1 Or depth >=10 Then depth = Self.NodeDepth ';newDepth=False
		If newDepth
			Self.Nodes[Self.NodeDepth+1] = Self.Nodes[depth].addChild( typ )
			Self.Nodes[Self.NodeDepth+1].addAttribute("var", str)
			Self.NodeDepth:+1
		Else
			Self.Nodes[depth].addChild( typ ).addAttribute("var", str)
		EndIf
	End Method

	Method xmlCloseNode()
		Self.NodeDepth:-1
	End Method

	Method xmlBeginNode(str:String)
		Self.Nodes[Self.NodeDepth + 1] = Self.Nodes[Self.NodeDepth].AddChild( str )
		Self.NodeDepth:+1
	End Method

	Method xmlSave(filename:String="-", zipped:Byte=0)
		If filename = "-" Then Print "nodes:"+Self.xml.root.getChildren().count() Else Self.xml.file.saveFile(filename)
	End Method

	'Summary: saves an object to defined XMLstream
	Method SaveObject:Int(obj:Object, nodename:String, _addfunc(obj:Object))
		Local result:String = ""
	    Self.xmlBeginNode(nodename)
			'list of objects as obj-param - iterate through all listobjects
			If TList(obj) <> Null
				For Local listobj:Object = EachIn TList(obj)
					SaveObject(listobj, nodename + "_CHILD", _addfunc)
				Next
			Else
				Local typ:TTypeId = TTypeId.ForObject(obj)
				For Local t:TField = EachIn typ.EnumFields()
					If t.MetaData("sl") <> "no"
						local fieldtype:TTypeId = TTypeId.ForObject(t.get(obj))
						If fieldtype.ExtendsType(ArrayTypeId)
							If fieldtype.ArrayLength(typ) > 0
								Print "array '" + t.Name() + " - " + fieldtype.Name() + "'"
							EndIf
						End If
						If TList(t.Get(obj)) <> Null
							Local liste:TList = TList(t.Get(obj))
							For Local childobj:Object = EachIn liste
								Print "saving list children..."
								Self.SaveObject(childobj, nodename + "_CHILD", _addfunc)
							Next
						Else
							Self.xmlWrite(Upper(t.name()), String(t.Get(obj)))
						End If
					EndIf
				Next
				If _addfunc <> Null Then _addfunc(obj)
			EndIf
		Self.xmlCloseNode()
	End Method

	'Summary: loads an object from a XMLstream
	Method LoadObject:Object(obj:Object, _handleNodefunc(_obj:Object, _node:txmlnode))
print "implement LoadObject"
return null
rem
		Local NODE:txmlNode = Self.NODE.FirstChild()
		Local nodevalue:String
		While NODE <> Null
			nodevalue = ""
			If NODE.hasAttribute("var", False) Then nodevalue = Self.NODE.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(obj)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("sl") <> "no" And Upper(t.name()) = NODE.name
					t.Set(obj, nodevalue)
				EndIf
			Next
			Self.NODE = Self.NODE.nextSibling()
			If _handleNodefunc <> Null Then _handleNodefunc(obj, NODE)
		Wend
		Return obj
endrem
	End Method
End Type
Global LoadSaveFile:TSaveFile = TSaveFile.Create()



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
	Field gfxmovies:TGW_Sprites
	Field gfxtape:TGW_Sprites
	Field gfxtapeseries:TGW_Sprites
	Field gfxtapeepisodes:TGW_Sprites
	Field gfxepisodes:TGW_Sprites
	Field maxGenres:int = 1

	Field currentseries:TProgramme	= Null

	Function Create:TgfxProgrammelist(x:Int, y:Int, maxGenres:int)
		Local Obj:TgfxProgrammelist =New TgfxProgrammelist
		Obj.gfxmovies		= Assets.GetSprite("pp_menu_werbung")   'Assets.GetSprite("") '  = gfxmovies
		Obj.gfxtape			= Assets.GetSprite("pp_cassettes_movies")
		Obj.gfxtapeseries	= Assets.GetSprite("pp_cassettes_series")
		Obj.gfxtapeepisodes	= Assets.GetSprite("pp_cassettes_episodes")
		Obj.gfxepisodes		= Assets.GetSprite("episodes")
		Obj.Pos.SetXY(x, y)
		Obj.maxGenres = maxGenres
		Return Obj
	End Function

	Method Draw:Int(createProgrammeblock:Int=1)
		if not enabled then return 0

		If self.openState >=3 Then gfxepisodes.Draw(Pos.x - gfxepisodes.w, Pos.y + gfxmovies.h - 4)

		If self.openState >=2
			gfxmovies.Draw(Pos.x - gfxmovies.w + 14, Pos.y)
			If currentgenre >= 0 	Then DrawTapes(currentgenre, createProgrammeblock)
			If currentSeries<> Null	Then DrawEpisodeTapes(currentseries, createProgrammeblock)
		EndIf
		If self.openState >=1
			local currY:float = Pos.y
			Assets.GetSprite("genres_top").draw(Pos.x,currY)
			currY:+Assets.GetSprite("genres_top").h

'			gfxgenres.Draw(Pos.x, Pos.y)
			For local genres:int = 0 To self.maxGenres-1 		'21 genres
				local lineHeight:int =0
				local entryNum:string = (genres mod 2)
				if genres = 0 then entryNum = "First"
				Assets.GetSprite("genres_entry"+entryNum).draw(Pos.x,currY)
				lineHeight = Assets.GetSprite("genres_entry"+entryNum).h

				Local genrecount:Int = TProgramme.CountGenre(genres, Players[Game.playerID].ProgrammeCollection.List)

				If genrecount > 0
					FontManager.baseFont.drawBlock (GetLocale("MOVIE_GENRE_" + genres) + " (" + TProgramme.CountGenre(genres, Players[Game.playerID].ProgrammeCollection.List) + ")", Pos.x + 4, Pos.y + lineHeight*genres +5, 114, 16, 0)
					SetAlpha 0.6; SetColor 0, 255, 0
					'takes 20% of fps...
					For Local i:Int = 0 To genrecount -1
						DrawLine(Pos.x + 121 + i * 2, Pos.y + 4 + lineHeight*genres - 1, Pos.x + 121 + i * 2, Pos.y + 17 + lineHeight*genres - 1)
					Next
				else
					SetAlpha 0.3; SetColor 0, 0, 0
					FontManager.baseFont.drawBlock (GetLocale("MOVIE_GENRE_" + genres), Pos.x + 4, Pos.y + lineHeight*genres +5, 114, 16, 0)
				EndIf
				SetAlpha 1.0
				SetColor 255, 255, 255
				currY:+ lineHeight
			Next
			Assets.GetSprite("genres_bottom").draw(Pos.x,currY)
		EndIf
	End Method

	Method DrawTapes:Int(genre:Int, createProgrammeblock:Int=1)
		Local locx:Int = Pos.x - gfxmovies.w + 25
		Local locy:Int = Pos.y+7 -19

		local font:TBitmapFont = FontManager.GetFont("Font10")
		For Local movie:TProgramme = EachIn Players[Game.playerID].ProgrammeCollection.List 'all programmes of one player
			If movie.genre = genre
				locy :+ 19
				If movie.isMovie
					gfxtape.Draw(locx, locy)
				else
					gfxtapeseries.Draw(locx, locy)
				endif
				font.DrawBlock(movie.title, locx + 13, locy + 5, 139, 16, 0, 0, 0, 0, True)
				If functions.MouseIn( locx, locy, gfxtape.w, gfxtape.h)
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

		For Local movie:TProgramme = EachIn Players[Game.playerID].ProgrammeCollection.List 'all programmes of one player
			If movie.genre = genre
				locy :+ 19
				If MOUSEMANAGER.IsHit(1) AND functions.MouseIn( locx, locy, gfxtape.w, gfxtape.h)
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
						TArchiveProgrammeBlock.CreateDragged(movie, Game.playerID)
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
		local font:TBitmapFont = FontManager.GetFont("Default", 8)

		For Local i:Int = 0 To series.episodelist.Count()-1
			Local episode:TProgramme = TProgramme(series.episodeList.ValueAtIndex(i))   'all programmes of one player
			If episode <> Null
				locy :+ 12
				SetAlpha 1.0
				gfxtapeepisodes.Draw(locx, locy)
				font.DrawBlock("(" + episode.episodeNumber + "/" + series.episodeList.count() + ") " + episode.title, locx + 10, locy + 1, 85, 12, 0, 0, 0, 0, True)
				If functions.IsIn(MouseX(),MouseY(), locx,locy, gfxtapeepisodes.w, gfxtapeepisodes.h)
					Game.cursorstate = 1
					SetAlpha 0.2;DrawRect(locx, locy, gfxtapeepisodes.w, gfxtapeepisodes.h) ;SetAlpha 1.0
					If Not MOUSEMANAGER.IsHit(1) then episode.ShowSheet(30,20, -1, series)
				EndIf
			EndIf
		Next
	End Method

	Method UpdateEpisodeTapes:Int(series:TProgramme, createProgrammeblock:Int=1)
		'Local genres:Int
		Local tapecount:Int = 0
		Local locx:Int = Pos.x - gfxepisodes.w + 8
		Local locy:Int = Pos.y + 5 + gfxmovies.h - 4 -12 '-4 as displacement for displaced the background
		For local episode:TProgramme = eachin  series.episodelist
			If episode <> Null
				locy :+ 12
				tapecount :+ 1
				If MOUSEMANAGER.IsHit(1) AND functions.IsIn(MouseX(),MouseY(), locx,locy, gfxtapeepisodes.w, gfxtapeepisodes.h)
					TProgrammeBlock.CreateDragged(episode)
					SetOpen(0)
					MOUSEMANAGER.resetKey(1)
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
			If MOUSEMANAGER.IsHit(1) AND functions.IsIn(MouseX(),MouseY(), Pos.x,Pos.y, Assets.GetSprite("genres_entry0").w, Assets.GetSprite("genres_entry0").h*self.MaxGenres)
				SetOpen(2)
				currentgenre = Floor((MouseY() - Pos.y - 1) / Assets.GetSprite("genres_entry0").h)
			EndIf

			If self.openState >=2
				If currentgenre >= 0	Then UpdateTapes(currentgenre, createProgrammeblock)
				If currentSeries<> Null	Then UpdateEpisodeTapes(currentseries, createProgrammeblock)
			EndIf
		EndIf
	End Method

	Method SetOpen:Int(newState:Int)
		newState = Max(0, newState)
		if newState <= 1 then currentgenre=-1
		if newState <= 2 then currentseries=Null
		If newState = 0 Then enabled = 0;currentseries=Null;currentgenre=-1 else enabled = 1

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
		For Local contract:TContract = EachIn Players[Game.playerID].ProgrammeCollection.ContractList 'all contracts of one player
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


	Function Load:TAudienceQuotes(pnode:TxmlNode)
print "implement Load:TAudienceQuotes"
return null
rem
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
endrem
	End Function

	Function LoadAll()
		TAudienceQuotes.List.Clear()
		Local Children:TList = LoadSaveFile.NODE.getChildren()
		For Local NODE:TxmlNode = EachIn Children
			If NODE.getName() = "AUDIENCEQUOTE"
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
	  Sheet = TTooltip.Create(title, getLocale("AUDIENCE_RATING") + ": " + functions.convertValue(String(audience), 2, 0) + " (MA: " + audiencepercentage + "%)", x, y, 200, 20)
    Else
	  Sheet.title = title
	  Sheet.text = getLocale("AUDIENCE_RATING")+": "+functions.convertValue(String(audience), 2, 0)+" (MA: "+(audiencepercentage/10)+"%)"
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
			self.useFontBold.drawStyled(title, self.pos.x+5+displaceX, self.pos.y+Self.TooltipHeader.h/2 - self.useFontBold.getHeight("ABC")/2 +2 , 50,50,50, 2,0, 1, 0.1)
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

    Global AdditionallyDragged:Int	= 0
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

	Method SetBasePos(_pos:TPosition = null)
		if _pos <> null then self.pos.setPos(_pos); self.StartPos.setPos(_pos)
	End Method

	Method SetBaseCoords(_x:Int = 1000, _y:Int = 1000)
      If _x <> 1000 Then Self.Pos.SetX(_x);Self.StartPos.SetX(_x)
      If _y <> 1000 Then Self.Pos.SetY(_y);Self.StartPos.SetY(_y)
	End Method

	Method IsAtStartPos:Int()
		If Abs(Self.pos.x - Self.StartPos.x)<=1 And Abs(Self.pos.y - Self.StartPos.y)<=1 Then Return True
		Return False
	End Method

	Function SortDragged:int(o1:object, o2:object)
		Local s1:TBlock = TBlock(o1)
		Local s2:TBlock = TBlock(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
		Return (s1.dragged * 100)-(s2.dragged * 100)
	End Function
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
	field pos:TPosition
	Global List:TList = CreateList()
	Global LastID:Int=0
	global sprite:TGW_Sprites

	Function Create:TError(title:String, message:String)
		Local obj:TError =  New TError
		obj.title	= title
		obj.message	= message
		obj.id		= LastID
		LastID :+1
		if obj.sprite = null then obj.sprite = Assets.GetSprite("gfx_errorbox")
		obj.pos		= TPosition.Create(400-obj.sprite.w/2 +6, 200-obj.sprite.h/2 +6)
		obj.link	= List.AddLast(obj)
		Game.error:+1
		Return obj
	End Function

	Function CreateNotEnoughMoneyError()
		TError.Create(getLocale("ERROR_NOT_ENOUGH_MONEY"),getLocale("ERROR_NOT_ENOUGH_MONEY_TEXT"))
	End Function

	Function DrawErrors()
		If Game.error > 0
			Local error:TError = TError(List.Last())
			If error <> Null Then error.draw()
		EndIf
	End Function

	Function UpdateErrors()
		If Game.error > 0
			Local error:TError = TError(List.Last())
			If error <> Null Then error.Update()
		EndIf
	End Function

	Method Update()
		MouseManager.resetKey(2) 'no right clicking allowed as long as "error notice is active"
		If Mousemanager.IsHit(1)
			If functions.MouseIn(pos.x,pos.y, sprite.w, sprite.h)
				link.Remove()
				Game.error :-1
				MouseManager.resetKey(1) 'clicked to remove error
			EndIf
		EndIf
	End Method

	Function DrawNewError(str:String="unknown error")
		TError(TError.List.Last()).message = str
		TError.DrawErrors()
		Flip 0
	End Function

	Method Draw()
		SetAlpha 0.5
		SetColor 0,0,0
		DrawRect(20,10,760, 373)
		SetAlpha 1.0
		Game.cursorstate = 0
		SetColor 255,255,255
		sprite.Draw(pos.x,pos.y)
		FontManager.GetFont("Default", 15, BOLDFONT).DrawBlock(title, pos.x + 12 + 6, pos.y + 15, sprite.w - 60, 40, 0, 150, 50, 50)
		FontManager.GetFont("Default", 12).DrawBlock(message, pos.x+12+6,pos.y+50,sprite.w-40, sprite.h-60,0,50,50,50)
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
		If functions.MouseIn( x, y, w, FontManager.baseFont.getBlockHeight(Self._text, w, h))
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
		If id = 3 Then Players[Game.playerID].Figure.inRoom = TRooms.GetRoom("financials", Players[Game.playerID].Figure.inRoom.owner)	'shows financials
		If id = 4 Then Players[Game.playerID].Figure.inRoom = TRooms.GetRoom("image", Players[Game.playerID].Figure.inRoom.owner)	'shows image and audiencequotes
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
			If Button.owner = Players[Game.playerID].figure.inRoom.owner then Button.Draw(tweenValue)
    	Next
		'tooltips - later drawn to avoid z-order problems
		For Local Button:TNewsbuttons = EachIn TNewsbuttons.List
			If Button.owner = Players[Game.playerID].figure.inRoom.owner
				if Button.tooltip <> null then Button.tooltip.Draw(tweenValue)
			endif
		Next
	End Function

    Function UpdateAll(deltaTime:float=1.0)
		For Local Button:TNewsbuttons = EachIn TNewsbuttons.List

			If Button.tooltip<> Null
				'sync with player abo
				Button.clickstate = Players[ Button.owner ].GetNewsAbonnement(Button.genre)

				If Button.clickstate=0
					Button.tooltip.title = Button.Caption+" - "+getLocale("NEWSSTUDIO_NOT_SUBSCRIBED")
					Button.tooltip.text = getLocale("NEWSSTUDIO_SUBSCRIBE_GENRE_LEVEL")+" 1: "+ (Button.clickstate+1)*10000+"€"
				Else
					Button.tooltip.title = Button.Caption+" - "+getLocale("NEWSSTUDIO_SUBSCRIPTION_LEVEL")+" "+Button.clickstate
					If Button.clickstate=3
						Button.tooltip.text = getLocale("NEWSSTUDIO_DONT_SUBSCRIBE_GENRE_ANY_LONGER")+ "0€"
					Else
						Button.tooltip.text = getLocale("NEWSSTUDIO_NEXT_SUBSCRIPTION_LEVEL")+": "+ (Button.clickstate+1)*10000+ "€"
					EndIf
				EndIf
				Button.tooltip.Update(deltaTime)
			EndIf

			If Button.owner = Game.playerID
				If Button.IsIn(MouseX(), MouseY())
					if MOUSEMANAGER.IsDown(1)
						if Button.clicked = 0 then Button.Clicked =1
					Else if Button.clicked = 1
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
		Next
		'tooltips
    End Function

    Method OnClick()
		If self.clickstate > Game.MaxAbonnementLevel Then self.clickstate=0 else self.clickstate :+1
		Players[Game.playerID].SetNewsAbonnement(genre, clickstate)
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
		For Local i:Int = 0 to Players[Game.playerID].newsabonnements[genre]-1
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
				Local contract:TContract = Players[ShowChannel].ProgrammePlan.GetActualContract()
				Interface.ActualProgram = Assets.GetSprite("gfx_interface_TVprogram_ads")
			    If contract <> Null
					ActualProgramToolTip.TitleBGtype 	= 1
					ActualProgramText 					= getLocale("ADVERTISMENT")+": "+contract.title
				Else
					ActualProgramToolTip.TitleBGtype	= 2
					ActualProgramText					= getLocale("BROADCASTING_OUTAGE")
				EndIf
			Else
				Local block:TProgrammeBlock = Players[ShowChannel].ProgrammePlan.GetActualProgrammeBlock()
				Interface.ActualProgram = Assets.GetSprite("gfx_interface_TVprogram_none")
				If block <> Null
					Interface.ActualProgram = Assets.GetSprite("gfx_interface_TVprogram_" + block.Programme.genre, "gfx_interface_TVprogram_none")
					ActualProgramToolTip.TitleBGtype	= 0
					if block.programme.parent <> null
						ActualProgramText					= block.programme.parent.title + ": "+ block.Programme.title + " ("+getLocale("BLOCK")+" "+(1+Game.GetActualHour()-(block.sendhour - game.day*24))+"/"+block.Programme.blocks+")"
					else
						ActualProgramText					= block.Programme.title + " ("+getLocale("BLOCK")+" "+(1+Game.GetActualHour()-(block.sendhour - game.day*24))+"/"+block.Programme.blocks+")"
					endif
				Else
					ActualProgramToolTip.TitleBGtype	= 2
					ActualProgramText 					= getLocale("BROADCASTING_OUTAGE")
				EndIf
			EndIf
			If Game.minute <= 5
				Interface.ActualProgram = Assets.GetSprite("gfx_interface_TVprogram_news")
				ActualProgramToolTip.TitleBGtype	= 3
				ActualProgramText 					= getLocale("NEWS")
			EndIf
		Else
			ActualProgramToolTip.TitleBGtype	= 3
			ActualProgramText 					= getLocale("TV_OFF")
		EndIf 'showchannel <>0
		If ActualProgramToolTip.enabled Then ActualProgramToolTip.Update(deltaTime)
		If ActualAudienceToolTip.enabled Then ActualAudienceToolTip.Update(deltaTime)

		'channel selection (tvscreen on interface)
		If MOUSEMANAGER.IsHit(1)
			For Local i:Int = 0 To 4
				If functions.MouseIn( 75 + i * 33, 171 + 383, 33, 41)
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
				ActualProgramToolTip.text	= getLocale("AUDIENCE_RATING")+": "+Players[ShowChannel].GetFormattedAudience()+ " (MA: "+functions.convertPercent(Players[ShowChannel].GetRelativeAudiencePercentage(),2)+"%)"
			Else
				ActualProgramToolTip.text	= getLocale("TV_TURN_IT_ON")
			EndIf
			ActualProgramToolTip.enabled 	= 1
			ActualProgramToolTip.lifetime	= ActualProgramToolTip.startlifetime
	    EndIf
		If functions.IsIn(MouseX(),MouseY(),385,468,108,30)
			ActualAudienceToolTip.title 	= getLocale("AUDIENCE_RATING")+": "+Players[Game.playerID].GetFormattedAudience()+ " (MA: "+functions.convertPercent(Players[Game.playerID].GetRelativeAudiencePercentage(),2)+"%)"
			ActualAudienceToolTip.text  	= getLocale("MAX_AUDIENCE_RATING")+": "+functions.convertValue(Int((Game.maxAudiencePercentage * Players[Game.playerID].maxaudience)),2,0)+ " ("+(Int(Ceil(1000*Game.maxAudiencePercentage)/10))+"%)"
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

				Local audiencerate:Float	= Float(Players[ShowChannel].audience / Float(Game.maxAudiencePercentage * Players[Game.playerID].maxaudience))
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
			FontManager.getFont("Default", 13, BOLDFONT).drawBlock(Players[Game.playerID].GetFormattedMoney() + "  ", 377, 427 - 383 + NoDX9moveY, 103, 25, 2, 200,230,200, 0, 2)
			FontManager.getFont("Default", 13, BOLDFONT).drawBlock(Players[Game.playerID].GetFormattedAudience() + "  ", 377, 469 - 383 + NoDX9moveY, 103, 25, 2, 200,200,230, 0, 2)
		 	FontManager.getFont("Default", 11, BOLDFONT).drawBlock((Game.day) + ". Tag", 366, 555 - 383 + NoDX9moveY, 120, 25, 1, 180,180,180, 0, 2)
		EndIf 'bottomimg is dirty

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
		If Game.cursorstate = 0 Then DrawImage(gfx_mousecursor, MouseX()-7, 	MouseY()	,0)
		If Game.cursorstate = 1 Then DrawImage(gfx_mousecursor, MouseX()-7, 	MouseY()-4	,1)
		If Game.cursorstate = 2 Then DrawImage(gfx_mousecursor, MouseX()-10,	MouseY()-12	,2)
	End Method

End Type








'----stations
'Stationmap
'provides the option to buy new stations
'functions are calculation of audiencesums and drawing of stations

Type TStation
	field pos:TPosition
	Field reach:Int=0
	Field price:Int
	Field owner:Int = 0
	Field id:Int = 0
	Global lastID:Int = 0


	Function Create:TStation(x:Int,y:Int, reach:Int, price:Int, owner:Int)
		Local obj:TStation = New TStation
		obj.pos = TPosition.Create(x,y)
		obj.reach = reach
		obj.price = price
		obj.owner = owner
		obj.id = obj.GetNewID()
		Return obj
	End Function

	Method GetNewID:Int()
		Self.lastID:+1
		Return Self.lastID
	End Method

	Method Reset()
		self.reach = 0
		self.pos.SetXY(-1,-1)
		self.owner = -1
		self.price = 0
	End Method

	Method getPrice:int()
		self.price = self.calculatePrice(self.reach)
		return self.price
	End Method

	Function calculatePrice:Int(summe:Int)
		return Max( 25000, Int(Ceil(summe / 10000)) * 25000 )
	End Function

	Function Load:TStation(pnode:TxmlNode)
print "implement Load:TStation"
return null
rem
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
endrem
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
			Case 1,2,3,4	Players[owner].color.MySetColor()
							antennaNr = "stationmap_antenna"+owner
			Default			SetColor 255, 255, 255
							antennaNr = "stationmap_antenna0"
		End Select
		DrawOval(pos.x - radius + 20, pos.y - radius + 10, 2 * radius, 2 * radius)
		SetColor 255,255,255
		SetAlpha 1.0
		Assets.GetSprite(antennaNr).Draw(pos.x + 20, pos.y + 10 + radius - Assets.GetSprite(antennaNr).h - 2, -1,0,0.5)
	End Method


End Type

Type TStationPoint
	field pos:TPosition
	field color:Int

	Function Create:TStationPoint(x:Int, y:Int, color:Int)
		Local obj:TStationPoint = New TStationPoint
		obj.pos = TPosition.Create(x,y)
		obj.color = color
		Return obj
	End Function
End Type

Type TStationMap
	Field StationList:TList	= CreateList()
	Field radius:Int		= 15		{saveload = "normal"}
	Field einwohner:Int		= 0			{saveload = "normal"}
	Field LastStation:TStation			{saveload = "normal"}
	Field LastCalculatedAudienceIncrease:int = -1
	Field action:Int		= 0			{saveload = "normal"}	'2= station buying (another click on the map buys the station)
																'1= searching a station
	Field populationmap:Int[stationmap_mainpix.width + 20, stationmap_mainpix.height + 20]
	Field bundesland:String = "" {saveload = "normal"}	'mouse over state
	Field outsideLand:Int = 0

	Field sellStation:TStation[5]
	Field buyStation:TStation[5]
	Field filter_ShowStations:Int[5]
	Field StationShare:Int[4, 3]

    field baseStationSprite:TGW_Sprites

	Global List:TList = CreateList()


	Function Load:TStationmap(pnode:TxmlNode)
print "implement Load:TStationmap"
return null
rem
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
				Case "STATION"
							    Local station:TStation = TStation.Load(NODE)
		    					If station <> Null Then PrintDebug("TStationmap.load()", "Station zur Stationmap hinzugefuegt", DEBUG_SAVELOAD) ;StationMap.StationList.AddLast(station)
			End Select
			NODE = NODE.nextSibling()
		Wend
endrem
  End Function

	Function LoadAll()
		PrintDebug("TStationMap.LoadAll()", "Lade StationMaps", DEBUG_SAVELOAD)
		TStationMap.List.Clear()
		Local Children:TList = LoadSaveFile.NODE.getChildren()
		For Local node:txmlNode = EachIn Children
			If NODE.getName() = "STATIONMAP"
			      TStationMap.Load(NODE)
			EndIf
		Next
	End Function

	Function SaveAll()
		LoadSaveFile.xmlBeginNode("ALLSTATIONMAPS")
			For Local StationMap:TStationMap = EachIn TStationMap.List
				LoadSaveFile.xmlBeginNode("STATIONMAP")
		 			Local typ:TTypeId = TTypeId.ForObject(StationMap)
					For Local t:TField = EachIn typ.EnumFields()
						If t.MetaData("saveload") = "normal" Then LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(StationMap)))
					Next
					For Local station:TStation = EachIn StationMap.StationList
						If station <> Null Then station.Save()
					Next
				LoadSaveFile.xmlCloseNode()
		    Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Function Create:TStationMap()
		Local obj:TStationMap=New TStationMap
		local start:int = Millisecs()
		local i:int, j:int

		'read all inhabitants of the map
		For i = 0 To stationmap_mainpix.width-1
			For j = 0 To stationmap_mainpix.height-1
				obj.populationmap[i, j] = obj.getPopulationForBrightness( ARGB_RED(stationmap_mainpix.ReadPixel(i, j)) )
				obj.einwohner:+ obj.populationmap[i, j]
			Next
		Next
		Print "StationMap: alle Pixel eingelesen - Einwohner:" + obj.einwohner + " zeit: "+(Millisecs()-start)+"ms"

		obj.baseStationSprite	=  Assets.GetSprite("stationmap_antenna0")
		obj.LastStation			= TStation.Create(-1,-1, 0, 0, -1)

		List.AddLast(obj)
		SortList List
		Return obj
	End Function

	Method AddStation(x:Int, y:Int, playerid:Int, valuetorefresh:Int Var)
		Local reach:Int = Self.CalculateAudienceIncrease(playerid, x, y)

		print "StationMap: added station to "+playerID+" reach:"+reach
		StationList.AddLast(TStation.Create(x, y, reach, TStation.calculatePrice(reach), playerid))
		valuetorefresh = CalculateAudienceSum(playerid)
	End Method

    Method Buy(x:Float, y:Float, playerid:Int = 1, fromNetwork:int = false)
		If Players[playerid].finances[Game.getWeekday()].PayStation(self.LastStation.getPrice() )
			Local station:TStation = TStation.Create(LastStation.pos.x,LastStation.pos.y, self.LastStation.reach, self.LastStation.getPrice(), playerid)
			StationList.AddLast(station)
			Print "Player" + playerid + " kauft Station für " + station.price + " Euro (" + station.reach + " Einwohner)"
			Players[playerid].maxaudience = CalculateAudienceSum(playerid)
			'network
			if game.networkgame Then NetworkHelper.SendStationChange(game.playerid, station, Players[game.playerID].maxaudience, 1)
			self.LastStation.Reset()
			Self.buyStation[playerid] = Null
		EndIf
    End Method

	Method SellByPos(pos:TPosition, reach:int, playerID:int)
		for local station:TStation = eachin self.StationList
			if station.pos.isSame(pos) and station.reach = station.reach and station.owner = playerID
				self.sell(station)
				exit
			endif
		Next
	End Method

	Method Sell(station:TStation)
		If Players[station.owner].finances[Game.getWeekday()].SellStation(Floor(station.price * 0.75))
			StationList.Remove(station)
	        Print "Player" + station.owner + " verkauft Station für " + (station.price * 0.75) + " Euro (" + station.reach + " Einwohner)"
			Players[station.owner].maxaudience = CalculateAudienceSum(station.owner) 'auf entsprechenden Player umstellen
			'events ...
			'network
			If Game.networkgame Then If Network.IsConnected Then NetworkHelper.SendStationChange(station.owner, station, Players[station.owner].maxaudience, 0)
			LastStation.reset()
			'when station is sold, audience will decrease, atm buy =/= increase ;D
			Players[station.owner].ComputeAudience(1)
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
		EndIf

		'buying stations
		'1. searching
		If action = 1
			Local pos:TPosition = TPosition.Create(0,0)
			If MOUSEMANAGER.MousePosChanged
				pos.setXY( MouseX() -20, MouseY() -10)

				lastStation.reach = Self.CalculateStationRange(pos.X, pos.Y)
				If lastStation.reach > 0
					Self.outsideLand = False 'no antennagraphic in foreign countries
					LastCalculatedAudienceIncrease = CalculateAudienceIncrease(Game.playerid, pos.X, pos.Y)
				else
					pos.setXY( LastStation.pos.X + 20, LastStation.pos.Y + 10)
					Self.outsideLand = True
					LastStation.reach = Self.CalculateStationRange(pos.X, pos.Y)
				EndIf
			Else
				pos.setXY( LastStation.pos.X + 20, LastStation.pos.Y + 10)
			EndIf
		endif
		'2. actually buy it
		If action = 2 And LastStation.pos.X <> 0 And LastStation.pos.y <> 0
			If MOUSEMANAGER.MousePosChanged Then LastStation.reach = Self.CalculateStationRange(LastStation.pos.X + 20, LastStation.pos.Y + 10)
			Buy(LastStation.pos.X, LastStation.pos.Y, Game.playerID)
			LastStation.Reset()
			action = 0
		EndIf

		ResetCollisions(3)
		If functions.MouseIn(207, 91, Assets.GetSprite("gfx_officepack_topo_bremen").w, Assets.GetSprite("gfx_officepack_topo_bremen").h)
			CollideImage(stationmap_land_bremen, 207, 91, 0, 0, 1, stationmap_land_bremen)
		Else If functions.MouseIn( 452, 118, Assets.GetSprite("gfx_officepack_topo_berlin").w, Assets.GetSprite("gfx_officepack_topo_berlin").h)
			CollideImage(stationmap_land_berlin, 452, 118, 0, 0, 1, stationmap_land_berlin)
		Else If functions.MouseIn( 270, 69, Assets.GetSprite("gfx_officepack_topo_hamburg").w, Assets.GetSprite("gfx_officepack_topo_hamburg").h)
			CollideImage(stationmap_land_hamburg, 270, 69, 0, 0, 1, stationmap_land_hamburg)
		Else If functions.MouseIn( 129, 258, Assets.GetSprite("gfx_officepack_topo_bawue").w, Assets.GetSprite("gfx_officepack_topo_bawue").h)
			CollideImage(stationmap_land_bawue, 129, 258, 0, 0, 1, stationmap_land_bawue)
		Else If functions.MouseIn( 223, 221, Assets.GetSprite("gfx_officepack_topo_bayern").w, Assets.GetSprite("gfx_officepack_topo_bayern").h)
			CollideImage(stationmap_land_bayern, 223, 221, 0, 0, 1, stationmap_land_bayern)
		Else If functions.MouseIn( 69, 263, Assets.GetSprite("gfx_officepack_topo_saarland").w, Assets.GetSprite("gfx_officepack_topo_saarland").h)
			CollideImage(stationmap_land_saarland, 69, 263, 0, 0, 1, stationmap_land_saarland)
		Else If functions.MouseIn( 59, 203, Assets.GetSprite("gfx_officepack_topo_rheinlandpfalz").w, Assets.GetSprite("gfx_officepack_topo_rheinlandpfalz").h)
			CollideImage(stationmap_land_rheinlandpfalz, 59, 203, 0, 0, 1, stationmap_land_rheinlandpfalz)
		Else If functions.MouseIn( 155, 169, Assets.GetSprite("gfx_officepack_topo_hessen").w, Assets.GetSprite("gfx_officepack_topo_hessen").h)
			CollideImage(stationmap_land_hessen, 155, 169, 0, 0, 1, stationmap_land_hessen)
		Else If functions.MouseIn( 276, 169, Assets.GetSprite("gfx_officepack_topo_thueringen").w, Assets.GetSprite("gfx_officepack_topo_thueringen").h)
			CollideImage(stationmap_land_thueringen, 276, 169, 0, 0, 1, stationmap_land_thueringen)
		Else If functions.MouseIn( 388, 167, Assets.GetSprite("gfx_officepack_topo_sachsen").w, Assets.GetSprite("gfx_officepack_topo_sachsen").h)
			CollideImage(stationmap_land_sachsen, 388, 167, 0, 0, 1, stationmap_land_sachsen)
		Else If functions.MouseIn( 314, 103, Assets.GetSprite("gfx_officepack_topo_sachsenanhalt").w, Assets.GetSprite("gfx_officepack_topo_sachsenanhalt").h)
			CollideImage(stationmap_land_sachsenanhalt, 314, 103, 0, 0, 1, stationmap_land_sachsenanhalt)
		Else If functions.MouseIn( 104, 61, Assets.GetSprite("gfx_officepack_topo_niedersachsen").w, Assets.GetSprite("gfx_officepack_topo_niedersachsen").h)
			CollideImage(stationmap_land_niedersachsen, 104, 61, 0, 0, 1, stationmap_land_niedersachsen)
		Else If functions.MouseIn( 213, 12, Assets.GetSprite("gfx_officepack_topo_schleswigholstein").w, Assets.GetSprite("gfx_officepack_topo_schleswigholstein").h)
			CollideImage(stationmap_land_schleswigholstein, 213, 12, 0, 0, 1, stationmap_land_schleswigholstein)
		Else If functions.MouseIn( 359, 78, Assets.GetSprite("gfx_officepack_topo_brandenburg").w, Assets.GetSprite("gfx_officepack_topo_brandenburg").h)
			CollideImage(stationmap_land_brandenburg, 359, 78, 0, 0, 1, stationmap_land_brandenburg)
		Else If functions.MouseIn( 55, 127, Assets.GetSprite("gfx_officepack_topo_nrw").w, Assets.GetSprite("gfx_officepack_topo_nrw").h)
			CollideImage(stationmap_land_nrw, 55, 127, 0, 0, 1, stationmap_land_nrw)
		Else If functions.MouseIn( 318, 21, Assets.GetSprite("gfx_officepack_topo_meckpom").w, Assets.GetSprite("gfx_officepack_topo_meckpom").h)
			CollideImage(stationmap_land_meckpom, 318, 21, 0, 0, 1, stationmap_land_meckpom)
		EndIf
		If action = 1 'placing a new station
		  Local Collision_Layer:Int=1
		  Local p:Object[]=CollideRect(MouseX(),MouseY(),1,1,Collision_Layer,0)
		  Bundesland = "Unbekannt"
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
				Case stationmap_land_brandenburg		bundesland = "Brandenburg"
				Case stationmap_land_nrw				bundesland="Nordrheinwestfahlen"
				Case stationmap_land_meckpom			bundesland="Mecklenburg Vorpommern"
			EndSelect
		  Next
		EndIf

  End Method

	Method DrawStations()
		For Local _Station:TStation = EachIn StationList
			If Self.filter_ShowStations[_Station.owner] Then _Station.Draw()
		Next
		If LastStation.pos.X <> 0 and LastStation.pos.Y <> 0
			SetAlpha 0.2
			SetColor 0,0,0 'replace with a playercolor
			DrawOval(  LastStation.pos.X+20- radius +1, LastStation.pos.Y+10-radius,2*radius,2*radius +1)
			SetAlpha 0.5
			SetColor 255,255,255 'replace with a playercolor
			DrawOval(  LastStation.pos.X+20- radius, LastStation.pos.Y+10-radius,2*radius,2*radius )
			SetAlpha 0.9
			baseStationSprite.draw(LastStation.pos.X+20,LastStation.pos.Y+10+radius-baseStationSprite.h-2, -1,0,0.5)
			SetAlpha 1.0
		EndIf
	End Method

	Method Draw()
		SetColor 255,255,255
		DrawStations()
		If action = 1 And Not Self.outsideLand 'placing a new station
			SetAlpha 0.5
			DrawOval( MouseX()- radius,MouseY()-radius,2*radius,2*radius )
			SetAlpha 0.9
			baseStationSprite.draw(MouseX(), MouseY() +radius -baseStationSprite.h-2, -1,0,0.5)
			SetAlpha 1.0
		EndIf
		local font:TBitmapFont = FontManager.baseFont
		If action = 1
			SetColor(0, 0, 0)
			font.Draw(bundesland, 595, 35)
			font.Draw("Reichweite: ", 595, 52)
				font.DrawBlock(functions.convertValue(String(self.LastStation.reach), 2, 0), 660, 52, 102, 20, 0.5)
			font.Draw("Zuwachs: ", 595, 69)
				font.DrawBlock(functions.convertValue(String(LastCalculatedAudienceIncrease), 2, 0), 660, 69, 102, 20, 2)
			font.Draw("Preis: ", 595, 86)
				FontManager.baseFontBold.DrawBlock(functions.convertValue(self.LastStation.GetPrice(), 2, 0), 660, 86, 102, 20, 2)
			SetColor(180, 180, 255)
			font.Draw(bundesland, 594, 34)
			SetColor(255,255,255)
		EndIf

		If Self.sellStation[Game.playerID] <> Null
			SetColor(0, 0, 0)
			font.Draw("Reichweite: ", 595, 197)
				font.DrawBlock(functions.convertValue(Self.sellStation[Game.playerID].reach, 2, 0), 660, 197, 102, 20, 2)
			font.Draw("Preis: ", 595, 214)
				FontManager.baseFontBold.DrawBlock(functions.convertValue(Self.sellStation[Game.playerID].price, 2, 0), 660, 214, 102, 20, 2)
			SetColor(255, 255, 255)
		EndIf
  End Method

	'summary: returns calculated distance between 2 points
	Method calculateDistance:Double(x1:Int, x2:Int)
		Return Sqr((x1*x1) + (x2*x2))
	End Method

	Method getPopulationForBrightness:int(value:int)
		value = Max(5, 255-value)
		value = (value*value)/255 '2 times so low values are getting much lower
		value = (value*value)/255

		If value > 110 Then value :* 2.0
		If value > 140 Then value :* 1.9
		If value > 180 Then value :* 1.3
		If value > 220 Then value :* 1.1	'population in big cities
		return 26.0 * value					'population in general
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
				For posX = _Station.pos.x - radius To _Station.pos.x + radius
					For posY = _Station.pos.y - radius To _Station.pos.y + radius
						' noch innerhalb des Kreises?
						If Sqr((posX - _Station.pos.x) ^ 2 + (posY - _Station.pos.y) ^ 2) <= radius
							If _Station.owner = playerA
								pointsA.Insert(String((posX - x) + "," + (posY - y)), TStationPoint.Create((posX - x) , (posY - y), ARGB_Color(255, 255, 255, 255)))
							Else
								pointsB.Insert(String((posX - x) + "," + (posY - y)), TStationPoint.Create((posX - x) , (posY - y), ARGB_Color(255, 255, 255, 255)))
							EndIf
						EndIf
					Next
				Next
			EndIf
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

		'einmal "blaue farbe" einmal "rote" farbe nutzen

		For Local point:TStationPoint = EachIn points.Values()
			If ARGB_Red(point.color) = 0 And ARGB_Blue(point.color) = 255
				returnvalue:+ populationmap[point.pos.x, point.pos.y]
			EndIf
		Next
		Return returnvalue
	End Method

	Method _FillPoints(map:TMap var, x:int, y:int, color:int)
		local posX:int=0
		local posY:int=0
		x = Max(0,x)
		y = Max(0,y)
'print "given: x"+x+" y"+y
'print "for posX = "+Max(x - radius,radius)+" To "+Min(x + radius, stationmap_mainpix.width-radius)
'print "	For posY = "+Max(y - radius,radius)+" To "+Min(y + radius, stationmap_mainpix.height-radius)
		' innerhalb des Bildes?
		For posX = Max(x - radius,radius) To Min(x + radius, stationmap_mainpix.width-radius)
			For posY = Max(y - radius,radius) To Min(y + radius, stationmap_mainpix.height-radius)
				' noch innerhalb des Kreises?
				If self.calculateDistance( posX - x, posY - y ) <= radius
					map.Insert(String((posX) + "," + (posY)), TStationPoint.Create((posX) , (posY), color ))
				EndIf
			Next
		Next
	End Method

	Method CalculateAudienceIncrease:Int(owner:Int = 0, _x:Int, _y:Int)
		Local start:Int = MilliSecs()
		Local Points:TMap = New TMap
		Local returnValue:Int = 0
        Local x:Int = 0, y:Int = 0, posX:Int = 0, posY:Int = 0

		'add "new" station which may be bought
		If _x = 0 And _y = 0 Then _x = MouseX() - 20; _y = MouseY() - 10
		self._FillPoints(Points, _x,_y, ARGB_Color(255, 0, 255, 255))

		'overwrite with stations owner already has - red pixels get overwritten with white,
		'count red at the end for increase amount
		For Local _Station:TStation = EachIn StationList
			If _Station.owner = owner
				If functions.IsIn(_x,_y, _station.pos.x - 2*radius, _station.pos.y - 2 * radius, 4*radius, 4*radius)
					self._FillPoints(Points, _Station.pos.x, _Station.pos.y, ARGB_Color(255, 255, 255, 255))
				EndIf
			EndIf
		Next

		For Local point:TStationPoint = EachIn points.Values()
			If ARGB_Red(point.color) = 0 And ARGB_Blue(point.color) = 255
				returnvalue:+ populationmap[point.pos.x, point.pos.y]
			EndIf
		Next
		Return returnvalue
	End Method

	'summary: returns maximum audience a player has
	Method CalculateAudienceSum:Int(owner:Int = 0)
		Local start:Int = MilliSecs()
		Local Points:TMap = New TMap
        Local x:Int = 0, y:Int = 0, posX:Int = 0, posY:Int = 0
		For Local _Station:TStation = EachIn StationList
			If _Station.owner = owner
				self._FillPoints(Points, _Station.pos.x, _Station.pos.y, ARGB_Color(255, 255, 255, 255))
			EndIf
		Next
		Local returnvalue:Int = 0

		For Local point:TStationPoint = EachIn points.Values()
			If ARGB_Red(point.color) = 255 And ARGB_Blue(point.color) = 255
				returnvalue:+ populationmap[point.pos.x, point.pos.y]
			EndIf
		Next
		Return returnvalue
	End Method

	'summary: returns a stations maximum audience reach
	Method CalculateStationRange:Int(x:Int, y:Int)
		Local posX:Int, posY:Int
		Local returnValue:Int = 0
		' für die aktuelle Koordinate die summe berechnen
		' min/max = immer innerhalb des Bildes
		For posX = Max(x - radius,radius) To Min(x + radius, stationmap_mainpix.width-radius)
			For posY = Max(y - radius,radius) To Min(y + radius, stationmap_mainpix.height-radius)
				' noch innerhalb des Kreises?
				If self.calculateDistance( posX - x, posY - y ) <= radius
					returnvalue:+ populationmap[posX, posY]
				EndIf
			Next
		Next
		Return returnValue
	End Method

End Type
