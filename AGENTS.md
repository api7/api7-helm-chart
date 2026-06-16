# AGENTS.md — API7 EE Helm Charts

本仓库（`api7/api7-helm-chart`）收录 API7 EE 各组件的 Helm chart，发布到公开 Helm repo `https://charts.api7.ai`（由 `gh-pages` 分支 + 自定义域名提供）。

| chart | 目录 | 版本是否等于 EE 版本 |
|---|---|---|
| `api7ee3`（Control Plane / Dashboard） | `charts/api7` | 是，appVersion = EE 版本 |
| `gateway`（Data Plane） | `charts/gateway` | 是，appVersion = EE 版本 |
| `api7-ingress-controller` | `charts/ingress-controller` | 否，有独立产品版本 |
| `developer-portal-fe` | `charts/developer-portal-fe` | 否，有独立产品版本 |

## 多版本分支维护模型

API7 EE 同时维护多条受支持的发布线（如 3.9.x、3.10.x），chart 必须能在不互相干扰的前提下分别打补丁。

### 分支布局

- **`main`** = 当前最新发布线（latest），例如现在的 3.10.x。
- **`release/<major>.<minor>`** = 历史发布线，例如 3.9.x 在 `release/3.9`、3.8.x 在 `release/3.8`。EE 的 major 恒为 3，minor 即"大版本"。

### 切线时机（不变量）

**`main` 永远等于 latest 线。** 当 latest 从 3.10 进到 3.11 时，先 `git branch release/3.10 main` 冻结旧线，**再**在 `main` 上 bump 到 3.11。这样每条被取代的线在被取代的瞬间就有分支，不必事后回去找基点。

新建 `release/<x>.<y>` 时，基点是**该线最后一次发布的 chart 状态**（带有那条线的 values/模板），不是从 `main` 改个号——`main` 可能已经带了更高版本独有的配置。

### 编号规则（承重，决定 `helm upgrade` 语义）

对 **appVersion 等于 EE 版本的 chart（`api7ee3`、`gateway`）**：

- chart 的 `major.minor` **跟随 EE 的 minor**：`main`(3.10) 用 `3.10.*`，`release/3.9` 用 `3.9.*`。
- chart 的 `patch` 是**这条线 chart 自己的计数器**，与 appVersion（EE app patch）**解耦**。每条线从 `.0` 起。因此会出现 `chart 3.10.0` 部署 `appVersion 3.10.1` 这种情况——以 appVersion 字段为准，chart patch 仅表示"本线第几个 chart"。

为什么这样：同一个 `charts.api7.ai` index 内，`3.9.x < 3.10.x`，于是 `helm upgrade` 默认取最高版永远停在最新线、不会被后发的老线补丁拽回旧版本；想留在老线的用户用 `--version '~3.9'` 锁定。若用不透明线性号（如 `0.18.x`），后发的 3.9 补丁号会窜到 3.10 之上，把 upgrade 语义带乱。

代价：同一条线内 chart 不能再用 major bump 表达破坏性变更——维护线本就只收向后兼容的 bugfix，破坏性变更只跟随 minor（新 EE 线）走。

对 **独立版本的子 chart（`ingress-controller`、`developer-portal-fe`）**：它们的版本号与 EE minor 不是一个轴，**默认跨 EE 线共享、不随 EE 线 fork**。只有当某条 EE 老线必须搭一个不同版本、且要持续收补丁时，才按它们**自身的产品 minor** 单独拉线维护。

## 发布判定

发布 EE `X.Y.Z` 的 chart 时：

- `X.Y` 是 latest 线（== `main` 当前线）→ 改 **`main`**。
- 否则 → 改 **`release/X.Y`**（不存在则按"切线时机"先建）。

操作铁律：**在任意 `release/*` 分支上，只 bump 这次确实要为该线重发的 chart，其余保持原版本号不动**，让 `CR_SKIP_EXISTING` 自动跳过，避免在子 chart 的线性号空间里撞号。

## 发布机制

`.github/workflows/release.yaml` 在 push 到 `main` 或 `release/**` 时运行 chart-releaser（submodule `helm/chart-releaser-action`）：为每个新版本创建 GitHub Release + `.tgz` 资产，并 merge 更新 `gh-pages` 的 `index.yaml`。要点：

- 触发分支含 `main` 和 `release/**`，老线 push 才能自动出对应 chart。
- 顶层 `concurrency: { group: helm-chart-release, cancel-in-progress: false }`：所有线共用一个 index，必须串行发布、且不取消进行中的 run，避免丢版本。
- `CR_SKIP_EXISTING: true`：已发布版本跳过，index 是 merge 累加，多分支天然安全。
- GitHub Release tag 为 `<chart>-<version>`（如 `gateway-3.9.0`），编号规则保证跨线唯一。
- `ci.yaml`（lint / ct install / helm-docs）同样覆盖 `release/**`。
- 改 chart 后用 `helm-docs --chart-search-root=charts` 重新生成各 chart 的 `README.md`，否则 CI 的 helm-docs 校验会失败。

## 用户升级指引

- 跟随最新线：`helm repo update && helm upgrade <release> api7/<chart>`（默认取最高版，始终是最新 EE 线）。
- 锁定老线：`helm upgrade <release> api7/<chart> --version '~3.9'`（停在 3.9.x，收该线的 chart 补丁，不会跳到 3.10）。

> 跨多个子项目的协同规则（CP/DP/Ingress/docs 等）见工作区根 `AGENTS.md`。
