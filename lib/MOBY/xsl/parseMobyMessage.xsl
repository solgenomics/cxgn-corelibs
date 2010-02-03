<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:moby="http://www.biomoby.org/moby" version="1.0">
<xsl:output method="xml" encoding="iso-8859-1" indent="no" disable-output-escaping="no"/>
	
	<xsl:template match="/">
		<xsl:text>#XSL_LIPM_MOBYPARSER_MESSAGE#</xsl:text>
		<xsl:text>
</xsl:text>
		<xsl:apply-templates select="/moby:MOBY/moby:mobyContent/moby:serviceNotes"/>
		<xsl:apply-templates select="/moby:MOBY/moby:mobyContent/moby:mobyData"/>
	</xsl:template>

	<xsl:template match="moby:serviceNotes">
		<xsl:text>#XSL_LIPM_MOBYPARSER_SERVICENOTES#</xsl:text>
		<xsl:value-of select="normalize-space(.)"/>
		<xsl:text>#XSL_LIPM_MOBYPARSER_SERVICENOTES#</xsl:text>
		<xsl:text>
</xsl:text>
	</xsl:template>

	<xsl:template match="moby:mobyData">
		
		<xsl:text>#XSL_LIPM_MOBYPARSER_DATA_START#</xsl:text>
		<xsl:text>
</xsl:text>

	<!-- Retrieve QueryId -->
			
		<xsl:value-of select="normalize-space(./@moby:queryID)"/>
		<xsl:variable name="queryID1" select="normalize-space(./@moby:queryID)"/>
		<xsl:variable name="queryID2" select="normalize-space(./@queryID)"/>
		<xsl:text>#XSL_LIPM_MOBYPARSER_QUERYID#</xsl:text>
		<xsl:if test="$queryID1 != ''">
			<xsl:value-of select="$queryID1"/>
		</xsl:if>
		<xsl:if test="$queryID2 != ''">
			<xsl:value-of select="$queryID2"/>
		</xsl:if>
		<xsl:text>#XSL_LIPM_MOBYPARSER_QUERYID#</xsl:text>
		<xsl:text>
</xsl:text>
		
		

		<xsl:for-each select="child::*">
			<xsl:text>#XSL_LIPM_MOBYPARSER_ARTICLE_START#</xsl:text>
			<xsl:text>
</xsl:text>
			<xsl:variable name="articleName" select="normalize-space(./@moby:articleName)"/>
			<xsl:choose>
				<xsl:when test="$articleName = ''">
					<xsl:text>#XSL_LIPM_MOBYPARSER_ARTICLENAME#</xsl:text>
					<xsl:value-of select="normalize-space(./@articleName)"/>
					<xsl:text>#XSL_LIPM_MOBYPARSER_ARTICLENAME#</xsl:text>
					</xsl:when>
				<xsl:otherwise>
					<xsl:text>#XSL_LIPM_MOBYPARSER_ARTICLENAME#</xsl:text>
					<xsl:value-of select="$articleName"/>
					<xsl:text>#XSL_LIPM_MOBYPARSER_ARTICLENAME#</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
			
			<xsl:text>
</xsl:text>
			<xsl:variable name="articleType" select="normalize-space(name(.))"/>
			<xsl:text>#XSL_LIPM_MOBYPARSER_ARTICLETYPE#</xsl:text>
			<xsl:value-of select="$articleType"/>
			<xsl:text>#XSL_LIPM_MOBYPARSER_ARTICLETYPE#</xsl:text>
			
			<xsl:text>
</xsl:text>

			<xsl:choose>
				<xsl:when test="$articleType = 'moby:Collection'">
					<xsl:apply-templates select="."/>
				</xsl:when>
				<xsl:when test="$articleType = 'moby:Simple'">
					<xsl:apply-templates select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<!--
	
	TEMPLATE COLLECTION
	
	-->

	
	<xsl:template match="moby:Collection">
		<xsl:text>#XSL_LIPM_MOBYPARSER_COLLECTION_START#</xsl:text>
		

		<xsl:for-each select="child::*">

			<xsl:variable name="articleType" select="normalize-space(name(.))"/>
			<xsl:if test="$articleType = 'moby:Simple'">
				<xsl:apply-templates select="."/>
			</xsl:if>

		</xsl:for-each>
		<xsl:text>#XSL_LIPM_MOBYPARSER_COLLECTION_END#</xsl:text>
	</xsl:template>
	
	
	<!--
	
	TEMPLATE PARAMETER
	
	-->

	<xsl:template match="moby:Parameter">
	
		<xsl:variable name="paramname1" select="normalize-space(./@moby:articleName)"/>
		<xsl:variable name="paramname2" select="normalize-space(./@articleName)"/>

		<xsl:text>#XSL_LIPM_MOBYPARSER_SECONDARY_START#</xsl:text>
		<xsl:if test="$paramname1 != ''">
			<xsl:value-of select="$paramname1"/>
		</xsl:if>
		<xsl:if test="$paramname2 != ''">
			<xsl:value-of select="$paramname2"/>
		</xsl:if>
		<!--<xsl:value-of select="normalize-space(./@moby:articleName)"/>-->
		<xsl:text>#XSL_LIPM_MOBYPARSER_SECONDARY_SEP#</xsl:text>
		<xsl:value-of select="normalize-space(./child::*)"/>
		<xsl:text>#XSL_LIPM_MOBYPARSER_SECONDARY_END#</xsl:text>
	</xsl:template>

	<!--
	
	TEMPLATE SIMPLE
	
	-->
	
	<xsl:template match="moby:Simple">
		<xsl:text>#XSL_LIPM_MOBYPARSER_SIMPLE_START#</xsl:text>
		<xsl:text>
</xsl:text>			
		
		<xsl:for-each select="child::*">
			<xsl:call-template name="objectClass"/>
		</xsl:for-each>
		
		<xsl:text>
</xsl:text>

	</xsl:template>
		
	
	<!--
	
	TEMPLATE OBJECT
	
	-->

	
	<xsl:template name="objectClass">
		
		<!-- Retrieve Object Type -->

		<xsl:variable name="objectType" select="normalize-space(name(.))"/>
			<xsl:text>#XSL_LIPM_MOBYPARSER_OBJECTTYPE#</xsl:text>
			<xsl:value-of select="$objectType"/>
			<xsl:text>#XSL_LIPM_MOBYPARSER_OBJECTTYPE#</xsl:text>

		<xsl:text>
</xsl:text>

		
		<!-- Retrieve Object Namespace-->

		<xsl:variable name="objectNamespace1" select="normalize-space(./@moby:namespace)"/>
		<xsl:variable name="objectNamespace2" select="normalize-space(./@namespace)"/>
		<xsl:text>#XSL_LIPM_MOBYPARSER_OBJECTNAMESPACE#</xsl:text>
		<xsl:if test="$objectNamespace1 != ''">
			<xsl:value-of select="$objectNamespace1"/>
		</xsl:if>
		<xsl:if test="$objectNamespace2 != ''">
			<xsl:value-of select="$objectNamespace2"/>
		</xsl:if>
		<xsl:text>#XSL_LIPM_MOBYPARSER_OBJECTNAMESPACE#</xsl:text>
		<xsl:text>
</xsl:text>

		<!-- Retrieve Object Id -->

		<xsl:variable name="objectId1" select="normalize-space(./@moby:id)"/>
		<xsl:variable name="objectId2" select="normalize-space(./@id)"/>
		<xsl:text>#XSL_LIPM_MOBYPARSER_OBJECTID#</xsl:text>
		<xsl:if test="$objectId1 != ''">
			<xsl:value-of select="$objectId1"/>
		</xsl:if>
		<xsl:if test="$objectId2 != ''">
			<xsl:value-of select="$objectId2"/>
		</xsl:if>
		<xsl:text>#XSL_LIPM_MOBYPARSER_OBJECTID#</xsl:text>
		<xsl:text>
</xsl:text>

		<!-- Retrieve Object  articleName  -->

		<xsl:variable name="objectName1" select="normalize-space(./@moby:articleName)"/>
		<xsl:variable name="objectName2" select="normalize-space(./@articleName)"/>
		<xsl:text>#XSL_LIPM_MOBYPARSER_OBJECTNAME#</xsl:text>
		<xsl:if test="$objectName1 != ''">
			<xsl:value-of select="$objectName1"/>
		</xsl:if>
		<xsl:if test="$objectName2 != ''">
			<xsl:value-of select="$objectName2"/>
		</xsl:if>
		<xsl:text>#XSL_LIPM_MOBYPARSER_OBJECTNAME#</xsl:text>
		<xsl:text>
</xsl:text>


		<!-- Retrieve Object Content -->
		
		<xsl:text>#XSL_LIPM_MOBYPARSER_OBJECTCONTENT#</xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>#XSL_LIPM_MOBYPARSER_OBJECTCONTENT#</xsl:text>
		<xsl:text>
</xsl:text>

		<xsl:for-each select="./child::*">
			<xsl:choose>
				<xsl:when test="contains(name(.),'CrossReference')">
					<xsl:call-template name="crossReference"/>
				</xsl:when>
				<xsl:when test="contains(name(.),'Xref')">
					<xsl:call-template name="crossReference"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>#XSL_LIPM_MOBYPARSER_OBJECTHASA_START#</xsl:text>
			<xsl:text>
</xsl:text>
						<xsl:call-template name="objectClass"/>
					<xsl:text>#XSL_LIPM_MOBYPARSER_OBJECTHASA_END#</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		
	</xsl:template>
	
	
	
	<!--
	
	TEMPLATE CROSS/X/REF
	
	-->

	
	
	<xsl:template name="crossReference">
		<xsl:for-each select="./child::*">
			<xsl:variable name="crossrefObjectType" select="normalize-space(name(.))"/>
			<xsl:variable name="crossrefObjectId1" select="normalize-space(./@moby:id)"/>
			<xsl:variable name="crossrefObjectId2" select="normalize-space(./@id)"/>
			<xsl:variable name="crossrefObjectNamespace1" select="normalize-space(./@moby:namespace)"/>
			<xsl:variable name="crossrefObjectNamespace2" select="normalize-space(./@namespace)"/>

			<xsl:text>#XSL_LIPM_MOBYPARSER_CROSSREF_START#</xsl:text>
			<xsl:value-of select="$crossrefObjectType"/>
			<xsl:text>#XSL_LIPM_MOBYPARSER_CROSSREF_SEP#</xsl:text>
			<xsl:if test="$crossrefObjectId1 != ''"><xsl:value-of select="$crossrefObjectId1"/></xsl:if>
			<xsl:if test="$crossrefObjectId2 != ''"><xsl:value-of select="$crossrefObjectId2"/></xsl:if>
			<xsl:text>#XSL_LIPM_MOBYPARSER_CROSSREF_SEP#</xsl:text>
			<xsl:if test="$crossrefObjectNamespace1 != ''"><xsl:value-of select="$crossrefObjectNamespace1"/></xsl:if>
			<xsl:if test="$crossrefObjectNamespace2 != ''"><xsl:value-of select="$crossrefObjectNamespace2"/></xsl:if>
			<xsl:text>#XSL_LIPM_MOBYPARSER_CROSSREF_END#</xsl:text>
			<xsl:text>
</xsl:text>
		</xsl:for-each>
		
	</xsl:template>
	
</xsl:stylesheet> 
