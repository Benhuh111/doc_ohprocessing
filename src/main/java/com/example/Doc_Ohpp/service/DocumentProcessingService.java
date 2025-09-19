package com.example.Doc_Ohpp.service;

import com.amazonaws.xray.spring.aop.XRayEnabled;
import com.example.Doc_Ohpp.model.Document;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

@Service
@XRayEnabled
public class DocumentProcessingService {

    private static final Logger logger = LoggerFactory.getLogger(DocumentProcessingService.class);

    private final S3Service s3Service;
    private final DynamoDBService dynamoDBService;
    private final SQSService sqsService;

    @Value("${aws.s3.bucket-name}")
    private String bucketName;

    public DocumentProcessingService(S3Service s3Service, DynamoDBService dynamoDBService, SQSService sqsService) {
        this.s3Service = s3Service;
        this.dynamoDBService = dynamoDBService;
        this.sqsService = sqsService;
    }

    /**
     * Upload and process a document
     * @param file The uploaded file
     * @return The created document with metadata
     */
    public Document uploadDocument(MultipartFile file) {
        logger.info("Starting document upload process: fileName={}, size={}", file.getOriginalFilename(), file.getSize());

        try {
            // Validate file
            validateFile(file);

            // Upload to S3
            String s3Key = s3Service.uploadDocument(
                    file.getOriginalFilename(),
                    file.getContentType(),
                    file.getBytes()
            );

            // Create document metadata
            Document document = new Document(
                    file.getOriginalFilename(),
                    file.getContentType(),
                    file.getSize(),
                    bucketName,
                    s3Key
            );
            document.setDocumentId(UUID.randomUUID().toString());

            // Save metadata to DynamoDB
            Document savedDocument = dynamoDBService.saveDocument(document);

            // Send upload notification
            sqsService.sendDocumentUploadedMessage(savedDocument);

            // Start async processing
            processDocumentAsync(savedDocument.getDocumentId());

            logger.info("Document upload completed: documentId={}", savedDocument.getDocumentId());
            return savedDocument;

        } catch (IOException e) {
            logger.error("Failed to read uploaded file: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to read uploaded file", e);
        } catch (Exception e) {
            logger.error("Failed to upload document: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to upload document", e);
        }
    }

    /**
     * Get document by ID
     * @param documentId Document ID
     * @return Document if found
     */
    public Document getDocument(String documentId) {
        logger.info("Retrieving document: documentId={}", documentId);

        Document document = dynamoDBService.getDocument(documentId);
        if (document == null) {
            throw new RuntimeException("Document not found: " + documentId);
        }

        return document;
    }

    /**
     * Get all documents
     * @return List of all documents
     */
    public List<Document> getAllDocuments() {
        logger.info("Retrieving all documents");
        return dynamoDBService.getAllDocuments();
    }

    /**
     * Download document content
     * @param documentId Document ID
     * @return Document content as byte array
     */
    public byte[] downloadDocument(String documentId) {
        logger.info("Downloading document: documentId={}", documentId);

        Document document = getDocument(documentId);
        return s3Service.downloadDocument(document.getS3Key());
    }

    /**
     * Delete a document
     * @param documentId Document ID
     */
    public void deleteDocument(String documentId) {
        logger.info("Deleting document: documentId={}", documentId);

        try {
            Document document = getDocument(documentId);

            // Delete from S3
            s3Service.deleteDocument(document.getS3Key());

            // Delete metadata from DynamoDB
            dynamoDBService.deleteDocument(documentId);

            // Send deletion notification
            sqsService.sendDocumentDeletedMessage(documentId, document.getFileName());

            logger.info("Document deleted successfully: documentId={}", documentId);

        } catch (Exception e) {
            logger.error("Failed to delete document: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to delete document", e);
        }
    }

    /**
     * Process document asynchronously
     * @param documentId Document ID to process
     */
    @Async
    public CompletableFuture<Void> processDocumentAsync(String documentId) {
        processDocument(documentId);
        return CompletableFuture.completedFuture(null);
    }

    /**
     * Simulate document processing (OCR, text extraction, etc.)
     * @param documentId Document ID to process
     */
    private void processDocument(String documentId) {
        logger.info("Starting document processing: documentId={}", documentId);

        try {
            // Update status to PROCESSING
            dynamoDBService.updateDocumentStatus(documentId, Document.ProcessingStatus.PROCESSING, null);

            // Ensure the document exists before proceeding
            Document startedDocument = getDocument(documentId);
            sqsService.sendDocumentProcessingStartedMessage(startedDocument);

            // Simulate processing work
            simulateProcessing(documentId);

            // Update status to COMPLETED
            String processingNotes = "Document processed successfully at " + LocalDateTime.now();
            dynamoDBService.updateDocumentStatus(documentId, Document.ProcessingStatus.COMPLETED, processingNotes);

            Document processedDocument = getDocument(documentId);
            sqsService.sendDocumentProcessingCompletedMessage(processedDocument);

            logger.info("Document processing completed: documentId={}", documentId);

        } catch (Exception e) {
            logger.error("Document processing failed: documentId={}, error={}", documentId, e.getMessage(), e);

            // Update status to FAILED
            String errorNotes = "Processing failed: " + e.getMessage();
            dynamoDBService.updateDocumentStatus(documentId, Document.ProcessingStatus.FAILED, errorNotes);

            // Best effort fetch; may be null if the document was removed
            Document failedDocument = dynamoDBService.getDocument(documentId);
            sqsService.sendDocumentProcessingFailedMessage(failedDocument, e.getMessage());
        }
    }

    /**
     * Simulate processing work (OCR, text extraction, etc.)
     * In a real application, this would do actual processing
     */
    private void simulateProcessing(String documentId) {
        try {
            Document document = dynamoDBService.getDocument(documentId);
            if (document == null) {
                throw new IllegalStateException("Document not found during processing: " + documentId);
            }

            // Simulate different processing times based on file size
            long processingTime = Math.min(document.getFileSize() / 1000, 10000); // Max 10 seconds
            processingTime = Math.max(processingTime, 2000); // Min 2 seconds

            logger.info("Simulating document processing for {} ms: documentId={}", processingTime, documentId);
            Thread.sleep(processingTime);

            // Simulate processing based on content type
            String contentType = document.getContentType();
            if (contentType != null) {
                if (contentType.startsWith("image/")) {
                    logger.info("Simulating OCR processing for image: documentId={}", documentId);
                    Thread.sleep(1000); // Additional time for OCR
                } else if (contentType.equals("application/pdf")) {
                    logger.info("Simulating PDF text extraction: documentId={}", documentId);
                    Thread.sleep(500); // Additional time for PDF processing
                } else if (contentType.startsWith("text/")) {
                    logger.info("Simulating text analysis: documentId={}", documentId);
                    Thread.sleep(200); // Minimal time for text processing
                }
            }

            // Simulate occasional processing failures (5% chance)
            if (Math.random() < 0.05) {
                throw new RuntimeException("Simulated processing failure");
            }

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Processing interrupted", e);
        }
    }

    /**
     * Get processing statistics
     */
    public DocumentProcessingStats getProcessingStats() {
        logger.info("Calculating processing statistics");

        List<Document> allDocuments = getAllDocuments();

        int totalDocuments = allDocuments.size();
        int uploadedCount = 0;
        int processingCount = 0;
        int completedCount = 0;
        int failedCount = 0;

        for (Document doc : allDocuments) {
            switch (doc.getStatus()) {
                case UPLOADED:
                    uploadedCount++;
                    break;
                case PROCESSING:
                    processingCount++;
                    break;
                case COMPLETED:
                    completedCount++;
                    break;
                case FAILED:
                    failedCount++;
                    break;
            }
        }

        return new DocumentProcessingStats(
                totalDocuments,
                uploadedCount,
                processingCount,
                completedCount,
                failedCount,
                sqsService.getQueueMessageCount()
        );
    }

    /**
     * Validate uploaded file
     */
    private void validateFile(MultipartFile file) {
        if (file.isEmpty()) {
            throw new IllegalArgumentException("File is empty");
        }

        if (file.getOriginalFilename() == null || file.getOriginalFilename().trim().isEmpty()) {
            throw new IllegalArgumentException("File name is required");
        }

        // Check file size (max 10MB as configured in properties)
        if (file.getSize() > 10 * 1024 * 1024) {
            throw new IllegalArgumentException("File size exceeds maximum limit of 10MB");
        }

        // Check allowed file types
        String contentType = file.getContentType();
        if (contentType != null && !isAllowedContentType(contentType)) {
            throw new IllegalArgumentException("File type not supported: " + contentType);
        }
    }

    /**
     * Check if content type is allowed
     */
    private boolean isAllowedContentType(String contentType) {
        return contentType.startsWith("text/") ||
                contentType.startsWith("image/") ||
                contentType.equals("application/pdf") ||
                contentType.equals("application/msword") ||
                contentType.equals("application/vnd.openxmlformats-officedocument.wordprocessingml.document");
    }

    /**
     * Processing statistics data class
     */
    public static class DocumentProcessingStats {
        private final int totalDocuments;
        private final int uploadedCount;
        private final int processingCount;
        private final int completedCount;
        private final int failedCount;
        private final int queueMessageCount;

        public DocumentProcessingStats(int totalDocuments, int uploadedCount, int processingCount,
                                       int completedCount, int failedCount, int queueMessageCount) {
            this.totalDocuments = totalDocuments;
            this.uploadedCount = uploadedCount;
            this.processingCount = processingCount;
            this.completedCount = completedCount;
            this.failedCount = failedCount;
            this.queueMessageCount = queueMessageCount;
        }

        // Getters
        public int getTotalDocuments() { return totalDocuments; }
        public int getUploadedCount() { return uploadedCount; }
        public int getProcessingCount() { return processingCount; }
        public int getCompletedCount() { return completedCount; }
        public int getFailedCount() { return failedCount; }
        public int getQueueMessageCount() { return queueMessageCount; }
    }
}