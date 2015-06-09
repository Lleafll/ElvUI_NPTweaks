local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local NP = E:GetModule('NamePlates')
local NPCT = E:GetModule('NameplateTweaks')
local EP = LibStub("LibElvUIPlugin-1.0")
local addon, ns = ...


--------------
-- Upvalues --
--------------
local C_TimerAfter = C_Timer.After
local UnitExists = UnitExists


----------------------------------------------
-- Nameplate custom health percent coloring --
----------------------------------------------
function NP:ColorizeAndScale(myPlate)
	local unitType = NP:GetReaction(self)
	local scale = 1

	self.unitType = unitType
	if RAID_CLASS_COLORS[unitType] then
		color = RAID_CLASS_COLORS[unitType]
	elseif unitType == "TAPPED_NPC" then
		color = NP.db.reactions.tapped
	elseif unitType == "HOSTILE_NPC" or unitType == "NEUTRAL_NPC" then
		local classRole = E.role
		local threatReaction = NP:GetThreatReaction(self)
		if(not NP.db.threat.enable) then
			if unitType == "NEUTRAL_NPC" then
				color = NP.db.reactions.neutral
			else
				color = NP.db.reactions.enemy
			end
		elseif threatReaction == 'FULL_THREAT' then
			if classRole == 'Tank' then
				color = NP.db.threat.goodColor
				scale = NP.db.threat.goodScale
			else
				color = NP.db.threat.badColor
				scale = NP.db.threat.badScale
			end
		elseif threatReaction == 'GAINING_THREAT' then
			if classRole == 'Tank' then
				color = NP.db.threat.goodTransitionColor
			else
				color = NP.db.threat.badTransitionColor
			end
		elseif threatReaction == 'LOSING_THREAT' then
			if classRole == 'Tank' then
				color = NP.db.threat.badTransitionColor
			else
				color = NP.db.threat.goodTransitionColor
			end
		elseif InCombatLockdown() then
			if classRole == 'Tank' then
				color = NP.db.threat.badColor
				scale = NP.db.threat.badScale
			else
				color = NP.db.threat.goodColor
				scale = NP.db.threat.goodScale
			end
		else
			if unitType == "NEUTRAL_NPC" then
				color = NP.db.reactions.neutral
			else
				color = NP.db.reactions.enemy
			end
		end

		self.threatReaction = threatReaction
	elseif unitType == "FRIENDLY_NPC" then
		color = NP.db.reactions.friendlyNPC
	elseif unitType == "FRIENDLY_PLAYER" then
		color = NP.db.reactions.friendlyPlayer
	else
		color = NP.db.reactions.enemy
	end
    
	--== altered code ==--
	if (color == NP.db.reactions.enemy or color == NP.db.reactions.neutral or color == NP.db.threat.goodColor) then
		local healthValue = myPlate.healthBar:GetValue()
		local minValue, maxValue = myPlate.healthBar:GetMinMaxValues()
		local percentValue = (healthValue/maxValue)
		if percentValue < E.private.npct.low then
			color = E.private.npct.lowColor
		elseif percentValue < E.private.npct.middle then
			color = E.private.npct.middleColor
		end
	end
	--== end altered code ==--

	if(not self.customColor) then
		myPlate.healthBar:SetStatusBarColor(color.r, color.g, color.b)

		if(NP.db.targetIndicator.enable and NP.db.targetIndicator.colorMatchHealthBar and self.unit == "target") then
			NP:ColorTargetIndicator(color.r, color.g, color.b)
		end
	elseif(self.unit == "target" and NP.db.targetIndicator.colorMatchHealthBar and NP.db.targetIndicator.enable) then
		NP:ColorTargetIndicator(self.customColor.r, self.customColor.g, self.customColor.b)
	end

	local w = NP.db.healthBar.width * scale
	local h = NP.db.healthBar.height * scale
	if NP.db.healthBar.lowHPScale.enable then
		if myPlate.lowHealth:IsShown() then
			w = NP.db.healthBar.lowHPScale.width * scale
			h = NP.db.healthBar.lowHPScale.height * scale
			if NP.db.healthBar.lowHPScale.toFront then
				myPlate:SetFrameStrata("HIGH")
			end
		else
			if NP.db.healthBar.lowHPScale.toFront then
				myPlate:SetFrameStrata("BACKGROUND")
			end
		end
	end
	if(not self.customScale and not self.isSmall and myPlate.healthBar:GetWidth() ~= w) then
		myPlate.healthBar:SetSize(w, h)
		self.castBar.icon:SetSize(NP.db.castBar.height + h + 5, NP.db.castBar.height + h + 5)
	end
end


--------------------------------------------------------------------------------------------------
-- Make nameplates update more frequently and be more responsive on mouseover and target change --
--------------------------------------------------------------------------------------------------
do
	local WorldFrame = WorldFrame
	
	function NP:OnUpdate(elapsed)
		local count = WorldFrame:GetNumChildren()
		if(count ~= numChildren) then
			numChildren = count
			NP:ScanFrames(WorldFrame:GetChildren())
		end

		NP.PlateParent:Hide()
		for blizzPlate, plate in pairs(NP.CreatedPlates) do
			if(blizzPlate:IsShown()) then
				if(not self.viewPort) then
					plate:SetPoint("CENTER", WorldFrame, "BOTTOMLEFT", blizzPlate:GetCenter())
				end
				NP.SetAlpha(blizzPlate, plate)
			else
				plate:Hide()
			end
		end
		NP.PlateParent:Show()
		
		--== altered code ==--
		if(self.elapsed and self.elapsed > 0.1) then
		--== end altered code ==--
			for blizzPlate, plate in pairs(NP.CreatedPlates) do
				if(blizzPlate:IsShown() and plate:IsShown()) then
					NP.SetUnitInfo(blizzPlate, plate)
					NP.ColorizeAndScale(blizzPlate, plate)
					NP.UpdateLevelAndName(blizzPlate, plate)
				end
			end

			self.elapsed = 0
		else
			self.elapsed = (self.elapsed or 0) + elapsed
		end
	end
	
	function NP:UPDATE_MOUSEOVER_UNIT()
		WorldFrame.elapsed = 0.17
	end
	
	do
		local original_PLAYER_TARGET_CHANGED = NP.PLAYER_TARGET_CHANGED
		function NP:PLAYER_TARGET_CHANGED()
			original_PLAYER_TARGET_CHANGED(self)
			if UnitExists("target") then
				C_TimerAfter(0.01, function() WorldFrame.elapsed = 2 end)
			end
		end
	end
end


-----------------------------------------------------------------------------------
-- Redefine aura timer function to start using decimals when t < 5s instead of 4 --
-----------------------------------------------------------------------------------
do
	local TimeColors = {
		[0] = '|cffeeeeee',
		[1] = '|cffeeeeee',
		[2] = '|cffeeeeee',
		[3] = '|cffFFEE00',
		[4] = '|cfffe0000',
	}
	
	function NP:UpdateAuraTime(frame, expiration)
		local timeleft = expiration-GetTime()
		local timervalue, formatid = E:GetTimeInfo(timeleft, 5)
		local format = E.TimeFormats[3][2]
		if timervalue < 5 then
			format = E.TimeFormats[4][2]
		end
		frame.TimeLeft:SetFormattedText(("%s%s|r"):format(TimeColors[formatid], format), timervalue)
	end
end


--------------------
-- Initialization --
--------------------
function NPCT:Initialize()
	EP:RegisterPlugin(addon, self.AddOptions)
end