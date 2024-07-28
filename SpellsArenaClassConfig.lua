local _, L = ...;

L.SpellsArenaClassConfig = {}; -- adds SpellsArenaClassConfig table to addon namespace

local SpellsArenaClassConfig = L.SpellsArenaClassConfig;
local UISpellsArenaClassConfig;
local tooltip = CreateFrame("GameTooltip", "fPBMouseoverTooltip", UIParent, "GameTooltipTemplate")
local UIParent = UIParent -- it's faster to keep local references to frequently used global vars
local UnitCanAttack = UnitCanAttack
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitIsPlayer = UnitIsPlayer
local UnitIsUnit = UnitIsUnit
local UnitIsEnemy = UnitIsEnemy
local UnitHealth = UnitHealth
local UnitName = UnitName
local UnitGUID = UnitGUID
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local IsInInstance = IsInInstance
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local GetName = GetName
local GetNumGroupMembers = GetNumGroupMembers
local GetNumArenaOpponents = GetNumArenaOpponents
local GetInstanceInfo = GetInstanceInfo
local GetZoneText = GetZoneText
local SetPortraitToTexture = SetPortraitToTexture
local ipairs = ipairs
local pairs = pairs
local next = next
local type = type
local select = select
local strsplit = strsplit
local strfind = string.find
local strmatch = string.match
local tblinsert = table.insert
local tblremove= table.remove
local mathfloor = math.floor
local mathabs = math.abs
local bit_band = bit.band
local tblsort = table.sort
local substring = string.sub
local tonumber = tonumber
local unpack = unpack
local SetScript = SetScript
local SetUnitDebuff = SetUnitDebuff
local SetOwner = SetOwner
local OnEvent = OnEvent
local CreateFrame = CreateFrame
local SetTexture = SetTexture
local SetNormalTexture = SetNormalTexture
local SetSwipeTexture = SetSwipeTexture
local SetCooldown = SetCooldown
local SetAlpha, SetPoint, SetParent, SetFrameLevel, SetDrawSwipe, SetSwipeColor, SetScale, SetHeight, SetWidth, SetDesaturated, SetVertexColor = SetAlpha, SetPoint, SetParent, SetFrameLevel, SetDrawSwipe, SetSwipeColor,  SetScale, SetHeight, SetWidth, SetDesaturated, SetVertexColor
local SetText = SetText
local SetChecked = SetChecked
local Disable = Disable
local AddLine = AddLine
local AddDoubleLine = AddDoubleLine
local GetVerticalScrollRange = GetVerticalScrollRange
local SetOwner = SetOwner
local getglobal = getglobal
local GetVerticalScroll = GetVerticalScroll
local GetChecked = GetChecked
local SetSpellByID = SetSpellByID
local CreateFontString = CreateFontString
local GetStringWidth = GetStringWidth
local _G = _G
local ClearAllPoints = ClearAllPoints
local GetParent = GetParent
local GetFrameLevel = GetFrameLevel
local GetDrawSwipe = GetDrawSwipe
local GetDrawLayer = GetDrawLayer
local GetAlpha = GetAlpha
local Hide = Hide
local Show = Show
local IsShown = IsShown
local IsVisible = IsVisible
local playerGUID
local print = print
local contents = {};
--------------------------------------
-- Defaults (usually a database!)
--------------------------------------
local defaults = {
	theme = {
		r = 0,
		g = 0.8, -- 204/255
		b = 1,
		hex = "00ccff"
	}
}


local tabs = {
	"DEATHKNIGHT",
	"DEMONHUNTER",
	"DRUID",
	"EVOKER",
	"HUNTER", -- Needs to be same
	"MAGE",
	"MONK",
	"PALADIN",
	"PRIEST",
	"ROGUE",
	"SHAMAN",
	"WARLOCK",
	"WARRIOR",
	"Racials",
	"PvP",
}


local tabsdropdown = {
	"Drink_Purge",
	"Immune_Arena",
	"CC_Arena",
	"Silence_Arena",
	"Interrupt", -- Needs to be same
	"Special_High",
	"Ranged_Major_OffenisiveCDs",
	"Roots_90_Snares",
	"Disarms",
	"Melee_Major_OffenisiveCDs",
	"Big_Defensive_CDs",
	"Player_Party_OffensiveCDs",
	"Small_Offenisive_CDs",
	"Small_Defensive_CDs",
	"Freedoms_Speed",
	"Snares_WithCDs",
	"Special_Low",
	"Snares_Ranged_Spamable",
	"Snares_Casted_Melee",
}

local tabsIndex = {}
for i = 1, #tabsdropdown do
	tabsIndex[tabsdropdown[i]] = i
end

local tabsDrop = {}
for i = 1, # tabsdropdown + 1 do
	if not  tabsdropdown[i] then
		tabsDrop[i] = "Delete"
	else
		tabsDrop[i] =  tabsdropdown[i]
	end
end

local function GetThemeColor()
	local c = defaults.theme;
	return c.r, c.g, c.b, c.hex;
end

local hexFontColors = {
	["Racials"] = "FF666666",
    ["PvP"] = "FFB9B9B9",
    ["PvE"] = "FF00FE44",
    ["logo"] = "ffff7a00",
}

for class, val in pairs(RAID_CLASS_COLORS) do
	hexFontColors[class] = val.colorStr
end

local function Colorize(text, color)
    if not text then return end
    local hexColor = hexFontColors[color] or hexFontColors["blizzardFont"]
	if hexColor then
    	return "|c" .. hexColor .. text .. "|r"
	end
end


local function ScrollFrame_OnMouseWheel(self, delta)
	local newValue = self:GetVerticalScroll() - (delta * 20);

	if (newValue < 0) then
		newValue = 0;
	elseif (newValue > self:GetVerticalScrollRange()) then
		newValue = self:GetVerticalScrollRange();
	end

	self:SetVerticalScroll(newValue);
end

local function PanelTemplates_DeselectTab(tab)
	local name = tab:GetName();
	tab.Left:Show();
	tab.Middle:Show();
	tab.Right:Show();
	tab:Enable();
	tab:Enable();
	tab.LeftActive:Hide();
	tab.MiddleActive:Hide();
	tab.RightActive:Hide();
end

local function PanelTemplates_SelectTab(tab)
	local name = tab:GetName();
	tab.Left:Hide();
	tab.Middle:Hide();
	tab.Right:Hide();
	--tab:LockHighlight();
	tab:Disable();
	tab.LeftActive:Show();
	tab.MiddleActive:Show();
	tab.RightActive:Show();

	local tooltip = GetAppropriateTooltip();
	if tooltip:IsOwned(tab) then
		tooltip:Hide();
	end
end

local function PanelTemplates_SetDisabledTabState(tab)
	local name = tab:GetName();
	tab.Left:Show();
	tab.Middle:Show();
	tab.Right:Show();
	--tab:UnlockHighlight();
	tab:Disable();
	tab.text = tab:GetText();
	-- Gray out text
	tab:SetDisabledTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
	tab.LeftActive:Hide();
	tab.MiddleActive:Hide();
	tab.RightActive:Hide();
end

local function PanelTemplates_UpdateTabs(frame)
	if ( frame.selectedTab ) then
		local tab;
		for i=1, frame.numTabs, 1 do
			tab = getglobal(frame:GetName().."Tab"..i);
			if ( tab.isDisabled ) then
				PanelTemplates_SetDisabledTabState(tab);
			elseif ( i == frame.selectedTab ) then
				PanelTemplates_SelectTab(tab);
			else
				PanelTemplates_DeselectTab(tab);
			end
		end
	end
end

local function PanelTemplates_SetTab(frame, id)
	frame.selectedTab = id;
	PanelTemplates_UpdateTabs(frame);
end

local function Tab_OnClick(self)
	PanelTemplates_SetTab(self:GetParent(), self:GetID());

	local scrollChild = UISpellsArenaClassConfig.ScrollFrame:GetScrollChild();
	if (scrollChild) then
		scrollChild:Hide();
	end

	UISpellsArenaClassConfig.ScrollFrame:SetScrollChild(self.content);
	self.content:Show();
end

local function makeAndShowSpellTTPVE(self)
	GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
	if type(self.spellID) == "number" then
	GameTooltip:SetSpellByID(self.spellID)
	else
		GameTooltip:SetText(self.spellID, 1, 1, 1, true)
		GameTooltip:AddLine("This Spell Uses the Name not SpellID.", 1.0, 0.82, 0.0, true);
	end
	if (self:GetChecked()) then
		GameTooltip:AddDoubleLine("|cff66FF00Enabled")
	else
		GameTooltip:AddDoubleLine("|cffFF0000Disabled")
	end
	GameTooltip:Show()
end

local function DeleteSpellFrame(spellID, duration, c)
	if spellID and duration then
		if _G[c:GetName().."spellCheck"..spellID..duration] then
			_G[c:GetName().."spellCheck"..spellID..duration] = nil
		end
	elseif _G[c:GetName().."spellCheck"..spellID] then
			_G[c:GetName().."spellCheck"..spellID] = nil
	end
end

local function GetSpellFrame(spellID, duration, c)
	if spellID and duration then
		if _G[c:GetName().."spellCheck"..spellID..duration] then
			return _G[c:GetName().."spellCheck"..spellID..duration]
		end
	elseif _G[c:GetName().."spellCheck"..spellID] then
		return _G[c:GetName().."spellCheck"..spellID]
	else
		return false
	end 
end

local function CustomAddedCompileSpells(spell, prio, i)
	local class = tabs[i]

	for k, v in ipairs(_G.LoseControlDB.customSpellIdsArena) do
		if spell == v[1] then
			tblremove(_G.LoseControlDB.customSpellIdsArena, k)
			break
		end
	end
	local oldPrioF
	for y = 1, #L.spellsArena do
		for l = 1, #L.spellsArena[y] do
			local spellID, oldPrio, _, _, duration, customname = unpack(L.spellsArena[y][l])
			if spell == spellID and (not duration) then
				print(oldPrio)
				oldPrioF = oldPrio
				local priotext = L[oldPrio] or oldPrio
				L.SpellsArenaClassConfig:WipeSpellList(i); print("|cff00ccffLoseControl|r : ".."|cff009900Removed |r"..spellID.." |cff009900from : |r"..priotext.." (Arena)")
				L.spellsArena[y][l] = nil 
				tblremove(L.spellsArena[y], l)
				break
			end
		end
	end
	L.classIds[spell] = class
	local name = GetSpellInfo(spell)
	if name then 
		L.classIds[name] = class
	end
	L.spellIdsArena[spell] = prio
	_G.LoseControlDB.spellEnabledArena[spell]= true
	if _G["LoseControlSpellsArenaConfig"] and oldPrioF then 
		L.SpellsArenaConfig:WipeSpellList(tabsIndex[oldPrioF])
	end
	if _G["LoseControlSpellsArenaConfig"] then
		L.SpellsArenaConfig:WipeSpellList(tabsIndex[prio]) 
	end
	tblinsert(_G.LoseControlDB.customSpellIdsArena, {spell, prio, nil, nil, nil, "Custom Spell", nil, nil, class})
	tblinsert(L.spellsArena[tabsIndex[prio]], 1, {spell, prio, nil, nil, nil, "Custom Spell",  nil, nil, class})
	if _G["LoseControlSpellsArenaConfig"] and oldPrioF then 
		L.SpellsArenaConfig:UpdateSpellList(tabsIndex[oldPrioF]) 
	end
	if _G["LoseControlSpellsArenaConfig"] then
		L.SpellsArenaConfig:UpdateSpellList(tabsIndex[prio]) 
	end
	local priotext = L[prio] or prio
	print("|cff00ccffLoseControl|r : ".."|cff009900Added |r"..spell.." |cff009900to to list: |r"..priotext.." (Arena)")
	L.SpellsArenaClassConfig:WipeSpellList(i)
	L.SpellsArenaClassConfig:UpdateSpellList(i)
	L.OptionsFunctions:UpdateAll()
end

local function CustomPVPDropDownCompileSpells(spell , newPrio, i, c, duration)
	local class = tabs[i]
	for k, v in ipairs(_G.LoseControlDB.customSpellIdsArena) do
		if spell == v[1] then
			tblremove(_G.LoseControlDB.customSpellIdsArena, k)
			break
		end
	end
	for y = 1, #L.spellsArena do
		for l = 1, #L.spellsArena[y] do
			local spellID, oldPrio, _, _, duration, customname = unpack(L.spellsArena[y][l])
			if spell == spellID and (not duration) then
				if _G["LoseControlSpellsArenaConfig"] then 
					L.SpellsArenaConfig:WipeSpellList(tabsIndex[oldPrio])
				end
				L.spellsArena[y][l] = nil 
				tblremove(L.spellsArena[y], l)
				local priotext = L[oldPrio] or oldPrio
				print("|cff00ccffLoseControl|r : ".."|cff009900Removed |r"..spellID.." |cff009900from list: |r"..priotext.." (Arena)")
				if newPrio == "Delete" then
					L.spellIdsArena[spell] = nil
					_G.LoseControlDB.spellEnabledArena[spell]= nil
					if L.spellsArenaLua[spell] then
						tblinsert(_G.LoseControlDB.customSpellIdsArena, {spell, newPrio, nil, nil, nil, customname})  --v[7]: Category Tab to enter spell
					end
					DeleteSpellFrame(spell, duration, c)
					local name = GetSpellInfo(spellID)
					if L.classIds[spellID] then 
						L.classIds[spellID] = nil
					end
					if L.classIds[name] then 
						L.classIds[name] = nil 
					end
					if _G["LoseControlSpellsArenaConfig"] then 
						L.SpellsArenaConfig:UpdateSpellList(tabsIndex[oldPrio])
					end
					SpellsArenaClassConfig:WipeSpellList(i)
					SpellsArenaClassConfig:UpdateSpellList(i)
					L.OptionsFunctions:UpdateAll()
				else
					L.spellIdsArena[spell] = newPrio
					tblinsert(_G.LoseControlDB.customSpellIdsArena, {spell, newPrio, nil, nil, nil, "Custom Priority", nil, nil, class})
					tblinsert(L.spellsArena[tabsIndex[newPrio]], 1, {spell, newPrio, nil, nil, nil, "Custom Priority", nil, nil, class})
					local priotext = L[newPrio] or newPrio
					print("|cff00ccffLoseControl|r : ".."|cff009900Added |r"..spell.." |cff009900to to list: |r"..priotext.." (Arena)")
					L.classIds[spellID] = class
					local name = GetSpellInfo(spellID)
					if name then 
						L.classIds[name] = class
					end
					if _G["LoseControlSpellsArenaConfig"] then 
						L.SpellsArenaConfig:UpdateSpellList(tabsIndex[oldPrio]);L.SpellsArenaConfig:UpdateTab(tabsIndex[newPrio]);
					end
					SpellsArenaClassConfig:WipeSpellList(i)
					SpellsArenaClassConfig:UpdateSpellList(i);
					L.OptionsFunctions:UpdateAll()
				end
				return
			end
		end
	end
end

local function createDropdown(opts)
	local dropdown_name = '$parent_' .. opts['name'] .. '_dropdown'
	local menu_items = opts['items'] or {}
	local title_text = opts['title'] or ''
	local dropdown_width = 0
	local default_val = opts['defaultVal'] or ''
	local change_func = opts['changeFunc'] or function (dropdown_val) end

	local dropdown = CreateFrame("Frame", dropdown_name, opts['parent'], 'UIDropDownMenuTemplate')
	local dd_title = dropdown:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	dd_title:SetPoint("TOPLEFT", 20, 10)

	for _, item in pairs(menu_items) do -- Sets the dropdown width to the largest item string width.
		dd_title:SetText(item)
		local text_width = dd_title:GetStringWidth() + 20
		if text_width > dropdown_width then
			dropdown_width = text_width
		end
	end

	UIDropDownMenu_SetWidth(dropdown, 1)
	UIDropDownMenu_SetText(dropdown, 1)
	dd_title:SetText(title_text)

	UIDropDownMenu_Initialize(dropdown, function(self, level, _)
		local info = UIDropDownMenu_CreateInfo()
		for key, val in pairs(menu_items) do
					if L[val] then val = L[val] end
			info.text = val;
			info.checked = false
						if val == default_val then
							info.checked = true
						end
			info.menuList= key
			info.hasArrow = false
			info.func = function(b)
				UIDropDownMenu_SetSelectedValue(dropdown, b.value, b.value)
				UIDropDownMenu_SetText(dropdown, b.value)
				b.checked = true
				change_func(dropdown, b.value)
			end
			UIDropDownMenu_AddButton(info)
		end
	end)

	return dropdown
end


local function createDropdownAdd(opts)
	local dropdown_name = '$parent_' .. opts['name'] .. '_dropdown'
	local menu_items = opts['items'] or {}
	local title_text = opts['title'] or ''
	local dropdown_width = 0
	local default_val = opts['defaultVal'] or ''
	local change_func = opts['changeFunc'] or function (dropdown_val) end

	local dropdown = CreateFrame("Frame", dropdown_name, opts['parent'], 'UIDropDownMenuTemplate')
	local dd_title = dropdown:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	dd_title:SetPoint("TOPLEFT", 20, 10)

	for _, item in pairs(menu_items) do -- Sets the dropdown width to the largest item string width.
		dd_title:SetText(item)
		local text_width = dd_title:GetStringWidth() + 20
		if text_width > dropdown_width then
			dropdown_width = text_width
		end
	end

	UIDropDownMenu_SetWidth(dropdown, dropdown_width)
	UIDropDownMenu_SetText(dropdown, dropdown_val)
	dd_title:SetText(title_text)

	UIDropDownMenu_Initialize(dropdown, function(self, level, _)
		local info = UIDropDownMenu_CreateInfo()
		for key, val in pairs(menu_items) do
					if L[val] then val = L[val] end
			info.text = val;
			info.checked = false
			info.menuList= key
			info.hasArrow = false
			info.func = function(b)
				UIDropDownMenu_SetSelectedValue(dropdown, b.value, b.value)
				UIDropDownMenu_SetText(dropdown, b.value)
				b.checked = true
				change_func(dropdown, b.value)
			end
			UIDropDownMenu_AddButton(info)
		end
	end)

	return dropdown
end

local function SetTabs(frame, numTabs, ...)
	frame.numTabs = numTabs;

	local frameName = frame:GetName();
	local width = {}
	local rows = 1
	local rowCount = 1
	local tabsize = 80
	local tabwidth = 80
	local name

	for i = 1, numTabs do
		local tab = CreateFrame("Button", frameName.."Tab"..i, frame, "PanelTabButtonTemplate"); --changed to PanelTabButtonTemplate
		tab:SetID(i);
		tab:SetFrameLevel(10)
		tab:SetWidth(100)
		tab.t = tab:CreateFontString(nil, "OVERLAY", "GameTooltipText")
		tab.t:SetFont("Fonts\\FRIZQT__.TTF", 9 )


		if L[select(i, ...)] then
			name = L[select(i, ...)]
			tab.tooltip = L[select(i, ...)]
			for i = 1, tabwidth do
				tab:SetText("                          ")
				tab.t:SetText(name)
				if tab.t:GetStringWidth() > tabsize then
					name = substring(name, 0, tabwidth- i)
				else
					break
				end
			end
			tab.t:SetPoint("CENTER", tab, "CENTER", 0, 0)
		else
			name = tabs[i]
			tab.tooltip = tabs[i]
			tab:SetText("                          ")
			for i = 1, tabwidth do
				tab.t:SetText(name)
				if tab.t:GetStringWidth() > tabsize then
					name = substring(name, 0, tabwidth - i)
				else
					break
				end
			end
			tab.t:SetPoint("CENTER", tab, "CENTER", 0, 0)
		end

		tab:SetScript("OnEnter", function(self, motion)
			GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
			GameTooltip:SetText(self.tooltip)
		end)

		tab:SetScript("OnLeave", function(self, motion)
			GameTooltip:Hide()
		end)

		tab:SetScript("OnClick", Tab_OnClick);
		tab.content = CreateFrame("Frame", tab:GetName()..'Content', UISpellsArenaClassConfig.ScrollFrame);
		tab.content:SetSize(760, 360);
		tab.content:Hide();
		tab.content.bg = tab.content:CreateTexture(nil, "BACKGROUND");
		tab.content.bg:SetAllPoints(true);
		tab.content.spellstext  =	tab.content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		--tab.content.bg:SetColorTexture(math.random(), math.random(), math.random(), 0.6);

		table.insert(contents, tab.content);

		if tabs[i] == "Interrupt" then
		else
			tab.content.input = CreateFrame("EditBox", tab:GetName()..'CustomSpells', 	tab.content, 'InputBoxTemplate')
			tab.content.input:SetSize(170,22)
			tab.content.input:SetAutoFocus(false)
			tab.content.input:SetMaxLetters(30)
			tab.content.input:SetPoint("TOPLEFT", tab.content, "TOPRIGHT", 25, -14)
			tab.content.input:SetScript('OnChar', function(self, customspelltext)
				tab.content.input.customspelltext = self:GetText()
	    	end)
			

			local drop_val
			local drop_opts = {
					['name']='raid',
					['parent']= tab.content.input,
					['title']='',
					['items']= tabsdropdown,
					['defaultVal']='',
					['changeFunc'] = function(dropdown_frame, dropdown_val)
					drop_val = dropdown_val
					for k, v in ipairs(tabsdropdown) do
							if dropdown_val == L[v] then
								drop_val = v
							end
						end
					end
			}
			local dropdown = createDropdownAdd(drop_opts)
			dropdown:SetPoint("TOP", tab.content.input, "CENTER", 0, -10)
			dropdown:SetScale(.8)

			tab.content.add = CreateFrame("Button",  tab:GetName()..'CustomSpellsButton', 	tab.content.input, "UIPanelButtonTemplate")
			tab.content.add:SetSize(40, 22)
			tab.content.add:SetPoint("TOPLEFT",	tab.content.input, "TOPRIGHT", 2, 0)
			tab.content.add:SetText("Add")
			tab.content.add:SetScript("OnClick", function(self, addenemy)
				local spell = GetSpellInfo(tonumber(tab.content.input.customspelltext))
				if spell then spell = tonumber(tab.content.input.customspelltext) else spell = tab.content.input.customspelltext end
				if drop_val and tab.content.input.customspelltext then
					CustomAddedCompileSpells(spell, drop_val, i)
				else
					print("|cff00ccffLoseControl|r : Please Select a Spell Type or Enter a spellId or Name")
				end
	    	end)
		end

		tab.content.reset = CreateFrame("Button",  tab:GetName()..'CustomSpellsButton', 	tab.content, "UIPanelButtonTemplate")
		tab.content.reset:SetSize(70,22)
		tab.content.reset:SetScale(.7)
		if tabs[i] == "Interrupt" then
			tab.content.reset:SetPoint("CENTER", tab.content,  "CENTER", 860, 245 )
		else
			tab.content.reset:SetPoint("CENTER", tab.content,  "CENTER", 860, 197 )
		end
		tab.content.reset:SetText("Enable All")
		tab.content.reset:SetScript("OnClick", function(self, enable)
			SpellsArenaClassConfig:EnableAll(i)
			L.OptionsFunctions:UpdateAll()
		end)


		tab.content.disable = CreateFrame("Button",  tab:GetName()..'CustomSpellsButton', 	tab.content, "UIPanelButtonTemplate")
		tab.content.disable:SetSize(70,22)
		tab.content.disable:SetScale(.7)
		tab.content.disable:SetPoint("CENTER",	tab.content.reset,  "CENTER", 0, -20)
		tab.content.disable:SetText("Disable All")
		tab.content.disable:SetScript("OnClick", function(self, disable)
			SpellsArenaClassConfig:DisableAll(i)
			L.OptionsFunctions:UpdateAll()
		end)


		if (i == 1) then
		tab:SetPoint("TOPLEFT", UISpellsArenaClassConfig, "BOTTOMLEFT", 6, 7);
		rowCount = 1
		else
			if rowCount <= 9 then
				tab:SetPoint("TOPLEFT", _G[frameName.."Tab"..(i - 1)], "TOPRIGHT", -3.25, 0);
				rowCount = rowCount + 1
	    	else
				y = 7 - (25 * rows)
				tab:SetPoint("TOPLEFT", UISpellsArenaClassConfig, "BOTTOMLEFT", 6, y);
				rows = rows + 1
				rowCount = 1
	    	end
		end
	end

	Tab_OnClick(_G[frameName.."Tab1"]);

	return contents;
end

local function CreateMenu()
	UISpellsArenaClassConfig = CreateFrame("Frame", "LoseControlSpellsArenaClassConfig", UIParent, "UIPanelDialogTemplate");
	local hex = select(4, GetThemeColor());
	local BambiTag = string.format("|cff%s%s|r", hex:upper(), "By Bambi");
	UISpellsArenaClassConfig.Title:SetText('LoseControl PVP Spells Config '..BambiTag)
	UISpellsArenaClassConfig:SetFrameStrata("DIALOG");
	UISpellsArenaClassConfig:SetFrameLevel(20);
	UISpellsArenaClassConfig:EnableMouse(true);
	UISpellsArenaClassConfig:SetMovable(true)
	UISpellsArenaClassConfig:RegisterForDrag("LeftButton")
	UISpellsArenaClassConfig:SetScript("OnDragStart", UISpellsArenaClassConfig.StartMoving)
	UISpellsArenaClassConfig:SetScript("OnDragStop", UISpellsArenaClassConfig.StopMovingOrSizing)

	UISpellsArenaClassConfig:SetSize(1050, 400);
	UISpellsArenaClassConfig:SetPoint("CENTER"); -- Doesn't need to be ("CENTER", UIParent, "CENTER")


	UISpellsArenaClassConfig.ScrollFrame = CreateFrame("ScrollFrame", nil, UISpellsArenaClassConfig, "ScrollFrameTemplate");
	UISpellsArenaClassConfig.ScrollFrame:SetPoint("TOPLEFT", LoseControlSpellsArenaClassConfigDialogBG, "TOPLEFT", 4, -8);
	UISpellsArenaClassConfig.ScrollFrame:SetPoint("BOTTOMRIGHT", LoseControlSpellsArenaClassConfigDialogBG, "BOTTOMRIGHT", -3, 4);
	UISpellsArenaClassConfig.ScrollFrame:SetClipsChildren(true);
	UISpellsArenaClassConfig.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);

	UISpellsArenaClassConfig.ScrollFrame.ScrollBar:ClearAllPoints();
  	UISpellsArenaClassConfig.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", UISpellsArenaClassConfig.ScrollFrame, "TOPRIGHT", -12, -18);
 	UISpellsArenaClassConfig.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", UISpellsArenaClassConfig.ScrollFrame, "BOTTOMRIGHT", -7, 18);

	local allContents = SetTabs(UISpellsArenaClassConfig, #tabs, unpack(tabs));

	UISpellsArenaClassConfig:Hide();
	return UISpellsArenaClassConfig;
end

--------------------------------------
-- SpellsArenaClassConfig functions
--------------------------------------
function SpellsArenaClassConfig:Addon_Load()
	if not UISpellsArenaClassConfig then CreateMenu(); SpellsArenaClassConfig:UpdateAllSpellList() end
end

function SpellsArenaClassConfig:Toggle() --Builds the Table
	if not UISpellsArenaClassConfig then CreateMenu(); SpellsArenaClassConfig:UpdateAllSpellList() end
	local menu = UISpellsArenaClassConfig
	menu:SetShown(not menu:IsShown());
end

function SpellsArenaClassConfig:UpdateTab(i)
	if not UISpellsArenaClassConfig then return end
	SpellsArenaClassConfig:WipeSpellList(i)
	SpellsArenaClassConfig:UpdateSpellList(i);
end

function SpellsArenaClassConfig:WipeAll()
	if not UISpellsArenaClassConfig then return end
	SpellsArenaClassConfig:WipeAllSpellList()
end

function SpellsArenaClassConfig:UpdateAll()
	if not UISpellsArenaClassConfig then return end
	SpellsArenaClassConfig:UpdateAllSpellList()
end

function SpellsArenaClassConfig:WipeAllSpellList()
	for i = 1, #tabs do
		SpellsArenaClassConfig:WipeSpellList(i)
	end
end

function SpellsArenaClassConfig:UpdateAllSpellList()
	for i = 1, #tabs do
		SpellsArenaClassConfig:UpdateSpellList(i)
	end
end

function SpellsArenaClassConfig:ResetAllSpellList()
	for i = 1, #tabs do
		SpellsArenaClassConfig:EnableAll(i)
	end
end

function SpellsArenaClassConfig:EnableAll(i)

	local CLASSTBL = {
		["DEATHKNIGHT"] = {},
		["DEMONHUNTER"] = {},
		["DRUID"] = {},
		["EVOKER"] = {},
		["HUNTER"] = {},
		["MAGE"] = {},
		["MONK"] = {},
		["PALADIN"] = {},
		["PRIEST"] = {},
		["ROGUE"] = {},
		["SHAMAN"] = {},
		["WARLOCK"] = {},
		["WARRIOR"] = {},
		["Racials"] = {},
		["PvP"] = {}
	}

	for y = 1, #L.spellsArena do
		for l = 1, #L.spellsArena[y] do
			local spellID = unpack(L.spellsArena[y][l])
			local name = GetSpellInfo(spellID)
			if L.classIds[spellID] or L.classIds[name] then
				local table = L.classIds[spellID] or L.classIds[name]
				tblinsert(CLASSTBL[table], L.spellsArena[y][l])
			end
		end
	end


	local c = contents[i]
	for l = 1, #CLASSTBL[tabs[i]] do
		local spellID, prio, _, _, duration, customname, _, cleuEvent = unpack(CLASSTBL[tabs[i]][l])
		local spellCheck = GetSpellFrame(spellID, duration, c)
		spellCheck.icon = _G[spellCheck:GetName().."Icon"]
		spellCheck.icon.check = spellCheck
		spellID = spellCheck.spellID
		_G.LoseControlDB.spellEnabledArena[spellID] = true
		spellCheck:SetChecked(_G.LoseControlDB.spellEnabledArena[spellID] or false);
	end
	if _G["LoseControlSpellsArenaConfig"] then 
		for i = 1, #tabsdropdown do
			L.SpellsArenaConfig:UpdateSpellList(i)
		end
	end
end

function SpellsArenaClassConfig:DisableAll(i)

	local CLASSTBL = {
		["DEATHKNIGHT"] = {},
		["DEMONHUNTER"] = {},
		["DRUID"] = {},
		["EVOKER"] = {},
		["HUNTER"] = {},
		["MAGE"] = {},
		["MONK"] = {},
		["PALADIN"] = {},
		["PRIEST"] = {},
		["ROGUE"] = {},
		["SHAMAN"] = {},
		["WARLOCK"] = {},
		["WARRIOR"] = {},
		["Racials"] = {},
		["PvP"] = {}
	}

	for y = 1, #L.spellsArena do
		for l = 1, #L.spellsArena[y] do
			local spellID = unpack(L.spellsArena[y][l])
			local name = GetSpellInfo(spellID)
			if L.classIds[spellID] or L.classIds[name] then
				local table = L.classIds[spellID] or L.classIds[name]
				tblinsert(CLASSTBL[table], L.spellsArena[y][l])
			end
		end
	end

	local c = contents[i]
	for l = 1, #CLASSTBL[tabs[i]] do
		local spellID, prio, _, _, duration, customname, _, cleuEvent = unpack(CLASSTBL[tabs[i]][l])
		local spellCheck = GetSpellFrame(spellID, duration, c)
		spellCheck.icon = _G[spellCheck:GetName().."Icon"]
		spellCheck.icon.check = spellCheck
		spellID = spellCheck.spellID
		_G.LoseControlDB.spellEnabledArena[spellID] = false
		spellCheck:SetChecked(_G.LoseControlDB.spellEnabledArena[spellID] or false);
	end
	if _G["LoseControlSpellsArenaConfig"] then 
		for i = 1, #tabsdropdown do
			L.SpellsArenaConfig:UpdateSpellList(i)
		end
	end
end

function SpellsArenaClassConfig:WipeSpellList(i)
local c = contents[i]
 	for l = 1, (#L.spellsArena[i]) do
		local spellID, _, _, _, duration = unpack(L.spellsArena[i][l])
		local spellCheck = GetSpellFrame(spellID, duration, c)
		if not  spellCheck then return end
		spellCheck:Hide()
	end
end

function SpellsArenaClassConfig:UpdateSpellList(i)
	local numberOfSpellChecksPerRow = 5
	if i == nil then return end
	local c = contents[i]
	local previousSpellID = nil
	local Y = -10
	local X = 230
	local spellCount = 1


	c.spellstext:SetText("|cff00ccffSpells|r : "..#L.spellsArena[i])
	c.spellstext:SetPoint("TOPLEFT", c, "TOPLEFT", 5, 0);

	local CLASSTBL = {
		["DEATHKNIGHT"] = {},
		["DEMONHUNTER"] = {},
		["DRUID"] = {},
		["EVOKER"] = {},
		["HUNTER"] = {},
		["MAGE"] = {},
		["MONK"] = {},
		["PALADIN"] = {},
		["PRIEST"] = {},
		["ROGUE"] = {},
		["SHAMAN"] = {},
		["WARLOCK"] = {},
		["WARRIOR"] = {},
		["Racials"] = {},
		["PvP"] = {}
	}


	for y = 1, #L.spellsArena do
		for l = 1, #L.spellsArena[y] do
			local spellID = unpack(L.spellsArena[y][l])
			local name = GetSpellInfo(spellID)
			if L.classIds[spellID] or L.classIds[name] then
				local table = L.classIds[spellID] or L.classIds[name]
				tblinsert(CLASSTBL[table], L.spellsArena[y][l])
			end
		end
	end


	for l = 1, #CLASSTBL[tabs[i]] do
		local spellID, prio, _, _, duration, customname, _, cleuEvent = unpack(CLASSTBL[tabs[i]][l])
		if (spellID) then
			local spellCheck = GetSpellFrame(spellID, duration, c)
			if spellCheck then
				if (previousSpellID) then
					if (spellCount % numberOfSpellChecksPerRow == 0) then
						Y = Y-40
						X = 30
					end
					spellCheck:ClearAllPoints()
					spellCheck:SetPoint("TOPLEFT", c, "TOPLEFT", X, Y);
					X = X+200
				else
					spellCheck:ClearAllPoints()
					spellCheck:SetPoint("TOPLEFT", c, "TOPLEFT", 30, -10);
				end
				spellCheck:Show()
				spellCheck:SetChecked(_G.LoseControlDB.spellEnabledArena[spellID] or false);   --Error on 1st ADDON_LOADED
				local aString = spellID
				if type(spellID) == "number" then
					if duration then
						aString = substring(GetSpellInfo(spellID), 0, 21).."\n"..substring(prio, 0, 21)..": "..duration or "SPELL REMOVED: "..spellID
					else
						local name = GetSpellInfo(spellID)
						if name then aString = substring(name, 0, 21).."\n"..substring(prio, 0, 21) else aString = "SPELL REMOVED: "..spellID end
					end
					spellCheck.icon:SetNormalTexture(GetSpellTexture(spellID) or 1)
				else
				spellCheck.icon:SetNormalTexture(1008124)
				end
				local cutString = aString
				if customname then
					cutString = cutString.."\n".."("..customname..")"
				end
				local name = GetSpellInfo(spellID)
				if L.classIds[spellID] or L.classIds[name] then 
					cutString = Colorize(cutString, L.classIds[spellID]) or Colorize(cutString, L.classIds[name]) or cutString
				end
				spellCheck.text:SetText(cutString);
				spellCheck.text:SetJustifyH('LEFT')
			else
				if not duration then
					spellCheck = CreateFrame("CheckButton", c:GetName().."spellCheck"..spellID, c, "UICheckButtonTemplate");
				else
					spellCheck = CreateFrame("CheckButton", c:GetName().."spellCheck"..spellID..duration, c, "UICheckButtonTemplate");
				end
				if (previousSpellID) then
					if (spellCount % numberOfSpellChecksPerRow == 0) then
						Y = Y-40
						X = 30
					end
					spellCheck:SetPoint("TOPLEFT", c, "TOPLEFT", X, Y);
					X = X+200
				else
					spellCheck:SetPoint("TOPLEFT", c, "TOPLEFT", 30, -10);
				end
				spellCheck:Show()
				spellCheck:SetChecked(_G.LoseControlDB.spellEnabledArena[spellID] or false);
				spellCheck.icon = CreateFrame("Button", spellCheck:GetName().."Icon", spellCheck, "ActionButtonTemplate")
				spellCheck.icon:Disable()
				spellCheck.icon:SetPoint("CENTER", spellCheck, "CENTER", -85, 0)
				spellCheck.icon:SetScale(0.35)
				spellCheck.icon:Show()
				spellCheck.icon.check = spellCheck
				local aString = spellID
				if type(spellID) == "number" then
					if duration then
						aString = substring(GetSpellInfo(spellID), 0, 21).."\n"..substring(prio, 0, 21)..": "..duration or "SPELL REMOVED: "..spellID
					else
						local name = GetSpellInfo(spellID)
						if name then aString = substring(name, 0, 21).."\n"..substring(prio, 0, 21) else aString = "SPELL REMOVED: "..spellID end
					end
					spellCheck.icon:SetNormalTexture(GetSpellTexture(spellID) or 1)
				else
				spellCheck.icon:SetNormalTexture(1008124)
				end
				local cutString = aString
				if customname then
					cutString = cutString.."\n".."("..customname..")"
				end
				local name = GetSpellInfo(spellID)
				if L.classIds[spellID] or L.classIds[name] then 
					cutString = Colorize(cutString, L.classIds[spellID]) or Colorize(cutString, L.classIds[name]) or cutString
				end
				spellCheck.text:SetText(cutString);
				spellCheck.text:SetJustifyH('LEFT')
				if cleuEvent then spellID = customname end
				spellCheck:SetChecked(_G.LoseControlDB.spellEnabledArena[spellID] or false);   --Error on 1st ADDON_LOADED
				spellCheck.spellID = spellID
				prio = L[prio] or prio
				local drop_opts = {
				    ['name']='raid',
				    ['parent']=spellCheck,
				    ['title']='',
				    ['items']= tabsDrop,
				    ['defaultVal'] = prio,
				    ['changeFunc'] = function(dropdown_frame, dropdown_val)
					local spell = GetSpellInfo(tonumber(spellID))
						if spell then spell = tonumber(spellID) else spell = spellID end
						for k, v in ipairs(tabsdropdown) do
							if dropdown_val == L[v] then
								dropdown_val = v
							end
						end
						CustomPVPDropDownCompileSpells(spell, dropdown_val, i, c, duration)
						spellCheck:SetChecked(_G.LoseControlDB.spellEnabledArena[spellID] or false)
					end
				}

				if not duration then
				local dropdown = createDropdown(drop_opts)
				dropdown:SetPoint("LEFT", spellCheck.text, "RIGHT", -10,0)
				dropdown:SetScale(.55)
				end

				spellCheck:SetScript("OnClick",function()
					GameTooltip:Hide()
					_G.LoseControlDB.spellEnabledArena[spellCheck.spellID] = spellCheck:GetChecked()
					if _G["LoseControlSpellsArenaConfig"] then 
						for i = 1, #tabsdropdown do
							L.SpellsArenaConfig:UpdateSpellList(i)
						end
					end
					L.OptionsFunctions:UpdateAll()
					makeAndShowSpellTTPVE(spellCheck)
				end);
				spellCheck:SetScript("OnEnter", function(self)
						makeAndShowSpellTTPVE(self)
				end)
				spellCheck:SetScript("OnLeave", function(self)
					GameTooltip:Hide()
				end)
			end
			previousSpellID = spellID
			spellCount = spellCount + 1
		end
	end
end
