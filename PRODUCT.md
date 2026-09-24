# Product

## Register

product

## Users

Consultores, comerciais e gestores de carteira que trabalham por objetivos e reportam
atividade semanal. Uma pessoa, a ver o próprio dia. Nunca um gestor a ver uma equipa.

Contexto de uso: ao fim do dia, de pé ou no carro, telemóvel na mão, trinta segundos de
paciência. E uma segunda sessão ao fim da semana, sentado, a fechar os números e a preparar
o relatório para enviar.

A tarefa é sempre a mesma: escrever nove números, ver como estão face aos objetivos, e sair.

## Product Purpose

Quem trabalha à comissão mede-se pelos contratos fechados, que é um sinal atrasado — quando
o mês mau se vê, a atividade que o causou aconteceu semanas antes. O que prevê o resultado
são contactos feitos e reuniões marcadas, e é isso que ninguém regista.

A app regista essa atividade diária, agrega por semana e por mês, compara com objetivos que
o próprio define, e gera o relatório pronto a enviar.

Sucesso é o registo demorar menos do que adiá-lo. Se o utilizador hesitar antes de abrir a
app, a app falhou.

## Brand Personality

Técnico e denso. Muitos números à vista ao mesmo tempo, pouca navegação, pouco espaço
desperdiçado. Mais perto de um painel de operações do que de uma app de hábitos.

Denso não é o mesmo que corporativo. A densidade aqui serve uma pessoa a ler os próprios
números de relance; não serve hierarquias, permissões nem vistas de equipa. A diferença está
na quantidade de decisões, não na quantidade de dados: muitos dados, poucas decisões.

Voz: direta, segunda pessoa do singular, português de Portugal. Sem exclamações de
encorajamento, sem parabéns. O facto basta.

## Anti-references

- **Dashboard SaaS genérico azul e cinzento.** É o que a app é hoje: `#2563eb` sobre slate,
  grelhas de cartões idênticos com número grande e label maiúsculo. Reflexo de categoria.
- **CRM corporativo (Salesforce, HubSpot).** Denso pelas razões erradas: separadores,
  configuração, vistas de equipa, relatórios para outra pessoa ler.
- **App de fitness gamificada.** Medalhas, streaks, confetes. Transforma trabalho em jogo e
  trata o utilizador como criança.
- **Rede social ou feed.** Scroll infinito, cartões sucessivos, conteúdo de terceiros. Nada
  aqui é social e nada aqui se descobre por scroll.

## Design Principles

1. **O número é o interface.** O valor vem primeiro, o rótulo depois e mais pequeno. Nada de
   decoração à volta de dados que falam sozinhos.
2. **Densidade sem decisões.** Mostrar tudo o que cabe, pedir o mínimo. Cada ecrã tem uma
   ação óbvia e o resto é leitura.
3. **Escrever tem de ser mais rápido do que adiar.** O caminho até gravar um dia mede-se em
   toques. Qualquer coisa que o alongue paga-se a si própria ou sai.
4. **Uma superfície, um vocabulário.** O mesmo botão, o mesmo campo, a mesma folha em todos
   os ecrãs. Surpresa aqui é defeito, não personalidade.
5. **O dispositivo decide, não o user-agent.** Toque grosso recebe teclado próprio e alvos
   grandes; rato recebe campos nativos. A pergunta é sobre o ponteiro, nunca sobre a marca
   do telemóvel.

## Accessibility & Inclusion

WCAG 2.2 AA como chão, mais movimento reduzido.

- Contraste mínimo 4.5:1 para texto normal, nos dois temas. O tema escuro já passa; o claro
  falha em `--text-muted` e `--success`.
- Foco visível em todos os elementos interativos, com `:focus-visible`.
- Alvos de toque de 44×44 mínimo nos gestos repetidos (steppers, seletor de dia, navegação
  de semana).
- `prefers-reduced-motion: reduce` desliga transições e animações de barra de progresso.
- Interface em português de Portugal, `lang="pt-PT"`.
