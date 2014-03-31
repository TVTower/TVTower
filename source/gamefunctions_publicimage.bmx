Type TPublicImage {_exposeToLua="selected"}
	Field Player:TPlayer
	Field ImageValues:TAudience
	
	Function Create:TPublicImage(player:TPlayer)
		Local obj:TPublicImage = New TPublicImage
		obj.Player = player
		obj.ImageValues = TAudience.CreateAndInit(100, 100, 100, 100, 100, 100, 100, 100, 100)
		Return obj
	End Function
	
	Method GetAttractionMods:TAudience()
		'Return TAudience.CreateAndInit(1, 1, 1, 1, 1, 1, 1, 1, 1)
		Return ImageValues.GetNewInstance().DivideFloat(100)
	End Method
	
	Method ChangeImage(imageChange:TAudience)	
		ImageValues.Add(imageChange)
		TDevHelper.Log("ChangePublicImage()", "Change player '" + Player.playerID + "' public image: " + imageChange.ToString(), LOG_DEBUG)
	End Method
End Type
