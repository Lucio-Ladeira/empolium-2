# Mapas — versão para apresentação

Implementado em 18/10/2026, para Godot 4.7. Validado com Godot 4.7.2.

## Arquitetura encontrada e abordagem

O projeto tinha um único cenário de teste, TileMapLayers isométricos de 32 × 16, atlas de imagens com regiões de 32 × 32, jogador CharacterBody2D com câmera, quatro inimigos com NavigationAgent2D, combate corpo a corpo, tiros, respawn, drops e melhorias. NPCs, comércio, boss próprio e progressão não estavam implementados. O menu inicial existente era apenas uma cena vazia.

Foi escolhida geração procedural simples em grade, com salas retangulares, caminho principal monotônico e duas ramificações opcionais. Não é uma biblioteca de salas desenhadas à mão. Reutiliza os tilesets e as cenas existentes, sem dependências externas. A cena de teste original continua intacta e pode ser executada com F6.

## Jogar

- F5 inicia `res://scenes/mapas/mapa.tscn`.
- Movimentação, dash, espada e tiro mantêm os controles anteriores.
- M amplia/recolhe o minimapa. O mapa tem a mesma orientação isométrica do cenário.
- Branco identifica a sala mais próxima; vermelho identifica encontro ativo; verde identifica sala concluída. No mapa ampliado: I início, C combate, N apoio, L loja, B núcleo e P portal.
- Entre nas salas de combate para iniciar os encontros. As barreiras fecham durante os combates e abrem quando o último inimigo morre.
- Conclua todos os combates comuns e o encontro final do núcleo para ativar o portal.
- Vá até o portal e pressione E para gerar o próximo setor.
- Esc abre o pause. Dentro das melhorias, Esc volta ao pause normal.

A transição mantém moedas, inventário e equipamentos; recupera vida e estamina e posiciona o jogador na entrada do novo mapa. Os setores repetem essa estrutura, sem fim de campanha ou dificuldade progressiva nesta versão. Reabrir a partida começa um inventário novo: não foi adicionado save em disco.

## Geração e segurança

Por padrão são 3–4 salas comuns, além de entrada, núcleo, portal, apoio e loja: 8–9 salas ao todo. Cada sala comum recebe 2–3 inimigos. O caminho principal avança em dois eixos da grade, impedindo que cruze a si mesmo. Apoio e loja são ramos laterais.

As salas usam uma grade de centros espaçados por 38 células. O piso é a união das salas e corredores; as paredes são construídas fora dessa união. O código valida que todo o piso está conectado e que os retângulos das salas não se sobrepõem antes de liberar a partida. A navegação é recalculada e sincronizada em cada geração. A origem visual das paredes foi compensada somente na cena nova para alinhar suas colisões ao piso.

O portal tem proteção contra uso repetido. A regeneração remove salas, inimigos, drops e projéteis antigos. Após a morte do jogador, salas concluídas permanecem concluídas; encontros ainda ativos são limpos e podem começar novamente ao entrar. O jogador retorna à sala inicial.

## Encontros

`sala.gd` mantém os estados NÃO VISITADA, EM COMBATE e CONCLUÍDA. Uma Area2D interna detecta a entrada do jogador. Os inimigos são instanciados em pontos afastados das paredes, priorizando posições distantes do jogador e sem repetir posições. A sala escuta o sinal `derrotado` dos inimigos; a morte do último conclui o encontro. A explosão do Vírus também emite esse sinal.

Para ajustar um encontro, altere `sala.encontro`, um Array[PackedScene], durante a montagem da sala. Para configurar o conjunto global, use `tipos_inimigos` no Inspector do nó Mapa. As cenas de inimigos devem seguir o contrato atual: Node2D, grupo `inimigos`, método `dano` e sinal `derrotado` emitido uma vez por morte. Preferencialmente herde `inimigo.gd`.

## NPC, loja e boss

- Apoio contém Marker2D `NPC1`, `NPC2` e `NPC3`. Por padrão aparecem Atlas (guia), Íris (médica) e Byte (técnico), com interação por E. Preencha `cenas_npcs` para substituir esses NPCs por até três cenas próprias.
- Loja contém `Vendedor` e `Item1`–`Item3`. Por padrão aparece Nox, com compras e vendas de chips e compras de cura. Preencha `cena_vendedor` para substituir o comerciante. Os marcadores de itens continuam disponíveis para objetos físicos futuros.
- Núcleo possui pontos de encontro válidos e o campo `cena_boss`. O boss futuro deve seguir o contrato dos inimigos e emitir `derrotado` ao morrer.
- Como não existe boss próprio, o núcleo tem um encontro demonstrativo com Trojan e Vírus, identificados como os inimigos que já são. Não foi criado um boss fictício ou um novo padrão de ataque.
- As salas de apoio e loja recebem NPCs robóticos e interações funcionais mesmo sem cenas personalizadas.

## Configurar e ampliar

Abra `scenes/mapas/mapa.tscn` e selecione Mapa no Inspector:

| Campo | Uso |
|---|---|
| `seed_mapa` | 0 sorteia uma partida; outro inteiro reproduz a disposição e os encontros. |
| `combates_min` / `combates_max` | 2–6 salas comuns; padrão 3–4. |
| `inimigos_min` / `inimigos_max` | 1–6 por encontro; padrão 2–3. |
| `tamanho_sala` | 19–27 células, preferencialmente ímpar; padrão 23. Núcleo usa 29. |
| `largura_corredor` | 5–9 células, preferencialmente ímpar; padrão 5. |
| `tipos_inimigos` | Cenas disponíveis para as salas comuns. |
| `cena_boss` | Cena do futuro chefe; vazio mantém o encontro demonstrativo. |
| `cenas_npcs` / `cena_vendedor` | Cenas para as salas reservadas. |

`seed_atual` fica disponível no Inspector remoto e no código. O próximo setor usa seed atual + 1, permitindo reproduzir a sequência. As chances dos drops continuam independentes e não são controladas pela seed do layout.

Para adicionar outro tipo de sala, inclua o tipo em `sala.gd`, seu nome em `NOMES`, sua distribuição em `gerar` e seus elementos em `_montar_sala`. Preserve o espaçamento de 38 células e a margem dos pontos de spawn. Objetos físicos novos exigem incluir seus obstáculos na navegação e repetir os testes de caminhos.

## Arquivos

Criados:

- `scenes/mapas/mapa.tscn`: cena principal de exploração, tiles, jogador, pause, navegação e HUD.
- `scenes/mapas/mapa.gd`: geração, conectividade, posicionamento e transição.
- `scenes/mapas/sala.gd`: entrada e estado dos encontros.
- `scenes/mapas/portal.gd`: visual do portal e interação E.
- `scenes/mapas/minimapa.gd`: orientação e mapa ampliado.
- `scenes/mapas/chao.tres` e `parede.tres`: tilesets extraídos do cenário existente.
- `scenes/mapas/README_MAPAS.md`: este guia.

Modificados:

- `project.godot`: nova cena principal.
- `scenes/inimigos/inimigo.gd`: sinal `derrotado`, reutilizando a proteção existente de uma morte/drop por inimigo.
- `scenes/player/player.gd`: respawn delega ao gerenciador de salas quando ele existe; mantém o reset anterior no mapa de teste.

Backups anteriores às mudanças e scripts de teste estão na pasta de trabalho do Codex, `work/mapas`.

## Limites e ações da equipe

Não é necessário montar salas ou assar navegação manualmente. Se uma partida antiga estiver aberta, pare e execute F5 novamente. Aceite a recarga dos arquivos externos se o editor perguntar.

Ficam para depois: boss original, obstáculos internos, save de campanha e novas artes. Não foram adicionados obstáculos ao interior das salas para preservar rotas previsíveis nesta entrega.

Os testes automatizados e a inspeção visual não substituem um ensaio manual no computador do evento. Antes da apresentação, façam uma partida com teclado/mouse e testem o executável exportado na máquina final; o pacote exportado não foi validado nesta tarefa.

## Resultados dos testes

- `testar.gd`: **3.844 verificações, zero falhas**, em 20 seeds, com 20 disposições distintas. Validou conectividade, ausência de sobreposição de salas, piso conectado, navegação e varredura do corpo real do jogador por todas as rotas, spawns livres, ativação por entrada, ausência de encontros duplicados, movimento de IA, mortes e explosões, conclusão de salas, respawn, pause/melhorias e portal com inventário preservado.
- `testar_limites.gd`: passou nas configurações 19 células / corredor 5 / 2 combates e 27 células / corredor 9 / 6 combates. Testou seis inimigos por sala sem posições repetidas, paredes bloqueando a saída do cenário, deslocamento físico real do jogador, marcadores de NPC/loja e regeneração com o contorno visual ativo.
- Teste de tiros existente: passou para mira, cadência, quatro inimigos, tiros sem knockback, espada com knockback, paredes, pause, expiração de projéteis e respawn.
- Teste de drops existente: passou para chances, coleta única, equipamentos, dano fracionário, respawn e carrossel de melhorias.
- Inicialização pela configuração normal do projeto: carregou sem erros de script ou recursos ausentes.
- Inspeção visual em 960 × 540: entrada, vista geral das conexões, HUD/minimapa e portal renderizados. O contorno atrás de paredes reutiliza o efeito existente, com as máscaras reconstruídas a cada geração.
- Na regressão do cenário antigo apareceu o aviso pré-existente de caminho vazio no efeito de outline. O cenário antigo não foi alterado; o mapa novo configura somente o caminho válido e não produziu esse aviso.
- Não realizados: boss próprio (sistema ausente), ensaio manual completo e teste de executável exportado na máquina do evento. NPCs e comércio foram implementados e testados na atualização abaixo.

Scripts, logs e capturas: `C:/Users/Usuario/Documents/Codex/2026-10-11/sistema-de-melhorias-tela-clicar-no/work/mapas/`. Os testes de regressão reutilizados ficam em `work/tiros-ajuste/test.gd` e `work/drops/test.gd`, na mesma pasta de trabalho.

## Atualização: barreiras, NPCs e comércio

- Barreiras físicas nas entradas/saídas de cada sala de combate e núcleo. Cobrem a passagem e bloqueiam jogador, inimigos e tiros; dash não atravessa. Abrem após a última morte, inclusive a explosão do Vírus. O respawn reabre as salas interrompidas. A detecção cobre toda a sala, evitando desvio pela borda, e as barreiras ficam atrás de quem entra para não prender o jogador dentro da colisão.
- Atlas explica exploração e combate; Íris cura toda a vida gratuitamente uma vez por setor; Byte restaura a estamina gratuitamente uma vez por setor. Não consomem o atendimento quando o atributo já está cheio.
- Nox vende um chip de cada tipo e três curas por setor. Cura é aplicada imediatamente (+1 PV); chips vão ao inventário para equipar pelo pause. Chips nível 2 agora estão disponíveis na loja, mantendo zero chance de drop de inimigos.
- Preços em engrenagens: Potência 4, Vitalidade 5, Agilidade 4, Energia 10, Processador 12, cura 2. Ajustáveis em `npc.gd`: `precos` e `preco_cura`.
- Aba Vender: somente chips livres, por metade do preço de compra (arredondada para baixo). Chips equipados precisam ser removidos antes. Não há estoque ou saldo negativo, nem cobrança por cura com vida cheia.
- E conversa com o NPC mais próximo; Esc ou E fecha. O diálogo pausa o mundo e captura o Esc sem abrir o pause comum. O estoque e os atendimentos se renovam no próximo setor; morrer não os renova.
- Arquivos novos: `porta.gd`, `npc.gd`, `interacao.gd`, todos em `scenes/mapas`. Alterações: `mapa.gd`, `sala.gd`, `canvas_layer.gd`, `scenes/menus/tela_melhorias.gd` e este guia.
- Testes: 264 verificações sem falhas em `work/comercio/testar.gd`; três seeds, entradas junto às paredes, colisão das barreiras, dash bloqueado, abertura após o último inimigo, respawn, quatro NPCs, saldo insuficiente, compra, estoque, venda, proteção dos equipados, atendimento único, teclas E/Esc e regeneração. Capturas conferidas para NPCs, loja, venda, guia e barreira.