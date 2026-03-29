--[[
    CooldownCompanion - ConfigSettings/TextModeTabs.lua: Text-mode appearance tab builder
]]

local ADDON_NAME, ST = ...
local CooldownCompanion = ST.Addon
local L = LibStub("AceLocale-3.0"):GetLocale("CooldownCompanion", true) or {}
local AceGUI = LibStub("AceGUI-3.0")
local CS = ST._configState

-- Imports from Helpers.lua
local ColorHeading = ST._ColorHeading
local AttachCollapseButton = ST._AttachCollapseButton
local CreateInfoButton = ST._CreateInfoButton
local BuildCompactModeControls = ST._BuildCompactModeControls
local BuildGroupSettingPresetControls = ST._BuildGroupSettingPresetControls
local CreatePromoteButton = ST._CreatePromoteButton
local BuildTextColorsControls = ST._BuildTextColorsControls
local OpenFormatEditor = ST._OpenFormatEditor
local AddColorPicker = ST._AddColorPicker
local RenderFormatPreview = ST._RenderFormatPreview
local ParseFormatString = ST._ParseFormatString

local tabInfoButtons = CS.tabInfoButtons
local appearanceTabElements = CS.appearanceTabElements

local TOKEN_HELP_TEXT = table.concat({
    L["|cffffffffAvailable Tokens:|r"],
    "",
    L["|cff00ff00{name}|r  Spell/item display name"],
    L["|cff00ff00{time}|r  Cooldown time remaining (1:23, 4.5)"],
    L["|cff00ff00{charges}|r  Current charges (if spell has charges)"],
    L["|cff00ff00{maxcharges}|r  Maximum charges (if spell has charges)"],
    L["|cff00ff00{stacks}|r  Aura stacks or item count"],
    L["|cff00ff00{aura}|r  Aura duration remaining"],
    L["|cff00ff00{keybind}|r  Keybind text"],
    L["|cff00ff00{status}|r  Shows ready, cooldown, or aura automatically"],
    L["|cff00ff00{icon}|r  Inline spell icon texture"],
    L["|cff00ff00{missingcharges}|r  |cff888888(conditional only)|r Recharging with charges left"],
    L["|cff00ff00{zerocharges}|r  |cff888888(conditional only)|r All charges spent"],
    L["|cff00ff00{pandemic}|r  |cff888888(conditional only)|r Aura in pandemic window"],
    L["|cff00ff00{proc}|r  |cff888888(conditional only)|r Spell proc overlay active"],
    L["|cff00ff00{available}|r  |cff888888(conditional only)|r Off cooldown / has charges"],
    L["|cff00ff00{unusable}|r  |cff888888(conditional only)|r Spell/item not usable"],
    L["|cff00ff00{oor}|r  |cff888888(conditional only)|r Target out of range"],
    "",
    L["{status} resolves to:"],
    L["  Ready (green) when off CD"],
    L["  Cooldown time (red) when on CD"],
    L["  Aura time (cyan) when aura active"],
}, "\n")

-- Syntax colors for summary (matching FormatEditor.lua)
local SUM_TOKEN  = "ff00ff00"
local SUM_COND_P = "ffffff00"
local SUM_COND_N = "ffff8844"
local SUM_EFFECT = "ffcc44ff"
local SUM_COLOR  = "ff44bbff"
local SUM_GRAY   = "ff888888"
local SUM_SEP    = "  |cff666666\194\183|r  "

local function BuildFormatSummary(formatString)
    local segments = ParseFormatString(formatString)
    local tokens, colors, effects, conds = {}, {}, {}, {}
    local seen = {}
    for _, seg in ipairs(segments) do
        if seg.type == "token" and not seg.unknown and not seen["t:" .. seg.value] then
            tokens[#tokens + 1] = "|c" .. SUM_TOKEN .. seg.value .. "|r"
            seen["t:" .. seg.value] = true
        elseif seg.type == "color_start" and not seen["c:" .. seg.value] then
            colors[#colors + 1] = "|c" .. SUM_COLOR .. seg.value .. "|r"
            seen["c:" .. seg.value] = true
        elseif seg.type == "effect_start" and not seen["e:" .. seg.value] then
            effects[#effects + 1] = "|c" .. SUM_EFFECT .. seg.value .. "|r"
            seen["e:" .. seg.value] = true
        elseif seg.type == "cond_start" then
            local prefix = seg.negated and "!" or "?"
            local key = prefix .. seg.value
            if not seen["d:" .. key] then
                local c = seg.negated and SUM_COND_N or SUM_COND_P
                conds[#conds + 1] = "|c" .. c .. key .. "|r"
                seen["d:" .. key] = true
            end
        end
    end

    local parts = {}
    if #tokens > 0 then
        parts[#parts + 1] = "|c" .. SUM_GRAY .. L["Tokens:|r "] .. table.concat(tokens, ", ")
    end
    if #conds > 0 then
        parts[#parts + 1] = "|c" .. SUM_GRAY .. L["Conditions:|r "] .. table.concat(conds, ", ")
    end
    if #colors > 0 then
        parts[#parts + 1] = "|c" .. SUM_GRAY .. L["Colors:|r "] .. table.concat(colors, ", ")
    end
    if #effects > 0 then
        parts[#parts + 1] = "|c" .. SUM_GRAY .. L["Effects:|r "] .. table.concat(effects, ", ")
    end

    if #parts == 0 then return {} end
    return parts
end

local function BuildTextAppearanceTab(container, group, style)
    local refreshStyle = function() CooldownCompanion:UpdateGroupStyle(CS.selectedGroup) end
    local refreshFrame = function() CooldownCompanion:RefreshGroupFrame(CS.selectedGroup) end

    -- ================================================================
    -- Text Settings (width, height, spacing)
    -- ================================================================
    local textHeading = AceGUI:Create("Heading")
    textHeading:SetText(L["Text Settings"])
    ColorHeading(textHeading)
    textHeading:SetFullWidth(true)
    container:AddChild(textHeading)

    local textSettingsCollapsed = CS.collapsedSections["textappearance_settings"]
    AttachCollapseButton(textHeading, textSettingsCollapsed, function()
        CS.collapsedSections["textappearance_settings"] = not CS.collapsedSections["textappearance_settings"]
        CooldownCompanion:RefreshConfigPanel()
    end)

    if not textSettingsCollapsed then
    local widthSlider = AceGUI:Create("Slider")
    widthSlider:SetLabel(L["Text Width"])
    widthSlider:SetSliderValues(50, 600, 1)
    widthSlider:SetValue(style.textWidth or 200)
    widthSlider:SetFullWidth(true)
    widthSlider:SetCallback("OnValueChanged", function(widget, event, val)
        style.textWidth = val
        CooldownCompanion:UpdateGroupStyle(CS.selectedGroup)
    end)
    container:AddChild(widthSlider)

    local heightSlider = AceGUI:Create("Slider")
    heightSlider:SetLabel(L["Text Height"])
    heightSlider:SetSliderValues(10, 100, 1)
    heightSlider:SetValue(style.textHeight or 20)
    heightSlider:SetFullWidth(true)
    heightSlider:SetCallback("OnValueChanged", function(widget, event, val)
        style.textHeight = val
        CooldownCompanion:UpdateGroupStyle(CS.selectedGroup)
    end)
    container:AddChild(heightSlider)

    if group.buttons and #group.buttons > 1 then
        local spacingSlider = AceGUI:Create("Slider")
        spacingSlider:SetLabel(L["Entry Spacing"])
        spacingSlider:SetSliderValues(-10, 100, 0.1)
        spacingSlider:SetValue(style.buttonSpacing or ST.BUTTON_SPACING)
        spacingSlider:SetFullWidth(true)
        spacingSlider:SetCallback("OnValueChanged", function(widget, event, val)
            style.buttonSpacing = val
            CooldownCompanion:UpdateGroupStyle(CS.selectedGroup)
        end)
        container:AddChild(spacingSlider)
    end

    local decimalCheck = AceGUI:Create("CheckBox")
    decimalCheck:SetLabel(L["Show Decimal Point"])
    decimalCheck:SetValue(style.decimalTimers or false)
    decimalCheck:SetFullWidth(true)
    decimalCheck:SetCallback("OnValueChanged", function(widget, event, val)
        style.decimalTimers = val or nil
        CooldownCompanion:UpdateGroupStyle(CS.selectedGroup)
    end)
    container:AddChild(decimalCheck)

    CreateInfoButton(decimalCheck.frame, decimalCheck.checkbg, "LEFT", "RIGHT", decimalCheck.text:GetStringWidth() + 4, 0, {
        L["Show Decimal Point"],
        {L["Shows one decimal place on duration text"], 1, 1, 1, true},
        {L["(e.g. \"4.5\" instead of \"5\")."], 1, 1, 1, true},
    }, decimalCheck)

    local headerCb = AceGUI:Create("CheckBox")
    headerCb:SetLabel(L["Show Group Header"])
    headerCb:SetValue(style.showTextGroupHeader == true)
    headerCb:SetFullWidth(true)
    headerCb:SetCallback("OnValueChanged", function(widget, event, val)
        style.showTextGroupHeader = val or false
        CooldownCompanion:RefreshGroupFrame(CS.selectedGroup)
        CooldownCompanion:RefreshConfigPanel()
    end)
    container:AddChild(headerCb)

    if style.showTextGroupHeader then
        local headerSizeSlider = AceGUI:Create("Slider")
        headerSizeSlider:SetLabel(L["Header Font Size"])
        headerSizeSlider:SetSliderValues(6, 72, 1)
        headerSizeSlider:SetValue(style.textHeaderFontSize or 12)
        headerSizeSlider:SetFullWidth(true)
        headerSizeSlider:SetCallback("OnValueChanged", function(widget, event, val)
            style.textHeaderFontSize = val
            CooldownCompanion:RefreshGroupFrame(CS.selectedGroup)
        end)
        container:AddChild(headerSizeSlider)

        AddColorPicker(container, style, "textHeaderFontColor", L["Header Color"], {1, 1, 1, 1}, true, refreshFrame, refreshFrame)
    end
    end -- not textSettingsCollapsed

    -- ================================================================
    -- Format String
    -- ================================================================
    local fmtHeading = AceGUI:Create("Heading")
    fmtHeading:SetText(L["Format String"])
    ColorHeading(fmtHeading)
    fmtHeading:SetFullWidth(true)
    container:AddChild(fmtHeading)

    local fmtCollapsed = CS.collapsedSections["textappearance_format"]
    local fmtCollapseBtn = AttachCollapseButton(fmtHeading, fmtCollapsed, function()
        CS.collapsedSections["textappearance_format"] = not CS.collapsedSections["textappearance_format"]
        CooldownCompanion:RefreshConfigPanel()
    end)

    -- Token reference info button
    local fmtInfo = CreateInfoButton(fmtHeading.frame, fmtCollapseBtn, "LEFT", "RIGHT", 4, 0, {
        {L["Format String"], 1, 0.82, 0, true},
        " ",
        {L["Controls what each button displays using"], 1, 1, 1, true},
        {L["|cff00ff00{tokens}|r that resolve to live spell/item data."], 1, 1, 1, true},
        " ",
        {L["Use |cffffff00{?token}|r...|cffffff00{/token}|r to show content only"], 1, 1, 1, true},
        {L["when a condition is met, or |cffff8844{!token}|r to show"], 1, 1, 1, true},
        {L["content when it is not."], 1, 1, 1, true},
        " ",
        {L["Wrap text in |cff44bbff{color}|r...|cff44bbff{/color}|r tags to"], 1, 1, 1, true},
        {L["override its color, or |cffcc44ff{pulse}|r...|cffcc44ff{/pulse}|r"], 1, 1, 1, true},
        {L["for a pulsing alpha effect."], 1, 1, 1, true},
        " ",
        {L["Click |cffffffffEdit Format|r to open the full editor"], 1, 1, 1, true},
        {L["with token lists, insertion buttons, and live preview."], 1, 1, 1, true},
    }, tabInfoButtons)
    fmtHeading.right:ClearAllPoints()
    fmtHeading.right:SetPoint("RIGHT", fmtHeading.frame, "RIGHT", -3, 0)
    fmtHeading.right:SetPoint("LEFT", fmtInfo, "RIGHT", 4, 0)

    if not fmtCollapsed then
    local fmt = style.textFormat or "{name}  {status}"

    local preSpacer = AceGUI:Create("Label")
    preSpacer:SetText(" ")
    preSpacer:SetFullWidth(true)
    container:AddChild(preSpacer)

    local fmtPreview = AceGUI:Create("Label")
    fmtPreview:SetText(RenderFormatPreview(fmt, style))
    fmtPreview:SetFullWidth(true)
    fmtPreview:SetFontObject(GameFontHighlight)
    fmtPreview:SetJustifyH("CENTER")
    container:AddChild(fmtPreview)

    local postSpacer = AceGUI:Create("Label")
    postSpacer:SetText(" ")
    postSpacer:SetFullWidth(true)
    container:AddChild(postSpacer)

    local summaryParts = BuildFormatSummary(fmt)
    for _, line in ipairs(summaryParts) do
        local fmtSummary = AceGUI:Create("Label")
        fmtSummary:SetText(line)
        fmtSummary:SetFullWidth(true)
        fmtSummary:SetFontObject(GameFontHighlightSmall)
        container:AddChild(fmtSummary)
    end

    local btnSpacer = AceGUI:Create("Label")
    btnSpacer:SetText(" ")
    btnSpacer:SetFullWidth(true)
    container:AddChild(btnSpacer)

    local editBtn = AceGUI:Create("Button")
    editBtn:SetText(L["Edit Format"])
    editBtn:SetFullWidth(true)
    editBtn:SetCallback("OnClick", function()
        OpenFormatEditor(style, CS.selectedGroup)
    end)
    container:AddChild(editBtn)
    end -- not fmtCollapsed

    -- ================================================================
    -- Font
    -- ================================================================
    local fontHeading = AceGUI:Create("Heading")
    fontHeading:SetText(L["Font"])
    ColorHeading(fontHeading)
    fontHeading:SetFullWidth(true)
    container:AddChild(fontHeading)

    local fontCollapsed = CS.collapsedSections["textappearance_font"]
    AttachCollapseButton(fontHeading, fontCollapsed, function()
        CS.collapsedSections["textappearance_font"] = not CS.collapsedSections["textappearance_font"]
        CooldownCompanion:RefreshConfigPanel()
    end)

    CreatePromoteButton(fontHeading, "textFont", CS.selectedButton and group.buttons[CS.selectedButton], style)

    if not fontCollapsed then
    local fontDrop = AceGUI:Create("Dropdown")
    fontDrop:SetLabel(L["Font"])
    CS.SetupFontDropdown(fontDrop)
    fontDrop:SetValue(style.textFont or "Friz Quadrata TT")
    fontDrop:SetFullWidth(true)
    fontDrop:SetCallback("OnValueChanged", function(widget, event, val)
        style.textFont = val
        CooldownCompanion:UpdateGroupStyle(CS.selectedGroup)
    end)
    container:AddChild(fontDrop)

    local fontSizeSlider = AceGUI:Create("Slider")
    fontSizeSlider:SetLabel(L["Font Size"])
    fontSizeSlider:SetSliderValues(6, 72, 1)
    fontSizeSlider:SetValue(style.textFontSize or 12)
    fontSizeSlider:SetFullWidth(true)
    fontSizeSlider:SetCallback("OnValueChanged", function(widget, event, val)
        style.textFontSize = val
        CooldownCompanion:UpdateGroupStyle(CS.selectedGroup)
    end)
    container:AddChild(fontSizeSlider)

    local outlineDrop = AceGUI:Create("Dropdown")
    outlineDrop:SetLabel(L["Font Outline"])
    outlineDrop:SetList(CS.outlineOptions)
    outlineDrop:SetValue(style.textFontOutline or "OUTLINE")
    outlineDrop:SetFullWidth(true)
    outlineDrop:SetCallback("OnValueChanged", function(widget, event, val)
        style.textFontOutline = val
        CooldownCompanion:UpdateGroupStyle(CS.selectedGroup)
    end)
    container:AddChild(outlineDrop)

    local alignDrop = AceGUI:Create("Dropdown")
    alignDrop:SetLabel(L["Alignment"])
    alignDrop:SetList({LEFT = "Left", CENTER = "Center", RIGHT = "Right"})
    alignDrop:SetValue(style.textAlignment or "LEFT")
    alignDrop:SetFullWidth(true)
    alignDrop:SetCallback("OnValueChanged", function(widget, event, val)
        style.textAlignment = val
        CooldownCompanion:UpdateGroupStyle(CS.selectedGroup)
    end)
    container:AddChild(alignDrop)

    local shadowCb = AceGUI:Create("CheckBox")
    shadowCb:SetLabel(L["Text Shadow"])
    shadowCb:SetValue(style.textShadow == true)
    shadowCb:SetFullWidth(true)
    shadowCb:SetCallback("OnValueChanged", function(widget, event, val)
        style.textShadow = val or false
        CooldownCompanion:UpdateGroupStyle(CS.selectedGroup)
    end)
    container:AddChild(shadowCb)
    end -- not fontCollapsed

    -- ================================================================
    -- Colors
    -- ================================================================
    local colorsHeading = AceGUI:Create("Heading")
    colorsHeading:SetText(L["Colors"])
    ColorHeading(colorsHeading)
    colorsHeading:SetFullWidth(true)
    container:AddChild(colorsHeading)

    local colorsCollapsed = CS.collapsedSections["textappearance_colors"]
    AttachCollapseButton(colorsHeading, colorsCollapsed, function()
        CS.collapsedSections["textappearance_colors"] = not CS.collapsedSections["textappearance_colors"]
        CooldownCompanion:RefreshConfigPanel()
    end)

    CreatePromoteButton(colorsHeading, "textColors", CS.selectedButton and group.buttons[CS.selectedButton], style)

    if not colorsCollapsed then
    BuildTextColorsControls(container, style, function()
        CooldownCompanion:UpdateGroupStyle(CS.selectedGroup)
    end)
    end -- not colorsCollapsed

    -- ================================================================
    -- Background & Border
    -- ================================================================
    local bgHeading = AceGUI:Create("Heading")
    bgHeading:SetText(L["Background & Border"])
    ColorHeading(bgHeading)
    bgHeading:SetFullWidth(true)
    container:AddChild(bgHeading)

    local bgCollapsed = CS.collapsedSections["textappearance_bg"]
    AttachCollapseButton(bgHeading, bgCollapsed, function()
        CS.collapsedSections["textappearance_bg"] = not CS.collapsedSections["textappearance_bg"]
        CooldownCompanion:RefreshConfigPanel()
    end)

    CreatePromoteButton(bgHeading, "textBackground", CS.selectedButton and group.buttons[CS.selectedButton], style)

    if not bgCollapsed then
    AddColorPicker(container, style, "textBgColor", L["Background Color"], {0, 0, 0, 0}, true, refreshStyle, refreshStyle)

    local borderSlider = AceGUI:Create("Slider")
    borderSlider:SetLabel(L["Border Size"])
    borderSlider:SetSliderValues(0, 5, 0.1)
    borderSlider:SetValue(style.textBorderSize or 0)
    borderSlider:SetFullWidth(true)
    borderSlider:SetCallback("OnValueChanged", function(widget, event, val)
        style.textBorderSize = val
        CooldownCompanion:UpdateGroupStyle(CS.selectedGroup)
    end)
    container:AddChild(borderSlider)

    AddColorPicker(container, style, "textBorderColor", L["Border Color"], {0, 0, 0, 1}, true, refreshStyle, refreshStyle)

    end -- not bgCollapsed

    -- ================================================================
    -- Compact Mode Controls
    -- ================================================================
    BuildCompactModeControls(container, group, tabInfoButtons)
end

-- Exports
ST._BuildTextAppearanceTab = BuildTextAppearanceTab
ST._BuildFormatSummary = BuildFormatSummary
