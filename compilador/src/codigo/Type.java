package codigo;

public enum Type {
    INT(4),
    FLOAT(8),
    STRING(4),
    BOOLEAN(4),
    VOID(0),
    ERROR(0);

    private final int width;

    Type(int width) {
        this.width = width;
    }

    public int width() {
        return width;
    }
}
