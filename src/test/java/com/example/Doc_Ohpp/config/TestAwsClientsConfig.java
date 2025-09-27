package com.example.Doc_Ohpp.config;

import org.mockito.Mockito;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.GetQueueUrlRequest;
import software.amazon.awssdk.services.sqs.model.ReceiveMessageRequest;
import software.amazon.awssdk.services.sqs.model.ReceiveMessageResponse;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;
import software.amazon.awssdk.services.sqs.model.SendMessageResponse;

import java.util.Collections;

@Configuration
public class TestAwsClientsConfig {

    @Bean
    @Primary
    public S3Client s3Client() {
        return Mockito.mock(S3Client.class);
    }

    @Bean
    @Primary
    public DynamoDbClient dynamoDbClient() {
        return Mockito.mock(DynamoDbClient.class);
    }

    @Bean
    @Primary
    public SqsClient sqsClient() {
        SqsClient mock = Mockito.mock(SqsClient.class);

        // Simulate SQS not available during tests: getQueueUrl throws to force service to operate without SQS
        Mockito.when(mock.getQueueUrl(Mockito.any(GetQueueUrlRequest.class)))
                .thenThrow(new RuntimeException("SQS not available in test environment"));

        // Return empty list for receiveMessage as a fallback
        Mockito.when(mock.receiveMessage(Mockito.any(ReceiveMessageRequest.class)))
                .thenReturn(ReceiveMessageResponse.builder().messages(Collections.emptyList()).build());

        // Return a simple sendMessage response
        Mockito.when(mock.sendMessage(Mockito.any(SendMessageRequest.class)))
                .thenReturn(SendMessageResponse.builder().messageId("mocked-message-id").build());

        return mock;
    }
}
