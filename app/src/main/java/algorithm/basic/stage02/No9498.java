package algorithm.basic.stage02;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class No9498 {
    public static void main(String[] args) throws IOException {
        BufferedReader bf = new BufferedReader(new InputStreamReader(System.in));
        String line = bf.readLine();
        int a = Integer.parseInt(line);

        // switch(a2) {
        // case 1: a = "";
        // }
        if (a < 60) {
            System.out.println("F");
        } else if (a < 70) {
            System.out.println("D");
        } else if (a < 80) {
            System.out.println("C");
        } else if (a < 90) {
            System.out.println("B");
        } else {
            System.out.println("A");
        }
    }
}
