package com.example.Doc_Ohpp.controller;

import com.amazonaws.xray.AWSXRay;
import com.amazonaws.xray.entities.Subsegment;
import com.amazonaws.xray.spring.aop.XRayEnabled;
import com.example.Doc_Ohpp.model.Document;
import com.example.Doc_Ohpp.service.DocumentProcessingService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/documents")
@XRayEnabled
public class DocumentController {

    private static final Logger logger = LoggerFactory.getLogger(DocumentController.class);

    private final DocumentProcessingService documentProcessingService;

    public DocumentController(DocumentProcessingService documentProcessingService) {
        this.documentProcessingService = documentProcessingService;
    }

    /**
     * Upload a new document
     */
    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> uploadDocument(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "description", required = false) String description) {

        logger.info("Document upload request: fileName={}, size={}", file.getOriginalFilename(), file.getSize());

        try {
            Document document = documentProcessingService.uploadDocument(file);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Document uploaded successfully");
            response.put("documentId", document.getDocumentId());
            response.put("fileName", document.getFileName());
            response.put("status", document.getStatus());
            response.put("uploadedAt", document.getUploadedAt());

            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            logger.warn("Invalid upload request: {}", e.getMessage());

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(errorResponse);

        } catch (Exception e) {
            logger.error("Document upload failed: {}", e.getMessage(), e);

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", "Upload failed: " + e.getMessage());

            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Get document metadata by ID
     */
    @GetMapping("/{documentId}")
    public ResponseEntity<Document> getDocument(@PathVariable String documentId) {
        logger.info("Get document request: documentId={}", documentId);

        try {
            Document document = documentProcessingService.getDocument(documentId);
            return ResponseEntity.ok(document);

        } catch (RuntimeException e) {
            logger.warn("Document not found: documentId={}", documentId);
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("Failed to retrieve document: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Get all documents
     */
    @GetMapping
    public ResponseEntity<List<Document>> getAllDocuments() {
        logger.info("Get all documents request");

        try {
            List<Document> documents = documentProcessingService.getAllDocuments();
            return ResponseEntity.ok(documents);

        } catch (Exception e) {
            logger.error("Failed to retrieve documents: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Download document content
     */
    @GetMapping("/{documentId}/download")
    public ResponseEntity<byte[]> downloadDocument(@PathVariable String documentId) {
        logger.info("Download document request: documentId={}", documentId);

        try {
            Document document = documentProcessingService.getDocument(documentId);
            byte[] content = documentProcessingService.downloadDocument(documentId);

            HttpHeaders headers = new HttpHeaders();
            headers.add(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + document.getFileName() + "\"");
            headers.add(HttpHeaders.CONTENT_TYPE, document.getContentType());

            return ResponseEntity.ok()
                    .headers(headers)
                    .body(content);

        } catch (RuntimeException e) {
            logger.warn("Document not found for download: documentId={}", documentId);
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("Failed to download document: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Delete a document
     */
    @DeleteMapping("/{documentId}")
    public ResponseEntity<Map<String, Object>> deleteDocument(@PathVariable String documentId) {
        logger.info("Delete document request: documentId={}", documentId);

        try {
            documentProcessingService.deleteDocument(documentId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Document deleted successfully");
            response.put("documentId", documentId);

            return ResponseEntity.ok(response);

        } catch (RuntimeException e) {
            logger.warn("Document not found for deletion: documentId={}", documentId);

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", "Document not found");

            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("Failed to delete document: {}", e.getMessage(), e);

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", "Deletion failed: " + e.getMessage());

            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Get processing statistics
     */
    @GetMapping("/stats")
    public ResponseEntity<DocumentProcessingService.DocumentProcessingStats> getProcessingStats() {
        logger.info("Get processing statistics request");

        try {
            DocumentProcessingService.DocumentProcessingStats stats = documentProcessingService.getProcessingStats();
            return ResponseEntity.ok(stats);

        } catch (Exception e) {
            logger.error("Failed to retrieve processing statistics: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        logger.info("Health check request received");

        // Create custom X-Ray subsegment for health check
        Subsegment healthSubsegment = AWSXRay.beginSubsegment("health-check");
        try {
            healthSubsegment.putAnnotation("operation", "health");
            healthSubsegment.putAnnotation("endpoint", "/api/documents/health");

            // Get processing statistics to verify all services are working
            var stats = documentProcessingService.getProcessingStats();

            Map<String, Object> response = new HashMap<>();
            response.put("status", "healthy");
            response.put("timestamp", LocalDateTime.now());
            response.put("service", "DocOh-Service");
            response.put("statistics", Map.of(
                "totalDocuments", stats.getTotalDocuments(),
                "uploadedCount", stats.getUploadedCount(),
                "processingCount", stats.getProcessingCount(),
                "completedCount", stats.getCompletedCount(),
                "failedCount", stats.getFailedCount(),
                "queueMessageCount", stats.getQueueMessageCount()
            ));

            healthSubsegment.putMetadata("health", "response", response);
            logger.info("Health check completed successfully");
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            logger.error("Health check failed: {}", e.getMessage(), e);
            healthSubsegment.putAnnotation("error", "health_check_failed");
            healthSubsegment.putMetadata("health", "error", e.getMessage());

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("status", "unhealthy");
            errorResponse.put("timestamp", LocalDateTime.now());
            errorResponse.put("error", e.getMessage());

            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        } finally {
            healthSubsegment.close();
        }
    }

    /**
     * Get document processing status
     */
    @GetMapping("/{documentId}/status")
    public ResponseEntity<Map<String, Object>> getDocumentStatus(@PathVariable String documentId) {
        logger.info("Get document status request: documentId={}", documentId);

        try {
            Document document = documentProcessingService.getDocument(documentId);

            Map<String, Object> status = new HashMap<>();
            status.put("documentId", document.getDocumentId());
            status.put("fileName", document.getFileName());
            status.put("status", document.getStatus());
            status.put("uploadedAt", document.getUploadedAt());
            status.put("processedAt", document.getProcessedAt());
            status.put("processingNotes", document.getProcessingNotes());

            return ResponseEntity.ok(status);

        } catch (RuntimeException e) {
            logger.warn("Document not found: documentId={}", documentId);
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("Failed to get document status: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}