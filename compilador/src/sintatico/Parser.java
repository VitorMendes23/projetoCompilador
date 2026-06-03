package sintatico;

import java.io.*;

import lexico.*;

public class Parser {
    private Lexer lexer;
    private Token look;

    public Parser(Lexer lexer) throws IOException {
        this.lexer = lexer;
        move();
    }

    private void move() throws IOException {
        look = lexer.scan();
    }

    private void error(String msg) {
        System.err.println("Erro sintático na linha " + Lexer.line + ": " + msg);
        System.exit(1);
    }

    private String tokenLexeme(Token t) {
        if (t instanceof Word) return ((Word) t).getLexeme();
        if (t instanceof Num) return ((Num) t).toString();
        if (t instanceof Literal) return "\"" + ((Literal) t).getValue() + "\"";
        if (t.tag == -1) return "fim de arquivo";
        if (t.tag >= 32 && t.tag < 127) return String.valueOf((char) t.tag);
        return String.valueOf(t.tag);
    }

    private String expectedDesc(int tag) {
        switch (tag) {
            case Tag.CLASS: return "'class'";
            case Tag.ID: return "identificador";
            case Tag.NUM: return "constante numérica";
            case Tag.LITERAL: return "literal";
            case Tag.INT: return "'int'";
            case Tag.STRING: return "'string'";
            case Tag.FLOAT: return "'float'";
            case Tag.IF: return "'if'";
            case Tag.ELSE: return "'else'";
            case Tag.DO: return "'do'";
            case Tag.WHILE: return "'while'";
            case Tag.REPEAT: return "'repeat'";
            case Tag.UNTIL: return "'until'";
            case Tag.READ: return "'read'";
            case Tag.WRITE: return "'write'";
            case Tag.NOT: return "'not'";
            case Tag.ATR: return "':='";
            case Tag.LE: return "'<='";
            case Tag.GE: return "'>='";
            case Tag.NE: return "'<>'";
            case Tag.OR: return "'or'";
            case Tag.AND: return "'and'";
            case Tag.TRUE: return "'true'";
            case Tag.FALSE: return "'false'";
            default:
                if (tag >= 32 && tag < 127) return "'" + (char) tag + "'";
                return String.valueOf(tag);
        }
    }

    private void match(int tag) throws IOException {
        if (look.tag == tag) {
            move();
        } else {
            error("encontrado " + tokenLexeme(look) + ", esperado " + expectedDesc(tag));
        }
    }

    public void parse() throws IOException {
        program();
        if (look.tag != -1) {
            error("encontrado " + tokenLexeme(look) + " após o fim do programa");
        }
        System.out.println("Programa sintaticamente correto!");
    }

    // program ::= class identifier { decl_list body }
    private void program() throws IOException {
        match(Tag.CLASS);
        match(Tag.ID);
        match('{');
        declList();
        body();
        match('}');
    }

    // body ::= { stmt_list }
    private void body() throws IOException {
        match('{');
        stmtList();
        match('}');
    }

    // decl_list ::= decl ; decl_list | ε
    private void declList() throws IOException {
        while (isStartOfDecl()) {
            decl();
            match(';');
        }
    }

    private boolean isStartOfDecl() {
        return look.tag == Tag.INT || look.tag == Tag.STRING || look.tag == Tag.FLOAT;
    }

    // decl ::= type ident_list
    private void decl() throws IOException {
        type();
        identList();
    }

    // ident_list ::= identifier ident_list'
    private void identList() throws IOException {
        match(Tag.ID);
        identListPrime();
    }

    // ident_list' ::= , identifier ident_list' | ε
    private void identListPrime() throws IOException {
        while (look.tag == ',') {
            match(',');
            match(Tag.ID);
        }
    }

    // type ::= int | string | float
    private void type() throws IOException {
        if (isStartOfDecl()) {
            move();
        } else {
            error("encontrado " + tokenLexeme(look) + ", esperado tipo (int, string ou float)");
        }
    }

    // stmt_list ::= stmt ; { stmt ; }
    private void stmtList() throws IOException {
        stmt();
        match(';');
        while (isStartOfStmt()) {
            stmt();
            match(';');
        }
    }

    private boolean isStartOfStmt() {
        return look.tag == Tag.ID || look.tag == Tag.IF || look.tag == Tag.DO ||
               look.tag == Tag.REPEAT || look.tag == Tag.READ || look.tag == Tag.WRITE;
    }

    // stmt ::= assign_stmt | if_stmt | do_stmt | repeat_stmt | read_stmt | write_stmt
    private void stmt() throws IOException {
        switch (look.tag) {
            case Tag.ID:
                assignStmt();
                break;
            case Tag.IF:
                ifStmt();
                break;
            case Tag.DO:
                doStmt();
                break;
            case Tag.REPEAT:
                repeatStmt();
                break;
            case Tag.READ:
                readStmt();
                break;
            case Tag.WRITE:
                writeStmt();
                break;
            default:
                error("encontrado " + tokenLexeme(look) +
                      ", esperado início de comando (identificador, if, do, repeat, read ou write)");
        }
    }

    // assign_stmt ::= identifier := simple_expr
    private void assignStmt() throws IOException {
        match(Tag.ID);
        match(Tag.ATR);
        simpleExpr();
    }

    // if_stmt ::= if ( condition ) { stmt_list } else_part
    private void ifStmt() throws IOException {
        match(Tag.IF);
        match('(');
        condition();
        match(')');
        match('{');
        stmtList();
        match('}');
        elsePart();
    }

    // else_part ::= else { stmt_list } | ε
    private void elsePart() throws IOException {
        if (look.tag == Tag.ELSE) {
            match(Tag.ELSE);
            match('{');
            stmtList();
            match('}');
        }
    }

    // do_stmt ::= do { stmt_list } do_suffix
    private void doStmt() throws IOException {
        match(Tag.DO);
        match('{');
        stmtList();
        match('}');
        doSuffix();
    }

    // do_suffix ::= while ( condition )
    private void doSuffix() throws IOException {
        match(Tag.WHILE);
        match('(');
        condition();
        match(')');
    }

    // repeat_stmt ::= repeat { stmt_list } stmt_suffix
    private void repeatStmt() throws IOException {
        match(Tag.REPEAT);
        match('{');
        stmtList();
        match('}');
        stmtSuffix();
    }

    // stmt_suffix ::= until ( condition )
    private void stmtSuffix() throws IOException {
        match(Tag.UNTIL);
        match('(');
        condition();
        match(')');
    }

    // read_stmt ::= read ( identifier )
    private void readStmt() throws IOException {
        match(Tag.READ);
        match('(');
        match(Tag.ID);
        match(')');
    }

    // write_stmt ::= write ( writable )
    private void writeStmt() throws IOException {
        match(Tag.WRITE);
        match('(');
        writable();
        match(')');
    }

    // writable ::= simple_expr
    private void writable() throws IOException {
        simpleExpr();
    }

    // condition ::= expression
    private void condition() throws IOException {
        expression();
    }

    // expression ::= simple_expr expression'
    private void expression() throws IOException {
        simpleExpr();
        expressionPrime();
    }

    // expression' ::= relop simple_expr | ε
    private void expressionPrime() throws IOException {
        if (isRelop()) {
            relop();
            simpleExpr();
        }
    }

    private boolean isRelop() {
        return look.tag == '>' || look.tag == Tag.GE ||
               look.tag == '<' || look.tag == Tag.LE ||
               look.tag == Tag.NE || look.tag == '=';
    }

    // relop ::= > | >= | < | <= | <> | =
    private void relop() throws IOException {
        if (isRelop()) {
            move();
        } else {
            error("encontrado " + tokenLexeme(look) + ", esperado operador relacional");
        }
    }

    // simple_expr ::= term simple_expr'
    private void simpleExpr() throws IOException {
        term();
        simpleExprPrime();
    }

    // simple_expr' ::= addop term simple_expr' | ε
    private void simpleExprPrime() throws IOException {
        while (isAddop()) {
            addop();
            term();
        }
    }

    private boolean isAddop() {
        return look.tag == '+' || look.tag == '-' || look.tag == Tag.OR;
    }

    // addop ::= + | - | or
    private void addop() throws IOException {
        if (isAddop()) {
            move();
        } else {
            error("encontrado " + tokenLexeme(look) + ", esperado operador aditivo (+, - ou or)");
        }
    }

    // term ::= factor_a term'
    private void term() throws IOException {
        factorA();
        termPrime();
    }

    // term' ::= mulop factor_a term' | ε
    private void termPrime() throws IOException {
        while (isMulop()) {
            mulop();
            factorA();
        }
    }

    private boolean isMulop() {
        return look.tag == '*' || look.tag == '/' || look.tag == '%' || look.tag == Tag.AND;
    }

    // mulop ::= * | / | % | and
    private void mulop() throws IOException {
        if (isMulop()) {
            move();
        } else {
            error("encontrado " + tokenLexeme(look) + ", esperado operador multiplicativo (*, /, % ou and)");
        }
    }

    // factor_a ::= factor | not factor | - factor
    private void factorA() throws IOException {
        if (look.tag == Tag.NOT) {
            match(Tag.NOT);
            factor();
        } else if (look.tag == '-') {
            match('-');
            factor();
        } else {
            factor();
        }
    }

    // factor ::= identifier | constant | ( expression )
    private void factor() throws IOException {
        if (look.tag == Tag.ID || look.tag == Tag.NUM || look.tag == Tag.LITERAL) {
            move();
        } else if (look.tag == '(') {
            match('(');
            expression();
            match(')');
        } else {
            error("encontrado " + tokenLexeme(look) +
                  ", esperado identificador, constante numérica, literal ou '('");
        }
    }
}
