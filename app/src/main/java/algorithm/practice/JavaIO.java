package algorithm.practice;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.Scanner;
import java.util.StringTokenizer;

public class JavaIO {
    // 콘솔 입력 방식
    public static void main(String[] args) throws IOException {
        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        StringTokenizer st = new StringTokenizer(br.readLine()); // StringTokenizer인자값에 문자열 추가 (한줄 읽기)
        int a = Integer.parseInt(st.nextToken()); // 쪼개기
        int b = Integer.parseInt(st.nextToken()); // 쪼개기

        System.out.println(a);
        System.out.println(b);

        br.close();

        // 2
        BufferedReader bf = new BufferedReader(new InputStreamReader(System.in));
        String[] line = bf.readLine().split(" ");
        String a2 = line[0] + line[1];
        String b2 = line[2] + line[3];
        long result = Long.valueOf(a) + Long.valueOf(b2);
        System.out.println(result);
        // 10 20 30 40
        // 4060

        // 3
        Scanner sc = new Scanner(System.in);
        int a3 = sc.nextInt();
        StringBuilder sb = new StringBuilder();
        for (int i = 1; i <= a3; i++)
            sb.append(i + "\n");
        System.out.println(sb);

    }
}

class ScannerIO {
    // 키보드와 연결된 자바 표준 입력 스트림
    // system.in.read()를 통해 한 바이트씩 읽음 (java.io의 system.in 클래스) => 즉 한글 안 됨
    // 기본적으로 아스키코드로 값을 받음
    // byte를 문자나 숫자로 변환해 줘야 됨
}

class BufferedReaderIO {
    public void Buffered() throws IOException {
        // BufferedReader를 사용하기 위해서 throws IOException 로 예외처리

        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        StringTokenizer st = new StringTokenizer(br.readLine()); // StringTokenizer인자값에 문자열 추가 (한줄 읽기)
        int a = Integer.parseInt(st.nextToken()); // 쪼개기
        int b = Integer.parseInt(st.nextToken()); // 쪼개기

        System.out.println(a);
        System.out.println(b);

        br.close();
    }
}
