function courseplay:handle_mode4(self, allowedToDrive, workArea, workSpeed, fill_level, last_recordnumber)
	local workTool = self.tippers[1] -- to do, quick, dirty and unsafe
	local posToVeh = workTool.cp.positionToVehicle; --1 = front / -1 = back

	workArea = (self.recordnumber > self.startWork) and (self.recordnumber < self.stopWork)
	-- Beginn Work
	if last_recordnumber == self.startWork and fill_level ~= 0 then
		if self.abortWork ~= nil then
			self.recordnumber = self.abortWork - 2
		end
	end
	-- last point reached restart
	if self.abortWork ~= nil then
		if (last_recordnumber == self.abortWork - 2) and fill_level ~= 0 then
			self.abortWork = nil
		end
	end
	-- safe last point
	if fill_level == 0 and workArea and self.abortWork == nil then
		self.abortWork = self.recordnumber
		self.recordnumber = self.stopWork - 4
		--	courseplay:debug(string.format("Abort: %d StopWork: %d",self.abortWork,self.stopWork), 2)
	end


	local firstPoint = last_recordnumber == 1;
	local prevPoint = self.Waypoints[last_recordnumber];
	local nextPoint = self.Waypoints[self.recordnumber];
	
	local ridgeMarker = prevPoint.ridgeMarker;
	local turnStart = prevPoint.turnStart;
	local turnEnd = prevPoint.turnEnd;
	local raiseTool = prevPoint.raiseTool;

	-- stop while folding
	if courseplay:isFoldable(workTool) then
		if courseplay:isFolding(workTool) then --TODO: doesn't seem to work perfectly w/ Amazone Condor
			allowedToDrive = false;
			courseplay:debug(workTool.name .. ": isFolding -> allowedToDrive == false", 3);
		end;
		courseplay:debug(string.format("%s: unfold: turnOnFoldDirection=%s, foldMoveDirection=%s", workTool.name, tostring(workTool.turnOnFoldDirection), tostring(workTool.foldMoveDirection)), 3);
	end;

	local is_ux5200 = workTool.state ~= nil and workTool.state.isTurnedOn ~= nil

	if workArea and fill_level ~= 0 and (self.abortWork == nil or self.runOnceStartCourse) then
		self.runOnceStartCourse = false;
		workSpeed = true
		if is_ux5200 then
			if workTool.state.isTurnedOn ~= true then
				workTool:setIsTurnedOn(true, false)
				workTool:setStateEvent("state", "markOn", true)

				workTool:setStateEvent("Speed", "ex", 1.0)
				workTool:setStateEvent("Speed", "trsp", 1.0)
				workTool:setStateEvent("Go", "trsp", true)
				workTool:setStateEvent("Go", "hubmast", false)
				workTool:setStateEvent("Done", "hubmast", true)
				workTool:setStateEvent("Go", "hubmast", false)
				workTool:setStateEvent("Go", "ex", true)
				workTool:setStateEvent("Done", "ex", true)
			end
		else
			if allowedToDrive then
				--unfold
				if courseplay:isFoldable(workTool) and workTool:getIsFoldAllowed() then -- and ((self.abortWork ~= nil and self.recordnumber == self.abortWork - 2) or (self.abortWork == nil and self.recordnumber == 2)) then
					if courseplay:is_sowingMachine(workTool) then
						workTool:setFoldDirection(-1);
					
					elseif workTool.turnOnFoldDirection ~= nil and workTool.turnOnFoldDirection ~= 0 then
						workTool:setFoldDirection(workTool.turnOnFoldDirection);
					
					--Backup
					else
						workTool:setFoldDirection(1); --> doesn't work for Kotte VTL (liquidManure)
					end;
				end;
				
				if not courseplay:isFolding(workTool) then
					--set or stow ridge markers
					if courseplay:is_sowingMachine(workTool) then
						if ridgeMarker ~= nil then
							if workTool.ridgeMarkerState ~= ridgeMarker then
								workTool:setRidgeMarkerState(ridgeMarker);
							end;
						elseif workTool.ridgeMarkerState ~= nil and workTool.ridgeMarkerState ~= 0 then
							workTool:setRidgeMarkerState(0);
						end;
					end;

					--lower/raise
					if workTool.needsLowering and workTool.aiNeedsLowering then
						--print(string.format("WP%d: isLowered() = %s, hasGroundContact = %s", self.recordnumber, tostring(workTool:isLowered()), tostring(workTool.hasGroundContact)));
						if turnEnd ~= nil and turnStart ~= nil then
							if not workTool:isLowered() and turnEnd == false and turnStart == false then
								self:setAIImplementsMoveDown(true);
							end;
						elseif not workTool:isLowered() then
							self:setAIImplementsMoveDown(true);
						end;
					end;

					--turn on
					if workTool.setIsTurnedOn ~= nil and not workTool.isTurnedOn then
						if courseplay:is_sowingMachine(workTool) then
							--do manually instead of :setIsTurnedOn so that workTool.turnOnAnimation and workTool.playAnimation aren't called
							workTool.isTurnedOn = true;
							--[[if workTool.airBlowerSoundEnabled ~= nil then
								workTool.airBlowerSoundEnabled = true;
							end;]]
						else
							workTool:setIsTurnedOn(true, false);
						end;
					end;
				end; --END if not isFolding
			end;
		end
	else
		workSpeed = false
		if is_ux5200 then
			if workTool.state.isTurnedOn ~= false then
				workTool:setStateEvent("Done", "ex", true)
				workTool:setStateEvent("Go", "ex", false)
				workTool:setStateEvent("Done", "hubmast", true)
				workTool:setStateEvent("Go", "hubmast", false)
				workTool:setStateEvent("Go", "trsp", false)
				workTool:setStateEvent("Speed", "trsp", 1.0)
				workTool:setStateEvent("Speed", "ex", 1.0)
				workTool:setStateEvent("state", "markOn", false)
				workTool:setIsTurnedOn(false, false)
			end
		else
			--turn off
			if workTool.setIsTurnedOn ~= nil and workTool.isTurnedOn then
				if courseplay:is_sowingMachine(workTool) then
					--do manually instead of :setIsTurnedOn so that workTool.turnOnAnimation and workTool.playAnimation aren't called
					workTool.isTurnedOn = false;
					--[[if workTool.airBlowerSoundEnabled ~= nil then
						workTool.airBlowerSoundEnabled = false;
					end;]]
				else
					workTool:setIsTurnedOn(false, false);
				end;
			end;

			--raise
			if not courseplay:isFolding(workTool) then
				if workTool.needsLowering and workTool.aiNeedsLowering and workTool:isLowered() then
					self:setAIImplementsMoveDown(false);
				end;
			end;

			--fold
			if courseplay:isFoldable(workTool) then
				if courseplay:is_sowingMachine(workTool) then
					workTool:setFoldDirection(1);

				elseif workTool.turnOnFoldDirection ~= nil and workTool.turnOnFoldDirection ~= 0 then
					workTool:setFoldDirection(-workTool.turnOnFoldDirection);
					
				--Backup
				else
					workTool:setFoldDirection(-1); --> doesn't work for Kotte VTL (liquidManure)
				end;
			end;
		end
	end

	if not allowedToDrive then
		workTool:setIsTurnedOn(false, false)
	end

	return allowedToDrive, workArea, workSpeed
end;
