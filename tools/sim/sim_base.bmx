'
' BlitzMax code generated with wxCodeGen v1.19 : 06 Mai 2015 09:35:05
' 
' 
' PLEASE DO "NOT" EDIT THIS FILE!
' 
SuperStrict

Import wx.wxFrame
Import wx.wxListCtrl
Import wx.wxLocale
Import wx.wxNotebook
Import wx.wxPanel
Import wx.wxSpinCtrl
Import wx.wxSplitterWindow
Import wx.wxStaticBoxSizer
Import wx.wxStaticText
Import wx.wxWindow


Type MyFrame1Base Extends wxFrame

	Field m_notebook1:wxNotebook
	Field m_panel1:wxPanel
	Field m_splitter1:wxSplitterWindow
	Field m_panel7:wxPanel
	Field m_listCtrl_ProgrammeLicences:wxListCtrl
	Field m_panel6:wxPanel
	Field m_staticText6:wxStaticText
	Field m_spinCtrl_gameYear:wxSpinCtrl
	Field m_staticText7:wxStaticText
	Field m_spinCtrl_audience:wxSpinCtrl
	Field m_staticText_block:wxStaticText
	Field m_spinCtrl_block:wxSpinCtrl
	Field m_staticText_blockCount:wxStaticText
	Field m_listCtrl_audiences:wxListCtrl


	Method Create:MyFrame1Base(parent:wxWindow = Null,id:Int = wxID_ANY, title:String = "TVTSim", x:Int = -1, y:Int = -1, w:Int = 780, h:Int = 550, style:Int = wxDEFAULT_FRAME_STYLE|wxTAB_TRAVERSAL)
		return MyFrame1Base(Super.Create(parent, id, title, x, y, w, h, style))
	End Method

	Method OnInit()

		Local bSizer1:wxBoxSizer
		bSizer1 = new wxBoxSizer.Create(wxVERTICAL)

		m_notebook1 = new wxNotebook.Create(Self, wxID_ANY)
		m_panel1 = new wxPanel.Create(m_notebook1, wxID_ANY,,,,, wxTAB_TRAVERSAL)

		Local bSizer4:wxBoxSizer
		bSizer4 = new wxBoxSizer.Create(wxVERTICAL)

		m_splitter1 = new wxSplitterWindow.Create(m_panel1, wxID_ANY,,,,, wxSP_3D)
		m_splitter1.SetSashGravity(0.0)
		m_panel7 = new wxPanel.Create(m_splitter1, wxID_ANY,,,,, wxTAB_TRAVERSAL)

		Local sbSizer2:wxStaticBoxSizer
		sbSizer2 = new wxStaticBoxSizer.CreateSizerWithBox( new wxStaticBox.Create(m_panel7, wxID_ANY, _("Programme")), wxVERTICAL)

		m_listCtrl_ProgrammeLicences = new wxListCtrl.Create(m_panel7, wxID_ANY,,,,, wxLC_REPORT|wxLC_SINGLE_SEL)
		m_listCtrl_ProgrammeLicences.SetMinSize(-1,150)
		sbSizer2.Add(m_listCtrl_ProgrammeLicences, 1, wxALL|wxEXPAND, 5)

		m_panel7.SetSizer(sbSizer2)
		m_panel7.Layout()
		sbSizer2.Fit(m_panel7)

		m_panel6 = new wxPanel.Create(m_splitter1, wxID_ANY,,,,, wxTAB_TRAVERSAL)

		Local bSizer6:wxBoxSizer
		bSizer6 = new wxBoxSizer.Create(wxVERTICAL)


		Local bSizer5:wxBoxSizer
		bSizer5 = new wxBoxSizer.Create(wxHORIZONTAL)

		m_staticText6 = new wxStaticText.Create(m_panel6, wxID_ANY, _("Spieljahr"))
		m_staticText6.Wrap(-1)
		bSizer5.Add(m_staticText6, 0, wxALL|wxALIGN_CENTER_VERTICAL, 5)

		m_spinCtrl_gameYear = new wxSpinCtrl.Create(m_panel6, wxID_ANY, "",,, 60,-1, wxSP_ARROW_KEYS, 1900, 2100, 1985)

		bSizer5.Add(m_spinCtrl_gameYear, 0, wxALL, 5)

		m_staticText7 = new wxStaticText.Create(m_panel6, wxID_ANY, _("Reichweite"))
		m_staticText7.Wrap(-1)
		bSizer5.Add(m_staticText7, 0, wxALL|wxALIGN_CENTER_VERTICAL, 5)

		m_spinCtrl_audience = new wxSpinCtrl.Create(m_panel6, wxID_ANY, "",,, 100,-1, wxSP_ARROW_KEYS, 0, 100000000, 1000000)

		bSizer5.Add(m_spinCtrl_audience, 0, wxALL, 5)

		m_staticText_block = new wxStaticText.Create(m_panel6, wxID_ANY, _("Block"))
		m_staticText_block.Wrap(-1)
		bSizer5.Add(m_staticText_block, 0, wxALL|wxALIGN_CENTER_VERTICAL, 5)

		m_spinCtrl_block = new wxSpinCtrl.Create(m_panel6, wxID_ANY, "",,, 40,-1, wxSP_ARROW_KEYS, 1, 10, 1)

		bSizer5.Add(m_spinCtrl_block, 0, wxALL, 5)

		m_staticText_blockCount = new wxStaticText.Create(m_panel6, wxID_ANY, _("/ 2"))
		m_staticText_blockCount.Wrap(-1)
		bSizer5.Add(m_staticText_blockCount, 0, wxALL|wxALIGN_CENTER_VERTICAL, 5)

		bSizer6.AddSizer(bSizer5, 0, wxEXPAND, 5)

		bSizer6.AddCustomSpacer(0, 5, 0, , 5)


		Local sbSizer1:wxStaticBoxSizer
		sbSizer1 = new wxStaticBoxSizer.CreateSizerWithBox( new wxStaticBox.Create(m_panel6, wxID_ANY, _("Quoten")), wxVERTICAL)

		m_listCtrl_audiences = new wxListCtrl.Create(m_panel6, wxID_ANY,,,,, wxLC_REPORT|wxLC_SINGLE_SEL)
		m_listCtrl_audiences.SetFont(new wxFont.CreateWithAttribs(wxNORMAL_FONT().GetPointSize(), 70, 90, 90, False))
		sbSizer1.Add(m_listCtrl_audiences, 1, wxALL|wxEXPAND, 5)

		bSizer6.AddSizer(sbSizer1, 1, wxEXPAND, 5)

		m_panel6.SetSizer(bSizer6)
		m_panel6.Layout()
		bSizer6.Fit(m_panel6)

		m_splitter1.SplitHorizontally(m_panel7, m_panel6, 200)
		m_splitter1.SetMinimumPaneSize(200)

		bSizer4.Add(m_splitter1, 1, wxEXPAND, 5)

		m_panel1.SetSizer(bSizer4)
		m_panel1.Layout()
		bSizer4.Fit(m_panel1)
		m_notebook1.AddPage(m_panel1, _("QuotenSim"), False)


		bSizer1.Add(m_notebook1, 1, wxEXPAND | wxALL, 5)

		SetSizer(bSizer1)
		Layout()
		Center(wxBOTH)

		m_listCtrl_ProgrammeLicences.ConnectAny(wxEVT_COMMAND_LIST_ITEM_SELECTED, _OnProgrammeLicencesItemSelected, Null, Self)
		m_listCtrl_ProgrammeLicences.ConnectAny(wxEVT_SIZE, _OnProgrammeLicencesSize, Null, Self)
		m_spinCtrl_gameYear.ConnectAny(wxEVT_COMMAND_SPINCTRL_UPDATED, _OnChangeSettings, Null, Self)
		m_spinCtrl_audience.ConnectAny(wxEVT_COMMAND_SPINCTRL_UPDATED, _OnChangeSettings, Null, Self)
		m_spinCtrl_block.ConnectAny(wxEVT_COMMAND_SPINCTRL_UPDATED, _OnChangeSettings, Null, Self)
	End Method

	Function _OnProgrammeLicencesItemSelected(event:wxEvent)
		MyFrame1Base(event.sink).OnProgrammeLicencesItemSelected(wxListEvent(event))
	End Function

	Method OnProgrammeLicencesItemSelected(event:wxListEvent)
		DebugLog "Please override MyFrame1.OnProgrammeLicencesItemSelected()"
		event.Skip()
	End Method

	Function _OnProgrammeLicencesSize(event:wxEvent)
		MyFrame1Base(event.sink).OnProgrammeLicencesSize(wxSizeEvent(event))
	End Function

	Method OnProgrammeLicencesSize(event:wxSizeEvent)
		DebugLog "Please override MyFrame1.OnProgrammeLicencesSize()"
		event.Skip()
	End Method

	Function _OnChangeSettings(event:wxEvent)
		MyFrame1Base(event.sink).OnChangeSettings(wxCommandEvent(event))
	End Function

	Method OnChangeSettings(event:wxCommandEvent)
		DebugLog "Please override MyFrame1.OnChangeSettings()"
		event.Skip()
	End Method

End Type

