SuperStrict
Import "Dig/base.framework.entity.spriteentity.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"


Type TFigureBaseCollection extends TEntityCollection
	Global _eventsRegistered:int= FALSE
	Global _instance:TFigureBaseCollection


	Method New()
		if not _eventsRegistered
			'handle savegame loading (assign sprites)
			EventManager.registerListenerFunction("SaveGame.OnLoad", onSaveGameLoad)

			_eventsRegistered = TRUE
		Endif
	End Method


	Function GetInstance:TFigureBaseCollection()
		if not _instance then _instance = new TFigureBaseCollection
		return _instance
	End Function


	Method Initialize:TFigureBaseCollection()
		Super.Initialize()
		return self
	End Method


	Method GetByGUID:TFigureBase(GUID:String)
		Return TFigureBase(entries.ValueForKey(GUID))
	End Method


	Method Get:TFigureBase(figureID:int)
		For local figure:TFigureBase = eachin entries.Values()
			if figure.id = figureID then return figure
		Next
		return Null
	End Method


	Method GetByName:TFigureBase(name:string)
		For local figure:TFigureBase = eachin entries.Values()
			if figure.name = name then return figure
		Next
		return Null
	End Method
	

	Method UpdateAll:int()
		For Local Figure:TFigureBase = EachIn entries.Values()
			Figure.Update()
		Next
	End Method


	'run when loading finished
	Function onSaveGameLoad(triggerEvent:TEventBase)
		TLogger.Log("TFigureBaseCollection", "Savegame loaded - reassigning sprites", LOG_DEBUG | LOG_SAVELOAD)
		For local figure:TFigureBase = eachin _instance.entries.Values()
			figure.onLoad()
		Next
	End Function
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetFigureBaseCollection:TFigureBaseCollection()
	Return TFigureBaseCollection.GetInstance()
End Function



Type TFigureBase extends TSpriteEntity {_exposeToLua="selected"}
	'area: from TEntity
	' .position.y is difference to y of building
	' .dimension.x and .y = "end" of figure in sprite
	Field name:String = "unknown"
	'backup of self.velocity.x
	Field initialdx:Float = 0.0
	Field PosOffset:TVec2D = new TVec2D.Init(0,0)
	'0=no boarding, 1=boarding, -1=deboarding
	Field boardingState:Int = 0

	'could be
	'- TVec2D: simple position
	'- TRoomDoorBase: a room door
	'- THotspot: a hotspot
	Field targets:object[]
	'indicator whether the current target was reached already (eg. it is
	'still waiting to enter a room)
	Field currentReachTargetStep:int = 0
	Field currentAction:int = 0

	'how long to wait until entering the target (door/hotspot)
	'or how long to wait until start moving when having left
	'a door
	Field WaitEnterTimer:Long = -1
	Field WaitLeavingTimer:Long = -1
	Field WaitEnterLeavingTime:Int = 200
	

	Field figureID:Int = 0
	'does the figure accept manual (AI or user) ChangeTarget-commands?
	Field controllable:Int = True
	Field alreadyDrawn:Int = 0 			{nosave}

	'whether this figure can move or not (eg. for debugging)
	Field moveable:int = TRUE
	Field greetOthers:int = TRUE
	'when was the last greet to another figure?
	Field lastGreetTime:int	= 0
	'what was the last type of greet?
	Field lastGreetType:int = -1
	Field lastGreetFigureID:int = -1
	'is there a player controlling that figure?
	Field playerID:int = 0
	'can this figure enter every room?
	Field hasMasterKey:int = False

	'how long should the greet-sprite be shown
	Global greetTime:int = 1000
	'how long to wait intil I greet the same person again
	Global greetEvery:int = 8000
	Global _initDone:int = FALSE


	Const ACTION_IDLE:int = 0
	Const ACTION_WALK:int = 1
	Const ACTION_ENTERING:int = 2
	Const ACTION_LEAVING:int = 3


	Method GetFloor:Int(pos:TVec2D = Null) abstract


	Method onLoad:int()
		'reassign sprite
		if sprite and sprite.name then sprite = GetSpriteFromRegistry(sprite.name)
	End Method


	'return if a figure could change targets or receive commands
	Method IsControllable:Int()
		return controllable
	End Method


	Method IsVisible:int()
		return True
	End Method


	Method IsIdling:int()
		If GetTarget() then return False
		If IsWaitingToEnter() or IsWaitingToLeave() then return False

		return True
	End Method


	Method IsInBuilding:int()
		return True
	End Method


	Method IsInRoom:Int(roomName:String="", checkFromRoom:Int=False)
		'a figureBase cannot be in a room (is always in building)
		return False
	End Method
	

	Method CanMove:int()
		if IsWaitingToEnter() then return False
		if IsWaitingToLeave() then return False
		return moveable
	End Method
	

	Method CanSeeFigure:int(figure:TFigureBase, range:int=50)
		'being in a room (or coming out of one)
		if not IsVisible() or not IsVisible() then return FALSE
		'from different floors
		If area.GetY() <> figure.area.GetY() then return FALSE
		'and out of range
		If Abs(area.GetX() - figure.area.GetX()) > range then return FALSE

		'same spot
		if area.GetX() = figure.area.GetX() then return TRUE
		'right of me
		if area.GetX() < figure.area.GetX()
			'i move to the left
			If velocity.GetX() < 0 then return FALSE
			return TRUE
		'left of me
		else
			'i move to the right
			If velocity.GetX() > 0 then return FALSE
			return TRUE
		endif
		return FALSE
	End Method


	Method GetTarget:object()
		if targets.length = 0 then return Null
		return targets[0]
	End Method


	'add a target AFTER all others
	Method AddTarget(target:object)
		targets :+ [target]
	End Method


	'sets the current target, removes all other targets
	Method SetTarget(target:object)
		ClearTargets()
		AddTarget(target)
	End Method


	Method PrependTarget(target:object)
		targets = [target] + targets
	End Method
	

	Method RemoveCurrentTarget:int()
		if targets.length = 0 then return False
		targets = targets[1..]
		return True
	End Method


	Method ClearTargets:int()
		targets = new object[0]
	End Method


	Method MoveToCurrentTarget:int()
		if not GetTarget() then return False

		area.position = GetTargetMoveToPosition().copy()
	End Method


	'change the target of the figure
	'@forceChange   defines wether the target could change target
	'               even when not controllable
	Method _ChangeTarget:Int(x:Int=-1, y:Int=-1, forceChange:Int=False)
		'remove control
		if forceChange then controllable = False
		'is controlling allowed (eg. figure MUST go to a specific target)
		if not forceChange and not IsControllable() then Return False

		'emit an event
		EventManager.triggerEvent( TEventSimple.Create("figure.onChangeTarget", self ) )
	End Method


	'forcefully change the target, even if not controllable
	'eg. to send it to a boss' room
	'do not expose this to AI - as it else could escape another forced
	'target change
	Method ForceChangeTarget:Int(x:Int=-1, y:Int=-1)
		return _ChangeTarget(x,y, True)
	End Method
	

	Method ChangeTarget:Int(x:Int=-1, y:Int=-1)
		return _ChangeTarget(x,y, False)
	End Method


	'returns the coordinate the figure has to walk to, to reach that
	'target
	Method GetTargetMoveToPosition:TVec2D()
		local target:object = GetTarget()
		if TVec2D(target) then return TVec2D(target)

		return Null
	End Method


	'call this as soon as 
	Method OnFinishGoTargetTask:int()
	End Method


	'split into two steps to allow a "waiting time"
	'step 1/2
	Method ReachTargetStep1:int()
		if not GetTarget() then return False

		velocity.SetX(0)
		
		'set target as current position - so we are exactly there we want to be
		local targetPosition:TVec2D = GetTargetMoveToPosition()
		if targetPosition then area.position.setX( targetPosition.getX() )

		currentReachTargetStep = 1

		'emit an event
		EventManager.triggerEvent( TEventSimple.Create("figure.onReachTarget", null, self, GetTarget() ) )

		'run custom onReachTarget method - eg to wait until entering a door
		'or just remove the current target
		customReachTargetStep1()
	End Method
	

	'step 2/2
	Method ReachTargetStep2:int()
		'reset current step to 0 so figure can call step 1 again
		currentReachTargetStep = 0
		RemoveCurrentTarget()
		
		'regain control if there is no other target waiting
		'TODO: place this in a custom "Route"-object? so there could
		'      be a chain of targets which you cannot skip
		if not GetTarget() then controllable = True
	End Method


	'by default we know no targets which need to get entered
	Method TargetNeedsToGetEntered:int()
		'if not GetTarget() then return False
		'if TVec2D(GetTarget()) then return False

		return False
	End Method


	Method customReachTargetStep1:Int()
		'disable WaitEnterTimer
		WaitEnterTimer = -1
	End Method


	Method EnterTarget:int()
		'emit an event
		EventManager.triggerEvent( TEventSimple.Create("figure.onEnterTarget", null, self, GetTarget() ) )
	End Method


	Method CanEnterTarget:Int()
		'cannot enter a non-target
		if not GetTarget() then return False

		if TVec2D(GetTarget()) then return False

		'no waiting needed
		if WaitEnterTimer = -1 then return True

		return not IsWaitingToEnter()
	End Method


	Method IsWaitingToEnter:Int()
		Return WaitEnterTimer > Time.GetTimeGone()
	End Method


	Method IsWaitingToLeave:Int()
		Return WaitLeavingTimer > Time.GetTimeGone()
	End Method


	'use this to enter either a roomdoor, a room or something else...
	Method EnterLocation:Int(obj:object, forceEnter:int=False)
		'stub
	End Method


	'returns what animation has to get played in that moment
	Method GetAnimationToUse:string()
		local result:string = "standBack"

		'if standing
		If GetVelocity().GetX() = 0 or not moveable
			if currentAction = ACTION_ENTERING
				result = "standBack"
			else
				result = "standFront"
			endif
		Else
			If GetVelocity().GetX() > 0 Then result = "walkRight"
			If GetVelocity().GetX() < 0 Then result = "walkLeft"
		EndIf
		
		if IsWaitingToLeave() then result = "standFront"
		if IsWaitingToEnter() then result = "standBack"

		return result
	End Method
	

	Method Update:int()
		'call parents update (which does movement and updates current
		'animation)
		Super.Update()

		Self.alreadydrawn = 0

		'movement is not done when in a room
		FigureMovement()
		'set the animation
		GetFrameAnimations().SetCurrent( getAnimationToUse() )

		'this could be overwritten by extended types
		UpdateCustom()
	End Method


	Method UpdateCustom:int()
		'empty by default
	End Method


	Method Draw:int(overwriteAnimation:String="") abstract
	Method FigureMovement:int() abstract
End Type