---
name: Sales Tracker
description: Registo diário de atividade comercial, lido como um painel de instrumentos.
colors:
  ink: "oklch(0.24 0.014 80)"
  ink-muted: "oklch(0.5 0.014 80)"
  paper: "oklch(0.975 0.006 80)"
  paper-raised: "oklch(0.955 0.008 80)"
  paper-surface: "oklch(0.995 0.004 80)"
  rule: "oklch(0.9 0.01 80)"
  signal: "oklch(0.52 0.16 292)"
  signal-strong: "oklch(0.44 0.16 292)"
  signal-wash: "oklch(0.94 0.03 292)"
  positive: "oklch(0.5 0.13 150)"
  caution: "oklch(0.52 0.11 70)"
  negative: "oklch(0.52 0.17 25)"
  ink-dark: "oklch(0.95 0.006 80)"
  ink-muted-dark: "oklch(0.74 0.012 80)"
  paper-dark: "oklch(0.18 0.01 80)"
  paper-raised-dark: "oklch(0.27 0.012 80)"
  paper-surface-dark: "oklch(0.225 0.011 80)"
  rule-dark: "oklch(0.33 0.012 80)"
  signal-dark: "oklch(0.74 0.13 292)"
  signal-strong-dark: "oklch(0.82 0.11 292)"
  signal-wash-dark: "oklch(0.3 0.06 292)"
  positive-dark: "oklch(0.78 0.15 150)"
  caution-dark: "oklch(0.8 0.13 70)"
  negative-dark: "oklch(0.7 0.15 25)"
typography:
  display:
    fontFamily: "ui-monospace, SFMono-Regular, 'SF Mono', Menlo, monospace"
    fontSize: "2rem"
    fontWeight: 600
    lineHeight: 1
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "1.25rem"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.01em"
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "1rem"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "normal"
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "0.9375rem"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "normal"
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "0.06em"
  numeric:
    fontFamily: "ui-monospace, SFMono-Regular, 'SF Mono', Menlo, monospace"
    fontSize: "1rem"
    fontWeight: 600
    lineHeight: 1
    letterSpacing: "normal"
rounded:
  sm: "6px"
  md: "10px"
  lg: "14px"
  pill: "999px"
spacing:
  hair: "2px"
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  xxl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.signal}"
    textColor: "{colors.paper-surface}"
    typography: "{typography.title}"
    rounded: "{rounded.md}"
    padding: "13px 20px"
    height: "48px"
  button-primary-hover:
    backgroundColor: "{colors.signal-strong}"
    textColor: "{colors.paper-surface}"
  button-secondary:
    backgroundColor: "{colors.paper-surface}"
    textColor: "{colors.signal}"
    typography: "{typography.title}"
    rounded: "{rounded.md}"
    padding: "11px 20px"
    height: "44px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.ink-muted}"
    typography: "{typography.body}"
    rounded: "{rounded.sm}"
    padding: "12px 8px"
  stepper-button:
    backgroundColor: "{colors.paper-raised}"
    textColor: "{colors.signal}"
    rounded: "{rounded.sm}"
    size: "44px"
  stepper-value:
    backgroundColor: "{colors.paper-surface}"
    textColor: "{colors.ink}"
    typography: "{typography.numeric}"
    rounded: "{rounded.sm}"
    height: "44px"
    width: "52px"
  metric:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    typography: "{typography.display}"
    padding: "0"
  metric-label:
    backgroundColor: "transparent"
    textColor: "{colors.ink-muted}"
    typography: "{typography.label}"
  panel:
    backgroundColor: "{colors.paper-surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: "16px"
  sheet:
    backgroundColor: "{colors.paper-surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: "20px 16px"
  tab:
    backgroundColor: "transparent"
    textColor: "{colors.ink-muted}"
    typography: "{typography.label}"
    padding: "10px 8px"
    height: "52px"
  tab-active:
    backgroundColor: "transparent"
    textColor: "{colors.signal}"
  field:
    backgroundColor: "{colors.paper-surface}"
    textColor: "{colors.ink}"
    typography: "{typography.numeric}"
    rounded: "{rounded.sm}"
    padding: "10px"
    height: "44px"
---

# Design

## Overview

**O Painel de Operações.**

A app é lida, não explorada. Alguém abre-a ao fim do dia, olha três segundos, escreve nove
números e fecha. Ao domingo à noite volta, sentado, para fechar a semana. Em nenhum dos dois
momentos há descoberta: o utilizador já sabe o que vem ver.

Isso dita tudo. Os números vêm primeiro e grandes, os rótulos vêm depois e pequenos, e o
espaço entre eles é o mínimo que os mantém legíveis. Densidade é a proposta, não um efeito
secundário: quantos mais valores couberem num ecrã sem obrigar a decidir nada, melhor.

Densidade não é confusão. A regra prática é *muitos dados, poucas decisões*. Cada ecrã tem
uma ação óbvia — gravar o dia, copiar o relatório — e tudo o resto é leitura.

O sistema é quase monocromático: papel quente, tinta escura, e uma única cor de sinal em
violeta que nunca passa de uma fração da superfície. O violeta existe para dizer três coisas
e mais nenhuma: isto é o valor, isto está selecionado, isto é a ação principal.

Anti-referências, em direto: nada de azul sobre cinzento-ardósia, que é o reflexo de
categoria; nada de separadores de CRM; nada de medalhas nem celebrações; nada que se
descubra por scroll.

## Colors

Estratégia: **Restrained**. Neutros com matiz, um acento abaixo de 10% da superfície.

Os neutros são quentes, com matiz 80 e croma entre 0.004 e 0.014 — o suficiente para o
branco deixar de ser branco e o preto deixar de ser preto, sem que ninguém consiga nomear a
cor. O acento é violeta a 292, escolhido por ficar longe do vermelho, do âmbar e do verde,
que estão reservados para significado. Papel quente contra sinal frio é o par que dá
identidade ao conjunto.

OKLCH é a fonte de verdade, para coincidir com o que está no CSS. Os hex ao lado são o
sRGB calculado, só para ferramentas que não leem OKLCH — não editar nenhum sem recalcular o
outro.

**Tema claro**

| Papel | Token | OKLCH | sRGB |
|---|---|---|---|
| Fundo da app | `--bg` | `0.975 0.006 80` | `#f9f6f2` |
| Superfície de painel | `--surface` | `0.995 0.004 80` | `#fffdfa` |
| Faixa interna | `--raised` | `0.955 0.008 80` | `#f3f0ea` |
| Régua | `--border` | `0.9 0.01 80` | `#e1ddd7` |
| Tinta | `--text` | `0.24 0.014 80` | `#231f18` |
| Tinta secundária | `--text-muted` | `0.5 0.014 80` | `#67635a` |
| Sinal | `--primary` | `0.52 0.16 292` | `#6d52bc` |
| Sinal premido | `--primary-dark` | `0.44 0.16 292` | — |
| Lavagem de sinal | `--primary-light` | `0.94 0.03 292` | — |
| Positivo | `--success` | `0.5 0.13 150` | `#137738` |
| Atenção | `--warning` | `0.52 0.11 70` | `#915c08` |
| Negativo | `--danger` | `0.52 0.17 25` | `#b63132` |

**Tema escuro**

| Papel | OKLCH | sRGB |
|---|---|---|
| Fundo | `0.18 0.01 80` | `#14110d` |
| Superfície | `0.225 0.011 80` | `#1e1b16` |
| Faixa | `0.27 0.012 80` | `#2a2620` |
| Régua | `0.33 0.012 80` | `#39352f` |
| Tinta | `0.95 0.006 80` | `#f1eeea` |
| Tinta secundária | `0.74 0.012 80` | `#afaaa3` |
| Sinal | `0.74 0.13 292` | `#ad9bf6` |
| Positivo | `0.78 0.15 150` | `#67d283` |
| Atenção | `0.8 0.13 70` | `#f3ae58` |
| Negativo | `0.7 0.15 25` | `#ed756e` |

Contraste verificado por cálculo, não por estimativa. O pior par de cada tema:
`--text-muted` sobre `--raised` dá **5.27:1** no claro e **6.53:1** no escuro. Texto normal
sobre `--primary` dá **5.80:1** no claro e **7.86:1** no escuro. Todos os valores estão
dentro do gamut sRGB.

Uma regra que nasce do cálculo: **nunca pôr texto sobre `--border`.** É uma régua, não uma
superfície. Texto secundário sobre ela dá 4.09:1 e falha. Quando for preciso um fundo para
texto pequeno, usar `--raised`.

## Typography

Uma família de sistema para interface, uma monoespaçada para números. É a única dualidade do
sistema e existe por uma razão concreta: as colunas de valores têm de alinhar, e um dígito
não pode mudar de largura quando passa de 9 para 11.

Escala fixa em rem, razão ~1.2, sem `clamp`. O utilizador vê isto sempre à mesma distância.

| Papel | Tamanho | Peso | Uso |
|---|---|---|---|
| `display` | 2rem | 600 mono | Valor de métrica, total da semana |
| `headline` | 1.25rem | 700 | Título de ecrã |
| `title` | 1rem | 700 | Cabeçalho de painel, texto de botão |
| `body` | 0.9375rem | 400 | Rótulo de linha, texto corrido |
| `numeric` | 1rem | 600 mono | Valor em campo e em stepper |
| `label` | 0.75rem | 600, `0.06em` | Rótulo de métrica, maiúsculas |

O piso é **0.75rem**. Hoje há texto a 0.6rem e 0.62rem; abaixo de 12px nada disto se lê num
telemóvel ao fim do dia, e nenhum rácio de contraste compensa isso.

Números com `font-variant-numeric: tabular-nums`.

## Elevation

**Plano, com camadas tonais.** Não há sombras em superfícies em repouso.

A separação faz-se por três meios, por esta ordem de preferência: mudança de tom de fundo
(`--bg` → `--surface` → `--raised`), régua de 1px em `--border`, e espaço. Sombra fica
reservada ao que flutua de verdade: a folha do numpad e a das definições, que sobem por cima
do conteúdo e precisam de o dizer.

Isto resolve de raiz o problema que a auditoria apanhou. Quando a separação é tonal, não
existe cartão dentro de cartão — existe uma faixa mais clara dentro de um painel, que é
outra coisa e lê-se bem.

| Nível | Tratamento |
|---|---|
| Fundo | `--bg`, sem régua |
| Painel | `--surface`, régua de 1px, raio `lg` |
| Faixa dentro de painel | `--raised`, sem régua, raio `sm` |
| Folha sobreposta | `--surface`, raio `lg` em cima, sombra ambiente, véu por trás |

## Components

**Vocabulário único.** O mesmo botão, o mesmo campo, a mesma folha em todos os ecrãs. O
numpad aparece sempre como folha vinda de baixo, nunca substituindo a vista.

**Estados.** Todo o elemento interativo tem os sete: repouso, passagem, foco, premido,
desativado, a carregar, erro. Foco é sempre `:focus-visible` com anel de 2px em `--primary`
e 2px de afastamento, em todo o lado, sem exceção.

Desativado nunca se comunica só por opacidade. Opacidade a 0.2 não passa contraste nenhum e
não diz ao leitor de ecrã o que se passa: usar o atributo `disabled`, tom `--text-muted` e
`aria-disabled`.

**Alvos de toque:** 44×44 mínimo em tudo o que se toca, sem exceção nos gestos repetidos —
steppers, seletor de dia, navegação de semana. É a interação mais frequente da app.

**Métrica.** Valor em `display` monoespaçado, rótulo em `label` por baixo, sem caixa à
volta. Uma grelha de métricas é uma grelha de números com réguas entre eles, não uma fila de
cartões.

**Barra de progresso.** Trilho em `--border`, enchimento em `--primary`, ou `--success` ao
atingir o objetivo. Altura de 8px, raio `pill`. A percentagem também é dita em texto, porque
cor sozinha não é informação.

**Folhas.** `role="dialog"`, `aria-modal="true"`, foco preso dentro, Escape fecha, o foco
volta ao elemento que a abriu, e o fundo não faz scroll.

**Ícones.** Um só vocabulário. Emoji não é vocabulário: muda de forma em cada plataforma e é
lido em voz alta pelos leitores de ecrã. Onde houver emoji, ou vai SVG, ou vai texto, ou vai
`aria-hidden`.

**Movimento.** 150 a 200ms, `ease-out`. Só transições de cor, opacidade e transformação —
nunca propriedades de layout. Sob `prefers-reduced-motion: reduce`, tudo a 0.01ms.

## Do's and Don'ts

**Do**

- Pôr o número primeiro e o rótulo a seguir, mais pequeno.
- Separar por tom e por régua de 1px antes de pensar em caixa.
- Usar monoespaçada em tudo o que seja valor numérico, com `tabular-nums`.
- Manter o acento abaixo de 10% da superfície: valor, seleção, ação principal.
- Perguntar ao ponteiro (`pointer: coarse`), nunca ao user-agent.
- Dizer o estado por texto além da cor.
- Verificar contraste por cálculo antes de aceitar uma cor.

**Don't**

- Cartão dentro de cartão. Se um painel precisa de secções, são faixas em `--raised`.
- `border-left` colorido como acento. É o tell mais reconhecível que existe.
- Texto sobre `--border`.
- Texto abaixo de 0.75rem.
- Emoji como ícone de interface.
- Azul sobre cinzento-ardósia. É o que isto era.
- Desativar por `opacity: 0.2` inline.
- `transition: all`.
- Gradiente em texto, vidro fosco decorativo, medalhas, confetes.
