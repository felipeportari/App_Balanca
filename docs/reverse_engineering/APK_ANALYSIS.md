# APK Analysis — OKOK International

**File:** `OKOK international.apk`  
**Date analyzed:** 2026-05-01  
**Method:** Unzip + binary string extraction (PowerShell)

## App identity

| Field | Value |
|-------|-------|
| Package | `com.chipsea.btcontrol` |
| Developer | ChipSea Technology |
| DEX files | 10 (classes.dex through classes10.dex) |
| APK size | ~50MB |

## Third-party SDKs found in APK

Heavy monetization / tracking stack — the main reason to replace the app:

| SDK | Purpose |
|-----|---------|
| Google AdMob | Ads |
| Mbridge (Mintegral) | Video ads |
| Vungle | Video ads |
| ironSource | Ads mediation |
| Facebook Audience Network | Ads |
| Google Firebase | Analytics / crash reporting |
| AppMetrica (Yandex) | Analytics |
| Google Play Services Fitness | Health data |
| Room (SQLite) | Local database |
| Kotlin Coroutines | Async |
| DataStore | Settings persistence |

## App features found in class structure

From `com.chipsea.btcontrol.*`:

- `BluetoothUpScaleActivity` — main BLE scale connection screen
- `BodyCircumferenceMainActivity` — body measurements (waist, hips, etc.)
- `DataCompareReportActivity` — data comparison/trends
- `WeightRecordActivity` / `WeightDayRecordActivity` — weight history
- `WeightGoalActivity` — weight goal setting
- `ReportDetailActivity` — detailed body composition report
- `HandAddWeightDialog` — manual weight entry
- `PregnancyDialogManager` — pregnancy mode
- `ImpedanceType` (enum) — impedance measurement types
- `SettingType` (enum) — app settings

## BLE UUIDs found in DEX

See `docs/protocol/BLE_PROTOCOL.md` for full table.

Key UUIDs:
- `D618D000-6000-1000-8000-000000000000` — ChipSea proprietary service
- `0000FFF0-0000-1000-8000-00805F9B34FB` — Generic write/notify service
- `0000181B-0000-1000-8000-00805F9B34FB` — Standard BLE Body Composition
- `00002902-0000-1000-8000-00805F9B34FB` — CCCD (enable notifications)

## Database schema fragments found

From string extraction in classes3.dex:
```sql
impedance float null,
scaleweight varchar(20) null,
scaleprop ...
```

## Strings suggesting body composition measurements

- `impedance`
- `impedanceMeasuringType`
- `ImpedanceType`
- `getWeight`
- `BodyCircumference`
- `BodyFatData` (inferred from class names)
- `ScaleHelper`
- `BleScaleFaileStatus`

## BLE communication log strings found

```
writeCharacteristic --> 
writeCharacteristic done!
WriteCharacteristic error
writeCharacteristic ret:
onCharacteristicChanged
onCharacteristicRead status:
onCharacteristicWrite status:
_BLE_TRANSMISSION_NOTIFY
```

## Next step: full decompilation

To get exact byte-level protocol, use:
```bash
# Download jadx
jadx -d output/ "OKOK international.apk"

# Then look at:
# output/sources/com/chipsea/btcontrol/
# Focus on BLE service classes
```
