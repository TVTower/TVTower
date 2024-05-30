' scene manager
Import brl.basic
Import "basefunctions_events.bmx"

Type TLayer
	field zindex:int = 0
	field name:string = "default"
	field updatefunc_()
	field drawfunc_()

	Function Create:TLayer(zindex:int = 0, name:string = "default")
		local tmpobj:TLayer = new TLayer
		tmpobj.zindex = zindex
		tmpobj.name = name
		return tmpobj
	End Function

	Method SetUpdateFunction:TLayer(func_())
		self.updatefunc_ = func_
		return self
	End Method

	Method SetDrawFunction:TLayer(func_())
		self.drawfunc_ = func_
		return self
	End Method

	Method Update()
		if self.updatefunc_ <> null then self.updatefunc_()
	End Method

	Method Draw()
		if self.drawfunc_ <> null then self.drawfunc_()
	End Method
End Type


Type TScene
	field _name:string
	field _layers:TList = CreateList()

	Function Create:TScene(name:string)
		local tmpobj:TScene = new TScene
		tmpobj.SetName(name)
		return tmpobj
	End Function

	Method GetName:string()
		return self._name
	End Method

	Method SetName(name:string)
		self._name = name
	end Method

	Method AddLayer:TScene(layer:TLayer)
		self._layers.addLast(layer)
		self.SortLayers()
		return self
	End Method

	Method SortLayers()
		'sort layers
	End Method

	Method Update()
		for local tmpObj:TLayer = eachin self._layers
			tmpObj.Update()
		Next
	End Method

	Method Draw()
		for local tmpObj:TLayer = eachin self._layers
			tmpObj.Draw()
		Next
	End Method
End Type


Type TSceneManager
	field currentScene:TScene
	field list:TList = CreateList()

	Function Create:TSceneManager()
		local tmpobj:TSceneManager = new TSceneManager
		return tmpobj
	End Function

	Method SetCurrentScene(scene:TScene)
		self.currentScene = scene
	End Method

	Method AddScene(scene:TScene)
		if (self.currentScene = null) then self.currentScene = scene
		self.list.addLast(scene)
	End Method

	Method Update()
		self.currentScene.Update()
	End Method

	Method Draw()
		self.currentScene.Draw()
		DrawText(self.currentScene.getName(), 0, 20)
		Flip 0
		Delay(1)
	End Method
End Type