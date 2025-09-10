---
title: Let's Encrypt 簽發了兩個新根憑證，YE 以及 YR
date: 2025-09-10T23:41:06+08:00
#lastmod:
draft: "false"
tags: [letsencrypt,ca-browser-forum, certificate]
categories: [WebPKI]
#authors: ""
summary: Let's Encrypt 簽發了兩個新的根憑證，名為 ISRG Root YE 以及 ISRG Root YR，有效日期為 20 年，中繼憑證名稱為 YE1/YE2/YE3 以及 YR1/YR2/YR3，由於命名規則改變，屆時我們將徹底失去看到 R20 的可能性
---

這篇文比較水，都在做重點引用

## 根的命名

Let's Encrypt 簽發了兩個新的根憑證，名為 ISRG Root YE 以及 ISRG Root YR，有效日期為 20 年 （Not After : Sep  2 23:59:59 2045）

下次新金鑰儀式預計在 2030 舉行。

這次稍微調整了命名規則

第一個英文 Y 是世代，上一個是 X，例如現有的 X1 與 X2

第二個字不再用純數字，而是演算法，E=ECDSA, R=RSA，不像以前用數字，這樣會更好辨識，至於這次一次弄兩個是因為要在日後方便推進後量子 (PQC) 密碼學的演算法，而不用因為兩個根憑證的時間差問題導致互相牽制

[引用 @aarongable 有關如此命名的原因](https://community.letsencrypt.org/t/preview-of-our-upcoming-root-ceremony/239494/22)

> And as we expand into more algorithms in a post-quantum world, numbers will be confusing and hard to interpret. Fundamentally: numbers should be used for things in a sequence, and different algorithms are not sequenced. The name "ISRG Root X2" was, in hindsight, arguably a mistake.
>
> **隨著我們在後量子世界中擴展到更多演算法，數字將會變得令人困惑且難以解釋。根本上：數字應該用來表示序列中的事物，而不同的演算法並沒有順序可循。事後看來，「ISRG Root X2」這個名字可以說是個錯誤。**

先看看現有的兩個根的演算法跟有效日期

* **ISRG Root X1**
  * RSA 4096
  * 2015-06-04 -> 2030-06-04
* **ISRG Root X2**
  * ECDSA P-384
  * 2020-09-04 -> 2035-09-04
  
X1, X2 演算法不一樣，實際上也不太算同個世代，並且光看名字沒辦法得知太多有用的資訊，也不知道它是什麼演算法

[引用 mcpherrinm 有關 PQC 根](https://community.letsencrypt.org/t/preview-of-our-upcoming-root-ceremony/239494/17)

> I also expect we will add a post quantum root during the period which the “Y” roots are current. I can’t say for sure, but if it’s an MLDSA root, I would expect that to be root YM. It will not be issued until at least 2026, if not later.
> 
> **我還預計，在“Y”根持續存在的時期（世代），我們會添加一個後量子根。我不確定，但如果是 MLDSA 根，我預計它會是 YM 根。它至少（最快）」要到 2026 年才會發布，甚至更晚。**
>
> Depending on advances in Quantum Computing, we may begin deprecation of the RSA and ECDSA roots, but the timeline for that is unknown.
> 
> **根據量子計算的進步，我們可能會開始棄用 RSA 和 ECDSA 根，但具體時間尚不清楚。**

屆時憑證演算法最多將會同時存在三個....想想就很精彩

## 中繼憑證

新的中繼憑證的命名方式同樣也加入世代的辨識文字，也就是<strong>「世代+演算法+流水號」</strong>，而不是直接累加，這會讓每一世代的數字重置，就不會再發生現有 RSA 中繼憑證疊加到 R13 的現象了（沒有 R20 了，悲）

所以新的中繼憑證名稱為：**YE1/YE2/YE3** 以及 **YR1/YR2/YR3**。

## 15 年的根憑證週期？還有交叉簽名以及詭異又不可避免的憑證鏈

根據 [CA/Root CA Lifecycles - MozillaWiki](https://wiki.mozilla.org/CA/Root_CA_Lifecycles)，所有的 TLS 根憑證將在 15 年後刪除，這麼做是因為現有的演算法可能在可遇見的未來遭到破解，此措施確保不會發生一個根憑證會存留長達 25 年的現象，讓容易受攻擊甚至已經被破解的根憑證遭到利用。

且根據 [Chrome Root Program Policy, Version 1.7](https://googlechrome.github.io/chromerootprogram) 的 4.1.2 Root CA Succession Planning 根 CA 繼任計劃

> CA Owners SHOULD request for the replacement of a certificate included in the Chrome Root Store no later than 5 years after the release date of the Chrome Root Store's initial inclusion of the certificate.
>
> **CA 擁有者應在 Chrome 根儲存區首次包含該憑證的發布日期後 5 年內要求更換 Chrome 根儲存區中包含的憑證。**
>
> The CA certificate being replaced will be removed from the Chrome Root Store upon the absence of unexpired and unrevoked TLS server authentication certificates
>
> **一旦缺少未過期且未撤銷的 TLS 伺服器驗證證書，被替換的 CA 證書將從 Chrome 根儲存區中刪除**

對了，雖然 15 年的規定並沒有寫進 CA/B Forum 規範內，但兩大瀏覽器引擎都這樣制定了，基本上就可以視為天條，大家都必須遵守了。

[引用 mcpherrinm 有關憑證鏈](https://community.letsencrypt.org/t/preview-of-our-upcoming-root-ceremony/239494/17)

> Chrome will remove X1/X2 once YR/YE are trusted and all certificates have been replaced, so servers will likely need to serve both an older root (Gen X now) and a current root (Gen Y).
> 
> **一旦 YR/YE 受到信任並且所有憑證都已被替換，Chrome 將刪除 X1/X2，因此伺服器可能需要同時提供舊根（現在是 X 代）和當前根（Y 代）。**
>
> In 5 years (2030), we will issue Gen Z roots. At that time, we expect Gen Y to be fully trusted, and so the default chain will switch to Gen Y and Gen Z, with Gen X still available if needed, but the chain will be getting longer. 5 years after (2035) that we will issue a new Gen A. X1 will expire and no longer be available. Users can chain to X2, A, Z or Y depending on their needs.
>
> **五年後（2030 年），我們將發表 Z 代根。屆時，我們預計 Y 代將完全可信，因此預設鏈將切換到 Y 代和 Z 代。如有需要，X 代仍然可用，但鏈會變得更長。五年後（2035 年），我們將發布新的 A 代。 X1 代將過期，不再可用。用戶可以根據需要連結到 X2、A、Z 或 Y 代。**
>
> We also expect technology like [TLS Trust Anchor Identifiers](https://www.ietf.org/archive/id/draft-beck-tls-trust-anchor-ids-00.html) will help avoid overly long chains as well.
> 
> **我們也希望 [TLS 信任錨標識符](https://www.ietf.org/archive/id/draft-beck-tls-trust-anchor-ids-00.html)等技術也有助於避免過長的鏈。**

然後[引用 @aarongable 有關憑證鏈](https://community.letsencrypt.org/t/preview-of-our-upcoming-root-ceremony/239494/22)

> > Does this mean that future (default) chains will de facto become longer?
> >
> > **這是否意味著未來（預設）鏈條實際上會變得更長？**
> >
> Yes. This is an unavoidable consequence of the fact that ISRG Root X1 and ISRG Root X2 will be removed from the Chrome trust store as soon as the last cert issued from the old hierarchy expires. Any website which serves a chain which includes only Root YR will be untrusted by old clients; any website which serves a chain which includes only ISRG Root X1 will be untrusted by new clients. We must provide a chain that includes both of those roots for compatibility with both updated and un-updated chrome instances.
> 
> **是的。這是不可避免的後果，因為一旦舊層次結構頒發的最後一份憑證到期，ISRG Root X1 和 ISRG Root X2 就會從 Chrome 信任庫中移除。任何服務於僅包含 Root YR 的鏈的網站都將失去舊客戶端的信任；任何服務於僅包含 ISRG Root X1 的鏈的網站也將失去新客戶端的信任。我們必須提供包含這兩個根的鏈，以確保與更新和未更新的 Chrome 實例相容。**

重點在以上的最後一個引用，Chrome 會在可行的時候提早把舊根憑證淘汰掉，這產生很尷尬的情況，就是在時間交界處會有大量的使用者存留在兩邊，屆時就必須同時提供兩種憑證鏈，一個是舊的根，另一個新的根，另外，如果在 2030 ~ 2035 之間，如果有要相容 ISRG Root X2 的需求，那麼

就會產出驚人的***三條***憑證鏈，或是用各種錯綜複雜且我現在也難以解釋的交叉簽名方式搞出可以相容三者的鏈，精彩。

## 撰寫此文的動機

是因為我意識到，本來可能在未來可以看到名為 **"R20"** 的中繼憑證，但突然被消滅了。

很臨時寫的，所以組織起來比較凌亂，但我盡量用排版讓畫面看起來舒服。

## Ref

（引用的文字都在這）
Preview of our upcoming Root Ceremony - Issuance Tech - Let's Encrypt Community Support: https://community.letsencrypt.org/t/preview-of-our-upcoming-root-ceremony/239494

Add configs for 2025 ceremony by aarongable · Pull Request #18 · letsencrypt/ceremony-demos: https://github.com/letsencrypt/ceremony-demos/pull/18

Chains of Trust - Let's Encrypt: https://letsencrypt.org/certificates

CA/Root CA Lifecycles - MozillaWiki: https://wiki.mozilla.org/CA/Root_CA_Lifecycles

Chrome Root Program Policy, Version 1.7: https://googlechrome.github.io/chromerootprogram
