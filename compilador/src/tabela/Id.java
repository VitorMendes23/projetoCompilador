package tabela;

public class Id {
    public String lexeme;
    public String type;

    public Id(String lexeme, String type) {
        this.lexeme = lexeme;
        this.type = type;
    }

    @Override
    public String toString() {
        return lexeme + (type != null ? " : " + type : "");
    }
}