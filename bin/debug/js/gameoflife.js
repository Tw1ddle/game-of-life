(function (console) { "use strict";
var $estr = function() { return js_Boot.__string_rec(this,''); };
var GameOfLife = function(renderer,width,height) {
	this.renderer = renderer;
	this.camera = new THREE.OrthographicCamera(-1,1,1,-1,0,1);
	this.scene = new THREE.Scene();
	this.params = { minFilter : THREE.LinearFilter, magFilter : THREE.NearestFilter, format : THREE.RGBAFormat};
	this.ping = new THREE.WebGLRenderTarget(width,height,this.params);
	this.pong = new THREE.WebGLRenderTarget(width,height,this.params);
	this.current = this.ping;
	this.material = new THREE.ShaderMaterial({ vertexShader : shaders_Life.vertexShader, fragmentShader : shaders_Life.fragmentShader, uniforms : shaders_Life.uniforms});
	this.material.uniforms.tUniverse.value = this.current.texture;
	var mesh = new THREE.Mesh(new THREE.PlaneBufferGeometry(2,2),this.material);
	this.scene.add(mesh);
};
GameOfLife.__name__ = true;
GameOfLife.prototype = {
	render: function() {
		if(this.current == this.ping) this.current = this.pong; else this.current = this.ping;
		this.material.uniforms.tUniverse.value = this.current.texture;
		var nonCurrent;
		if(this.current == this.ping) nonCurrent = this.pong; else nonCurrent = this.ping;
		this.renderer.render(this.scene,this.camera,nonCurrent,true);
	}
	,isCellLive: function(x,y) {
		var buffer = new Uint8Array(4);
		this.renderer.readRenderTargetPixels(this.current,x,y,1,1,buffer);
		console.log(buffer);
		if(buffer[3] == 255) return true; else return false;
	}
	,stampPattern: function(x,y,pattern) {
	}
};
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
		this.renderer.setClearColor(new THREE.Color(16711680));
		this.renderer.setPixelRatio(window.devicePixelRatio);
		this.scene = new THREE.Scene();
		this.camera = new THREE.OrthographicCamera(-1,1,1,-1,0,1);
		this.lifeEffect = new GameOfLife(this.renderer,500,500);
		this.scene.add(this.camera);
		var mesh = new THREE.Mesh(new THREE.PlaneBufferGeometry(2,2),this.lifeEffect.material);
		this.scene.add(mesh);
		this.onResize();
		window.addEventListener("resize",function() {
			_g.onResize();
		},true);
		this.renderer.domElement.addEventListener("mousedown",function(e) {
			e.preventDefault();
			var x = e.clientX - _g.renderer.domElement.offsetLeft | 0;
			var y = e.clientY - _g.renderer.domElement.offsetTop | 0;
			_g.onPointerDown(x,y);
		},false);
		this.renderer.domElement.addEventListener("touchdown",function(e1) {
			e1.preventDefault();
		},false);
		this.gameDiv.appendChild(this.renderer.domElement);
		var gameAttachPoint = window.document.getElementById("game");
		gameAttachPoint.appendChild(this.gameDiv);
		window.requestAnimationFrame($bind(this,this.animate));
	}
	,animate: function(time) {
		this.lifeEffect.render();
		this.renderer.render(this.scene,this.camera);
		window.requestAnimationFrame($bind(this,this.animate));
	}
	,onResize: function() {
		this.renderer.setSize(500,500);
	}
	,onPointerDown: function(x,y) {
		var live = this.lifeEffect.isCellLive(x,y);
		console.log(live);
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
var shaders_Life = function() { };
shaders_Life.__name__ = true;
var util_FileReader = function() { };
util_FileReader.__name__ = true;
var $_, $fid = 0;
function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $fid++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; o.hx__closures__[m.__id__] = f; } return f; }
String.__name__ = true;
Array.__name__ = true;
GameOfLife.header = "header";
GameOfLife.accordion = "accordion";
GameOfLife.controls = "controls";
GameOfLife.runstop = "runstop";
GameOfLife.step = "step";
GameOfLife.clear = "clear";
GameOfLife.game = "game";
Main.WEBSITE_URL = "http://www.samcodes.co.uk/project/game-of-life/";
Main.REPO_URL = "https://github.com/Tw1ddle/game-of-life/";
shaders_Life.uniforms = { tUniverse : { type : "t", value : null}};
shaders_Life.vertexShader = "varying vec2 vUv;\r\n\r\nvoid main()\r\n{\r\n\tvUv = uv;\r\n\tgl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);\r\n}";
shaders_Life.fragmentShader = "varying vec2 vUv;\r\n\r\nuniform sampler2D tUniverse;\r\n\r\nvoid main()\r\n{\r\n\tgl_FragColor = vec4(1.0, 0.5, 0.0, 1.0);\r\n}";
Main.main();
})(typeof console != "undefined" ? console : {log:function(){}});

//# sourceMappingURL=gameoflife.js.map