SuperStrict
Import "basefunctions.bmx"
Import "Dig/base.util.event.bmx"
Import "Dig/base.util.color.bmx"



'Manager of all screens and corresponding effects
Type TScreenCollection
	Field baseScreen:TScreen
	Field currentScreen:TScreen
	Field targetScreen:TScreen = null
	Field screens:TMap = CreateMap()					'containing all screens
	Global instance:TScreenCollection
	Global _screenDimension:TVec2D = new TVec2D.Init(0,0)
	Global useChangeEffects:int = TRUE


	Function Create:TScreenCollection(baseScreen:TScreen)
		local obj:TScreenCollection = new TScreenCollection
		obj.baseScreen = baseScreen

		if not instance then instance = obj

		return obj
	End Function


	Function GetInstance:TScreenCollection()
		if not instance then instance = TScreenCollection.Create(null)
		return instance
	End Function


	Method GetCurrentScreen:TScreen()
		if not currentScreen then return baseScreen
		return currentScreen
	End Method


	Method Add:int(screen:TScreen)
		screens.insert(lower(screen.name), screen)
	End Method


	Method Remove:int(screen:TScreen)
		screens.remove(lower(screen.name))
	End Method


	Method RemoveByName:int(name:string)
		screens.remove(lower(name))
	End Method


	Method GetScreen:TScreen(name:string)
		local obj:TScreen = TScreen( screens.ValueForKey(lower(name)) )
		if obj then return obj

		Throw "TScreen: "+name+" not found."
		return null
	End Method


	Method GoToScreen:int(screen:TScreen=null, screenName:string="")
		'skip current screen has same name
		if currentScreen and currentScreen.name = lower(screenName) then return TRUE
		'fetch screen object if missing
		if not screen and screenName<>"" then screen = GetScreen(screenName)
		'skip if already in this screen
		if currentScreen = screen then return TRUE

		'trigger event so others can attach
		local event:TEventSimple = TEventSimple.Create("screen.onLeave", new TData.Add("toScreen", screen), currentScreen)
		EventManager.triggerEvent(event)
		if not event.isVeto()
			local event:TEventSimple = TEventSimple.Create("screen.onEnter", new TData.Add("fromScreen", currentScreen), screen)
			EventManager.triggerEvent(event)
			if not event.isVeto()
				'instead of assigning currentScreen directly we use a setter
				'so visual effects can happen first
				'there is an effect to handle first - so set target instead of current screen
				if useChangeEffects and currentScreen and currentScreen.HasScreenChangeEffect(screen)
					return _SetTargetScreen(screen)
				else
					return _SetCurrentScreen(screen)
				endif
			endif
		endif
		return FALSE
	End Method


	Method _SetCurrentScreen:int(screen:TScreen)
		if screen <> currentScreen
			if screen then screen.Enter(currentScreen)
			currentScreen = screen
			screen.Start()
		endif
		return TRUE
	End Method


	Method _SetTargetScreen:int(screen:TScreen)
		if currentScreen then currentScreen.Leave(screen)
		targetScreen = screen
		return TRUE
	End Method


	Method GoToMainScreen:int()
		return GoToScreen(null)
	End Method


	'change to parent of current screen
	Method GoToParentScreen:int()
		if not GetCurrentScreen() then return FALSE

		return GoToScreen(GetCurrentScreen().parentScreen)
	End Method


	'tries to change to a child screen of the current one
	Method GoToSubScreen:int(name:string)
		if not getCurrentScreen() then return FALSE

		local newScreen:TScreen = getCurrentScreen().GetSubScreen(name)
		if newScreen then return GoToScreen(newScreen)
		return FALSE
	End Method


	Method DrawCurrent:int(tweenValue:float)
		if not GetCurrentScreen() then return FALSE

		GetCurrentScreen().draw(tweenValue)
		'trigger event so others can attach
		EventManager.triggerEvent(TEventSimple.Create("screen.onDraw", null, GetCurrentScreen()))

		'handle screen change effects (LEAVE) for current screen
		if targetScreen
			if GetCurrentScreen()._leaveScreenEffect then GetCurrentScreen()._leaveScreenEffect.Draw(tweenValue)
		'handle screen change effects (ENTER) for current screen
		else
			if GetCurrentScreen()._enterScreenEffect then GetCurrentScreen()._enterScreenEffect.Draw(tweenValue)
		endif

		'draw things on top of everything - eg an ingame interface
		GetCurrentScreen().drawOverlay(tweenValue)
	End Method


	Method UpdateCurrent:int(deltaTime:float)
		if not GetCurrentScreen() then return FALSE

		'handle screen change (effects finished)
		if targetScreen and GetCurrentScreen() and GetCurrentScreen().FinishedLeaveEffect()
			_SetCurrentScreen(targetScreen)
			targetScreen = null
		endif

		'handle screen change effects (LEAVE) for current screen
		if targetScreen and not GetCurrentScreen().FinishedLeaveEffect()
			GetCurrentScreen()._leaveScreenEffect.Update(deltaTime)
		'handle screen change effects (ENTER) for current screen
		else
			if not GetCurrentScreen().FinishedEnterEffect()
				GetCurrentScreen()._enterScreenEffect.Update(deltaTime)
			endif
		endif

		GetCurrentScreen().update(deltaTime)


		'trigger event so others can attach
		EventManager.triggerEvent(TEventSimple.Create("screen.onUpdate", null, GetCurrentScreen()))
	End Method


	Function SetScreenDimension(width:int, height:int)
		_screenDimension = new TVec2D.Init(width,height)
	End Function
End Type
Global ScreenCollection:TScreenCollection = TScreenCollection.Create(null)



'base screen object
Type TScreen
    Field name:string						'identifier (in screens map)
	Field subScreens:TMap = CreateMap()		'containing all screens this screen controlls
	Field parentScreen:TScreen = null
	Field _enterScreenEffect:TScreenChangeEffect = null
	Field _leaveScreenEffect:TScreenChangeEffect = null


	Method Create:TScreen(name:string)
		SetName(name)
		'initialize screen change effects
		if _enterScreenEffect then _enterScreenEffect.Reset()
		if _leaveScreenEffect then _leaveScreenEffect.Reset()

		return self
	End Method


	Method ToString:string()
		return "TScreen"
	End Method


	Method SetName(name:string)
		self.name = name
	End Method


	Method SetScreenChangeEffects(enterEffect:TScreenChangeEffect, leaveEffect:TScreenChangeEffect)
		_enterScreenEffect = enterEffect
		_leaveScreenEffect = leaveEffect
	End Method


	Method HasScreenChangeEffect:int(otherScreen:TScreen)
		return (_leaveScreenEffect <> null)
	End Method


	Method AddSubScreen:int(screen:TScreen)
		screen.parentScreen = self
		subScreens.insert(screen.name, screen)
	End Method


	Method RemoveSubScreen:int(screen:TScreen)
		screen.parentScreen = null
		subScreens.Remove(screen.name)
	End Method


	Method HasSubScreen:int(name:string="")
		return subScreens.Contains(name)
	End Method


	Method GetSubScreen:TScreen(name:string)
		name = lower(name)
		'checking my subs
		For local key:string = eachin subScreens.Keys()
			if lower(key) = name then return TScreen(subScreens.ValueForKey(key))
		Next
		'not found? - checking the subs of my subs
		For local screen:TScreen = eachin subScreens.Values()
			if not screen then continue
			local res:TScreen = screen.GetSubScreen(name)
			if res then return res
		Next
		return null
	End Method


	Method FinishedLeaveEffect:int()
		if not _leaveScreenEffect then return TRUE
		return _leaveScreenEffect.Finished()
	End Method


	Method FinishedEnterEffect:int()
		if not _enterScreenEffect then return TRUE
		return _enterScreenEffect.Finished()
	End Method


	Method Enter:int(fromScreen:TScreen=null)
		if _enterScreenEffect then _enterScreenEffect.Reset()
	End Method


	'gets called right after entering that screen
	'so use this to init certain values or elements on that screen
	Method Start:int()
	End Method


	Method Leave:int(toScreen:TScreen=null)
		if _leaveScreenEffect then _leaveScreenEffect.Reset()
	End Method


	Method Update:int(deltaTime:float)
		'nothing by default
	End Method

	Method Draw:int(tweenValue:float=1.0)
		'nothing by default
	End Method

	Method DrawOverlay:int(tweenValue:float=1.0)
		'nothing by default
	End Method
End Type


'base class for screen change effects
Type TScreenChangeEffect
	Field _finished:int       = FALSE
	Field _duration:int       = 0		'time the effect runs (in milliseconds)
	Field _name:string        = "TScreenChangeEffect"
	Field _direction:int      = 0
	Field _progress:float     = 0.0		'0-1.0
	Field _progressMax:float  = 1.0		'0-1.0
	Field _progressOld:float  = 0.0		'for tweening
	Field _area:TRectangle    = null
	Field ID:int = 0
	const DIRECTION_CLOSE:int = 0
	const DIRECTION_OPEN:int  = 1
	global _lastID:int  = 0


	Method New()
		_lastID:+1
		ID = _lastID
	End Method


	Method GetDuration:int()
		return _duration
	End Method

	'amount a value has to change per millisecond
	Method GetSpeed:float()
		return 1000.0/_duration
	End Method


	Method GetArea:TRectangle()
		if not _area then _area = new TRectangle.Init(0,0, TScreenCollection._screenDimension.GetX(), TScreenCollection._screenDimension.GetY())
		return _area
	End Method


	'has the effect ended?
	Method Finished:int()
		return _finished
	End Method


	Method SetFinished(bool:int=TRUE)
		_finished = bool
	End Method


	Method Reset()
		_finished = FALSE
		_progress = 0.0
		_progressOld = 0.0
	End Method


	Method ToString:string()
		if _direction = 0 then return _name+ID+"_closing"
		return _name+ID+"_opening"
	End Method


	Method Draw:int(tweenValue:Float=1.0)	abstract


	Method Update:int(deltaTime:float)
		if Finished() then return TRUE

		_progressOld = _progress 'for tweening
		_progress :+ deltaTime * GetSpeed()


		if _progress > _progressMax then SetFinished(TRUE)
	End Method
End Type



'fading from color-transparent or vice versa
Type TScreenChangeEffect_SimpleFader extends TScreenChangeEffect
	field _color:TColor       = TColor.clBlack

	Method Create:TScreenChangeEffect_SimpleFader(direction:int=0, area:TRectangle=null)
		_direction = direction
		_duration  = 250 '250 millisecs time
		_area      = null
		if area then _area = area.copy()
		_name      = "TScreenChangeEffect_SimpleFader"
		return self
	End Method


	Method Draw:int(tweenValue:Float=1.0)
		local oldCol:TColor = new TColor.Get()
		local tweenProgress:float = MathHelper.Tween(_progressOld, _progress, tweenValue)
		if _direction = DIRECTION_OPEN then tweenProgress = Max(0, 1.0 - tweenProgress)

		SetAlpha tweenProgress

		_color.SetRGB()
		DrawRect(GetArea().GetX(), GetArea().GetY(), GetArea().GetW(), GetArea().GetH())
		oldCol.SetRGBA()
	End Method
End Type



'growing/shrinking rectangles hiding an area
Type TScreenChangeEffect_ClosingRects extends TScreenChangeEffect_SimpleFader
	Method Create:TScreenChangeEffect_ClosingRects(direction:int=0, area:TRectangle=null)
		Super.Create(direction, area)
		_name = "TScreenChangeEffect_ClosingRects"
		_duration = 250
		_progressMax = 1.2 'so it is fullblack a bit longer
		return self
	End Method


	Method Draw:int(tweenValue:Float=1.0)
		local oldCol:TColor = new TColor.Get()
		local tweenProgress:float = MathHelper.Tween(_progressOld, _progress, tweenValue)
		if _direction = DIRECTION_OPEN then tweenProgress = Max(0, 1.0 - tweenProgress)

		local rectsWidth:float  = tweenProgress * (GetArea().GetW() / 2)
		local rectsHeight:float = tweenProgress * (GetArea().GetH() / 2)

		_color.SetRGB()
		SetAlpha tweenProgress

		DrawRect(GetArea().GetX(), GetArea().GetY(), rectsWidth, rectsHeight)
		DrawRect(GetArea().GetX(), GetArea().GetY() + GetArea().GetH() - rectsHeight, rectsWidth, rectsHeight)

		DrawRect(GetArea().GetX() + GetArea().GetW() - rectsWidth, GetArea().GetY(), rectsWidth, rectsHeight)
		DrawRect(GetArea().GetX() + GetArea().GetW() - rectsWidth, GetArea().GetY() + GetArea().GetH() - rectsHeight, rectsWidth, rectsHeight)

		oldCol.SetRGBA()
	End Method
End Type
