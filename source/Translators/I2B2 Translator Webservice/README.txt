Jeff Klann - 7/2012

This is a preliminary version of an I2B2 translator service to house the XSL transforms and perform ontology lookups, written with Jersey. I can be run standalone or deployed in JBOSS.

If deploying as JBOSS, compile the code and place it in a directory {jboss}/server/default/deploy/hqmf.war with the correct package structure. Copy hqmf.properties and the WEB-INF directory there as well. Edit the hqmf.properties file. Add the jersey servlet libraries to {jboss}/server/default/lib. You will need:

asm-3.1.jar		jersey-core-1.12.jar	jersey-servlet-1.12.jar
jersey-client-1.12.jar	jersey-server-1.12.jar	jsr311-api-1.1.1.jar

Finally, be sure to download the I2B2 HQMF Transforms XSL directory into a location specified in your hqmf.properties.