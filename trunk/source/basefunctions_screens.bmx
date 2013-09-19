SuperStrict
Import "basefunctions_sprites.bmx"

'manager: so we can use the same screen for indivdual "users"
'and store their state without needing individual "screens" for them
Type TScreenManager
	Field baseScreen:TScreen
	Field currentScreen:TScreen

	Function Create:TScreenManager(screen:TScreen)
		local obj:TScreenManager = new TScreenManager
		obj.baseScreen = screen
		return obj
	End Function

	Method GetCurrentScreen:TScreen()
		if self.currentScreen then return self.currentScreen else return self.baseScreen
	End Method

	Method GoToScreen:int(screen:TScreen)
		'trigger event so others can attach
		local event:TEventSimple = TEventSimple.Create("screen.onLeave", TData.Create().Add("toScreen", screen), self.currentScreen)
		EventManager.triggerEvent(event)
		if not event.isVeto()
			local event:TEventSimple = TEventSimple.Create("screen.onEnter", TData.Create().Add("fromScreen",self.currentScreen), screen)
			EventManager.triggerEvent(event)
			if not event.isVeto()
				self.currentScreen = screen
				return TRUE
			endif
		endif
		return FALSE
	End Method


	Method GoToMainScreen:int()
		return GoToScreen(null)
	End Method


	Method GoToParentScreen:int()
		return GoToScreen(self.GetCurrentScreen().parentScreen)
	End Method


	Method GoToSubScreen:int (name:string)
		local newScreen:TScreen = self.getCurrentScreen().GetSubScreen(name)
		if newScreen then return GoToScreen(newScreen)
		return FALSE
	End Method


	Method Draw:int()
		self.GetCurrentScreen().draw()
	End Method


	Method Update:int(deltaTime:float)
		self.GetCurrentScreen().update(deltaTime)
	End Method
End Type


Type TScreen
    Field background:TGW_Sprites    	   				'background, the image containing the whole room
    Field name:string									'identifier (in screens map)
	Field subScreens:TMap = CreateMap()					'containing all screens this screen controlls
	Field parentScreen:TScreen = null
	Global screens:TMap = CreateMap()					'containing all screens

	Function Create:TScreen(name:string, background:TGW_Sprites)
		local obj:TScreen = new TScreen
		obj.background = background
		obj.name = name
		'add to global list
		AddScreen(obj)
		return obj
	End Function

	Function AddScreen:int(screen:TScreen)
		screens.insert(screen.name, screen)
	End Function

	Function RemoveScreen:int(name:string)
		screens.remove(name)
	End Function

	Function GetScreen:TScreen(name:string)
		local obj:TScreen = TScreen( screens.ValueForKey(name) )
		if obj then return obj
		Throw "TScreen: "+name+" not found."
		return null
	End Function

	Method AddSubScreen:int(screen:TScreen)
		screen.parentScreen = self
		self.subScreens.insert(screen.name, screen)
	End Method

	Method RemoveSubScreen:int(screen:TScreen)
		screen.parentScreen = null
		self.subScreens.Remove(screen.name)
	End Method

	Method GetSubScreen:TScreen(name:string)
		'checking my subs
		For local key:string = eachin self.subScreens.Keys()
			if lower(key) = lower(name) then return TScreen( self.subScreens.ValueForKey(key) )
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
		'default update
		' ...

		'trigger event so others can attach
		EventManager.triggerEvent( TEventSimple.Create("screen.onUpdate", TData.Create().AddNumber("type", 0), self) )
	End Method

	Method Draw:int()
		'maybe we dont want a default background
		if not self.background then return 0

		SetBlend SOLIDBLEND
		self.background.Draw(20,10)
		SetBlend ALPHABLEND

		'trigger event so others can attach
		EventManager.triggerEvent( TEventSimple.Create("screen.onDraw", TData.Create().AddNumber("type", 1), self) )
	End Method
End Type
