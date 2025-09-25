package com.example.Doc_Ohpp.service;

import com.example.Doc_Ohpp.model.Document;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DocumentProcessingServiceTest {

    @Mock
    private S3Service s3Service;

    @Mock
    private DynamoDBService dynamoDBService;

    @Mock
    private SQSService sqsService;

    @Mock
    private MultipartFile multipartFile;

    private DocumentProcessingService documentProcessingService;

    @BeforeEach
    void setUp() {
        documentProcessingService = new DocumentProcessingService(s3Service, dynamoDBService, sqsService);
    }

    @Test
    void uploadDocument_ShouldReturnDocument_WhenValidFileProvided() throws IOException {
        // Given
        String fileName = "test.txt";
        String contentType = "text/plain";
        byte[] content = "Test content".getBytes();
        String s3Key = "documents/test-key";

        when(multipartFile.getOriginalFilename()).thenReturn(fileName);
        when(multipartFile.getContentType()).thenReturn(contentType);
        when(multipartFile.getSize()).thenReturn((long) content.length);
        when(multipartFile.getBytes()).thenReturn(content);
        when(multipartFile.isEmpty()).thenReturn(false);

        when(s3Service.uploadDocument(eq(fileName), eq(contentType), eq(content))).thenReturn(s3Key);

        Document savedDocument = new Document(fileName, contentType, content.length, "test-bucket", s3Key);
        savedDocument.setDocumentId("test-id");
        when(dynamoDBService.saveDocument(any(Document.class))).thenReturn(savedDocument);

        // Mock getDocument calls for async processing
        when(dynamoDBService.getDocument("test-id")).thenReturn(savedDocument);

        // When
        Document result = documentProcessingService.uploadDocument(multipartFile);

        // Then
        assertNotNull(result);
        assertEquals(fileName, result.getFileName());
        assertEquals(contentType, result.getContentType());
        assertEquals(Document.ProcessingStatus.UPLOADED, result.getStatus());

        verify(s3Service).uploadDocument(eq(fileName), eq(contentType), eq(content));
        verify(dynamoDBService).saveDocument(any(Document.class));
        verify(sqsService).sendDocumentUploadedMessage(any(Document.class));
    }

    @Test
    void uploadDocument_ShouldThrowException_WhenFileIsEmpty() {
        // Given
        when(multipartFile.isEmpty()).thenReturn(true);

        // When & Then
        assertThrows(RuntimeException.class, () -> {
            documentProcessingService.uploadDocument(multipartFile);
        });

        verify(s3Service, never()).uploadDocument(anyString(), anyString(), any(byte[].class));
    }

    @Test
    void getDocument_ShouldReturnDocument_WhenDocumentExists() {
        // Given
        String documentId = "test-id";
        Document document = new Document("test.txt", "text/plain", 1024, "test-bucket", "test-key");
        document.setDocumentId(documentId);

        when(dynamoDBService.getDocument(documentId)).thenReturn(document);

        // When
        Document result = documentProcessingService.getDocument(documentId);

        // Then
        assertNotNull(result);
        assertEquals(documentId, result.getDocumentId());
        verify(dynamoDBService).getDocument(documentId);
    }

    @Test
    void getDocument_ShouldThrowException_WhenDocumentNotFound() {
        // Given
        String documentId = "non-existent-id";
        when(dynamoDBService.getDocument(documentId)).thenReturn(null);

        // When & Then
        assertThrows(RuntimeException.class, () -> {
            documentProcessingService.getDocument(documentId);
        });
    }

    @Test
    void getAllDocuments_ShouldReturnListOfDocuments() {
        // Given
        List<Document> documents = Arrays.asList(
                new Document("doc1.txt", "text/plain", 1024, "bucket", "key1"),
                new Document("doc2.pdf", "application/pdf", 2048, "bucket", "key2")
        );

        when(dynamoDBService.getAllDocuments()).thenReturn(documents);

        // When
        List<Document> result = documentProcessingService.getAllDocuments();

        // Then
        assertNotNull(result);
        assertEquals(2, result.size());
        verify(dynamoDBService).getAllDocuments();
    }

    @Test
    void deleteDocument_ShouldDeleteFromS3AndDynamoDB_WhenDocumentExists() {
        // Given
        String documentId = "test-id";
        Document document = new Document("test.txt", "text/plain", 1024, "test-bucket", "test-key");
        document.setDocumentId(documentId);

        when(dynamoDBService.getDocument(documentId)).thenReturn(document);

        // When
        documentProcessingService.deleteDocument(documentId);

        // Then
        verify(s3Service).deleteDocument(document.getS3Key());
        verify(dynamoDBService).deleteDocument(documentId);
        verify(sqsService).sendDocumentDeletedMessage(documentId, document.getFileName());
    }

    @Test
    void downloadDocument_ShouldReturnFileContent_WhenDocumentExists() {
        // Given
        String documentId = "test-id";
        byte[] expectedContent = "Test content".getBytes();
        Document document = new Document("test.txt", "text/plain", 1024, "test-bucket", "test-key");
        document.setDocumentId(documentId);

        when(dynamoDBService.getDocument(documentId)).thenReturn(document);
        when(s3Service.downloadDocument(document.getS3Key())).thenReturn(expectedContent);

        // When
        byte[] result = documentProcessingService.downloadDocument(documentId);

        // Then
        assertNotNull(result);
        assertArrayEquals(expectedContent, result);
        verify(s3Service).downloadDocument(document.getS3Key());
    }
}
