# Проверка v0.12

## Состав и исправления

32 героя, 11 наборов, 17 полей, 404 типа карт, 55 портретных записей. Добавлены два героя полного набора Sun’s Origin: Ода Нобунага, Томоэ Годзэн и замок Адзути. Новые 23 карты и английские тексты сверены с оригинальным каталогом; граф поля — с опубликованной схемой. [Источники](v12_sources.md).

«Элементарно» теперь открывает игроку карту защиты бота и предсказание до разрешения боя, пока атака ещё закрыта. Успех проверяется по напечатанному значению. Бот использует публичное распределение значений колоды, а не закрытую карту атаки. Проверены успешное/неуспешное предсказания и восстановление состояния через JSON.

Для «Ужасающего рёва» воспроизведён запрет ухода с клетки при атаке и защите, через обычное/автоматическое движение и размещение. На следующий ход запрет истекает по тексту карты. Добавлены красные отметки на фишках, состояние героя и запись в журнале; механический обход запрета в этих сценариях не воспроизведён.

Нобунага: проверен зональный бонус стражи внутри и вне зоны, взаимодействие с отменой; отдельные контракты проверяют окружение, обмен бойца, массовый урон и выбор двух эффектов. Томоэ: выход героя из зоны, отсутствие урона помощникам и при движении самой Томоэ, ограничение боевого урона, пошаговые маршруты и повторные выходы во время «Атаки жеребца» Йенненги. Все новые временные состояния сериализуются.

## Автоматические сценарии

Все 29 наборов прошли. Карточные контракты: 404 типа, 435 стадий, 5974 проверки результата. Новый интеграционный набор: 16501 проверка, 808 исполнений карт, 8 полных партий, 1386 сохранений. Для прежних 30 героев сохранены 60 сценариев способностей (279 проверок), новые два покрыты отдельными сценариями выше. Полные партии и контракты не доказывают корректность всех возможных комбинаций.

| Набор | Результат |
| --- | --- |
| v11_focus_tests | V11_FOCUS checks=110 failures=0 |
| v11_ability_tests | V11_ABILITIES checks=279 failures=0 heroes=32 scenarios=60 |
| v11_ui_tests | V11_UI checks=11 failures=0 |
| v9_effect_results_tests | V9_EFFECT_RESULTS checks=75 failures=0 |
| v9_reserve_tests | V9_RESERVE checks=73 failures=0 |
| v8_engine_tests | V8_ENGINE checks=69623 failures=0 matches=48 card_runs=808 saves=1534 |
| engine_tests | ENGINE_TESTS: 72283 assertions, 0 failures |
| expansion_tests | EXPANSION_TESTS checks=104903 failures=0 matches=42 |
| v6_engine_tests | V6_ENGINE_TESTS checks=160585 failures=0 matches=84 card_runs=132 |
| buffy_engine_tests | BUFFY_ENGINE_TESTS checks=187146 failures=0 matches=72 card_runs=100 saves=597 |
| v7_engine_tests | V7_ENGINE checks=74 failures=0 |
| muldoon_tests | MULDOON_TESTS checks=169 failures=0 |
| hand_view_ui_tests | HAND_VIEW_UI_TESTS checks=89 failures=0 |
| ui_tests | UI_TESTS checks=269 failures=0 |
| abilities_ui_tests | ABILITY_UI_TESTS checks=29 failures=0 |
| complex_effect_ui_tests | COMPLEX_EFFECT_UI_TESTS checks=11 failures=0 |
| v6_ui_tests | V6_UI_TESTS checks=42 failures=0 |
| v8_ui_tests | V8_UI checks=91 failures=0 |
| v9_ui_tests | V9_UI checks=36 failures=0 |
| localization_v07_tests | LOCALIZATION_V07_TESTS checks=3546 failures=0 untranslated=0 |
| localization_tests | LOCALIZATION_TESTS checks=2620 failures=0 untranslated=0 |
| scroll_gesture_tests | SCROLL_GESTURE before=100 after=145 |
| v10_engine_tests | V10_ENGINE checks=69077 failures=0 matches=36 card_runs=808 saves=1610 |
| v10_effect_results_tests | V10_EFFECT_RESULTS checks=43 failures=0 |
| v10_ui_tests | V10_UI checks=1136 failures=0 |
| responsive_tests | RESPONSIVE_TESTS 10091 checks, 0 failures, 5 sizes |
| v12_engine_tests | V12_ENGINE checks=16501 failures=0 matches=8 card_runs=808 saves=1386 |
| v12_card_contract_tests | V12_CARD_CONTRACTS checks=5974 failures=0 cards=404 stages=435 |
| v9_engine_tests | V9_ENGINE checks=97478 failures=0 matches=42 card_runs=808 saves=1731 |

## Данные и интерфейс

Аудит данных: 10697 проверок без ошибок; сохранены прежние герои, поля, наборы, сканы, портреты и переводы. У всех 1433 строк исходного интерфейса есть переводы EN/NB/ES, проверены параметры форматирования. В графах полей проверены координаты и стартовые позиции.

Просмотрены реальные снимки Godot/OpenGL: новый набор, карточка героя, замок Адзути, русская и английская партия, окно открытой защиты «Элементарно» и отметки запрета движения. Физический Android-телефон не использовался.

## Выпускные файлы

APK: версия 0.12.0, код 12, `org.unmatchedpocket.prototype`, Android 7.0+, ARMv7/ARM64. Нет запрошенных разрешений. Подпись v2/v3 и zipalign проверены; сертификат совпадает с 0.11. Все шесть каталогов данных APK совпадают с финальными JSON проекта. Включены 404 карточные текстуры, 55 портретных записей, 17 полей, 12 скомпилированных скриптов. Тесты, документы, инструменты и закрытые ключи не включены в APK.

Windows EXE самостоятельно запускается: `UI_SMOKE_OK 4 players, 6 fighters`. Native/OpenGL: 10091 проверка геометрии без ошибок, 5 размеров экрана. Физический Android-телефон не проверялся.

| Файл | Байт | SHA-256 |
| --- | ---: | --- |
| UnmatchedPocket-v0.12-android.apk | 148963664 | `AE9F917A03990ADDD5E57EC99F5A2F3DBC26172B96ACF9BD4534B056CE8624D6` |
| UnmatchedPocket-v0.12-windows.exe | 201834560 | `CDEA62B8199C3AEFE7ED09369F35A20434385F0B9E40122EDB179A6A3C169915` |

Прежние опубликованные файлы 0.1–0.11 сверены по SHA-256 и не изменены. Контрольные суммы текущего выпуска: `UnmatchedPocket-v0.12-SHA256.txt` рядом со сборками. Сохранения 1–12 поддерживаются.
