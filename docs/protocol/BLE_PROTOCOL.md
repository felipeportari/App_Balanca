# BLE Protocol — OKOK International Scale (ChipSea)

> Extraído diretamente do código-fonte descompilado via jadx.
> Fontes: `chipseaStraightFrame.java`, `syncChipseaInstruction.java`, `BtGattAttr.java`

## Device overview

| Field | Value |
|-------|-------|
| Brand | OKOK International |
| Package | `com.chipsea.btcontrol` |
| BLE lib | `com.chipsea.btlib` |
| Measurements | Peso, Impedância, Gordura %, Músculo %, Osso, Água %, IMC, TMB, Gordura Visceral |

---

## BLE Service & Characteristic UUIDs (confirmados do código)

Fonte: `BtGattAttr.java`

### Protocolo principal — CHIPSEA/ISSC (FFF0)

| Role | UUID | Nome interno |
|------|------|-------------|
| Service | `0000fff0-0000-1000-8000-00805f9b34fb` | `CHIPSEA_SERVICE_UUID` / `ISSC_SERVICE_UUID` |
| Write (RX) | `0000fff1-0000-1000-8000-00805f9b34fb` | `CHIPSEA_CHAR_RX_UUID` |
| Notify (TX) | `0000fff2-0000-1000-8000-00805f9b34fb` | `CHIPSEA_CHAR_TX_UUID` |

### Protocolo JD (D618D)

| Role | UUID | Nome interno |
|------|------|-------------|
| Service | `D618D000-6000-1000-8000-000000000000` | `JD_SERVICE_UUID` |
| Notify (TX) | `D618D001-6000-1000-8000-000000000000` | `JD_CHAR_TX_UUID` |
| Write (RX) | `D618D002-6000-1000-8000-000000000000` | `JD_CHAR_RX_UUID` |

> **Atenção:** No protocolo JD, RX e TX estão invertidos! Write=D618D002, Notify=D618D001

### Protocolo LX (A620)

| Role | UUID |
|------|------|
| Service | `0000a602-0000-1000-8000-00805f9b34fb` |
| UP_I    | `0000a620` |
| UP_N (notify) | `0000a621` |
| UP_ACK  | `0000a622` |
| DOWN_WI | `0000a623` |
| DOWN_WO | `0000a624` |
| DOWN_ACK | `0000a625` |

### Protocolo LEAONE (FAA0)

| Role | UUID |
|------|------|
| Service | `0000faa0-0000-1000-8000-00805f9b34fb` |
| Write   | `0000faa1-0000-1000-8000-00805f9b34fb` |
| Notify  | `0000faa2-0000-1000-8000-00805f9b34fb` |

### Standard BLE

| UUID | Propósito |
|------|----------|
| `00002902-0000-1000-8000-00805f9b34fb` | CCCD — habilitar notificações |
| `0000181b-0000-1000-8000-00805f9b34fb` | Body Composition Service (padrão BLE SIG) |
| `00002a9c-0000-1000-8000-00805f9b34fb` | Body Composition Measurement |
| `0000fa9c-0000-1000-8000-00805f9b34fb` | Body Composition History |
| `00001805-0000-1000-8000-00805f9b34fb` | Current Time Service |
| `00002a08-0000-1000-8000-00805f9b34fb` | Current Time Characteristic |

---

## Frame header

Todos os pacotes (enviados e recebidos) começam com `0xCA` (byte[0]).

Em Java: `-54` (signed) = `0xCA` (unsigned).

---

## Pacotes recebidos da balança (Notify)

Fonte: `chipseaStraightFrame.java` — método `process()`

### Versão 0x10 — Tipo 0x10 (medição com composição corporal)

```
Byte[0]  = 0xCA        header
Byte[1]  = 0x10        versão
Byte[2]  = length
Byte[3]  = device type
Byte[4]  = cmdId / scaleProperty
             → cmdId = BytesUtil.getCmdId(scaleProperty)
             → cmdId > 0 significa composição corporal disponível
Byte[5..6] = peso raw  → WeightUnitUtil.Parser(b5, b6, scaleProperty)
             → weight_kg = parserResult.kgWeight
Byte[7..8]  = gordura corporal (axunge)  → bytesToInt(bytes)
Byte[9..10] = água (water)               → bytesToInt(bytes)
Byte[11..12]= músculo (muscle)           → bytesToInt(bytes)
Byte[13..14]= TMB (BMR)                  → bytesToInt(bytes)
Byte[15..16]= gordura visceral           → bytesToInt(bytes)
Byte[17]    = osso (bone)                → bytesToInt(bytes)
```

### Versão 0x11 — Tipo 0x00 ou 0x01 (peso simples / peso estável)

```
Byte[0]  = 0xCA
Byte[1]  = 0x11
Byte[2]  = length
Byte[3]  = lockFlag (0=medindo, 1=estável)
Byte[4]  = ? (ignorado)
Byte[5..6] = peso raw
Byte[7..11] = ?
Byte[11] = scaleProperty
```

### Flags do `scaleProperty`

`scaleProperty` é um byte de flags que contém:
- Unidade (kg / lb / jin / st)
- Número de casas decimais
- Estado do lock

Extraído por `BytesUtil.getUnit()`, `BytesUtil.getDigit()`, `BytesUtil.getCmdId()`.

---

## Comandos enviados para a balança (Write)

Fonte: `syncChipseaInstruction.java`

### Enviar perfil do usuário — v10 (0xCA 0x10)

```
Byte[0]  = 0xCA
Byte[1]  = 0x10        versão
Byte[2]  = 0x0E        length (14)
Byte[3]  = 0x01        type
Byte[4]  = year (2 dígitos, ex: 25 para 2025)
Byte[5]  = month (1-12)
Byte[6]  = day
Byte[7]  = hour
Byte[8]  = minute
Byte[9]  = second
Byte[10..13] = userId (int32, big-endian)
Byte[14] = sex (byte) — ver codificação abaixo
Byte[15] = age (anos, calculado a partir da data de nascimento)
Byte[16] = height (cm)
Byte[17] = XOR checksum de Byte[1..16]
Byte[18] = 0x00
Byte[19] = 0x00
```

### Enviar perfil do usuário — v11 (0xCA 0x11) para 1 usuário

```
Byte[0]  = 0xCA
Byte[1]  = 0x11        versão
Byte[2]  = 0x10        length (16)
Byte[3]  = 0x10        type
Byte[4]  = 0x11        package field (1 pacote de 1)
Byte[5..8] = timestamp Unix (int32)
Byte[9]  = 0x00
Byte[10] = 0x00
Byte[11..14] = roleId (int32)
Byte[15] = sex+age  → (sex==male ? age|0x80 : age&0x7F)
Byte[16] = height (cm)
Byte[17..18] = weight (short, peso alvo em 0.1kg)
Byte[19] = XOR checksum de Byte[1..18]
```

### Codificação sex+age (mergeSexAndAge)

```
male   → age | 0x80     (bit 7 = 1)
female → age & 0x7F     (bit 7 = 0)
```

### Selecionar usuário ativo

```
Byte[0]  = 0xCA
Byte[1]  = 0x11
Byte[2]  = 0x05
Byte[3]  = 0x15        (NAK = 21)
Byte[4..7] = userId (int32)
Byte[8]  = XOR checksum de Byte[1..7]
```

### Solicitar histórico

```
Byte[0]  = 0xCA
Byte[1]  = 0x11
Byte[2]  = 0x02
Byte[3]  = 0x11
Byte[4]  = 0x01
Byte[5]  = XOR checksum de Byte[1..4]
Byte[6..19] = 0x00
```

---

## Cálculo de peso (WeightUnitUtil)

O peso raw de 2 bytes é interpretado assim:

```
weight_raw = (byte[high] << 8) | byte[low]

if digit == ONE:
  weight_display = weight_raw / 10.0   (ex: 750 → 75.0 kg)
if digit == TWO:
  weight_display = weight_raw / 100.0

Conversões de unidade:
  jin → kg:  peso * 0.5
  lb  → kg:  peso * 0.4535924
  st  → lb:  strôes × 14 + libras_decimais
```

---

## Composição corporal (calculada pelo app)

Os valores de gordura/músculo/osso/água/TMB/visceral são recebidos da balança
(não calculados pelo app) no protocolo versão 0x10.

Escala dos valores recebidos:
- Gordura (axunge), Água, Músculo: `valor / 10.0 → percentual`
- TMB (BMR): `valor` em kcal
- Gordura Visceral: índice (tipicamente 1-50)
- Osso: `valor / 10.0` em kg

O músculo é calculado como percentual na leitura:
```java
muscle_pct = (muscle / weight) * 100
if (muscle_pct >= 50) muscle_pct = min(muscle_as_raw, 50)
fatScale.setMuscle((int)(muscle_pct * 10))
```

---

## Checksum

XOR de todos os bytes no intervalo especificado:
```
xor = byte[start] ^ byte[start+1] ^ ... ^ byte[end]
```

Implementado em `BytesUtil.getDatasXor(bArr, startIdx, length)`.
