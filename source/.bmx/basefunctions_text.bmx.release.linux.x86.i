import brl.blitz
import brl.font
import brl.basic
import brl.glmax2d
TGW_FontManager^brl.blitz.Object{
.DefaultFont:TGW_Font&
.List:brl.linkedlist.TList&
-New%()="_bb_TGW_FontManager_New"
-Delete%()="_bb_TGW_FontManager_Delete"
+Create:TGW_FontManager()="_bb_TGW_FontManager_Create"
-GW_GetFont:brl.max2d.TImageFont(_FName$,_FSize%=-1,_FStyle%=-1)="_bb_TGW_FontManager_GW_GetFont"
-AddFont:TGW_Font(_FName$,_FFile$,_FSize%,_FStyle%)="_bb_TGW_FontManager_AddFont"
}="bb_TGW_FontManager"
TGW_Font^brl.blitz.Object{
.FName$&
.FFile$&
.FSize%&
.FStyle%&
.FFont:brl.max2d.TImageFont&
-New%()="_bb_TGW_Font_New"
-Delete%()="_bb_TGW_Font_Delete"
+Create:TGW_Font(_FName$,_FFile$,_FSize%,_FStyle%)="_bb_TGW_Font_Create"
}="bb_TGW_Font"
