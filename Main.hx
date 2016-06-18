package;

import js.Browser;
import js.html.ButtonElement;
import js.html.DivElement;
import js.html.SelectElement;
import js.html.TextAreaElement;
import shaders.Copy;
import three.Mesh;
import three.OrthographicCamera;
import three.PlaneBufferGeometry;
import three.Scene;
import three.ShaderMaterial;
import three.Texture;
import three.WebGLRenderer;
import three.Wrapping;
import webgl.Detector;

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
	// Stores the embedded pattern files from the /embed folder as arrays of strings for use at runtime
}

class Main {
	private static inline var WEBSITE_URL:String = "http://www.samcodes.co.uk/project/game-of-life/"; // Hosted demo URL
	private static inline var REPO_URL:String = "https://github.com/Tw1ddle/game-of-life/"; // Code repository URL
	
	private var renderer:WebGLRenderer; // The WebGL renderer
	private var scene:Scene;
	private var camera:OrthographicCamera;
	private var gameOfLife:GameOfLife;
	private var copyMaterial:ShaderMaterial; // For rendering the final game of life texture to the screen
	private var gameDiv:DivElement; // The HTML div the Game of Life simulation is nested in
	
	private var selectedPatternName(default, set):String; // Name of the currently selected pattern file (name of the corresponding member variable in the Patterns class)
	
	private var patternPresetListElement:SelectElement = cast Browser.document.getElementById(ID.patternpresetlist);
	private var patternFileEditElement:TextAreaElement = cast Browser.document.getElementById(ID.patternfileedit);
	private var lifeClearButtonElement:ButtonElement = cast Browser.document.getElementById(ID.lifeclearbutton);
	private var lifeStepButtonElement:ButtonElement = cast Browser.document.getElementById(ID.lifestepbutton);
	private var runPauseButtonElement:ButtonElement = cast Browser.document.getElementById(ID.liferunpausebutton);

	private static function main():Void {
		var main = new Main();
	}

	private inline function new() {
		for (name in Type.getClassFields(Patterns)) {
			// Populate the embedded pattern select dropdown
			var option = Browser.document.createOptionElement();
			option.appendChild(Browser.document.createTextNode(name));
			option.value = name;
			patternPresetListElement.appendChild(option);
			
			#if debug // Check that all the embedded patterns are supported, can be read, expanded etc
			var data = Reflect.field(Patterns, name);
			//PatternReader.expandToStringArray(name, data);
			#end
		}
		
		Browser.window.onload = onWindowLoaded; // Wait for the window to load before creating the input elements, starting the simulation input etc
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
		gameOfLife = new GameOfLife(renderer, 512, 512);
		
		copyMaterial = new ShaderMaterial({
			vertexShader: Copy.vertexShader,
			fragmentShader: Copy.fragmentShader,
			uniforms: Copy.uniforms
		});
		copyMaterial.uniforms.tTexture.value = null;
		
		// Populate scene
		var mesh = new Mesh(new PlaneBufferGeometry(2, 2), copyMaterial);
		scene.add(mesh);
		
		// Initial renderer setup
		onResize();
		
		// Event setup
		patternPresetListElement.addEventListener("change", function() {
			selectedPatternName = patternPresetListElement.value;
		}, false);
		
		lifeClearButtonElement.addEventListener("click", function() {
			gameOfLife.clear();
		}, false);
		
		lifeStepButtonElement.addEventListener("click", function() {
			gameOfLife.render(true);
		}, false);
		
		runPauseButtonElement.addEventListener("click", function() {
			gameOfLife.togglePaused();
		}, false);
		
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
		
		renderer.domElement.addEventListener("touchstart", function(e:Dynamic):Void {
			e.preventDefault();
			var x:Int = Std.int(e.touches[0].clientX - renderer.domElement.offsetLeft);
			var y:Int = Std.int(e.touches[0].clientY - renderer.domElement.offsetTop);
			onPointerDown(x, y);
		}, false);
		
		// Present game and start simulation loop
		gameDiv.appendChild(renderer.domElement);
		var gameAttachPoint = Browser.document.getElementById("game");
		gameAttachPoint.appendChild(gameDiv);
		Browser.window.requestAnimationFrame(animate);
	}
	
	/**
	 * Main update loop.
	 * @param	time	The time since the last frame of animation.
	 */
	private function animate(time:Float):Void {
		gameOfLife.render();
		
		// Render the game of life scene to the screen
		copyMaterial.uniforms.tTexture.value = gameOfLife.current.texture;
		renderer.render(scene, camera);
		
		Browser.window.requestAnimationFrame(animate);
	}
	
	/**
	 * Triggered when the user resizes the browser.
	 */
	private function onResize():Void {
		renderer.setSize(900, 900);
	}
	
	/**
	 * Called when the user clicks or taps the Game of Life world.
	 * @param	x	The local x-coordinate of the pointer.
	 * @param	y	The local y-coordinate of the pointer.
	 */
	private function onPointerDown(x:Int, y:Int):Void {
		var live:Bool = gameOfLife.isCellLive(x, y);
		
		// TODO create the texture for the pattern
		//var patternGrid = PatternReader.expandToStringArray(selectedPatternName, Reflect.field(Patterns, selectedPatternName));
		//trace(patternGrid);
		
		var canvas = Browser.document.createCanvasElement();
		canvas.width = 100;
		canvas.height = 100;
		var ctx = canvas.getContext("2d");
		
		gameDiv.appendChild(canvas);

		ctx.beginPath();
		ctx.rect(0, 0, 100, 100);
		ctx.fillStyle = "blue";
		ctx.fill();
		
		ctx.beginPath();
		ctx.rect(0, 0, 50, 50);
		ctx.fillStyle = "red";
		ctx.fill();
		
		var tex = new Texture(canvas);
		tex.needsUpdate = true;
		tex.wrapS = Wrapping.ClampToEdgeWrapping;
		tex.wrapT = Wrapping.ClampToEdgeWrapping;
		
		gameOfLife.stampPattern(x, y, tex);
	}
	
	/**
	 * Helper function for setting the currently selected pattern. When this updates, so should the content of the pattern file textbox.
	 * @param	patternName	The name of the member variable in the Patterns class that corresponds to the file.
	 * @return	The current pattern name.
	 */
	private function set_selectedPatternName(patternName:String):String {
		selectedPatternName = patternName;
		
		var fileContent:Array<String> = Reflect.getProperty(Patterns, patternName);
		Sure.sure(fileContent.length > 0);
		
		// Ensure empty lines count as newlines in the text edit
		var content = "";
		for (line in fileContent) {
			content += line + "\r";
		}
		patternFileEditElement.value = content;
		
		return selectedPatternName;
	}
}