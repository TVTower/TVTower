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
		Return ImageValues.Copy().DivideFloat(100)
	End Method
	
	Method ChangeImage(imageChange:TAudience)	
		ImageValues.Add(imageChange)
		TDevHelper.Log("ChangePublicImage()", "Change player '" + Player.playerID + "' public image: " + imageChange.ToString(), LOG_DEBUG)
	End Method
	
	Function ChangeImageCauseOfBroadcast(bc:TBroadcast)
		If (bc.TopAudience > 1000) 'Nur etwas ändern, wenn auch ein paar Zuschauer einschalten und nicht alle Sendeausfall haben.		
			Local modification:TAudience = TBroadcast.GetPotentialAudienceForHour(TAudience.CreateAndInitValue(1))
		
			'If (broadcastType = 0) Then 'Movies
				Local map:TMap = CreateMap()	
				
				Local attrList:TList = CreateList()
				For Local i:Int = 1 To 4 'TODO: Was passiert wenn ein Spieler ausscheidet?
					map.Insert(string.FromInt(i), TAudience.CreateAndInitValue(0))
					attrList.AddLast(bc.AudienceResults[i].AudienceAttraction.PublicImageAttraction)
				Next			
				
				ChangePublicImageForTargetGroup(map, 1, attrList, TAudience.ChildrenSort)
				ChangePublicImageForTargetGroup(map, 2, attrList, TAudience.TeenagersSort)
				ChangePublicImageForTargetGroup(map, 3, attrList, TAudience.HouseWifesSort)
				ChangePublicImageForTargetGroup(map, 4, attrList, TAudience.EmployeesSort)
				ChangePublicImageForTargetGroup(map, 5, attrList, TAudience.UnemployedSort)
				ChangePublicImageForTargetGroup(map, 6, attrList, TAudience.ManagerSort)
				ChangePublicImageForTargetGroup(map, 7, attrList, TAudience.PensionersSort)
				ChangePublicImageForTargetGroup(map, 8, attrList, TAudience.WomenSort)
				ChangePublicImageForTargetGroup(map, 9, attrList, TAudience.MenSort)			
				
				For Local i:Int = 1 To 4 'TODO: Was passiert wenn ein Spieler ausscheidet?
					Local audience:TAudience = TAudience(map.ValueForKey(string.FromInt(i)))
					audience.Multiply(modification)
					Game.GetPlayer(i).PublicImage.ChangeImage(audience)
				Next						
			'Endif	
		End If	
	End Function
	
	Function ChangePublicImageForTargetGroup(playerAudience:TMap, targetGroup:Int, attrList:TList, compareFunc( o1:Object,o2:Object )=CompareObjects)
		Local tempList:TList = attrList.Copy()		
		SortList(tempList,False,compareFunc)
		
		If (tempList.Count() = 4) Then
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(0)).Id) )).SetValue(targetGroup, 1)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(1)).Id) )).SetValue(targetGroup, 0.5)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(2)).Id) )).SetValue(targetGroup, -0.5)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(3)).Id) )).SetValue(targetGroup, -1)
		Elseif (tempList.Count() = 3) Then
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(0)).Id) )).SetValue(targetGroup, 1)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(1)).Id) )).SetValue(targetGroup, 0)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(2)).Id) )).SetValue(targetGroup, -1)
		Elseif (tempList.Count() = 2) Then
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(0)).Id) )).SetValue(targetGroup, 1)
			TAudience(playerAudience.ValueForKey( string.FromInt(TAudience(tempList.ValueAtIndex(1)).Id) )).SetValue(targetGroup, -1)
		EndIf
	End Function		
End Type
