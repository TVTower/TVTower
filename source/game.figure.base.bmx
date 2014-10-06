SuperStrict
Import "Dig/base.framework.entity.spriteentity.bmx"
Import "Dig/base.util.registry.spriteloader.bmx"


Type TFigureBaseCollection
	Field list:TList = CreateList()
	Field lastFigureID:int = 0
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


	Method GenerateID:int()
		lastFigureID :+1
		return lastFigureID
	End Method


	Method Get:TFigureBase(figureID:int)
		For local figure:TFigureBase = eachin List
			if figure.id = figureID then return figure
		Next
		return Null
	End Method


	Method GetByName:TFigureBase(name:string)
		For local figure:TFigureBase = eachin List
			if figure.name = name then return figure
		Next
		return Null
	End Method
	

	Method Add:int(figure:TFigureBase)
		'if there is a figure with the same id, remove that first
		if figure.id > 0
			local existingFigure:TFigureBase = Get(figure.id)
			if existingFigure then Remove(existingFigure)
		endif

		List.AddLast(figure)
		'List.Sort()
		return TRUE
	End Method


	Method Remove:int(figure:TFigureBase)
		List.Remove(figure)
		return TRUE
	End Method


	Method UpdateAll:int()
		For Local Figure:TFigureBase = EachIn list
			Figure.Update()
		Next
	End Method


	'run when loading finished
	Function onSaveGameLoad(triggerEvent:TEventBase)
		TLogger.Log("TFigureBaseCollection", "Savegame loaded - reassigning sprites", LOG_DEBUG | LOG_SAVELOAD)
		For local figure:TFigureBase = eachin _instance.list
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

	Field target:TVec2D	= Null {_exposeToLua}
	'targetting a special object (door, hotspot) ?
	Field targetObj:TStaticEntity
	'how long to wait until entering the target (door/hotspot)
	'or how long to wait until start moving when having left
	'a door
	Field WaitEnterTimer:Long = -1
	Field WaitLeavingTimer:Long = -1
	Field WaitEnterLeavingTime:Int = 200
	

	Field figureID:Int = 0
	'does the figure accept manual (AI or user) ChangeTarget-commands?
	Field controllable:Int = True
	Field ControlledByID:Int = -1
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

	'how long should the greet-sprite be shown
	Global greetTime:int = 1000
	'how long to wait intil I greet the same person again
	Global greetEvery:int = 8000

	Global _initDone:int = FALSE


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
		If target or targetObj then return False
		If IsWaitingToEnter() or IsWaitingToLeave() then return False

		return True
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
	

	Method ChangeTarget:Int(x:Int=-1, y:Int=-1) {_exposeToLua}
		return _ChangeTarget(x,y, False)
	End Method


	Method ReachTarget:int()
		'regain control
		controllable = True

		velocity.SetX(0)
		'set target as current position - so we are exactly there we want to be
		if target then area.position.setX( target.getX() )
		'remove target
		target = null

		'emit an event
		EventManager.triggerEvent( TEventSimple.Create("figure.onReachTarget", null, self, targetObj ) )

		'start waiting in front of the target
		If targetObj
			WaitEnterTimer = Time.GetTimeGone() + WaitEnterLeavingTime
		EndIf
	End Method


	Method EnterTarget:int()
		'emit an event
		EventManager.triggerEvent( TEventSimple.Create("figure.onEnterTarget", null, self, targetObj ) )

		'reset target
		targetObj = Null

		'disable waiting
		WaitEnterTimer = -1
	End Method


	Method CanEnterTarget:Int()
		'if still going to somewhere
		if target then return False
		'if you do not have a target, you cannot enter one
		if not targetObj then return False

		return not IsWaitingToEnter()
	End Method


	Method IsWaitingToEnter:Int()
		Return WaitEnterTimer > Time.GetTimeGone()
	End Method

	Method IsWaitingToLeave:Int()
		Return WaitLeavingTimer > Time.GetTimeGone()
	End Method


	'returns what animation has to get played in that moment
	Method GetAnimationToUse:string()
		local result:string = "standBack"
		'if standing
		If GetVelocity().GetX() = 0 or not moveable
			result = "standFront"
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