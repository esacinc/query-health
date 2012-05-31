<?xml version="1.0" encoding="UTF-8"?>
<!-- iHQMF to i2b2 Converter
    Changelog:
    Jeff Klann - 5/2012 - v0.1
        Supports basic transformations. Demographics->Age; Diagnosis; Lab Test Results
        Inversion (NOT operation)
        effectiveTime and measurementPeriod
        Panel-wide timeRelationships: all time relationships within a panel reference each other and occur overlappingly 
        Panel-wide filterRelationships: all criteria within a panel specify a minimum occurrence number that is the same
        (Appropriate errors thrown for time and filter relationships that are impossible in i2b2 XML.)
        SHRINE Demographics -> Age, Race, Marital Status, Gender, Language
        SHRINE Diagnoses, Medications
        i2b2 demo procedures
          
    Todo: 
      EncounterCriteria AgeAtVisit doesn't work.
      Sections not mentioned above are untested.
      Finish timeRelationships to the measurePeriod (right now just copies the measurePeriod)
      Constrain by modifiers (esp. medication route and dose)
      Integration
      Misc todos
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xalan="http://xml.apache.org/xalan"
    xmlns:java="http://xml.apache.org/xslt/java"
    xmlns:hl7v3="urn:hl7-org:v3"
    version="1.0">
    <xsl:import href="time.xsl"/>
    
    <xsl:output method="xml" standalone="yes" omit-xml-declaration="no" indent="yes" xalan:indent-amount="2"/>
    
    <!-- Pretty the output -->
    <xsl:strip-space elements="*"/>
    <xsl:template match="text()"/>
    <xsl:template mode="item" match="text()"/>
    
    <!-- Global parameters that should get their value from the invoking code.
       I think this will all be determined by the server or by query health and doesn't need to be packaged in HQMF? -->
    <xsl:param name="username">demo</xsl:param>
    <xsl:param name="sessiontoken"></xsl:param>
    <xsl:param name="userproject">Demo</xsl:param> <!-- Also this is assumed to be the user's group -->
    <xsl:param name="userdomain">HarvardDemo</xsl:param>
    
    <!-- Concepts. Final version will hook into ontology cell. -->
    <xsl:variable name="concepts" select="document('concepts.xml')"/>
    
    <!-- Have references to dataCriteria readily available. -->
    <xsl:key name="dataCriteria" match="/hl7v3:ihqmf/*/hl7v3:id" use="@extension"/>
    
    <!-- Also have a reference to the measurePeriod available. -->
    <xsl:variable name="measurePeriod-rtf">
        <xsl:apply-templates select="/hl7v3:ihqmf/hl7v3:measurePeriod/hl7v3:value"/>
    </xsl:variable>
    <xsl:variable name="measurePeriod" select="xalan:nodeset($measurePeriod-rtf)"/>
    
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
                    <xsl:variable name="i2b2-concept-rtf"> <!-- This is an unfortunate but necessary way to put result-tree fragments backtogether. -->
                        <xsl:choose>
                            <xsl:when test="$concepts//concept[basecode=$i2b2-code]"><xsl:copy-of select="$concepts//concept[basecode=$i2b2-code]"/></xsl:when>
                            <xsl:when test="$concepts//concept[basecode=concat('SHRINE|',$i2b2-code)]"><xsl:copy-of select="$concepts//concept[basecode=concat('SHRINE|',$i2b2-code)]"/></xsl:when>
                            <xsl:otherwise> <!-- Note: We create a fake \\notfound key if there's an error. -->
                                <concept>
                                    <level></level>
                                    <name>Not Found!</name>
                                    <key>//notfound</key>
                                    <tooltip>Not Found!</tooltip>
                                    <visualattributes></visualattributes>
                                    <synonym_cd></synonym_cd>
                                </concept>
                            </xsl:otherwise> <!-- Return empty-handed. -->
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="i2b2-concept" select="xalan:nodeset($i2b2-concept-rtf)/concept[1]"/> 
                     <!-- Note: we arbitrarily choose the first matching concept... -->
                    <xsl:choose>
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
                        <xsl:when test="$i2b2-concept!=''">
                            <hlevel><xsl:value-of select="$i2b2-concept/level"/></hlevel>
                            <item_name><xsl:value-of select="$i2b2-concept/name"/></item_name>
                            <item_key><xsl:value-of select="$i2b2-concept/key"/></item_key>
                            <tooltip><xsl:value-of select="$i2b2-concept/tooltip"/></tooltip>
                            <class>ENC</class> <!-- TODO: I'm not sure what this means. -->
                            <item_icon><xsl:value-of select="$i2b2-concept/visualattributes"/></item_icon>
                            <item_is_synonym><xsl:value-of select="$i2b2-concept/synonym_cd"/></item_is_synonym>
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
    
    <!-- Convert IVL_PQ width values to a high and low 
        This is really a meager effort and a better normalizer should be written.
        The only option is a width in years with no high or low. -->
    <xsl:template match="hl7v3:value">
        <xsl:choose>
            <xsl:when test="./hl7v3:width">
                <xsl:if test="hl7v3:width/@unit!='a'">
                    <xsl:message terminate="yes">Only timetamp widths in year multiples are supported.</xsl:message>
                </xsl:if>
                <hl7v3:low value="{number(substring($now,1,8))-(10000*hl7v3:width/@value)}"/> 
                <hl7v3:high value="{$now}"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Constrain_by_date 
        Assumes that effectiveTime has only a high/low element.
        Also assumes that if an effectiveTime exists, it completely overrides the measurePeriod. This might be wrong? -->
    <xsl:template name="constrain_by_date">
        <xsl:choose>
            <xsl:when test="hl7v3:effectiveTime">
                <constrain_by_date>
                    <date_from>
                        <xsl:call-template name="convert_date"><xsl:with-param name="input_date" select="hl7v3:effectiveTime/hl7v3:low/@value"/></xsl:call-template>           
                    </date_from>
                    <date_to>
                        <xsl:call-template name="convert_date"><xsl:with-param name="input_date" select="hl7v3:effectiveTime/hl7v3:high/@value"/></xsl:call-template>  
                    </date_to>
                </constrain_by_date>
            </xsl:when>
            <xsl:when test="count(hl7v3:timeRelationship/hl7v3:measurePeriodTimeReference)>0">
                <!-- TODO: Actually process the timeQuantity and timeRelationshipCode -->
                <constrain_by_date>
                    <date_from>
                        <xsl:call-template name="convert_date"><xsl:with-param name="input_date" select="$measurePeriod/hl7v3:low/@value"/></xsl:call-template>           
                    </date_from>
                    <date_to>
                        <xsl:call-template name="convert_date"><xsl:with-param name="input_date" select="$measurePeriod/hl7v3:high/@value"/></xsl:call-template>  
                    </date_to>
                </constrain_by_date>                
            </xsl:when>
            <xsl:otherwise>
                <!-- Process measurePeriod -->
                <constrain_by_date>
                    <date_from>
                        <xsl:call-template name="convert_date"><xsl:with-param name="input_date" select="$measurePeriod/hl7v3:low/@value"/></xsl:call-template>           
                    </date_from>
                    <date_to>
                        <xsl:call-template name="convert_date"><xsl:with-param name="input_date" select="$measurePeriod/hl7v3:high/@value"/></xsl:call-template>  
                    </date_to>
                </constrain_by_date>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Helper function converts dates from ISO/HL7 format to XMLSchema dateTime format -->
    <xsl:template name="convert_date">
        <xsl:param name="input_date"/>
        <xsl:value-of select="concat(substring($input_date,1,4),'-',substring($input_date,5,2),'-',substring($input_date,7,2),'Z')"/>
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
                <xsl:when test="count(hl7v3:value)=0">
                    <xsl:message>Warning: element <xsl:value-of select="hl7v3:localVariableName"/> can take a value constraint but doesn't have one...</xsl:message>
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
            <message_header>
                <security> <!-- May use <ticket/> instead of <domain/>, <username/> & <password/> -->
                    <domain><xsl:value-of select="$userdomain"/></domain>
                    <username><xsl:value-of select="$username"/></username>
                    <password token_ms_timeout="1800000" is_token="true">SessionKey:<xsl:value-of select="$sessiontoken"/></password>
                </security>
                <project_id><xsl:value-of select="$userproject"/></project_id>
            </message_header>
            <request_header>
                <result_waittime_ms>180000</result_waittime_ms> <!-- Must send back 'DONE', 'PENDING' or 'ERROR' within this time -->
            </request_header>
            <message_body> 
                <ns4:psmheader>
                    <user>
                        <xsl:attribute name="login"><xsl:value-of select="$username"/></xsl:attribute>
                        <xsl:attribute name="group"><xsl:value-of select="$userproject"/></xsl:attribute>
                        <xsl:value-of select="$username"/>
                    </user>
                    <patient_set_limit>0</patient_set_limit>
                    <estimated_time>0</estimated_time>
                    <query_mode>optimize_without_temp_table</query_mode>
                    <request_type>CRC_QRY_runQueryInstance_fromQueryDefinition</request_type>
                </ns4:psmheader>
                    <ns4:request xsi:type="ns4:query_definition_requestType" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                        <query_definition>
                            <query_name><xsl:value-of select="hl7v3:title"/></query_name>
                            <query_timing>ANY</query_timing> <!-- Should work with measurePeriod -->
                            <specificity_scale>0</specificity_scale>
                            <xsl:apply-templates select="hl7v3:populationCriteria"/>
                        </query_definition>
                    </ns4:request>
                </message_body>
            </ns6:request>
    </xsl:template>
    
    <xsl:template match="hl7v3:populationCriteria">
        <xsl:if  test="count(hl7v3:dataCriteriaCombiner) != 1">
            <xsl:message terminate="yes">Non-i2b2 dataCriteriaCombiner structure - too many outer combiners (<xsl:value-of select="count(dataCriteriaCombiner)"/>)!</xsl:message>
        </xsl:if>
        <xsl:if  test="hl7v3:dataCriteriaCombiner[1]/hl7v3:criteriaOperation != 'AllTrue'">
            <xsl:message terminate="yes">Non-i2b2 dataCriteriaCombiner structure - outer combiner must be AllTrue (not <xsl:value-of select="hl7v3:dataCriteriaCombiner[1]/hl7v3:criteriaOperation"/>)!</xsl:message>
        </xsl:if>
        <xsl:apply-templates select="hl7v3:dataCriteriaCombiner/hl7v3:dataCriteriaCombiner"/>            
    </xsl:template>

    <!-- Panel -->
    <xsl:template match="hl7v3:dataCriteriaCombiner/hl7v3:dataCriteriaCombiner">
        <xsl:if test="hl7v3:criteriaOperation!='AtLeastOneTrue' and hl7v3:criteriaOperation!='AllFalse'">
            <xsl:message terminate="yes">Non-i2b2 dataCriteriaCombiner structure - inner combiners must be AtLeastOneTrue or AllFalse! (not <xsl:value-of select="hl7v3:criteraOperation"/>)</xsl:message>
        </xsl:if>
        
        <!-- Handle filter and global time criteria. -->
        <xsl:variable name="timestuff-rtf">
            <xsl:apply-templates mode="time" select="key('dataCriteria',hl7v3:dataCriteriaReference/@extension)/.."></xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="timestuff" select="xalan:nodeset($timestuff-rtf)"/>
        
        <!-- Panel-wide minimum count -->
        <xsl:variable name="mincount">
            <xsl:choose>
                <xsl:when test="count($timestuff/VALUE)>0">
                    <xsl:choose>
                        <xsl:when test="sum($timestuff/VALUE) = $timestuff/VALUE[1]*count($timestuff/VALUE)">
                            <xsl:value-of select="$timestuff/VALUE[1]"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message terminate="yes">
                                i2b2 requires all filterCriteria within a panel to be the same!
                            </xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>1</xsl:otherwise>
            </xsl:choose>
        </xsl:variable> 
        
        <!-- Check all temporal constraints are within one panel
              TODO: We do not check that each item also mentions all items in the panel... -->
        <xsl:for-each select="$timestuff/REF">
            <xsl:choose>    
                <xsl:when test="hl7v3:dataCriteriaReference[@extension=current()]">
                    <xsl:message>Good!</xsl:message>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">
                        Cannot process time constraint - referencing across panels!
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:variable name="panel-timing">
            <xsl:choose>
                <xsl:when test="count($timestuff/REF)>0">SAMEVISIT</xsl:when>
                <xsl:otherwise>ANY</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <panel>
            <panel_number><xsl:value-of select="1+count(preceding-sibling::hl7v3:dataCriteriaCombiner)"/></panel_number>
            <panel_accuracy_scale>100</panel_accuracy_scale>
            <invert>
                <xsl:choose>
                    <xsl:when test="hl7v3:criteriaOperation='AtLeastOneTrue'">0</xsl:when>
                    <xsl:when test="hl7v3:criteriaOperation='AllFalse'">1</xsl:when>
                </xsl:choose>
            </invert>
            <panel_timing><xsl:value-of select="$panel-timing"/></panel_timing> <!-- Todo: should at least play with measurePeriod -->
            <total_item_occurrences><xsl:value-of select="$mincount"/></total_item_occurrences>
            <xsl:apply-templates mode="item" select="key('dataCriteria',hl7v3:dataCriteriaReference/@extension)/.."></xsl:apply-templates>
        </panel>
    </xsl:template>

    <!-- Handle panel-wide temporal constraints -->
    <xsl:template mode="time" match="*">
        <xsl:if test="./hl7v3:timeRelationship/hl7v3:dataCriteriaTimeReference">
            <xsl:choose>
                <xsl:when test="count(./hl7v3:timeRelationship/hl7v3:timeQuantity)=0"> <!-- TODO: Also check the time relationship is one that means 'overlaps' -->
                    <REF><xsl:value-of select="./hl7v3:timeRelationship/hl7v3:dataCriteriaTimeReference/@extension"/></REF>                    
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">Illegal panel-wide time relationship; only same encounter is supported.</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="./hl7v3:filterCriteria/hl7v3:filterCode">
            <xsl:choose>
                <xsl:when test="./hl7v3:filterCriteria/hl7v3:filterCode = 'MIN' and ./hl7v3:filterCriteria/hl7v3:repeatNumber">
                    <VALUE><xsl:value-of select="./hl7v3:filterCriteria/hl7v3:repeatNumber/@value"/></VALUE>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">
                        The only filterCriteria supported are minimum repeat numbers!
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
 
    <!-- Handle modifiers for some types -->
    <xsl:template mode="modifiers" match="hl7v3:MedicationCriteria">
        <xsl:if test="./hl7v3:medicationState != 'EVN'">
            <xsl:message terminate="yes">
                Only medication events are supported, not <xsl:value-of select="./hl7v3:medicationState"/>
            </xsl:message>
        </xsl:if>
        <!-- TODO: SUPPORT constrain_by_modifier -->
        <xsl:if test="./hl7v3:routeCode|./hl7v3:medicationRateQuantity|./hl7v3:medicationDoseQuantity">
            <xsl:message terminate="yes"> <!-- Todo: THESE I ACTUALLY NEED TO SUPPORT -->
                Medication modifiers are not yet supported. 
            </xsl:message>
        </xsl:if>
    </xsl:template>
    <xsl:template mode="modifiers" match="hl7v3:ProcedureCriteria">
        <xsl:if test="./hl7v3:value">
            <xsl:message terminate="yes">
                Values are illegal for procedures!
            </xsl:message>
        </xsl:if>
        <!-- TODO: SUPPORT constrain_by_modifier -->
        <xsl:if test="./hl7v3:status|./hl7v3:procedureBodySite"> <!-- Todo: get rid of these? -->
            <xsl:message terminate="yes"> 
                Procedure modifiers are not yet supported. 
            </xsl:message>
        </xsl:if>
    </xsl:template>
    <xsl:template mode="modifiers" match="hl7v3:DemographicsCriteria|hl7v3:VitalSignsCriteria|hl7v3:LabResultsCriteria">
        <xsl:if test="./hl7v3:status">
            <xsl:message terminate="yes">
                Status is illegal for demographics and vitals!
            </xsl:message>
        </xsl:if>
    </xsl:template>
    <xsl:template mode="modifiers" match="hl7v3:ImmunizationCriteria">
        <xsl:if test="./hl7v3:category">
            <xsl:message terminate="yes"> <!-- todo: get rid of this? -->
                Not sure what category is in immunization criteria???
            </xsl:message>
        </xsl:if>
        <!-- TODO: SUPPORT constrain_by_modifier -->
        <xsl:if test="./hl7v3:reaction"> <!-- todo get rid of this? -->
            <xsl:message terminate="yes"> 
                Immunization modifiers are not yet supported. 
            </xsl:message>
        </xsl:if>
    </xsl:template>
    <!-- This template seems to be needed for nodes without a template, or garbage is sometimes output. -->
    <xsl:template mode="modifiers" match="*"></xsl:template>
    
    <!-- Template for non-result criteria -->
    <xsl:template mode="item" match="hl7v3:AllergyCriteria|hl7v3:ProblemCriteria|hl7v3:DemographicsCriteria">
        <item>
            <item_name><xsl:value-of select="hl7v3:localVariableName"/></item_name>
            <xsl:call-template name="get-concept"/>
            <xsl:call-template name="constrain_by_date"/>
            <xsl:apply-templates mode="modifiers" select="."/>
        </item>
    </xsl:template>
    
    <!-- Template for result criteria -->
    <xsl:template mode="item" match="hl7v3:ProcedureCriteria|hl7v3:EncounterCriteria|hl7v3:MedicationCriteria|hl7v3:LabResultsCriteria|hl7v3:VitalSignCriteria">
        <item>
            <item_name><xsl:value-of select="hl7v3:localVariableName"/></item_name>
            <xsl:call-template name="get-concept"/>
            <xsl:call-template name="contrain_by_value"/>
            <xsl:call-template name="constrain_by_date"/>
            <xsl:apply-templates mode="modifiers" select="."/>
        </item>
    </xsl:template>
    
    <!-- Immunization has a weird reaction and category, so handle separately -->
    <xsl:template mode="item" match="hl7v3:ImmunizationCriteria">
        <item>
            <item_name><xsl:value-of select="hl7v3:localVariableName"/></item_name>
            <xsl:call-template name="get-concept"/>
        </item>
    </xsl:template>
</xsl:stylesheet>