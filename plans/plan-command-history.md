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

## Status (0.1.6-alpha) and continuation

Implemented: persistent history with the arrow keys, recording only what worked (a slash word that does not exist is dropped, a line followed by an error within 0.4 seconds is dropped, /reload, /reloadui, /rl, /logout, /camp, /quit and /exit are recorded at once, lines still waiting are kept when the game closes), conversation lines (switchable), the window with panel tabs below it (Commands, Conversations, Favorites), search, scroll bar, Run and edit in the chat box, favorites (a separate list, typed or taken from a history line, ordered, run from the menu), the minimap button, the LibDataBroker object for Titan Panel, a saved window position, an opaque window and a diagnostic log that never holds the text of a line.

The pinned facts the code relies on and that were confirmed live: EditBox:AddHistoryLine is called with the sent text, plain up and down arrows reach OnArrowPressed with the alt mode off, errors after a failed line arrive as UI_ERROR_MESSAGE, and the count shows after a reload. Also confirmed in the saved data: the client adds a spoken line to the chat box history together with its chat type word ("/p hello", "/s hello", "/w Name hello"), so a leading slash does not mean a command. Since 0.1.8 History.Classify treats the chat type words (and channel numbers) as conversation lines and corrects older entries once.

### Live checks still to do

- [ ] Arrow keys walk through the saved history after a /reload and after a restart, oldest to newest, and down returns to the text that was being typed.
- [ ] A mistyped command (unknown word) is not recorded; a known command that fails (for example casting without mana) is not recorded; a conversation line to a player that is offline (whisper) is not recorded; check the log (menu: Print the recording log to chat).
- [ ] Conversation lines can be switched off in the settings; whispers and conversation lines never appear in the diagnostic log.
- [ ] The window: tabs fit at the first opening after a restart, the position is kept, it is opaque over other windows, a click on a line puts it in the chat box, Run sends it, right click: Run, Edit in chat, Favorite, Delete.
- [ ] Favorites: typed in the Favorites tab, added from a history line, moved up and down, removed, run from the menu; the starter list (/reload, /sit, /stand, /dance, /wave, /cheer, /laugh, /thank, /bow) was created once and earlier quick commands and pinned lines were carried over.
- [ ] The minimap button (left click window, right click menu, drag) and the Titan plugin text "History: N", also without Titan Panel installed.
- [ ] Protected commands (/cast, /use) sent with Run are only put into the chat box, as documented; confirm what the client does.
- [ ] Limit of lines (100 to 1000) and the scope (all characters or this character) behave as set.

### Ideas and optimization

- A multi line editor for long macros with a copy out in lines of at most 255 characters.
- Export of the history as text, sorting by use count, a separate favorites list per character.
- Measure the cost of the hook on the chat edit boxes and the size of the saved history at 1000 lines.
- Keep the same window code in step with the sibling addon (opaque layer, saved position, panel tab measuring): the lessons are listed in plans/plan-live-verification-and-optimization.md of the Titan Gathered Forever v3 repository.


## Artwork verification, 2026-11-16

Version 0.1.6-alpha adds an original journal, quill and hourglass emblem to IconTexture, Titan and the minimap. Automated Lua suites, package inclusion and installation byte checks are separate from pending live rendering after a full client restart. No source publication or release upload.
