# Проверки сборки 0.36

```text
v36-cards-tests.log: V36_CARDS checks=324 failures=0 scenarios=64
v36-edge-tests.log: V36_EDGES checks=190 failures=0
v36-sequence-tests.log: V36_SEQUENCE checks=56 failures=0
v36-matches-tests.log: V36_MATCHES checks=1927 failures=0 matches=15
v36-svyatogor-tests.log: V26_SVYATOGOR checks=171 failures=0
v36-base-tests.log: V27_BASE checks=4977 failures=0 maps=34
v36-mikula-tests.log: V29_MIKULA checks=571 failures=0 matches=3
v36-hellboy-tests.log: V35_CARDS checks=828 failures=0 scenarios=154
v36-hellboy-sequence-tests.log: V35_SEQUENCE checks=27 failures=0
v36-hellboy-edge-tests.log: V35_EDGE checks=67 failures=0
v36-stars-tests.log: V34_CARDS checks=722 failures=0 scenarios=134
v36-tmnt-tests.log: V33_CARDS checks=678 failures=0 scenarios=134
v36-boards-tests.log: V24_BOARDS checks=6015 failures=0 item_modes=60 maps=34
v36-timing-tests.log: V23_TIMING checks=55 failures=0
v36-ui-tests.log: V36_UI checks=155 failures=0
v36-localization-tests.log: LOCALIZATION_V07_TESTS checks=8738 failures=0 untranslated=0
SVYATOGOR_ART: 30 images unchanged from v0.35
V36_NATIVE_OK: menu, board, Foot deployment, Krang roll, English roll dialog, Svyatogor stats reviewed
```

Windows EXE: UI_SMOKE_OK. В APK восемь JSON-каталогов сверены с проектом. Подпись и выравнивание проверены скриптом экспорта. Контрольные суммы опубликованных выпусков 0.34 и 0.35 совпадают. Добавлены Шреддер и Крэнг: по 30 карт. Всего 78 официальных и 2 FAN-профиля, 1005 видов карт, 34 поля. Изменены эффекты и характеристики Святогора по скриншотам пользователя. Все 30 изображений Святогора совпадают с 0.35. 15 полных партий с новыми героями: три уровня бота, дуэли, FFA и команды. Этот прогон включает новые карты и указанные регрессионные наборы, а не гарантирует отсутствие всех возможных межколодных ошибок. Физическое Android-устройство не проверялось.
