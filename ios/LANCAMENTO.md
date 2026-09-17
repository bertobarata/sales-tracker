# MetTracker (iOS) — estado e runbook de lançamento

App nativa SwiftUI + SwiftData + CloudKit. Vive neste repo ao lado da PWA React
para que divergências na lógica partilhada (semana ISO, formato do relatório)
apareçam no mesmo diff.

## Estado atual

| | |
|---|---|
| Build | ✅ passa (Xcode 27, iOS 26.0+, Swift 6 modo estrito) |
| Testes | ✅ 42 unitários (Swift Testing) + 4 de UI |
| Sincronização | CloudKit privado (`iCloud.com.bertobarata.salestracker`) |
| Bundle ID | `com.bertobarata.salestracker` |
| Widget | `com.bertobarata.salestracker.widget` |
| App Group | `group.com.bertobarata.salestracker` |
| Assinatura | ✅ archive e export de App Store a passar, equipa `7ACX25JD5D` |
| Nome na loja | MetTracker (ver aviso em `AppStore/METADATA.md`) |
| Ícone | ✅ funil, `Assets.xcassets`, 1024×1024 sem alfa; camadas para Liquid Glass em `AppStore/icon/` |
| Capturas | ✅ quatro, 6.9" (1320×2868), em `AppStore/screenshots/` |
| Metadados | ✅ `AppStore/METADATA.md` |

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
- [x] `APPLE_TEAM_ID` = `7ACX25JD5D` (conta Individual), preenchido em `project.yml`.
      O runbook do TVDE (`~/Developer/App/mobile/LANCAMENTO.md:105`) ainda tem `XXXXXXXXXX`.
- [x] Identificadores no portal — o Xcode criou-os sozinho por assinatura automática
      (aparecem com o prefixo `XC`): os dois App IDs, o App Group e o contentor CloudKit.
- [x] Dispositivo registado na equipa (`Berto 17 Pro`). A Apple não emite perfil de
      desenvolvimento a uma equipa sem dispositivos, e sem esse perfil o archive falha.
- [ ] Registar no portal Apple, com estes identificadores exatos:
      - App ID `com.bertobarata.salestracker`, com **iCloud (CloudKit)**,
        **App Groups** e **Push Notifications** ligados. O push é exigido pela
        sincronização do SwiftData sobre CloudKit, mesmo não havendo notificações
        remotas próprias — sem ele o `archive` de distribuição falha a assinar
      - App ID `com.bertobarata.salestracker.widget`, com iCloud e App Groups
      - App Group `group.com.bertobarata.salestracker`
      - Contentor CloudKit `iCloud.com.bertobarata.salestracker`
- [ ] App Store Connect → Agreements, Tax and Banking (é preciso mesmo para app grátis)

### Bloqueadores de revisão
- [ ] **Guideline 4.2 (Minimum Functionality)** — é o risco real: a app é uma
      ferramenta pessoal. Mitigação já feita: objetivos configuráveis, métricas
      genéricas de atividade comercial (nada preso à Metlife), widgets e atalhos.
      Não voltar a introduzir nada específico de um empregador. As notas para a
      equipa de revisão em `AppStore/METADATA.md` respondem a esta guideline de frente.
- [ ] **Guideline 5.2.1** — "MetTracker" pode ser lido como ligação à MetLife.
      Se a Apple travar, muda-se o campo do nome; o bundle ID não muda.
- [x] Política de privacidade num URL público —
      `https://baratastudio.com/mettracker-privacidade.html`
      (repo `bertobarata-website`, branch `feat/mettracker-legal`, **por juntar**)
- [x] Página de suporte — `https://baratastudio.com/mettracker.html` (mesmo branch)
- [x] Nutrition labels: resposta "Data Not Collected", justificada em `AppStore/METADATA.md`
- [x] Ícone 1024×1024 sem canal alfa
- [x] Capturas de ecrã 6.9" (1320×2868), quatro ecrãs

Guidelines 4.8 (Sign in with Apple), 5.1.1 (login forçado) e 5.1.1(v) (apagar conta)
**não se aplicam** — a app não tem contas nem login de terceiros. Foi essa a razão
principal para escolher CloudKit em vez de Firebase.

### Ainda por construir
- [x] Assets.xcassets com ícone e AccentColor
- [ ] Importar o histórico da PWA (exportar Firestore → ler no arranque) —
      **cortado do v1.0** por decisão do Berto a 2026-09-15. Fica para o v1.1.

## Capturas de ecrã

`DemoData` (só em builds Debug, só com `--demo-data` nos argumentos de lançamento)
arranca a app com doze semanas de dados numa base em memória. Nunca toca na base real
nem no iCloud, e o ficheiro inteiro está dentro de `#if DEBUG`, por isso não existe
no binário de distribuição.

O teste `ScreenshotTests` percorre os quatro separadores e guarda uma imagem de cada um
como anexo do `.xcresult`. Os comandos para regenerar estão em `AppStore/METADATA.md`.


## Archive e exportação

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd ios

xcodebuild archive -project SalesTracker.xcodeproj -scheme SalesTracker \
  -destination 'generic/platform=iOS' \
  -archivePath /tmp/MetTracker.xcarchive -allowProvisioningUpdates

xcodebuild -exportArchive -archivePath /tmp/MetTracker.xcarchive \
  -exportPath /tmp/MetTracker-export \
  -exportOptionsPlist AppStore/ExportOptions.plist -allowProvisioningUpdates
```

Verificado no `.ipa` exportado: `aps-environment` = `production`, ambiente do contentor
CloudKit = `Production`, `get-task-allow` = falso, `beta-reports-active` presente (TestFlight),
App Group e contentor iCloud nos entitlements, widget embebido, ícone incluído.

### Esquema do CloudKit em produção

O build de distribuição aponta ao ambiente **Production** do contentor. O SwiftData cria os
tipos de registo sozinho no ambiente **Development**, mas nunca em Production — esse tem de
ser promovido à mão no CloudKit Console. Enquanto não o for, a sincronização não funciona
para quem instalar a app da loja, e falha em silêncio.

1. Correr a app uma vez num dispositivo com build de desenvolvimento, gravando pelo menos
   um dia, para o esquema aparecer em Development
2. https://icloud.developer.apple.com → contentor `iCloud.com.bertobarata.salestracker`
3. Schema → **Deploy Schema to Production**


## Armadilha do `INFOPLIST_KEY_*`

As definições `INFOPLIST_KEY_<chave>` só são lidas quando é o Xcode a gerar o
Info.plist (`GENERATE_INFOPLIST_FILE = YES`). Este alvo usa um Info.plist próprio,
escrito pelo XcodeGen a partir do bloco `info:`, por isso todas as `INFOPLIST_KEY_*`
eram **ignoradas sem aviso nenhum** — o build passava, os testes passavam, e o
problema só apareceu na validação da Apple, depois do upload:

```
Invalid bundle. No orientations were specified in the
com.bertobarata.salestracker bundle.
```

Quatro chaves estavam em falta ou erradas no `.ipa` da build 1: orientações,
localizações, região de desenvolvimento (`en` em vez de `pt-PT`) e a versão, que
ficava fixa em 1.0 (1) por o Info.plist gerado levar valores literais.

**Regra para este projeto: chaves do Info.plist vivem no bloco `info: properties:`.**
As versões referenciam as variáveis, `$(MARKETING_VERSION)` e
`$(CURRENT_PROJECT_VERSION)`, senão subir a versão não muda o que vai no pacote.

Decidido ao mesmo tempo: `TARGETED_DEVICE_FAMILY = 1`, só iPhone. Suportar iPad
obrigaria às quatro orientações para multitarefa e a um conjunto próprio de
capturas de ecrã. A app continua a instalar em iPad em modo de compatibilidade.


## Armadilhas apanhadas a testar

**Um `ModelContainer` local não pode morrer antes do `ModelContext`.** O `EntryStore`
só guarda o contexto; se o contentor que o criou sair de âmbito, o primeiro `fetch`
rebenta dentro do SwiftData com `EXC_BREAKPOINT` — não com um erro apanhável. Nos testes
o contentor é guardado numa struct que vive tanto quanto o teste.

**A app é o hospedeiro dos testes unitários**, por isso arranca em cada execução. Sob
XCTest passa a usar base em memória, para não ficar a tentar ligar-se a uma conta iCloud
que não existe no simulador.

**Os testes de UI precisam de estado determinado.** Com gravação automática, o que uma
execução escreve fica no simulador e falseia a seguinte. Daí `--empty-store`,
`--skip-onboarding` e `--reset-onboarding`, todos dentro de `#if DEBUG`.
