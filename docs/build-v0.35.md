# Проверки сборки 0.35

```text
v35-hellboy-tests.log: V35_CARDS checks=828 failures=0 scenarios=154
v35-ability-tests.log: V35_ABILITIES checks=1731 failures=0 matches=12
v35-edge-tests.log: V35_EDGE checks=67 failures=0
v35-sequence-tests.log: V35_SEQUENCE checks=27 failures=0
v35-ui-tests.log: V35_UI checks=162 failures=0
v35-stars-regression.log: V34_CARDS checks=722 failures=0 scenarios=134
v35-stars-ability-regression.log: V34_ABILITIES checks=2164 failures=0 matches=12
v35-tmnt-regression.log: V33_CARDS checks=678 failures=0 scenarios=134
v35-legends-regression.log: V32_LEGENDS checks=2689 failures=0 cards=128 matches=12
v35-marvel-regression.log: V31_EDGE checks=328 failures=0 defense_cards=58
v35-boards-regression.log: V24_BOARDS checks=6015 failures=0 item_modes=60 maps=34
v35-base-regression.log: V27_BASE checks=4977 failures=0 maps=34
v35-mikula-regression.log: V29_MIKULA checks=541 failures=0 matches=3
v35-timing-regression.log: V23_TIMING checks=55 failures=0
v35-localization-tests.log: LOCALIZATION_V07_TESTS checks=8538 failures=0 untranslated=0
```

Windows EXE: UI_SMOKE_OK. В APK восемь JSON-каталогов сверены с проектом. Подпись и выравнивание проверены скриптом экспорта. Контрольные суммы опубликованных выпусков 0.33 и 0.34 совпадают. Физическое Android-устройство не проверялось.
