package tabela;

import codigo.Type;

public class Id {
    public static final int VAR = 0;
    public static final int RESERVED = 1;

    public String lexeme;
    public Type type;
    public int kind;
    public int offset;

    public Id(String lexeme, Type type, int kind) {
        this.lexeme = lexeme;
        this.type = type;
        this.kind = kind;
        this.offset = -1;
    }

    @Override
    public String toString() {
        return lexeme + (type != null ? " : " + type : "");
    }
}