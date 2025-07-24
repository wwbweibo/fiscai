#!/bin/bash

# FiscAI APP图标生成脚本
# 将SVG图标转换为各种尺寸的PNG文件

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 FiscAI APP图标生成器${NC}"

# 检查依赖
if ! command -v inkscape &> /dev/null; then
    echo -e "${RED}❌ 需要安装Inkscape来转换SVG到PNG${NC}"
    echo -e "   macOS: ${YELLOW}brew install inkscape${NC}"
    echo -e "   Ubuntu: ${YELLOW}sudo apt install inkscape${NC}"
    echo -e "   Windows: 从官网下载 https://inkscape.org/"
    exit 1
fi

# 检查SVG源文件
if [ ! -f "app_icon.svg" ]; then
    echo -e "${RED}❌ 找不到 app_icon.svg 文件${NC}"
    echo -e "   请确保在项目根目录运行此脚本"
    exit 1
fi

# 生成PNG函数
generate_png() {
    local output_path=$1
    local size=$2
    
    # 确保目录存在
    mkdir -p "$(dirname "$output_path")"
    
    # 使用Inkscape转换
    if inkscape --export-type=png \
                --export-filename="$output_path" \
                --export-width="$size" \
                --export-height="$size" \
                app_icon.svg &> /dev/null; then
        echo -e "${GREEN}✅ 生成 $output_path (${size}x${size})${NC}"
        return 0
    else
        echo -e "${RED}❌ 生成失败 $output_path${NC}"
        return 1
    fi
}

echo "📱 开始生成图标..."

success_count=0
total_count=0

# Android图标
echo -e "\n${BLUE}📱 生成Android图标...${NC}"
android_icons=(
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png:48"
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png:72"
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png:96"
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png:144"
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png:192"
)

for icon in "${android_icons[@]}"; do
    IFS=':' read -r path size <<< "$icon"
    total_count=$((total_count + 1))
    if generate_png "$path" "$size"; then
        success_count=$((success_count + 1))
    fi
done

# iOS图标  
echo -e "\n${BLUE}🍎 生成iOS图标...${NC}"
ios_icons=(
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png:20"
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png:40"
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png:60"
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png:29"
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png:58"
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png:87"
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png:40"
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png:80"
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png:120"
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png:120"
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png:180"
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png:76"
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png:152"
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png:167"
    "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png:1024"
)

for icon in "${ios_icons[@]}"; do
    IFS=':' read -r path size <<< "$icon"
    total_count=$((total_count + 1))
    if generate_png "$path" "$size"; then
        success_count=$((success_count + 1))
    fi
done

# 结果汇总
echo -e "\n${GREEN}🎉 完成! 成功生成 $success_count/$total_count 个图标${NC}"

if [ $success_count -eq $total_count ]; then
    echo -e "\n${GREEN}✅ 下一步:${NC}"
    echo -e "   1. 运行 '${YELLOW}flutter clean${NC}' 清理缓存"
    echo -e "   2. 运行 '${YELLOW}flutter run${NC}' 重新构建应用"
    echo -e "   3. 查看新的APP图标效果"
else
    failed_count=$((total_count - success_count))
    echo -e "\n${YELLOW}⚠️  有 $failed_count 个图标生成失败，请检查错误信息${NC}"
fi 