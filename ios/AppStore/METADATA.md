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
• Relatório semanal em texto, pronto a copiar para uma mensagem
• Exportação em CSV, para abrir no Numbers ou no Excel
• Tendências do último mês, de 3 ou de 6 meses em gráficos
• Widgets no ecrã principal e no ecrã bloqueado, com incremento direto
• Controlo no Centro de Controlo e atalhos para a Siri
• Lembrete diário, só nos dias que ainda não registou

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

```
Não é necessária conta nem credenciais: a aplicação abre diretamente no registo do dia.

A base de dados começa vazia. Para ver os ecrãs com conteúdo, basta escrever números no
separador "Hoje" e tocar em Guardar — os separadores Semana, Relatório e Tendências passam
a mostrar dados imediatamente.

A aplicação não tem servidor próprio. Os dados são guardados localmente com SwiftData e
sincronizados através do CloudKit, na base de dados privada do utilizador. O programador não
tem acesso a esses dados. Por isso não existe início de sessão, não é oferecido login de
terceiros e não há conta para eliminar dentro da aplicação — as guidelines 4.8, 5.1.1 e
5.1.1(v) não se aplicam.

Sobre a Guideline 4.2: a aplicação não é um invólucro de um site nem uma lista de ligações.
Implementa registo estruturado de nove métricas de atividade, agregação semanal com objetivos
configuráveis, geração de relatório em texto, exportação CSV, gráficos de tendência até 26
semanas, dois widgets, um control do Centro de Controlo, App Intents para a Siri e notificações
locais condicionadas aos dias por preencher.

Idioma da interface: português de Portugal.
```

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
