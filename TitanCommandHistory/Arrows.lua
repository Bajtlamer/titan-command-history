local _, ns = ...
-- Up and down in the chat box, like a shell: up walks back through what was sent, down walks forward and ends at
-- the text that was being typed.
local Arrows = {}
Arrows.__index = Arrows
ns.Arrows = Arrows

-- texts() returns the history, oldest first.
function Arrows.New(texts)
    return setmetatable({ texts = texts, index = nil, draft = '' }, Arrows)
end

function Arrows:Reset() self.index, self.draft = nil, '' end

-- current is what the box holds now. Returns the text to show, or nil when there is nothing to change.
function Arrows:Up(current)
    local texts = self.texts()
    if #texts == 0 then return nil end
    if not self.index then
        self.draft, self.index = current or '', #texts + 1
    end
    if self.index <= 1 then return texts[1] end
    self.index = self.index - 1
    return texts[self.index]
end

function Arrows:Down()
    local texts = self.texts()
    if not self.index then return nil end
    if self.index >= #texts then
        local draft = self.draft
        self:Reset()
        return draft
    end
    self.index = self.index + 1
    return texts[self.index]
end

-- Attaches the behaviour to a chat edit box. The addon hook runs after the native handler, so its text wins.
function Arrows.Attach(box, texts)
    local navigator = Arrows.New(texts)
    if box.SetAltArrowKeyMode then pcall(box.SetAltArrowKeyMode, box, false) end
    local function show(text)
        if text == nil then return end
        box:SetText(text)
        if box.SetCursorPosition then box:SetCursorPosition(#text) end
    end
    box:HookScript('OnArrowPressed', function(self, key)
        if key == 'UP' then show(navigator:Up(self:GetText()))
        elseif key == 'DOWN' then show(navigator:Down()) end
    end)
    box:HookScript('OnTextChanged', function(_, user) if user then navigator:Reset() end end)
    box:HookScript('OnEditFocusGained', function() navigator:Reset() end)
    return navigator
end
