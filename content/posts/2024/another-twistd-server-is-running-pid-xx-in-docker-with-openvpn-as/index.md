---
title: OpenVPN AS Docker 遇到 Another twistd server is running, PID xx
date: 2024-06-23T17:22:06+08:00
draft: "false"
tags: [cli,vpn]
categories: [Linux, Docker, "System Management"]
#authors: ""
---
在 Ubuntu 虛擬機執行 `sudo docker ps` 時發現 OpenVPN AS 一直在重啟，然後被洗版以下訊息

```text
Another twistd server is running, PID 1

This could either be a previously started instance of your application or a
different application entirely. To start a new one, either run it in some other
directory, or use the --pidfile and --logfile parameters to avoid clashes.
```
查詢後找到這個 CSDN 文章: <https://blog.csdn.net/Awesome_py/article/details/122342265> | CC 4.0 BY-SA 

大意就是去容器裡面把 pid 檔案刪除

## 開始
1. 首先先成為 `root`
```bash
sudo -i
```

2. 查看容器 ID
```bash
docker ps -a
```
```
CONTAINER ID   IMAGE                       COMMAND                  CREATED          STATUS          PORTS                                       NAMES
9197f0c1442a   openvpn/openvpn-as:latest   "/docker-entrypoint.…"   6 weeks ago      Up 11 minutes                                               openvpn_as
```
在此範例，`9197f0c1442a` 就是 ID

3. 把容器停止

指令為 `docker stop ID 或名字`
```bash
docker stop 9197f0c1442a
```

4. 查看容器實際目錄
```
docker inspect 9197f0c1442a
```
尋找類似這樣的地方，因為我這個系統的 Docker 是用 Snap 裝的，可能跟你比較不一樣
```json
"Data": {
                "LowerDir": "/var/snap/docker/common/var-lib-docker/overlay2/2f87497f0a8a09a684e06ab8e3f0d544d7e62f22981b8aec82bb32ed8aa2a081-init/diff:/var/snap/docker/common/var-lib-docker/overlay2/24a42029198ef590420fe3918f6c95fde8231260c29be0d8d032a456b6089c51/diff:/var/snap/docker/common/var-lib-docker/overlay2/bea0c55fba471e7dd6568a18403a15ca550d3e66f76c21a4179f67beedcf1c12/diff:/var/snap/docker/common/var-lib-docker/overlay2/210f35ef1045b27c779582bfd87097a861bb7f65ec701c882b9914a583d213b1/diff:/var/snap/docker/common/var-lib-docker/overlay2/08bab7648426ef3cfd258b31be998829acc6b563d52f366e7e759c433ab52c9e/diff:/var/snap/docker/common/var-lib-docker/overlay2/d56b8dbb9365da0f32cc426d7149b010a719d895d159835d14c9379e3cd341f0/diff",
                "MergedDir": "/var/snap/docker/common/var-lib-docker/overlay2/2f87497f0a8a09a684e06ab8e3f0d544d7e62f22981b8aec82bb32ed8aa2a081/merged",
                "UpperDir": "/var/snap/docker/common/var-lib-docker/overlay2/2f87497f0a8a09a684e06ab8e3f0d544d7e62f22981b8aec82bb32ed8aa2a081/diff",
                "WorkDir": "/var/snap/docker/common/var-lib-docker/overlay2/2f87497f0a8a09a684e06ab8e3f0d544d7e62f22981b8aec82bb32ed8aa2a081/work"
            }
```

請看末尾是 `merged`, `diff`, `work` 的那幾個目錄，它們前方都相同，我們要去它們存在的目錄:

類似這樣
```bash
cd /var/snap/docker/common/var-lib-docker/overlay2/2f87497f0a8a09a684e06ab8e3f0d544d7e62f22981b8aec82bb32ed8aa2a081/
```

5. 尋找以及刪除 `.pid` 檔案

首先尋找 `.pid` 檔案:
```bash
find -name '*.pid'
```
以我為例，我找到這兩個檔案:
```text
./diff/twistd.pid
./diff/ovpn/tmp/wserv.pid
```

然後我們分別刪除這兩個檔案
```bash
rm ./diff/twistd.pid
rm ./diff/ovpn/tmp/wserv.pid
```

