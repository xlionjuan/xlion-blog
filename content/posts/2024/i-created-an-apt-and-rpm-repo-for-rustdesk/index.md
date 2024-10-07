---
title: 我弄了個 RustDesk 的 APT 跟 RPM 的 repo
date: 2024-10-08T02:06:06+08:00
draft: "false"
tags: [cli, github]
categories: [Linux, Tools, 心得]
#authors: ""
summary: 官方都不弄自己的 repo! 太煩了，自己做吧! 還有跟好人與壞人交涉的劇情
---

{{< github repo="rustdesk/rustdesk" >}}
{{< github repo="xlionjuan/rustdesk-apt-repo-latest" >}}
{{< github repo="xlionjuan/rustdesk-apt-repo-nightly" >}}
{{< github repo="xlionjuan/rustdesk-rpm-repo" >}}

## 前言

我想先引用一下我在 [xlionjuan/rustdesk-rpm-repo#1 (comment)](https://github.com/xlionjuan/rustdesk-rpm-repo/issues/1#issuecomment-2395347906) 說的話，有位好心人建議我提交到 Fedora COPR 或直接建議向 Fedora 上游建議納入 RustDesk。

>### For submitting to COPR:
>
>I'm not planning to do it, because they didn't support direct `.rpm` upload, it need to build from source, which I'm not able to do, no matter times and my ability.
>### For submitting to Fedora directly:
>
>I don't have enough time and ability to this, sorry, and I think it is not a great ideas to submit this software that has very high releace frequency, instead, COPR or official RPM repo is the better ideas.
>
>If you suggesting me to asking RustDesk to no matter create a COPR or submitting to Fedora, I don't think it is possible at this moment, they even don't have the Launchpad PPA! Which has way higher marketshare than RPM based distros.
>
>They have **NOTHING** to distribute their software, and no anybody (except @ besdar is submitting to Flathub, and they have Arch AUR) doing this!
>
>And what can I do is create a small APT/RPM repository, and use shell scripts to download their official GitHub Releases.
>
>I hope you understand something from this story.
>
>Edit: I forgot they have AUR.

中文翻譯：

>### 對於提交到 COPR:
>
>我並不打算這麼做，因為他不支援直接上傳 `.rpm`，他要求直接從原始碼建置，不管是我的能力或是時間都無法做到這點。
>### 對於直接提交至 Fedora:
>
>我沒有足夠的時間與能力做到這點，抱歉，並且我認為提交高發布頻率的軟體並不是個好主意，取而代之的，COPR 或是官方的 RPM repo 是更好的主意。
>
>如果你建議我要求 RustDesk 去建立 COPR 或是提交到 Fedora，我不認為此時此刻是可能的，他們甚至沒有 Launchpad PPA！ 他們的市占率遠高於 RPM 的發行版。
>
>他們**沒有**任何方式散播他們的軟體，也沒任何人(除了 @ besdar 正在提交到 Flathub，也有 Arch AUR)
>
>我能做的只有建立小型的 APT/RPM 儲存庫，然後使用腳本去下載他們最新的 GitHub Releases。
>
>我希望你能從故事中了解到什麼
>
>編輯：我忘了他們有 AUR

**備註**：
1. [Launchpad PPA](https://launchpad.net/ubuntu/+ppas) 是跟 [Fedora Copr](https://copr.fedorainfracloud.org/) 相似的東西，允許開發者或包維護者提交軟體上去，這樣他們就會有一個 repo
2. Flathub 審核已通過：[flathub/flathub#5670](https://github.com/flathub/flathub/pull/5670)
3. 上述講的「**沒有**任何方式散播他們的軟體」，看起來有點誇大，但實際並不然，考慮到 Debian/Ubuntu 系的發行版是最大宗的，並且他們的中國使用者並不在少數，以及中國國家發行的 Linux 發行版也幾乎是 Debian/Ubuntu 系，此言論並非空穴來風

目前我位於學校的實驗室負責維護各種機器系統的日常維護與更新等，我們通通都使用我架設的 [RustDesk Server](https://github.com/rustdesk/rustdesk-server)，因為 AnyDesk 一直 ban 人並且中文輸入法問題一直不解決，其中包含數台 Ubuntu 系統的電腦跟伺服器，用了一年後，比較大的麻煩是更新問題，每次都 `cd /tmp && wget https://github.com/rustdesk/rustdesk/releases/download/1.3.0/rustdesk-1.3.0-x86_64.deb   && sudo dpkg -i rustdesk-1.3.0-x86_64.deb`

是真的很煩，然後看看這個: [rustdesk/rustdesk#3985 Add APT repository](https://github.com/rustdesk/rustdesk/discussions/3985)

發布於 2022/07/10，不能說沒有，只能說 RustDesk 完全沒有回過一句話，只有我在下面留言說我弄好 [APT](https://github.com/rustdesk/rustdesk/discussions/3985#discussioncomment-10713783) 跟 [RPM](https://github.com/rustdesk/rustdesk/discussions/3985#discussioncomment-10855093) repo 時偷按讚

再來看看 Flathub: [rustdesk/rustdesk#1537 Add binary on flathub](https://github.com/rustdesk/rustdesk/discussions/1537)

提交到 Flathub 的 PR 有兩個，第一個是失敗的，第二個是現在這個成功的，

第一個: [flathub/flathub#5233 Add com.rustdesk.RustDesk](https://github.com/flathub/flathub/pull/5233)

第二個: [flathub/flathub#5670 Add com.rustdesk.RustDesk](https://github.com/flathub/flathub/pull/5670)

從第一個 PR 更可以知道，老闆(用官帳的就是老闆)實在是不太想做那些人與人打交道的事情，當時審查員與老闆在權限的事情上吵架，其中一點是  `"--filesystem=home"`，也就是取得完整的 home 權限，審查員問: 「它支援 filechooser portals 嗎? 你真的要保持這個權限嗎?」....然後老闆就說: 「為何 AnyDesk 有我們不能有」就生氣了...

>**備註**: filechooser portals 是個在 iOS 很常見、Android 以後也會完全實施的一個功能，簡單來說，程式不再有存取你的資料的權限，而是要存取時(例如: 要在文書軟體開啟檔案時)，去跟系統說「我要檔案!」，然後系統就會跳對話框，請使用者挑選檔案，只有被選中的檔案可以被該程式所讀取，其他一律隔離，這同時也是一種「沙箱」程式時會採用的措施。

在一般人看來，好像審查員在故意刁難，因為遠端控制軟體要傳輸檔案時，都是該程式自己的介面，使用 filechooser portals 在許多使用場景顯然不且實際，但在我看來，這就是審查員在形式上必須進行的一部分，開發者必須就權限請求提供合理的解釋，審查員必須要...審核...痾對就是這樣，這就是他們的職責，PR 並不是發生在黑箱，而是完全公開的，任何流程都會被放在網路上供人檢視，他們對於該做的事情、應盡的職責必須更加留意。


## APT repo
### 找 Action
我是先弄 APT repo 的，其實之前就弄過純手工的，非 CI 的，真的很複雜，所以想找合適的 GitHub Action 來代替，就找到了這個

{{< github repo="morph027/apt-repo-action" >}}
> 幫他按個星星吧..

用了之後發現 RustDesk 的 Debian control(`.deb` 安裝檔的包資訊訊息)又缺 `Section:` 又缺 `Priority:`，導致出現 `No section given for 'PACKAGE NAME', skipping.`，被跳過不納入 repo 的生成，我就發了 Issue: [morph027/apt-repo-action#5](https://github.com/morph027/apt-repo-action/issues/5)

也是他去查資料後發現有 `override` 的功能，並且在他的 action 更新了這個功能，真棒! 然後問題就解決了

見: [Debian control sections 說明](https://www.debian.org/doc/debian-policy/ch-archive.html#s-subsections)


### RustDesk 原始 Debian Control 檔案

這是我在後來找到的，從檔案結構上來看，該出現 Debian Conteol 檔案的位置沒了蹤影，到後來才發現是藏在 `build.py` 裡面用變數的模式加入..

此時此刻，我已經把缺少的 `Section:` 以及 `Priority:` 推 PR 上去了，也馬上被 merge 了。

[rustdesk/rustdesk@master/build.py#L281-L297](https://github.com/rustdesk/rustdesk/blob/e06f456bbd3241c20993fa4603a0c8e6ca6c9bdb/build.py#L281-L297)

```python
def generate_control_file(version):
    control_file_path = "../res/DEBIAN/control"
    system2('/bin/rm -rf %s' % control_file_path)

    content = """Package: rustdesk
Version: %s
Architecture: %s
Maintainer: rustdesk <info@rustdesk.com>
Homepage: https://rustdesk.com
Depends: libgtk-3-0, libxcb-randr0, libxdo3, libxfixes3, libxcb-shape0, libxcb-xfixes0, libasound2, libsystemd0, curl, libva-drm2, libva-x11-2, libvdpau1, libgstreamer-plugins-base1.0-0, libpam0g, gstreamer1.0-pipewire%s
Recommends: libayatana-appindicator3-1
Description: A remote control software.

""" % (version, get_deb_arch(), get_deb_extra_depends())
    file = open(control_file_path, "w")
    file.write(content)
    file.close()
```
### 抓取 RustDesk 的腳本

這邊我使用了 ChatGPT 4o-Preview 幫我撰寫腳本，需求為使用 GitHub API 抓取最新的 Release，然後根據條件過濾出我要的檔案，他就使用了 [jq](https://github.com/jqlang/jq) 來解析 GitHub API 裡面的資訊，我也是因此認識到 [jq](https://github.com/jqlang/jq) 這個 JSON 解析器的。

> 問了第二次就生出成品了，太讚啦

[rustdesk_latest.sh#L18-L20](https://github.com/xlionjuan/rustdesk-apt-repo-latest/blob/d1b37d7e2a698e71ff409166bd814acb3421af26/rustdesk_latest.sh#L18-L20)

```bash
RUSTDESK_URL_AMD64=$(echo "$RELEASE_DATA" | jq -r '.assets[] | select(.name | contains("x86_64") and endswith(".deb") and (contains("sciter") | not)) | .browser_download_url' | head -n 1)
RUSTDESK_URL_ARM64=$(echo "$RELEASE_DATA" | jq -r '.assets[] | select(.name | contains("aarch64") and endswith(".deb") and (contains("sciter") | not)) | .browser_download_url' | head -n 1)
RUSTDESK_URL_ARMHF=$(echo "$RELEASE_DATA" | jq -r '.assets[] | select(.name | contains("armv7") and endswith(".deb")) | .browser_download_url' | head -n 1)
```

依序來講的話大致是這樣:

`assets` 裡面的:

* 包含 `x86_64` | 結尾為 `.deb` | 不包含 `sciter`
* 包含 `aarch64` | 結尾為 `.deb` | 不包含 `sciter`
* 包含 `armv7` | 結尾為 `.deb`

的 `browser_download_url`，因為 RustDesk 目前主要使用的 Flutter 介面不支援老架構，所以 `armv7` 不可以篩掉 `sciter`

然後就是 print 出結果，通通 `wget` 下來

```bash
echo "--------------------RESULT--------------------"
echo "RUSTDESK_URL_AMD64=\"$RUSTDESK_URL_AMD64\""
echo "RUSTDESK_URL_ARM64=\"$RUSTDESK_URL_ARM64\""
echo "RUSTDESK_URL_ARMHF=\"$RUSTDESK_URL_ARMHF\""
echo ""
echo "------------------DOWNLOADING-----------------"
wget $RUSTDESK_URL_AMD64
wget $RUSTDESK_URL_ARM64
wget $RUSTDESK_URL_ARMHF
```

### 撰寫 `.list` 跟 `.sources` 文件以及加入 repo 的指令等

其實，[morph027/apt-repo-action](https://github.com/morph027/apt-repo-action) 它提供的 `action.yml` 會生成下面的摘要

🚀 <- 它原本就有 ~~尊重原作~~
```bash
curl -sfLo /etc/apt.trusted.gpg.d/xlion-rustdesk-latest-apt-repo-keyring.asc gpg.key
echo "deb  main main" >/etc/apt/sources.list.d/xlion-rustdesk-latest-apt-repo.list
```

沒有 `signed-by=` 是壞習慣，也是不安全的，也不知何故連結消失了，就自己做，然後 gpg 檔案很長很醜

#### GPG Key
首先是 GPG Key，參考 [Cloudflare WARP Linux](https://pkg.cloudflareclient.com/) 的說明

```bash
# Add cloudflare gpg key
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

# 把它改成自己的樣子
curl -fsSL https://raw.githubusercontent.com/xlionjuan/rustdesk-apt-repo-nightly/refs/heads/main/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/xlion-repo.gpg
```

#### `.list` 跟 `.sources`
我在 [Intel® oneAPI Toolkits Installation Guide for Linux* OS](https://www.intel.com/content/www/us/en/docs/oneapi/installation-guide-linux/2024-2/yum-dnf-zypper.html) 學到可以用 `tee`

```bash 
tee > /tmp/oneAPI.repo << EOF
[oneAPI]
name=Intel® oneAPI repository
baseurl=https://yum.repos.intel.com/oneapi
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
EOF

sudo mv /tmp/oneAPI.repo /etc/yum.repos.d
```

改成自己的樣子，但是要直接用 `sudo` 放進去，首先是 `.list`

```bash
sudo tee /etc/apt/sources.list.d/xlion-rustdesk-repo.list << EOF
# Change "latest" to "nightly" if you want to switch channel
deb [signed-by=/usr/share/keyrings/xlion-repo.gpg] https://xlionjuan.github.io/rustdesk-apt-repo-latest main main
EOF
```

再來是 `.sources`，也就是 Deb822 格式，Ubuntu 24 以及 Debian 12 之後都支援

就不貼了..**麻煩去文章頭點連結去看最新的 README，這裡只是參考用**

### Architecture 問題
只要你有裝 Steam 32bit Library，或是你如果是工程師，會需要載到 32bit 的東西，你的 dpkg 就會開啟 32bit 的功能，所以假設你的 `.list` 跟 `.sources` 裡面沒有特別指定 Architecture，APT 在 update package lists 時就會把你 dpkg 裡面有開的 Architecture 通通都去跟來源請求，如果來源伺服器沒有相應架構的 package list，就會報警告，類似這樣:

```
N: Skipping acquire of configured file 'main/binary-i386/Packages' as repository 'https://xlionjuan.github.io/rustdesk-apt-repo-latest main InRelease' doesn't support architecture 'i386'
```

誰看了不煩呀，而且它不是只跳幾次會不見，而是每次都出現，除非你只用 GUI 程式更新，應該是不會看到警告(它不是錯誤)，我一開始想到兩個方法:

* 在 `.list` 或 `.sources` 指定架構
* 儲存庫有 i386(32bit) 程式

然後我就在 README 末尾教人如何指定架構，後來想想..能不能在建立 repo 的時候新增這個架構，但實際上一個軟體包都沒有?

...

**還真的可以!**.. 走了冤望路，但也是有學到

### 加入 RustDesk Server
然後我就想想，既然都建立了 APT repo 了，RustDesk Server 也有 `.deb` 安裝版本，那麼我就乾脆加進去吧

類似的腳本，相似的味道，因為沒有 Flutter 跟 Sciter 的差異，所以就是只要是 `.deb` 就全包拉!

**但是**

**但是**

**但是**

如果你是新架的，麻煩請使用 **Docker**，**Docker** 會讓事情變簡單，而且也非常容易抄作業，以及非常容易進行備份跟轉移，可以看**我推**(我寫的)給官方的兩篇教學，一個是教你裝 Ubuntu Server + Docker 再教你架 RustDesk Server 的，另一個是教你用 Synology NAS 的 Container Station(改名了，原本叫 Docker) 架 RustDesk Server，前者很抱歉，只有英文版~~我懶得翻中文~~，後者有中英文版:

* [Ubuntu Server with Docker](https://rustdesk.com/docs/en/self-host/rustdesk-server-oss/ubuntu-server/docker/)
* [Synology DSM 7.2](https://rustdesk.com/docs/zh-tw/self-host/rustdesk-server-oss/synology/dsm-7/)

```bash
DEB_URLS=$(echo "$RELEASE_DATA" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')

echo "-----------------RUSTDESK SERVER-----------------"
echo "--------------DEB FILES TO DOWNLOAD--------------"
echo ""
echo "$DEB_URLS"
echo ""
echo "-------------------DOWNLOADING------------------"

# Loop through each URL and download the .deb files
for url in $DEB_URLS; do
    wget "$url"
done
```

`for` 腳本是 ChatGPT 生給我的...

### 為何拆兩個 GitHub repo
RustDesk 有 `latest` 跟 `nightly`，也就是最新版跟每夜建置版本，其實我本來想用 `components` 去拆的，但發現這個 action 不支援，我沒打算再去請他寫，這也違背簡單的初衷，我就直接拆成兩個了，後來在弄 RPM repo 時，後來想想，好像可以拆子目錄啊....啊....但我懶得弄了，不然我已經部署的設備設定又要改，也確定有人在用了，就不碰了

## RPM repo
哇...這個區塊會比上面短很多，非常多..吧 ~~(<--我寫完了，99 行，APT 那 part 183 行~~ 

因為我筆電是用 [Bluefin-dx](https://projectbluefin.io/)，基於 Fedora 的，所以 RPM repo 我也是需要的

### 找 Action & Reddit drama
#### Reddit drama
首先我一樣先 Google 找可以建立 RPM repo 的 action，結果，怎麼找都找不到，找到的用永遠是打包程式成 `.rpm` 的 action，所以我就上 Reddit 的 r/Fedora [發問](https://www.reddit.com/r/Fedora/comments/1fwnt7z/recommend_github_action_that_can_create_rpm_repo/)(我邊走路去買晚餐時寫的)，基本上是沒有因此得到幫助，留言有一位好心人跟一個槓精 [u/denniot](https://www.reddit.com/user/denniot/)，以下是過程:

> [u/denniot:](https://www.reddit.com/user/denniot/) you can't host a rpm repository in github, but just rpm package in github, which is straightforward once you write a spec file. 
>
> [u/XLioncc (Me):](https://www.reddit.com/user/XLioncc/) Can't host own RPM/YUM repository? I doubt it. 
> 
> [u/denniot:](https://www.reddit.com/user/denniot/) you can doubt, but it's a fact, it requires a specific directory structure. 
>
> [u/XLioncc (Me):](https://www.reddit.com/user/XLioncc/) APT also has its "specific" directory structure, isn't it? 
> 
> [u/denniot:](https://www.reddit.com/user/denniot/) not really, it can be a single archive like many other repo. 
>
> [u/XLioncc (Me):](https://www.reddit.com/user/XLioncc/) Umm, both of them are provided by http server, I can't understand why host it on GitHub Pages can cause problems. 
>
> [u/denniot:](https://www.reddit.com/user/denniot/) it doesn't cause any problems, because it's not simply supported. even gitlab package registry doesn't. 
>
> [u/XLioncc (Me):](https://www.reddit.com/user/XLioncc/) Excuse me? I'm saying GitHub Pages, this topic is nothing related to ghcr 
> > because it's not simply supported. 
> Why? Than Google, Fedora official repo has subfolder too? Any reasons why you said it didn't support subfolders?
> 
> What I want is something that can create the RPM repo's wwwroot, I will take care the rest. 
>
> [u/denniot:](https://www.reddit.com/user/denniot/) I'm just telling the absolute fact. The both gitlab and github do not let you host rpm repository. 
>
> [u/XLioncc (Me):](https://www.reddit.com/user/XLioncc/) Excuse me?
>
> Nvidia is doing this for VERY LONG TIMES 
> 
> <https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installing-with-yum-or-dnf>
>
> [u/denniot:](https://www.reddit.com/user/denniot/) that's actually nvidia special thing. it's clear from the cname. you are getting really annoying, so i'm blocking you. no offence. 

以下用 ChatGPT 翻譯並微調:

> [u/denniot:](https://www.reddit.com/user/denniot/) 你無法在 GitHub 上架設 RPM 倉庫，但可以在 GitHub 上放置 RPM 套件，這很簡單，只要你寫好規格文件（spec file）。
>
> [u/XLioncc (Me):](https://www.reddit.com/user/XLioncc/) 無法自行架設 RPM/YUM 倉庫？我有點懷疑。
>
> [u/denniot:](https://www.reddit.com/user/denniot/) 你可以懷疑，但這是事實，它需要特定的目錄結構。
>
> [u/XLioncc (Me):](https://www.reddit.com/user/XLioncc/) APT 也有它的「特定」的目錄結構，不是嗎？
>
> [u/denniot:](https://www.reddit.com/user/denniot/) 並不完全是，它可以像許多其他倉庫一樣是一個單一的壓縮檔案。
>
> [u/XLioncc (Me):](https://www.reddit.com/user/XLioncc/) 嗯，兩者都由 HTTP 伺服器提供服務，我不明白為何在 GitHub Pages 上架設會造成問題。
>
> [u/denniot:](https://www.reddit.com/user/denniot/) 它不會造成任何問題，因為它根本不被支援。甚至 GitLab 的套件註冊表也不支援。
>
> [u/XLioncc (Me):](https://www.reddit.com/user/XLioncc/) 什麼？我說的是 GitHub Pages，這個話題與 ghcr 完全無關。
> > 因為它根本不被支援。
> 為什麼？Google 和 Fedora 官方倉庫也有子目錄，為什麼你說它不支援子目錄？
>
> 我需要的是一個可以建立 RPM 倉庫的 wwwroot，我會處理剩下的部分。
>
> [u/denniot:](https://www.reddit.com/user/denniot/) 我只是陳述絕對的事實。GitLab 和 GitHub 都不讓你主機 RPM 倉庫。
>
> [u/XLioncc (Me):](https://www.reddit.com/user/XLioncc/) 什麼？
>
> Nvidia 已經做這件事很長一段時間了
>
> <https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installing-with-yum-or-dnf>
>
> [u/denniot:](https://www.reddit.com/user/denniot/) 那實際上是 Nvidia 的特殊情況。從 CNAME 上就能看出來。你真的很煩人，所以我要封鎖你，無意冒犯。

然後它就封鎖我了，讓我們看看他所說的 CNAME，這是取自上述提及的 NVIDIA 文件:

```bash
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
```

？ 

`nvidia.github.io`，`github.io` 前面的 `nvidia` 是 GitHub 的[帳號名稱](https://github.com/nvidia)，只要你的帳號名稱是什麼，你就可以拿到什麼 CNAME，接著後面的 `libnvidia-container` 就是他其中一個[儲存庫](https://github.com/nvidia/libnvidia-container)的名稱，完全免費，完全合法，沒有違反 ToS。 明明什麼都不懂，卻要不懂裝懂

{{< youtubeLite id="abWGRc3wsEI" label="難道只有我覺得..." >}}

#### Google 找手工版的流程 & 問 ChatGPT

問了 ChatGPT 之後，發現流程簡單的不真實，無法讓人相信，所以我就 Google 找手工版的教學，發現也是簡單的很離譜，離譜到我最後腳本只有這樣........

```bash
#!/bin/bash

# Sign RPM
rpm --addsign wwwroot/latest/*.rpm

# Create repo
createrepo_c wwwroot/latest

# Sign Repo
gpg --detach-sign --armor wwwroot/latest/repodata/repomd.xml
```

當 CI 完成沒錯誤後，我還「蛤」了一大聲，為何簡單的那麼離譜，問了 ChatGPT 後發現 RPM repo 簡化了一堆東西，不只沒 `codename`, `components` 的概念，架構也不分，看了下 Fedora 官方 `.repo` 檔案發現估計都是用子目錄切了，那麼 `latest` 跟 `nightly` 我就用子目錄拆了，方便跟精簡許多。

## 好心人 續

[xlionjuan/rustdesk-rpm-repo#1](https://github.com/xlionjuan/rustdesk-rpm-repo/issues/1)

Reddit 那位好心人跟開這個 Issue 的是同一位，我早就知道他了，他在 Fedora 圈子很活躍(頭貼也讓人很有記憶點)，他建議我提交到 Fedora COPR 或直接建議向 Fedora 上游建議納入 RustDesk，然後我原本說 Copr 不支援直接上傳 `.rpm`，他就傳 [Copr 支援 tarballs](https://docs.fedoraproject.org/en-US/quick-docs/publish-rpm-on-copr/#_packaging_from_source_tarballs) 的連結給我，很棒! 我不知道，我就興奮地去下載 RustDesk 的 tarballs，結果......悲劇

```
tree rustdesk-1.3.1-unsigned

rustdesk-1.3.1-unsigned
├── rustdesk-1.3.1-aarch64.dmg
├── rustdesk-1.3.1-x86_64.dmg
└── windows-x86_64
    ├── data
    │   ├── app.so
    │   ├── flutter_assets
    │   │   ├── AssetManifest.bin
    │   │   ├── AssetManifest.json
    │   │   ├── assets
    │   │   │   ├── actions_mobile.svg
    │   │   │   ├── actions.svg
...
... 以下省略

18 directories, 95 files
```

不是哥們，你這應該是 tarballs 的包結果是你沒數位簽章的 Windows 跟 macOS 版本啊?

...

說著說著他就嘗試把 RustDesk 弄上 Copr (他很天真，他一定不了解 RustDesk 專案結構)，然後就是....**大失敗**! 我完全不意外，因為 RustDesk 摩改的東西真的太多了，他把編譯的腳本幾乎都寫進 `build.py` 內了，讓我們看看 RustDesk 的 `rpm.spec`(類似 Debian Control 的東西，但把安裝、建置等腳本合一):

```
Name:       rustdesk
Version:    1.3.2
Release:    0
Summary:    RPM package
License:    GPL-3.0
Requires:   gtk3 libxcb libxdo libXfixes alsa-lib libvdpau1 libva2 pam gstreamer1-plugins-base
Recommends: libayatana-appindicator-gtk3

%description
The best open-source remote desktop client software, written in Rust.

%prep
# we have no source, so nothing here

%build
# we have no source, so nothing here

%global __python %{__python3}

%install
mkdir -p %{buildroot}/usr/bin/
mkdir -p %{buildroot}/usr/lib/rustdesk/
mkdir -p %{buildroot}/usr/share/rustdesk/files/
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps/
mkdir -p %{buildroot}/usr/share/icons/hicolor/scalable/apps/
install -m 755 $HBB/target/release/rustdesk %{buildroot}/usr/bin/rustdesk
install $HBB/libsciter-gtk.so %{buildroot}/usr/lib/rustdesk/libsciter-gtk.so
install $HBB/res/rustdesk.service %{buildroot}/usr/share/rustdesk/files/
install $HBB/res/128x128@2x.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/rustdesk.png
install $HBB/res/scalable.svg %{buildroot}/usr/share/icons/hicolor/scalable/apps/rustdesk.svg
install $HBB/res/rustdesk.desktop %{buildroot}/usr/share/rustdesk/files/
install $HBB/res/rustdesk-link.desktop %{buildroot}/usr/share/rustdesk/files/

%files
/usr/bin/rustdesk
/usr/lib/rustdesk/libsciter-gtk.so
/usr/share/rustdesk/files/rustdesk.service
/usr/share/icons/hicolor/256x256/apps/rustdesk.png
/usr/share/icons/hicolor/scalable/apps/rustdesk.svg
/usr/share/rustdesk/files/rustdesk.desktop
/usr/share/rustdesk/files/rustdesk-link.desktop
/usr/share/rustdesk/files/__pycache__/*

%changelog
# let's skip this for now

# https://www.cnblogs.com/xingmuxin/p/8990255.html
%pre
# can do something for centos7
case "$1" in
  1)
    # for install
  ;;
  2)
    # for upgrade
    systemctl stop rustdesk || true
  ;;
esac

%post
cp /usr/share/rustdesk/files/rustdesk.service /etc/systemd/system/rustdesk.service
cp /usr/share/rustdesk/files/rustdesk.desktop /usr/share/applications/
cp /usr/share/rustdesk/files/rustdesk-link.desktop /usr/share/applications/
systemctl daemon-reload
systemctl enable rustdesk
systemctl start rustdesk
update-desktop-database

%preun
case "$1" in
  0)
    # for uninstall
    systemctl stop rustdesk || true
    systemctl disable rustdesk || true
    rm /etc/systemd/system/rustdesk.service || true
  ;;
  1)
    # for upgrade
  ;;
esac

%postun
case "$1" in
  0)
    # for uninstall
    rm /usr/share/applications/rustdesk.desktop || true
    rm /usr/share/applications/rustdesk-link.desktop || true
    update-desktop-database
  ;;
  1)
    # for upgrade
  ;;
esac
```
`# we have no source, so nothing here` 

嗚呼~~~什麼都沒有，Copr 當然會掛掉啊

我就說，可能比較好的解決方案就是找位技術高深的人去把 [Arch AUR](https://aur.archlinux.org/packages/rustdesk) 的 **PKGBUILD** 移植到這，但這我們雙方就都做不到了。

最後，他在 RustDesk 發了個 Discussion: [rustdesk/rustdesk#9576 Publish to COPR](https://github.com/rustdesk/rustdesk/discussions/9576)，我覺得呢，真的很天真。

## 結語

* 斗點錢給 [RustDesk](https://github.com/sponsors/rustdesk)
* 架伺服器要用 Docker🐋 要用 Docker🐋 要用 Docker🐋
* 主程式的部分，有能力的話可以幫幫他們，扣掉翻譯 README等，他們開發人員只有三位，老闆+兩個人，然後那兩個其實也是他們自己人

以 7 萬個星星的專案來講，這真的是有點神奇......