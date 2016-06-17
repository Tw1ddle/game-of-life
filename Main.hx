package;

import js.Browser;
import js.html.DivElement;
import js.html.SelectElement;
import shaders.Life;
import three.Mesh;
import three.OrthographicCamera;
import three.PixelFormat;
import three.PlaneBufferGeometry;
import three.Scene;
import three.ShaderMaterial;
import three.Texture;
import three.TextureFilter;
import three.WebGLRenderTarget;
import three.WebGLRenderTargetOptions;
import three.WebGLRenderer;
import webgl.Detector;
import js.html.TextAreaElement;

using StringTools;

// Automatic HTML code completion, you need to point these to your debug/release HTML
#if debug
@:build(CodeCompletion.buildLocalFile("bin/debug/index.html"))
#else
@:build(CodeCompletion.buildLocalFile("bin/release/index.html"))
#end
class ID {}

@:build(PatternFileReaderMacro.build("embed"))
@:keep
class Patterns {
	// Contains whole pattern (gliders etc) files as arrays of strings for use at runtime
}

class GameOfLife {
	private var camera:OrthographicCamera;
	private var scene:Scene;
	private var params:WebGLRenderTargetOptions;
	private var ping:WebGLRenderTarget;
	private var pong:WebGLRenderTarget;
	private var current:WebGLRenderTarget;
	public var material(default, null):ShaderMaterial;
	private var renderer:WebGLRenderer;
	
	public function new(renderer:WebGLRenderer, width:Int, height:Int) {
		this.renderer = renderer;
		camera = new OrthographicCamera( -1, 1, 1, -1, 0, 1);
		scene = new Scene();
		params = { minFilter: TextureFilter.LinearFilter, magFilter: TextureFilter.NearestFilter, format: cast PixelFormat.RGBAFormat };
		ping = new WebGLRenderTarget(width, height, params);
		pong = new WebGLRenderTarget(width, height, params);
		current = ping;
		material = new ShaderMaterial( {
			vertexShader: Life.vertexShader,
			fragmentShader: Life.fragmentShader,
			uniforms: Life.uniforms
		});
		material.uniforms.tUniverse.value = current.texture;
		
		var mesh = new Mesh(new PlaneBufferGeometry(2, 2), material);
		scene.add(mesh);
	}
	
	public function render():Void {
		// Swap render targets
		current = current == ping ? pong : ping;
		material.uniforms.tUniverse.value = current.texture;
		
		var nonCurrent = current == ping ? pong : ping;
		
		// Render the game of life 2D scene into the non-current render target
		renderer.render(this.scene, this.camera, nonCurrent, true);
	}
	
	public function isCellLive(x:Int, y:Int):Bool {
		var buffer = new js.html.Uint8Array(4);
		renderer.readRenderTargetPixels(current, x, y, 1, 1, buffer);
		trace(buffer);
		return buffer[3] == 255 ? true : false; // TODO fix
	}
	
	public function stampPattern(x:Int, y:Int, pattern:Texture):Void {
		// todo render pattern texture/pixels to rendertarget
		
	}
}

// Expands and converts ASCII Life 1.0x format patterns: http://www.conwaylife.com/wiki/Life_1.05
class LifeReader {
	// TODO
}

// Expands and converts "plain text" cells format patterns: http://www.conwaylife.com/wiki/Plaintext
class PlaintextCellsReader {
	// TODO
}

// Expands and converts run length encoded patterns: http://www.conwaylife.com/wiki/RLE
class RLEReader {
	public static function expandRle(rle:Array<String>):Array<String> {
		var width:Int = 0;
		var height:Int = 0;
		var rule:String = "";
		var rlePattern:String = "";
		var runCountMatcher:EReg = ~/[0-9]/i;
		var foundSize:Bool = false;
		
		for (line in rle) {
			if (line.indexOf("#") != -1) {
				continue; // Ignore the # lines
			}
			
			if (!foundSize) { // Look for the width, height and rule
				var components:Array<String> = line.split(",");
				Sure.sure(components.length == 2 || components.length == 3);
				
				var getComponentValue = function(component:String):String {
					var kv = component.split("=");
					Sure.sure(kv.length == 2);
					var v = kv[1].trim();
					Sure.sure(v.length != 0);
					return v;
				}
				
				width = Std.parseInt(getComponentValue(components[0]));
				height = Std.parseInt(getComponentValue(components[1]));
				
				if(components.length == 3) {
					rule = getComponentValue(components[2]);
				}
				
				foundSize = true;
				continue;
			}
			
			rlePattern += line; // Flatten all other lines of RLE encoded b (dead) o (alive) and $ (end of line) cell descriptions into a single string
		}
		
		var result:Array<String> = [];
		var rleRows:Array<String> = rlePattern.split("$");
		for (row in rleRows) {
			var expandedRow:String = "";
			var number:String = "";
			for (i in 0...row.length) {
				var ch = row.charAt(i);
				if (runCountMatcher.match(ch)) {
					number += ch;
				} else if (ch == "o") {
					var runCount = 1;
					if(number.length > 0) {
						runCount = Std.parseInt(number);
					}
					for (i in 0...runCount) {
						expandedRow += "o";
						number = "";
					}
				} else if (ch == "b") {
					var runCount = 1;
					if(number.length > 0) {
						runCount = Std.parseInt(number);
					}
					for (i in 0...runCount) {
						expandedRow += "b";
						number = "";
					}
				}
			}
			result.push(expandedRow);
		}
		
		Sure.sure(result.length > 0);
		trace(result);
		return result;
	}
}

class Main {
	private static inline var WEBSITE_URL:String = "http://www.samcodes.co.uk/project/game-of-life/"; // Hosted demo URL
	private static inline var REPO_URL:String = "https://github.com/Tw1ddle/game-of-life/"; // Code repository URL
	
	private var renderer:WebGLRenderer;
	private var scene:Scene;
	private var camera:OrthographicCamera;
	private var lifeEffect:GameOfLife;
	private var gameDiv:DivElement;
	
	private var selectedPatternFileName(default, set):String; // Name of the currently selected pattern file (name of the corresponding member variable in the Patterns class)
	
	private var patternPresetListElement:SelectElement = cast Browser.document.getElementById("patternpresetlist"); // TODO
	private var patternFileEditElement:TextAreaElement = cast Browser.document.getElementById("patternfileedit"); // TODO

	private static function main():Void {
		var main = new Main();
	}

	private inline function new() {
		for (name in Type.getClassFields(Patterns)) {
			var data = Reflect.field(Patterns, name);
			
			if (StringTools.endsWith(name, "rle")) {
				//trace("its a rle"); // TODO
				trace(name);
				RLEReader.expandRle(data);
			}
			
			var option = Browser.document.createOptionElement();
			option.appendChild(Browser.document.createTextNode(name));
			option.value = name;
			patternPresetListElement.appendChild(option);
		}
		
		patternPresetListElement.addEventListener("change", function() {
			selectedPatternFileName = patternPresetListElement.value;
		}, false);
		
		// Wait for the window to load before creating the sliders, starting the simulation input etc
		Browser.window.onload = onWindowLoaded;
	}

	private inline function onWindowLoaded():Void {
		gameDiv = Browser.document.createDivElement();
		
		// WebGL support check
		var glSupported:WebGLSupport = Detector.detect();
		if (glSupported != SUPPORTED_AND_ENABLED) {
			var unsupportedInfo = Browser.document.createElement('div');
			unsupportedInfo.style.position = 'absolute';
			unsupportedInfo.style.top = '10px';
			unsupportedInfo.style.width = '100%';
			unsupportedInfo.style.textAlign = 'center';
			unsupportedInfo.style.color = '#ffffff';
			
			switch(glSupported) {
				case WebGLSupport.NOT_SUPPORTED:
					unsupportedInfo.innerHTML = 'Your browser does not support WebGL. Click <a href="' + REPO_URL + '" target="_blank">here for project info</a> instead.';
				case WebGLSupport.SUPPORTED_BUT_DISABLED:
					unsupportedInfo.innerHTML = 'Your browser supports WebGL, but the feature appears to be disabled. Click <a href="' + REPO_URL + '" target="_blank">here for project info</a> instead.';
				default:
					unsupportedInfo.innerHTML = 'Could not detect WebGL support. Click <a href="' + REPO_URL + '" target="_blank">here for project info</a> instead.';
			}
			
			gameDiv.appendChild(unsupportedInfo);
			return;
		}
		
		// Setup WebGL renderer
        renderer = new WebGLRenderer( { antialias: true } );
		renderer.autoClear = false;
		renderer.setPixelRatio(Browser.window.devicePixelRatio);
		
		// Scene setup
		scene = new Scene();
		
		// Camera setup
		camera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);
		
		// Setup Game of Life shader effect
		lifeEffect = new GameOfLife(renderer, 500, 500);
		
		// Populate scene
		scene.add(camera);
		
		// TODO use a texture rendering material...
		var mesh = new Mesh(new PlaneBufferGeometry(2, 2), lifeEffect.material);
		scene.add(mesh);
		
		// Initial renderer setup
		onResize();
		
		// Event setup
		// Window resize event
		Browser.window.addEventListener("resize", function():Void {
			onResize();
		}, true);
		
		renderer.domElement.addEventListener("mousedown", function(e:Dynamic):Void {
			e.preventDefault();
			
			var x:Int = Std.int(e.clientX - renderer.domElement.offsetLeft);
			var y:Int = Std.int(e.clientY - renderer.domElement.offsetTop);
			
			onPointerDown(x, y);
		}, false);
		
		renderer.domElement.addEventListener("touchdown", function(e:Dynamic):Void {
			e.preventDefault();
			
		}, false);
		
		// Present game and start animation loop
		gameDiv.appendChild(renderer.domElement);
		var gameAttachPoint = Browser.document.getElementById("game");
		gameAttachPoint.appendChild(gameDiv);
		Browser.window.requestAnimationFrame(animate);
	}
	
	private function animate(time:Float):Void {
		lifeEffect.render();
		
		// Render the world scene to the screen
		renderer.render(scene, camera);
		
		Browser.window.requestAnimationFrame(animate);
	}
	
	// Called when browser window resizes
	private function onResize():Void {
		renderer.setSize(500, 500);
	}
	
	// Called when the user clicks or taps
	private function onPointerDown(x:Int, y:Int):Void {
		var live:Bool = lifeEffect.isCellLive(x, y);
		
		trace(live);
	}
	
	private function set_selectedPatternFileName(fileName:String):String {
		selectedPatternFileName = fileName;
		
		var fileContent:Array<String> = Reflect.getProperty(Patterns, fileName);
		Sure.sure(fileContent.length > 0);
		
		var content = "";
		for (line in fileContent) {
			content += line + "\r";
		}
		patternFileEditElement.value = content;
		
		return selectedPatternFileName;
	}
}