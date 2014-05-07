Import "game.gameobject.bmx"
Import "game.broadcast.genredefinition.base.bmx"
Import "game.broadcast.audienceattraction.bmx"
Import "game.broadcast.audienceresult.bmx"


'Base type for programmes, advertisements...
Type TBroadcastMaterial	extends TNamedGameObject {_exposeToLua="selected"}
	Field state:int				= 0		'by default the state is "normal"
	Field materialType:int		= 0		'original material type (may differ to usage!)
	Field usedAsType:int		= 0		'the type this material is used for (programme as adspot -> trailer)
	Field useableAsType:int		= 0		'the type this material can be used for (so we can forbid certain ads as tvshow etc)

	Field programmedHour:int	= -1	'time at which the material is planned to get send
	Field programmedDay:int		= -1

	Field currentBlockBroadcasting:int		{_exposeToLua} '0 = läuft nicht; 1 = 1 Block; 2 = 2 Block; usw.

	'states a program can be in
	const STATE_NORMAL:int		= 0
	const STATE_OK:int			= 1
	const STATE_FAILED:int		= 2
	const STATE_RUNNING:int		= 3
	'types of broadcastmaterial
	Const TYPE_UNKNOWN:int		= 1
	const TYPE_PROGRAMME:int	= 2
	const TYPE_ADVERTISEMENT:int= 4
	const TYPE_NEWS:int			= 8
	const TYPE_NEWSSHOW:int		= 16


	'needed for all extending objects
	Method GetAudienceAttraction:TAudienceAttraction(hour:Int, block:Int, lastMovieBlockAttraction:TAudienceAttraction, lastNewsBlockAttraction:TAudienceAttraction, withSequenceEffect:Int=False, withLuckEffect:Int=False ) Abstract


	'needed for all extending objects
	Method GetQuality:Float()  {_exposeToLua}
		print "GetQuality"
	End Method


	'what to earn for each viewers in euros?
	'ex.: returning 0.15 means:
	'     for 1.000     viewers I earn 150,00 Euro
	'     for 2.000     viewers I earn 300,00 Euro
	'     for 1.000.000 viewers I earn 150.000,00 Euro and so on
	'so better keep the values low
	Method GetBaseRevenue:Float() {_exposeToLua}
		return 0.0
	End Method


	'get the title
	Method GetDescription:string() {_exposeToLua}
		Return "NO DESCRIPTION"
	End Method


	'get the title
	Method GetTitle:string() {_exposeToLua}
		Return "NO TITLE"
	End Method


	Method GetBlocks:int(broadcastType:int=0) {_exposeToLua}
		Return 1
	End Method


	Method isType:int(typeID:int) {_exposeToLua}
		return self.materialType = typeID
	End Method


	Method setMaterialType:int(typeID:int=0)
		self.materialType = typeID
		self.useableAsType :| typeID
	End Method


	Method setUsedAsType:int(typeID:int=0)
		if typeID > 0
			self.usedAsType = typeID
			self.useableAsType :| typeID
		else
			self.usedAsType = materialType
		endif
	End Method


	Method setState:int(state:int)
		self.state = state
	End Method


	Method isState:int(state:int) {_exposeToLua}
		if self.state = state then return TRUE
		return FALSE
	End Method


	'by default this is the normal ID, but could be the contracts id or so...
	Method GetReferenceID:int() {_exposeToLua}
		return self.id
	End Method


	Method BeginBroadcasting:int(day:int, hour:int, minute:int, audienceResult:TAudienceResult)
		self.SetState(self.STATE_RUNNING)
		Self.currentBlockBroadcasting = 1
	End Method


	Method FinishBroadcasting:int(day:int, hour:int, minute:int, audienceResult:TAudienceResult)
		'print "finished broadcasting of: "+GetTitle()
	End Method


	Method BreakBroadcasting:int(day:int, hour:int, minute:int, audienceResult:TAudienceResult)
		'print "finished broadcasting a block of: "+GetTitle()
	End Method


	Method ContinueBroadcasting:int(day:int, hour:int, minute:int, audienceResult:TAudienceResult)
		Self.currentBlockBroadcasting :+ 1
		'print "continue broadcasting the next block of: "+GetTitle()
	End Method


	'returns whether a programme is programmed for that given day
	Method IsProgrammedForDay:int(day:int)
		if programmedDay = -1 then return FALSE
		'starting at given day
		if programmedDay = day then return TRUE
		'started day before and running that day too?
		if programmedDay = day-1 and getBlocks() + programmedHour > 24 then return TRUE
		return FALSE
	End Method


	'returns whether the programme is programmed at all
	Method IsProgrammed:int(day:int=-1)
		if programmedDay = -1 then return FALSE
		if programmedHour = -1 then return FALSE
		return TRUE
	End Method


	'overrideable default-drawer
	Method ShowSheet:int(x:int,y:int,align:int=0)
		'
	End Method

	Method GetGenreDefinition:TGenreDefinitionBase()
		Return Null
	End Method
End Type
