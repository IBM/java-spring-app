package application;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Bean;
import org.springdoc.core.GroupedOpenApi;

import io.swagger.v3.oas.models.ExternalDocumentation;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;


@Configuration
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
