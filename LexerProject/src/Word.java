public class Word extends Token {
    private String lexeme = "";

    // Operadores compostos e palavras reservadas (constantes estáticas)
    public static final Word le   = new Word("<=", Tag.LE);
    public static final Word ge   = new Word(">=", Tag.GE);
    public static final Word ne   = new Word("<>", Tag.NE);
    public static final Word or   = new Word("or", Tag.OR);
    public static final Word and  = new Word("and", Tag.AND);
    public static final Word atr  = new Word(":=", Tag.ATR);

    public static final Word True = new Word("true", Tag.TRUE);
    public static final Word False= new Word("false", Tag.FALSE);


    public Word(String s, int tag) {
        super(tag);
        lexeme = s;
    }

    public String getLexeme() {
        return lexeme;
    }

    @Override
    public String toString() {
        return lexeme;
    }
}