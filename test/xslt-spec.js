(function($, _){
    
	//This is our example plugin that will be created.
	_.xslt('evalx', '../eval.xsl', {
		force_array : "|hit|location|list|term|target|"
	}, function(result){
		var doc,
			json = (typeof(result)=='string')?result:$(result).text();
			doc = eval( "(" + json + ")" );
		return doc;
	});
	
    var root;
    
  	// RSpec/Bacon Style
	with (jqUnit) {
		
		//tests basic init functionality
		describe('jQuery XSLT', 'evalx', {
			before: function(){
				// this is an assignment object so we cant mess
				// with the actual test suite
				jQuery.ajax({
					type:'GET',
					dataType:'xml',
					url:'data/test-js.xml',
					async:false,
					success:function(xml){
						root = _.evalx(xml).root;
					},
					error:function(){
						ok(false);
					}
				});
			}
		}).it('should be a function', function(){
            
			defined( _, 'evalx' ,'_.evalx is defined');
            
		}).should('prefix attributes with $', function(){
			
            equals( root.$version, '1.0');
			equals( root.$xmlns, "http://example.com/test");
            
		}).should('replace namespace namespace prefix : with $', function(){
            
			equals( root.$xmlns$ding, 
                    'http://zanstra.com/ding', 
                    'namespace appears on objects which use that prefix');
			equals( root.nsobject.$xmlns$xlink, 
                    "http://xlink" , 
                    'namespace appears on objects which use that prefix');
            
		}).should('evaluate dates', function(){
            
			equals( root.birthdate.toUTCString(), 
                    'Tue, 14 Nov 2006 05:00:00 GMT', 
                    'date is correct');
            
		}).should('treat elements in sequence as an array', function(){
            
			equals( root.appointment.length, 
                    2, 
                    'appointments is an array');
			equals( root.appointment[0].toUTCString(), 
                    'Tue, 14 Nov 2006 17:30:00 GMT', 
                    'date is correct');
			equals( root.appointment[1].toUTCString(), 
                    'Tue, 14 Nov 2006 17:20:00 GMT', 
                    'date is correct');
            
		}).should('safely escape cdata as a string', function(){
            
			equals( root.script.replace('<','&lt;', 'g'), 
                    "&lt;script>alert(\"YES\")&lt;/script>", 
                    'cdata was safely treated as a string');
            
		}).should('safely parse simple types', function(){
            
			equals( root.positive, 
                    123, 
                    'parsed positive number');
			equals( root.negative, 
                    -12, 
                    'parsed negative number');
			equals( root.zero, 
                    0, 
                    'parsed zero number');
			equals( root.fixed, 
                    10.25, 
                    'parsed fixed');
			equals( root.fixed_neg, 
                    -10.25, 
                    'parsed fixed negative');
			equals( root.padded_zero, 
                    1, 
                    'parsed padded zero number');
			equals( root['int'], 
                    123, 
                    'parsed int number');
			equals( root['float'], 
                    -12.123, 
                    'parsed float number');
			equals( root['boolean'], 
                    true, 
                    'parsed boolean ');
            
		}).pending('should support javascript mantis', function(){
			// It doesnt matter what you put here it wont be run until
			// you change this to an actual spec
			ok(false);
		});
		
		
	}
    
})(jQuery, jsPath);
