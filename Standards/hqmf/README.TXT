Files in this package include the following: 

Schemas - Contains the Modified HL7 Schemas supporting the new Model
  COCT_MT090107UV.xsd
  COCT_MT150007UV.xsd
  EMeasureNew.xsd          - The new HQMF Schema Base file
  POQM_MT000001UVNew.xsd   - The main Document model
  POQM_MT000002UVNew.xsd   - Entry Models

Coreschemas - Contains the core HL7 Schemas support all HL7 Models
  datatypes-r1.1-base.xsd  - Base data types
  datatypes-r1.1.xsd       - More complex data types
  datatypes-rX-cs.xsd      - A fix for the CS data type in R1
  infrastructureRoot.xsd   - Describes infrastructure root attributes
  NarrativeBlock.xsd       - Schema for the narrative portion
  voc.xsd                  - Vocabulary


Modeling - Contains the VSD Model files
  POQM_RM000001UV.vsd      - HQMF Model in Visio
  POQM_RM000001UV.xml      - HQMF Model Auxilliary Data

Samples - Contains the current Sample files supporting the new schema
  NQF59New.xml             - Sample Measure in new format

The sample file found in the Samples folder validates against the new schema.  The new schemas are manually edited based on changes made to the new modeling.
