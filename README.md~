# Compilador — Etapa 3 (Analisador Semantico + Geracao de Codigo)

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
│   │   └── codigo/     (Type.java, VMGen.java) -- NOVO Etapa 3
│   ├── bin/             (.class compilados, ignora git)
│   │
│   │   -- ARQUIVOS DE TESTE --
│   ├── Teste1.txt  ...  Teste6.txt       -- etapa 1 (lexico)
│   ├── Teste7.txt  ...  Teste12.txt      -- etapa 2 (sintatico, com erros)
│   ├── Teste7_corrigido.txt  ...  Teste12_corrigido.txt  -- corrigidos sintaticamente
│   ├── Teste*_corrigido1.txt  ...         -- variantes intermediarias
│   └── Teste12_corrigido.vm               -- codigo VM gerado (exemplo)
│
├── vm-1.7/                          # emulador da VM (codigo fonte OCaml)
│   ├── *.ml / *.mli / *.mll / *.mly
│   ├── build.sh                     -- script para compilar o emulador
│   ├── vm                           -- executavel bytecode (pre-compilado)
│   └── vm-native                    -- executavel nativo (standalone)
│
├── contextoTeorico/                 -- PDFs e documentacao de apoio
│
└── relatorio_etapa2.tex             -- relatorio da etapa anterior
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

# Compilar primeiro (secao 2)
javac -d bin src/**/*.java

# Executar com um arquivo de teste
java -cp bin Main Teste12_corrigido.txt
```

### 3.1 Resultados esperados

| Arquivo | Resultado esperado |
|---------|-------------------|
| `Teste1.txt` | erro lexico |
| `Teste2.txt` | erro lexico |
| `Teste3.txt` | erro lexico |
| `Teste4.txt` | erro lexico |
| `Teste5.txt` | erro lexico |
| `Teste6.txt` | erro lexico |
| `Teste7.txt` | erro sintatico |
| `Teste8.txt` | erro sintatico |
| `Teste9.txt` | erro sintatico |
| `Teste10.txt` | erro sintatico |
| `Teste11.txt` | erro sintatico |
| `Teste12.txt` | erro sintatico |
| `Teste7_corrigido.txt` | `Erro semantico: Variavel 'altura' nao declarada` |
| `Teste8_corrigido.txt` | `Erro semantico: Operando esquerdo de '%%' deve ser inteiro` |
| `Teste9_corrigido.txt` | `Erro semantico: Variavel 'maior' nao declarada` |
| `Teste10_corrigido.txt` | `Erro semantico: Variavel 'sobrenome' nao declarada` |
| `Teste11_corrigido.txt` | `Erro semantico: Variavel 'qtd' nao declarada` |
| `Teste12_corrigido.txt` | **COMPILA** — gera `Teste12_corrigido.vm` |

### 3.2 Executar todos os testes de uma vez (Linux/WSL)

```bash
cd compilador
javac -d bin src/**/*.java

echo "=== Testes com erro esperado ==="
for f in Teste{1..6}.txt Teste{7..12}.txt Teste{7..11}_corrigido.txt; do
    echo -n "$f => "
    java -cp bin Main "$f" 2>&1
done

echo ""
echo "=== Unico que compila ==="
java -cp bin Main Teste12_corrigido.txt
```

---

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

### 5.1 Teste interativo

```bash
cd vm-1.7

# Usar o binario nativo (standalone)
echo -e "5\n3\n0\n-1" | ./vm-native ../compilador/Teste12_corrigido.vm
```

Saida esperada:

```
Digite um numero (negativo para sair): read =>
O numero 5 eh impar
Digite um numero (negativo para sair): read =>
O numero 3 eh impar
Digite um numero (negativo para sair): read =>
O numero 0 eh par
Digite um numero (negativo para sair): read =>
Soma total: 8
```

### 5.2 Opcoes da VM

```bash
./vm-native -help

# -silent    execucao silenciosa (sem output)
# -dump      mostra estado da pilha ao final
# -count     mostra numero de passos executados
# -ssize N   tamanho da pilha (padrao 10000)
```

### 5.3 Fluxo completo (compilar + executar)

```bash
# 1. Compilar o codigo fonte
cd compilador
javac -d bin src/**/*.java

# 2. Gerar o .vm
java -cp bin Main Teste12_corrigido.txt

# 3. Executar na VM
cd ../vm-1.7
echo -e "5\n3\n0\n-1" | ./vm-native ../compilador/Teste12_corrigido.vm
```

---

## 6. Casos de teste para o relatorio

Para cada arquivo corrigido, documentar:
1. O comando executado
2. A saida do compilador (erro ou sucesso)
3. Se gerou `.vm`, o codigo gerado
4. Se executou na VM, o resultado

### Exemplo de documentacao

```
Arquivo: Teste12_corrigido.txt
Analise semantica: OK (compila sem erros)
Codigo VM gerado: Teste12_corrigido.vm (58 linhas)
Execucao na VM:
  Input: 5, 3, 0, -1
  Output:
    O numero 5 eh impar
    O numero 3 eh impar
    O numero 0 eh par
    Soma total: 8
  Soma correta: 5 + 3 + 0 = 8
```

---

## 7. Observacoes importantes

- O compilador **para no primeiro erro** — nao ha recuperacao de erros.
- O `.vm` gerado fica na mesma pasta do `.txt` de entrada.
- O emulador VM foi obtido do `web.archive.org` (site original do LRI
  estava fora do ar). Codigo fonte em OCaml por Jean-Christophe Filliatre.
- `vm-native` foi compilado no WSL (Ubuntu 24.04, OCaml 4.14.1).
