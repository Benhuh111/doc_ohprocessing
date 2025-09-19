package com.example.Doc_Ohpp.service;

import org.junit.jupiter.api.BeforeEach;
import com.example.Doc_Ohpp.model.Document;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.*;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SQSServiceTest {

    @Mock
    private SqsClient sqsClient;

    private SQSService sqsService;

    @BeforeEach
    void setUp() {
        lenient().when(sqsClient.getQueueUrl(any(GetQueueUrlRequest.class)))
                .thenReturn(GetQueueUrlResponse.builder()
                        .queueUrl("https://sqs.eu-north-1.amazonaws.com/123456789/test-queue")
                        .build());

        sqsService = new SQSService(sqsClient);
    }

    @Test
    void sendDocumentUploadedMessage_ShouldSendMessage_WhenDocumentProvided() {
        // Given
        Document document = new Document("test.txt", "text/plain", 1024, "test-bucket", "test-key");
        document.setDocumentId("test-id");

        when(sqsClient.sendMessage(any(SendMessageRequest.class)))
                .thenReturn(SendMessageResponse.builder().messageId("msg-123").build());

        // When
        sqsService.sendDocumentUploadedMessage(document);

        // Then
        verify(sqsClient, times(1)).sendMessage(any(SendMessageRequest.class));
    }
}