# 🎮 R36S / ArkOS — Fix FN & Select mappings (EmulationStation + RetroArch)

This repository provides a one‑shot script to normalize controller mappings on **R36S / ArkOS** (also useful on similar devices).
It fixes **FN (Hotkey)** and **Select** in both **EmulationStation** and **RetroArch/RetroArch32**, and enables a clean **FN + X** menu combo in‑game.

---

## ✨ What the script does

* **🖥 EmulationStation**

  * Ensures `<input name="select" ... id="…">` matches your **Select** button ID.
  * Ensures (or inserts if missing) `<input name="hotkeyenable" ... id="…">` for your **FN** button ID.

* **🎯 RetroArch / RetroArch32**

  * Sets:

    * `input_enable_hotkey_btn = "<FN_ID>"`
    * `input_player1_select_btn = "<SELECT_ID>"`
    * `input_menu_toggle_btn = "<MENU_ID>"` → use **FN + \<MENU\_ID>** to open the menu (e.g., FN+X)
    * `input_menu_toggle_gamepad_combo = "0"` (disables default Select+X combos)
  * Optionally backs up & clears per‑core/per‑game overrides.

* **🗂 Autoconfigs (controllers)**

  * Updates entries in `/usr/share/retroarch*/autoconfig/udev` and user autoconfigs if present.

* **💾 Backups**

  * Everything is backed up to `~/backup_inputs_YYYYmmdd-HHMMSS/`.

---

## ⚙️ Requirements

* ArkOS (community build) or similar Linux‑based firmware.
* SSH access or a local terminal on the device.
* `sed`, `find`, basic GNU userland (available by default on ArkOS).

---

## 🚀 Quick start

1. **📄 Copy the script to your device** (or create it there):

   ```bash
   # On the device (SSH):
   nano r36s-fn-select-fix.sh
   # paste the script content, save and exit

   chmod +x r36s-fn-select-fix.sh
   ```

2. **🕹 Generate EmulationStation config** (if you haven’t):

   On the device UI:
   `Start → Controller Settings → Configure Input`

3. **Run the script as your user (fixes user configs):**

   ```bash
   ./r36s-fn-select-fix.sh
   ```

   Defaults used: `FN=12`, `SELECT=16`, `MENU=2` (X button).
   To override:

   ```bash
   ./r36s-fn-select-fix.sh --fn-id 12 --select-id 16 --menu-id 2
   ```

4. **Run the script with sudo** (fixes `/usr/share/*` autoconfigs):

   ```bash
   sudo ./r36s-fn-select-fix.sh
   ```

5. **🔄 Reboot** (recommended):

   ```bash
   sudo reboot
   ```

---

## ✅ Verify

* **EmulationStation**:
  Select behaves as Select; FN no longer acts as Select.

* **In‑game (RetroArch/RetroArch32)**:

  * **FN + X** opens the menu.
  * Select alone does not open the menu.
  * (If enabled by your build) **FN + Start** exits the game.

You can also grep configs:

```bash
# RetroArch user configs
grep -E 'input_enable_hotkey_btn|input_player1_select_btn|input_menu_toggle_btn|input_menu_toggle_gamepad_combo' ~/.config/retroarch/retroarch.cfg
grep -E 'input_enable_hotkey_btn|input_player1_select_btn|input_menu_toggle_btn|input_menu_toggle_gamepad_combo' ~/.config/retroarch32/retroarch.cfg

# EmulationStation (system)
sudo grep -E 'hotkeyenable|select' /etc/emulationstation/es_input.cfg
```

---

## 🧹 Optional: clean overrides

If per‑core/per‑game overrides keep overriding your settings:

```bash
./r36s-fn-select-fix.sh --clean-overrides
sudo ./r36s-fn-select-fix.sh --clean-overrides
sudo reboot
```

This backs up overrides to `~/backup_inputs_*/retroarch_overrides_*` and clears them.

---

## 🛠 Troubleshooting

* **No changes in EmulationStation:**
  Ensure you’ve created `es_input.cfg`:
  `Start → Controller Settings → Configure Input`.

* **No changes in /usr/share autoconfigs:**
  Run the script with `sudo`.

* **Line endings error (`bash\r`):**
  Convert the file to Unix line endings (LF):
  `dos2unix r36s-fn-select-fix.sh` (if available) or re‑save from your editor with LF.

* **Different button IDs:**
  Re‑run with the correct IDs:
  `./r36s-fn-select-fix.sh --fn-id <FN> --select-id <SELECT> --menu-id <X>`

---

## 🧪 Tested on

* R36S "Soy Sauce" Board (ArkOS community build)
* RetroArch & RetroArch32 standard layouts

---

## 📌 License

This repository is licensed under the [MIT](https://opensource.org/licenses/MIT) license.
You can read the full text in the [LICENSE](LICENSE.md) file.

---

# 🇪🇸 Español — R36S / ArkOS — Arreglo de mapeos FN y Select

Este repositorio incluye un script para normalizar los mapeos de **FN (Hotkey)** y **Select** en **EmulationStation** y **RetroArch/RetroArch32**, y habilitar el combo **FN + X** para abrir el menú dentro del juego.

## ✨ Qué hace

* **EmulationStation**

  * Ajusta `select` al ID correcto.
  * Asegura (o inserta si falta) `hotkeyenable` con el ID de tu FN.

* **RetroArch / RetroArch32**

  * Define:

    * `input_enable_hotkey_btn = "<FN_ID>"`
    * `input_player1_select_btn = "<SELECT_ID>"`
    * `input_menu_toggle_btn = "<MENU_ID>"` → **FN + \<MENU\_ID>** abre el menú (p. ej., FN+X)
    * `input_menu_toggle_gamepad_combo = "0"` (desactiva combos por defecto como Select+X)

* **Autoconfigs**

  * Ajusta `/usr/share/retroarch*/autoconfig/udev` y los autoconfigs del usuario si existen.

* **Backups**

  * Todos los cambios se respaldan en `~/backup_inputs_YYYYmmdd-HHMMSS/`.

## ⚙️ Requisitos

* ArkOS (build de la comunidad) u otro firmware Linux.
* Acceso por SSH o terminal local.
* Herramientas estándar (`sed`, `find`, etc.).

## 🚀 Pasos rápidos

1. **Copiar/crear el script** en la consola y dar permisos:

   ```bash
   nano r36s-fn-select-fix.sh
   # pega el contenido del script y guarda
   chmod +x r36s-fn-select-fix.sh
   ```

2. **Generar `es_input.cfg`** si aún no existe:
   `Start → Controller Settings → Configure Input`

3. **Ejecutar el script como usuario** (ajusta configs del usuario):

   ```bash
   ./r36s-fn-select-fix.sh
   ```

   Valores por defecto: `FN=12`, `SELECT=16`, `MENU=2` (botón X).
   Para cambiarlos:

   ```bash
   ./r36s-fn-select-fix.sh --fn-id 12 --select-id 16 --menu-id 2
   ```

4. **Ejecutar con sudo** (ajusta autoconfigs en `/usr/share/*`):

   ```bash
   sudo ./r36s-fn-select-fix.sh
   ```

5. **🔄 Reiniciar**:

   ```bash
   sudo reboot
   ```

## ✅ Verificar

* **EmulationStation**: Select y FN se comportan correctamente.
* **En juego (RetroArch/RetroArch32)**:

  * **FN + X** abre el menú.
  * Select solo no abre el menú.
  * (Si tu build lo permite) **FN + Start** sale del juego.

También puedes verificar con:

```bash
# RetroArch (usuario)
grep -E 'input_enable_hotkey_btn|input_player1_select_btn|input_menu_toggle_btn|input_menu_toggle_gamepad_combo' ~/.config/retroarch/retroarch.cfg
grep -E 'input_enable_hotkey_btn|input_player1_select_btn|input_menu_toggle_btn|input_menu_toggle_gamepad_combo' ~/.config/retroarch32/retroarch.cfg

# EmulationStation (sistema)
sudo grep -E 'hotkeyenable|select' /etc/emulationstation/es_input.cfg
```

## 🧹 Limpieza opcional de overrides

```bash
./r36s-fn-select-fix.sh --clean-overrides
sudo ./r36s-fn-select-fix.sh --clean-overrides
sudo reboot
```

## 🛠 Solución de problemas

* **Sin cambios en EmulationStation:** Genera primero `es_input.cfg` en ES.
* **Sin cambios en /usr/share autoconfigs:** Ejecuta con `sudo`.
* **Error de finales de línea (`bash\r`):** Guarda con formato LF o usa `dos2unix`.
* **IDs de botones distintos:** Re‑ejecuta con los IDs correctos.

## 🧪 Probado en

* R36S "Soy Sauce" Board (ArkOS build comunidad)
* RetroArch & RetroArch32 (layouts estándar)

## 📌 Licencia

Este repositorio está bajo la licencia [MIT](https://opensource.org/licenses/MIT).
Puedes leer el texto completo en el archivo [LICENSE](LICENSE.md).
