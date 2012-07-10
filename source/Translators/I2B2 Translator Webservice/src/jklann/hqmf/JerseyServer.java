
package jklann.hqmf;

import com.sun.jersey.api.container.grizzly2.GrizzlyServerFactory;
import com.sun.jersey.api.core.PackagesResourceConfig;
import com.sun.jersey.api.core.ResourceConfig;
import org.glassfish.grizzly.http.server.HttpServer;
import javax.ws.rs.core.UriBuilder;
import java.io.IOException;
import java.net.URI;


/** Jeff Klann - 7/9/2012
 * Borrowed almost exactly from the example on Jersey's site, this starts up a 
 * Grizzly HTTPD server with Jersey running inside using the appropriate HQMF resources.
 * Base URL is read from hqmf.properties. ONLY used when NOT deployed as a servlet.
 * 
 */
 public class JerseyServer {
 
     private static URI getBaseURI() {
    	 String url = "http://localhost:8080";
    	 url = MyProps.getInstance().baseURL;
         return UriBuilder.fromUri(url).build();
     }
 
     public static final URI BASE_URI = getBaseURI();
     
     public static HttpServer httpServer = null;
 
     protected static HttpServer startServer() throws IOException {
    	 System.out.println("Initializing Xalan...");
    	 try {
			Processors.getInstance();
		} catch (Exception e) {
			System.out.println("Noooo! Terrible! "+e.getMessage());
			e.printStackTrace();
		}
         System.out.println("Starting grizzly...");
         ResourceConfig rc = new PackagesResourceConfig("jklann.hqmf");
         return GrizzlyServerFactory.createHttpServer(BASE_URI, rc);
     }
     
     public static void main(String[] args) throws IOException {
         httpServer = startServer();
         System.out.println(String.format("Jersey app started with WADL available at "
                 + "%sapplication.wadl",
                BASE_URI, BASE_URI));
         for (;;) {
        	 try {
				Thread.sleep(30000);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
         }
     
         //httpServer.stop();
     }    
 }
