# 与上游同步

本仓库在 [router-for-me/Cli-Proxy-API-Management-Center](https://github.com/router-for-me/Cli-Proxy-API-Management-Center) 基础上移除了侧栏与仪表盘中的 **快速开始**，并将 `/quick-start` 重定向到 `/ai-providers`。

## 远程约定

| 远程名 | 用途 |
|--------|------|
| `origin` | 上游主仓库（只拉取，不要 push） |
| `noaff` | 本 fork：`origin652/Cli-Proxy-API-Management-Center-With-No-Aff` |

首次在本机 clone 本 fork 后，若缺少上游远程：

```powershell
git remote add origin https://github.com/router-for-me/Cli-Proxy-API-Management-Center.git
git remote add noaff https://github.com/origin652/Cli-Proxy-API-Management-Center-With-No-Aff.git
git fetch origin
git fetch noaff
```

## 拉取上游更新

```powershell
cd Cli-Proxy-API-Management-Center

git fetch origin
git checkout main
git merge origin/main
```

习惯线性历史时可用 `git rebase origin/main`（推送前若已推过 `noaff`，需 `git push noaff main --force-with-lease`，慎用）。

## 合并冲突时

优先保留本 fork 的定制（无快速开始），涉及文件通常为：

- `src/components/layout/MainLayout.tsx` — 无 `quickStart` 侧栏项
- `src/pages/DashboardPage.tsx` — 无快速开始统计卡片
- `src/router/MainRoutes.tsx` — `/quick-start` → `/ai-providers` 重定向

解决冲突后：

```powershell
git add .
git commit   # 若 merge/rebase 尚未完成提交
git push noaff main
```

## 一键同步 + 去 aff + 发 Release

在 **工作区干净**、当前分支为 `main` 时，在 Git Bash / WSL / Linux / macOS 下执行：

```bash
bash scripts/sync-and-release.sh
```

脚本会依次：

1. `git fetch origin` 并 `git merge origin/main`（有冲突则 **退出并提示** 你手动解决）
2. 应用 `scripts/remove-quick-start.patch`（去掉侧栏/仪表盘快速开始并重定向路由）
3. `git push noaff main`
4. 自动递增 tag（如 `v1.9.4-noaff.2`）并 `git push noaff <tag>`，触发 GitHub Actions 打包 `management.html`

可选环境变量：`UPSTREAM_REMOTE`、`FORK_REMOTE`、`TAG_PREFIX`（默认 `noaff`）。

## 日常推送

只推送到自己的仓库：

```powershell
git push noaff main
```