# homework_task_tracker

A new Flutter application.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Сборка сервера:
1. Скачать реп
```bash
  git clone https://github.com/Legendorik/CPTracker
```
2. Перейти в папку backend
```bash
  cd CPTracker/backend
```
3. Переместить заранее полученный от разработчиков .env файл в эту директорию
4. Собрать образ
```bash
  docker build . -t 'server:latest'
```
5. Запустить контейнер
```bash
  docker run --name server -p 0.0.0.0:8000:8000/tcp --env-file .env -d server
```

Сборка сервера опциональна, приложение работает с удаленным сервером

## Сборка приложения под Linux:
1. Установка snapd
```bash
  sudo apt update
  sudo apt upgrade -y
  sudo apt install snapd
```
2. Установка flutter
```bash
  sudo snap install flutter --classic
```
3. Установка необходимых зависимостей
```bash
  sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev -y
  flutter config --enable-linux-desktop
```
4. Проверить дополнительные требования для использования flutter
```bash
  flutter doctor
```
5. Клонировать репозиторий
```bash
  git clone https://github.com/Legendorik/CPTracker
```
6. Перейти в папку frontend
```bash
  cd CPTracker/frontend
```
7. Установить необходимые пакеты
```bash
  flutter pub get
```
8. Запустить приложение
```bash
  flutter run -d linux
```

Для сборки релизной версии используйте команду
```bash
  flutter build linux
```

## Сборка приложения под Windows:
1. Загрузите и установите Flutter SDK с официального сайта https://flutter.dev/docs/get-started/install/windows

2. Измените переменную PATH соответственно руководству https://flutter.dev/docs/get-started/install/windows#update-your-path

3. Проверить дополнительные требования для использования flutter
```bash
  flutter doctor
```
4. Клонировать репозиторий
```bash
  git clone https://github.com/Legendorik/CPTracker
```
5. Открыть папку frontend
```bash
  cd CPTracker/frontend
```
6. Настроить платформу для сборки
```bash
  flutter config --enable-windows-desktop
```
7. Установить необходимые пакеты
```bash
  flutter pub get
```
8. Запустить приложение
```bash
  flutter run -d windows
```

Для сборки релизной версии используйте команду
```bash
  flutter build windows
```