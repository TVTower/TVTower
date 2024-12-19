SuperStrict
Import "Dig/base.gfx.gui.chat.bmx"
Import "game.player.base.bmx"

Type TGUIGameChat Extends TGUIChat
	Method Create:TGUIGamechat(pos:SVec2I, dimension:SVec2I, limitState:String = "")
		Super.Create(pos, dimension, limitState)
		Return Self
	End Method


	'override
	Method AddEntryFromData( data:TData )
		Local senderID:Int = data.getInt("senderID", 0)
		Local sendingPlayer:TPlayerBase = GetPlayerBase(senderID)

		'override data if we found a valid player
		If sendingPlayer And senderID > 0
			data.Add("senderName", sendingPlayer.Name)
			data.Add("senderColor", sendingPlayer.color)
		Else
			data.Add("senderName", "SYSTEM")
			data.Add("senderColor", TColor.Create(220,50,50))
			data.Add("textColor", TColor.Create(220,80,70))
		EndIf

		Super.AddEntryFromData(data)
	End Method


	Method GetSenderID:int() override
		return GetPlayerBaseCollection().playerID
	End Method


	Method GetSenderName:String() override
		Local p:TPlayerBase = GetPlayerBase( GetPlayerBaseCollection().playerID )
		If not p
			Return "unknown"
		Else
			return p.name
		EndIf
	End Method
End Type
