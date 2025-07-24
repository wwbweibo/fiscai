# FiscAI APP图标生成指南

## 📱 图标设计概念

新设计的FiscAI图标融合了以下元素：
- **主色调**: 蓝色渐变 (#2563EB → #3B82F6)
- **核心图标**: 人民币符号 ¥ (体现财务管理)
- **科技元素**: 几何线条和光点 (体现AI智能)
- **现代风格**: 圆角矩形背景，简洁现代

## 🛠️ 生成PNG图标的方法

### 方法一：在线工具 (推荐)
1. 访问 [SVG to PNG Converter](https://cloudconvert.com/svg-to-png)
2. 上传项目根目录的 `app_icon.svg` 文件
3. 设置输出尺寸并生成以下规格的PNG文件

### 方法二：使用设计软件
- Adobe Illustrator / Figma / Sketch
- 导入SVG文件并导出为不同尺寸的PNG

## 📋 需要生成的图标尺寸

### Android图标 (保存到 android/app/src/main/res/)
```
mipmap-mdpi/ic_launcher.png     (48x48)
mipmap-hdpi/ic_launcher.png     (72x72)  
mipmap-xhdpi/ic_launcher.png    (96x96)
mipmap-xxhdpi/ic_launcher.png   (144x144)
mipmap-xxxhdpi/ic_launcher.png  (192x192)
```

### iOS图标 (保存到 ios/Runner/Assets.xcassets/AppIcon.appiconset/)
```
Icon-App-20x20@1x.png    (20x20)
Icon-App-20x20@2x.png    (40x40)
Icon-App-20x20@3x.png    (60x60)
Icon-App-29x29@1x.png    (29x29)
Icon-App-29x29@2x.png    (58x58)
Icon-App-29x29@3x.png    (87x87)
Icon-App-40x40@1x.png    (40x40)
Icon-App-40x40@2x.png    (80x80)
Icon-App-40x40@3x.png    (120x120)
Icon-App-60x60@2x.png    (120x120)
Icon-App-60x60@3x.png    (180x180)
Icon-App-76x76@1x.png    (76x76)
Icon-App-76x76@2x.png    (152x152)
Icon-App-83.5x83.5@2x.png (167x167)
Icon-App-1024x1024@1x.png (1024x1024)
```

## 🚀 快速生成脚本

运行以下命令快速生成所有需要的图标尺寸：

```bash
# 如果您有ImageMagick已安装
./generate_icons.sh

# 或者使用Python脚本
python3 generate_icons.py
```

## ✅ 完成后的操作

1. 替换所有图标文件后，清理构建缓存：
```bash
# Flutter
flutter clean
flutter pub get

# iOS (如果需要)
cd ios && rm -rf build && cd ..

# Android (如果需要)  
cd android && ./gradlew clean && cd ..
```

2. 重新构建应用：
```bash
flutter run
```

## 🎨 图标特色

- ✨ 现代化设计风格
- 💙 契合APP主题色彩
- 💰 突出财务管理功能  
- 🤖 体现AI智能特性
- 📱 适配各种设备尺寸 