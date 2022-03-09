SuperStrict
Import "game.debug.screen.page.bmx"
Import "game.game.bmx"
Import "game.player.bmx"



Type TDebugScreenPage_PublicImages extends TDebugScreenPage
	Field buttons:TDebugControlsButton[]
	
	Method Init:TDebugScreenPage_PublicImages()
		Local texts:String[] = ["Reset Player 1", "Reset Player 2", "Reset Player 3", "Reset Player 4"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], position.x, position.y)
			button._onClickHandler = OnButtonClickHandler

			buttons :+ [button]
		Next
		
		Return self
	End Method
	
	
	Method SetPosition(x:Int, y:Int)
		position = new SVec2I(x, y)

		'move buttons
		For local b:TDebugControlsButton = EachIn buttons
			b.x = x + 510 + 5
			b.y = y + b.dataInt * (b.h + 3)
		Next
	End Method
	
	
	Method Reset()
	End Method
	
	
	Method Activate()
	End Method


	Method Deactivate()
	End Method


	Method Update()
		Local playerID:Int = GetShownPlayerID()

		For Local b:TDebugControlsButton = EachIn buttons
			b.Update()
		Next
	End Method


	Method Render()
		DrawOutlineRect(position.x + 510, 13, 160, 150)
		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		RenderBlock_ChannelImage(1, position.x + 5, position.y)
		RenderBlock_ChannelImage(2, position.x + 5 + 250, position.y)
		RenderBlock_ChannelImage(3, position.x + 5, position.y + 170)
		RenderBlock_ChannelImage(4, position.x + 5 + 250, position.y + 170)
	End Method


	Method RenderBlock_ChannelImage(playerID:Int, x:Int, y:Int)
		Local player:TPlayer = GetPlayer(playerID)
		Local boxWidth:Int = 180

		SetColor 40,40,40
		DrawRect(x, y, boxWidth, 130)
		SetColor 50,50,40
		DrawRect(x+1, y+1, boxWidth-2, 130)
		SetColor 255,255,255

		Local textX:Int = x + 3
		Local textY:Int = y + 3 - 1
		Local p:TPublicImage = GetPublicImage(playerID)
		textFont.Draw("Player: " + playerID, textX, textY)
		textFont.Draw("Image: " + MathHelper.NumberToString(p.GetAverageImage(), 3), textX + 100, textY)
		textY :+ 15
		textFont.Draw("m", textX + 85, textY)
		textFont.Draw("/ f", textX + 107, textY)
		textFont.Draw("= total", textX + 140, textY)
		textY :+ 12

		Local a:TAudience = p.GetImageValues()

		Local targetGroupID:Int = 0
		For Local i:Int = 1 To TVTTargetGroup.count
			targetGroupID = TVTTargetGroup.GetAtIndex(i)
			textFont.Draw(GetLocale("TARGETGROUP_"+TVTTargetGroup.GetAsString(targetGroupID)) + ": ", textX, textY)
			textFont.Draw(MathHelper.NumberToString(a.GetGenderValue(targetGroupID, TVTTargetGroup.Men), 3), textX + 85, textY)
			textFont.Draw("/ " + MathHelper.NumberToString(a.GetGenderValue(targetGroupID, TVTTargetGroup.Women), 3), textX + 107, textY)
			textFont.Draw("= " + MathHelper.NumberToString(a.GetTotalValue(targetGroupID), 3), textX + 140, textY)
			textY :+ 10
		Next
	End Method



	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Select sender.dataInt
			case 0
				GetPublicImage(1).Reset()
			case 1
				GetPublicImage(2).Reset()
			case 2
				GetPublicImage(3).Reset()
			case 3
				GetPublicImage(4).Reset()
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function
End Type