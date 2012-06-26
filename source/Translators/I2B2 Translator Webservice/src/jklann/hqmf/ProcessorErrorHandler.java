package jklann.hqmf;

import java.io.StringReader;
import java.io.StringWriter;

import javax.xml.transform.ErrorListener;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.TransformerFactoryConfigurationError;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

/** Jeff Klann - 6/2012
 * 
 * A somewhat goofy error handler for Xalan transforms. Keeps a global log of 
 * warnings and errors and the last fatal error, for return and display. Keeps
 * chugging through the transform except when reaching a fatal error, in which 
 * case the exception is passed along.
 * 
 * @author jklann
 *
 */

public class ProcessorErrorHandler implements ErrorListener {

	static StringBuilder log;
	static Transformer identity;
	static String lastFatality = "";
	
	static {
		log = new StringBuilder();
		log.append("<?xml version='1.0'?><errors>");
		try {
			identity = TransformerFactory.newInstance().newTransformer();
		} catch (TransformerConfigurationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (TransformerFactoryConfigurationError e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	String lastwarning = "<warning></warning>";
	
	public static String getLog() {
		return webifyXML(log.toString()+"</errors>");
	}
	
	public static String webifyXML(String input) {
		System.out.println(input);
		Source xmlInput = new StreamSource(new StringReader(input));
		StreamResult xmlOutput = new StreamResult(new StringWriter());
		try {
			identity.transform(xmlInput, xmlOutput);
		} catch (TransformerException e) {
			// TODO Auto-generated catch block
			System.out.println("Error webifying log: "+e.getMessage());
		}
		return xmlOutput.getWriter().toString();		
	}
	
	public void error(TransformerException arg0) throws TransformerException {
		log.append("<error>"+arg0.getMessage()+"</error>");

	}

	public void fatalError(TransformerException arg0)
			throws TransformerException {
		log.append("<fatalerror>"+arg0.getMessageAndLocation()+"</fatalerror>");
		
		lastFatality = webifyXML("<errors>"+lastwarning+"<fatalerror>"+arg0.getMessageAndLocation()+"</fatalerror>"+"</errors>");
		throw arg0;
	}

	public void warning(TransformerException arg0) throws TransformerException {
		lastwarning="<warning>"+arg0.getMessage()+"</warning>";
		log.append(lastwarning);
	}

}
