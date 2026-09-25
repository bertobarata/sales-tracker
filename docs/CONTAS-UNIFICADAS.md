# Contas unificadas e sincronismo entre plataformas — plano para a 1.1

Decisão de 2026-09-25: a **1.0 sai como está**, sem contas na app iOS. Este documento é o
plano da versão seguinte, para começar em paralelo sem tocar na build que está em revisão.

---

## Porque é que isto não pode entrar na 1.0

A submissão em revisão descreve uma app sem contas e sem servidor. As notas que enviámos ao
App Review dizem, textualmente:

> There is no server. Data is stored locally with SwiftData and synced through CloudKit to
> the user's own private iCloud database. The developer has no access to it and receives no
> copy. This is why the app has no sign-in, offers no third-party login, and has no in-app
> account deletion.

Pôr login na app iOS contradiz isto e dispara quatro obrigações de uma vez:

| Gatilho | Guideline | O que passa a ser obrigatório |
|---|---|---|
| Existe login de terceiros (Google) | **4.8** | Oferecer Sign in with Apple ao lado, com paridade de funcionalidade |
| Existe criação de conta | **5.1.1(v)** | Apagar a conta **dentro da app**, não por email nem por formulário |
| Os dados passam a ir para o Firestore | App Privacy | Deixa de ser "Data Not Collected"; passa a declarar recolha |
| Passa a haver servidor do programador | Política | Reescrever a política de privacidade publicada |

Cada um destes é verificável pelo revisor. Entrar com eles a meio de uma ronda 2.1 já aberta
é convidar uma terceira.

---

## Estado atual: duas ilhas

| | PWA (web) | iOS 1.0 |
|---|---|---|
| Identidade | Firebase Auth, Google | nenhuma |
| Armazenamento | Firestore + localStorage | SwiftData + CloudKit privado |
| Sincroniza com a outra | não | não |

A decisão de as manter separadas está em `ios/LANCAMENTO.md`, de 2026-09-15. Foi correta na
altura: escolher CloudKit foi o que dispensou as guidelines 4.8, 5.1.1 e 5.1.1(v) e permitiu
responder "Data Not Collected". O preço é o que se quer agora resolver.

---

## A boa notícia: os esquemas já quase batem certo

Quem escreveu o iOS deixou isto preparado. O `DailyEntry.swift` diz:

> `dayKey` ("yyyy-MM-dd") é a identidade lógica e mantém o mesmo formato usado pela PWA,
> para migrações e exportações continuarem a bater certo.

E é verdade. As nove métricas diárias têm **os mesmos nomes** nos dois lados. Os campos
semanais também, `pessoasSeguras` incluído. As chaves são as mesmas: dia em `yyyy-MM-dd`,
semana pela segunda-feira.

O que diverge, e tem de ser decidido:

| Campo | Web | iOS | Resolução proposta |
|---|---|---|---|
| `updatedAt` | não existe | existe em ambos os modelos | **Adicionar à web.** Sem isto não há como resolver conflitos entre dispositivos |
| Checklist diária | não existe | `checklistDoneIDs` por dia + definição em `UserDefaults` | Subir ao Firestore; a web ganha o ecrã ou ignora o campo |
| Objetivos | 3 (1as, 2as, valor mensal) | 6 (+ 3as, contratos/semana, valor/semana) | iOS é superconjunto; a web adota os seis |
| Dia de fecho do mês | não existe | `monthCloseDay` | Subir; a web passa a respeitá-lo |
| Lembretes | um, `reminderTime` | dois, manhã e tarde | iOS é superconjunto |
| Aspeto | segue o sistema | claro/escuro/sistema | Fica local a cada plataforma, não sincroniza |

**Nada disto exige mudar o formato dos dados já gravados.** É acrescentar campos, não
reescrever registos.

---

## Arquitetura proposta

**Firebase Auth + Firestore como sistema de registo, nas três plataformas.**

```
Firebase Auth ──┬── Google         (web, iOS, Android)
                └── Apple          (web, iOS, Android)   ← obrigatório pela 4.8
                         │
                    users/{uid}/
                      daily/{yyyy-MM-dd}
                      weekly/{yyyy-MM-dd}       (segunda-feira)
                      settings/app
                      checklist/items
```

No iOS, o SwiftData **fica** como cache local e continua a servir offline e os widgets. Muda
o que está por baixo: em vez de sincronizar por CloudKit, escreve também para o Firestore e
ouve as alterações de volta. A app continua a abrir e a funcionar sem rede.

CloudKit sai. Não serve o objetivo: não há Android, e na web obrigaria toda a gente a ter
Apple ID.

**Resolução de conflitos:** última escrita ganha, por `updatedAt` ao nível do documento. Um
dia é um documento pequeno e escrito por uma pessoa só — não justifica nada mais fino.

---

## Migração de quem já usa a 1.0

Este é o ponto com mais risco, e não pode ser deixado para o fim.

Quem instalar a 1.0 acumula meses de dados em CloudKit privado. Se a 1.1 simplesmente
trocar de armazenamento, esses dados desaparecem do ecrã. Quem os perder não volta.

Fluxo proposto, no primeiro arranque da 1.1:

1. Detetar dados locais no SwiftData sem `uid` associado
2. Pedir para entrar (Google ou Apple), explicando que é para sincronizar entre dispositivos
3. Subir o que existe localmente para `users/{uid}/`, sem apagar o local
4. A partir daí, o Firestore é a fonte e o SwiftData é a cache

Quem recusar entrar fica a funcionar só no dispositivo. **Obrigar a entrar viola a 5.1.1**:
uma app que funciona sem conta não pode passar a exigir uma. A conta tem de ser opcional e
justificada pela sincronização.

Na web não há migração: os dados já estão em `users/{uid}/`, sob o mesmo Google.

---

## O que a Apple vai verificar

- **Sign in with Apple** presente ao lado do Google, com o mesmo alcance. Não chega estar no
  ecrã: tem de dar acesso às mesmas funcionalidades.
- **Apagar conta dentro da app**, num sítio encontrável, que apague mesmo os dados do
  servidor e não só a sessão. Um link para email não passa.
- **App Privacy** a declarar o que é recolhido e para quê. Deixa de ser "Data Not Collected".
- **Política de privacidade** atualizada no URL já publicado, a dizer que existe servidor,
  que dados guarda e como se apagam.
- **A app funciona sem conta**, senão a 5.1.1 bloqueia.

O vídeo de revisão passa a ter de mostrar registo, início de sessão **e** eliminação de conta
— os três fluxos que a carta 2.1 pediu e a que respondemos "não existem".

---

## Ordem de trabalho

Cada fase é útil por si e pode parar sem deixar nada meio feito.

1. **Web: Sign in with Apple ao lado do Google.** Sem tocar no iOS. Valida o fornecedor
   Apple no Firebase e o fluxo de duas contas para a mesma pessoa.
2. **Web: `updatedAt` em tudo o que se escreve.** Preparação para os conflitos, sem mudar
   comportamento nenhum hoje.
3. **Web: apagar conta.** Precisa de existir de qualquer forma, e é mais fácil de acertar na
   web do que no telemóvel.
4. **iOS: camada Firestore ao lado do SwiftData**, atrás de um interruptor, com CloudKit
   ainda ligado. Nada muda para o utilizador.
5. **iOS: login e migração**, com o fluxo acima.
6. **iOS: desligar o CloudKit**, notas de revisão e política novas, App Privacy refeita.
7. **Android**, quando houver. O backend já não dá trabalho nenhum nesta altura.

Estimativa honesta: as fases 1 a 3 são dias. As 4 a 6 são semanas, e a 5 é onde mora o risco.

---

## Decisões que faltam e são tuas

- **Contas separadas ou fundidas?** Se entrares com Google na web e com Apple no telemóvel,
  são duas contas com dois conjuntos de dados. O Firebase sabe ligar fornecedores à mesma
  conta, mas isso tem de ser desenhado — e explicado a quem usa.
- **A conta é opcional ou faz falta?** A minha leitura: opcional, e a app tem de continuar
  a valer a pena sem ela. É também o que a 5.1.1 exige.
- **Quem paga o Firestore?** Hoje é o plano gratuito e chega de sobra. Com três plataformas
  e utilizadores a sério, vale a pena saber onde fica o tecto antes de lá chegar.
