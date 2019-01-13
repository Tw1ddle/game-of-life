package shaders;

import js.three.Vector4;
import util.FileReader;

class Clear {
	public static var uniforms = {
		clearColor: { type: "v4", value: new Vector4(1.0, 1.0, 1.0, 1.0) }
	};
	public static var vertexShader = FileReader.readFile("shaders/passthrough.vertex");
	public static var fragmentShader = FileReader.readFile("shaders/clear.fragment");
}