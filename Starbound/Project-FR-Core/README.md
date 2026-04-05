# ⚙️ Project FR: Localization Core Engine

This folder contains the **technical heart** of the localization system. It manages the dynamic injection of translations into Starbound's engine using Lua hooks and a centralized caching system.

## 📁 Internal Logic Structure

* **`gen_conf.config`**: The master switch. Controls the active `locale` and `fallbackLocale`. 
* **`/scripts/`**: Contains the `generator.lua` and specialized tooltip builders.
* **`/dictionary/`**: Root folder for localized data.
    * `/{locale}/`: Sub-directory for the active language (e.g., `/fr/`).
    * `/{locale}/items/`: Segmented (A-Z) JSON files for high-performance indexing.

## 🛠️ Core Functions

The engine relies on three main architectural pillars:

1.  **Dynamic Routing**: The `loadAsset` function automatically resolves paths based on the `locale` parameter in `gen_conf.config`.
2.  **Protected Loading**: All asset calls are wrapped in `pcall` to ensure the game never crashes, even if a translation key or file is missing.
3.  **On-the-fly Injection**: Translations are not patched into `.object` or `.item` files. They are injected into the UI/Tooltip buffer at the exact moment the player interacts with the item.

## 🌍 Extension & Forking

To use this core for a different language:
1.  **Do not modify the Lua scripts.**
2.  Create your own language folder in `/dictionary/{your_locale}/`.
3.  Apply a JSON patch to `gen_conf.config` to update the `"locale"` value.

---
**Lead Developer:** Neshkel
**Architecture Type:** Data-Driven Localization Framework