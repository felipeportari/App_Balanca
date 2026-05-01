# BLE Protocol — OKOK International Scale (ChipSea)

> Reverse-engineered from `OKOK international.apk` (com.chipsea.btcontrol)

## Device overview

| Field | Value |
|-------|-------|
| Brand | OKOK International |
| SDK | com.chipsea.btcontrol (ChipSea) |
| Communication | Bluetooth Low Energy (BLE / GATT) |
| Measurements | Weight, Impedance, Body Fat %, Muscle %, Bone %, Water %, BMI |

---

## BLE Service & Characteristic UUIDs

The app supports multiple protocol variants. The device will advertise one of these services.

### Protocol A — D618D (Primary ChipSea)

| Role | UUID |
|------|------|
| Service | `D618D000-6000-1000-8000-000000000000` |
| Write   | `D618D001-6000-1000-8000-000000000000` |
| Notify  | `D618D002-6000-1000-8000-000000000000` |

### Protocol B — FFF0 (Legacy / Fallback)

| Role | UUID |
|------|------|
| Service | `0000FFF0-0000-1000-8000-00805F9B34FB` |
| Write   | `0000FFF1-0000-1000-8000-00805F9B34FB` |
| Notify  | `0000FFF2-0000-1000-8000-00805F9B34FB` |

### Protocol C — FFE0

| Role | UUID |
|------|------|
| Service    | `0000FFE0-0000-1000-8000-00805F9B34FB` |
| Notify/RW  | `0000FFE4-0000-1000-8000-00805F9B34FB` |

### Protocol D — FAA0

| Role | UUID |
|------|------|
| Service | `0000FAA0-0000-1000-8000-00805F9B34FB` |
| Write   | `0000FAA1-0000-1000-8000-00805F9B34FB` |
| Notify  | `0000FAA2-0000-1000-8000-00805F9B34FB` |

### Protocol E — A620 (Body Composition)

| Role | UUID |
|------|------|
| Service | `0000A602-0000-1000-8000-00805F9B34FB` |
| Write   | `0000A620-0000-1000-8000-00805F9B34FB` |
| Notify  | `0000A621-0000-1000-8000-00805F9B34FB` |
| Extra   | `0000A622` / `A623` / `A624` / `A625` |

### Protocol F — FFA0

| Role | UUID |
|------|------|
| Service | `0000FFA0-0000-1000-8000-00805F9B34FB` |
| Write   | `0000FFA1-0000-1000-8000-00805F9B34FB` |
| Notify  | `0000FFA2-0000-1000-8000-00805F9B34FB` |

### Standard BLE Services also present

| Service | UUID | Purpose |
|---------|------|---------|
| Generic Access | `0000 1800` | Device name, appearance |
| Current Time   | `0000 1805` | Time sync |
| Device Info    | `0000 180A` | Manufacturer, model |
| Heart Rate     | `0000 180D` | (unused in scale) |
| Body Composition | `0000 181B` | Standard BLE body comp |

---

## Communication flow

```
App                              Scale
 |                                 |
 |--- BLE scan & connect -------->|
 |<-- GATT services discovered ---|
 |                                 |
 |--- Enable notify on char ------>|  (write 0x0100 to CCCD 0x2902)
 |                                 |
 |--- Send user profile cmd ------>|  height, age, gender, unit
 |                                 |
 |    [user steps on scale]        |
 |<-- Real-time weight (unstable)--|  streaming during weighing
 |<-- Final weight (stable) -------|  when measurement locks
 |<-- Impedance result ------------|  BIA measurement
 |                                 |
 |  [app calculates body comp]     |  BMI/fat/muscle calculated client-side
```

---

## Command structure (Protocol FFF0 / D618D)

> Full byte-level protocol to be documented after deeper decompilation.
> See `reverse_engineering/` folder for raw byte captures.

### Send user profile

Sent before or during measurement to allow impedance-based body composition.

```
Byte[0]  = 0xFF (header)
Byte[1]  = command type  (0x12 = set user info)
Byte[2]  = unit (0x00 = kg, 0x01 = lb, 0x02 = jin/catty)
Byte[3]  = height (cm, e.g. 175)
Byte[4]  = age (years)
Byte[5]  = gender (0x00 = female, 0x01 = male)
Byte[6]  = checksum (XOR of bytes 1..5)
```

### Weight data notification

Scale sends weight packets while measurement is in progress.

```
Byte[0]  = 0xFF (header)
Byte[1]  = status (0x01 = measuring, 0x02 = stable, 0x03 = impedance done)
Byte[2]  = unit   (0x00 = kg, 0x01 = lb, 0x02 = jin)
Byte[3]  = weight high byte
Byte[4]  = weight low byte
  → weight_raw = (Byte[3] << 8) | Byte[4]
  → weight_kg  = weight_raw / 10.0   (e.g. 0x02EE = 750 = 75.0 kg)
Byte[5]  = impedance high byte   (0x00 when still measuring)
Byte[6]  = impedance low byte
  → impedance_ohm = (Byte[5] << 8) | Byte[6]
Byte[7]  = checksum
```

---

## Body composition calculation

Impedance is measured by the scale hardware. Body fat % and other metrics are
**calculated by the app** using the Deurenberg / ChipSea formulas, not by the scale itself.

Inputs: weight (kg), height (cm), age (years), gender, impedance (Ω)

Derived metrics:
- **BMI** = weight / (height_m²)
- **Body Fat %** — formula varies by gender/age, uses impedance
- **Muscle Mass** — derived from lean body mass
- **Bone Mass** — derived from weight/lean mass ratio
- **Body Water %** — approximated from lean mass
- **Visceral Fat** — index based on waist estimate / age / gender
- **Basal Metabolic Rate (BMR)** — Harris–Benedict or Mifflin–St Jeor

---

## TODO — needs BLE capture to confirm

- [ ] Exact byte layout for D618D protocol commands
- [ ] Exact checksum algorithm (XOR vs sum vs CRC)
- [ ] Impedance measurement trigger byte
- [ ] Time sync command format
- [ ] History/data sync command (if any)
- [ ] Confirm unit encoding values

---

## References

- APK: `OKOK international.apk` — package `com.chipsea.btcontrol`
- BLE CCCD UUID: `00002902-0000-1000-8000-00805F9B34FB`
- Standard Body Composition Service: UUID `0x181B` (Bluetooth SIG)
