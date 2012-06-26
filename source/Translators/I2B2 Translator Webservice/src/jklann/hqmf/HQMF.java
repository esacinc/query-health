package jklann.hqmf;

/** Jeff Klann - 6/2012 
 * My HQMF resources for Jersey. Handles execution of 
 * XSL translation as well as proxying GET-based ONT lookups to a cell specified
 * in the .properties file. I need to think more throughly about how to pass authentication
 * information into these calls when my POST request XML is already predetermined.
 * Also whether there is a more elegant way to do proxying that could make use of a redirect
 * URL.
 */

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;

import javax.ws.rs.Consumes;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;
import javax.ws.rs.core.MediaType;
import javax.xml.transform.TransformerException;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import java.io.Reader;
import com.sun.jersey.api.client.ClientResponse;
import com.sun.jersey.spi.resource.Singleton;


@Singleton
@Path("/hqmf")
public class HQMF {
    @GET @Path("/killServer")
    @Produces("text/html")
    public String killServer() {

		JerseyServer.httpServer.stop();
		System.exit(0);
		return "Stopped server";
    }
    
    @GET @Path("/log")
    @Produces("text/xml")
    public String getLog() {
		return ProcessorErrorHandler.getLog();
    }
    
    @GET @Path("/test")
    @Produces("text/xml")
    public String doTest() throws Exception {
    	Processors p = null;
		p = Processors.getInstance();
		ByteArrayOutputStream result = new ByteArrayOutputStream();
		StreamSource source = new StreamSource(p.xslLoc+"/i2b2-query.xml");
		try {
			p.hqmf.transform(source,new StreamResult(result));
		} catch(TransformerException e) { return ProcessorErrorHandler.lastFatality; }
		return result.toString();
    }
    
    @GET @Path("/reload")
    @Produces("text/html")
    public String reload() throws Exception {
    	Processors p = Processors.getInstance();
    	p.reload();
		return "XSLT was reloaded!";
    	
    }
    
    @POST 
    @Path("/tohqmf") 
    @Consumes({MediaType.APPLICATION_XML,MediaType.TEXT_XML})
    @Produces("text/xml")
    public String toHQMF(Reader input) throws Exception
    {
    	Processors p = null;
		p = Processors.getInstance();
		ByteArrayOutputStream result = new ByteArrayOutputStream();
    	StreamSource source = new StreamSource(input);
    	try {
    		p.hqmf.transform(source,new StreamResult(result));
    	} catch(TransformerException e) { return ProcessorErrorHandler.lastFatality; }
		return result.toString();    	
    }
    
    @POST 
    @Path("/toi2b2") 
    @Consumes({MediaType.APPLICATION_XML,MediaType.TEXT_XML})
    @Produces("text/xml")
    public String toI2B2(Reader input) throws Exception
    {
    	Processors p = null;
		p = Processors.getInstance();
		
		// hqmf to ihqmf
		ByteArrayOutputStream result = new ByteArrayOutputStream();
    	StreamSource source = new StreamSource(input);
    	try {
    		p.ihqmf.transform(source,new StreamResult(result));
    	} catch(TransformerException e) { return ProcessorErrorHandler.lastFatality; }
		
		// ihqmf to xml
		StreamSource s2 = new StreamSource(new ByteArrayInputStream(result.toByteArray()));
		result = new ByteArrayOutputStream(); 
		try {
			p.i2b2.transform(s2, new StreamResult(result));
		} catch(TransformerException e) { return ProcessorErrorHandler.lastFatality; }
		return result.toString();    	
    }
    
    @POST 
    @Path("/toihqmf") 
    @Consumes({MediaType.APPLICATION_XML,MediaType.TEXT_XML})
    @Produces("text/xml")
    public String toIHQMF(Reader input) throws Exception
    {
    	Processors p = null;
		p = Processors.getInstance();
		
		// hqmf to ihqmf
		ByteArrayOutputStream result = new ByteArrayOutputStream();
    	StreamSource source = new StreamSource(input);
    	try {
    		p.ihqmf.transform(source,new StreamResult(result));
    	} catch(TransformerException e) { return ProcessorErrorHandler.lastFatality; }
		return result.toString();    	
    }
    
    @Path("/getTermInfo")
    @GET
    @Produces("text/xml")
    public String getTermInfo(
    		@DefaultValue("demo") @QueryParam("username") String userName,
    		@DefaultValue("Demo") @QueryParam("project") String project,
    		@DefaultValue("i2b2demo") @QueryParam("domain") String domain,
    		@DefaultValue("demouser") @QueryParam("token") String token,
    		@DefaultValue("false") @QueryParam("isToken") boolean isToken,
    		@DefaultValue("\\\\I2B2\\i2b2\\Diagnoses\\Circulatory system (390-459)\\Acute Rheumatic fever (390-392)\\") @QueryParam("key") String key
    		) throws Exception {
    	Processors p = Processors.getInstance();
    	String request = p.generateRequest(userName, project, domain, token, isToken, key,"getTermInfo");
    	//System.out.println(request+"\n");
    	ClientResponse response = p.getTermInfo.accept(MediaType.APPLICATION_XML,MediaType.TEXT_XML).type(MediaType.TEXT_XML).post(ClientResponse.class, request);
    	String xmlResponse = response.getEntity(String.class);
    	
    	//System.out.println(response.toString());
    	//System.out.println(xmlResponse.toString());
		return xmlResponse.toString();
    }
    
    @Path("/getCodeInfo")
    @GET
    @Produces("text/xml")
    public String getCodeInfo(
    		@DefaultValue("demo") @QueryParam("username") String userName,
    		@DefaultValue("Demo") @QueryParam("project") String project,
    		@DefaultValue("i2b2demo") @QueryParam("domain") String domain,
    		@DefaultValue("demouser") @QueryParam("token") String token,
    		@DefaultValue("false") @QueryParam("isToken") boolean isToken,
    		@DefaultValue("ICD9:250") @QueryParam("key") String key
    		) throws Exception {
    	Processors p = Processors.getInstance();
    	String request = p.generateRequest(userName, project, domain, token, isToken, key,"getCodeInfo");
    	//System.out.println(request+"\n");
    	ClientResponse response = p.getCodeInfo.accept(MediaType.APPLICATION_XML,MediaType.TEXT_XML).type(MediaType.TEXT_XML).post(ClientResponse.class, request);
    	String xmlResponse = response.getEntity(String.class);
    	
    	//System.out.println(response.toString());
    	//System.out.println(xmlResponse.toString());
		return xmlResponse.toString();
    }
}