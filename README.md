# Rizz Messenger

[![Flutter](https://img.shields.io/badge/Flutter-3.41+-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-🔥-orange.svg)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

### **Rizz** — кроссплатформенный мессенджер с открытым исходным кодом, построенный на Flutter и Firebase.

## 🏗 Архитектура

Проект построен по принципам **Clean Architecture** с разделением на слои:

- `core` — платформенные абстракции, DI, логгер, уведомления, темы
- `features` — экраны и бизнес-логика, разделённые по фичам (auth, chat, contacts, profile, settings)
- `shared` — общие модели, сервисы (Firebase, кэш, конвертация файлов), виджеты

Используется **GetIt** для внедрения зависимостей и **Provider** для управления состоянием интерфейса.

## 🚀 Быстрый старт

### Предварительные требования

- Flutter SDK >=3.11.3
- Firebase проект (создайте в [Firebase Console](https://console.firebase.google.com))
- Для десктопных сборок могут потребоваться дополнительные библиотеки (см. раздел "Платформы")

### Установка

1. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/yourusername/Rizz.git
   cd Rizz
   ```
   Установите зависимости:
   ```bash
   flutter pub get
   ```
    Настройте Firebase:
    1. Установите FlutterFire CLI
    2. Выполните flutterfire configure и выберите свой проект
    3. Сгенерированный файл lib/firebase_options.dart уже есть в репозитории, но вы можете обновить его под свои ключи.

    Запустите приложение:
    ```bash
    flutter run
    ```
    📦 Сборка под платформы

    **Android**
    ```bash
    flutter build apk --release
    ```
    **iOS**
    ```bash
    flutter build ios --release
    ```
    *(Требуется macOS с Xcode)*

    **Windows**
    ```bash
    flutter build windows --release
    ```
    **Linux**
    ```bash
    # Установите зависимости GStreamer (для аудио)
    sudo apt install libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly

    flutter build linux --release
    ```
    **macOS**
    ```bash
    flutter build macos --release
    ```
    **Web**
    ```bash
    flutter build web
    ```
### 🛠 Используемые технологии:
* Flutter — UI toolkit
* Firebase — Auth, Firestore, Storage, Messaging
* GetIt — Dependency Injection
* Provider — State Management
* SharedPreferences & Hive — локальное хранилище
* Path Provider, Permission Handler, Open File — работа с файловой системой
* Image Picker, File Picker, Camera, Video Player, Audioplayers, Record — медиа
* Local Notifier & Flutter Local Notifications — уведомления на десктопе и мобильных
* Device Info Plus, Package Info Plus — информация об устройстве

📁 Структура проекта
```text
lib/
├── app.dart
├── main.dart
├── firebase_options.dart
├── version.dart
├── core/
│   ├── di/
│   ├── logger/
│   ├── notification/
│   ├── platform/
│   ├── settings/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   ├── chat/
│   ├── contacts/
│   ├── home/
│   ├── media/
│   ├── profile/
│   └── settings/
└── shared/
    ├── models/
    ├── services/
    └── widgets/
```
## 🤝 Вклад в проект
### Приветствуются любые улучшения! Чтобы внести вклад:
* Форкните репозиторий
* Создайте ветку (git checkout -b feature/awesome-feature)
* Закоммитьте изменения (git commit -m 'Add awesome feature')
* Запушьте ветку (git push origin feature/awesome-feature)
* Откройте Pull Request

📄 Лицензия
Распространяется под лицензией MIT. См. файл LICENSE.

👤 Авторы
OneX01 & Devine Machinery — Duality Project

### Создано с ❤️ на Flutter