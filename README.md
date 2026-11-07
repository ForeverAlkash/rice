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
git clone https://github.com/<user>/<repo>.git rice && cd rice && ./install.sh
```

Ставит все пакеты одним pacman-ом, раскладывает конфиги (старые бэкапит),
докачивает обои из upstream, настраивает ydotool/группу input.

Логин: `exec Hyprland` в `~/.zprofile`.
