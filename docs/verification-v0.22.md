# Проверки версии 0.22

30 октября 2026 года. Godot 4.7.1, Windows.

Пройдено 25 наборов проверок, ошибок 0. Суммарно 352337 проверок; многие повторяют общие инварианты состояния. Явно посчитано 110 матчей в старых наборах; дополнительно проверены новые командные партии.

Каждое из 686 определений карт запускалось вручную и автоматически: 1372 сценария. Проверка выполнения цепочки не доказывает правильность всех сочетаний правил. Дополнительно используются целевые утверждения о значениях, здоровье, позициях, смене форм, ресурсах, раскрытии карт, сбросе и сохранении.

| Набор | Результат |
|---|---|
| v22_card_tests | V22_CARDS checks=7359 failures=0 cards=1372 |
| v21_rules_tests | V21_RULES checks=411 failures=0 |
| v20_large_tests | V20_LARGE checks=20 failures=0 |
| v19_match_tests | V19_MATCHES checks=93 failures=0 |
| v18_rules_tests | V18_RULES checks=33019 failures=0 matches=9 saves=2423 |
| v17_rules_tests | V17_RULES checks=47452 failures=0 matches=12 card_runs=1372 saves=2412 |
| v16_rules_tests | V16_RULES checks=34067 failures=0 matches=9 card_runs=1372 saves=2420 |
| v15_rules_tests | V15_RULES checks=52491 failures=0 matches=18 card_runs=1372 saves=2492 |
| v14_rules_tests | V14_RULES checks=56093 failures=0 matches=24 card_runs=1372 saves=2653 |
| v13_rules_tests | V13_RULES checks=72253 failures=0 matches=30 card_runs=1372 saves=2556 |
| v12_engine_tests | V12_ENGINE checks=19544 failures=0 matches=8 card_runs=1372 saves=2319 |
| v11_focus_tests | V11_FOCUS checks=110 failures=0 |
| v11_ability_tests | V11_ABILITIES checks=313 failures=0 heroes=56 scenarios=64 |
| v14_card_contract_tests | V14_CARD_CONTRACTS checks=7350 failures=0 cards=489 stages=528 |
| muldoon_tests | MULDOON_TESTS checks=169 failures=0 |
| v22_rules_tests | V22_RULES checks=493 failures=0 |
| ui_tests | UI_TESTS checks=430 failures=0 |
| localization_tests | LOCALIZATION_TESTS checks=4456 failures=0 untranslated=0 |
| localization_v07_tests | LOCALIZATION_V07_TESTS checks=5994 failures=0 untranslated=0 |
| responsive_tests | RESPONSIVE_TESTS 10091 checks, 0 failures, 5 sizes |
| hand_view_ui_tests | HAND_VIEW_UI_TESTS checks=89 failures=0 |
| scroll_gesture_tests | SCROLL_GESTURE before=100 after=145 |
| abilities_ui_tests | ABILITY_UI_TESTS checks=29 failures=0 |
| complex_effect_ui_tests | COMPLEX_EFFECT_UI_TESTS checks=11 failures=0 |
| v22_render_native | V22_UI_LANGUAGES_OK (new hero sheets in EN/NB/ES) |

Исправления по проверке: общий обработчик движения теперь учитывает fixed_fighter и старый псевдоним opponent в ручном режиме и у бота; исправлены здоровье и дальность Вонга; тёмный договор помещает карту вниз колоды до взятия карты; проверен случай пустой колоды; контратаки Человека-паука учитывают изменённую силу карты; дуэльный загон Тираннозавра исключён из списка четырёх игроков; исправлен импорт двух портретов.

Переводы: все 2240 исходных строк покрыты в EN/NB/ES, оставшегося русского текста в проверенных локализованных экранах нет; числовые подстановки при переводе сохранялись и сверялись. Накопившиеся пропуски переведены автоматически через Google Translate, существовавшие записи словаря сохранены. Терминологическая редактура всего автоматического перевода человеком не проводилась.

Данные: 8966 проверок, 0 ошибок; новые колоды сверены с исходными значениями, типами, усилением и количеством карт; хеши новых изображений проверены. Графический прогон открывал новую партию и карточки всех четырёх новых профилей на EN/NB/ES. Windows EXE запущен отдельно, APK имеет проверенную подпись, семь каталогов в APK совпадают с исходниками.

Ограничения: это не исчерпывающая проверка всех сочетаний. Физический Android не использовался. Жетоны предметов на полях Marvel по-прежнему отключены. Геометрия крупной базы Тираннозавра пока приближённая, как в 0.20.
