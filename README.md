# Titan Command History

A persistent, shell style history of what you send from the chat box, for WoW Forever 1.60.1 (interface 16001). Titan Panel is optional.

## What it does

- Remembers commands (text starting with a slash) and conversation lines, saved between sessions.
- Up and down arrow in the chat box walk through them in the order they were sent, like a shell, also after a reload. Typing ends the walk, down returns to what you were typing.
- Records only what worked, like a shell: a slash word the client does not know is dropped, and so is a line followed by an error message within 0.4 seconds. A setting records everything instead.
- A window with classic panel tabs below it (Commands, Conversations, Favorites), a search box and a scroll bar. Click a line to edit it in the chat box and press Enter, or press Run to send it at once. Right click a line to make it a favorite or delete it.
- Favorites: a separate list shared by all characters, kept in the order you choose (right click: Move up, Move down, Remove). Add one from a history line (right click, Favorite) or type any command or line in the Favorites tab and press Enter. Favorites are not trimmed and not touched when the history is cleared. A starter list (/reload, /sit, /stand, /dance, /wave, /cheer, /laugh, /thank, /bow) is created once.
- The window opens where you left it: its position is saved, also after /reload and a restart (menu: Settings > Reset window position).
- A minimap button (left click: window, right click: menu, drag to move) and a LibDataBroker object that Titan Panel shows as "History: N".
- Right click menu: the favorites, which run with one click, removing a favorite, settings (record conversation lines, record only successful input, minimap button, shared or per character history, number of saved lines) and clearing the history (favorites stay).

## Limits

- Protected commands such as /cast and /use are refused by the client when an addon sends them. Run only puts them in the chat box in that case; the player presses Enter.
- The chat box takes at most 255 characters per line.
- The diagnostic log (menu: Print the recording log to chat) keeps the kind and the first word of a line and the outcome, never the text.

## Status

Version 0.1.8. Automated tests cover the store, the recording rules and the arrow key logic. The client behaviour listed in plans/plan-command-history.md still has to be confirmed in game.

## Development

`python3 tools/check.py` runs the Lua suites and compiles every shipped file (LuaJIT, Lua 5.1 semantics). `python3 tools/install.py --addons-dir <AddOns>` previews an installation and `--apply` performs it with a backup.

## Artwork, 0.1.7

Original journal, quill and hourglass emblem in the AddOns list, Titan Panel and minimap. The package includes its own 64px uncompressed 32-bit TGA. Large logos and avatars are in artwork/v1. A full restart and live visual confirmation are required.

## Development folders and artwork

Development folder: titan-command-history. Runtime addon folders are separate from artwork/. The versioned artwork/v1/ directory contains the original master PNG, logo-1024.png, avatar-400.png for CurseForge, icon-64.png and Icon.tga for each addon. artwork/index.json lists the available versions. Add future designs as a new version directory; keep previous artwork. Marketing PNGs and source masters are excluded from runtime ZIPs.

## CurseForge project text

Ready-to-copy summaries, descriptions and local artwork references are listed in [curseforge/ref-index.md](curseforge/ref-index.md).
