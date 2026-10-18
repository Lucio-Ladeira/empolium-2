# Empolium Desktop

Menu de inicialização com fluxo de boot, login, desktop e aplicativos internos.

## Rodar como projeto separado

Abra esta pasta no Godot 4.7 ou superior e execute `res://main.tscn`. O botão `Empolium 2` abre a cena procedural usada como entrada do jogo, `res://scenes/mapas/mapa.tscn`; ela só estará disponível depois de integrar este desktop ao projeto principal.

O gerenciador de arquivos usa uma árvore virtual de demonstração. Pesquisar percorre toda a pasta pessoal; os arquivos não são lidos nem alterados no disco.

## Integrar ao jogo principal

O projeto principal usa `res://scenes/mapas/mapa.tscn` como cena inicial do jogo. Os recursos do desktop não colidem com os do jogo; só existem caminhos compartilhados para configurações do Git/editor e `project.godot`, que não deve ser copiado.

1. Copie `assets/`, `os/`, `os.gd` e `main.tscn` para a raiz do projeto do jogo. Não copie este `project.godot`.
2. No `project.godot` do jogo, mantenha as configurações existentes, adicione o autoload `OSVisualFX="*res://os/effects/os_visual_fx.gd"` e defina `run/main_scene="res://main.tscn"`.
3. O campo `game_scene_path` em `os/desktop/desktop.gd` aponta para `res://scenes/mapas/mapa.tscn`. Atualize esse campo se a cena principal do jogo mudar.

`OSVisualFX` mantém o shader CRT ativo sobre o desktop e o jogo, e conduz a transição de linha CRT ao trocar de cena.
