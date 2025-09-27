package com.example.Doc_Ohpp.config;

import org.mockito.Mockito;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.sqs.SqsClient;

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
        return Mockito.mock(SqsClient.class);
    }
}

