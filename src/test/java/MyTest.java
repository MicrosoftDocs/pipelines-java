import com.microsoft.demo.Demo;
import org.junit.Test;

public class MyTest {
    @Test
    public void test_method_1() {
        Demo d = new Demo();
        d.DoSomething(true);
    }

    @Test
    public void test_method_2() {
        Demo d1 = new Demo();
        d1.DoSomething(false);
    }

    @Test
    public void test_method_3() {
    }

    @Test
    public void test_method_4() {
    }

    @Test
    public void test_method_5() {
    }
}