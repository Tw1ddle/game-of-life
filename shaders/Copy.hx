package shaders;

import util.FileReader;

class Copy {
	public static var uniforms = {
		tTexture: { type: "t", value: null }
	};
	public static var vertexShader = FileReader.readFile("shaders/copy.vertex");
	public static var fragmentShader = FileReader.readFile("shaders/copy.fragment");
}