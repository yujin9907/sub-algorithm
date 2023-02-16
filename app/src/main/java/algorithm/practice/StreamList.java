package algorithm.practice;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collector;
import java.util.stream.Collectors;

public class StreamList {
    List<Integer> testList = Arrays.asList(1, 2, 3, 4, 5);

    public void 중복제거하기() {
        List<Integer> newList = testList.stream().distinct().collect(Collectors.toList());
    }

    public void remove() {
        // 리스트라는 메모리에 있는 요소를 진짜 빼버리는 거임
        testList.remove(0); // 인덱스 0 번
        testList.remove(new Integer(1)); // 오브젝트 1, 문자면 상관없는데 숫자면 인덱스로 인식하지 않도록 이렇게 넣어줌
    }

    public void 최대최소구하기() {
        int max = Collections.max(testList);
        int min = Collections.min(testList);
    }

    public void 배열과리스트() {
        int[] li = { 1, 2, 3, 4 };
        List<int[]> arrayToList = Arrays.asList(li);
        Object[] listToArray = testList.toArray();
    }
}
