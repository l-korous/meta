<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="$metaDbName" />

ALTER TABLE dbo.A ADD CONSTRAINT FK_A_B_id FOREIGN KEY ([B_id], [branch_id]) REFERENCES B ([id], [branch_id]) ON UPDATE NO ACTION ON DELETE CASCADE
ALTER TABLE dbo.AtC ADD CONSTRAINT FK_AtC_A_sru FOREIGN KEY ([A_sru], [branch_id]) REFERENCES A ([id], [branch_id]) ON UPDATE NO ACTION ON DELETE CASCADE
ALTER TABLE dbo.AtC ADD CONSTRAINT FK_AtC_Cid FOREIGN KEY ([Cid], [branch_id]) REFERENCES C ([_123], [branch_id]) ON UPDATE NO ACTION ON DELETE CASCADE
</xsl:template>
</xsl:stylesheet>
