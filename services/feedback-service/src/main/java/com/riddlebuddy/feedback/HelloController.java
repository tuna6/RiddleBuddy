package com.riddlebuddy.feedback;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {
    @GetMapping("/")
    public String sayHello() {
    
        return "Hello from Feedback Service!";
    }

    @GetMapping("/health")
    public String health() {
        return "OK";
    }
}
