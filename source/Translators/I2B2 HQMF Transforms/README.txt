Transforms to support translation between I2B2 XML and HQMF. 

XSL/
I2B2ToI2B2Plus.xsl - Creates an augmented i2b2 message augmented with basecodes. A prerequisite for the HQMF translation. 
   Requires a live i2b2 ONT cell which will accept the security parameters suggested in the i2b2 query header.
I2B2PlusToHQMF.xsl - Converts an i2b2plus XML to an HQMF XML.
HQMFtoIntermediate.xsl - Converts an HQMF XML to the intermediate "ihqmf" representation. Note this is a different, simpler fork than the one maintained by Drajer LLC. It is much simpler and only really being used to simplify updates and implementation.
IntermediateToI2B2.xsl - Converts an ihqmf XML back to an i2b2 message. Requires a live i2b2 ONT cell which will accept the security parameters suggested in the xsl params to look up key names from basecodes.
   
Other files in XSL are utility files.