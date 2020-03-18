import com.microsoft.demo.Demo;
import org.junit.Test;
import org.openqa.selenium.*;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.support.ui.Select;

public class MyTest {


    @Test
    public void test_method_1() {

        System.setProperty("webdriver.chrome.driver","/Users/Admin/Applications/chromedriver");
        WebDriver driver = new ChromeDriver();
        String baseUrl = "https://www.google.com/";

        String expectedTitle = "Google";
        String actualTitle = "";

        driver.get(baseUrl);
        actualTitle = driver.getTitle();

        if (actualTitle.contentEquals(expectedTitle)){
            System.out.println("Test Passed!");
        } else {
            System.out.println("Test Failed");
        }
        driver.close();
    }

    @Test
    public void test_method_2() {

        System.setProperty("webdriver.chrome.driver","/Users/Admin/Applications/chromedriver");
        WebDriver driver = new ChromeDriver();
        String baseUrl = "https://www.google.com/";
        driver.get(baseUrl);

        driver.findElement(By.xpath("//*[@id=\"tsf\"]/div[2]/div[1]/div[1]/div/div[2]/input")).sendKeys("vadim" + Keys.ENTER);
        driver.findElement(By.cssSelector("a[jsname=LgbsSe]")).click();

        driver.close();
    }
}