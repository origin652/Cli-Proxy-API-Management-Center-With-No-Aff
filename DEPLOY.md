# 让线上界面去掉「快速开始」

改源码 **不会** 自动更新你正在用的管理页。常见访问方式是：

`http://<主机>:<API端口>/management.html`

这个文件来自 **CLI Proxy API 主程序自带的 Web UI**（上游打包进去的），不是 GitHub 上改完就生效。

## 1. 先确认你打开的是哪一套

| 方式 | 地址 | 是否已是本 fork |
|------|------|-----------------|
| 连后端 | `http://localhost:8317/management.html` 等 | 否，除非已替换文件 |
| 本地开发 | `http://localhost:5173`（`bun run dev`） | 是，用当前源码 |

在 **5173 开发服** 里侧栏没有「快速开始」，说明代码没问题；在 **8317/management.html** 里还有，说明要换 `management.html` 或强刷无效的旧缓存。

## 2. 构建无快速开始版本

```powershell
cd Cli-Proxy-API-Management-Center
bun install --frozen-lockfile
bun run build
Copy-Item dist\index.html dist\management.html -Force
```

产物：`dist\management.html`（约 2.2MB 单文件 HTML）。

## 3. 替换到 CLI Proxy API

把 `dist\management.html` 覆盖到 **CLI Proxy API 实际对外提供该文件的位置**（随安装方式不同路径会变），例如：

- 与 `cli-proxy-api` 可执行文件同目录或文档里写的 `static` / `web` 目录
- Docker 镜像里挂载的静态资源目录

覆盖后 **重启 CLI Proxy API**，浏览器用 **Ctrl+F5** 或无痕窗口再打开 `.../management.html`。

若不知道文件在哪：在 CLI Proxy API 安装目录搜索现有的 `management.html`，用新文件替换同名文件。

## 4. 仅验证 UI（不碰后端）

```powershell
bun run dev
```

浏览器打开 `http://localhost:5173`，连你的 API 后端即可；侧栏应以当前 fork 为准。

## 5. 从本 fork 的 GitHub Release 下载（可选）

若在 `noaff` 仓库发布了带 `management.html` 的 Release，可从 Release 资源下载后按第 3 步替换。