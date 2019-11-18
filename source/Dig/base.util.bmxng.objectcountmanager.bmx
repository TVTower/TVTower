SuperStrict
Import Brl.Map
Import Brl.Retro
Import Brl.Reflection
Import Brl.ObjectList
Import Brl.StringBuilder


Global OCM:TObjectCountManager = new TObjectCountManager


Type TObjectCountManager
	Field dumps:TObjectList = New TObjectList
	Field baseDump:TObjectCountDump
	Field dumpKeyCount:Int 'cache

	Method New()
		'fire reflection so it inits its TStringMap, TList, ...
		TTypeId.ForName("TObjectList")
	End Method


	Method EnableObjectCount(bool:int = True)
		CountObjectInstances = bool
	End Method


	Method GetTotal:Int(key:String)
		Local dumpEntry:TObjectCountDump = TObjectCountDump(dumps.Last())
		if not dumpEntry Then dumpEntry = baseDump
		if not dumpEntry Then print "no dumpentry";return 0
		Return dumpEntry.GetTotal(key)
	End Method


	Method FetchDump(description:String = "")
		EnableObjectCount()

		Local dump:TObjectCountDump = AnalyzeDump(TObjectCountDump(dumps.Last()), FetchDumpString(), MilliSecs())
		dump.description = description
		dumpKeyCount = Max(dumpKeyCount, dump.keyCount)

		dumps.AddLast(dump)
	End Method


	Method StoreBaseDump(description:String = "Base Dump")
		EnableObjectCount()

		baseDump = AnalyzeDump(Null, FetchDumpString(), MilliSecs())
		baseDump.description = description
		dumpKeyCount = Max(dumpKeyCount, baseDump.keyCount)
	End Method


	Method FetchDumpString:String()
		'try to free as much as possible
		GCCollect()

		Local buf:Byte[4096*3]
		DumpObjectCounts(buf, 4096*3, 0)
		Return String.FromCString(buf)
	End Method


	Method AnalyzeDump:TObjectCountDump(previousDumpEntry:TObjectCountDump, currentDump:String, time:Long)
		Local l:String[] = currentDump.split("~n")

		Local dumpEntry:TObjectCountDump = New TObjectCountDump
		dumpEntry.time = time

		For Local s:String = EachIn l
			If s[0] = Asc("=") Then Continue

			'split type from count
			Local p:String[] = s.split("~t")
			'trim meta data
			Local t:String = p[0].split("{")[0].Trim()
			Local c:Int = 0
			If p.length > 1 Then c = Int(p[1])

			If baseDump
				c :- baseDump.GetTotal(t)
			EndIf

			If previousDumpEntry
				local prev:Int = previousDumpEntry.GetTotal(t)
				dumpEntry.Add(t, c - prev, c)
			Else
				dumpEntry.Add(t, c, c)
			EndIf

			'can simply add as there wont be duplicates
			dumpEntry.keyCount :+ 1
		Next

		Return dumpEntry
	End Method


	'changeDirection = 1 to only show entries with increase of amount
	'changeDirection =-1 to only show entries with decrease of amount
	Method Dump(ocd:TObjectCountDump = Null, onlyChanged:Int = False, changeDirection:Int = 1)
		Print DumpToString(ocd, onlyChanged, changeDirection)
	End Method


	Method DumpToString:String(ocd:TObjectCountDump = Null, onlyChanged:Int = False, changeDirection:Int = 1)
		Local s:TStringBuilder = New TStringBuilder

		s.Append("========   Instance count dump (" + RSet(dumpKeyCount, 4) + ")   ========~n")

		If Not ocd Then ocd = TObjectCountDump(dumps.Last())
		If ocd
			s.Append("= Time: " + RSet(ocd.time, 8) + RSet(" ", 31) + "=~n")
			If ocd.description
				s.Append("= Desc: " + LSet(ocd.description, 39) + "=~n")
			EndIf

			local e:TObjectCountDumpEntry
			For Local k:String = EachIn ocd.entries.Keys()
				e = ocd.Get(k)
				If Not e Then Continue
				If onlyChanged
					If changeDirection > 0 And e.change <= 0 Then Continue
					If changeDirection < 0 And e.change >= 0 Then Continue
				EndIf
				if e.change < 0
					s.Append(LSet(k, 32) + RSet(e.total, 8) + RSet(e.change, 8) + "~n")
				elseif e.change > 0
					s.Append(LSet(k, 32) + RSet(e.total, 8) + RSet("+" + e.change, 8) + "~n")
				else
					s.Append(LSet(k, 32) + RSet(e.total, 8) + RSet("0", 8) + "~n")
				endif
			Next
		EndIf

		s.Append("=================   Dump End   =================~n")
		Return s.ToString()
	End Method
End Type




Type TObjectCountDump
	Field entries:TStringMap = New TStringMap
	Field time:Long
	Field description:String
	Field keyCount:Int 'cache

	Method Add(key:String, change:Int, total:Int)
		Local e:TObjectCountDumpEntry = New TObjectCountDumpEntry
		e.change = change
		e.total = total

		entries.Insert(key, e)
	End Method


	Method Get:TObjectCountDumpEntry(key:String)
		Return TObjectCountDumpEntry(entries.ValueForKey(key))
	End Method


	Method GetChange:Int(key:String)
		Local e:TObjectCountDumpEntry = TObjectCountDumpEntry(entries.ValueForKey(key))
		If e Then Return e.change
		Return 0
	End Method


	Method GetTotal:Int(key:String)
		Local e:TObjectCountDumpEntry = TObjectCountDumpEntry(entries.ValueForKey(key))
		If e Then Return e.total
		Return 0
	End Method
End Type


Type TObjectCountDumpEntry
	'contains the amount of change since last
	Field change:Int
	'contains the amount since base/reference dump
	Field total:Int
End Type