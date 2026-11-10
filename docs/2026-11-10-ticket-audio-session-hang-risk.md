# Tiket: AVAudioSession „Hang Risk“ – zvuk se spouští na hlavním vlákně

Datum: 2026-11-10 · Stav: otevřeno · Priorita: nízká (varování, nic nepadá)

## Co Xcode hlásí
- Issue navigator, runtime issue „AVAudioSession Hang Risk“: 3× v aplikaci, 24× v testech (stejná příčina).
- Text: metoda může způsobit nereagování UI, pokud se volá na hlavním vlákně.
- Zdroj hlášení: Thread Performance Checker (zapnutý ve výchozím nastavení pro akci Run).

## Příčina (ověřeno u prvního hlášení, zbylé dvě ověřit)
Stopa vlákna: `CalibrationSession` (closure) → `AudioEngine.start()` → `queue.sync` → `AudioSessionOwnership.acquire` → `AVAudioSession.setCategory`.
- `SmackAPad/Sources/Calibration/CalibrationSession.swift:82` volá `try audio.start()` na hlavním vlákně.
- `SmackAPad/Sources/Audio/AudioEngine.swift:356` (`activateSession()` uvnitř `queue.sync`) čeká na zvukovou frontu a nastavuje kategorii, vzorkovací frekvenci a velikost bufferu.
- Zkontrolovat i `SmackAPad/Sources/UI/PracticeSession.swift:607` (`audio.start(onRunAudioChange:)`).

## Navržená oprava
1. Spouštění zvuku z kalibrace (a případně z cvičení) přesunout mimo hlavní vlákno (asynchronně), po dokončení se vrátit na `MainActor` a aktualizovat stav UI.
2. Nesahat do pořadí kroků v `AudioEngine` (kategorie, 48 kHz, buffer 5 ms, aktivace) – je citlivé na latenci.
3. Neměnit `AudioSessionOwnership`, pokud to není nutné.

## Kritéria hotovo
- Po spuštění kalibrace i cvičení v Issue navigatoru nezůstane žádné „AVAudioSession Hang Risk“.
- Testy (`AfterMeSessionTests` a ostatní) projdou beze změny chování a bez těchto varování.
- Ověřeno na skutečném iPadu: latence a odezva pádů beze změny, kalibrace funguje.

## Dočasné řešení
Kontrola vypnutá ve schématu (Run → Diagnostics → Thread Performance Checker), aby varování nezahlcovalo seznam. Po opravě znovu zapnout.

## Doporučení, pokud to bude řešit AI
Model: Claude Opus 5.5, vysoká úroveň uvažování (práce s vlákny a zvukem, chyba by se projevila jen zpožděním nebo výpadkem zvuku).
