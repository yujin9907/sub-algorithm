package algorithm.basic.stage01;

import java.time.LocalDate;
import java.util.Scanner;

public class no10808 {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        int taiYear = 2541;

        String now = LocalDate.now().toString().substring(0, 4);

        System.out.println(2541 - 1998);
        System.out.println(taiYear - 543);
    }
}
