<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xalan="http://xml.apache.org/xalan"
  xmlns:v3="urn:hl7-org:v3" xmlns="urn:hl7-org:v3">
  <xsl:output method="xml" standalone="yes" omit-xml-declaration="no" indent="yes" xalan:indent-amount="2"/>
  <!-- 
    Process an HQMF document and extract the essentials for
    translation to executable code 
    
    Changelog:
        Keith W. Boone - 5/2012 - initial version
        Jeff Klann - 6/2012 - fixes to mesh with my updated schema
          Note that this is not thoroughly tested - it has been tested on the i2b2 HQMF version of NQF59
           and on my larger composite query. 
           There are places this translator probably still does not produce valid ihqmf. Needs work.
        Jeff Klann - 8/8/2012 - bugfix, somehow wasn't carrying dataCriteriaCombiner operations over.
          The revised translator will supersede this bugfix.
  -->
  <xsl:template match="/v3:QualityMeasureDocument">
    <ihqmf>
      <!-- Pull Title and Description from appropriate parts of the document -->
      <title>
        <xsl:value-of select="v3:title"/>
      </title>
      <description>
        <xsl:value-of
          select="v3:component/v3:measureDescriptionSection/v3:text"/>
      </description>

      <!-- Translate the measurePeriod -->
      <!-- TODO-JGK: This seems like a nice place to instantiate widths into high/low -->
      <measurePeriod>
        <xsl:copy-of select="v3:controlVariable/v3:measurePeriod/v3:id"/>
        <xsl:copy-of select="v3:controlVariable/v3:measurePeriod/v3:value"/>     
      </measurePeriod>

      <!-- Insert criteria -->
      <xsl:apply-templates
        select="v3:component/v3:dataCriteriaSection/v3:entry/v3:*[v3:definition]"/>

      <!-- Then pull population and stratifier criteria together -->
      <xsl:apply-templates
        select="//v3:patientPopulationCriteria|//v3:numeratorCriteria|
        //v3:denominatorCriteria|//v3:denominatorExceptionCriteria"
      />
      <!-- 
        TBD: This should be exactly like population criteria, 
        but include only stratifiers 
      -->
      <xsl:apply-templates
        select="//v3:stratifierCriteria"
      />
    </ihqmf>
  </xsl:template>

  <!-- Turn off default text matching rule -->
  <xsl:template match="text()"/>

  <!-- Perform the basic filling in for each data criteria
    Caller must pass the source of the primary code in the primaryCode
    parameter.
    -->
  <xsl:template name="dataCriteria">
    <xsl:param name="primaryCode"/>
    <!-- id and localVariableName are copies -->
    <xsl:copy-of select="v3:id"/>
    <xsl:copy-of select="../v3:localVariableName"/>

    <!-- 
      If there was a value set in primaryCode, copy it
      TBD: This should be in same sequence with codedValue 
      and freeTextValue
    -->
    <xsl:if test="$primaryCode/@valueSet">
      <code valueSet="{$primaryCode/@valueSet}"/>
    </xsl:if>

    <!-- effectiveTime is a copy -->
    <xsl:copy-of select="v3:effectiveTime"/>

    <!-- If there was a code set in primaryCode, copy it -->
    <xsl:if test="$primaryCode/@code">
      <code code="{$primaryCode/@code}"
        codeSystem="{$primaryCode/@codeSystem}"/>
    </xsl:if>

    <!-- If there was a free text value, get it -->
    <xsl:if test="$primaryCode/v3:originalText/text()">
      <freeTextValue>
        <xsl:value-of select="$primaryCode/v3:orginalText/text()"/>
      </freeTextValue>
    </xsl:if>
    <xsl:apply-templates select="v3:excerpt"/>
    <xsl:apply-templates select="v3:temporallyRelatedInformation"/>
  </xsl:template>

  <!-- Handle excerpts as filters -->
  <xsl:template match="v3:excerpt">
    <filterCriteria>
      <xsl:if test="v3:subsetCode">
        <filterCode>
          <xsl:value-of select="v3:subsetCode/@code"/>
        </filterCode>
      </xsl:if>
      <!-- if there was a repeatNumber, include it -->
      <xsl:copy-of select="v3:*/v3:repeatNumber"/>
      
      <!-- TBD: Need to discuss criteria inside excerpt in 
          intermediate schema
      -->
      <!-- This select is why the criteria template predicates
        use ancestor-or-self::*/v3:definition, because the definition
        isn't needed in excerpted child criteria (because the parent 
        provides it). TODO: Introduced bug to fix another - got rid of ancestor or self
        -->
      <xsl:apply-templates select="*"/>
    </filterCriteria>
  </xsl:template>

  <!-- Map temporallyRelatedInformation to timeRelationship -->
  <xsl:template match="v3:temporallyRelatedInformation">
    <timeRelationship>
      <timeRelationshipCode>
        <xsl:value-of select="@typeCode"/>
      </timeRelationshipCode>
      <timeQuantity value="{v3:pauseQuantity/@value}"
        unit="{v3:pauseQuantity/@unit}"/>
      <measurePeriodTimeReference>
        <xsl:copy-of select="v3:*/v3:id"/>
        <!-- If there is no event reference, use measurePeriod ID 
          TBD: Discuss whether this works for implementers, and ensure
          that <measurePeriod> and other events have similar representation
          of time components with respect to time to facilitate 
          implementation.
        -->
        <xsl:if test="not(v3:*/v3:id)">
          <xsl:copy-of select="//v3:measurePeriod/v3:id"/>
        </xsl:if>
      </measurePeriodTimeReference>
    </timeRelationship>
  </xsl:template>

  <!-- Demographics -->
  <xsl:template
    match="v3:observationCriteria[
      self::*/v3:definition/v3:*/v3:id/@extension = 'Demographics']">

    <DemographicsCriteria>
      <xsl:call-template name="dataCriteria">
        <xsl:with-param name="primaryCode" select="v3:code"/>
      </xsl:call-template>

      <xsl:if test="v3:value">
        <xsl:copy-of select="v3:value"/>
      </xsl:if>
    </DemographicsCriteria>
  </xsl:template>

  <!-- Problems -->
  <xsl:template
    match="v3:observationCriteria[
      self::*/v3:definition/v3:*/v3:id/@extension = 'Problems']">
    <ProblemCriteria>
      <xsl:call-template name="dataCriteria">
        <xsl:with-param name="primaryCode" select="v3:value"/>
      </xsl:call-template>
    </ProblemCriteria>
  </xsl:template>

  <!-- Allergies -->
  <xsl:template
    match="v3:observationCriteria[ 
      self::*/v3:definition/v3:*/v3:id/@extension = 'Allergies']">
    <AllergyCriteria>
      <xsl:call-template name="dataCriteria">
        <xsl:with-param name="primaryCode" select="v3:value"/>
      </xsl:call-template>
    </AllergyCriteria>
  </xsl:template>

  <!-- Encounters -->
  <xsl:template
    match="v3:encounterCriteria[
    self::*/v3:definition/v3:*/v3:id/@extension = 'Encounters']">
    <EncounterCriteria>
      <xsl:call-template name="dataCriteria">
        <xsl:with-param name="primaryCode" select="v3:code"/>
      </xsl:call-template>
      <xsl:if test="v3:value">
        <xsl:copy-of select="v3:value"/>
      </xsl:if>
    </EncounterCriteria>
  </xsl:template>

  <!-- Procedures -->
  <xsl:template
    match="v3:procedureCriteria[
    self::*/v3:definition/v3:*/v3:id/@extension = 'Procedures']">
    <ProcedureCriteria>
      <xsl:call-template name="dataCriteria">
        <xsl:with-param name="primaryCode" select="v3:code"/>
      </xsl:call-template>
      <!-- TBD: Not sure what value to put here -->
      <xsl:if test="false()">
        <procedureStatus code="{@moodCode}"/>
      </xsl:if>
      <xsl:if test="v3:targetSiteCode/@code">
        <procedureBodySite code="{v3:targetSiteCode/@code}"/>
      </xsl:if>
    </ProcedureCriteria>
  </xsl:template>

  <!-- Medications -->
  <xsl:template
    match="v3:substanceAdministrationCriteria[
    self::*/v3:definition/v3:*/v3:id/@extension = 
    'Medications']">
    <MedicationCriteria>
      <xsl:if
        test="not(v3:participant/v3:roleParticipant[@classCode='THER']/v3:code)">
        <!-- TBD: Does it make sense to have a medication criteria without
          a code? -->
        <xsl:message terminate="no"> No Medication code found for
          medication criteria //substanceAdministrationCriteria[
            <xsl:value-of
            select="1+ count(preceding::v3:substanceAdministrationCriteria)"
          /> ] </xsl:message>
      </xsl:if>
      <xsl:call-template name="dataCriteria">
        <xsl:with-param name="primaryCode"
          select="v3:participant/v3:roleParticipant[@classCode='THER']/v3:code"
        />
      </xsl:call-template>
      <medicationState>
        <xsl:value-of select="@moodCode"/>
        <!-- deal with default if processed w/o schema -->
        <xsl:if test="string(@moodCode)=''">EVN</xsl:if>
      </medicationState>
      <xsl:if test="v3:routeCode/@code">
        <routeCode>
          <xsl:value-of select="v3:routeCode/@code"/>
        </routeCode>
      </xsl:if>

      <!-- TBD: These two would be easier if the names were simply
        rateQuantity and doseQuantity
        -->
      <xsl:if test="v3:rateQuantity">
        <medicationRateQuantity>
          <xsl:copy-of select="v3:rateQuantity/@*"/>
          <xsl:copy-of select="v3:rateQuantity/*"/>
        </medicationRateQuantity>
      </xsl:if>
      <xsl:if test="v3:doseQuantity">
        <medicationDoseQuantity>
          <xsl:copy-of select="v3:doseQuantity/@*"/>
          <xsl:copy-of select="v3:doseQuantity/*"/>
        </medicationDoseQuantity>
      </xsl:if>
    </MedicationCriteria>
  </xsl:template>
  
  <!-- Medications (Supply) -->
  <!-- TBD: Consider merging this template with substanceAdministration -->
  <xsl:template
    match="v3:supplyCriteria[
    self::*/v3:definition/v3:*/v3:id/@extension = 
    'Medications']">
    <MedicationCriteria>
      <xsl:if
        test="not(v3:participant/v3:roleParticipant[@classCode='THER']/v3:code)">
        <!-- TBD: Does it make sense to have a medication criteria without
          a code? -->
        <xsl:message terminate="no"> No Medication code found for
          medication criteria //supplyCriteria[
          <xsl:value-of
            select="1+ count(preceding::v3:supplyCriteria)"
          /> ] </xsl:message>
      </xsl:if>
      <xsl:call-template name="dataCriteria">
        <xsl:with-param name="primaryCode"
          select="v3:participant/v3:roleParticipant[@classCode='THER']/v3:code"
        />
      </xsl:call-template>
      <medicationState>
        <xsl:value-of select="@moodCode"/>
      </medicationState>
      <!-- We will not know dose or rate if supply -->
    </MedicationCriteria>
  </xsl:template>
  
  <!-- Immunzations -->
  <!-- TBD: Do we need to deal with supply for immunization? -->
  <xsl:template
    match="v3:substanceAdministrationCriteria[
    self::*/v3:definition/v3:*/v3:id/@extension = 'Immunizations']">
    <ImmunizationCriteria>
      <xsl:call-template name="dataCriteria">
        <xsl:with-param name="primaryCode" select="v3:value"/>
      </xsl:call-template>
      <!-- TBD: Not sure what to put here -->
      <xsl:if test="false()">
        <reaction>st</reaction>
      </xsl:if>
      <xsl:if test="false()">
        <category>st</category>
      </xsl:if>
    </ImmunizationCriteria>
  </xsl:template>

  <xsl:template
    match="v3:observationCriteria[
    self::*/v3:definition/v3:*/v3:id/@extension = 'Results']">
    <LabResultsCriteria>
      <xsl:call-template name="dataCriteria">
        <xsl:with-param name="primaryCode" select="v3:code"/>
      </xsl:call-template>

     <xsl:copy-of select="v3:value"/>
 
      <!-- TBD: Not sure what to put here -->
      <xsl:if test="false()">
        <resultStatus>st</resultStatus>
      </xsl:if>
    </LabResultsCriteria>
  </xsl:template>

  <xsl:template
    match="v3:observationCriteria[
    self::*/v3:definition/v3:*/v3:id/@extension = 'Vitals']">
    <VitalSignCriteria>
      <xsl:call-template name="dataCriteria">
        <xsl:with-param name="primaryCode" select="v3:code"/>
      </xsl:call-template>

      <xsl:if test="false()">
        <vitalSignType>st</vitalSignType>
      </xsl:if>
      <xsl:if test="false()">
        <vitalSignValue>st</vitalSignValue>
      </xsl:if>
    </VitalSignCriteria>
  </xsl:template>
  
  <!-- TBD: Still need to deal with this -->
  <xsl:template
    match="v3:patientPopulationCriteria|v3:numeratorCriteria|v3:denominatorCriteria">
    <populationCriteria>
      <xsl:copy-of select="v3:id"/>
      <xsl:call-template name="dataCriteriaCombiner">
        <xsl:with-param name="operation">AllTrue</xsl:with-param>
      </xsl:call-template>
    </populationCriteria>
  </xsl:template>
  
  <xsl:template match="v3:denominatorExceptionCriteria"> 
    <populationCriteria>
      <xsl:copy-of select="v3:id"/>
      <xsl:call-template name="dataCriteriaCombiner">
        <xsl:with-param name="operation">AtLeastOneTrue</xsl:with-param>
      </xsl:call-template>
    </populationCriteria>
  </xsl:template>
  <xsl:template match="v3:stratifierCriteria">
    <stratifierCriteria>
      <xsl:copy-of select="v3:id"/>
      <xsl:call-template name="dataCriteriaCombiner">
        <xsl:with-param name="operation">OnlyOneTrue</xsl:with-param>
      </xsl:call-template>
    </stratifierCriteria>
  </xsl:template>

  <xsl:template match="v3:observationReference|v3:actReference|
    v3:substanceAdministrationReference|v3:supplyReference|
    v3:procedureReference|v3:encounterReference">
    <!-- TBD: Move @root/@extension up to dataCriteriaReference 
      (Change v3:id below to v3:id/@*)
    -->
    <dataCriteriaReference>
      <xsl:copy-of select="v3:id/@*"/>
    </dataCriteriaReference>
  </xsl:template>
  
  <xsl:template
    name="dataCriteriaCombiner"
    match="v3:allTrue|v3:allFalse|
       v3:atLeastOneTrue|v3:atLeastOneFalse|
       v3:onlyOneTrue|v3:onlyOneFalse">
    <!--<xsl:param name="operation"/>
    
    <xsl:param name="operation" select="concat(translate(substring(local-name(.),
      1,1),'abcdefghijklmnopqrstuvwxyz',
      'abcdefghijklmnopqrstuvwxyz'),substring(local-name(.),2,string-length(local-name(.))))"/> -->
   
    <xsl:param name="operation" select="concat(translate(substring(local-name(.),
      1,1),'abcdefghijklmnopqrstuvwxyz',
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),substring(local-name(.),2,string-length(local-name(.))))"/>

    <dataCriteriaCombiner>
      <!-- TBD: Change initial case of dataCriteriaOperationType to
        match schema
      -->
      <criteriaOperation>
        <xsl:value-of select="$operation"/>
      </criteriaOperation>
      <xsl:apply-templates 
        select="v3:precondition[v3:observationReference|v3:actReference|
        v3:substanceAdministrationReference|v3:supplyReference|
        v3:procedureReference|v3:encounterReference]/*"/>
      
      <xsl:apply-templates 
        select="v3:precondition[v3:allTrue|v3:allFalse|
        v3:atLeastOneTrue|v3:atLeastOneFalse|
        v3:onlyOneTrue|v3:onlyOneFalse]/*"/>
    </dataCriteriaCombiner>
  </xsl:template>
</xsl:stylesheet>
