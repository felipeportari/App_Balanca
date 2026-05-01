# Como capturar o protocolo BLE com nRF Connect

O próximo passo mais importante é capturar o tráfego real entre o app oficial e a balança.
Isso confirma os bytes exatos enviados/recebidos.

## Método 1 — nRF Connect (recomendado, sem root)

1. Instale **nRF Connect for Mobile** (Nordic Semiconductor) no Android
2. Abra o app e faça scan de dispositivos BLE
3. Encontre a balança (geralmente nome como "OKOK-XXXX", "LS-XXXX", ou "CS-XXXX")
4. Conecte
5. Explore os serviços GATT e anote os UUIDs presentes
6. No serviço com UUID `D618D000-...` ou `FFF0-...`:
   - Ative o **Notify** na characteristic de notificação
   - Observe os pacotes chegando ao pisar na balança
   - Anote os bytes em hex
7. Tente escrever na characteristic de **Write** e observe a resposta

**Exportar log:**
- No nRF Connect: Menu → Log → Export

## Método 2 — Bluetooth HCI snoop log (requer habilitar nas opções de desenvolvedor)

1. No Android: Configurações → Opções do desenvolvedor → Habilitar log Bluetooth HCI
2. Use o app OKOK oficial com a balança normalmente
3. Copie o arquivo `/data/misc/bluetooth/logs/btsnoop_hci.log`
4. Abra no Wireshark e filtre por `btle`

**No Wireshark:**
```
btle && btatt
```
Filtre por Handle matching (usar o handle da characteristic FFF2/D618D002)

## O que documentar

Para cada pacote capturado, registre:

```
Direção: App→Balança (Write) ou Balança→App (Notify)
Momento: antes de subir / peso estabilizando / peso estável / impedância pronta
Bytes (hex): FF 12 01 AF 19 01 XX
Interpretação: ?
```

## Arquivo de log esperado

Salve as capturas em `docs/reverse_engineering/ble_captures/` no formato:
```
session_YYYY-MM-DD.txt
```

## Dicas

- A balança precisa estar ligada (LED piscando) — geralmente acende ao pisar
- Pode ser necessário enviar um comando de "inicialização" antes de receber dados
- O app original envia o perfil do usuário (altura/peso alvo/gênero) no início
- Alguns modelos só medem impedância quando recebem o perfil primeiro
