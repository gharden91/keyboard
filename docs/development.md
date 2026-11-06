# Development

## Where Swift runs

- **Mac (Xcode):** everything. This is the only place the host app and the
  keyboard extension build, and the only place they run on a simulator or
  device.
- **Cloud sessions (Linux container):** run them in the **`keyboard`** cloud
  environment. It is limited-network with package managers on, and it also
  allows `download.swift.org`. Its setup script installs Swift 6.0.3 for
  Ubuntu 24.04 into `/opt` and symlinks it into `/usr/local/bin`, so
  `swift test` works on `Shared/`. The script is idempotent: it skips the
  install when `swift` is already on the path. The **Default** environment
  has no toolchain and blocks `download.swift.org`, along with Docker Hub,
  ECR and GCR image pulls. A session there has only GitHub Actions to check
  its Swift.
- **Bumping Swift:** change `V=` in the environment's setup script (cloud
  environment settings, not the repo) and keep it in step with the tools
  version `Package.swift` declares.

`Shared/` imports Foundation only, never UIKit or CoreGraphics (`SPEC.md`
§4), so it builds the same on the Mac and on Linux. `CGPoint`, `CGSize` and
`CGRect` come from Foundation on both.
