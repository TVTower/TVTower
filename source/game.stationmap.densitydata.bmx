SuperStrict
Import Text.Csv
Import Brl.Retro



Type TStationMapDensityData
	Field width:Int
	Field height:Int
	Field dataRaw:Int[]
	Field dataRawWidth:Int
	Field dataRawHeight:Int
	Field dataIsStretched:Int = False
	Field data:Int[]
	Field maxPopulationDensity:Int
	Field totalPopulation:Int
	
	Const MAP_VERSION:Byte = 1
	Const MAP_VERSION_MINIMUM:Byte = 1
	Const MAP_IDENTIFIER:String = "TVT"


	Method New(fileURI:String)
		If fileURI.ToLower().EndsWith("csv")
			If self.LoadFromCSV(fileURI)
				'cache if needed ?
				Local binFileURI:String = StripExt(fileURI) + ".bin"
				If FileType(binFileURI) <> FILETYPE_FILE
					self.SaveToBin(binFileURI)
					print "TStationMapDensityData: Caching CSV as BIN. " + binFileURI
				EndIf
			Else
				print "TStationMapDensityData: Invalid CSV file. " + fileURI
			EndIf
		Else
			Local loaded:Int = False
			Local binFileExisting:Int = (FileType(fileURI) = FILETYPE_FILE)
			If binFileExisting and self.LoadFromBin(fileURI)
				loaded = True
			EndIf
			
			If not loaded
				Local csvFileURI:String = StripExt(fileURI) + ".csv"
				If FileType(csvFileURI) = FILETYPE_FILE
					print "TStationMapDensityData: Converting from existing CSV. " + csvFileURI
					self.LoadFromCSV(csvFileURI)
					self.SaveToBin(fileURI)
				ElseIf binFileExisting
					print "TStationMapDensityData: Incompatible BIN and no CSV file found. " + fileURI
				Else
					print "TStationMapDensityData: Neither BIN nor CSV file found. " + fileURI
				EndIf
			Else
				self.LoadFromBin(fileURI)
			EndIf
		EndIf
	End Method


	Method LoadFromCSV:Int(fileURI:String, xName:String="x_1km", yName:String="y_1km", popName:String="population")
		Local csv:TCsvParser
		Local stream:TStream
		Local options:TCsvOptions = New TCsvOptions
		options.delimiter = ";"
		
		'read min/max values
		stream = ReadStream(fileURI)
		csv = TCsvParser.Parse(stream, options)
		Local minX:Int, maxX:Int
		Local minY:Int, maxY:Int
		Local isFirstRow:int = True
		While csv.NextRow() = ECsvStatus.row
			Local row:TCsvRow = csv.GetRow()
			Local x:Int = Int(row.GetColumn(xName).GetValue())
			Local y:Int = Int(row.GetColumn(yName).GetValue())
			If isFirstRow
				minX = x
				maxX = x
				minY = y
				maxY = y
				isFirstRow = False
			Else
				minX = min(minX, x)
				maxX = max(maxX, x)
				minY = min(minY, y)
				maxY = max(maxY, y)
			EndIf
		Wend	
		csv.Free()
		stream.Close()
		

		'now read the actual data
		self.width = maxX + 1 '0-30 means 31 elements, so add 1 !
		self.height = maxY + 1
		self.data = New Int[self.width * self.height]
		self.totalPopulation = 0
		self.maxPopulationDensity = 0

		stream = ReadStream(fileURI)
		csv = TCsvParser.Parse(stream, options)
		While csv.NextRow() = ECsvStatus.row
			Local row:TCsvRow = csv.GetRow()
			Local x:Int = Int(row.GetColumn(xName).GetValue())
			Local y:Int = Int(row.GetColumn(yName).GetValue())
			Local pop:Int = Int(row.GetColumn(popName).GetValue())

			'store with "local" coords
			self.data[y * self.width + x] = pop
			self.totalPopulation :+ pop
			self.maxPopulationDensity = max(pop, self.maxPopulationDensity)
		Wend
		csv.Free()
		stream.Close()
		
		Return True
	End Method
	
	
	Method SaveToBin:Int(fileURI:String)
		Local outStream:TStream = WriteStream(fileURI)
		outStream.WriteString(MAP_IDENTIFIER) 'magic byte "TVT density map"
		outStream.WriteByte(MAP_VERSION) 'version tag
		outStream.WriteShort(self.width)
		outStream.WriteShort(self.height)
		outStream.WriteInt(self.data.length)
		
		If self.maxPopulationDensity > 65536 'max short value
			outStream.WriteByte(4) '4 = bytes per "value"
			For local i:Int = EachIn self.data
				outStream.WriteInt(i)
			Next
		Else
			outStream.WriteByte(2) '2 = bytes per "value"
			For local i:Int = EachIn self.data
				outStream.WriteShort(i)
			Next
		EndIf
		outStream.Close()
		
		Return True
	End Method


	Method LoadFromBin:Int(fileURI:String)
		Local stream:TStream = ReadStream(fileURI)
		Local fileID:String = stream.ReadString(3)
		If fileID <> MAP_IDENTIFIER
			print "TStationMapDensityData.LoadFromBin: incompatible file."
			Return False
		EndIf
		Local fileVersion:Byte = stream.ReadByte()
		If fileVersion < MAP_VERSION_MINIMUM
			print "TStationMapDensityData.LoadFromBin: incompatible file, map version too low: " + fileVersion + " < " + MAP_VERSION_MINIMUM
			Return False
		EndIf
		Local w:Int = stream.ReadShort()
		Local h:Int = stream.ReadShort()
		Local dataElements:Int = stream.ReadInt()
		Local bytesPerValue:int = stream.ReadByte()

		self.width = w
		self.height = h
		self.data = New Int[width * height]
		self.totalPopulation = 0
		self.maxPopulationDensity = 0

		Local pop:Int
		Select bytesPerValue
			case 2
				For local i:Int = 0 until dataElements
					pop = Int(stream.ReadShort())
					self.data[i] = pop
					self.totalPopulation :+ pop
					self.maxPopulationDensity = max(pop, self.maxPopulationDensity)
				Next
			case 4
				For local i:Int = 0 until dataElements
					pop = stream.ReadInt()
					self.data[i] = pop
					self.totalPopulation :+ pop
					self.maxPopulationDensity = max(pop, self.maxPopulationDensity)
				Next
			default	throw "TStationMapDensityData.LoadFromBin: unsupported bytesPerValue " + bytesPerValue
		End Select
		stream.Close()

		Return True
	End Method


	Method LoadMaskFromBin:Byte[](fileURI:String)
		Local stream:TStream = ReadStream(fileURI)
		Local fileID:String = stream.ReadString(3)
		If fileID <> MAP_IDENTIFIER
			print "TStationMapDensityData.LoadFromBin: incompatible file."
			Return Null
		EndIf
		Local fileVersion:Byte = stream.ReadByte()
		If fileVersion < MAP_VERSION_MINIMUM
			print "TStationMapDensityData.LoadFromBin: incompatible file, map version too low: " + fileVersion + " < " + MAP_VERSION_MINIMUM
			Return Null
		EndIf
		Local w:Int = stream.ReadShort()
		Local h:Int = stream.ReadShort()
		Local dataElements:Int = stream.ReadInt()
		Local bytesPerValue:int = stream.ReadByte()

		Local mask:Byte[] = New Byte[w * h]
		Select bytesPerValue
			case 2
				For local i:Int = 0 until dataElements
					If stream.ReadShort() > 0 Then mask[i] = 255
				Next
			case 4
				For local i:Int = 0 until dataElements
					If stream.ReadInt() > 0 Then mask[i] = 255
				Next
			default	throw "TStationMapDensityData.LoadMaskFromBin: unsupported bytesPerValue " + bytesPerValue
		End Select
		stream.Close()

		Return mask
	End Method
	
	
	Method GetRawWidth:Int()
		If Not Self.dataIsStretched Then Return Self.width
		Return Self.dataRawWidth
	End Method


	Method GetRawHeight:Int()
		If Not Self.dataIsStretched Then Return Self.height
		Return Self.dataRawHeight
	End Method

	
	Method Stretch(width:Int, height:Int)
		'backup data
		If not self.dataIsStretched
			self.dataRaw = self.data
			self.dataRawWidth = self.width
			self.dataRawHeight = self.height
		EndIf
		self.data = StretchArray(self.dataRaw, self.dataRawWidth, self.dataRawHeight, width, height)
		self.dataIsStretched = True
		self.width = width
		self.height = height

		'refresh totalPop/maxPopulationDensity caches
		self.totalPopulation = 0
		self.maxPopulationDensity = 0
		For local i:Int = EachIn self.data
			self.totalPopulation :+ i
			self.maxPopulationDensity = max(i, self.maxPopulationDensity)
		Next
	End Method


	'stretch a given array ensuring total sum of all cells stays
	'the same
	Function StretchArray:Int[](array:Int[], arrayW:Int, arrayH:int, newW:Int, newH:Int, distributeToEmpty:Int = False)
		Local result:Float[] = New Float[newW * newH]

		Local rowRatio:Float = arrayW/Float(newW)
		Local colRatio:Float = arrayH/Float(newH)

		Local origSum:Int
		Local rescaledSum:Float
		For local i:int = EachIn array
			origSum :+ i
		Next
		
		For local destX:int = 0 until newW
			For local destY:int = 0 until newH
				Local totalWeight:Float = 0

				Local srcXStart:Int = int(destX * rowRatio)
				Local srcXEnd:Int = int((destX + 1) * rowRatio)
				Local srcYStart:Int = int(destY * colRatio)
				Local srcYEnd:Int = int((destY + 1) * colRatio)
				For local srcX:int = srcXStart to srcXEnd
					For local srcY:int = srcYStart to srcYEnd
						Local xOverlap:Float = min((destX + 1) * rowRatio, srcX + 1) - max(destX * rowRatio, srcX)
						Local yOverlap:Float = min((destY + 1) * colRatio, srcY + 1) - max(destY * colRatio, srcY)
						Local overlapArea:Float = max(xOverlap, 0) * max(yOverlap, 0)
						Local weight:Float = overlapArea / (rowRatio * colRatio)
						If weight > 0.0
							totalWeight :+ weight
							result[destY * newW + destX] :+ array[srcY * arrayW + srcX] * weight
						EndIf
					Next
				Next
				result[destY * newW + destX] :/ totalWeight
				rescaledSum :+ result[destY * newW + destX]
			Next
		Next

		' Adjust the output array to preserve the total sum
		Local scalingFactor:Float = origSum / rescaledSum

		' cut the array down to integers
		Local resultInt:Int[] = New Int[newW*newH]
		Local integerSum:Int
		For local i:int = 0 until resultInt.length
			resultInt[i] = Int(result[i] * scalingFactor)
			integerSum :+ resultInt[i]
		Next

		'print integersum + "  scalingFactor="+scalingFactor + "  origSum="+origSum + " rescaledSum="+rescaledSum

		' Distribute the difference among the array elements
		Local diff:Int = Int(origSum) - integerSum
		Local x:int, y:int
		while diff <> 0
			if diff > 0
				If distributeToEmpty or resultInt[y*newW + x] > 0
					resultInt[y*newW + x] :+ 1
					diff :- 1
				EndIf
			Else
				If distributeToEmpty or resultInt[y*newW + x] > 0
					resultInt[y*newW + x] :- 1
					diff :+ 1
				EndIf
			EndIf

			y :+ 1
			if y >= newH
				y = 0
				x :+ 1
			endif
			
			'we might not have been able to distribute all values
			'as all cells were "empty" after stretching
			If not distributeToEmpty and x >= newW Then exit
		wend
		
		return resultInt
	End Function


	'myMap[x,y] returns the data for x,y
	Method Operator[]:Int(x:Int, y:Int)
		Return self.data[y * self.width + x]
	End Method

	Method Operator[]:Int(index:Int)
		Return self.data[index]
	End Method

	'set value of myMap.data[index of x,y]
	Method Operator[]=(x:Int, y:Int, value:Int)
		self.data[y * self.width + x] = value
	End Method

	'set value of myMap.data[index]
	Method Operator[]=(index:Int, value:Int)
		self.data[index] = value
	End Method
End Type
