<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:set="http://exslt.org/sets"
  xmlns:exslt="http://exslt.org/common" xmlns:emf="urn:hl7-org:v3"
  exclude-result-prefixes="set exslt xsi emf">
  <xsl:output method="xml"/>
  <!-- Find the necessary sections -->
  <xsl:variable name="LOINC" select="'2.16.840.1.113883.6.1'"/>
  <xsl:variable name="MeasureDescriptionSection"
    select="//emf:section[emf:code/@code='34089-3' and 
        emf:code/@codeSystem=$LOINC]"/>
  <xsl:variable name="DataDeclarationSection"
    select="//emf:section[emf:code/@code='57025-9' and 
        emf:code/@codeSystem=$LOINC]"/>
  <xsl:variable name="PopulationCriteriaSection"
    select="//emf:section[emf:code/@code='57026-7' and 
        emf:code/@codeSystem=$LOINC]"/>
  <xsl:variable name="MeasureObservationSection"
    select="//emf:section[emf:code/@code='57027-5' and 
        emf:code/@codeSystem=$LOINC]"/>

  <xsl:variable name="IPPEntries"
    select="$PopulationCriteriaSection/emf:entry/
        emf:observation[emf:value/@code='IPP' and emf:value/@codeSystem='2.16.840.1.113883.5.1063']/
        emf:sourceOf[@typeCode='PRCN']"/>
  <xsl:variable name="NumeratorEntries"
    select="$PopulationCriteriaSection/emf:entry/
        emf:observation[emf:value/@code='NUMER' and emf:value/@codeSystem='2.16.840.1.113883.5.1063']/
        emf:sourceOf[@typeCode='PRCN']"/>
  <xsl:variable name="DenominatorEntries"
    select="$PopulationCriteriaSection/emf:entry/
        emf:observation[emf:value/@code='DENOM' and emf:value/@codeSystem='2.16.840.1.113883.5.1063']/
        emf:sourceOf[@typeCode='PRCN']"/>
  <xsl:variable name="ExceptionEntries"
    select="$PopulationCriteriaSection/emf:entry/
        emf:observation[emf:value/@code='DENEXCEP' and emf:value/@codeSystem='2.16.840.1.113883.5.1063']/
        emf:sourceOf[@typeCode='PRCN']"/>

  <xsl:variable name="Classifiers"
    select="$PopulationCriteriaSection/emf:entry/
    emf:observation[emf:value/@code='CLASSIFIER' and emf:value/@codeSystem='2.16.840.1.113883.5.1063']"/>
  
  <xsl:template match="/">
    <!-- xsl:call-template name="generateTermList"/ -->
    <xsl:call-template name="generateParameterList"/>
    <xsl:variable name="vars">
      <xsl:call-template name="generateVariableList"/>
    </xsl:variable>
    <xsl:text>CREATE VIEW POPULATION AS </xsl:text>
    <xsl:call-template name="processEntries">
      <xsl:with-param name="entries" select="$IPPEntries"/>
      <xsl:with-param name="vars" select="exslt:node-set($vars)"/>
    </xsl:call-template>
    <xsl:text>;&#xA;</xsl:text>
    <xsl:text>CREATE VIEW NUMERATOR AS </xsl:text>
    <xsl:call-template name="processEntries">
      <xsl:with-param name="entries" select="$NumeratorEntries"/>
      <xsl:with-param name="vars" select="exslt:node-set($vars)"/>
    </xsl:call-template>
    <xsl:text>;&#xA;</xsl:text>
    <xsl:text>CREATE VIEW DENOMINATOR AS </xsl:text>
    <xsl:call-template name="processEntries">
      <xsl:with-param name="entries" select="$DenominatorEntries"/>
      <xsl:with-param name="vars" select="exslt:node-set($vars)"/>
    </xsl:call-template>
    <xsl:text>;&#xA;</xsl:text>
    <xsl:text>CREATE VIEW EXCLUSIONS AS </xsl:text>
    <xsl:call-template name="processEntries">
      <xsl:with-param name="entries" select="$ExceptionEntries"/>
      <xsl:with-param name="vars" select="exslt:node-set($vars)"/>
    </xsl:call-template>
    <xsl:text>;&#xA;</xsl:text>
    
    <xsl:if test='$Classifiers'>
      <xsl:for-each select="$Classifiers">
        <xsl:text>CREATE VIEW </xsl:text> 
        <xsl:value-of select="../emf:localVariableName"/>
        <xsl:text> AS (&#xA;</xsl:text>
        <xsl:for-each select="emf:sourceOf[@typeCode='PRCN']">
          <xsl:variable name="declaration"
            select="$DataDeclarationSection/emf:entry/*[current()/emf:*/emf:id/@root = emf:id/@root and 
            current()/emf:*/emf:id/@extension = emf:id/@extension]"/>
          <xsl:apply-templates select=".">
            <xsl:with-param name="depth" select="0"/>
            <xsl:with-param name="vars" select="exslt:node-set($vars)"/>
            <xsl:with-param name="class" select="$declaration/../emf:localVariableName"/>
          </xsl:apply-templates>
          <xsl:if test="position() != last()"> UNION </xsl:if>
        </xsl:for-each>
        <xsl:text>);&#xA;</xsl:text> 
      </xsl:for-each>
    </xsl:if>
    <xsl:text>
SELECT 
</xsl:text>
<xsl:for-each select="$Classifiers">
  <xsl:value-of select="../emf:localVariableName"/>
  <xsl:text>.CLASS AS </xsl:text>
  <xsl:value-of select="../emf:localVariableName"/>
  <xsl:text>, </xsl:text>
</xsl:for-each>
    <xsl:text>
    COUNT(P.PATIENTID) AS POPULATIONIDS ,
    COUNT(D.PATIENTID) AS DENOMINATORIDS,
    COUNT(N.PATIENTID) AS NUMERATORIDS,
    COUNT(E.PATIENTID) AS EXCEPTIONIDS
FROM POPULATION P&#xA;</xsl:text>
<xsl:for-each select="$Classifiers">
  JOIN <xsl:value-of select="../emf:localVariableName"/>
  ON P.PATIENTID = <xsl:value-of select="../emf:localVariableName"/>.PATIENTID
</xsl:for-each><xsl:text>
LEFT OUTER JOIN DENOMINATOR D
ON P.PATIENTID = D.PATIENTID /* column 2 contains null where X in P and not in D */
LEFT OUTER JOIN NUMERATOR N
ON D.PATIENTID = N.PATIENTID /* column 3 contains null where X in N and not in D */
LEFT OUTER JOIN EXCEPTION E
ON D.PATIENTID = E.PATIENTID AND E.PATIENTID NOT IN (SELECT PATIENTID FROM NUMERATOR) /* column 4 contains a PATIENTID if In the denominator but not found in numerator, NULL otherwise */
GROUP BY </xsl:text>
    <xsl:for-each select="$Classifiers">
      <xsl:value-of select="../emf:localVariableName"/>
      <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
    </xsl:for-each><xsl:text>
ORDER BY </xsl:text>
<xsl:for-each select="$Classifiers">
  <xsl:value-of select="../emf:localVariableName"/>
  <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
</xsl:for-each>
  </xsl:template>

  <xsl:template name="generateTermList">
    <xsl:text>INSERT INTO VALUESETS (ID, CODESYSTEMNAME, CODE, DISPLAYNAME) VALUES&#xA;</xsl:text>
    <xsl:variable name="valueSets" select="set:distinct(//*/@valueSet)"/>
    <xsl:variable name="codeSets" select="document('svs.xml')"/>
    <xsl:for-each select="$codeSets//ValueSet[@id=$valueSets]">
      <xsl:variable name="valueSet" select="@id"/>
      <xsl:for-each select="ConceptList/Concept">
        <xsl:text>  ('</xsl:text>
        <xsl:value-of select="$valueSet"/>
        <xsl:text>','</xsl:text>
        <xsl:value-of select="@code"/>
        <xsl:text>','</xsl:text>
        <xsl:value-of select="@codeSystemName"/>
        <xsl:text>','</xsl:text>
        <xsl:value-of select="@displayName"/>
        <xsl:text>')</xsl:text>
        <xsl:choose>
          <xsl:when test="position() = last()">;&#xA;</xsl:when>
          <xsl:otherwise>, &#xA;</xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="generateParameterList">
    <xsl:text>&#xA;# Generate named variables&#xA;</xsl:text>
    <xsl:for-each
      select="$DataDeclarationSection//emf:entry[emf:localVariableName != &quot;&quot;]/
            emf:observation[@moodCode=&quot;EVN&quot; and not(@isCriterionInd=&quot;true&quot;)]">
      <xsl:variable name="name" select="../emf:localVariableName"/>
      <xsl:text>DECLARE @</xsl:text>
      <xsl:value-of select="$name"/>
      <xsl:choose>
        <xsl:when test="emf:value/@xsi:type='TS'"> TIMESTAMP;&#xA;</xsl:when>
        <xsl:when test="emf:value/@xsi:type='ST'"> TEXT;&#xA;</xsl:when>
        <xsl:when test="emf:value/@xsi:type='PQ'">
          <xsl:text> REAL;&#xA;</xsl:text>
          <xsl:text>DECLARE @</xsl:text>
          <xsl:value-of select="$name"/>
          <xsl:text>_unit TEXT;&#xA;</xsl:text>
        </xsl:when>
        <xsl:when test="emf:value/@xsi:type='CD'">
          <xsl:text> TEXT;&#xA;</xsl:text>
          <xsl:text>DECLARE @</xsl:text>
          <xsl:value-of select="$name"/>
          <xsl:text>_cs TEXT;&#xA;</xsl:text>
        </xsl:when>
        <xsl:otherwise>;&#xA;</xsl:otherwise>
      </xsl:choose>
      <xsl:text>SET @</xsl:text>
      <xsl:value-of select="$name"/>
      <xsl:text> = </xsl:text>
      <xsl:choose>
        <xsl:when test="emf:value/@xsi:type='TS'">
          <xsl:text> '</xsl:text>
          <xsl:value-of select="emf:value/@value"/>
          <xsl:text>';&#xA;</xsl:text>
        </xsl:when>
        <xsl:when test="emf:value/@xsi:type='ST'">
          <xsl:text> '</xsl:text>
          <xsl:value-of select="emf:value"/>
          <xsl:text>';&#xA;</xsl:text>
        </xsl:when>
        <xsl:when test="emf:value/@xsi:type='PQ'">
          <xsl:text> </xsl:text>
          <xsl:value-of select="emf:value/@value"/>
          <xsl:text>;&#xA;</xsl:text>
          <xsl:text>SET @</xsl:text>
          <xsl:value-of select="$name"/>
          <xsl:text>_unit = </xsl:text>
          <xsl:text> '</xsl:text>
          <xsl:value-of select="emf:value/@unit"/>
          <xsl:text>';&#xA;</xsl:text>
        </xsl:when>
        <xsl:when test="emf:value/@xsi:type='CD'">
          <xsl:text> '</xsl:text>
          <xsl:value-of select="emf:value/@code"/>
          <xsl:text>';&#xA;</xsl:text>
          <xsl:text>SET @</xsl:text>
          <xsl:value-of select="$name"/>
          <xsl:text>_cs = </xsl:text>
          <xsl:text> '</xsl:text>
          <xsl:value-of select="emf:value/@codeSystem"/>
          <xsl:text>';&#xA;</xsl:text>
        </xsl:when>
        <xsl:otherwise> = '';&#xA;</xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="generateVariableList">
    <variables>
      <xsl:for-each
        select="$DataDeclarationSection//emf:entry/emf:*[@isCriterionInd=&quot;true&quot;]">
        <variable name="{../emf:localVariableName}">
          <xsl:if test="not(../emf:localVariableName)">
            <xsl:attribute name="name">
              <xsl:value-of select="generate-id(.)"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:attribute name="table">
            <xsl:value-of select="emf:sourceOf[@typeCode='INST']/*/emf:id/@extension"/>
          </xsl:attribute>
          <xsl:if test="../emf:subsetCode/@code and not(contains(../emf:subsetCode/@code,'SUM'))">
            <xsl:attribute name="subset">
              <xsl:value-of select="../emf:subsetCode/@code"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:call-template name="criteria">
            <xsl:with-param name="act" select="."/>
          </xsl:call-template>
        </variable>
      </xsl:for-each>
    </variables>
  </xsl:template>

  <xsl:template name="criteria">
    <xsl:param name="act"/>
    <xsl:variable name="code"
      select="$act[self::emf:substanceAdministration or self::emf:supply]/
        emf:participant[@typeCode=&quot;PRD&quot; or @typeCode=&quot;CSM&quot;]/
        emf:roleParticipant[@classCode=&quot;THER&quot;]/emf:code|
        $act[self::emf:act or self::emf:procedure or self::emf:encounter]/emf:code|
        $act[self::emf:observation and emf:value/@xsi:type='CD']/emf:value|
        $act[self::emf:observation and emf:value/@xsi:type!='CD']/emf:code"/>
    <xsl:if test="$code">
      <xsl:text>&#xA;        </xsl:text>
    </xsl:if>
    
    <xsl:if test="$code/@code">
      <xsl:text>CODE = '</xsl:text>
      <xsl:value-of select="$code/@code"/>
      <xsl:text>' AND CODESYSTEM = '</xsl:text>
      <xsl:value-of select="$code/@codeSystem"/>
      <xsl:text>'</xsl:text>
    </xsl:if>
    <xsl:if test="not($code/@code) and $code/@valueSet">
      <xsl:text>CODE IN (SELECT CODE FROM VALUESETS WHERE ID = '</xsl:text>
      <xsl:value-of select="$code/@valueSet"/>
      <xsl:text>')</xsl:text>
    </xsl:if>
    <xsl:if test="$act/emf:effectiveTime">
      <xsl:if test="$code">
        <xsl:text> AND&#xA;        </xsl:text>
      </xsl:if>
      <xsl:if test="$act/emf:effectiveTime/emf:low">
        <xsl:text>EFFECTIVETIME &gt;</xsl:text>
        <xsl:if test="$act/emf:effectiveTime/emf:low/@inclusive">=</xsl:if>
        <xsl:text> </xsl:text>
        <xsl:if test="$act/emf:effectiveTime/emf:low/@value">
          <xsl:text>'</xsl:text>
          <xsl:value-of select="$act/emf:effectiveTime/emf:low/@value"/>
          <xsl:text>'</xsl:text>
        </xsl:if>
        <xsl:if test="$act/emf:effectiveTime/emf:low/emf:expression">
          <xsl:value-of select="$act/emf:effectiveTime/emf:low/emf:expression"/>
        </xsl:if>
        <xsl:if test="$act/emf:effectiveTime/emf:high"> AND </xsl:if>
      </xsl:if>
      <xsl:if test="$act/emf:effectiveTime/emf:high">
        <xsl:text>EFFECTIVETIME &lt;</xsl:text>
        <xsl:if test="$act/emf:effectiveTime/emf:high/@inclusive">=</xsl:if>
        <xsl:text> </xsl:text>
        <xsl:if test="$act/emf:effectiveTime/emf:high/@value">
          <xsl:text>'</xsl:text>
          <xsl:value-of select="$act/emf:effectiveTime/emf:high/@value"/>
          <xsl:text>'</xsl:text>
        </xsl:if>
        <xsl:if test="$act/emf:effectiveTime/emf:high/emf:expression">
          <xsl:value-of select="$act/emf:effectiveTime/emf:high/emf:expression"/>
        </xsl:if>
      </xsl:if>
    </xsl:if>
    <xsl:variable name="value" select="$act/emf:value"/>
    <xsl:choose>
      <xsl:when test="not($value)"/>
      <xsl:when test="$value/@xsi:type='CD'"/>
      <xsl:when test="$value/@xsi:type='IVL_PQ'">
        <xsl:if test="$act/emf:effectiveTime|$code">
          <xsl:text> AND </xsl:text>
        </xsl:if>
        <xsl:if test="$value/emf:low|$value/emf:high">
          <xsl:text>&#xA;        </xsl:text>
        </xsl:if>
        <xsl:if test="$value/emf:low">
          <xsl:text>VALUE &gt;</xsl:text>
          <xsl:if test="$value/emf:low/@inclusive">=</xsl:if>
          <xsl:text> </xsl:text>
          <xsl:value-of select="$value/emf:low/@value"/>
          <xsl:if test="$value/emf:high">
            <xsl:text> AND </xsl:text>
          </xsl:if>
        </xsl:if>
        <xsl:if test="$value/emf:high">
          <xsl:text>VALUE &lt;</xsl:text>
          <xsl:if test="$value/emf:high/@inclusive">=</xsl:if>
          <xsl:text> </xsl:text>
          <xsl:value-of select="$value/emf:high/@value"/>
        </xsl:if>
        <xsl:if test="$value/emf:high|$value/emf:low">
          <xsl:text> AND UNITS = '</xsl:text>
          <xsl:value-of select="$value/emf:high/@unit|$value/emf:low/@unit"/>
          <xsl:text>'&#xA;</xsl:text>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">
          <xsl:value-of select="$value/@xsi:type"/>
          <xsl:text>TYPE NOT SUPPORTED</xsl:text>
        </xsl:message>
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

  <xsl:template name="and">
    <xsl:param name="args"/>
    <xsl:param name="depth"/>
    <xsl:param name="vars"/>
    <xsl:variable name="first" select="$args[1]"/>
    <xsl:variable name="rest" select="$args[position() != 1]"/>
    <xsl:apply-templates select="$first">
      <xsl:with-param name="depth" select="$depth + 1"/>
      <xsl:with-param name="vars" select="$vars"/>
    </xsl:apply-templates>
    <xsl:if test="$rest">
      <xsl:text> INTERSECT </xsl:text>
      <xsl:call-template name="and">
        <xsl:with-param name="args" select="$rest"/>
        <xsl:with-param name="depth" select="$depth"/>
        <xsl:with-param name="vars" select="$vars"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  <xsl:template name="or">
    <xsl:param name="args"/>
    <xsl:param name="depth"/>
    <xsl:param name="vars"/>
    <xsl:variable name="first" select="$args[1]"/>
    <xsl:variable name="rest" select="$args[position() != 1]"/>
    <xsl:apply-templates select="$first">
      <xsl:with-param name="depth" select="$depth + 1"/>
      <xsl:with-param name="vars" select="$vars"/>
    </xsl:apply-templates>
    <xsl:if test="$rest">
      <xsl:text> UNION </xsl:text>
      <xsl:call-template name="or">
        <xsl:with-param name="args" select="$rest"/>
        <xsl:with-param name="depth" select="$depth"/>
        <xsl:with-param name="vars" select="$vars"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  <xsl:template name="xor">
    <xsl:param name="args"/>
    <xsl:param name="depth"/>
    <xsl:param name="vars"/>
    <xsl:message terminate="yes">THIS DOESN'T WORK!</xsl:message>
    <xsl:variable name="first" select="$args[1]"/>
    <xsl:variable name="rest" select="$args[position() != 1]"/>
    <xsl:apply-templates select="$first">
      <xsl:with-param name="depth" select="$depth + 1"/>
      <xsl:with-param name="vars" select="$vars"/>
    </xsl:apply-templates>
    <xsl:if test="$rest">
      <xsl:call-template name="xor">
        <xsl:with-param name="args" select="$rest"/>
        <xsl:with-param name="depth" select="$depth"/>
        <xsl:with-param name="vars" select="$vars"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="processEntries">
    <xsl:param name="entries"/>
    <xsl:param name="depth" select="1"/>
    <xsl:param name="vars"/>
    <xsl:if test="$entries[emf:conjunctionCode/@code='AND' or not(emf:conjunctionCode)]">
      <xsl:text>(</xsl:text>
      <xsl:call-template name="and">
        <xsl:with-param name="args"
          select="$entries[emf:conjunctionCode/@code='AND' or not(emf:conjunctionCode)]"/>
        <xsl:with-param name="depth" select="$depth"/>
        <xsl:with-param name="vars" select="$vars"/>
      </xsl:call-template>
      <xsl:text>)</xsl:text>
      <xsl:if test="$entries[emf:conjunctionCode/@code != 'AND']">
        <xsl:text> INTERSECT </xsl:text>
      </xsl:if>
    </xsl:if>
    <xsl:if test="$entries/emf:conjunctionCode/@code=&quot;OR&quot;">
      <xsl:text>(</xsl:text>
      <xsl:call-template name="or">
        <xsl:with-param name="args" select="$entries[emf:conjunctionCode/@code='OR']"/>
        <xsl:with-param name="depth" select="$depth"/>
        <xsl:with-param name="vars" select="$vars"/>
      </xsl:call-template>
      <xsl:text>)</xsl:text>
      <xsl:if test="$entries[emf:conjunctionCode/@code = 'XOR']">
        <xsl:text> INTERSECT </xsl:text>
      </xsl:if>
    </xsl:if>
    <xsl:if test="$entries/emf:conjunctionCode/@code=&quot;XOR&quot;">
      <xsl:message terminate="yes">THIS DOESN'T WORK!</xsl:message>
    </xsl:if>
  </xsl:template>

  <xsl:template match="emf:sourceOf[@typeCode='PRCN']">
    <xsl:param name="depth"/>
    <xsl:param name="vars"/>
    <xsl:param name="class"/>
    <!-- 
            Find the act that was declared in Data Criteria
        -->
    <xsl:variable name="act"
      select="emf:act|emf:observation|
            emf:encounter|emf:procedure|
            emf:substanceAdministration|emf:supply"/>
    <xsl:variable name="declaration"
      select="$DataDeclarationSection/emf:entry/*[$act/emf:id/@root = emf:id/@root and 
            $act/emf:id/@extension = emf:id/@extension]"/>
    <xsl:variable name="negated"
      select="concat($act/@actionNegationInd,$act/../@negationInd) = 'true'"/>
    <!-- 
            If there was a declaration in the data section, then this is
            not a grouper (which should be represented using organizer?). 
        -->
    <xsl:if test="$declaration">
      <!-- deal with negationInd on sourceOf and actionNegationInd on criteria -->
      <xsl:variable name="varName">
        <xsl:value-of select="$declaration/../emf:localVariableName"/>
        <!-- Generate a name if one isn't given -->
        <xsl:if test="not($declaration/../emf:localVariableName)">
          <xsl:value-of select="generate-id($declaration)"/>
        </xsl:if>
      </xsl:variable>
      <xsl:text>/* </xsl:text>
      <xsl:if test="$negated">!</xsl:if>
      <xsl:value-of select="$varName"/>
      <xsl:text>*/</xsl:text>
      <xsl:variable name="v" select="$vars//variable[@name=$varName]"/>
      <xsl:text>&#xA;  SELECT DISTINCT PATIENTID </xsl:text>
      <xsl:if test="$class">
        <xsl:text>, '</xsl:text>
        <xsl:value-of select="$class"/>
        <xsl:text>' CLASS </xsl:text>
      </xsl:if>
      <xsl:text>FROM </xsl:text>
      <xsl:value-of select="$v/@table"/>
      <xsl:text>&#xA;    WHERE </xsl:text>
      <xsl:if test="$negated">NOT</xsl:if>
      <xsl:text>(</xsl:text>
      <xsl:if test="$v/@subset">
        <xsl:text> ID IN (SELECT TOP 1 FROM </xsl:text> 
        <xsl:value-of select="$v/@table"/>
        <xsl:text> O WHERE </xsl:text>
        <xsl:value-of select="$v/@table"/>in
        <xsl:text>.PATIENTID = O.PATIENTID</xsl:text>
        <xsl:text>ORDER BY </xsl:text>
        <xsl:choose>
          <xsl:when test="$v/@subset='FIRST' or $v/@subset='RECENT'"> EFFECTIVETIME </xsl:when>
          <xsl:when test="$v/@subset='MIN' or $v/@subset='MAX'"> VALUE </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="$v/@subset='FIRST' or $v/@subset='MIN'"> ASC </xsl:when>
          <xsl:when test="$v/@subset='RECENT' or $v/@subset='MAX'"> DESC </xsl:when>
        </xsl:choose>
        <xsl:text>) AND &#xA;</xsl:text>
      </xsl:if>
      
      <xsl:value-of select="$v"/>
      <xsl:text>    )&#xA;</xsl:text>
    </xsl:if>
    <xsl:if test="$act/emf:sourceOf[@typeCode=&quot;PRCN&quot;]">
      <xsl:call-template name="processEntries">
        <xsl:with-param name="entries" select="$act/emf:sourceOf[@typeCode='PRCN']"/>
        <xsl:with-param name="vars" select="$vars"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>


</xsl:stylesheet>
