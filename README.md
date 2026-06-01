# BJW Cafeteria Reminder

A macOS menu-bar app that reminds you about weekly tea-break (茶歇) and daily fresh-fruit (鲜果) events at BJW Beijing West Campus.

Data is updated automatically — you don't need to do anything after installation.

---

## Quick Start

### 1. Install

Open Terminal and run:

```bash
brew tap TANDian83/bjw-cafeteria
brew install --cask bjw-cafeteria-reminder
```

First launch only — clear macOS Gatekeeper quarantine:

```bash
xattr -cr /Applications/BjwCafeteriaReminder.app
```

Then open the app:

```bash
open /Applications/BjwCafeteriaReminder.app
```

### 2. Use

Once launched, a menu-bar icon appears (no Dock icon).

| Feature | How |
|---------|-----|
| View this week's menu | Click menu-bar icon → 「查看本周列表」 |
| Manually check for data update | Click menu-bar icon → 「检查更新」 |
| Adjust reminder timing | Click menu-bar icon → 「设置…」 → 「全局提前/延后」 |
| Launch at login | Click menu-bar icon → 「设置…」 → 「登录时自动启动」 |

The app will:
- **Pop up a reminder** before each tea-break / fruit event (default: 5 minutes early).
- **Catch up missed reminders** after sleep/wake (within a configurable window).
- Allow you to **disable individual items** from the event list.

### 3. Data Updates (Automatic)

Schedule data is hosted at a [shared GitHub repo](https://github.com/TANDian83/bjw-cafeteria-data). The app:

- Fetches the latest schedule on every launch.
- Automatically checks for updates daily at **11:30 AM (Beijing time)**.
- Falls back to cached data silently if the network is unavailable.

You don't need to do anything — data is published automatically each week.

---

## App Updates

When a new version is released, run:

```bash
brew upgrade --cask bjw-cafeteria-reminder
xattr -cr /Applications/BjwCafeteriaReminder.app
```

---

## Uninstall

```bash
brew uninstall --cask bjw-cafeteria-reminder
```

To also remove cached data:

```bash
rm -rf ~/.bjw-cafeteria
```

---

## FAQ

**Q: The app won't open — macOS says it's from an unidentified developer.**

A: Run `xattr -cr /Applications/BjwCafeteriaReminder.app` and try again. This only needs to be done once after each install/upgrade.

**Q: I don't see any schedule data.**

A: Click 「检查更新」 in the menu bar. If data is still missing, the weekly email may not have been processed yet — it usually updates by Monday around 11:00 AM.

**Q: How do I change the reminder offset?**

A: Click menu-bar icon → 「设置…」→ adjust 「全局提前/延后」 (in minutes, default: -5 = 5 minutes early).
