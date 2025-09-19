# Doc_Ohpp

Doc_Ohpp is a Spring Boot application designed for document processing, integrating with AWS services such as S3, DynamoDB, and SQS.

## Features

- Spring Boot 3.5.5 (Java 21)
- AWS SDK v2 for S3, DynamoDB, and SQS
- Modular service structure for AWS integrations
- Placeholder for AWS X-Ray tracing

## Project Structure

- `config/` – AWS configuration classes
- `controller/` – REST controllers (e.g., `DocumentController`)
- `model/` – Data models (`Document`, `DocumentMetadata`)
- `service/` – Service classes for S3, DynamoDB, SQS, and document processing
- `test/` – Unit and integration tests

## Getting Started

1. Build the project:
   ```sh
   mvn clean install
   ```
2. Run the application:
   ```sh
   mvn spring-boot:run
   ```

## Configuration

Application properties can be set in `src/main/resources/application.properties`.

## Testing

Run all tests with:
```sh
  mvn test
```

## AWS Integration

- S3: File storage
- DynamoDB: Metadata storage
- SQS: Messaging

---
