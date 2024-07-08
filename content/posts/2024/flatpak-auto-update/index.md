---
title: 自動更新你的 Flatpak
date: 2024-05-14T12:00:06+08:00
lastmod: 2024-07-08T09:58:00+08:00
draft: "false"
tags: [flatpak]
keywords:
  - flatpak
  - snap
  - immutable
  - linux
categories: [Linux]
---
![](flatpak-feature.png)
Flatpak 本身並不內建自動更新，倘若希望它能自動更新，就必須另外設置腳本以及 timer 定時器來達成，儘管許多人並不喜歡自動更新，但 Linux 的特點就是一切皆可由您做主，自動更新尤其適合於不想日後花非常多時間特別留心去維護 Linux 系統的人，又或者是你在幫不熟悉 Linux 的使用者設定自動更新，以下 Systemd 腳本取自 [OpenSUSE MicroOS](https://microos.opensuse.org/)。

## 請先切換目錄:
```bash
cd /lib/systemd/system 
```

## 接著直接添加以下兩個檔案：
第一個：
```bash
sudo vim update-system-flatpaks.timer
```

```ini
[Unit]
Description=Update system Flatpaks daily
Documentation=man:flatpak-update(1)

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```
<hr>

第二個：
```bash
sudo vim update-system-flatpaks.service 
```

```ini
[Unit]
Description=Update system Flatpaks
Documentation=man:flatpak-update(1)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/flatpak --system update -y --noninteractive

[Install]
WantedBy=default.target
```
<hr>

最後開啟定時器：
```bash
sudo systemctl enable update-system-flatpaks.timer 
```

<hr>





# 另一種選擇

取自 Universal Blue Project: <https://github.com/ublue-os/config/tree/main/files/usr/lib/systemd>

與 OpenSUSE MicroOS 的不同之處是它所做的事情是更完整的，除了多了 `uninstall --unused -y` 會移除沒有用的依賴，還會檢查是否為計量連線，另外，同時也包含了 User 與 System 兩種 Flatpak。

## 請先切換目錄:
```bash
cd /lib/systemd/system 
```

System 第一個：
```bash
sudo vim flatpak-system-update.service
```

```ini
[Unit]
Description=Flatpak Automatic Update
Documentation=man:flatpak(1)
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecCondition=/bin/bash -c '[[ "$(busctl get-property org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager Metered | cut -c 3-)" == @(2|4) ]]'
ExecStart=/usr/bin/flatpak --system uninstall --unused -y --noninteractive ; /usr/bin/flatpak --system update -y --noninteractive ; /usr/bin/flatpak --system repair
```

System 第二個：
```bash
sudo vim flatpak-system-update.timer
```

```ini
[Unit]
Description=Flatpak Automatic Update Trigger
Documentation=man:flatpak(1)

[Timer]
RandomizedDelaySec=10m
OnBootSec=2m
OnCalendar=*-*-* 4:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

開啟 System Flatpak 定時器：
```bash
sudo systemctl enable flatpak-system-update.timer 
```

### 接下來 User Flatpak

## 請切換目錄:  (目錄不一樣記得切)
```bash
cd /lib/systemd/user
```

User 第一個：
```bash
sudo vim flatpak-user-update.service
```

```ini
[Unit]
Description=Flatpak Automatic Update
Documentation=man:flatpak(1)
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecCondition=/bin/bash -c '[[ "$(busctl get-property org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager Metered | cut -c 3-)" == @(2|4) ]]'
ExecStart=/usr/bin/flatpak --user uninstall --unused -y --noninteractive ; /usr/bin/flatpak --user update -y --noninteractive ; /usr/bin/flatpak --user repair
```

User 第二個：
```bash
sudo vim flatpak-user-update.timer
```

```ini
[Unit]
Description=Flatpak Automatic Update Trigger
Documentation=man:flatpak(1)

[Timer]
RandomizedDelaySec=10m
OnBootSec=2m
OnCalendar=*-*-* 4:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

開啟 User Flatpak 定時器：   (這裡不要 `sudo` 而且要多加 `--user` 喔！)
```bash
systemctl --user enable flatpak-user-update.timer
```
