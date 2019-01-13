package shaders;

import js.three.Vector2;
import util.FileReader;

class Stamp {
	public static var uniforms = {
		tLast: { type: "t", value: null },
		tStamp: { type: "t", value: null },
		pos: { type: "v2", value: new Vector2(0, 0) },
		size: { type: "v2", value: new Vector2(0, 0) }
	};
	public static var vertexShader = FileReader.readFile("shaders/passthrough.vertex");
	public static var fragmentShader = FileReader.readFile("shaders/stamp.fragment");
}