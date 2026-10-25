--!strict
-- A purchase-finished boolean alone is insufficient: ask Roblox for ownership.
local Processor={}
function Processor.process(pass,queryOwnership,grant)
	local queried,owns=pcall(queryOwnership,pass.PassId)
	if not queried then return false,"lookup_failed" end
	if owns~=true then return false,"not_owned" end
	local returned,committed,status=pcall(grant,{Kind="pass",Id=pass.ItemId,PassKey=pass.Key,Verified=true})
	if returned and committed and (status=="ok" or status=="duplicate") then return true,status end
	return false,"save_failed"
end
return table.freeze(Processor)
