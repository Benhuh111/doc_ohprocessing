package com.example.Doc_Ohpp;

import com.amazonaws.xray.AWSXRay;
import com.amazonaws.xray.AWSXRayRecorderBuilder;
import com.amazonaws.xray.plugins.EC2Plugin;
import com.amazonaws.xray.strategy.sampling.LocalizedSamplingStrategy;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class DocOhppApplication {

	static {
		// Configure X-Ray with proper service name and plugins at startup
		AWSXRayRecorderBuilder builder = AWSXRayRecorderBuilder.standard()
				.withPlugin(new EC2Plugin())
				.withSamplingStrategy(new LocalizedSamplingStrategy());

		AWSXRay.setGlobalRecorder(builder.build());

		// Set the service name for X-Ray traces
		System.setProperty("com.amazonaws.xray.strategy.tracingName", "DocOh-Service");
	}

	public static void main(String[] args) {
		SpringApplication.run(DocOhppApplication.class, args);
	}

}