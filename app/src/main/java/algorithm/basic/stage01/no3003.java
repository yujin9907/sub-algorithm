package algorithm.basic.stage01;

import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.NoArgsConstructor;

@Builder
@AllArgsConstructor
@NoArgsConstructor
class White {
    Integer king;
    Integer queen;
    Integer look;
    Integer bishop;
    Integer nite;

    public White(List<Integer> whites) {
        this.king = whites.get(0);
        this.queen = whites.get(1);
        this.look = whites.get(2);
        this.bishop = whites.get(3);
        this.nite = whites.get(4);
    }

    public White mius(White white) {
        return White.builder()
                .king(2 - white.king)
                .queen(2 - white.queen)
                .bishop(2 - white.bishop)
                .look(2 - white.look)
                .nite(2 - nite)
                .build();
    }
}

public class no3003 {

    public static void main(String[] args) {

        Scanner s = new Scanner(System.in);

        int king = 1 - s.nextInt();
        int queen = 1 - s.nextInt();
        int bishop = 2 - s.nextInt();
        int look = 2 - s.nextInt();
        int nite = 2 - s.nextInt();
        int pon = 8 - s.nextInt();

        System.out.println(king + " " + queen + " " + bishop + " " + look + " " + nite);

    }

    public void solve1() {
        Scanner sc = new Scanner(System.in);
        List<Integer> whites = new ArrayList<>();

        for (int i = 0; i < 5; i++) {
            int a = sc.nextInt();
            whites.add(a);
        }

        White w = new White(whites);
        w = w.mius(w);

        for (Integer piece : whites) {
            System.out.println(piece);
        }
    }
}
