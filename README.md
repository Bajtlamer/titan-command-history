# Titan Command History

A persistent, shell style history of what you send from the chat box, for WoW Forever 1.60.1 (interface 16001). Titan Panel is optional.

## What it does

- Remembers commands (text starting with a slash) and conversation lines, saved between sessions.
- Up and down arrow in the chat box walk through them in the order they were sent, like a shell, also after a reload. Typing ends the walk, down returns to what you were typing.
- Records only what worked, like a shell: a slash word the client does not know is dropped, and so is a line followed by an error message within 0.4 seconds. A setting records everything instead.
- A window with classic panel tabs below it (Commands, Conversations, Pinned), a search box and a scroll bar. Click a line to edit it in the chat box and press Enter, or press Run to send it at once. Right click a line to pin it, add it to the quick commands or delete it.
- A minimap button (left click: window, right click: menu, drag to move) and a LibDataBroker object that Titan Panel shows as "History: N".
- Right click menu: quick commands that run with one click (/reload, /sit, /stand, /dance, /wave and more, editable from the history window), settings (record conversation lines, record only successful input, minimap button, shared or per character history, number of saved lines) and clearing the history while keeping pinned lines.

## Limits

- Protected commands such as /cast and /use are refused by the client when an addon sends them. Run only puts them in the chat box in that case; the player presses Enter.
- The chat box takes at most 255 characters per line.
- The diagnostic log (menu: Print the recording log to chat) keeps the kind and the first word of a line and the outcome, never the text.

## Status

Version 0.1.2-alpha. Automated tests cover the store, the recording rules and the arrow key logic. The client behaviour listed in plan-command-history.md still has to be confirmed in game.

## Development

`python3 tools/check.py` runs the Lua suites and compiles every shipped file (LuaJIT, Lua 5.1 semantics). `python3 tools/install.py --addons-dir <AddOns>` previews an installation and `--apply` performs it with a backup.
