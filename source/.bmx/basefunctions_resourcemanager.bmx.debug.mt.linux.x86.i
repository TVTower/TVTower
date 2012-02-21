import brl.blitz
import brl.max2d
import brl.random
import brl.reflection
import brl.threads
import "basefunctions_xml.bmx"
import "basefunctions_image.bmx"
import "basefunctions_sprites.bmx"
TAssetManager^brl.blitz.Object{
content:brl.map.TMap&=mem:p("_bb_TAssetManager_content")
AssetsToLoad:brl.map.TMap&=mem:p("_bb_TAssetManager_AssetsToLoad")
AssetsLoadedLock:brl.threads.TMutex&=mem:p("_bb_TAssetManager_AssetsLoadedLock")
AssetsToLoadLock:brl.threads.TMutex&=mem:p("_bb_TAssetManager_AssetsToLoadLock")
AssetsLoadThread:brl.threads.TThread&=mem:p("_bb_TAssetManager_AssetsLoadThread")
.checkExistence%&
-New%()="_bb_TAssetManager_New"
+LoadAssetsInThread:Object(Input:Object)="_bb_TAssetManager_LoadAssetsInThread"
-StartLoadingAssets%()="_bb_TAssetManager_StartLoadingAssets"
-AddToLoadAsset%(resourceName$,resource:Object)="_bb_TAssetManager_AddToLoadAsset"
+Create:TAssetManager(initialContent:brl.map.TMap="bbNullObject",checkExistence%=0)="_bb_TAssetManager_Create"
-AddSet%(content:brl.map.TMap)="_bb_TAssetManager_AddSet"
-PrintAssets%()="_bb_TAssetManager_PrintAssets"
-SetContent%(content:brl.map.TMap)="_bb_TAssetManager_SetContent"
-Add%(assetName$,asset:TAsset,assetType$=$"unknown")="_bb_TAssetManager_Add"
+ConvertImageToSprite:TGW_Sprites(img:brl.max2d.Timage,spriteName$,spriteID%=-1)="_bb_TAssetManager_ConvertImageToSprite"
-AddImageAsSprite%(assetName$,img:brl.max2d.TImage,animCount%=1)="_bb_TAssetManager_AddImageAsSprite"
-GetObject:Object(assetName$,assetType$=$"",defaultAssetName$=$"")="_bb_TAssetManager_GetObject"
-GetSprite:TGW_Sprites(assetName$,defaultName$=$"")="_bb_TAssetManager_GetSprite"
-GetMap:brl.map.TMap(assetName$)="_bb_TAssetManager_GetMap"
-GetSpritePack:TGW_SpritePack(assetName$)="_bb_TAssetManager_GetSpritePack"
-GetFont:brl.max2d.TImageFont(assetName$)="_bb_TAssetManager_GetFont"
-GetImage:brl.max2d.TImage(assetName$)="_bb_TAssetManager_GetImage"
-GetBigImage:TBigImage(assetName$)="_bb_TAssetManager_GetBigImage"
}="bb_TAssetManager"
Assets:TAssetManager&=mem:p("bb_Assets")
