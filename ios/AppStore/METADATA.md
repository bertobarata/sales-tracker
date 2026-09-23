# MetTracker — metadados da App Store

Copiar campo a campo para o App Store Connect. Idioma principal: **Português (Portugal)**.

## Identificação

| Campo | Valor | Limite |
|---|---|---|
| Nome | `MetTracker` | 30 |
| Subtítulo | `Registo diário de atividade` | 30 |
| Bundle ID | `com.bertobarata.salestracker` | — |
| SKU | `METTRACKER-IOS-001` | — |
| Categoria principal | Negócios | — |
| Categoria secundária | Produtividade | — |
| Classificação etária | 4+ | — |
| Preço | Grátis | — |
| Direitos de autor | `2026 Berto Barata` | — |

> **Aviso sobre o nome.** "Met" pode ser lido como associação à MetLife. A Guideline 5.2.1
> permite à Apple recusar nomes que sugiram ligação a marca de terceiros. Se a submissão for
> travada por esse motivo, muda-se só este campo — o bundle ID e o binário não mudam.
> Alternativas já pensadas: Consultrack, Trackmet, Prospeto.

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
O MetTracker é um registo diário de atividade comercial para quem trabalha por objetivos.

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

Em inglês de propósito: a interface é portuguesa e isso está declarado, mas o argumento
contra a Guideline 4.2 não pode depender de tradução automática para ser entendido.

```
HOW TO TEST

No account or credentials are required. The app opens straight into the daily entry screen.

The database starts empty. To see the app with content, type numbers on the "Hoje" (Today) tab — entries save themselves, there is no save button — then open "Semana" (Week), "Relatório" (Report) and "Tendências" (Trends), which fill in immediately.

On first launch a short onboarding explains the sales funnel the app tracks. Its fifth page offers to enable two daily reminders; accepting shows the standard iOS notification permission prompt. Declining is fine and the app works the same.

The widget and Control Center control can be added from the Home Screen and Control Center as usual. Siri shortcuts appear under the app in the Shortcuts app.

WHAT THIS APP IS

A daily activity tracker for salespeople who work to targets. It records nine activity metrics per day, aggregates them by week and by a configurable monthly closing period, generates a weekly text report, exports CSV, and charts trends over one, three or six months.

It is free, has no in-app purchases, no advertising and no analytics. iPhone only, by design.

DATA AND PRIVACY

There is no server. Data is stored locally with SwiftData and synced through CloudKit to the user's own private iCloud database. The developer has no access to it and receives no copy. This is why the app has no sign-in, offers no third-party login, and has no in-app account deletion — guidelines 4.8, 5.1.1 and 5.1.1(v) do not apply. The App Privacy answer is "Data Not Collected" for the same reason.

ON GUIDELINE 4.2

This is not a web wrapper or a list of links. It implements structured daily entry of nine metrics, user-defined daily checklist items, weekly and monthly aggregation against configurable targets, a configurable month-closing day, weekly report generation, CSV export, trend charts, two widgets, a Control Center control, App Intents for Siri, and two daily local notifications that are skipped on days already recorded.

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
