package lexico;

import tabela.Env;
import tabela.Id;

import java.io.*;
import java.util.*;

public class Lexer {
    public static int line = 1;
    private int ch;
    private FileReader file;
    private Hashtable<String, Word> words = new Hashtable<>();
    private Env topEnv;

    private void reserve(Word w) {
        words.put(w.getLexeme(), w);
        topEnv.put(w.getLexeme(), new Id(w.getLexeme(), "reserved"));
    }

    public Lexer(String fileName) throws FileNotFoundException {
        try {
            file = new FileReader(fileName);
            readch(); // inicializa ch com primeiro caractere
        } catch (FileNotFoundException e) {
            System.out.println("Arquivo não encontrado: " + fileName);
            throw e;
        } catch (IOException e) {
            System.err.println("Erro de leitura: " + e.getMessage());
            System.exit(1);
        }
        topEnv = new Env(null);

        reserve(new Word("class", Tag.CLASS));
        reserve(new Word("int", Tag.INT));
        reserve(new Word("string", Tag.STRING));
        reserve(new Word("float", Tag.FLOAT));
        reserve(new Word("if", Tag.IF));
        reserve(new Word("else", Tag.ELSE));
        reserve(new Word("do", Tag.DO));
        reserve(new Word("while", Tag.WHILE));
        reserve(new Word("repeat", Tag.REPEAT));
        reserve(new Word("until", Tag.UNTIL));
        reserve(new Word("read", Tag.READ));
        reserve(new Word("write", Tag.WRITE));
        reserve(new Word("not", Tag.NOT));
        reserve(Word.True);
        reserve(Word.False);
        reserve(Word.and);
        reserve(Word.or);
    }

    private void readch() throws IOException {
        ch = file.read();
    }

    private boolean readch(char c) throws IOException {
        readch();
        if (ch != c) return false;
        ch = ' ';
        return true;
    }

    private void error(String msg, int lineError) {
        System.err.println("Erro léxico na linha " + lineError + ": " + msg);
        System.exit(1);
    }

    public Token scan() throws IOException {
        // ignora delimitadores e comentários
        while (true) {
            if (ch == ' ' || ch == '\t' || ch == '\b') {
                readch();
                continue;
            } else if (ch == '\n') {
                line++;
                readch();
                continue;
            } else if (ch == '\r') {
                readch();
                continue;
            } else if (ch == '/') {
                readch();
                if (ch == '/') {
                    while (true) {
                        readch();
                        if (ch == '\n') { line++; break; }
                        if (ch == -1) break;
                    }
                    continue;
                } else if (ch == '*') {
                    int startLine = line;
                    readch();
                    boolean closed = false;
                    while (true) {
                        if (ch == -1) {
                            error("Comentário não fechado", startLine);
                        }
                        if (ch == '*') {
                            readch();
                            if (ch == '/') {
                                closed = true;
                                readch();
                                break;
                            }
                        } else {
                            if (ch == '\n') line++;
                            readch();
                        }
                    }
                    if (closed) continue;
                } else {
                    return new Token('/');
                }
            } else if (ch == -1) {
                return new Token(-1); // EOF
            } else {
                break;
            }
        }

        // operadores compostos
        switch (ch) {
            case '<':
                readch();
                if (ch == '=') { ch = ' '; return Word.le; }
                if (ch == '>') { ch = ' '; return Word.ne; }
                return new Token('<');
            case '>':
                if (readch('=')) return Word.ge;
                return new Token('>');
            case ':':
                if (readch('=')) return Word.atr;
                return new Token(':');
        }

        // números inteiros e reais
        if (Character.isDigit(ch)) {
            int firstDigit = Character.digit(ch, 10);
            readch();

            if (firstDigit == 0) {
                if (Character.isDigit(ch))
                    error("Número com zero à esquerda: '0" + (char)ch + "...'", line);
                if (ch == '.') {
                    readch();
                    if (!Character.isDigit(ch)) error("Esperado dígito após ponto decimal", line);
                    double realVal = 0.0;
                    double divisor = 10.0;
                    do {
                        realVal = realVal + Character.digit(ch, 10) / divisor;
                        divisor *= 10;
                        readch();
                    } while (Character.isDigit(ch));
                    return new Num(realVal);
                }
                return new Num(0);
            } else {
                int intVal = firstDigit;
                while (Character.isDigit(ch)) {
                    intVal = 10 * intVal + Character.digit(ch, 10);
                    readch();
                }
                if (ch == '.') {
                    readch();
                    if (!Character.isDigit(ch)) error("Esperado dígito após ponto decimal", line);
                    double realVal = intVal;
                    double divisor = 10.0;
                    do {
                        realVal = realVal + Character.digit(ch, 10) / divisor;
                        divisor *= 10;
                        readch();
                    } while (Character.isDigit(ch));
                    return new Num(realVal);
                }
                return new Num(intVal);
            }
        }

        // identificadores e palavras reservadas
        if (Character.isLetter(ch)) {
            StringBuilder sb = new StringBuilder();
            do {
                sb.append((char) ch);
                readch();
            } while (Character.isLetterOrDigit(ch));

            String s = sb.toString();
            Word w = words.get(s);
            if (w != null) return w;

            Id id = topEnv.get(s);
            if (id == null) {
                id = new Id(s, null);
                topEnv.put(s, id);
            }
            return new Word(s, Tag.ID);
        }

        // literal (string entre aspas)
        if (ch == '"') {
            int startLine = line;
            StringBuilder sb = new StringBuilder();
            readch();
            while (ch != '"') {
                if (ch == '\n' || ch == -1)
                    error("lexico.Literal não fechado", startLine);
                sb.append((char) ch);
                readch();
            }
            readch();
            return new Literal(sb.toString());
        }

        // caracteres simples
        Token t = new Token(ch);
        readch(); // avança para o próximo caractere
        return t;
    }

    public void printSymbolTable() {
        System.out.println("\n=== TABELA DE SÍMBOLOS ===");
        topEnv.print();
    }
}