SuperStrict
Import "basefunctions.bmx"
Import "Dig/base.util.event.bmx"
Import "Dig/base.util.color.bmx"
Import "Dig/base.util.interpolation.bmx"
Import "game.gameeventkeys.bmx"




'Manager of all screens and corresponding effects
Type TScreenCollection
	Field baseScreen:TScreen
	Field currentScreen:TScreen
	Field targetScreen:TScreen = null
	'containing all screens
	Field screens:TMap = CreateMap()
	Field screenTransitionActive:int = False

	Global instance:TScreenCollection
	Global _screenDimension:TVec2D = new TVec2D(0,0)
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


	Method IsScreenTransitionActive:int()
		return screenTransitionActive
	End Method


	Method GoToScreen:int(screen:TScreen=null, screenName:string="", force:int = False)
		'skip if current screen has same name
		if currentScreen and currentScreen.name = lower(screenName) then return TRUE
		'fetch screen object if missing
		if not screen and screenName<>"" then screen = GetScreen(screenName)
		'skip if already in this screen
		if currentScreen = screen then return TRUE

		'trigger event so others can attach
		TriggerBaseEvent(GameEventKeys.Screen_OnLeave, new TData.Add("toScreen", screen), currentScreen)

		'if on a screen, try to leave first
		if currentScreen and not currentScreen.TryLeave(screen)
			print "currentScreen.TryLeave failed"
			if not force then return False
		endif

		'if entering a screen, try to enter
		if screen
			local event:TEventBase = TEventBase.Create(GameEventKeys.Screen_OnTryEnter, new TData.Add("fromScreen", currentScreen), screen)
			event.Trigger()
			if event.IsVeto()
				print "screen.onTryEnter forbidden"
				if not force then return False
			endif
		endif

		TriggerBaseEvent(GameEventKeys.Screen_OnBeginLeave, new TData.Add("toScreen", screen), currentScreen)


		'instead of assigning currentScreen directly we use a setter
		'so visual effects can happen first
		'there is an effect to handle first - so set target instead of current screen
		if useChangeEffects and currentScreen and currentScreen.HasScreenChangeEffect(screen)
			return _SetTargetScreen(screen)
		else
			'reset a potential existing target screen
			targetScreen = null
			return _SetCurrentScreen(screen)
		endif

		'screen.onFinishLeave is called via "_SetCurrentScreen"
		'which is also called via _SetTargetScreen and when then
		'finishing the animation

		return FALSE
	End Method


	Method _SetCurrentScreen:int(screen:TScreen)
rem
local screenName:string = "NULL"
local currentName:string = "NULL"
if screen then screenName = screen.GetName()
if currentScreen then currentName = currentScreen.GetName()

print "_SetCurrentScreen ["+currentName+" -> "+screenName+"]"
endrem
		local oldScreen:TScreen = currentScreen

		if screen <> currentScreen
			if screen
'print "               : begin enter [to: " + screen.name+"]"
				screen.BeginEnter(currentScreen)
			EndIf
			currentScreen = screen
			TriggerBaseEvent(GameEventKeys.Screen_OnFinishLeave, new TData.Add("toScreen", currentScreen), oldScreen)

			'if not currentScreen then currentScreen = baseScreen
		endif

		'finished transition in all cases
		screenTransitionActive = False

		local oldScreenName:String
		local currentScreenName:String
		if oldScreen then oldScreenName = oldScreen.GetName()
		if currentScreen then currentScreenName = currentScreen.GetName()
		TriggerBaseEvent(GameEventKeys.Screen_OnSetCurrent, new TData.Add("oldScreenName", oldScreenName).Add("currentScreenName", currentScreenName), oldScreen, currentScreen)

		return TRUE
	End Method


	Method _SetTargetScreen:int(screen:TScreen)
		'starting transition in all cases
		screenTransitionActive = True

rem
local screenName:string = "NULL"
local currentName:string = "NULL"
if screen then screenName = screen.GetName()
if currentScreen then currentName = currentScreen.GetName()
print "_SetTargetScreen ["+currentName+" -> "+screen.GetName()+"]"
endrem
		if currentScreen
			currentScreen.BeginLeave(screen)
'print "               : begin leave [from: "+currentScreen.GetName()+"]"
		endif

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

		GetCurrentScreen().Draw(tweenValue)
		'trigger event so others can attach
		TriggerBaseEvent(GameEventKeys.Screen_OnDraw, null, GetCurrentScreen())

		if useChangeEffects
			'handle screen change effects (LEAVE) for current screen
			'keep drawing the last state until the screen is changed
			if targetScreen and targetScreen <> GetCurrentScreen()
				if GetCurrentScreen()._leaveScreenEffect
					GetCurrentScreen()._leaveScreenEffect.Draw(tweenValue)
				endif
			'handle screen change effects (ENTER) for current screen
			else if not GetCurrentScreen().FinishedEnterEffect()
				GetCurrentScreen()._enterScreenEffect.Draw(tweenValue)
			endif
		endif

		'draw things on top of everything - eg an ingame interface
		GetCurrentScreen().DrawOverlay(tweenValue)
	End Method


	Method UpdateCurrent:int(deltaTime:float)
		'handle screen change (effects finished)
		if targetScreen and GetCurrentScreen()
			if not useChangeEffects or GetCurrentScreen().FinishedLeaveEffect()
				if GetCurrentScreen().state = TScreen.STATE_LEAVING
'print "               : finish leave [from: "+GetCurrentScreen().GetName()+"]"
					GetCurrentScreen().FinishLeave(targetScreen)
				endif

				_SetCurrentScreen(targetScreen)
				targetScreen = null
			endif
		endif

		if not GetCurrentScreen() then return FALSE

		'handle screen change effects (LEAVE) for current screen
		if targetScreen
			if useChangeEffects and not GetCurrentScreen().FinishedLeaveEffect()
				GetCurrentScreen()._leaveScreenEffect.Update()
			endif
		'handle screen change effects (ENTER) for current screen
		else
			if useChangeEffects and not GetCurrentScreen().FinishedEnterEffect()
				GetCurrentScreen()._enterScreenEffect.Update()
			endif

			if GetCurrentScreen().state = TScreen.STATE_ENTERING and (not useChangeEffects or GetCurrentScreen().FinishedEnterEffect())
'print "               : finish enter [to: "+GetCurrentScreen().GetName()+"]"
				GetCurrentScreen().FinishEnter()
'print "----------"
			endif
		endif

		GetCurrentScreen().Update(deltaTime)

		'trigger event so others can attach
		TriggerBaseEvent(GameEventKeys.Screen_OnUpdate, null, GetCurrentScreen())
	End Method


	Function SetScreenDimension(width:int, height:int)
		if not _screenDimension then _screenDimension = new TVec2D
		_screenDimension.SetXY(width, height)
	End Function
End Type
Global ScreenCollection:TScreenCollection = TScreenCollection.Create(null)
ScreenCollection.SetScreenDimension(800,600)


'base screen object
Type TScreen
    'identifier (in screens map)
    Field name:string = "default"
    Field group:string = ""
	'containing all screens this screen controlls
	Field subScreens:TMap = CreateMap()
	Field parentScreen:TScreen = null
	Field _enterScreenEffect:TScreenChangeEffect = null
	Field _leaveScreenEffect:TScreenChangeEffect = null
	Field _callbacks_update:Int(sender:TScreen, deltaTime:Float)[]
	Field _callbacks_draw:Int(sender:TScreen, tweenValue:Float)[]
	Field state:int = 0
	Const STATE_NONE:int = 0
	Const STATE_ENTERING:int = 1
	Const STATE_LEAVING:int = 2


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


	Method GetName:string()
		return name
	End Method


	Method SetName(name:string)
		self.name = name
	End Method


	Method SetGroup(group:string)
		self.group = group
	End Method


	Method SetGroupName(group:string, name:string)
		SetGroup(group)
		SetName(name)
	End Method


	Method SetScreenChangeEffects(enterEffect:TScreenChangeEffect, leaveEffect:TScreenChangeEffect)
		_enterScreenEffect = enterEffect
		_leaveScreenEffect = leaveEffect
	End Method


	Method HasScreenChangeEffect:int(otherScreen:TScreen)
		return (_leaveScreenEffect <> null)
	End Method


	Method HasParentScreen:int(screenName:string)
		if not parentScreen then return False

		if parentScreen.name = screenName
			return True
		else
			return parentScreen.HasParentScreen(screenName)
		endif
	End Method


	Method HasSubScreen:int(screenName:string)
		if not subScreens then return False

		For local subScreen:TScreen = EachIn subScreens.Values()
			if subScreen.name = screenName then return True

			if subScreen.HasSubScreen(screenName) then return True
		Next
		return False
	End Method


	Method AddSubScreen:int(screen:TScreen)
		screen.parentScreen = self
		subScreens.insert(screen.name.ToLower(), screen)
	End Method


	Method RemoveSubScreen:int(screen:TScreen)
		screen.parentScreen = null
		subScreens.Remove(screen.name.ToLower())
	End Method


	Method GetSubScreen:TScreen(screenName:string)
		screenName = lower(screenName)
		'checking my subs
		Local subScreen:TScreen = TScreen(subScreens.ValueForKey(screenName))
		If subScreen Then Return subScreen

		'not found? - checking the subs of my subs
		For local screen:TScreen = eachin subScreens.Values()
			local res:TScreen = screen.GetSubScreen(screenName)
			if res then return res
		Next
		return null
	End Method


	Method Start()
	End Method


	Method FinishedLeaveEffect:int()
		if not _leaveScreenEffect then return TRUE
		return _leaveScreenEffect.Finished()
	End Method


	Method FinishedEnterEffect:int()
		if not _enterScreenEffect then return TRUE
		return _enterScreenEffect.Finished()
	End Method


	'gets called right when entering that screen
	'so use this to init certain values or elements on that screen
	Method BeginEnter:int(fromScreen:TScreen=null)
		state = TScreen.STATE_ENTERING

		TriggerBaseEvent(GameEventKeys.Screen_OnBeginEnter, new TData.Add("fromScreen", fromScreen), self)

		Start()
		if _enterScreenEffect then _enterScreenEffect.Reset()
	End Method


	'called when finished entering (eg. animation finished)
	Method FinishEnter:int()
		state = TScreen.STATE_NONE

		TriggerBaseEvent(GameEventKeys.Screen_OnFinishEnter, null, self)
	End Method


	Method BeginLeave:int(toScreen:TScreen=null)
		state = TScreen.STATE_LEAVING

		if _leaveScreenEffect then _leaveScreenEffect.Reset()
	End Method


	Method FinishLeave:int(toScreen:TScreen=null)
		state = TScreen.STATE_NONE
	End Method


	Method TryLeave:int(toScreen:TScreen=null)
		local event:TEventBase = TEventBase.Create(GameEventKeys.Screen_OnTryLeave, new TData.Add("toScreen", toScreen), self)
		event.Trigger()
		if event.isVeto() then return False
		return True
	End Method


	Method Update:int(deltaTime:float) Final
		'Call callbacks before custom screen stuff
		'(UpdateCustom calls room (of the screen).Update logic which
		' checks for right clicks to leave the room ... so handle any
		' "right click resets" like "delete dragged item" before.
		' This is like with widgets to identify a click: the uppermost
		' has to be checked first)
		For Local i:Int = 0 until _callbacks_update.length
			_callbacks_update[i](self, deltaTime)
		Next

		UpdateCustom(deltaTime)
	End Method

	
	Method UpdateCustom:Int(deltatime:Float)
		'nothing by default, extend for custom stuff
	End Method


	Method Draw:int(tweenValue:float=1.0) Final
		DrawCustom(tweenValue)

		For Local i:Int = 0 until _callbacks_draw.length
			_callbacks_draw[i](self, tweenValue)
		Next
	End Method


	Method DrawCustom:int(tweenValue:float=1.0)
		'nothing by default, extend for custom stuff
	End Method


	Method DrawOverlay:int(tweenValue:float=1.0)
		'nothing by default
	End Method
	
	
	' === CALLBACK HELPERS ===
	' NOT THREAD-SAFE (not intended to be used from Subthreads!)
	' we could now use a mutex to check things but this should not be necessary
	
	Method AddUpdateCallback:Int(cb:Int(sender:TScreen, deltaTime:Float))
		For Local i:Int = 0 until _callbacks_update.length
			if _callbacks_update[i] = cb then Return False
		Next
		_callbacks_update :+ [cb]

		Return True
	End Method

	Method RemoveUpdateCallback:Int(cb:Int(sender:TScreen, deltaTime:Float))
		For Local i:Int = 0 until _callbacks_update.length
			if _callbacks_update[i] = cb 
				_callbacks_update = _callbacks_update[.. i] + _callbacks_update[i + 1 ..] 
				Return True
			EndIf
		Next
		Return False
	End Method

	Method AddDrawCallback:Int(cb:Int(sender:TScreen, tweenValue:Float))
		For Local i:Int = 0 until _callbacks_draw.length
			if _callbacks_draw[i] = cb then Return False
		Next
		_callbacks_draw :+ [cb]
		Return True
	End Method

	Method RemoveDrawCallback:Int(cb:Int(sender:TScreen, tweenValue:Float))
		For Local i:Int = 0 until _callbacks_draw.length
			if _callbacks_draw[i] = cb 
				_callbacks_draw = _callbacks_draw[.. i] + _callbacks_draw[i + 1 ..] 
				Return True
			EndIf
		Next
		Return False
	End Method
End Type


'base class for screen change effects
Type TScreenChangeEffect
	Field _finished:int = FALSE
	'time the effect runs (in milliseconds)
	Field _timeStart:Long = -1
	Field _duration:int = 0
	Field _waitAtBegin:int = 0
	Field _waitAtEnd:int = 0
	Field _name:string = "TScreenChangeEffect"
	Field _direction:int = 0
	'for tweening
	Field _progressOld:float = 0.0
	Field _area:TRectangle = null
	Field ID:int = 0
	const DIRECTION_CLOSE:int = 0
	const DIRECTION_OPEN:int = 1
	global _lastID:int = 0


	Method New()
		_lastID:+1
		ID = _lastID
	End Method


	Method GetDuration:int()
		return _duration
	End Method

	'returns the duration it takes in realtime
	Method GetRealtimeDuration:int()
		return _duration
	End Method


	Method GetCurrentTime:Long()
		return Time.GetAppTimeGone()
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


	Method SetDuration(milliseconds:int=250)
		_duration = milliseconds
	End Method


	Method SetWaitAtBegin(milliseconds:int=250)
		_waitAtBegin = milliseconds
	End Method


	Method SetWaitAtEnd(milliseconds:int=250)
		_waitAtEnd = milliseconds
	End Method


	Method GetTimeStart:Long()
		if _timeStart = -1 then _timeStart = GetCurrentTime()
		return _timeStart
	End Method


	Method Reset:int()
		_finished = FALSE
		_timeStart = GetCurrentTime()
		_progressOld = 0.0
	End Method


	Method Initialize:int()
		Reset()
	End Method


	Method ToString:string()
		if _direction = 0 then return _name+ID+"_closing"
		return _name+ID+"_opening"
	End Method


	Method GetProgress:Float()
		local actionTime:Long = GetDuration() - _waitAtBegin - _waitAtEnd
		if actionTime <= 0 then return 1.0

		return Float( Min(1.0, Max(0, double(GetCurrentTime() - GetTimeStart() - _waitAtBegin) / actionTime)))
	End Method


	Method Draw:int(tweenValue:Float=1.0)	abstract


	Method Update:int()
		if Finished() then return TRUE

		_progressOld = GetProgress() 'for tweening

		if GetCurrentTime() > GetTimeStart() + GetDuration() or GetProgress() >= 1.0
			SetFinished(TRUE)
			return True
		endif

		return False
	End Method
End Type



'fading from color-transparent or vice versa
Type TScreenChangeEffect_SimpleFader extends TScreenChangeEffect
	field _color:SColor8 = SColor8.Black

	Method Create:TScreenChangeEffect_SimpleFader(direction:int=0, area:TRectangle=null)
		_direction = direction

		If area
			if not _area then _area = new TRectangle
			_area.CopyFrom(area)
		Else
			_area = null
		EndIf

		Initialize()

		_name = "TScreenChangeEffect_SimpleFader"
		return self
	End Method


	Method Initialize:int()
		Reset()
		SetDuration(350)
	End Method


	Method Draw:int(tweenValue:Float=1.0)
		'skip drawing if whole thing takes less than 10 ms
		if GetRealtimeDuration() < 10 then return False

		Local oldCol:SColor8; GetColor(oldCol)
		Local oldA:Float = GetAlpha()
		local tweenProgress:float = MathHelper.Tween(_progressOld, GetProgress(), tweenValue)
		if _direction = DIRECTION_OPEN then tweenProgress = Max(0, 1.0 - tweenProgress)

		SetAlpha tweenProgress
		SetColor(_color)
		DrawRect(GetArea().GetX(), GetArea().GetY(), GetArea().GetW(), GetArea().GetH())
		
		SetColor(oldCol)
		SetAlpha(oldA)
	End Method
End Type



'growing/shrinking rectangles hiding an area
Type TScreenChangeEffect_ClosingRects extends TScreenChangeEffect_SimpleFader
	Method Create:TScreenChangeEffect_ClosingRects(direction:int=0, area:TRectangle=null)
		Super.Create(direction, area)
		_name = "TScreenChangeEffect_ClosingRects"

		return self
	End Method


	Method Initialize:int()
		Super.Initialize()

		SetDuration(500)
		'so it is full black a bit longer
		if _direction = DIRECTION_CLOSE
			SetWaitAtBegin(0)
			SetWaitAtEnd(100)
		else
			SetWaitAtBegin(100)
			SetWaitAtEnd(0) 'so it is full black a bit longer
		endif
	End Method


	Method Draw:int(tweenValue:Float=1.0)
		'skip drawing if whole thing takes less than 100 ms
		if GetRealtimeDuration() < 100 then return False

		Local oldCol:SColor8; GetColor(oldCol)
		Local oldA:Float = GetAlpha()
		'use a non-linear tween
		local currentProgress:float = MathHelper.Clamp(MathHelper.Tween(_progressOld, GetProgress(), tweenValue), 0,1)
		if _direction = DIRECTION_OPEN
			currentProgress = 1.0 - currentProgress
		endif

		local alphaProgress:Float = currentProgress
		local tweenProgress:Float = MathHelper.Clamp(Float(TInterpolation.RegularInOut(0, 1, currentProgress, 1.0)))

		local rectsWidth:float  = tweenProgress * (GetArea().GetW() / 2)
		local rectsHeight:float = tweenProgress * (GetArea().GetH() / 2)

		SetColor(_color)
		SetAlpha alphaProgress

		DrawRect(GetArea().GetX(), GetArea().GetY(), rectsWidth, rectsHeight)
		DrawRect(GetArea().GetX(), GetArea().GetY() + GetArea().GetH() - rectsHeight, rectsWidth, rectsHeight)

		DrawRect(GetArea().GetX() + GetArea().GetW() - rectsWidth, GetArea().GetY(), rectsWidth, rectsHeight)
		DrawRect(GetArea().GetX() + GetArea().GetW() - rectsWidth, GetArea().GetY() + GetArea().GetH() - rectsHeight, rectsWidth, rectsHeight)

		SetColor(oldCol)
		SetAlpha(oldA)
	End Method
End Type
