package application;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Component
public class Info {
	@Value("${server.port}")
	int port;

	@EventListener(ApplicationReadyEvent.class)
	public void contextRefreshedEvent() {
		System.out.println("The following endpoints are available by default :-");
		System.out.println("  Health        : http://localhost:" + port + "/health");
		System.out.println("  Application   : http://localhost:" + port + "/v1/");
	}
}
