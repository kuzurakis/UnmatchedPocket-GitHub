# Проверка v0.13

## Состав

Полный набор Slings and Arrows: Шекспир, Гамлет, Титания, Вещие сёстры; 120 экземпляров 48 новых типов карт, шесть дополнительных чар, театр «Глобус» на 32 клетки для 2–4 игроков. Состав приложения: 36 героев, 12 наборов, 18 полей, 452 типа обычных карт, 62 портретные записи. [Источники и исправления ошибок каталога](v13_sources.md).

## Результаты

Карточные контракты: 452 типа, 487 стадий, 6760 проверок, 0 ошибок. Для каждой стадии ожидаемый результат задан отдельно. Все 12 эффектов завершения строки дополнительно проверены в полных боях. [Таблица карт](card-audit-v0.13.md), [способности](ability-audit-v0.13.md).

Новый интеграционный набор: 69752 проверки, 30 полных партий на новом поле, 904 исполнения карт, 1794 JSON-сохранения. Проверяются здоровье, отсутствие наложения бойцов, сохранение 30 карт с учётом строки/котла и шести уникальных чар. Три сложности, ручные и автоматические решения, дуэли, каждый за себя и команды. Отдельные дополнительные случаи: 43 проверки и 14 сохранений — досрочное окончание хода, полный возврат атаки But a Dream, отмена Fairy Song и различение урона Гамлету/помощнику.

Все 30 наборов прошли:

| Набор | Результат |
| --- | --- |
| v13_rules_tests | V13_RULES checks=69752 failures=0 matches=30 card_runs=904 saves=1794 |
| v12_engine_tests | V12_ENGINE checks=17043 failures=0 matches=8 card_runs=904 saves=1557 |
| v11_focus_tests | V11_FOCUS checks=110 failures=0 |
| v13_card_contract_tests | V13_CARD_CONTRACTS checks=6760 failures=0 cards=452 stages=487 |
| v11_ability_tests | V11_ABILITIES checks=279 failures=0 heroes=36 scenarios=60 |
| v11_ui_tests | V11_UI checks=11 failures=0 |
| v9_effect_results_tests | V9_EFFECT_RESULTS checks=75 failures=0 |
| v9_reserve_tests | V9_RESERVE checks=73 failures=0 |
| v9_engine_tests | V9_ENGINE checks=98020 failures=0 matches=42 card_runs=904 saves=1902 |
| v8_engine_tests | V8_ENGINE checks=70165 failures=0 matches=48 card_runs=904 saves=1705 |
| engine_tests | ENGINE_TESTS: 72283 assertions, 0 failures |
| expansion_tests | EXPANSION_TESTS checks=104903 failures=0 matches=42 |
| v6_engine_tests | V6_ENGINE_TESTS checks=160585 failures=0 matches=84 card_runs=132 |
| buffy_engine_tests | BUFFY_ENGINE_TESTS checks=187146 failures=0 matches=72 card_runs=100 saves=597 |
| v7_engine_tests | V7_ENGINE checks=74 failures=0 |
| muldoon_tests | MULDOON_TESTS checks=169 failures=0 |
| hand_view_ui_tests | HAND_VIEW_UI_TESTS checks=89 failures=0 |
| ui_tests | UI_TESTS checks=293 failures=0 |
| abilities_ui_tests | ABILITY_UI_TESTS checks=29 failures=0 |
| complex_effect_ui_tests | COMPLEX_EFFECT_UI_TESTS checks=11 failures=0 |
| v6_ui_tests | V6_UI_TESTS checks=42 failures=0 |
| v8_ui_tests | V8_UI checks=91 failures=0 |
| v9_ui_tests | V9_UI checks=36 failures=0 |
| localization_v07_tests | LOCALIZATION_V07_TESTS checks=3962 failures=0 untranslated=0 |
| localization_tests | LOCALIZATION_TESTS checks=2932 failures=0 untranslated=0 |
| scroll_gesture_tests | SCROLL_GESTURE before=100 after=145 |
| v10_engine_tests | V10_ENGINE checks=69619 failures=0 matches=36 card_runs=904 saves=1781 |
| v10_effect_results_tests | V10_EFFECT_RESULTS checks=43 failures=0 |
| v10_ui_tests | V10_UI checks=1200 failures=0 |
| responsive_tests | RESPONSIVE_TESTS 10091 checks, 0 failures, 5 sizes |

## Данные и интерфейс

Аудит данных: 11689 проверок без ошибок. Характеристики, количество карт, стадии эффектов, слоги и ингредиенты сверены с оригинальными компонентами. Все старые герои, поля, наборы, изображения и переводы побайтово/структурно сверены с замороженными исходниками 0.12. Для 1616 исходных строк есть переводы EN/NB/ES, проверены параметры форматирования.

Native/OpenGL: 10091 проверка геометрии на пяти размерах экрана, без ошибок. Ещё 25 проверок нового интерфейса: фильтр набора, новое поле, счётчик слогов, окно строки, котла и чар, скрытие/возврат окна, весь текст особых панелей на EN/NB/ES и реальный выбор оплаты «Не быть». Просмотрены настоящие снимки меню, нового поля, русской/английской партии, строки, котла, чар, вопроса Гамлета и правил поля.

Сохранения форматов 1–13 принимаются. Проверки не перебирают все возможные сочетания компонентов. Физический Android-телефон не использовался.

## Выпускные файлы

APK: версия 0.13.0, код 13, `org.unmatchedpocket.prototype`, Android 7.0+, ARMv7/ARM64. Запрошенных разрешений нет. Подпись v2/v3 и zipalign проверены; сертификат совпадает с 0.12. Все семь каталогов данных APK совпадают с финальными JSON проекта. Включены 452 карточные текстуры, 62 портретные записи, 18 полей, шесть чар и котёл, 13 скомпилированных скриптов. Тесты, документы, инструменты и закрытые ключи в APK не включены.

Windows EXE самостоятельно запускается: `UI_SMOKE_OK 4 players, 7 fighters`. Физический Android-телефон не проверялся.

| Файл | Байт | SHA-256 |
| --- | ---: | --- |
| UnmatchedPocket-v0.13-android.apk | 157027275 | `763C43B723C3902FC082338A3F45C324F4F60125B3BAECF3D7579C0F6B55599A` |
| UnmatchedPocket-v0.13-windows.exe | 210058256 | `D136007F42A6FB2007211FF37AAEAF7EB4E95AB17BDBE7791D8F8BAFFFA8EAF1` |

Прежние опубликованные файлы 0.1–0.12 сверены по SHA-256 и не изменены. Контрольные суммы текущего выпуска: `UnmatchedPocket-v0.13-SHA256.txt` рядом со сборками.
