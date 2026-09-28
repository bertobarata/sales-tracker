# TODO

Três pedidos do Berto, 2026-09-28. **A PWA é o alvo**; o iOS acompanha. O objetivo por trás
dos três é o mesmo: contas unificadas, para trabalhar em qualquer lado — ver
[`CONTAS-UNIFICADAS.md`](CONTAS-UNIFICADAS.md).

Isso muda a ordem. Dois dos três itens guardam **preferências do utilizador**, e uma
preferência que não viaja entre dispositivos é pior do que não existir: configuras no
portátil, abres o telemóvel, está tudo como dantes.

---

## 0. O que tem de vir primeiro

Hoje as preferências vivem em `localStorage`, com quatro chaves e mais nada:

```js
// src/utils/settings.js:3
const DEFAULTS = {
  goalPrimeirasReunioesRealizadas: 10,
  goalSegundasReunioesRealizadas: 8,
  goalMensalValor: 5000,
  reminderTime: '18:30',
};
```

`saveSettings` escreve só no browser — ao contrário das entradas diárias, **as definições
nunca sincronizam**. Já é um bug hoje: quem usa a PWA em dois sítios tem objetivos
diferentes em cada um, sem aviso.

- [ ] **Sincronizar as definições pelo Firestore**, como `syncDailyEntry` já faz para os
      dias (`src/utils/sync.js:11`). É pré-requisito dos itens 2 e 3, e arruma um bug que já
      existe
- [ ] Decidir o que acontece a quem usa sem login — as definições ficam locais e só sobem
      quando houver conta

Só depois disto é que reordenar e esconder métricas valem a pena.

---

## 1. Botão de editar, em todos os separadores

São quatro separadores (`App.jsx:184-188`), e "editar" quer dizer uma coisa diferente em
cada um. Um botão com o mesmo nome a fazer quatro coisas distintas confunde mais do que
ajuda, por isso vale a pena nomear o que cada um faz antes de escrever código.

- [ ] **Hoje** (`DailyInput.jsx`) — já é todo de edição, com o `NumPad` por campo. O que
      falta não é editar, é **escolher que campos aparecem e por que ordem** → item 3
- [ ] **Semana** (`Dashboard.jsx`) — corrigir números de dias passados sem ter de voltar ao
      dia. É aqui que "editar" tem significado próprio e mais valor
- [ ] **Relatório** (`WeeklyReport.jsx`) — editar o texto antes de enviar, em vez de copiar
      e corrigir na app de mensagens. Hoje o texto é gerado e só se copia
- [ ] **Tendências** (`Trends.jsx`) — escolher que gráficos aparecem e por que ordem
- [ ] Padrão único: ou todos os separadores têm o mesmo afordance no mesmo sítio, ou
      nenhum tem. Metade com botão e metade com gesto é pior que qualquer das duas
- [ ] Alvo de toque de 44px, como o resto (`DESIGN.md`), e o botão não pode colidir com o
      ícone de definições que já está no cabeçalho

### iOS: já está escrito e está morto

```swift
// ios/SalesTracker/Views/SettingsView.swift:154-161
.onDelete { offsets in ... }
.onMove   { source, destination in ... }
```

O `ChecklistItem.swift:55` tem `move(fromOffsets:toOffset:)` e a ordem persiste. Mas **não
há `EditButton` nem `editMode` em parte nenhuma do projeto**, e em SwiftUI o `.onMove` só
funciona em modo de edição. As tarefas do dia sempre se puderam reordenar — falta uma linha.

- [ ] `EditButton()` na toolbar do `SettingsView`. É a coisa mais barata desta lista toda e
      devia ser a primeira a entrar

---

## 2. Reordenar, e esconder

A ordem dos nove campos está fixa no código, nas duas plataformas:

```js
// src/components/DailyInput.jsx:31
const FIELDS = [
  { key: 'contactos', label: 'Contactos efetuados' },
  ...
];
```

```swift
// ios/SalesTracker/Models/Metric.swift:5
enum Metric: String, CaseIterable, Identifiable, Sendable { case contactos ... }
```

Quem faz mais pesquisa do que reuniões quer as pesquisas em cima. Quem nunca faz terceiras
reuniões quer esse campo fora do ecrã.

- [ ] Guardar a ordem como array de chaves nas definições, com a ordem atual de `FIELDS`
      como omissão. Chaves desconhecidas ignoram-se; chaves em falta vão para o fim — assim
      uma métrica nova numa versão futura não parte a preferência de ninguém
- [ ] **Esconder métricas não usadas.** É o irmão natural do reordenar e encurta o ecrã
      Hoje, que é longo. Esconder nunca apaga dados: o campo escondido continua a somar
      zero e os números antigos mantêm-se
- [ ] `Dashboard`, `WeeklyReport` e `Trends` seguem a mesma ordem, senão a app contradiz-se
      entre separadores
- [ ] iOS: a mesma preferência, lida pelo widget e pelo control do Centro de Controlo
      através do App Group
- [ ] Reordenar com rato **e** com toque. `dnd-kit` ou HTML5 drag-and-drop puro; decidir
      antes de escrever, porque mistura mal com o scroll da lista no telemóvel
- [ ] Acessibilidade: arrastar tem de ter alternativa por teclado e por VoiceOver — subir
      e descer como ações, não só o gesto

**Decidido:** o ecrã segue a ordem do utilizador, o **CSV fica fixo**, com o cabeçalho a
nomear cada coluna. Um CSV que muda de colunas entre exportações parte qualquer folha de
cálculo construída por cima.

---

## 2b. Exportação: "está a exportar texto, não folha de cálculo"

Queixa do Berto, 2026-09-28, por diagnosticar. O que o código diz, antes de mexer:

- **PWA já gera `.xlsx` a sério.** `src/utils/report.js:24-57` importa o SheetJS
  dinamicamente e faz `writeFile(wb, 'historico_vendas.xlsx')`. Não é texto.
- **iOS gera CSV a sério.** `Core/CSVExport.swift` escreve ficheiro temporário com BOM
  (`\u{FEFF}`, para o Excel respeitar os acentos), colunas de `Metric.csvHeader`
  (`Metric.swift:63`), partilhado por `ShareLink`.

Ou seja, no papel os dois estão certos. Hipóteses para o que o Berto viu, por ordem de
probabilidade:

- [ ] **iOS: o `.csv` abre no visualizador de texto do iPhone**, não no Numbers. É
      comportamento do iOS, não bug da app — mas a experiência é a que ele descreve. Saída:
      exportar `.xlsx` também no iOS, ou dar `UTType` que o Numbers reclame por omissão
- [ ] **Confundiu os dois botões do Relatório.** `WeeklyReportView.swift:88-94` tem
      "Exportar histórico (CSV)" **e** "Preparar exportação CSV" — dois passos, dois
      rótulos parecidos. E ao lado está "Copiar texto", que copia mesmo texto
- [ ] Na PWA, o download do `.xlsx` falhou em silêncio nalgum browser
- [ ] **Confirmar com ele qual das duas apps e qual o botão** antes de escrever código

**Objetivo declarado:** colunas e folha de cálculo abrível direto, nas duas plataformas.
Provavelmente passa por unificar em `.xlsx` e deixar o CSV como opção secundária.

---

## 3. Espanhol

**Não há infraestrutura de i18n em lado nenhum**, nem na PWA nem no iOS. As frases estão
escritas à mão dentro dos componentes.

### PWA

- [ ] Escolher a abordagem. Sem framework, um módulo de dicionário com `t('chave')` chega;
      `react-i18next` traz negrito a mais para o tamanho desta app
- [ ] Extrair as strings dos JSX, incluindo os `label:` do `FIELDS` e os textos do
      `WeeklyReport`, que são os que o utilizador **envia a outras pessoas**
- [ ] Detetar o idioma do browser, com troca manual nas definições, e guardar a escolha na
      mesma preferência sincronizada do item 0
- [ ] Datas e números por `Intl`, não por formato fixo
- [ ] `<html lang>` acompanha o idioma escolhido — hoje está preso a `pt`

### iOS

- [ ] String Catalog (`Localizable.xcstrings`). São **107 literais distintos** em Swift
- [ ] `project.yml:50` só declara `pt-PT`; acrescentar `es`
- [ ] Widget e control são targets próprios e precisam de cobertura própria, senão ficam em
      português dentro de uma app espanhola
- [ ] `LogMetricIntent.swift` — `title` e `IntentDescription` são o que a **Siri lê em voz
      alta**; traduzir com cuidado, não à letra
- [ ] App Store Connect: localização `es-ES` com nome, subtítulo, descrição, palavras-chave
      e **screenshots em espanhol**. Sem screenshots próprias a Apple mostra as de pt-PT

### Comum às duas

- [ ] **Terminologia primeiro, tradução depois.** "1.ª reunião", "2.ª reunião" não decalcam
      para espanhol comercial. Fixar o vocabulário num sítio só e usar o mesmo nas duas
      plataformas
- [ ] Revisão por falante nativo. App de nicho comercial; tradução automática nota-se
- [x] **`es-ES`, espanhol de Espanha** — decidido pelo Berto. (`es-419` é o espanhol da
      América Latina: "móvil" vs "celular", "ordenador" vs "computadora", e outro mercado
      na ficha da loja. Não se faz.)
- [ ] Site: `mettracker.html` e `mettracker-privacidade.html` em espanhol, ou assumir
      suporte só em português

---

## Ordem sugerida

Encaixada nas fases do `CONTAS-UNIFICADAS.md`, cujas fases 1 a 3 são web e são dias:

1. `EditButton` no `SettingsView` do iOS — uma linha, desbloqueia código já escrito
2. **Definições a sincronizar pelo Firestore** (item 0) — desbloqueia tudo o resto e
   arruma um bug que já existe
3. Ordem e visibilidade das métricas na PWA, guardadas nessa preferência
4. Editar no Semana e no Relatório — os dois separadores onde "editar" significa algo
5. iOS a ler a mesma ordem, depois da fase 4 do plano de contas
6. Espanhol, começando pela terminologia e pela PWA

O espanhol fica para o fim de propósito: é o item com mais trabalho e o único que não
ganha nada em esperar pelas contas unificadas — mas é também o único que obriga a mexer em
todas as strings das duas bases de código, e isso faz-se melhor depois de os ecrãs
estabilizarem.
