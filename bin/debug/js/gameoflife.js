(function (console) { "use strict";
var $estr = function() { return js_Boot.__string_rec(this,''); };
var Main = function() {
	window.onload = $bind(this,this.onWindowLoaded);
};
Main.__name__ = true;
Main.main = function() {
	var main = new Main();
};
Main.prototype = {
	onWindowLoaded: function() {
		var _g = this;
		var _this = window.document;
		this.gameDiv = _this.createElement("div");
		var glSupported = WebGLDetector.detect();
		if(glSupported != 0) {
			var unsupportedInfo = window.document.createElement("div");
			unsupportedInfo.style.position = "absolute";
			unsupportedInfo.style.top = "10px";
			unsupportedInfo.style.width = "100%";
			unsupportedInfo.style.textAlign = "center";
			unsupportedInfo.style.color = "#ffffff";
			switch(glSupported) {
			case 2:
				unsupportedInfo.innerHTML = "Your browser does not support WebGL. Click <a href=\"" + "https://github.com/Tw1ddle/game-of-life/" + "\" target=\"_blank\">here for project info</a> instead.";
				break;
			case 1:
				unsupportedInfo.innerHTML = "Your browser supports WebGL, but the feature appears to be disabled. Click <a href=\"" + "https://github.com/Tw1ddle/game-of-life/" + "\" target=\"_blank\">here for project info</a> instead.";
				break;
			default:
				unsupportedInfo.innerHTML = "Could not detect WebGL support. Click <a href=\"" + "https://github.com/Tw1ddle/game-of-life/" + "\" target=\"_blank\">here for project info</a> instead.";
			}
			this.gameDiv.appendChild(unsupportedInfo);
			return;
		}
		this.renderer = new THREE.WebGLRenderer({ antialias : true});
		this.renderer.autoClear = false;
		this.renderer.setClearColor(new THREE.Color(0));
		this.renderer.setPixelRatio(window.devicePixelRatio);
		this.onResize();
		window.addEventListener("resize",function() {
			_g.onResize();
		},true);
		this.scene = new THREE.Scene();
		this.camera = new THREE.OrthographicCamera(-0.5,0.5,0.5,-0.5,1,1000);
		this.gameDiv.appendChild(this.renderer.domElement);
		var gameAttachPoint = window.document.getElementById("game");
		gameAttachPoint.appendChild(this.gameDiv);
		window.requestAnimationFrame($bind(this,this.animate));
	}
	,animate: function(time) {
		this.renderer.render(this.scene,this.camera);
		window.requestAnimationFrame($bind(this,this.animate));
	}
	,onResize: function() {
		this.renderer.setSize(500,500);
	}
};
Math.__name__ = true;
var js_Boot = function() { };
js_Boot.__name__ = true;
js_Boot.__string_rec = function(o,s) {
	if(o == null) return "null";
	if(s.length >= 5) return "<...>";
	var t = typeof(o);
	if(t == "function" && (o.__name__ || o.__ename__)) t = "object";
	switch(t) {
	case "object":
		if(o instanceof Array) {
			if(o.__enum__) {
				if(o.length == 2) return o[0];
				var str2 = o[0] + "(";
				s += "\t";
				var _g1 = 2;
				var _g = o.length;
				while(_g1 < _g) {
					var i1 = _g1++;
					if(i1 != 2) str2 += "," + js_Boot.__string_rec(o[i1],s); else str2 += js_Boot.__string_rec(o[i1],s);
				}
				return str2 + ")";
			}
			var l = o.length;
			var i;
			var str1 = "[";
			s += "\t";
			var _g2 = 0;
			while(_g2 < l) {
				var i2 = _g2++;
				str1 += (i2 > 0?",":"") + js_Boot.__string_rec(o[i2],s);
			}
			str1 += "]";
			return str1;
		}
		var tostr;
		try {
			tostr = o.toString;
		} catch( e ) {
			return "???";
		}
		if(tostr != null && tostr != Object.toString && typeof(tostr) == "function") {
			var s2 = o.toString();
			if(s2 != "[object Object]") return s2;
		}
		var k = null;
		var str = "{\n";
		s += "\t";
		var hasp = o.hasOwnProperty != null;
		for( var k in o ) {
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str.length != 2) str += ", \n";
		str += s + k + " : " + js_Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str += "\n" + s + "}";
		return str;
	case "function":
		return "<function>";
	case "string":
		return o;
	default:
		return String(o);
	}
};
var $_, $fid = 0;
function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $fid++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; o.hx__closures__[m.__id__] = f; } return f; }
String.__name__ = true;
Array.__name__ = true;
Main.WEBSITE_URL = "http://www.samcodes.co.uk/project/game-of-life/";
Main.REPO_URL = "https://github.com/Tw1ddle/game-of-life/";
Main.header = "header";
Main.accordion = "accordion";
Main.controls = "controls";
Main.runstop = "runstop";
Main.step = "step";
Main.clear = "clear";
Main.game = "game";
Main.main();
})(typeof console != "undefined" ? console : {log:function(){}});

//# sourceMappingURL=gameoflife.js.map