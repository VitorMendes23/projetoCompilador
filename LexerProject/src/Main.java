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
            Env env;

            while (true) {
                t = lex.scan();
                if (t.tag == -1) break;
                if (t instanceof Num)
                    System.out.println("<NUM, \"" + t.toString() + "\">");
                else if (t instanceof Word) {
                    Word w = (Word) t;
                    System.out.println("<" + w.toString() + ", \"" + w.getLexeme() + "\">");
                } else {
                    System.out.println("<'" + (char) t.tag + "', \"" + (char) t.tag + "\">");
                }
            }
            System.out.println("\n== TABELA DE SÍMBOLOS ==");
            lex.printSymbolTable();

        } catch (FileNotFoundException e) {
            System.err.println("Arquivo não encontrado.");
        } catch (IOException e) {
            System.err.println("Erro de leitura: " + e.getMessage());
        }
    }
}