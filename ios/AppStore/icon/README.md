# Ícone do MetTracker

Conceito: o **funil**. Quatro formas que estreitam, a última destacada do resto —
o contrato que sai. Sem texto, sem letras, sem réplicas de interface, como manda a HIG.

## Ficheiros

| Ficheiro | O que é |
|---|---|
| `layer-1-funil.svg` | camada de baixo: os três degraus do funil |
| `layer-2-contrato.svg` | camada de cima: o contrato que sai |
| `preview-1024.png` | versão achatada, já com o gradiente, 1024×1024 sem alfa |
| `preview.png` | a mesma a 480px e a 110px, para o teste de legibilidade |

O `preview-1024.png` está copiado para `Assets.xcassets/AppIcon.appiconset/`, por isso
a app já tem este ícone. Serve para submeter.

## Passar a Liquid Glass em camadas (Icon Composer)

O achatado funciona, mas não ganha os reflexos nem as variantes do sistema. Para isso:

1. Abrir o **Icon Composer** (vem com o Xcode; também está em developer.apple.com)
2. Novo ícone, plataforma iOS
3. **Background** → gradiente linear, de `#2F86F6` a `#0A2A63`, a 150°
4. Importar `layer-1-funil.svg` como camada
5. Importar `layer-2-contrato.svg` como camada por cima
6. Baixar a opacidade da camada 1 para uns 85% — a HIG recomenda variar opacidade
   entre camadas para dar profundidade
7. Ver as variantes **default, dark, clear e tinted** e ajustar o que destoar
8. Exportar como `MetTracker.icon` para `ios/SalesTracker/Resources/Assets.xcassets/`
9. Apagar o `AppIcon.appiconset` e pôr `ASSETCATALOG_COMPILER_APPICON_NAME: MetTracker`
   no `project.yml`

**Não** aplicar máscara de cantos arredondados nas camadas: é o sistema que a aplica, e
uma camada já mascarada estraga os reflexos e deixa as arestas serrilhadas.
