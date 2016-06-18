package shaders;

import util.FileReader;

class Stamp {
	public static var uniforms = {
		tTexture: { type: "t", value: null }
	};
	public static var vertexShader = FileReader.readFile("shaders/stamp.vertex");
	public static var fragmentShader = FileReader.readFile("shaders/stamp.fragment");
}