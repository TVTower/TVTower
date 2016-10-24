Rem
	====================================================================
	Layer class + Layermanager class
	====================================================================

	Code contains following classes:
	TLayerManager: basic layer manager (Set, Get)
	TLayer: basic layer with possiblity to hold (static) renderables


	====================================================================
	LICENCE

	Copyright (C) 2002-2015 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
EndRem
SuperStrict
Import "base.framework.entity.bmx"
Import BRL.Map

Type TLayerManager
	Field layers:TMap = CreateMap()
	global _instance:TLayerManager


	Method New()
		if _instance Then Throw "Multiple TLayerManager not allowed"
	End Method


	Function GetInstance:TLayerManager()
		If not _instance Then New TLayerManager
		Return _instance
	End Function


	'adds a layer
	'overwrites an existing layers with same name
	Method Set:int(key:String, layer:TLayer)
		layers.Insert(key.ToUpper(), layer)
	End Method


	Method Get:TLayer(name:String)
		return TLayer(layers.ValueForKey(name.ToUpper()))
	End Method
End Type




Type TLayer
	Field name:String
	Field zIndex:Int
	Field entities:TMap = CreateMap()


	Method AddEntity:int(entity:TEntity)
		entities.insert(entity.name.ToUpper(), entity)
	End Method


	Method GetEntity:TEntity(name:string)
		return TEntity(entities.ValueForKey(name.ToUpper()))
	End Method


	'sort layers according zIndex
	Method Compare:Int(other:Object)
		Local otherLayer:TLayer = TLayer(other)
		If otherLayer
			'below me
			If otherLayer.zIndex < zIndex Then Return 1
			'on top of me
			If otherLayer.zIndex > zIndex Then Return -1
		EndIf
		Return Super.Compare(other)
	End Method


	Method Render:Int(xOffset:Float=0, yOffset:Float=0)
		For Local entity:TEntity = Eachin entities
			'skip invisble objects
			If not entity.visible Then continue

			entity.Render(xOffset, yOffset)
		Next
	End Method
End Type