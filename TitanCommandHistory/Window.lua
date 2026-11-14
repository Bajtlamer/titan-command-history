local _, ns = ...
-- The history window: tabs Commands, Conversations and Pinned, a search box, a scroll bar. A click puts the line
-- into the chat box, Run sends it, right click opens a menu.
local Window = { offset = 0, total = 0, tab = 'command' }
ns.Window = Window

local ROWS, ROW_HEIGHT, WHEEL_STEP = 16, 22, 3
local WIDTH, HEIGHT, ROW_WIDTH = 790, 540, 730
local tabs = { { 'command', 'Commands' }, { 'chat', 'Conversations' }, { 'pinned', 'Pinned' } }
local GOLD, GRAY = '|cffffd100', '|cff9d9d9d'

function Window.Clamp(offset, total)
    return math.max(0, math.min(math.floor(offset + 0.5), math.max(0, total - ROWS)))
end

function Window.RangeText(offset, total)
    if total == 0 then return 'No lines' end
    return string.format('Showing %d-%d of %d', offset + 1, math.min(total, offset + ROWS), total)
end

function Window.Ago(seconds)
    if seconds < 60 then return 'now' end
    if seconds < 3600 then return math.floor(seconds / 60) .. ' min ago' end
    if seconds < 86400 then return math.floor(seconds / 3600) .. ' h ago' end
    return math.floor(seconds / 86400) .. ' d ago'
end

local function text(parent, font, x, y, width)
    local fontString = parent:CreateFontString(nil, 'OVERLAY', font)
    fontString:SetPoint('TOPLEFT', parent, 'TOPLEFT', x, y)
    fontString:SetWidth(width)
    fontString:SetJustifyH('LEFT')
    return fontString
end

local function button(parent, label, x, y, width, callback)
    local b = CreateFrame('Button', nil, parent, 'UIPanelButtonTemplate')
    b:SetSize(width, 22)
    b:SetPoint('TOPLEFT', parent, 'TOPLEFT', x, y)
    b:SetText(label)
    b:SetScript('OnClick', callback)
    return b
end

-- Classic panel tabs hanging below the window. Plain buttons inside the window when the client lacks the template.
-- Lessons from the sibling addon: a new frame is already shown, so its first Show fires no OnShow, and a new tab
-- text has a fixed width that makes GetStringWidth report the cut text. So the tabs are measured at creation
-- (without the fixed width) and again shortly after.
local function tabIndex(key)
    for index, tab in ipairs(tabs) do if tab[1] == key then return index end end
    return 1
end

local function selectTab(key)
    Window.tab, Window.offset = key, 0
    Window.Refresh()
end

local function labelOf(b)
    return b.Text or (b.GetName and b:GetName() and _G[b:GetName() .. 'Text'])
end

local function fitTabs(window)
    for _, b in ipairs(window.tabButtons) do
        local label = labelOf(b)
        if label and label.SetWidth then label:SetWidth(0) end
        local width = label and label.GetStringWidth and label:GetStringWidth()
        if type(width) ~= 'number' or width <= 0 then width = nil end
        if PanelTemplates_TabResize then pcall(PanelTemplates_TabResize, b, nil, nil, nil, nil, width) end
        if width and b.GetWidth and b.SetWidth and (b:GetWidth() or 0) < width + 16 then b:SetWidth(width + 30) end
    end
end

local function panelTabs(window)
    local previous
    for index, tab in ipairs(tabs) do
        local b = CreateFrame('Button', nil, window, 'PanelTabButtonTemplate')
        b:SetID(index)
        b:SetText(tab[2])
        if previous then b:SetPoint('LEFT', previous, 'RIGHT', -16, 0)
        else b:SetPoint('TOPLEFT', window, 'BOTTOMLEFT', 15, 2) end
        local key = tab[1]
        b:SetScript('OnClick', function() selectTab(key) end)
        b.key = key
        window.tabButtons[index] = b
        previous = b
    end
    window.Tabs = window.tabButtons
    PanelTemplates_SetNumTabs(window, #tabs)
    PanelTemplates_SetTab(window, tabIndex(Window.tab))
    window.panelTabs = true
    fitTabs(window)
    local function onShow()
        fitTabs(window)
        if C_Timer and C_Timer.After then
            for _, delay in ipairs({ 0.1, 0.5, 1.5 }) do
                C_Timer.After(delay, function() if window:IsShown() then fitTabs(window) end end)
            end
        end
    end
    if window.HookScript then window:HookScript('OnShow', onShow) else window:SetScript('OnShow', onShow) end
    onShow()
end

local function buttonTabs(window)
    local step = math.floor((WIDTH - 30) / #tabs)
    for index, tab in ipairs(tabs) do
        local key = tab[1]
        local b = CreateFrame('Button', nil, window, 'UIPanelButtonTemplate')
        b:SetSize(step - 6, 22)
        b:SetPoint('TOPLEFT', window, 'TOPLEFT', 15 + (index - 1) * step, -65)
        b:SetText(tab[2])
        b:SetScript('OnClick', function() selectTab(key) end)
        b.key = key
        window.tabButtons[index] = b
    end
end

function Window.Tabs(window)
    window.tabButtons = {}
    if PanelTemplates_SetNumTabs and PanelTemplates_SetTab and pcall(panelTabs, window) then return end
    for _, b in pairs(window.tabButtons) do b:Hide() end
    window.tabButtons, window.panelTabs = {}, nil
    buttonTabs(window)
end

function Window.Toggle()
    if Window.window and Window.window:IsShown() then Window.window:Hide() else Window.Show() end
end

function Window.ScrollTo(offset)
    Window.offset = Window.Clamp(offset, Window.total)
    Window.Refresh()
end

local function rowMenu(row)
    local entry = row.entry
    if not entry or not MenuUtil or not MenuUtil.CreateContextMenu then return end
    MenuUtil.CreateContextMenu(row, function(_, root)
        root:CreateButton('Run', function() ns.Actions.Run(entry.text) end)
        root:CreateButton('Edit in chat', function() ns.Actions.Insert(entry.text) end)
        root:CreateCheckbox('Pinned', function() return entry.pinned == true end, function()
            ns.History.SetPinned(entry, not entry.pinned); Window.Refresh()
        end)
        if entry.kind == 'command' then
            root:CreateButton('Add to quick commands', function() ns.History.AddQuick(entry.text) end)
        end
        root:CreateButton('Delete', function() ns.History.Remove(entry); Window.Refresh(); ns.Titan.Refresh() end)
    end)
end

function Window.Refresh()
    local w = Window.window
    if not w or not w:IsShown() then return end
    local rows = ns.History.Entries(Window.tab, Window.searchText)
    Window.total = #rows
    Window.offset = Window.Clamp(Window.offset, Window.total)
    if w.panelTabs then
        PanelTemplates_SetTab(w, tabIndex(Window.tab))
    else
        for _, tab in ipairs(w.tabButtons) do
            if tab.key == Window.tab then tab:LockHighlight() else tab:UnlockHighlight() end
        end
    end
    w.rangeText:SetText(Window.RangeText(Window.offset, Window.total))
    local now = time and time() or 0
    for index = 1, ROWS do
        local line = w.lines[index]
        local entry = rows[Window.offset + index]
        line.entry = entry
        if entry then
            line.text:SetText((entry.pinned and (GOLD .. '* |r') or '') .. entry.text)
            local uses = (entry.uses or 1) > 1 and (' x' .. entry.uses) or ''
            line.info:SetText(GRAY .. Window.Ago(math.max(0, now - (entry.at or now))) .. uses .. '|r')
            line:Show()
        else line:Hide() end
    end
    local last = math.max(0, Window.total - ROWS)
    w.slider.syncing = true
    w.slider:SetMinMaxValues(0, last); w.slider:SetValue(Window.offset)
    w.slider.syncing = false
    if last > 0 then w.slider:Show() else w.slider:Hide() end
    w.footer:SetText(ns.History.Count() .. ' saved lines (' .. (ns.History.Settings().scope == 'character'
        and 'this character' or 'all characters') .. ', limit ' .. ns.History.Settings().max .. ').')
end

function Window.Show()
    local w = Window.window
    if not w then
        local name = 'TitanCommandHistoryWindow'
        w = CreateFrame('Frame', name, UIParent, 'BasicFrameTemplateWithInset')
        Window.window = w
        if UISpecialFrames then table.insert(UISpecialFrames, name) end
        w:SetSize(WIDTH, HEIGHT)
        w:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
        w:SetClampedToScreen(true); w:SetMovable(true); w:EnableMouse(true); w:RegisterForDrag('LeftButton')
        w:SetScript('OnDragStart', function(self) self:StartMoving() end)
        w:SetScript('OnDragStop', function(self) self:StopMovingOrSizing() end)
        w:SetScript('OnHide', function() GameTooltip:Hide() end)
        w.TitleText:SetText('Titan Command History')
        local note = text(w, 'GameFontHighlightSmall', 15, -33, WIDTH - 30)
        note:SetText('Click a line to edit it in the chat box, Run sends it at once. Right click for more. Protected commands such as /cast cannot be sent from here.')
        Window.Tabs(w)
        w.rangeText = text(w, 'GameFontHighlightSmall', 15, -70, 300)
        text(w, 'GameFontNormalSmall', 560, -70, 50):SetText('Search')
        local search = CreateFrame('EditBox', nil, w, 'InputBoxTemplate')
        search:SetSize(110, 22); search:SetPoint('TOPLEFT', w, 'TOPLEFT', 615, -65); search:SetAutoFocus(false)
        search:SetScript('OnEscapePressed', function(self) self:ClearFocus() end)
        search:SetScript('OnTextChanged', function(self, user)
            if not user then return end
            Window.searchText, Window.offset = self:GetText(), 0
            Window.Refresh()
        end)
        button(w, 'Clear', 725, -65, 50, function()
            search:SetText(''); search:ClearFocus(); Window.searchText, Window.offset = nil, 0
            Window.Refresh()
        end)
        w.lines = {}
        for index = 1, ROWS do
            local line = CreateFrame('Button', nil, w)
            line:SetSize(ROW_WIDTH, ROW_HEIGHT)
            line:SetPoint('TOPLEFT', w, 'TOPLEFT', 15, -100 - (index - 1) * ROW_HEIGHT)
            line:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
            line.text = text(line, 'GameFontHighlight', 0, -4, 530)
            line.text:SetWordWrap(false)
            line.info = text(line, 'GameFontHighlightSmall', 540, -5, 100)
            local run = button(line, 'Run', ROW_WIDTH - 50, 0, 50, function()
                if line.entry then ns.Actions.Run(line.entry.text) end
            end)
            run:SetHeight(20)
            line:SetScript('OnClick', function(self, which)
                if not self.entry then return end
                if which == 'RightButton' then rowMenu(self) else ns.Actions.Insert(self.entry.text) end
            end)
            line:SetScript('OnEnter', function(self)
                if not self.entry then return end
                GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
                GameTooltip:AddLine(self.entry.text, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            line:SetScript('OnLeave', function() GameTooltip:Hide() end)
            w.lines[index] = line
        end
        w:EnableMouseWheel(true)
        w:SetScript('OnMouseWheel', function(_, delta) Window.ScrollTo(Window.offset - delta * WHEEL_STEP) end)
        local slider = CreateFrame('Slider', nil, w)
        w.slider = slider
        slider:SetOrientation('VERTICAL')
        slider:SetPoint('TOPLEFT', w, 'TOPLEFT', 15 + ROW_WIDTH + 8, -100)
        slider:SetSize(16, ROWS * ROW_HEIGHT)
        slider:SetMinMaxValues(0, 0); slider:SetValueStep(1); slider:SetObeyStepOnDrag(true)
        local track = slider:CreateTexture(nil, 'BACKGROUND')
        track:SetAllPoints(slider); track:SetColorTexture(0, 0, 0, 0.35)
        slider:SetThumbTexture('Interface\\Buttons\\UI-ScrollBar-Knob')
        slider:GetThumbTexture():SetSize(16, 24)
        slider:EnableMouseWheel(true)
        slider:SetScript('OnMouseWheel', function(_, delta) Window.ScrollTo(Window.offset - delta * WHEEL_STEP) end)
        slider:SetScript('OnValueChanged', function(self, value)
            if not rawget(self, 'syncing') then Window.ScrollTo(value) end
        end)
        w.footer = text(w, 'GameFontHighlightSmall', 15, -100 - ROWS * ROW_HEIGHT - 8, WIDTH - 30)
    end
    w:Show()
    Window.Refresh()
end
