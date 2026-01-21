package com.infoline.api;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Controller REST pour l'API InfoLine.
 * 
 * @RestController = Cette classe gère des requêtes HTTP et renvoie du JSON
 * @RequestMapping = Toutes les URLs de cette classe commencent par "/api"
 */
@RestController
@RequestMapping("/api")
public class HelloController {

    /**
     * Endpoint simple : GET /api/hello
     * 
     * Teste avec : curl http://localhost:8080/api/hello
     */
    @GetMapping("/hello")
    public String hello() {
        return "Hello World depuis InfoLine API !";
    }

    /**
     * Endpoint qui renvoie du JSON : GET /api/status
     * 
     * Teste avec : curl http://localhost:8080/api/status
     */
    @GetMapping("/status")
    public Map<String, Object> status() {
        Map<String, Object> response = new HashMap<>();
        response.put("application", "InfoLine API");
        response.put("version", "1.0.0");
        response.put("status", "running");
        response.put("timestamp", LocalDateTime.now().toString());
        return response;
    }
}