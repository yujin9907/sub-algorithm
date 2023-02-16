package algorithm.basic.stage02;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

// 45분 일찍 알림 맞추는 문제: 00시 일 때 생각을 못 했음

public class No2884 {
    public static void main(String[] args) throws IOException {
        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        // 이렇게 사용할 경우 -> numberfomat 에러
        // int h = Integer.parseInt(br.readLine());
        // int m = Integer.parseInt(br.readLine());

        String[] strs = br.readLine().split(" ");
        int h = Integer.parseInt(strs[0]);
        int m = Integer.parseInt(strs[1]);

        int an = m - 45;
        if (an >= 0) {
            System.out.println(h + " " + an);
        } else if (h - 1 < 0) {
            System.out.println("23 " + (60 + an));
        } else {
            System.out.println(h - 1 + " " + (60 + an));

        }
    }
}
