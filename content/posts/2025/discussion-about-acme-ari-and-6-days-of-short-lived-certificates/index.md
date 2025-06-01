---
title: ACME ARI 淺談以及 6 天短憑證
date: 2025-06-01T23:00:38+08:00
draft: "false"
tags: [letsencrypt, zerossl, caddy, acme-sh, synology, tls, ca-browser-forum, certificate, apple]
categories: [System Managements, WebPKI, Cyber Security]
#authors: ""
summary: ACME 更新資訊是一種讓 CA 可以「建議」Client 何時更新憑證的機制，它會提供一個 JSON endpoint 讓 ACME Client 獲取，以讓它們可以在 CA 所期望的時間進行更新憑證，或是在大規模憑證撤銷時，可以有效的以自動化的方式快速更新憑證
---

~~後來覺得好像沒很淺~~

## 寫此文的契機？

我有一臺 Synology NAS，它裡面的 ACME 功能不支援申請 Synology DDNS 以及 QuickConnect 以外的 wildcard certificate，也就是 `*. example.com` 這種的證書，因為它的 ACME Client 不支援用 DNS 驗證的 DNS-01 驗證方式，只支援透過 HTTP-01 方式進行驗證，這也意味著 80 端口必須永遠對外開啟，對於 DSM 這種高度客製化的系統，又讓許多系統元件保持在極舊的狀態，我真的不敢把它的 HTTP Server 完全對外，一直使其永遠走 Cloudflare 以及本地防火牆限定 Cloudflare IPs 才可連入，所以我一直都是使用 [acme.sh](https://github.com/acmesh-official/acme.sh) 來更新我的 wildcard certificate 然後設定每個月一次的 cronjob，就這樣用了快兩年，但前幾天突然家裡內部的 DNS DoH endpoint 連不上了，才發現憑證居然到期了，加上不久前  Let's Encrypt 宣布即將發行 6 天的憑證，然後再宣導 ARI 的重要性，所以才踏上了解 ARI 以及順便 [LEGO ACME Client](https://github.com/go-acme/lego) 的路。

（最後發現我其實不應該把 [acme.sh](https://github.com/acmesh-official/acme.sh) 頻率設一個月的，會導致沒辦法容錯）

## ACME

[ACME](https://letsencrypt.org/how-it-works/) 就是一種讓客戶端（這裡指伺服器）與 CA 溝通並且在證明身分後頒發大部分時間為 90 天的 SSL 憑證的協定，這是有意為之的，因為為了讓 https 普及，用自動化+短期憑證的方式，可以減少因憑證洩漏導致的安全問題，這裡不會展開太多講 ACME 本身，因為已存在許久且到處都有，在這我要講的是 ARI。

## 現有 ACME 更新機制

這裡都先以 90 天憑證為例，其實更長更短都是存在的。

現有的 ACME Client 的機制大部分是目前憑證有效期小於 30 天之時進行憑證更換的操作，有的 ACME Client 的邏輯是剩餘時長為總時長的三分之一（也就是 30 天），如為更短時長為二分之一，這兩種各自都會產生不同的問題。

首先講到比較實際的，伺服器負載，雖然鼓勵大家設置 cron job 時設定隨機時間，並且如果支援的話，設隨機延遲會更好，讓我們回想一下大部分的 cron job 會/能怎麼設

1. 每月某日
2. 每週的星期幾
3. 加上當天的幾點幾分，然後大不了以此基礎上設隨機 delay
4. ACME Client 有的自己也會加 delay，但大都只有幾分鐘

你會發現，這些設定沒辦法很隨機，以天為視角的話，隨機 delay 也是幾分鐘到幾小時的隨機 delay，再怎麼樣基本上還是集中在特定的天，所以管理員就會挑他的 lucky number，或是特定的星期幾，例如週一或周三，不管是前者還是後者，都會導致特定時間點到時，對 CA 產生很大的負擔。

## ARI 是什麼

ACME Renewal Information (ARI)，也就是 ACME 更新資訊是一種讓 CA 可以「建議」Client 何時更新憑證的機制，那麼怎麼個建議法呢？

它會提供一個 JSON endpoint 讓 ACME Client 獲取

先看範例 JSON：

```
GET https://example.com/acme/renewal-info/aYhba4dGQEHhs3uEe6CuLN4ByNQ.AIdlQyE
```

```json
{
  "suggestedWindow": {
    "start": "2021-01-03T00:00:00Z",
    "end": "2021-01-07T00:00:00Z"
  },
  "explanationURL": "https://example.com/docs/ari"
}
```

可以看到裡面有個開始跟結束時間，以及一個解釋說明連結。

大部分時候只會有開始與結束時間，解釋說明連結並非必要，它可以用於解釋意料外的開始與結束時間決定原因，例如動態負載平衡或是發生大量撤銷憑證的事件時的說明連結。

至於開始與結束時間的決定，CA 可以建議一個預測的離峰時間（或單純打散），ACME Client 只要看到目前時間在這個期間內，它就會進行更新，或是自行安排一個時間進行更新，例如對自身合適的當天的離峰時間（非強制一定要馬上），但如果已經超過結束時間，那麼無論如何將會立刻進行續約。

會發生目前時間超過結束時間的預想場景是發生[大規模憑證撤銷](https://letsencrypt.org/tlsalpnrevocation/)時，誰都不希望這樣的事情發生，但倘若真的發生，透過把結束時間強制提前可以促使 ACME Client 看到後馬上更新憑證，透過 ARI 的機制可減緩遇到這樣的狀況時所造成的管理員麻煩，或是 CA 為了儘速通知客戶造成兩難的情況。


### 理想間隔

那麼導入 ARI 後，timer 或 cronjob 該怎麼設呢？

https://community.letsencrypt.org/t/what-are-you-doing-with-ari-retry-after/233048/27

這個討論串在討論 ACME Client 對於 `Retry-After` header 的行為，因為 ACME Client 應當遵循 `Retry-After` header 來進行 ARI 資訊的重新取得


Let's Encrypt staff Aaron Gable 說道：

> From the perspective of the ARI author, the ideal ACME client wakes up every hour, but only has to do local work most of the time: checking the latest ARI response to see if it's in the suggested window now, checking the latest retry-after to see if it needs to check again, checking the certs on disk to see if one has expired, checking the local config to see if there's a new cert to manage, etc. It only does "real" work if one of those checks says it needs to, so waking up that frequently is cheap.

他說**每小時**進行一次是理想的，因為如果無事可做，對系統的開銷很小，所以就算這麼頻繁也無傷大雅。

https://www.reddit.com/r/caddyserver/comments/1gtpxwe/frequency_of_caddy_checking_for_certificate/

根據此單一來源的 Reddit 貼文，Caddy reverse proxy 是每 6 小時刷新一次，但此數字可能是來自 `Retry-After` header，根據本人測試，目前看來 Let's Encrypt ARI 的 `Retry-After` header 都是 21600 秒，也就是 6 小時。

但在原理來看，ARI 資訊只是個 JSON，提供它的開銷遠比頒發憑證還來的小，就算對於 `Retry-After` header 尚未完善的 ACME Client 每個小時都去 GET 一次，相對來說也不至於對 CA 造成太大的負擔。

### 實際 ARI 資訊

在此用 [Let's Encrypt Staging Environment](https://letsencrypt.org/docs/staging-environment/)，以實際的範例看看 ARI 資訊在現實長什麼樣子。

先去 `directory` 尋找所需要的端點:

```
curl https://acme-staging-v02.api.letsencrypt.org/directory    
```

```json
{
  "agzuBnrNces": "https://community.letsencrypt.org/t/adding-random-entries-to-the-directory/33417",
  "keyChange": "https://acme-staging-v02.api.letsencrypt.org/acme/key-change",
  "meta": {
    "caaIdentities": [
      "letsencrypt.org"
    ],
    "profiles": {
      "classic": "https://letsencrypt.org/docs/profiles#classic",
      "shortlived": "https://letsencrypt.org/docs/profiles#shortlived (not yet generally available)",
      "tlsserver": "https://letsencrypt.org/docs/profiles#tlsserver"
    },
    "termsOfService": "https://letsencrypt.org/documents/LE-SA-v1.5-February-24-2025.pdf",
    "website": "https://letsencrypt.org/docs/staging-environment/"
  },
  "newAccount": "https://acme-staging-v02.api.letsencrypt.org/acme/new-acct",
  "newNonce": "https://acme-staging-v02.api.letsencrypt.org/acme/new-nonce",
  "newOrder": "https://acme-staging-v02.api.letsencrypt.org/acme/new-order",
  "renewalInfo": "https://acme-staging-v02.api.letsencrypt.org/draft-ietf-acme-ari-03/renewalInfo",
  "revokeCert": "https://acme-staging-v02.api.letsencrypt.org/acme/revoke-cert"
}
```

`renewalInfo` 就是我們要找的

至於要求 ARI 資訊時，所需要的由 AKI 以及 Serial 所組成的 ARI Cert ID，[請參考此官方說明](https://letsencrypt.org/2024/04/25/guide-to-integrating-ari-into-existing-acme-clients/#step-3-constructing-the-ari-certid)，在此是請 ChatGPT 產生用 Python 解析並請求的程式碼，公鑰給它即可幫你產生好 Cert ID。 

**Python 程式碼備註:** ARI 的標準已經挺接近完成，在此的實現應該不會有大變化，一定會變的就是 endpoint（看網址就知道），另外也有在討論這個 endpoint 本身是否應該要身分驗證才能存取，這部分有[歧議](https://datatracker.ietf.org/doc/review-ietf-acme-ari-06-secdir-lc-emery-2024-11-26/)，雖 renew 資訊，又或者是 Cert ID （用公鑰即可得知）都不是私密資訊，所以怕被行為不端的人進行 DoS 攻擊，但這又可以輕鬆地被快取機制緩解，詳情請見[草案](https://datatracker.ietf.org/doc/draft-ietf-acme-ari/)的 Review 部分。

*範例 Python 程式碼以及憑證請見末尾*


此憑證的到期時間為 `Not After : Jul 28 12:40:51 2025 GMT`

用 `GET` 請求端點:

```
curl https://acme-staging-v02.api.letsencrypt.org/draft-ietf-acme-ari-03/renewalInfo/_EbRAUNfu3umPTBorhG64LxtydM.LCdu7lpbOvtRFeponOGTh4Kr
```

```json
{
  "suggestedWindow": {
    "start": "2025-06-27T15:24:56Z",
    "end": "2025-06-29T10:35:46Z"
  }
}
```

透過 ChatGPT 計算並且請它用 Python 驗證，開始時間與到期時間的差異為 **30天 21小時 15分 55秒**


另外根據[此](https://community.letsencrypt.org/t/ari-recommendation-may-cause-renewal-outside-suggested-window/235059/25)
> renewing within a 90day cert's suggestedWindow shouldn't be too hard. It's roughly +- 1 day from the 2/3 point. this should get picked up on a daily run.

以 90 天憑證為例，沒太特別的事情的話應該是會圍繞著憑證期限的三分之二（30 天）周圍，但請注意，這可能在未來改變。

### 撤銷它!

剛剛說了，發生[大規模憑證撤銷](https://letsencrypt.org/tlsalpnrevocation/)時，會把結束時間提前，以告知 ACME Client 提早進行續約，那麼我們就來嘗試撤銷它然後再運行一次 ACME Client，在此使用 [LEGO](https://github.com/go-acme/lego) 作為範例。

```bash
# 讓我先備份目錄，模擬被外部撤銷的情形，因為本地自己做撤銷，內部資料可能會變化影響後續操作
sudo cp -r cert2 cert2-revoke

sudo podman run --rm -v ./cert2-revoke:/cert:rw goacme/lego --server=https://acme-staging-v02.api.letsencrypt.org/directory --path "/cert" --email xxx@xxx.com -d "demo.xlion.dev" revoke
```

**再看看 ARI 資訊變什麼樣子**

```
curl https://acme-staging-v02.api.letsencrypt.org/draft-ietf-acme-ari-03/renewalInfo/_EbRAUNfu3umPTBorhG64LxtydM.LCdu7lpbOvtRFeponOGTh4Kr
```

```json
{
  "suggestedWindow": {
    "start": "2025-04-29T15:04:05Z",
    "end": "2025-04-29T15:34:05Z"
  }
}
```

備註: 測試當下時間為 UTC 16:05

這時間區間看起來就是當下時間減一小時，然後結束時間就只是多個半小時，反正無論起始，它現在都變成過去的時間了，代表 ACME Client 一旦看到，就應該立即更新憑證！

**來續約**

```bash
sudo podman run --rm -e CLOUDFLARE_DNS_API_TOKEN=xxx -v ./cert2:/cert:rw goacme/lego --server=https://acme-staging-v02.api.letsencrypt.org/directory -a --path "/cert" --email xxx@xxx.com --dns cloudflare -d "demo.xlion.dev" renew


2025/04/29 16:09:27 [INFO] [demo.xlion.dev] acme: renewalInfo endpoint indicates that renewal is needed
2025/04/29 16:09:27 [INFO] [demo.xlion.dev] acme: Trying renewal with 2156 hours remaining
2025/04/29 16:09:27 [INFO] renewal: random delay of 1m0.707261545s
2025/04/29 16:10:28 [INFO] [demo.xlion.dev] acme: Obtaining bundled SAN certificate
2025/04/29 16:10:28 [INFO] [demo.xlion.dev] AuthURL: https://acme-staging-v02.api.letsencrypt.org/acme/authz/196855784/17080207074
2025/04/29 16:10:28 [INFO] [demo.xlion.dev] acme: authorization already valid; skipping challenge
2025/04/29 16:10:28 [INFO] [demo.xlion.dev] acme: Validations succeeded; requesting certificates
2025/04/29 16:10:29 [INFO] Wait for certificate [timeout: 30s, interval: 500ms]
2025/04/29 16:10:34 [INFO] [demo.xlion.dev] Server responded with a certificate.
```

可以看到

`acme: renewalInfo endpoint indicates that renewal is needed` 就是說 ARI 端點說「需要更新」， 另外 `acme: Trying renewal with 2156 hours remaining` 表示在憑證還有 2156 小時時進行更新，也就是 89.8333...天。

## 短期憑證

1. [Let's Encrypt 將在 2025 年終止 OCSP 服務](https://letsencrypt.org/2024/12/05/ending-ocsp/)
2. 在 2025 年 1 月時，Let's Encrypt 宣布了[將在 2025 年提供 6 天以及 IP 地址的憑證](https://letsencrypt.org/2025/01/16/6-day-and-ip-certs/)

3. 以及 4 月 [CA/Browser Forum 投票通過了 TLS 憑證的有效期最終將縮減至 47 天](https://www.digicert.com/blog/tls-certificate-lifetimes-will-officially-reduce-to-47-days)

這三件事會交叉一起講

### 撤銷了，然後呢

首先我們得先講講憑證撤銷的事情，目前，憑證撤銷後需要透過 CRL 和 OCSP 協定來傳播資訊，CRL 是比較早期的技術，原理是去下載憑證撤銷列表下來比對，但隨著網路發展，這個列表會越來越大，導致客戶端的效率降低，所以 OCSP 出現了，它不用下載龐大的撤銷列表，而是每次連結時，直接去 CA 伺服器問說這個憑證是否有效，有沒有被撤銷，看似很美好，但經過了多年驗證，人們發現了兩個主要問題：**效能**以及**隱私**

首先是效能，蛤？ 不是說 OCSP 解決了效能問題嗎？

但結果事實是，性能開銷並沒有消失，而是把開銷轉移到 CA 身上了

因為每個使用者存取網站時，都會向 OCSP 取得憑證資訊，導致 CA ~~的笑容消失~~要負擔非常大的資源來運行 OCSP 伺服器，感覺變成有點本末倒置，而且也不環保。

接著是隱私，OCSP 就是每次存取網站時都會去取得單個憑證的狀態，這就意味著暴露使用者存取某網站的事實，不管是暴露給 CA，還是與 OCSP 取得資訊時導致的中間人側錄，不管是 OCSP 還是 CRL，傳輸都不是加密的，這會導致 OCSP 成為很大的隱私破口。（註：這兩種資訊傳遞前都會進行簽名，所以雖傳輸沒加密，也不必擔心內容被竄改，但依然會洩漏請求跟傳輸的資訊）

另外，大多數的瀏覽器對於憑證撤銷資訊都是 **Soft-fail / Fail open** 的，也就是說倘若因任何原因取得失敗，瀏覽器是會照樣放行的，讓憑證吊銷資訊形同虛設，取得失敗的原因非常多，首先是 CA 超載可用性下降、網路不好、離 CA 伺服器物理距離太遠延遲很高甚至連不上、位於中國大陸地區等等，雖然後續有推出 OCSP Stapling 功能，也就是客戶端預先取得 Web Server 預先「裝訂」好的 OCSP 資訊，再搭配 OCSP Must Staple，這告訴瀏覽器，如果他們在憑證中看到該擴展，他們就不應該就此聯繫 CA，而應該期望在握手中看到裝訂好的副本，但，事與願違，不管是瀏覽器或 Web Server 對於 Must Staple 都並不完整，後者更嚴重，會直接導致服務中斷。

### 6 天憑證

[Let's Encrypt 宣布將在 2025 年提供 6 天以及 IP 地址的憑證](https://letsencrypt.org/2024/12/05/ending-ocsp/)，首先是 IP，比較好理解，因為對於非企業用戶而言，很難有效的確保用戶是否長期持有某 IP 地址，所以乾脆就把憑證有效期縮短，就可以免除這個問題了。

再來是普通時候的 6 天憑證，剛剛講到憑證撤銷所帶來的困難，就算撤銷了，也會有非常大的機率導致被撤銷的憑證依然能被使用，那麼就直接縮短憑證的有效期限來減輕因憑證洩漏而導致的損害，而且還可以因此省去 CRL 和 OCSP，因為它們不需要，也往往無法派上用場。

過了三個月，也就是 4 月，[CA/Browser Forum 投票通過了 TLS 憑證的有效期最終將縮減至 47 天](https://www.digicert.com/blog/tls-certificate-lifetimes-will-officially-reduce-to-47-days)，縮短是逐步縮短的，規則如下:

* 從今天到 2026 年 3 月 15 日， TLS 憑證的最長有效期限為 398 天。
* 自 2026 年 3 月 15 日起，TLS 憑證的最長有效期限為 200 天。
* 自 2027 年 3 月 15 日起，TLS 憑證的最長有效期限為 100 天。
* 自 2029 年 3 月 15 日起，TLS 憑證的最長有效期限為 47 天。

基本上論點與 Let's Encrypt 6 天憑證相同，但列出更詳細的理由：

* 從簽發時刻起，時間越長，證書中所表示的數據（例如網域擁有權驗證）與實際情況出現偏差的可能性就越大。因此，縮短證書有效期限和資料重用期間可以提高證書的平均淨可靠性
* 證書有效期和資料重用期的減少會降低證書中包含的資訊不再準確後仍然有效的可能性，例如域名搶註、過期或第三方的金鑰存取/控制
* 讓憑證的自動頒發、替換和輪換機制進一步的推動
* 憑證狀態服務（例如 CRL 和 OCSP）因各種原因無法良好發揮作用
* 考慮到演算法、函式庫或生態系統等迅速發展，或因弱點需儘速輪換等，例如以前的 SHA-1，因為憑證時間過長所以花很久替換掉

### 反駁論點

事先聲明，個人是正方。

* IIS 不支援
    * IIS 早已有成熟的第三方 ACME Client
* Tier 1 防火牆不支援
    * Fortinet, Cisco, Juniper 等都支援了
* 物聯網設備
    * 你應該自行建立你自己的根憑證，並自己簽發自己的中繼憑證跟葉證書

<hr>

## 以下內容會有點零散...

### \*不要\*移除 TLS Client Auth EKU !

我引用一下我在 Let's Encrypt Community [的一段評論](https://community.letsencrypt.org/t/do-not-remove-tls-client-auth-eku/237427/27)

> Every times when WebPKI or certificates policies changed, we get some people yelling, some of them are just don't like change, but lots of them are relying one of the changed policies that are not the intended usage, like "I'm getting troubles on my always offline systems" or "My IoT devices...." when 47 day policy comes, this is why you need to generate your on root CA.
> 每次 WebPKI 或憑證政策發生變化時，我們都會聽到一些人大喊大叫，他們中的一些人只是不喜歡改變，但許多人依賴於某個已更改的政策，而這些政策並不是預期用途，例如“我始終離線的系統遇到了麻煩”或“我的 IoT 設備......”當 47 天政策到來時，這就是為什麼您需要生成您的根 CA。
> 
> Sounds like some mail servers are relying wrong function to check the origin, the correct way is SPF+DKIM+DMARC
> 聽起來有些郵件伺服器依賴錯誤的功能來檢查來源，正確的方法是 SPF+DKIM+DMARC
> 
> People are previously arguing reverse DNS lookup is important for mail servers, but since DKIM become supposed on most mail servers, this problems are gone, not to mention reverse DNS still not an option for lots of providers.
> 人們以前爭論說反向 DNS 查找對於郵件伺服器很重要，但自從 DKIM 在大多數郵件伺服器上成為主流後，這個問題就消失了，更不用說反向 DNS 仍然不是許多提供者的選擇。


這篇是一位電子郵件伺服器的維護者請求不要移除 TLS Client Auth（TLS 客戶端驗證）的 EKU，因為這樣它的 Email server 就容易被判定為垃圾郵件。 這不太對吧，現在你只要妥善設置 SPF+DKIM+DMARC，幾乎就都沒問題了，首先是 SPF，它裡面的內容其實主要是 Mail server 的 IP 地址們，這是最基礎也存在許久的要求，再來是 DKIM+DMARC，這兩個是比較新的，但也好一陣子了，DKIM 就是把 Mail server 的簽章公鑰放在 DNS 紀錄上，然後 Mail server 在發信時都會先簽章後再送出，如此一來就更能驗證 Mail server 的身分，DMARC 簡單來講是一種 policy 設定，它可以要求收信端的 Mail server 遇到不符合標準的 mail 時該怎麼做，可以是拒收、丟垃圾信或放行，另外還會寄送報告給指定收件人，可以檢視來自他們網域所發的信的合規情形。

其實這就是典型的那種「被廣泛使用的 bug」導致想修掉它反而導致會導致災難性後果導致不能修的情況，像是Linux kernel 就發生過這樣的情況，但我忘了是什麼事情了。 在憑證領域沒有這樣的問題，比較不用為了遷就而去阻礙整個行業的發展，而且這也關乎到資訊安全，很多人都不想馬虎。

### 組織慣性如何將 WebPKI 中的風險外部化

[How Organizational Inertia Externalizes Risk in the WebPKI](https://unmitigatedrisk.com/?p=974)

*部分文句為使用其翻譯文本並綜合本人看法混合改寫而成，我非常推薦你閱讀原文*

#### 時長

這裡講道以前的憑證長達 5 年甚至 10 年，蘋果想打破這個現狀，它想把憑證最長長度縮為 1 年，但憑證商們以及整個 CA/Browser Forum 都不想理蘋果，結果它們在 2020 年初單方面地宣布，Safari 將在 2020 年 8 月 31 日之後拒絕接受有效期超過 398 天的證書，導致 CA 措手不及，最後 CA/Browser Forum 才在 2021 年通過了SC-42 投票案，將 398 天編纂為共享要求，這證明了 CA 在沒有外力的情況下不會讓步。

裡面有一段有提及一個剛剛上面沒有提到過的案例，上面提到其中一個風險是域名搶註以及所有權轉移，它會發生 [BygoneSSL（過期憑證重用）](https://insecure.design/)的問題

1. 假設 Alice 註冊了 foo.com 以及 bar.com 網域，效期一年
2. 它請求了個包含 foo.com 以及 bar.com 網域的憑證長達 3 年
3. 一年之後，Alice 不再使用 foo.com 的網域了，所以沒續約
4. Alice 不再擁有 foo.com 網域的控制權
5. Bob 發現了這個事情，所以去註冊了 foo.com 的網域
6. Bob 向 CA 請求撤銷 foo.com 網域所頒發的憑證
7. Alice 那張包含 foo.com 以及 bar.com 網域的憑證被撤銷，導致服務中斷 (DoS)

這也體現了上述提及的

> 從簽發時刻起，時間越長，證書中所表示的數據（例如網域擁有權驗證）與實際情況出現偏差的可能性就越大。因此，縮短證書有效期限和資料重用期間可以提高證書的平均淨可靠性

所以這次 47 天憑證也毫不意外地是蘋果發起的，但這次大家幾乎都同意，除了幾間日本公司跟 TWCA...

*我們用 30 年證明了憑證撤銷機制不可靠，雖然聽起來很悲哀，但是時候採用其他替代方案了*

#### 批評者的反駁

批評者常常使用的理由是「老系統無法處理頻繁的更新」，但，[Caddy 反向代理](https://caddyserver.com/)以及 [acme.sh](https://github.com/acmesh-official/acme.sh) 又或者是各種外部部署/管理工具的存在證明了事實並非如此；他們的惰性將風險擴散至整個生態系統。

前者 Caddy 是一款內建全自動憑證請求以及 HTTPS 設置的反向代理伺服器，它**預設**會幫所有的網站妥善設置 HTTPS，在極端狀況下，例如它有數千個網域的網站，它還內建速率限制機制和指數退避來避免癱瘓 CA，它會慢慢地幫你把所有網域的 SSL 憑證從頒發到設置全部搞定，連額外設定都不用設，你只要確保你設定所設定的網域是否正確即可，它甚至還支援在 Let'S Encrypt 無法運作時切換到其他憑證商，目前為 [ZeroSSL](https://zerossl.com/)。

後者 acme.sh 是使用 Shell Script 撰寫的 ACME 客戶端，它除了請求憑證外，它還支援自動部署憑證到非常多個系統內，詳情[見此](https://github.com/acmesh-official/acme.sh/wiki/deployhooks)。

如果你說你的舊系統沒有 API 可用？ 那你應該在它前面部署一個反向代理，例如前面所提及的 [Caddy](https://caddyserver.com/)，而且非常老舊的系統本來就不應該在沒有反向代理的情況下直接對外。

*現在超過 90% 的證書頒發都是透過 ACME 協定所頒發的*

甚至有人會說它的伺服器本身是不能連上網際網路的，那麼你本就應該自行產生自己的根憑證並簽發自己的證書，而不是把整個行業拖下水。

## 結語

這是一時興起寫的文章，又遇到憑證縮短的新聞讓我到非常雀躍，本文事先用自己的 [HedgeDoc Server](https://hedgedoc.org/) 開始起草，有好一段時間是在全家外面的桌子然後用手機開 [HedgeDoc](https://hedgedoc.org/) 邊查資料邊寫（我很會善用手機 Chrome 的分頁群組），然後到電腦再接續跟精修與擴充，本文在四月底花約一個禮拜撰寫大部分的內容（也就是範例憑證頒發時間之時），然後就這樣放置了一個月，放到 6/1，然後完成「反駁論點」之後的部分，然後再做最後全文的檢查。

詳細的時間的話，從 [HedgeDoc](https://hedgedoc.org/) 提供的歷史紀錄來看，就是 4/26 密集撰寫到 5/1，然後直接放鳥到 6/1 XD。

另外我還意外發現 Synology DSM UI 無法正確顯示與選擇沒有 CN (Common Name) 的憑證，我已經聯絡 Synology Support，他們也知悉了這是未來會被淘汰的內容，詳細內容請見: [FYI: tlsserver profile will make the certificate unable to choose on Synology DSM - Issuance Tech - Let's Encrypt Community Support](https://community.letsencrypt.org/t/fyi-tlsserver-profile-will-make-the-certificate-unable-to-choose-on-synology-dsm/236919)

本文撰寫初期大量使用 ChatGPT 上網查詢資料來了解規範內容，在具備基本的了解以及資料來源充足之後，開始直接閱讀原始資料來源並用其內容支撐本文的內容與論點，本文無任何使用任何 AI 潤飾的段落，但翻譯段落不在此限。

## Ref:

How It Works - Let's Encrypt: https://letsencrypt.org/how-it-works/

Challenge Types - Let's Encrypt: https://letsencrypt.org/docs/challenge-types/#dns-01-challenge

An Engineer’s Guide to Integrating ARI into Existing ACME Clients: https://letsencrypt.org/2024/04/25/guide-to-integrating-ari-into-existing-acme-clients/

Automated Certificate Management Environment (ACME) Renewal Information (ARI) Extension（標準規範，撰文之時為 08 版）:
https://datatracker.ietf.org/doc/draft-ietf-acme-ari/

ARI recommendation may cause renewal outside Suggested Window - Client dev - Let's Encrypt Community Support（留言，有關 SuggestedWindow）: https://community.letsencrypt.org/t/ari-recommendation-may-cause-renewal-outside-suggested-window/235059/25

Ending OCSP Support in 2025 - Let's Encrypt: https://letsencrypt.org/2024/12/05/ending-ocsp/

Announcing Six Day and IP Address Certificate Options in 2025 - Let's Encrypt: https://letsencrypt.org/2025/01/16/6-day-and-ip-certs/

TLS Certificate Lifetimes Will Officially Reduce to 47 Days | DigiCert: https://www.digicert.com/blog/tls-certificate-lifetimes-will-officially-reduce-to-47-days

Voting Period Begins: SC-081v3: Introduce Schedule of Reducing Validity and Data Reuse Periods: https://groups.google.com/a/groups.cabforum.org/g/servercert-wg/c/bvWh5RN6tYI/m/6yPQAxRcCAAJ

同上但在 GitHub 的討論串: https://github.com/cabforum/servercert/pull/553

How Organizational Inertia Externalizes Risk in the WebPKI: https://unmitigatedrisk.com/?p=974

Do \*NOT\* remove TLS Client Auth EKU! - Feature Requests - Let's Encrypt Community Support （引用我的留言）: https://community.letsencrypt.org/t/do-not-remove-tls-client-auth-eku/237427/27

Automatic HTTPS — Caddy Documentation: https://caddyserver.com/docs/automatic-https

deployhooks · acmesh-official/acme.sh Wiki: https://github.com/acmesh-official/acme.sh/wiki/deployhooks

FYI: tlsserver profile will make the certificate unable to choose on Synology DSM - Issuance Tech - Let's Encrypt Community Support: https://community.letsencrypt.org/t/fyi-tlsserver-profile-will-make-the-certificate-unable-to-choose-on-synology-dsm/236919

## 長內容區

因為我沒辦法把 `<detail>` 跟 code block 一起弄好，所以放至結尾，以免影響閱讀。

### 範例 Python 程式碼

如果因為規範變更等因素導致此程式碼失效，我很建議你將新規範文件送給 ChatGPT 請它幫你重新撰寫，注意，撰文之時 ARI 規範為 08 版。 此程式碼主要是提供 [An Engineer’s Guide to Integrating ARI into Existing ACME Clients](https://letsencrypt.org/2024/04/25/guide-to-integrating-ari-into-existing-acme-clients/) 這篇文章給它進行規範了解。

另外如果只是變更 URI 請修改 `def fetch_ari_info(cert_id):` 部分，Let's Encrypt Production, Staging 環境以及 Google Trust Services 都會提供 ARI。

```python
import subprocess
import base64
import sys
import requests
import re

def extract_cert_info(cert_path):
    cert_text_result = subprocess.run(
        ["openssl", "x509", "-in", cert_path, "-noout", "-text"],
        capture_output=True,
        text=True,
        check=True
    )
    cert_text = cert_text_result.stdout

    aki_hex = None
    issuer_line = None
    lines = cert_text.splitlines()

    for idx, line in enumerate(lines):
        if "Authority Key Identifier" in line:
            next_line = lines[idx + 1].strip()
            if next_line.startswith("keyid:"):
                aki_hex = next_line.split("keyid:")[1].strip().replace(":", "")
                break
            else:
                # 如果沒有 keyid:，就檢查是不是 raw hex
                if re.match(r'^([0-9A-Fa-f]{2}:)+[0-9A-Fa-f]{2}$', next_line):
                    aki_hex = next_line.replace(":", "")
                    print("⚡ 警告：從 raw bytes fallback 解析 AKI。")
                    break

        if "Issuer:" in line:
            issuer_line = line.strip()

    if issuer_line is None:
        issuer = "未知"
    else:
        issuer = issuer_line.replace("Issuer:", "").strip()

    if aki_hex is None:
        raise ValueError("❌ 這張憑證完全找不到 Authority Key Identifier，無法產生 CertID。")

    # 現在正確來抓 Serial Number
    serial_result = subprocess.run(
        ["openssl", "x509", "-in", cert_path, "-noout", "-serial"],
        capture_output=True,
        text=True,
        check=True
    )
    serial_line = serial_result.stdout.strip()

    if not serial_line.startswith("serial="):
        raise ValueError("❌ 找不到 Serial Number。")

    serial_hex = serial_line.split("=")[1].strip()

    return aki_hex, serial_hex, issuer

def build_cert_id(aki_hex, serial_hex):
    aki_bytes = bytes.fromhex(aki_hex)
    serial_bytes = bytes.fromhex(serial_hex)

    aki_b64url = base64.urlsafe_b64encode(aki_bytes).decode('utf-8').rstrip("=")
    serial_b64url = base64.urlsafe_b64encode(serial_bytes).decode('utf-8').rstrip("=")

    cert_id = f"{aki_b64url}.{serial_b64url}"
    return cert_id

def fetch_ari_info(cert_id):
    url_base = "https://acme-staging-v02.api.letsencrypt.org/draft-ietf-acme-ari-03/renewalInfo/"
    full_url = url_base + cert_id

    print(f"🔗 正在連線到: {full_url}")

    try:
        response = requests.get(full_url)
        response.raise_for_status()
    except requests.exceptions.HTTPError as e:
        if response.status_code == 404:
            try:
                error_info = response.json()
                detail = error_info.get('detail', '')
                print(f"❌ ARI 查詢失敗（404）: {detail}")
            except Exception:
                print("❌ ARI 查詢失敗（404），無法解析錯誤訊息。")
        else:
            print(f"❌ 其他 HTTP 錯誤: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 無法連線或其他錯誤: {e}")
        sys.exit(1)

    data = response.json()
    print("🌟 ARI 回傳內容：")
    print(data)

    if "suggestedWindow" in data:
        start = data["suggestedWindow"]["start"]
        end = data["suggestedWindow"]["end"]
        print(f"✅ 建議續期時間：{start} ~ {end}")
    else:
        print("⚠️ 這張憑證目前無建議續期時間 (可能是已撤銷或失效)")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"用法: python {sys.argv[0]} your-cert.pem")
        sys.exit(1)

    cert_path = sys.argv[1]

    try:
        aki_hex, serial_hex, issuer = extract_cert_info(cert_path)
    except ValueError as e:
        print(str(e))
        sys.exit(1)

    print(f"📋 簽發者 (Issuer)：{issuer}")
    print(f"📋 AKI (hex)：{aki_hex}")
    print(f"📋 Serial (hex)：{serial_hex}")

    cert_id = build_cert_id(aki_hex, serial_hex)

    fetch_ari_info(cert_id)
```

### 範例憑證

```
openssl x509 -in certificates/demo.xlion.dev.crt -text -noout

Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            2c:27:6e:ee:5a:5b:3a:fb:51:15:ea:68:9c:e1:93:87:82:ab
        Signature Algorithm: ecdsa-with-SHA384
        Issuer: C = US, O = (STAGING) Let's Encrypt, CN = (STAGING) Pseudo Plum E5
        Validity
            Not Before: Apr 29 12:40:52 2025 GMT
            Not After : Jul 28 12:40:51 2025 GMT
        Subject: CN = demo.xlion.dev
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (256 bit)
                pub:
                    04:ac:69:08:46:25:e0:2f:5c:c4:4a:20:f5:f7:66:
                    0d:3a:e4:db:ed:32:15:e1:37:e6:81:97:49:46:1a:
                    49:c4:5f:1e:78:2e:da:87:c2:27:a0:69:e2:a4:17:
                    de:6f:38:f2:6b:b2:c1:90:df:47:df:a6:59:01:c5:
                    80:72:11:3e:79
                ASN1 OID: prime256v1
                NIST CURVE: P-256
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Key Identifier:
                B1:C6:18:A1:20:33:5D:B3:8C:A3:FD:C0:57:50:FF:F2:F6:C9:D3:49
            X509v3 Authority Key Identifier:
                FC:46:D1:01:43:5F:BB:7B:A6:3D:30:68:AE:11:BA:E0:BC:6D:C9:D3
            Authority Information Access:
                CA Issuers - URI:http://stg-e5.i.lencr.org/
            X509v3 Subject Alternative Name:
                DNS:demo.xlion.dev
            X509v3 Certificate Policies:
                Policy: 2.23.140.1.2.1
            X509v3 CRL Distribution Points:
                Full Name:
                  URI:http://stg-e5.c.lencr.org/44.crl
            CT Precertificate SCTs:
                Signed Certificate Timestamp:
                    Version   : v1 (0x0)
                    Log ID    : DD:99:34:FC:A5:E7:24:80:C9:56:68:7D:81:34:99:08:
                                49:B2:49:F7:B5:69:D8:C7:BC:AB:3F:5C:C1:F3:6E:64
                    Timestamp : Apr 29 13:39:22.836 2025 GMT
                    Extensions: none
                    Signature : ecdsa-with-SHA256
                                30:45:02:21:00:8D:7A:0F:0A:FC:76:98:0A:76:5A:3E:
                                34:FA:27:23:8A:3E:2C:32:E3:40:92:4E:3A:CB:48:23:
                                CE:F4:4D:49:C1:02:20:69:F6:B7:C8:D9:11:2B:06:55:
                                40:8A:56:46:37:B8:FA:A7:FD:96:F6:C1:46:01:D8:15:
                                B4:33:4E:DA:65:F8:FC
                Signed Certificate Timestamp:
                    Version   : v1 (0x0)
                    Log ID    : C0:5D:20:54:38:5C:B2:CF:B2:17:92:0D:2F:0D:C7:83:
                                52:61:47:B1:AA:4F:EF:97:CA:78:E1:F0:BB:84:FC:ED
                    Timestamp : Apr 29 13:39:23.371 2025 GMT
                    Extensions: 00:00:05:00:12:57:9E:9E
                    Signature : ecdsa-with-SHA256
                                30:45:02:21:00:A1:54:87:AB:41:1D:FD:1D:2B:F5:0C:
                                CD:CC:D2:1C:0F:B9:FD:6E:0C:4C:9C:F1:1D:57:0E:D5:
                                D0:96:34:1F:34:02:20:13:50:35:80:9D:AE:DB:DF:E0:
                                E2:A0:B4:DB:66:B9:74:92:3F:B5:28:D8:9F:4F:E0:23:
                                C4:90:87:DD:91:E3:72
    Signature Algorithm: ecdsa-with-SHA384
    Signature Value:
        30:65:02:30:57:30:8c:16:8c:87:4a:bd:3f:e9:d1:39:22:87:
        c1:fd:ad:e3:57:1d:33:44:2b:01:95:64:fc:2d:12:be:8d:c5:
        ba:38:ff:37:5b:88:d2:65:d7:a4:c1:e8:99:6d:f9:17:02:31:
        00:95:7f:73:2b:57:12:8a:9d:36:c6:15:7e:94:1f:cd:1f:d3:
        45:b4:e5:93:54:cf:23:c0:64:67:b9:d5:34:52:fe:bb:93:dc:
        65:a8:4c:c4:d7:5f:13:5e:fe:fb:5e:2d:d6
```