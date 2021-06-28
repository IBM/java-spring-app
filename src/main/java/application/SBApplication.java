package application;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springdoc.core.GroupedOpenApi;


@SpringBootApplication
public class SBApplication {
    @Bean
    public GroupedOpenApi actuatorOpenApi() {
        return GroupedOpenApi.builder()
            .group("api")
            .pathsToMatch("/health", "/v1")
            .build();
    }

    public static void main(String[] args) {
        SpringApplication.run(SBApplication.class, args);
    }
}
