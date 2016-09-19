SuperStrict
Import "Dig/base.gfx.gui.list.base.bmx"
Import "Dig/base.gfx.gui.list.selectlist.bmx"

Import "common.misc.datasheet.bmx"
Import "game.screen.base.bmx"

Import "game.achievements.base.bmx"


Type TScreenHandler_OfficeAchievements extends TScreenHandler
	Field showCategory:int = 0
	Field showCategoryIndex:int = 0
	Field showGroup:int = 0
	Field showMode:int = 0
	Field roomOwner:int = 0
	Field categoryCountCompleted:int[]
	Field categoryCountMax:int[]

	Field highlightNavigationEntry:int = -1

	Global achievementList:TGUISelectList

	Global hoveredGuiAchievement:TGUIAchievementListItem

	Global _eventListeners:TLink[]
	Global _instance:TScreenHandler_OfficeAchievements

	Const SHOW_ALL:int = 0
	Const SHOW_COMPLETED:int = 1
	Const SHOW_FAILED:int = 2
	Const SHOW_INCOMPLETED:int = 4
	


	Function GetInstance:TScreenHandler_OfficeAchievements()
		if not _instance then _instance = new TScreenHandler_OfficeAchievements
		return _instance
	End Function


	Method Initialize:int()
		local screen:TScreen = ScreenCollection.GetScreen("screen_office_achievements")
		if not screen then return False

		'=== CREATE ELEMENTS ===
		InitGUIElements()


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== register event listeners
		'GUI -> GUI
		'we want to know if we hover a specific block
'		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.OnMouseOver", onMouseOverCastItem, "TGUICastListItem" ) ]
'		_eventListeners :+ [ EventManager.registerListenerFunction("guiobject.OnMouseOver", onMouseOverProductionConceptItem, "TGuiProductionConceptListItem" ) ]


		'LOGIC -> GUI
		'finish an achievement while looking at the list
'		_eventListeners :+ [ EventManager.registerListenerFunction("ProductionConcept.SetCast", onProductionConceptChangeCast ) ]

		'to reload achievement list when entering a screen
		_eventListeners :+ [ EventManager.registerListenerFunction("screen.onBeginEnter", onEnterScreen, screen) ]

		'to update/draw the screen
		_eventListeners :+ _RegisterScreenHandler( onUpdate, onDraw, screen )
	End Method


	Method RemoveAllGuiElements:int()
		achievementList.EmptyList()

		hoveredGuiAchievement = null
	End Method


	Method SetLanguage()
		'nothing yet
	End Method


	Method AbortScreenActions:Int()
		'nothing yet
	End Method


	Function onUpdate:int( triggerEvent:TEventBase )
		local room:TOwnedGameObject = TOwnedGameObject( triggerEvent.GetData().get("room") )
		if not room then return 0

		GetInstance().roomOwner = room.owner

		GetInstance().Update()
	End Function


	Function onDraw:int( triggerEvent:TEventBase )
		local room:TOwnedGameObject = TOwnedGameObject( triggerEvent.GetData().get("room") )
		if not room then return 0

		GetInstance().roomOwner = room.owner

		GetInstance().Render()
	End Function


	Function onEnterScreen:int( triggerEvent:TEventBase )
		GetInstance().ReloadAchievements()
	End Function
	


	
	'=== EVENTS ===

	'GUI -> GUI reactio
	Function onMouseOverAchievement:int( triggerEvent:TEventBase )
		local item:TGUIAchievementListItem = TGUIAchievementListItem(triggerEvent.GetSender())
		if item = Null then return FALSE

		GetInstance().hoveredGuiAchievement = item

		return TRUE
	End Function


	Method InitGUIElements()
		if not achievementList
			achievementList = new TGUISelectList.Create(new TVec2D.Init(210,60), new TVec2D.Init(525, 280), "office_achievements")
		endif

		achievementList.scrollItemHeightPercentage = 1.0
		achievementList.SetAutosortItems(False) 'already sorted achievements
		achievementList.SetOrientation(GUI_OBJECT_ORIENTATION_Vertical)


		ReloadAchievements()
	End Method


	Method ReloadAchievements()
		'=== PRODUCTION COMPANY SELECT ===
		achievementlist.EmptyList()
		
		'add the achievements to that list

		'sort by series/name
'		local productionConcepts:TProductionConcept[]
'		For local productionConcept:TProductionConcept = EachIn GetProductionConceptCollection().entries.Values()
'			productionConcepts :+ [productionConcept]
'		Next
'		productionConcepts.Sort(true)

		categoryCountCompleted = new int[TVTAchievementCategory.count+1]
		categoryCountMax = new int[TVTAchievementCategory.count+1]

		local achievements:TList = CreateList()
		For local achievement:TAchievement = EachIn GetAchievementCollection().achievements.entries.values()
			categoryCountMax[0] :+ 1
			categoryCountMax[TVTAchievementCategory.GetIndex(achievement.category)] :+ 1
			if achievement.IsCompleted(roomOwner)
				categoryCountCompleted[0] :+ 1
				categoryCountCompleted[TVTAchievementCategory.GetIndex(achievement.category)] :+ 1
			endif

			if showCategory > 0 and achievement.category <> showCategory then continue
			if showGroup > 0 and achievement.group <> showGroup then continue
			if showMode > 0
				if showMode & SHOW_COMPLETED > 0 and not achievement.IsCompleted(roomOwner) then continue
				if showMode & SHOW_FAILED > 0 and not achievement.IsFailed(roomOwner) then continue
				if showMode & SHOW_INCOMPLETED > 0 and achievement.IsCompleted(roomOwner) then continue
			endif

			achievements.AddLast(achievement)
		Next
		achievements.Sort( True, TAchievement.SortByCategory )


		For local achievement:TAchievement = EachIn achievements
'print "adding c:"+achievement.category+" g:"+achievement.group+" i:"+achievement.index+"  " + achievement.GetTitle()
			'base items do not have a size - so we have to give a manual one
			local item:TGUIAchievementListItem = new TGUIAchievementListItem.Create(null, null, achievement.GetTitle())
			item.data = new TData.Add("achievement", achievement)
			item.Resize(400, 60)
			achievementList.AddItem( item )
		Next

		achievementList.RecalculateElements()
		'refresh scrolling state
		achievementList.Resize(-1, -1)
	End Method

global LS_office_achievements:TLowerString = TLowerString.Create("office_achievements")	

	Method Update()
		'gets refilled in gui-updates
		hoveredGuiAchievement = null

		highlightNavigationEntry = -1
		if THelper.MouseIn(50,50,100,300)
			'0 to ... because we include "all" (which is 0)
			For local i:int = 0 to TVTAchievementCategory.count
				if THelper.MouseIn(50, 65 + i*20 -5, 100, 20)
					highlightNavigationEntry = i

					if MouseManager.IsClicked(1)
						showCategory = TVTAchievementCategory.GetAtIndex(i)
						showCategoryIndex = i
						ReloadAchievements()
						MouseManager.ResetKey(1)
					endif
				endif
			Next
		endif
		

		GuiManager.Update( LS_office_achievements )

		if (MouseManager.IsClicked(2) or MouseManager.IsLongClicked(1))
			'leaving room now
			RemoveAllGuiElements()
		endif
	End Method


	Method Render()
		SetColor(255,255,255)


		'=== CATEGORY SELECTION ===

		GetBitmapFont("default", 13, BOLDFONT).DrawStyled(GetLocale("ACHIEVEMENTCATEGORY_CATEGORIES"), 40, 35, TColor.CreateGrey(140), TBitmapFont.STYLE_EMBOSS, 1, 0.5)

		For local i:int = 0 to TVTAchievementCategory.count
			local title:string = GetLocale( "ACHIEVEMENTCATEGORY_" + TVTAchievementCategory.GetAsString(TVTAchievementCategory.GetAtIndex(i)) )
			if highlightNavigationEntry = i
				GetBitmapFont("default", 13, BOLDFONT).DrawStyled(Chr(183) + " " + title, 40, 65 + i*20, TColor.CreateGrey(50), TBitmapFont.STYLE_EMBOSS, 1, 0.5)
			elseif i = showCategoryIndex
				GetBitmapFont("default", 13, BOLDFONT).DrawStyled(Chr(183) + " " + title, 40, 65 + i*20, TColor.Create(90,180,220), TBitmapFont.STYLE_EMBOSS, 1, 0.5)
			else
				GetBitmapFont("default", 13, BOLDFONT).DrawStyled(Chr(183) + " " + title, 40, 65 + i*20, TColor.CreateGrey(120), TBitmapFont.STYLE_EMBOSS, 1, 0.5)
			endif
		Next



		'=== ACHIEVEMENT LIST ===

		local skin:TDatasheetSkin = GetDatasheetSkin("achievements")

		'where to draw
		local outer:TRectangle = new TRectangle
		'calculate position/size of content elements
		local contentX:int = 0
		local contentY:int = 0
		local contentW:int = 0
		local contentH:int = 0
		local outerSizeH:int = skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()
		local outerH:int = 0 'size of the "border"
		
		local titleH:int = 18


		'=== ACHIEVEMENT LIST ===
		outer.Init(200, 25, 550, 325)
		contentX = skin.GetContentX(outer.GetX())
		contentY = skin.GetContentY(outer.GetY())
		contentW = skin.GetContentW(outer.GetW())
		contentH = skin.GetContentH(outer.GetH())

		local listH:int = contentH - titleH

		local caption:string = GetLocale("ACHIEVEMENTS")
		caption :+ " ~q" + GetLocale( "ACHIEVEMENTCATEGORY_" + TVTAchievementCategory.GetAsString(showCategory) ) + "~q"
		if categoryCountCompleted.length > showCategoryIndex
			caption :+ " [" + categoryCountCompleted[showCategoryIndex] + "/" + categoryCountMax[showCategoryIndex] + "]"
		endif
		

		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
		GetBitmapFontManager().Get("default", 13	, BOLDFONT).drawBlock(caption, contentX + 5, contentY-1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
		contentY :+ titleH
		skin.RenderContent(contentX, contentY, contentW, listH , "2")
		'reposition list
		if achievementList.rect.getX() <> contentX + 5
			achievementList.rect.SetXY(contentX + 5, contentY + 3)
			achievementList.Resize(contentW - 8, listH - 6)
		endif
		contentY :+ listH

		skin.RenderBorder(outer.GetIntX(), outer.GetIntY(), outer.GetIntW(), outer.GetIntH())

		GuiManager.Draw( LS_office_achievements )

		'draw achievement-sheet
		'if hoveredGuiProductionConcept then hoveredGuiProductionConcept.DrawSupermarketSheet()
 	End Method
End Type




Type TGUIAchievementListItem Extends TGUISelectListItem
	Field achievement:TAchievement
	Field displayName:string = ""

	Const paddingBottom:Int	= 2
	Const paddingTop:Int = 3


	Method CreateSimple:TGUIAchievementListItem(achievement:TAchievement)
		'make it "unique" enough
		Self.Create(Null, Null, achievement.GetGUID())

		self.displayName = achievement.GetTitle()

		'resize it
		GetDimension()

		Return Self
	End Method


    Method Create:TGUIAchievementListItem(pos:TVec2D=Null, dimension:TVec2D=Null, value:String="")
		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(pos, dimension, "")

		SetValueColor(TColor.Create(0,0,0))
		
'		GUIManager.add(Self)

		Return Self
	End Method

'rem
	Method getDimension:TVec2D()
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(Self.getParent("tguiscrollablepanel"))
		Local maxWidth:Int = 300
		If parentPanel Then maxWidth = parentPanel.getContentScreenWidth() '- GetScreenWidth()
		Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text

		Local dimension:TVec2D = New TVec2D.Init(maxWidth, GetSpriteFromRegistry("gfx_datasheet_achievement_bg").GetHeight())
		
		'add padding
		dimension.addXY(0, Self.paddingTop)
		dimension.addXY(0, Self.paddingBottom)

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If Self.rect.getW() <> dimension.getX() Or Self.rect.getH() <> dimension.getY()
			'resize item
			Self.Resize(dimension.getX(), dimension.getY())
		EndIf

		Return dimension
	End Method
'endrem

	'override to not draw anything
	'as "highlights" are drawn in "DrawValue"
	Method DrawBackground()
		'nothing
	End Method


	'override
	Method DrawValue()
		DrawAchievement(GetScreenX(), GetScreenY() + Self.paddingTop, GetScreenWidth(), GetScreenHeight() - Self.paddingBottom - Self.paddingTop, TAchievement(data.Get("achievement")))

		If isHovered()
			SetBlend LightBlend
			SetAlpha 0.10 * GetAlpha()

			DrawAchievement(GetScreenX(), GetScreenY() + Self.paddingTop, GetScreenWidth(), GetScreenHeight() - Self.paddingBottom - Self.paddingTop, TAchievement(data.Get("achievement")))

			SetBlend AlphaBlend
			SetAlpha 10.0 * GetAlpha()
		EndIf
	End Method


	Function DrawAchievement(x:Float, y:Float, w:Float, h:Float, achievement:TAchievement)
		local title:string = achievement.GetTitle() ' + " [c:"+achievement.category+" > g:"+achievement.group+" > i:"+achievement.index+"   "+achievement.GetGUID()+"]"
		local text:string = achievement.GetText()

		local skin:TDatasheetSkin = GetDatasheetSkin("achievement")

		local titleOffsetX:int = 3, titleOffsetY:int = 3
		local textOffsetX:int = 3, textOffsetY:int = 15

		local sprite:TSprite = GetSpriteFromRegistry("gfx_datasheet_achievement_bg")
		sprite.DrawArea(x,y,w,h)
		local achievementSprite:TSprite
		if achievement.IsCompleted( GetPlayerBaseCollection().playerID )
			if achievement.spriteFinished
				achievementSprite = GetSpriteFromRegistry( achievement.spriteFinished )
			endif

			if not achievementSprite
				achievementSprite = GetSpriteFromRegistry( "gfx_datasheet_achievement_img_ok" )
			endif
		else
			if achievement.spriteUnfinished
				achievementSprite = GetSpriteFromRegistry( achievement.spriteUnfinished )
			endif

			'reset title / text
			title = "? ? ? ? ? ?"
			text = ""
		endif

		if achievementSprite then achievementsprite.Draw(x+6, y+5)

		local border:TRectangle = sprite.GetNinePatchContentBorder()

		local oldCol:TColor = new TColor.Get()

		SetAlpha( Max(0.6, oldCol.a) )
		skin.fontSemiBold.drawBlock( ..
			title, ..
			x + textOffsetX + border.GetLeft(), ..
			y + titleOffsetY + border.GetTop(), .. '-1 to align it more properly
			w - textOffsetX - (border.GetRight() + border.GetLeft()),  ..
			15, ..
			ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)

		SetAlpha( Max(0.6, oldCol.a) )
		skin.fontNormal.drawBlock( ..
			text, ..
			x + textOffsetX + border.GetLeft(), ..
			y + titleOffsetY + border.GetTop(), .. '-1 to align it more properly
			w - textOffsetX - (border.GetRight() + border.GetLeft()),  ..
			Max(15, sprite.GetHeight() - (border.GetTop() + border.GetBottom())), ..
			ALIGN_LEFT_CENTER, skin.textColorNeutral)

		SetAlpha (oldCol.a)
	End Function


	Method DrawContent()
		if isSelected()
			SetColor 245,230,220
			Super.DrawContent()

			SetColor 220,210,190
			SetAlpha GetAlpha() * 0.10
			SetBlend LightBlend
			Super.DrawContent()
			SetBlend AlphaBlend
			SetAlpha GetAlpha() * 10

			SetColor 255,255,255
		else
			Super.DrawContent()
		endif
	End Method


	Method DrawDatasheet(leftX:Float=30, rightX:Float=30)
		Local sheetY:Float 	= 20
		Local sheetX:Float 	= int(leftX)
		Local sheetAlign:Int= 0
		If MouseManager.x < GetGraphicsManager().GetWidth()/2
			sheetX = GetGraphicsManager().GetWidth() - int(rightX)
			sheetAlign = 1
		EndIf

		SetColor 0,0,0
		SetAlpha 0.2
		local sheetCenterX:Float = sheetX
		if sheetAlign = 0
			sheetCenterX :+ 250/2 '250 is sheetWidth
		else
			sheetCenterX :- 250/2 '250 is sheetWidth
		endif
		Local tri:Float[]=[sheetCenterX,sheetY+25, sheetCenterX,sheetY+90, getScreenX() + getScreenWidth()/2.0, getScreenY() + GetScreenHeight()/2.0]
		DrawPoly(tri)
		SetColor 255,255,255
		SetAlpha 1.0

		ShowAchievementSheet(achievement, sheetX, sheetY, sheetAlign, FALSE)
	End Method


	Function ShowAchievementSheet:Int(achievement:TAchievement, x:Float,y:Float, align:int=0, showAmateurInformation:int = False)
		'=== PREPARE VARIABLES ===
		local sheetWidth:int = 250
		local sheetHeight:int = 0 'calculated later
		'move sheet to left when right-aligned
		if align = 1 then x = x - sheetWidth

		local skin:TDatasheetSkin = GetDatasheetSkin("cast")
		local contentW:int = skin.GetContentW(sheetWidth)
		local contentX:int = int(x) + skin.GetContentX()
		local contentY:int = int(y) + skin.GetContentY()
rem
		'=== CALCULATE SPECIAL AREA HEIGHTS ===
		local titleH:int = 18, imageH:int = 50, descriptionH:int = 50
		local splitterHorizontalH:int = 6
		local boxH:int = 0, barH:int = 0
		local boxAreaH:int = 0, barAreaH:int = 0, msgAreaH:int = 0
		local boxAreaPaddingY:int = 4, barAreaPaddingY:int = 4

		boxH = skin.GetBoxSize(89, -1, "", "spotsPlanned", "neutral").GetY()
		barH = skin.GetBarSize(100, -1).GetY()
		titleH = Max(titleH, 3 + GetBitmapFontManager().Get("default", 13, BOLDFONT).getBlockHeight(cast.GetFullName(), contentW - 10, 100))

		'bar area starts with padding, ends with padding and contains
		'also contains 8 bars
		if celebrity and not showAmateurInformation
			barAreaH = 2 * barAreaPaddingY + 7 * (barH + 2)
		endif
		
		'box area
		'contains 1 line of boxes + padding at the top
		boxAreaH = 1 * boxH + 1 * boxAreaPaddingY

		'total height
		sheetHeight = titleH + jobDescriptionH + lifeDataH + lastProductionsH + barAreaH + boxAreaH + skin.GetContentPadding().GetTop() + skin.GetContentPadding().GetBottom()


		'=== RENDER ===

		'=== TITLE AREA ===
		skin.RenderContent(contentX, contentY, contentW, titleH, "1_top")
			local title:string = cast.GetFullName()
			if showAmateurInformation
				title = GetLocale("JOB_AMATEUR")
			endif
			
			if titleH <= 18
				GetBitmapFont("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY -1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			else
				GetBitmapFont("default", 13, BOLDFONT).drawBlock(title, contentX + 5, contentY +1, contentW - 10, titleH, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			endif
		contentY :+ titleH


		if not showAmateurInformation	
			'=== JOB DESCRIPTION AREA ===
			if jobDescriptionH > 0
				skin.RenderContent(contentX, contentY, contentW, jobDescriptionH, "1")

				local firstJobID:int = -1
				for local jobIndex:int = 1 to TVTProgrammePersonJob.Count 
					local jobID:int = TVTProgrammePersonJob.GetAtIndex(jobIndex)
					if not cast.HasJob(jobID) then continue

					firstJobID = jobID
					exit
				next

				local genre:int = cast.GetTopGenre()
				local genreText:string = ""
				if genre >= 0 then genreText = GetLocale("PROGRAMME_GENRE_" + TVTProgrammeGenre.GetAsString(genre))
				if genreText then genreText = "~q" + genreText+"~q-"

				if firstJobID >= 0
					'add genre if you know the job
					skin.fontNormal.drawBlock(genreText + GetLocale("JOB_"+TVTProgrammePersonJob.GetAsString(firstJobID)), contentX + 5, contentY, contentW - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
				else
					'use the given jobID but declare as amateur
					if jobID > 0
						skin.fontNormal.drawBlock(GetLocale("JOB_AMATEUR_"+TVTProgrammePersonJob.GetAsString(jobID)), contentX + 5, contentY, contentW - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
					else
						skin.fontNormal.drawBlock(GetLocale("JOB_AMATEUR"), contentX + 5, contentY, contentW - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
					endif
				endif

				contentY :+ jobDescriptionH
			endif


			'=== LIFE DATA AREA ===
			skin.RenderContent(contentX, contentY, contentW, lifeDataH, "1")
			'splitter
			GetSpriteFromRegistry("gfx_datasheet_content_splitterV").DrawArea(contentX + 5 + 165, contentY, 2, jobDescriptionH)
			local latinCross:string = Chr(10013) '† = &#10013 ---NOT--- &#8224; (the dagger-cross)
			if celebrity
				local dob:String = GetWorldTime().GetFormattedDate( GetWorldTime().GetTimeGoneFromString(celebrity.dayOfBirth), "d.m.y")
				skin.fontNormal.drawBlock(dob +" ("+celebrity.GetAge()+" J.)", contentX + 5, contentY, 165 - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
				skin.fontNormal.drawBlock(celebrity.countryCode, contentX + 170 + 5, contentY, contentW - 170 - 10, jobDescriptionH -1, ALIGN_LEFT_CENTER, skin.textColorNeutral, 0,1,1.0,True, True)
			endif
			contentY :+ lifeDataH


			'=== LAST PRODUCTIONS AREA ===
			skin.RenderContent(contentX, contentY, contentW, lastProductionsH, "2")

			contentY :+ 3
			if celebrity
				'last productions
				if celebrity.GetProducedProgrammes().length > 0
					local productionGUIDs:string[] = celebrity.GetProducedProgrammes()
					local i:int = 0
					local entryNum:int = 0
					while i < productionGUIDs.length and entryNum < 3
						local production:TProgrammeData = GetProgrammeDataCollection().GetByGUID( productionGUIDs[ i] )
						i :+ 1
						if not production then continue

						skin.fontSemiBold.drawBlock(production.GetYear(), contentX + 5, contentY + lastProductionEntryH*entryNum, contentW, lastProductionEntryH, null, skin.textColorNeutral)
						if production.IsInProduction()
							skin.fontNormal.drawBlock(production.GetTitle() + " (In Produktion)", contentX + 5 + 30 + 5, contentY + lastProductionEntryH*entryNum , contentW  - 10 - 30 - 5, lastProductionEntryH, null, skin.textColorNeutral)
						else
							skin.fontNormal.drawBlock(production.GetTitle(), contentX + 5 + 30 + 5, contentY + lastProductionEntryH*entryNum , contentW  - 10 - 30 - 5, lastProductionEntryH, null, skin.textColorNeutral)
						endif
						entryNum :+1
					Wend
				endif
			endif
			contentY :+ lastProductionsH - 3
		endif

		'=== BARS / BOXES AREA ===
		'background for bars + boxes
		if barAreaH + boxAreaH > 0
			skin.RenderContent(contentX, contentY, contentW, barAreaH + boxAreaH, "1_bottom")
		endif


		'===== DRAW CHARACTERISTICS / BARS =====
		'TODO: only show specific data of a cast, "all" should not be
		'      exposed until we eg. produce specific "insight"-shows ?
		'      -> or have some "agent" to pay to get such information

		if celebrity
			'bars have a top-padding
			contentY :+ barAreaPaddingY
			'XP
			skin.RenderBar(contentX + 5, contentY, 100, 12, celebrity.GetExperiencePercentage(jobID))
			skin.fontSemiBold.drawBlock(GetLocale("CAST_EXPERIENCE"), contentX + 5 + 100 + 5, contentY, 125, 15, null, skin.textColorLabel)
			contentY :+ barH + 2


			local genreDefinition:TMovieGenreDefinition
			if TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept
				local script:TScript = TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.script
				if script then genreDefinition = GetMovieGenreDefinition( script.mainGenre )
			endif

			local attributes:int[] = [TVTProgrammePersonAttribute.FAME, ..
			                          TVTProgrammePersonAttribute.SKILL, ..
			                          TVTProgrammePersonAttribute.POWER, ..
			                          TVTProgrammePersonAttribute.HUMOR, ..
			                          TVTProgrammePersonAttribute.CHARISMA, ..
			                          TVTProgrammePersonAttribute.APPEARANCE ..
			                         ]
			For local attributeID:int = EachIn attributes
				local mode:int = 0

				local attributeFit:Float = 0.0
				local attributeGenre:Float = 0.0
				local attributePerson:Float = 0.0
				if genreDefinition
					attributeGenre = genreDefinition.GetCastAttribute(jobID, attributeID)
					attributePerson = celebrity.GetAttribute(attributeID)
				endif

				'unimportant attribute / no bonus/malus for this attribute
				if MathHelper.AreApproximatelyEqual(attributeGenre, 0.0)
					mode = 1
				'neutral
'				elseif MathHelper.AreApproximatelyEqual(attributePerson, 0.0) 
'					mode = 2
				'negative
				elseif attributeGenre < 0
					mode = 3
				'positive
				else
					mode = 4
				endif

				'set "skill" neutral if not assigned "negative/positive" already
				if mode = 1 and attributeID = TVTProgrammePersonAttribute.SKILL
					mode = 2
				endif
			

				select mode
					'unused
					case 1
						local oldA:Float = GetAlpha()
						SetAlpha oldA * 0.4
						skin.RenderBar(contentX + 5, contentY, 100, 12, celebrity.GetAttribute(attributeID))
						SetAlpha oldA * 0.3
						skin.fontSemiBold.drawBlock(GetLocale("CAST_"+TVTProgrammePersonAttribute.GetAsString(attributeID).ToUpper()), contentX + 5 + 100 + 5, contentY, 125, 15, null, skin.textColorLabel)
						SetAlpha oldA
					'neutral
					case 2
						skin.RenderBar(contentX + 5, contentY, 100, 12, celebrity.GetAttribute(attributeID))
						skin.fontSemiBold.drawBlock(GetLocale("CAST_"+TVTProgrammePersonAttribute.GetAsString(attributeID).ToUpper()), contentX + 5 + 100 + 5, contentY, 125, 15, null, skin.textColorLabel)
					'negative
					case 3
						skin.RenderBar(contentX + 5, contentY, 100, 12, celebrity.GetAttribute(attributeID))
						skin.fontSemiBold.drawBlock(GetLocale("CAST_"+TVTProgrammePersonAttribute.GetAsString(attributeID).ToUpper()), contentX + 5 + 100 + 5, contentY, 125, 15, null, skin.textColorBad)

					'positive
					case 4
						skin.RenderBar(contentX + 5, contentY, 100, 12, celebrity.GetAttribute(attributeID))
						skin.fontSemiBold.drawBlock(GetLocale("CAST_"+TVTProgrammePersonAttribute.GetAsString(attributeID).ToUpper()), contentX + 5 + 100 + 5, contentY, 125, 15, null, skin.textColorGood)
				End Select
				contentY :+ barH + 2
			Next
		endif

		'=== MESSAGES ===
		'TODO: any chances of "not available from day x-y of 1998"

		'=== BOXES ===
		'boxes have a top-padding (except with messages)
		if msgAreaH = 0 then contentY :+ boxAreaPaddingY

		if celebrity
			contentY :+ boxAreaPaddingY
		endif
		if jobID >= 0
			skin.fontSemibold.drawBlock(GetLocale("JOB_"+TVTProgrammePersonJob.GetAsString(jobID)), contentX + 5, contentY, 94, 25, ALIGN_LEFT_CENTER, skin.textColorLabel)
			skin.RenderBox(contentX + 5 + 94, contentY, contentW - 10 - 94 +1, -1, TFunctions.DottedValue(cast.GetBaseFee(jobID, TScreenHandler_SupermarketProduction.GetInstance().currentProductionConcept.script.blocks)), "money", "neutral", skin.fontBold, ALIGN_RIGHT_CENTER)
		endif
		contentY :+ boxH
endrem

		'=== OVERLAY / BORDER ===
		skin.RenderBorder(int(x), int(y), sheetWidth, sheetHeight)
	End Function

End Type
