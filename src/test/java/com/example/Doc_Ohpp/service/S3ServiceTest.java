package com.example.Doc_Ohpp.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectResponse;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class S3ServiceTest {

    @Mock
    private S3Client s3Client;

    private S3Service s3Service;

    @BeforeEach
    void setUp() {
        s3Service = new S3Service(s3Client);
    }

    @Test
    void uploadDocument_ShouldReturnS3Key_WhenUploadSuccessful() {
        String fileName = "test-document.txt";
        String contentType = "text/plain";
        byte[] content = "Test content".getBytes();

        when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
                .thenReturn(PutObjectResponse.builder().build());

        String s3Key = s3Service.uploadDocument(fileName, contentType, content);

        assertNotNull(s3Key);
        assertTrue(s3Key.contains(fileName));
        verify(s3Client, times(1)).putObject(any(PutObjectRequest.class), any(RequestBody.class));
    }

    @Test
    void uploadDocument_ShouldThrowException_WhenS3ClientFails() {
        String fileName = "test-document.txt";
        String contentType = "text/plain";
        byte[] content = "Test content".getBytes();

        when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
                .thenThrow(new RuntimeException("S3 error"));

        assertThrows(RuntimeException.class, () -> {
            s3Service.uploadDocument(fileName, contentType, content);
        });
    }
}