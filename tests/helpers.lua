local function eq(actual, expected) assert(actual == expected, 'expected ' .. tostring(expected) .. ', got ' .. tostring(actual)) end
local ns = {}
assert(loadfile('TitanCommandHistory/Window.lua'))('TitanCommandHistory', ns)
assert(loadfile('TitanCommandHistory/MinimapButton.lua'))('TitanCommandHistory', ns)
local W = ns.Window
eq(W.Clamp(-3, 100), 0); eq(W.Clamp(500, 100), 84); eq(W.Clamp(5.6, 100), 6); eq(W.Clamp(3, 5), 0)
eq(W.RangeText(0, 0), 'No lines'); eq(W.RangeText(16, 40), 'Showing 17-32 of 40'); eq(W.RangeText(30, 40), 'Showing 31-40 of 40')
eq(W.Ago(5), 'now'); eq(W.Ago(120), '2 min ago'); eq(W.Ago(7300), '2 h ago'); eq(W.Ago(200000), '2 d ago')
local x, y = ns.MinimapButton.Position(0, 140, 140)
eq(math.floor(x + 0.5), 92); eq(math.floor(y + 0.5), 0)
eq(ns.MinimapButton.AngleFromCursor(0, 10, 0, 0), 90); eq(ns.MinimapButton.AngleFromCursor(-5, 0, 0, 0), 180)
eq(ns.MinimapButton.AngleFromCursor(0, -10, 0, 0), 270)
-- the window position is kept in the settings and restored
local store = { settings = {} }
ns.History = { Settings = function() return store.settings end }
UIParent = {}
local window = { points = {}, stored = { 'TOPLEFT', UIParent, 'BOTTOMLEFT', 50.5, 700 } }
function window:GetPoint() return unpack(self.stored) end
function window:ClearAllPoints() self.cleared = (self.cleared or 0) + 1 end
function window:SetPoint(...) self.points[#self.points + 1] = { ... } end
eq(W.RestorePosition(window), false)                                      -- nothing saved: the default place stays
W.SavePosition(window)
local saved = store.settings.windowPoint
eq(saved[1], 'TOPLEFT'); eq(saved[2], 'BOTTOMLEFT'); eq(saved[3], 50.5); eq(saved[4], 700)
eq(W.RestorePosition(window), true); eq(window.points[1][2], UIParent); eq(window.points[1][4], 50.5)
store.settings.windowPoint = { 'CENTER', 'CENTER', 'x', 0 }               -- a damaged value is ignored
eq(W.RestorePosition(window), false)
store.settings.windowPoint = saved
W.window = window; W.ResetPosition()
eq(store.settings.windowPoint, nil); eq(window.points[#window.points][1], 'CENTER')
UIParent = nil
print('PASS helpers 6 checks')
