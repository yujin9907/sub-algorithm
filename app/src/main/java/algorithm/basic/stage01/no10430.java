package algorithm.basic.stage01;

import java.util.Scanner;

public class no10430 {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        int a = sc.nextInt();
        int b = sc.nextInt();
        int c = sc.nextInt();

        System.out.println((a + b) % c);
        System.out.println(((a % c) + (b % c)) % c);
        System.out.println((a * b) % c);
        System.out.println(((a % c) * (b % c)) % c);

        // case 1 은 분배법칙에 의해 성립한다
        // case 2 는 성립하지 않는다
    }
}
