package com.microsoft.demo;

public class Demo {
    public void DoSomething(boolean flag){
        Test t = new Test();
        System.out.println(t.test(10));

        if(flag){
            System.out.println("I am covered");
            return;
        }

        System.out.println("I am not covered");
    }
}