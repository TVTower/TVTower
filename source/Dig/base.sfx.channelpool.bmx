Rem
	====================================================================
	class providing a simple channel pool
	====================================================================

	With this class it is easy to allocate channels or reuse existing
	ones in the case of a limitation regarding channel count.

	You are able to protect channels so they do not get returned for
	reuse (like background music channels).


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2015 Ronny Otto, digidea.de

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
Import brl.Audio
Import brl.Map


Type TChannelPool
	Global channels:TMap = CreateMap()
	'a list of keys for channels you cannot "overwrite" when exceeding
	'a limit
	Global protectedChannels:string[]
	'is there a limit of channels? As channels are "software mixed"
	'by the audio-module, there shouldn't be some
	Global channelLimit:int = -1
	Global channelCount:int = -1


	'returns the channel associated to the given key
	'If no channel exists yet, a new one is created/added automatically
	Function GetChannel:TChannel(key:string)
		key = key.toLower()
		local channel:TChannel = TChannel(channels.ValueForKey(key))
		'if channel was not existing yet, create a new one
		If not channel
			channel = AllocChannel()
			If not channel
				Throw "TChannelPool: Failed to allocate new channel."
			EndIf
			AddChannel(key, channel)
		EndIf
		'if we do not have a channel now, we will surely have exceeded a
		'limit. In that case we return a random one to override it
		If not channel and GetChannelCount() >= 1
			local channelKey:string = GetRandomChannelKey()
			If not channelKey
				Throw "TChannelPool: Limit exceeded. No existing and valid channel found to reuse."
			EndIf

			local channel:TChannel = TChannel(channels.ValueForKey(channelKey))
			If not channel
				Throw "TChannelPool: channelKey invalid."
			EndIf

			'remove the old channel, and add it back with the new
			'name - so from now on, the newly requested key is stored
			'instead of the old one
			RemoveChannel(channelKey)
			AddChannel(key, channel)
		EndIf

		return channel
	End Function


	'returns the channel of a random channel key
	Function GetRandomChannel:TChannel()
		return TChannel(channels.ValueForKey( GetRandomChannelKey() ))
	End Function

	
	'returns the key of a random channel
	'currently unused channels are preferred so it is not truly "random"
	Function GetRandomChannelKey:String()
		'if no protected channels are existent ... we just could
		'randomly access a channel
		If protectedChannels.length = 0
			local randNumber:int = Rnd(1, GetChannelCount())
			local randPosition:int = 0
			For local k:string = EachIn channels.Keys()
				randPosition :+ 1
				If randPosition >= randNumber and not isProtectedChannel(k)
					return k
				EndIf
			Next
			return ""
		Else
			'create an array containing just "unprotected" channels
			'also store not playing channels in an extra array
			'because we prefer an currently unused channel
			local unprotectedChannelKeys:string[]
			local unprotectedUnusedChannelKeys:string[]
			local channel:TChannel
			For local k:string = EachIn channels.Keys()
				If isProtectedChannel(k) then Continue
				channel = TChannel(channels.ValueForKey(k))
				If not channel then continue

				unprotectedChannelKeys :+ [k]
				If not channel.Playing()
					unprotectedUnusedChannelKeys :+ [k]
				EndIf
			Next

			If not unprotectedChannelKeys
				Throw "TChannelPool.GetRandomChannelKey(): No unprotected and valid channel found to return."
			Else
				If unprotectedUnusedChannelKeys
					return unprotectedUnusedChannelKeys[ Rnd(0,unprotectedUnusedChannelKeys.length-1) ]
				Else
					return unprotectedChannelKeys[ Rnd(0,unprotectedChannelKeys.length-1) ]
				EndIf
			EndIf
		EndIf
		return ""
	End Function


	Function RemoveChannel:TChannel(key:string)
		key = key.toLower()
		local channel:TChannel = GetChannel(key)
		if not channel then return Null

		channels.Remove(key)
		'invalidate channel count
		channelCount = -1
		'remove a previously set protection?
		UnProtectChannel(key)

		return channel
	End Function


	Function HasChannel:Int(key:string)
		key = key.toLower()
		For local k:string = EachIn channels.Keys()
			if k = key then return True
		Next

		return False
	End Function


	'adds a channel - and overwrites potentially existing ones
	Function AddChannel:TChannel(key:string, channel:TChannel)
		'if there is a limit, skip adding a channel if limit is
		'exceeded
		If channelLimit >= 0 and GetChannelCount() > channelLimit
			return Null
		EndIf

		key = key.toLower()
		channels.insert(key, channel)

		'invalidate channelCount
		channelCount = -1

		'remove a previously set protection?
		'UnProtectChannel(key)

		return channel
	End Function


	Function isProtectedChannel:Int(key:string)
		if not protectedChannels then return False
		key = key.ToLower()
		For local k:string = EachIn protectedChannels
			if k = key then return True
		Next
		return False
	End Function
	

	'mark a channel for protection so it cannot get overwritten
	'when the limits exceed
	Function ProtectChannel:int(key:string)
		'already protected?
		if isProtectedChannel(key) then return True

		key = key.ToLower()
		protectedChannels :+ [key]
	End Function


	Function UnProtectChannel:int(key:string)
		if not protectedChannels then return False
		
		key = key.ToLower()
		local newProtectedChannels:string[]

		For local k:string = EachIn protectedChannels
			if k <> key then newProtectedChannels :+ [k]
		Next

		protectedChannels = protectedChannels
	End Function


	Function GetChannelCount:int(forceRecount:int = False)
		'use cached var
		if not forceRecount and channelCount >= 0 then return channelCount

		channelCount = 0
		For local channel:TChannel = EachIn channels.Values()
			channelCount :+1
		Next

		return channelCount
	End Function
End Type


'convenience accessors
Function GetPooledChannel:TChannel(key:string)
	return TChannelPool.GetChannel(key)
End Function

Function GetRandomPooledChannel:TChannel()
	return TChannelPool.GetRandomChannel()
End Function

Function AddPooledChannel:TChannel(key:string, channel:TChannel)
	return TChannelPool.AddChannel(key, channel)
End Function

Function RemovePooledChannel:TChannel(key:string)
	return TChannelPool.RemoveChannel(key)
End Function

Function PooledChannelExists:Int(key:string)
	return TChannelPool.HasChannel(key)
End Function

Function ProtectPooledChannel(key:string)
	TChannelPool.ProtectChannel(key)
End Function

Function UnProtectPooledChannel(key:string)
	TChannelPool.UnProtectChannel(key)
End Function
