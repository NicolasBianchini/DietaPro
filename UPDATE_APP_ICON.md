# Como atualizar o ícone do aplicativo DietaPro

## Imagens disponíveis
- `lib/images/FotoApp.png` - Ícone do aplicativo (usar para iOS e Android)
- `lib/images/Splash.png` - Logo da splash screen e login
- `lib/images/LogoApp.png` - Logo adicional

## Para iOS (iPhone/iPad)

### Opção 1: Usar ferramenta online (Recomendado)
1. Acesse: https://www.appicon.co/
2. Faça upload de `lib/images/FotoApp.png`
3. Selecione apenas "iPhone" e "iPad"
4. Clique em "Generate"
5. Baixe o arquivo ZIP
6. Extraia e substitua o conteúdo em: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Opção 2: Usar flutter_launcher_icons
1. Adicione ao `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  ios: true
  android: false
  image_path: "lib/images/FotoApp.png"
  remove_alpha_ios: true
```

2. Execute:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### Opção 3: Manual
Os tamanhos necessários para iOS são:
- 1024x1024 (App Store)
- 180x180 (iPhone 3x)
- 120x120 (iPhone 2x)
- 167x167 (iPad Pro)
- 152x152 (iPad 2x)
- 76x76 (iPad 1x)
- 60x60, 40x40, 29x29, 20x20 (diversos tamanhos)

Substitua os arquivos em: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Para Android

### Opção 1: Usar flutter_launcher_icons
1. Adicione ao `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "lib/images/FotoApp.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "lib/images/FotoApp.png"
```

2. Execute:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### Opção 2: Manual
Os tamanhos necessários para Android são:
- mipmap-mdpi: 48x48
- mipmap-hdpi: 72x72
- mipmap-xhdpi: 96x96
- mipmap-xxhdpi: 144x144
- mipmap-xxxhdpi: 192x192

Substitua os arquivos em: `android/app/src/main/res/mipmap-*/ic_launcher.png`

## Solução rápida com flutter_launcher_icons (Recomendado)

Execute este comando para instalar e configurar automaticamente:

```bash
flutter pub add dev:flutter_launcher_icons

# Depois adicione ao pubspec.yaml:
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "lib/images/FotoApp.png"
  remove_alpha_ios: true
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "lib/images/FotoApp.png"

# Execute a geração:
flutter pub run flutter_launcher_icons
```

## Teste
Após atualizar os ícones:
1. Desinstale o app do dispositivo/simulador
2. Execute: `flutter clean && flutter run`
3. O novo ícone aparecerá na tela inicial do dispositivo

