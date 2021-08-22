package com.microsoft.demo;

public class Demo {
    public void DoSomething(boolean flag){
        if(flag){
            System.out.println("I am covered");
            return;
        }

        System.out.println("I am not covered");
    }

    public void sayHello(String name){
        System.out.println("Hello " + name);
    }

    public void sayBye(String name){
        System.out.println("See you again " + name);
    }
}