package com.infoline;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;

import java.util.HashMap;
import java.util.Map;

/**
 * InfoLine Login Service - AWS Lambda Handler
 * 
 * Point d'entrée serverless pour l'authentification des utilisateurs.
 * Cette implémentation est un placeholder démontrant l'infrastructure.
 * En production, elle serait connectée à Cognito ou une base utilisateurs.
 */
public class LoginHandler implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {

    @Override
    public APIGatewayProxyResponseEvent handleRequest(APIGatewayProxyRequestEvent request, Context context) {
        context.getLogger().log("InfoLine Login Service - Requête reçue");
        
        // Headers CORS
        Map<String, String> headers = new HashMap<>();
        headers.put("Content-Type", "application/json");
        headers.put("Access-Control-Allow-Origin", "*");
        headers.put("Access-Control-Allow-Methods", "POST, OPTIONS");
        
        // Récupérer l'environnement
        String environment = System.getenv("ENVIRONMENT");
        if (environment == null) {
            environment = "dev";
        }
        
        // Log de la requête
        context.getLogger().log("Environment: " + environment);
        context.getLogger().log("HTTP Method: " + request.getHttpMethod());
        context.getLogger().log("Request Body: " + request.getBody());
        
        // Réponse JSON
        String responseBody = String.format(
            "{\"message\": \"InfoLine Auth Service\", " +
            "\"status\": \"ready\", " +
            "\"environment\": \"%s\", " +
            "\"service\": \"login-placeholder\", " +
            "\"note\": \"En production, ce service serait connecté à AWS Cognito\"}",
            environment
        );
        
        APIGatewayProxyResponseEvent response = new APIGatewayProxyResponseEvent();
        response.setStatusCode(200);
        response.setHeaders(headers);
        response.setBody(responseBody);
        
        return response;
    }
}
