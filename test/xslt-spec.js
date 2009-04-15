(function($){
	//This is our example plugin that will be created.
	$.xslt('xml2js', '../src/xml2js.xsl', {
		force_array : "|hit|location|list|term|target|"
	}, function(result){
		var doc,
			json = (typeof(result)=='string')?result:$(result).text();
			doc = eval( "(" + json + ")" );
		return doc;
	});
	
  	// RSpec/Bacon Style
	with (jqUnit) {
		
		//tests basic init functionality
		describe('jQuery XSLT', 'xml2js', {
			before: function(){
				var _this = this;
				// this is an assignment object so we cant mess
				// with the actual test suite
				this.js = {};
				jQuery.ajax({
					type:'GET',
					dataType:'xml',
					url:'data/test-js.xml',
					async:false,
					success:function(xml){
						_this.js = $.xml2js(xml);
					},
					error:function(){
						ok(false);
					}
				});
			}
		}).it('should be a function', function(){
			isType($.xml2js, Function);
		}).should('attributes are prefixed with $', function(){
			equals(this.a('js').root.$version, '1.0');
		}).pending('should do something awesome', function(){
			// It doesnt matter what you put here it wont be run until
			// you change this to an actual spec
			ok(false);
		});
		
		
	}
    
})(jQuery);
