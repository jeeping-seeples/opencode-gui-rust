# Audit: Baseline Performance Measurements (J-005)

## 1. Environment & Hardware Specifications

Measurements conducted on the cloud agent VM (Ubuntu 24.04 x86_64, 4 vCPUs, 7.8 GiB RAM):
- Application Target: Packaged Electron app (`upstream/packages/desktop/dist/linux-unpacked/ai.opencode.desktop.dev`), version `2.2.5` (`dev` channel).
- Bundled CLI version: `0.0.0-dev-787`.

## 2. Results Summary (5 Packaged Runs)

| Metric | Min | Median | Max | Notes |
|---|---|---|---|---|
| **Startup Time (s)** | 30.85s | **30.92s** | 31.38s | Measured under virtual display in VM |
| **Idle Memory RSS (MB)** | 193.88 MB | **251.11 MB** | 289.16 MB | Whole process tree |
| **Idle Memory PSS (MB)** | 190.42 MB | **247.71 MB** | 285.72 MB | Whole process tree |
| **Idle CPU (%)** | 0.0% | **0.5%** | 1.0% | Near-zero CPU utilization once settled |

## 3. Resource Allocation & Process Breakdown

- Background CLI daemon (`opencode-cli serve --service`): ~190 MB - 250 MB RSS.
- Electron process tree (main + GPU + renderer): ~100 MB - 140 MB RSS.
- Total idle footprint: ~250 MB - 290 MB.
