import java.io.*;
import java.util.*;

public class Lexer {
    public static int line = 1;
    private int ch = ' ';          // mudado para int
    private FileReader file;
    private Hashtable<String, Word> words = new Hashtable<>();

    private void reserve(Word w) {
        words.put(w.getLexeme(), w);
    }

    public Lexer(String fileName) throws FileNotFoundException {
        try {
            file = new FileReader(fileName);
        } catch (FileNotFoundException e) {
            System.out.println("Arquivo não encontrado: " + fileName);
            throw e;
        }

        /*
        Palavras reservadas: class, int, string, float, if, else, do, while, repeat, until, read, write, not
        Operadores relacionais: >=, <=, <> (dois caracteres juntos)
        Operadores aditivos: +, -, or
        Operadores multiplicativos: *, /, %, and
        * */

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
    }

    private void readch() throws IOException {
        ch = file.read();   // agora ch pode ser -1
    }

    private boolean readch(char c) throws IOException {
        readch();
        if (ch != c) return false;
        ch = ' ';
        return true;
    }

    public Token scan() throws IOException {
        // Fim do arquivo?
        if (ch == -1) return new Token(-1);

        // Ignora espaços, tabs, newlines, carriage returns
        while (true) {
            if (ch == ' ' || ch == '\t' || ch == '\b') {
                readch();
            } else if (ch == '\n') {
                line++;
                readch();
            } else if (ch == '\r') {   // ignora CR do Windows
                readch();
            } else if (ch=='/') {// Ignora comentários
                readch();

                if (ch=='/') {
                    while (true) {
                        readch();
                        if (ch == '\n') {
                            line++;
                            readch();
                            break;
                        }
                    }
                } else if (ch=='*') {
                    while (true) {
                        readch();
                        if (ch=='\n') line++;
                        if (ch=='*') {
                            readch();
                            if (ch=='/') {
                                readch();
                                break;
                            }
                        }
                    }
                } else {
                    return new Token('/');
                }
            } else {
                break;
            }
        }

        // Operadores compostos
        switch (ch) {
            case '<':
                readch();
                if (ch=='=') {
                    readch();
                    return Word.le;
                }
                else if (ch=='>') {
                    readch();
                    return Word.ne;
                }
                else return new Token('<');
            case '>':
                if (readch('=')) return Word.ge;
                else return new Token('>');
            case ':':
                if (readch('=')) return Word.atr;
                else return new Token(':');
        }

        // Números inteiros (sem zeros à esquerda)
        if (Character.isDigit(ch)) {
            if (Character.digit(ch, 10)==0) {
                readch();
                return new Num(0);
            } else {
                int value = 0;
                do {
                    value = 10 * value + Character.digit(ch, 10);
                    readch();
                } while (Character.isDigit(ch));
                return new Num(value);
            }
        }

        // Identificadores e palavras reservadas
        if (Character.isLetter(ch)) {
            StringBuilder sb = new StringBuilder();
            do {
                sb.append((char) ch);
                readch();
                // AND e OR
                if (sb.toString().equals("and") && !Character.isLetterOrDigit(ch)) return Word.and;
                if (sb.toString().equals("or") && !Character.isLetterOrDigit(ch)) return Word.or;
            } while (Character.isLetterOrDigit(ch));
            String s = sb.toString();
            Word w = words.get(s);
            if (w != null) return w;
            return new Word(s, Tag.ID);
        }

        // Literal
        if (ch==34) {
            StringBuilder sb = new StringBuilder();
            while (true) {
                readch();
                if (ch==34) {
                    readch();
                    break;
                }
                sb.append((char) ch);
            }
            String s = sb.toString();
            Word w = words.get(s);
            if (w != null) return w;
            return new Word(s, Tag.ID);
        }

        // Qualquer outro caractere (pontuação, operadores simples, etc.)
        Token t = new Token(ch);
        ch = ' ';
        return t;
    }
}