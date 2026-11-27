[English](../CUSTOMIZE.md) · **Español** · [Português](../pt/CUSTOMIZE.md) · [← Inicio Docs](README.md)

# Personalización

Todo está en **Ajustes** (`SUPER+U`). Las mismas acciones están disponibles como comandos:

```bash
rice-bar set style flat|floating|islands|island
rice-bar set opacity 0.9
rice-bar set autohide on|off
```

## Rofi
Usa **Ajustes > Rofi**, o la línea de comandos:

```bash
rice-rofi set theme shadow|graphite|midnight|rose|paper
rice-rofi set layout list|grid|bar
rice-rofi set position top|center|bottom
rice-rofi set transparency on|off
rice-rofi set blur on|off
rice-rofi reset          # valores por defecto
rice-rofi restore        # restaurar tus archivos originales de rofi e Hyprland
```
El tema se escribe en `~/.config/rofi/shadows.rasi` y se carga desde `~/.config/rofi/config.rasi`. Tus líneas `@theme` anteriores se comentan (copia: `config.rasi.bak-rice-rofi`).

## Tema
```bash
rice-colors list             # todos los esquemas
rice-colors mode ocean       # auto, grey, navy, mono, slate, stone, steel, ash, ink, ocean, sky, ...
```

## Notificaciones (swaync)
```bash
rice-notify set pos_x left|center|right
rice-notify set layout controls-top|controls-bottom|minimal
rice-notify set style glass|solid|outline
rice-notify test             # enviar una notificación de prueba
rice-notify restore          # restaurar tus archivos originales de swaync
```

## Reposo y pantalla de bloqueo (hypridle + hyprlock)
```bash
rice-lock set lock_after 5          # minutos, 0 = nunca
rice-lock set suspend_after 30
rice-lock set clock big|stacked|minimal
rice-lock set background screenshot|wallpaper|color
rice-lock restore                   # restaurar tus hyprlock.conf e hypridle.conf originales
```

## Capturas y grabación
```bash
rice-hotcorner shot region   # captura de una región
rice-hotcorner record full   # iniciar grabación (ejecuta "record stop" para parar)
```
