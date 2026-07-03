package codigo;

import java.io.*;

public class VMGen {
    private StringBuilder sb = new StringBuilder();
    private int labelCounter = 0;

    public String newLabel() {
        return "L" + (labelCounter++);
    }

    public void emit(String s) {
        sb.append(s).append("\n");
    }

    public void emitLabel(String l) {
        sb.append(l).append(":\n");
    }

    public int saveOutput(String filename) throws IOException {
        try (PrintWriter pw = new PrintWriter(new FileWriter(filename))) {
            pw.print(sb.toString());
        }
        return sb.length();
    }

    public String getOutput() {
        return sb.toString();
    }
}
