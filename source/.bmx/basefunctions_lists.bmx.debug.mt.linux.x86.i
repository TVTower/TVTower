import brl.blitz
import brl.glmax2d
TObjectList^brl.blitz.Object{
.Items:Object&[]&
._Size%&
.StepSize%&
-New%()="_bb_TObjectList_New"
-AddFirst%(val:Object)="_bb_TObjectList_AddFirst"
-AddLast%(val:Object)="_bb_TObjectList_AddLast"
-ToDelimString$(Delim$=$"")="_bb_TObjectList_ToDelimString"
-ToString$()="_bb_TObjectList_ToString"
-Count%()="_bb_TObjectList_Count"
-Contains%(val:Object)="_bb_TObjectList_Contains"
+FromObjectArray:TObjectList(val:Object&[])="_bb_TObjectList_FromObjectArray"
-Insert%(val:Object,index%,AutoAddToEnd%=0)="_bb_TObjectList_Insert"
-RemoveByIndex%(index%)="_bb_TObjectList_RemoveByIndex"
-RemoveByObject%(val:Object,RemoveAll%=0)="_bb_TObjectList_RemoveByObject"
-Clear%()="_bb_TObjectList_Clear"
-ToArray:Object&[]()="_bb_TObjectList_ToArray"
-ToList%(List:brl.linkedlist.TList Var)="_bb_TObjectList_ToList"
-GetStepSize%()="_bb_TObjectList_GetStepSize"
-SetStepSize%(val%)="_bb_TObjectList_SetStepSize"
-Sort%()="_bb_TObjectList_Sort"
-Free%()="_bb_TObjectList_Free"
-SwapByIndex%(FirstIndex%,SecondIndex%)="_bb_TObjectList_SwapByIndex"
-SwapByVal%(FirstObject:Object,SecondObject:Object)="_bb_TObjectList_SwapByVal"
+Destroy%(List:TObjectList)="_bb_TObjectList_Destroy"
+Create:TObjectList(StepSize%=10)="_bb_TObjectList_Create"
}="bb_TObjectList"
