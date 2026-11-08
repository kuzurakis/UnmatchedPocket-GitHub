# Проверки сборки 0.32

```text
v32-legends-tests.log: V32_LEGENDS checks=2689 failures=0 cards=128 matches=12
v32-edge-tests.log: V32_EDGE checks=63 failures=0
v32-board-tests.log: V32_BOARDS checks=324 failures=0
v32-ui-tests.log: V32_UI checks=115 failures=0
v32-marvel-regression.log: V31_MARVEL checks=2724 failures=0 cards=142 matches=12
v32-old-edge-regression.log: V31_EDGE checks=328 failures=0 defense_cards=58
v32-mikula-regression.log: V29_MIKULA checks=541 failures=0 matches=3
v32-base-regression.log: V27_BASE checks=4380 failures=0 maps=30
v32-timing-regression.log: V23_TIMING checks=55 failures=0
v32-boards-regression.log: V24_BOARDS checks=5366 failures=0 item_modes=60 maps=30
v32-localization-tests.log: LOCALIZATION_V07_TESTS checks=7218 failures=0 untranslated=0
v32-svyatogor-regression.log: V26_SVYATOGOR checks=171 failures=0
```

Windows EXE: UI_SMOKE_OK. В APK восемь JSON-каталогов сверены с проектом. Подпись и выравнивание проверены скриптом экспорта. Контрольные суммы опубликованных выпусков 0.30 и 0.31 совпадают. Физическое Android-устройство не проверялось.
