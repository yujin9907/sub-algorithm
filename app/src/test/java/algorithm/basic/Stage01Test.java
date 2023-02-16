package algorithm.basic;

import java.util.ArrayList;
import java.util.List;

import org.junit.jupiter.api.Test;

public class Stage01Test {

    @Test
    public void no2588() {

        int x = 472;
        int y = 385;
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

    @Test
    public void powTest() {
        System.out.println(Math.pow(10, 0));
    }
}
