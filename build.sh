#!/bin/bash
# 构建 FreeRDP 客户端 .app
# 用法:
#   ./build.sh            仅构建, 产物在 build/FreeRDPClient.app
#   ./build.sh install    构建并安装到 /Applications
#   ./build.sh dmg        构建并生成拖拽安装 DMG (build/FreeRDPClient-<版本>.dmg)
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

if [ "${1:-}" = "dmg" ]; then
    echo "==> 制作 DMG…"
    VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")
    DMG="$BUILD_DIR/$APP_NAME-$VERSION.dmg"
    STAGING="$BUILD_DIR/dmg-staging"
    VOLNAME="FreeRDP 客户端"
    rm -rf "$STAGING"; mkdir -p "$STAGING"
    ditto "$APP" "$STAGING/$APP_NAME.app"
    ln -s /Applications "$STAGING/Applications"
    rm -f "$DMG"

    # 先做可写镜像, 挂载后放入卷图标, 再压缩为只读 UDZO
    RW="$BUILD_DIR/$APP_NAME-rw.dmg"
    rm -f "$RW"
    if hdiutil create -volname "$VOLNAME" -srcfolder "$STAGING" -fs HFS+ -format UDRW -ov "$RW" >/dev/null 2>&1 \
       && ATTACH_OUT=$(hdiutil attach "$RW" -nobrowse -noautoopen 2>/dev/null); then
        MOUNT=$(echo "$ATTACH_OUT" | grep -o '/Volumes/.*' | tail -1)
        if [ -n "$MOUNT" ] && [ -d "$MOUNT" ]; then
            cp "$BUILD_DIR/AppIcon.icns" "$MOUNT/.VolumeIcon.icns" 2>/dev/null || true
            SetFile -a C "$MOUNT" 2>/dev/null || true
        fi
        hdiutil detach "$MOUNT" >/dev/null 2>&1 || true
        hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null
        rm -f "$RW"
    else
        echo "    (回退: 直接压缩生成)"
        hdiutil create -volname "$VOLNAME" -srcfolder "$STAGING" -fs HFS+ -format UDZO -imagekey zlib-level=9 -ov "$DMG" >/dev/null
    fi
    rm -rf "$STAGING"
    echo "==> DMG 完成: $DMG"
fi
