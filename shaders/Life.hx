package shaders;

import three.Vector2;
import three.Vector4;
import util.FileReader;

class Life {
	public static var uniforms = {
		tUniverse: { type: "t", value: null },
		texelSize: { type: "v2", value: new Vector2() },
		liveColor: { type: "v4", value: new Vector4() },
		deadColor: { type: "v4", value: new Vector4() }
	};
	public static var vertexShader = FileReader.readFile("shaders/life.vertex");
	public static var fragmentShader = FileReader.readFile("shaders/life.fragment");
}