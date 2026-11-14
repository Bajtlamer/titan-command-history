local _, ns = ...
-- What the window and the menus do with a line: put it into the chat box for editing, or send it at once.
local Actions = {}
ns.Actions = Actions

local function chatBox()
    if ChatEdit_ChooseBoxForSend then return ChatEdit_ChooseBoxForSend() end
    return DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox
end

-- Opens the chat box with the text in it. The player edits it and presses Enter.
function Actions.Insert(text)
    if ChatFrame_OpenChat and pcall(ChatFrame_OpenChat, text) then return true end
    local box = chatBox()
    if not box then return false end
    if ChatEdit_ActivateChat then ChatEdit_ActivateChat(box) end
    box:SetText(text)
    return true
end

-- Sends the text as if it had been typed and Enter pressed. The client refuses protected commands (such as
-- /cast) from addons; those are only put into the chat box.
function Actions.Run(text)
    local box = chatBox()
    if not box or not ChatEdit_SendText then return Actions.Insert(text) end
    if ChatEdit_ActivateChat then ChatEdit_ActivateChat(box) end
    box:SetText(text)
    ChatEdit_SendText(box, 1)
    if ChatEdit_DeactivateChat then ChatEdit_DeactivateChat(box) end
    return true
end
