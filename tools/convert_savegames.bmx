SuperStrict
Framework Brl.StandardIO
Import Archive.ZSTD
Import Archive.RAW
Import Text.mxml
Import Text.xml
Import MaxGUI.Drivers
Import brl.eventQueue


AppTitle = "Savegame converter"
Global buttonHeight:Int = 31
?Linux
buttonHeight = 26
?
Global windowMain:TGadget = CreateWindow( AppTitle, 100, 100, 700, 310, Null, WINDOW_TITLEBAR|WINDOW_STATUS|WINDOW_CENTER|WINDOW_ACCEPTFILES)
Global filesListBox:TGadget = CreateListBox(0,0,ClientWidth(windowMain),200, windowMain)
Global hintLabel:TGadget = CreateLabel("Drop one or more files on this window",0,205 + buttonHeight + 5 ,ClientWidth(windowMain),30, windowMain)
Global convertToZSTButton:TGadget = CreateButton("compress (zst)", 0 * ClientWidth(windowMain)/3, 205, ClientWidth(windowMain)/3, buttonHeight, windowMain)
Global convertToXMLButton:TGadget = CreateButton("uncompress (xml)", 1 * ClientWidth(windowMain)/3, 205, ClientWidth(windowMain)/3, buttonHeight, windowMain)
Global resetButton:TGadget = CreateButton("Reset", 2 * ClientWidth(windowMain)/3, 205, ClientWidth(windowMain)/3, buttonHeight, windowMain)
SetGadgetLayout(hintLabel, EDGE_ALIGNED, EDGE_ALIGNED, EDGE_ALIGNED, EDGE_CENTERED)
SetGadgetLayout(filesListBox, EDGE_ALIGNED, EDGE_ALIGNED, EDGE_CENTERED, EDGE_ALIGNED)
SetGadgetLayout(convertToZSTButton, EDGE_ALIGNED, EDGE_ALIGNED, EDGE_CENTERED, EDGE_ALIGNED)
SetGadgetLayout(convertToXMLButton, EDGE_ALIGNED, EDGE_ALIGNED, EDGE_CENTERED, EDGE_ALIGNED)
SetGadgetLayout(resetButton, EDGE_ALIGNED, EDGE_ALIGNED, EDGE_CENTERED, EDGE_ALIGNED)

Global files:String[]


Repeat
	Select WaitEvent()
		
		Case EVENT_APPTERMINATE, EVENT_WINDOWCLOSE
			End

		Case EVENT_WINDOWACCEPT
			Local temp:String = String(EventExtra())
			If temp
				files :+ [temp]
				AddGadgetItem(filesListBox, temp)
			EndIf
						
		Case EVENT_GADGETACTION
			If EventSource() = convertToZSTButton
				ConvertFiles("zst")
			ElseIf EventSource() = convertToXMLButton
				ConvertFiles("xml")
			ElseIf EventSource() = resetButton
				files = New String[0]
				For Local i:Int = 0 Until filesListBox.ItemCount()
					filesListBox.RemoveItem(0)
				Next
			EndIf
	EndSelect
Forever




'=====

Function ConvertFiles(targetType:String)
For Local i:Int = 0 Until files.length
	ModifyGadgetItem(filesListBox, i, files[i] + " ... processing")
	SetStatusText(windowMain, "Processing: " + files[i])
	PollSystem()

	If targetType = "xml"
		If ExtractExt(files[i]).ToLower() = "xml"
			ModifyGadgetItem(filesListBox, i, files[i] + " ... already uncompressed.")
			SetStatusText(windowMain, "Skipped: " + files[i])
			PollSystem()
		Else
			ConvertZST2XML(files[i], StripExt(files[i]) + ".xml", True)

			ModifyGadgetItem(filesListBox, i, files[i] + " ... uncompressed.")
			SetStatusText(windowMain, "Uncompressed: " + files[i])
			PollSystem()
		EndIf
	ElseIf targetType = "zst"
		If ExtractExt(files[i]).ToLower() = "zst"
			ModifyGadgetItem(filesListBox, i, files[i] + " ... already compressed.")
			SetStatusText(windowMain, "Skipped: " + files[i])
			PollSystem()
		Else
			ConvertXML2ZST(files[i], StripExt(files[i]) + ".zst", False)

			ModifyGadgetItem(filesListBox, i, files[i] + " ... compressed.")
			SetStatusText(windowMain, "Compressed: " + files[i])
			PollSystem()
		EndIf
	EndIf
	'GadgetItemText
Next

End Function


Function ConvertZST2XML(inputURI:String, outputURI:String, formatXML:Int = True)
	Local ra:TReadArchive = New TReadArchive
	ra.SetFormat(EArchiveFormat.RAW)
	ra.AddFilter(EArchivefilter.ZSTD)

	ra.Open(inputURI)

	Local entry:TArchiveEntry = New TArchiveEntry
	While ra.ReadNextHeader(entry) = ARCHIVE_OK
		Local doc:TxmlDoc = TxmlDoc.readDoc(ra.DataStream())
		doc.saveFile(outputURI, True, formatXML)
		Exit
	Wend
	ra.Free() 'do not wait for GC
End Function


Function ConvertXML2ZST(inputURI:String, outputURI:String, formatXML:Int = True)
	Local doc:TxmlDoc = TxmlDoc.parseFile(inputURI)
	If Not doc Then Notify "TxmlDoc.readdoc("+inputURI+") failed."
	
	Local saveStream:TStream = WriteStream(outputURI)
	If Not saveStream Then Notify "WriteStream("+outputURI+") failed."

	Local wa:TWriteArchive = New TWriteArchive
	wa.SetFormat(EArchiveFormat.RAW)
	wa.AddFilter(EArchiveFilter.ZSTD)
	wa.SetCompressionLevel(3) 'speed vs size
	wa.Open(outputURI)

	Local entry:TArchiveEntry = New TArchiveEntry
	wa.Header(entry)
	Local xmlArchiveStream:TStream = wa.DataStream()

	doc.saveFile(xmlArchiveStream, False, formatXML)

	wa.FinishEntry()
	entry.Free()
	wa.Close()
	xmlArchiveStream.Close()
End Function