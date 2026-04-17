public class Num extends Token {
    public final int value;
    public final double realValue;

    public Num(int value) {
        super(Tag.NUM);
        this.value = value;
        this.realValue = 0;
    }

    public Num(double realValue) {
        super(Tag.NUM);
        this.value = 0;
        this.realValue = realValue;
    }

    @Override
    public String toString() {
        if (value != 0){
            return "" + value;
        }else if (realValue != 0){
            return "" + realValue;
        }
        return "";
    }
}