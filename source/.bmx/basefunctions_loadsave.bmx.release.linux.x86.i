import brl.blitz
import "basefunctions_xml.bmx"
import brl.reflection
TSaveFile^brl.blitz.Object{
.file:xmlDocument&
.node:xmlNode&
.currentnode:xmlNode&
.root:xmlNode&
.Nodes:xmlNode&[]&
.NodeDepth%&
.lastNode:xmlNode&
-New%()="_bb_TSaveFile_New"
-Delete%()="_bb_TSaveFile_Delete"
+Create:TSaveFile()="_bb_TSaveFile_Create"
-InitSave%()="_bb_TSaveFile_InitSave"
-InitLoad%(filename$=$"save.xml",zipped@=0)="_bb_TSaveFile_InitLoad"
-xmlWrite%(typ$=$"unknown",str$,newDepth@=0,depth%=-1)="_bb_TSaveFile_xmlWrite"
-xmlCloseNode%()="_bb_TSaveFile_xmlCloseNode"
-xmlBeginNode%(str$)="_bb_TSaveFile_xmlBeginNode"
-xmlSave%(filename$=$"-",zipped@=0)="_bb_TSaveFile_xmlSave"
-SaveObject%(obj:Object,nodename$,_addfunc%(obj:Object))="_bb_TSaveFile_SaveObject"
-LoadObject:Object(obj:Object,_handleNodefunc%(_obj:Object,_node:xmlnode))="_bb_TSaveFile_LoadObject"
}="bb_TSaveFile"
LoadSaveFile:TSaveFile&=mem:p("bb_LoadSaveFile")
