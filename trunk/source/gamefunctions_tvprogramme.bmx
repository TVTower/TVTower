Const CURRENCYSIGN:string = Chr(8364) 'eurosign

Type TPlayerProgrammePlan
	Field ProgrammeBlocks:TList = CreateList()
	Field Contracts:TList		= CreateList()
	Field NewsBlocks:TList		= CreateList()

	Field AdditionallyDraggedProgrammeBlocks:Int = 0

	Field parent:TPlayer

	Function Create:TPlayerProgrammePlan( parent:TPlayer)
		Local obj:TPlayerProgrammePlan = New TPlayerProgrammePlan
'		TPlayerProgrammePlan.List.AddLast(obj)
		obj.parent = parent
		Return obj
	End Function

	Method ClearLists:int()
		ProgrammeBlocks.Clear()
		Contracts.Clear()
		NewsBlocks.Clear()
	End Method

	Method AddProgrammeBlock:TLink(block:TProgrammeBlock)
		Return Self.ProgrammeBlocks.addLast(block)
	End Method

	Method GetProgrammeBlock:TProgrammeBlock(id:Int)
		For Local obj:TProgrammeBlock = EachIn Self.ProgrammeBlocks
			If obj.id = id Then Return obj
		Next
		Return Null
	EndMethod

	Method GetActualProgrammeBlock:TProgrammeBlock(time:Int = -1, day:Int = - 1)
		If time = -1 Then time = Game.GetHour()
		If day  = -1 Then day  = Game.day
		Local planHour:Int = day*24 + time

		For Local block:TProgrammeBlock = EachIn Self.ProgrammeBlocks
			If (block.sendHour + block.Programme.blocks - 1 >= planHour And block.sendHour <= planHour) Then Return block
		Next
		Return Null
	End Method

	'returns a number based on day to send and hour from position
	'121 means 5 days and 1 hours -> 01:00 on day 5
	Function GetPlanHour:Int(dayHour:Int, dayToPlan:Int=Null)
		If dayToPlan = Null Then dayToPlan = game.daytoplan
		Return dayToPlan*24 + dayHour
	End Function

    Method DrawAllProgrammeBlocks()
		If Self.AdditionallyDraggedProgrammeBlocks > 0
			For Local ProgBlock:TProgrammeBlock = EachIn Self.ProgrammeBlocks
				If Self.parent.playerID = Game.playerID And ProgBlock.dragged=1 Then ProgBlock.DrawShades()
			Next
		EndIf
		For Local ProgrammeBlock:TProgrammeBlock = EachIn Self.ProgrammeBlocks
			ProgrammeBlock.Draw()
		Next
    End Method

	Method UpdateAllProgrammeBlocks()
		Local gfxListenabled:Byte = (PPprogrammeList.enabled <> 0 Or PPcontractList.enabled <> 0)
		'assume all are dropped
		Self.AdditionallyDraggedProgrammeBlocks = 0

		Self.ProgrammeBlocks.sort(True, TBlock.SortDragged)
		Local clickrecognized :Byte = 0

		For Local block:TProgrammeBlock = EachIn Self.ProgrammeBlocks
			If gfxListenabled = 0 And MOUSEMANAGER.IsHit(2) And block.dragged = 1
				block.DeleteBlock() 'removes block from Programmeplan
				MOUSEMANAGER.resetKey(2)
			EndIf

			If gfxListenabled=0 And Not Clickrecognized And MOUSEMANAGER.IsHit(1)
				If Not block.dragged
					If block.dragable And block.State = 0 And functions.DoMeet(block.sendhour, block.sendhour+block.programme.blocks, Game.daytoplan*24,Game.daytoplan*24+24)
						For Local i:Int = 1 To block.programme.blocks
							Local pos:TPosition = block.GetBlockSlotXY(i, block.pos)
							If functions.MouseIn(pos.x, pos.y, block.width, 30)
								block.Drag()
								Exit
							EndIf
						Next
					EndIf
				Else 'drop dragged block
					Local DoNotDrag:Int = 0
					If gfxListenabled = 0 And MOUSEMANAGER.IsHit(1) And block.State = 0
						For Local DragAndDrop:TDragAndDrop = EachIn block.DragAndDropList  					'loop through DnDs
							If DragAndDrop.CanDrop(MouseX(),MouseY(), "programmeblock")						'mouse within dnd-rect
								For Local Otherblock:TProgrammeBlock = EachIn Self.ProgrammeBlocks   		'loop through other pblocks
									'is there a block positioned at the desired place?

									'is otherblock not the same as our actual block? - on the same day
									If Otherblock <> block
										Local dndHour:Int = game.daytoplan*24 + (DragAndDrop.pos.x = 394)*12 + (DragAndDrop.pos.y - 17) / 30		'timeset calc.

										'loop through aimed time + duration in scheduler
										If functions.DoMeet(dndHour, dndHour+block.programme.blocks-1,  otherblock.sendHour, otherBlock.sendHour + otherBlock.programme.blocks-1)
											clickrecognized = 1
											If Not Otherblock.DraggingAllowed()
												DoNotDrag = 1
												block.Drag()
												Otherblock.Drop()
												'print "would swap "+block.programme.title+" with "+otherblock.programme.title + " but not allowed"
												Exit
											Else
												block.Drop()
												Otherblock.Drag()
											EndIf
										EndIf
									EndIf
								Next
								If DoNotDrag <> 1
									block.Pos.SetXY(DragAndDrop.pos.x, DragAndDrop.pos.y)
									block.StartPos.SetPos(block.Pos)
									clickrecognized = 1

									block.sendhour = Self.getPlanHour(block.GetHourOfBlock(1, block.pos), game.daytoplan)
									block.Drop()
									Exit 'exit loop-each-dragndrop, we've already found the right position
								EndIf
							EndIf
						Next
						If block.IsAtStartPos() And DoNotDrag = 0 And (Game.day < Game.daytoplan Or (Game.day = Game.daytoplan And Game.GetHour() < block.GetHourOfBlock(1,block.StartPos)))
							block.Drop()
							block.Pos.SetPos(block.StartPos)
						EndIf
					EndIf
				EndIf
			EndIf

			If block.dragged = 1
				Self.AdditionallyDraggedProgrammeBlocks :+1
				Local displace:Int = Self.AdditionallyDraggedProgrammeBlocks *5
				block.Pos.SetXY(MouseX() - block.width/2 - displace, MouseY() - block.height/2 - displace)
			EndIf
		Next
    End Method

	Method GetNewsBlock:TNewsBlock(id:Int)
		For Local obj:TNewsBlock = EachIn Self.NewsBlocks
			If obj.id = id Then Return obj
		Next
		Return Null
	EndMethod


	Method DrawAllNewsBlocks()
		For Local NewsBlock:TNewsBlock = EachIn Self.NewsBlocks
			If Self.parent.playerID = Game.playerID
				If (newsblock.dragged=1 Or (newsblock.pos.y > 0)) And (Newsblock.publishtime + Newsblock.publishdelay <= Game.timeSinceBegin) Then NewsBlock.Draw()
			EndIf
		Next
    End Method

    Method UpdateAllNewsBlocks()
		Local havetosort:Byte = 0
		Local dontpay:Int = 0
		Local number:Int = 0
		If TNewsBlock.LeftListPositionMax >=4
			If TNewsBlock.LeftListPosition+4 > TNewsBlock.LeftListPositionMax Then TNewsBlock.LeftListPosition = TNewsBlock.LeftListPositionMax-4
		Else
			TNewsBlock.LeftListPosition = 0
		EndIf

		Self.NewsBlocks.sort(True, TNewsBlock.sort)

		For Local NewsBlock:TNewsBlock = EachIn Self.NewsBlocks
			If NewsBlock.owner = Game.playerID
				If newsblock.GetSlotOfBlock() < 0 And (Newsblock.publishtime + Newsblock.publishdelay <= Game.timeSinceBegin)
					number :+ 1
					If number >= TNewsBlock.LeftListPosition And number =< TNewsBlock.LeftListPosition+4
						NewsBlock.Pos.SetXY(35, 22+88*(number-TNewsBlock.LeftListPosition   -1))
					Else
						NewsBlock.pos.SetXY(0, -100)
					EndIf
					NewsBlock.StartPos.SetPos(NewsBlock.Pos)
				EndIf
				If newsblock.GetSlotOfBlock() > 0 Then dontpay = 1
				If NewsBlock.dragged = 1
					NewsBlock.sendslot = -1
					If MOUSEMANAGER.IsHit(2)
						If game.networkgame Then If network.IsConnected Then NetworkHelper.SendPlanNewsChange(game.playerID, newsblock, 2)
						Players[Game.playerID].ProgrammePlan.RemoveNewsBlock(NewsBlock)
						havetosort = 1
						MOUSEMANAGER.resetKey(2)
					EndIf
				EndIf
				If MOUSEMANAGER.IsHit(1)
					If NewsBlock.dragged = 0 And NewsBlock.dragable = 1 And NewsBlock.State = 0
						If functions.IsIn(MouseX(), MouseY(), NewsBlock.pos.x, NewsBlock.pos.y, NewsBlock.width, NewsBlock.height)
							NewsBlock.dragged = 1
							If game.networkgame Then If network.IsConnected Then NetworkHelper.SendPlanNewsChange(game.playerID, newsblock, 1)
						EndIf
					Else
						Local DoNotDrag:Int = 0
						If NewsBlock.State = 0
							NewsBlock.dragged = 0
							For Local DragAndDrop:TDragAndDrop = EachIn TNewsBlock.DragAndDropList
								If DragAndDrop.CanDrop(MouseX(),MouseY()) = 1
									For Local OtherNewsBlock:TNewsBlock = EachIn Self.NewsBlocks
										If OtherNewsBlock.owner = Game.playerID
											'is there a NewsBlock positioned at the desired place?
											If MOUSEMANAGER.IsHit(1) And OtherNewsBlock.dragable = 1 And OtherNewsBlock.pos.isSame(DragAndDrop.pos)
												If OtherNewsBlock.State = 0
													OtherNewsBlock.dragged = 1
													If game.networkgame Then If network.IsConnected Then NetworkHelper.SendPlanNewsChange(game.playerID, otherNewsBlock, 1)
													Exit
												Else
													DoNotDrag = 1
												EndIf
											EndIf
										EndIf
									Next
									If DoNotDrag <> 1
										NewsBlock.Pos.SetPos(DragAndDrop.pos)
										NewsBlock.StartPos.SetPos(NewsBlock.Pos)
										Exit 'exit loop-each-dragndrop, we've already found the right position
									EndIf
								EndIf
							Next
							If NewsBlock.IsAtStartPos()
								If Not newsblock.paid And newsblock.pos.x > 400
									NewsBlock.Pay()
									newsblock.paid=True
								EndIf
								NewsBlock.dragged    = 0
								NewsBlock.Pos.SetPos(NewsBlock.StartPos)
								NewsBlock.sendslot   = Newsblock.GetSlotOfBlock()
								If NewsBlock.sendslot >0 And NewsBlock.sendslot < 4
									If game.networkgame Then If network.IsConnected Then NetworkHelper.SendPlanNewsChange(game.playerID, newsblock, 0)
								EndIf
								Self.NewsBlocks.sort(True, TNewsBlock.sort)
							EndIf
						EndIf
					EndIf
				EndIf
				If NewsBlock.dragged = 1
					TNewsBlock.AdditionallyDragged = TNewsBlock.AdditionallyDragged +1
					NewsBlock.Pos.SetXY(MouseX() - NewsBlock.width /2 - TNewsBlock.AdditionallyDragged *5, MouseY() - NewsBlock.height /2 - TNewsBlock.AdditionallyDragged *5)
				EndIf
				If NewsBlock.dragged = 0
					NewsBlock.Pos.SetPos(NewsBlock.StartPos)
				EndIf
			EndIf
		Next
		TNewsBlock.LeftListPositionMax = number
		TNewsBlock.AdditionallyDragged = 0
    End Method


	Method ProgrammePlaceable:Int(Programme:TProgramme, time:Int = -1, day:Int = -1)
		If Programme = Null Then Return 0
		If time = -1 Then time = Game.GetHour()
		If day  = -1 Then day  = Game.day

		If GetActualProgramme(time, day) = Null
			If time + Programme.blocks - 1 > 23 Then time:-24;day:+1 'sendung geht bis nach 0 Uhr
			If GetActualProgramme(time + Programme.blocks - 1, day) = Null Then Return 1
		EndIf
		Return 0
	End Method

	Method ContractPlaceable:Int(Contract:TContract, time:Int = -1, day:Int = -1)
		If Contract = Null Then Return 0
		If time = -1 Then time = Game.GetHour()
		If day  = -1 Then day  = Game.day
		If GetActualContract(time, day) = Null Then Return 1
		Return 0
	End Method

	Method GetActualProgramme:TProgramme(time:Int = -1, day:Int = - 1)
		If time = -1 Then time = Game.GetHour()
		If day  = -1 Then day  = Game.day
		Local planHour:Int = day*24+time

		For Local block:TProgrammeBlock = EachIn Self.ProgrammeBlocks
			If (block.sendHour + block.Programme.blocks - 1 >= planHour) Then Return block.programme
		Next
		Return Null
	End Method

	Method GetActualContract:TContract(time:Int = -1, day:Int = - 1)
		If time = -1 Then time = Game.GetHour()
		If day  = -1 Then day  = Game.day

		For Local contract:TContract = EachIn Self.Contracts
			If (contract.sendtime>= time And contract.sendtime <=time) And contract.senddate = day Then Return contract
		Next
		Return Null
	End Method

	Method GetActualAdBlock:TAdBlock(playerID:Int, time:Int = -1, day:Int = - 1)
		If time = -1 Then time = Game.GetHour()
		If day  = -1 Then day  = Game.day

		For Local adblock:TAdBlock= EachIn TAdBlock.List
			If adblock.owner = playerID
				If (adblock.contract.sendtime>= time And adblock.contract.sendtime <=time) And..
					adblock.contract.senddate = day Then Return adblock
			EndIf
		Next
		Return Null
	End Method

	Method GetActualNewsBlock:TNewsBlock(position:Int)
		For Local newsBlock:TNewsBlock = EachIn Self.NewsBlocks
			If newsBlock.sendslot = position Then Return newsBlock
		Next
	End Method

	Method RefreshAdPlan(day:Int)
		For Local contract:TContract = EachIn Self.Contracts
			If contract.senddate = day Then Self.RemoveContract(contract)
		Next
		For Local Adblock:TAdBlock= EachIn TAdBlock.List
			If adblock.contract.owner = Self.parent.playerID
				'Print "REFRESH AD:ADDED "+adblock.contract.title;
				Self.AddContract(adblock.contract)
			EndIf
		Next
	End Method

	Method RemoveProgramme(_Programme:TProgramme, removeCurrentRunning:Int = 0)
		'remove all blocks using that programme and are NOT run
		Local currentHour :Int = game.day*24+game.GetHour()
		For Local block:TProgrammeBlock = EachIn Self.ProgrammeBlocks
			If block.programme = _Programme And block.sendhour +removeCurrentRunning*block.programme.blocks > currentHour Then Self.ProgrammeBlocks.remove(block)
		Next

		'remove programme from player programme list
		'Player[self.parent.playerID].ProgrammeCollection.RemoveProgramme( _Programme )
	End Method

	Method AddContract(_Contract:TContract)
		Local contract:TContract = New TContract
		contract			= CloneContract(_Contract)
		contract.owner		= Self.parent.playerID
		contract.senddate	= Game.daytoplan
		Self.Contracts.AddLast(contract)
		GetPreviousContractCount(contract)
	End Method

	Method AddNewsBlock(block:TNewsBlock)
		Self.NewsBlocks.AddLast(block)
	End Method

	Method RemoveNewsBlock(block:TNewsBlock)
		Self.NewsBlocks.remove(block)
	End Method

	'clones a TProgramme - a normal prog = otherprog
	'just creates a reference to this object, but we want
	'a real copy (to be able to send repeatitions of movies
	Function CloneContract:TContract(_contract:TContract)
		If _contract <> Null
			Local typ:TTypeId = TTypeId.ForObject(_contract)
			Local clone:TContract = New TContract
			For Local t:TField = EachIn typ.EnumFields()
				t.Set(clone, t.Get(_contract))
			Next
			TContract(clone).clone = 1
			clone.botched = 0
			clone.finished = 0
			clone.owner = 0
			Return clone
		EndIf
	End Function

	Method RemoveContract(_contract:TContract)
		For Local contract:TContract = EachIn Self.Contracts
			If contract <> Null And contract.title = _contract.title And contract.senddate = _contract.senddate And contract.sendtime = _contract.sendtime
				Self.Contracts.remove(_contract)
			EndIf
		Next
	End Method

	Method GetPreviousContractCount:Int(_contract:TContract)
		Local count:Int = 1
		If Not Self.Contracts Then Self.Contracts = CreateList()
		For Local contract:TContract = EachIn Self.Contracts
			If contract.title = _contract.title And contract.botched <> 1
				contract.spotnumber = count
				count :+ 1
			EndIf
		Next
		Return count
	End Method

	Method RenewContractCount:Int(_contract:TContract)
		Local count:Int = 1
		Local contract:TContract = Null
		For Local contract:TContract = EachIn Self.Contracts
			If contract.title = _contract.title
				If contract.botched <> 1
					contract.spotnumber = count
					count :+1
				Else
					contract.spotnumber = 0
				EndIf
			EndIf
		Next
	End Method
End Type

Global GENRE_CALLINSHOW:Int = 20

Global TYPE_MOVIE:Int = 1
Global TYPE_SERIE:Int = 2
Global TYPE_EPISODE:Int = 4
Global TYPE_CONTRACT:Int = 8
Global TYPE_AD:Int = 16
Global TYPE_NEWS:Int = 32

'holds all Programmes a player possesses
Type TPlayerProgrammeCollection {_exposeToLua="selected"}
	Field List:TList			= CreateList() {_private hideFromAI}
	Field MovieList:TList		= CreateList() {_private hideFromAI}
	Field SeriesList:TList		= CreateList() {_private hideFromAI}
	Field ContractList:TList	= CreateList() {_private hideFromAI}
	Field parent:TPlayer

	Function Create:TPlayerProgrammeCollection(player:TPlayer) {hideFromAI}
		Local obj:TPlayerProgrammeCollection = New TPlayerProgrammeCollection
		obj.parent =player
		Return obj
	End Function

	Method ClearLists() {_private hideFromAI}
		List.Clear()
		MovieList.Clear()
		SeriesList.Clear()
		ContractList.Clear()
	End Method

	Method GetMovieCount:Int() {_exposeToLua}
		Return Self.MovieList.count()
	End Method

	Method GetSeriesCount:Int() {_exposeToLua}
		Return Self.SeriesList.count()
	End Method

	Method GetProgrammeCount:Int() {_exposeToLua}
		Return Self.List.count()
	End Method

	Method GetContractCount:Int() {_exposeToLua}
		Return Self.ContractList.count()
	End Method


	'removes Contract from Collection (Advertising-Menu in Programmeplanner)
	Method RemoveOriginalContract(_contract:TContract) {_private hideFromAI}
		If _contract <> Null
			For Local contract:TContract = EachIn ContractList
				If contract.title = _contract.title And contract.clone = 0
					'Print "removing contract:"+contract.title
					ContractList.Remove(contract)
					Exit
				EndIf
			Next
		EndIf
	End Method

	Method RemoveProgramme:Int(programme:TProgramme, typ:Int = 1)
		If programme = Null Then Return False

		Print "removed from player collection programme:"+programme.title +  " "+typ
		List.remove(programme)
		MovieList.remove(programme)
		If game.networkgame Then NetworkHelper.SendProgrammeCollectionChange(Self.parent.playerID, programme, typ)
	End Method

	Method AddContract:Int(contract:TContract, owner:Int=0)
		If contract <> Null
			contract.sign(owner)
			'DebugLog contract.calculatedMinAudience + " ("+contract.GetMinAudiencePercentage(contract.minaudience)+"%)"
			Self.ContractList.AddLast(contract)
			TContractBlock.Create(contract, 1,owner)
		EndIf
	End Method

	Method AddProgramme:Int(programme:TProgramme, typ:Int=0)
		If programme <> Null
			programme.owner = parent.playerID
			If programme.isMovie() Then MovieList.AddLast(programme) Else SeriesList.AddLast(programme)
			Self.List.AddLast(programme)
			'readd
			If typ = 2 And game.networkgame Then NetworkHelper.SendProgrammeCollectionChange(Self.parent.playerID, programme, typ)
		EndIf
	End Method

	'GetLocalRandom... differs from GetRandom... for using it's personal programmelist
	'instead of the global one
	'returns a movie out of the players programmebouquet

	Method GetRandomProgramme:TProgramme(serie:Int = 0) {_exposeToLua}
		If serie Then Return Self.GetRandomSerie()
		Return Self.GetRandomMovie()
	End Method

	Method GetRandomMovie:TProgramme() {_exposeToLua}
		Return TProgramme(MovieList.ValueAtIndex(randRange(0, MovieList.count()-1)))
	End Method

	Method GetRandomSerie:TProgramme() {_exposeToLua}
		Return TProgramme(SeriesList.ValueAtIndex(randRange(0, SeriesList.count()-1)))
	End Method

	Method GetRandomContract:TContract() {_exposeToLua}
		Return TContract(ContractList.ValueAtIndex(randRange(0, ContractList.count()-1)))
	End Method


	'get programme by index number in list - useful for lua-scripts
	Method GetProgrammeFromList:TProgramme(pos:Int=0) {_exposeToLua}
		Return TProgramme( List.ValueAtIndex(pos) )
	End Method

	'get movie by index number in list - useful for lua-scripts
	Method GetMovieFromList:Tprogramme(pos:Int=0) {_exposeToLua}
		Return TProgramme( MovieList.ValueAtIndex(pos) )
	End Method

	'get series by index number in list - useful for lua-scripts
	Method GetSeriesFromList:Tprogramme(pos:Int=0) {_exposeToLua}
		Return TProgramme( SeriesList.ValueAtIndex(pos) )
	End Method

	'get contract by index number in list - useful for lua-scripts
	Method GetContractFromList:TContract(pos:Int=0) {_exposeToLua}
		Return TContract( ContractList.ValueAtIndex(pos) )
	End Method



	Method GetProgramme:TProgramme(id:Int) {_exposeToLua}
		For Local obj:TProgramme = EachIn Self.List
			If Obj.id = id Then Return obj
		Next
		Return Null
	End Method

	Method GetContract:TContract(id:Int) {_exposeToLua}
		For Local contract:TContract=EachIn Self.ContractList
			If contract.id = id Then Return contract
		Next
		Return Null
	End Method

	Method GetMovies:Object[]() {_exposeToLua}
		Return Self.MovieList.toArray()
	End Method

	Method GetSeries:Object[]() {_exposeToLua}
		Return Self.SeriesList.toArray()
	End Method

	Method GetProgrammes:Object[]() {_exposeToLua}
		Return Self.list.toArray()
	End Method

	Method GetContracts:Object[]() {_exposeToLua}
		Return Self.ContractList.toArray()
	End Method
End Type


Type TProgrammeElement
	Field title:String 	{_exposeToLua}

	Field description:String
	Field id:Int = 0	{_exposeToLua}
	Field programmeType:Int = 0
	Global LastID:Int = 0

	Method BaseInit(title:String, description:String, programmeType:Int = 0)
		Self.title = title
		Self.description = description
		Self.programmeType = programmeType
		Self.id = Self.LastID

		Self.LastID :+1
	End Method

	Method GetId:Int() {_exposeToLua}
		Return Self.id
	End Method
End Type

'ad-contracts
Type TContract Extends TProgrammeElement {_exposeToLua="selected"}
  Field daystofinish:Int
  Field spotcount:Int
  Field spotssent:Int
  Field spotnumber:Int = -1
  Field botched:Int =0
  Field senddate:Int = -1
  Field sendtime:Int = -1
  Field targetgroup:Int
  Field minaudience:Float
  Field minimage:Float
  Field fixedPrice:Int
  Field profitBase:Float
  Field penaltyBase:Float
  Field finished:Int =0
  Field clone:Int = 0 'is it a clone (used for adblocks) or the original one (contract-gfxlist)
  Field owner:Int = 0
  Field daysigned:Int 'day the contract has been taken from the advertiser-room
  Field profit:Int		= -1
  Field penalty:Int		= -1
  Field calculatedMinAudience:Int 	= -1

  Global List:TList = CreateList() {saveload = "special"}

	Function Load:TContract(pnode:TxmlNode)
Print "implement load contracts"
Rem
		Local Contract:TContract = New TContract
		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If NODE.Name = Upper("MINAUDIENCEMULTIPLICATOR")
				TContract.MinAudienceMultiplicator = Double(node.Attribute("var").Value)
			EndIf
			If NODE.Name = Upper("CONTRACTS")
				If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
				Local typ:TTypeId = TTypeId.ForObject(StationMap)
				For Local t:TField = EachIn typ.EnumFields()
					If t.MetaData("saveload") <> "special" And Upper(t.name()) = NODE.name
						t.Set(Contract, nodevalue)
					EndIf
				Next
				If contract.owner > 0 And contract.owner <= 4
				    If contract.clone > 0 Then Players[contract.owner].ProgrammePlan.AddContract(contract)
				    If contract.clone = 0 Then Players[contract.owner].ProgrammeCollection.AddContract(contract)
				EndIf
				If contract.clone = 0 Then TContract.List.AddLast(contract)
			EndIf
			NODE = NODE.nextSibling()
		Wend
		Return contract
endrem
	End Function

	Function LoadAll()
Print "TContract.LoadAll()"
Return
Rem
		PrintDebug("TContract.LoadAll()", "Lade Werbeverträge", DEBUG_SAVELOAD)
		TContract.List.Clear()
		Local Children:TList = LoadSaveFile.NODE.ChildList
		For Local node:xmlNode = EachIn Children
			If NODE.name = "ALLCONTRACTS"
			      TContract.Load(NODE)
			End If
		Next
endrem
	End Function

	Function SaveAll()
		LoadSaveFile.xmlBeginNode("ALLCONTRACTS")
   			For Local Contract:TContract = EachIn TContract.List
     			Contract.Save()
   			Next
   		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("CONTRACT")
 			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "special" Then LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
			Next
		LoadSaveFile.xmlCloseNode()
	End Method

	Function Create:TContract(title:String, description:String, daystofinish:Int, spotcount:Int, targetgroup:Int, minaudience:Int, minimage:Int, fixedPrice:Int, profit:Int, penalty:Int, id:Int=0, owner:Int = 0)
		Local obj:TContract =New TContract
		obj.BaseInit(title, description, TYPE_CONTRACT)
		obj.daystofinish	= daystofinish
		obj.spotcount		= spotcount
		obj.spotssent		= 0
		obj.owner			= owner
		obj.spotnumber		=  1
		obj.targetgroup		= targetgroup
		obj.minaudience		= Float(minaudience) / 10.0
		obj.minimage		= Float(minimage) / 10.0
		obj.fixedPrice		= fixedPrice
		obj.profitBase		= Float(profit)
		obj.penaltyBase    	= Float(penalty)
		obj.daysigned   	= -1

		TContract.List.AddLast(obj)
		SortList(TContract.List)
		Return obj
	End Function


	Function GetRandomContractFromList:TContract(_list:TList, playerID:Int =-1)
		If _list = Null Then Return Null
		If _list.count() > 0
			Local obj:TContract = TContract(_list.ValueAtIndex((randRange(0, _list.Count() - 1))))
			If obj <> Null
				obj.owner = playerID
				Return obj
			EndIf
		EndIf
		Print "contract list empty - wrong filter ?"
		Return Null
	End Function

	Function GetRandomContract:TContract(playerID:Int = -1)
		'filter to entries we need
		Local obj:TContract
		Local resultList:TList = CreateList()
		For obj = EachIn TContract.list
			If obj.owner <= 0 And obj.daysigned < 0 Then resultList.addLast(obj)
		Next
		Return TContract.GetRandomContractFromList(resultList, playerID)
	End Function

	Function GetRandomContractWithMaxAudience:TContract(maxAudience:Int, playerID:Int = -1, maxAudienceQuote:Float=0.35)
		'maxAudienceQuote - xx% market share as maximum
		'filter to entries we need
		Local obj:TContract
		Local resultList:TList = CreateList()
		For obj = EachIn TContract.list
			If obj.owner <= 0 And obj.daysigned < 0 And obj.getMinAudience(playerID) <= maxAudience*maxAudienceQuote
				resultList.addLast(obj)
			EndIf
		Next
		Return TContract.GetRandomContractFromList(resultList, playerID)
	End Function



	Method Sign:Int(playerID:Int, day:Int = -1)
		If day < 0 Then day = game.day
		owner					= playerID
		daysigned				= day
		calculatedMinAudience	= getMinAudience(playerID)
		self.profit				= self.GetProfit()
		self.penalty			= self.GetPenalty()
	End Method

	Method GetMinAudiencePercentage:Float(dbvalue:Int = -1)  {_exposeToLua}
		If dbvalue < 0 Then dbvalue = Self.minaudience
		Return dbvalue / 100.0 'from 75% to 0.75
	End Method

	'multiplies basevalues of prices, values are from 0 to 255 for 1 spot... per 1000 people in audience
	'if targetgroup is set, the price is doubled
	Method GetProfit:Int(baseValue:Int= -1, playerID:Int=-1) {_exposeToLua}
		If Self.profit >= 0 Then Return Self.profit
		if baseValue = -1 then baseValue = self.profitBase
		if playerID = -1 then playerID = self.owner

		Return CalculatePrices(baseValue, playerID)
	End Method

	Method GetPenalty:Int(baseValue:Int= -1, playerID:Int=-1) {_exposeToLua}
		If Self.penalty >= 0 Then Return Self.penalty
		if baseValue = -1 then baseValue = self.penaltyBase
		if playerID = -1 then playerID = self.owner

		Return CalculatePrices(baseValue, playerID)
	End Method

	Method CalculatePrices:Int(baseprice:Int=0, playerID:Int=-1)
		Local price:Float				= baseprice
		Local audiencepercentage:Float	= Self.GetMinAudiencePercentage()


		'ad is with fixed price - only avaible without minimum restriction
		If Self.fixedPrice>0
			Return price * spotcount
		Else
			'print title+" spots: "+spotcount+" baseprice: "+baseprice + " audience:"+audiencepercentage+"%   * " + int(Max(1, CalculateMinAudience(playerID)/1000)) + "tsd viewers	 playerid:"+playerID

			'price we would get if 100% of audience is watching
			price :* Max(5, getMinAudience(playerID)/1000)
		EndIf
		If Self.targetgroup > 0 Then price :*1.5

		'price is for each spot
		price:* Float(spotcount)

		price = TFunctions.RoundMoney(price)
		Return price
	End Method

	'gets audience in numbers (not percents)
	Method GetMinAudience:Int(playerID:Int=-1) {_exposeToLua}
		If playerID < 0 Then playerID = Self.owner

		If calculatedMinAudience >=0 Then Return calculatedMinAudience
		If Not Game.isPlayerID(playerID)
			Local avg:Int = 0
			For Local i:Int = 1 To 4
				avg :+ Players[ i ].maxaudience
			Next
			avg:/4
			Return Floor(avg * Self.GetMinAudiencePercentage() / 1000) * 1000
		EndIf
		'0.5 = more than 50 percent of whole germany wont watch TV the same time
		Return Floor(Players[ playerID ].maxaudience*0.5 * Self.GetMinAudiencePercentage() / 1000) * 1000
	End Method

	'days left for sending all contracts from today
	Method GetDaysLeft:Int() {_exposeToLua}
		Return (daystofinish-(Game.day - daysigned))
	End Method

	'amount of spots to send
	Method GetSpotCount:Int() {_exposeToLua}
		Return self.spotcount
	End Method

	'total days to send contract from date of sign
	Method GetDaysToFinish:Int() {_exposeToLua}
		Return self.daysToFinish
	End Method

	Method GetTargetGroup:Int() {_exposeToLua}
		Return self.targetgroup
	End Method

	Method GetTargetGroupString:String(group:Int=-1) {_exposeToLua}
		if group < 0 then group = self.targetGroup
		If group >= 1 And group <=9
			Return GetLocale("AD_GENRE_"+group)
		EndIf
		Return GetLocale("AD_GENRE_NONE")
	End Method



	Method ShowSheet:Int(x:Int,y:Int, plannerday:Int = -1, successfulSentContracts:Int=-1)
		Local playerID:Int = owner
		If playerID <= 0 Then playerID = game.playerID

		Assets.GetSprite("gfx_datasheets_contract").Draw(x,y)

		Local font:TBitmapFont = Assets.fonts.basefont
		Assets.fonts.basefontBold.drawBlock(title 	       				, x+10 , y+11 , 270, 70,0, 0,0,0, 0,1)
		font.drawBlock(description     		 		, x+10 , y+33 , 270, 70)
		font.drawBlock(getLocale("AD_PROFIT")+": "	, x+10 , y+94 , 130, 16)
		font.drawBlock(functions.convertValue(String( self.getProfit( playerID ) ), 2, 0)+" "+CURRENCYSIGN , x+10 , y+94 , 130, 16,2)
		font.drawBlock(getLocale("AD_TOSEND")+": "    , x+150, y+94 , 127, 16)
		If successfulSentContracts >=0
			font.DrawBlock((spotcount - successfulSentContracts)+"/"+spotcount , x+150, y+91 , 127, 16,2)
		Else
			font.drawBlock(spotcount+"/"+spotcount , x+150, y+91 , 127, 19,2)
		EndIf
		font.drawBlock(getLocale("AD_PENALTY")+": "       , x+10 , y+117, 130, 16)
		font.drawBlock(functions.convertValue(String( self.GetPenalty( playerID ) ), 2, 0)+" "+CURRENCYSIGN, x+10 , y+117, 130, 16,2)
		font.drawBlock(getLocale("AD_MIN_AUDIENCE")+": "    , x+150, y+117, 127, 16)
		font.drawBlock(functions.convertValue(String( GetMinAudience( playerID ) ), 2, 0), x+150, y+117, 127, 16,2)
		font.drawBlock(getLocale("AD_TARGETGROUP")+": "+self.GetTargetgroupString()   , x+10 , y+140 , 270, 16)
		If owner <= 0
			If daystofinish > 1
				font.drawBlock(getLocale("AD_TIME")+": "+daystofinish + getLocale("DAYS"), x+86 , y+163 , 122, 16)
			Else
				font.drawBlock(getLocale("AD_TIME")+": "+daystofinish + getLocale("DAY"), x+86 , y+163 , 122, 16)
			EndIf
		Else
			Select self.getDaysLeft()
				Case 0	font.drawBlock(getLocale("AD_TIME")+": "+getLocale("AD_TILL_TODAY") , x+86 , y+163 , 126, 16)
				Case 1	font.drawBlock(getLocale("AD_TIME")+": "+getLocale("AD_TILL_TOMORROW") , x+86 , y+163 , 126, 16)
				Default	font.drawBlock(getLocale("AD_TIME")+": "+Replace(getLocale("AD_STILL_X_DAYS"),"%1", Self.GetDaysLeft()), x+86 , y+163 , 122, 16)
			EndSelect
		EndIf
	End Method

	Function GetContract:TContract(number:Int)
		For Local contract:TContract = EachIn List
			If contract.id = number Then Return contract
		Next
		Return Null
	End Function
End Type

Type TProgramme Extends TProgrammeElement {_exposeToLua="selected"} 			'parent of movies, series and so on
	Field actors:String			= ""
	Field director:String		= ""
	Field country:String		= "UNK"
	Field year:Int				= 1900
	Field livehour:Int			= 0
	Field Outcome:Float			= 0
	Field review:Float			= 0
	Field speed:Float			= 0
	Field relPrice:Int			= 0
	Field Genre:Int				= 0
	Field episodeNumber:Int		= 0
	Field episodeList:TList		= CreateList()
	Field blocks:Int			= 1
	Field fsk18:Int				= 0
	Field _isMovie:Int			= 1
	Field topicality:Int		= -1 				'how "attractive" a movie is (the more shown, the less this value)
	Field maxtopicality:Int 	= 255
	Field parent:TProgramme		= Null
	Field owner:Int = 0
	Field attractiveness:Float	= -1 'Wird nur in der Lua-KI verwendet du die Filme zu bewerten
	'holding all programmes
	Global ProgList:TList		= CreateList()	{saveload = "nosave"}
	Global ProgMovieList:TList	= CreateList()	{saveload = "nosave"}
	Global ProgSeriesList:TList	= CreateList()	{saveload = "nosave"}


	Function Create:TProgramme(title:String, description:String, actors:String, director:String, country:String, year:Int, livehour:Int, Outcome:Float, review:Float, speed:Float, relPrice:Int, Genre:Int, blocks:Int, fsk18:Int, episode:Int=-1)
		Local obj:TProgramme =New TProgramme
		If episode >= 0
			obj.BaseInit(title, description, TYPE_SERIE)
			obj._isMovie     = 0
			'only add parent of series
			If episode = 0 Then ProgSeriesList.AddLast(obj)
		Else
			obj.BaseInit(title, description, TYPE_MOVIE)
			obj._isMovie     = 1
			ProgMovieList.AddLast(obj)
		EndIf
		obj.episodeNumber = episode
		obj.review      = Max(0,review)
		obj.speed       = Max(0,speed)
		obj.relPrice    = Max(0,relPrice)
		obj.Outcome	    = Max(0,Outcome)
		obj.Genre       = Max(0,Genre)
		obj.blocks      = Max(1,blocks)
		obj.fsk18       = fsk18
		obj.actors 		= actors
		obj.director    = director
		obj.country     = country
		obj.year        = year
		obj.livehour    = Max(-1,livehour)
		obj.topicality  = obj.ComputeTopicality()
		obj.maxtopicality = obj.topicality
		ProgList.AddLast(obj)
		Return obj
	End Function


	Method AddEpisode:TProgramme(title:String, description:String, actors:String, director:String, country:String, year:Int, livehour:Int, Outcome:Float, review:Float, speed:Float, relPrice:Int, Genre:Int, blocks:Int, fsk18:Int, episode:Int=0, id:Int=0)
		Local obj:TProgramme = New TProgramme
		obj.BaseInit( title, description, TYPE_SERIE | TYPE_EPISODE)
		If review < 0 Then obj.review = Self.review Else obj.review = review
		If speed < 0 Then obj.speed = Self.speed Else obj.speed = speed
		If relPrice < 0 Then obj.relPrice = Self.relPrice Else obj.relPrice = relPrice
		If blocks < 0 Then obj.blocks = Self.blocks Else obj.blocks = blocks
		If year < 0	Then obj.year = Self.year Else obj.year = year
		If livehour < 0	Then obj.livehour = Self.livehour Else obj.livehour = livehour
		If genre < 0 Then obj.genre = Self.genre Else obj.genre = genre
		If actors = "" Then obj.actors = Self.actors Else obj.actors = actors
		If director = "" Then obj.director = Self.director Else obj.director = director
		If country = "" Then obj.country = Self.country Else obj.country = country

		obj.topicality		= obj.ComputeTopicality()
		obj.maxtopicality	= obj.topicality

		obj.fsk18       	= fsk18
		obj._isMovie     	= 0
		If episode = 0 Then episode = Self.episodeList.count()+1
		obj.episodeNumber	= episode
		obj.parent			= Self
		Self.episodeList.AddLast(obj)
		ProgList.AddLast(obj)
		Return obj
	End Method

	Function Load:TProgramme(pnode:txmlNode, isEpisode:Int = 0, origowner:Int = 0)
	Print "implement Load:TProgramme"
Return Null
Rem
		Local Programme:TProgramme = New TProgramme
		Programme.episodeList = CreateList() ' TObjectList.Create(100)

		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(Programme)
			For Local t:TField = EachIn typ.EnumFields()
				If (t.MetaData("saveload") <> "nosave" Or t.MetaData("saveload") = "normal") And Upper(t.name()) = NODE.name
					t.Set(Programme, nodevalue)
				EndIf
			Next
			Select NODE.name
				Case "EPISODE" Programme.EpisodeList.AddLast(TProgramme.Load(NODE, 1, Programme.owner))
			End Select
			NODE = NODE.nextSibling()
		Wend
		If Programme.episodeList.count() > 0 And Not isEpisode
			' Print "loaded series: "+Programme.title
			TProgramme.ProgSeriesList.AddLast(Programme)
		Else If Not isEpisode
			TProgramme.ProgMovieList.AddLast(Programme)
			'Print "loaded  movie: "+Programme.title
		EndIf
		TProgramme.ProgList.AddLast(Programme)

		if Programme.owner > 0
			'Print "added to player:"+Programme.used + " ("+Programme.title+") Clone:"+Programme.clone + " Time:"+Programme.sendtime
			Players[Programme.owner].ProgrammeCollection.AddProgramme(Programme)
		elseIf isEpisode And origowner > 0
			Players[origowner].ProgrammeCollection.AddProgramme(Programme)
			'Print "added to player:"+Programme.used
		EndIf
		Return programme
endrem
	End Function

	Function LoadAll()
Print "implement TProgramme.LoadAll()"
Return
Rem
		PrintDebug("TProgramme.LoadAll()", "Lade Programme", DEBUG_SAVELOAD)
		ProgList.Clear()
		ProgMovieList.Clear()
		ProgSeriesList.Clear()
		Local Children:TList = LoadSaveFile.NODE.ChildList
		For Local NODE:xmlNode = EachIn Children
			If NODE.name = "PROGRAMME" then TProgramme.Load(NODE)
		Next
endrem
	End Function

	Function SaveAll()
		Local Programme:TProgramme
		Local i:Int = 0
		LoadSaveFile.xmlBeginNode("ALLPROGRAMMES")
			For i = 0 To TProgramme.ProgMovieList.Count()-1
				Programme = TProgramme(TProgramme.ProgMovieList.ValueAtIndex(i))
'				Programme = TProgramme(TProgramme.ProgMovieList.Items[i] )
				If Programme <> Null Then Programme.Save()
			Next
			For i = 0 To TProgramme.ProgSeriesList.Count()-1
'				Programme = TProgramme(TProgramme.ProgSeriesList.Items[i])
				Programme = TProgramme(TProgramme.ProgSeriesList.ValueAtIndex(i))
				If Programme <> Null Then Programme.Save()
			Next
	 	LoadSaveFile.xmlCloseNode()
	End Function

	Method Save(isepisode:Int=0)
	    If Not isepisode Then LoadSaveFile.xmlBeginNode("PROGRAMME")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "nosave" Or t.MetaData("saveload") = "normal"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			'SaveFile.WriteInt(Programme.episodeList.Count()-1)
			If Not isepisode
				For Local j:Int = 0 To Self.episodeList.Count()-1
					LoadSaveFile.xmlBeginNode("EPISODE")
						TProgramme(Self.episodeList.ValueAtIndex(j)).Save(True)
'						TProgramme(Self.episodeList.Items[j] ).Save(True)
					LoadSaveFile.xmlCloseNode()
				Next
			EndIf
		If Not isepisode Then LoadSaveFile.xmlCloseNode()
	End Method

	Method Buy()
		Players[Game.playerID].finances[Game.getWeekday()].PayMovie(self.getPrice())
		'DebugLog "Programme "+title +" bought"
	End Method

	Method Sell()
		Players[Game.playerID].finances[Game.getWeekday()].SellMovie(self.getPrice())
		'DebugLog "Programme "+title +" sold"
	End Method

	Function CountGenre:Int(Genre:Int, Liste:TList)
		Local genrecount:Int=0
		For Local movie:TProgramme= EachIn Liste
			If movie.Genre = Genre Then genrecount:+1
		Next
		Return genrecount
	End Function

	Function GetProgramme:TProgramme(id:Int)
		For Local i:Int = 0 To ProgList.Count() - 1
			If TProgramme(ProgList.ValueAtIndex(i)) <> Null
				If TProgramme(ProgList.ValueAtIndex(i)).id = id Then Return TProgramme(ProgList.ValueAtIndex(i))
			EndIf
		Next
		Return Null
	End Function

	Function GetMovie:TProgramme(id:Int)
		For Local i:Int = 0 To ProgMovieList.Count() - 1
			If TProgramme(ProgMovieList.ValueAtIndex(i)) <> Null
				If TProgramme(ProgMovieList.ValueAtIndex(i)).id = id Then Return TProgramme(ProgMovieList.ValueAtIndex(i))
			EndIf
		Next
		Return Null
	End Function

	Function GetSeries:TProgramme(id:Int)
		For Local i:Int = 0 To ProgSeriesList.Count() - 1
			If TProgramme(ProgSeriesList.ValueAtIndex(i)).id = id Then Return TProgramme(ProgSeriesList.ValueAtIndex(i))
		Next
		Return Null
	End Function

	Function GetRandomProgrammeFromList:TProgramme(_list:TList, playerID:Int =-1)
		If _list = Null Then Return Null
		If _list.count() > 0
			Local movie:TProgramme = TProgramme(_list.ValueAtIndex((randRange(0, _list.Count() - 1))))
			If movie <> Null
				movie.owner = playerID
				Return  movie
			EndIf
		EndIf
		Print "ProgrammeList empty - wrong filter ?"
		Return Null
	End Function

	Function GetRandomMovie:TProgramme(playerID:Int = -1)
		'filter to entries we need
		Local movie:TProgramme
		Local resultList:TList = CreateList()
		For movie = EachIn ProgMovieList
			If movie.owner = 0 And movie.isMovie() Then resultList.addLast(movie)
		Next
		Return TProgramme.GetRandomProgrammeFromList(resultList, playerID)
	End Function

	Function GetRandomMovieWithMinPrice:TProgramme(MinPrice:Int, playerID:Int = -1)
		'filter to entries we need
		Local movie:TProgramme
		Local resultList:TList = CreateList()
		For movie = EachIn ProgMovieList
			If movie.getPrice() >= MinPrice And  movie.owner = 0 And movie.isMovie() Then resultList.addLast(movie)
		Next
		Return TProgramme.GetRandomProgrammeFromList(resultList, playerID)
	End Function

	Function GetRandomProgrammeByGenre:TProgramme(genre:Int = 0, playerID:Int = -1)
		Local movie:TProgramme
		Local resultList:TList = CreateList()
		For movie = EachIn ProgList
			If movie.genre = genre And movie.episodeNumber <= 0 And movie.owner = 0 Then resultList.addLast(movie)
		Next
		Return TProgramme.GetRandomProgrammeFromList(resultList, playerID)
	End Function

	Function GetRandomSerie:TProgramme(playerID:Int = -1)
		Local movie:TProgramme
		Local resultList:TList = CreateList()
		For movie = EachIn ProgSeriesList
			If movie.owner = 0 And movie.episodeNumber <= 0 And Not movie.isMovie() Then resultList.addLast(movie)
		Next
		Return TProgramme.GetRandomProgrammeFromList(resultList, playerID)
	End Function

	Method GetAttractiveness:Float() {_exposeToLua}
		Return Self.attractiveness
	End Method

	Method SetAttractiveness(value:Float) {_exposeToLua}
		Self.attractiveness = value
	End Method

	Method GetGenre:int() {_exposeToLua}
		return self.genre
	End Method

	Method GetGenreString:String(_genre:Int=-1) {_exposeToLua}
		If _genre > 0 Then Return GetLocale("MOVIE_GENRE_" + _genre)
		Return GetLocale("MOVIE_GENRE_" + Self.genre)
	End Method

	Method isMovie:int() {_exposeToLua}
		return self._isMovie
	End Method

	Method GetBlocks:int() {_exposeToLua}
		return self.blocks
	End Method

	Method GetXRated:int() {_exposeToLua}
		return (self.fsk18 <> "")
	End Method

	Method GetOutcome:int() {_exposeToLua}
		return self.outcome
	End Method

	Method GetSpeed:int() {_exposeToLua}
		return self.speed
	End Method

	Method GetReview:int() {_exposeToLua}
		return self.review
	End Method

	Method GetTopicality:int() {_exposeToLua}
		return self.topicality
	End Method

	Method GetEpisodeCount:int() {_exposeToLua}
		return self.episodeList.count()
	End Method

	'Manuel: Wird nur in der Lua-KI verwendet
	Method GetPricePerBlock:Int() {_exposeToLua}
		Return Self.GetPrice() / Self.GetBlocks()
	End Method

	'Manuel: Wird nur in der Lua-KI verwendet
	Method GetQualityLevel:Int() {_exposeToLua}
		Local quality:Int = Self.GetBaseAudienceQuote()

		If quality > 20
			Return 5
		ElseIf quality > 15
			Return 4
		ElseIf quality > 10
			Return 3
		ElseIf quality > 5
			Return 2
		Else
			Return 1
		EndIf
	End Method

	'returns array of all episodes or an empty array if no episodes are found
	Method GetEpisodes:Object[]() {_exposeToLua}
		If Self.episodeList
			Return Self.episodeList.toArray()
		Else
			Return CreateList().toArray()
		EndIf
	End Method

	'returns episode if found
	Method GetEpisode:TProgramme(number:Int) {_exposeToLua}
		If TProgramme(Self.episodeList.ValueAtIndex(number)) <> Null Then Return TProgramme(Self.episodeList.ValueAtIndex(number))
		Return Null
	End Method

	Method ComputeTopicality:Float()
		Local value:Int = 0

		'parent of serie called
		If Self.episodeList.count() > 0
			For Local episode:TProgramme = EachIn Self.episodeList
				episode.topicality = episode.ComputeTopicality()
				value :+ episode.topicality
			Next
			topicality = value / Self.episodeList.count()
		ElseIf topicality < 0
			topicality = Max(0, 255 - 2 * Max(0, Game.year - year) )   'simplest form ;D
		EndIf
		Return topicality
	End Method

	'base quote of a programme
	Method GetBaseAudienceQuote:Float(lastquote:Float=0.1) {_exposeToLua}
		Local quality:Float		= 0.0

		If outcome > 0
			quality	=	 0.2	*Float(lastquote)..
						+0.35	*Float(Outcome)/255.0..
						+0.2	*Float(review)/255.0..
						+0.15	*Float(speed)/255.0..
		Else 'tv shows
			quality	=	 0.3	*Float(lastquote)..
						+0.4	*Float(review)/255.0..
						+0.3	*Float(speed)/255.0..
		EndIf

		'the older the less ppl want to watch - 1 year = 0.99%, 2 years = 0.98%...
		Local age:Int = Max(0,100-Max(0,game.year - year))
		quality:* Max(0.10, (age/ 100.0))

		'repetitions wont be watched that much
		quality	:*	(ComputeTopicality()/255.0)^2

		'no minus quote
		Return Max(0, quality)
	End Method

	'computes a percentage which could be multiplied with maxaudience
	Method GetAudienceQuote:Float(lastquote:Float=0, maxAudiencePercentage:Float=-1)
		Local quote:Float		= self.getBaseAudienceQuote(lastquote)

		'a bit of luck :D
		quote	:+ Float(RandRange(-10,10))/1000.0 ' +/- 0.1-1%

		If maxAudiencePercentage = -1
			quote :* Game.maxAudiencePercentage
		Else
			quote :* maxAudiencePercentage
		EndIf

		'no minus quote
		Return Max(0, quote)
	End Method

	Method CutTopicality:Int()
		Select genre
			Case 13, 15, 17, 20
				topicality :* 0.7
			Case 20 'call in
				topicality :* 0.8
			Default
				topicality :* 0.5
		End Select
'		local topicalityPercentage:float= float(topicality)/float(maxTopicality)
'		topicalityPercentage * topicalityPercentage

	End Method

	Method RefreshTopicality:Int()
		topicality = Min(topicality*1.5, maxtopicality)
		Return topicality
	End Method

	Method GetPrice:Int() {_exposeToLua}
		Local value:Float
		Local tmpreview:Float
		Local tmpspeed:Float

		If Self.episodeList.count() > 0
			For Local episode:TProgramme = EachIn Self.episodeList
				value :+ episode.getPrice()
			Next
			value :* 0.75
		Else
			If Outcome > 0 'movies
				value = 0.45 * 255 * Outcome + 0.25 * 255 * review + 0.3 * 255 * speed
				If (maxTopicality >= 220) Then value:*1.25
				If (maxTopicality >= 240) Then value:*1.25
				If (maxTopicality >= 250) Then value:*1.25
				If (maxTopicality > 253)  Then value:*1.4 'the more current the more expensive
			Else 'shows, productions, series...
				tmpreview = 1.6667 * review
				If (review > 0.5 * 255) Then tmpreview = 255 - 2.5 * (review - 0.5 * 255)
				tmpspeed = 1.6667 * speed
				If (speed > 0.6 * 255) Then tmpspeed = 255 - 2.5 * (speed - 0.6 * 255)
				value = 0.4 * 255 * tmpreview + 0.6 * 255 * tmpspeed
			EndIf
			value:*(3 * ComputeTopicality() / 255)
			value = Int(Floor(value / 1000) * 1000)
		EndIf
		Return value
	End Method

	Method ShowSheet:Int(x:Int,y:Int, plannerday:Int = -1, series:TProgramme=Null)
		Local widthbarspeed:Float		= Float(speed / 255)
		Local widthbarreview:Float		= Float(review / 255)
		Local widthbaroutcome:Float		= Float(Outcome/ 255)
		Local widthbartopicality:Float	= Float(Float(topicality) / 255)
		Local widthbarMaxTopicality:Float= Float(Float(MaxTopicality) / 255)
		Local normalFont:TBitmapFont	= Assets.fonts.baseFont

		Local dY:Int = 0

		If isMovie()
			Assets.GetSprite("gfx_datasheets_movie").Draw(x,y)
			Assets.fonts.basefontBold.DrawBlock(title, x + 10, y + 11, 278, 20)
		Else
			Assets.GetSprite("gfx_datasheets_series").Draw(x,y)
			'episode display
			If series <> Null
				Assets.fonts.basefontBold.DrawBlock(series.title, x + 10, y + 11, 278, 20)
				normalFont.DrawBlock("(" + episodeNumber + "/" + series.episodeList.count() + ") " + title, x + 10, y + 34, 278, 20, 0)  'prints programmedescription on moviesheet
			Else
				Assets.fonts.basefontBold.DrawBlock(title, x + 10, y + 11, 278, 20)
				normalFont.DrawBlock(episodeList.count()+" "+GetLocale("MOVIE_EPISODES") , x+10,  y+34 , 278, 20,0) 'prints programmedescription on moviesheet
			EndIf

			dy :+ 22
		EndIf
		If Self.fsk18 <> 0 Then normalFont.DrawBlock(GetLocale("MOVIE_XRATED") , x+240 , y+dY+34 , 50, 20,0) 'prints pg-rating

		normalFont.DrawBlock(GetLocale("MOVIE_DIRECTOR")+":", x+10 , y+dY+135, 280, 16,0)
		normalFont.DrawBlock(GetLocale("MOVIE_ACTORS")+":"  , x+10 , y+dY+148, 280, 32,0)
		normalFont.DrawBlock(GetLocale("MOVIE_SPEED")       , x+222, y+dY+187, 280, 16,0)
		normalFont.DrawBlock(GetLocale("MOVIE_CRITIC")      , x+222, y+dY+210, 280, 16,0)
		normalFont.DrawBlock(GetLocale("MOVIE_BOXOFFICE")   , x+222, y+dY+233, 280, 16,0)
		normalFont.DrawBlock(director         , x+10 +5+ Int(normalFont.getWidth(GetLocale("MOVIE_DIRECTOR")+":")) , y+dY+135, 280-15-normalFont.getWidth(GetLocale("MOVIE_DIRECTOR")+":"), 16,0) 	'prints director
		normalFont.DrawBlock(actors           , x+10 +5+ Int(normalFont.getWidth(GetLocale("MOVIE_ACTORS")+":")), y+dY+148, 280-15-normalFont.getWidth(GetLocale("MOVIE_ACTORS")+":"), 32,0) 	'prints actors
		normalFont.DrawBlock(GetGenreString(Genre)  , x+78 , y+dY+35 , 150, 16,0) 	'prints genre
		normalFont.DrawBlock(country          , x+10 , y+dY+35 , 150, 16,0)		'prints country
		If genre <> GENRE_CALLINSHOW
			normalFont.DrawBlock(year		      , x+36 , y+dY+35 , 150, 16,0) 	'prints year
			normalFont.DrawBlock(description      , x+10,  y+dy+56 , 278, 70,0) 'prints programmedescription on moviesheet
		Else
			normalFont.DrawBlock(description      , x+10,  y+dy+56 , 278, 50,0) 'prints programmedescription on moviesheet
			normalFont.DrawBlock(getLocale("MOVIE_CALLINSHOW")      , x+10,  y+dy+106 , 278, 20,0) 'prints programmedescription on moviesheet
		EndIf
		normalFont.DrawBlock(GetLocale("MOVIE_TOPICALITY")  , x+84, y+281, 40, 16,0)
		normalFont.DrawBlock(GetLocale("MOVIE_BLOCKS")+": "+blocks, x+10, y+281, 100, 16,0)
		normalFont.DrawBlock(self.GetPrice(), x+240, y+281, 120, 20,0)

		If widthbarspeed  >0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+13 - 200 + widthbarspeed*200,	y+dY+188,		x+13, y+dY+187, 200, 12)
		If widthbarreview >0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+13 - 200 + widthbarreview*200,y+dY+210,		x+13, y+dY+209, 200, 12)
		If widthbaroutcome>0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+13 - 200 + widthbaroutcome*200,y+dY+232,		x+13, y+dY+231, 200, 12)
		SetAlpha 0.3
		If widthbarMaxTopicality>0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+115 - 200 + widthbarMaxTopicality*100,y+280,	x+115, y+279, 100,12)
		SetAlpha 1.0
		If widthbartopicality>0.01 Then Assets.GetSprite("gfx_datasheets_bar").DrawClipped(x+115 - 200 + widthbartopicality*100,y+280,	x+115, y+279, 100,12)
	End Method
 End Type

Type TNews Extends TProgrammeElement
  Field Genre:Int
  Field quality:Int
  Field price:Int
  Field episodecount:Int = 0
  Field episode:Int = 0
  Field episodeList:TList 	{saveload="special"}
  Field happenedday:Int = -1
  Field happenedhour:Int = -1
  Field happenedminute:Int = -1
  Field parent:TNews = Null
  Field used : Int = 0  										'event happened, so this news is not repeated until every else news is used
  Global LastUniqueID:Int = 0 {saveload="special"}
  Global List:TList = CreateList()								'holding only first chain of news (start)
  Global NewsList:TList = CreateList()  {saveload="special"}	'holding all news


	Function Load:TNews(pnode:txmlNode, isEpisode:Int = 0, origowner:Int = 0)
Print "implement load:TNews"
Return Null
Rem
		Local News:TNews = New TNews
		Local ParentNewsID:Int = -1
		News.episodeList = CreateList() ' TObjectList.Create(100)

		Local NODE:xmlNode = pnode.FirstChild()
		While NODE <> Null
			Local nodevalue:String = ""
			If node.HasAttribute("var", False) Then nodevalue = node.Attribute("var").value
			Local typ:TTypeId = TTypeId.ForObject(News)
			For Local t:TField = EachIn typ.EnumFields()
				If (t.MetaData("saveload") <> "nosave" And t.MetaData("saveload") <> "special") And Upper(t.name()) = NODE.name
					t.Set(News, nodevalue)
				EndIf
			Next
			Select NODE.name
				Case "LASTUNIQUEID"	TNews.LastUniqueID = Int(node.Attribute("var").Value)
				Case "PARENTNEWSID"	ParentNewsID = Int(node.Attribute("var").Value)
				Case "EPISODE"		News.EpisodeList.AddLast(TNews.Load(NODE, 1))
			End Select
			NODE = NODE.nextSibling()
		Wend
	  	If ParentNewsID >= 0 Then news.parent = TNews.GetNews(parentNewsID)
   	    TNews.NewsList.AddLast(news)
		If Not IsEpisode Then TNews.List.AddLast(news)
		Return news
endrem
	End Function

	Function LoadAll()
Print "implement TNews.LoadAll()"
Return
Rem
		PrintDebug("TNews.LoadAll()", "Lade News", DEBUG_SAVELOAD)
		TNews.List.Clear()
	    TNews.NewsList.Clear()
		Local Children:TList = LoadSaveFile.NODE.ChildList
		For Local node:xmlNode = EachIn Children
			If NODE.name = "ALLNEWS"
			      TNews.Load(NODE)
			End If
		Next
endrem
	End Function

	Function SaveAll()
		Local i:Int = 0
		LoadSaveFile.xmlBeginNode("ALLNEWS")
			LoadSaveFile.xmlWrite("LASTUNIQUEID",	TNews.LastUniqueID)
			For i = 0 To TNews.List.Count()-1
				Local news:TNews = TNews(TNews.List.ValueAtIndex(i))
				If news <> Null Then news.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save(isEpisode:Int=0)
	    If Not isepisode Then LoadSaveFile.xmlBeginNode("NEWS")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") <> "special" Or t.MetaData("saveload") = "normal"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Not isepisode
				For Local j:Int = 0 To Self.episodeList.Count()-1
					LoadSaveFile.xmlBeginNode("EPISODE")
						TNews(Self.episodeList.ValueAtIndex(j)).Save(True)
					LoadSaveFile.xmlCloseNode()
				Next
			EndIf
		If Not isepisode Then LoadSaveFile.xmlCloseNode()
	End Method


	Function CountGenre:Int(Genre:Int, Liste:TList)
		Local genrecount:Int=0
		For Local news:TNews= EachIn Liste
			If news.Genre = Genre genrecount:+1
		Next
		Return genrecount
	End Function

	Function GetRandomNews:TNews()
		Local news:TNews = Null
		Local allsent:Int = 0
		Repeat news = TNews(List.ValueAtIndex((randRange(0, List.Count() - 1))))
			allsent:+1
		Until news.used = 0 Or allsent > 250
		If allsent > 250
			For Local i:Int = 0 To List.Count()-1
				news = TNews(List.ValueAtIndex(i))
				If news <> Null Then news.used = 0
			Next
			Print "NEWS: allsent > 250... reset"
			news = TNews(List.ValueAtIndex((randRange(0, List.Count() - 1))))
		EndIf
		news.happenedday = game.day
		news.happenedhour = game.GetHour()
		news.happenedminute = game.GetMinute()
		news.used = 1
		Print "get random news: "+news.title
		Return news
	End Function

	Function GetGenre:String(Genre:Int)
		If Genre = 0 Then Return GetLocale("NEWS_POLITICS_ECONOMY")
		If Genre = 1 Then Return GetLocale("NEWS_SHOWBIZ")
		If Genre = 2 Then Return GetLocale("NEWS_SPORT")
		If Genre = 3 Then Return GetLocale("NEWS_TECHNICS_MEDIA")
		If Genre = 4 Then Return GetLocale("NEWS_CURRENTAFFAIRS")
		Return Genre+ " unbekannt"
	End Function

	Method ComputeTopicality:Float()
		Return Max(0, Int(255-10*((Game.day*10000+game.GetHour()*100+game.GetMinute()) - (happenedday*10000+happenedhour*100+happenedminute))/100) )'simplest form ;D
	End Method

	'computes a percentage which could be multiplied with maxaudience
	Method ComputeAudienceQuote:Float(lastquote:Float=0)
		Local quote:Float =0.0
		If lastquote < 0 Then lastquote = 0
			quote = 0.1*lastquote + 0.35*((quality+5)/255) + 0.5*ComputeTopicality()/255 + 0.05*(randMax(254)+1)/255
		Return quote * Game.maxAudiencePercentage
	End Method

	Method ComputePrice:Int()
		Return Floor(Float(quality * price / 100 * 2 / 5)) * 100 + 1000  'Teuerstes in etwa 10000+1000
	End Method

	Function Create:TNews(title:String, description:String, Genre:Int, episode:Int=0, quality:Int=0, price:Int=0, id:Int=0)
		Local LocObject:TNews =New TNews
		LocObject.BaseInit(title, description, TYPE_NEWS)
		LocObject.title       = title
		LocObject.description = description
		LocObject.Genre       = Genre
		LocObject.episode     = episode
		Locobject.quality     = quality
		Locobject.price       = RandRange(80,100)

		LocObject.episodeList = CreateList()
		List.AddLast(LocObject)
		NewsList.AddLast(LocObject)
		Return LocObject
	End Function

	Method AddEpisode:TNews(title:String, description:String, Genre:Int, episode:Int=0,quality:Int=0, price:Int=0, id:Int=0)
		Local obj:TNews =New TNews
		obj.BaseInit(title, description, TYPE_NEWS)
		obj.Genre       = Genre
		obj.quality     = quality
		obj.price       = price

		Self.episodecount :+ 1
	    obj.episode     = episode
		obj.parent		= Self

		Self.episodeList.AddLast(obj)
		SortList(Self.episodeList)
		NewsList.AddLast(obj)
		Return obj
	End Method

	'returns Parent (first) of a random NewsChain	(genre -1 is random)
	'Important: only unused (happenedday = -1 or older than X days)
	Function GetRandomChainParent:TNews(Genre:Int=-1)
		Local allsent:Int =0
		Local news:TNews=Null
		Repeat news = TNews(List.ValueAtIndex(randRange(0, List.Count() - 1)))
			allsent:+1
		Until news.used = 0 Or allsent > 250
		If allsent > 250 Then news = TNews(List.ValueAtIndex(randRange(0, List.Count() - 1)))

		news.happenedday = game.day
		news.happenedhour = game.GetHour()
		news.happenedminute = game.GetMinute()
		news.used = 1
		Return news
	EndFunction

  'returns the next news out of a chain, params are the currentnews
  'Important: only unused (happenedday = -1 or older than X days)
  Function GetNextInNewsChain:TNews(currentNews:TNews, isParent:Int=0)
    Local news:TNews=Null
    If currentNews <> Null
      If Not isParent Then news = TNews(currentNews.parent.episodeList.ValueAtIndex(currentnews.episode -1))
      If     isParent Then news = TNews(currentNews.episodeList.ValueAtIndex(0))
      news.happenedday		= game.day
      news.happenedhour		= game.GetHour()
      news.happenedminute	= game.GetMinute()
      news.used				= 1
      Return news
    EndIf
  EndFunction

 Function GetNews:TNews(number:Int)
   Local news:TNews = Null
   For Local i:Int = 0 To TNews.List.Count()-1
     news = TNews(TNews.List.ValueAtIndex(i))
'     news = TNews(TNews.List.Items[ i ])
	 If news <> Null
  	   If news.id = number
         news.happenedday = Game.day
  	     news.happenedhour = Game.GetHour()
  	     news.happenedminute = Game.GetMinute()
	     Return news
	   EndIf
	 EndIf
   Next
   Return Null
 End Function
End Type

Type TDatabase
	Field file:String
	Field moviescount:Int
	Field totalmoviescount:Int
	Field seriescount:Int
	Field newscount:Int
	Field totalnewscount:Int
	Field contractscount:Int

	Function Create:TDatabase()
		Local Database:TDatabase=New TDatabase
		Database.file				= ""
		Database.moviescount   		= 0
		Database.totalmoviescount	= 0
		Database.seriescount		= 0
		Database.newscount			= 0
		Database.contractscount		= 0
		Return Database
	End Function


	Method Load(filename:String)
		Local title:String
		Local description:String
		Local actors:String
		Local director:String
		Local land:String
		Local year:Int
		Local Genre:Int
		Local duration:Int
		Local fsk18:Int
		Local price:Int
		Local review:Int
		Local speed:Int
		Local Outcome:Int
		Local livehour:Int

		Local daystofinish:Int
		Local spotcount:Int
		Local targetgroup:Int
		Local minimage:Int
		Local minaudience:Int
		Local fixedPrice:Int
		Local profit:Int
		Local penalty:Int

		Local quality:Int


		Local xml:TXmlHelper = TXmlHelper.Create(filename)
		Local nodeParent:TxmlNode
		Local nodeChild:TxmlNode
		Local nodeEpisode:TxmlNode
		Local listChildren:TList
		Local loadError:String = ""



		'---------------------------------------------
		'importing all movies
		'Print "reading movies from database"
		nodeParent		= xml.FindRootChild("allmovies")
		loadError		= "Problems loading movies. Check database.xml"
		If nodeParent <> Null
			listChildren = nodeParent.getChildren()
			If listChildren = Null Then Throw loadError

			For nodeChild = EachIn listChildren
				If nodeChild.getName() = "movie"
					title       = xml.FindValue(nodeChild,"title", "unknown title")
					description = xml.FindValue(nodeChild,"description", "23")
					actors      = xml.FindValue(nodeChild,"actors", "")
					director    = xml.FindValue(nodeChild,"director", "")
					land        = xml.FindValue(nodeChild,"country", "UNK")
					year 		= xml.FindValueInt(nodeChild,"year", 1900)
					Genre 		= xml.FindValueInt(nodeChild,"genre", 0 )
					duration    = xml.FindValueInt(nodeChild,"blocks", 2)
					fsk18 		= xml.FindValueInt(nodeChild,"xrated", 0)
					price 		= xml.FindValueInt(nodeChild,"price", 0)
					review 		= xml.FindValueInt(nodeChild,"critics", 0)
					speed 		= xml.FindValueInt(nodeChild,"speed", 0)
					Outcome 	= xml.FindValueInt(nodeChild,"outcome", 0)
					livehour 	= xml.FindValueInt(nodeChild,"time", 0)
					If duration < 0 Or duration > 12 Then duration =1
					TProgramme.Create(title,description,actors, director,land, year, livehour, Outcome, review, speed, price, Genre, duration, fsk18, -1)
					'print "film: "+title+ " " + Database.totalmoviescount
					Database.totalmoviescount :+ 1
				EndIf
			Next
		Else
			Throw loadError
		EndIf

		'---------------------------------------------
		'importing all series including their episodes
		nodeParent		= xml.FindRootChild("allseries")
		'Print "reading series from database"
		loadError		= "Problems loading series. Check database.xml"
		If nodeParent = Null Then Throw loadError
		listChildren = nodeParent.getChildren()
		If listChildren = Null Then Throw loadError
		For nodeChild = EachIn listChildren
			If nodeChild.getName() = "serie"
				'load series main data
				title       = xml.FindValue(nodeChild,"title", "unknown title")
				description = xml.FindValue(nodeChild,"description", "")
				actors      = xml.FindValue(nodeChild,"actors", "")
				director    = xml.FindValue(nodeChild,"director", "")
				land        = xml.FindValue(nodeChild,"country", "UNK")
				year 		= xml.FindValueInt(nodeChild,"year", 1900)
				Genre 		= xml.FindValueInt(nodeChild,"genre", 0)
				duration    = xml.FindValueInt(nodeChild,"blocks", 2)
				fsk18 		= xml.FindValueInt(nodeChild,"xrated", 0)
				price 		= xml.FindValueInt(nodeChild,"price", -1)
				review 		= xml.FindValueInt(nodeChild,"critics", -1)
				speed 		= xml.FindValueInt(nodeChild,"speed", -1)
				Outcome 	= xml.FindValueInt(nodeChild,"outcome", -1)
				livehour 	= xml.FindValueInt(nodeChild,"time", -1)
				If duration < 0 Or duration > 12 Then duration =1
				Local parent:TProgramme = TProgramme.Create(title,description,actors, director,land, year, livehour, Outcome, review, speed, price, Genre, duration, fsk18, 0)
				Database.seriescount :+ 1

				'load episodes
				Local EpisodeNum:Int = 0
				Local listEpisodes:TList = nodeChild.getChildren()
				If listEpisodes <> Null And listEpisodes.count() > 0
					For nodeEpisode = EachIn listEpisodes
						If nodeEpisode.getName() = "episode"
							EpisodeNum	= xml.FindValueInt(nodeEpisode,"number", EpisodeNum+1)
							title      	= xml.FindValue(nodeEpisode,"title", "")
							description = xml.FindValue(nodeEpisode,"description", description)
							actors      = xml.FindValue(nodeEpisode,"actors", "")
							director    = xml.FindValue(nodeEpisode,"director", "")
							land        = xml.FindValue(nodeEpisode,"country", "")
							year 		= xml.FindValueInt(nodeEpisode,"year", -1)
							Genre 		= xml.FindValueInt(nodeEpisode,"genre", -1)
							duration    = xml.FindValueInt(nodeEpisode,"blocks", -1)
							fsk18 		= xml.FindValueInt(nodeEpisode,"xrated", fsk18)
							price 		= xml.FindValueInt(nodeEpisode,"price", -1)
							review 		= xml.FindValueInt(nodeEpisode,"critics", -1)
							speed 		= xml.FindValueInt(nodeEpisode,"speed", -1)
							Outcome 	= xml.FindValueInt(nodeEpisode,"outcome", -1)
							livehour	= xml.FindValueInt(nodeEpisode,"time", -1)
							'add episode to last added serie
							'print "serie: --- episode:"+duration + " " + title
							parent.AddEpisode(title,description,actors, director,land, year, livehour, Outcome, review, speed, price, Genre, duration, fsk18, EpisodeNum)
						EndIf
					Next
				EndIf
			EndIf
		Next

		'---------------------------------------------
		'importing all ads
		nodeParent		= xml.FindRootChild("allads")
		'Print "reading ads from database"
		loadError		= "Problems loading ads. Check database.xml"
		If nodeParent = Null Then Throw loadError

		listChildren = nodeParent.getChildren()
		If listChildren = Null Then Throw loadError
		For nodeChild = EachIn listChildren
			If nodeChild.getName() = "ad"
				title       = xml.FindValue(nodeChild,"title", "unknown title")
				description = xml.FindValue(nodeChild,"description", "")
				targetgroup = xml.FindValueInt(nodeChild,"targetgroup", 0)
				spotcount	= xml.FindValueInt(nodeChild,"repetitions", 1)
				minaudience	= xml.FindValueInt(nodeChild,"minaudience", 0)
				minimage	= xml.FindValueInt(nodeChild,"minimage", 0)
				fixedPrice	= xml.FindValueInt(nodeChild,"fixedprice", 0)
				profit	    = xml.FindValueInt(nodeChild,"profit", 0)
				penalty		= xml.FindValueInt(nodeChild,"penalty", 0)
				daystofinish= xml.FindValueInt(nodeChild,"duration", 1)

				TContract.Create(title, description, daystofinish, spotcount, targetgroup, minaudience, minimage, fixedPrice, profit, penalty, Database.contractscount, 0)
				'print "contract: "+title+ " " + Database.contractscount
				Database.contractscount :+ 1
			EndIf
		Next


		'---------------------------------------------
		'importing all news including their chains
		nodeParent		= xml.FindRootChild("allnews")
		'Print "reading news from database"
		loadError		= "Problems loading news. Check database.xml"
		If nodeParent = Null Then Throw loadError
		listChildren = nodeParent.getChildren()
		If listChildren = Null Then Throw loadError
		For nodeChild = EachIn listChildren
			If nodeChild.getName() = "news"
				'load series main data
				title       = xml.FindValue(nodeChild,"title", "unknown newstitle")
				description	= xml.FindValue(nodeChild,"description", "")
				genre		= xml.FindValueInt(nodeChild,"genre", 0)
				quality		= xml.FindValueInt(nodeChild,"topicality", 0)
				price		= xml.FindValueInt(nodeChild,"price", 0)
				Local parentNews:TNews = TNews.Create(title, description, Genre, Database.totalnewscount,quality, price, 0)

				'load episodes
				Local EpisodeNum:Int = 0
				Local listEpisodes:TList = nodeChild.getChildren()
				If listEpisodes <> Null And listEpisodes.count() > 0
					For nodeEpisode = EachIn listEpisodes
						If nodeEpisode.getName() = "episode"
							EpisodeNum		= xml.FindValueInt(nodeEpisode,"number", EpisodeNum+1)
							title			= xml.FindValue(nodeEpisode,"title", "unknown Newstitle")
							description		= xml.FindValue(nodeEpisode,"description", "")
							genre			= xml.FindValueInt(nodeEpisode,"genre", genre)
							quality			= xml.FindValueInt(nodeEpisode,"topicality", quality)
							price			= xml.FindValueInt(nodeEpisode,"price", price)
							parentNews.AddEpisode(title,description, Genre, EpisodeNum,quality, price, Database.totalnewscount)
							Database.totalnewscount :+1
						EndIf
					Next
					Database.newscount :+ 1
					Database.totalnewscount :+1
				EndIf
			EndIf
		Next

		Print("found " + Database.seriescount+ " series, "+Database.totalmoviescount+ " movies, "+ Database.contractscount + " advertisements, " + Database.totalnewscount + " news")
	End Method
End Type





Type TAdBlock Extends TBlockGraphical
	Field State:Int 				= 0			{saveload = "normal"}
    Field timeset:Int 				=-1			{saveload = "normal"}
    Field Height:Int							{saveload = "normal"}
    Field width:Int								{saveload = "normal"}
    Field blocks:Int				= 1			{saveload = "normal"}
    Field senddate:Int				=-1			{saveload = "normal"} 			 'which day this ad is planned to be send?
    Field sendtime:Int				=-1			{saveload = "normal"}			 'which time this ad is planned to be send?
    Field contract:TContract
    Field id:Int					= 0			{saveload = "normal"}
	Field Link:TLink
    Global LastUniqueID:Int			= 0
    Global DragAndDropList:TList
    Global List:TList = CreateList()

    Global spriteBaseName:String = "pp_adblock1"

  Function LoadAll(loadfile:TStream)
    TAdBlock.List.Clear()
	Print "cleared adblocklist:"+TAdBlock.List.Count()
    Local BeginPos:Int = Stream_SeekString("<ADB/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</ADB>",loadfile)  -6
    Local strlen:Int = 0
    loadfile.Seek(BeginPos)

	TAdBlock.lastUniqueID:Int        = ReadInt(loadfile)
    TAdBlock.AdditionallyDragged:Int = ReadInt(loadfile)
	Repeat
      Local AdBlock:TAdBlock= New TAdBlock
	  AdBlock.state    = ReadInt(loadfile)
	  AdBlock.dragable = ReadInt(loadfile)
	  AdBlock.dragged = ReadInt(loadfile)
	  AdBlock.StartPos.Load(Null)
	  AdBlock.timeset   = ReadInt(loadfile)
	  AdBlock.height   = ReadInt(loadfile)
	  AdBlock.width   = ReadInt(loadfile)
	  AdBlock.blocks   = ReadInt(loadfile)
	  AdBlock.senddate = ReadInt(loadfile)
	  AdBlock.sendtime = ReadInt(loadfile)
	  AdBlock.owner    = ReadInt(loadfile)
	  Local ContractID:Int = ReadInt(loadfile)
      If ContractID >= 0
	    Local contract:TContract = New TContract
		contract = TContract.Load(Null) 'loadfile)
        AdBlock.contract = New TContract
 	    AdBlock.contract = Players[AdBlock.owner].ProgrammePlan.CloneContract(contract)
 	    AdBlock.contract.owner = AdBlock.owner
        AdBlock.contract.senddate = contract.senddate
        AdBlock.contract.sendtime = contract.sendtime
 	    AdBlock.contract.spotnumber = Adblock.GetPreviousContractCount()
	  EndIf
		AdBlock.Pos.Load(Null)
	  AdBlock.id = ReadInt(loadfile)
	  AdBlock.Link = TAdBlock.List.AddLast(AdBlock)
	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	  Players[AdBlock.owner].ProgrammePlan.AddContract(AdBlock.contract)
	Until loadfile.Pos() >= EndPos
	Print "loaded adblocklist"
  End Function

	Function SaveAll()
		LoadSaveFile.xmlBeginNode("ALLADBLOCKS")
			LoadSaveFile.xmlWrite("LASTUNIQUEID", 			TAdBlock.LastUniqueID)
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED", 	TAdBlock.AdditionallyDragged)
			For Local AdBlock:TAdBlock= EachIn TAdBlock.List
				If AdBlock <> Null Then AdBlock.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("ADBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.contract <> Null
				LoadSaveFile.xmlWrite("CONTRACTID", 	Self.contract.id)
				Self.contract.Save()
			Else
				LoadSaveFile.xmlWrite("CONTRACTID", 	"-1")
			EndIf
		LoadSavefile.xmlCloseNode()
	End Method

	Function Create:TAdBlock(x:Int = 0, y:Int = 0, owner:Int = 0, contractpos:Int = -1)
		Local AdBlock:TAdBlock=New TAdBlock
		AdBlock.Pos 		= TPosition.Create(x, y)
		AdBlock.StartPos	= TPosition.Create(x, y)
		Adblock.owner = owner
		AdBlock.blocks = 1
		AdBlock.State = 0
		Adblock.id = TAdBlock.LastUniqueID
		TAdBlock.LastUniqueID :+1

		'hier noch als variablen uebernehmen
		AdBlock.dragable = 1
		AdBlock.width = Assets.GetSprite("pp_adblock1").w
		AdBlock.Height = Assets.GetSprite("pp_adblock1").h
		AdBlock.senddate = Game.day
		AdBlock.sendtime = AdBlock.GetTimeOfBlock()

		Local _contract:TContract
		If contractpos <= -1
			_contract = Players[owner].ProgrammeCollection.GetRandomContract()
		Else
			SortList(Players[owner].ProgrammeCollection.ContractList)
			_contract = TContract(Players[owner].ProgrammeCollection.ContractList.ValueAtIndex(contractPos-1))
		EndIf
		AdBlock.contract			= Players[owner].ProgrammePlan.CloneContract(_contract)
		AdBlock.contract.owner		= owner
		AdBlock.contract.spotnumber	= Players[owner].ProgrammePlan.GetPreviousContractCount(AdBlock.contract)
		AdBlock.contract.senddate	= Game.day
		AdBlock.contract.sendtime	= Int(Floor((Adblock.StartPos.y - 17) / 30))

		Adblock.Link = List.AddLast(AdBlock)
		TAdBlock.list.sort(True, TAdblock.sort)

		Players[owner].ProgrammePlan.AddContract(AdBlock.contract)
		Return AdBlock
	End Function

	Function CreateDragged:TAdBlock(contract:TContract, owner:Int=-1)
	  Local playerID:Int =0
	  If owner < 0 Then playerID = game.playerID Else playerID = owner
	  Local AdBlock:TAdBlock=New TAdBlock
 	  AdBlock.Pos 			= TPosition.Create(MouseX(), MouseY())
 	  AdBlock.StartPos		= TPosition.Create(0, 0)
 	  AdBlock.owner 		= playerID
 	  AdBlock.State 		= 0
 	  Adblock.id			= TAdBlock.LastUniqueID
 	  TAdBlock.LastUniqueID :+1
 	  AdBlock.dragable 		= 1
 	  AdBlock.width 		= Assets.GetSprite("pp_adblock1").w
 	  AdBlock.Height		= Assets.GetSprite("pp_adblock1").h
 	  AdBlock.senddate 		= Game.daytoplan
      AdBlock.sendtime 		= 100

 	  AdBlock.contract				= Players[playerID].ProgrammePlan.CloneContract(contract)
 	  AdBlock.contract.owner		= playerID
 	  AdBlock.contract.spotnumber 	= Adblock.GetPreviousContractCount()
  	  Adblock.dragged 				= 1
	  Adblock.Link 					= List.AddLast(AdBlock)
		TAdBlock.list.sort(True, TAdblock.sort)
 	  Return Adblock
	End Function

	Function GetActualAdBlock:TAdBlock(playerID:Int = -1, time:Int = -1, day:Int = -1)
		If playerID = -1 Then playerID = Game.playerID
		If time = -1 Then time = Game.GetHour()
		If day = -1 Then day = Game.day

		For Local Obj:TAdBlock = EachIn TAdBlock.list
			If Obj.owner = playerID
				If (Obj.sendtime) = time And Obj.senddate = day Then Return Obj
			EndIf
  		Next
		Return Null
  	End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method

	Function Sort:Int(o1:Object, o2:Object)
		Local s1:TAdBlock = TAdBlock(o1)
		Local s2:TAdBlock = TAdBlock(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (10000*s1.dragged + (s1.sendtime + 25*s1.senddate))-(10000*s2.dragged + (s2.sendtime + 25*s2.senddate))
	End Function

	Method GetBlockX:Int(time:Int)
		If time < 12 Then Return 67 + Assets.GetSprite("pp_programmeblock1").w
		Return 394 + Assets.GetSprite("pp_programmeblock1").w
	End Method

	Method GetBlockY:Int(time:Int)
		If time < 12 Then Return time * 30 + 17
		Return (time - 12) * 30 + 17
	End Method

    Method GetTimeOfBlock:Int(_x:Int = 1000, _y:Int = 1000)
		If StartPos.x = 589
    	  Return 12+(Int(Floor(StartPos.y - 17) / 30))
		Else If StartPos.x = 262
    	  Return 1*(Int(Floor(StartPos.y - 17) / 30))
    	EndIf
    	Return -1
    End Method

    'draw the Adblock inclusive text
    'zeichnet den Programmblock inklusive Text
    Method Draw()
		'Draw dragged Adblockgraphic
		If dragged = 1 Or senddate = Game.daytoplan 'out of gameplanner
			State = 1
			If Game.day > Game.daytoplan Then State = 4
			If Game.day < Game.daytoplan Then State = 0
			If Game.day = Game.daytoplan
				If GetTimeOfBlock() > (Int(Floor((Game.minutesOfDayGone-55) / 60))) Then State = 0  'normal
				If GetTimeOfBlock() = (Int(Floor((Game.minutesOfDayGone-55) / 60))) Then State = 2  'running
				If GetTimeOfBlock() < (Int(Floor((Game.minutesOfDayGone) / 60)))    Then State = 1  'runned
				If GetTimeOfBlock() < 0      									    Then State = 0  'normal
			EndIf

			If State = 0 Then SetColor 255,255,255;dragable=1  'normal
			If State = 1 Then SetColor 200,255,200;dragable=0  'runned
			If State = 2 Then SetColor 250,230,120;dragable=0  'running
			If State = 4 Then SetColor 255,255,255;dragable=0  'old day

			Local variant:String = ""
			If dragged = 1 And State = 0
				If TAdBlock.AdditionallyDragged >0 Then SetAlpha 1- (1/TAdBlock.AdditionallyDragged * 0.25)
				variant = "_dragged"
			EndIf
			Assets.GetSprite("pp_adblock1"+variant).Draw(Pos.x, Pos.y)

			'draw graphic

			SetColor 0,0,0
			Assets.fonts.basefontBold.DrawBlock(Self.contract.title, pos.x + 3, pos.y+2, Self.width-5, 18, 0, 0, 0, 0, True)
			SetColor 80,80,80
			Local text:String = (contract.spotnumber)+"/"+contract.spotcount
			If State = 1 And contract.spotnumber = contract.spotcount
				text = "- OK -"
			ElseIf contract.botched=1
				text = "------"
			EndIf
			Assets.fonts.baseFont.Draw(text ,Pos.x+5,Pos.y+18)
			SetColor 255,255,255 'eigentlich alte Farbe wiederherstellen
			SetAlpha 1.0
		EndIf 'same day or dragged
    End Method

	Function DrawAll(origowner:Int)
		TAdBlock.list.sort(True, TAdblock.sort)
      For Local AdBlock:TAdBlock = EachIn TAdBlock.List
        If origowner = Adblock.owner ' or Adblock.owner = Game.playerID
     	  AdBlock.Draw()
        EndIf
      Next
	End Function

	Function UpdateAll(origowner:Int)
      Local gfxListenabled:Byte = 0
      Local havetosort:Byte = 0
      Local number:Int = 0
      If PPprogrammeList.enabled <> 0 Or PPcontractList.enabled <> 0 Then gfxListenabled = 1

		TAdBlock.list.sort(True, TAdblock.sort)
      For Local AdBlock:TAdBlock = EachIn TAdBlock.List
      If Adblock.owner = Game.playerID And origowner = game.playerID
        number :+ 1
        If AdBlock.dragged = 1 Then AdBlock.timeset = -1; AdBlock.contract.senddate = Game.daytoplan
        If PPprogrammeList.enabled=0 And MOUSEMANAGER.IsHit(2) And AdBlock.dragged = 1
'          Game.IsMouseRightHit = 0
          ReverseList TAdBlock.List
          Adblock.RemoveBlock()
          Adblock.Link.Remove()
		  havetosort = 1
          ReverseList TAdBlock.List
          AdBlock.GetPreviousContractCount()
          MOUSEMANAGER.resetKey(2)
        EndIf
		If Adblock.dragged And Adblock.StartPos.x>0 And Adblock.StartPos.y >0
		 If Adblock.GetTimeOfBlock() < game.GetHour() Or (Adblock.GetTimeOfBlock() = game.GetHour() And game.GetMinute() >= 55)
			Adblock.dragged = False
 		 EndIf
		EndIf

        If gfxListenabled=0 And MOUSEMANAGER.IsHit(1)
	    	If AdBlock.dragged = 0 And AdBlock.dragable = 1 And Adblock.State = 0
    	        If Adblock.senddate = game.daytoplan
					If functions.IsIn(MouseX(), MouseY(), AdBlock.pos.x, Adblock.pos.y, AdBlock.width, AdBlock.height-1)
						AdBlock.dragged = 1
						For Local OtherlocObject:TAdBlock = EachIn TAdBlock.List
							If OtherLocObject.dragged And OtherLocObject <> Adblock And OtherLocObject.owner = Game.playerID
								TPosition.SwitchPos(AdBlock.StartPos, OtherlocObject.StartPos)
  								OtherLocObject.dragged = 1
								If OtherLocObject.GetTimeOfBlock() < game.GetHour() And game.GetMinute() >= 55
									OtherLocObject.dragged = 0
								EndIf
							End If
						Next
						Adblock.RemoveBlock() 'just removes the contract from the plan, the adblock still exists
						AdBlock.GetPreviousContractCount()
					EndIf
				EndIf
			Else
            Local DoNotDrag:Int = 0
            If PPprogrammeList.enabled=0 And MOUSEMANAGER.IsHit(1)  And Adblock.State = 0
'			  Print ("X:"+Adblock.x+ " Y:"+Adblock.y+" time:"+Adblock.GetTimeOfBlock(Adblock.x,Adblock.y))' > game.GetHour())
              AdBlock.dragged = 0
              For Local DragAndDrop:TDragAndDrop = EachIn TAdBlock.DragAndDropList
                If DragAndDrop.CanDrop(MouseX(),MouseY(),"adblock")
                  For Local OtherAdBlock:TAdBlock = EachIn TAdBlock.List
                   If OtherAdBlock.owner = Game.playerID Then
                   'is there a Adblock positioned at the desired place?
                      If MOUSEMANAGER.IsHit(1) And OtherAdBlock.dragable = 1 And OtherAdBlock.pos.x = DragAndDrop.pos.x
                        If OtherAdblock.senddate = game.daytoplan
                         If OtherAdBlock.pos.y = DragAndDrop.pos.y
                           If OtherAdBlock.State = 0
                             OtherAdBlock.dragged = 1
           	    	         otherAdblock.RemoveBlock()
          					 havetosort = 1
                           Else
                             DoNotDrag = 1
                           EndIf
             	         EndIf
             	        EndIf
                      EndIf
                    If havetosort
       				  OtherAdBlock.GetPreviousContractCount()
  	          		  AdBlock.GetPreviousContractCount()
                      Exit
                    EndIf
                   EndIf
                  Next
                  If DoNotDrag <> 1
						Local oldPos:TPosition = TPosition.CreateFromPos(AdBlock.StartPos)
               		 AdBlock.startPos.SetPos(DragAndDrop.pos)
					 If Adblock.GetTimeOfBlock() < Game.GetHour() Or (Adblock.GetTimeOfBlock() = Game.GetHour() And Game.GetMinute() >= 55)
						adblock.dragged = True
						If AdBlock.startPos.isSame(oldPos) Then Adblock.dragged = False
						AdBlock.StartPos.setPos(oldPos)
						MOUSEMANAGER.resetKey(1)
					 Else
						AdBlock.StartPos.setPos(oldPos)
						Adblock.Pos.SetPos(DragAndDrop.pos)
						AdBlock.StartPos.SetPos(AdBlock.pos)
                     EndIf
					Exit 'exit loop-each-dragndrop, we've already found the right position
				  EndIf
                EndIf
              Next
				If AdBlock.IsAtStartPos()
					AdBlock.Pos.SetPos(AdBlock.StartPos)
	      		    AdBlock.dragged    			= 0
    	            AdBlock.contract.sendtime	= Adblock.GetTimeOfBlock()
        	        AdBlock.contract.senddate	= Game.daytoplan
            	    AdBlock.sendtime			= Adblock.GetTimeOfBlock()
                	AdBlock.senddate			= Game.daytoplan
	   	            Adblock.AddBlock()
					TAdBlock.list.sort(True, TAdblock.sort)
    		        AdBlock.GetPreviousContractCount()
				EndIf
            EndIf
          EndIf
         EndIf

        If AdBlock.dragged = 1
  		  	Adblock.State = 0
			TAdBlock.AdditionallyDragged = TAdBlock.AdditionallyDragged +1
			AdBlock.Pos.SetXY(MouseX() - AdBlock.width  /2 - TAdBlock.AdditionallyDragged *5,..
							  MouseY() - AdBlock.height /2 - TAdBlock.AdditionallyDragged *5)
        EndIf
        If AdBlock.dragged = 0
          If Adblock.StartPos.x = 0 And Adblock.StartPos.y = 0
          	AdBlock.dragged = 1
          	TAdBlock.AdditionallyDragged = TAdBlock.AdditionallyDragged +1
          Else
				AdBlock.Pos.SetPos(AdBlock.StartPos)
          EndIf
        EndIf
      EndIf
      Next
        TAdBlock.AdditionallyDragged = 0
    End Function

  Method RemoveOverheadAdblocks:Int()
    sendtime = GetTimeOfBlock()
  	Local count:Int = 1
  	If Not List Then List = CreateList()
  	For Local AdBlock:TAdBlock= EachIn List
  	  If Adblock.owner = contract.owner And Adblock.contract.title = contract.title And adblock.contract.botched <> 1
  	    AdBlock.contract.spotnumber = count
  	    If count > contract.spotcount And Game.day <= Adblock.senddate
  	      'DebugLog "removing overheadadblock"
  	      'TAdBlock.List.Remove(Adblock)
		  Adblock.Link.Remove()
  	    Else
  	      count :+ 1
  	    EndIf
  	  EndIf
  	Next
  '	contract.spotnumber = count-1
  	Return count
  End Method

  'removes Adblocks which are supposed to be deleted for its contract being obsolete (expired)
  Function RemoveAdblocks:Int(Contract:TContract, BeginDay:Int=0)
  	If Not List Then List = CreateList()
  	For Local AdBlock:TAdBlock= EachIn List
  	  If Adblock.owner = contract.owner And Adblock.contract.title = contract.title And..
	     (adblock.contract.daysigned + adblock.contract.daystofinish < BeginDay)
        'TAdBlock.List.Remove(Adblock)
		Adblock.Link.Remove()
  	  EndIf
  	Next
  End Function

	Method ShowSheet:Int(x:Int,y:Int)
		Self.contract.showSheet(x,y,-1, GetSuccessfulSentContractCount())
	End Method

   Method GetPreviousContractCount:Int()
    sendtime = GetTimeOfBlock()
  	Local count:Int = 1
  	If Not List Then List = CreateList()
  	For Local AdBlock:TAdBlock= EachIn List
  	  If Adblock.owner = contract.owner And Adblock.contract.title = contract.title And adblock.contract.botched <> 1
  	    AdBlock.contract.spotnumber = count
  	    count :+ 1
  	  '  If count > contract.spotcount and Game.day > Game.daytoplan Then count = 1
  	  EndIf
  	Next
  '	contract.spotnumber = count-1
  	Return count
  End Method

   Method GetSuccessfulSentContractCount:Int()
    sendtime = GetTimeOfBlock()
  	Local count:Int = 0
  	If Not List Then List = CreateList()
  	For Local AdBlock:TAdBlock= EachIn List
  	  If Adblock.owner = contract.owner And Adblock.contract.title = contract.title And adblock.contract.botched = 3
  	    count :+ 1
  	  EndIf
  	Next
  	Return count
  End Method
    'remove from programmeplan
    Method RemoveBlock()
   	  Players[Game.playerID].ProgrammePlan.RemoveContract(Self.contract)
      If game.networkgame Then NetworkHelper.SendPlanAdChange(game.playerID, Self, 0)
    End Method

    Method AddBlock()
      'Print "LOCAL: added adblock:"+Self.contract.title
'      Players[game.playerID].ProgrammePlan.RefreshProgrammePlan(game.playerID, Self.Programme.senddate)
      Players[Game.playerID].ProgrammePlan.AddContract(Self.contract)
      If game.networkgame Then NetworkHelper.SendPlanAdChange(game.playerID, Self, 1)
    End Method

    Function GetBlockByContract:TAdBlock(contract:TContract)
	 For Local _AdBlock:TAdBlock = EachIn TAdBlock.List
		If contract.daysigned = _Adblock.contract.daysigned..
		   And contract.title = _Adblock.contract.title..
		   And contract.owner = _Adblock.contract.owner
		  Return _Adblock
		EndIf
	 Next
    End Function

	Function GetBlock:TAdBlock(id:Int)
	 For Local _AdBlock:TAdBlock = EachIn TAdBlock.List
	 	If _Adblock.ID = id Then Return _Adblock
	 Next
		Return Null
	End Function
End Type

Type TProgrammeBlock Extends TBlockGraphical
    Field id:Int		= -1 {saveload = "normal"}
	Field State:Int		= 0 {saveload = "normal"}
	Field link:TLink

    Field image:TGW_Sprites
    Field image_dragged:TGW_Sprites
    Field Programme:TProgramme
    Global LastUniqueID:Int =0
    Global DragAndDropList:TList

	Field sendHour:Int = -1					'which hour of the game (24h*day+dayHour) block is planned to be send?


  Function LoadAll(loadfile:TStream)
'    TProgrammeBlock.List.Clear()
    Local BeginPos:Int = Stream_SeekString("<PRB/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</PRB>",loadfile)  -6
    Local strlen:Int = 0
    loadfile.Seek(BeginPos)

	TProgrammeBlock.lastUniqueID:Int        = ReadInt(loadfile)
    TProgrammeBlock.AdditionallyDragged:Int = ReadInt(loadfile)
'	Local FinishString:String = ""
	Repeat
      Local ProgrammeBlock:TProgrammeBlock = New TProgrammeBlock
 	  ProgrammeBlock.image = Assets.GetSprite("pp_programmeblock1")
 	  ProgrammeBlock.image_dragged = Assets.GetSprite("pp_programmeblock1_dragged")
	  ProgrammeBlock.id   = ReadInt(loadfile)
	  ProgrammeBlock.state    = ReadInt(loadfile)
	  ProgrammeBlock.dragable = ReadInt(loadfile)
	  ProgrammeBlock.dragged = ReadInt(loadfile)
	  ProgrammeBlock.StartPos.Load(Null)
	  ProgrammeBlock.height = ReadInt(loadfile)
	  ProgrammeBlock.width = ReadInt(loadfile)
	  ProgrammeBlock.Pos.Load(Null)
	  Local progID:Int = ReadInt(loadfile)
      Local ProgSendHour:Int = ReadInt(loadfile)
	  Local ParentprogID:Int = ReadInt(loadfile)
	  ProgrammeBlock.owner    = ReadInt(loadfile)
      If ProgID >= 0
        ProgrammeBlock.Programme 		  = Tprogramme.GetProgramme(ProgID) 'change owner?
        ProgrammeBlock.sendHour = ProgSendHour
	  EndIf
	  Players[ProgrammeBlock.owner].ProgrammePlan.ProgrammeBlocks.addLast(ProgrammeBlock)
	  ReadString(loadfile, 5)  'finishing string (eg. "|PRB|")
'	  Players[ProgrammeBlock.owner].ProgrammePlan.AddProgramme(ProgrammeBlock.Programme, 1)
	Until loadfile.Pos() >= EndPos 'Or FinishString <> "|PRB|"
	Print "loaded programmeblocklist"
  End Function

	Function SaveAll()
		'foreach player !
		Rem
		LoadSaveFile.xmlBeginNode("ALLPROGRAMMEBLOCKS")
			LoadSaveFile.xmlWrite("LASTUNIQUEID",		TProgrammeBlock.LastUniqueID)
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED",TProgrammeBlock.AdditionallyDragged)
		    For Local ProgrammeBlock:TProgrammeBlock= EachIn TProgrammeBlock.List
				If ProgrammeBlock <> Null Then ProgrammeBlock.Save()
			Next
		LoadSaveFile.xmlCloseNode()
		endrem
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("PROGRAMMEBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.Programme <> Null
				LoadSaveFile.xmlWrite("PROGRAMMEID", Self.Programme.id)
				LoadSavefile.xmlWrite("PROGRAMMESENDHOUR",	Self.sendhour)
			Else
				LoadSavefile.xmlWrite("PROGRAMMEID",		"-1")
				LoadSavefile.xmlWrite("PROGRAMMESENDDATE",	"-1")
				LoadSavefile.xmlWrite("PROGRAMMESENDTIME",	"-1")
			EndIf
	 	LoadSaveFile.xmlCloseNode()
	End Method

	Method SetStartConfig(x:Float, y:Float, owner:Int=0, state:Int=0)
 	  Self.image 		= Assets.GetSprite("pp_programmeblock1")
 	  Self.image_dragged= Assets.GetSprite("pp_programmeblock1_dragged")
	  Self.Pos			= TPosition.Create(x, y)
	  Self.StartPos		= TPosition.Create(x, y)
 	  Self.owner 		= owner
 	  Self.State 		= state
	  Self.id 			= Self.lastUniqueID
	  Self.lastUniqueID:+1
 	  Self.dragable 	= 1
 	  Self.width 		= Self.image.w
 	  Self.Height 		= Self.image.h
	End Method


    'creates a programmeblock which is already dragged (used by movie/series-selection)
    'erstellt einen gedraggten Programmblock (genutzt von der Film- und Serienauswahl)
	Function CreateDragged:TProgrammeBlock(movie:TProgramme, owner:Int =-1)
		If owner < 0 Then owner = game.playerID
		Local obj:TProgrammeBlock=New TProgrammeBlock
		obj.SetStartConfig(MouseX(),MouseY(),owner, 0)
		obj.dragged		= 1
		obj.Programme	= movie
		obj.sendHour	= TPlayerProgrammePlan.getPlanHour(obj.GetHourOfBlock(1, obj.StartPos), Game.daytoplan)
		obj.link		= Players[owner].ProgrammePlan.ProgrammeBlocks.addLast(obj)
		Players[owner].ProgrammePlan.AdditionallyDraggedProgrammeBlocks :+ 1

		Return obj
	End Function

	Function Create:TProgrammeBlock(x:Int=0, y:Int=0, serie:Int=0, owner:Int=0, programmepos:Int=-1)
		Local obj:TProgrammeBlock=New TProgrammeBlock
		obj.SetStartConfig(x,y,owner, randRange(0,3))
		If Programmepos <= -1
			obj.Programme = Players[owner].ProgrammeCollection.GetRandomProgramme(serie)
		Else
			SortList(Players[owner].ProgrammeCollection.MovieList)
			'get programme "pos"
			obj.Programme = TProgramme(Players[owner].ProgrammeCollection.MovieList.ValueAtIndex(programmepos))
		EndIf

		obj.sendHour	= TPlayerProgrammePlan.getPlanHour(obj.GetHourOfBlock(1, obj.StartPos),Game.daytoplan)
		obj.link		= Players[owner].ProgrammePlan.ProgrammeBlocks.addLast(obj)
		'Print "Player "+owner+" -Create block: added:"+obj.Programme.title
		Return obj
	End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method

    Method DraggingAllowed:Int()
    	Return (dragable And Self.GetState() = 0 And owner=Game.playerID)
    End Method

    Method DrawBlockPart(x:Int,y:Int,kind:Int, variant:String="")
    	If kind=1
			Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y, x, y, -1, 30)
    	Else
			Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y - 30, x, y, -1, 15)
    	    If kind=2
				Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y - 30 + 15, x, y + 15, -1, 15)
    	    Else
				Assets.GetSprite("pp_programmeblock2"+variant).DrawClipped(x, y - 30, x, y + 15, -1, -1)
    	    EndIf
	    EndIf
    End Method

	Method GetState:Int()
		State = 1
		If Game.day > Game.daytoplan Then State = 4
		If Game.day < Game.daytoplan Then State = 0
		If Game.day = Game.daytoplan
			'xx:05
			Local moviesStartTime:Int	= Int(Floor((Game.minutesOfDayGone-5) / 60))
			'xx:55
			Local moviesEndTime:Int		= Int(Floor((Game.minutesOfDayGone+5) / 60)) 'with ad
			Local startTime:Int			= Self.GetHourOfBlock(1, Self.StartPos)
			Local endTime:Int			= Self.GetHourOfBlock(Self.programme.blocks, Self.StartPos)
			'running or runned (1 or 2)
			If startTime <= moviesStartTime Then State = 1 + (endTime >= moviesEndTime)
			'not run - normal
			If startTime > moviesStartTime Or Self.sendHour < 0 Then State = 0
		EndIf
		Return State
	End Method

	'draw the programmeblock inclusive text
    'zeichnet den Programmblock inklusive Text
	Method Draw()
		'Draw dragged programmeblockgraphic
		If Self.dragged = 1 Or functions.DoMeet(Self.sendHour, Self.sendHour + Self.programme.blocks, Game.daytoplan*24,Game.daytoplan*24+24)  'out of gameplanner
			GetState()
			If dragged Then state = 0
			If State = 0 Then SetColor 255,255,255;dragable=1  'normal
			If State = 1 Then SetColor 200,255,200;dragable=0  'runned
			If State = 2 Then SetColor 250,230,120;dragable=0  'running
			If State = 4 Then SetColor 255,255,255;dragable=0  'old day

			Local variant:String = ""
			Local drawTitle:Int = 1
			If dragged = 1 And state=0 Then variant = "_dragged"

			If programme.blocks = 1
				Assets.GetSprite("pp_programmeblock1"+variant).Draw(pos.x, pos.y)
			Else
				For Local i:Int = 1 To Self.programme.blocks
					Local _type:Int = 1
					If i > 1 And i < Self.programme.blocks Then _type = 2
					If i = Self.programme.blocks Then _type = 3
					If Self.dragged
						'draw on manual position
						Self.DrawBlockPart(pos.x,pos.y + (i-1)*30,_type)
					Else
						'draw on "planner spot" position
						Local _pos:TPosition = Self.getSlotXY(Self.sendhour+i-1)

						If Self.sendhour+i-1 >= game.daytoplan*24 And Self.sendhour+i-1 < game.daytoplan*24+24
							Self.DrawBlockPart(_pos.x,_pos.y ,_type)
							If i = 1 Then pos = _pos
						Else
							If i=1 Then drawTitle = 0
						EndIf
					EndIf
				Next
			EndIf
			If drawTitle Then Self.DrawBlockText(TColor.Create(50,50,50), Self.pos)
		EndIf 'daytoplan switch
    End Method

    Method DrawBlockText(color:TColor = Null, _pos:TPosition)
		SetColor 0,0,0

		Local maxWidth:Int = Self.image.w - 5
		Local title:String = Self.programme.title
		If Not Self.programme.isMovie()
			title = Self.programme.parent.title + " (" + Self.programme.episodeNumber + "/" + Self.programme.parent.episodeList.count() + ")"
		EndIf

		While Assets.fonts.basefontBold.getWidth(title) > maxWidth And title.length > 4
			title = title[..title.length-3]+".."
		Wend

		Assets.fonts.basefontBold.DrawBlock(title, _pos.x + 5, _pos.y +2, Self.image.w - 10, 18, 0, 0, 0, 0, True)
		If color <> Null Then color.set()
		Local useFont:TBitmapFont = Assets.GetFont("Default", 11, ITALICFONT)
		If programme.parent <> Null
			useFont.Draw(Self.Programme.getGenreString()+"-Serie",_pos.x+5,_pos.y+18)
			useFont.Draw("Teil: " + Self.Programme.episodeNumber + "/" + Self.programme.parent.episodeList.count(), _pos.x + 138, _pos.y + 18)
		Else
			useFont.Draw(Self.Programme.getGenreString(),_pos.x+5,_pos.y+18)
			If Self.programme.fsk18 <> 0 Then useFont.Draw("FSK 18!",_pos.x+138,_pos.y+18)
		EndIf
		SetColor 255,255,255
	End Method

	Method DrawShades()
		'draw a shade of the programmeblock on its original position but not when just created and so dragged from its creation on
		 If (Self.StartPos.x = 394 Or Self.StartPos.x = 67) And (Abs(Self.pos.x - Self.StartPos.x) > 0 Or Abs(Self.pos.y - Self.StartPos.y) >0)
			SetAlpha 0.4
			If Self.programme.blocks = 1
				Self.image.Draw(Self.StartPos.x, Self.StartPos.y)
			Else
				For Local i:Int = 1 To Self.programme.blocks
					Local _pos:TPosition = Self.getBlockSlotXY(i, Self.startPos)
					Local _type:Int = 1
					If i > 1 And i < Self.programme.blocks Then _type = 2
					If i = Self.programme.blocks Then _type = 3
					Self.DrawBlockPart(_pos.x,_pos.y,_type)
				Next
			EndIf
			Self.DrawBlockText( TColor.Create(80,80,80), Self.startPos )

			SetAlpha 1.0
		EndIf
	End Method

    Method DeleteBlock()
		Print "deleteBlock: programme:"+Self.Programme.title
		'remove self from block list
		Players[Game.playerID].ProgrammePlan.ProgrammeBlocks.remove(Self)
'		self.remove()
'		Players[Game.playerID].ProgrammePlan.RemoveProgramme(Self.Programme)
    End Method

	'give total hour - returns x of planner-slot
	Method GetSlotX:Int(time:Int)
		Return GetSlotXY(time).x
	End Method

	'give total hour - returns y of planner-slot
	Method GetSlotY:Int(time:Int)
		Return GetSlotXY(time).y
	End Method

	'give total hour - returns position of planner-slot
	Method GetSlotXY:TPosition(totalHours:Int)
		totalHours = totalHours Mod 24
		Local top:Int = 17
		If Floor(totalHours/12) Mod 2 = 1 '(12-23, + next day 12-23 and so on)
			Return TPosition.Create(394, top + (totalHours - 12)*30)
		Else
			Return TPosition.Create(67, top + totalHours*30)
		EndIf
	End Method

	'returns the slot coordinates of a position on the plan
	'returns for current day not total (eg. 0-23)
	Method GetBlockSlotXY:TPosition(blockNumber:Int, _pos:TPosition = Null)
		Return Self.GetSlotXY( Self.GetHourOfBlock(blockNumber, _pos) )
	End Method

	'returns the hour of a position on the plan
	'returns for current day not total (eg. 0-23)
	Method GetHourOfBlock:Int(blockNumber:Int, _pos:TPosition= Null)
		If _pos = Null Then _pos = Self.pos
		'0-11 links, 12-23 rechts
		Local top:Int = 17
		Return (_pos.y - top) / 30 + 12*(_pos.x = 394)   +  (blockNumber-1)
	End Method

    'remove from programmeplan
    Method Drag()
		If Self.dragged <> 1
			Self.dragged	= 1
			Self.sendHour	= -1

			'emit event ?
			If game.networkgame Then NetworkHelper.SendPlanProgrammeChange(game.playerID, Self, 0)
		EndIf
    End Method

	'add to plan again
    Method Drop()
		If Self.dragged <> 0
			Self.dragged = 0
			Pos.SetPos(StartPos)
			Self.sendHour = TPlayerProgrammePlan.getPlanHour(Self.getHourOfBlock(1, Self.pos), game.daytoplan)

			'emit event ?
			If game.networkgame Then NetworkHelper.SendPlanProgrammeChange(game.playerID, Self, 1)
		EndIf
    End Method
End Type

Type TNewsBlock Extends TBlockGraphical
	Field State:Int 		= 0 	{saveload = "normal"}
    Field sendslot:Int 		= -1 	{saveload = "normal"} 'which day this news is planned to be send?
    Field publishdelay:Int 	= 0		{saveload = "normal"} 'value added to publishtime when compared with Game.minutesOfDayGone to delay the "usabilty" of the block
    Field publishtime:Int 	= 0		{saveload = "normal"} '
    Field paid:Byte 		= 0 	{saveload = "normal"}
    Field news:TNews
	Field id:Int	 		= 0 	{saveload = "normal"}
    Global LastUniqueID:Int 		= 0
    Global DragAndDropList:TList

    Global LeftListPosition:Int		= 0
    Global LeftListPositionMax:Int	= 4


	Function LoadAll(loadfile:TStream)
'		TNewsBlock.List.Clear()
		'Print "cleared newsblocklist:"+TNewsBlock.List.Count()
		Local BeginPos:Int = Stream_SeekString("<NEWSB/>",loadfile)+1
		Local EndPos:Int = Stream_SeekString("</NEWSB>",loadfile)  -8
		Local strlen:Int = 0
		loadfile.Seek(BeginPos)

		TNewsBlock.lastUniqueID:Int        = ReadInt(loadfile)
		TNewsBlock.AdditionallyDragged:Int = ReadInt(loadfile)
		TNewsBlock.LeftListPosition:Int    = ReadInt(loadfile)
		TNewsBlock.LeftListPositionMax:Int = ReadInt(loadfile)
		Local NewsBlockCount:Int = ReadInt(loadfile)
		If NewsBlockCount > 0
			Repeat
				Local NewsBlock:TNewsBlock= New TNewsBlock
				NewsBlock.State      	= ReadInt(loadfile)
				NewsBlock.dragable   	= ReadByte(loadfile)
				NewsBlock.dragged    	= ReadByte(loadfile)
				NewsBlock.StartPos.Load(Null)
				NewsBlock.sendslot   	= ReadInt(loadfile)
				NewsBlock.publishdelay= ReadInt(loadfile)
				NewsBlock.publishtime	= ReadInt(loadfile)
				NewsBlock.paid 		= ReadByte(loadfile)
				NewsBlock.Pos.Load(Null)
				NewsBlock.owner		= ReadInt(loadfile)
				NewsBlock.id	= ReadInt(loadfile)
				Local NewsID:Int		= ReadInt(loadfile)
				If newsID >= 0 Then Newsblock.news = TNews.Load(Null) 'loadfile)

				NewsBlock.imageBaseName = "gfx_news_sheet"
				NewsBlock.width 		= Assets.GetSprite("gfx_news_sheet0").w
				NewsBlock.Height		= Assets.GetSprite("gfx_news_sheet0").h

				'TNewsBlock.List.AddLast(NewsBlock)
				ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
				Players[NewsBlock.owner].ProgrammePlan.AddNewsBlock(NewsBlock)
				Print "added '" + NewsBlock.news.title + "' to programmeplan for:"+newsBlock.owner
			Until loadfile.Pos() >= EndPos
		EndIf
		Print "loaded newsblocklist"
	End Function

	Function SaveAll()
		LoadSaveFile.xmlBeginNode("ALLNEWSBLOCKS")
			LoadSaveFile.xmlWrite("LASTUNIQUEID",		TNewsBlock.LastUniqueID)
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED",TNewsBlock.AdditionallyDragged)
			LoadSaveFile.xmlWrite("LEFTLISTPOSITION",	TNewsBlock.LeftListPosition)
			LoadSaveFile.xmlWrite("LEFTLISTPOSITIONMAX",TNewsBlock.LeftListPositionMax)
			'SaveFile.WriteInt(TNewsBlock.List.Count())
			For Local i:Int = 1 To 4
				For Local NewsBlock:TNewsBlock= EachIn Players[i].ProgrammePlan.NewsBlocks
					If NewsBlock <> Null Then NewsBlock.Save()
				Next
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("NEWSBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.news <> Null
				LoadSaveFile.xmlWrite("NEWSID",		Self.news.id)
				Self.news.Save()
			Else
				LoadSaveFile.xmlWrite("NEWSID",		"-1")
			EndIf
		LoadSaveFile.xmlCloseNode()
	End Method

	Function Create:TNewsBlock(text:String="unknown", x:Int=0, y:Int=0, owner:Int=1, publishdelay:Int=0, usenews:TNews=Null)
	  Local LocObject:TNewsBlock=New TNewsBlock
	  LocObject.Pos		= TPosition.Create(x, y)
	  LocObject.StartPos= TPosition.Create(x, y)
 	  LocObject.owner = owner
 	  LocObject.State = 0
 	  locobject.publishdelay = publishdelay
 	  locobject.publishtime = Game.timeSinceBegin
 	  'hier noch als variablen uebernehmen
 	  LocObject.dragable = 1
 	  LocObject.sendslot = -1
 	  locObject.id = TNewsBlock.LastUniqueID
 	  TNewsBlock.LastUniqueID :+1

	  If usenews = Null Then usenews = TNews.GetRandomNews()

 	  LocObject.news = usenews

		Locobject.imageBaseName = "gfx_news_sheet"
		Locobject.imageBaseName = "gfx_news_sheet" '_dragged
		LocObject.width 		= Assets.GetSprite(Locobject.imageBaseName+"0").w
		LocObject.Height		= Assets.GetSprite(Locobject.imageBaseName+"0").h

		Players[owner].ProgrammePlan.AddNewsBlock(LocObject)
		Return LocObject
	End Function

    Method Pay()
        Players[owner].finances[Game.getWeekday()].PayNews(news.ComputePrice())
    End Method

	Function IncLeftListPosition:Int(amount:Int=1)
      If TNewsBlock.LeftListPositionMax-TNewsBlock.LeftListPosition > 4 Then TNewsBlock.LeftListPosition:+amount
	End Function

	Function DecLeftListPosition:Int(amount:Int=1)
		TNewsBlock.LeftListPosition = Max(0, TNewsBlock.LeftListPosition -amount)
	End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method


    Function Sort:Int(o1:Object, o2:Object)
		Local n1:TNewsBlock = TNewsBlock(o1)
		Local n2:TNewsBlock = TNewsBlock(o2)
		If Not n2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
		Return (Not n2.dragged) * (n2.news.happenedday*10000+n2.news.happenedhour*100+n2.news.happenedminute) - (Not n1.dragged) * (n1.news.happenedday*10000+n1.news.happenedhour*100+n1.news.happenedminute)
    End Function

    Method GetSlotOfBlock:Int()
    	If pos.x = 445 And dragged = 0 Then Return Int((StartPos.y - 19) / 87)
    	Return -1
    End Method

    'draw the Block inclusive text
	Method Draw()
		State = 0
		SetColor 255,255,255
		dragable=1
		Local variant:String = ""
		If dragged = 1 And State = 0
			If Self.AdditionallyDragged > 0 Then SetAlpha 1- 1/Self.AdditionallyDragged * 0.25
			'variant = "_dragged"
		EndIf
		Assets.GetSprite(Self.imageBaseName+news.genre+variant).Draw(Pos.x, Pos.y)


		'draw graphic
		If paid Then Assets.GetFont("Default", 9).drawBlock(CURRENCYSIGN+" OK", pos.x + 1, pos.y + 65, 14, 25, 1, 50, 50, 50)
		Assets.fonts.basefontBold.drawBlock(news.title, pos.x + 15, pos.y + 3, 290, 15 + 8, 0, 20, 20, 20)
		Assets.fonts.baseFont.drawBlock(news.description, pos.x + 15, pos.y + 18, 300, 45 + 8, 0, 100, 100, 100)
		SetAlpha 0.3
		Assets.GetFont("Default", 9).drawBlock(news.GetGenre(news.Genre), pos.x + 15, pos.y + 72, 120, 15, 0, 0, 0, 0)
		SetAlpha 1.0
		Assets.GetFont("Default", 12).drawBlock(news.ComputePrice() + ",-", pos.x + 220, pos.y + 70, 90, 15, 2, 0, 0, 0)
		If Game.day - news.happenedday = 0 Then Assets.fonts.baseFont.drawBlock("Heute " + Game.GetFormattedExternTime(news.happenedhour, news.happenedminute) + " Uhr", pos.x + 90, pos.y + 72, 140, 15, 2, 0, 0, 0)
		If Game.day - news.happenedday = 1 Then Assets.fonts.baseFont.drawBlock("(Alt) Gestern " + Game.GetFormattedExternTime(news.happenedhour, news.happenedminute) + " Uhr", pos.x + 90, pos.y + 72, 140, 15, 2, 0, 0, 0)
		If Game.day - news.happenedday = 2 Then Assets.fonts.baseFont.drawBlock("(Alt) Vorgestern " + Game.GetFormattedExternTime(news.happenedhour, news.happenedminute) + " Uhr", pos.x + 90, pos.y + 72, 140, 15, 2, 0, 0, 0)
		SetColor 255, 255, 255
		SetAlpha 1.0
	End Method

End Type

'Contracts used in AdAgency
Type TContractBlock Extends TBlockGraphical
	Field contract:TContract
	Field slot:Int = 0			{saveload = "normal"}	'slot at the moment
	Field origSlot:Int = 0		{saveload = "normal"}	'slot on table
	Global DragAndDropList:TList = CreateList()
	Global List:TList = CreateList()
	Global AdditionallyDragged:Int =0

  Function LoadAll(loadfile:TStream)
    TContractBlock.List.Clear()
	Print "cleared contractblocklist:"+TContractBlock.List.Count()
    Local BeginPos:Int = Stream_SeekString("<CONTRACTB/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</CONTRACTB>",loadfile)  -12
    'Local strlen:Int = 0
    loadfile.Seek(BeginPos)
    TContractBlock.AdditionallyDragged:Int = ReadInt(loadfile)
	Local ContractBlockCount:Int = ReadInt(loadfile)
	If ContractBlockCount > 0
	Repeat
      Local ContractBlock:TContractBlock= New TContractBlock
	  ContractBlock.Pos.Load(Null)
	  ContractBlock.OrigPos.Load(Null)
	  Local ContractID:Int  = ReadInt(loadfile)
	  If ContractID >= 0
	    ContractBlock.contract = TContract.GetContract(ContractID)
		Local targetgroup:Int = ContractBlock.contract.targetgroup
		If targetgroup > 9 Or targetgroup <0 Then targetgroup = 0
		ContractBlock.imageBaseName	= "gfx_contracts_"+targetgroup
 	  	ContractBlock.width		= Assets.getSprite(ContractBlock.imageBaseName).w
 	  	ContractBlock.Height	= Assets.getSprite(ContractBlock.imageBaseName).h
	  EndIf
	  ContractBlock.dragable= ReadInt(loadfile)
	  ContractBlock.dragged = ReadInt(loadfile)
	  ContractBlock.slot	= ReadInt(loadfile)
		ContractBlock.StartPos.Load(Null)
	  ContractBlock.owner   = ReadInt(loadfile)
	  TContractBlock.List.AddLast(ContractBlock)
	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	Until loadfile.Pos() >= EndPos
	EndIf
	Print "loaded contractblocklist"
  End Function

	Function SaveAll()
		Local ContractCount:Int = 0
		LoadSaveFile.xmlBeginNode("ALLCONTRACTBLOCKS")
			LoadSaveFile.xmlWRITE("ADDITIONALLYDRAGGED"		, TContractBlock.AdditionallyDragged)
			For Local ContractBlock:TContractBlock= EachIn TContractBlock.List
				If ContractBlock <> Null Then If ContractBlock.owner <= 0 Then ContractCount:+1
		    Next
			LoadSaveFile.xmlWRITE("CONTRACTCOUNT"				, ContractCount)
			For Local ContractBlock:TContractBlock= EachIn TContractBlock.List
				If ContractBlock <> Null Then ContractBlock.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("CONTRACTBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt" Or t.MetaData("saveload") = "normalExtB"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.contract <> Null
				LoadSaveFile.xmlWrite("CONTRACTID",		Self.contract.id)
			Else
				LoadSaveFile.xmlWrite("CONTRACTID",		"-1")
			EndIf
		LoadSaveFile.xmlCloseNode()
	End Method

	Function ContractsToPlayer:Int(playerID:Int)
		TContractBlock.list.sort(True, TBlock.SortDragged)

		For Local locObject:TContractBlock = EachIn TContractBlock.List
			If locobject.pos.x > 520 And locobject.owner <= 0
				locobject.SignContract(playerID)
			EndIf
		Next
	End Function

	Function RemoveContractFromSuitcase(contract:TContract)
		If contract <> Null
			For Local ContractBlock:TContractBlock =EachIn TContractBlock.List
				If ContractBlock.contract.id = contract.id Then TContractBlock.list.remove(ContractBlock);Exit
			Next
		EndIf
	End Function

	Method SignContract:Int(playerID:Int)
		'locobject.owner = playerID
		If game.networkgame
			Local ContractArray:TContract[1]
			ContractArray[0] = Self.contract
			If network.IsConnected Then NetworkHelper.SendContractsToPlayer(game.playerID, ContractArray)
			ContractArray = Null
		EndIf
		Players[playerID].ProgrammeCollection.AddContract(Self.contract, playerID)

		Self.slot	= Self.origSlot	'revert to original slot

		Local x:Int = 285 + Self.slot * Assets.getSprite(Self.imageBaseName).w
		Local y:Int = 300 - 10 - Assets.getSprite(Self.imageBaseName).h - Self.slot * 7
		Self.Pos.SetXY(x, y)
		Self.OrigPos.SetXY(x, y)
		Self.StartPos.SetXY(x, y)
		Self.dragable = 1
		Self.contract = TContract.GetRandomContractWithMaxAudience(Game.getMaxAudience(-1), -1, 0.30)

		If Self.contract <> Null
			Local targetgroup:Int = Self.contract.targetgroup
			If targetgroup > 9 Or targetgroup <0 Then targetgroup = 0
			Self.imageBaseName = "gfx_contracts_"+targetgroup
		EndIf
		Self.owner = 0
		Return True
	End Method


	'if owner = 0 then its a block of the adagency, otherwise it's one of the player'
	Function Create:TContractBlock(contract:TContract, slot:Int=0, owner:Int=0)
		Local LocObject:TContractBlock=New TContractBlock
		Local targetgroup:Int = contract.targetgroup
		If targetgroup > 9 Or targetgroup <0 Then targetgroup = 0
		locObject.imageBaseName	= "gfx_contracts_"+targetgroup
 	  	locObject.width			= Assets.getSprite(locObject.imageBaseName).w
 	  	locObject.Height		= Assets.getSprite(locObject.imageBaseName).h

		Local x:Int = 285 + slot * LocObject.width
		Local y:Int = 300 - 10 - LocObject.height - slot * 7
		LocObject.Pos			= TPosition.Create(x, y)
		LocObject.OrigPos		= TPosition.Create(x, y)
		LocObject.StartPos		= TPosition.Create(x, y)
		LocObject.slot 			= slot
		LocObject.origSlot		= slot
		locObject.owner 		= owner
		LocObject.dragable 		= 1
		LocObject.contract 		= contract
		List.AddLast(LocObject)
		TContractBlock.list.sort(True, TBlock.SortDragged)

		If owner = 0
			Local DragAndDrop:TDragAndDrop = New TDragAndDrop
			DragAndDrop.slot 	= slot + 200
			DragAndDrop.pos.SetXY(x,y)
			DragAndDrop.w 		= LocObject.width
			DragAndDrop.h 		= LocObject.height
			TContractBlock.DragAndDropList.AddLast(DragAndDrop)
		Else
			LocObject.dragable = 0
		EndIf
		Return LocObject
	End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method

    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()
		SetColor 255,255,255  'normal

		If dragged = 1
			If TContractBlock.AdditionallyDragged > 0 Then SetAlpha 1- 1/TContractBlock.AdditionallyDragged * 0.25
			Assets.GetSprite(Self.imageBaseName+"_dragged").Draw(Pos.x + 6, Pos.y)
		Else
			If Pos.x > 520
				If dragable = 0 Then SetColor 200,200,200
				Assets.GetSprite(Self.imageBaseName+"_dragged").Draw(Pos.x, Pos.y)
				If dragable = 0 Then SetColor 255,255,255
			Else
				Assets.GetSprite(Self.imageBaseName).Draw(Pos.x, Pos.y)
			EndIf
		EndIf
		SetAlpha 1
	End Method

	Function DrawAll(DraggingAllowed:Int)
		TContractBlock.list.sort(True, TBlock.SortDragged)
		For Local locObject:TContractBlock = EachIn TContractBlock.List
			If locObject.contract <> Null And (locobject.owner <= 0 Or locobject.owner = Game.playerID)
				locObject.Draw()
			EndIf
		Next
	End Function

    Function UpdateAll(DraggingAllowed:Byte)
		Local localslot:Int = 0 'slot in suitcase

		TContractBlock.list.sort(True, TBlock.SortDragged)

		For Local locObject:TContractBlock = EachIn TContractBlock.List
			If locobject.owner = Game.playerID Or locobject.startPos.x > 550
				locobject.Pos.SetXY(550 + Assets.GetSprite(locobject.imageBaseName).w*localslot, 87)
				locobject.StartPos.SetPos(locobject.Pos)
				If locobject.owner = game.playerID Then locobject.dragable = 0
				locobject.slot = localslot
				localslot:+1
			EndIf
			If DraggingAllowed And locobject.owner <= 0
				If MOUSEMANAGER.IsHit(2) And locObject.dragged = 1
					Print "right"
					locObject.Pos.SetPos(locObject.StartPos)
					locobject.dragged = 0
					MOUSEMANAGER.resetKey(2)
				EndIf
				If MOUSEMANAGER.IsHit(1)
					'drag
					If locObject.dragged = 0 And locObject.dragable = 1
						If functions.MouseIn(locObject.Pos.x, locObject.Pos.y, locObject.width-1, locObject.height)
							locObject.dragged = 1
							For Local OtherlocObject:TContractBlock = EachIn TContractBlock.List
								If OtherLocObject.dragged And OtherLocObject <> locObject
									TPosition.SwitchPos(locObject.StartPos, OtherLocObject.StartPos)
									OtherLocObject.dragged = 0
								EndIf
							Next
							MouseManager.resetKey(1)
						EndIf
					'drop
					Else
						Local realDNDfound:Int = 0
						locObject.dragged = 0

						For Local DragAndDrop:TDragAndDrop = EachIn TContractBlock.DragAndDropList
							If DragAndDrop.CanDrop(MouseX(), MouseY()) = 1 And (DragAndDrop.pos.x < 550 Or DragAndDrop.pos.x > 550 + Assets.GetSprite(locobject.imageBaseName).w * (localslot - 1))
								'limit contracts in suitcase
								If localslot >= Game.maxContractsAllowed Then Exit

								For Local OtherlocObject:TContractBlock= EachIn TContractBlock.List
									If DraggingAllowed And otherlocobject.owner <= 0
										If MOUSEMANAGER.IsHit(1) And OtherlocObject.dragable = 1 And OtherlocObject.pos.isSame(DragAndDrop.pos)
											OtherlocObject.dragged = 1
											MouseManager.resetKey(1)
											Exit
										EndIf
									EndIf
								Next
								LocObject.Pos.SetPos(DragAndDrop.pos)
								LocObject.StartPos.SetPos(LocObject.Pos)
								realDNDfound =1
								Exit 'exit loop-each-dragndrop, we've already found the right position
							EndIf
						Next

						'no drop-area under Adblock (otherwise this part is not executed - "exit"), so reset position
						If LocObject.IsAtStartPos()
							locObject.dragged = 0
							LocObject.Pos.SetPos(LocObject.StartPos)
							TContractBlock.list.sort(True, TBlock.SortDragged)
						EndIf
					EndIf
				EndIf
				If locObject.dragged = 1
					TContractBlock.AdditionallyDragged :+1
					LocObject.Pos.SetXY(MouseX() - locObject.width /2 -  TContractBlock.AdditionallyDragged *5,..
										MouseY() - locObject.height /2 - TContractBlock.AdditionallyDragged *5)
				Else
					LocObject.Pos.SetPos(LocObject.StartPos)
				EndIf
			EndIf
		Next
        TContractBlock.AdditionallyDragged = 0
	End Function
End Type


Type TSuitcaseProgrammeBlocks Extends TBlockGraphical
	Field Programme:TProgramme
	Field id:Int = 0
	Global LastID:Int = 0

	Method GetNewID()
		Self.id = Self.LastID
		Self.LastID:+1
	EndMethod

    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw(additionalDragged:Int = 0)
      SetColor 255,255,255  'normal

      If dragged = 1
    	If additionalDragged > 0 Then SetAlpha 1- 1/additionalDragged * 0.25
       	If Programme.Genre < 9
			Assets.GetSprite("gfx_movie"+Programme.Genre).Draw(Pos.x+7, Pos.y)
     	Else
			Assets.GetSprite("gfx_movie0").Draw(Pos.x+7, Pos.y)
     	EndIf
      Else
        If Pos.x > 520
            If dragable = 0 Then SetAlpha 0.5;SetColor 200,200,200
        EndIf
       	If Programme.Genre < 9
			Assets.GetSprite("gfx_movie"+Programme.Genre).Draw(Pos.x, Pos.y)
     	Else
			Assets.GetSprite("gfx_movie0").Draw(Pos.x, Pos.y)
     	EndIf
      EndIf
      SetColor 255,255,255
      SetAlpha 1
    End Method

End Type

'Programmeblocks used in MovieAgency
Type TMovieAgencyBlocks Extends TSuitcaseProgrammeBlocks
  Field slot:Int = 0 {saveload = "normal"}
  Field Link:TLink
  Global DragAndDropList:TList = CreateList()
  Global List:TList = CreateList()
  Global AdditionallyDragged:Int =0

  Function LoadAll(loadfile:TStream)
    TMovieAgencyBlocks.List.Clear()
	Print "cleared movieagencyblocks:" + TMovieAgencyBlocks.List.Count()
    Local BeginPos:Int = Stream_SeekString("<MOVIEAGENCYB/>", loadfile) + 1
    Local EndPos:Int = Stream_SeekString("</MOVIEAGENCYB>",loadfile)  -15
    loadfile.Seek(BeginPos)
    TMovieAgencyBlocks.AdditionallyDragged:Int = ReadInt(loadfile)
	Local MovieAgencyBlocksCount:Int = ReadInt(loadfile)
	If MovieAgencyBlocksCount > 0
	Repeat
      Local MovieAgencyBlocks:TMovieAgencyBlocks = New TMovieAgencyBlocks
	  MovieAgencyBlocks.Pos.Load(Null)
	  MovieAgencyBlocks.OrigPos.Load(Null)
	  MovieAgencyBlocks.StartPos.Load(Null)
	  MovieAgencyBlocks.StartPosBackup.Load(Null)
	  Local ProgrammeID:Int  = ReadInt(loadfile)
	  If ProgrammeID >= 0
	    MovieAgencyBlocks.Programme = TProgramme.GetProgramme(ProgrammeID)
 	    MovieAgencyBlocks.width  = Assets.GetSprite("gfx_movie0").w-1
 	    MovieAgencyBlocks.height = Assets.GetSprite("gfx_movie0").h
	  EndIf
	  MovieAgencyBlocks.dragable= ReadInt(loadfile)
	  MovieAgencyBlocks.dragged = ReadInt(loadfile)
	  MovieAgencyBlocks.slot	= ReadInt(loadfile)
	  MovieAgencyBlocks.StartPos.Load(Null)
	  MovieAgencyBlocks.owner   = ReadInt(loadfile)
	  MovieAgencyBlocks.Link = TMovieAgencyBlocks.List.AddLast(MovieAgencyBlocks)

	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	Until loadfile.Pos() >= EndPos
	EndIf
	Print "loaded movieagencyblocks"
  End Function

	Function SaveAll()
		Local MovieAgencyBlocksCount:Int = 0
		LoadSaveFile.xmlBeginNode("ALLMOVIEAGENCYBLOCKS")
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED",	TMovieAgencyBlocks.AdditionallyDragged)
			For Local MovieAgencyBlocks:TMovieAgencyBlocks= EachIn TMovieAgencyBlocks.List
				If MovieAgencyBlocks <> Null Then If MovieAgencyBlocks.owner <= 0 Then MovieAgencyBlocksCount:+1
			Next
			LoadSaveFile.xmlWrite("MOVIEAGENCYBLOCKSCOUNT",	MovieAgencyBlocksCount)
			For Local MovieAgencyBlocks:TMovieAgencyBlocks= EachIn TMovieAgencyBlocks.List
				If MovieAgencyBlocks <> Null Then MovieAgencyBlocks.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("MOVIEAGENCYBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.Programme <> Null
				LoadSaveFile.xmlWrite("PROGRAMMEID", Self.programme.id)
			Else
				LoadSaveFile.xmlWrite("PROGRAMMEID",		"-1")
			EndIf
		LoadSaveFile.xmlCloseNode()
	End Method


	Method SwitchBlock(otherObj:TBlock)
		Super.SwitchBlock(otherObj)
		If game.networkgame Then NetworkHelper.SendMovieAgencyChange(NET_SWITCH, Game.playerID, TMovieAgencyBlocks(otherObj).Programme.id, - 1, Programme)
		'Print "movieagency: switched - other obj found"
	End Method

	'buy means pay and set owner, but in players collection only if left the room!!
	Method Buy:Int(playerID:Int = -1, fromNetwork:Int = False)
		If PlayerID = -1 Then PlayerID = Game.playerID
		If Players[PlayerID].finances[Game.getWeekday()].PayMovie(Programme.getPrice())
			owner = PlayerID
			Programme.owner = PlayerID
			If Not fromNetwork And game.networkgame Then NetworkHelper.SendMovieAgencyChange(NET_BUY, PlayerID, -1, - 1, Programme)
			'reset pos
			Self.Pos.y = 241
			Return 1
		EndIf
		Return 0
	End Method

	Method Sell:int(PlayerID:Int=-1, fromNetwork:Int = False)
		If PlayerID = -1 Then PlayerID = Game.playerID
		if PlayerID <> self.owner then return -1


		Players[PlayerID].finances[Game.getWeekday()].SellMovie(Programme.getPrice())

		Self.StartPos.SetPos(Self.StartPosBackup)
		Self.StartPosBackup.SetY(0)
		If Self.StartPos.y < 240 And Self.StartPos.x > 760 Then Self.SetCoords(Self.StartPos.x,Self.StartPos.y,Self.StartPos.x,Self.StartPos.y)

		If Not fromNetwork And Game.networkgame Then NetworkHelper.SendMovieAgencyChange(NET_SELL, PlayerID, -1, -1, programme) 'remove from collection
		programme.owner = 0
		owner = 0
		'Print "Programme "+Programme.title +" sold"
		return 1
	End Method

  Function RemoveBlockByProgramme(programme:TProgramme, playerID:Int=0)
    If programme <> Null
	  Local movieblockarray:Object[]
	  movieblockarray = TMovieAgencyBlocks.List.ToArray()
	  For Local j:Int = 0 To movieblockarray.Length-1
        If TMovieAgencyBlocks(movieblockarray[j]).Programme <> Null
	      If TMovieAgencyBlocks(movieblockarray[j]).Programme.title = programme.title
  	        movieblockarray[j] = Null
          EndIf
	    EndIf
	  Next
	  TMovieAgencyBlocks.List.Clear()
	  TMovieAgencyBlocks.List = TList.FromArray(movieblockarray)
	EndIf
  End Function

  'refills missing blocks in the movieagency
  'has to be excluded from other functions to make it the way, that a player has to leave the movieagency
  'to get "new" movies to buy
  Function ReFillBlocks:Int()
    Local movierow:Byte[11]
    Local seriesrow:Byte[7]
	For Local locObject:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
      If locobject.Programme <> Null
	    If locobject.Pos.y = 134-70     Then movierow[ Int( (locobject.Pos.x-600)/15 ) ] = 1
        If locobject.Pos.y = 134-70+110 Then seriesrow[ Int( (locobject.Pos.x-600)/15 ) ] = 1
      Else
	    If locobject.Pos.y = 134-70     Then locobject.Programme = TProgramme.GetRandomMovie()
        If locobject.Pos.y = 134-70+110 Then locobject.Programme = TProgramme.GetRandomSerie()
	  EndIf
	Next
	For Local i:Byte = 0 To seriesrow.length-2
	  If seriesrow[i] <> 1 Then  TMovieAgencyBlocks.Create(TProgramme.GetRandomSerie(),i+20, 0)
	Next
	For Local i:Byte = 0 To movierow.length-2
	  If movierow[i] <> 1 Then TMovieAgencyBlocks.Create(TProgramme.GetRandomMovie(),i, 0)
	Next
  End Function

  Function ProgrammeToPlayer:Int(playerID:Int)
		TArchiveProgrammeBlock.ClearSuitcase(playerID)
		TMovieAgencyBlocks.list.sort(True, TBlock.SortDragged)
		For Local locObject:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			If locobject.Pos.y > 240 And locobject.owner = playerID
				Players[playerID].ProgrammeCollection.AddProgramme(locobject.Programme)
				Local x:Int=600+locobject.slot*15
				Local y:Int=134-70

				If locobject.slot >= 20 And locobject.slot <= 30 '2. Reihe: Serien
					x=600+(locobject.slot-20)*15
					y=134-70 + 110
				EndIf
				LocObject.Pos.SetXY(x, y)
				LocObject.OrigPos.SetXY(x, y)
				LocObject.StartPos.SetXY(x, y)
				locobject.owner		= 0
				LocObject.dragable	= 1
				If locobject.Programme.isMovie()
					locobject.Programme = TProgramme.GetRandomMovie(-1)
				Else
					locobject.Programme = TProgramme.GetRandomSerie(-1)
				EndIf
			EndIf
		Next
		TMovieAgencyBlocks.ReFillBlocks()
	End Function

	'if owner = 0 then its a block of the adagency, otherwise it's one of the player'
	Function Create:TMovieAgencyBlocks(Programme:TProgramme, slot:Int=0, owner:Int=0)
		If Programme = Null Then Return Null
		Local LocObject:TMovieAgencyBlocks=New TMovieAgencyBlocks
		Local x:Int=600+slot*15 'ImageWidth(gfx_movie[0])
		Local y:Int=134-70 'ImageHeight(gfx_movie[0])
		If slot >= 20 And slot <= 30 '2. Reihe: Serien
			x=600+(slot-20)*15
			y=134-70 + 110
		EndIf
		If owner > 0 Then y = 260
		LocObject.Pos			=TPosition.Create(x, y)
		LocObject.OrigPos		=TPosition.Create(x, y)
		LocObject.StartPos		=TPosition.Create(x, y)
		LocObject.StartPosBackup=TPosition.Create(x, y)
		LocObject.slot = slot
		locObject.owner = owner
		'hier noch als variablen uebernehmen
		LocObject.dragable = 1
		LocObject.width  = Assets.GetSprite("gfx_movie0").w-1
		LocObject.height = Assets.GetSprite("gfx_movie0").h
		LocObject.Programme = Programme
		If Not List Then List = CreateList()
		LocObject.Link = List.AddLast(LocObject)
		TMovieAgencyBlocks.list.sort(True, TBlock.SortDragged)

		If owner = 0
			Local DragAndDrop:TDragAndDrop = New TDragAndDrop
			DragAndDrop.slot = slot + 200
			DragAndDrop.pos.setXY(x,y)
			DragAndDrop.w = Assets.GetSprite("gfx_movie0").w
			DragAndDrop.h = Assets.GetSprite("gfx_movie0").h
			TMovieAgencyBlocks.DragAndDropList.AddLast(DragAndDrop)
		Else
			LocObject.dragable = 0
		EndIf
		'Print "created movieblock"+locobject.y
		Return LocObject
	End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method

    Method GetSlotOfBlock:Int()
    	If Pos.x = 589
    	  Return 12+(Int(Floor(StartPos.y- 17) / 30))
    	EndIf
    	If Pos.x = 262
    	  Return 1*(Int(Floor(StartPos.y - 17) / 30))
    	EndIf
    	Return -1
    End Method

   Function DrawAll(DraggingAllowed:Byte)
		For Local locObject:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			If locobject.owner <= 0 Or locobject.owner = Game.playerID Then locObject.Draw(TMovieAgencyBlocks.AdditionallyDragged)
		Next
	End Function

	Function UpdateAll(DraggingAllowed:Byte)
		Local localslot:Int = 0 								'slot in suitcase
		Local imgWidth:Int  = Assets.GetSprite("gfx_movie0").w

		TMovieAgencyBlocks.AdditionallyDragged = 0				'reset additional dragged objects
		TMovieAgencyBlocks.list.sort(True, TBlock.SortDragged)

		'search for obj of the player (and set coords from left to right of suitcase)
		For Local locObj:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			If locObj.Programme <> Null
			'	locObj.dragable = True
				'its a programme of the player, so set it to the coords of the suitcase
				If locObj.owner = Game.playerID
					If locObj.StartPosBackup = Null Then Print "StartPosBackup missing";locObj.StartPosBackup = TPosition.Create(0,0)
					If locObj.StartPosBackup.y = 0 Then locObj.StartPosBackup.SetPos(locObj.StartPos)
					locObj.SetCoords(550+imgWidth*localslot, 267, 550+imgWidth*localslot, 267)
					locObj.dragable = True
					localslot:+1
				End If
			EndIf
		Next

		ReverseList TMovieAgencyBlocks.list 					'reorder: first are dragged obj then not dragged

		For Local locObj:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
			If locObj.Programme <> Null
				locObj.dragable = 1
				If locObj.Programme.getPrice() > Players[Game.playerID].finances[0].money And..
				   locObj.owner <> Game.playerID And..
				   locObj.dragged = 0  Then locObj.dragable = 0


				'block is dragable and from movieagency or player
				If DraggingAllowed And locObj.dragable And (locObj.owner <= 0 Or locObj.owner = Game.playerID)
					'if right mbutton clicked and block dragged: reset coord of block
					If MOUSEMANAGER.IsHit(2) And locObj.dragged
						locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y)
						locObj.dragged = False
						MOUSEMANAGER.resetKey(2)
					EndIf

					'if left mbutton clicked: sell, buy, drag, drop, replace with underlaying block...
					If MouseManager.IsHit(1)
						'search for underlaying block (we have a block dragged already)
						If locObj.dragged
							'obj over employee - so buy or sell
							If functions.MouseIn(20,65, 135, 225)
                          		If locObj.StartPos.y <= 240 And locObj.owner <> Game.playerID Then locObj.Buy()
                          		If locObj.StartPos.y >  240 And locObj.owner =  Game.playerID Then locObj.Sell()
								locObj.dragged = False
							EndIf
							'obj over suitcase - so buy ?
							If functions.MouseIn(540,250,190,360)
                          		If locObj.StartPos.y <= 240 And locObj.Pos.y > 240  And locObj.owner <> Game.playerID Then locObj.Buy()
								locObj.dragged = False
							EndIf
							'obj over old position in shelf - so sell ?
							If functions.MouseIn(locobj.StartPosBackup.x,locobj.StartPosBackup.y,locobj.width,locobj.height)
                          		If locObj.StartPos.y >  240 And locObj.owner =  Game.playerID Then locObj.Sell()
								locObj.dragged = False
							EndIf

							'block over rect of programme-shelf
							If functions.IsIn(locObj.Pos.x, locObj.Pos.y, 590,30, 190,280)
								'want to drop in origin-position
								If locObj.ContainingCoord(MouseX(), MouseY())
									locObj.dragged = False
									MouseManager.resetKey(1)
									'Print "movieagency: dropped to original position"
								'not dropping on origin: search for other underlaying obj
								Else
									For Local OtherLocObj:TMovieAgencyBlocks = EachIn TMovieAgencyBlocks.List
										If OtherLocObj <> Null
											If OtherLocObj.ContainingCoord(MouseX(), MouseY()) And OtherLocObj <> locObj And OtherLocObj.dragged = False And OtherLocObj.dragable
												If locObj.Programme.isMovie() = OtherLocObj.Programme.isMovie()
													locObj.SwitchBlock(otherLocObj)
													Exit	'exit enclosing for-loop (stop searching for other underlaying blocks)
												EndIf
												MouseManager.resetKey(1)
											EndIf
										EndIf
									Next
								EndIf	'end: drop in origin or search for other obj underlaying
							EndIf 		'end: block over programme-shelf
						Else			'end: an obj is dragged
							If LocObj.ContainingCoord(MouseX(), MouseY())
								locObj.dragged = 1
								MouseManager.resetKey(1)
							EndIf
						EndIf
					EndIf 				'end: left mbutton clicked
				EndIf					'end: dragable block and player or movieagency is owner
			EndIf 						'end: obj.programme <> NULL

			'if obj dragged then coords to mousecursor+displacement, else to startcoords
			If locObj.dragged = 1
				TMovieAgencyBlocks.AdditionallyDragged :+1
				Local displacement:Int = TMovieAgencyBlocks.AdditionallyDragged *5
				locObj.setCoords(MouseX() - locObj.width/2 - displacement, MouseY() - locObj.height/2 - displacement)
			Else
				locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y)
			EndIf
		Next
		ReverseList TMovieAgencyBlocks.list 'reorder: first are not dragged obj
  End Function
End Type

'Programmeblocks used in Archive
Type TArchiveProgrammeBlock Extends TSuitcaseProgrammeBlocks
  Field slot:Int				= 0 {saveload = "normal"}
  Field alreadyInSuitcase:Byte	= 0
  Field owner:Int				= 0 {saveload = "normal"}

  Global List:TList				= CreateList()
  Global DragAndDropList:TList	= CreateList()
  Global AdditionallyDragged:Int= 0

  Function LoadAll(loadfile:TStream)
 	TArchiveProgrammeBlock.DragAndDropList.Clear()
    Local BeginPos:Int = Stream_SeekString("<ARCHIVEDND/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</ARCHIVEDND>",loadfile)  -13
    loadfile.Seek(BeginPos)
	Local DNDCount:Int = ReadInt(loadfile)
    For Local i:Int = 1 To DNDCount
	  Local DragAndDrop:TDragAndDrop = New TDragAndDrop
      DragAndDrop.slot = ReadInt(loadfile)
      DragAndDrop.pos.SetXY(ReadInt(loadfile), ReadInt(loadfile))
      DragAndDrop.w = ReadInt(loadfile)
      DragAndDrop.h = ReadInt(loadfile)
	  DragAndDrop.typ = ""
	  'Print "loaded DND: used"+DragAndDrop.used+" x"+DragAndDrop.rectx+" y"+DragAndDrop.recty+" w"+DragAndDrop.rectw
	  ReadString(loadfile,5) 'finishing string (eg. "|DND|")
      If Not TArchiveProgrammeBlock.DragAndDropList Then TArchiveProgrammeBlock.DragAndDropList = CreateList()
      TArchiveProgrammeBlock.DragAndDropList.AddLast(DragAndDrop)
    Next
    SortList TArchiveProgrammeBlock.DragAndDropList

    BeginPos:Int = Stream_SeekString("<ARCHIVEB/>",loadfile)+1
    EndPos:Int = Stream_SeekString("</ARCHIVEB>",loadfile)  -11
    loadfile.Seek(BeginPos)
    TArchiveProgrammeBlock.AdditionallyDragged:Int = ReadInt(loadfile)
	Local ArchiveProgrammeBlocksCount:Int = ReadInt(loadfile)
	If ArchiveProgrammeBlocksCount > 0
	Repeat
      Local ArchiveProgrammeBlocks:TArchiveProgrammeBlock = New TArchiveProgrammeBlock
	  ArchiveProgrammeBlocks.id = ReadInt(loadfile)
	  ArchiveProgrammeBlocks.Pos.Load(Null)
	  ArchiveProgrammeBlocks.OrigPos.Load(Null)
	  Local ProgrammeID:Int  = ReadInt(loadfile)
	  If ProgrammeID >= 0
	    ArchiveProgrammeBlocks.Programme = TProgramme.GetProgramme(ProgrammeID)
 	    ArchiveProgrammeBlocks.width  = Assets.GetSprite("gfx_movie0").w-1
 	    ArchiveProgrammeBlocks.height = Assets.GetSprite("gfx_movie0").h
	  EndIf
	  ArchiveProgrammeBlocks.dragable= ReadInt(loadfile)
	  ArchiveProgrammeBlocks.dragged = ReadInt(loadfile)
	  ArchiveProgrammeBlocks.slot	= ReadInt(loadfile)
	  ArchiveProgrammeBlocks.StartPos.Load(Null)
	  ArchiveProgrammeBlocks.owner   = ReadInt(loadfile)

	  TArchiveProgrammeBlock.List.AddLast(ArchiveProgrammeBlocks)

	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	Until loadfile.Pos() >= EndPos
	EndIf
	Print "loaded archiveprogrammeblocks"
  End Function

	Function SaveAll()
		Local ArchiveProgrammeBlocksCount:Int = 0
		LoadSaveFile.xmlBeginNode("ARCHIVEDND")
			'SaveFile.WriteInt(TArchiveProgrammeBlock.DragAndDropList.Count())
			For Local DragAndDrop:TDragAndDrop = EachIn TArchiveProgrammeBlock.DragAndDropList
				LoadSaveFile.xmlBeginNode("DND")
					LoadSaveFile.xmlWrite("SLOT",		DragAndDrop.slot)
					LoadSaveFile.xmlWrite("X",		DragAndDrop.pos.x)
					LoadSaveFile.xmlWrite("Y",		DragAndDrop.pos.y)
					LoadSaveFile.xmlWrite("W",		DragAndDrop.w)
					LoadSaveFile.xmlWrite("H",		DragAndDrop.h)
				LoadSaveFile.xmlCloseNode()
			Next
		LoadSaveFile.xmlCloseNode()
		LoadSaveFile.xmlBeginNode("ALLARCHIVEPROGRAMMEBLOCKS")
			LoadSaveFile.xmlWrite("ADDITIONALLYDRAGGED", 	TArchiveProgrammeBlock.AdditionallyDragged)
			For Local ArchiveProgrammeBlocks:TArchiveProgrammeBlock= EachIn TArchiveProgrammeBlock.List
				If ArchiveProgrammeBlocks <> Null
					'If ArchiveProgrammeBlocks.owner <= 0 Then
					ArchiveProgrammeBlocksCount:+1
				EndIf
			Next
			LoadSaveFile.xmlWrite("ARCHIVEPROGRAMMEBLOCKSCOUNT", 	ArchiveProgrammeBlocksCount)
			For Local ArchiveProgrammeBlocks:TArchiveProgrammeBlock= EachIn TArchiveProgrammeBlock.List
				If ArchiveProgrammeBlocks <> Null Then ArchiveProgrammeBlocks.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
  		LoadSaveFile.xmlBeginNode("ARCHIVEPROGRAMMEBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.Programme <> Null
				LoadSaveFile.xmlWrite("PROGRAMMEID", Self.programme.id)
			Else
				LoadSaveFile.xmlWrite("PROGRAMMEID",	"-1")
			EndIf
		LoadSaveFile.xmlCloseNode()
	End Method

	'deletes Programmes from Plan (every instance) and from the players collection
	Function ProgrammeToSuitcase:Int(playerID:Int)
		Local myslot:Int=0
		For Local locObject:TArchiveProgrammeBlock = EachIn TArchiveProgrammeBlock.List
			If locobject.owner = playerID And Not locobject.alreadyInSuitcase
				TMovieAgencyBlocks.Create(locobject.Programme, myslot, playerID)
				'reset audience "sendeausfall"
				If Players[playerID].ProgrammePlan.GetActualProgramme().id = locobject.Programme.id Then Players[playerID].audience = 0
				'remove programme from plan
				Players[playerID].ProgrammePlan.RemoveProgramme( locobject.Programme )
				'remove programme from players collection
				Players[playerID].ProgrammeCollection.RemoveProgramme( locobject.Programme )

				locobject.alreadyInSuitcase = True
				myslot:+1
			EndIf
		Next
	End Function

	Function ClearSuitcase:Int(playerID:Int)
		For Local block:TArchiveProgrammeBlock=EachIn TArchiveProgrammeBlock.list
			If block.owner = playerID Then TArchiveProgrammeBlock.List.Remove(block)
		Next
	End Function

	'if a archiveprogrammeblock is "deleted", the programme is readded to the players programmecollection
	'afterwards it deletes the archiveprogrammeblock
	Method ReAddProgramme:Int(playerID:Int)
		Players[playerID].ProgrammeCollection.AddProgramme(Self.Programme, 2)
		'remove blocks which may be already created for having left the archive before re-adding it...
		TMovieAgencyBlocks.RemoveBlockByProgramme(Self.Programme, playerID)

		Self.alreadyInSuitcase = False
		List.Remove(Self)
	End Method

	Method RemoveProgramme:Int(programme:TProgramme, owner:Int=0)
		Players[owner].ProgrammeCollection.RemoveProgramme(programme)
	End Method

	'if owner = 0 then its a block of the adagency, otherwise it's one of the player'
	Function Create:TArchiveProgrammeBlock(Programme:TProgramme, slot:Int=0, owner:Int=0)
		If owner < 0 Then owner = game.playerID
		Local obj:TArchiveProgrammeBlock=New TArchiveProgrammeBlock
		Local x:Int=60+slot*15 'ImageWidth(gfx_movie[0])
		Local y:Int=285 'ImageHeight(gfx_movie[0])
		obj.Pos			= TPosition.Create(x, y)
		obj.OrigPos		= TPosition.Create(x, y)
		obj.StartPos	= TPosition.Create(x, y)
		obj.slot		= slot
		obj.owner 		= owner
		obj.dragable	= 1
		obj.width  		= Assets.GetSprite("gfx_movie0").w
		obj.height 		= Assets.GetSprite("gfx_movie0").h
		obj.Programme 	= Programme
		List.AddLast(obj)
		TArchiveProgrammeBlock.list.sort(True, TBlock.SortDragged)
		Return obj
	End Function

	'creates a programmeblock which is already dragged (used by movie/series-selection)
    'erstellt einen gedraggten Programmblock (genutzt von der Film- und Serienauswahl)
	Function CreateDragged:TArchiveProgrammeBlock(programme:TProgramme, owner:Int =-1)
		Local obj:TArchiveProgrammeBlock= TArchiveProgrammeBlock.Create(programme, 0, owner)
		obj.Pos		= TPosition.Create(MouseX(), MouseY())
		obj.StartPos= TPosition.Create(0, 0) 'ProgrammeBlock.x, ProgrammeBlock.y
		'dragged
		obj.dragged	= 1
		TArchiveProgrammeBlock.AdditionallyDragged :+ 1

		Return obj
	End Function

    Method GetSlotOfBlock:Int()
    	If Pos.x = 589 Then Return 12+(Int(Floor(StartPos.y - 17) / 30))
    	If Pos.x = 262 Then Return    (Int(Floor(StartPos.y - 17) / 30))
    	Return -1
    End Method

	Function DrawAll(DraggingAllowed:Byte)
		TArchiveProgrammeBlock.list.sort(True, TBlock.SortDragged)
		For Local locObject:TArchiveProgrammeBlock = EachIn TArchiveProgrammeBlock.List
			If locobject.owner <= 0 Or locobject.owner = Game.playerID
				locObject.Draw(TArchiveProgrammeBlock.additionallyDragged)
			EndIf
		Next
	End Function

    Function UpdateAll(DraggingAllowed:Byte)
		Local number:Int = 0
		Local localslot:Int = 0 'slot in suitcase

		TArchiveProgrammeBlock.list.sort(True, TBlock.SortDragged)
		For Local locObject:TArchiveProgrammeBlock = EachIn TArchiveProgrammeBlock.List
			If DraggingAllowed And locobject.owner <= 0 Or locobject.owner = Game.playerID
				number :+ 1
				If MOUSEMANAGER.IsHit(2) And locObject.dragged = 1
					locObject.ReAddProgramme(game.playerID)
					MOUSEMANAGER.resetKey(2)
					Exit
				EndIf

				If MOUSEMANAGER.IsHit(1)
					If locObject.dragged = 0 And locObject.dragable = 1
						If functions.MouseIn(locObject.Pos.x, locobject.Pos.y, locObject.width, locObject.height)
							locObject.dragged = 1
						EndIf
					ElseIf locobject.dragable = 1
						Local realDNDfound:Int = 0
						If MOUSEMANAGER.IsHit(1)
							locObject.dragged = 0
							realDNDfound = 0
							For Local DragAndDrop:TDragAndDrop = EachIn TArchiveProgrammeBlock.DragAndDropList
								'don't allow dragging of series into the agencies movie-row and wise versa
								If DragAndDrop.CanDrop(MouseX(),MouseY(), "archiveprogrammeblock") = 1 And (DragAndDrop.pos.x < 50+200 Or DragAndDrop.pos.x > 50+Assets.GetSprite("gfx_movie0").w*(localslot-1))
									For Local OtherlocObject:TArchiveProgrammeBlock= EachIn TArchiveProgrammeBlock.List
										If DraggingAllowed And otherlocobject.owner <= 0 'on plan and not in elevator
											'is there a NewsBlock positioned at the desired place?
											If MOUSEMANAGER.IsHit(1) And OtherlocObject.dragable = 1 And OtherlocObject.Pos.isSame(DragAndDrop.pos)
												OtherlocObject.dragged = 1
											EndIf
										EndIf
									Next
									LocObject.Pos.SetPos(DragAndDrop.pos)
									locobject.RemoveProgramme(locobject.Programme, locobject.owner)
									LocObject.StartPos.SetPos(LocObject.Pos)
									realDNDfound =1
									Exit 'exit loop-each-dragndrop, we've already found the right position
								EndIf
							Next
							'suitcase as dndzone
							If Not realDNDfound And functions.IsIn(MouseX(),MouseY(),50-10,280-20,200+2*10,100+2*20)
								For Local DragAndDrop:TDragAndDrop = EachIn TArchiveProgrammeBlock.DragAndDropList
									If functions.IsIn(DragAndDrop.pos.x, DragAndDrop.pos.y, 50,280,200,100)
										If DragAndDrop.pos.x >= 55 + Assets.GetSprite("gfx_contracts_base").w * (localslot)
											LocObject.Pos.SetPos(DragAndDrop.pos)
											LocObject.StartPos.SetPos(LocObject.Pos)
											Exit 'exit loop-each-dragndrop, we've already found the right position
										EndIf
									EndIf
								Next
							EndIf
							'no drop-area under Adblock (otherwise this part is not executed - "exit"), so reset position
							If Abs(locObject.Pos.x - locObject.StartPos.x)<=1 And..
							   Abs(locObject.Pos.y - locObject.StartPos.y)<=1
								locObject.dragged    = 0
								LocObject.Pos.SetPos(LocObject.StartPos)
								TArchiveProgrammeBlock.list.sort(True, TBlock.SortDragged)
							EndIf
						EndIf
					EndIf
				EndIf
				If locObject.dragged = 1
				  TArchiveProgrammeBlock.AdditionallyDragged :+1
				  LocObject.Pos.SetXY(MouseX() - locObject.width /2 - TArchiveProgrammeBlock.AdditionallyDragged *5,..
									  MouseY() - locObject.height /2 - TArchiveProgrammeBlock.AdditionallyDragged *5)
				EndIf
				If locObject.dragged = 0
					If locObject.StartPos.x = 0 And locObject.StartPos.y = 0
						locObject.dragged = 1
						TArchiveProgrammeBlock.AdditionallyDragged:+ 1
					Else
						LocObject.Pos.SetPos(LocObject.StartPos)
					EndIf
				EndIf
			EndIf
			locobject.dragable = 1
		Next
		TArchiveProgrammeBlock.AdditionallyDragged = 0
	End Function
End Type

'Programmeblocks used in Archive
Type TAuctionProgrammeBlocks {_exposeToLua="selected"}
	Field x:Int = 0					{saveload = "normal"}
	Field y:Int = 0					{saveload = "normal"}
	Field imageWithText:TImage = Null
	Field Programme:TProgramme
	Field slot:Int = 0				{saveload = "normal"}
	Field Bid:Int[5]
	Field uniqueID:Int = 0			{saveload = "normal"}
	Field Link:TLink
	Global LastUniqueID:Int =0
	Global List:TList = CreateList()

  Function ProgrammeToPlayer()
    For Local locObject:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
      If locObject.Programme <> Null And locObject.Bid[0] > 0 And locObject.Bid[0] <= 4
	    Players[locobject.Bid[0]].ProgrammeCollection.AddProgramme(locobject.Programme)
		Print "player "+Players[locobject.Bid[0]].name + " won the auction for: "+locobject.Programme.title
		Repeat
		  LocObject.Programme = TProgramme.GetRandomMovieWithMinPrice(250000)
		Until LocObject.Programme <> Null
		locObject.imageWithText = Null
		For Local i:Int = 0 To 4
	 	  LocObject.Bid[i] = 0
		Next
      End If
    Next

  End Function

  Function LoadAll(loadfile:TStream)
    TAuctionProgrammeBlocks.List.Clear()
	Print "cleared auctionblocks:"+TAuctionProgrammeBlocks.List.Count()
    Local BeginPos:Int = Stream_SeekString("<ARCHIVEB/>",loadfile)+1
    Local EndPos:Int = Stream_SeekString("</AUCTIONB>",loadfile)  -11
    loadfile.Seek(BeginPos)
	Local AuctionProgrammeBlocksCount:Int = ReadInt(loadfile)
	If AuctionProgrammeBlocksCount > 0
	Repeat
      Local AuctionProgrammeBlocks:TAuctionProgrammeBlocks = New TAuctionProgrammeBlocks
	  AuctionProgrammeBlocks.uniqueID = ReadInt(loadfile)
	  AuctionProgrammeBlocks.x 	= ReadInt(loadfile)
	  AuctionProgrammeBlocks.y   = ReadInt(loadfile)
	  Local ProgrammeID:Int  = ReadInt(loadfile)
	  If ProgrammeID >= 0
	    AuctionProgrammeBlocks.Programme = TProgramme.GetProgramme(ProgrammeID)
	  EndIf
	  AuctionProgrammeBlocks.slot	= ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[0]	= ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[1] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[2] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[3] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Bid[4] = ReadInt(loadfile)
	  AuctionProgrammeBlocks.Link   = TAuctionProgrammeBlocks.List.AddLast(AuctionProgrammeBlocks)

	  ReadString(loadfile,5) 'finishing string (eg. "|PRB|")
	Until loadfile.Pos() >= EndPos
	EndIf
	Print "loaded auctionprogrammeblocks"
  End Function

	Function SaveAll()
	    Local AuctionProgrammeBlocksCount:Int = 0
		For Local AuctionProgrammeBlocks:TAuctionProgrammeBlocks= EachIn TAuctionProgrammeBlocks.List
			If AuctionProgrammeBlocks <> Null Then AuctionProgrammeBlocksCount:+1
		Next
		LoadSaveFile.xmlBeginNode("ALLAUCTIONPROGRAMMEBLOCKS")
			LoadSaveFile.xmlWrite("AUCTIONPROGRAMMEBLOCKSCOUNT",	AuctionProgrammeBlocksCount)
			For Local AuctionProgrammeBlocks:TAuctionProgrammeBlocks= EachIn TAuctionProgrammeBlocks.List
				If AuctionProgrammeBlocks <> Null Then AuctionProgrammeBlocks.Save()
			Next
		LoadSaveFile.xmlCloseNode()
	End Function

	Method Save()
		LoadSaveFile.xmlBeginNode("CONTRACTBLOCK")
			Local typ:TTypeId = TTypeId.ForObject(Self)
			For Local t:TField = EachIn typ.EnumFields()
				If t.MetaData("saveload") = "normal" Or t.MetaData("saveload") = "normalExt"
					LoadSaveFile.xmlWrite(Upper(t.name()), String(t.Get(Self)))
				EndIf
			Next
			If Self.Programme <> Null
				LoadSaveFile.xmlWrite("PROGRAMMEID",	Self.programme.id)
			Else
				LoadSaveFile.xmlWrite("PROGRAMMEID", "-1")
			EndIf
			LoadSaveFile.xmlWrite("BID0", Self.Bid[0] )
			LoadSaveFile.xmlWrite("BID1", Self.Bid[1] )
			LoadSaveFile.xmlWrite("BID2", Self.Bid[2] )
			LoadSaveFile.xmlWrite("BID3", Self.Bid[3] )
			LoadSaveFile.xmlWrite("BID4", Self.Bid[4] )
		LoadSaveFile.xmlCloseNode()
	End Method

	Function Create:TAuctionProgrammeBlocks(Programme:TProgramme, slot:Int=0)
		Local LocObject:TAuctionProgrammeBlocks=New TAuctionProgrammeBlocks
		LocObject.x			= 140+((slot+1) Mod 2)* 260
		LocObject.y			= 75+ Ceil((slot-1) / 2)*60
		LocObject.Bid[0]	= 0
		LocObject.Bid[1]	= 0
		LocObject.Bid[2]	= 0
		LocObject.Bid[3]	= 0
		LocObject.Bid[4]	= 0
		LocObject.slot		= slot
		LocObject.Programme	= Programme
		List.AddLast(LocObject)
		TAuctionProgrammeBlocks.list.sort(True, TAuctionProgrammeBlocks.sort)
		Return LocObject
	End Function

	Function Sort:Int(o1:Object, o2:Object)
		Local s1:TArchiveProgrammeBlock = TArchiveProgrammeBlock(o1)
		Local s2:TArchiveProgrammeBlock = TArchiveProgrammeBlock(o2)
		If Not s2 Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
        Return (s1.slot)-(s2.slot)
	End Function

    'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()
		Local HighestBidder:String	= ""
		Local HighestBid:Int		= Programme.getPrice()
		Local NextBid:Int			= 0

		If Bid[0]>0 And Bid[0] <=4 Then If Bid[ Bid[0] ] <> 0 Then HighestBid = Bid[ Bid[0] ]
		NextBid = HighestBid

		If HighestBid < 100000
			NextBid :+ 10000
		Else If HighestBid >= 100000 And HighestBid < 250000
			NextBid :+ 25000
		Else If HighestBid >= 250000 And HighestBid < 750000
			NextBid :+ 50000
		Else If HighestBid >= 750000
			NextBid :+ 75000
		EndIf

		SetColor 255,255,255  'normal
	    If imageWithText = Null

			ImageWithText = CopyImage2( Assets.GetSprite("gfx_auctionmovie").GetImage(0) )
'			ImageWithText = CreateImage(300,40)
			local pix:TPixmap = LockImage(ImageWithText)

			if not ImageWithText THROW "GetImage Error for gfx_auctionmovie"

			'set target for font
			local font:TBitmapFont = Assets.GetFont("Default", 10)
			font.setTargetImage(ImageWithText)

			If Players[Bid[0]] <> Null
				HighestBidder = Players[Bid[0]].name
				font.drawStyled(HighestBidder,33,35, 0, 0, 0, 1, 0.25)
'				font.drawStyled(HighestBidder,33,35, Players[Bid[0]].color.r, Players[Bid[0]].color.g, Players[Bid[0]].color.b, 1, 0.25)
			EndIf
			Assets.GetFont("Default", 10, BOLDFONT).setTargetImage(ImageWithText)
			Assets.GetFont("Default", 10, BOLDFONT).drawBlock(Programme.title, 31,5, 215,20, 0, 0,0,0, false, 1, 1, 0.50)
'			Assets.GetFont("Default", 10, BOLDFONT).drawStyled(Programme.title, 31,5, 0,0,0,1,0,1,0.25)
			Assets.GetFont("Default", 10, BOLDFONT).resetTarget()

'			font.drawBlock(Programme.title, 31,5, 215,20,0, 0,0,0)
			font.drawBlock("Preis:"+HighestBid+CURRENCYSIGN, 31,20, 215,20,2, 100,100,100,1)
			font.drawBlock("Bieten:"+NextBid+CURRENCYSIGN, 31,33, 215,20,2, 0,0,0,1)

			'reset target for font
			font.resetTarget()

	    EndIf
		SetColor 255,255,255
		SetAlpha 1
		DrawImage(imageWithText,x,y)
    End Method


  Function DrawAll(DraggingAllowed:Byte)
		TAuctionProgrammeBlocks.list.sort(True, TAuctionProgrammeBlocks.sort)
      For Local locObject:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
        locObject.Draw()
      Next
  End Function

	Method GetProgramme:TProgramme()  {_exposeToLua}
		return self.Programme
	End Method

	Method SetBid:int(playerID:Int)
		If not Game.isPlayerID( playerID ) then return -1
		if self.Bid[ self.Bid[0] ] = playerID then return 0

		'reset so cache gets renewed
		self.imageWithText = null

		local price:int = self.GetNextBid()
		If Players[playerID].finances[Game.getWeekday()].PayProgrammeBid(price) = True
			If Players[Self.Bid[0]] <> Null Then
				Players[Self.Bid[0]].finances[Game.getWeekday()].GetProgrammeBid(Self.Bid[Self.Bid[0]])
				Self.Bid[Self.Bid[0]] = 0
			EndIf
			Self.Bid[0] = playerID
			Self.Bid[playerID] = price
			Self.imageWithText = Null
		EndIf
		return price
	End Method

	Method GetNextBid:int() {_exposeToLua}
		Local HighestBid:Int	= self.Programme.getPrice()
		Local NextBid:Int		= 0
		If Game.isPlayerID(self.Bid[0]) AND self.Bid[ self.Bid[0] ] <> 0 Then HighestBid = self.Bid[ self.Bid[0] ]
		NextBid = HighestBid
		If HighestBid < 100000
			NextBid :+ 10000
		Else If HighestBid >= 100000 And HighestBid < 250000
			NextBid :+ 25000
		Else If HighestBid >= 250000 And HighestBid < 750000
			NextBid :+ 50000
		Else If HighestBid >= 750000
			NextBid :+ 75000
		EndIf
		return NextBid
	End Method

	Method GetHighestBidder:int() {_exposeToLua}
		if Game.isPlayerID(self.Bid[0]) then return self.Bid[0] else return -1
	End Method

	Function UpdateAll(DraggingAllowed:Byte)
		TAuctionProgrammeBlocks.list.sort(True, TAuctionProgrammeBlocks.sort)
		Local MouseHit:Int = MOUSEMANAGER.IsHit(1)
		For Local locObject:TAuctionProgrammeBlocks = EachIn TAuctionProgrammeBlocks.List
			If MouseHit And functions.IsIn(MouseX(), MouseY(), locObject.x, locObject.y, Assets.GetSprite("gfx_auctionmovie").w, Assets.GetSprite("gfx_auctionmovie").h) And locObject.Bid[0] <> game.playerID

	  			If game.networkgame Then NetworkHelper.SendMovieAgencyChange(NET_BID, game.playerID, locObject.GetNextBid(), -1, locObject.Programme)
	  			locObject.SetBid( game.playerID )  'set the bid
			EndIf
		Next
	End Function

End Type