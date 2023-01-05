package openfl.display;

import flixel.FlxG;
import openfl.display.Shader;
import openfl.filters.ShaderFilter;
import flixel.math.FlxMath;
import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.math.FlxMath;
#if openfl
import openfl.system.System;
#end

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class FPS extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	private var memoryMegas:Float = 0;
	private var memoryTotal:Float = 0;

	#if cpp
	var totalmem:Int = InitLoader.Ram;
	#end
	var gpuInfo:String = FlxG.stage.context3D.driverInfo.substr(FlxG.stage.context3D.driverInfo.indexOf('Renderer=') + 9);
	var platform:String = InitLoader.System + " " + InitLoader.SystemVer;
	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;

	var textShader = new Shader();
	var debug:Bool = #if debug true #else false #end;

	private var intervalArray:Array<String> = ['MB', 'GB', 'TB']; // og: https://github.com/BeastlyGhost/Forever-Engine-Underscore/blob/master/source/base/debug/Overlay.hx

	private function getInterval(size:Float):String
	{
		var data = 0;
		if (size > 1024 && data < intervalArray.length - 1)
		{
			data++;
			size = size / 1024;
		}

		size = Math.round(size * 100) / 100;
		return size + " " + intervalArray[data];
	}

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		textShader.glFragmentSource = "varying float vAlpha;
			varying vec2 vTexCoord;
			uniform sampler2D uImage0;
			uniform int width;
			uniform int height;
			
			void main(void) {
				
				vec4 color = texture2D(uImage0, vTexCoord);
				vec4 left = texture2D(uImage0, vTexCoord - vec2(-1.0 / width, 0));
				vec4 right = texture2D(uImage0, vTexCoord - vec2(1.0 / width, 0));
				vec4 up = texture2D(uImage0, vTexCoord - vec2(0, -1.0 / height));
				vec4 down = texture2D(uImage0, vTexCoord - vec2(0, 1.0 / height));
				float alpha = color.a;
				if (left.a > alpha) alpha = left.a;
				if (right.a > alpha) alpha = right.a;
				if (up.a > alpha) alpha = up.a;
				if (down.a > alpha) alpha = down.a;
				gl_FragColor = vec4(
					color.r * color.a,
					color.g * color.a,
					color.b * color.a,
					color.a
					);
				
			}";

		filters = [new ShaderFilter(textShader)];
		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("VCR OSD Mono", 14, color);
		autoSize = LEFT;
		multiline = true;
		text = '';

		cacheCount = 0;
		currentTime = 0;
		times = [];
		backgroundColor = 0;
		width = 350;
	}

	private var _ms:Float = 0.0;
	private var totalms:Float = 0.0;

	// Event Handlers

	@:noCompletion
	private override function __enterFrame(deltaTime:Float):Void
	{
		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
			times.shift();

		var currentCount:Int = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		_ms = FlxMath.lerp(_ms, 1 / Math.round(currentFPS) * 1000,
			CoolUtil.boundTo(FlxG.elapsed * 3.75 * ((Math.abs(_ms - 1 / Math.round(currentFPS) * 1000) < 0.45) ? 2.5 : 1.0), 0, 1));
		if (currentFPS > ClientPrefs.framerate)
			currentFPS = ClientPrefs.framerate;

		if (FlxG.keys.justPressed.F3)
			debug = !debug;

		var fpsMs = ' (${FlxMath.roundDecimal(_ms, 2)}ms)';
		if (currentCount != cacheCount || _ms != totalms /*&& visible*/)
		{
			text = '';
			if (ClientPrefs.showFPS)
				text += "FPS: " + currentFPS + (debug ? fpsMs : '');
			// Show Mem Pr: https://github.com/ShadowMario/FNF-PsychEngine/pull/9554/

			#if openfl
			memoryMegas = Math.abs(FlxMath.roundDecimal(System.totalMemory / 1000000, 1));

			if (memoryMegas > memoryTotal)
				memoryTotal = memoryMegas;

			if (ClientPrefs.showMEM)
				text += '\nMem: ${getInterval(memoryMegas)} / Peak: ${getInterval(memoryTotal)}' #if cpp + ' / Total: ${getInterval(totalmem)}' #end +
			(debug ? ' / Vram: ${getInterval(Std.int(FlxG.stage.context3D.totalGPUMemory / 1024 / 1024))}' : '');
			#end

			// if (ClientPrefs.showGPU)
			if (debug)
				text += '\nGPU: $gpuInfo\nObjects: ${FlxG.state.members.length}\nCameras: ${FlxG.cameras.list.length}\nSystem: $platform';

			if (ClientPrefs.showState || debug)
				text += '\nState: ${Type.getClassName(Type.getClass(FlxG.state))}' + '\nSubState: ${Type.getClassName(Type.getClass(FlxG.state.subState))}';

			if (text != null || text != '')
			{
				if (Main.fpsVar != null)
					Main.fpsVar.visible = true;
			}

			textColor = #if debug 0xFF00EAFF #else 0xFFFFFFFF #end;
			if (memoryMegas > 3000 || currentFPS <= ClientPrefs.framerate / 2)
				textColor = 0xFFFF0000;

			text += "\n";
		}

		cacheCount = currentCount;
		totalms = _ms;
	}

	public function setPosition(X:Float = 0, Y:Float = 0):Void
	{
		this.x = X;
		this.y = Y;
	}
}
