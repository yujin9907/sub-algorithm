package algorithm.practice;

public class StaticVariable {
    // 변수 스코프 알아보기 위해서

    int num;

    void getVariable() {
        num = 1;
    }

    public void publicVariable() {
        num = 1;
    }

    public static void main(String[] args) {
    }
}
