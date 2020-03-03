import org.junit.Test;
import org.junit.experimental.categories.Category;

import static org.junit.Assert.assertTrue;

@Category(DBTest.class)
public class MyDBTest {

    @Test
    public void dbTest() throws InterruptedException {
        Thread.sleep(3600000 * 10);
        assertTrue(true);
    }
}
