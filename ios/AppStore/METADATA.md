# Meet Tracker — metadados da App Store

Copiar campo a campo para o App Store Connect. Idioma principal: **Português (Portugal)**.

## Identificação

| Campo | Valor | Limite |
|---|---|---|
| Nome | `Meet Tracker` | 30 |
| Subtítulo | `Registo diário de atividade` | 30 |
| Bundle ID | `com.bertobarata.salestracker` | — |
| SKU | `METTRACKER-IOS-001` | — |
| Categoria principal | Negócios | — |
| Categoria secundária | Produtividade | — |
| Classificação etária | 4+ | — |
| Preço | Grátis | — |
| Direitos de autor | `2026 Berto Barata` | — |

> **A app chamava-se MetTracker.** Renomeada para `Meet Tracker` na build 5, a 2026-09-24.
> "Met" podia ser lido como associação à MetLife, e a Guideline 5.2.1 permite à Apple recusar
> nomes que sugiram ligação a marca de terceiros. A rejeição que motivou a mudança foi outra
> (2.1, ver secção no fim), mas o ponto 6 dessa carta pergunta por autorização para material
> de terceiros — respondê-lo com o nome antigo era convidar a pergunta seguinte.
>
> "Meet" é de reuniões, que é o que a app conta. O nome ficou mais descritivo e o risco saiu.
>
> Por baixo do ícone fica `MeetTracker`, sem espaço: 11 caracteres não truncam, 12 truncam.
> **O bundle ID, o App Group e o contentor CloudKit não mudaram** — mudá-los partia a
> sincronização de quem já tivesse dados. O SKU também não: é imutável e só interno.

## URLs

| Campo | Valor |
|---|---|
| Privacy Policy URL | `https://baratastudio.com/mettracker-privacidade.html` |
| Support URL | `https://baratastudio.com/mettracker.html` |
| Marketing URL | `https://baratastudio.com` (opcional) |

## Texto promocional (170)

```
Fecha a semana em dois minutos: os números do dia, o progresso face aos objetivos e o relatório pronto a enviar.
```

## Descrição

```
O Meet Tracker é um registo diário de atividade comercial para quem trabalha por objetivos.

Ao fim do dia, escreve os números: contactos efetuados, reuniões marcadas, reuniões realizadas, pesquisas e referências. A aplicação trata do resto — soma a semana, compara com os objetivos que definiu e prepara o relatório para enviar.

Uma introdução no primeiro arranque explica o funil e porque é que contar só os contratos fechados dá o alarme tarde de mais.

O QUE FAZ

• Registo diário das nove métricas de atividade, com teclado numérico e um toque por incremento
• Guarda sozinho: muda de separador a meio e não se perde nada
• Tarefas diárias de sim/não, com os nomes que o utilizador quiser
• Painel da semana com progresso face aos objetivos que o próprio define
• Objetivo mensal de valor fechado, com o que falta sempre à vista
• Dia de fecho do mês configurável, para carteiras que não fecham no último dia
• Relatório semanal em texto, pronto a copiar para uma mensagem
• Exportação em CSV, para abrir no Numbers ou no Excel
• Tendências do último mês, de 3 ou de 6 meses em gráficos
• Widgets no ecrã principal e no ecrã bloqueado, com incremento direto
• Controlo no Centro de Controlo e atalhos para a Siri
• Dois lembretes por dia, só nos dias que ainda não registou
• Aspeto claro, escuro ou a seguir o sistema

SEM CONTA, SEM SERVIDOR

Não há registo nem início de sessão. A aplicação abre e está pronta a usar.

Os dados ficam no seu iPhone e, se tiver o iCloud ligado, sincronizam com os seus outros dispositivos pela sua base de dados privada do iCloud. Não passam por servidores nossos — não existe servidor nenhum. Não há publicidade, não há ferramentas de análise e não há bibliotecas de terceiros a enviar nada para fora do dispositivo.

PARA QUEM É

Para consultores, comerciais e gestores de carteira que reportam atividade semanal e preferem dois minutos por dia a uma folha de cálculo ao domingo à noite.

A aplicação é genérica: as métricas e os objetivos são os que definir, não estão presos a nenhuma empresa nem a nenhum modelo de negócio.
```

## Palavras-chave (100 caracteres, separadas por vírgula, sem espaços)

```
vendas,comercial,atividade,reuniões,objetivos,crm,prospeção,relatório,semanal,consultor,metas
```

Contagem: 91 caracteres.

## Notas de versão (1.0.0)

```
Primeira versão.
```

## Privacidade — respostas do questionário (App Privacy)

Resposta à primeira pergunta: **"Do you or your third-party partners collect data from this app?" → No.**

Isto produz a etiqueta **"Data Not Collected"** e dispensa todo o resto do questionário. É a resposta correta:

- Os dados escritos pelo utilizador ficam no dispositivo e na base de dados **privada** do iCloud dele.
- Dados guardados no iCloud privado do utilizador, sem acesso do programador, **não contam como recolha** para efeitos deste questionário.
- Não há SDK de terceiros, publicidade, análise de utilização nem identificadores enviados para fora.

## Notas para a equipa de revisão (App Review Information)

Este é o texto que vai no campo Notes **e** que foi enviado como resposta à rejeição 2.1 de
2026-09-24 (ver a secção no fim). A Apple pediu explicitamente que a informação ficasse nas
Notes, para servir de referência a submissões futuras.

Em inglês de propósito: a interface é portuguesa e isso está declarado, mas nem o argumento
contra a Guideline 4.2 nem as seis respostas podem depender de tradução automática.

```
NOTE ON THE APP NAME

The app was renamed from "MetTracker" to "Meet Tracker". "Meet" refers to meetings,
which are the core of what the app counts. The app has no affiliation with any
insurance company or any other third party, and contains no third-party material.
The bundle identifier is unchanged.

1. SCREEN RECORDING

   <LINK>

   Recorded on an iPhone 17 Pro running the current release of iOS, starting from the
   app launch, using the same build submitted for review.

   The three flows listed in your request do not exist in this app and therefore do not
   appear in the recording:
   - No account registration, login, or account deletion. The app creates no account of
     any kind and has no sign-in of any kind (see items 3 and 4).
   - No user-generated content shared with or visible to other users. The app is
     single-user; no data ever leaves the user's own device and private iCloud account.
   - No paid content, no in-app purchases, no subscriptions, no advertising.

   The recording instead shows the complete typical flow: first-launch onboarding,
   daily entry, settings and goals, the weekly dashboard, the weekly report and CSV
   export, the trend charts, and the widget, Control Center control and Siri shortcuts.

2. PURPOSE AND TARGET AUDIENCE

   Meet Tracker is a daily activity tracker for salespeople who work to targets.

   The problem: people in commission-based sales usually measure themselves by closed
   deals, which is a lagging signal - by the time a bad month is visible, the activity
   that caused it happened weeks earlier. The activity that predicts the result is
   calls made and meetings booked, and that is what usually goes unrecorded.

   What the app does: at the end of the day the user types the numbers for that day -
   contacts made, first, second and third meetings booked, the same three actually
   held, prospecting done, referrals received. The app aggregates them by week and by a
   configurable monthly closing period, compares them against targets the user sets,
   produces a weekly text report ready to paste into a message, exports CSV, and charts
   trends over one, three or six months.

   Target audience: independent salespeople, consultants and portfolio managers who
   report weekly activity and would rather spend two minutes a day than an hour with a
   spreadsheet on Sunday night. The metrics and targets are user-defined and are not
   tied to any company, employer or business model.

   This is not an employee or enterprise app. It is not distributed by, commissioned by
   or built for any organization, and it contains nothing specific to one. Guideline 3.2
   does not apply.

3. SETUP AND ACCESS

   No credentials are needed and none can be provided, because the app has no accounts.
   It opens straight into the daily entry screen and is usable immediately.

   On a fresh install the database is empty. To see the app with content, type numbers
   on the "Hoje" (Today) tab - entries save themselves, there is no save button - then
   open "Semana" (Week), "Relatorio" (Report) and "Tendencias" (Trends), which fill in
   immediately. Trends are more informative once several days exist.

   On first launch a short onboarding explains the sales funnel the app tracks. Its
   fifth page offers to enable two daily reminders; accepting shows the standard iOS
   notification permission prompt. Declining is fine and the app works the same.

   Goals, the monthly closing day, the checklist items and the appearance are all in
   Settings, reachable from the toolbar on every tab.

   The widget and the Control Center control are added from the Home Screen and Control
   Center as usual. Siri shortcuts appear under the app in the Shortcuts app.

4. EXTERNAL SERVICES, TOOLS AND PLATFORMS

   None. There are no third-party services of any kind in this app:

   - No data providers
   - No authentication service (there is no sign-in at all)
   - No payment processor (the app is free and sells nothing)
   - No AI services
   - No analytics, no crash reporting, no advertising, no attribution SDK
   - No third-party frameworks or libraries whatsoever. The Xcode project contains zero
     Swift Package Manager dependencies and no CocoaPods.

   The app uses only Apple frameworks: SwiftUI, SwiftData, CloudKit, WidgetKit,
   UserNotifications, App Intents and Swift Charts.

   There is no server of ours at any point in the app's operation. Data is stored
   locally with SwiftData and synced through CloudKit to the user's own private iCloud
   database. The developer has no access to it and receives no copy of it. This is why
   the app has no sign-in, offers no third-party login, has no in-app account deletion,
   and why the App Privacy answer is "Data Not Collected". Guidelines 4.8, 5.1.1 and
   5.1.1(v) do not apply.

5. REGIONAL DIFFERENCES

   There are none. The app behaves identically in every region. There is no
   region-gated content, no regional pricing, no geo-restricted feature and no
   server-side configuration of any kind - there is no server.

   The interface is in Portuguese (Portugal) only, and that is declared in the
   metadata. The app is free worldwide.

6. REGULATED INDUSTRY AND THIRD-PARTY MATERIAL

   The app does not operate in a regulated industry and contains no protected
   third-party material.

   It is a personal productivity counter. The user types numbers describing their own
   working day into their own device. The app gives no financial, insurance, legal,
   investment or medical advice, sells nothing, processes no transactions, handles no
   money, and connects to no financial institution or third-party data source.

   It contains no third-party trademarks, logos, brand names, licensed content or data
   feeds. The app icon and all artwork are original work by the developer. The app name
   is generic and descriptive, as explained at the top of these notes.

ON GUIDELINE 4.2

This is not a web wrapper or a list of links. It implements structured daily entry of
nine metrics, user-defined daily checklist items, weekly and monthly aggregation against
configurable targets, a configurable month-closing day, weekly report generation, CSV
export, trend charts, two widgets, a Control Center control, App Intents for Siri, and
two daily local notifications that are skipped on days already recorded.

Interface language: Portuguese (Portugal).
```

**Não pôr roadmap aqui.** Estas notas são lidas por quem decide sobre *esta* build. Anunciar
contas, iPad ou importação futura só levanta perguntas sobre o que a versão atual faz ou
deixa de fazer — e a 4.2 é precisamente o risco que não se quer acordar. O roadmap vive no
`LANCAMENTO.md` e na memória do projeto.

## Capturas de ecrã

`ios/AppStore/screenshots/6.9/` — seis imagens 1320×2868, geradas no simulador
iPhone 17 Pro Max com dados de demonstração:

| Ficheiro | Ecrã |
|---|---|
| `00-introducao.png` | primeiro ecrã da introdução |
| `01-funil.png` | o funil explicado |
| `02-hoje.png` | registo do dia |
| `03-semana.png` | progresso face aos objetivos |
| `04-relatorio.png` | relatório semanal |
| `05-tendencias.png` | gráficos de tendência |

Para regenerar:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd ios
xcrun simctl boot E528BB9A-81F6-42A5-911F-26955A8AB1C0
xcrun simctl status_bar E528BB9A-81F6-42A5-911F-26955A8AB1C0 override \
  --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
xcodebuild test -project SalesTracker.xcodeproj -scheme SalesTracker \
  -destination 'id=E528BB9A-81F6-42A5-911F-26955A8AB1C0' \
  -only-testing:SalesTrackerUITests/ScreenshotTests \
  -resultBundlePath /tmp/st-shots.xcresult
xcrun xcresulttool export attachments --path /tmp/st-shots.xcresult --output-path /tmp/st-att
```

O 6.9" é o tamanho que o App Store Connect pede para iPhone e serve de base para os tamanhos
menores. Confirmar no ecrã de upload se pede também 6.5" — se pedir, o mesmo teste corre num
simulador iPhone 11 Pro Max e produz 1242×2688.

## Histórico de revisão

### 1.0.0 (4) — rejeitada a 2026-09-24, Guideline 2.1 Information Needed

Submission ID `9a80991b-2177-4d88-ab31-4e9ca4d56b55`, submetida a 2026-09-23.

Não foi um bug nem uma falha de conformidade: é a carta padrão para contas de programador
com histórico de revisão limitado. Pede seis blocos de informação e uma gravação de ecrã
feita em dispositivo físico, a começar no arranque da app. O bloco "Prevent Common Issues"
no fim da carta é boilerplate — aparece em todas estas cartas e não aponta nada de concreto.

Os seis pontos pedidos: (1) gravação de ecrã, (2) propósito e público-alvo, (3) instruções
de acesso e credenciais, (4) serviços externos usados, (5) diferenças regionais, (6)
indústria regulada ou material protegido de terceiros.

Resposta: o texto completo está no bloco das Notas para a equipa de revisão, acima.
Foi enviado na página do App Review e colado no campo Notes, como a Apple pediu.

Decidido ao mesmo tempo, e a razão de existir uma build 5: renomear para `Meet Tracker`.
O ponto 6 pergunta por autorização para material de terceiros, e responder-lhe com um nome
que podia ser lido como MetLife era convidar a pergunta seguinte. Ver o aviso na secção de
Identificação.

O vídeo grava-se **com a build 5 pelo TestFlight**, não com a 4: a Apple pediu a gravação da
app a correr, e com a listagem a dizer "Meet Tracker" e o ícone a dizer "MetTracker" a
incoerência aparecia no próprio vídeo (Guideline 2.3.7).
