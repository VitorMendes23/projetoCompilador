public class Tag {
    // Palavras reservadas: class, int, string, float, if, else, do, while, repeat, until, read, write, not
    public static final int CLASS   = 256;
    public static final int INT     = 257;
    public static final int STRING  = 258;
    public static final int FLOAT   = 259;
    public static final int IF      = 260;
    public static final int ELSE    = 261;
    public static final int DO      = 262;
    public static final int WHILE   = 263;
    public static final int REPEAT  = 264;
    public static final int UNTIL   = 265;
    public static final int READ    = 266;
    public static final int WRITE   = 267;
    public static final int NOT     = 268;
    public static final int TRUE    = 269;
    public static final int FALSE   = 270;

    // Operadores e pontuação
    public static final int LE  = 290;   // <=
    public static final int GE  = 291;   // >=
    public static final int NE  = 292;   // <>
    public static final int OR  = 293;   // or
    public static final int AND = 294;   // and
    public static final int ATR = 295;   // :=

    // Outros tokens
    public static final int NUM = 280;
    public static final int ID  = 281;

    // Operadores de um caractere (usaremos o próprio caractere como código)
    // Ex: '<' vale 60, '>' vale 62, '=' vale 61, etc.
}