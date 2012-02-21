-- ============================
-- === Simple Lua Framework ===
-- ============================
-- Autor: Manuel Vögele (STARS_crazy@gmx.de)

-- ##### HISTORY #####
-- 13.12.2007 Manuel
-- NEW: SLFDataObject eingefügt
-- 12.12.2007 Manuel
-- +++++ Library erstellt +++++

-- ##### KONSTANTEN #####
NL = "\n"
APP_VERSION = "--[[NOVersion]]--" -- Kann überschrieben werden

-- ##### GLOBALS #####
globalIDCounter = 0     --TODO: Counter könnte eine Zahlengrenze sprengen (zu prüfen)

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
SLFObject = {Id = 0}

function SLFObject:new(o)
	o = o or {}   -- Erstellt das Objekt, wenn keiens Vorhanden
	setmetatable(o, self)
	self.__index = self
	globalIDCounter = globalIDCounter + 1
	self.Id = globalIDCounter
	self:initialize()
	return o
end

function SLFObject:initialize()
	--kann überschrieben werden, ist im Standard aber leer.
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
SLFDataObject = SLFObject:new()

function SLFDataObject:load(loadcache)
	o = {}   -- Erstellt das Objekt, wenn keiens Vorhanden
	setmetatable(o, self)
	self.__index = self
	LoadCacheCounter = LoadCacheCounter + 1
	loadcache[LoadCacheCounter] = self
	return o
end

function SLFDataObject:typename()
	return "SLFDataObject" --Hier muss der "Klassen"-Name zurückgeliefert werden
end

function SLFDataObject:resume()
	--wird nach dem Laden aufgerufen
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
SLFManager = {StoreDefinition = {}, StoreData = ""}

function SLFManager:save()
	-- Standard-Methode zum speichern. Zuvor sollten alle zu speichernden globalen Variablen im StoreDefinition hinterlegt werden.
	-- Format: Exakter VariablenName = Wert
	local SaveList = {}
	local ResultData = "--#V" .. APP_VERSION .. NL
	for k,v in pairs(SLFManager.StoreDefinition) do
		ResultData = ResultData .. SLFManager:saveAsString(k, v, SaveList)
	end
	SLFManager.StoreData = ResultData
	return SLFManager.StoreData
end

function SLFManager:load(pStoreData)
	-- Standard-Methode zum laden von vorhandenen Daten
	SLFManager.StoreData = pStoreData or SLFManager.StoreData
	LoadCache = {}
	LoadCacheCounter = 0

	loadstring(SLFManager.StoreData)()	-- Führt das Skript aus

	for k,v in pairs(LoadCache) do
		v:resume()	-- Ruft für alle Tables "resume" auf
	end
end

function SLFManager:basicSerialize(o)
	if type(o) == "number" then
		return tostring(o)
	else
		return string.format("%q", o)
	end
end

function SLFManager:saveAsString(name, value, saved)
	local result = ""--savestring or ""
	saved = saved or {}
	result = name .. " = "
	if type(value) == "number" or type(value) == "string" then
		result = result .. SLFManager:basicSerialize(value) .. NL
	elseif type(value) == "table" then
		if saved[value] then
			result = result .. saved[value] .. NL
		else
			saved[value] = name
			if value["typename"] then
				result = result .. value.typename() .. ":load(LoadCache)" .. NL
			else
				result = result .. "{}".. NL
			end
			for k,v in pairs(value) do
				k = SLFManager:basicSerialize(k)
				local fname = string.format("%s[%s]", name, k)
				result = result .. SLFManager:saveAsString(fname, v, saved)
			end
		end
		saved[value] = name
	else
		error("Kann Folgendes nicht speichern: " .. type(value))
	end

	return result
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- ##### WEITERE FUNKTIONEN #####

math.round = function(pNumber, pPosition)
	pPosition = pPosition or 0
	local tempPosition = (10^pPosition)
	return (math.floor((pNumber * tempPosition) + 0.5) / tempPosition)
end

table.count = function(pTable)
	local Count = 0
	for k,v in pairs(pTable) do Count = Count + 1 end
	return Count
end

-- ##### TEST #####

--print(math.round(55.51545))

--[[
a = SLFDataObject:new()
a.b = SLFDataObject:new()
a.b.c = SLFDataObject:new()
a.b.c.d = a

local Data1 = ""
local Data2 = ""

SLFManager.StoreDefinition.a = a

Data1 = SLFManager.save()

a = nil
print("leer: " .. type(a))

SLFManager.load()

print("X:X: " .. type(a))

Data2 = SLFManager.save()

assert(Data1 == Data2, "Falsches Ergebnis")
]]--