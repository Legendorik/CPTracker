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
  docker run --name server -p 127.0.0.1:8000:8000/tcp --env-file .env -d server
```