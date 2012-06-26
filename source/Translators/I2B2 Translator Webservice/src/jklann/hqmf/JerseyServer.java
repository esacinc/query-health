/** Jeff Klann - 6/2012
 * Borrowed almost exactly from the example on Jersey's site, this starts up a 
 * Grizzly HTTPD server with Jersey running inside using the appropriate HQMF resources.
 * Base URL is read from hqmf.properties, but port 8080 is hardcoded.
 */


package jklann.hqmf;
   import com.sun.jersey.api.container.grizzly2.GrizzlyServerFactory;
   import com.sun.jersey.api.core.PackagesResourceConfig;
   import com.sun.jersey.api.core.ResourceConfig;
   import org.glassfish.grizzly.http.server.HttpServer;
import org.glassfish.grizzly.http.server.NetworkListener;
   
   import javax.ws.rs.core.UriBuilder;
   import java.io.IOException;
import java.net.URI;


 
 public class JerseyServer {
 
     private static URI getBaseURI() {
    	 String url = "http://localhost/";
    	 try {
 			url = Processors.getInstance().baseURL;
 		} catch (Exception e) {
 			System.out.println("Noooo! Terrible! "+e.getMessage());
 			e.printStackTrace();
 		}
         return UriBuilder.fromUri(url).port(8080).build();
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
