package algorithm.practice;

import java.util.Scanner;

public class NextIntTest {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        int testNum = sc.nextInt();
        int testParamNum = sc.nextInt(testNum);
        System.out.println("----------");
        System.out.println("none : " + testNum);
        System.out.println("has : " + testParamNum);
    }
}
