# Vendor Dependencies

This directory should contain the `LiteRTLMEngine.xcframework` — the prebuilt static libraries from Google's [LiteRT-LM](https://github.com/nicewang/nicewang-LiteRT-LM) project.

These binaries are **not included in the repository** because they are large (~150 MB per platform) and are built from upstream source.

## How to build

1. Clone Google's LiteRT-LM repository
2. Run the build script from the repo root:

```bash
./tools/build_apple_xcframework.sh /path/to/LiteRT-LM
```

3. Copy the output to this directory:

```bash
cp -R /path/to/LiteRT-LM/out/apple/LiteRTLMEngine.xcframework Vendor/
```

The xcframework should contain slices for:
- `ios-arm64` (device)
- `ios-arm64-simulator`
- `macos-arm64`
