# Android APK

Текущие готовые сборки версии 0.38: `UnmatchedPocket-v0.38-android.apk` и `UnmatchedPocket-v0.38-windows.exe`. Скрипты по умолчанию используют имена без номера версии; чтобы сохранить обе версии, передайте `-OutputApk` / `-OutputExe` с нужным именем.

Проект рассчитан на Godot 4.7.1 (GDScript, Compatibility), JDK 17 и обычный экспорт APK без Gradle. Пресет `Android` включает ARMv7 и ARM64, Android 7.0+; интернет приложению не нужен.

В PowerShell из каталога проекта:

```powershell
pwsh -ExecutionPolicy Bypass -File .\tools\build-android.ps1 -OutputApk '..\UnmatchedPocket-v0.38-android.apk'
```

Готовый файл появится рядом с папкой проекта: `UnmatchedPocket-v0.38-android.apk`. Для запуска на телефоне скопируйте APK и разрешите установку из выбранного приложения (например, файлового менеджера). Это тестовая сборка с отладочной подписью.

Скрипт использует уже установленный Godot в `C:\Godot`, JDK 17 в `C:\Program Files\Java\jdk-17` и Android SDK. Он ищет SDK в `ANDROID_HOME`, `ANDROID_SDK_ROOT`, обычной папке Android Studio или `work/toolchain/android-sdk`. Отдельные настройки Godot и тестовый ключ хранятся в `work/android-export`; настройки редактора пользователя не меняются.

На другом компьютере укажите пути явно:

```powershell
.\tools\build-android.ps1 `
  -GodotExe 'C:\Godot\Godot_v4.7.1-stable_win64_console.exe' `
  -JavaHome 'C:\Program Files\Java\jdk-17' `
  -AndroidSdk 'C:\Android\Sdk' `
  -TemplateDir 'C:\Godot\templates\4.7.1.stable'
```

В `TemplateDir` нужен файл `android_debug.apk` от той же версии Godot. В SDK нужны `platform-tools` и `build-tools/35.0.1`. Скрипт проверяет подпись APK через `apksigner` и выравнивание через `zipalign`.

Официальная инструкция: [Exporting for Android — Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).

Для публикации в Google Play понадобится отдельная release-сборка AAB и постоянный ключ подписи. Эта поставка предназначена для локальной установки APK и проверки прототипа.

# Windows

`UnmatchedPocket-v0.38-windows.exe` запускается самостоятельно на 64-битной Windows; устанавливать Godot для него не нужно. Ресурсы встроены в EXE.

Повторная сборка:

```powershell
pwsh -ExecutionPolicy Bypass -File .\tools\build-windows.ps1 -OutputExe '..\UnmatchedPocket-v0.38-windows.exe'
```

Скрипт ищет шаблон `windows_release_x86_64.exe` той же версии Godot в установленном наборе export templates или `work/toolchain/templates/4.7.1.stable`. На другом компьютере можно передать `-GodotExe` и `-TemplateDir`. Для отладочной сборки используйте `-DebugBuild` (нужен шаблон `windows_debug_x86_64.exe`).

Сами SDK, JDK и шаблоны не входят в исходники проекта. Их можно установить по официальной инструкции Godot; скрипты принимают пути к ним.
