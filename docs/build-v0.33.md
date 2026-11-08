# Проверки сборки 0.33

```text
v33-tmnt-tests.log: V33_CARDS checks=678 failures=0 scenarios=134
v33-ability-tests.log: V33_ABILITIES checks=2724 failures=0 matches=12
v33-edge-tests.log: V33_EDGE checks=32 failures=0
v33-legends-regression.log: V32_LEGENDS checks=2689 failures=0 cards=128 matches=12
v33-board-regression.log: V24_BOARDS checks=5366 failures=0 item_modes=60 maps=30
v33-base-regression.log: V27_BASE checks=4380 failures=0 maps=30
v33-localization-clean.log: LOCALIZATION_V07_TESTS checks=7650 failures=0 untranslated=0
```

Windows EXE: UI_SMOKE_OK. В APK восемь JSON-каталогов сверены с проектом. Подпись и выравнивание проверены скриптом экспорта. Контрольные суммы опубликованных выпусков 0.31 и 0.32 совпадают. Физическое Android-устройство не проверялось.
