package algorithm.basic.stage01;

import java.util.Scanner;

public class no1000 {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        double a = sc.nextInt();
        double b = sc.nextInt();

        // vscode debug console은 input 못 받는대
        // double a = 10;
        // double b = 3;

        System.out.println(a / b); // 1001, 10998
    }
}
