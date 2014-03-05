Type TPublicImage {_exposeToLua="selected"}
	Field Player:TPlayer
	'Field ByGroups:TAudience	{_exposeToLua}
	
	Function Create:TPublicImage(player:TPlayer)
		Local obj:TPublicImage = New TPublicImage
		obj.Player = player
		Return obj
	End Function
	
	Method GetAttractionMods:TAudience()
		Return TAudience.CreateAndInit(1, 1, 1, 1, 1, 1, 1, 1, 1)
	End Method
End Type
