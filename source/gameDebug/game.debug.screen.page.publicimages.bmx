SuperStrict
Import "game.debug.screen.page.bmx"
Import "../game.game.bmx"
Import "../game.player.bmx"

Type TDebugScreenPage_PublicImages extends TDebugScreenPage
	Global _instance:TDebugScreenPage_PublicImages


	Method New()
		_instance = self
	End Method


	Function GetInstance:TDebugScreenPage_PublicImages()
		If Not _instance Then new TDebugScreenPage_PublicImages
		Return _instance
	End Function 


	Method Init:TDebugScreenPage_PublicImages()
		Local texts:String[] = ["Reset", "-1%", "+1%", "+10%", "Reset", "-1%", "+1%", "+10%", "Reset", "-1%", "+1%", "+10%", "Reset", "-1%", "+1%", "+10%"]
		Local button:TDebugControlsButton
		For Local i:Int = 0 Until texts.length
			button = CreateActionButton(i, texts[i], position.x, position.y)
			button._onClickHandler = OnButtonClickHandler

			buttons :+ [button]
		Next

		Return self
	End Method


	Method MoveBy(dx:Int, dy:Int) override
		'move buttons
		If buttons.length >= 6
			buttons[ 0].SetXY(position.x + 510 + 18              , position.y + 23 + 0 * 18).SetWH( 43, 15)
			buttons[ 1].SetXY(position.x + 510 + 18 + 47 + 0 * 30, position.y + 23 + 0 * 18).SetWH( 26, 15)
			buttons[ 2].SetXY(position.x + 510 + 18 + 47 + 1 * 30, position.y + 23 + 0 * 18).SetWH( 26, 15)
			buttons[ 3].SetXY(position.x + 510 + 18 + 47 + 2 * 30, position.y + 23 + 0 * 18).SetWH( 30, 15)
			buttons[ 4].SetXY(position.x + 510 + 18              , position.y + 23 + 1 * 18).SetWH( 43, 15)
			buttons[ 5].SetXY(position.x + 510 + 18 + 47 + 0 * 30, position.y + 23 + 1 * 18).SetWH( 26, 15)
			buttons[ 6].SetXY(position.x + 510 + 18 + 47 + 1 * 30, position.y + 23 + 1 * 18).SetWH( 26, 15)
			buttons[ 7].SetXY(position.x + 510 + 18 + 47 + 2 * 30, position.y + 23 + 1 * 18).SetWH( 30, 15)
			buttons[ 8].SetXY(position.x + 510 + 18              , position.y + 23 + 2 * 18).SetWH( 43, 15)
			buttons[ 9].SetXY(position.x + 510 + 18 + 47 + 0 * 30, position.y + 23 + 2 * 18).SetWH( 26, 15)
			buttons[10].SetXY(position.x + 510 + 18 + 47 + 1 * 30, position.y + 23 + 2 * 18).SetWH( 26, 15)
			buttons[11].SetXY(position.x + 510 + 18 + 47 + 2 * 30, position.y + 23 + 2 * 18).SetWH( 30, 15)
			buttons[12].SetXY(position.x + 510 + 18              , position.y + 23 + 3 * 18).SetWH( 43, 15)
			buttons[13].SetXY(position.x + 510 + 18 + 47 + 0 * 30, position.y + 23 + 3 * 18).SetWH( 26, 15)
			buttons[14].SetXY(position.x + 510 + 18 + 47 + 1 * 30, position.y + 23 + 3 * 18).SetWH( 26, 15)
			buttons[15].SetXY(position.x + 510 + 18 + 47 + 2 * 30, position.y + 23 + 3 * 18).SetWH( 30, 15)
		EndIf
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
		DrawWindow(position.x + 510 - 2, position.y, 160, 95, "Manipulate Images")
		textFont.Draw("P1", position.x + 510, position.y + 22 + 0 * 18)
		textFont.Draw("P2", position.x + 510, position.y + 22 + 1 * 18)
		textFont.Draw("P3", position.x + 510, position.y + 22 + 2 * 18)
		textFont.Draw("P4", position.x + 510, position.y + 22 + 3 * 18)

		For Local i:Int = 0 Until buttons.length
			buttons[i].Render()
		Next

		RenderBlock_ChannelImage(1, position.x + 5, position.y)
		RenderBlock_ChannelImage(2, position.x + 5 + 220, position.y)
		RenderBlock_ChannelImage(3, position.x + 5, position.y + 120)
		RenderBlock_ChannelImage(4, position.x + 5 + 220, position.y + 120)
	End Method


	Method RenderBlock_ChannelImage(playerID:Int, x:Int, y:Int)
		Local player:TPlayer = GetPlayer(playerID)
		Local p:TPublicImage = GetPublicImage(playerID)

		Local contentRect:SRectI = DrawWindow(x, y, 213, 110, "Player: " + playerID, "Image: " + TFunctions.NumberToString(p.GetAverageImage(), 3))

		Local textY:Int = contentRect.y
		textFont.Draw("m", contentRect.x + 85, textY)
		textFont.Draw("/ f", contentRect.x + 120, textY)
		textFont.Draw("= total", contentRect.x + 163, textY)
		textY :+ 12

		Local a:TAudience = p.GetImageValues()
		For Local targetGroupID:Int = EachIn TVTTargetGroup.GetBaseGroupIDs() 'baseGroupCount = without "men/women"
			textFont.Draw(GetLocale("TARGETGROUP_"+TVTTargetGroup.GetAsString(targetGroupID)) + ": ", contentRect.x, textY)
			textFont.Draw(TFunctions.NumberToString(a.GetGenderValue(targetGroupID, TVTPersonGender.MALE), 3), contentRect.x + 85, textY)
			textFont.Draw("/ " + TFunctions.NumberToString(a.GetGenderValue(targetGroupID, TVTPersonGender.FEMALE), 3), contentRect.x + 120, textY)
			textFont.Draw("= " + TFunctions.NumberToString(a.GetWeightedValue(targetGroupID), 3), contentRect.x + 163, textY)
			textY :+ 11
		Next
	End Method


	Function OnButtonClickHandler(sender:TDebugControlsButton)
		Local changeValue:Float = 1.0 '1%
		Select sender.dataInt
			Case 0
				GetPublicImage(1).Reset()
			Case 1
				GetPublicimage(1).ChangeImage(New SAudience(-changeValue, -changeValue))
			Case 2
				GetPublicimage(1).ChangeImage(New SAudience(changeValue, changeValue))
			Case 3
				GetPublicimage(1).ChangeImage(New SAudience(changeValue*10, changeValue*10))
			Case 4
				GetPublicImage(2).Reset()
			Case 5
				GetPublicimage(2).ChangeImage(New SAudience(-changeValue, -changeValue))
			Case 6
				GetPublicimage(2).ChangeImage(New SAudience(changeValue, changeValue))
			Case 7
				GetPublicimage(2).ChangeImage(New SAudience(changeValue*10, changeValue*10))
			Case 8
				GetPublicImage(3).Reset()
			Case 9
				GetPublicimage(3).ChangeImage(New SAudience(-changeValue, -changeValue))
			Case 10
				GetPublicimage(3).ChangeImage(New SAudience(changeValue, changeValue))
			Case 11
				GetPublicimage(3).ChangeImage(New SAudience(changeValue*10, changeValue*10))
			Case 12
				GetPublicImage(4).Reset()
			Case 13
				GetPublicimage(4).ChangeImage(New SAudience(-changeValue, -changeValue))
			Case 14
				GetPublicimage(4).ChangeImage(New SAudience(changeValue, changeValue))
			Case 15
				GetPublicimage(4).ChangeImage(New SAudience(changeValue*10, changeValue*10))
		End Select

		'handled
		sender.clicked = False
		sender.selected = False
	End Function
End Type
