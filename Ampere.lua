
local myname, ns = ...
local L = ns.L
local Refresh = function() end
local EDGEGAP, ROWHEIGHT, ROWGAP, GAP = 16, 50, 2, 4
local NUMADDONS = GetNumAddOns()
local GOLD_TEXT = {1.0, 0.82, 0}
local RED_TEXT = {1, 0, 0}
local STATUS_COLORS = setmetatable({
	DISABLED = {157/256, 157/256, 157/256},
	DEP_DISABLED = {157/256, 157/256, 157/256},
	NOT_DEMAND_LOADED = {1, 0.5, 0},
	DEP_NOT_DEMAND_LOADED = {1, 0.5, 0},
	LOAD_ON_DEMAND = {30/256, 1, 0},
	DISABLED_AT_RELOAD = {163/256, 53/256, 238/256},
	LOADED_AT_RELOAD = {1, 0.2, 0},
	DEP_MISSING = {1, 0.5, 0},
}, {__index = function() return RED_TEXT end})


local enabledstates = setmetatable({}, {
	__index = function(t, i)
		local name, _, _, enabled = GetAddOnInfo(i)
		if name ~= i then return t[name] end

		t[i] = not not enabled -- Looks silly, but ensures we store a boolean
		return enabled
	end
})


-- We have to hook these, GetAddOnInfo doesn't report back the new enabled state
local orig1, orig2, orig3, orig4 = EnableAddOn, DisableAddOn, EnableAllAddOns, DisableAllAddOns
local function posthook(...) Refresh(); return ... end
EnableAddOn = function(addon, ...)
	enabledstates[GetAddOnInfo(addon)] = true
	return posthook(orig1(addon, ...))
end
DisableAddOn = function(addon, ...)
	enabledstates[GetAddOnInfo(addon)] = false
	return posthook(orig2(addon, ...))
end
EnableAllAddOns = function(...)
	for i=1,NUMADDONS do enabledstates[GetAddOnInfo(i)] = true end
	return posthook(orig3(...))
end
DisableAllAddOns = function(...)
	for i=1,NUMADDONS do enabledstates[GetAddOnInfo(i)] = false end
	return posthook(orig4(...))
end


local frame = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
frame.name = "Ampere"
frame:Hide()
frame:SetScript("OnShow", function(frame)
	local function MakeButton(parent)
		local butt = CreateFrame("Button", nil, parent or frame)
		butt:SetWidth(80) butt:SetHeight(22)

		butt:SetHighlightFontObject(GameFontHighlightSmall)
		butt:SetNormalFontObject(GameFontNormalSmall)

		butt:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
		butt:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
		butt:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
		butt:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
		butt:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
		butt:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
		butt:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)
		butt:GetDisabledTexture():SetTexCoord(0, 0.625, 0, 0.6875)
		butt:GetHighlightTexture():SetBlendMode("ADD")

		return butt
	end


	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(L["Addon Management Panel"])


	local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
--~ 	subtitle:SetHeight(32)
	subtitle:SetHeight(35)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetPoint("RIGHT", frame, -32, 0)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
--~ 	subtitle:SetMaxLines(3)
	subtitle:SetText(L["This panel can be used to toggle addons, load Load-on-Demand addons, or reload the UI.  You must reload UI to unload an addon.  Settings are saved on a per-char basis."])

	local rows, anchor = {}
	local function helper(...)
		for i=1,select("#", ...) do
			local dep = select(i, ...)
			local loaded = IsAddOnLoaded(dep) and 1 or 0
			GameTooltip:AddDoubleLine(i == 1 and L["Dependencies:"] or " ", dep, 1, 0.4, 0, 1, loaded, loaded)
		end
	end
	local function OnEnter(self)
		local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(self.addon)
		local author = GetAddOnMetadata(self.addon, "Author")
		local version = GetAddOnMetadata(self.addon, "Version")
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:AddLine(title, nil, nil, nil, true)
		GameTooltip:AddLine(notes, 1, 1, 1, true)
		if author then GameTooltip:AddDoubleLine(L["Author:"], author, 1,0.4,0, 1,1,1) end
		if version then GameTooltip:AddDoubleLine(L["Version:"], version, 1,0.4,0, 1,1,1) end
		helper(GetAddOnDependencies(self.addon))
		GameTooltip:Show()
	end
	local function OnLeave() GameTooltip:Hide() end
	local function OnClick(self)
		local addon = self.addon
		local enabled = enabledstates[addon]
		PlaySound(enabled and "igMainMenuOptionCheckBoxOff" or "igMainMenuOptionCheckBoxOn")
		if enabled then DisableAddOn(addon) else EnableAddOn(addon) end
		Refresh()
	end
	local function LoadOnClick(self)
		local addon = self:GetParent().addon
		if not select(4,GetAddOnInfo(addon)) then
			EnableAddOn(addon)
			LoadAddOn(addon)
			DisableAddOn(addon)
		else LoadAddOn(addon) end
	end
	local function OnButtEntry(self)
		self.row:LockHighlight()
		OnEnter(self.row)
	end
	local function OnButtPullout(self)
		self.row:UnlockHighlight()
		OnLeave(self.row)
	end
	for i=1,math.floor((frame:GetHeight()-145)/(ROWHEIGHT + ROWGAP))*2 do
		local row = CreateFrame("CheckButton", nil, frame)
		if not anchor then
			row:SetPoint("TOP", subtitle, "BOTTOM", 0, -16)
			row:SetPoint("LEFT", EDGEGAP, 0)
			row:SetPoint("RIGHT", frame, "CENTER", -3, 0)
		elseif i%2 == 0 then
			row:SetPoint("TOP", anchor, "TOP")
			row:SetPoint("LEFT", frame, "CENTER", 3, 0)
			row:SetPoint("RIGHT", -EDGEGAP*2-8, 0)
		else
			row:SetPoint("TOP", anchor, "BOTTOM", 0, -ROWGAP)
			row:SetPoint("LEFT", EDGEGAP, 0)
			row:SetPoint("RIGHT", frame, "CENTER", -3, 0)
			-- row:SetPoint("RIGHT", -EDGEGAP*2-8, 0)
		end
		row:SetHeight(ROWHEIGHT)

		row:SetScript("OnClick", OnClick)

		row:SetNormalTexture("Interface\\ClassTrainerFrame\\TrainerTextures")
		row:GetNormalTexture():SetTexCoord(0.00195313, 0.57421875, 0.65820313, 0.75000000)
		row:SetCheckedTexture("Interface\\ClassTrainerFrame\\TrainerTextures")
		row:GetCheckedTexture():SetTexCoord(0.00195313, 0.57421875, 0.84960938, 0.94140625)
		row:GetCheckedTexture():SetVertexColor(1,1,1,0.35)
		row:GetCheckedTexture():SetBlendMode("ADD")
		row:SetHighlightTexture("Interface\\ClassTrainerFrame\\TrainerTextures")
		row:GetHighlightTexture():SetTexCoord(0.00195313, 0.57421875, 0.75390625, 0.84570313)
		row:GetHighlightTexture():SetBlendMode("ADD")

		if i%2 == 1 then anchor = row end
		rows[i] = row

		--
		-- <Layer level="BACKGROUND">
		-- 	<Texture parentKey="disabledBG" hidden="true" alphaMode="MOD">
		-- 		<Anchors>
		-- 			<Anchor point="TOPLEFT" x="2" y="-2"/>
		-- 			<Anchor point="BOTTOMRIGHT" x="-2" y="2"/>
		-- 		</Anchors>
		-- 		<Color r="0.55" g="0.55" b="0.55" a="1"/>
		-- 	</Texture>
		-- </Layer>
		--

		local icon = row:CreateTexture(nil, "OVERLAY")
		icon:SetSize(32, 32)
		icon:SetPoint("TOPLEFT", 2, -2)
		row.icon = icon


		local version = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		version:SetPoint("TOP", icon, "TOP", -4, 0)
		version:SetPoint("RIGHT", row, "RIGHT", -4, 0)
		-- version:SetDrawLayer("OVERLAY")
		row.version = version


		local title = row:CreateFontString(nil, "OVERLAY", "GameTooltipHeaderText")
		title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 4, 0)
		title:SetPoint("RIGHT", version, "LEFT", -4, 0)
		-- title:SetDrawLayer("OVERLAY")
		row.title = title


		local subtitle = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, 0)
		subtitle:SetPoint("RIGHT", row, "RIGHT", -4, 0)
		subtitle:SetJustifyH("LEFT")
		-- subtitle:SetDrawLayer("OVERLAY")
		row.subtitle = subtitle


		local loadbutton = MakeButton(row)
		loadbutton:SetPoint("BOTTOMRIGHT", -2, 2)
		loadbutton:SetText(L["Load"])
		loadbutton:SetScript("OnClick", LoadOnClick)
		loadbutton:SetScript("OnEnter", OnButtEntry)
		loadbutton:SetScript("OnLeave", OnButtPullout)
		loadbutton.row = row
		row.loadbutton = loadbutton


		local reason = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		reason:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, 0)
		-- reason:SetDrawLayer("OVERLAY")
		row.reason = reason

		row:SetScript("OnEnter", OnEnter)
		row:SetScript("OnLeave", OnLeave)
	end


	local offset = 0
	Refresh = function()
		if not frame:IsVisible() then return end
		for i,row in ipairs(rows) do
			if (i + offset) <= NUMADDONS then
				local name, title, notes, enabled, loadable, reason = GetAddOnInfo(i + offset)
				local version = GetAddOnMetadata(i + offset, "Version")
				local launchericon = GetAddOnMetadata(i + offset, "X-LoadOn-LDB-Launcher")

				local loaded = IsAddOnLoaded(i + offset)
				local lod = IsAddOnLoadOnDemand(i + offset)
				if lod and not loaded and (not reason or reason == "DISABLED") then
					reason = "LOAD_ON_DEMAND"
					row.loadbutton:Show()
					row.loadbutton:SetWidth(45)
				else
					row.loadbutton:Hide()
					row.loadbutton:SetWidth(1)
				end
				if loaded and not enabledstates[name] then reason = "DISABLED_AT_RELOAD" end
				if enabled and not loaded and not lod then reason = "LOADED_AT_RELOAD" end

				row:SetChecked(enabledstates[name])
				row.icon:SetTexture(launchericon or "Interface\\Icons\\INV_Misc_EngGizmos_30")
				row.title:SetText(title)
				row.version:SetText(version)
				row.subtitle:SetText(notes)
				row.reason:SetText(reason and (TEXT(_G["ADDON_" .. reason] or L[reason])))
				row.title:SetTextColor(unpack(not enabled and STATUS_COLORS.DISABLED or GOLD_TEXT))
				if reason then row.reason:SetTextColor(unpack(STATUS_COLORS[reason])) end
				row.addon = name
				row.notes = notes
				row:Show()
			else
				row:Hide()
			end
		end
	end
	frame:SetScript("OnEvent", Refresh)
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnShow", Refresh)
	Refresh()


	local scrollbar = LibStub("tekKonfig-Scroll").new(frame, nil, #rows/2)
	scrollbar:ClearAllPoints()
	scrollbar:SetPoint("TOP", rows[1], 0, -16)
	scrollbar:SetPoint("BOTTOM", rows[#rows], 0, 16)
	scrollbar:SetPoint("RIGHT", -16, 0)
	scrollbar:SetMinMaxValues(0, math.max(0, NUMADDONS-#rows))
	scrollbar:SetValue(0)
	scrollbar:SetValueStep(2)

	local f = scrollbar:GetScript("OnValueChanged")
	scrollbar:SetScript("OnValueChanged", function(self, value, ...)
		offset = value
		Refresh()
		return f(self, value, ...)
	end)

	frame:EnableMouseWheel()
	frame:SetScript("OnMouseWheel", function(self, val) scrollbar:SetValue(scrollbar:GetValue() - val*#rows/2 - 1) end)


	local enableall = MakeButton()
	enableall:SetPoint("BOTTOMLEFT", 16, 16)
	enableall:SetText(L["Enable All"])
	enableall:SetScript("OnClick", EnableAllAddOns)


	local disableall = MakeButton()
	disableall:SetPoint("LEFT", enableall, "RIGHT", 4, 0)
	disableall:SetText(L["Disable All"])
	disableall:SetScript("OnClick", DisableAllAddOns)


	local reload = MakeButton()
	reload:SetPoint("BOTTOMRIGHT", -16, 16)
	reload:SetText(L["Reload UI"])
	reload:SetScript("OnClick", ReloadUI)
end)

InterfaceOptions_AddCategory(frame)


LibStub("tekKonfig-AboutPanel").new("Ampere", "Ampere")


----------------------------------------
--      Quicklaunch registration      --
----------------------------------------

local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Ampere", {
	type = "launcher",
	icon = "Interface\\Icons\\Spell_Nature_StormReach",
	OnClick = function() InterfaceOptionsFrame_OpenToCategory(frame) end,
})


----------------------------
--      Reload Slash      --
----------------------------

SLASH_RELOAD1 = "/rl"
SlashCmdList.RELOAD = ReloadUI
