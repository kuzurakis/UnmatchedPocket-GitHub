# Проверка v0.15

## Состав

40 героев, 14 наборов (Realms Fall пока представлен только Эредином), 22 поля, 500 типов карт со сканами, 70 портретов. В колодах партии 1200 карт; в каталоге 1211 компонентов, включая альтернативные карты Баффи и невыбранное снаряжение Геральта. Шесть чар Титании учитываются отдельно.

## Автоматические проверки

Пройдены все 32 набора общей регрессии. Каждая из 500 карт запускалась в ручном и автоматическом режиме, всего 1000 запусков. Для прежних 489 карт сохранены проверки результатов по стадиям; новые 11 проверяются отдельными сценариями v15_rules_tests и v15_edge_tests. Сценарии не исчерпывают все возможные сочетания карт.

Новые сценарии: 18 полных партий на трёх сложностях, ручное разрешение и боты; дуэль, трое каждый за себя, 2 на 2; сохранения посреди жертвы, возвращения и замены защитника. Способность проверяется без ярости, с последним живым Всадником, после его поражения и возвращения, при атаке и защите. Отдельно проверены блокировки, отмена, союзники, «Неясыть», истощение, проход через врагов и принадлежность карты после портала.

Дополнительно: V15_EDGES checks=220 failures=0; V15_UI checks=15 failures=0. Новый интерфейс отрисован обычным графическим Godot; просмотрены игровые экраны и правила. Общая адаптивность проверена на пяти размерах. Переводы русского/английского/букмола/испанского проверены в данных и на новых панелях.

| Набор | Результат |
|---|---|
| v15_rules_tests | V15_RULES checks=50503 failures=0 matches=18 card_runs=1000 saves=1884 |
| v14_rules_tests | V14_RULES checks=54105 failures=0 matches=24 card_runs=1000 saves=2045 |
| v13_rules_tests | V13_RULES checks=70263 failures=0 matches=30 card_runs=1000 saves=1947 |
| v12_engine_tests | V12_ENGINE checks=17554 failures=0 matches=8 card_runs=1000 saves=1710 |
| v11_focus_tests | V11_FOCUS checks=110 failures=0 |
| v14_card_contract_tests | V14_CARD_CONTRACTS checks=7350 failures=0 cards=489 stages=528 |
| v11_ui_tests | V11_UI checks=11 failures=0 |
| v9_effect_results_tests | V9_EFFECT_RESULTS checks=75 failures=0 |
| v9_reserve_tests | V9_RESERVE checks=73 failures=0 |
| v9_engine_tests | V9_ENGINE checks=98531 failures=0 matches=42 card_runs=1000 saves=2055 |
| v8_engine_tests | V8_ENGINE checks=70676 failures=0 matches=48 card_runs=1000 saves=1858 |
| expansion_tests | EXPANSION_TESTS checks=104903 failures=0 matches=42 |
| v6_engine_tests | V6_ENGINE_TESTS checks=160585 failures=0 matches=84 card_runs=132 |
| buffy_engine_tests | BUFFY_ENGINE_TESTS checks=187146 failures=0 matches=72 card_runs=100 saves=597 |
| v7_engine_tests | V7_ENGINE checks=74 failures=0 |
| muldoon_tests | MULDOON_TESTS checks=169 failures=0 |
| hand_view_ui_tests | HAND_VIEW_UI_TESTS checks=89 failures=0 |
| abilities_ui_tests | ABILITY_UI_TESTS checks=29 failures=0 |
| complex_effect_ui_tests | COMPLEX_EFFECT_UI_TESTS checks=11 failures=0 |
| v6_ui_tests | V6_UI_TESTS checks=42 failures=0 |
| v8_ui_tests | V8_UI checks=91 failures=0 |
| v9_ui_tests | V9_UI checks=36 failures=0 |
| localization_v07_tests | LOCALIZATION_V07_TESTS checks=4378 failures=0 untranslated=0 |
| localization_tests | LOCALIZATION_TESTS checks=3244 failures=0 untranslated=0 |
| scroll_gesture_tests | SCROLL_GESTURE before=100 after=145 |
| v10_engine_tests | V10_ENGINE checks=70130 failures=0 matches=36 card_runs=1000 saves=1934 |
| v10_effect_results_tests | V10_EFFECT_RESULTS checks=43 failures=0 |
| v10_ui_tests | V10_UI checks=1448 failures=0 |
| responsive_tests | RESPONSIVE_TESTS 10091 checks, 0 failures, 5 sizes |
| v11_ability_tests | V11_ABILITIES checks=305 failures=0 heroes=40 scenarios=62 |
| engine_tests | ENGINE_TESTS: 72283 assertions, 0 failures |
| ui_tests | UI_TESTS checks=328 failures=0 |

## Данные и сборки

Сверка с зафиксированным архивом v0.14 подтверждает сохранность прежних героев, полей, наборов, изображений и переводов. Проверены исходные графы новых полей, напечатанные значения карт, хеши изображений и наличие переводов. [Данные аудита](data-audit-v0.15.json).

APK: версия 15 / 0.15.0, прежний пакет и подпись, ARMv7/ARM64, Android 7+, без запрашиваемых разрешений. Проверяются подпись, манифест, совпадение семи каталогов и наличие импортированных текстур. Windows EXE проходит встроенный тест интерфейса. Сохранения версии 1–15 принимаются.

Физический телефон в этой сессии не использовался. Готовые выпуски v0.1–v0.14 не изменяются.

[Источники и принятые правила](v15_sources.md).
