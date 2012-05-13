<?xml version="1.0" encoding="UTF-8"?>
<!-- iHQMF to i2b2 Converter
    Changelog:
    Jeff Klann - 5/2012 - initial version
    Supports basic transformations. Demographics->Age; Diagnosis; Lab Test Results
    
    Minor modifications should support 
      SHRINE Demographics -> Age, Race, Marital Status, Gender, Language
      SHRINE Diagnoses
      
    Todo: 
      SHRINE Medications
      i2b2_demo procedures
      What happens if there's no basecode
      Time: effectiveTime and measurementPeriod
      Inversion (NOT operation)
      Other sections (e.g., encounters)    
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xalan="http://xml.apache.org/xalan"
    xmlns:java="http://xml.apache.org/xslt/java"
    xmlns:hl7v3="urn:hl7-org:v3"
    version="1.0">
    <xsl:output method="xml" standalone="yes" omit-xml-declaration="no" indent="yes" xalan:indent-amount="2"/>
    
    <!-- Pretty the output -->
    <xsl:strip-space elements="*"/>
    <xsl:template match="text()"/>
    <xsl:template mode="item" match="text()"/>
    
    <!-- Concepts. Final version will hook into ontology cell. -->
    <xsl:variable name="concepts" select="document('concepts.xml')"/>
    
    <!-- Have references to dataCriteria readily available. -->
    <xsl:key name="dataCriteria" match="/hl7v3:ihqmf/*/hl7v3:id" use="@extension"/>
    
    <!-- Generic dataCriteria Output -->
    <xsl:template name="get-concept">
            <xsl:choose>
                <xsl:when test="hl7v3:code/@code">
                    <xsl:variable name="i2b2-code">
                        <xsl:choose>
                            <xsl:when test="hl7v3:code/@codeSystem='2.16.840.1.113883.6.96'">SNOMED</xsl:when>
                            <xsl:when test="hl7v3:code/@codeSystem='2.16.840.1.113883.6.104'">ICD9</xsl:when>
                            <xsl:when test="hl7v3:code/@codeSystem='2.16.840.1.113883.6.103'">ICD9</xsl:when>
                            <xsl:when test="hl7v3:code/@codeSystem='2.16.840.1.113883.6.1'">LOINC</xsl:when>
                            <xsl:when test="hl7v3:code/@codeSystem='2.16.840.1.113883.6.88'">RXNORM</xsl:when>
                            <xsl:when test="hl7v3:code/@codeSystem='2.16.840.1.113883.12.416'">PHSCDRGC</xsl:when>
                            <xsl:when test="hl7v3:code/@codeSystem='2.16.840.1.113883.6.238'">RACE</xsl:when>
                            <xsl:when test="hl7v3:code/@codeSystem='2.16.840.1.113883.5.2'">MARITAL</xsl:when>
                            <xsl:when test="hl7v3:code/@codeSystem='2.16.840.1.113883.5.1'">SEX</xsl:when>
                            <xsl:when test="hl7v3:code/@codeSystem='1.0.639.1'">LANGUAGE</xsl:when>
                            <xsl:otherwise>OID</xsl:otherwise>
                        </xsl:choose>:<xsl:value-of select="hl7v3:code/@code"/>
                    </xsl:variable>
                    <xsl:variable name="i2b2-concept" select="$concepts//concept[basecode=concat('',$i2b2-code)]"></xsl:variable>
                    <xsl:choose>
                       <xsl:when test="$i2b2-concept">
                           <hlevel><xsl:value-of select="$i2b2-concept/level"/></hlevel>
                           <item_name><xsl:value-of select="$i2b2-concept/name"/></item_name>
                           <item_key><xsl:value-of select="$i2b2-concept/key"/></item_key>
                           <tooltip><xsl:value-of select="$i2b2-concept/tooltip"/></tooltip>
                           <class>ENC</class> <!-- TODO: I'm not sure what this means. -->
                           <item_icon><xsl:value-of select="$i2b2-concept/visualattributes"/></item_icon>
                           <item_is_synonym><xsl:value-of select="$i2b2-concept/synonym_cd"/></item_is_synonym>
                       </xsl:when>
                       <xsl:when test="$i2b2-code='SNOMED:424144002'"> <!-- Special handling for ages -->
                           <!-- TODO: Check inclusiveness constraints. -->
                           <xsl:if test="not(hl7v3:value/@xsi:type='IVL_PQ' or hl7v3:value/hl7v3:low or hl7v3:value/hl7v3:high or hl7v3:value/hl7v3:low/@unit='a' or hl7v3:value/hl7v3:high/@unit='a')">
                               <xsl:message terminate="yes">Age constraints of BETWEEN only supported!</xsl:message>
                           </xsl:if>
                           <xsl:variable name="agerange">
                               <xsl:if test="hl7v3:value/hl7v3:low/@inclusive='false'"><xsl:value-of select="hl7v3:value/hl7v3:low/@value +1"/></xsl:if>
                               <xsl:if test="hl7v3:value/hl7v3:low/@inclusive='true'"><xsl:value-of select="hl7v3:value/hl7v3:low/@value"/></xsl:if>
                               <xsl:text>-</xsl:text>
                               <xsl:if test="hl7v3:value/hl7v3:high/@inclusive='false'"><xsl:value-of select="hl7v3:value/hl7v3:high/@value -1"/></xsl:if>
                               <xsl:if test="hl7v3:value/hl7v3:high/@inclusive='true'"><xsl:value-of select="hl7v3:value/hl7v3:high/@value"/></xsl:if>
                           </xsl:variable>
                           <xsl:variable name="i2b2-ageconcept" select="$concepts//concept[columnname='birth_date' and operator='BETWEEN' and contains(key,$agerange)]"/>
                           <!-- TODO: Should be harmonized with the above code to not be repetitive. -->
                           <hlevel><xsl:value-of select="$i2b2-ageconcept/level"/></hlevel>
                           <item_name><xsl:value-of select="$i2b2-ageconcept/name"/></item_name>
                           <item_key><xsl:value-of select="$i2b2-ageconcept/key"/></item_key>
                           <tooltip><xsl:value-of select="$i2b2-ageconcept/tooltip"/></tooltip>
                           <class>ENC</class> <!-- TODO: I'm not sure what this means. -->
                           <item_icon><xsl:value-of select="$i2b2-ageconcept/visualattributes"/></item_icon>
                           <item_is_synonym><xsl:value-of select="$i2b2-ageconcept/synonym_cd"/></item_is_synonym>
                       </xsl:when>
                       <xsl:otherwise>
                            <xsl:message terminate="no"><xsl:value-of select="$i2b2-code"/> not found. :(</xsl:message>
                       </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="hl7v3:code/@valueSet"/>
                </xsl:otherwise>
            </xsl:choose>
    </xsl:template>
    
    
    <!-- Constrain_by_value on lab results. -->
    <xsl:template name="contrain_by_value">
        <constrain_by_value>
            <xsl:choose>
                <xsl:when test="hl7v3:value/@xsi:type='IVL_PQ'">
                    <value_type>NUMBER</value_type>
                    <xsl:choose>
                        <xsl:when test="hl7v3:value/hl7v3:low and not(hl7v3:value/hl7v3:high)"> <!-- GT and GE -->
                            <value_unit_of_measure><xsl:value-of select="hl7v3:value/hl7v3:low/@unit"/></value_unit_of_measure>
                            <value_constraint><xsl:value-of select="hl7v3:value/hl7v3:low/@value"/></value_constraint>
                            <value_operator> 
                                <xsl:if test="hl7v3:value/hl7v3:low/@inclusive='false'">GT</xsl:if>
                                <xsl:if test="hl7v3:value/hl7v3:low/@inclusive='true'">GE</xsl:if>
                            </value_operator>  
                        </xsl:when>
                        <xsl:when test="hl7v3:value/hl7v3:high and not(hl7v3:value/hl7v3:low)"> <!-- LT and LE -->
                            <value_unit_of_measure><xsl:value-of select="hl7v3:value/hl7v3:high/@unit"/></value_unit_of_measure>
                            <value_constraint><xsl:value-of select="hl7v3:value/hl7v3:high/@value"/></value_constraint>
                            <value_operator> 
                                <xsl:if test="hl7v3:value/hl7v3:high/@inclusive='false'">LT</xsl:if>
                                <xsl:if test="hl7v3:value/hl7v3:high/@inclusive='true'">LE</xsl:if>
                            </value_operator> 
                        </xsl:when>
                        <xsl:when test="hl7v3:value/hl7v3:low and hl7v3:value/hl7v3:high"> <!-- BETWEEN -->
                            <xsl:if test="hl7v3:value/hl7v3:low/@unit != hl7v3:value/hl7v3:high/@unit"><xsl:message terminate="yes">Units do not agree in interval!</xsl:message></xsl:if>
                            <value_unit_of_measure><xsl:value-of select="hl7v3:value/hl7v3:high/@unit"/></value_unit_of_measure>
                            <value_constraint><xsl:value-of select="hl7v3:value/hl7v3:low/@value"/> and <xsl:value-of select="hl7v3:value/hl7v3:high/@value"/></value_constraint>
                            <value_operator>BETWEEN</value_operator> <!-- TODO: Not checking inclusiveness pattern is supported -->
                        </xsl:when>
                        <xsl:otherwise> 
                            <xsl:message terminate="yes">Unsupported constraint type!</xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="hl7v3:value/@xsi:type='PQ'"> <!-- EQ -->
                    <constrain_by_value>
                        <value_type>NUMBER</value_type>
                        <value_unit_of_measure><xsl:value-of select="hl7v3:value/@unit"/></value_unit_of_measure>
                        <value_operator>EQ</value_operator>
                        <value_constraint><xsl:value-of select="hl7v3:value/@value"/></value_constraint>
                    </constrain_by_value>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">Unsupported result value type: <xsl:value-of select="hl7v3:value/@xsi:type"/></xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </constrain_by_value>
    </xsl:template>
    
    <!-- Top-level output -->
    <xsl:template match="/hl7v3:ihqmf">
        <xsl:message><xsl:value-of select="system-property('user.dir')"/></xsl:message>
        <ns6:request xmlns:ns4="http://www.i2b2.org/xsd/cell/crc/psm/1.1/" xmlns:ns7="http://www.i2b2.org/xsd/cell/ont/1.1/" xmlns:ns3="http://www.i2b2.org/xsd/cell/crc/pdo/1.1/" xmlns:ns5="http://www.i2b2.org/xsd/hive/plugin/" xmlns:ns2="http://www.i2b2.org/xsd/hive/pdo/1.1/" xmlns:ns6="http://www.i2b2.org/xsd/hive/msg/1.1/" xmlns:ns8="http://www.i2b2.org/xsd/cell/crc/psm/querydefinition/1.1/">
            <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <query_definition>
                    <query_name><xsl:value-of select="hl7v3:title"/></query_name>
                    <query_timing>ANY</query_timing> <!-- Should work with measurePeriod -->
                    <specificity_scale>0</specificity_scale>
                    <xsl:apply-templates select="hl7v3:populationCriteria"/>
                </query_definition>
            </ns4:request>
        </ns6:request>
    </xsl:template>
    <xsl:template match="hl7v3:populationCriteria">
        <xsl:if  test="count(hl7v3:dataCriteriaCombiner) != 1">
            <xsl:message terminate="yes">Non-i2b2 dataCriteriaCombiner structure - too many outer combiners (<xsl:value-of select="count(dataCriteriaCombiner)"/>)!</xsl:message>
        </xsl:if>
        <xsl:if  test="hl7v3:dataCriteriaCombiner[1]/hl7v3:criteriaOperation != 'AllTrue'">
            <xsl:message terminate="yes">Non-i2b2 dataCriteriaCombiner structure - outer combiner must be AllTrue (not <xsl:value-of select="dataCriteriaCombiner[1]/criteriaOperation"/>)!</xsl:message>
        </xsl:if>
        <xsl:apply-templates select="hl7v3:dataCriteriaCombiner/hl7v3:dataCriteriaCombiner"/>            
    </xsl:template>

    <!-- Panel -->
    <xsl:template match="hl7v3:dataCriteriaCombiner/hl7v3:dataCriteriaCombiner">
        <xsl:if test="hl7v3:criteriaOperation!='AtLeastOneTrue'">
            <xsl:message terminate="yes">Non-i2b2 dataCriteriaCombiner structure - inner combiners must be AtLeastOneTrue! (not <xsl:value-of select="criteraOperation"/>)</xsl:message>
        </xsl:if>
        <panel>
            <panel_number><xsl:value-of select="1+count(preceding-sibling::hl7v3:dataCriteriaCombiner)"/></panel_number>
            <panel_accuracy_scale>100</panel_accuracy_scale>
            <invert>0</invert>
            <panel_timing>ANY</panel_timing> <!-- Todo: should at least play with measurePeriod -->
            <total_item_occurrences>1</total_item_occurrences>
            <xsl:apply-templates mode="item" select="key('dataCriteria',hl7v3:dataCriteriaReference/@extension)/.."></xsl:apply-templates>
        </panel>
    </xsl:template>
    
    <!-- Template for non-result criteria -->
    <xsl:template mode="item" match="hl7v3:AllergyCriteria|hl7v3:EncounterCriteria|hl7v3:ProblemCriteria|hl7v3:DemographicsCriteria">
        <item>
            <item_name><xsl:value-of select="hl7v3:localVariableName"/></item_name>
            <xsl:call-template name="get-concept"/>
        </item>
    </xsl:template>
    
    <!-- Template for result criteria -->
    <xsl:template mode="item" match="hl7v3:ProcedureCriteria|hl7v3:MedicationCriteria|hl7v3:LabResultsCriteria|hl7v3:VitalSignCriteria">
        <item>
            <item_name><xsl:value-of select="hl7v3:localVariableName"/></item_name>
            <xsl:call-template name="get-concept"/>
            <xsl:call-template name="contrain_by_value"/>
        </item>
    </xsl:template>
    
    <!-- Immunization has a reaction and category, so handle separately -->
    <xsl:template mode="item" match="hl7v3:ImmunizationCriteria">
        <item>
            <item_name><xsl:value-of select="hl7v3:localVariableName"/></item_name>
            <xsl:call-template name="get-concept"/>
        </item>
    </xsl:template>
</xsl:stylesheet>