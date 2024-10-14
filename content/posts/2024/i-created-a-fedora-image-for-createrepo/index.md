---
title: 我為了 createrepo 建立了個 Fedora Image
date: 2024-10-15T02:09:06+08:00
draft: "false"
tags: [cli, github, docker, container]
categories: [Linux, Tools, 心得]
#authors: ""
summary: 其實我大可不必這麼做的，但就算是 Ubuntu 24.10，它的 `createrepo-c` 依然只有舊到哭且發布於 2021/07/07 的 `0.17.3`，然而，目前最新版本為發布於 2024/08/15 `1.1.4`，差距來到了 3 年！ 雖然跑起來沒有問題，但看著就不太舒服而且毛毛的，就改用 Fedora Container，但因為還要再裝依賴以及初始化 Container，整個運行時間會再增加約快 20 秒！（初始化約 6~8 秒，安裝依賴約花費 10 多秒）
---

本文為建立 rustdesk-rpm-repo 的後續：
{{< article link="/posts/2024/i-created-an-apt-and-rpm-repo-for-rustdesk/" >}}

<hr>

本文建立的 Container Image 在此：
{{< github repo="xlionjuan/fedora-createrepo-image" >}}

## Why
其實我大可不必這麼做的，但就算是 Ubuntu 24.10，它的 `createrepo-c` 依然只有舊到哭且發布於 2021/07/07 的 `0.17.3`，然而，目前最新版本為發布於 2024/08/15 `1.1.4`，差距來到了 3 年！

> 請見 [Launchpad](https://launchpad.net/ubuntu/+source/createrepo-c) 以及最新 [createrepo-c 的 Releases](https://github.com/rpm-software-management/createrepo_c/releases)

雖然跑起來沒有問題，但看著就不太舒服而且毛毛的，就改用 [Fedora Container](https://hub.docker.com/_/fedora)，但因為還要再裝依賴 "`dnf -y install createrepo_c jq wget rpm-sign gnupg git`"，以及初始化 Container，整個運行時間會再增加約快 20 秒！（初始化約 6~8 秒，安裝依賴約花費 10 多秒）

要把 Actions 跑在容器很簡單，只要添加 `container: fedora:latest` 即可，剩下 GitHub 會幫你通通搞定
```yml
jobs:
    build:
      runs-on: ubuntu-latest
      container: fedora:latest
      steps:
        - name: Checkout code
          uses: actions/checkout@v4
          .......
```

## 開做！

首先建立一個 [GitHub repo](https://github.com/xlionjuan/fedora-createrepo-image).....

然後建立 Dockerfile，用最新的 Fedora 當基底，`LABEL` 是擺好看的，接下來是用 `dnf` 安裝所需要的依賴，接者把 `dnf` 快取清光光，再直接刪除相關資料夾來減少 Image 大小。
```dockerfile
FROM fedora:latest

LABEL org.opencontainers.image.description="Simple container image just for create RPM repo."

RUN dnf -y install createrepo_c jq wget rpm-sign gnupg git \
    && dnf clean all \
    && rm -rf /var/cache/dnf /var/log/dnf.log /var/lib/rpm/__db*
```

然後我建議發佈到 GitHub 的 `ghcr.io` 就好，因為可以省去要再建立 Docker Hub Token 的麻煩，而且本來就是要在 GitHub Actions 用，減少資源浪費。

然後請 ChatGPT o1-preview 幫我寫 GitHub Action 檔案，提示詞如下：

```text
我會把這個 Docker 放在一個 GitHub Repository 的根目錄

現在幫我寫一個 GitHub Action ，把這個 Dockerfile build 之後發布到 Ghcr.io

Tag 命名規則是：每個 image 都要掛上今日日期的 tag, 格式 yyyymmdd
例如 20241030

然後最新的要掛 latest
```

然後就生出接近完美的 [.yml](https://github.com/xlionjuan/fedora-createrepo-image/blob/main/.github/workflows/build.yml) 了，只有裡面不同 step 的 action 版本不是最新，換成新的即可，然後我事後有再微調，讓 [Renovatebot](https://github.com/renovatebot/renovate) 可以加入進來進行日常維護。

## 效果

* 安裝依賴節省約 10 多秒
* `wget` RustDesk 時快了 1~2 秒....? 

這是因為 Fedora 40 開始，使用 `wget2` 取代 `wget`，簡單來講它是個重寫的版本，對於新的網路技術相容性更好，效能更好，還支援併發下載，只需把不同連結排在一起就有併發下載的功能，例如： 
```bash
wget https://example.com/a.zip https://example.com/b.zip https://example.com/c.zip
```

但其實不併發下載，效能也是有感提升（GitHub Actions 是跑在 Microsoft Azure，網路速度快的體感更大）

在跟 ChatGPT 繼續交涉後，我發現竟然 bash 也可以併發執行指令，語法為一個 `&`，我一直只知道 `&&`，例如常常在 GitHub Actions 看到的指令：
```bash
sudo apt-get update && sudo apt install blabla
```
這代表先執行前面（更新套件庫列表），然後執行後面（安裝套件）

<br>

如果要同時執行兩個指令，例如用舊版 `wget` 併發下載檔案：
```bash
wget https://example.com/a.zip & wget https://example.com/b.zip
```
一個 `&` 就會變成同時執行

## 調整以前的腳本 增加效能
### 下載 RustDesk
那麼我就利用 `wget2` 可以併發下載的特點，以及透過 `&` 同時執行，改善以前的腳本

本來下載 RustDesk 在 Actions yml 的指令長這樣

```yml
- name: Download RustDesk latest and nightly
  run: |
    bash rustdesk_latest.sh
    bash rustdesk_nightly.sh
```

這樣就是依序執行，把它改成同時執行！

```yml
- name: Download RustDesk latest and nightly
  run: bash rustdesk_latest.sh & bash rustdesk_nightly.sh
```

還沒完！

在剛認識 `wget2`，但還沒認識 `&`，之前，我把裡面下載的指令改這樣，因為 RPM 有 SUSE 跟非 SUSE 的，資料夾要切開，指令就得分開

```bash
wget -P wwwroot/latest $RUSTDESK_URL_AMD64 $RUSTDESK_URL_ARM64
wget -P wwwroot/latest-suse $RUSTDESK_URL_AMD64_SUSE $RUSTDESK_URL_ARM64_SUSE
```

但現在我有 `&`，通通給我一次下載！ 節省約 4 秒鐘

```bash
wget -P wwwroot/latest $RUSTDESK_URL_AMD64 $RUSTDESK_URL_ARM64 & wget -P wwwroot/latest-suse $RUSTDESK_URL_AMD64_SUSE $RUSTDESK_URL_ARM64_SUSE
```
Nightly 就如法炮製，不重複

### Sign RPM

Nightly, latest，又 SUSE 跟非 SUSE 的，變成總共四個資料夾要處理

```bash
rpm --addsign wwwroot/latest/*.rpm & \
rpm --addsign wwwroot/latest-suse/*.rpm & \
rpm --addsign wwwroot/nightly/*.rpm & \
rpm --addsign wwwroot/nightly-suse/*.rpm
```

以下省略... 請見[腳本資料夾](https://github.com/xlionjuan/rustdesk-rpm-repo/tree/main/createrepo)

## 結語
這樣優化完整個工作流程大約若在 60 秒左右，優化前大約再加 10 秒，改用 Fedora Container 之前大約總時間約在 50 秒左右，雖然總時間依然增加了 10 秒，但因為整個環境就是跑在 RPM 家族環境上，在建立 RPM repo 這件事情上理應更加穩固。

另外建立容器也是為了避免浪費資源，因為 rustdesk-rpm-repo 是每天跑的，所以每天節省個 10 秒的資源也是有意義的，至於容器本身的發布設定為 1 個月一次，還是比 Ubuntu 好。

### 讓 Bash 更嚴格
另外這也挺重要，就是在 `.sh` 檔案前面添加這個，bash 就會變嚴格

```bash
set -oue pipefail
```

否則，只要最後一個指令沒有失敗，就可能還是會被判定成功 (return 0)

例如：
```bash
a
b
c
d
e
```

你的 a,b,c,d 都失敗了，但你的 e 成功了，可能還是會 return 狀態碼為 0 (成功)，實際上你的 `.sh` 錯的一蹋糊塗，被判定成功後會繼續執行後面的流程，例如我故意讓 `rpm --addsign` 失敗，但同 `.sh` 後面其他東西成功了，然後就一路跑到 deploy 去了，這是不可接受的，加上 `set -oue pipefail` 之後，就可以發現工作流程有成功的失敗了，避免沒完成工作就一路滑~到 deploy 去了。
