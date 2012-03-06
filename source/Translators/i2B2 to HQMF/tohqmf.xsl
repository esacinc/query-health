<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns="urn:hl7-org:v3" version="1.0">
  <xsl:import href="time.xsl"/>
  <xsl:output indent="yes"/>
  <!-- 
    create a variable to access I2B2 Concepts.  In production
    this would be accessed via a web service request 
  -->
  <xsl:variable name="concepts" select="document('concepts.xml')"/>

  <!-- Create an OID for the document -->
  <xsl:variable name="OID"
    >2.16.840.1.113883.3.1619.5148.3</xsl:variable>
  <xsl:variable name="docOID">
    <xsl:value-of select="$OID"/>
    <xsl:text>.</xsl:text>
    <xsl:value-of select="$nowOID"/>
  </xsl:variable>

  <xsl:template match="//query_definition">
    <xsl:if
      test="//result_output_list/result_output/@name != 'patient_count_xml'"
      > Cannot map <xsl:value-of
        select="//result_output_list/result_output/@name"/> to HQMF. </xsl:if>
    <QualityMeasureDocument xmlns="urn:hl7-org:v3"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      classCode="DOC">
      <typeId root="2.16.840.1.113883.1.3" extension="POQM_HD00001"/>
      <id root="{$docOID}.1"/>
      <code code="57024-2" codeSystem="2.16.840.1.113883.6.1"/>
      <title>Sample Quality Measure Document</title>
      <statusCode code="completed"/>
      <setId root="{$docOID}"/>
      <versionNumber value="1"/>
      <author typeCode="AUT" contextControlCode="OP">
        <assignedPerson classCode="ASSIGNED"/>
      </author>
      <custodian typeCode="CST">
        <assignedPerson classCode="ASSIGNED"/>
      </custodian>
      <controlVariable>
        <localVariableName>MeasurePeriod</localVariableName>
        <measurePeriod>
          <id root="0" extension="StartDate"/>
          <value>
            <width unit="a" value="1"/>
          </value>
        </measurePeriod>
      </controlVariable>
      <component>
        <measureDescriptionSection>
          <title>Measure Description Section</title>
          <text>This is a description of the measure.</text>
        </measureDescriptionSection>
      </component>
      <component>
        <dataCriteriaSection>
          <code code="57025-9" codeSystem="2.16.840.1.113883.6.1"/>
          <title>Data Criteria Section</title>
          <text>This section describes the data criteria.</text>
          <definition>
            <observationDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Demographics"/>
            </observationDefinition>
          </definition>
          <definition>
            <encounterDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Encounters"/>
            </encounterDefinition>
          </definition>
          <definition>
            <observationDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Problems"/>
            </observationDefinition>
          </definition>
          <definition>
            <observationDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Allergies"/>
            </observationDefinition>
          </definition>
          <definition>
            <procedureDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Procedures"/>
            </procedureDefinition>
          </definition>
          <definition>
            <observationDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Results"/>
            </observationDefinition>
          </definition>
          <definition>
            <observationDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Vitals"/>
            </observationDefinition>
          </definition>
          <definition>
            <substanceAdministrationDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Medications"/>
            </substanceAdministrationDefinition>
          </definition>
          <definition>
            <supplyDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1" extension="RX"
              />
            </supplyDefinition>
          </definition>
          <xsl:apply-templates select="panel/item">
            <xsl:sort select="../panel_number" data-type="number"
              order="ascending"/>
          </xsl:apply-templates>
        </dataCriteriaSection>
      </component>
      <component>
        <populationCriteriaSection>
          <code code="57026-7" codeSystem="2.16.840.1.113883.6.1"/>
          <title>Population Criteria Section</title>
          <text>This section describes the Initial Patient Population,
            Numerator, Denominator, Denominator Exceptions, and Measure
            Populations</text>
          <entry>
            <patientPopulationCriteria>
              <id root="{$docOID}" extension="IPP"/>
              <xsl:apply-templates select="panel">
                <xsl:sort select="panel_number" data-type="number"
                  order="ascending"/>
              </xsl:apply-templates>
            </patientPopulationCriteria>
          </entry>
        </populationCriteriaSection>
      </component>
    </QualityMeasureDocument>
  </xsl:template>

  <xsl:template match="text()"/>
  <xsl:template match="text()" mode="bytype"/>

  <xsl:template name="get-localVariable-name">
    <xsl:param name="string" select="normalize-space(item_name)"/>
    <xsl:variable name="unique" select="generate-id(item_name)"></xsl:variable>
    <xsl:variable name="name">
      <xsl:if
        test="contains('1234567890',substring($string,1,1))">
        <xsl:text>_</xsl:text>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="contains($string,'&gt;=')">
          <xsl:value-of select="substring-before($string,'&gt;=')"/>
          <xsl:text>GE</xsl:text>
          <xsl:value-of select="substring-after($string,'&gt;=')"/>
        </xsl:when>
        <xsl:when test="contains($string,'&lt;=')">
          <xsl:value-of select="substring-before($string,'&lt;=')"/>
          <xsl:text>LE</xsl:text>
          <xsl:value-of select="substring-after($string,'&lt;=')"/>
        </xsl:when>
        <xsl:when test="contains($string,'&gt;')">
          <xsl:value-of select="substring-before($string,'&gt;')"/>
          <xsl:text>GT</xsl:text>
          <xsl:value-of select="substring-after($string,'&gt;')"/>
        </xsl:when>
        <xsl:when test="contains($string,'&lt;')">
          <xsl:value-of select="substring-before($string,'&lt;')"/>
          <xsl:text>LT</xsl:text>
          <xsl:value-of select="substring-after($string,'&lt;')"/>
        </xsl:when>
        <xsl:when test="contains($string,'=')">
          <xsl:value-of select="substring-before($string,'=')"/>
          <xsl:text>EQ</xsl:text>
          <xsl:value-of select="substring-after($string,'=')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$string"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of
      select="translate(translate(normalize-space($name),':()',''),' ','_')"
    />
    <xsl:text>_</xsl:text>
    <xsl:value-of select="$unique"/>
  </xsl:template>

  <xsl:template match="panel/item">
    <xsl:variable name="name">
      <xsl:call-template name="get-localVariable-name"/>
    </xsl:variable>
    <entry>
      <localVariableName>
        <xsl:value-of select="$name"/>
      </localVariableName>
      <!-- 
        depending on the type of criteria specified, insert the 
        appropriate criterion model 
      -->
      <xsl:variable name="key" select="substring-after(normalize-space(item_key),'\i2b2\')"/>
      <xsl:variable name="type"
        select="substring-before($key,&quot;\&quot;)"/>
      <xsl:variable name="subtype"
        select="substring-before(substring-after($key,&quot;\&quot;),&quot;\&quot;)"/>
      <xsl:apply-templates select="." mode="bytype">
        <xsl:with-param name="key" select="$key"/>
        <xsl:with-param name="type" select="$type"/>
        <xsl:with-param name="subtype" select="$subtype"/>
        <xsl:with-param name="name" select="$name"/>
      </xsl:apply-templates>
    </entry>
  </xsl:template>
  <xsl:template mode="bytype"
    match="item[starts-with(item_key,'\\i2b2_DEMO\i2b2\Demographics')]">
    <xsl:param name="type"/>
    <xsl:param name="subtype"/>
    <xsl:param name="name"/>
    <observationCriteria>
      <id root="{$docOID}" extension="{$name}"/>
      <code code="" codeSystem="2.16.840.1.113883.6.96" displayName="">
        <!-- 
        Age	424144002	Current Chronological Age	IVL_PQ
        Gender 	263495000	Gender	CE or ST
        Race	103579009	Race	CE or ST
        Ethnicity	364699009	Ethnic Group	CE or ST
        Marital Status	125680007	Marital Status	CE or ST
        Religious Preference	160538000	Religious Affiliation	CE or ST
        Postal Code	184102003	Patient Postal Code	CE or ST
        City	433178008	City of Residence	CE or ST
        State	N/A	State/Province of Residence	CE or ST
        -->
        <xsl:choose>
          <xsl:when test="$subtype='Age'">
            <xsl:attribute name="displayName">
              <xsl:text>Current Chronological Age</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="code">424144002</xsl:attribute>
          </xsl:when>
          <xsl:when test="$subtype ='Gender'">
            <xsl:attribute name="displayName">Gender</xsl:attribute>
            <xsl:attribute name="code">263495000</xsl:attribute>
          </xsl:when>
          <xsl:when test="$subtype ='Race'">
            <xsl:attribute name="displayName">Race</xsl:attribute>
            <xsl:attribute name="code">103579009</xsl:attribute>
          </xsl:when>
          <xsl:when test="$subtype ='Marital Status'">
            <xsl:attribute name="displayName">
              <xsl:text>Marital Status</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="code">125680007</xsl:attribute>
          </xsl:when>
          <xsl:when test="$subtype ='Religion'">
            <xsl:attribute name="displayName">
              <xsl:text>Religious Preference</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="code">160538000</xsl:attribute>
          </xsl:when>
          <!-- TBD: Zip Codes mapped to State, City or Postal Code -->
          <xsl:otherwise>
            <xsl:message terminate="yes"> Cannot Map <xsl:value-of
                select="$subtype"/> to HQMF Demographics </xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </code>
      <xsl:if test='../panel_date_from|../panel_date_to'>
        <effectiveTime>
          <xsl:apply-templates select="../panel_date_from|../panel_date_to"/>
        </effectiveTime>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$subtype='Age'">
          <xsl:choose>
            <xsl:when test="contains(item_name,&quot;&gt;=&quot;)">
              <xsl:variable name="age"
                select="substring-before(substring-after(item_name,'= '),' ')"/>
              <value xsi:type="IVL_PQ">
                <low value="{normalize-space($age)}" inclusive="true"
                  unit="a"/>
                <high value="{normalize-space($age)+1}"
                  inclusive="false" unit="a"/>
              </value>
            </xsl:when>
            <xsl:when test="contains(item_name,&quot;-&quot;)">
              <xsl:variable name="agelow"
                select="substring-before(item_name,'-')"/>
              <xsl:variable name="agehigh"
                select="substring-before(substring-after(item_name,'-'),' ')"/>
              <value xsi:type="IVL_PQ">
                <low value="{normalize-space($agelow)}" inclusive="true"
                  unit="a"/>
                <high value="{normalize-space($agehigh)+1}"
                  inclusive="false" unit="a"/>
              </value>
            </xsl:when>
            <xsl:otherwise>
              <xsl:message terminate="yes">Cannot Parse Age Range for
                  <xsl:value-of select="item_key"/> to HQMF Demographics
              </xsl:message>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$subtype ='Gender'">
          <value xsi:type="CD" value=""/>
        </xsl:when>
        <xsl:when test="$subtype ='Race'">
          <value xsi:type="CD" value=""/>
        </xsl:when>
        <xsl:when test="$subtype ='Marital Status'">
          <value xsi:type="CD" value=""/>
        </xsl:when>
        <xsl:when test="$subtype ='Religion'">
          <value xsi:type="CD" value=""/>
        </xsl:when>
        <!-- TBD: Zip Codes mapped to State, City or Postal Code -->
        <xsl:otherwise>
          <value xsi:type="ADDR">
            <city/>
            <state/>
            <zipCode/>
          </value>
        </xsl:otherwise>
      </xsl:choose>
      <definition>
        <observationReference moodCode="DEF">
          <id root="2.16.840.1.113883.3.1619.5148.1"
            extension="Demographics"/>
        </observationReference>
      </definition>
    </observationCriteria>
  </xsl:template>
  <xsl:template mode="bytype"
    match="item[starts-with(item_key,'\\i2b2_DIAG\i2b2\Diagnoses')]">
    <xsl:param name="type"/>
    <xsl:param name="subtype"/>
    <xsl:param name="name"/>
    <xsl:variable name="concept" select="$concepts//concept[key = normalize-space(current()/item_key)]"/>
    <xsl:variable name="code"
      select="substring-after($concept/basecode,':')"/>
    <observationCriteria>
      <id root="{$docOID}" extension="{$name}"/>
      <xsl:if test='../panel_date_from|../panel_date_to'>
        <effectiveTime>
          <xsl:apply-templates select="../panel_date_from|../panel_date_to"/>
        </effectiveTime>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$concept/basecode">
          <value xsi:type="CD" code="{$code}"
            displayName='substring-before("(",concat($concept/name,"("))'
            codeSystem="2.16.840.1.113883.6.103"
            codeSystemName='ICD-9-CM'/>
        </xsl:when>
        <xsl:otherwise>
          <value xsi:type="CD" code="{translate(normalize-space(item_key),' ','+')}"
            codeSystem="2.16.840.1.113883.3.1619.5148.19.1"/>
        </xsl:otherwise>
      </xsl:choose>
      <definition>
        <observationReference moodCode="DEF">
          <id root="2.16.840.1.113883.3.1619.5148.1"
            extension="Problems"/>
        </observationReference>
      </definition>
    </observationCriteria>
  </xsl:template>
  <xsl:template mode="bytype"
    match="item[starts-with(item_key,'\\i2b2_LABS\i2b2\Labtests')]">
    <xsl:param name="type"/>
    <xsl:param name="subtype"/>
    <xsl:param name="name"/>
    <xsl:variable name="concept" select="$concepts//concept[key = normalize-space(current()/item_key)]"/>
    <xsl:variable name="code"
      select="substring-after($concept/basecode,':')"/>
    <observationCriteria>
      <id root="{$docOID}" extension="{$name}"/>
      <xsl:choose>
        <xsl:when test="$concept/basecode">
          <code code="{$code}"
            displayName='substring-before("(",concat($concept/name,"("))'
            codeSystem="2.16.840.1.113883.6.1"
            codeSystemName='ICD-9-CM'/>
        </xsl:when>
        <xsl:otherwise>
          <code code="{translate(normalize-space(item_key),' ','+')}"
            codeSystem="2.16.840.1.113883.3.1619.5148.19.1"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test='../panel_date_from|../panel_date_to'>
        <effectiveTime>
          <xsl:apply-templates select="../panel_date_from|../panel_date_to"/>
        </effectiveTime>
      </xsl:if>
      <xsl:apply-templates select="constrain_by_value"/>
      <definition>
        <observationReference moodCode="DEF">
          <id root="2.16.840.1.113883.3.1619.5148.1" extension="Results"
          />
        </observationReference>
      </definition>
    </observationCriteria>
  </xsl:template>
  
  <xsl:template match="panel_date_from|panel_date_to">
    <xsl:variable name="name">
      <xsl:choose>
        <xsl:when test="self::panel_date_from">low</xsl:when>
        <xsl:otherwise>high</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name='{$name}'>
      <xsl:attribute name='value'>
        <xsl:value-of 
          select='concat(substring(.,1,4),substring(.,6,2),substring(.,9,2))'/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>
  <xsl:template match="panel_date_to">
    <high value='{
      concat(substring(.,1,4),
      substring(.,6,2),
      substring(.,9,2))}'/>
  </xsl:template>
  <xsl:template
    match="constrain_by_value[value_type = &quot;NUMBER&quot;]">
    <xsl:variable name="unit" select="value_unit_of_measure"/>
    <value xsi:type="IVL_PQ">
      <xsl:choose>
        <xsl:when test="value_operator = &quot;EQ&quot;">
          <xsl:attribute name="xsi:type">PQ</xsl:attribute>
          <xsl:attribute name="unit">
            <xsl:value-of select="$unit"/>
          </xsl:attribute>
          <xsl:attribute name="value">
            <xsl:value-of select="value_constraint"/>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="value_operator = &quot;GT&quot;">
          <low value="{value_constraint}" unit="{$unit}"
            inclusive="false"/>
        </xsl:when>
        <xsl:when test="value_operator = &quot;GE&quot;">
          <low value="{value_constraint}" unit="{$unit}"
            inclusive="true"/>
        </xsl:when>
        <xsl:when test="value_operator = &quot;LT&quot;">
          <high value="{value_constraint}" unit="{$unit}"
            inclusive="false"/>
        </xsl:when>
        <xsl:when test="value_operator = &quot;LE&quot;">
          <high value="{value_constraint}" unit="{$unit}"
            inclusive="true"/>
        </xsl:when>
        <xsl:when test="value_operator = &quot;BETWEEN&quot;">
          <low
            value="{substring-before(value_constraint,&quot; and &quot;)}"
            unit="{$unit}"/>
          <high
            value="{substring-after(value_constraint,&quot; and &quot;)}"
            unit="{$unit}"/>
        </xsl:when>
      </xsl:choose>
    </value>
  </xsl:template>
  <xsl:template
    match="constrain_by_value[value_type != &quot;NUMBER&quot;]">
    <xsl:message terminate="yes"> Cannot Parse Value for <xsl:value-of
        select="value_type"/> types </xsl:message>
  </xsl:template>
  <xsl:template mode="bytype"
    match="item[starts-with(item_key,'\\i2b2_MEDS\i2b2\Medications')]"> </xsl:template>
  <xsl:template mode="bytype"
    match="item[starts-with(item_key,'\\i2b2_PROC\i2b2\Procedures')]"> </xsl:template>
  <xsl:template mode="bytype"
    match="item[starts-with(item_key,'\\i2b2_VISIT\i2b2\Visit Details')]"> </xsl:template>
  <xsl:template mode="bytype" match="item">
    <xsl:message terminate="yes"> Cannot Map <xsl:value-of
        select="item_key"/> to HQMF Criteria </xsl:message>
  </xsl:template>

  <xsl:template match="item" mode="criteria">
    <xsl:variable name="name">
      <xsl:call-template name="get-localVariable-name"/>
    </xsl:variable>
    <xsl:variable name="elem-name">
      <!-- determine the appropriate reference types -->
      <xsl:choose>
        <xsl:when
          test="starts-with(item_key,'\\i2b2_DEMO\i2b2\Demographics')">
          <xsl:text>observationReference</xsl:text>
        </xsl:when>
        <xsl:when
          test="starts-with(item_key,'\\i2b2_DIAG\i2b2\Diagnoses')">
          <xsl:text>observationReference</xsl:text>
        </xsl:when>
        <xsl:when
          test="starts-with(item_key,'\\i2b2_LABS\i2b2\Labtests')">
          <xsl:text>observationReference</xsl:text>
        </xsl:when>
        <xsl:when
          test="starts-with(item_key,'\\i2b2_MEDS\i2b2\Medications')">
          <xsl:text>substanceAdministrationReference</xsl:text>
        </xsl:when>
        <xsl:when
          test="starts-with(item_key,'\\i2b2_DEMO\i2b2\Procedures')">
          <xsl:text>procedureReference</xsl:text>
        </xsl:when>
        <xsl:when
          test="starts-with(item_key,'\\i2b2_VISIT\i2b2\Visit Details')">
          <xsl:text>encounterReference</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes"> Cannot Map <xsl:value-of
              select="item_key"/> to HQMF Criteria </xsl:message>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <precondition>
      <xsl:element name="{$elem-name}">
        <id root="{$docOID}" extension="{$name}">
          <xsl:attribute name="extension">
            <xsl:call-template name="get-localVariable-name"/>
          </xsl:attribute>
        </id>
      </xsl:element>
    </precondition>
  </xsl:template>

  <xsl:template match="panel">
    <xsl:choose>
      <xsl:when test="invert = '1'">
        <precondition>
          <allFalse>
            <xsl:apply-templates select="item" mode="criteria"/>
          </allFalse>
        </precondition>
      </xsl:when>
      <xsl:when test="count(item) &gt; 1">
        <precondition>
          <atLeastOneTrue>
            <xsl:apply-templates select="item" mode="criteria"/>
          </atLeastOneTrue>
        </precondition>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="item" mode="criteria"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
