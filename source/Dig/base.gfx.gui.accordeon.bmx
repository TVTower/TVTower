Rem
	===========================================================
	GUI Button
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"


Type TGUIAccordeonPanel extends TGUIObject
	Field isOpen:int = False
	Field fixedSize:TVec2D = new TVec2D.Init(-1,-1)


	Method Create:TGUIAccordeonPanel(pos:TVec2D, dimension:TVec2D, value:String, State:String = "")
		'setup base widget
		Super.CreateBase(pos, dimension, State)

		SetValue(value)

    	GUIManager.Add(Self)
		Return Self
	End Method
	

	Method New()
'		setOption(GUI_OBJECT_CLICKABLE, False)
		setOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)
	End Method
	
	
	Method Close:int()
		if isOpen = False then return True

		isOpen = False
		SetAppearanceChanged(True)

		'adjust parental accordeon
		if TGUIAccordeon(GetParent()) then TGUIAccordeon(GetParent()).onClosePanel(self)

		EventManager.triggerEvent( TEventSimple.Create("guiaccordeonpanel.OnClose", null, Self) )
		
		return True
	End Method


	Method Open:int()
		if isOpen = true then return True

		isOpen = True
		SetAppearanceChanged(True)

		'adjust parental accordeon
		if TGUIAccordeon(GetParent()) then TGUIAccordeon(GetParent()).onOpenPanel(self)

		EventManager.triggerEvent( TEventSimple.Create("guiaccordeonpanel.OnOpen", null, Self) )

		return True
	End Method


	Method GetHeaderHeight:Float()
		return 16
	End Method


	Method GetHeaderScreenHeight:Float()
		return GetHeaderHeight()
	End Method


	Method GetBodyY:Float()
		'displace by header
		Return GetHeaderHeight()
	End Method


	Method GetBodyHeight:Float()
		if isOpen
			if fixedSize.y = -1
				return Max(0, GetScreenHeight() - GetHeaderScreenHeight())
			else
				return Max(0, fixedSize.y - GetHeaderScreenHeight())
			endif
		else
			return 0
		endif
	End Method


	Method GetHeight:int()
		if isOpen
			if fixedSize.y = -1
				return Max(Super.GetHeight(), GetHeaderHeight())
			else
				return Max(fixedSize.y, GetHeaderHeight())
			endif
		endif
		return GetHeaderHeight()
	End Method


	Method GetScreenHeight:Float()
		return GetHeight()
	End Method


	Method GetWidth:Int()
		if fixedSize.x = -1 then return Super.GetWidth()
		return fixedSize.x
	End Method


	Method DrawHeader()
		SetColor 80, abs(255 - (25 * _id)) mod 255, (35 * _id) mod 255
		DrawRect( GetScreenX(), GetScreenY(), GetScreenWidth(), GetHeaderScreenHeight() )

		if IsHovered()
			SetColor 250,250,250
		else
			SetColor 0, 0, 0
		endif
		local openStr:string = Chr(9654)
		if isOpen then openStr = Chr(9660)
		if TGUIAccordeon(GetParent())
			DrawText(openStr + " Panel #" + TGUIAccordeon(GetParent()).GetPanelIndex(self), GetScreenX(), GetScreenY())
		else
			DrawText(openStr + " Panel [id=" + _id+"]", GetScreenX(), GetScreenY())
		endif
		SetColor 255,255,255
	End Method


	Method DrawBody()
		SetColor 120,120,120
		DrawRect( GetScreenX(), GetScreenY() + GetHeaderScreenHeight(), GetScreenWidth(), GetBodyHeight() )
		SetColor 255,255,255
	End Method


	Method DrawContent()
		'draw header after the body so potential "shadows" are drawn
		'correctly
		DrawBody()
		DrawHeader()
	End Method


	'override to toggle open/close
	Method onClick:Int(triggerEvent:TEventBase)
		local coord:TVec2D = TVec2D(triggerEvent.GetData().Get("coord"))
		local headerScreenRect:TRectangle = new TRectangle.Init(GetScreenX(), GetScreenY(), GetScreenWidth(), GetHeaderScreenHeight())
		if headerScreenRect.containsVec( coord )
			if isOpen
				Close()
			else
				Open()
			endif
		endif

		Return Super.onClick(triggerEvent)
	End Method
End Type




Type TGUIAccordeon extends TGUIObject
	Field panels:TGUIAccordeonPanel[]

	Field _panelsFillAccordeon:int = True
	Field _allowMultipleOpenPanels:int = False
	Field _disableRefitPanelSizes:int = False
	


'	Method New()
'		setOption(GUI_OBJECT_CLICKABLE, False)
'		setOption(GUI_OBJECT_CAN_GAIN_FOCUS, False)
'	End Method

		
	Method Create:TGUIAccordeon(pos:TVec2D, dimension:TVec2D, value:String, State:String = "")
		'setup base widget
		Super.CreateBase(pos, dimension, State)

		SetValue(value)

    	GUIManager.Add(Self)
		Return Self
	End Method


	Method onOpenPanel:int(panel:TGUIAccordeonPanel)
		local disableRefitPanelSizesBackup:int = _disableRefitPanelSizes
		'avoid running multiple refits during closing other panels
		_disableRefitPanelSizes = true
		
		'close all other open panels
		if not _allowMultipleOpenPanels
			For local i:int = 0 until panels.length
				if panels[i] = panel then continue
				if panels[i].isOpen then panels[i].Close()
			Next
		endif

		_disableRefitPanelSizes = disableRefitPanelSizesBackup
		if not _disableRefitPanelSizes then RefitPanelSizes()

		EventManager.triggerEvent( TEventSimple.Create("guiaccordeon.OnOpenPanel", new TData.Add("panel", panel), Self) )

		return True
	End Method


	Method onClosePanel:int(panel:TGUIAccordeonPanel)
		'if no panel is open now, keep the closing one opened
		if GetOpenPanelCount() = 0
			panel.Open()
			return False
		endif
		
		RefitPanelSizes()

		EventManager.triggerEvent( TEventSimple.Create("guiaccordeon.OnClosePanel", new TData.Add("panel", panel), Self) )

		return True
	End Method
	

	Method OpenPanel:int(index:int)
		local child:TGUIAccordeonPanel = TGUIAccordeonPanel( GetPanelAtIndex(index) )
		if not child then return False
		return child.Open()
	End Method 
		

	Method ClosePanel:int(index:int)
		local child:TGUIAccordeonPanel = TGUIAccordeonPanel( GetPanelAtIndex(index) )
		if not child then return False
		return child.Close()
	End Method


	'override, remove panels too
	Method RemoveChild:Int(child:TGUIobject)
		if TGUIAccordeonPanel(child)
			RemovePanel(TGUIAccordeonPanel(child))
		endif

		return Super.RemoveChild(child)
	End Method
	

	Method AddPanel:int(panel:TGUIAccordeonPanel, index:int = -1)
		if not panel then return False
		'already added ?
		if GetPanelIndex(panel) >= 0 then return False

		if not panels
			panels = [panel]
		else
			'within existing or "next" index
			index = Min(panels.length, index)

			if index = panels.length
				panels :+ [panel]
			elseif index = 0
				panels = [panel] + panels
			else
				panels = panels[.. index] + [panel] + panels[index ..]
			endif
		endif

		panel.SetParent(self)
		'accordeon manages the panel
		GUIManager.remove(panel)

		RefitPanelSizes()

		return True
	End Method


	Method RemovePanel:int(panel:TGUIAccordeonPanel)
		if not panel or not panels then return False

		local newPanels:TGUIAccordeonPanel[] = new TGUIAccordeonPanel[0]
		local removedSomething:int = False
		for local p:TGUIAccordeonPanel = EachIn panels
			if p = panel
				p.SetParent(null)
				removedSomething = True
				continue
			endif

			newPanels :+ [p]
		next

		panels = newPanels

		if removedSomething then RefitPanelSizes()

		return removedSomething
	End Method


	Method GetPanelAtIndex:TGUIAccordeonPanel(index:int)
		if index < 0 or not panels or index >= panels.length then return Null

		return panels[index]
	End Method


	Method GetPanelIndex:int(panel:TGUIAccordeonPanel)
		if not panels or panels.length = 0 then return -1

		for local i:int = 0 until panels.length
			if panels[i] = panel then return i
		next

		return -1
	End Method


	Method GetOpenPanelCount:int()
		local openPanels:int = 0
		for local i:int = 0 until panels.length
			if panels[i].isOpen then openPanels :+ 1
		next
		return openPanels
	End Method


	Method GetPanelCount:int()
		if not panels then return 0
		return panels.length
	End Method


	Method GetTotalPanelHeadersHeight:int()
		if not panels then return 0
		
		local panelHeadersHeight:int = 0
		for local p:TGUIAccordeonPanel = EachIn panels
			panelHeadersHeight :+ p.GetHeaderHeight()
		next
		return panelHeadersHeight
	End Method


	'returns the maximum height for an open panel's body
	Method GetMaxPanelBodyHeight:int()
		return Max(0, GetHeight() - GetTotalPanelHeadersHeight())
	End Method


	Method RefitPanelSizes:int()
		if not panels then return False

		local panelX:int = 0
		local panelY:int = 0
		For local p:TGUIAccordeonPanel = Eachin panels
			p.SetPosition(panelX, panelY)

			if not p.isOpen
				p.Resize(GetContentWidth(), -1)
				panelY :+ p.GetHeaderHeight()
			else
				'auto height
				if not p.fixedSize or p.fixedSize.y = -1
					if _panelsFillAccordeon and not _allowMultipleOpenPanels
						p.Resize(GetContentWidth(), p.GetHeaderHeight() + GetMaxPanelBodyHeight())
					else
						p.Resize(GetContentWidth(), p.GetHeaderHeight() + p.GetBodyHeight())
					endif
				endif
				
				panelY :+ p.GetHeight()
			endif
		Next
	End Method


	'override to add panels
	Method UpdateChildren:int()
		if panels
			For local p:TGUIAccordeonPanel = EachIn panels
				p.Update()
			Next
		endif
	End Method

	'override to add panels
	Method DrawChildren:int()
		if panels
			For local p:TGUIAccordeonPanel = EachIn panels
				p.Draw()
			Next
		endif
		Super.DrawChildren()
	End Method


	'override to add panels
	Method DrawTooltips:int()
		if panels
			For local p:TGUIAccordeonPanel = EachIn panels
				p.DrawTooltips()
			Next
		endif
		Super.DrawTooltips()
	End Method	


	Method DrawContent()
		'DrawRect( GetScreenX(), GetScreenY(), GetScreenWidth(), GetScreenHeight() )
	End Method
End Type