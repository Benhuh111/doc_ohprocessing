package com.example.Doc_Ohpp.service;

import com.amazonaws.xray.spring.aop.XRayEnabled;
import com.example.Doc_Ohpp.model.Document;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
@XRayEnabled
public class DynamoDBService {

    private static final Logger logger = LoggerFactory.getLogger(DynamoDBService.class);

    private final DynamoDbClient dynamoDbClient;

    @Value("${aws.dynamodb.table-name}")
    private String tableName;

    public DynamoDBService(DynamoDbClient dynamoDbClient) {
        this.dynamoDbClient = dynamoDbClient;
    }

    /**
     * Save document metadata to DynamoDB
     * @param document Document to save
     * @return Saved document with generated ID
     */
    public Document saveDocument(Document document) {
        try {
            // Generate document ID if not present
            if (document.getDocumentId() == null || document.getDocumentId().isEmpty()) {
                document.setDocumentId(UUID.randomUUID().toString());
            }

            logger.info("Saving document metadata to DynamoDB: documentId={}", document.getDocumentId());

            Map<String, AttributeValue> item = documentToAttributeMap(document);

            PutItemRequest putItemRequest = PutItemRequest.builder()
                    .tableName(tableName)
                    .item(item)
                    .build();

            dynamoDbClient.putItem(putItemRequest);

            logger.info("Document metadata saved successfully: documentId={}", document.getDocumentId());
            return document;

        } catch (Exception e) {
            logger.error("Failed to save document metadata: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to save document metadata", e);
        }
    }

    /**
     * Retrieve document metadata by ID
     * @param documentId Document ID
     * @return Document if found, null otherwise
     */
    public Document getDocument(String documentId) {
        try {
            logger.info("Retrieving document metadata from DynamoDB: documentId={}", documentId);

            Map<String, AttributeValue> key = Map.of(
                    "documentId", AttributeValue.builder().s(documentId).build()
            );

            GetItemRequest getItemRequest = GetItemRequest.builder()
                    .tableName(tableName)
                    .key(key)
                    .build();

            GetItemResponse response = dynamoDbClient.getItem(getItemRequest);

            if (response.item().isEmpty()) {
                logger.info("Document not found: documentId={}", documentId);
                return null;
            }

            Document document = attributeMapToDocument(response.item());
            logger.info("Document metadata retrieved successfully: documentId={}", documentId);
            return document;

        } catch (Exception e) {
            logger.error("Failed to retrieve document metadata: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to retrieve document metadata", e);
        }
    }

    /**
     * Update document processing status
     * @param documentId Document ID
     * @param status New processing status
     * @param notes Optional processing notes
     */
    public void updateDocumentStatus(String documentId, Document.ProcessingStatus status, String notes) {
        try {
            logger.info("Updating document status: documentId={}, status={}", documentId, status);

            Map<String, AttributeValue> key = Map.of(
                    "documentId", AttributeValue.builder().s(documentId).build()
            );

            Map<String, AttributeValueUpdate> updates = new HashMap<>();
            updates.put("status", AttributeValueUpdate.builder()
                    .value(AttributeValue.builder().s(status.name()).build())
                    .action(AttributeAction.PUT)
                    .build());

            if (status == Document.ProcessingStatus.COMPLETED || status == Document.ProcessingStatus.FAILED) {
                updates.put("processedAt", AttributeValueUpdate.builder()
                        .value(AttributeValue.builder().s(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)).build())
                        .action(AttributeAction.PUT)
                        .build());
            }

            if (notes != null && !notes.isEmpty()) {
                updates.put("processingNotes", AttributeValueUpdate.builder()
                        .value(AttributeValue.builder().s(notes).build())
                        .action(AttributeAction.PUT)
                        .build());
            }

            UpdateItemRequest updateItemRequest = UpdateItemRequest.builder()
                    .tableName(tableName)
                    .key(key)
                    .attributeUpdates(updates)
                    .build();

            dynamoDbClient.updateItem(updateItemRequest);

            logger.info("Document status updated successfully: documentId={}, status={}", documentId, status);

        } catch (Exception e) {
            logger.error("Failed to update document status: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to update document status", e);
        }
    }

    /**
     * Get all documents (for listing purposes)
     * @return List of all documents
     */
    public List<Document> getAllDocuments() {
        try {
            logger.info("Retrieving all documents from DynamoDB");

            ScanRequest scanRequest = ScanRequest.builder()
                    .tableName(tableName)
                    .build();

            ScanResponse response = dynamoDbClient.scan(scanRequest);

            List<Document> documents = new ArrayList<>();
            for (Map<String, AttributeValue> item : response.items()) {
                documents.add(attributeMapToDocument(item));
            }

            logger.info("Retrieved {} documents from DynamoDB", documents.size());
            return documents;

        } catch (Exception e) {
            logger.error("Failed to retrieve all documents: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to retrieve all documents", e);
        }
    }

    /**
     * Delete document metadata
     * @param documentId Document ID
     */
    public void deleteDocument(String documentId) {
        try {
            logger.info("Deleting document metadata from DynamoDB: documentId={}", documentId);

            Map<String, AttributeValue> key = Map.of(
                    "documentId", AttributeValue.builder().s(documentId).build()
            );

            DeleteItemRequest deleteItemRequest = DeleteItemRequest.builder()
                    .tableName(tableName)
                    .key(key)
                    .build();

            dynamoDbClient.deleteItem(deleteItemRequest);

            logger.info("Document metadata deleted successfully: documentId={}", documentId);

        } catch (Exception e) {
            logger.error("Failed to delete document metadata: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to delete document metadata", e);
        }
    }

    /**
     * Convert Document object to DynamoDB attribute map
     */
    private Map<String, AttributeValue> documentToAttributeMap(Document document) {
        Map<String, AttributeValue> item = new HashMap<>();

        item.put("documentId", AttributeValue.builder().s(document.getDocumentId()).build());
        item.put("fileName", AttributeValue.builder().s(document.getFileName()).build());
        item.put("contentType", AttributeValue.builder().s(document.getContentType()).build());
        item.put("fileSize", AttributeValue.builder().n(String.valueOf(document.getFileSize())).build());
        item.put("s3Key", AttributeValue.builder().s(document.getS3Key()).build());
        item.put("s3Bucket", AttributeValue.builder().s(document.getS3Bucket()).build());
        item.put("status", AttributeValue.builder().s(document.getStatus().name()).build());

        if (document.getUploadedAt() != null) {
            item.put("uploadedAt", AttributeValue.builder().s(document.getUploadedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)).build());
        }

        if (document.getProcessedAt() != null) {
            item.put("processedAt", AttributeValue.builder().s(document.getProcessedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)).build());
        }

        if (document.getProcessingNotes() != null) {
            item.put("processingNotes", AttributeValue.builder().s(document.getProcessingNotes()).build());
        }

        return item;
    }

    /**
     * Convert DynamoDB attribute map to Document object
     */
    private Document attributeMapToDocument(Map<String, AttributeValue> item) {
        Document document = new Document();

        document.setDocumentId(item.get("documentId").s());
        document.setFileName(item.get("fileName").s());
        document.setContentType(item.get("contentType").s());
        document.setFileSize(Long.parseLong(item.get("fileSize").n()));
        document.setS3Key(item.get("s3Key").s());
        document.setS3Bucket(item.get("s3Bucket").s());
        document.setStatus(Document.ProcessingStatus.valueOf(item.get("status").s()));

        if (item.containsKey("uploadedAt") && item.get("uploadedAt") != null) {
            document.setUploadedAt(LocalDateTime.parse(item.get("uploadedAt").s()));
        }

        if (item.containsKey("processedAt") && item.get("processedAt") != null) {
            document.setProcessedAt(LocalDateTime.parse(item.get("processedAt").s()));
        }

        if (item.containsKey("processingNotes") && item.get("processingNotes") != null) {
            document.setProcessingNotes(item.get("processingNotes").s());
        }

        return document;
    }
}