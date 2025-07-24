#!/usr/bin/env python3
"""
FiscAI APP图标生成器
自动将SVG图标转换为各种尺寸的PNG文件并放置到正确位置
"""

import os
import subprocess
import sys
from pathlib import Path

def check_dependencies():
    """检查依赖工具是否安装"""
    try:
        subprocess.run(['inkscape', '--version'], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ 需要安装Inkscape来转换SVG到PNG")
        print("   macOS: brew install inkscape")
        print("   Ubuntu: sudo apt install inkscape")
        print("   Windows: 从官网下载 https://inkscape.org/")
        return False

def generate_png(svg_file, output_file, size):
    """使用Inkscape将SVG转换为指定尺寸的PNG"""
    cmd = [
        'inkscape',
        '--export-type=png',
        f'--export-filename={output_file}',
        f'--export-width={size}',
        f'--export-height={size}',
        str(svg_file)
    ]
    
    try:
        subprocess.run(cmd, check=True, capture_output=True)
        print(f"✅ 生成 {output_file} ({size}x{size})")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ 生成失败 {output_file}: {e}")
        return False

def main():
    # 检查SVG源文件
    svg_file = Path('app_icon.svg')
    if not svg_file.exists():
        print("❌ 找不到 app_icon.svg 文件")
        print("   请确保在项目根目录运行此脚本")
        sys.exit(1)
    
    # 检查依赖
    if not check_dependencies():
        sys.exit(1)
    
    print("🚀 开始生成FiscAI APP图标...")
    
    # Android图标配置
    android_icons = [
        ('android/app/src/main/res/mipmap-mdpi/ic_launcher.png', 48),
        ('android/app/src/main/res/mipmap-hdpi/ic_launcher.png', 72),
        ('android/app/src/main/res/mipmap-xhdpi/ic_launcher.png', 96),
        ('android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png', 144),
        ('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 192),
    ]
    
    # iOS图标配置
    ios_icons = [
        ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png', 20),
        ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png', 40),
        ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png', 60),
        ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png', 29),
        ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png', 58),
        ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png', 87),
        ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png', 40),
        ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png', 80),
        ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png', 120),
        ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png', 120),
        ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png', 180),
        ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png', 76),
        ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png', 152),
        ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png', 167),
        ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png', 1024),
    ]
    
    all_icons = android_icons + ios_icons
    success_count = 0
    
    # 生成所有图标
    for output_path, size in all_icons:
        output_file = Path(output_path)
        
        # 确保目录存在
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        # 生成PNG文件
        if generate_png(svg_file, output_file, size):
            success_count += 1
    
    print(f"\n🎉 完成! 成功生成 {success_count}/{len(all_icons)} 个图标")
    
    if success_count == len(all_icons):
        print("\n✅ 下一步:")
        print("   1. 运行 'flutter clean' 清理缓存")
        print("   2. 运行 'flutter run' 重新构建应用")
        print("   3. 查看新的APP图标效果")
    else:
        print(f"\n⚠️  有 {len(all_icons) - success_count} 个图标生成失败，请检查错误信息")

if __name__ == '__main__':
    main() 