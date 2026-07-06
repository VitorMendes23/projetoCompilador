## Estrutura do repositorio

```
LexerProject/
├── INSTRUCOES.md                    # este arquivo
├── .gitignore
│
├── compilador/                      # codigo fonte do compilador (Java)
│   ├── src/
│   │   ├── Main.java
│   │   ├── lexico/     (Lexer, Token, Tag, Word, Num, Literal)
│   │   ├── sintatico/  (Parser.java)
│   │   ├── tabela/     (Env.java, Id.java)
│   │   └── codigo/     (Type.java, VMGen.java)
│   ├── bin/             (.class compilados)
│   ├── testes/          (arquivos .txt e .vm de teste)
│   │   ├── testes_lexico/     -- etapa 1 (Teste1-6.txt, debug)
│   │   ├── testes_sintatico/  -- etapa 2 (Teste7-12.txt, intermediarios)
│   │   └── testes_semantico/  -- etapa 3 (v1/v2, _corrigido finais, .vm)
│   │
│   └── out/               (output do IDE)
│
├── vm-1.7/                          # emulador da VM (codigo OCaml)
│   ├── *.ml / *.mli / *.mll / *.mly
│   ├── build.sh
│   ├── vm
│   └── vm-native                    # executavel nativo (standalone)
│
└── contextoTeorico/                 # PDFs e documentacao de apoio
```

---

## 1. Pre-requisitos

### 1.1 Java (obrigatorio)

Compilador Java 21+ instalado:

```bash
javac -version   # deve mostrar "javac 21.x.x" ou superior
```

### 1.2 Emulador VM (necessario para executar o codigo gerado)

#### Linux / WSL (Windows)

Instalar OCaml:

```bash
# Ubuntu / Debian / WSL
sudo apt update
sudo apt install -y ocaml ocaml-nox ocaml-base make
```

Verificar:

```bash
ocamlc -version   # OCaml 4.14 ou superior
```

> O repositorio ja inclui os binarios pre-compilados `vm-1.7/vm` e
> `vm-1.7/vm-native`. Se preferir recompilar, veja secao 4.

---

## 2. Compilar o compilador (Java)

Abrir terminal na pasta `compilador/`:

```bash
cd compilador

# Compilar todos os .java
javac -d bin src/**/*.java
```

Se estiver no Windows PowerShell:

```powershell
cd compilador
javac -d bin (Get-ChildItem -Path src -Recurse -Filter *.java | % { $_.FullName })
```

---

## 3. Executar testes

Sempre a partir da pasta `compilador/`:

```bash
cd compilador

# Compilar primeiro
javac -d bin src/**/*.java

# Executar com um arquivo de teste
java -cp bin Main testes/testes_semantico/Teste12_corrigido.txt
```


## 4. Compilar o emulador VM (opcional)

So necessario se quiser recompilar o emulador ou se estiver em
uma arquitetura diferente (ARM, etc.).

```bash
cd vm-1.7
bash build.sh
```

O script gera dois executaveis:
- `vm`          — bytecode (requer ocamlrun)
- `vm-native`   — nativo, standalone (nao requer ocamlrun)

---

## 5. Executar o codigo VM gerado

### 5.1 Testes que compilam e executam na VM

Todos os comandos a partir da pasta `vm-1.7/`:

```bash
cd vm-1.7
```


### 5.3 Fluxo completo (compilar + executar)

```bash
# 1. Compilar o codigo fonte
cd compilador
javac -d bin src/**/*.java

# 2. Gerar o .vm
java -cp bin Main testes/testes_semantico/Teste6_v2.txt

# 3. Executar na VM
cd ../vm-1.7
echo -e "5\n3\n0\n-1" | ./vm-native ../compilador/testes/testes_semantico/Teste6_v2.vm
```

---

## 7. Observacoes importantes

- O compilador **para no primeiro erro** — nao ha recuperacao de erros.
- O `.vm` gerado fica na mesma pasta do `.txt` de entrada (portanto dentro de `testes/testes_semantico/`).
- A VM foi modificada para ecoar a entrada lida (linha 149 de `vm.ml`), entao o terminal mostra os valores digitados.
- O emulador VM foi obtido do `web.archive.org` (site original do LRI
  estava fora do ar). Codigo fonte em OCaml por Jean-Christophe Filliatre.
- `vm-native` foi compilado no WSL (Ubuntu 24.04, OCaml 4.14.1).
