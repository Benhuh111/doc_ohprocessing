package com.example.Doc_Ohpp.model;

import java.time.LocalDateTime;
import java.util.Map;

public class DocumentMetadata {
    private String documentId;
    private String extractedText;
    private Map<String, Object> metadata;
    private String ocrConfidence;
    private LocalDateTime extractedAt;
    private String language;
    private int pageCount;
    private String processingEngine;

    // Constructors
    public DocumentMetadata() {}

    public DocumentMetadata(String documentId) {
        this.documentId = documentId;
        this.extractedAt = LocalDateTime.now();
    }

    // Getters and Setters
    public String getDocumentId() {
        return documentId;
    }

    public void setDocumentId(String documentId) {
        this.documentId = documentId;
    }

    public String getExtractedText() {
        return extractedText;
    }

    public void setExtractedText(String extractedText) {
        this.extractedText = extractedText;
    }

    public Map<String, Object> getMetadata() {
        return metadata;
    }

    public void setMetadata(Map<String, Object> metadata) {
        this.metadata = metadata;
    }

    public String getOcrConfidence() {
        return ocrConfidence;
    }

    public void setOcrConfidence(String ocrConfidence) {
        this.ocrConfidence = ocrConfidence;
    }

    public LocalDateTime getExtractedAt() {
        return extractedAt;
    }

    public void setExtractedAt(LocalDateTime extractedAt) {
        this.extractedAt = extractedAt;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public int getPageCount() {
        return pageCount;
    }

    public void setPageCount(int pageCount) {
        this.pageCount = pageCount;
    }

    public String getProcessingEngine() {
        return processingEngine;
    }

    public void setProcessingEngine(String processingEngine) {
        this.processingEngine = processingEngine;
    }
}