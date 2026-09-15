# Sales Tracker iOS — estado e runbook de lançamento

App nativa SwiftUI + SwiftData + CloudKit. Vive neste repo ao lado da PWA React
para que divergências na lógica partilhada (semana ISO, formato do relatório)
apareçam no mesmo diff.

## Estado atual

| | |
|---|---|
| Build | ✅ passa (Xcode 27, iOS 18.0+, Swift 6 modo estrito) |
| Testes | ✅ 23 unitários + 2 de UI |
| Sincronização | CloudKit privado (`iCloud.com.bertobarata.salestracker`) |
| Bundle ID | `com.bertobarata.salestracker` |
| Widget | `com.bertobarata.salestracker.widget` |
| App Group | `group.com.bertobarata.salestracker` |
| Assinatura | ❌ `DEVELOPMENT_TEAM` por preencher |

## Comandos

O `xcode-select` do sistema aponta para as Command Line Tools, por isso todos os
comandos precisam de `DEVELOPER_DIR` à frente (evita o `sudo xcode-select -s`):

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd ios

xcodegen generate     # regenerar o .xcodeproj a partir do project.yml

xcodebuild build -project SalesTracker.xcodeproj -scheme SalesTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO

xcodebuild test -project SalesTracker.xcodeproj -scheme SalesTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

**O `.xcodeproj` não está no git.** É gerado. Depois de clonar, correr
`xcodegen generate` antes de abrir no Xcode. Qualquer alteração de targets,
entitlements ou build settings faz-se em `project.yml`, nunca no Xcode.

## Arquitetura

```
ios/
  project.yml                  definição dos targets (fonte de verdade)
  SalesTracker/
    Models/                    DailyEntry, WeeklySummary, Metric
    Core/                      WeekMath, ReportBuilder, CSVExport, EntryStore,
                               AppSettings, ReminderScheduler, LogMetricIntent
    Views/                     RootView + 4 ecrãs + Components partilhados
  SalesTrackerWidget/          widget de progresso + control do Centro de Controlo
  SalesTrackerTests/           lógica pura (semanas, relatório, CSV)
  SalesTrackerUITests/         fumo dos 4 ecrãs + gravar um dia
```

Notas de implementação que não são óbvias no código:

- **CloudKit proíbe `@Attribute(.unique)`.** A deduplicação por dia e por semana
  é feita à mão no `EntryStore`, ficando o registo mais recente.
- **`ModelConfiguration(groupContainer:)` faz `fatalError`**, não lança, quando o
  App Group não está nos entitlements. Daí o `AppGroup.isAvailable` antes de a usar —
  sem isso, qualquer build não assinado rebenta no arranque.
- **O widget usa um `ModelContext` próprio**, não o `mainContext`: o provider
  corre fora do MainActor.
- O formato do texto do WhatsApp está fixado num teste que compara a string
  completa. Quem o alterar parte o teste de propósito.

## Diferenças face à PWA

| PWA | iOS |
|---|---|
| Firestore + Google Auth | CloudKit privado, sem login |
| Excel (.xlsx) | CSV com BOM UTF-8, via `ShareLink` |
| Notificações web | `UNUserNotificationCenter`, só nos dias por registar |
| recharts | Swift Charts |
| — | Widgets Home/Lock, control do Centro de Controlo, atalhos Siri |

**As duas apps não sincronizam entre si.** Decisão tomada em 2026-09-15: o iOS
usa CloudKit, a PWA fica no Firestore. São duas ilhas de dados.

## Por fazer antes de submeter

### Bloqueadores de assinatura
- [ ] `APPLE_TEAM_ID` → preencher `DEVELOPMENT_TEAM` em `project.yml`
      (developer.apple.com → Membership). Continua `XXXXXXXXXX` no runbook do TVDE.
- [ ] Registar no portal Apple: App ID, App Group, contentor CloudKit
- [ ] App Store Connect → Agreements, Tax and Banking (é preciso mesmo para app grátis)

### Bloqueadores de revisão
- [ ] **Guideline 4.2 (Minimum Functionality)** — é o risco real: a app é uma
      ferramenta pessoal. Mitigação já feita: objetivos configuráveis, métricas
      genéricas de atividade comercial (nada preso à Metlife), widgets e atalhos.
      Não voltar a introduzir nada específico de um empregador.
- [ ] Política de privacidade num URL público (o site do Barata Studio serve)
- [ ] Nutrition labels: dados só em iCloud privado → "Data Not Collected"
- [ ] Ícone 1024×1024 sem canal alfa
- [ ] Capturas de ecrã 6.9" e 6.5"

Guidelines 4.8 (Sign in with Apple), 5.1.1 (login forçado) e 5.1.1(v) (apagar conta)
**não se aplicam** — a app não tem contas nem login de terceiros. Foi essa a razão
principal para escolher CloudKit em vez de Firebase.

### Ainda por construir
- [ ] Assets.xcassets com ícone e AccentColor (agora usa o azul do sistema)
- [ ] Importar o histórico da PWA (exportar Firestore → ler no arranque)
