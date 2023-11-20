SuperStrict
Import Brl.Pixmap
Import Math.Vector
Import Brl.Threads
Import "Dig/base.util.longintmap.bmx"


Struct SLayerConfig
	Field layer:TPopulationCanvasLayer
	Field mode:EPopulationCanvasMode
	Field options:Int
	'layer offset
	'allows to move around a layer's content without adjusting the
	'content itself
	Field offsetX:Int
	Field offsetY:Int
End Struct



'Base class / Container for population calculations
Type TPopulationCanvas
	Field staticarray layers:SLayerConfig[10]
	Field layersDynamic:SLayerConfig[]

'	Field staticarray layers:TPopulationCanvasLayer[20]
'	Field staticarray layer_modes:EPopulationCanvasMode[20]
'	Field staticarray layer_options:Int[20]
	'layer offset
	'allows to move around a layer's content without adjusting the
	'content itself
'	Field staticarray layer_offsetX:Int[20]
'	Field staticarray layer_offsetY:Int[20]
	Field layersUsed:int
	
	Const LAYEROPTION_INVISIBLE:INT = 1
	Const LAYEROPTION_IGNORE_IN_AREA_CALCULATION:INT = 2


	'=== layer management ===

	Method AddLayer(layer:TPopulationCanvasLayer, layerMode:EPopulationCanvasMode = EPopulationCanvasMode.Add, layerOptions:Int = -1, layerOffsetX:Int = 0, layerOffsetY:Int = 0)
		If not layer Then Return

		Local dynamicIndex:Int = layersUsed - layers.Length
		If dynamicIndex >= 0
			If layersDynamic.Length <= dynamicIndex Then layersDynamic = layersDynamic[ .. dynamicIndex + 10]
			layersDynamic[dynamicIndex].layer = layer
			layersDynamic[dynamicIndex].mode = layerMode
			layersDynamic[dynamicIndex].offsetX = layerOffsetX
			layersDynamic[dynamicIndex].offsetY = layerOffsetY
			if layerOptions >= 0 Then layersDynamic[dynamicIndex].options = layerOptions
		Else
			layers[layersUsed].layer = layer
			layers[layersUsed].mode = layerMode
			layers[layersUsed].offsetX = layerOffsetX
			layers[layersUsed].offsetY = layerOffsetY
			if layerOptions >= 0 Then layers[layersUsed].options = layerOptions
		EndIf

		layersUsed :+ 1
	End Method


	Method SetLayer(layer:TPopulationCanvasLayer, index:Int, layerMode:EPopulationCanvasMode = EPopulationCanvasMode.Add, layerOptions:Int = -1, layerOffsetX:Int = 0, layerOffsetY:Int = 0)
		If not layer Then Return
		If index < 0 Then Return

		Local dynamicIndex:Int = index - layers.Length
		If dynamicIndex >= 0
			If layersDynamic.Length <= dynamicIndex Then layersDynamic = layersDynamic[ .. dynamicIndex + 10]
			layersDynamic[dynamicIndex].layer = layer
			layersDynamic[dynamicIndex].mode = layerMode
			layersDynamic[dynamicIndex].offsetX = layerOffsetX
			layersDynamic[dynamicIndex].offsetY = layerOffsetY
			if layerOptions >= 0 Then layersDynamic[dynamicIndex].options = layerOptions
		Else
			layers[index].layer = layer
			layers[index].mode = layerMode
			layers[index].offsetX = layerOffsetX
			layers[index].offsetY = layerOffsetY
			if layerOptions >= 0 Then layers[index].options = layerOptions
		EndIf

		layersUsed = Max(layersUsed, index + 1)
	End Method

rem
todo
	Method InsertLayer:Int(layer:TPopulationCanvasLayer, index:Int, layerMode:EPopulationCanvasMode = EPopulationCanvasMode.Add, layerOptions:Int = -1, layerOffsetX:Int = 0, layerOffsetY:Int = 0)
		If index < 0 Then Return False

		'advance entries
		If index > layersUsed
			For local i:int = layers.length-1 -1 to index step -1
				layers[i + 1] = layers[i]
				layer_options[i + 1] = layer_options[i]
				layer_modes[i + 1] = layer_modes[i]
				layer_offsetX[i + 1] = layer_offsetX[i]
				layer_offsetY[i + 1] = layer_offsetY[i]
			Next
		EndIf

		'insert current
		layers[index] = layer
		layer_options[index] = layerOptions
		layer_modes[index] = layerMode
		layer_offsetX[index] = layerOffsetX
		layer_offsetY[index] = layerOffsetY

		layersUsed = layers.length
		For local i:int = layers.length-1 to 0 step -1
			if layers[i] then exit
			layersUsed :- 1
		Next

		Return True
	End Method
endrem

	Method GetLayer:TPopulationCanvasLayer(index:Int)
		If index < 0 or index >= layersUsed Then Return Null

		Local dynamicIndex:Int = index - layers.Length
		If dynamicIndex >= 0
			Return layersDynamic[dynamicIndex].layer
		Else
			Return layers[index].layer
		EndIf
	End Method

rem
'todo
	Method RemoveLayer:Int(index:Int)
		If index < 0 Or index >= layers.length Then Return False
		'move all upcoming to left
		For local i:int = index + 1 to layers.length-1
			layers[i - 1] = layers[i]
			layer_options[i - 1] = layer_options[i]
			layer_modes[i - 1] = layer_modes[i]
			layer_offsetX[i - 1] = layer_offsetX[i]
			layer_offsetY[i - 1] = layer_offsetY[i]
		Next
		'unset last
		layers[layers.length - 1] = Null
		layer_options[layers.length - 1] = 0
		layer_modes[layers.length - 1] = EPopulationCanvasMode.Add
		layer_offsetX[layers.length - 1] = 0
		layer_offsetY[layers.length - 1] = 0

		'update layers used
		layersUsed = layers.length
		For local i:int = layers.length-1 to 0 step -1
			if layers[i] then exit
			layersUsed :- 1
		Next
	End Method

	Method RemoveLayer:Int(layer:TPopulationCanvasLayer)
'		Return layers.Remove(layer)
	End Method
endrem


	Method SetLayerMode(index:Int, mode:EPopulationCanvasMode)
		If index < 0 or index >= layersUsed Then Return

		Local dynamicIndex:Int = index - layers.Length
		If dynamicIndex >= 0
			self.layersDynamic[dynamicIndex].mode = mode
		Else
			self.layers[index].mode = mode
		EndIf
	End Method


	Method SetLayerOptions(index:Int, layerOptions:Int)
		If index < 0 or index >= layersUsed Then Return

		Local dynamicIndex:Int = index - layers.Length
		If dynamicIndex >= 0
			self.layersDynamic[dynamicIndex].options = layerOptions
		Else
			self.layers[index].options = layerOptions
		EndIf
	End Method


	Method SetLayerOption(index:Int, layerOption:Int, enable:Int = True)
		If index < 0 or index >= layersUsed Then Return

		Local dynamicIndex:Int = index - layers.Length
		If dynamicIndex >= 0
			If enable
				self.layersDynamic[dynamicIndex].options :| layerOption
			Else
				self.layersDynamic[dynamicIndex].options :& ~layerOption
			EndIf
		Else
			If enable
				self.layers[index].options :| layerOption
			Else
				self.layers[index].options :& ~layerOption
			EndIf
		EndIf
	End Method
	
	
	Method SetLayerVisibility(index:Int, enable:Int = True)
		If index < 0 or index >= layersUsed Then Return

		Local dynamicIndex:Int = index - layers.Length
		If dynamicIndex >= 0
			If enable
				self.layersDynamic[dynamicIndex].options :& ~LAYEROPTION_INVISIBLE
			Else
				self.layersDynamic[dynamicIndex].options :| LAYEROPTION_INVISIBLE
			EndIf
		Else
			If enable
				self.layers[index].options :& ~LAYEROPTION_INVISIBLE
			Else
				self.layers[index].options :| LAYEROPTION_INVISIBLE
			EndIf
		EndIf
	End Method
		

	Method SetLayerIgnoreInAreaCalculation(index:Int, enable:Int = True)
		If index < 0 or index >= layersUsed Then Return

		Local dynamicIndex:Int = index - layers.Length
		If dynamicIndex >= 0
			If enable
				self.layersDynamic[dynamicIndex].options :| LAYEROPTION_IGNORE_IN_AREA_CALCULATION
			Else
				self.layersDynamic[dynamicIndex].options :& ~LAYEROPTION_IGNORE_IN_AREA_CALCULATION
			EndIf
		Else
			If enable
				self.layers[index].options :| LAYEROPTION_IGNORE_IN_AREA_CALCULATION
			Else
				self.layers[index].options :& ~LAYEROPTION_IGNORE_IN_AREA_CALCULATION
			EndIf
		EndIf
	End Method


	Method SetLayerOffset(index:Int, offsetX:Int, offsetY:Int)
		If index < 0 or index >= layersUsed Then Return

		Local dynamicIndex:Int = index - layers.Length
		If dynamicIndex >= 0
			self.layersDynamic[dynamicIndex].offsetX = offsetX
			self.layersDynamic[dynamicIndex].offsetY = offsetY
		Else
			self.layers[index].offsetX = offsetX
			self.layers[index].offsetY = offsetY
		EndIf
	End Method


	'=== data getters/setters ===
	Method GetUsedArea(x:Int var, y:Int var, w:Int var, h:Int var)
		if layersUsed = 0 Then Return

		Local isFirst:Int = True
		Local minX:Int
		Local maxX:Int
		Local minY:Int
		Local maxY:Int

		For local i:int = 0 to layersUsed-1
			Local dynamicIndex:Int = i - layers.Length

			if i < layers.length
				If not layers[i] Then continue

				layers[i].layer.UpdateLayerBoundaries()
				'not ignoring?
				if layers[i].options & LAYEROPTION_IGNORE_IN_AREA_CALCULATION = 0
					if layers[i].layer.x + layers[i].offsetX < minX or isFirst then minX = layers[i].layer.x + layers[i].offsetX
					if layers[i].layer.y + layers[i].offsetY < minY or isFirst then minY = layers[i].layer.y + layers[i].offsetY
					if layers[i].layer.x2 + layers[i].offsetX > maxX or isFirst then maxX = layers[i].layer.x2 + layers[i].offsetX
					if layers[i].layer.y2 + layers[i].offsetY > maxY or isFirst then maxY = layers[i].layer.y2 + layers[i].offsetY
					
					isFirst = False
				EndIf
			ElseIf dynamicIndex < layersDynamic.length 
				If not layersDynamic[dynamicIndex] Then continue

				layersDynamic[dynamicIndex].layer.UpdateLayerBoundaries()
				'not ignoring?
				if layersDynamic[dynamicIndex].options & LAYEROPTION_IGNORE_IN_AREA_CALCULATION = 0
					if layersDynamic[dynamicIndex].layer.x + layersDynamic[dynamicIndex].offsetX < minX or isFirst then minX = layersDynamic[dynamicIndex].layer.x + layersDynamic[dynamicIndex].offsetX
					if layersDynamic[dynamicIndex].layer.y + layersDynamic[dynamicIndex].offsetY < minY or isFirst then minY = layersDynamic[dynamicIndex].layer.y + layersDynamic[dynamicIndex].offsetY
					if layersDynamic[dynamicIndex].layer.x2 + layersDynamic[dynamicIndex].offsetX > maxX or isFirst then maxX = layersDynamic[dynamicIndex].layer.x2 + layersDynamic[dynamicIndex].offsetX
					if layersDynamic[dynamicIndex].layer.y2 + layersDynamic[dynamicIndex].offsetY > maxY or isFirst then maxY = layersDynamic[dynamicIndex].layer.y2 + layersDynamic[dynamicIndex].offsetY
					
					isFirst = False
				EndIf
			EndIf
		Next

		x = minX
		y = minY
		w = maxX - minX
		h = maxY - minY
	End Method


	'checks layers "top to down" for a value
	'each layer's set values are like opaque color
	Method GetFirstValue:Int(x:Int, y:Int)
		throw "GetFirstValue(): todo"
	End Method


	'sums layers "top to down" by adding/subtracting/...
	'layers 
	Method GetValue:Int(x:Int, y:Int)
		if layersUsed = 0 Then Return 0

		Local result:Int
		For local i:int = 0 to layersUsed-1
			Local dynamicIndex:Int = i - layers.Length
			local value:Int
			local layer_mode:EPopulationCanvasMode

			If i < layers.length
				'ignore empty and invisible
				If not layers[i] Then Continue
				if layers[i].options & LAYEROPTION_INVISIBLE > 0 Then Continue
				
				value = layers[i].layer.GetValue(x - layers[i].offsetX, y - layers[i].offsetY).value
				layer_mode = layers[i].mode
			ElseIf dynamicIndex < layersDynamic.length 
				'ignore empty and invisible
				If not layersDynamic[dynamicIndex] Then continue
				if layersDynamic[dynamicIndex].options & LAYEROPTION_INVISIBLE > 0 Then Continue

				value = layersDynamic[dynamicIndex].layer.GetValue(x - layersDynamic[dynamicIndex].offsetX, y - layersDynamic[dynamicIndex].offsetY).value
				layer_mode = layersDynamic[dynamicIndex].mode
			EndIf

			Select layer_mode
				case EPopulationCanvasMode.Add
					result :+ value
				case EPopulationCanvasMode.Subtract
					result :- value
				case EPopulationCanvasMode.Multiply
					result :* value
				case EPopulationCanvasMode.AddBinary
					result :+ 1 * (0 <> value)
				case EPopulationCanvasMode.SubtractBinary
					result :- 1 * (0 <> value)
				case EPopulationCanvasMode.MultiplyBinary 'same as "BinaryMask" !
					result = int(result * (0 <> value))
				case EPopulationCanvasMode.AlphaMask
					result = int((result * value)/255)
				case EPopulationCanvasMode.NegativeAlphaMask
					result = int((result * (255-value))/255)
				case EPopulationCanvasMode.ClipSmaller
					result = int(result * (result >= value))
				case EPopulationCanvasMode.ClipBigger
					'if result < 0
					'	print "x="+x+", y="+y+"  result="+result+"  layer="+layers[i].GetValue(x, y).value
					'endif
					result = int(result * (result <= value))
				'set result to 0 if is same as "value" (clip "equal")
				case EPopulationCanvasMode.ClipBinary
					result = int((result <> value))
				'set result to 0 if is NOT same as "value" (clip "not equal")
				case EPopulationCanvasMode.ClipNegativeBinary
					result = int((result = value))
				case EPopulationCanvasMode.MaskExclusiveCoverage
					'either 0 or 1
					'value = 0 : not existing in this layer (clip out)
					'result > value: stuff still existing after removal (so "was there before")
					'result = 0: stuff NOT existing before (so "wasn't there before")
					result = (value <> 0 and result <= value and result <> 0) 

					'das waere, was "uebrig bleibt" (von anderem Mast noch mit "belegt")
					'result = (value <> 0 and result > value) 
				case EPopulationCanvasMode.MaskedAdd
					result = int((result <> 0) * value)
				case EPopulationCanvasMode.NegativeMaskedAdd
					result = int((result = 0) * value)
				case EPopulationCanvasMode.BinaryMask
					result = int(result * (0 <> value))
				case EPopulationCanvasMode.NegativeBinaryMask
					result = int(result * (0 = value))
			End Select
		Next
		return result
	End Method



	'sums layers "top to down" by adding/subtracting/...
	'layers 
	Method GetValue:Int() nodebug
		if layersUsed = 0 Then Return 0

		Local x:Int, y:Int, w:int, h:int
		GetUsedArea(x, y, w, h)


		Local totalResult:Int
		
		'lock all layers to avoid concurrent modification
		'this avoids lock/unlock mutex for each single pixel access
		For local i:int = 0 to layersUsed-1
			Local dynamicIndex:Int = i - layers.Length

			If i < layers.length
				if layers[i] and layers[i].options & LAYEROPTION_INVISIBLE > 0
					layers[i].layer.LockConcurrentModification(True)
				EndIf
			ElseIf dynamicIndex < layersDynamic.length 
				If layersDynamic[dynamicIndex] and layersDynamic[dynamicIndex].options & LAYEROPTION_INVISIBLE > 0
					layersDynamic[dynamicIndex].layer.LockConcurrentModification(True)
				EndIf
			EndIf
		Next

		
		For local myX:Int = x to x + w
			For local myY:Int = y to y + h
				Local result:Int
				For local i:int = 0 to layersUsed - 1
					Local dynamicIndex:Int = i - layers.Length
					local value:Int
					local layer_mode:EPopulationCanvasMode

					If i < layers.length
						'ignore empty and invisible
						If not layers[i] Then Continue
						if layers[i].options & LAYEROPTION_INVISIBLE > 0 Then Continue
						
						value = layers[i].layer.GetValue(myX - layers[i].offsetX, myY - layers[i].offsetY).value
						layer_mode = layers[i].mode
					ElseIf dynamicIndex < layersDynamic.length 
						'ignore empty and invisible
						If not layersDynamic[dynamicIndex] Then continue
						if layersDynamic[dynamicIndex].options & LAYEROPTION_INVISIBLE > 0 Then Continue

						value = layersDynamic[dynamicIndex].layer.GetValue(myX - layersDynamic[dynamicIndex].offsetX, myY - layersDynamic[dynamicIndex].offsetY).value
						layer_mode = layersDynamic[dynamicIndex].mode
					endIf


					Select layer_mode
						case EPopulationCanvasMode.Add
							result :+ value
						case EPopulationCanvasMode.Subtract
							result :- value
						case EPopulationCanvasMode.Multiply
							result :* value
						case EPopulationCanvasMode.AddBinary
							result :+ 1 * (0 <> value)
						case EPopulationCanvasMode.SubtractBinary
							result :- 1 * (0 <> value)
						case EPopulationCanvasMode.MultiplyBinary 'same as "BinaryMask" !
							result = int(result * (0 <> value))
						case EPopulationCanvasMode.AlphaMask
							result = int((result * value)/255)
						case EPopulationCanvasMode.NegativeAlphaMask
							result = int((result * (255-value))/255)
						case EPopulationCanvasMode.ClipSmaller
							result = int((result * (result >= value))/255)
						case EPopulationCanvasMode.ClipBigger
							result = int((result * (result <= value))/255)
						case EPopulationCanvasMode.ClipBinary
							result = int(result <> value)
						case EPopulationCanvasMode.ClipNegativeBinary
							result = int(result = value)
						case EPopulationCanvasMode.MaskExclusiveCoverage
							'either 0 or 1
							'value = 0 : not existing in this layer (clip out)
							'result > value: stuff still existing after removal (so "was there before")
							'result = 0: stuff NOT existing before (so "wasn't there before")
							result = (value <> 0 and result <= value and result <> 0) 

						case EPopulationCanvasMode.MaskedAdd
							result = int((result <> 0) * value)
						case EPopulationCanvasMode.NegativeMaskedAdd
							result = int((result = 0) * value)
						case EPopulationCanvasMode.BinaryMask
							result = int(result * (0 <> value))
						case EPopulationCanvasMode.NegativeBinaryMask
							result = int(result * (0 = value))
					End Select
				Next
				totalResult :+ result
			Next
		Next

		'unlock all layers to avoid concurrent modification
		For local i:int = 0 to layersUsed-1
			Local dynamicIndex:Int = i - layers.Length

			If i < layers.length
				if layers[i] and layers[i].options & LAYEROPTION_INVISIBLE > 0
					layers[i].layer.LockConcurrentModification(False)
				EndIf
			ElseIf dynamicIndex < layersDynamic.length 
				If layersDynamic[dynamicIndex] and layersDynamic[dynamicIndex].options & LAYEROPTION_INVISIBLE > 0
					layersDynamic[dynamicIndex].layer.LockConcurrentModification(False)
				EndIf
			EndIf
		Next
		return totalResult
	End Method
	

	Method CreatePixmapFromCanvas:TPixmap()
		Local x:Int, y:Int, w:int, h:int
		GetUsedArea(x, y, w, h)

		Local pix:TPixmap = CreatePixmap(w, h, PF_RGBA8888)
		pix.ClearPixels(0)

		For Local i:Int = 0 to layersUsed - 1
			Local dynamicIndex:Int = i - layers.Length
			'argb
			Local layerColor:Int = (Int(255 * $1000000) + Int((50 + i*10) * $10000) + Int(100*(i mod 2) * $100) + Int(0))

			For local canvasX:Int = x until x + w
				For local canvasY:Int = y until y + h
					local value:Int
					If i < layers.length
						value = layers[i].layer.GetValue(canvasX - layers[i].offsetX, canvasY - layers[i].offsetY).value
					ElseIf dynamicIndex < layersDynamic.length
						value = layersDynamic[dynamicIndex].layer.GetValue(canvasX - layersDynamic[dynamicIndex].offsetX, canvasY - layersDynamic[dynamicIndex].offsetY).value
					EndIf
					if value > 0 
						pix.WritePixel(canvasX - x, canvasY - y, layerColor)
					EndIf
				Next
			Next
		Next
		return pix
	End Method	
End Type




Struct SPopulationCanvasLayerGetResult
	Field found:Int
	Field value:Int
End Struct




Enum EPopulationCanvasMode
	Add					'add the value
	Subtract			'subtract the value
	Multiply			'useful to reset to 0 if value in layer is 0
	AddBinary			'add the value: 1 if value<>0, 0 if value=0
	SubtractBinary		'subtract the value: 1 if value<>0, 0 if value=0
	MultiplyBinary		'multiply with 1 if value<>0 and with 0 if value=0
	AlphaMask			'amount of the value 0=0%, 255=100%
	NegativeAlphaMask	'amount of the value 0=100%, 255=0%
	ClipSmaller         'set values smaller than "value" to 0
	ClipBigger          'set values bigger than "value" to 0
	ClipBinary          'set values unequal to "value" to 0, equal to 1 
	ClipNegativeBinary  'set values equal to "value" to 0, unequal to 0
	MaskOut             'set result to 0 if this layer contains a value
	MaskExclusiveCoverage 'only keep from this layer what is set here but not in others
	MaskedAdd           'add value if result of "other" layers is <> 0 (useful to build "unions")
	NegativeMaskedAdd   'add value if result of "other" layers is 0
'====
'TODO: measure if "Multiply" is similar fast
'====
	BinaryMask          'amount of the value 0=0%, all others 100%
	NegativeBinaryMask  'amount of the value 0=100%, all others 0%  (useful to "mask out")
End Enum




Type TPopulationCanvasLayer
	Field x:Int, y:Int, x2:Int, y2:Int
	Field value:Int
	'returns either 0 for values = 0 and 1 for values > 0
	Field binaryMode:Int = False
	Field accessMutex:TMutex = CreateMutex()
	Field autoUseAccessMutex:Int = True


	Method Clear()
		'Multithread-safe
		AtomicSwap(self.value, 0)
	End Method
	
	
	Method CreatePixmapFromLayer:TPixmap(offsetX:Int = 0, offsetY:Int = 0, ignoreLocalOffset:int = True)
		'ensure we refreshed boundaries
		UpdateLayerBoundaries()
		
		Local pix:TPixmap
		if ignoreLocalOffset
			pix = CreatePixmap(self.x2 - self.x + offsetX, self.y2 - self.y + offsetY, PF_RGBA8888)
		else
			pix = CreatePixmap(self.x2 + offsetX, self.y2 + offsetY, PF_RGBA8888)
		endif
		pix.ClearPixels(0)
		Local white:Int = $ffffffff

		if ignoreLocalOffset
			For local canvasX:Int = self.x to self.x2
				For local canvasY:Int = self.y to self.y2
					if GetValue(canvasX, canvasY).value > 0
						pix.WritePixel(canvasX - self.x + offsetX, canvasY - self.y + offsetY, white)
					EndIf
				Next
			Next
		Else
			For local canvasX:Int = self.x to self.x2
				For local canvasY:Int = self.y to self.y2
					if GetValue(canvasX, canvasY).value > 0
						pix.WritePixel(canvasX + offsetX, canvasY + offsetY, white)
					EndIf
				Next
			Next
		EndIf
		return pix
	End Method
	

	Method UpdateLayerBoundaries(x:Int, y:Int, x2:Int, y2:Int)
		if self.x > x then self.x = x
		if self.y > y then self.y = y
		if self.x2 <= x2 then self.x2 = x2 + 1
		if self.y2 <= y2 then self.y2 = y2 + 1
	End Method

	'refresh boundary caches?
	Method UpdateLayerBoundaries()
	End Method
	
	
	Method LockConcurrentModification(on:int = True)
		If on
			LockMutex(accessMutex)
			autoUseAccessMutex = False
		Else
			autoUseAccessMutex = True
			UnlockMutex(accessMutex)
		EndIf
	End Method


	Method GetValue:SPopulationCanvasLayerGetResult()
		Local result:SPopulationCanvasLayerGetResult
		result.found = True
		If binaryMode
			result.value = value<>0
		Else
			result.value = value
		EndIf
		Return result
	End Method


	Method GetValue:SPopulationCanvasLayerGetResult(x:Int, y:Int)
		Local result:SPopulationCanvasLayerGetResult
		If x < self.x or x >= self.x2 or y < self.y or y >= self.y2
			result.found = False
		Else
			result.found = True
		EndIf

		If binaryMode
			result.value = self.value<>0
		Else
			result.value = self.value
		EndIf
		Return result
	End Method


	Method GetValue:SPopulationCanvasLayerGetResult(points:SVec2I[])
		'LockMutex(accessMutex)
		Local result:SPopulationCanvasLayerGetResult
		result.found = True
		If binaryMode
			result.value = self.value<>0
		Else
			result.value = self.value
		EndIf
		'UnlockMutex(accessMutex)
		Return result
	End Method


	Method SetValue(value:Int)
		'Multithread-safe
		AtomicSwap(self.value, value)
'		Self.value = value
	End Method


	Method AddValue(value:Int)
		'Multithread-safe
		AtomicAdd(self.value, value)
	End Method


	Method SetValue(value:Int, x:Int, y:Int)
		Throw "Not implemented"
	End Method


	Method AddValue(value:Int, x:Int, y:Int)
		Throw "Not implemented"
	End Method


	Method SetValue(value:Int, points:SVec2I[])
		Throw "Not implemented"
	End Method


	Method AddValue(value:Int, points:SVec2I[])
		Throw "Not implemented"
	End Method


	Method SetValue(value:Int, x:Int, y:Int, radius:Int)
		Throw "Not implemented"
	End Method


	Method AddValue(value:Int, x:Int, y:Int, radius:Int)
		Throw "Not implemented"
	End Method


	Method SetValue(value:TPixmap, x:Int, y:Int, rgbaChannelIndex:Int = 3)
		Throw "Not implemented"
	End Method


	Method AddValue(value:TPixmap, x:Int, y:Int, rgbaChannelIndex:Int = 3)
		Throw "Not implemented"
	End Method
End Type


Type TPopulationCanvasLayer_Map extends TPopulationCanvasLayer
	Field map:TLongIntMap = New TLongIntMap


	Method Clear() override
		LockMutex(accessMutex)
		map.Clear()
		UnlockMutex(accessMutex)
	End Method


	Method SetValue(value:Int, x:Int, y:Int) override
		if x < 0 or y < 0 then Return

		LockMutex(accessMutex)

		UpdateLayerBoundaries(x, y, x, y)

		map.Insert(GeneratePositionKey(x, y), value)

		UnlockMutex(accessMutex)
	End Method


	Method AddValue(value:Int, x:Int, y:Int) override
		if x < 0 or y < 0 then Return

		LockMutex(accessMutex)

		UpdateLayerBoundaries(x, y, x, y)

		Local key:Long = GeneratePositionKey(x, y)
		map.Insert(key, map.ValueForKey(key) + value)

		UnlockMutex(accessMutex)
	End Method


	Method SetValue(value:Int, x:Int, y:Int, radius:Int)
		LockMutex(accessMutex)
		Local circleRectX:Int = x - radius
		Local circleRectY:Int = y - radius
		Local circleRectX2:Int = x + radius
		Local circleRectY2:Int = y + radius
		'limit to >= 0,0
		if circleRectX < 0 Then circleRectX = 0
		if circleRectY < 0 Then circleRectY = 0

		'update layer boundaries
		UpdateLayerBoundaries(circleRectX, circleRectY, circleRectX2, circleRectY2)

		Local radiusSquared:Int = radius*radius
		For local circleY:Int = circleRectY To circleRectY2
			For local circleX:Int = circleRectX To circleRectX2
				'left the circle?
				If ((circleX - x)*(circleX - x)) + ((circleY - y)*(circleY - y)) > radiusSquared Then Continue
				map.Insert(GeneratePositionKey(circleX, circleY), value)
			Next
		Next

		UnlockMutex(accessMutex)
	End Method


	Method AddValue(value:Int, x:Int, y:Int, radius:Int)
		LockMutex(accessMutex)
		Local circleRectX:Int = x - radius
		Local circleRectY:Int = y - radius
		Local circleRectX2:Int = x + radius
		Local circleRectY2:Int = y + radius
		'limit to >= 0,0
		if circleRectX < 0 Then circleRectX = 0
		if circleRectY < 0 Then circleRectY = 0

		'update layer boundaries
		UpdateLayerBoundaries(circleRectX, circleRectY, circleRectX2, circleRectY2)

		Local radiusSquared:Int = radius*radius
		For local circleY:Int = circleRectY To circleRectY2
			For local circleX:Int = circleRectX To circleRectX2
				'left the circle?
				If ((circleX - x)*(circleX - x)) + ((circleY - y)*(circleY - y)) > radiusSquared Then Continue

				Local key:Long = GeneratePositionKey(circleX, circleY)
				map.Insert(key, map.ValueForKey(key) + value)
			Next
		Next

		UnlockMutex(accessMutex)
	End Method


	Method GetValue:SPopulationCanvasLayerGetResult(x:Int, y:Int) override
		Local result:SPopulationCanvasLayerGetResult
		result.found = False
		if x < 0 or y < 0 then Return result

		If x < self.x or x >= self.x2 or y < self.y or y >= self.y2
			Return result
		Else
			Local useMutex:Int = autoUseAccessMutex 
			If useMutex Then LockMutex(accessMutex)
			result.found = True
			result.value = map.ValueForKey(GeneratePositionKey(x, y))
			If binaryMode Then result.value = result.value<>0

			If useMutex Then UnlockMutex(accessMutex)
			Return result
		Endif
	End Method


	Function GeneratePositionKey:Long(X:Int, Y:Int)
		Return Long(X) Shl 32 | Long(Y)
	End Function


	Function SplitPositionKey(key:Long, X:Int Var, Y:Int Var)
		X = Int(key Shr 32)
		Y = key & $ffffffff
	End Function
End Type




Type TPopulationCanvasLayer_2DByteArray extends TPopulationCanvasLayer
	Field data:Byte Ptr
	Field dataW:Int
	Field dataH:Int
	Field capacity:Size_T


	Method Clear() override
		RemoveData()
	End Method


	Method ResizeData(w:int, h:int, allowShrink:Int = False)
		if w < dataW or h < dataH and not allowShrink Then Return
		if w = dataW and h = dataW then Return
		if w = 0 or h = 0 Then RemoveData(); Return

		LockMutex(accessMutex)

		'define how wide a line to copy "is", and how many
		'lines to copy
		Local copyW:int = dataW
		Local copyH:int = dataH
		if w < dataW then copyW = w
		if h < dataH then copyH = h


		'copy old data into new - line by line
		Local newCapacity:Size_T = w * h
		Local newData:Byte Ptr = MemAlloc(newCapacity)
		'ensure 0 is written there
		MemClear(newData, newCapacity)
		If dataW > 0 and dataH > 0
			'print "Resize w="+w +" h="+h
			For Local dataY:Int = 0 Until copyH
				'source and target y-lines
				Local dataYPtr:Byte Ptr = data + dataY * dataW
				Local newDataYPtr:Byte Ptr = newData + dataY * w
				'copy into
				MemCopy(newDataYPtr, dataYPtr, Size_T(copyW * sizeof(1:byte)))
			Next
			RemoveData()
		'Else
		'	print "Resize w="+w +" h="+h + " (new datablock)"
		EndIf

		data = newData
		dataW = w
		dataH = h
		capacity = newCapacity

		UnlockMutex(accessMutex)
	End Method


	Method InitData(w:Int, h:Int)
		LockMutex(accessMutex)

		RemoveData()
		self.dataW = w
		self.dataH = h
		self.capacity = w * h
		self.data = MemAlloc( capacity )
	
		UnlockMutex(accessMutex)
	End Method


	Method RemoveData()
		lockMutex(accessMutex)
		If capacity >= 0 Then MemFree(data)
		capacity = 0
		dataW = 0
		dataH = 0
		UnlockMutex(accessMutex)
	End Method

	
	Method Delete()
		RemoveData()
	End Method


	Method EnsureDataSize(expectMoreResizes:Int = True)
		If dataW < self.x2 - self.x or dataH < self.y2 - self.y
			Local oldW:Int = dataW
			Local oldH:Int = dataH
			'if there is more to expect then already resize to a bigger dimension
			'to avoid resizes for each tiny added row or column
			If expectMoreResizes
				ResizeData((self.x2 - self.x) * 3 / 2, (self.y2 - self.y) * 3 / 2)
			Else
				ResizeData((self.x2 - self.x), (self.y2 - self.y))
			Endif
			'print "EnsureDataSize: " + oldW+"x"+oldH +" -> " + dataW+"x"+dataH
		EndIf
	End Method


	Method SetValue(value:Int, x:Int, y:Int) override
		if x < 0 or y < 0 then Return

		LockMutex(accessMutex)
		UpdateLayerBoundaries(x, y, x, y)
		EnsureDataSize(True)

		Local valuePtr:Byte Ptr = data + (y - self.y) * dataW + (x - self.x)
		valuePtr[0] = Byte(value)

		UnlockMutex(accessMutex)
	End Method


	Method AddValue(value:Int, x:Int, y:Int) override
		if x < 0 or y < 0 then Return

		LockMutex(accessMutex)
		UpdateLayerBoundaries(x, y, x, y)
		EnsureDataSize(True)

		'attention: counting more than 255 antennas (most probably of the same player)
		'on this spot is not possible
		Local valuePtr:Byte Ptr = data + (y - self.y) * dataW + (x - self.x)
		If valuePtr[0] + Byte(value) > 255 Then 
			valuePtr[0] = 255
		Else
			valuePtr[0] = valuePtr[0] + Byte(value)
		EndIf

		UnlockMutex(accessMutex)
	End Method


	Method SetValue(value:TPixmap, x:Int, y:Int, rgbaChannelIndex:Int = 3) override
		If not value or value.width = 0 or value.height = 0 Then Return
		LockMutex(accessMutex)

		UpdateLayerBoundaries(x, y, x + value.width - 1, y + value.height - 1)
		EnsureDataSize(False)

		Local localX:Int = x - self.x
		Local localY:Int = y - self.y

		Local bytesPerPixel:Int = BytesPerPixel[value.format]

		Select value.format
			Case PF_A8
				For local pixX:Int = 0 until value.width
					For local pixY:Int = 0 until value.height
						Local sourcePtr:Byte Ptr = value.pixels + pixY * value.pitch + pixX * bytesPerPixel
						Local valuePtr:Byte Ptr = data + (localY + pixY) * dataW + (localX + pixX)
						valuePtr[0] = sourcePtr[0]
					Next
				Next 
			Case PF_RGBA8888
				'store alpha component
				For local pixX:Int = 0 until value.width
					For local pixY:Int = 0 until value.height
						Local sourcePtr:Byte Ptr = value.pixels + pixY * value.pitch + pixX * bytesPerPixel
						Local valuePtr:Byte Ptr = data + (localY + pixY) * dataW + (localX + pixX)
						valuePtr[0] = sourcePtr[rgbaChannelIndex] & $ff
					Next
				Next 
			Default
				Throw "unsupported TPixmap-format. Only PF_A8 or PF_RGBA8888 supported."
		End Select
	
		UnlockMutex(accessMutex)
	End Method


	Method AddValue(value:TPixmap, x:Int, y:Int, rgbaChannelIndex:Int = 3) override
		If not value or value.width = 0 or value.height = 0 Then Return
		LockMutex(accessMutex)

		UpdateLayerBoundaries(x, y, x + value.width - 1, y + value.height - 1)
		EnsureDataSize(False)

		Local localX:Int = x - self.x
		Local localY:Int = y - self.y

		Local bytesPerPixel:Int = BytesPerPixel[value.format]

		Select value.format
			Case PF_A8
				For local pixX:Int = 0 until value.width
					For local pixY:Int = 0 until value.height
						Local sourcePtr:Byte Ptr = value.pixels + pixY * value.pitch + pixX * bytesPerPixel
						Local valuePtr:Byte Ptr = data + (localY + pixY) * dataW + (localX + pixX)
						valuePtr[0] = sourcePtr[0]
						If valuePtr[0] + sourcePtr[0] > 255 Then 
							valuePtr[0] = 255
						Else
							valuePtr[0] = valuePtr[0] + sourcePtr[0]
						EndIf
					Next
				Next 
			Case PF_RGBA8888
				'store alpha component
				For local pixX:Int = 0 until value.width
					For local pixY:Int = 0 until value.height
						Local sourcePtr:Byte Ptr = value.pixels + pixY * value.pitch + pixX * bytesPerPixel
						Local valuePtr:Byte Ptr = data + (localY + pixY) * dataW + (localX + pixX)
						Local value:Byte = sourcePtr[rgbaChannelIndex] & $ff
						If valuePtr[0] + value > 255 Then 
							valuePtr[0] = 255
						Else
							valuePtr[0] = valuePtr[0] + value
						EndIf
					Next
				Next 
			Default
				Throw "unsupported TPixmap-format. Only PF_A8 or PF_RGBA8888 supported."
		End Select
	
		UnlockMutex(accessMutex)
	End Method

	Method SetValue(value:Int, x:Int, y:Int, radius:Int)
		LockMutex(accessMutex)
		'screen positions, not local ones!
		Local circleRectX:Int = x - radius
		Local circleRectY:Int = y - radius
		Local circleRectX2:Int = x + radius
		Local circleRectY2:Int = y + radius
		'limit to >= 0,0
		if circleRectX < 0 Then circleRectX = 0
		if circleRectY < 0 Then circleRectY = 0

		UpdateLayerBoundaries(circleRectX, circleRectY, circleRectX2, circleRectY2)
		EnsureDataSize(True)

		Local radiusSquared:Int = radius*radius
		For local circleY:Int = circleRectY To circleRectY2
			For local circleX:Int = circleRectX To circleRectX2
				'left the circle?
				If ((circleX - x)*(circleX - x)) + ((circleY - y)*(circleY - y)) > radiusSquared Then Continue

				Local valuePtr:Byte Ptr = data + (circleY - self.y) * dataW + (circleX - self.x)
'				print "x=" + circleX + " -> " + (circleX - self.x) + "  y=" + circleY + " -> " + (circleY - self.y)
				valuePtr[0] = Byte(value)
			Next
		Next
'		end

		UnlockMutex(accessMutex)
	End Method


	Method AddValue(value:Int, x:Int, y:Int, radius:Int)
		LockMutex(accessMutex)
		'screen positions, not local ones!
		Local circleRectX:Int = x - radius
		Local circleRectY:Int = y - radius
		Local circleRectX2:Int = x + radius
		Local circleRectY2:Int = y + radius
		'limit to >= 0,0
		if circleRectX < 0 Then circleRectX = 0
		if circleRectY < 0 Then circleRectY = 0

		UpdateLayerBoundaries(circleRectX, circleRectY, circleRectX2, circleRectY2)
		EnsureDataSize(True)

		Local radiusSquared:Int = radius*radius
		For local circleY:Int = circleRectY To circleRectY2
			For local circleX:Int = circleRectX To circleRectX2
				'left the circle?
				If ((circleX - x)*(circleX - x)) + ((circleY - y)*(circleY - y)) > radiusSquared Then Continue

				Local valuePtr:Byte Ptr = data + (circleY - self.y) * dataW + (circleX - self.x)
'				print "x=" + circleX + " -> " + (circleX - self.x) + "  y=" + circleY + " -> " + (circleY - self.y)
				If valuePtr[0] + value > 255 Then 
					valuePtr[0] = 255
				Else
					valuePtr[0] = valuePtr[0] + Byte(value)
				EndIf
			Next
		Next
'		end

		UnlockMutex(accessMutex)
	End Method


	Method GetValue:SPopulationCanvasLayerGetResult(x:Int, y:Int) override
		Local result:SPopulationCanvasLayerGetResult
		result.found = False
		if x < 0 or y < 0 then Return result

		If x < self.x or x >= self.x2 or y < self.y or y >= self.y2
			Return result
		Else
			Local useMutex:Int = autoUseAccessMutex 
			If useMutex Then LockMutex(accessMutex)

			result.found = True

			Local valuePtr:Byte Ptr = data + (y - self.y) * dataW + (x - self.x)
			result.value = valuePtr[0] ' Shl 24 | $00ffffff
			'print valuePtr[0]  +" -> " + (valuePtr[0] Shl 24 | $00ffffff)
			If binaryMode Then result.value = result.value<>0

			If useMutex Then UnLockMutex(accessMutex)
			Return result
		Endif
	End Method
End Type




Type TPopulationCanvasLayer_2DIntegerArray extends TPopulationCanvasLayer
	Field data:Int[]
	Field dataW:Int
	Field dataH:Int


	Method Clear() override
		RemoveData()
	End Method


	Method ResizeData(w:int, h:int, allowShrink:Int = False)
		if w < dataW or h < dataH and not allowShrink Then Return
		if w = dataW and h = dataW then Return
		if w = 0 or h = 0 Then RemoveData(); Return

		LockMutex(accessMutex)

		'define how wide a line to copy "is", and how many
		'lines to copy
		Local copyW:int = dataW
		Local copyH:int = dataH
		if w < dataW then copyW = w
		if h < dataH then copyH = h


		'copy old data into new - line by line
		Local dataPtr:Int Ptr = varptr data
		Local newData:int[] = New Int[w * h]
		Local newDataPtr:Int Ptr = varptr newData
		If dataW > 0 and dataH > 0
			'print "Resize  origDim=("+dataW+", "+dataH+") ->  newDim=("+w+", "+h+")  copyDim=(" + copyW+", "+copyH+")"
			For Local dataY:Int = 0 Until copyH
				'source and target y-lines
				Local dataYPtr:Int Ptr = dataPtr + dataY * dataW
				Local newDataYPtr:Int Ptr = newDataPtr + dataY * w
				'copy into
				MemCopy(newDataYPtr, dataYPtr, Size_T(copyW * sizeof(1:int)))
			Next
			RemoveData()
		Else
			'print "Resize w="+w +" h="+h + " (new datablock)"
		EndIf

		data = newData
		dataW = w
		dataH = h

		UnlockMutex(accessMutex)
	End Method


	Method InitData(w:Int, h:Int)
		LockMutex(accessMutex)

		RemoveData()
		self.dataW = w
		self.dataH = h
		self.data = New Int[w * h]
	
		UnlockMutex(accessMutex)
	End Method


	Method RemoveData()
		lockMutex(accessMutex)
		data = Null
		dataW = 0
		dataH = 0
		UnlockMutex(accessMutex)
	End Method

	
	Method Delete()
		RemoveData()
	End Method


	Method EnsureDataSize(expectMoreResizes:Int = True)
		If dataW < self.x2 - self.x or dataH < self.y2 - self.y
			Local oldW:Int = dataW
			Local oldH:Int = dataH
			'if there is more to expect then already resize to a bigger dimension
			'to avoid resizes for each tiny added row or column
			If expectMoreResizes
				ResizeData((self.x2 - self.x) * 3 / 2, (self.y2 - self.y) * 3 / 2)
			Else
				ResizeData((self.x2 - self.x), (self.y2 - self.y))
			Endif
			'print "EnsureDataSize: " + oldW+"x"+oldH +" -> " + dataW+"x"+dataH
		EndIf
	End Method


	Method SetValue(value:Int, x:Int, y:Int) override
		if x < 0 or y < 0 then Return

		LockMutex(accessMutex)
		UpdateLayerBoundaries(x, y, x, y)
		EnsureDataSize(True)

		Local dataPtr:Int Ptr = varptr data
		Local valuePtr:Int Ptr = dataPtr + ((y - self.y) * dataW + (x - self.x) )
		valuePtr[0] = value

		UnlockMutex(accessMutex)
	End Method


	Method AddValue(value:Int, x:Int, y:Int) override
		if x < 0 or y < 0 then Return

		LockMutex(accessMutex)
		UpdateLayerBoundaries(x, y, x, y)
		EnsureDataSize(True)

		Local dataPtr:Int Ptr = varptr data
		Local valuePtr:Int Ptr = dataPtr + ((y - self.y) * dataW + (x - self.x))
		valuePtr[0] = valuePtr[0] + value

		UnlockMutex(accessMutex)
	End Method


	Method SetValue(value:TPixmap, x:Int, y:Int, rgbaChannelIndex:Int = 3) override
		If not value or value.width = 0 or value.height = 0 Then Return
		LockMutex(accessMutex)

		UpdateLayerBoundaries(x, y, x + value.width - 1, y + value.height - 1)
		EnsureDataSize(False)

		Local localX:Int = x - self.x
		Local localY:Int = y - self.y

		Local bytesPerPixel:Int = BytesPerPixel[value.format]
		Local dataPtr:Int Ptr = varptr data

		Select value.format
			Case PF_A8
				For local pixX:Int = 0 until value.width
					For local pixY:Int = 0 until value.height
						Local sourcePtr:Byte Ptr = value.pixels + pixY * value.pitch + pixX * bytesPerPixel
						Local valuePtr:Int Ptr = dataPtr + (localY + pixY) * dataW + (localX + pixX)
						valuePtr[0] = Int(sourcePtr[0])
					Next
				Next 
			Case PF_RGBA8888
				'store alpha component
				For local pixX:Int = 0 until value.width
					For local pixY:Int = 0 until value.height
						Local sourcePtr:Byte Ptr = value.pixels + pixY * value.pitch + pixX * bytesPerPixel
						Local valuePtr:Int Ptr = dataPtr + (localY + pixY) * dataW + (localX + pixX)
						valuePtr[0] = Int(sourcePtr[rgbaChannelIndex] & $ff)
					Next
				Next 
			Default
				Throw "unsupported TPixmap-format. Only PF_A8 or PF_RGBA8888 supported."
		End Select
	
		UnlockMutex(accessMutex)
	End Method


	Method AddValue(value:TPixmap, x:Int, y:Int, rgbaChannelIndex:Int = 3) override
		If not value or value.width = 0 or value.height = 0 Then Return
		LockMutex(accessMutex)

		UpdateLayerBoundaries(x, y, x + value.width - 1, y + value.height - 1)
		EnsureDataSize(False)

		Local localX:Int = x - self.x
		Local localY:Int = y - self.y

		Local bytesPerPixel:Int = BytesPerPixel[value.format]
		Local dataPtr:Int Ptr = varptr data

		Select value.format
			Case PF_A8
				For local pixX:Int = 0 until value.width
					For local pixY:Int = 0 until value.height
						Local sourcePtr:Byte Ptr = value.pixels + pixY * value.pitch + pixX * bytesPerPixel
						Local valuePtr:Int Ptr = dataPtr + (localY + pixY) * dataW + (localX + pixX)
						valuePtr[0] = valuePtr[0] + sourcePtr[0]
					Next
				Next 
			Case PF_RGBA8888
				'store alpha component
				For local pixX:Int = 0 until value.width
					For local pixY:Int = 0 until value.height
						Local sourcePtr:Byte Ptr = value.pixels + pixY * value.pitch + pixX * bytesPerPixel
						Local valuePtr:Int Ptr = dataPtr + (localY + pixY) * dataW + (localX + pixX)
						valuePtr[0] = valuePtr[0] + (sourcePtr[rgbaChannelIndex] & $ff)
					Next
				Next 
			Default
				Throw "unsupported TPixmap-format. Only PF_A8 or PF_RGBA8888 supported."
		End Select
	
		UnlockMutex(accessMutex)
	End Method

	Method SetValue(value:Int, x:Int, y:Int, radius:Int)
		LockMutex(accessMutex)
		'screen positions, not local ones!
		Local circleRectX:Int = x - radius
		Local circleRectY:Int = y - radius
		Local circleRectX2:Int = x + radius
		Local circleRectY2:Int = y + radius
		'limit to >= 0,0
		if circleRectX < 0 Then circleRectX = 0
		if circleRectY < 0 Then circleRectY = 0

		UpdateLayerBoundaries(circleRectX, circleRectY, circleRectX2, circleRectY2)
		EnsureDataSize(True)

		Local dataPtr:Int Ptr = varptr data
		Local radiusSquared:Int = radius*radius
		For local circleY:Int = circleRectY To circleRectY2
			For local circleX:Int = circleRectX To circleRectX2
				'left the circle?
				If ((circleX - x)*(circleX - x)) + ((circleY - y)*(circleY - y)) > radiusSquared Then Continue

				Local valuePtr:Int Ptr = dataPtr + (circleY - self.y) * dataW + (circleX - self.x)
'				print "x=" + circleX + " -> " + (circleX - self.x) + "  y=" + circleY + " -> " + (circleY - self.y)
				valuePtr[0] = value
			Next
		Next
'		end

		UnlockMutex(accessMutex)
	End Method


	Method AddValue(value:Int, x:Int, y:Int, radius:Int)
		LockMutex(accessMutex)
		'screen positions, not local ones!
		Local circleRectX:Int = x - radius
		Local circleRectY:Int = y - radius
		Local circleRectX2:Int = x + radius
		Local circleRectY2:Int = y + radius
		'limit to >= 0,0
		if circleRectX < 0 Then circleRectX = 0
		if circleRectY < 0 Then circleRectY = 0

		UpdateLayerBoundaries(circleRectX, circleRectY, circleRectX2, circleRectY2)
		EnsureDataSize(True)

		Local dataPtr:Int Ptr = varptr data
		Local radiusSquared:Int = radius*radius
		For local circleY:Int = circleRectY To circleRectY2
			For local circleX:Int = circleRectX To circleRectX2
				'left the circle?
				If ((circleX - x)*(circleX - x)) + ((circleY - y)*(circleY - y)) > radiusSquared Then Continue

				Local valuePtr:Int Ptr = dataPtr + (circleY - self.y) * dataW + (circleX - self.x)
'				print "x=" + circleX + " -> " + (circleX - self.x) + "  y=" + circleY + " -> " + (circleY - self.y)
				valuePtr[0] = valuePtr[0] + value
			Next
		Next
'		end

		UnlockMutex(accessMutex)
	End Method


	Method GetValue:SPopulationCanvasLayerGetResult(x:Int, y:Int) override
		Local result:SPopulationCanvasLayerGetResult
		result.found = False
		'if x < 0 or y < 0 then Return result

		If x < self.x or x >= self.x2 or y < self.y or y >= self.y2
			Return result
		Else
			Local useMutex:Int = autoUseAccessMutex 
			If useMutex Then LockMutex(accessMutex)
	
			result.found = True

			Local dataPtr:Int Ptr = varptr data
			Local valuePtr:Int Ptr = dataPtr + (y - self.y) * dataW + (x - self.x)
			result.value = valuePtr[0]
			'print valuePtr[0]  +" -> " + (valuePtr[0] Shl 24 | $00ffffff)
			If binaryMode Then result.value = result.value<>0

			If useMutex Then UnLockMutex(accessMutex)
			Return result
		Endif
	End Method
End Type




'only works for a SINGLE circle (as we cannot leightweightly calculate
'overlaps)
Type TPopulationCanvasLayer_Circle extends TPopulationCanvasLayer
	Field circleX:Int
	Field circleY:Int
	Field circleR:Int = -1
	Field circleV:Int



	Method SetValue(value:Int, x:Int, y:Int) override
		Throw "Setting a canvas-circle value is not possible."
	End Method


	Method AddValue(value:Int, x:Int, y:Int) override
		Throw "Adding a canvas-circle value is not possible."
	End Method


	Method SetValue(value:TPixmap, x:Int, y:Int, rgbaChannelIndex:Int = 3) override
		Throw "Setting a canvas-circle pixmap value is not possible."
	End Method


	Method AddValue(value:TPixmap, x:Int, y:Int, rgbaChannelIndex:Int = 3) override
		Throw "Adding a canvas-circle pixmap value is not possible."
	End Method


	Method SetValue(value:Int, x:Int, y:Int, radius:Int)
		UpdateLayerBoundaries(x - radius, y - radius, x + radius, y + radius)

		circleX = x
		circleY = y
		circleR = radius
		circleV = value
	End Method


	Method AddValue(value:Int, x:Int, y:Int, radius:Int)
		UpdateLayerBoundaries(x - radius, y - radius, x + radius, y + radius)

		If circleX = x and circleY = y and circleR = radius 
			circleV :+ value
		Else
			circleX = x
			circleY = y
			circleR = radius
			circleV = value
		EndIf
	End Method


	Method GetValue:SPopulationCanvasLayerGetResult(x:Int, y:Int) override
		Local result:SPopulationCanvasLayerGetResult

		'no circle defined?
		If circleR < 0 then Return result

		'x,y outside of circle?
		If circleR^2 < (x - circleX)^2 + (y - circleY)^2 Then Return result

		result.found = True
		result.value = circleV
		Return result
	End Method


	Method GetValue:SPopulationCanvasLayerGetResult()
		Local result:SPopulationCanvasLayerGetResult
		'no circle defined?
		If circleR < 0 then Return result
		
		result.found = True
		result.value = Int(circleR^2 * PI)
		Return result
	End Method


	Method GetValue:SPopulationCanvasLayerGetResult(points:SVec2I[])
		Local result:SPopulationCanvasLayerGetResult

		'no circle defined?
		If circleR < 0 then Return result

		For local p:SVec2I = EachIn points
			'x,y outside of circle?
			If circleR^2 < (p.x - circleX)^2 + (p.y - circleY)^2 Then continue
			
			result.found = True
			result.value :+ circleV
		Next
		Return result
	End Method
End Type




Type TPopulationCanvasLayer_Canvas extends TPopulationCanvasLayer
	Field canvas:TPopulationCanvas


	Method New(canvas:TPopulationCanvas)
		self.canvas = canvas
	End Method


	'refresh boundary caches?
	Method UpdateLayerBoundaries() override
		if canvas
			Local x:Int, y:Int, w:int, h:int
			canvas.GetUsedArea(x, y, w, h)
			self.x = x
			self.y = y
			self.x2 = x + w 
			self.y2 = y + h 
		EndIf
	End Method

	
	Method SetValue(value:Int, x:Int, y:Int) override
		Throw "Setting a canvas-canvaslayer value is not possible."
	End Method


	Method AddValue(value:Int, x:Int, y:Int) override
		Throw "Adding a canvas-canvaslayer value is not possible."
	End Method


	Method SetValue(value:TPixmap, x:Int, y:Int, rgbaChannelIndex:Int = 3) override
		Throw "Setting a canvas-canvaslayer value is not possible."
	End Method


	Method AddValue(value:TPixmap, x:Int, y:Int, rgbaChannelIndex:Int = 3) override
		Throw "Adding a canvas-canvaslayer value is not possible."
	End Method

	Method SetValue(value:Int, x:Int, y:Int, radius:Int)
		Throw "Setting a canvas-canvaslayer value is not possible."
	End Method


	Method AddValue(value:Int, x:Int, y:Int, radius:Int)
		Throw "Adding a canvas-canvaslayer value is not possible."
	End Method


	Method GetValue:SPopulationCanvasLayerGetResult(x:Int, y:Int) override
		Local result:SPopulationCanvasLayerGetResult
		If not canvas
			result.found = False
		Else
			result.found = True
			result.value = canvas.GetValue(x, y)
		EndIf
		Return result
	End Method


	Method GetValue:SPopulationCanvasLayerGetResult()
		Local result:SPopulationCanvasLayerGetResult
		If not canvas
			result.found = False
		Else
			result.found = True
			result.value = canvas.GetValue()
		EndIf
		Return result
	End Method


	Method GetValue:SPopulationCanvasLayerGetResult(points:SVec2I[])
		Local result:SPopulationCanvasLayerGetResult
		If not canvas
			result.found = False
		Else
			result.found = True
			For local p:SVec2I = EachIn points
				result.value :+ canvas.GetValue(p.x, p.y)
			Next
		EndIf
		Return result
	End Method
End Type


