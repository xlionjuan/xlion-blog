---
title: 在 Hermes Agent 設定 MiniMax Token Plan MCP 以獲得視覺與網路搜尋功能
date: 2026-04-29T20:32:06+08:00
#lastmod:
draft: "false"
tags: [minimax, mcp,'hermes agent', gemini]
categories: ['ai agent']
#authors: ""
summary: MiniMax 不是多模態模型，在 Hermes Agent 要怎麼看圖？
---

由於這涉及到 token，Hermes Agent 會自動 redact token 部分導致編輯失敗，你得自己來。

> [!TIP] 其實
> 其實此行為可關閉，但我不會教你，你必須閱讀官方文件並在**知悉風險**後手動關閉

## 能做什麼

這兩個功能

* `web_search`
* `understand_image`

## 加入到你的 `config.yaml`

```yaml
mcp_servers:
  minimax:
    args:
    - minimax-coding-plan-mcp
    - -y
    command: uvx
    env:
      MINIMAX_API_HOST: https://api.minimax.io
      MINIMAX_API_KEY: sk-cp-blabla用你的 API Key 填滿我
    timeout: 120
```

不要無腦加，同根層級的 `mcp_servers` 不能重複出現，真不會，跟你的 Agent 說：**「幫我弄，key 弄成 placehoder 我等等去加」**，它弄好後，你去添加 Key。

還是怕搞砸？文件： https://hermes-agent.nousresearch.com/docs/guides/use-mcp-with-hermes

> [!TIP] 不想要其中一個功能？
> 使用 `hermes mcp configure minimax` 進行調整

## 關掉 `vision_analyze`

否則你的 Agent 看到還是會一直去嘗試，並出錯，使用 `hermes setup` 設定，或叫你 Agent 弄。

```
[ ] 👁️  Vision / Image Analysis  (vision_analyze)
```

## 不能用系統視覺辨識函數（`vision_analyze`）？

以及 `browser_vision` 也會用到

根據 OpenClaw 的程式碼：

* https://github.com/openclaw/openclaw/blob/53d34e7cde7f28ce90625236c8f3b1643465b439/extensions/minimax/openclaw.plugin.json#L82
* https://github.com/openclaw/openclaw/blob/53d34e7cde7f28ce90625236c8f3b1643465b439/src/agents/minimax-vlm.ts
* https://github.com/openclaw/openclaw/blob/53d34e7cde7f28ce90625236c8f3b1643465b439/extensions/minimax/media-understanding-provider.ts#L10

等地方

有一個單獨的圖片辨識模型叫 `MiniMax-VL-01`，那 Hermes Agent 可不可以直接用？不行！

你會發現裡面的 `MiniMax-VL-01` 是一個「虛擬」的一個模型 ID，Image tools 如果匹配到同樣的 provider + 同樣的模型名稱，會直接進入「獨立」的 API 結構流程，並且還提及一個獨立的端點 `/v1/coding_plan/vlm`

我使用過以下端點測試，均無法成功，這證明了 MiniMax 對於它的視覺辨識模型端點是用不同的請求格式，老實說是挺噁心的

1. `/v1/coding_plan/vlm`
2. `/anthropic`
3. `/v1/chat/completions`

那有沒有其他方法？ 有的，就是 auxiliary models 輔助模型，`gemini-3.1-flash-lite-preview` 比一般的 flash 更便宜一些，單純看圖是夠用的，看你是用什麼其他 provider，你必須設定，例如 OpenRouter, Gemini 或是 Nous Research 自家訂閱方案的。

又或是你有 ChatGPT，用 `gpt-5.4-mini`。

```yaml
auxiliary:
  vision:
    provider: nous
    model: google/gemini-3.1-flash-lite-preview
    base_url: ''
    api_key: ''
    timeout: 120
    extra_body: {}
    download_timeout: 30
```

## Ref

https://platform.minimax.io/docs/guides/token-plan-mcp-guide

https://hermes-agent.nousresearch.com/docs/guides/use-mcp-with-hermes

https://hermes-agent.nousresearch.com/docs/user-guide/configuration#auxiliary-models