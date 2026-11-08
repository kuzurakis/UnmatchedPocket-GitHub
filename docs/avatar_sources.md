# Портреты на фишках

В версии 0.5 используются шестнадцать настоящих изображений из открытых страниц героев The Unmatched Club: девять портретов и семь отдельных изображений жетонов помощников. Художник персонажей — Oliver Barrett. Источники проверены 25 октября 2026 года.

| Герой | Портрет | Помощник | Жетон |
| --- | --- | --- | --- |
| [Алиса](https://www.the-unmatched.club/heroes/alice) | [402 × 402](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/avatars/CDE8K9N6i_bdh-kwzJv7w.webp) | Бармаглот | [128 × 128](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/sidekicks/2Xt6pTFi1BqovPgKbANOJ.webp) |
| [Король Артур](https://www.the-unmatched.club/heroes/king-arthur) | [800 × 800](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/avatars/dgwIAej9v-Omrn0sSVs5i.webp) | Мерлин | [128 × 128](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/sidekicks/4Rl9Oq9N82zhatbTShnXn.webp) |
| [Медуза](https://www.the-unmatched.club/heroes/medusa) | [402 × 402](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/avatars/bI206lUtJUQru-FOD8A74.webp) | Гарпия | [128 × 128](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/sidekicks/G42WIKYZ1cmwACVwMggzM.webp) |
| [Синдбад](https://www.the-unmatched.club/heroes/sinbad) | [750 × 750](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/avatars/2RiCcBVu5Tk09amVSf6BO.webp) | Носильщик | [128 × 128](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/sidekicks/2SD817c0HhsliZ40hRdB8.webp) |

Исходные WEBP-файлы сохранены без изменения в `assets/avatars/`. `data/avatars.json` сопоставляет `hero_id` с объектами `hero` и `sidekick`: `path` указывает локальный файл, `region` задаёт прямоугольник кадрирования в пикселях исходника, `source_url` и `page_url` сохраняют происхождение. Кадрирование выполняется при отрисовке через UV-координаты текстур; новые изображения нейросетью не создавались.

Фишка героя круглая, помощника — шестиугольная. Рамка обозначает владельца; союзник дополнительно отмечен зелёным знаком «+». Гарпии имеют номера #1–#3, чтобы номер не выглядел как количество здоровья. Здоровье преобразуется в целое число перед показом. У Алисы виден значок «↑ +2» для большого размера либо «↓ +1» для маленького; у Синдбада «V N» показывает число плаваний в сбросе. Эти метки обновляются непосредственно из состояния партии.

Неразмещённые фишки (`placed=false`) скрыты до выбора стартовой клетки. Геометрия поля и обработка нажатий сохраняют единое масштабирование; добавление портретов не меняет центры игровых клеток.

- [Робин Гуд](https://www.the-unmatched.club/heroes/robin-hood): [портрет](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/avatars/biGrBHVsYWTXjeEYTGqov.webp), помощник Разбойник: [жетон](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/sidekicks/KwI9DqW6Y6Je1Sj_ippng.webp). Оригинальные файлы сохранены без изменения; прямоугольник показа задан в каталоге.

- [Бигфут](https://www.the-unmatched.club/heroes/bigfoot): [портрет](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/avatars/mUid6ngk5qXZJQcZM0d6C.webp), помощник Кролень: [жетон](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/sidekicks/brjO1wbtbusXfYkfTDsZ6.webp). Оригинальные файлы сохранены без изменения; прямоугольник показа задан в каталоге.

- [Брюс Ли](https://www.the-unmatched.club/heroes/bruce-lee): [портрет 402 × 402](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/avatars/Zhn4BRhIP_U1sAdFadtMG.webp). Помощников нет.
- [Роберт Малдун](https://www.the-unmatched.club/heroes/robert-muldoon): [портрет 402 × 402](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/avatars/YGWpoTEIA9IhNwuqiJR_V.webp), [отдельный жетон работника InGen 128 × 128](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/sidekicks/dZH3X5Qyq3Fd_A5mRZpJl.webp).
- [Рапторы](https://www.the-unmatched.club/heroes/raptors): [исходный портрет трёх рапторов 402 × 402](https://yptpnirqgfmxphjvsdjz.supabase.co/storage/v1/object/public/heroes/avatars/XK60vlQzY_BhoHHrmyzzu.webp). В игре это три самостоятельных героя; помощников нет. Один исходный портрет используется для общего узнаваемого обозначения этой колоды.

## Обновление v0.6

Полные источники пяти новых колод, 66 изображений карт, семи портретов и четырёх полей, точные графы и особенности правил приведены в [источниках v0.6](v06_sources.md). Текущее издание набора с Брюсом Ли включает Мухаммеда Али и два поля; историческое описание отдельного набора выше относится к версии 0.5.
