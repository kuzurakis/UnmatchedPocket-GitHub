# Проверка версии 0.11.0

Godot 4.7.1 / Windows. Все 28 серий завершены без ошибок. Физический Android-телефон не использовался.

## Покрытие

- 381 уникальное определение карт, 407 стадий с независимыми ожидаемыми результатами: 5599 проверок, 0 ошибок.
- 30 способностей, два разных сценария каждой: 60 сценариев, 279 проверок, 0 ошибок.
- Полные карточные цепочки: 762 запуска (каждый тип в атаке и защите/схеме); полные партии при трёх навыках ботов в дуэлях, FFA и командах; сохранения во время эффектов.
- Регрессии Шапочки, Йенненги, защиты от урона, конца партии и связанных необычных карт.
- Интерфейс: реальная последовательность выбора распределения урона, устойчивые номера лучников, скрытие/возврат и остановка ботов, символы трёх отдельных копий карты в руке, описание корзинки в сбросе.
- Данные и переводы: 11351 проверка, 0 ошибок. По 1483 ключа перевода, 1375 исходных строк; пропусков нет.

[Покрытие по каждому герою и карте](card-audit-v0.11.md). Конечный набор сценариев не доказывает правильность всех возможных взаимодействий.

## Серии

| Серия | Результат |
| --- | --- |
| v11_ui_tests | V11_UI checks=11 failures=0 |
| v9_effect_results_tests | V9_EFFECT_RESULTS checks=75 failures=0 |
| v9_reserve_tests | V9_RESERVE checks=73 failures=0 |
| v9_engine_tests | V9_ENGINE checks=97229 failures=0 matches=42 card_runs=762 saves=1656 |
| v8_engine_tests | V8_ENGINE checks=69356 failures=0 matches=48 card_runs=762 saves=1459 |
| engine_tests | ENGINE_TESTS: 72283 assertions, 0 failures |
| expansion_tests | EXPANSION_TESTS checks=104903 failures=0 matches=42 |
| v6_engine_tests | V6_ENGINE_TESTS checks=160585 failures=0 matches=84 card_runs=132 |
| buffy_engine_tests | BUFFY_ENGINE_TESTS checks=187146 failures=0 matches=72 card_runs=100 saves=597 |
| v7_engine_tests | V7_ENGINE checks=74 failures=0 |
| muldoon_tests | MULDOON_TESTS checks=169 failures=0 |
| hand_view_ui_tests | HAND_VIEW_UI_TESTS checks=89 failures=0 |
| ui_tests | UI_TESTS checks=258 failures=0 |
| abilities_ui_tests | ABILITY_UI_TESTS checks=29 failures=0 |
| complex_effect_ui_tests | COMPLEX_EFFECT_UI_TESTS checks=11 failures=0 |
| v6_ui_tests | V6_UI_TESTS checks=42 failures=0 |
| v8_ui_tests | V8_UI checks=91 failures=0 |
| v9_ui_tests | V9_UI checks=36 failures=0 |
| localization_v07_tests | LOCALIZATION_V07_TESTS checks=3346 failures=0 untranslated=0 |
| localization_tests | LOCALIZATION_TESTS checks=2470 failures=0 untranslated=0 |
| scroll_gesture_tests | SCROLL_GESTURE before=100 after=145 |
| v10_engine_tests | V10_ENGINE checks=68828 failures=0 matches=36 card_runs=762 saves=1535 |
| v10_effect_results_tests | V10_EFFECT_RESULTS checks=43 failures=0 |
| v10_ui_tests | V10_UI checks=1074 failures=0 |
| responsive_tests | RESPONSIVE_TESTS 10091 checks, 0 failures, 5 sizes |
| v11_focus_tests | V11_FOCUS checks=110 failures=0 |
| v11_card_contract_tests | V11_CARD_CONTRACTS checks=5599 failures=0 cards=381 stages=407 |
| v11_ability_tests | V11_ABILITIES checks=279 failures=0 heroes=30 scenarios=60 |


## Выпускные файлы

APK: версия 0.11.0, код 11, `org.unmatchedpocket.prototype`, Android 7.0+, ARMv7/ARM64. Манифест не запрашивает разрешений. Подпись v2/v3 и zipalign проверены. Сертификат совпадает с 0.10. Шесть каталогов данных APK совпадают с финальными JSON проекта. Включены 381 карточная текстура, 52 портретные записи, 16 полей и 11 скомпилированных скриптов. Тесты, документы, инструменты и закрытые ключи не включены.

Windows EXE самостоятельно запускается: `UI_SMOKE_OK 4 players, 7 fighters`, код 0. Native/OpenGL: 10091 проверка геометрии, 0 ошибок, 5 размеров; ещё 11 проверок интерфейса корзинки и реальной последовательности распределения урона. Просмотрены снимки Шапочки, символов трёх копий Into the Woods, сброса, оставшегося лучника №2 и временно раскрытого поля. Физический Android-телефон не проверялся.

| Файл | Байт | SHA-256 |
| --- | ---: | --- |
| UnmatchedPocket-v0.11-android.apk | 133384231 | `F6C01B57CDB481A1AE2758159B1FA8FCA403FF740318C5849E5E0F8755764F9D` |
| UnmatchedPocket-v0.11-windows.exe | 186195272 | `72AD73A21149FF5E50538D2DD51358F8AFBCF1CAE12FB0C75414A4817F91A0C2` |

Все опубликованные ранее файлы 0.1–0.10 сверены по SHA-256 и не изменены. Контрольные суммы текущего выпуска: `UnmatchedPocket-v0.11-SHA256.txt` рядом со сборками.
