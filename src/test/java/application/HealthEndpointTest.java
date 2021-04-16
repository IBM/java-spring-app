package application;

import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.web.server.LocalServerPort;
import org.springframework.test.context.junit.jupiter.SpringExtension;

@ExtendWith(SpringExtension.class)
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
public class HealthEndpointTest {

	@Autowired
	private TestRestTemplate server;

	@LocalServerPort
	private int port;

	@Test
	public void testEndpoint() throws Exception {
		String endpoint = "http://localhost:" + port + "/health";
		String response = server.getForObject(endpoint, String.class);
		assertTrue(response.startsWith("{\"status\":\"UP\""), "Invalid response from server : " + response);
	}
}
