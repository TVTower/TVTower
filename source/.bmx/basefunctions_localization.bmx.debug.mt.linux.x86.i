import brl.blitz
import brl.retro
import brl.map
import brl.glmax2d
Localization^brl.blitz.Object{
currentLanguage$&=mem:p("_bb_Localization_currentLanguage")
supportedLanguages:brl.linkedlist.TList&=mem:p("_bb_Localization_supportedLanguages")
Resources:brl.linkedlist.TList&=mem:p("_bb_Localization_Resources")
-New%()="_bb_Localization_New"
+SetLanguage%(language$)="_bb_Localization_SetLanguage"
+Language$()="_bb_Localization_Language"
+AddLanguages%(languages$)="_bb_Localization_AddLanguages"
+OpenResource%(filename$)="_bb_Localization_OpenResource"
+LoadResource%(filename$)="_bb_Localization_LoadResource"
+OpenResources%(filter$)="_bb_Localization_OpenResources"
+LoadResources%(filter$)="_bb_Localization_LoadResources"
+GetString$(Key$,group$=$"")="_bb_Localization_GetString"
+GetLanguageFromFilename$(filename$)="_bb_Localization_GetLanguageFromFilename"
+GetResourceFiles:brl.linkedlist.TList(filter$)="_bb_Localization_GetResourceFiles"
+Dispose%()="_bb_Localization_Dispose"
}="bb_Localization"
LocalizationResource^brl.blitz.Object{
.language$&
._link:brl.linkedlist.TLink&
-New%()="_bb_LocalizationResource_New"
-GetString$(Key$,group$=$"")A="brl_blitz_NullMethodError"
-Close%()A="brl_blitz_NullMethodError"
}A="bb_LocalizationResource"
LocalizationStreamingResource^LocalizationResource{
.Stream:brl.stream.TStream&
-New%()="_bb_LocalizationStreamingResource_New"
+open:LocalizationStreamingResource(filename$,language$=$"")="_bb_LocalizationStreamingResource_open"
-GetString$(Key$,group$=$"")="_bb_LocalizationStreamingResource_GetString"
-Close%()="_bb_LocalizationStreamingResource_Close"
-Delete%()="_bb_LocalizationStreamingResource_Delete"
}="bb_LocalizationStreamingResource"
LocalizationMemoryResource^LocalizationResource{
.map:brl.map.TMap&
-New%()="_bb_LocalizationMemoryResource_New"
+open:LocalizationMemoryResource(filename$,language$=$"")="_bb_LocalizationMemoryResource_open"
-GetString$(Key$,group$=$"")="_bb_LocalizationMemoryResource_GetString"
-Close%()="_bb_LocalizationMemoryResource_Close"
-Delete%()="_bb_LocalizationMemoryResource_Delete"
}="bb_LocalizationMemoryResource"
