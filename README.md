# Canaduino Display Monitor

ESPHome-based DC voltage monitor with OLED display for the [Canaduino PLC](https://canaduino.ca/) board + Arduino Nano ESP32 (ESP32-S3).

Reads DC voltage via a 0-25V voltage sensor module and displays it on a 128x64 SSD1306/SSD1309 OLED screen.

## Hardware

- **Canaduino PLC board** with Arduino Nano ESP32 (ESP32-S3)
- **0.96" OLED display** - SSD1306 or SSD1309, 128x64, I2C (4-pin)
- **DC 0-25V voltage sensor module** - Resistive divider (30k/7.5k)

## Wiring

### OLED Display → Canaduino J13 I2C Port

The J13 port on the Canaduino has 4 pins (top to bottom):

```
J13 Pin    Wire To        Signal
───────    ───────        ──────
  GND  →  Display GND    Ground
  5V   →  Display VCC    Power (5V, 500mA)
  SDA  →  Display SCL    ← NOTE: Cross-wired!
  SCL  →  Display SDA    ← NOTE: Cross-wired!
```

**Important:** The Canaduino J13 I2C pins are swapped relative to their labels. Connect display SCL to the Canaduino SDA terminal and display SDA to the Canaduino SCL terminal. The ESPHome config accounts for this with `sda: 12, scl: 11`.

### Voltage Sensor → Canaduino A1

```
Sensor Pin    Canaduino Terminal
──────────    ──────────────────
  S (signal)  →  A1 (analog input, 0-10V range)
  + (VCC)     →  5V
  - (GND)     →  GND
```

The voltage to measure connects to the screw terminals on the voltage sensor module (VCC/GND).

**Note:** The Canaduino A1 input has a built-in 0-10V voltage divider. Combined with the sensor module's 5:1 divider, the effective measurement range depends on both. Max safe input to the sensor module is 16.5V (ESP32 3.3V ADC limit × 5).

## Setup

1. Copy `secrets.example.h` to `secrets.h` and fill in your credentials:
   ```bash
   cp secrets.example.h secrets.h
   ```

2. Edit `secrets.h` with your WiFi SSID, password, and OTA password. The `upload.sh` script reads these and passes them to ESPHome as substitutions.

3. First flash via USB (see [Initial USB Flash](#initial-usb-flash) below).

4. Subsequent updates use OTA:
   ```bash
   ./upload.sh
   ```

## Calibration

The voltage sensor uses `calibrate_linear` with 4 reference points. To calibrate for your specific board:

1. Flash with the default calibration values
2. Apply known voltages (0V, ~5V, ~10V, ~12V) and note what the display reads vs your multimeter
3. Update the `calibrate_linear` values in the YAML:
   ```yaml
   filters:
     - calibrate_linear:
         - <raw_adc_at_0V> -> 0.0
         - <raw_adc_at_5V> -> <meter_reading>
         - <raw_adc_at_10V> -> <meter_reading>
         - <raw_adc_at_12V> -> <meter_reading>
   ```
4. OTA update with the new calibration

Each Canaduino board may need individual calibration due to component tolerances.

## Initial USB Flash

The Arduino Nano ESP32 uses native USB which requires manual bootloader entry:

1. Compile: `esphome compile display-monitor.yaml`
2. Put board in bootloader mode: **hold BOOT**, **tap RESET**, **release BOOT**
3. Find the port: `ls /dev/cu.usbmodem*` (typically `usbmodem1201` in bootloader mode)
4. Flash the factory binary:
   ```bash
   ~/.platformio/penv/bin/python3 -m esptool \
     --before no-reset --after hard-reset \
     --baud 460800 --port /dev/cu.usbmodem1201 --chip esp32s3 \
     write-flash -z --flash-size detect 0x0 \
     .esphome/build/display-monitor/.pioenvs/display-monitor/firmware.factory.bin
   ```

After the first flash, OTA updates work via `./upload.sh` or:
```bash
esphome run display-monitor.yaml --no-logs --device display-monitor.local
```

## Pin Mapping

| Function | Canaduino Terminal | Arduino Nano ESP32 | GPIO |
|----------|-------------------|-------------------|------|
| Display SDA | J13 SCL (swapped!) | A5 | GPIO 12 |
| Display SCL | J13 SDA (swapped!) | A4 | GPIO 11 |
| Voltage Sensor | A1 | A0 | GPIO 1 |

## License

MIT
