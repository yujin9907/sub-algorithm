package algorithm.basic.stage01;

import java.time.LocalDate;
import java.util.Scanner;

public class no10869 {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        int taiYear = sc.nextInt();

        String now = LocalDate.now().toString().substring(0, 4);
        System.out.println(taiYear + Integer.parseInt(now));
    }
}