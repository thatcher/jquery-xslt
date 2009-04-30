<?xml version="1.0" encoding="UTF-8"?>
<stylesheet version="1.0" 
            xmlns="http://www.w3.org/1999/XSL/Transform"
            xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <!--
     /**
      *  Copyright (c) 2009, Chris Thatcher
      *  License MIT/GPL 
      *  Based on work by Doeke Zanstra
      */
    -->

    <output indent="no" 
            omit-xml-declaration="yes" 
	        method="text" 
            encoding="UTF-8" 
            media-type="application/javascript"/>
    <strip-space elements="*"/>
    <param name="force_array" />


    <!-- convert root element to an anonymous container -->
    <template match="/">
        <text>{</text>
            <apply-templates select="*"/>
        <text>}</text>
    </template>
    
    <!-- simple object or array filter -->
    <template match="*" name="base">
        <variable name="this" select="."/>
        <choose>  
            <when test="name(following-sibling::node())=name()
                          or name(preceding-sibling::node()[1])=name()
                          or contains($force_array, concat('|' , name(), '|'))">
                <if test="not(name(preceding-sibling::node()[1])=name())">
                    <!-- array of like-named elements -->
                    <call-template name="array_wrapper">
                        <with-param name="aw" select=". | following-sibling::node()[name()=name($this)]"/>
                    </call-template>
                    <if test="following-sibling::node()[name()!=name($this)]">
                        <text>,</text>
                    </if>
                </if>
            </when>
            <otherwise>
                <choose>
                    <!-- complex property or nested object -->
                    <when test="count(./*)>0 or count(./@*)>0"> 
                        <call-template name='nested_object'>
                            <with-param name='no' select='.'/>
                        </call-template>
                    </when>
                    <!-- simple content with no attributes -->
                    <when test="count(./*)=0 and ./text() and count(./@*)=0">
                        <call-template name="property">
                            <with-param name="p" select="."/>
                        </call-template>
                    </when>
                    <otherwise>
                        <!-- item:null -->
                        <call-template name='null_property'>
                            <with-param name='np' select='.'/>
                        </call-template>
  					</otherwise>
                </choose>
            </otherwise>
        </choose>
    </template>
    
  <!-- mixed document text -->
  <template name='mixed_content'>
    <param name='m'/>
    <text>  '$':</text>
    <text>[</text>
    <for-each select="$m">
        <variable name='this' select='.'/>
        <choose>
            <when test='name()'>
                <choose>
                    <when test="name(following-sibling::node())=name()
                                  or name(preceding-sibling::node()[1])=name()
                                  or contains($force_array, concat('|' , name(), '|'))">
                        <if test="not(name(preceding-sibling::node()[1])=name())">
                            <!-- array of like-named elements -->
                            <call-template name="array_wrapper">
                                <with-param name="aw" select=". | following-sibling::node()[name()=name($this)]"/>
                                <with-param name='ew' select='true()'/>
                            </call-template>
                            <if test="following-sibling::node()[name()!=name($this)]">
                                <text>,</text>
                            </if>
                        </if>
                    </when>
                    <otherwise>
                        <choose>
                            <!-- complex property or nested object -->
                            <when test="count(./*)>0 or count(./@*)>0"> 
                                <call-template name='nested_object'>
                                    <with-param name='no' select='.'/>
                                    <with-param name='ew' select='true()'/>
                                </call-template>
                            </when>
                            <!-- simple content with no attributes -->
                            <when test="count(./*)=0 and ./text() and count(./@*)=0">
                                <call-template name="property">
                                    <with-param name="p" select="."/>
                                    <with-param name='ew' select='true()'/>
                                </call-template>
                            </when>
                            <otherwise>
                                <!-- item:null -->
                                <call-template name='null_property'>
                                    <with-param name='np' select='.'/>
                                    <with-param name='ew' select='true()'/>
                                </call-template>
          					</otherwise>
                        </choose>
                    </otherwise>
                </choose>
            </when>
            <otherwise >
                <if test='string-length(normalize-space(.))>0'>
                    <call-template name='value'>
                        <with-param name="v"  select="."/>
                    </call-template>
                    <if test="following-sibling::*">
                        <text>,</text>
                    </if>
                </if>
            </otherwise>
        </choose>
    </for-each>
    <text>]</text>
  </template>
  
  <template name='nested_object'>
    <param name='no'/>
    <param name='ew' select='false()'/>
    <call-template name="indent"/>
    <if test='$ew'><text>{</text></if>
    <call-template name="quote-property">
        <with-param name="name" select="translate(name($no),':','$')"/>
    </call-template>
    <text>:</text>
    <call-template name="object_wrapper">
        <with-param name="ow" select="$no"/>
    </call-template>
    <if test='$ew'><text>}</text></if>
    <if test="$no/following-sibling::*">
        <text>,</text>
    </if>
  </template>
  
  <template name='object_wrapper'>
    <param name='w'/>
    <text>{</text>
    <call-template name="object">
        <with-param name="o"  select="."/>
    </call-template>
    <call-template name="indent"/>
    <text>}</text>
  </template>
  
  <template name='object'>
    <param name="o"/>
    <!-- JS: handle namespaces -->
    <call-template name="namespaces"/>
    <!-- JS: handle attributes -->
    <call-template name="attrs"/>
    <if test="count($o/@*)>0  and count($o/text() | $o/*)>0">
      <text>,</text>
    </if>
    <choose>
        <when test="count($o/text()) > 0 and
                        count($o/@*) > 0 and 
                        count($o/text()) > 0 and 
                        string-length(normalize-space($o/text()))>0">
            <call-template name="indent"/>
            <call-template name="mixed_content">
      		    <with-param name="m" select="$o/*|$o/text()"/>
            </call-template>
        </when>
        <otherwise>
            <apply-templates select="$o/*"/>
        </otherwise>
    </choose>
  </template>
  
  <template name='array_wrapper'>
    <param name='aw'/>
    <param name='ew' select='false()'/>
    <call-template name="indent"/>
    <if test='$ew'><text>{</text></if>
    <call-template name="quote-property">
        <with-param name="name" select="translate(name($aw),':','$')"/>
    </call-template>
    <text>:</text>
    <text>[</text>
    <for-each select="$aw">
        <call-template name='array_item'>
            <with-param name='ai' select='.'/>
        </call-template>
        <if test="not(position()=last() or last()=1)">
            <text>,</text>
        </if>
    </for-each>
    <text>]</text>
    <if test='$ew'><text>}</text></if>
  </template>
  
  <template name='array_item'>
    <param name='ai'/>
    <choose>
        <when test="count($ai/*)>0"> 
            <call-template name="object_wrapper">
                <with-param name="w"  select="$ai"/>
            </call-template>
        </when>
        <when test="count($ai/*)=0 and $ai/text()">
            <call-template name="value">
                <with-param name="v" select="$ai/text()"/>
            </call-template>
        </when>
        <otherwise>
            <text>null</text>
        </otherwise>
    </choose>
  </template>
  
  <template name='property'>
      <param name='p'/>
    <param name='ew' select='false()'/>
    <call-template name="indent"/>
    <if test='$ew'><text>{</text></if>
    <call-template name="quote-property">
        <with-param name="name" select="translate(name($p),':','$')"/>
    </call-template>
    <text>:</text>
    <call-template name="value">
        <with-param name="v" select="$p/text()"/>
    </call-template>
    <if test='$ew'><text>}</text></if>
    <if test="$p/following-sibling::*">
        <text>,</text>
    </if>
  </template>
  
  <template name='null_property'>
    <param name='np'/>
    <param name='ew' select='false()'/>
    <call-template name="indent"/>
    <if test='$ew'><text>{</text></if>
    <call-template name="quote-property">
      <with-param name="name" select="translate(name($np),':','$')"/>
    </call-template>
    <text>:null</text>
    <if test='$ew'><text>}</text></if>
    <if test="$np/following-sibling::*">,</if>
  </template>
  
  <!-- JS: attributes -->
  <template name="attrs">
    <if test="not(count(attribute::*)=0)">
      <for-each select="attribute::*">
        <call-template name="indent"/>
        <call-template name="quote-property">
          <with-param name="name" select="concat('$',translate(name(),':','$'))"/>
        </call-template>
        <text> : </text>
        <call-template name="value">
            <with-param name="v" select="."/>
        </call-template>
        <if test="not(position()=last() or last()=1)">
          <text>,</text>
        </if>
      </for-each>
    </if>
  </template>
  
    <!-- JS: namespaces -->
    <template name="namespaces">
        <if test="not(namespace-uri() = namespace-uri(parent::node()))">
            <call-template name="indent"/>
            <text>  "$xmlns" : </text>
            <call-template name="escape-string">
                <with-param name="s" select="namespace-uri()"/>
            </call-template>
            <text>, </text>
        </if>
        <for-each select="child::* | attribute::*">
            <variable name="this" select="."/>
            <if test="not(name() = local-name()) and 
                            not(preceding-sibling::node()[namespace-uri() = namespace-uri($this)])">
                <variable name="prefix" select="substring-before(name(), ':')"/>
                <call-template name="indent"/>
                <call-template name="quote-property">
                    <with-param name="name" select="concat('$xmlns$',$prefix)"/>
                </call-template>
                <text>: </text>
                <call-template name="escape-string">
                    <with-param name="s" select="namespace-uri()"/>
                </call-template>
                <if test="not(position()=last() or last()=1)">
                    <text>,</text>
                </if>
            </if>
        </for-each>
    </template>
  
  <!-- Main template for escaping strings; used by above template and for object-properties 
       Responsibilities: placed quotes around string, and chain up to next filter, escape-bs-string -->
  <template name="escape-string">
    <param name="s"/>
    <text>"</text>
    <call-template name="escape-bs-string">
      <with-param name="s" select="$s"/>
    </call-template>
    <text>"</text>
  </template>
  
  <!-- Escape the backslash (\) before everything else. -->
  <template name="escape-bs-string">
    <param name="s"/>
    <choose>
      <when test="contains($s,'\')">
        <call-template name="escape-quot-string">
          <with-param name="s" select="concat(substring-before($s,'\'),'\\')"/>
        </call-template>
        <call-template name="escape-bs-string">
          <with-param name="s" select="substring-after($s,'\')"/>
        </call-template>
      </when>
      <otherwise>
        <call-template name="escape-quot-string">
          <with-param name="s" select="$s"/>
        </call-template>
      </otherwise>
    </choose>
  </template>
  
  <!-- Escape the double quote ("). -->
  <template name="escape-quot-string">
    <param name="s"/>
    <choose>
      <when test="contains($s,'&quot;')">
        <call-template name="encode-string">
          <with-param name="s" select="concat(substring-before($s,'&quot;'),'\&quot;')"/>
        </call-template>
        <call-template name="escape-quot-string">
          <with-param name="s" select="substring-after($s,'&quot;')"/>
        </call-template>
      </when>
      <otherwise>
        <call-template name="encode-string">
          <with-param name="s" select="$s"/>
        </call-template>
      </otherwise>
    </choose>
  </template>
  
  

  <!-- Replace tab, line feed and/or carriage return by its matching escape code. Also escape tag-closes
      (</tag> to <\/tag> for client-side javascript compliance). Can't escape backslash
       or double quote here, because they don't replace characters (&#x0; becomes \t), but they prefix 
       characters (\ becomes \\). Besides, backslash should be seperate anyway, because it should be 
       processed first. This function can't do that. -->
  <template name="encode-string">
    <param name="s"/>
	  <value-of select="normalize-space($s)"/>
  </template>

  
    <!-- simple value type checking -->
    <template name="value">
        <param name="v"/>
        <choose>
            <!-- number (no support for javascript mantise) -->
            <when test="not(string(number($v))='NaN') or 
                            not(string(number($v))='NaN') ">
                <value-of select="."/>
            </when>
            <!-- boolean, case-insensitive -->
            <when test="translate($v,'TRUE','true')='true' or 
                            translate($v,'TRUE','true')='true'">true</when>
            <when test="translate($v,'FALSE','false')='false' or 
                            translate($v,'FALSE','false')='false'">false</when>
            <!-- JS: include comments -->
            <when test="comment()">/*<value-of select="$v"/>*/</when> 
            <!-- JS: Date: YYYY-dd-mm[Thh] -->
            <when test="string-length($v)=10 
              and string-length(translate(substring($v,1,4),'0123456789',''))=0 
              and substring($v,5,1)='-' 
              and string-length(translate(substring($v,6,2),'0123456789',''))=0 
              and substring($v,8,1)='-' 
              and string-length(translate(substring($v,9,2),'0123456789',''))=0">
              <text>new Date(</text>
              <value-of select="substring($v,1,4)"/>
              <text>,</text>
              <value-of select="substring($v,6,2)"/>
              <text>-1,</text>
              <value-of select="substring($v,9,2)"/>
              <text>)</text>
            </when> 
            <!-- JS: Date: YYYY-dd-mmThh:mm -->
            <when test="string-length($v)=16 
              and string-length(translate(substring($v,1,4),'0123456789',''))=0 
              and substring($v,5,1)='-' 
              and string-length(translate(substring($v,6,2),'0123456789',''))=0 
              and substring($v,8,1)='-' 
              and string-length(translate(substring($v,9,2),'0123456789',''))=0 
              and substring($v,11,1)='T'
              and string-length(translate(substring($v,12,2),'0123456789',''))=0 
              and substring($v,14,1)=':'
              and string-length(translate(substring($v,15,2),'0123456789',''))=0 ">
              <text>new Date(</text>
              <value-of select="substring($v,1,4)"/>
              <text>,</text>
              <value-of select="substring($v,6,2)"/>
              <text>-1,</text>
              <value-of select="substring($v,9,2)"/>
              <text>,</text>
              <value-of select="substring($v,12,2)"/>
              <text>,</text>
              <value-of select="substring($v,15,2)"/>
              <text>)</text>
            </when> 
            <!-- JS: Date: YYYY-dd-mmThh:mm:ss -->
            <when test="string-length($v)=19 
              and string-length(translate(substring($v,1,4),'0123456789',''))=0 
              and substring($v,5,1)='-' 
              and string-length(translate(substring($v,6,2),'0123456789',''))=0 
              and substring($v,8,1)='-' 
              and string-length(translate(substring($v,9,2),'0123456789',''))=0 
              and substring($v,11,1)='T'
              and string-length(translate(substring($v,12,2),'0123456789',''))=0 
              and substring($v,14,1)=':'
              and string-length(translate(substring($v,15,2),'0123456789',''))=0 
              and substring($v,17,1)=':'
              and string-length(translate(substring($v,18,2),'0123456789',''))=0">
              <text>new Date(</text>
              <value-of select="substring($v,1,4)"/>
              <text>,</text>
              <value-of select="substring($v,6,2)"/>
              <text>-1,</text>
              <value-of select="substring($v,9,2)"/>
              <text>,</text>
              <value-of select="substring($v,12,2)"/>
              <text>,</text>
              <value-of select="substring($v,15,2)"/>
              <text>,</text>
              <value-of select="substring($v,18,2)"/>
              <text>)</text>
            </when>
            <!-- string --> 
            <otherwise>
                <call-template name="escape-string">
                    <with-param name="s" select="$v"/>
                </call-template>
            </otherwise>
        </choose>
    </template>
  
  <!-- JS: don't quote if not necessary -->
  <template name="quote-property">
    <param name="name"/>
    <call-template name="escape-string">
      <with-param name="s" select="$name"/>
    </call-template>
  </template>
  
  <!-- JS: indent for reability -->
  <template name="indent">
    <text>
    </text>
    <for-each select="ancestor::*">
      <text>  </text>
    </for-each>
  </template>
  
  
    
    <!--
	  vvvvvvvvvvvvvvv Original Header Retained Below vvvvvvvvvvvvvvvvv
	
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
</stylesheet>