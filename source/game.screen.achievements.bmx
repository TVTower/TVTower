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

	Global LS_office_achievements:TLowerString = TLowerString.Create("office_achievements")
	Global _eventListeners:TEventListenerBase[]
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
		EventManager.UnregisterListenersArray(_eventListeners)
		_eventListeners = new TEventListenerBase[0]

		'=== register event listeners
		'to reload achievement list when entering a screen
		_eventListeners :+ [ EventManager.registerListenerFunction(GameEventKeys.Screen_OnBeginEnter, onEnterScreen, screen) ]

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
			achievementList = new TGUISelectList.Create(new SVec2I(210,60), new SVec2I(525, 280), "office_achievements")
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
			item.displayName = achievement.GetTitle()
			item.SetSize(400, 70)
			item.GetDimension()
			achievementList.AddItem( item )
		Next

		achievementList.RecalculateElements()
		'refresh scrolling state
		achievementList.SetSize(-1, -1)
	End Method


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

						'handled left click
						MouseManager.SetClickHandled(1)
					endif
				endif
			Next
		endif


		GuiManager.Update( LS_office_achievements )

		if MouseManager.IsClicked(2)
			'leaving room now
			RemoveAllGuiElements()

			'no mouse reset - we still want to leave the room
		endif
	End Method


	Method Render()
		SetColor(255,255,255)


		'=== CATEGORY SELECTION ===

		GetBitmapFont("default", 13, BOLDFONT).DrawSimple(GetLocale("ACHIEVEMENTCATEGORY_CATEGORIES"), 40, 33, new SColor8(140, 140, 140), EDrawTextEffect.Emboss, 0.5)

		For local i:int = 0 to TVTAchievementCategory.count
			local title:string = GetLocale( "ACHIEVEMENTCATEGORY_" + TVTAchievementCategory.GetAsString(TVTAchievementCategory.GetAtIndex(i)) )
			if highlightNavigationEntry = i
				GetBitmapFont("default", 13, BOLDFONT).DrawSimple(Chr(183) + " " + title, 40, 63 + i*20, new SColor8(50, 50, 50), EDrawTextEffect.Emboss, 0.5)
			elseif i = showCategoryIndex
				GetBitmapFont("default", 13, BOLDFONT).DrawSimple(Chr(183) + " " + title, 40, 63 + i*20, new SColor8(90, 180, 220), EDrawTextEffect.Emboss, 0.5)
			else
				GetBitmapFont("default", 13, BOLDFONT).DrawSimple(Chr(183) + " " + title, 40, 63 + i*20, new SColor8(120, 120,120), EDrawTextEffect.Emboss, 0.5)
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
		outer.Init(200, 25, 550, 324)
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
		GetBitmapFontManager().Get("default", 13, BOLDFONT).DrawBox(caption, contentX + 5, contentY, contentW - 10, titleH, sALIGN_LEFT_CENTER, skin.textColorNeutral)
		contentY :+ titleH
		skin.RenderContent(contentX, contentY, contentW, listH , "2")
		'reposition list
		if achievementList.rect.getX() <> contentX + 5
			achievementList.rect.SetXY(contentX + 5, contentY + 3)
			achievementList.SetSize(contentW - 8, listH - 6)
		endif
		contentY :+ listH

		skin.RenderBorder(outer.GetIntX(), outer.GetIntY(), outer.GetIntW(), outer.GetIntH())

		GuiManager.Draw( LS_office_achievements )

		'draw achievement-sheet
		'if hoveredGuiProductionConcept then hoveredGuiProductionConcept.DrawSupermarketSheet()
 	End Method
End Type




Type TGUIAchievementListItem Extends TGUISelectListItem
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


    Method Create:TGUIAchievementListItem(pos:SVec2I, dimension:SVec2I, value:String="")
		'no "super.Create..." as we do not need events and dragable and...
   		Super.CreateBase(pos, dimension, "")

		SetValueColor(TColor.Create(0,0,0))

'		GUIManager.add(Self)

		Return Self
	End Method

'rem
	Method getDimension:SVec2F() override
		'available width is parentsDimension minus startingpoint
		Local parentPanel:TGUIScrollablePanel = TGUIScrollablePanel(GetFirstParentalObject("tguiscrollablepanel"))
		Local maxWidth:Int = 400
		If parentPanel Then maxWidth = parentPanel.GetContentScreenRect().GetW() '- GetScreenRect().GetW()


		local titleOffsetX:int = 3, titleOffsetY:int = 1
		local textOffsetX:int = 3, textOffsetY:int = 15
		local skin:TDatasheetSkin = GetDatasheetSkin("achievement")
		local sprite:TSprite = GetSpriteFromRegistry("gfx_datasheet_achievement_bg")
		local border:SRect = sprite.GetNinePatchInformation().contentBorder
		local halfTextWidth:int = 0.5 * (GetScreenRect().GetW() - textOffsetX - (border.GetRight() + border.GetLeft()))
		local leftWidth:int = 1.25 * halfTextWidth
		local rightWidth:int = 0.75 * halfTextWidth

		'Local maxHeight:Int = 2000 'more than 2000 pixel is a really long text
		local maxTextHeight:int = Max(skin.fontNormal.GetBoxHeight(GetAchievementText(), leftWidth, 2000), ..
		                              skin.fontNormal.GetBoxHeight(GetAchievementRewardText(), rightWidth, 2000))
		Local maxHeight:Int = Max( sprite.GetHeight(), ..
		                           textOffsetY + border.GetTop() + border.GetBottom() + maxTextHeight ..
		                      )

		Local w:Float = maxWidth
		Local h:Float = maxHeight

		'add padding
		h :+ Self.paddingTop
		h :+ Self.paddingBottom

		'set current size and refresh scroll limits of list
		'but only if something changed (eg. first time or content changed)
		If Self.rect.w <> w Or Self.rect.h <> h
			'resize item
			Self.SetSize(w, h)
		EndIf

		Return new SVec2F(w, h)
	End Method
'endrem

	'override to not draw anything
	'as "highlights" are drawn in "DrawValue"
	Method DrawBackground()
		'nothing
	End Method


	'override
	Method DrawValue()
		DrawAchievement(GetScreenRect().GetX(), GetScreenRect().GetY() + Self.paddingTop, GetScreenRect().GetW(), GetScreenRect().GetH() - Self.paddingBottom - Self.paddingTop)

		If isHovered()
			SetBlend LightBlend
			SetAlpha 0.10 * GetAlpha()

			DrawAchievement(GetScreenRect().GetX(), GetScreenRect().GetY() + Self.paddingTop, GetScreenRect().GetW(), GetScreenRect().GetH() - Self.paddingBottom - Self.paddingTop)

			SetBlend AlphaBlend
			SetAlpha 10.0 * GetAlpha()
		EndIf
	End Method


	Method GetAchievementTitle:string()
		local achievement:TAchievement = TAchievement(data.Get("achievement"))
		if not achievement then return ""

		return achievement.GetTitle()
	End Method


	Method GetAchievementText:string()
		local achievement:TAchievement = TAchievement(data.Get("achievement"))
		if not achievement then return ""

		return achievement.GetText()
	End Method


	Method GetAchievementRewardText:string()
		local achievement:TAchievement = TAchievement(data.Get("achievement"))
		if not achievement then return "123"

		local rewardText:string
		For local i:int = 0 until achievement.GetRewards().length
			if rewardText <> "" then rewardText :+ "~n"
			rewardText :+ chr(9654) + " " +achievement.GetRewards()[i].GetTitle()
		Next
		if rewardText <> ""
			rewardText = "" + GetLocale("REWARD") + ":~n" + rewardText
		endif

		return rewardText
	End Method


	Method GetAchievementLongText:string()
		local rewardText:string = GetAchievementRewardText()
		if rewardText
			return GetAchievementText()
		else
			return GetAchievementText()
		endif
	End Method



	Method DrawAchievement(x:Float, y:Float, w:Float, h:Float)
		local title:string = GetAchievementTitle()
		local textLeft:string, textRight:string
		local achievement:TAchievement = TAchievement(data.get("achievement"))
		if not achievement then return

		local skin:TDatasheetSkin = GetDatasheetSkin("achievement")

		local titleOffsetX:int = 3, titleOffsetY:int = 1
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

			textLeft = GetAchievementText()
			textRight = GetAchievementRewardText()
		else
			if achievement.spriteUnfinished
				achievementSprite = GetSpriteFromRegistry( achievement.spriteUnfinished )
			endif

			'reset title / text
			title = "? ? ? ? ? ?"
			textLeft = ""
			textRight = ""
		endif

		'draw background-icon (question mark)
		GetSpriteFromRegistry( "gfx_datasheet_achievement_img" ).Draw(x+4,y+3)
		if achievementSprite then achievementsprite.Draw(x+6, y+5)

		local border:SRect = sprite.GetNinePatchInformation().contentBorder

		local oldColA:Float = GetAlpha()

		SetAlpha( Max(0.6, oldColA) )
		skin.fontSemiBold.DrawBox( ..
			title, ..
			x + textOffsetX + border.GetLeft(), ..
			y + titleOffsetY + border.GetTop(), .. '-1 to align it more properly
			w - textOffsetX - (border.GetRight() + border.GetLeft()),  ..
			17, ..
			sALIGN_LEFT_CENTER, skin.textColorNeutral)


		if textRight <> ""
			local halfTextWidth:int = 0.5 * (w - textOffsetX - (border.GetRight() + border.GetLeft()))
			local leftWidth:int = 1.25 * halfTextWidth
			local rightWidth:int = 0.75 * halfTextWidth

			SetAlpha( Max(0.6, oldColA) )
			skin.fontNormal.DrawBox( ..
				textLeft, ..
				x + textOffsetX + border.GetLeft(), ..
				y + textOffsetY + border.GetTop(), ..
				leftWidth - 10,  ..
				Max(17, GetScreenRect().GetH() - (border.GetTop() + border.GetBottom() + 15)), ..
				sALIGN_LEFT_TOP, skin.textColorNeutral)

			skin.fontNormal.DrawBox( ..
				textRight, ..
				x + textOffsetX + border.GetLeft() + leftWidth + 10, ..
				y + textOffsetY + border.GetTop(), ..
				rightWidth - 10,  ..
				Max(17, GetScreenRect().GetH() - (border.GetTop() + border.GetBottom() + 15)), ..
				sALIGN_LEFT_TOP, skin.textColorNeutral)
			SetAlpha (oldColA)
		else
			SetAlpha( Max(0.6, oldColA) )
			skin.fontNormal.DrawBox( ..
				textLeft, ..
				x + textOffsetX + border.GetLeft(), ..
				y + textOffsetY + border.GetTop(), .. '-1 to align it more properly
				w - textOffsetX - (border.GetRight() + border.GetLeft()),  ..
				Max(17, sprite.GetHeight() - (border.GetTop() + border.GetBottom() + 15)), ..
				sALIGN_LEFT_CENTER, skin.textColorNeutral)
			SetAlpha (oldColA)
		endif

	End Method


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
End Type
