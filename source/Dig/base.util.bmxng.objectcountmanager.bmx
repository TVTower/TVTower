SuperStrict
Import Brl.Map
Import Brl.Retro
Import Brl.Reflection
Import Brl.ObjectList
Import Brl.StringBuilder
Import "base.util.longmap.bmx"

Global OCM:TObjectCountManager = new TObjectCountManager


Type TObjectCountManager
	Field enabled:int = True
	Field printEnabled:int = True
	Field dumps:TObjectList = New TObjectList
	Field lastDump:TObjectCountDump
	Field keyIDtoNameMap:TLongMap = new TLongMap 'keyID=>name mapping
	Field baseDump:TObjectCountDump
	Field dumpKeyCount:Int 'cache
	Field ignoreTypes:TLongMap 'store hashes of the lower strings, not names!

	Method New()
		'fire reflection so it inits its TStringMap, TList, ...
		TTypeId.ForName("TObjectList")
	End Method


	Method EnableObjectCount(bool:int = True)
		if not enabled then return
		CountObjectInstances = bool
	End Method
	
	
	Method GetKeyID:Long(key:String)
		Return Long(key.ToLower().hashCode())
	End Method


	Method GetKey:String(keyID:Long)
		Return String(keyIDtoNameMap.ValueForKey(keyID))
	End Method


	Method GetTotal:Int(key:String)
		Return GetTotal( GetKeyID(key) )
	End Method


	Method GetTotal:Int(keyID:Long)
		Local dumpEntry:TObjectCountDump = lastDump
		If Not lastDump 
			If Not baseDump Then Return 0
			Return baseDump.GetTotal(keyID)
		EndIf
		Return lastDump.GetTotal(keyID)
	End Method


	Method GetEntry:TObjectCountDumpEntry(key:String)
		Return GetEntry( GetKeyID(key) )
	End Method
	

	Method GetEntry:TObjectCountDumpEntry(keyID:Long)
		Local dumpEntry:TObjectCountDump = lastDump
		If Not lastDump 
			If Not baseDump Then Return Null
			Return basedump.Get(keyID)
		EndIf
		Return lastDump.Get(keyID)
	End Method

	
	Method GetLastDump:TObjectCountDump()
		Return lastDump
	End Method
	

	'add one or multiple (comma separated) types to ignore in outputs
	Method AddIgnoreTypes(types:string)
		local typeArr:string[] = types.split(",")

		if not ignoreTypes Then ignoreTypes = new TLongMap

		For local s:string = EachIn typeArr
			s = s.trim()
			if not s then continue

			ignoreTypes.Insert(GetKeyID(s), null)
		Next
	End Method


	Method ClearIgnoreTypes()
		if ignoreTypes then ignoreTypes.clear()
	End Method


	Method IsIgnoringType:Int(keyID:Long)
		if ignoreTypes and ignoreTypes.Contains(keyID) Then return True
		return False
	End Method


	Method IsIgnoringType:Int(t:string)
		if ignoreTypes and ignoreTypes.Contains( GetKeyID(t) ) Then return True
		return False
	End Method


	Method FetchDump(description:String = "")
		if not enabled then return

		EnableObjectCount()

		Local dump:TObjectCountDump = AnalyzeDump(lastDump, FetchDumpString(), MilliSecs())
		dump.description = description
		dumpKeyCount = Max(dumpKeyCount, dump.keyCount)

		dumps.AddLast(dump)
		lastDump = dump
	End Method


	Method StoreBaseDump(description:String = "Base Dump")
		if not enabled then return

		EnableObjectCount()

		baseDump = AnalyzeDump(Null, FetchDumpString(), MilliSecs())
		baseDump.description = description
		dumpKeyCount = Max(dumpKeyCount, baseDump.keyCount)
	End Method


	Method FetchDumpString:String()
		if not enabled then return ""

		'try to free as much as possible
		GCCollect()

		Local buf:Byte[4096*3]
		DumpObjectCounts(buf, 4096*3, 0)
		Return String.FromCString(buf)
	End Method


	Method AnalyzeDump:TObjectCountDump(previousDumpEntry:TObjectCountDump, currentDump:String, time:Long)
		Local skipThisLine:Int = False
		Local skipMeta:Int = False
		Local lastLinebreak:Int = -1
		Local readingValue:Int = False
		
		Local metaStart:Int, metaEnd:Int
		Local keyStart:Int, keyEnd:Int
		Local valueStart:Int, valueEnd:Int
		Local currentChar:Int
		Local lastChar:Int
		
		Local dumpEntry:TObjectCountDump = New TObjectCountDump
		dumpEntry.time = time
		
		For Local i:Int = 0 Until currentDump.Length
			lastChar = currentChar
			currentChar = currentDump[i]
			
			'end of line?
			If currentChar = Asc("~n")
				If Not skipThisLine
					'====
					'Actual handling of the key/value pair here
					'====
					Local t:String = currentDump[keyStart .. keyEnd]
					Local c:Int = Int(currentDump[valueStart .. valueEnd + 1])
					'debug: Print "Key: ~q" + t + "~q  Value: ~q" + c + "~q"

					Local keyID:Long = GetKeyID( t )
					keyIDtoNameMap.Insert(keyID, t)


					If baseDump
						c :- baseDump.GetTotal(keyID)
					EndIf

					local prev:Int
					If previousDumpEntry Then prev = previousDumpEntry.GetTotal(keyID)
					dumpEntry.Add(keyID, c - prev, c)

					dumpEntry.total :+ c
					dumpEntry.totalChange :+ (c - prev)


					'can simply add as there wont be duplicates
					dumpEntry.keyCount :+ 1

					'====
				EndIf
				
				skipThisLine = False
				readingValue = False
				keyStart = i + 1
				lastLineBreak = i
				Continue
			EndIf
			
			'begun new line?
			If lastLineBreak = i - 1
				If currentChar = Asc("=")
					skipThisLine = True
					Continue
				EndIf
			EndIf
			
			If Not skipThisLine
				If currentChar = Asc("{")
					metaStart = i
					skipMeta = True
				ElseIf lastChar = Asc("}")
					metaEnd = i 'already advanced a char since lastChar!
					skipMeta = False
				EndIf
				If Not skipMeta
					If currentChar = Asc("~t")
						keyEnd = i - (metaEnd - metaStart)
						metaStart = 0
						metaEnd = 0
						valueStart = i + 1
						readingValue = True
						Continue
					EndIf
					
					If Not readingValue
						keyEnd = i
					Else
						valueEnd = i
					EndIf
				EndIf
			EndIf
		Next

		Return dumpEntry
	End Method

rem
	Method AnalyzeDump:TObjectCountDump(previousDumpEntry:TObjectCountDump, currentDump:String, time:Long)
		Local l:String[] = currentDump.split("~n")

		Local dumpEntry:TObjectCountDump = New TObjectCountDump
		dumpEntry.time = time

		For Local s:String = EachIn l
			If s[0] = Asc("=") Then Continue
			If not s Then continue

			'split type from count
			Local p:String[] = s.split("~t")
			'trim meta data
			Local t:String = p[0]
			Local metaTagPos:Int = t.find("{")
			if metaTagPos > 0 Then t = p[0][.. metaTagPos]

			Local keyID:Long = GetKeyID(t)
			keyIDtoNameMap.Insert(keyID, t)

			Local c:Int = 0
			If p.length > 1 Then c = Int(p[1])

			If baseDump
				c :- baseDump.GetTotal(keyID)
			EndIf

			If previousDumpEntry
				local prev:Int = previousDumpEntry.GetTotal(keyID)
				dumpEntry.Add(keyID, c - prev, c)
			Else
				dumpEntry.Add(keyID, c, c)
			EndIf

			'can simply add as there wont be duplicates
			dumpEntry.keyCount :+ 1
		Next

		Return dumpEntry
	End Method
endrem

	'changeDirection = 1 to only show entries with increase of amount
	'changeDirection =-1 to only show entries with decrease of amount
	Method Dump(ocd:TObjectCountDump = Null, onlyChanged:Int = False, changeDirection:Int = 1)
		if not enabled then return

		Print DumpToString(ocd, onlyChanged, changeDirection)
	End Method


	Method DumpToString:String(ocd:TObjectCountDump = Null, onlyChanged:Int = False, changeDirection:Int = 1)
		if not enabled then return ""

		Local s:TStringBuilder = New TStringBuilder

		s.Append("========   Instance count dump (" + RSet(dumpKeyCount, 4) + ")   ========~n")

		If Not ocd Then ocd = lastDump
		If ocd
			s.Append("= Time:     " + RSet(ocd.time, 8) + RSet(" ", 27) + "=~n")
			s.Append("= Elements: " + RSet(ocd.keyCount, 8) + RSet(" ", 27) + "=~n")
			If ocd.description
				s.Append("= Desc:     " + LSet(ocd.description, 35) + "=~n")
			EndIf

			'For Local key:TLongKey = EachIn ocd.entries.Keys()
			For Local e:TObjectCountDumpEntry = EachIn ocd.entries.Values()
				if IsIgnoringType(e.keyID) then continue

				If onlyChanged
					If changeDirection > 0 And e.change <= 0 Then Continue
					If changeDirection < 0 And e.change >= 0 Then Continue
				EndIf
				if e.change > 0
					s.Append(LSet(OCM.GetKey(e.keyID), 32) + RSet(e.total, 8) + RSet("+" + e.change, 8) + "~n")
				else
					s.Append(LSet(OCM.GetKey(e.keyID), 32) + RSet(e.total, 8) + RSet(e.change, 8) + "~n")
				endif
			Next
		EndIf

		if ocd.totalChange > 0
			s.Append("= Total:    " + RSet(ocd.total, 8) + RSet("+" + ocd.totalChange, 27) + "=~n")
		Else
			s.Append("= Total:    " + RSet(ocd.total, 8) + RSet(ocd.totalChange, 27) + "=~n")
		EndIf
		s.Append("=================   Dump End   =================~n")
		Return s.ToString()
	End Method
End Type




Type TObjectCountDump
	Field entries:TLongMap = New TLongMap
	Field total:Int
	Field totalChange:Int
	Field time:Long
	Field description:String
	Field keyCount:Int 'cache

	Method Add(keyID:Long, change:Int, total:Int)
		Local e:TObjectCountDumpEntry = New TObjectCountDumpEntry
		e.keyID = keyID
		e.change = change
		e.total = total

		entries.Insert(keyID, e)
	End Method
	

	Method Get:TObjectCountDumpEntry(keyID:Long)
		Return TObjectCountDumpEntry(entries.ValueForKey(keyID))
	End Method


	Method Get:TObjectCountDumpEntry(key:String)
		Return TObjectCountDumpEntry(entries.ValueForKey( OCM.GetKeyID(key) ))
	End Method
	
	
	Method GetMostChanged:TObjectCountDumpEntry[](limit:Int = 0)
		Local arr:TObjectCountDumpEntry[keyCount]
		Local added:Int
		'ignore own
		Local k1:Long = OCM.GetKeyID("TObjectCountDumpEntry")
		Local k2:Long = OCM.GetKeyID("TObjectCountDump")
		
		For local e:TObjectCountDumpEntry = EachIn entries.Values()
			if e.keyID = k1 Then continue
			if e.keyID = k2 Then continue
			if e.change = 0 Then continue
		
			arr[added] = e
			added :+ 1
		Next
		arr = arr[.. added]
	
		
		arr.sort(True)
		if limit > 0 and arr.length > limit
			arr = arr[.. limit]
		EndIf
		
		Return arr
	End Method


	Method GetChange:Int(keyID:Long)
		Local e:TObjectCountDumpEntry = Get(keyID)
		If e Then Return e.change
		Return 0
	End Method


	Method GetChange:Int(key:String)
		Local e:TObjectCountDumpEntry = Get(key)
		If e Then Return e.change
		Return 0
	End Method


	Method GetTotal:Int(keyID:Long)
		Local e:TObjectCountDumpEntry = Get(keyID)
		If e Then Return e.total
		Return 0
	End Method


	Method GetTotal:Int(key:String)
		Local e:TObjectCountDumpEntry = Get(key)
		If e Then Return e.total
		Return 0
	End Method
End Type


Type TObjectCountDumpEntry
	Field keyID:Long
	'contains the amount of change since last
	Field change:Int
	'contains the amount since base/reference dump
	Field total:Int

	'default sort is now "by change"
	Method Compare:int(other:object)
		Local o2:TObjectCountDumpEntry = TObjectCountDumpEntry(other)
		If Not o2 Then Return 1
		
		If o2.change > change
			Return 1
		Elseif o2.change < change
			Return -1
		Else
			Return Super.Compare(other)
		EndIf
	End Method
End Type
