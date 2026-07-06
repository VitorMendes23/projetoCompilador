package sintatico;

import codigo.Type;
import codigo.VMGen;
import lexico.*;
import tabela.Env;
import tabela.Id;

public class Parser {
    private Lexer lex;
    private Token lookahead;
    private VMGen vm = new VMGen();
    private Env topEnv;
    private int nextOffset = 0;

    public Parser(Lexer lex, Env env) {
        this.lex = lex;
        this.topEnv = env;
        advance();
    }

    public VMGen getVMGen() {
        return vm;
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
        System.err.println("Erro sintatico na linha " + Lexer.line + ": " + msg);
        System.exit(1);
    }

    private void errorSem(String msg) {
        System.err.println("Erro semantico na linha " + Lexer.line + ": " + msg);
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
                case Tag.NUM: return "numero";
                case Tag.ID: return "identificador";
                case Tag.LITERAL: return "literal";
                case Tag.TRUE: return "true";
                case Tag.FALSE: return "false";
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
            return "numero " + t.toString();
        } else if (t instanceof Literal) {
            return "literal \"" + ((Literal) t).getValue() + "\"";
        } else if (t.tag == -1) {
            return "fim de arquivo";
        } else {
            return "'" + (char) t.tag + "'";
        }
    }

    // ------------------ programa principal ------------------

    public void program() {
        match(Tag.CLASS);
        match(Tag.ID);
        match('{');
        if (isDeclListStart()) {
            declList();
        }
        vm.emit("START");
        vm.emit("PUSHN " + nextOffset);
        body();
        vm.emit("STOP");
        match('}');
        if (lookahead.tag != -1) {
            error("Conteudo extra apos o fim do programa");
        }
    }

    // ------------------ declaracoes ------------------

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
        Type t = type();
        identList(t);
    }

    private Type type() {
        if (lookahead.tag == Tag.INT) { match(Tag.INT); return Type.INT; }
        if (lookahead.tag == Tag.STRING) { match(Tag.STRING); return Type.STRING; }
        if (lookahead.tag == Tag.FLOAT) { match(Tag.FLOAT); return Type.FLOAT; }
        error("Esperado tipo (int, string, float)");
        return Type.ERROR;
    }

    private void identList(Type t) {
        declareId(t);
        while (lookahead.tag == ',') {
            match(',');
            declareId(t);
        }
    }

    private void declareId(Type t) {
        String name = ((Word) lookahead).getLexeme();
        match(Tag.ID);
        if (topEnv.getCurrentScope(name) != null) {
            errorSem("Variavel '" + name + "' ja declarada");
        }
        Id id = new Id(name, t, Id.VAR);
        id.offset = nextOffset;
        nextOffset += t.width();
        topEnv.put(name, id);
    }

    // ------------------ corpo (bloco de comandos) ------------------

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
            default: error("Comando invalido");
        }
    }

    // ------------------ atribuicao ------------------

    private void assignStmt() {
        String name = ((Word) lookahead).getLexeme();
        match(Tag.ID);
        Id id = topEnv.get(name);
        if (id == null) errorSem("Variavel '" + name + "' nao declarada");
        if (id.kind == Id.RESERVED) errorSem("'" + name + "' e palavra reservada");
        match(Tag.ATR);
        Type exprType = simpleExpr();
        if (!isAssignable(id.type, exprType)) {
            errorSem("Tipos incompativeis na atribuicao: " + id.type + " := " + exprType);
        }
        if (id.type == Type.FLOAT && exprType == Type.INT) {
            vm.emit("ITOF");
        }
        vm.emit("STOREL " + id.offset);
    }

    private boolean isAssignable(Type target, Type value) {
        if (target == value) return true;
        if (target == Type.FLOAT && value == Type.INT) return true;
        return false;
    }

    // ------------------ if/else ------------------

    private void ifStmt() {
        match(Tag.IF);
        match('(');
        Type condType = condition();
        if (condType != Type.BOOLEAN) {
            errorSem("Condicao if deve ser booleana, encontrado " + condType);
        }
        String elseLabel = vm.newLabel();
        vm.emit("JZ " + elseLabel);
        match(')');
        match('{');
        stmtList();
        match('}');
        String endLabel = vm.newLabel();
        vm.emit("JUMP " + endLabel);
        ifStmtPrime(elseLabel);
        vm.emitLabel(endLabel);
    }

    private void ifStmtPrime(String elseLabel) {
        if (lookahead.tag == Tag.ELSE) {
            match(Tag.ELSE);
            vm.emitLabel(elseLabel);
            match('{');
            stmtList();
            match('}');
        } else {
            vm.emitLabel(elseLabel);
        }
    }

    // ------------------ do/while ------------------

    private void doStmt() {
        match(Tag.DO);
        String loopLabel = vm.newLabel();
        vm.emitLabel(loopLabel);
        match('{');
        stmtList();
        match('}');
        doSuffix(loopLabel);
    }

    private void doSuffix(String loopLabel) {
        match(Tag.WHILE);
        match('(');
        Type condType = condition();
        if (condType != Type.BOOLEAN) {
            errorSem("Condicao while deve ser booleana, encontrado " + condType);
        }
        String endLabel = vm.newLabel();
        vm.emit("JZ " + endLabel);
        vm.emit("JUMP " + loopLabel);
        vm.emitLabel(endLabel);
        match(')');
    }

    // ------------------ repeat/until ------------------

    private void repeatStmt() {
        match(Tag.REPEAT);
        String loopLabel = vm.newLabel();
        vm.emitLabel(loopLabel);
        match('{');
        stmtList();
        match('}');
        stmtSuffix(loopLabel);
    }

    private void stmtSuffix(String loopLabel) {
        match(Tag.UNTIL);
        match('(');
        Type condType = condition();
        if (condType != Type.BOOLEAN) {
            errorSem("Condicao until deve ser booleana, encontrado " + condType);
        }
        String endLabel = vm.newLabel();
        vm.emit("NOT");
        vm.emit("JZ " + endLabel);
        vm.emit("JUMP " + loopLabel);
        vm.emitLabel(endLabel);
        match(')');
    }

    // ------------------ read / write ------------------

    private void readStmt() {
        match(Tag.READ);
        match('(');
        String name = ((Word) lookahead).getLexeme();
        match(Tag.ID);
        Id id = topEnv.get(name);
        if (id == null) errorSem("Variavel '" + name + "' nao declarada");
        if (id.kind == Id.RESERVED) errorSem("'" + name + "' e palavra reservada");
        vm.emit("READ");
        if (id.type == Type.INT) vm.emit("ATOI");
        else if (id.type == Type.FLOAT) vm.emit("ATOF");
        vm.emit("STOREL " + id.offset);
        match(')');
    }

    private void writeStmt() {
        match(Tag.WRITE);
        match('(');
        Type t = writable();
        if (t == Type.INT) vm.emit("WRITEI");
        else if (t == Type.FLOAT) vm.emit("WRITEF");
        else if (t == Type.STRING) vm.emit("WRITES");
        else if (t == Type.BOOLEAN) vm.emit("WRITEI");
        match(')');
    }

    private Type writable() {
        return simpleExpr();
    }

    // ------------------ condicao ------------------

    private Type condition() {
        return expression();
    }

    // ------------------ expressoes ------------------

    private Type expression() {
        Type left = simpleExpr();
        Type right = expressionPrime(left);
        return right != null ? right : left;
    }

    private Type expressionPrime(Type leftType) {
        if (isRelop()) {
            String op = relopToken();
            relop();
            Type rightType = simpleExpr();
            return emitRelop(leftType, rightType, op);
        }
        return null;
    }

    private Type simpleExpr() {
        Type left = term();
        while (isAddop()) {
            String op = addopToken();
            addop();
            Type right = term();
            left = emitAddOp(left, right, op);
        }
        return left;
    }

    private Type term() {
        Type left = factorA();
        while (isMulop()) {
            String op = mulopToken();
            mulop();
            Type right = factorA();
            left = emitMulOp(left, right, op);
        }
        return left;
    }

    private Type factorA() {
        if (lookahead.tag == Tag.NOT) {
            match(Tag.NOT);
            Type t = factor();
            if (t != Type.BOOLEAN) {
                errorSem("Operando de 'not' deve ser booleano, encontrado " + t);
            }
            vm.emit("NOT");
            return Type.BOOLEAN;
        }
        if (lookahead.tag == '-') {
            match('-');
            Type t = factor();
            if (t != Type.INT && t != Type.FLOAT) {
                errorSem("Operando de '-' unario deve ser numerico, encontrado " + t);
            }
            if (t == Type.INT) {
                vm.emit("PUSHI 0");
                vm.emit("SWAP");
                vm.emit("SUB");
            } else {
                vm.emit("PUSHF 0.0");
                vm.emit("SWAP");
                vm.emit("FSUB");
            }
            return t;
        }
        return factor();
    }

    private Type factor() {
        if (lookahead.tag == Tag.ID) {
            String name = ((Word) lookahead).getLexeme();
            match(Tag.ID);
            Id id = topEnv.get(name);
            if (id == null) errorSem("Variavel '" + name + "' nao declarada");
            if (id.kind == Id.RESERVED) errorSem("'" + name + "' e palavra reservada");
            vm.emit("PUSHL " + id.offset);
            return id.type;
        }
        if (lookahead.tag == Tag.NUM) {
            return consumeNum();
        }
        if (lookahead.tag == Tag.LITERAL) {
            return consumeLiteral();
        }
        if (lookahead.tag == Tag.TRUE) {
            match(Tag.TRUE);
            vm.emit("PUSHI 1");
            return Type.BOOLEAN;
        }
        if (lookahead.tag == Tag.FALSE) {
            match(Tag.FALSE);
            vm.emit("PUSHI 0");
            return Type.BOOLEAN;
        }
        if (lookahead.tag == '(') {
            match('(');
            Type t = expression();
            match(')');
            return t;
        }
        error("Fator esperado (identificador, constante, '(')");
        return Type.ERROR;
    }

    private Type consumeNum() {
        Num num = (Num) lookahead;
        match(Tag.NUM);
        if (num.isReal) {
            vm.emit("PUSHF " + num.realValue);
            return Type.FLOAT;
        } else {
            vm.emit("PUSHI " + num.intValue);
            return Type.INT;
        }
    }

    private Type consumeLiteral() {
        String val = ((Literal) lookahead).getValue();
        match(Tag.LITERAL);
        vm.emit("PUSHS \"" + escapeString(val) + "\"");
        return Type.STRING;
    }

    private String escapeString(String s) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '\n': sb.append("\\n"); break;
                case '\t': sb.append("\\t"); break;
                case '\r': sb.append("\\r"); break;
                case '"': sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                default: sb.append(c);
            }
        }
        return sb.toString();
    }

    // ------------------ operadores ------------------

    private boolean isRelop() {
        int t = lookahead.tag;
        return t == '>' || t == Tag.GE || t == '<' || t == Tag.LE || t == Tag.NE || t == '=';
    }

    private String relopToken() {
        int t = lookahead.tag;
        if (t == '>') return ">";
        if (t == Tag.GE) return ">=";
        if (t == '<') return "<";
        if (t == Tag.LE) return "<=";
        if (t == Tag.NE) return "<>";
        if (t == '=') return "=";
        return "";
    }

    private void relop() {
        if (isRelop()) advance();
        else error("Operador relacional esperado");
    }

    private boolean isAddop() {
        int t = lookahead.tag;
        return t == '+' || t == '-' || t == Tag.OR;
    }

    private String addopToken() {
        int t = lookahead.tag;
        if (t == '+') return "+";
        if (t == '-') return "-";
        if (t == Tag.OR) return "or";
        return "";
    }

    private void addop() {
        if (isAddop()) advance();
        else error("Operador aditivo esperado (+, -, or)");
    }

    private boolean isMulop() {
        int t = lookahead.tag;
        return t == '*' || t == '/' || t == '%' || t == Tag.AND;
    }

    private String mulopToken() {
        int t = lookahead.tag;
        if (t == '*') return "*";
        if (t == '/') return "/";
        if (t == '%') return "%";
        if (t == Tag.AND) return "and";
        return "";
    }

    private void mulop() {
        if (isMulop()) advance();
        else error("Operador multiplicativo esperado (*, /, %, and)");
    }

    // ------------------ geracao de codigo para operacoes ------------------

    private Type emitAddOp(Type left, Type right, String op) {
        if (op.equals("or")) {
            if (left != Type.BOOLEAN) errorSem("Operando esquerdo de 'or' deve ser booleano, encontrado " + left);
            if (right != Type.BOOLEAN) errorSem("Operando direito de 'or' deve ser booleano, encontrado " + right);
            vm.emit("ADD");
            vm.emit("PUSHI 0");
            vm.emit("SUP");
            return Type.BOOLEAN;
        }
        if (left == Type.STRING || right == Type.STRING) {
            return emitConcat(left, right);
        }
        if (left == Type.INT && right == Type.INT) {
            if (op.equals("+")) vm.emit("ADD");
            else if (op.equals("-")) vm.emit("SUB");
            else vm.emit("ADD");
            return Type.INT;
        }
        if (left == Type.FLOAT && right == Type.FLOAT) {
            if (op.equals("+")) vm.emit("FADD");
            else if (op.equals("-")) vm.emit("FSUB");
            else vm.emit("FADD");
            return Type.FLOAT;
        }
        if (right == Type.INT) {
            vm.emit("ITOF");
            right = Type.FLOAT;
        }
        if (left == Type.INT) {
            vm.emit("SWAP");
            vm.emit("ITOF");
            vm.emit("SWAP");
            left = Type.FLOAT;
        }
        if (op.equals("+")) vm.emit("FADD");
        else if (op.equals("-")) vm.emit("FSUB");
        else vm.emit("FADD");
        return Type.FLOAT;
    }

    private Type emitMulOp(Type left, Type right, String op) {
        if (op.equals("and")) {
            if (left != Type.BOOLEAN) errorSem("Operando esquerdo de 'and' deve ser booleano, encontrado " + left);
            if (right != Type.BOOLEAN) errorSem("Operando direito de 'and' deve ser booleano, encontrado " + right);
            vm.emit("MUL");
            return Type.BOOLEAN;
        }
        if (op.equals("%")) {
            if (left != Type.INT) errorSem("Operando esquerdo de '%%' deve ser inteiro, encontrado " + left);
            if (right != Type.INT) errorSem("Operando direito de '%%' deve ser inteiro, encontrado " + right);
            vm.emit("MOD");
            return Type.INT;
        }
        if (op.equals("/")) {
            if (right == Type.INT) { vm.emit("ITOF"); right = Type.FLOAT; }
            if (left == Type.INT) { vm.emit("SWAP"); vm.emit("ITOF"); vm.emit("SWAP"); left = Type.FLOAT; }
            vm.emit("FDIV");
            return Type.FLOAT;
        }
        if (left == Type.INT && right == Type.INT) {
            vm.emit("MUL");
            return Type.INT;
        }
        if (left == Type.FLOAT && right == Type.FLOAT) {
            vm.emit("FMUL");
            return Type.FLOAT;
        }
        if (right == Type.INT) {
            vm.emit("ITOF");
            right = Type.FLOAT;
        }
        if (left == Type.INT) {
            vm.emit("SWAP");
            vm.emit("ITOF");
            vm.emit("SWAP");
            left = Type.FLOAT;
        }
        vm.emit("FMUL");
        return Type.FLOAT;
    }

    private Type emitRelop(Type left, Type right, String op) {
        if (left == Type.STRING && right == Type.STRING) {
            if (!op.equals("=") && !op.equals("<>")) {
                errorSem("Operador relacional '" + op + "' nao suportado para strings");
            }
            vm.emit("EQUAL");
            if (op.equals("<>")) vm.emit("NOT");
            return Type.BOOLEAN;
        }
        if (left == Type.BOOLEAN && right == Type.BOOLEAN) {
            if (!op.equals("=") && !op.equals("<>")) {
                errorSem("Operador relacional '" + op + "' nao suportado para booleanos");
            }
            vm.emit("EQUAL");
            if (op.equals("<>")) vm.emit("NOT");
            return Type.BOOLEAN;
        }
        if (left == Type.INT && right == Type.INT) {
            switch (op) {
                case "=": vm.emit("EQUAL"); break;
                case "<>": vm.emit("EQUAL"); vm.emit("NOT"); break;
                case "<": vm.emit("INF"); break;
                case "<=": vm.emit("INFEQ"); break;
                case ">": vm.emit("SUP"); break;
                case ">=": vm.emit("SUPEQ"); break;
            }
            return Type.BOOLEAN;
        }
        if (right == Type.INT) { vm.emit("ITOF"); right = Type.FLOAT; }
        if (left == Type.INT) { vm.emit("SWAP"); vm.emit("ITOF"); vm.emit("SWAP"); left = Type.FLOAT; }
        if (left == Type.FLOAT && right == Type.FLOAT) {
            switch (op) {
                case "=": vm.emit("EQUAL"); break;
                case "<>": vm.emit("EQUAL"); vm.emit("NOT"); break;
                case "<": vm.emit("INF"); break;
                case "<=": vm.emit("INFEQ"); break;
                case ">": vm.emit("SUP"); break;
                case ">=": vm.emit("SUPEQ"); break;
            }
            return Type.BOOLEAN;
        }
        errorSem("Tipos incompativeis para comparacao: " + left + " e " + right);
        return Type.ERROR;
    }

    private Type emitConcat(Type left, Type right) {
        if (right == Type.INT) vm.emit("STRI");
        else if (right == Type.FLOAT) vm.emit("STRF");
        else if (right != Type.STRING) errorSem("Tipo invalido para concatenacao: " + right);
        vm.emit("SWAP");
        if (left == Type.INT) vm.emit("STRI");
        else if (left == Type.FLOAT) vm.emit("STRF");
        else if (left != Type.STRING) errorSem("Tipo invalido para concatenacao: " + left);
        vm.emit("CONCAT");
        return Type.STRING;
    }
}
