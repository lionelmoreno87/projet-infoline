package com.infoline;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * Tests unitaires pour LoginHandler
 */
class LoginHandlerTest {

    private LoginHandler handler;
    private Context mockContext;
    private LambdaLogger mockLogger;

    @BeforeEach
    void setUp() {
        handler = new LoginHandler();
        mockContext = mock(Context.class);
        mockLogger = mock(LambdaLogger.class);
        when(mockContext.getLogger()).thenReturn(mockLogger);
    }

    @Test
    @DisplayName("handleRequest retourne status 200")
    void handleRequest_ReturnsStatus200() {
        // Given
        APIGatewayProxyRequestEvent request = new APIGatewayProxyRequestEvent();
        request.setHttpMethod("POST");
        request.setBody("{\"username\": \"test\"}");

        // When
        APIGatewayProxyResponseEvent response = handler.handleRequest(request, mockContext);

        // Then
        assertEquals(200, response.getStatusCode());
    }

    @Test
    @DisplayName("handleRequest retourne Content-Type JSON")
    void handleRequest_ReturnsJsonContentType() {
        // Given
        APIGatewayProxyRequestEvent request = new APIGatewayProxyRequestEvent();
        request.setHttpMethod("POST");

        // When
        APIGatewayProxyResponseEvent response = handler.handleRequest(request, mockContext);

        // Then
        assertEquals("application/json", response.getHeaders().get("Content-Type"));
    }

    @Test
    @DisplayName("handleRequest inclut headers CORS")
    void handleRequest_IncludesCorsHeaders() {
        // Given
        APIGatewayProxyRequestEvent request = new APIGatewayProxyRequestEvent();
        request.setHttpMethod("POST");

        // When
        APIGatewayProxyResponseEvent response = handler.handleRequest(request, mockContext);

        // Then
        assertNotNull(response.getHeaders().get("Access-Control-Allow-Origin"));
        assertEquals("*", response.getHeaders().get("Access-Control-Allow-Origin"));
    }

    @Test
    @DisplayName("handleRequest retourne message InfoLine Auth Service")
    void handleRequest_ReturnsInfoLineMessage() {
        // Given
        APIGatewayProxyRequestEvent request = new APIGatewayProxyRequestEvent();
        request.setHttpMethod("POST");

        // When
        APIGatewayProxyResponseEvent response = handler.handleRequest(request, mockContext);

        // Then
        assertNotNull(response.getBody());
        assertTrue(response.getBody().contains("InfoLine Auth Service"));
    }
}
