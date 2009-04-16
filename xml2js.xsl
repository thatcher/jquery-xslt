<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!--
	Modified by Chris Thatcher

	vvvvvvvvvvvvvvv Original Header vvvvvvvvvvvvvvvvv
	
  Copyright (c) 2006, Doeke Zanstra
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, 
  are permitted provided that the following conditions are met:

  Redistributions of source code must retain the above copyright notice, this 
  list of conditions and the following disclaimer. Redistributions in binary 
  form must reproduce the above copyright notice, this list of conditions and the 
  following disclaimer in the documentation and/or other materials provided with 
  the distribution.

  Neither the name of the dzLib nor the names of its contributors may be used to 
  endorse or promote products derived from this software without specific prior 
  written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
  THE POSSIBILITY OF SUCH DAMAGE.
-->

  <xsl:output indent="no" 
  	omit-xml-declaration="yes" 
	method="text" 
	encoding="UTF-8" 
	media-type="application/javascript"/>
    <xsl:strip-space elements="*"/>
  <xsl:param name="force_array" />

  
  <!-- JS: attributes -->
  <xsl:template name="attrs">
    <xsl:if test="not(count(attribute::*)=0)">
      <xsl:for-each select="attribute::*">
        <xsl:call-template name="indent"/>
        <xsl:call-template name="quote-property">
          <xsl:with-param name="name" select="concat('$',translate(name(),':','$'))"/>
        </xsl:call-template>
        <xsl:text> : </xsl:text>
        <xsl:call-template name="value">
            <xsl:with-param name="v" select="."/>
        </xsl:call-template>
        <xsl:if test="not(position()=last() or last()=1)">
          <xsl:text>,</xsl:text>
        </xsl:if>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>
  
    <!-- JS: namespaces -->
    <xsl:template name="namespaces">
        <xsl:if test="not(namespace-uri() = namespace-uri(parent::node()))">
            <xsl:text>$xmlns : </xsl:text>
            <xsl:call-template name="escape-string">
                <xsl:with-param name="s" select="namespace-uri()"/>
            </xsl:call-template>
            <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:for-each select="child::* | attribute::*">
            <xsl:variable name="this" select="."/>
            <xsl:if test="not(name() = local-name()) and 
                            not(preceding-sibling::node()[namespace-uri() = namespace-uri($this)])">
                <xsl:variable name="prefix" select="substring-before(name(), ':')"/>
                <xsl:call-template name="indent"/>
                <xsl:call-template name="quote-property">
                    <xsl:with-param name="name" select="concat('$xmlns$',$prefix)"/>
                </xsl:call-template>
                <xsl:text>: </xsl:text>
                <xsl:call-template name="escape-string">
                    <xsl:with-param name="s" select="namespace-uri()"/>
                </xsl:call-template>
                <xsl:if test="not(position()=last() or last()=1)">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
  
  <!-- Main template for escaping strings; used by above template and for object-properties 
       Responsibilities: placed quotes around string, and chain up to next filter, escape-bs-string -->
  <xsl:template name="escape-string">
    <xsl:param name="s"/>
    <xsl:text>"</xsl:text>
    <xsl:call-template name="escape-bs-string">
      <xsl:with-param name="s" select="$s"/>
    </xsl:call-template>
    <xsl:text>"</xsl:text>
  </xsl:template>
  
  <!-- Escape the backslash (\) before everything else. -->
  <xsl:template name="escape-bs-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <xsl:when test="contains($s,'\')">
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="concat(substring-before($s,'\'),'\\')"/>
        </xsl:call-template>
        <xsl:call-template name="escape-bs-string">
          <xsl:with-param name="s" select="substring-after($s,'\')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="$s"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Escape the double quote ("). -->
  <xsl:template name="escape-quot-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <xsl:when test="contains($s,'&quot;')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,'&quot;'),'\&quot;')"/>
        </xsl:call-template>
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="substring-after($s,'&quot;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="$s"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  

  <!-- Replace tab, line feed and/or carriage return by its matching escape code. Also escape tag-closes
      (</tag> to <\/tag> for client-side javascript compliance). Can't escape backslash
       or double quote here, because they don't replace characters (&#x0; becomes \t), but they prefix 
       characters (\ becomes \\). Besides, backslash should be seperate anyway, because it should be 
       processed first. This function can't do that. -->
  <xsl:template name="encode-string">
    <xsl:param name="s"/>
	<xsl:value-of select="normalize-space($s)"/>
  </xsl:template>

  
  <!-- JS: Date: YYYY-dd-mm[Thh]
  <xsl:template match="text()[string-length()=10 
    and string-length(translate(substring(.,1,4),'0123456789',''))=0 
    and substring(.,5,1)='-' 
    and string-length(translate(substring(.,6,2),'0123456789',''))=0 
    and substring(.,8,1)='-' 
    and string-length(translate(substring(.,9,2),'0123456789',''))=0
    ]">
    <xsl:text>new Date(</xsl:text>
    <xsl:value-of select="substring(.,1,4)"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="substring(.,6,2)"/>
    <xsl:text>-1,</xsl:text>
    <xsl:value-of select="substring(.,9,2)"/>
    <xsl:text>)</xsl:text>
    </xsl:template> -->
  <!-- JS: Date: YYYY-dd-mmThh:mm
  <xsl:template match="text()[string-length()=16 
    and string-length(translate(substring(.,1,4),'0123456789',''))=0 
    and substring(.,5,1)='-' 
    and string-length(translate(substring(.,6,2),'0123456789',''))=0 
    and substring(.,8,1)='-' 
    and string-length(translate(substring(.,9,2),'0123456789',''))=0 
    and substring(.,11,1)='T'
    and string-length(translate(substring(.,12,2),'0123456789',''))=0 
    and substring(.,14,1)=':'
    and string-length(translate(substring(.,15,2),'0123456789',''))=0 
    ]">
    <xsl:text>new Date(</xsl:text>
    <xsl:value-of select="substring(.,1,4)"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="substring(.,6,2)"/>
    <xsl:text>-1,</xsl:text>
    <xsl:value-of select="substring(.,9,2)"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="substring(.,12,2)"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="substring(.,15,2)"/>
    <xsl:text>)</xsl:text>
    </xsl:template> -->
  <!-- JS: Date: YYYY-dd-mmThh:mm:ss 
  <xsl:template match="text()[string-length()=19 
    and string-length(translate(substring(.,1,4),'0123456789',''))=0 
    and substring(.,5,1)='-' 
    and string-length(translate(substring(.,6,2),'0123456789',''))=0 
    and substring(.,8,1)='-' 
    and string-length(translate(substring(.,9,2),'0123456789',''))=0 
    and substring(.,11,1)='T'
    and string-length(translate(substring(.,12,2),'0123456789',''))=0 
    and substring(.,14,1)=':'
    and string-length(translate(substring(.,15,2),'0123456789',''))=0 
    and substring(.,17,1)=':'
    and string-length(translate(substring(.,18,2),'0123456789',''))=0 
    ]">
    <xsl:text>new Date(</xsl:text>
    <xsl:value-of select="substring(.,1,4)"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="substring(.,6,2)"/>
    <xsl:text>-1,</xsl:text>
    <xsl:value-of select="substring(.,9,2)"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="substring(.,12,2)"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="substring(.,15,2)"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="substring(.,18,2)"/>
    <xsl:text>)</xsl:text>
    </xsl:template>-->

  <!-- item:null -->
  <!--xsl:template match="*[count(child::node())=0]">
    <xsl:call-template name="indent"/>
    <xsl:call-template name="quote-property">
      <xsl:with-param name="name" select="translate(name(),':','$')"/>
    </xsl:call-template>
    <xsl:text>:null</xsl:text>
    <xsl:if test="following-sibling::*">,</xsl:if>
  </xsl:template-->

    <!-- object or array filter -->
    <xsl:template match="*" name="base">
        <xsl:variable name="this" select="."/>
        <xsl:choose>  
            <xsl:when test="name(following-sibling::node())=name()
                          or name(preceding-sibling::node()[1])=name()
                          or contains($force_array, concat('|' , name(), '|'))">
                <xsl:if test="not(name(preceding-sibling::node()[1])=name())">
                    <xsl:call-template name="indent"/>
                    <xsl:call-template name="quote-property">
                        <xsl:with-param name="name" select="translate(name(),':','$')"/>
                    </xsl:call-template>
                    <xsl:text>:</xsl:text>
                    <xsl:text>[</xsl:text>
                    <xsl:for-each select=". | following-sibling::node()[name()=name($this)]">
                        <xsl:choose>
                            <xsl:when test="count(./*)>0"> 
                                <xsl:text>{</xsl:text>
                                <xsl:call-template name="object">
                                    <xsl:with-param name="o"  select="."/>
                                </xsl:call-template>
                                <xsl:call-template name="indent"/>
                                <xsl:text>}</xsl:text>
                            </xsl:when>
                            <xsl:when test="count(./*)=0 and ./text()">
                                <xsl:call-template name="value">
                                    <xsl:with-param name="v" select="./text()"/>
                                </xsl:call-template>
                            </xsl:when>
                        </xsl:choose>
                        <xsl:if test="not(position()=last() or last()=1) and not(count(child::node())=0)">
                            <xsl:text>,</xsl:text>
                        </xsl:if>
                        <xsl:if test="position()=last()">
                            <xsl:text>]</xsl:text>
                            <xsl:if test="following-sibling::*">
                                <xsl:text>,</xsl:text>
                            </xsl:if>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="count(./*)>0"> 
                        <xsl:call-template name="indent"/>
                        <xsl:call-template name="quote-property">
                            <xsl:with-param name="name" select="translate(name(),':','$')"/>
                        </xsl:call-template>
                        <xsl:text>:</xsl:text>
                        <xsl:text>{</xsl:text>
                        <xsl:call-template name="object">
                            <xsl:with-param name="o"  select="."/>
                        </xsl:call-template>
                        <xsl:call-template name="indent"/>
                        <xsl:text>}</xsl:text>
                        <xsl:if test="following-sibling::*">
                            <xsl:text>,</xsl:text>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="count(./*)=0 and ./text()">
                        <xsl:call-template name="indent"/>
                        <xsl:call-template name="quote-property">
                            <xsl:with-param name="name" select="translate(name(),':','$')"/>
                        </xsl:call-template>
                        <xsl:text>:</xsl:text>
                        <xsl:call-template name="value">
                            <xsl:with-param name="v" select="./text()"/>
                        </xsl:call-template>
                        <xsl:if test="following-sibling::*">
                            <xsl:text>,</xsl:text>
                        </xsl:if>
                    </xsl:when>
					<xsl:otherwise>
						
					    <xsl:call-template name="indent"/>
					    <xsl:call-template name="quote-property">
					      <xsl:with-param name="name" select="translate(name(),':','$')"/>
					    </xsl:call-template>
					    <xsl:text>:null</xsl:text>
					    <xsl:if test="following-sibling::*">,</xsl:if>
					</xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
  
  <xsl:template name='object'>
    <xsl:param name="o"/>
    <!-- JS: handle namespaces -->
    <xsl:call-template name="namespaces"/>
    <!-- JS: handle attributes -->
    <xsl:call-template name="attrs"/>
    <xsl:if test="count($o/@*)>0  and count($o/*)>0">
      <xsl:text>,</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="$o/*"/>
  </xsl:template>
  
  <!-- ignore document text -->
  <!--xsl:template match="text()[preceding-sibling::node() or following-sibling::node()]">
      goop
  </xsl:template-->
  
    <!-- simple value type checking -->
    <xsl:template name="value">
        <xsl:param name="v"/>
        <xsl:choose>
            <!-- number (no support for javascript mantise) -->
            <xsl:when test="not(string(number($v))='NaN') or 
                              not(string(number($v))='NaN') ">
                <xsl:value-of select="."/>
            </xsl:when>
            <!-- boolean, case-insensitive -->
            <xsl:when test="translate($v,'TRUE','true')='true' or 
                              translate($v,'TRUE','true')='true'">true</xsl:when>
            <xsl:when test="translate($v,'FALSE','false')='false' or 
                                translate($v,'FALSE','false')='false'">false</xsl:when>
            <!-- JS: include comments -->
            <xsl:when test="comment()">/*<xsl:value-of select="$v"/>*/</xsl:when> 
            <!-- string --> 
            <xsl:otherwise>
                <xsl:call-template name="escape-string">
                    <xsl:with-param name="s" select="$v"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
  
  <!-- JS: don't quote if not necessary -->
  <xsl:template name="quote-property">
    <xsl:param name="name"/>
    <xsl:call-template name="escape-string">
      <xsl:with-param name="s" select="$name"/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- JS: indent for reability -->
  <xsl:template name="indent">
    <xsl:text>
    </xsl:text>
    <xsl:for-each select="ancestor::*">
      <xsl:text>  </xsl:text>
    </xsl:for-each>
  </xsl:template>
  
  
  <!-- convert root element to an anonymous container -->
  <xsl:template match="/">
    <xsl:text>{</xsl:text>
        <xsl:apply-templates select="*"/>
    <xsl:text>}</xsl:text>
  </xsl:template>
    
</xsl:stylesheet>