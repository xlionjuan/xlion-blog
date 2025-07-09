---
title: 不要刪 Synology DSM 的 iSCSI Subvolume
date: 2025-07-10T12:00:06+08:00
draft: "false"
tags: [Synology, Btrfs]
categories: [System Managements]
#authors: ""
summary: 
---

就只是快速紀錄一下，因為也不是特別為了寫而做的事情，嚴格來講，這算是個臨時發生的慘案，但過快一個月才發。

## 起因

在多年前，就因為為了測試而去用 SAN Manager 開 iSCSI 來玩，但機器效能低，I/O 也整個慘，所以根本沒有被拿來實際使用，也就把建立的 iSCSI LUN 刪掉了。

在日後，我一直以為是 iSCSI LUN 刪除時沒有砍快照，導致遺留，然後在近日，我儲存間有點快不夠了，所以就自己 SSH 進去 + 與 ChatGPT 互動想要釋放空間。

我唯一有留的最直接的紀錄是 `sudo btrfs subvolume list /volume1` 的輸出結果

## 清！

這是把事前留的輸出結果進行 `grep iSCSI` 的結果

```
cat output.txt|grep iSCSI

    32:	ID 370 gen 68389479 top level 256 path @iSCSI
    39:	ID 907 gen 71244250 top level 370 path @iSCSI/LUN/VDISK_BLUN/e88719cc-7052-479a-8663-3154e2f0e891
    40:	ID 908 gen 71244250 top level 370 path @iSCSI/LUN/VDISK_BLUN/dc3c8c2a-a6cc-4d8b-a5fc-121301b88ef4
    41:	ID 912 gen 71255737 top level 370 path @iSCSI/Snapshot
    42:	ID 934 gen 71205297 top level 370 path @iSCSI/LUN/VDISK_BLUN/5dc450d9-b525-4741-b101-ae8c93651af5
    43:	ID 936 gen 71205297 top level 370 path @iSCSI/LUN/VDISK_BLUN/18716c31-6086-4244-8457-e0568440573c
    51:	ID 5646 gen 71244250 top level 370 path @iSCSI/LUN/VDISK_BLUN/cb2d072b-d3ec-4b0d-a963-2a9dadee4e43
    52:	ID 5654 gen 71205297 top level 370 path @iSCSI/LUN/VDISK_BLUN/4c4beac5-af97-42fd-83f4-070e70f66024
    60:	ID 56964 gen 32298555 top level 912 path @iSCSI/Snapshot/BLUN/6d4dfe6b-51d6-46c8-9ddf-470c21555d18/141b137c-ba04-4076-9597-d377c0dea38b
    61:	ID 56965 gen 32298559 top level 912 path @iSCSI/Snapshot/BLUN/d49b029c-99b4-4a34-96c8-6b4fae9f8866/3eb381b7-bb93-4613-8744-3c4cfd853a77
    62:	ID 56968 gen 32299083 top level 912 path @iSCSI/Snapshot/BLUN/6d4dfe6b-51d6-46c8-9ddf-470c21555d18/e29740c5-bcd6-4a76-b663-3fbc040f6b5e
    63:	ID 56969 gen 32299091 top level 912 path @iSCSI/Snapshot/BLUN/d49b029c-99b4-4a34-96c8-6b4fae9f8866/89d43d8c-92e4-463f-8ae4-ad369e4c00bf
    67:	ID 64233 gen 71262481 top level 370 path @iSCSI/LUN/VDISK_BLUN/1eb2a864-95c7-45c2-bcb8-12aed5bb37d1
    68:	ID 64234 gen 71262481 top level 370 path @iSCSI/LUN/VDISK_BLUN/224a8aad-166c-4fd5-85b7-d531e04ffde2
    69:	ID 64238 gen 71262622 top level 370 path @iSCSI/LUN/VDISK_BLUN/8bc06e67-a72e-483a-a15d-0fe1762e0d87
    70:	ID 64239 gen 71262622 top level 370 path @iSCSI/LUN/VDISK_BLUN/bd1a49cc-f708-469e-9ede-5aafcbecf4ce
    71:	ID 64240 gen 71262622 top level 370 path @iSCSI/LUN/VDISK_BLUN/99d0d2d6-5489-4d77-ba02-ab341463aa71
    72:	ID 67923 gen 71263786 top level 370 path @iSCSI/LUN/VDISK_BLUN/e968e235-a38d-48a3-86fb-9fbc3b7c4994
    73:	ID 67924 gen 71263392 top level 370 path @iSCSI/LUN/VDISK_BLUN/3adde418-01ab-4795-977b-00e29b995ba2
    84:	ID 78281 gen 45607759 top level 912 path @iSCSI/Snapshot/BLUN/6d4dfe6b-51d6-46c8-9ddf-470c21555d18/fdc084ec-c489-4b2e-8b6a-f296e13b54ee
    85:	ID 78282 gen 45607764 top level 912 path @iSCSI/Snapshot/BLUN/d49b029c-99b4-4a34-96c8-6b4fae9f8866/707d5f81-e12c-424a-b913-4a3cc50967db
    86:	ID 78283 gen 71255663 top level 370 path @iSCSI/LUN/VDISK_BLUN/6d4dfe6b-51d6-46c8-9ddf-470c21555d18
    87:	ID 78284 gen 71255669 top level 370 path @iSCSI/LUN/VDISK_BLUN/d49b029c-99b4-4a34-96c8-6b4fae9f8866
   168:	ID 110195 gen 71255662 top level 370 path @iSCSI/LUN/VDISK_BLUN/7f7f3c91-22c5-4266-90e4-5fe024866d09
   169:	ID 110196 gen 71255667 top level 370 path @iSCSI/LUN/VDISK_BLUN/ec8884f9-72d9-4e9d-86da-af17251d5502
   281:	ID 118020 gen 69604040 top level 912 path @iSCSI/Snapshot/BLUN/7f7f3c91-22c5-4266-90e4-5fe024866d09/4c4921a0-30e7-4ab4-804f-b521983ae361
   282:	ID 118021 gen 69604041 top level 912 path @iSCSI/Snapshot/BLUN/6d4dfe6b-51d6-46c8-9ddf-470c21555d18/478a8461-bceb-490b-8ac4-c1bd89483dbe
   284:	ID 118023 gen 69604048 top level 912 path @iSCSI/Snapshot/BLUN/ec8884f9-72d9-4e9d-86da-af17251d5502/f5217a52-492a-4dcc-a74d-724cddedee02
   285:	ID 118025 gen 69604055 top level 912 path @iSCSI/Snapshot/BLUN/d49b029c-99b4-4a34-96c8-6b4fae9f8866/88003c9e-0b1b-482a-a4f9-1e5fd0c5263c
   303:	ID 118822 gen 70025678 top level 912 path @iSCSI/Snapshot/BLUN/7f7f3c91-22c5-4266-90e4-5fe024866d09/799d5f1e-8d47-4358-bff2-13ebb25de46a
   304:	ID 118823 gen 70025679 top level 912 path @iSCSI/Snapshot/BLUN/6d4dfe6b-51d6-46c8-9ddf-470c21555d18/a8b1fcc5-2ca4-4075-9437-54a1d1280239
   305:	ID 118824 gen 70025684 top level 912 path @iSCSI/Snapshot/BLUN/ec8884f9-72d9-4e9d-86da-af17251d5502/da5e26ee-a6cd-47f2-8529-01ab44d744e3
   306:	ID 118825 gen 70025691 top level 912 path @iSCSI/Snapshot/BLUN/d49b029c-99b4-4a34-96c8-6b4fae9f8866/9410c914-3df8-4751-97ff-32d3864beef7
   356:	ID 119679 gen 70484192 top level 912 path @iSCSI/Snapshot/BLUN/6d4dfe6b-51d6-46c8-9ddf-470c21555d18/adf6e197-81f2-439d-967b-420aa86080be
   357:	ID 119680 gen 70484193 top level 912 path @iSCSI/Snapshot/BLUN/7f7f3c91-22c5-4266-90e4-5fe024866d09/30457383-2192-46be-abf1-f92d0266cc7f
   360:	ID 119685 gen 70484205 top level 912 path @iSCSI/Snapshot/BLUN/d49b029c-99b4-4a34-96c8-6b4fae9f8866/1b8db88a-d7b9-4bb7-994b-f494416d2bd9
   361:	ID 119686 gen 70484208 top level 912 path @iSCSI/Snapshot/BLUN/ec8884f9-72d9-4e9d-86da-af17251d5502/2129f311-77bb-4d5f-b6e7-77e42c1037fa
   394:	ID 120373 gen 70868109 top level 912 path @iSCSI/Snapshot/BLUN/7f7f3c91-22c5-4266-90e4-5fe024866d09/64668b21-783a-4d81-94ea-8aea867b0ecc
   395:	ID 120375 gen 70868116 top level 912 path @iSCSI/Snapshot/BLUN/ec8884f9-72d9-4e9d-86da-af17251d5502/cfe30b21-5fdb-4be7-a39d-af77fe5ed45a
   483:	ID 120484 gen 70940216 top level 912 path @iSCSI/Snapshot/BLUN/7f7f3c91-22c5-4266-90e4-5fe024866d09/f3a326fa-cfd1-4973-9fbd-4a522da19fda
   484:	ID 120485 gen 70940224 top level 912 path @iSCSI/Snapshot/BLUN/ec8884f9-72d9-4e9d-86da-af17251d5502/9aa0f399-62ec-4550-9713-50224e1b41e1
   585:	ID 120591 gen 71003928 top level 912 path @iSCSI/Snapshot/BLUN/6d4dfe6b-51d6-46c8-9ddf-470c21555d18/5e6cf076-10c1-462a-a419-1f34be475dea
   586:	ID 120592 gen 71003929 top level 912 path @iSCSI/Snapshot/BLUN/7f7f3c91-22c5-4266-90e4-5fe024866d09/d438d76b-e61f-486d-a330-3e2dc2548acc
   587:	ID 120593 gen 71003934 top level 912 path @iSCSI/Snapshot/BLUN/d49b029c-99b4-4a34-96c8-6b4fae9f8866/a8caf6c2-1a9e-4c52-8c25-e082794900aa
   588:	ID 120594 gen 71003935 top level 912 path @iSCSI/Snapshot/BLUN/ec8884f9-72d9-4e9d-86da-af17251d5502/b507cb74-c944-4099-9dcd-5921e5e78448
   689:	ID 120721 gen 71051002 top level 912 path @iSCSI/Snapshot/BLUN/7f7f3c91-22c5-4266-90e4-5fe024866d09/d547d9ef-634b-461c-8a90-0567b6f0d44d
   690:	ID 120722 gen 71051003 top level 912 path @iSCSI/Snapshot/BLUN/6d4dfe6b-51d6-46c8-9ddf-470c21555d18/e84e54dd-4193-4e67-9d48-3536dd83dc4f
   691:	ID 120723 gen 71051006 top level 912 path @iSCSI/Snapshot/BLUN/ec8884f9-72d9-4e9d-86da-af17251d5502/ff678d35-a688-4eff-a179-1931b10ac456
   692:	ID 120724 gen 71051007 top level 912 path @iSCSI/Snapshot/BLUN/d49b029c-99b4-4a34-96c8-6b4fae9f8866/a797c32c-f51b-4383-b549-97905289098c
   796:	ID 120832 gen 71097770 top level 912 path @iSCSI/Snapshot/BLUN/7f7f3c91-22c5-4266-90e4-5fe024866d09/0c15adce-74b1-49e1-8b0e-27766ddd7426
   797:	ID 120833 gen 71097771 top level 912 path @iSCSI/Snapshot/BLUN/6d4dfe6b-51d6-46c8-9ddf-470c21555d18/c3770268-4d8b-4a0a-a816-3e3d4aad46a2
   798:	ID 120834 gen 71097776 top level 912 path @iSCSI/Snapshot/BLUN/ec8884f9-72d9-4e9d-86da-af17251d5502/400477fa-6a17-4dc6-a890-edecafed2852
   799:	ID 120835 gen 71097777 top level 912 path @iSCSI/Snapshot/BLUN/d49b029c-99b4-4a34-96c8-6b4fae9f8866/269a461d-ab7a-4b59-a836-1d344a1c06bd
   898:	ID 120938 gen 71145278 top level 912 path @iSCSI/Snapshot/BLUN/7f7f3c91-22c5-4266-90e4-5fe024866d09/e1ab113e-ee2e-4190-92bd-756d2f0eea77
   899:	ID 120939 gen 71145279 top level 912 path @iSCSI/Snapshot/BLUN/6d4dfe6b-51d6-46c8-9ddf-470c21555d18/f4e70280-0063-4ef2-a87c-e6d7c00f8359
   900:	ID 120940 gen 71145283 top level 912 path @iSCSI/Snapshot/BLUN/ec8884f9-72d9-4e9d-86da-af17251d5502/6b7009fe-fe1e-48ca-9bc0-faaeef44b9d7
   901:	ID 120941 gen 71145284 top level 912 path @iSCSI/Snapshot/BLUN/d49b029c-99b4-4a34-96c8-6b4fae9f8866/1de7a2cb-5a34-4a8c-908f-81fd5d99970f
  1038:	ID 121082 gen 71192847 top level 912 path @iSCSI/Snapshot/BLUN/7f7f3c91-22c5-4266-90e4-5fe024866d09/2c6d0814-ab96-4fb5-a6fa-c73f70440d61
  1039:	ID 121083 gen 71192848 top level 912 path @iSCSI/Snapshot/BLUN/6d4dfe6b-51d6-46c8-9ddf-470c21555d18/bde04e15-3531-463f-a8b7-e381cb2bdc89
  1040:	ID 121084 gen 71192852 top level 912 path @iSCSI/Snapshot/BLUN/ec8884f9-72d9-4e9d-86da-af17251d5502/d45b9526-eb08-47e1-894f-76248bd3c2cc
  1041:	ID 121085 gen 71192855 top level 912 path @iSCSI/Snapshot/BLUN/d49b029c-99b4-4a34-96c8-6b4fae9f8866/ae23af37-8f51-440a-a281-be37b4e61977
  1188:	ID 121236 gen 71255662 top level 912 path @iSCSI/Snapshot/BLUN/7f7f3c91-22c5-4266-90e4-5fe024866d09/be37441b-7c1c-4a2d-9f48-0cb1b104a571
  1189:	ID 121237 gen 71255663 top level 912 path @iSCSI/Snapshot/BLUN/6d4dfe6b-51d6-46c8-9ddf-470c21555d18/021e99cc-b16f-4bd3-a0dc-1a09258c3df3
  1190:	ID 121238 gen 71255667 top level 912 path @iSCSI/Snapshot/BLUN/ec8884f9-72d9-4e9d-86da-af17251d5502/c874c513-a36a-4298-92b6-2eac4455cacc
  1191:	ID 121239 gen 71255669 top level 912 path @iSCSI/Snapshot/BLUN/d49b029c-99b4-4a34-96c8-6b4fae9f8866/439337ab-5f8b-42b0-9190-e036375d3999
```

然後我就很興奮的請 ChatGPT 幫我寫遞歸腳本幫我把這些都砍掉，然後我就看著儲存空間管理員的「詳細使用量」隨著空間回收，越來越少...越來越少....

最後想說重開一下，因為我的系統是只有系統更新才重開，但好久沒系統更新了，都破百天了，想說就重開一下，然後，我發現我的虛擬機沒有開，進去後看發現狀態寫「遺失」，Huh，然後我就上網找了一下，看到有 Reddit post 在討論如何轉移 VMM 的儲存空間遷移到別的儲存空間，看到目錄，我傻眼，為何在 `@iSCSI` 之下？

然後再仔細看，`VDISK_BLUN` Huh？

看來 VMM 的虛擬硬碟就包含在這裡面沒錯了。

那我問你，`@Virtualization` 以及 `@libvirt` 這兩個 Subvolumes 幹嘛的？
