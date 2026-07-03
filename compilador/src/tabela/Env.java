package tabela;

import java.util.*;

public class Env {
    private Hashtable<String, Id> table;
    protected Env prev;

    public Env(Env n) {
        table = new Hashtable<>();
        prev = n;
    }

    public void put(String lexeme, Id i) {
        table.put(lexeme, i);
    }

    public Id get(String lexeme) {
        for (Env e = this; e != null; e = e.prev) {
            Id found = e.table.get(lexeme);
            if (found != null)
                return found;
        }
        return null;
    }

    public Id getCurrentScope(String lexeme) {
        return table.get(lexeme);
    }

    public int size() {
        return table.size();
    }

    public void print() {
        List<String> keys = new ArrayList<>(table.keySet());
        Collections.sort(keys);
        for (String key : keys) {
            Id id = table.get(key);
            System.out.println(key + " -> " + id);
        }
    }
}