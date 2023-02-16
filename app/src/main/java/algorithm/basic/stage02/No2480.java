package algorithm.basic.stage02;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class No2480 {
    public static void main(String[] args) throws IOException {
        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        List<String> list = Arrays.asList(br.readLine().split(" "));
        int a = Integer.parseInt(list.get(0));
        int b = Integer.parseInt(list.get(1));
        int c = Integer.parseInt(list.get(2));

        // 중복을 제거해서 값이 1 이면 세개가 같고 2면 두개가 같고 3이면 같은 게 없다
        // 근데 출력을 하려고 보니까 답이 없다 같은 게 뭔지 어떻게 알건데?
        List<String> cnt = list.stream().distinct().collect(Collectors.toList());

        if (cnt.size() == 1) {
            System.out.println(10000 + a * 1000);
        }
        if (cnt.size() == 2) {
            System.out.println(1000);
        }

        // 같은 게 먼지 알아내려고 직접 비교했다
        // 근데 일일이 sout 쓰고 싶지 않아서 아래 저지랄을 하다가 이건 아니다 싶어서
        int data = 0;

        if (a == b) {
            if (a == c) {
                data = a;
            } else {
                data = a;
            }
        } else {
            if (b == c) {
                data = b;
            }
        }

        List<Integer> intlist = list.stream().map((s) -> Integer.parseInt(s)).collect(Collectors.toList());
        if (data == 0) {
            System.out.println(Collections.max(intlist) * 100);
        }

        // 지랄 그냥 if 문 세네줄 써서 풀자... : 인터넷엔, 세네줄로 else if로 깔끔하게 / 클래스를 작성해서 구한 경우도 있었음
    }
}
