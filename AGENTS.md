# AGENTS.md — API7 EE Helm Charts

This repo (`api7/api7-helm-chart`) holds the Helm charts for API7 EE components and publishes them to the public Helm repo `https://charts.api7.ai` (served from the `gh-pages` branch via a custom domain).

| chart | directory | chart version == EE version? |
|---|---|---|
| `api7ee3` (Control Plane / Dashboard) | `charts/api7` | yes — appVersion is the EE version |
| `gateway` (Data Plane) | `charts/gateway` | yes — appVersion is the EE version |
| `api7-ingress-controller` | `charts/ingress-controller` | no — independent product version |
| `developer-portal-fe` | `charts/developer-portal-fe` | no — independent product version |
| `aisix-cp` (AISIX private-deployment control plane) | `charts/aisix-cp` | no — independent product version (source of truth: `api7/AISIX-Cloud` `helm/aisix-cp`) |
| `aisix` (AISIX AI gateway data plane) | `charts/aisix` | no — independent product version; **this repo is the source of truth** (unlike `aisix-cp`, no dev-repo counterpart to sync from) |
| `ngxdig` (eBPF flame-graph / diagnosis agent, DaemonSet) | `charts/ngxdig` | no — independent product version (source of truth: `api7/ngx-flame`) |

## Multi-line maintenance model

API7 EE supports several release lines at once (e.g. 3.9.x and 3.10.x). The charts must let each line receive patches without disturbing the others.

### Branch layout

- **`main`** = the latest (newest) release line, e.g. 3.10.x today.
- **`release/<major>.<minor>`** = a historical line, e.g. 3.9.x on `release/3.9`, 3.8.x on `release/3.8`. The EE major is always `3`; the minor is the "feature line".

### When to cut a line (invariant)

**`main` always equals the latest line.** When the latest moves from 3.10 to 3.11, first `git branch release/3.10 main` to freeze the old line, **then** bump `main` to 3.11. This guarantees every superseded line has a branch the moment it is superseded.

When creating `release/<x>.<y>`, branch from **the last published chart state of that line** (which carries that line's values/templates) — not from `main` renumbered, since `main` may already carry config that only exists in a newer line.

### Version numbering (load-bearing — governs `helm upgrade`)

For charts whose **appVersion is the EE version** (`api7ee3`, `gateway`):

- the chart's `major.minor` **mirrors the EE minor**: `main` (3.10) uses `3.10.*`, `release/3.9` uses `3.9.*`.
- the chart's `patch` is **this line's own counter**, decoupled from the app patch (the EE patch). Each line starts at `.0`. So a `chart 3.10.0` may deploy `appVersion 3.10.1` — `appVersion` is the source of truth for the image version; the chart patch only means "the Nth chart on this line".

Why: in the shared `charts.api7.ai` index, `3.9.x < 3.10.x`, so a plain `helm upgrade` always stays on the newest line and is never dragged back to an older line by a later patch release, while users who want to stay on an older line pin it with `--version '~3.9'`. An opaque linear scheme (e.g. `0.18.x`) would let a later 3.9 patch sort above 3.10 and break that ordering.

Cost: within a single line the chart can no longer use a major bump for breaking changes — but a maintenance line should only take backward-compatible bug fixes; breaking changes ride the next minor (a new EE line).

For **independently-versioned sub-charts** (`ingress-controller`, `developer-portal-fe`): their version axis is not the EE minor, so they are **shared across EE lines and not forked per line** by default. Only fork them onto their **own product minor** when an older EE line must ship a different version of them and keep patching it.

The **AISIX charts (`aisix-cp`, `aisix`) release as a pair**, on the AISIX OP version axis rather than the EE one: at each OP release both get `version` **and** `appVersion` set to that release. `appVersion` pins the image tag on both sides, so the two charts must never carry different `appVersion`s — a control plane and a data plane from different releases is not a combination we ship.

## Release decision

When releasing the chart for EE `X.Y.Z`:

- `X.Y` is the latest line (== `main`'s current line) → edit **`main`**.
- otherwise → edit **`release/X.Y`** (cut it first per "When to cut a line" if it does not exist).

Operational rule: **on any `release/*` branch, only bump the charts you actually intend to re-release for that line; leave the rest at their existing versions** so `CR_SKIP_EXISTING` skips them — this avoids colliding numbers in a sub-chart's linear version space.

## Release mechanism

`.github/workflows/release.yaml` runs chart-releaser (submodule `helm/chart-releaser-action`) on push to `main` or `release/**`: it creates a GitHub Release + `.tgz` asset per new version and merges the update into the `gh-pages` `index.yaml`. Notes:

- triggers include `main` and `release/**`, so a push to an older line publishes its own charts.
- top-level `concurrency: { group: helm-chart-release, cancel-in-progress: false }`: all lines share one index, so releases must be serialized and an in-progress run must never be cancelled, or a release could be dropped.
- `CR_SKIP_EXISTING: true`: already-released versions are skipped and the index is merged (not overwritten), so multiple branches are safe.
- the GitHub Release tag is `<chart>-<version>` (e.g. `gateway-3.9.0`); the numbering rule keeps it unique across lines.
- `ci.yaml` (lint / ct install / helm-docs) also covers `release/**`.
- after editing a chart, regenerate each chart's `README.md` with `helm-docs --chart-search-root=charts`, or the helm-docs CI check fails. Use **v1.13.1**, the version CI installs: 1.14.x appends an `Autogenerated from chart metadata...` footer that CI then rejects, and the `helm-docs` pre-commit hook runs whatever `helm-docs` is on `PATH` — so it happily rewrites every chart README into a form CI fails on. Put a v1.13.1 binary first on `PATH` when committing.

## Gateway chart: which config to expose

The gateway chart's `values.yaml`/configmap mirror the gateway's `conf/config-default.yaml`, **except** for config the control plane owns and delivers to the DP at runtime via the heartbeat config payload / etcd. Never expose these in the chart (a chart-set value would be overridden or would fight the CP):

- `apisix.data_encryption` and `apisix.ssl.key_encrypt_salt` — per-gateway-group keyring (CP `GetDataplaneConfig`)
- `api7ee.consumer_proxy`, `api7ee.developer_proxy`, `api7ee.telemetry` — CP system settings
- dynamic service discovery (`api7_discovery`, K8s/Nacos) — configured per gateway group in the Dashboard
- the enabled `plugins` / `stream_plugins` list — CP manages it through the etcd `/plugins` key, including custom plugins

When adding values, keep defaults identical to `config-default.yaml` so a default render changes nothing. To verify a rendered config is valid, extract `config.yaml` from the rendered configmap and run it through the real image: `docker run --rm --entrypoint sh -v $PWD/config.yaml:/usr/local/apisix/conf/config.yaml api7/api7-ee-3-gateway:<ver> -c 'apisix init'` — the config schema is validated at init.

## developer-portal-fe chart: config is a pass-through

`config.yaml` is rendered from `developerPortal.config`, which carries the application's whole config schema (owned by `api7/api7ee-developer-portal`, `apps/site/src/lib/config/schema.ts`). **Do not hoist schema fields into their own `.Values` keys** — a dedicated key plus template plumbing per field mirrors that schema, drifts on every application release, and leaves two ways to set one field. Only the connection settings the chart itself owns are templated, and they are merged over the block, so a user cannot replace the `${PORTAL_TOKEN}` / `${DB_URL}` / `${AUTH_SECRET}` placeholders with literal credentials — those placeholders stay in the ConfigMap and resolve from Secret-backed env vars at startup.

That is not a licence to skip chart releases: pass-through only means a user is never *blocked* on one, while `values.yaml` is still how they find out an option exists. When the application adds config worth surfacing, add it under `developerPortal.config` and cut a chart release. Write it as a commented example rather than a live default — a live default pins the application's default of that day into the chart and keeps overriding it after the application moves on.

To verify a rendered config, run it through the image's own loader: `docker run --rm -v $PWD/config.yaml:/app/apps/site/config.yaml -e PORTAL_TOKEN=x -e DB_URL=x -e AUTH_SECRET=$(head -c 32 /dev/zero | tr '\0' a) --entrypoint sh api7/api7-ee-developer-portal-fe:<ver> -c 'node preflight.js'` — reaching the `Portal URL:` line means the config validated (the portal/database checks after it need a live backend). That mount path is fixed: the standalone server chdirs into `apps/site`, and preflight looks there.

## User upgrade guidance

- Follow the latest line: `helm repo update && helm upgrade <release> api7/<chart>` (picks the highest version, always the newest EE line).
- Pin an older line: `helm upgrade <release> api7/<chart> --version '~3.9'` (stays on 3.9.x and takes that line's chart patches without jumping to 3.10).
