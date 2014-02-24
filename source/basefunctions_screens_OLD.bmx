SuperStrict
Import "basefunctions_sprites.bmx"

Type TScreenCollection
	Field baseScreen:TScreen
	Field currentScreen:TScreen
	Field screens:TMap = CreateMap()					'containing all screens
	Global instance:TScreenCollection


	Function Create:TScreenCollection(screen:TScreen)
		local obj:TScreenCollection = new TScreenCollection
		obj.baseScreen = screen

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
		local event:TEventSimple = TEventSimple.Create("screen.onLeave", TData.Create().Add("toScreen", screen), self.currentScreen)
		EventManager.triggerEvent(event)
		if not event.isVeto()
			local event:TEventSimple = TEventSimple.Create("screen.onEnter", TData.Create().Add("fromScreen",self.currentScreen), screen)
			EventManager.triggerEvent(event)
			if not event.isVeto()
				currentScreen = screen
				return TRUE
			endif
		endif
		return FALSE
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


	Method DrawCurrent:int()
		if GetCurrentScreen()
			GetCurrentScreen().draw()
			'trigger event so others can attach
			EventManager.triggerEvent( TEventSimple.Create("screen.onDraw", TData.Create().AddNumber("type", 1), GetCurrentScreen()) )
		endif
	End Method


	Method UpdateCurrent:int(deltaTime:float)
		if GetCurrentScreen()
			GetCurrentScreen().update(deltaTime)

			'trigger event so others can attach
			EventManager.triggerEvent( TEventSimple.Create("screen.onUpdate", TData.Create().AddNumber("type", 0), GetCurrentScreen()) )
		endif
	End Method
End Type
Global ScreenCollection:TScreenCollection = TScreenCollection.Create(null)


Type TScreen
    Field background:TGW_Sprite    	   				'background, the image containing the whole room
    Field name:string								'identifier (in screens map)
	Field subScreens:TMap = CreateMap()				'containing all screens this screen controlls
	Field parentScreen:TScreen = null


	Method Create:TScreen(name:string, background:TGW_Sprite=null)
		self.Init(name, background)
		return self
	End Method


	Method Init:int(name:string, background:TGW_Sprite=null)
		self.name = name
		self.background = background
	End Method


	Method AddSubScreen:int(screen:TScreen)
		screen.parentScreen = self
		self.subScreens.insert(screen.name, screen)
	End Method


	Method RemoveSubScreen:int(screen:TScreen)
		screen.parentScreen = null
		self.subScreens.Remove(screen.name)
	End Method


	Method GetSubScreen:TScreen(name:string)
		name = lower(name)
		'checking my subs
		For local key:string = eachin self.subScreens.Keys()
			if lower(key) = name then return TScreen( self.subScreens.ValueForKey(key) )
		Next
		'not found? - checking the subs of my subs
		For local screen:TScreen = eachin self.subScreens.Values()
			if not screen then continue
			local res:TScreen = screen.GetSubScreen(name)
			if res then return res
		Next
		return null
	End Method


	Method Update:int(deltaTime:float)
		'nothing by default
	End Method


	Method DrawBackground:int()
		if not background then return FALSE
		SetBlend SOLIDBLEND
		background.Draw(20,10)
		SetBlend ALPHABLEND
	End Method


	Method Draw:int()
		'tweenValue = CURRENT_TWEEN_FACTOR

		DrawBackground()
	End Method
End Type
