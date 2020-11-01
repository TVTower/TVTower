SuperStrict

'Import "Dig/base.gfx.sprite.bmx"
'Import "Dig/base.gfx.bitmapfont.bmx"
'Import "Dig/base.util.vector.bmx"
Import "Dig/base.util.localization.bmx"
'Import "Dig/base.util.registry.spriteloader.bmx"
Import "Dig/base.util.input.bmx"
Import "Dig/base.util.helper.bmx"
Import "game.game.base.bmx"

Import "common.misc.gamegui.bmx"



Type TError
	Field window:TGUIModalWindow
	Field title:String
	Field message:String

	Field id:Int
	Field link:TLink
	Field linkReversed:TLink

	Global List:TList = CreateList()
	Global ListReversed:TList = CreateList()
	Global LastID:Int=0


	Function Create:TError(title:String, message:String, fullscreen:int = True)
		Local obj:TError =  New TError
		obj.title = title
		obj.message	= message
		obj.id = LastID
		LastID :+1
		obj.link = List.AddLast(obj)
		obj.linkReversed = ListReversed.AddFirst(obj)

		'create a new one
		obj.window = new TGUIGameModalWindow.Create(null, New TVec2D.Init(400,120), "SYSTEM")
		obj.window.guiCaptionTextBox.SetFont(headerFont)
		obj.window._defaultValueColor = TColor.clBlack.copy()
		obj.window.defaultCaptionColor = TColor.clWhite.copy()
		obj.window.SetCaptionArea(New TRectangle.Init(-1, 6, -1, 30))
		obj.window.guiCaptionTextBox.SetValueAlignment( ALIGN_CENTER_TOP )
		'no buttons
		obj.window.SetDialogueType(0)
		'use a non-button-background
		obj.window.guiBackground.spriteBaseName = "gfx_gui_window"

		if not fullscreen
			obj.window.darkenedArea = New TRectangle.Init(0,0,800,385)
			obj.window.screenArea = New TRectangle.Init(0,0,800,385)
		endif

		obj.window.SetCaption( title )
		obj.window.SetValue( message )

		obj.window.SetManaged(False)

		Return obj
	End Function


	Function onClick:Int( triggerEvent:TEventBase )
		print "clicked gui"
	End Function


	Function CreateNotEnoughMoneyError()
		Create(getLocale("ERROR_NOT_ENOUGH_MONEY"),getLocale("ERROR_NOT_ENOUGH_MONEY_TEXT"), False)
	End Function


	Function hasActiveError:Int()
		Return (List.count() > 0)
	End Function


	Function DrawErrors()
		'draw last added as last!
		For local error:TError = EachIn List
			error.Draw()
		Next
	End Function


	Function UpdateErrors()
		'handle last added as first!
		For local error:TError = EachIn ListReversed
			error.Update()
		Next
	End Function


	Method Update:int()
		If not window.IsClosing() and Mousemanager.IsClicked(1)
			local rect:TRectangle = window.GetScreenRect()
			If THelper.MouseInRect(rect)
				window.Close()
				'handled left click
				MouseManager.SetClickHandled(1) 'clicked to remove error
				return True
			EndIf
		EndIf

		window.Update()

		if not window.IsClosed()
			'no right clicking allowed as long as "error notice is active"
			MouseManager.SetClickHandled(2)
		else
			window.Remove()
			link.Remove()
			linkReversed.Remove()
			return True
		endif

		return False
	End Method


	Method Draw()
		window.Draw()

		GetGameBase().cursorstate = 0
	End Method
End Type
