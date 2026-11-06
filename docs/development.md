# Development

## Where Swift runs

- **Mac (Xcode):** everything. This is the only place the host app and the
  keyboard extension build, and the only place they run on a simulator or
  device.
- **Cloud sessions (Linux container):** no Swift toolchain is installed.
  `download.swift.org` is blocked by the default network policy, and so are
  Docker Hub, ECR and GCR image pulls. A cloud session can run `swift test`
  on `Shared/` only in an environment that allows `download.swift.org` and
  installs the toolchain in its setup script. Without one, GitHub Actions is
  the cloud session's feedback loop.

`Shared/` imports Foundation only, never UIKit or CoreGraphics (`SPEC.md`
§4), so it builds the same on the Mac and on Linux. `CGPoint`, `CGSize` and
`CGRect` come from Foundation on both.
