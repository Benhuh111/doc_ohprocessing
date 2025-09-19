package com.example.Doc_Ohpp.service;

import com.example.Doc_Ohpp.model.Document;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.*;

import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class DynamoDBServiceTest {

    @Mock
    private DynamoDbClient dynamoDbClient;

    private DynamoDBService dynamoDBService;

    @BeforeEach
    void setUp() {
        dynamoDBService = new DynamoDBService(dynamoDbClient);
    }

    @Test
    void saveDocument_ShouldReturnDocumentWithId_WhenSaveSuccessful() {
        // Given
        Document document = new Document("test.txt", "text/plain", 1024, "test-bucket", "test-key");

        when(dynamoDbClient.putItem(any(PutItemRequest.class)))
                .thenReturn(PutItemResponse.builder().build());

        // When
        Document savedDocument = dynamoDBService.saveDocument(document);

        // Then
        assertNotNull(savedDocument.getDocumentId());
        assertEquals("test.txt", savedDocument.getFileName());
        assertEquals(Document.ProcessingStatus.UPLOADED, savedDocument.getStatus());
        verify(dynamoDbClient, times(1)).putItem(any(PutItemRequest.class));
    }

    @Test
    void getDocument_ShouldReturnDocument_WhenDocumentExists() {
        // Given
        String documentId = UUID.randomUUID().toString();
        Map<String, AttributeValue> item = Map.of(
                "documentId", AttributeValue.builder().s(documentId).build(),
                "fileName", AttributeValue.builder().s("test.txt").build(),
                "contentType", AttributeValue.builder().s("text/plain").build(),
                "fileSize", AttributeValue.builder().n("1024").build(),
                "s3Key", AttributeValue.builder().s("test-key").build(),
                "s3Bucket", AttributeValue.builder().s("test-bucket").build(),
                "status", AttributeValue.builder().s("UPLOADED").build()
        );

        when(dynamoDbClient.getItem(any(GetItemRequest.class)))
                .thenReturn(GetItemResponse.builder().item(item).build());

        // When
        Document document = dynamoDBService.getDocument(documentId);

        // Then
        assertNotNull(document);
        assertEquals(documentId, document.getDocumentId());
        assertEquals("test.txt", document.getFileName());
        verify(dynamoDbClient, times(1)).getItem(any(GetItemRequest.class));
    }

    @Test
    void getDocument_ShouldReturnNull_WhenDocumentNotExists() {
        // Given
        String documentId = UUID.randomUUID().toString();

        when(dynamoDbClient.getItem(any(GetItemRequest.class)))
                .thenReturn(GetItemResponse.builder().build());

        // When
        Document document = dynamoDBService.getDocument(documentId);

        // Then
        assertNull(document);
        verify(dynamoDbClient, times(1)).getItem(any(GetItemRequest.class));
    }
}