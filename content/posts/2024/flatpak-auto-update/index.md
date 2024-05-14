---
title: 自動更新你的 Flatpak
date: 2024-05-14T12:00:06+08:00
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

```
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

```
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

