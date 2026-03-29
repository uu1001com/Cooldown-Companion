local ADDON_NAME, ST = ...
local CooldownCompanion = ST.Addon
local L = LibStub("AceLocale-3.0"):GetLocale("CooldownCompanion", true) or {}
local AceGUI = LibStub("AceGUI-3.0")
local CS = ST._configState

-- Imports from Helpers.lua
local ColorHeading = ST._ColorHeading
local CreateCharacterCopyButton = ST._CreateCharacterCopyButton

------------------------------------------------------------------------
-- Frame Anchoring panels
------------------------------------------------------------------------

local ANCHOR_POINTS = {
    "TOPLEFT", "TOP", "TOPRIGHT",
    "LEFT", "CENTER", "RIGHT",
    "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}
local ANCHOR_POINT_LABELS = {}
for _, p in ipairs(ANCHOR_POINTS) do ANCHOR_POINT_LABELS[p] = p end

local UNIT_FRAME_OPTIONS = {
    [""]         = "Auto-detect",
    blizzard     = "Blizzard Default",
    uuf          = "UnhaltedUnitFrames",
    elvui        = "ElvUI",
    msuf         = "Midnight Simple Unit Frames",
    custom       = "Custom",
}
local UNIT_FRAME_ORDER = { "", "blizzard", "uuf", "elvui", "msuf", "custom" }

local function BuildFrameAnchoringPlayerPanel(container)
    local db = CooldownCompanion.db.profile
    local settings = CooldownCompanion:GetFrameAnchoringSettings()

    -- Enable Frame Anchoring
    local enableCb = AceGUI:Create("CheckBox")
    enableCb:SetLabel(L["Enable Frame Anchoring"])
    enableCb:SetValue(settings.enabled)
    enableCb:SetFullWidth(true)
    enableCb:SetCallback("OnValueChanged", function(widget, event, val)
        settings.enabled = val
        CooldownCompanion:EvaluateFrameAnchoring()
        CooldownCompanion:RefreshConfigPanel()
    end)
    container:AddChild(enableCb)

    CreateCharacterCopyButton(enableCb, "frameAnchoring", L["Frame Anchoring"], function()
        CooldownCompanion:EvaluateFrameAnchoring()
        CooldownCompanion:RefreshConfigPanel()
    end)

    if not settings.enabled then return end

    -- Unit Frames dropdown
    local ufDrop = AceGUI:Create("Dropdown")
    ufDrop:SetLabel(L["Unit Frames"])
    ufDrop:SetList(UNIT_FRAME_OPTIONS, UNIT_FRAME_ORDER)
    ufDrop:SetValue(settings.unitFrameAddon or "")
    ufDrop:SetFullWidth(true)
    ufDrop:SetCallback("OnValueChanged", function(widget, event, val)
        settings.unitFrameAddon = val ~= "" and val or nil
        CooldownCompanion:EvaluateFrameAnchoring()
        CooldownCompanion:RefreshConfigPanel()
    end)
    container:AddChild(ufDrop)

    -- Custom frame name editboxes (only when "Custom" selected)
    if settings.unitFrameAddon == "custom" then
        -- Player frame row (editbox + pick button)
        local playerRow = AceGUI:Create("SimpleGroup")
        playerRow:SetFullWidth(true)
        playerRow:SetLayout("Flow")

        local playerEdit = AceGUI:Create("EditBox")
        playerEdit:SetLabel(L["Player Frame Name"])
        playerEdit:SetText(settings.customPlayerFrame or "")
        playerEdit:SetRelativeWidth(0.68)
        playerEdit:SetCallback("OnEnterPressed", function(widget, event, text)
            settings.customPlayerFrame = text
            CooldownCompanion:EvaluateFrameAnchoring()
        end)
        playerRow:AddChild(playerEdit)

        local playerPickBtn = AceGUI:Create("Button")
        playerPickBtn:SetText(L["Pick"])
        playerPickBtn:SetRelativeWidth(0.24)
        playerPickBtn:SetCallback("OnClick", function()
            CS.StartPickFrame(function(name)
                if CS.configFrame then
                    CS.configFrame.frame:Show()
                end
                if name then
                    settings.customPlayerFrame = name
                    CooldownCompanion:EvaluateFrameAnchoring()
                end
                CooldownCompanion:RefreshConfigPanel()
            end)
        end)
        playerRow:AddChild(playerPickBtn)

        container:AddChild(playerRow)

        -- Target frame row (editbox + pick button)
        local targetRow = AceGUI:Create("SimpleGroup")
        targetRow:SetFullWidth(true)
        targetRow:SetLayout("Flow")

        local targetEdit = AceGUI:Create("EditBox")
        targetEdit:SetLabel(L["Target Frame Name"])
        targetEdit:SetText(settings.customTargetFrame or "")
        targetEdit:SetRelativeWidth(0.68)
        targetEdit:SetCallback("OnEnterPressed", function(widget, event, text)
            settings.customTargetFrame = text
            CooldownCompanion:EvaluateFrameAnchoring()
        end)
        targetRow:AddChild(targetEdit)

        local targetPickBtn = AceGUI:Create("Button")
        targetPickBtn:SetText(L["Pick"])
        targetPickBtn:SetRelativeWidth(0.24)
        targetPickBtn:SetCallback("OnClick", function()
            CS.StartPickFrame(function(name)
                if CS.configFrame then
                    CS.configFrame.frame:Show()
                end
                if name then
                    settings.customTargetFrame = name
                    CooldownCompanion:EvaluateFrameAnchoring()
                end
                CooldownCompanion:RefreshConfigPanel()
            end)
        end)
        targetRow:AddChild(targetPickBtn)

        container:AddChild(targetRow)
    end

    -- Mirroring checkbox
    local mirrorCb = AceGUI:Create("CheckBox")
    mirrorCb:SetLabel(L["Mirror target from player"])
    mirrorCb:SetValue(settings.mirroring)
    mirrorCb:SetFullWidth(true)
    mirrorCb:SetCallback("OnValueChanged", function(widget, event, val)
        settings.mirroring = val
        CooldownCompanion:ApplyFrameAnchoring()
        CooldownCompanion:RefreshConfigPanel()
    end)
    container:AddChild(mirrorCb)

    -- Inherit group alpha checkbox
    local alphaCb = AceGUI:Create("CheckBox")
    alphaCb:SetLabel(L["Inherit group alpha"])
    alphaCb:SetValue(settings.inheritAlpha)
    alphaCb:SetFullWidth(true)
    alphaCb:SetCallback("OnValueChanged", function(widget, event, val)
        settings.inheritAlpha = val
        CooldownCompanion:ApplyFrameAnchoring()
    end)
    container:AddChild(alphaCb)

    -- Player Frame section heading
    local playerHeading = AceGUI:Create("Heading")
    playerHeading:SetText(L["Player Frame Position"])
    ColorHeading(playerHeading)
    playerHeading:SetFullWidth(true)
    container:AddChild(playerHeading)

    local ps = settings.player

    -- Anchor Point
    local apDrop = AceGUI:Create("Dropdown")
    apDrop:SetLabel(L["Anchor Point"])
    apDrop:SetList(ANCHOR_POINT_LABELS, ANCHOR_POINTS)
    apDrop:SetValue(ps.anchorPoint or "RIGHT")
    apDrop:SetFullWidth(true)
    apDrop:SetCallback("OnValueChanged", function(widget, event, val)
        ps.anchorPoint = val
        CooldownCompanion:ApplyFrameAnchoring()
        CooldownCompanion:RefreshConfigPanel()
    end)
    container:AddChild(apDrop)

    -- Relative Anchor Point
    local rpDrop = AceGUI:Create("Dropdown")
    rpDrop:SetLabel(L["Relative Anchor Point"])
    rpDrop:SetList(ANCHOR_POINT_LABELS, ANCHOR_POINTS)
    rpDrop:SetValue(ps.relativePoint or "LEFT")
    rpDrop:SetFullWidth(true)
    rpDrop:SetCallback("OnValueChanged", function(widget, event, val)
        ps.relativePoint = val
        CooldownCompanion:ApplyFrameAnchoring()
        CooldownCompanion:RefreshConfigPanel()
    end)
    container:AddChild(rpDrop)

    -- X Offset
    local xSlider = AceGUI:Create("Slider")
    xSlider:SetLabel(L["X Offset"])
    xSlider:SetSliderValues(-200, 200, 0.1)
    xSlider:SetValue(ps.xOffset or 0)
    xSlider:SetFullWidth(true)
    xSlider:SetCallback("OnValueChanged", function(widget, event, val)
        ps.xOffset = val
        CooldownCompanion:ApplyFrameAnchoring()
    end)
    container:AddChild(xSlider)

    -- Y Offset
    local ySlider = AceGUI:Create("Slider")
    ySlider:SetLabel(L["Y Offset"])
    ySlider:SetSliderValues(-200, 200, 0.1)
    ySlider:SetValue(ps.yOffset or 0)
    ySlider:SetFullWidth(true)
    ySlider:SetCallback("OnValueChanged", function(widget, event, val)
        ps.yOffset = val
        CooldownCompanion:ApplyFrameAnchoring()
    end)
    container:AddChild(ySlider)
end

local function BuildFrameAnchoringTargetPanel(container)
    local settings = CooldownCompanion:GetFrameAnchoringSettings()

    if not settings.enabled then
        local disabledLabel = AceGUI:Create("Label")
        disabledLabel:SetText(L["Enable Frame Anchoring in the Player Frame column to configure target settings."])
        disabledLabel:SetFullWidth(true)
        container:AddChild(disabledLabel)
        return
    end

    if settings.mirroring then
        local infoLabel = AceGUI:Create("Label")
        infoLabel:SetText(L["Target frame is mirrored from player frame settings."])
        infoLabel:SetFullWidth(true)
        container:AddChild(infoLabel)
    else
        -- Independent target settings
        local targetHeading = AceGUI:Create("Heading")
        targetHeading:SetText(L["Target Frame Position"])
        ColorHeading(targetHeading)
        targetHeading:SetFullWidth(true)
        container:AddChild(targetHeading)

        local ts = settings.target

        -- Anchor Point
        local apDrop = AceGUI:Create("Dropdown")
        apDrop:SetLabel(L["Anchor Point"])
        apDrop:SetList(ANCHOR_POINT_LABELS, ANCHOR_POINTS)
        apDrop:SetValue(ts.anchorPoint or "LEFT")
        apDrop:SetFullWidth(true)
        apDrop:SetCallback("OnValueChanged", function(widget, event, val)
            ts.anchorPoint = val
            CooldownCompanion:ApplyFrameAnchoring()
        end)
        container:AddChild(apDrop)

        -- Relative Anchor Point
        local rpDrop = AceGUI:Create("Dropdown")
        rpDrop:SetLabel(L["Relative Anchor Point"])
        rpDrop:SetList(ANCHOR_POINT_LABELS, ANCHOR_POINTS)
        rpDrop:SetValue(ts.relativePoint or "RIGHT")
        rpDrop:SetFullWidth(true)
        rpDrop:SetCallback("OnValueChanged", function(widget, event, val)
            ts.relativePoint = val
            CooldownCompanion:ApplyFrameAnchoring()
        end)
        container:AddChild(rpDrop)

        -- X Offset
        local xSlider = AceGUI:Create("Slider")
        xSlider:SetLabel(L["X Offset"])
        xSlider:SetSliderValues(-200, 200, 0.1)
        xSlider:SetValue(ts.xOffset or 0)
        xSlider:SetFullWidth(true)
        xSlider:SetCallback("OnValueChanged", function(widget, event, val)
            ts.xOffset = val
            CooldownCompanion:ApplyFrameAnchoring()
        end)
        container:AddChild(xSlider)

        -- Y Offset
        local ySlider = AceGUI:Create("Slider")
        ySlider:SetLabel(L["Y Offset"])
        ySlider:SetSliderValues(-200, 200, 0.1)
        ySlider:SetValue(ts.yOffset or 0)
        ySlider:SetFullWidth(true)
        ySlider:SetCallback("OnValueChanged", function(widget, event, val)
            ts.yOffset = val
            CooldownCompanion:ApplyFrameAnchoring()
        end)
        container:AddChild(ySlider)
    end
end

-- Expose for ButtonSettings.lua and Config.lua
ST._BuildFrameAnchoringPlayerPanel = BuildFrameAnchoringPlayerPanel
ST._BuildFrameAnchoringTargetPanel = BuildFrameAnchoringTargetPanel
