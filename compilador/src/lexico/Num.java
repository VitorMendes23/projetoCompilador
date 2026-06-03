package lexico;

public class Num extends Token {
    public final int intValue;
    public final double realValue;
    public final boolean isReal;

    public Num(int value) {
        super(Tag.NUM);
        this.intValue = value;
        this.realValue = 0.0;
        this.isReal = false;
    }

    public Num(double realValue) {
        super(Tag.NUM);
        this.intValue = 0;
        this.realValue = realValue;
        this.isReal = true;
    }

    @Override
    public String toString() {
        if (isReal)
            return String.valueOf(realValue);
        else
            return String.valueOf(intValue);
    }
}