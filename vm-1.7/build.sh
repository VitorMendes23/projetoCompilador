#!/bin/bash
# Script de compilacao do emulador VM
# Uso: bash build.sh
# Saida: vm (executavel bytecode) e vm-native (executavel nativo, se ocamlopt disponivel)

set -e
cd "$(dirname "$0")"

echo "=== Gerando version.ml ==="
echo 'let version = "1.7"' > version.ml
echo 'let date = "'"$(date)"'"' >> version.ml

echo "=== Gerando lexer/parser ==="
ocamllex code_lexer.mll
ocamlyacc code_parser.mly

echo "=== Compilando modulos (bytecode) ==="
ocamlc -g -c label.mli label.ml
ocamlc -g -c hstring.mli hstring.ml
ocamlc -g -c util.mli util.ml
ocamlc -g -c instr.mli
ocamlc -g -c code_parser.mli code_parser.ml
ocamlc -g -c code_lexer.ml
ocamlc -g -c code.mli code.ml
ocamlc -g -c version.ml
ocamlc -g -c maze.mli maze.ml
ocamlc -g -c vm.mli vm.ml
ocamlc -g -c main.ml

echo "=== Linkando (bytecode) ==="
ocamlc -g -o vm label.cmo hstring.cmo util.cmo code_parser.cmo code_lexer.cmo code.cmo version.cmo maze.cmo vm.cmo main.cmo
echo "OK: vm gerado"

# Tentar compilacao nativa (standalone, sem dependencia do ocamlrun)
if command -v ocamlopt &>/dev/null; then
    echo "=== Compilando modulos (nativo) ==="
    ocamlopt -c label.mli label.ml
    ocamlopt -c hstring.mli hstring.ml
    ocamlopt -c util.mli util.ml
    ocamlopt -c instr.mli
    ocamlopt -c code_parser.mli code_parser.ml
    ocamlopt -c code_lexer.ml
    ocamlopt -c code.mli code.ml
    ocamlopt -c version.ml
    ocamlopt -c maze.mli maze.ml
    ocamlopt -c vm.mli vm.ml
    ocamlopt -c main.ml

    echo "=== Linkando (nativo) ==="
    ocamlopt -o vm-native label.cmx hstring.cmx util.cmx code_parser.cmx code_lexer.cmx code.cmx version.cmx maze.cmx vm.cmx main.cmx
    echo "OK: vm-native gerado (standalone)"
fi

echo ""
echo "=== Compilacao concluida ==="
ls -la vm vm-native 2>/dev/null || ls -la vm
