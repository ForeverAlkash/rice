# rice

Hyprland-райс: [Prism](https://github.com/Jack02134x/prism-shell) (quickshell) с моими правками + конфиги.

## Что внутри

- `hypr/` — hyprland.lua (Prism starter, Lua-конфиг) + скрипты
- `quickshell/` — Prism shell целиком (bar, launcher, dashboard, lock) + мои правки
- `matugen/`, `kitty/`, `gtk-3.0/`, `gtk-4.0/`, `qt6ct/` — темизация от обоев (matugen → kitty/GTK/QT)
- `cava/`, `btop/`, `fastfetch/`, `easyeffects/` — мелкие конфиги
- `libinput-gestures.conf` — свайпы тачпада → back/forward (mouse4/5)

## Установка

На чистом Arch (без DE):

```bash
git clone https://github.com/ForeverAlkash/rice.git ~/rice && cd ~/rice && ./install.sh
```

Клонировать можно куда угодно — скрипт сам раскладывает конфиги в `~/.config`.

Скрипт:
1. ставит все пакеты одним pacman-ом (Hyprland, quickshell, matugen, PipeWire, NetworkManager, kitty, thunar, шрифты, иконки, easyeffects, btop, fastfetch, mpv, libinput-gestures, ydotool…);
2. копирует конфиги в `~/.config` — существующие файлы бэкапит как `<имя>.bak-<дата>`;
3. докачивает обои (~155 МБ) из upstream prism-shell, если их нет;
4. добавляет юзера в группу `input` и включает демон ydotool (для жестов; нужна перезагрузка/перезаход в сессию).

Логин: в `~/.zprofile` строка `exec Hyprland` (Hyprland стартует с tty1). Показ клавиш райса — `SUPER + /`.
