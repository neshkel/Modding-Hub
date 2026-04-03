# 🌌 Neshkel's Modding Hub

Welcome to my multi-game modding repository. This central hub hosts all my active projects, translations, and custom tools, organized for scalability and clean version control.

---

## 🚀 Current Projects

### 🌠 Starbound: Project FR (Core Engine)
A complete French localization overhaul for the Starbound core engine (v1.4+).
- **Status:** In Progress 
  - *User Interface:* 95%
  - *Systems & Mechanics:* 90%
- **Methodology:** JSON Patching & Lua Injection.

### 🧟 Project Zomboid: Kentucky Remastered
Map overhaul and structural enhancements for the Knox Event.
- **Status:** Development (Build 41 / Transitioning to Build 42).
- **Focus:** Redesigning original map segments. Currently evaluating the extraction of main structural assets for modular implementation in B42.

### ⚔️ Kenshi: French Localization
Ongoing efforts to provide a high-quality French translation for various mods.
- **Status:** On Hold / Maintenance.
- **Note:** Focusing on consistency and lore-friendly terminology.

### 🏔️ Valheim: Auga UI Customization
Deep-level modifications of the Auga UI Plugin.
- **Status:** Experimental.
- **Technical Note:** Direct DLL manipulation for custom UI features. A Pull Request to the official Auga repository is planned once the implementation is stable.

---

## 📂 Repository Structure

To keep the repository lightweight and efficient, I follow a **"Vault Strategy"**:

- **`/[GameName]/[ModName]/`**: The "Live" mod files. These are the only files tracked by Git and ready for distribution.
- **`/[GameName]/_Vault/`**: The developer's laboratory. This folder is **ignored by Git** to prevent heavy files from flooding the repo. It contains:
  - `_WIP`: Work-in-progress files and drafts.
  - `_Archive`: Older versions and deprecated assets.
  - `_Library`: Packed mods (.pak) and external dependencies.
  - `Automation`: Python scripts and batch tools for development.
  - `Communication`: Steam Workshop assets, banners, and screenshots.

---

## 🛠️ Developer Setup & Workflow

### 🔗 Symbolic Links (Recommended)
To test mods directly in-game without duplicating files, use a **Symbolic Link**. This allows the game to read files directly from this repository.

1. Open **Command Prompt** as **Administrator**.
2. Run the following command (adjust paths to your system):

```cmd
mklink /D "C:\Path\To\Game\mods\Project-Name" "C:\Path\To\Modding-Hub\Game\Project-Name"
```

### 💾 Backup Management
A custom `BackUp.bat` (available in the `Automation` subfolders) manages:
- **Automated Mirroring:** Uses `Robocopy` to mirror local work to external drives.
- **Dynamic Selection:** Choose between "Live Mods" or "The Vault" for each game.
- **Safety:** Ensures a 1:1 copy of the source for easy recovery.

---

## 🛡️ License & Contributions

- **License:** Please refer to the [LICENSE](LICENSE) file for usage terms.
- **Contributions:** If you wish to contribute to translations or code, feel free to fork the repository and submit a **Pull Request**.

---

> *"Modding is not just about changing the game; it's about mastering the engine."*