package com.example.Doc_Ohpp.service;

import com.amazonaws.xray.spring.aop.XRayEnabled;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.example.Doc_Ohpp.model.Document;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@XRayEnabled
public class SQSService {

    private static final Logger logger = LoggerFactory.getLogger(SQSService.class);

    private final SqsClient sqsClient;
    private final ObjectMapper objectMapper;

    @Value("${aws.sqs.queue-name}")
    private String queueName;

    private String queueUrl;

    public SQSService(SqsClient sqsClient) {
        this.sqsClient = sqsClient;
        this.objectMapper = new ObjectMapper();
    }

    /**
     * Initialize the queue URL by getting it from SQS
     * This is called after Spring has injected the @Value properties
     */
    @PostConstruct
    private void initializeQueueUrl() {
        try {
            if (queueName == null || queueName.trim().isEmpty()) {
                logger.error("Queue name is not configured. Check your application.properties file.");
                throw new RuntimeException("Queue name is not configured");
            }

            logger.info("Initializing SQS queue URL for queue: {}", queueName);

            GetQueueUrlRequest getQueueUrlRequest = GetQueueUrlRequest.builder()
                    .queueName(queueName.trim())
                    .build();

            GetQueueUrlResponse response = sqsClient.getQueueUrl(getQueueUrlRequest);
            this.queueUrl = response.queueUrl();

            logger.info("SQS Queue URL initialized: {}", queueUrl);

        } catch (Exception e) {
            logger.error("Failed to initialize SQS queue URL for queue '{}': {}", queueName, e.getMessage(), e);
            throw new RuntimeException("Failed to initialize SQS queue URL", e);
        }
    }

    /**
     * Send document upload notification
     * @param document The uploaded document
     */
    public void sendDocumentUploadedMessage(Document document) {
        try {
            Map<String, Object> message = createDocumentMessage(document, "DOCUMENT_UPLOADED");
            sendMessage(message, "DocumentUploaded");

            logger.info("Document uploaded message sent: documentId={}", document.getDocumentId());

        } catch (Exception e) {
            logger.error("Failed to send document uploaded message: {}", e.getMessage(), e);
            // Don't throw exception here - we don't want to fail the upload if notification fails
        }
    }

    /**
     * Send document processing started notification
     * @param document The document being processed
     */
    public void sendDocumentProcessingStartedMessage(Document document) {
        try {
            Map<String, Object> message = createDocumentMessage(document, "PROCESSING_STARTED");
            sendMessage(message, "ProcessingStarted");

            logger.info("Document processing started message sent: documentId={}", document.getDocumentId());

        } catch (Exception e) {
            logger.error("Failed to send processing started message: {}", e.getMessage(), e);
        }
    }

    /**
     * Send document processing completed notification
     * @param document The processed document
     */
    public void sendDocumentProcessingCompletedMessage(Document document) {
        try {
            Map<String, Object> message = createDocumentMessage(document, "PROCESSING_COMPLETED");
            sendMessage(message, "ProcessingCompleted");

            logger.info("Document processing completed message sent: documentId={}", document.getDocumentId());

        } catch (Exception e) {
            logger.error("Failed to send processing completed message: {}", e.getMessage(), e);
        }
    }

    /**
     * Send document processing failed notification
     * @param document The document that failed processing
     * @param errorMessage Error details
     */
    public void sendDocumentProcessingFailedMessage(Document document, String errorMessage) {
        try {
            Map<String, Object> message = createDocumentMessage(document, "PROCESSING_FAILED");
            message.put("errorMessage", errorMessage);
            sendMessage(message, "ProcessingFailed");

            logger.info("Document processing failed message sent: documentId={}", document.getDocumentId());

        } catch (Exception e) {
            logger.error("Failed to send processing failed message: {}", e.getMessage(), e);
        }
    }

    /**
     * Send document deleted notification
     * @param documentId The ID of the deleted document
     * @param fileName The name of the deleted file
     */
    public void sendDocumentDeletedMessage(String documentId, String fileName) {
        try {
            Map<String, Object> message = new HashMap<>();
            message.put("eventType", "DOCUMENT_DELETED");
            message.put("documentId", documentId);
            message.put("fileName", fileName);
            message.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));

            sendMessage(message, "DocumentDeleted");

            logger.info("Document deleted message sent: documentId={}", documentId);

        } catch (Exception e) {
            logger.error("Failed to send document deleted message: {}", e.getMessage(), e);
        }
    }

    /**
     * Receive messages from the queue (for processing)
     * @param maxMessages Maximum number of messages to receive
     * @return List of received messages
     */
    public List<Message> receiveMessages(int maxMessages) {
        try {
            logger.info("Receiving up to {} messages from SQS queue", maxMessages);

            ReceiveMessageRequest receiveMessageRequest = ReceiveMessageRequest.builder()
                    .queueUrl(queueUrl)
                    .maxNumberOfMessages(maxMessages)
                    .waitTimeSeconds(10) // Long polling
                    .messageAttributeNames("All")
                    .build();

            ReceiveMessageResponse response = sqsClient.receiveMessage(receiveMessageRequest);
            List<Message> messages = response.messages();

            logger.info("Received {} messages from SQS queue", messages.size());
            return messages;

        } catch (Exception e) {
            logger.error("Failed to receive messages from SQS: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to receive messages from SQS", e);
        }
    }

    /**
     * Delete a message from the queue after processing
     * @param message The message to delete
     */
    public void deleteMessage(Message message) {
        try {
            DeleteMessageRequest deleteMessageRequest = DeleteMessageRequest.builder()
                    .queueUrl(queueUrl)
                    .receiptHandle(message.receiptHandle())
                    .build();

            sqsClient.deleteMessage(deleteMessageRequest);

            logger.debug("Message deleted from SQS queue: messageId={}", message.messageId());

        } catch (Exception e) {
            logger.error("Failed to delete message from SQS: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to delete message from SQS", e);
        }
    }

    /**
     * Get approximate number of messages in the queue
     * @return Number of messages in the queue
     */
    public int getQueueMessageCount() {
        try {
            GetQueueAttributesRequest getQueueAttributesRequest = GetQueueAttributesRequest.builder()
                    .queueUrl(queueUrl)
                    .attributeNames(QueueAttributeName.APPROXIMATE_NUMBER_OF_MESSAGES)
                    .build();

            GetQueueAttributesResponse response = sqsClient.getQueueAttributes(getQueueAttributesRequest);
            String messageCount = response.attributes().get(QueueAttributeName.APPROXIMATE_NUMBER_OF_MESSAGES);

            return Integer.parseInt(messageCount);

        } catch (Exception e) {
            logger.error("Failed to get queue message count: {}", e.getMessage(), e);
            return 0;
        }
    }

    /**
     * Create a standard document message
     */
    private Map<String, Object> createDocumentMessage(Document document, String eventType) {
        Map<String, Object> message = new HashMap<>();
        message.put("eventType", eventType);
        message.put("documentId", document.getDocumentId());
        message.put("fileName", document.getFileName());
        message.put("contentType", document.getContentType());
        message.put("fileSize", document.getFileSize());
        message.put("s3Bucket", document.getS3Bucket());
        message.put("s3Key", document.getS3Key());
        message.put("status", document.getStatus().name());
        message.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));

        if (document.getProcessingNotes() != null) {
            message.put("processingNotes", document.getProcessingNotes());
        }

        return message;
    }

    /**
     * Send a message to the SQS queue
     */
    private void sendMessage(Map<String, Object> messageContent, String messageGroupId) {
        try {
            String messageBody = objectMapper.writeValueAsString(messageContent);

            SendMessageRequest sendMessageRequest = SendMessageRequest.builder()
                    .queueUrl(queueUrl)
                    .messageBody(messageBody)
                    .messageAttributes(Map.of(
                            "EventType", MessageAttributeValue.builder()
                                    .stringValue(messageContent.get("eventType").toString())
                                    .dataType("String")
                                    .build(),
                            "DocumentId", MessageAttributeValue.builder()
                                    .stringValue(messageContent.get("documentId").toString())
                                    .dataType("String")
                                    .build()
                    ))
                    .build();

            SendMessageResponse response = sqsClient.sendMessage(sendMessageRequest);

            logger.debug("Message sent to SQS: messageId={}, groupId={}", response.messageId(), messageGroupId);

        } catch (JsonProcessingException e) {
            logger.error("Failed to serialize message content: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to serialize message content", e);
        } catch (Exception e) {
            logger.error("Failed to send message to SQS: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to send message to SQS", e);
        }
    }
}