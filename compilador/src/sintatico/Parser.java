package sintatico;

import lexico.*;

public class Parser {
    private Lexer lex;
    private Token lookahead;

    public Parser(Lexer lex) {
        this.lex = lex;
        advance();
    }

    private void advance() {
        try {
            lookahead = lex.scan();
        } catch (Exception e) {
            error("Erro de leitura: " + e.getMessage());
        }
    }

    private void match(int tag) {
        if (lookahead.tag == tag) {
            advance();
        } else {
            error("Esperado " + tagToString(tag) + ", encontrado " + tokenToString(lookahead));
        }
    }

    private void error(String msg) {
        System.err.println("Erro sintático na linha " + Lexer.line + ": " + msg);
        System.exit(1);
    }

    private String tagToString(int tag) {
        if (tag >= 256) {
            switch (tag) {
                case Tag.CLASS: return "class";
                case Tag.INT: return "int";
                case Tag.STRING: return "string";
                case Tag.FLOAT: return "float";
                case Tag.IF: return "if";
                case Tag.ELSE: return "else";
                case Tag.DO: return "do";
                case Tag.WHILE: return "while";
                case Tag.REPEAT: return "repeat";
                case Tag.UNTIL: return "until";
                case Tag.READ: return "read";
                case Tag.WRITE: return "write";
                case Tag.NOT: return "not";
                case Tag.LE: return "<=";
                case Tag.GE: return ">=";
                case Tag.NE: return "<>";
                case Tag.OR: return "or";
                case Tag.AND: return "and";
                case Tag.ATR: return ":=";
                case Tag.NUM: return "número";
                case Tag.ID: return "identificador";
                case Tag.LITERAL: return "literal";
                default: return "token desconhecido";
            }
        } else {
            return "'" + (char) tag + "'";
        }
    }

    private String tokenToString(Token t) {
        if (t instanceof Word) {
            return "'" + ((Word) t).getLexeme() + "'";
        } else if (t instanceof Num) {
            return "número " + t.toString();
        } else if (t instanceof Literal) {
            return "literal \"" + ((Literal) t).getValue() + "\"";
        } else if (t.tag == -1) {
            return "fim de arquivo";
        } else {
            return "'" + (char) t.tag + "'";
        }
    }

    // ------------------ não-terminais principais ------------------

    public void program() {
        match(Tag.CLASS);
        match(Tag.ID);
        match('{');
        if (isDeclListStart()) {
            declList();
        }
        body();
        match('}');
        if (lookahead.tag != -1) {
            error("Conteúdo extra após o fim do programa");
        }
    }

    private boolean isDeclListStart() {
        return lookahead.tag == Tag.INT || lookahead.tag == Tag.STRING || lookahead.tag == Tag.FLOAT;
    }

    private void declList() {
        decl();
        match(';');
        while (isDeclListStart()) {
            decl();
            match(';');
        }
    }

    private void decl() {
        type();
        identList();
    }

    private void type() {
        if (lookahead.tag == Tag.INT) match(Tag.INT);
        else if (lookahead.tag == Tag.STRING) match(Tag.STRING);
        else if (lookahead.tag == Tag.FLOAT) match(Tag.FLOAT);
        else error("Esperado tipo (int, string, float)");
    }

    private void identList() {
        match(Tag.ID);
        while (lookahead.tag == ',') {
            match(',');
            match(Tag.ID);
        }
    }

    private void body() {
        match('{');
        stmtList();
        match('}');
    }

    private void stmtList() {
        stmt();
        match(';');
        while (isStmtStart()) {
            stmt();
            match(';');
        }
    }

    private boolean isStmtStart() {
        int t = lookahead.tag;
        return t == Tag.ID || t == Tag.IF || t == Tag.DO ||
                t == Tag.REPEAT || t == Tag.READ || t == Tag.WRITE;
    }

    private void stmt() {
        switch (lookahead.tag) {
            case Tag.ID: assignStmt(); break;
            case Tag.IF: ifStmt(); break;
            case Tag.DO: doStmt(); break;
            case Tag.REPEAT: repeatStmt(); break;
            case Tag.READ: readStmt(); break;
            case Tag.WRITE: writeStmt(); break;
            default: error("Comando inválido");
        }
    }

    private void assignStmt() {
        match(Tag.ID);
        match(Tag.ATR);
        simpleExpr();
    }

    private void ifStmt() {
        match(Tag.IF);
        match('(');
        condition();
        match(')');
        match('{');
        stmtList();
        match('}');
        ifStmtPrime();
    }

    private void ifStmtPrime() {
        if (lookahead.tag == Tag.ELSE) {
            match(Tag.ELSE);
            match('{');
            stmtList();
            match('}');
        }
        // λ
    }

    private void doStmt() {
        match(Tag.DO);
        match('{');
        stmtList();
        match('}');
        doSuffix();
    }

    private void doSuffix() {
        match(Tag.WHILE);
        match('(');
        condition();
        match(')');
    }

    private void repeatStmt() {
        match(Tag.REPEAT);
        match('{');
        stmtList();
        match('}');
        stmtSuffix();
    }

    private void stmtSuffix() {
        match(Tag.UNTIL);
        match('(');
        condition();
        match(')');
    }

    private void readStmt() {
        match(Tag.READ);
        match('(');
        match(Tag.ID);
        match(')');
    }

    private void writeStmt() {
        match(Tag.WRITE);
        match('(');
        writable();
        match(')');
    }

    private void writable() {
        simpleExpr();
    }

    private void condition() {
        expression();
    }

    // ------------------ expressões ------------------

    private void expression() {
        simpleExpr();
        expressionPrime();
    }

    private void expressionPrime() {
        if (isRelop()) {
            relop();
            simpleExpr();
        }
        // λ
    }

    private void simpleExpr() {
        term();
        simpleExprPrime();
    }

    private void simpleExprPrime() {
        while (isAddop()) {
            addop();
            term();
        }
    }

    private void term() {
        factorA();
        termPrime();
    }

    private void termPrime() {
        while (isMulop()) {
            mulop();
            factorA();
        }
    }

    private void factorA() {
        if (lookahead.tag == Tag.NOT) {
            match(Tag.NOT);
            factor();
        } else if (lookahead.tag == '-') {
            match('-');
            factor();
        } else {
            factor();
        }
    }

    private void factor() {
        if (lookahead.tag == Tag.ID) {
            match(Tag.ID);
        } else if (lookahead.tag == Tag.NUM || lookahead.tag == Tag.LITERAL) {
            constant();
        } else if (lookahead.tag == '(') {
            match('(');
            expression();
            match(')');
        } else {
            error("Fator esperado (identificador, constante, '(')");
        }
    }

    private void constant() {
        if (lookahead.tag == Tag.NUM) {
            match(Tag.NUM);
        } else if (lookahead.tag == Tag.LITERAL) {
            match(Tag.LITERAL);
        } else {
            error("Constante esperada (número ou literal)");
        }
    }

    // ------------------ operadores ------------------

    private boolean isRelop() {
        int t = lookahead.tag;
        return t == '>' || t == Tag.GE || t == '<' || t == Tag.LE || t == Tag.NE || t == '=';
    }

    private void relop() {
        if (isRelop()) advance();
        else error("Operador relacional esperado");
    }

    private boolean isAddop() {
        int t = lookahead.tag;
        return t == '+' || t == '-' || t == Tag.OR;
    }

    private void addop() {
        if (isAddop()) advance();
        else error("Operador aditivo esperado (+, -, or)");
    }

    private boolean isMulop() {
        int t = lookahead.tag;
        return t == '*' || t == '/' || t == '%' || t == Tag.AND;
    }

    private void mulop() {
        if (isMulop()) advance();
        else error("Operador multiplicativo esperado (*, /, %, and)");
    }
}