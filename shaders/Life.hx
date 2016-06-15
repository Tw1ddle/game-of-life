package shaders;

import util.FileReader;

class Life {
	public static var uniforms = {
		tUniverse: { type: "t", value: null }
	};
	public static var vertexShader = FileReader.readFile("shaders/life.vertex");
	public static var fragmentShader = FileReader.readFile("shaders/life.fragment");
}