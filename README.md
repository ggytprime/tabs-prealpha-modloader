# TabsModLoader

Um mod loader minimal para **Totally Accurate Battle Simulator (Pre-Alpha)** — Unity 5.5, Mono (x64).

- Inicia antes do Unity fechar qualquer coisa — a gente injeta uma chamada no `GameLogic.Awake()`
  (main thread, Unity já inicializado) no `Assembly-CSharp.dll`.
- Carrega DLLs na pasta `Mods/` e cada DLL deriva de `TabsMod` para ganhar acesso ao ciclo de
  Unity, log e ao `Assembly-CSharp.dll` do jogo.
- Tudo que uma mod precisa é referenciar `Assembly-CSharp.dll`, `UnityEngine.dll`,
  `System.dll`/`System.Core.dll` e `TabsModLoader.dll` para compilar.

## Estrutura

```
TabsModLoader/
  build/             # saída: TabsModLoader.dll, ExampleMod.dll, GoreMod.dll, Patcher.exe
  src/
    ModLoader/       # loader (Bootstrap, ModLoaderCore, ModEngine, ModApi, GameHooks)
    Example/         # mod de exemplo
    Gore/            # gore: sangue no ponto do golpe, desmembramento, ossos, decalques
  tools/
    Patcher/         # Patcher.exe (Mono.Cecil) — injeta Bootstrap.Init no Assembly-CSharp
    Inspect/         # ferramenta de inspecao do assembly do jogo (dev)
  lib/               # Mono.Cecil (net40)
  build.sh           # compila tudo contra as DLLs do jogo
  install.bat        # instala no jogo (Windows, pede elevação)
  install.sh         # variante bash do instalador
  uninstall.sh       # remove e restaura Assembly-CSharp original
  README.md
```

## Instalação

```bat
:: Windows, com o jogo instalado (clique direito -> Executar como administrador)
C:\Users\gabim\Documents\projeto\tabs-modloader\install.bat
```

Como o jogo fica em `Program Files (x86)`, o instalador pede elevação para escrever:
- `Managed/Assembly-CSharp.dll` (patchado; o original vai para `Assembly-CSharp.dll.bak`)
- `Managed/TabsModLoader.dll`
- `Mods/ExampleMod.dll`
- `Mods/GoreMod.dll`

Para uma instalação em outra pasta (ex: cópia do jogo fora do Program Files), só mudar `GAME_DIR`:
```bash
GAME_DIR="C:\caminho\do\meu\backup\do\jogo" bash install.sh
```

## Remoção

```bash
GAME_DIR="C:\Program Files (x86)\Totally Accurate Battle Simulator Pre-Alpha" bash uninstall.sh
```
Isso restaura o `Assembly-CSharp.dll` original (de `.bak`) e remove o loader e a mod de exemplo.

## Como escrever uma mod

1. Crie uma classe que deriva de `TabsMod`.
2. Marque com `[TabsMod("Name")]` (nome, versão e autor opcionais).
3. Implemente `Load(ModContext ctx)`.

Exemplo mínimo:

```csharp
using TabsModLoader;
using UnityEngine;

namespace MeuMod
{
    [TabsMod("MeuMod")]
    public class MeuMod : TabsMod
    {
        public override void Load(ModContext ctx)
        {
            ctx.Log("MeuMod carregou.");
            ctx.OnUpdate(() =>
            {
                if (Input.GetKeyDown(KeyCode.H))
                    ctx.Log("H pressionado!");
            });
        }
    }
}
```

Compile contra as DLLs do jogo (`Managed/*.dll`) + `TabsModLoader.dll`. O método `Load` é chamado no
main thread do Unity logo após o `Awake` do `GameLogic`, então a API do Unity já está pronta.

## API disponível

- `ModContext` (recebido no `Load`):
  - `ctx.Name`, `ctx.Directory`, `ctx.DataDirectory` (pasta %LOCALAPPDATA%\TabsModLoader\<mod>, sempre
    gravável)
  - `ctx.Log`, `ctx.LogWarning`, `ctx.LogError`, `ctx.LogException`
  - `ctx.OnUpdate(Action)` — roda toda frame, no main thread
  - `ctx.OnUnitDamaged(Action<UnitDamaged>)` — dano real com ponto de contato, direção, arma e vítima
  - `ctx.Unload()` — chamado ao fechar o jogo (opcional na sua mod)
- `Mods` (estático, para mods que não querem instância):
  - `Mods.GameDirectory`, `Mods.ModsDirectory`, `Mods.LoaderVersion`
  - `Mods.OnUpdate(Action)`, `Mods.Log`, `Mods.LogWarning`, `Mods.LogError`, `Mods.LogException`
- `TabsModLoader.LogFilePath` (em `LoaderLog`) aponta para onde o loader escreve o log.

## Console e log

Ao abrir o jogo, o loader **abre uma janela de console** (`AllocConsole`) ao lado da janela do jogo,
mostrando:

- versão do loader, versão do Unity, pasta do jogo e pasta de mods;
- cada mod encontrado/carregado (nome, versão, autor);
- no fim, uma tabela com os mods carregados: arquivo `.dll`, pasta de dados e classe;
- erros em vermelho e avisos em amarelo.

O mesmo texto vai para o arquivo de log: `TabsModLoader.log` na raiz do jogo (se não conseguir gravar
lá — caso de `Program Files` —, cai para `%LOCALAPPDATA%\TabsModLoader\loader.log`). As mensagens também
aparecem no console do Unity (`Debug.Log` / `Warning` / `Error`).

## Exemplo incluso

O `ExampleMod` é o mínimo necessário: registra um `OnUpdate`, espera 120 frames, escreve
`loaded.txt` na pasta de dados da mod e loga tudo — serve para confirmar que o carregamento de DLLs,
os callbacks por frame e o acesso à pasta de dados funcionam.

## Mod de gore (GoreMod)

`src/Gore/` é um mod de verdade, e serve de exemplo de mod que conversa com a lógica do jogo:

O gore usa o **hook de dano** (`ctx.OnUnitDamaged`): o Patcher injeta uma chamada em
`UnitHandler.TakeDamage`, então o mod recebe vítima, dano, direção, arma e o **ponto exato do contato**.

- `GoreMod.cs` decide o que acontece: respingo no ponto do golpe (intensidade pelo dano), golpes acima
  de 70 de dano podem arrancar membro, e pancadas fortes (club/physical/explosive, 55+) quebram osso.
  Se o ponto informado ficar a mais de 1,2 m do corpo (explosão passa o centro dela, não o contato), o
  sangue é trazido para a parte do corpo mais próxima.
- `Dismemberment.cs` é o desmembramento de verdade: acha a `Joint` mais próxima do impacto e **destrói
  todas as joints que tocam aquele pedaço**, senão outra junta continua puxando e a perna "estica" pelo
  mapa. O pedaço solto é desparentado (escala herdada é o que faz ragdoll tremer), vai para a layer 8
  (como as partes que o jogo larga na morte) e só leva um empurrão de ~1,5 m/s (`VelocityChange`, não
  `Impulse` — impulso em 0,2 kg arremessava o membro para fora do mapa).
  - `PhysicsDamageChecker`/`Bodypart` do pedaço são desligados (uma perna voando não pode mais dar dano
    no dono antigo), e depois de ~1,5-2 s ele é congelado (`isKinematic`) quando já está no chão, senão
    o `PhysicsAnimation` do jogo continua aplicando torque de caminhada nele e ele fica tremendo/andando.
  - O sangramento do pedaço para automaticamente se ele se afastar mais de ~2,2 m do corte, e o mesmo
    vale para o toco — é isso que impedia sangue de aparecer longe do corpo.
  - Osso exposto nos dois tocos e sangramento arterial por ~6s.
- `GoreMaterials.cs` monta os materiais em runtime: sangue fresco (vermelho escuro, brilho alto — a
  camada molhada), sangue seco, osso, carne, e um decalque de poça com textura procedural e alpha
  (Standard shader em modo Fade). Nenhum asset externo é necessário.
- `BloodSystem.cs` cuida das gotas (movidas na mão, sem física), dos pedaços de carne irregulares
  (`Rigidbody`) e das **manchas no chão**: quads texturizados, alinhados à normal do piso, que ficam
  16-30s; poças maiores duram 70s.
- Limites para não derrubar o FPS: 340 gotas, 190 manchas, 70 pedaços de carne, 4 membros por unidade.
- Teclas: **F3** liga/desliga o gore em tempo real, **F4** limpa sangue e ossos da cena.
- O console mostra `Hook de dano ativo`, `Membro arrancado (dano, golpe)` e
  `Morte com gore: N (respingos, manchas, carne)`; exceções viram log vermelho sem travar o jogo.

## Modificar/recompilar

```bash
GAME_DIR="C:\Program Files (x86)\Totally Accurate Battle Simulator Pre-Alpha" bash build.sh
```
Isso reconstrói `build/TabsModLoader.dll`, `build/ExampleMod.dll`, `build/GoreMod.dll` e `build/Patcher.exe` contra as DLLs
do jogo apontados por `GAME_DIR`. Depois rode `install.bat` de novo para reinstalar.

## Notas técnicas

- Patcher faz dois patches, ambos idempotentes:
  1. `call TabsModLoader.Bootstrap::Init()` no início de `GameLogic.Awake()` (liga o loader);
  2. `call TabsModLoader.GameHooks::UnitDamage(this, damage, dir, damager, worldPosition)` logo antes
     de `m_health -= damage` em `UnitHandler.TakeDamage()` — depois da checagem de imunidade do jogo,
     então o mod só vê dano que realmente seria aplicado.
  Se o padrão de IL não for encontrado, ele sai com código 14 e imprime o IL do método; o assembly
  original fica intacto e o `.bak` só é criado na primeira instalação.
- O loader chama `Application.runInBackground = true` para os efeitos continuarem animando mesmo com a
  janela do jogo em segundo plano.
- O loader é idempotente: `Bootstrap.Init` só executa uma vez por carregamento.
- O loader segura a Unity assim que o `Awake` é chamado — se você precisar esperar um estado específico
  (ex: `GameLogic.Instance` pronto), faça a checagem dentro do seu `OnUpdate`.
- Para remover pacotes do Cecil/Proteção de integridade: se o jogo validar hashes de assemblies (não é o
  caso do Pre-Alpha standalone), o patch teria que ser revertido ou feito na memória. Para este jogo,
  patch no disco é suficiente.
