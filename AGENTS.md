# Titan Command History

Target Forever 1.60.1, interface 16001. Runtime uses Lua 5.1 semantics. Titan Panel is optional (LibDataBroker). Never record or send anything the player did not send from the chat box. Whispers and conversation lines are private: keep them out of logs, exports and diagnostics unless the player asks.

## Validation and installation

- Run `python3 tools/check.py` before completing runtime updates and installation.
- The user explicitly authorizes, for every completed update: building the package with `python3 tools/package.py` (ZIP and SHA256SUMS in dist/, never committed) and installing it into the game with `python3 tools/install.py --addons-dir '/Applications/World of Warcraft/_forever_/Interface/AddOns'` (preview first, then `--apply`), verifying installed bytes. The installer backs up the previous copy and preserves other AddOns and SavedVariables. Do not ask again for this. Never restart the game automatically; tell the user to /reload, or to restart when files were added.
- The user authorizes using git and gh to version and push this project's source to `https://github.com/Bajtlamer/titan-command-history.git` (account Bajtlamer, branch main). Tags, GitHub releases and release assets still need explicit approval.
- Increment the patch version for each completed update (keep the alpha suffix until told otherwise); keep the manifest and Namespace.lua in sync.

## Repository hygiene

Runtime files live only in TitanCommandHistory/. Tools, tests and the ref-, book- and tmp- documents stay at root; plans live in plans/. Exclude dist/, SavedVariables and temporary data from Git. Documents use plan-, ref-, book-, tmp- prefixes; every plan-* document lives in plans/, not in the repository root. No emoji, decorative glyphs or em dashes.
