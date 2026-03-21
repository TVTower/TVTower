SuperStrict
Framework SDL.sdlrendermax2d
Import Brl.standardio
Import "../source/Dig/base.util.graphicsmanager.bmx"
Import "../source/Dig/base.util.input.bmx"
Import "../source/Dig/base.gfx.bitmapfont.bmx"
Import "../source/Dig/base.util.helper.bmx"
Import "../source/basefunctions.bmx"

GetGraphicsManager().SetDesignedSize(1000, 800)
GetGraphicsManager().SetScaleQuality(1) 'default to smooth
GetGraphicsManager().InitGraphics(1000, 800)


Global dataChart:TDataChart
dataChart = new TDataChart
dataChart.SetPosition(25, 282)
dataChart.SetDimension(750, 90)
dataChart.SetXSegmentsCount(24)

dataChart.valueFormat = "convertvalue"

'news
dataChart.AddDataSet(new TDataChartDataSet, New TDataChartDataSetConfig(SColor8.red), new SVec2D(-5, 0))
dataChart.GetDataSet(0).SetDataCount(26) '26 to have one earlier and later (-1 to 25)
'programmes
dataChart.AddDataSet(new TDataChartDataSet, New TDataChartDataSetConfig(SColor8.blue), new SVec2D(5, 0))
dataChart.GetDataSet(1).SetDataCount(26)

dataChart.SetXRange(0, 24)

For local i:int = 0 until 24
	dataChart.SetXSegmentLabel(i, i)
Next

'5 markieren
dataChart.SetCurrentSegment( 5 )

For local i:Int = 0 Until 26
	dataChart.GetDataSet(0).SetDataEntry(i + 1, i + 0.2, i * 5)
	dataChart.GetDataSet(1).SetDataEntry(i + 1, i + 0.5, Rand(50))
Next



While Not KeyDown(KEY_ESCAPE)
	Cls
	MouseManager.Update()

	SetColor 120, 120, 120
	DrawRect( 0, 0, GetGraphicsManager().GetWidth(), GetGraphicsManager().GetHeight() )

	dataChart.Update()
	dataChart.Render()

	SetAlpha 1.0
	SetColor( SColor8.white )

	DrawOval(MouseManager.currentPos.x - 5, MouseManager.currentPos.y - 5, 10, 10)

	Flip
Wend






Type TDataChartDataSet
	Field points:SVec2D[]
	Field minimumY:Float
	Field maximumY:Float
	Field maximumAtIndex:Int
	Field minimumAtIndex:Int
	Field _cacheValid:Int = False



	Method UpdateCache()
		'TODO: max/min fuer derzeitig angezeigte Werte/Viewport
		If points.length > 0
			maximumY = points[0].y
			minimumY = points[0].y
			maximumAtIndex = 0
			minimumAtIndex = 0

			For Local i:int = 0 until points.length
				if not points[i] then continue

				If maximumY < points[i].y
					maximumAtIndex = i
					maximumY = points[i].y
				EndIf
				If minimumY > points[i].y
					minimumAtIndex = i
					minimumY = points[i].y
				EndIf
			Next
		EndIf

		_cacheValid = True
	End Method


	Method GetMinimumY:Float()
		If Not _cacheValid Then UpdateCache()
		return minimumY
	End Method


	Method GetMaximumY:Float()
		If Not _cacheValid Then UpdateCache()
		return maximumY
	End Method


	Method ClearData:TDataChartDataSet()
		points = new SVec2D[ points.length ]

		_cacheValid = False

		Return self
	End Method


	Method SetData:TDataChartDataSet(points:SVec2D[])
		self.points = points

		_cacheValid = False

		Return Self
	End Method


	Method SetDataCount:TDataChartDataSet(count:Int)
		'extend and keep existing?
		If points
			If count <> points.length
				points = points[ .. count]
				_cacheValid = False
			EndIf
		Else
			points = new SVec2D[count]
			_cacheValid = False
		EndIf

		Return Self
	End Method


	Method SetDataEntry:TDataChartDataSet(index:Int, x:Float, y:Float)
		if points.length <= index or index < 0 then Return Self

		points[index] = new SVec2D(x,y)

		_cacheValid = False

		Return Self
	End Method


	Method SetDataEntry:TDataChartDataSet(index:Int, point:SVec2D)
		if points.length <= index or index < 0 then Return Self

		points[index] = point

		_cacheValid = False

		Return Self
	End Method

End Type




Type TDataChartDataSetConfig
	'rendering enabled?
	Field display:Int = True
	'eg. not displayed but constant y-axis
	Field affectsMinMaxY:Int = True

	Field color:SColor8 = SColor8.white
	Field secondaryColor:SColor8 = SColor8.white


	Method New(color:SColor8)
		SetColor(color, True)
	End Method


	Method SetColor:TDataChartDataSetConfig(color:SColor8, calculateSecondaryColor:Int = False)
		self.color = color

		' set secondary color to a darker one
		if calculateSecondaryColor
			local s:SColor8 = SColor8Helper.AdjustBrightness(color, -0.25)
			s = SColor8Helper.Multiply(s, 1.0, 1.0, 1.0, 0.5)
			self.secondaryColor = s
		EndIf

		Return self
	End Method

	Method SetSecondaryColor:TDataChartDataSetConfig(color:SColor8)
		self.secondaryColor = color
		return self
	End Method

	Method SetDisplay:TDataChartDataSetConfig(display:Int)
		self.display = display
		return self
	End Method

	Method SetAffectsMinMaxY:TDataChartDataSetConfig(affectsMinMaxY:Int)
		self.affectsMinMaxY = affectsMinMaxY
		return self
	End Method
End Type




Type TDataChart
	Field area:SRectI = new SRectI
	Field areaGraph:TRectangle = new TRectangle

	'x value limits (min-max)
	Field xRangeBegin:Float
	Field xRangeEnd:Float
	'begin/end indices for each dataset
	'they are depending on the currently set (visible) range
	Field xRangeDataIndexBegin:Int[]
	Field xRangeDataIndexEnd:Int[]
	'Field xRangeMinimum:Float
	'Field xRangeMaximum:Float

	'zoom factor, how many data points fit into one pixel
	'             or how many pixels are needed to show all data points
	Field _pixelsPerDataPointX:Float


	Field xSegmentsCount:int
	'width for all (if no individuals are set)
	Field xSegmentWidth:int = -1
	'width of the individual segments
	Field xSegmentWidths:int[]
	'start position of the individual segments
	Field xSegmentStarts:int[]
	Field xSegmentLabels:string[]
	'how many data blocks are _before_ the first
	Field xDataOffset:int = 1
	Field hoveredSegment:int = -1
	Field currentSegment:int = -1
	Field selectedSegment:int = -1
	Field dataSets:TDataChartDataSet[]
	Field dataSetConfigs:TDataChartDataSetConfig[]
	Field dataSetOffsets:SVec2D[]
	Field labelFont:TBitmapFont
	Field labelColor:SColor8 = new SColor8(120, 120, 120)
	Field labelColor2:SColor8 = new SColor8(80, 80, 80)

	'Field selectedColor:TColor = TColor.Create(200,200,200)
	Field selectedColor:SColor8 = new SColor8(185,200,255)
	Field hoveredColor:SColor8 = new SColor8(95,110,255)

	Field leftAxisLabelEnabled:int = True
	Field rightAxisLabelEnabled:int = True
	Field topAxisLabelEnabled:int = False
	Field bottomAxisLabelEnabled:int = True

	Field leftAxisLabelSize:int = 50
	Field rightAxisLabelSize:int = 50
	Field topAxisLabelSize:int = 15
	Field bottomAxisLabelSize:int = 15
	Field leftAxisLabelOffset:SVec2I = new SVec2I(0, 0)
	Field rightAxisLabelOffset:SVec2I = new SVec2I(4, -4)
	Field topAxisLabelOffset:SVec2I = new SVec2I(0, -2)
	Field bottomAxisLabelOffset:SVec2I = new SVec2I(0, 2)

	Field valueFormat:String = "%3.3f"
	Field valueDisplayMaximumY:Float
	Field valueDisplayMinimumY:Float

	'segment implicitly hovered if no other is hovered explicitly
	Field autoHoverSegment:Int = -1


	Method GetPixelsPerDataPointX:Float()
		If _pixelsPerDataPointX > 0
			return _pixelsPerDataPointX
		Else
			if (xRangeEnd - xRangeBegin) <> 0
				return abs((areaGraph.GetIntW() / Float(xRangeEnd - xRangeBegin)))
			else
				return area.w
			endif
		EndIf
	End Method


	Method SetPosition:TDataChart(x:int, y:int)
		area = New SRectI(x, y, area.w, area.h)

		Return self
	End Method


	Method SetDimension:TDataChart(w:int, h:int)
		area = New SRectI(area.x, area.y, w, h)

		_RefreshElementSizes()
		Return self
	End Method


	Method SetXRange(valueBegin:Float, valueEnd:Float)
		xRangeBegin = valueBegin
		xRangeEnd = valueEnd
	End Method


	Method SetXSegmentLabels:TDataChart(labels:string[])
		xSegmentLabels = labels

		Return self
	End Method


	Method SetXSegmentLabel:TDataChart(index:int, label:string)
		if index < 0 or index >= xSegmentLabels.length Then Return self
		xSegmentLabels[index] = label
	End Method


	Method SetXSegmentsCount:TDataChart(count:int)
		xSegmentsCount = count
		If xSegmentLabels.length <> count
			xSegmentLabels = xSegmentLabels[ .. xSegmentsCount]
			xSegmentWidths = xSegmentWidths[ .. xSegmentsCount]
			xSegmentStarts = xSegmentStarts[ .. xSegmentsCount]
		EndIf

		_RefreshElementSizes()
		Return self
	End Method


	Method _RefreshElementSizes()
		'update padding information
		local axisTop:int = topAxisLabelEnabled * topAxisLabelSize
		local axisLeft:int = leftAxisLabelEnabled * leftAxisLabelSize
		local axisBottom:int = bottomAxisLabelEnabled * bottomAxisLabelSize
		local axisRight:int = rightAxisLabelEnabled * rightAxisLabelSize

		'update graph area
		areaGraph.SetXYWH(axisLeft + 1, ..
		                  axisTop, ..
		                  area.w - (axisLeft + 1 + axisRight), ..
		                  area.h - (axisTop  + axisBottom + 1) ..
		                 )

		'resize segments
		'global
		xSegmentWidth = areaGraph.GetW() / xSegmentsCount
		'individual
		'TODO

		'add "skipped pixels" to right label area
		areaGraph.MoveW( -(areaGraph.w - xSegmentWidth * xSegmentsCount))
	End Method


	Method SetSegmentWidth(segmentIndex:int, width:int)
		if segmentIndex < 0 or segmentIndex >= xSegmentWidths.length then return

		xSegmentWidths[segmentIndex] = width
		'position this segment after the previous one
		if segmentIndex > 0
			xSegmentStarts[segmentIndex] = xSegmentStarts[segmentIndex -1] + GetSegmentWidth(segmentIndex -1)
		endif

		'reposition all elements afterwards
		if segmentIndex < xSegmentWidths.length-1
			'recursive called for all coming segments
			SetSegmentWidth(segmentIndex + 1, GetSegmentWidth(segmentIndex + 1))
		endif
	End Method


	Method GetSegmentWidth:int(segmentIndex:int)
		if segmentIndex < 0 or segmentIndex >= xSegmentWidths.length then return 0
		'fallback
		if xSegmentWidths[segmentIndex] <= 0 and xSegmentWidth > 0 then return xSegmentWidth
		'or use defined value
		return xSegmentWidths[segmentIndex]
	End Method


	Method GetSegmentStart:int(segmentIndex:int)
		if segmentIndex < 0 or not xSegmentStarts or segmentIndex >= xSegmentStarts.length then return 0

		'use auto-calculated value
		if xSegmentStarts[segmentIndex] <= 0
			if segmentIndex > 0
				return GetSegmentStart(segmentIndex -1) + GetSegmentWidth(segmentIndex -1)
			else
				return 0
			endif
		endif

		'or use defined value
		return xSegmentStarts[segmentIndex]
	End Method


	Method GetMinimumY:Float()
		if dataSets.length = 0 then return 0

		local m:Float = dataSets[0].GetMinimumY()
		For local ds:TDataChartDataSet = EachIn dataSets
			if m > ds.GetMinimumY() then m = ds.GetMinimumY()
		Next
		return m
	End Method


	Method GetMaximumY:Float()
		if dataSets.length = 0 then return 0

		local m:Float = dataSets[0].GetMaximumY()
		For local ds:TDataChartDataSet = EachIn dataSets
			if m < ds.GetMaximumY() then m = ds.GetMaximumY()
		Next
		return m
	End Method


	Method AddDataSet:TDataChart(dataSet:TDataChartDataSet)
		Local config:TDataChartDataSetConfig = New TDataChartDataSetConfig.SetColor(SColor8.Black, True)
		Return AddDataSet(dataSet, config, Null)
	End Method

	
	Method AddDataSet:TDataChart(dataSet:TDataChartDataSet, dataSetConfig:TDataChartDataSetConfig, offset:SVec2D)
		dataSets :+ [dataSet]
		dataSetConfigs :+ [dataSetConfig]
		dataSetOffsets :+ [offset]
		return self
	End Method


	Method SetDataSet:TDataChart(index:int, dataSet:TDataChartDataSet, dataSetConfig:TDataChartDataSetConfig, offset:SVec2D)
		if dataSets.length <= index
			dataSets = dataSets[ .. index]
			dataSetConfigs = dataSetConfigs[ .. index]
			dataSetOffsets = dataSetOffsets[ .. index]
		endif
		dataSets[index] = dataSet
		dataSetConfigs[index] = dataSetConfig
		dataSetOffsets[index] = offset
		return self
	End Method


	Method GetDataSet:TDataChartDataSet(index:int)
		If index < 0 Or index >= dataSets.length 
			Return Null
		Else
			Return dataSets[index]
		EndIf
	End Method	

	
	Method ClearDataSet:TDataChart(dataSetIndex:int = -1)
		if dataSetIndex < 0
			For local ds:TDataChartDataSet = EachIn dataSets
				ds.ClearData()
			Next
		elseif dataSetIndex < dataSets.length and dataSets[dataSetIndex]
			dataSets[dataSetIndex].ClearData()
		endif
		return self
	End Method


	'for current hour
	Method SetCurrentSegment:TDataChart(segmentIndex:int = -1)
		currentSegment = segmentIndex
		return self
	End Method


	Method SetSelectedSegment:TDataChart(segmentIndex:int = -1)
		selectedSegment = segmentIndex
		return self
	End Method


	Method SetHoveredSegment:TDataChart(segmentIndex:int = -1)
		hoveredSegment = segmentIndex
		return self
	End Method


	Method Update()
		hoveredSegment = -1

		If THelper.MouseIn(area)
			Local startX:int = area.x + areaGraph.GetX()
			For local i:int = 0 until xSegmentsCount
				If MouseManager.currentPos.x > startX and MouseManager.currentPos.x <= startX + xSegmentWidth
					SetHoveredSegment(i)

					If MouseManager.IsClicked(1)
						If selectedSegment = i
							SetSelectedSegment(-1)
						Else
							SetSelectedSegment(i)
						EndIf
						'handled single click
						MouseManager.SetClickHandled(1)
					EndIf

					exit
				EndIf
				startX :+ xSegmentWidth
			Next
		EndIf
		If hoveredSegment < 0 And selectedSegment < 0 And autoHoverSegment >= 0
			hoveredSegment = autoHoverSegment
		EndIf
	End Method


	Method Render()
		if not labelFont Then labelFont = GetBitmapFont("Default", 9)


		RenderBackground()
		RenderData()
		RenderTexts()
	End Method


	Method RenderBackground()
		Local x:int = area.x + areaGraph.GetIntX() - 1 '+-1 for the borders
		Local y:int = area.y + areaGraph.GetIntY() - 1
		Local w:int = areaGraph.GetIntW() + 2
		Local h:int = areaGraph.GetIntH() + 2
'		SetColor 255,0,0
'		DrawRect(x,y,w,h)
		SetColor 50,50,50
		DrawLine(x, y, x, y + h - 1)
		DrawLine(x, y + h - 1, x + w - 1, y + h - 1)
'print x+"  " + y + "  " + w + "  " + h
		SetColor 150,150,150
		DrawLine(x + w - 1, y + 1, x + w - 1, y + h - 2) '+2 and -2 to avoid overlap
		DrawLine(x + 1, y, x + w - 1, y) '+1 and -1 to avoid overlap
		SetColor 255,255,255


		for local i:int = 0 until xSegmentsCount
			SetColor 0,0,0
			if i mod 2 = 0
				SetAlpha 0.1
			else
				SetAlpha 0.05
			endif
			DrawRect(x + 1 + GetSegmentStart(i), y+1, GetSegmentWidth(i), h-2)
		next
		SetAlpha 1.0

		'hover states
		if hoveredSegment>=0 or selectedSegment>=0 or currentSegment>=0
			if currentSegment >= 0
				SetAlpha 0.10
				SetBlend LightBlend
				SetColor 255,255,255
				DrawRect(x + 1 + GetSegmentStart(currentSegment), y+1, GetSegmentWidth(currentSegment), h-2)
			endif
			'selected segment itself is hovered or no other segment is hovered
			if selectedSegment >= 0 And (hoveredSegment < 0 Or selectedSegment = hoveredSegment)
				SetAlpha 0.15
				SetBlend ShadeBlend
				SetColor(selectedColor)
				DrawRect(x + 1 + GetSegmentStart(selectedSegment), y+1, GetSegmentWidth(selectedSegment), h-2)
			endif
			if hoveredSegment >= 0
				SetAlpha 0.15
				SetBlend LightBlend
				SetColor(hoveredColor)
				DrawRect(x + 1 + GetSegmentStart(hoveredSegment), y+1, GetSegmentWidth(hoveredSegment), h-2)
			endif
			SetAlpha 1.0
			SetBlend AlphaBlend
		endif


		'splitter lines
		SetColor 150,150,150
'		SetAlpha 0.2
		For local i:int = 0 until xSegmentsCount - 1 'skip last
			DrawLine(x + GetSegmentStart(i+1), y + 1, x + GetSegmentStart(i+1), y + h - 2)
		Next
'		SetAlpha 1.0

		'draw arrows on axis
		SetColor 50,50,50
		DrawPoly([Float(x),Float(y), Float(x+4), Float(y+3), Float(x-2), Float(y+3)]) '+4 instead of +2 -- don't know why
		DrawPoly([Float(x+w),Float(y+h), Float(x+w-3), Float(y+h-2), Float(x+w-3), Float(y+h+2)])

		SetColor 255,255,255
	End Method


	Method RenderData()
		Local vp:SRectI = New SRectI(Int(areaGraph.x + area.x), Int(areaGraph.y + area.y), Int(areaGraph.w), Int(areaGraph.h))
		GetGraphicsManager().BackupAndSetViewport( vp )

		local shadowCol:TColor = TColor.Create(0,0,0)
		shadowCol.a = 0.3

		'shadow render
		For local dsIndex:int = 0 until dataSets.length
			RenderDataSet(dsIndex, 0, 1, shadowCol)
		Next

		'points render
		For local dsIndex:int = 0 until dataSets.length
			RenderDataSet(dsIndex, 0, 0)
		Next

		GetGraphicsManager().RestoreViewport()
	End Method


	Method RenderDataSet(dsIndex:int, xOffset:int=0, yOffset:int=0, colorOverride:TColor=Null)
		Local x:int = area.x + areaGraph.GetIntX()
		Local y:int = area.y + areaGraph.GetIntY()
		Local w:int = areaGraph.GetIntW()
		Local h:int = areaGraph.GetIntH()
		Local maximumY:Float = GetMaximumY()
		Local minimumY:Float = GetMinimumY()
		Local effectiveMaximumY:Float = 1.1 * maximumY
		Local oldCol:SColor8; GetColor(oldCol)
		Local oldColA:Float = GetAlpha()

		Local pixelsPerDataPointX:Float = GetPixelsPerDataPointX()

		Local baseDataPointX:Int = x ' + 0.5*pixelsPerDataPointX
		Local dataPointX:Float
		
		Local config:TDataChartDataSetConfig = dataSetConfigs[dsIndex]

		valueDisplayMaximumY = 1.1 * maximumY
		valueDisplayMinimumY = 0

		if dsindex >= 0 And dataSetOffsets.length > dsIndex
			x :+ dataSetOffsets[dsIndex].x
			y :+ dataSetOffsets[dsIndex].y
		endif

		'=== DOTS BG ===
		if colorOverride
			colorOverride.SetRGBA()
		else
			SetColor(config.secondaryColor, True)
		endif
		dataPointX = basedataPointX
		if dataSets[dsIndex]
			For Local i:int = xDataOffset until Min(xDataOffset + xSegmentsCount, dataSets[dsIndex].points.length)
				if not dataSets[dsIndex].points[i] then continue

				dataPointX = int(baseDataPointX + pixelsPerDataPointX * dataSets[dsIndex].points[i].x)

				DrawOval(xOffset + dataPointX -3, ..
						 yOffset + y + (1 - dataSets[dsIndex].points[i].y/valueDisplayMaximumY) * h -3, ..
						 7,7)
			Next
		endif

		'=== LINES ===
		'if drawConnected
		if colorOverride
			colorOverride.SetRGBA()
		else
			SetColor(config.secondaryColor, True)
		endif
		SetAlpha 0.5 * GetAlpha()
		SetLineWidth(2)
		GetGraphicsManager().EnableSmoothLines()
		if dataSets[dsIndex].points.length >= xDataOffset
			'for now: first must be present
			local lastX:Float = dataSets[dsIndex].points[0 + xDataOffset - 1].x
			local lastY:Float = dataSets[dsIndex].points[0 + xDataOffset - 1].y
			For Local i:int = xDataOffset to Min(xDataOffset + xSegmentsCount +1, dataSets[dsIndex].points.length-1)
				if not dataSets[dsIndex].points[i] then continue

				DrawLine(int(xOffset + baseDataPointX + pixelsPerDataPointX * lastX), ..
						 int(yOffset + y + (1 - lastY/valueDisplayMaximumY) * h), ..
						 int(xOffset + baseDataPointX + pixelsPerDataPointX * dataSets[dsIndex].points[i].x), ..
						 int(yOffset + y + (1 - dataSets[dsIndex].points[i].y/valueDisplayMaximumY) * h))
				lastX = dataSets[dsIndex].points[i].x
				lasty = dataSets[dsIndex].points[i].y
			Next
		endif
		SetLineWidth(1)
		SetAlpha 2 * GetAlpha()

		'endif


		'=== DOTS ===
		if colorOverride
			colorOverride.SetRGBA()
		else
			SetColor(config.secondaryColor, True)
		endif
		dataPointX = basedataPointX
		For Local i:int = xDataOffset until Min(xDataOffset + xSegmentsCount, dataSets[dsIndex].points.length)
			if not dataSets[dsIndex].points[i] then continue

			dataPointX = int(baseDataPointX + pixelsPerDataPointX * dataSets[dsIndex].points[i].x)
			DrawOval(xOffset + dataPointX -2, yOffset + y + (1 - dataSets[dsIndex].points[i].y/valueDisplayMaximumY) * h -2, 5,5)
		Next

		SetColor( oldCol )
		SetAlpha( oldColA )
	End Method


	Method RenderTexts()
		'segment labels
		Local bottomXLabelH:int = area.h - areaGraph.GetY2()
		Local x:int = area.x + areaGraph.GetIntX()
		Local x2:int = area.x + areaGraph.GetIntX2()

		Local col:SColor8
		For Local i:Int = 0 Until xSegmentsCount
			local dataIndex:int = i  + xDataOffset

			if xSegmentLabels.length > i and xSegmentLabels[i]
				if i = hoveredSegment
					col = hoveredColor
'				elseif i = selectedSegment
'					col = selectedColor
				elseif (i mod 2 = 0)
					col = labelColor2
				else
					col = labelColor
				endif

				labelFont.DrawBox(xSegmentLabels[i], x + GetSegmentStart(i) + bottomAxisLabelOffset.x, Int(area.GetY2() - bottomXLabelH + bottomAxisLabelOffset.y), GetSegmentWidth(i), bottomXLabelH, sALIGN_CENTER_CENTER, col)
			EndIf
			'not needed
			'labelFont.DrawBox(dataIndex, x + GetSegmentStart(i) + bottomAxisLabelOffset.GetIntX(), -20 + area.GetY2() - bottomXLabelH + bottomAxisLabelOffset.GetIntY(), GetSegmentWidth(i), bottomXLabelH, sALIGN_CENTER_CENTER, col)
		Next

		'values
		labelFont.DrawBox(GetFormattedValue(valueDisplayMaximumY), int(x2 + rightAxisLabelOffset.x), int(area.y + areaGraph.GetY() + rightAxisLabelOffset.y), (area.GetX2() - areaGraph.GetX2()), 20, sALIGN_LEFT_TOP, labelColor)
		labelFont.DrawBox(GetFormattedValue(valueDisplayMinimumY), int(x2 + rightAxisLabelOffset.x), int(area.y + areaGraph.GetY2() + rightAxisLabelOffset.y), (area.GetX2() - areaGraph.GetX2()), 20, sALIGN_LEFT_TOP, labelColor)
	End Method


	Method GetFormattedValue:string(v:float)
		if valueFormat = "convertvalue"
			return TFunctions.convertValue(v,0,2)
		else
			return StringHelper.printf(valueFormat, [string(v)])
		endif
	End Method
End Type