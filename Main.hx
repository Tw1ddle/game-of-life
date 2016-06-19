package;

import js.Browser;
import js.html.ButtonElement;
import js.html.DivElement;
import js.html.Element;
import js.html.SelectElement;
import js.html.TextAreaElement;
import shaders.Copy;
import three.Color;
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

// Stores the embedded pattern files from the /embed folder as arrays of strings for use at runtime
@:build(PatternFileReaderMacro.build("embed"))
@:keep
class Patterns {
}

class Main {
	private static inline var WEBSITE_URL:String = "http://www.samcodes.co.uk/project/game-of-life/"; // Hosted demo URL
	private static inline var REPO_URL:String = "https://github.com/Tw1ddle/game-of-life/"; // Code repository URL
	
	private static inline var DEFAULT_PATTERN_NAME:String = "gosperglidergun_rle"; // Name of the default pattern preset
	
	private var renderer:WebGLRenderer; // The WebGL renderer
	private var clearColor:Color; // The color to clear the Game of Life area to when manually cleared
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
	
	private var simulationFramerateSlider:Element = cast Browser.document.getElementById(ID.simulationframerateslider);
	private var worldSizeSlider:Element = cast Browser.document.getElementById(ID.worldsizeslider);

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
			PatternLoader.expandToBoolGrid(name, data);
			#end
		}
		
		Sure.sure(Reflect.field(Patterns, DEFAULT_PATTERN_NAME));
		selectedPatternName = DEFAULT_PATTERN_NAME;
		
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
		
		clearColor = new Color(0x000000);
		
		// Scene setup
		scene = new Scene();
		
		// Camera setup
		camera = new OrthographicCamera(-0.5, 0.5, 0.5, -0.5, 0, 1);
		
		// Setup Game of Life shader effect
		gameOfLife = new GameOfLife(renderer, 256, 256);
		
		copyMaterial = new ShaderMaterial({
			vertexShader: Copy.vertexShader,
			fragmentShader: Copy.fragmentShader,
			uniforms: Copy.uniforms
		});
		copyMaterial.uniforms.tTexture.value = null;
		
		// Populate scene
		var mesh = new Mesh(new PlaneBufferGeometry(1, 1), copyMaterial);
		scene.add(mesh);
		
		// Initial renderer setup
		onResize();
		
		// Event setup
		patternPresetListElement.addEventListener("change", function() {
			selectedPatternName = patternPresetListElement.value;
		}, false);
		
		lifeClearButtonElement.addEventListener("click", function() {
			gameOfLife.clear(clearColor);
		}, false);
		
		lifeStepButtonElement.addEventListener("click", function() {
			if (!gameOfLife.paused) {
				gameOfLife.togglePaused();
				onPauseToggled();
			}
			
			gameOfLife.step(true);
		}, false);
		
		runPauseButtonElement.addEventListener("click", function() {
			gameOfLife.togglePaused();
			onPauseToggled();
		}, false);
		
		// Window resize event
		Browser.window.addEventListener("resize", function():Void {
			onResize();
		}, true);
		
		renderer.domElement.addEventListener("mousedown", function(e:Dynamic):Void {
			e.preventDefault();
			
			var rect = renderer.domElement.getBoundingClientRect();
			var size = renderer.getSize();
			var x = (e.clientX - rect.left) / size.width;
			var y = (e.clientY - rect.top) / size.height;
			
			onPointerDown(x, y); // TODO use % across or the coordinates as % of the render target, not the raw pointer coordinates
		}, false);
		
		renderer.domElement.addEventListener("touchstart", function(e:Dynamic):Void {
			e.preventDefault();
			
			var rect = renderer.domElement.getBoundingClientRect();
			var size = renderer.getSize();
			var x = (e.clientX - rect.left) / size.width;
			var y = (e.clientY - rect.top) / size.height;
			
			// TODO fix, use touch stuff properly?
			trace(x);
			trace(y);
			
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
		gameOfLife.step();
		
		// Render the game of life scene to the screen
		copyMaterial.uniforms.tTexture.value = gameOfLife.current.texture;
		renderer.render(scene, camera);
		
		Browser.window.requestAnimationFrame(animate);
	}
	
	/**
	 * Triggered when the user resizes the browser.
	 */
	private function onResize():Void {
		var size = previousPowerOfTwo(Browser.window.innerWidth);
		renderer.setSize(size, size);
	}
	
	/**
	 * Call when you pause or unpause the Game of Life simulation.
	 */
	private function onPauseToggled():Void {
		if (gameOfLife.paused) {
			runPauseButtonElement.innerHTML = "<h2>Run</h2>";
		} else {
			runPauseButtonElement.innerHTML = "<h2>Pause</h2>";
		}
	}
	
	/**
	 * Called when the user clicks or taps the Game of Life world.
	 * @param	x	The percentage distance the pointer was across the renderer view element.
	 * @param	y	The percentage distance the pointer was up the renderer view element.
	 */
	private function onPointerDown(x:Float, y:Float):Void {
		var patternGrid = PatternLoader.expandToBoolGrid(selectedPatternName, Reflect.field(Patterns, selectedPatternName));
		
		var maxWidth:Int = 0;
		for (line in patternGrid) {
			if (line.length > maxWidth) {
				maxWidth = line.length;
			}
		}
		
		var canvas = Browser.document.createCanvasElement();
		canvas.width = nextPowerOfTwo(maxWidth);
		canvas.height = nextPowerOfTwo(patternGrid.length);
		var ctx = canvas.getContext("2d");
		
		ctx.beginPath();
		ctx.rect(0, 0, canvas.width, canvas.height);
		ctx.fillStyle = "black";
		ctx.fill();
		
		for (y in 0...patternGrid.length) {
			for (x in 0...patternGrid[y].length) {
				if (patternGrid[y][x] == true) { // TODO make it work for the other formats, this is RLE specific
					ctx.beginPath();
					ctx.rect(x, y, 1, 1);
					ctx.fillStyle = "white";
					ctx.fill();
				}
			}
		}
		
		var tex = new Texture(canvas);
		tex.needsUpdate = true;
		tex.wrapS = Wrapping.ClampToEdgeWrapping;
		tex.wrapT = Wrapping.ClampToEdgeWrapping;
		
		//gameDiv.appendChild(canvas); // For debug viewing, note need to not dispose the canvas/texture
		gameOfLife.stampPattern(x, y, tex);
		gameOfLife.step(true);
		
		tex.dispose();
	}
	
	/**
	 * Gets a random pattern file from the embedded Patterns class.
	 * @return	The content of the pattern file.
	 */
	private function getRandomPattern():Array<String> {
		var patterns = Type.getClassFields(Patterns);
		var randomFieldIndex = Std.int(Math.random() * (patterns.length - 1));
		return Reflect.field(Patterns, patterns[randomFieldIndex]);
	}
	
	/**
	 * Gets the next power of 2.
	 * @param	x	The value to compute the next power of 2 above.
	 * @return	The next power of 2 above x.
	 */
	private inline function nextPowerOfTwo(x:Int):Int {
		var result:Int = 1;
		while (result < x) {
			result <<= 1;
		}
		return result;
	}
	
	/**
	 * Gets the previous power of 2.
	 * @param	x	The value to compute the previous power of 2 below.
	 * @return	The previous power of 2 below x.
	 */
	private inline function previousPowerOfTwo(x:Int):Int {
		var result:Int = 1;
		while (result << 1 < x) {
			result <<= 1;
		}
		return result;
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
		
		if (patternPresetListElement.value != patternName) {
			patternPresetListElement.value = patternName;
		}
		
		return selectedPatternName;
	}
}