# Plan: Titan Command History

Target WoW Forever 1.60.1, interface 16001, Lua 5.1 semantics, Titan Panel optional.

## Goal

A persistent, Linux style history of what the player sends from the chat box, usable from the arrow keys, from a window and from a Titan Panel plugin.

## Decisions (agreed with the user)

1. The name is TitanCommandHistory. Titan stays optional: the display uses LibDataBroker, which Titan reads and any other bar can read too.
2. Both commands (text starting with a slash) and conversation lines are recorded. The window shows them on separate tabs. The arrow keys in the chat box walk through all of them in the order they were sent, like a shell.
3. Only successful input is recorded, like a shell that skips mistyped commands: a slash command whose word does not exist is dropped, and so is any line that is followed by an error message within 0.4 seconds. A setting records everything instead.
4. A click on a row puts the text into the chat box for editing and the player presses Enter. A Run button (and the favorites in the menu) sends the text directly. Protected commands such as /cast are refused by the client when sent from an addon, so the window only offers Run and explains the limit.

## Parts

- History.lua: the store (entries, kind, pinned, use counts, limit, search, scope account or character). Pure Lua, fully tested.
- Capture.lua: decides what is recorded. Builds the set of known slash words from the SLASH_ and EMOTE globals, keeps a pending line for 0.4 seconds and drops it on an error.
- Arrows.lua: up and down in the chat box. Plain arrows are enabled (alt mode off), the addon hook runs after the native handler, so the addon text wins.
- Actions.lua: put text into the chat box, run text.
- Window.lua: tabs Commands, Conversations, Favorites; search; scroll bar; row click, Run button, right click menu (Run, Edit in chat, Favorite, Delete; for favorites Move up, Move down, Remove). The Favorites tab has a box to type a new favorite.
- Titan.lua: LibDataBroker object with the count as text, tooltip with the latest lines, right click menu with the favorites, settings and clear.
- Core.lua: saved variables TitanCommandHistoryDB, events, hooks of every chat edit box.

## Unverified client behaviour (to confirm live)

- The text passed to EditBox:AddHistoryLine by the client when a line is sent (used as the capture point).
- Whether plain up and down arrows reach OnArrowPressed with SetAltArrowKeyMode(false).
- Whether UI_ERROR_MESSAGE reliably follows a failed send.
- The recording log in the saved variables (key log) exists to check these.

## Later ideas

Editing long macro text in a multi line box and copying it out in 255 character lines; export of the history; frequency sorting.

## Favorites (0.1.3-alpha)

Favorites replace the earlier pinned lines and quick commands: one list, shared by all characters, kept in the chosen order and outside the history (not trimmed, not part of the arrow keys, not touched by Clear). A favorite can be any command or line. They are added from a history line or typed in the Favorites tab, run from the window and from the menu. Earlier quick commands and pinned lines are carried over once.
