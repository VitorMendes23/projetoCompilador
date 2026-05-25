import java.io.*;

public class Main {
    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("Uso: java Main <arquivo fonte>");
            return;
        }

        try {
            Lexer lex = new Lexer(args[0]);
            Token t;

            System.out.println("=== SAÍDA DE TOKENS ===");
            while (true) {
                t = lex.scan();
                if (t.tag == -1) break;

                if (t instanceof Num) {
                    Num n = (Num) t;
                    System.out.println("<NUM, " + n.toString() + ">");
                } else if (t instanceof Literal) {
                    Literal lit = (Literal) t;
                    System.out.println("<LITERAL, \"" + lit.getValue() + "\">");
                } else if (t instanceof Word) {
                    Word w = (Word) t;
                    if (w.tag == Tag.ID)
                        System.out.println("<ID, \"" + w.getLexeme() + "\">");
                    else
                        System.out.println("<" + w.getLexeme() + ">");
                } else {
                    System.out.println("<" + (char) t.tag + ">");
                }
            }

            lex.printSymbolTable();

        } catch (FileNotFoundException e) {
            System.err.println("Arquivo não encontrado.");
        } catch (IOException e) {
            System.err.println("Erro de leitura: " + e.getMessage());
        }
    }
}