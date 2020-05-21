package com.microsoft.demo;

public class Demo {
    public void DoSomething(boolean flag){
        if(flag){
            System.out.println("I am covered");
            return;
        }
        
        System.out.println("I am not covered");
    }
    
    public void Hello(){
        String s = null;
        System.out.println(s.length());
    }
}
