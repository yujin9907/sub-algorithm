package algorithm.basic.stage01;

import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class no2588 {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        int x = sc.nextInt();
        int y = sc.nextInt();
        int result = 0;
        int sum = 0;
        int total = 0;

        List<Integer> xList = new ArrayList<>();
        List<Integer> yList = new ArrayList<>();

        while (x > 0) {
            xList.add(x % 10);
            x /= 10;
            yList.add(y % 10);
            y /= 10;
        }

        // for (Integer xt : yList) {
        // System.out.println(xt);
        // }

        for (int i = 0; i < 3; i++) {
            for (int j = 0; j < 3; j++) {
                result = (int) (xList.get(j) * yList.get(i) * Math.pow(10, j + i));
                // System.out.println(result);
                sum += result;
            }
            System.out.println(sum / (int) Math.pow(10, i));
            total += sum;
            result = 0;
            sum = 0;
        }
        System.out.println(total);
    }
}
