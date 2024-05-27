SuperStrict
Import Brl.LinkedList
Import "base.util.color.bmx"
Import "base.util.rectangle.bmx"
Import "base.util.vector.bmx"
Import "base.util.graphicsmanagerbase.bmx"


Type TRenderConfig
	Field clsColor:SColor8
	Field color:SColor8
	Field alpha:Float
	Field blendMode:Int
	Field scaleX:Float, scaleY:Float
	Field originX:Float, originY:Float
	Field rotation:Float
	Field viewport:SRect

	Global list:TList = CreateList()
	Global _stackedViewport:TRectangle = new TRectangle
	Global _stackedViewportValid:Int = False


	'fetch the last render configuration from the list
	'and use its values
	'returns the popped config
	Function Pop:TRenderconfig()
		local config:TRenderConfig = TRenderConfig(list.RemoveLast())
		if not config then return Null

		SetColor(config.color)
		SetAlpha(config.alpha)
		SetCLSColor(config.clsColor)
		SetBlend(config.blendMode)
		SetOrigin(config.originX, config.originY)
		SetScale(config.scaleX, config.scaleY)
		SetRotation(config.rotation)
		GetGraphicsManager().setViewPort(int(config.viewport.x), int(config.viewport.y), int(config.viewport.w), int(config.viewport.h))

		return config
	End Function


	'remove a specific configuration
	Function RemoveConfig:Int(config:TRenderConfig)
		if list.Remove(config)
			_stackedViewport = null
		endif
	End Function


	'store the current render configuration in the list
	Function Push:TRenderConfig()
		local config:TRenderConfig = new TRenderConfig

		GetColor(config.color)
		config.alpha = GetAlpha()
		local r:int, g:int, b:int; GetClsColor(r,g,b)
		config.clsColor = new SColor8(r,g,b)
		config.blendMode = GetBlend()
		config.rotation = GetRotation()

		GetOrigin(config.originX, config.originY)
		GetScale(config.scaleX, config.scaleY)
		config.rotation = GetRotation()
		local x:int,y:int,w:int,h:int; GetGraphicsManager().GetViewPort(x, y, w, h)
		config.viewport = new SRect(x,y,w,h)

		list.AddLast(config)
		return config
	End Function


	'returns the viewport of all configurations overlayed 	(passepartout)
	Function GetStackedViewPort:SRect()
		local result:SRect
		local isFirst:Int = True

		For local config:TRenderConfig = EachIn list
			'if first configuration: copy as first viewport rect
			if isFirst 
				result = config.viewport
				isFirst = False
				continue
			endif

			'all other configurations intersect with the base rect (they
			'keep decreasing the viewport)
			result = result.IntersectRect(config.viewport)
		Next

		return result
	End Function


	'Sets the viewport of all configurations overlayed 	(passepartout)
	Function SetStackedViewPort()
		if not list or list.count() = 0
			GetGraphicsManager().SetViewPort(0, 0, GetGraphicsManager().realWidth, GetGraphicsManager().realHeight)
		EndIf
	
		local result:SRect = GetStackedViewPort()
		GetGraphicsManager().SetViewPort(int(result.x), int(result.y), int(result.w), int(result.h))
	End Function
End Type
