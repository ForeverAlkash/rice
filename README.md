# rice

Мой личный сетап Hyprland. Это **форк [Prism](https://github.com/Jack02134x/prism-shell)** — беру оттуда основу (quickshell-шелл + крашение темы от обоев), дальше всё докручено под себя.

## Скрины

| | |
|---|---|
| ![dashboard](screenshots/dashboard.png) | ![wallpapers](screenshots/wallpapers.png) |
| *Дашборд: плеер, погода, скринтайм, тумблеры* | *Пикер обоев — от них красится вся система* |
| ![spotify](screenshots/spotify.png) | ![lock](screenshots/lock.png) |
| *Бар поверх приложений* | *Локскрин + аватар* |

## Что тут самодельное

Основа — Prism, но внутрь я добавил:

- **AI в лаунчере** — `q <вопрос>` уходит в локальную Ollama, работает без облака
- **Счётчик обновлений** — pacman-обновления видны прямо в шторке и на дашборде
- **Переключатель аудиовыхода** — наушники/спикеры/монитор в пару кликов, с фильтрацией джеков
- **Заметки** — плавающее окошко kitty с markdown-файлом, по хоткею
- **Тёплый экран** — hyprsunset с запоминанием состояния
- **Меню скриншотов** вместо мгновенного снимка

А ещё **вырезал** то, чем не пользуюсь: clock-app (часы свои), study noise, GLava, интеграцию с телефоном через KDE Connect.

Тему перевёл в монохром — вместо радуги акцентов один primary-цвет, лаунчер и локскрин переработаны. Мелочи в конфигах: bt-agent в автозапуск (чтобы наушники не отваливались), пофикшенный cliphist, Throne и Telegram на своих воркспейсах. Свои конфиги поверх — `hypr/hyprland.lua`, свайпы тачпада как back/forward, qt6ct/GTK-темы.

Подробный построчный diff от ванили я не веду — просто сравни с [upstream](https://github.com/Jack02134x/prism-shell), расхождений не так много.

## Структура

```
hypr/        — hyprland.lua (Lua-конфиг) + скрипты
quickshell/  — сам шелл (форк Prism) + мои правки
matugen/     — шаблоны: обои → kitty / GTK / QT / бар
kitty/ gtk-3.0/ gtk-4.0/ qt6ct/  — темы приложений
cava/ btop/ fastfetch/ easyeffects/ — мелочи
screenshots/ — скрины для этого README
install.sh   — установка одной командой
```

## Установка

Чистый Arch, без DE:

```bash
git clone https://github.com/ForeverAlkash/rice.git ~/rice
cd ~/rice && ./install.sh
```

Скрипт:
1. ставит пакеты (Hyprland, quickshell, matugen, PipeWire, NM, kitty, шрифты и т.д.) одним pacman-ом
2. раскладывает конфиги в `~/.config` (старые бэкапит)
3. докачивает обои из upstream (они тяжёлые, в репо не тяну)
4. настраивает ydotool и группу `input` для жестов

Логин: `exec Hyprland` в `~/.zprofile`. Шпаргалка по клавишам — `SUPER + /`.

## Благодарности

Вся база — [Jack02134x](https://github.com/Jack02134x) и его [Prism](https://github.com/Jack02134x/prism-shell). Спасибо за проделанную работу, я лишь докрутил под себя.
