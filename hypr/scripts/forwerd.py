#!/usr/bin/env python3
import sys
from evdev import UInput, ecodes

# Создаём виртуальное устройство мыши
ui = UInput({
    ecodes.EV_KEY: [ecodes.BTN_SIDE, ecodes.BTN_EXTRA],
})

# Аргумент: "back" или "forward"
button = sys.argv[1] if len(sys.argv) > 1 else "back"

if button == "back":
    ui.write(ecodes.EV_KEY, ecodes.BTN_SIDE, 1)    # Нажать
    ui.write(ecodes.EV_KEY, ecodes.BTN_SIDE, 0)    # Отпустить
elif button == "forward":
    ui.write(ecodes.EV_KEY, ecodes.BTN_EXTRA, 1)   # Нажать
    ui.write(ecodes.EV_KEY, ecodes.BTN_EXTRA, 0)   # Отпустить

ui.syn()
