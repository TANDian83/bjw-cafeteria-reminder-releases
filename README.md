# BJW 餐厅提醒

macOS 菜单栏 App，自动提醒每周茶歇和每日鲜果。

安装后无需任何操作，数据每周自动更新。

---

## 安装

打开 Terminal，依次运行：

```bash
brew tap TANDian83/bjw-cafeteria
brew install --cask bjw-cafeteria-reminder
```

首次安装需要清除 macOS 安全限制（只需执行一次）：

```bash
xattr -cr /Applications/BjwCafeteriaReminder.app
```

打开 App：

```bash
open /Applications/BjwCafeteriaReminder.app
```

---

## 使用

启动后菜单栏会出现一个图标（不会出现在 Dock 栏）。

| 功能 | 操作 |
|------|------|
| 查看本周菜单 | 点击菜单栏图标 →「查看本周列表」 |
| 手动检查数据更新 | 点击菜单栏图标 →「检查更新」 |
| 调整提醒时间偏移 | 点击菜单栏图标 →「设置…」→「全局提前/延后」 |
| 开机自动启动 | 点击菜单栏图标 →「设置…」→「登录时自动启动」 |

App 会自动：
- 在每次茶歇/鲜果活动前 **弹窗提醒**（默认提前 5 分钟）
- 睡眠/锁屏后唤醒时 **补发错过的提醒**
- 支持按单个菜品 **关闭提醒**（在列表中操作）

---

## 数据更新（自动）

数据托管在 [GitHub](https://github.com/TANDian83/bjw-cafeteria-data)，App 会自动获取：

- 每次启动时拉取最新数据
- 每天北京时间 **11:30** 自动检查更新
- 网络不可用时静默使用缓存数据

无需手动操作，每周数据会自动发布。

---

## App 升级

如需升级到新版本，运行：

```bash
brew upgrade --cask bjw-cafeteria-reminder
xattr -cr /Applications/BjwCafeteriaReminder.app
```

---

## 卸载

```bash
brew uninstall --cask bjw-cafeteria-reminder
```

同时清除本地缓存数据：

```bash
rm -rf ~/.bjw-cafeteria
```

---

## 常见问题

**Q：打不开 App，macOS 提示"无法验证开发者"**

运行以下命令后重试（每次安装/升级后只需执行一次）：

```bash
xattr -cr /Applications/BjwCafeteriaReminder.app
```

**Q：没有显示任何数据**

点击菜单栏图标 →「检查更新」。如果仍然没有数据，说明本周邮件尚未处理，通常周一上午 11:00 左右会自动更新。

**Q：怎么调整提醒提前/延后的时间？**

点击菜单栏图标 →「设置…」→ 调整「全局提前/延后」（单位：分钟，默认 -5 = 提前 5 分钟）。
