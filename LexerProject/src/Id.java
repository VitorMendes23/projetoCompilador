public class Id {
    public String lexeme;  // nome do identificador
    public String type;

    public Id(String lexeme, String type) {
        this.lexeme = lexeme;
        this.type = type;
    }

    @Override
    public String toString() {
        return lexeme + " : " + type;
    }

}
