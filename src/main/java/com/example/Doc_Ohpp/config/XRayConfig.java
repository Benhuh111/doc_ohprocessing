package com.example.Doc_Ohpp.config;

import com.amazonaws.xray.AWSXRay;
import com.amazonaws.xray.entities.Segment;
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@Configuration
public class XRayConfig {

    @Bean
    public FilterRegistrationBean<XRayTracingFilter> xRayServletFilter() {
        FilterRegistrationBean<XRayTracingFilter> registrationBean = new FilterRegistrationBean<>();
        registrationBean.setFilter(new XRayTracingFilter());
        registrationBean.addUrlPatterns("/*");
        registrationBean.setOrder(1);
        return registrationBean;
    }

    public static class XRayTracingFilter implements Filter {

        @Override
        public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
                throws IOException, ServletException {

            HttpServletRequest httpRequest = (HttpServletRequest) request;
            HttpServletResponse httpResponse = (HttpServletResponse) response;

            String requestURI = httpRequest.getRequestURI();
            String method = httpRequest.getMethod();

            // Create a segment for this HTTP request
            Segment segment = AWSXRay.beginSegment("DocOh-Service");

            try {
                // Add HTTP request information to the segment
                Map<String, Object> requestMap = new HashMap<>();
                requestMap.put("method", method);
                requestMap.put("url", httpRequest.getRequestURL().toString());
                requestMap.put("user_agent", httpRequest.getHeader("User-Agent"));
                requestMap.put("client_ip", getClientIpAddress(httpRequest));

                segment.putHttp("request", requestMap);

                // Add custom annotations for filtering
                segment.putAnnotation("http.method", method);
                segment.putAnnotation("http.url", requestURI);
                segment.putAnnotation("service.name", "DocOh-Service");

                // Continue with the request
                chain.doFilter(request, response);

                // Add response information
                Map<String, Object> responseMap = new HashMap<>();
                responseMap.put("status", httpResponse.getStatus());
                segment.putHttp("response", responseMap);

            } catch (Exception e) {
                segment.addException(e);
                throw e;
            } finally {
                AWSXRay.endSegment();
            }
        }

        private String getClientIpAddress(HttpServletRequest request) {
            String xForwardedFor = request.getHeader("X-Forwarded-For");
            if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
                return xForwardedFor.split(",")[0].trim();
            }

            String xRealIp = request.getHeader("X-Real-IP");
            if (xRealIp != null && !xRealIp.isEmpty()) {
                return xRealIp;
            }

            return request.getRemoteAddr();
        }
    }
}
