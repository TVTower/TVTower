-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- Movie ist jetzt nur noch ein Wrapper

function CheckMovieBuyConditions(movie, maxPrice, minQuality)
	if (movie.GetPrice() > maxPrice) then return false end	
	if (minQuality ~= nil) then
		if (movie.getBaseAudienceQuote() < minQuality) then return false end
	end
	return true
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
SpotRequisition = Requisition:new{
	TaskId = TASK_ADAGENCY,
	Priority = 5
}

function SpotRequisition:typename()
	return "SpotRequisition"
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
