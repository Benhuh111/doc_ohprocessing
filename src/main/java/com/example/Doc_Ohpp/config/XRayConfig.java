package com.example.Doc_Ohpp.config;

import com.amazonaws.xray.AWSXRay;
import com.amazonaws.xray.AWSXRayRecorderBuilder;
import com.amazonaws.xray.plugins.EC2Plugin;
import com.amazonaws.xray.plugins.ECSPlugin;
import com.amazonaws.xray.strategy.sampling.LocalizedSamplingStrategy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import jakarta.annotation.PostConstruct;

@Configuration
public class XRayConfig {

    @PostConstruct
    public void init() {
        AWSXRayRecorderBuilder builder = AWSXRayRecorderBuilder.standard()
                .withPlugin(new EC2Plugin())
                .withPlugin(new ECSPlugin());

        // Use local sampling strategy for development
        builder.withSamplingStrategy(new LocalizedSamplingStrategy());

        AWSXRay.setGlobalRecorder(builder.build());
    }

    @Bean
    public AWSXRayRecorderBuilder xrayRecorderBuilder() {
        return AWSXRayRecorderBuilder.standard()
                .withPlugin(new EC2Plugin())
                .withPlugin(new ECSPlugin());
    }
}