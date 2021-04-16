package application;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.junit.jupiter.SpringExtension;

@ExtendWith(SpringExtension.class)
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
public class EndpointTest {

	@Autowired
	private TestRestTemplate server;

	@LocalServerPort
	private int port;

	@Test
	public void testEndpoint() throws Exception {
		String endpoint = "http://localhost:" + port;
		ResponseEntity<String> response = server.getForEntity(endpoint, String.class);
		HttpStatus status = response.getStatusCode();
		assertEquals(HttpStatus.OK, status, "Invalid response from server : " + response);
	}
}
