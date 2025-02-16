SuperStrict
Import Brl.LinkedList
Import "base.util.color.bmx"
Import "base.util.rectangle.bmx"
Import "base.util.vector.bmx"
Import "base.util.graphicsmanagerbase.bmx"


Struct SRenderConfig
	Field clsColor:SColor8
	Field color:SColor8
	Field alpha:Float
	Field blendMode:Int
	Field scaleX:Float, scaleY:Float
	Field originX:Float, originY:Float
	Field rotation:Float
	Field vpX:Int, vpY:Int, vpW:Int, vpH:Int

	Method New()
		GetColor(color)
		alpha = GetAlpha()
		
		local r:int, g:int, b:int; GetClsColor(r,g,b)

		clsColor = new SColor8(r,g,b)
		blendMode = GetBlend()
		rotation = GetRotation()

		GetOrigin(originX, originY)
		GetScale(scaleX, scaleY)
		rotation = GetRotation()
		GetGraphicsManager().GetViewPort(vpX, vpY, vpW, vpH)
	End Method
	
	Method Apply()
		SetColor(color)
		SetAlpha(alpha)
		SetCLSColor(clsColor)
		SetBlend(blendMode)
		SetOrigin(originX, originY)
		SetScale(scaleX, scaleY)
		SetRotation(rotation)
		GetGraphicsManager().SetViewPort(vpX, vpY, vpW, vpH)
	End Method
End Struct


Type TRenderConfig
	Global stack:SRenderConfig[]
	Global nextIndex:Int = 0


	'store the current render configuration
	Function Backup()
		'resize if needed (avoids having a precreated config - which
		'does not work until Max2D is initialized
		if stack.length = 0
			stack = stack[.. 50]
		EndIf
			
		If nextIndex >= 50
			Throw "TRenderconfig index exceeds limit of 50"
		EndIf

		stack[nextIndex] = New SRenderConfig
		nextIndex :+ 1
	End Function


	'apply previous render configuration
	Function Restore()
		If stack.length = 0 or nextIndex = 0 Then Return 'nothing to do

		
		nextIndex :- 1
		stack[nextIndex].Apply()
	End Function


	'returns the viewport of all configurations overlayed 	(passepartout)
	Function GetStackedViewPort:SRect()
		local result:SRect = New SRect(0, 0, GetGraphicsManager().realWidth, GetGraphicsManager().realHeight)

		if nextIndex > 0
			For Local i:int = 1 to nextIndex
				'all other configurations intersect with the base rect (they
				'keep decreasing the viewport)
				result = result.IntersectRect(stack[i].vpX, stack[i].vpY, stack[i].vpW, stack[i].vpH)
			Next
		endif

		return result
	End Function


	'Sets the viewport of all configurations overlayed 	(passepartout)
	Function SetStackedViewPort()
		if nextIndex = 0
			GetGraphicsManager().SetViewPort(0, 0, GetGraphicsManager().realWidth, GetGraphicsManager().realHeight)
		EndIf
	
		local result:SRect = GetStackedViewPort()
		GetGraphicsManager().SetViewPort(int(result.x), int(result.y), int(result.w), int(result.h))
	End Function
End Type
