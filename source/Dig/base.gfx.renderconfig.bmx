SuperStrict
Import Brl.LinkedList
Import "base.util.color.bmx"
Import "base.util.rectangle.bmx"
Import "base.util.vector.bmx"
Import "base.util.graphicsmanagerbase.bmx"


Type TRenderConfig
	Field clsColor:TColor
	Field color:TColor
	Field blendMode:Int
	Field scale:TVec2D
	Field origin:TVec2D
	Field rotation:Float
	Field viewPort:TRectangle

	Global list:TList = CreateList()


	'fetch the last render configuration from the list
	'and use its values
	'returns the popped config
	Function Pop:TRenderconfig()
		local config:TRenderConfig = TRenderConfig(list.RemoveLast())
		if not config then return Null

		config.color.SetRGBA()
		config.clsColor.SetCls()
		SetBlend(config.blendMode)
		SetOrigin(config.origin.x, config.origin.y)
		SetScale(config.scale.x, config.scale.y)
		SetRotation(config.rotation)
		GetGraphicsManager().setViewPort(int(config.viewPort.position.x), int(config.viewPort.position.y), int(config.viewPort.dimension.x), int(config.viewPort.dimension.y))

		return config
	End Function


	'remove a specific configuration
	Function RemoveConfig:Int(config:TRenderConfig)
		list.Remove(config)
	End Function


	'store the current render configuration in the list
	Function Push:TRenderConfig()
		local config:TRenderConfig = new TRenderConfig

		config.color = New TColor.Get()
		config.clsColor = New TColor.GetFromClsColor()
		config.blendMode = GetBlend()
		config.rotation = GetRotation()

		config.origin = new TVec2D; GetOrigin(config.origin.x, config.origin.y)
		config.scale = new TVec2D; GetScale(config.scale.x, config.scale.y)
		config.rotation = GetRotation()
		local x:int,y:int,w:int,h:int; GetGraphicsManager().GetViewPort(x, y, w, h)
		config.viewPort = new TRectangle.Init(x,y,w,h)


		list.AddLast(config)
		return config
	End Function


	'returns the viewport of all configurations overlayed 	(passepartout)
	Function GetStackedViewPort:TRectangle()
		local result:TRectangle

		For local config:TRenderConfig = EachIn list
			'if first configuration: store it as first viewport rect
			if not result
				result = config.viewPort.copy()
				continue
			endif

			'all other configurations intersect with the base rect (they
			'keep decreasing the viewport)
			result.Intersect(config.viewPort)
		Next

		return result
	End Function


	'Sets the viewport of all configurations overlayed 	(passepartout)
	Function SetStackedViewPort:TRectangle()
		local result:TRectangle = GetStackedViewPort()
		if result
			GetGraphicsManager().SetViewPort(int(result.position.x), int(result.position.y), int(result.dimension.x), int(result.dimension.y))
		else
			GetGraphicsManager().SetViewPort(0, 0, GetGraphicsManager().realWidth, GetGraphicsManager().realHeight)
		endif
	End Function
End Type
