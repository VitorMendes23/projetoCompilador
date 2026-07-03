import lexico.Lexer;
import sintatico.Parser;

import java.io.*;

public class Main {
    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("Uso: java Main <arquivo fonte>");
            return;
        }

        try {
            Lexer lex = new Lexer(args[0]);
            Parser parser = new Parser(lex, lex.getEnv());
            parser.program();

            String outFile = args[0].replaceFirst("\\.[^.]+$", "") + ".vm";
            parser.getVMGen().saveOutput(outFile);
            System.out.println("Programa compilado com sucesso. Codigo VM gerado: " + outFile);
        } catch (FileNotFoundException e) {
            System.err.println("Arquivo nao encontrado.");
        } catch (IOException e) {
            System.err.println("Erro de leitura: " + e.getMessage());
        }
    }
}