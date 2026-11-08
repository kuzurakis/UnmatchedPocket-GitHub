# Проверки сборки 0.31

```text
v31-marvel-tests.log: V31_MARVEL checks=2724 failures=0 cards=142 matches=12
v31-edge-tests.log: V31_EDGE checks=328 failures=0 defense_cards=58
v31-ui-tests.log: V31_UI checks=33 failures=0
v31-mikula-regression.log: V29_MIKULA checks=541 failures=0 matches=3
v31-base-regression.log: V27_BASE checks=4028 failures=0 maps=28
v31-timing-regression.log: V23_TIMING checks=55 failures=0
v31-boards-regression.log: V24_BOARDS checks=5035 failures=0 item_modes=60 maps=28
v31-localization-regression.log: LOCALIZATION_V07_TESTS checks=6818 failures=0 untranslated=0
v31-health-regression.log: V30_HEALTH checks=7 failures=0
v31-stats-locale.log: V31_STATS_LOCALE checks=12 failures=0
v31-svyatogor-regression.log: V26_SVYATOGOR checks=171 failures=0
```

Windows EXE: UI_SMOKE_OK. В APK восемь JSON-каталогов сверены с проектом. Подпись и выравнивание проверены скриптом экспорта. Контрольные суммы опубликованных выпусков 0.29 и 0.30 совпадают. Физическое Android-устройство не проверялось.
