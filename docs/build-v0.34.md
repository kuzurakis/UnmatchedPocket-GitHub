# Проверки сборки 0.34

```text
v34-stars-tests.log: V34_CARDS checks=722 failures=0 scenarios=134
v34-ability-tests.log: V34_ABILITIES checks=2164 failures=0 matches=12
v34-edge-tests.log: V34_EDGE checks=40 failures=0
v34-ui-tests.log: V34_UI checks=162 failures=0
v34-tmnt-regression.log: V33_CARDS checks=678 failures=0 scenarios=134
v34-legends-regression.log: V32_LEGENDS checks=2689 failures=0 cards=128 matches=12
v34-board-regression.log: V24_BOARDS checks=5708 failures=0 item_modes=60 maps=32
v34-base-regression.log: V27_BASE checks=4722 failures=0 maps=32
v34-localization-tests.log: LOCALIZATION_V07_TESTS checks=8066 failures=0 untranslated=0
```

Windows EXE: UI_SMOKE_OK. В APK восемь JSON-каталогов сверены с проектом. Подпись и выравнивание проверены скриптом экспорта. Контрольные суммы опубликованных выпусков 0.32 и 0.33 совпадают. Физическое Android-устройство не проверялось.
