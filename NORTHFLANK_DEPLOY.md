# Деплой Stirling-PDF на Northflank через GitHub

## Что включено в этот билд

Используется **fat-версия** — все функции активны:
| Функция | Инструмент | Статус |
|---|---|---|
| Редактор текста PDF | Встроенный Java | ✅ |
| Слияние / разделение / сжатие | Встроенный Java | ✅ |
| Конвертация в Word/Excel/PPT | LibreOffice | ✅ |
| OCR (распознавание текста) | Tesseract + OCRmyPDF | ✅ |
| Сжатие / Ремонт PDF | Ghostscript + qpdf | ✅ |
| Конвертация epub/mobi | Calibre | ✅ |
| HTML/URL в PDF | WeasyPrint | ✅ |
| Подпись / Сертификаты | Встроенный Java | ✅ |
| Авторизация | — | ❌ отключена |

---

## Шаг 1 — Подготовка GitHub репозитория

1. Убедитесь что ваш код запушен в GitHub
2. В репозитории должен быть файл `Dockerfile` в корне (уже создан)

---

## Шаг 2 — Создание проекта в Northflank

1. Зайдите на [northflank.com](https://northflank.com) → **New Project**
2. Назовите проект `stirling-pdf`

---

## Шаг 3 — Build Service (сборка из GitHub)

1. Внутри проекта → **New Service** → **Build Service**
2. Подключите GitHub аккаунт
3. Выберите ваш репозиторий
4. Настройки сборки:
   - **Build type:** Dockerfile
   - **Dockerfile path:** `/Dockerfile`
   - **Docker work directory:** `/`
   - **Branch:** `main`
5. Включите **"Automatically build on push"** — это даст автодеплой при push в GitHub
6. Нажмите **Create Build Service**

> Первая сборка займёт **15–25 минут** (компилируется Java + Node.js)
> Последующие сборки быстрее благодаря кешированию слоёв

---

## Шаг 4 — Deployment Service (запуск)

1. **New Service** → **Deployment Service**
2. В разделе **Image source** выберите ваш Build Service
3. Настройки:
   - **Plan:** `nf-compute-200-4` (2 vCPU / 4 GB — рекомендуется)
   - **Instances:** 1 (можно увеличить позже)
   - **Port:** `8080` → HTTP → **Public**

### Переменные окружения (Environment Variables)

Добавьте в раздел **Runtime Environment**:

```
SECURITY_ENABLELOGIN=false
DISABLE_ADDITIONAL_FEATURES=false
FAT_DOCKER=true
SYSTEM_DEFAULTLOCALE=en-US
SYSTEM_MAXFILESIZE=200
STIRLING_JVM_PROFILE=balanced
UI_APPNAME=Stirling-PDF
```

4. **Health Check:**
   - Protocol: HTTP
   - Path: `/api/v1/info/status`
   - Port: `8080`
   - Initial delay: `120s`

5. Нажмите **Create Deployment Service**

---

## Шаг 5 — Автоматический деплой (CI/CD)

В **Build Service** → **Settings** → **CI**:
- ✅ Build on push to `main`
- В **Deployment Service** → **Settings** → **Deploy triggers**:
  - ✅ Auto-deploy when build completes

Теперь при каждом `git push` в `main`:
1. Northflank автоматически собирает новый образ
2. Деплоит его без простоя (rolling update)

---

## Шаг 6 — Проверка

Перейдите по публичному URL вашего Deployment Service.
Приложение должно открыться без запроса авторизации.

---

## Важные заметки

### Хранилище (Volumes)
Для сохранения данных между перезапусками добавьте **Volumes**:
- `/configs` — настройки приложения
- `/logs` — логи
- `/usr/share/tessdata` — данные OCR (языки)

### Если нужна авторизация
Измените переменные окружения:
```
SECURITY_ENABLELOGIN=true
SECURITY_INITIALLOGIN_USERNAME=admin
SECURITY_INITIALLOGIN_PASSWORD=YourStrongPassword123
```

### Масштабирование
В Deployment Service → **Instances** можно увеличить количество реплик
в любой момент без остановки сервиса.
