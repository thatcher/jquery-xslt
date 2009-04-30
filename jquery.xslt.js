/*
 * Chris Thatcher
 *
 * Copyright (c) 2005-2009
 * 
 * based on jquery.xslt.js by Johann Burkard (<mailto:jb@eaio.com>)
 * <http://eaio.com>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
 * NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
 * USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 */
 
/**
 * jQuery client-side XSLT plugins.
 * 
 * @author <a href="mailto:jb@eaio.com">Johann Burkard</a>
 * @version $Id: jquery.xslt.js,v 1.10 2008/08/29 21:34:24 Johann Exp $
 */
(function($, _) {
	var _xslt = null,
		template = null,
		processor = null;
	
    _.xslt = function() {
        return this;
    }
    var str = /^\s*</;
    if (document.recalc) { // IE 5+
        _.xslt = function(name, xslt_url, parameters, filter) {
			// Load your XSL
			//alert("Loading "+xslt_url);
			_xslt = new ActiveXObject("MSXML2.FreeThreadedDomDocument");
			_xslt.async = false;
			_xslt.load(xslt_url);
			
			// create a compiled XSL-object
			template = new ActiveXObject("MSXML2.XSLTemplate");
			template.stylesheet = _xslt.documentElement;
				
			// create XSL-processor
			processor = template.createProcessor();
			
			
			// input for XSL-processor
			if(parameters){
				for(var p in parameters){
					processor.addParameter(p, parameters[p]);
				}
			}
			//add function to jquery namespace
			_[name] = function(xml){
				processor.input = xml;
				processor.transform();
				if(filter && $.isFunction(filter)){
					return filter(processor.output);
				}else{
					return processor.output;
				}
			};
			
            return this;
       };
    }else if (	window.DOMParser != undefined && 
				window.XMLHttpRequest != undefined && 
				window.XSLTProcessor != undefined  ) { // Mozilla 0.9.4+, Opera 9+
       var processor = new XSLTProcessor();
       var support = false;
       if ($.isFunction(processor.transformDocument)) {
           support = window.XMLSerializer != undefined;
       } else {
           support = true;
       }
       if (support) {
            _.xslt = function(name, xslt_url, parameters, filter) {
				//compile an xslt and add it to the jQuery static namespace
				$.ajax({
					url:xslt_url,
					type:"GET",
					dataType:'xml',
					async:false,
					success: function(xml){ 
						_xslt = xml;
					}
				});
            	processor.importStylesheet(_xslt);
				if(parameters){
					for(var p in parameters){
						processor.setParameter(null, p, parameters[p]);
					}
				}
				//add the function to jquery namespace
                if ($.isFunction(processor.transformToFragment)) {
					
					_[name] = function(xml){
						var result;
						if(filter && $.isFunction(filter)){
							result = processor.transformToFragment(xml, document);
							return filter(result);
						}else{
							return processor.transformToFragment(xml, document);
						}
					};
					
                } else if($.isFunction(processor.transformDocument)) {

					_[name] = function(xml){
	                    // obsolete Mozilla interface
	                    var resultDoc = document.implementation.createDocument("", "", null);
	                    processor.transformDocument(xml, _xslt, resultDoc, null);
						if(filter && $.isFunction(filter)){
							return filter($("#transformiixResult",resultDoc).html());
						}else{
							return $("#transformiixResult",resultDoc).html();
						}
	                    
					};
                }
                return this;
            };
       }
    }
})(jQuery, jsPath);
