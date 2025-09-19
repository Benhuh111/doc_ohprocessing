package com.example.Doc_Ohpp.model;

import java.time.LocalDateTime;

public class Document {
    private String documentId;
    private String fileName;
    private String contentType;
    private long fileSize;
    private String s3Key;
    private String s3Bucket;
    private ProcessingStatus status;
    private LocalDateTime uploadedAt;
    private LocalDateTime processedAt;
    private String processingNotes;

    public enum ProcessingStatus {
        UPLOADED,
        PROCESSING,
        COMPLETED,
        FAILED
    }

    // Constructors
    public Document() {}

    public Document(String fileName, String contentType, long fileSize, String s3Bucket, String s3Key) {
        this.fileName = fileName;
        this.contentType = contentType;
        this.fileSize = fileSize;
        this.s3Bucket = s3Bucket;
        this.s3Key = s3Key;
        this.status = ProcessingStatus.UPLOADED;
        this.uploadedAt = LocalDateTime.now();
    }

    // Getters and Setters
    public String getDocumentId() {
        return documentId;
    }

    public void setDocumentId(String documentId) {
        this.documentId = documentId;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public String getContentType() {
        return contentType;
    }

    public void setContentType(String contentType) {
        this.contentType = contentType;
    }

    public long getFileSize() {
        return fileSize;
    }

    public void setFileSize(long fileSize) {
        this.fileSize = fileSize;
    }

    public String getS3Key() {
        return s3Key;
    }

    public void setS3Key(String s3Key) {
        this.s3Key = s3Key;
    }

    public String getS3Bucket() {
        return s3Bucket;
    }

    public void setS3Bucket(String s3Bucket) {
        this.s3Bucket = s3Bucket;
    }

    public ProcessingStatus getStatus() {
        return status;
    }

    public void setStatus(ProcessingStatus status) {
        this.status = status;
    }

    public LocalDateTime getUploadedAt() {
        return uploadedAt;
    }

    public void setUploadedAt(LocalDateTime uploadedAt) {
        this.uploadedAt = uploadedAt;
    }

    public LocalDateTime getProcessedAt() {
        return processedAt;
    }

    public void setProcessedAt(LocalDateTime processedAt) {
        this.processedAt = processedAt;
    }

    public String getProcessingNotes() {
        return processingNotes;
    }

    public void setProcessingNotes(String processingNotes) {
        this.processingNotes = processingNotes;
    }
}