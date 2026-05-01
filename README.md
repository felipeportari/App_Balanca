# Balança App — Custom BLE Scale Client

Substituição do app oficial **OKOK International** por um app próprio, limpo e sem anúncios.

## O problema

O app oficial (`com.chipsea.btcontrol`) é:
- Cheio de anúncios (Mbridge, Vungle, AdMob, ironSource)
- Exige login/conta
- Interface confusa
- Envia dados para servidores chineses (analytics, Firebase, AppMetrica)
- APK de ~50MB com SDKs de terceiros desnecessários

## O objetivo

App simples e local que:
- Conecta diretamente na balança via BLE
- Exibe peso em tempo real
- Calcula composição corporal (gordura, músculo, água, osso, IMC)
- Armazena histórico localmente
- Sem conta, sem internet, sem anúncios

---

## Status do projeto

- [x] Análise do APK original
- [x] Identificação dos UUIDs BLE
- [x] Documentação do protocolo
- [ ] Captura BLE (nRF Connect) para confirmar bytes
- [ ] Implementação do app
- [ ] Testes com o dispositivo real

---

## Hardware

| Campo | Valor (a confirmar) |
|-------|---------------------|
| Marca | OKOK International |
| Modelo | (verificar na embalagem/app) |
| Fabricante do chip | ChipSea |
| Comunicação | Bluetooth BLE |
| Medições | Peso + Impedância bioelétrica (BIA) |

---

## Protocolo BLE

Ver [`docs/protocol/BLE_PROTOCOL.md`](docs/protocol/BLE_PROTOCOL.md) para os UUIDs e estrutura de bytes encontrados.

**UUIDs confirmados no APK:**

| Protocolo | Service UUID | Write | Notify |
|-----------|-------------|-------|--------|
| D618D (principal) | `D618D000-6000-1000-8000-000000000000` | `D618D001` | `D618D002` |
| FFF0 (legado) | `0000FFF0-...-00805F9B34FB` | `FFF1` | `FFF2` |
| FFE0 | `0000FFE0-...-00805F9B34FB` | — | `FFE4` |
| FAA0 | `0000FAA0-...-00805F9B34FB` | `FAA1` | `FAA2` |

---

## Estrutura do repositório

```
docs/
  protocol/          — Protocolo BLE documentado
  reverse_engineering/ — Capturas BLE brutas (nRF Connect logs)
app/                 — Código fonte do novo app
```

---

## Próximos passos

1. **Capturar BLE** — instalar nRF Connect no Android, usar a balança e exportar o log para confirmar os bytes exatos
2. **Escolher stack** — React Native, Flutter, ou Kotlin nativo
3. **Implementar BLE layer** — scan, connect, notify, parse
4. **Implementar UI** — tela de peso em tempo real + histórico

---

## Referências técnicas

- [Bluetooth SIG — Body Composition Service 0x181B](https://www.bluetooth.com/specifications/specs/body-composition-service-1-0/)
- ChipSea SDK: `com.chipsea.btcontrol` (extraído do APK original)
- APK analisado: `OKOK international.apk`
