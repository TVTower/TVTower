-- File: Strategy.lua
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["AIStrategy"] = class(KIDataObjekt, function(c)
	KIDataObjekt.init(c)	-- must init base!
	c.TodayStartAccountBalance = 0 -- Kontostand zu Beginn des Tages
end)

function AIStrategy:typename()
	return "AIStrategy"
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["AIStrategyElement"] = class(KIDataObjekt, function(c)
	KIDataObjekt.init(c)	-- must init base!
end)

function AIStrategyElement:typename()
	return "AIStrategyElement"
end

function AIStrategyElement:execute(playerAI)
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<