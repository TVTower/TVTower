SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.game.bmx"
Import "../game.newsagency.bmx"

Type TDebugScreenPage_Politics extends TDebugScreenPage
	Global _instance:TDebugScreenPage_Politics


	Method New()
		_instance = self
	End Method

	Function GetInstance:TDebugScreenPage_Politics()
		If Not _instance Then new TDebugScreenPage_Politics
		Return _instance
	End Function


	Method Init:TDebugScreenPage_Politics()
		Local texts:String[] = ["Send Terrorist FR", "Send Terrorist VR", "Reset Terror Levels"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], position.x, position.y)
			button.w = 115
			'custom position
			button.x = position.x + 547
			button.y = 18 + 2 + i * (button.h + 2)
			button._onClickHandler = OnButtonClickHandler

			buttons :+ [button]
		Next

		Return self
	End Method


	Method MoveBy(dx:Int, dy:Int) override
		'move buttons
		For Local b:TDebugControlsButton = EachIn buttons
			b.x :+ dx
			b.y :+ dy
		Next
	End Method


	Method Reset()
	End Method


	Method Activate()
	End Method


	Method Deactivate()
	End Method


	Method Update()
		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next
	End Method


	Method Render()
		DrawWindow(position.x + 545, position.y, 120, 73, "Manipulate")
		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Select sender.dataInt
			Case 0
				If Not GetGame().networkGame
					TFigureTerrorist(GetGame().terrorists[0]).SetDeliverToRoom( GetRoomCollection().GetFirstByDetails("", "vrduban") )
				EndIf
			Case 1
				If Not GetGame().networkGame
					TFigureTerrorist(GetGame().terrorists[1]).SetDeliverToRoom( GetRoomCollection().GetFirstByDetails("", "frduban") )
				EndIf
			Case 2
				GetNewsAgency().SetTerroristAggressionLevel(0,0)
				GetNewsAgency().SetTerroristAggressionLevel(1,-1)
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function
End Type
