package;

import js.Browser;
import js.html.Element;
import js.html.InputElement;
import js.html.SelectElement;
import js.nouislider.NoUiSlider;
import js.wNumb.WNumb;

using StringTools;

// Automatic HTML code completion, you need to point these to your debug/release HTML
#if debug
@:build(CodeCompletion.buildLocalFile("bin/debug/index.html"))
#else
@:build(CodeCompletion.buildLocalFile("bin/release/index.html"))
#end

class Main {
    private static inline var WEBSITE_URL:String = "http://www.samcodes.co.uk/project/game-of-life/"; // Hosted demo URL

    private static function main():Void {
        var main = new Main();
    }

    private inline function new() {
        // Wait for the window to load before creating the sliders, starting the simulation input etc
        Browser.window.onload = onWindowLoaded;
    }

    private inline function onWindowLoaded():Void {
	
    }
}