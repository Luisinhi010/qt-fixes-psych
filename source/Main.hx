package;

import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
#if cpp import sys.io.File; #else import js.html.File; #end
// crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
#if sys
import sys.FileSystem;
import sys.io.Process;
#end
#end
using StringTools;

class Main extends Sprite
{
	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: InitLoader, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var gameTitle(get, null):String = '';

	static function get_gameTitle():String
	{
		if (gameTitle == '')
			gameTitle = Lib.application.meta["name"];

		return gameTitle;
	}

	public static var fpsVar:FPS;

	var flxGame:codename.FunkinGame;

	public static var __justcompiled:Bool = false; // useless but cool
	public static var __curBuild:Int;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
		Lib.current.addChild(new Main());

	public function new()
	{
		super();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		#if (flixel < "5.0.0")
		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}
		#end

		Application.current.window.title = gameTitle;
		Application.current.window.setIcon(lime.utils.Assets.getImage('assets/art/iconOG.png'));
		flxGame = new codename.FunkinGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate,
			game.skipSplash, game.startFullscreen);
		addChild(flxGame);

		#if sys
		if (__justcompiled = Sys.args().contains("-livereload")) // yoshi please dont kill me
		{
			var buildNum:Int = Std.parseInt(File.getContent("./../../../../buildnumber.txt"));
			buildNum++;
			File.saveContent("./../../../../buildnumber.txt", Std.string(buildNum));
			__curBuild = buildNum;
			Sys.println('Build Number: $__curBuild');
		}
		#end
		MusicBeatState.updatewindowres();

		#if !mobile
		fpsVar = new FPS(10, 3, 0xFFFFFF);
		fpsVar.alpha = 0.8;

		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if (fpsVar != null)
			fpsVar.visible = false;
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if desktop
		if (!DiscordClient.isInitialized)
		{
			DiscordClient.initialize();
			Application.current.window.onClose.add(function()
			{
				DiscordClient.shutdown();
			});
		}
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function(w, h)
		{
			if (FlxG.cameras != null)
			{
				for (cam in FlxG.cameras.list)
				{
					if (cam != null && cam.filters != null)
						resetSpriteCache(cam.flashSprite);
				}
			}

			if (FlxG.game != null)
				resetSpriteCache(FlxG.game);
		});
	}

	static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var errMsgPrint:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "PsychEngine_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
					errMsgPrint += file + ":" + line + "\n"; // if you Ctrl+Mouse Click its go to the line. -Luis
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: "
			+ e.error
			+ "\n Version: "
			+ MainMenuState.qtfixesVersion
			+ "\n Build: "
			+ __curBuild
			+ "\nPlease report this error to the GitHub page: https://github.com/Luisinhi010/qt-fixes-psych\n\n> Crash Handler written by: sqirra-rng";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsgPrint + '\n' + e.error);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		DiscordClient.shutdown();
		Sys.exit(1);
	}
	#end
}
