# Проверка v0.14

## Состав

Полный набор The Witcher: Steel & Silver: Геральт с Лютиком, Цири с Иггоракс, Древний Леший с волками; 37 типов карт, 96 компонентов, два поля. Состав приложения: 39 героев, 13 наборов, 20 полей, 489 типов обычных карт, 68 портретных записей. [Источники](v14_sources.md).

## Автоматические проверки

Карточные контракты: 489 типов, 528 стадий, 7350 проверок, 0 ошибок. Для каждой стадии ожидаемый результат задан отдельно. Дополнительно 978 исполнений всех карт в ручном и автоматическом режиме. [Таблица карт](card-audit-v0.14.md), [способности](ability-audit-v0.14.md).

Новый интеграционный набор: `V14_RULES checks=53982 failures=0 matches=24 card_runs=978 saves=2009`. Включает восемь комплектов снаряжения, пять пороговых карт при Источнике 0–10, защиту от отмены, постоянные эффекты, путь Иггоракс, каждую стрелку Каэр Морхена и 24 полные партии. В партиях проверяются здоровье, отсутствие наложения фигур, 30 карт с учётом постоянного приёма. Все решения и состояния проходят JSON-сохранения. Дополнительно 6 проверок корректного журнала при блокировании действий «Пургой».

Все 31 набора прошли:

| Набор | Результат |
| --- | --- |
| v14_rules_tests | V14_RULES checks=53982 failures=0 matches=24 card_runs=978 saves=2009 |
| v13_rules_tests | V13_RULES checks=70140 failures=0 matches=30 card_runs=978 saves=1911 |
| v12_engine_tests | V12_ENGINE checks=17431 failures=0 matches=8 card_runs=978 saves=1674 |
| v11_focus_tests | V11_FOCUS checks=110 failures=0 |
| v14_card_contract_tests | V14_CARD_CONTRACTS checks=7350 failures=0 cards=489 stages=528 |
| v11_ability_tests | V11_ABILITIES checks=279 failures=0 heroes=39 scenarios=60 |
| v11_ui_tests | V11_UI checks=11 failures=0 |
| v9_effect_results_tests | V9_EFFECT_RESULTS checks=75 failures=0 |
| v9_reserve_tests | V9_RESERVE checks=73 failures=0 |
| v9_engine_tests | V9_ENGINE checks=98408 failures=0 matches=42 card_runs=978 saves=2019 |
| v8_engine_tests | V8_ENGINE checks=70553 failures=0 matches=48 card_runs=978 saves=1822 |
| engine_tests | ENGINE_TESTS: 72283 assertions, 0 failures |
| expansion_tests | EXPANSION_TESTS checks=104903 failures=0 matches=42 |
| v6_engine_tests | V6_ENGINE_TESTS checks=160585 failures=0 matches=84 card_runs=132 |
| buffy_engine_tests | BUFFY_ENGINE_TESTS checks=187146 failures=0 matches=72 card_runs=100 saves=597 |
| v7_engine_tests | V7_ENGINE checks=74 failures=0 |
| muldoon_tests | MULDOON_TESTS checks=169 failures=0 |
| hand_view_ui_tests | HAND_VIEW_UI_TESTS checks=89 failures=0 |
| ui_tests | UI_TESTS checks=316 failures=0 |
| abilities_ui_tests | ABILITY_UI_TESTS checks=29 failures=0 |
| complex_effect_ui_tests | COMPLEX_EFFECT_UI_TESTS checks=11 failures=0 |
| v6_ui_tests | V6_UI_TESTS checks=42 failures=0 |
| v8_ui_tests | V8_UI checks=91 failures=0 |
| v9_ui_tests | V9_UI checks=36 failures=0 |
| localization_v07_tests | LOCALIZATION_V07_TESTS checks=4282 failures=0 untranslated=0 |
| localization_tests | LOCALIZATION_TESTS checks=3172 failures=0 untranslated=0 |
| scroll_gesture_tests | SCROLL_GESTURE before=100 after=145 |
| v10_engine_tests | V10_ENGINE checks=70007 failures=0 matches=36 card_runs=978 saves=1898 |
| v10_effect_results_tests | V10_EFFECT_RESULTS checks=43 failures=0 |
| v10_ui_tests | V10_UI checks=1324 failures=0 |
| responsive_tests | RESPONSIVE_TESTS 10091 checks, 0 failures, 5 sizes |

## Данные и интерфейс

Аудит данных: 12961 проверок без ошибок. Характеристики, количество экземпляров, стадии и английские тексты новых карт сверены с оригинальным каталогом и сканами. Для восьми комплектов снаряжения независимо проверены 30 карт и две копии каждой выбранной карты. Графы новых полей сверены с исходной схемой; для стрелок отдельно проверены направленное движение и ненаправленное соседство.

Все прежние герои, поля, наборы, сканы, портреты, чары и переводы сверены с замороженным выпуском 0.13 и сохранены. У всех 1737 исходных строк есть переводы EN/NB/ES; проверены параметры форматирования.

Native/OpenGL: 10091 проверка геометрии на пяти размерах экрана, 0 ошибок. Ещё 37 проверок нового интерфейса: фильтр трёх героев, выбор всех трёх видов снаряжения реальными карточными кнопками, применение выбора в партии, отсутствие запасных карт в колоде, ширина окон 960/1280, показ и настройка постоянного приёма, символ и счётчик Источника, скрытие/возврат окна, полный текст специальных панелей и снаряжения на EN/NB/ES. Просмотрены настоящие снимки Godot: меню, снаряжение, оба поля, русская/английская партия, описание Источника и постоянного приёма.

Сохранения 1–14 принимаются. Проверки не перебирают все сочетания героев, карт и полей. Физический Android-телефон не использовался.

## Выпускные файлы

APK: версия 0.14.0, код 14, `org.unmatchedpocket.prototype`, Android 7.0+, ARMv7/ARM64. Запрошенных разрешений нет. Подпись v2/v3 и zipalign проверены; сертификат совпадает с 0.13. Все семь каталогов данных APK совпадают с финальными JSON проекта. Включены 489 карточных текстур, 68 портретных записей, 20 полей, шесть чар и котёл, 14 скомпилированных скриптов. Тесты, документы, инструменты и закрытые ключи в APK не включены.

Windows EXE самостоятельно запускается: `UI_SMOKE_OK 4 players, 9 fighters`. Физический Android-телефон не проверялся.

| Файл | Байт | SHA-256 |
| --- | ---: | --- |
| UnmatchedPocket-v0.14-android.apk | 164168888 | `E7A9A783A3C1619E54FC9BBDF0F0A093A2D8290388FB6182D4DDAD9F16D31DBB` |
| UnmatchedPocket-v0.14-windows.exe | 217324776 | `A35FA7E95DD6917EBF34BA198F9B183A958BF486F603693546AF3D6284D82491` |

Прежние опубликованные файлы 0.1–0.13 сверены по SHA-256 и не изменены. Контрольные суммы текущего выпуска: `UnmatchedPocket-v0.14-SHA256.txt` рядом со сборками.
