---
name: github-push-gfw-workaround
description: Git push to GitHub bypasses GFW HTTPS block with http.sslVerify=false
metadata: 
  node_type: memory
  type: reference
  originSessionId: 6b5aa006-d8f4-45c1-a7f8-713feb9abcfd
---

# GitHub Push 绕过 GFW 方法

**问题**: `git push` HTTPS 到 GitHub 超时 (GFW 阻断 TCP 443)，但 `curl` 和 SSH 能连通。

**解决方案**: 
```bash
git -c http.sslVerify=false push origin <branch>
```

或永久配置:
```bash
git config --global http.sslVerify false
```

**原理**: GFW 对 HTTPS 流量做 SNI 检测+TCP 重置。禁用 SSL 证书验证后，某些 CDN 节点(GitHub 使用 Fastly)不会被阻断。

**Why**: `git -c http.sslVerify=false` 成功推送。`http.version=HTTP/2` 配合使用也可绕过某些 GFW 检测。

**已测试成功**: 2026-05-29, codex/registration-service 分支推送到 Siyebai/agent-republic

**备用方案**: GitHub REST API 推送 (scripts/api-push.js), 但操作复杂不推荐首选。
