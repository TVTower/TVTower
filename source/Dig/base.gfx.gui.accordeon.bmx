Rem
	===========================================================
	GUI Button
	===========================================================
End Rem
SuperStrict
Import "base.gfx.gui.bmx"


Type TGUIAccordeonPanel Extends TGUIObject
	Field isOpen:Int = False
	Field fixedSize:TVec2D = New TVec2D.Init(-1,-1)


	Method GetClassName:String()
		Return "tguiaccordeonpanel"
	End Method


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


	Method Close:Int()
		If isOpen = False Then Return True

		isOpen = False
		SetAppearanceChanged(True)

		'adjust parental accordeon
		If TGUIAccordeon(_parent) Then TGUIAccordeon(_parent).onClosePanel(Self)

		TriggerBaseEvent(GUIEventKeys.GUIAccordeonPanel_OnClose, Null, Self)

		Return True
	End Method


	Method Open:Int()
		If isOpen = True Then Return True

		isOpen = True
		SetAppearanceChanged(True)

		'adjust parental accordeon
		If TGUIAccordeon(_parent) Then TGUIAccordeon(_parent).onOpenPanel(Self)

		TriggerBaseEvent(GUIEventKeys.GUIAccordeonPanel_OnOpen, Null, Self)

		Return True
	End Method


	Method GetHeaderHeight:Float()
		Return 16
	End Method


	Method GetHeaderScreenHeight:Float()
		Return GetHeaderHeight()
	End Method


	Method GetBodyY:Float()
		'displace by header
		Return GetHeaderHeight()
	End Method


	Method GetBodyHeight:Float()
		If isOpen
			If fixedSize.y = -1
				Return Max(0, GetScreenRect().GetH() - GetHeaderScreenHeight())
			Else
				Return Max(0, fixedSize.y - GetHeaderScreenHeight())
			EndIf
		Else
			Return 0
		EndIf
	End Method


	Method GetHeight:Int()
		If isOpen
			If fixedSize.y = -1
				Return Max(Super.GetHeight(), GetHeaderHeight())
			Else
				Return Max(fixedSize.y, GetHeaderHeight())
			EndIf
		EndIf
		Return GetHeaderHeight()
	End Method


	Method GetWidth:Int()
		If fixedSize.x = -1 Then Return Super.GetWidth()
		Return fixedSize.x
	End Method


	Method _UpdateScreenH:Float()
		_screenRect.SetH( GetHeight() )
		return _screenRect.GetH()
	End Method


	Method DrawHeader()
		SetColor 80, Abs(255 - (25 * _id)) Mod 255, (35 * _id) Mod 255
		DrawRect( GetScreenRect().GetX(), GetScreenRect().GetY(), GetScreenRect().GetW(), GetScreenRect().GetH() )

		If IsHovered()
			SetColor 250,250,250
		Else
			SetColor 0, 0, 0
		EndIf
		Local openStr:String = Chr(9654)
		If isOpen Then openStr = Chr(9660)
		If TGUIAccordeon(_parent)
			DrawText(openStr + " Panel #" + TGUIAccordeon(_parent).GetPanelIndex(Self), GetScreenRect().GetX(), GetScreenRect().GetY())
		Else
			DrawText(openStr + " Panel [id=" + _id+"]", GetScreenRect().GetX(), GetScreenRect().GetY())
		EndIf
		SetColor 255,255,255
	End Method


	Method DrawBody()
		SetColor 120,120,120
		DrawRect( GetScreenRect().GetX(), GetScreenRect().GetY() + GetHeaderScreenHeight(), GetScreenRect().GetW(), GetBodyHeight() )
		SetColor 255,255,255
	End Method


	Method DrawContent()
		'draw header after the body so potential "shadows" are drawn
		'correctly
		DrawBody()
		DrawHeader()
	End Method


	'override to toggle open/close
	Method onClick:Int(triggerEvent:TEventBase) override
		Local coord:TVec2D = TVec2D(triggerEvent.GetData().Get("coord"))
		Local headerScreenRect:TRectangle = New TRectangle.Init(GetScreenRect().GetX(), GetScreenRect().GetY(), GetScreenRect().GetW(), GetHeaderScreenHeight())

		If headerScreenRect.containsVec( coord )
			If isOpen
				Close()
			Else
				Open()
			EndIf
		EndIf

		Return Super.onClick(triggerEvent)
	End Method


	Method UpdateLayout()
	End Method
End Type




Type TGUIAccordeon Extends TGUIObject
	Field panels:TGUIAccordeonPanel[]

	Field _panelsFillAccordeon:Int = True
	Field _allowMultipleOpenPanels:Int = False


	Method GetClassName:String()
		Return "tguiaccordeon"
	End Method


	Method Create:TGUIAccordeon(pos:TVec2D, dimension:TVec2D, value:String, State:String = "")
		'setup base widget
		Super.CreateBase(pos, dimension, State)

		SetValue(value)

    	GUIManager.Add(Self)
		Return Self
	End Method


	Method onOpenPanel:Int(panel:TGUIAccordeonPanel)
		'close all other open panels
		If Not _allowMultipleOpenPanels
			For Local i:Int = 0 Until panels.length
				If panels[i] = panel Then Continue
				If panels[i].isOpen Then panels[i].Close()
			Next
		EndIf

		InvalidateLayout()

		TriggerBaseEvent(GUIEventKeys.GUIAccordeon_OnOpenPanel, New TData.Add("panel", panel), Self)

		Return True
	End Method


	Method onClosePanel:Int(panel:TGUIAccordeonPanel)
		'if no panel is open now, keep the closing one opened
		If GetOpenPanelCount() = 0
			panel.Open()
			Return False
		EndIf

		InvalidateLayout()

		TriggerBaseEvent(GUIEventKeys.GUIAccordeon_OnClosePanel, New TData.Add("panel", panel), Self)

		Return True
	End Method


	Method OpenPanel:Int(index:Int)
		Local child:TGUIAccordeonPanel = TGUIAccordeonPanel( GetPanelAtIndex(index) )
		If Not child Then Return False
		Return child.Open()
	End Method


	Method ClosePanel:Int(index:Int)
		Local child:TGUIAccordeonPanel = TGUIAccordeonPanel( GetPanelAtIndex(index) )
		If Not child Then Return False
		Return child.Close()
	End Method


	'override, remove panels too
	Method RemoveChild:Int(child:TGUIobject, giveBackToManager:Int=False)
		If TGUIAccordeonPanel(child)
			RemovePanel(TGUIAccordeonPanel(child))
		EndIf

		Return Super.RemoveChild(child, giveBackToManager)
	End Method


	Method AddPanel:Int(panel:TGUIAccordeonPanel, index:Int = -1)
		If Not panel Then Return False
		'already added ?
		If GetPanelIndex(panel) >= 0 Then Return False

		If Not panels
			panels = [panel]
		Else
			'within existing or "next" index
			index = Min(panels.length, index)

			If index = panels.length
				panels :+ [panel]
			ElseIf index = 0
				panels = [panel] + panels
			Else
				panels = panels[.. index] + [panel] + panels[index ..]
			EndIf
		EndIf

		panel.SetParent(Self)

		'accordeon manages the panel
		GUIManager.remove(panel)

		InvalidateLayout()

		Return True
	End Method


	Method RemovePanel:Int(panel:TGUIAccordeonPanel)
		If Not panel Or Not panels Then Return False

		Local newPanels:TGUIAccordeonPanel[] = New TGUIAccordeonPanel[0]
		Local removedSomething:Int = False
		For Local p:TGUIAccordeonPanel = EachIn panels
			If p = panel
				p.SetParent(Null)
				removedSomething = True
				Continue
			EndIf

			newPanels :+ [p]
		Next

		panels = newPanels

'		If removedSomething Then RefitPanelSizes()
		If removedSomething Then InvalidateLayout()


		Return removedSomething
	End Method


	Method GetPanelAtIndex:TGUIAccordeonPanel(index:Int)
		If index < 0 Or Not panels Or index >= panels.length Then Return Null

		Return panels[index]
	End Method


	Method GetPanelIndex:Int(panel:TGUIAccordeonPanel)
		If Not panels Or panels.length = 0 Then Return -1

		For Local i:Int = 0 Until panels.length
			If panels[i] = panel Then Return i
		Next

		Return -1
	End Method


	Method GetOpenPanelCount:Int()
		Local openPanels:Int = 0
		For Local i:Int = 0 Until panels.length
			If panels[i].isOpen Then openPanels :+ 1
		Next
		Return openPanels
	End Method


	Method GetPanelCount:Int()
		If Not panels Then Return 0
		Return panels.length
	End Method


	Method GetTotalPanelHeadersHeight:Int()
		If Not panels Then Return 0

		Local panelHeadersHeight:Int = 0
		For Local p:TGUIAccordeonPanel = EachIn panels
			panelHeadersHeight :+ p.GetHeaderHeight()
		Next
		Return panelHeadersHeight
	End Method


	'returns the maximum height for an open panel's body
	Method GetMaxPanelBodyHeight:Int()
		Return Max(0, GetHeight() - GetTotalPanelHeadersHeight())
	End Method


	'override to add panels
	Method UpdateChildren:Int()
		If panels
			For Local p:TGUIAccordeonPanel = EachIn panels
				p.Update()
			Next
		EndIf
	End Method

	'override to add panels
	Method DrawChildren:Int()
		If panels
			For Local p:TGUIAccordeonPanel = EachIn panels
				p.Draw()
			Next
		EndIf
		Super.DrawChildren()
	End Method


	'override to add panels
	Method DrawTooltips:Int()
		If panels
			For Local p:TGUIAccordeonPanel = EachIn panels
				p.DrawTooltips()
			Next
		EndIf
		Super.DrawTooltips()
	End Method


	Method DrawContent()
		'DrawRect( GetScreenRect().GetX(), GetScreenRect().GetY(), GetScreenRect().GetW(), GetScreenRect().GetH() )
	End Method


	Method onAppearanceChanged:Int()
		Super.onAppearanceChanged()
		if panels
			For Local p:TGUIAccordeonPanel = EachIn panels
				p.InvalidateLayout()
				p.SetAppearanceChanged(True)
			Next
		endif
	End Method


	Method UpdateLayout()
		If panels
			InvalidateScreenRect()

			Local panelX:Int = 0
			Local panelY:Int = 0
			For Local p:TGUIAccordeonPanel = EachIn panels
				p.SetPosition(panelX, panelY)

				If Not p.isOpen
					p.SetSize(GetContentWidth(), -1)
					panelY :+ p.GetHeaderHeight()
				Else
					'auto height
					If Not p.fixedSize Or p.fixedSize.y = -1
						If _panelsFillAccordeon And Not _allowMultipleOpenPanels
							p.SetSize(GetContentWidth(), p.GetHeaderHeight() + GetMaxPanelBodyHeight())
						Else
							p.SetSize(GetContentWidth(), p.GetHeaderHeight() + p.GetBodyHeight())
						EndIf
					EndIf

					panelY :+ p.GetHeight()
				EndIf

			Next
		EndIf
	End Method
End Type