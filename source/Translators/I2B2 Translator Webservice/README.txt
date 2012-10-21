Jeff Klann - 10/2012

This is a preliminary version of an I2B2 HQMF translator service (to house the XSL transforms and perform ontology lookups), written with Jersey. It can be run standalone or in an i2b2 JBoss installation.

If deploying as JBOSS, copy the hqmf.war directory to {jboss}/server/default/deploy/hqmf.war. Do the following:

1. Edit the hqmf.properties to match your local environment. (Note that subkey_age is no longer required, but the parameter must exist in the properties file.)

2. Copy the I2B2 XSL Transforms directory contents into the XSL directory here (or elsewhere if so configured in the properties file).

3. Place the compiled code directly in the war directory. A compiled version of the code is included here for convenience.

4. Add the jersey servlet libraries to {jboss}/server/default/lib. You will need:

asm-3.1.jar		jersey-core-1.12.jar	jersey-servlet-1.12.jar
jersey-client-1.12.jar	jersey-server-1.12.jar	jsr311-api-1.1.1.jar

If not deploying in JBoss, simply compile and run the code (target is JerseyServer) and make sure that hqmf.properties (in the war directory) is in the current directory when the code is running and is configured for the local environment.

Jeff Klann, PhD
Partners Healthcare
Massachusetts General Hospital
Harvard Medical School