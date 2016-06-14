(function (console) { "use strict";
var Main = function() {
	window.onload = $bind(this,this.onWindowLoaded);
};
Main.main = function() {
	var main = new Main();
};
Main.prototype = {
	onWindowLoaded: function() {
	}
};
var $_, $fid = 0;
function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $fid++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; o.hx__closures__[m.__id__] = f; } return f; }
Main.WEBSITE_URL = "http://www.samcodes.co.uk/project/game-of-life/";
Main.header = "header";
Main.main();
})(typeof console != "undefined" ? console : {log:function(){}});
