import java.io.*;

import lexico.*;
import sintatico.*;

public class Main {
    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("Uso: java Main <arquivo fonte>");
            return;
        }

        try {
            Lexer lex = new Lexer(args[0]);
            Parser parser = new Parser(lex);
            parser.parse();

        } catch (FileNotFoundException e) {
            System.err.println("Arquivo não encontrado.");
        } catch (IOException e) {
            System.err.println("Erro de leitura: " + e.getMessage());
        }
    }
}