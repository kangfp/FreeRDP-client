#!/bin/bash
# 构建 FreeRDP 客户端 .app
# 用法:
#   ./build.sh            仅构建, 产物在 build/FreeRDPClient.app
#   ./build.sh install    构建并安装到 /Applications
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="FreeRDPClient"
BUILD_DIR="build"
APP="$BUILD_DIR/$APP_NAME.app"

echo "==> 编译 (release)…"
swift build -c release

echo "==> 生成图标…"
mkdir -p "$BUILD_DIR"
if [ ! -f "$BUILD_DIR/AppIcon.icns" ]; then
    swift scripts/generate_icon.swift "$BUILD_DIR/AppIcon.png"
    ICONSET="$BUILD_DIR/AppIcon.iconset"
    mkdir -p "$ICONSET"
    for s in 16 32 128 256 512; do
        sips -z $s $s "$BUILD_DIR/AppIcon.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
        d=$((s * 2))
        sips -z $d $d "$BUILD_DIR/AppIcon.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
    done
    iconutil -c icns "$ICONSET" -o "$BUILD_DIR/AppIcon.icns"
fi

echo "==> 组装 .app…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/$APP_NAME" "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
cp "$BUILD_DIR/AppIcon.icns" "$APP/Contents/Resources/"

echo "==> 签名 (ad-hoc)…"
codesign --force --sign - "$APP"

echo "==> 完成: $APP"

if [ "${1:-}" = "install" ]; then
    echo "==> 安装到 /Applications…"
    rm -rf "/Applications/$APP_NAME.app"
    ditto "$APP" "/Applications/$APP_NAME.app"
    echo "==> 已安装: /Applications/$APP_NAME.app"
fi
