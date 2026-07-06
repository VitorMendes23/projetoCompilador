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

### 3.1 Resultados esperados

| Arquivo | Resultado esperado |
|---------|-------------------|
| `testes/testes_lexico/Teste1.txt` | erro lexico |
| `testes/testes_lexico/Teste2.txt` | erro lexico |
| `testes/testes_lexico/Teste3.txt` | erro lexico |
| `testes/testes_lexico/Teste4.txt` | erro lexico |
| `testes/testes_lexico/Teste5.txt` | erro lexico |
| `testes/testes_lexico/Teste6.txt` | erro lexico |
| `testes/testes_sintatico/Teste7.txt` | erro sintatico |
| `testes/testes_sintatico/Teste8.txt` | erro sintatico |
| `testes/testes_sintatico/Teste9.txt` | erro sintatico |
| `testes/testes_sintatico/Teste10.txt` | erro sintatico |
| `testes/testes_sintatico/Teste11.txt` | erro sintatico |
| `testes/testes_sintatico/Teste12.txt` | erro sintatico |
| `testes/testes_semantico/Teste7_corrigido.txt` | `Erro semantico: Variavel 'altura' nao declarada` |
| `testes/testes_semantico/Teste8_corrigido.txt` | `Erro semantico: Operando esquerdo de '%%' deve ser inteiro` |
| `testes/testes_semantico/Teste9_corrigido.txt` | `Erro semantico: Variavel 'maior' nao declarada` |
| `testes/testes_semantico/Teste10_corrigido.txt` | `Erro semantico: Variavel 'sobrenome' nao declarada` |
| `testes/testes_semantico/Teste11_corrigido.txt` | `Erro semantico: Variavel 'qtd' nao declarada` |
| `testes/testes_semantico/Teste12_corrigido.txt` | **COMPILA** — gera `.vm` |
| `testes/testes_semantico/Teste1_v2.txt` | **COMPILA** — gera `.vm` |
| `testes/testes_semantico/Teste2_v2.txt` | **COMPILA** — gera `.vm` |
| `testes/testes_semantico/Teste3_v2.txt` | **COMPILA** — gera `.vm` |
| `testes/testes_semantico/Teste4_v2.txt` | **COMPILA** — gera `.vm` |
| `testes/testes_semantico/Teste5_v2.txt` | **COMPILA** — gera `.vm` |
| `testes/testes_semantico/Teste6_v2.txt` | **COMPILA** — gera `.vm` |

### 3.2 Executar todos os testes de uma vez (Linux/WSL)

```bash
cd compilador
javac -d bin src/**/*.java

echo "=== Testes com erro (lexico) ==="
for f in testes/testes_lexico/Teste{1..6}.txt; do
    echo -n "$f => "
    java -cp bin Main "$f" 2>&1
done

echo ""
echo "=== Testes com erro (sintatico) ==="
for f in testes/testes_sintatico/Teste{7..12}.txt; do
    echo -n "$f => "
    java -cp bin Main "$f" 2>&1
done

echo ""
echo "=== Testes com erro (semantico) ==="
for f in testes/testes_semantico/Teste{7..11}_corrigido.txt; do
    echo -n "$f => "
    java -cp bin Main "$f" 2>&1
done

echo ""
echo "=== Testes que compilam (semantico) ==="
for f in testes/testes_semantico/Teste12_corrigido.txt testes/testes_semantico/Teste{1..6}_v2.txt; do
    echo -n "$f => "
    java -cp bin Main "$f" 2>&1
done
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

### 5.1 Testes que compilam e executam na VM

Todos os comandos a partir da pasta `vm-1.7/`:

```bash
cd vm-1.7
```

#### Teste1_v2 — area do triangulo (base x altura / 2)

```bash
echo -e "10\n5" | ./vm-native ../compilador/testes/testes_semantico/Teste1_v2.vm
```

Saida:
```
Digite o valor da base: read => 10
Digite o valor da altura: read => 5
A area e: 25.
```

#### Teste2_v2 — par ou impar

```bash
echo -e "7" | ./vm-native ../compilador/testes/testes_semantico/Teste2_v2.vm
```

Saida:
```
Entre com o valor de a: read => 7
7e impar
```

#### Teste3_v2 — maior de 3 numeros float

```bash
echo -e "15.5\n8.3\n12.7" | ./vm-native ../compilador/testes/testes_semantico/Teste3_v2.vm
```

Saida:
```
Digite um numero: read => 15.5
Digite outro numero: read => 8.3
Digite mais um numero: read => 12.7
O maior numero e: 15.5
```

#### Teste4_v2 — cadastro com salario e bonus

```bash
echo -e "Joao\nSilva\n25\n3500.0\n500.0\nMaria\nSouza\n0\n0\n0" | ./vm-native ../compilador/testes/testes_semantico/Teste4_v2.vm
```

Saida:
```
Digite o seu nome: read => Joao
Digite o seu sobrenome: read => Silva
Digite a sua idade: read => 25
Digite o salario: read => 3500.0
Digite o bonus: read => 500.0
Joao Silva:Salario liquido: 3500.
Digite o seu nome: read => Maria
Digite o seu sobrenome: read => Souza
Digite a sua idade: read => 0
Digite o salario: read => 0
Digite o bonus: read => 0
```

#### Teste5_v2 — media de alturas

```bash
echo -e "3\n1.5\n0.8\n2.0" | ./vm-native ../compilador/testes/testes_semantico/Teste5_v2.vm
```

Saida:
```
Quantos dados deseja informar? read => 3
Altura: read => 1.5
Altura: read => 0.8
Altura: read => 2.0
Media: 1.43333333333
```

#### Teste6_v2 — par/ímpar com soma total

```bash
echo -e "5\n3\n0\n-1" | ./vm-native ../compilador/testes/testes_semantico/Teste6_v2.vm
```

Saida:
```
Digite um numero (negativo para sair): read => 5
O numero 5 eh impar
Digite um numero (negativo para sair): read => 3
O numero 3 eh impar
Digite um numero (negativo para sair): read => 0
O numero 0 eh par
Digite um numero (negativo para sair): read => -1
Soma total: 8
```

#### Teste12_corrigido — par/ímpar com soma total

```bash
echo -e "5\n3\n0\n-1" | ./vm-native ../compilador/testes/testes_semantico/Teste12_corrigido.vm
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
java -cp bin Main testes/testes_semantico/Teste6_v2.txt

# 3. Executar na VM
cd ../vm-1.7
echo -e "5\n3\n0\n-1" | ./vm-native ../compilador/testes/testes_semantico/Teste6_v2.vm
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
- O `.vm` gerado fica na mesma pasta do `.txt` de entrada (portanto dentro de `testes/testes_semantico/`).
- A VM foi modificada para ecoar a entrada lida (linha 149 de `vm.ml`), entao o terminal mostra os valores digitados.
- O emulador VM foi obtido do `web.archive.org` (site original do LRI
  estava fora do ar). Codigo fonte em OCaml por Jean-Christophe Filliatre.
- `vm-native` foi compilado no WSL (Ubuntu 24.04, OCaml 4.14.1).
