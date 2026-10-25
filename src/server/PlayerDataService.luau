--!strict
local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local Config=require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Schema=require(game:GetService("ReplicatedStorage").Shared.DataSchema)
local Data={Profiles={}, Closing=false}
local persistent=not RunService:IsStudio() or Config.StudioPersistence
local store=if persistent then DataStoreService:GetDataStore(Config.DataStoreName) else nil
local function retry(operation, deadline)
	local lastError
	for attempt=1,4 do
		if deadline and os.clock()>deadline then break end
		local ok,result=pcall(operation)
		if ok then return true,result end
		lastError=result
		if attempt<4 then task.wait(math.min(2^(attempt-1),4)) end
	end
	return false,lastError
end
function Data.load(player)
	local saved={MaxStage=0,Completed=false}
	if store then
		local ok,value=retry(function() return store:GetAsync("u_"..player.UserId) end)
		if not ok then
			warn("[Data] Load failed for "..player.UserId..": "..tostring(value))
			if player.Parent then player:Kick("Progress could not be loaded. Please rejoin; your saved progress is safe.") end
			return nil -- Never overwrite existing data with defaults after a failed load.
		end
		saved=Schema.sanitize(value)
	end
	if not player.Parent then return nil end
	local profile={MaxStage=saved.MaxStage,Completed=saved.Completed,BestTime=saved.BestTime,
		RunStage=saved.MaxStage,Deaths=0,StartedAt=workspace:GetServerTimeNow(),
		FullRun=saved.MaxStage==0,Won=saved.MaxStage==50,Revision=0,SavedRevision=0,
		Saving=false,LastSave=0,Gate=0,StageEntered=os.clock(),LastReplay=0}
	Data.Profiles[player]=profile
	player:SetAttribute("Persistence",persistent)
	return profile
end
function Data.mark(profile)
	profile.Revision+=1
end
function Data.save(player,deadline)
	local profile=Data.Profiles[player]
	if not profile then return true end
	while profile.Saving do
		if deadline and os.clock()>deadline then return false end
		task.wait(0.1)
	end
	if profile.SavedRevision>=profile.Revision then return true end
	if not store then profile.SavedRevision=profile.Revision; return true end
	profile.Saving=true
	local revision=profile.Revision
	local snapshot={MaxStage=profile.MaxStage,Completed=profile.Completed,BestTime=profile.BestTime}
	local ok,result=retry(function()
		return store:UpdateAsync("u_"..player.UserId,function(old)
			return Schema.merge(old,snapshot)
		end)
	end,deadline)
	profile.Saving=false
	profile.LastSave=os.clock()
	if ok then profile.SavedRevision=revision
	else warn("[Data] Save pending for "..player.UserId..": "..tostring(result)) end
	if player.Parent then player:SetAttribute("SavePending",profile.SavedRevision<profile.Revision) end
	return ok
end
function Data.requestSave(player)
	local profile=Data.Profiles[player]
	if not profile or profile.Queued then return end
	profile.Queued=true
	task.delay(Config.SaveDebounce,function()
		profile.Queued=false
		if Data.Profiles[player] and not Data.Closing then Data.save(player) end
	end)
end
function Data.start()
	if not persistent then warn("[Data] Studio session-only mode. Set StudioPersistence=true on a separate published test place to test DataStore.") end
	task.spawn(function()
		while not Data.Closing do
			task.wait(Config.SaveInterval)
			for player in Data.Profiles do
				if not Data.Closing then task.spawn(Data.save,player) end
			end
		end
	end)
	game:BindToClose(function()
		Data.Closing=true
		local deadline=os.clock()+25
		local pending=0
		for player in Data.Profiles do
			pending+=1
			task.spawn(function() Data.save(player,deadline); pending-=1 end)
		end
		while pending>0 and os.clock()<deadline do task.wait(0.1) end
		if pending>0 then warn("[Data] Shutdown save deadline reached; "..pending.." writes unfinished") end
	end)
end
return Data
