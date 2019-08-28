-- File: SLF.lua
-- ============================
-- === Simple Lua Framework ===
-- ============================
-- Author: Manuel Vögele (STARS_crazy@gmx.de)
-- Last modified: 22.01.2015
-- Created at: 12.12.2007

-- this is defined by the game engine if called from there
-- else the file was opened via a direct call
if CURRENT_WORKING_DIR == nil and debug.getinfo(2, "S") then
	CURRENT_WORKING_DIR = debug.getinfo(2, "S").source:sub(2):match("(.*[/\\])") or "."
	package.path = CURRENT_WORKING_DIR .. '/?.lua;' .. package.path .. ';'
end

-- ##### KONSTANTEN #####
NL = "\n"

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- ##### HILFSMETHODEN #####

function getApplicationVersion()
	if _G["APP_VERSION"] then
		return _G["APP_VERSION"]
	else
		return "undefined"
	end
end


-- source: http://lua-users.org/wiki/SimpleLuaClasses
-- Compatible with Lua 5.1 (not 5.0).
function class(base, init)
	local c = {}    -- a new class instance
	if not init and type(base) == 'function' then
		init = base
		base = nil
	elseif type(base) == 'table' then
		-- our new class is a shallow copy of the base class!
		for i,v in pairs(base) do
			c[i] = v
		end
		c._base = base
	end
	-- the class will be the metatable for all its objects,
	-- and they will look up their methods in it.
	c.__index = c

	-- expose a constructor which can be called by <classname>(<args>)
	local mt = {}
	mt.__call = function(class_tbl, ...)
		local obj = {}
		setmetatable(obj,c)
		if init then
			init(obj,...)
		else
			-- make sure that any stuff from the base class is initialized!
			if base and base.init then
				base.init(obj, ...)
			end
		end
		return obj
	end
	c.init = init
	c.is_a = function(self, klass)
		local m = getmetatable(self)
		while m do
			if m == klass then return true end
				m = m._base
			end
		return false
	end
	setmetatable(c, mt)
	return c
end

function loadClass(classType)
	local c = classType()
	table.insert(LoadCache, c)
	return c
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["SLFObject"] = class(function(c)
	--Basis
end)
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["SLFDataObject"] = class(SLFObject, function(c)
	SLFObject.init(c)	-- must init base!
end)


function SLFDataObject:typename()
	return "SLFDataObject" --return "class name" here
end


function SLFDataObject:resume()
	--wird nach dem Laden aufgerufen // Hier auf "InvalidDataObject" prüfen
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["SLFManager"] = {StoreDefinition = {}, LoadedData = {}, StoreData = ""}


function SLFManager:save()
	-- Standard-Methode zum speichern. Zuvor sollten alle zu speichernden
	-- globalen Variablen im StoreDefinition hinterlegt werden.
	-- Format: Exakter VariablenName = Wert
	local SaveList = {}
	local ResultData = "--#Version " .. getApplicationVersion() .. NL
	for k,v in pairs(SLFManager.StoreDefinition) do
		ResultData = ResultData .. SLFManager:saveAsString(k, v, SaveList)
		ResultData = ResultData .. string.format("%s[%q]", "SLFManager.LoadedData", k) .. " = " .. k
	end
	SLFManager.StoreData = ResultData
	return SLFManager.StoreData
end


function SLFManager:load(pStoreData)
	-- Standard-Methode zum laden von vorhandenen Daten
	SLFManager.StoreData = pStoreData or SLFManager.StoreData
	_G["LoadCache"] = {}
	loadstring(SLFManager.StoreData)()	-- Führt das Skript aus
	debugMsg("Loaded objects: " .. table.count(LoadCache))

	for k,v in pairs(LoadCache) do
		v:resume()	-- Ruft fuer alle Tables "resume" auf
	end
end


function SLFManager:basicSerialize(o)
	if type(o) == "number" then
		return tostring(o)
	elseif type(o) == "boolean" then
		return tostring(o)
	else
		return string.format("%q", o)
	end
end


function SLFManager:saveAsString(name, value, saved)
	local result = "" --savestring or ""
	local isSLFDataObject = false
	saved = saved or {}
	result = name .. " = "
	if type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
		result = result .. SLFManager:basicSerialize(value) .. NL
	elseif type(value) == "table" then
		if saved[value] then
			result = result .. saved[value] .. NL
		else
			saved[value] = name
			if value["typename"] then
				isSLFDataObject = true
				result = result .. "loadClass(" .. value.typename() .. ")" .. NL
			else
				result = result .. "{}".. NL
			end
			for k,v in pairs(value) do
				k = SLFManager:basicSerialize(k)
				if type(v) == "userdata" then
					local fname = string.format("%s[%s]", name, k)
					local externalStoreIndex = TVT.SaveExternalObject(v)
					result = result .. fname .. " = TVT.RestoreExternalObject("..externalStoreIndex..")" .. NL
					-- return "true" -> leading to "InvalidDataObject" = true
					--return nil, true
				else
					local fname = string.format("%s[%s]", name, k)
					local data, isInvalidDataObject = SLFManager:saveAsString(fname, v, saved)
					if isInvalidDataObject then
						result = result .. string.format("%s[%q]", name, "InvalidDataObject") .. " = true" .. NL
					else
						result = result .. data
					end
				end
			end
		end
		saved[value] = name
	else
		error("Not able to save: " .. type(value) .. " (Name: " .. name .. ")")
	end

	return result
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




-- ##### AUXILIARY FUNCTIONS #####

function unpack(t, i)
	i = i or 1
	if t[i] ~= nil then
		return t[i], unpack(t, i + 1)
	end
end

--[[
math.round = function(pNumber, pPosition)
	pPosition = pPosition or 0
	local tempPosition = (10^pPosition)
	return (math.floor((pNumber * tempPosition) + 0.5) / tempPosition)
end
--]]

math.round = function(pNum, pNumDecimalPlaces)
	local multiplier = 10^(pNumDecimalPlaces or 0)
	if pNum >= 0 then
		return math.floor(pNum * multiplier + 0.5) / multiplier
	else
		return math.ceil(pNum * multiplier - 0.5) / multiplier
	end
end

table.count = function(pTable)
	if pTable == nil then return 0 end
	local Count = 0
	for k,v in pairs(pTable) do Count = Count + 1 end
	return Count
end

table.first = function(pTable)
	if pTable == nil then return nil end
	for k,v in pairs(pTable) do
		return v
	end
end

table.contains = function(pTable, item)
	if pTable == nil then return false end
    for key, value in pairs(pTable) do
        if value == item then return true end
    end
    return false
end

table.sortByKeys = function(t, f)
	local a = {}
	for n in pairs(t) do
		a[#a + 1] = n
	end
	table.sort(a, f)
	local i = 0
	return function()
		i = i + 1
		return a[i], t[a[i]]
	end
end

table.getKey = function(pTable, item)
	if pTable == nil then return nil end
    for key, value in pairs(pTable) do
        if value == item then
			return key
		end
    end
    return nil
end


-- return the ONE based index of an item in a table
table.getIndex = function(pTable, item)
	if pTable == nil then return -1 end
	local index = 1
    for key, value in pairs(pTable) do
        if value == item then
			return index
		end
		index = index + 1
    end
    return -1
end

table.removeElement = function(t, e)
	local index = table.getIndex(t, e)
	if (index ~= -1) then
		table.remove(t, index)
	end
end

table.removeKey = function(t, key)
	table.remove(t, table.getIndex(t, t[key]))
end

table.removeCollection = function(t, c)
    for key, value in pairs(c) do
        local tKey = table.getKey(t, value)

		if tKey ~= nil then
			--if t[tKey] ~= nil then
			--	debugMsg("removeCollection: removing t[" ..tKey.."] = " .. t[tKey].GetTitle())
			--end

			t[tKey] = nil
		end
    end
end

--http://lua-users.org/wiki/CopyTable
table.copy = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--http://lua-users.org/wiki/CopyTable
table.deepcopy = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

string.left = function(t, count, fixWidth)
	if (string.len(t) > count) then
		return string.sub(t, 0, count)
	elseif (fixWidth) then
		return t .. string.rep(" ", count - string.len(t))
	end
	return t
end

string.right = function(t, count, fixWidth)
	if (string.len(t) > count) then
		return string.sub(t, -count)
	elseif (fixWidth) then
		return string.rep(" ", count - string.len(t)) .. t
	end
	return string.sub(t, -count)
end


--split given text into an delim-glued table
function split(text, delim)
	local result = {}
	local magicChars = "^.-+*()[]$%?"

	if delim == nil then
		delim = "%s"
	elseif string.find(delim, magicChars, 1, true) then
		delim = "%" .. delim
	end

	local pattern = "[^" .. delim .. "]+"
	for w in string.gmatch(text, pattern) do
		table.insert(result, w)
	end
	return result


--	local words = {}
--	for word in text:gmatch("%w+") do table.insert(words, word) end
--	return words
end



-- source: http://lua-users.org/wiki/BitwiseOperators
function bitmaskNumber(index)
	return 2 ^ (index - 1)  -- 1-based indexing
end

-- Typical call:  if hasbit(x, bit(3)) then ...
function bitmaskHasBit(x, p)
	return x % (p + p) >= p
end

function bitmaskSetBit(x, p)
	return bitmaskHasBit(x, p) and x or x + p
end

function bitmaskClearBit(x, p)
	return bitmaskHasBit(x, p) and x - p or x
end

-- ##### TEST #####

--print(math.round(55.51545))
--[[
print("====== Start!")

a = SLFDataObject()
a.b = SLFDataObject()
a.b.c = SLFDataObject()
a.b.c.d = a

a.b.List = {}
a.b.List["key1"] = "val1"
a.b.List["key2"] = "val2"

local Data1 = ""
local Data2 = ""

SLFManager.StoreDefinition.a = a

Data1 = SLFManager.save()

print("Data1: " .. Data1)

a = nil

SLFManager.load()

Data2 = SLFManager.save()

assert(Data1 == Data2, "Wrong Result")

print("====== End!")
]]--