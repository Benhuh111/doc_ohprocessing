package com.example.Doc_Ohpp.config;

import org.mockito.Mockito;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.GetQueueUrlRequest;
import software.amazon.awssdk.services.sqs.model.GetQueueUrlResponse;
import software.amazon.awssdk.services.sqs.model.ReceiveMessageRequest;
import software.amazon.awssdk.services.sqs.model.ReceiveMessageResponse;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;
import software.amazon.awssdk.services.sqs.model.SendMessageResponse;
import software.amazon.awssdk.services.sqs.model.GetQueueAttributesRequest;
import software.amazon.awssdk.services.sqs.model.GetQueueAttributesResponse;
import software.amazon.awssdk.services.sqs.model.QueueAttributeName;

import java.util.Collections;
import java.util.Map;

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

        // Return a safe queue URL when asked
        Mockito.when(mock.getQueueUrl(Mockito.any(GetQueueUrlRequest.class)))
                .thenReturn(GetQueueUrlResponse.builder().queueUrl("https://sqs.local/mock-queue-url").build());

        // Return empty list for receiveMessage
        Mockito.when(mock.receiveMessage(Mockito.any(ReceiveMessageRequest.class)))
                .thenReturn(ReceiveMessageResponse.builder().messages(Collections.emptyList()).build());

        // Return a simple sendMessage response
        Mockito.when(mock.sendMessage(Mockito.any(SendMessageRequest.class)))
                .thenReturn(SendMessageResponse.builder().messageId("mocked-message-id").build());

        // Return default attributes for getQueueAttributes
        Mockito.when(mock.getQueueAttributes(Mockito.any(GetQueueAttributesRequest.class)))
                .thenReturn(GetQueueAttributesResponse.builder()
                        .attributes(Map.of(QueueAttributeName.APPROXIMATE_NUMBER_OF_MESSAGES.toString(), "0"))
                        .build());

        return mock;
    }
}
