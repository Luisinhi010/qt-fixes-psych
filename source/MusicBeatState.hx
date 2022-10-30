package;

import flixel.system.scaleModes.RatioScaleMode;
import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxBasic;
import lime.app.Application;

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var controls(get, never):Controls;

	public static var camBeat:FlxCamera;

	// public static var commitHash:String = getGitCommitHash();
	public static var multAnims:Bool = false; // animations multiplyed by Playstate's PlaybackRate

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public static function getUsername()
	{
		#if sys
		if (ClientPrefs.usePlayerUsername)
		{
			var envs = Sys.environment();
			if (envs.exists("USERNAME"))
				return envs["USERNAME"];
			if (envs.exists("USER"))
				return envs["USER"];
		}
		#end
		return null;
	}

	public static function getUsernameOption()
	{
		#if sys
		if (getUsername() != null && ClientPrefs.usePlayerUsername && FlxG.save.data.usePlayerUsername != null)
			return true;
		#end
		return false;
	}

	/*public static function getGitCommitHash() // BeastlyGhost said to me to put this here. -Luis
		{
			#if sys
			var process:sys.io.Process = new sys.io.Process('git', ['rev-parse', 'HEAD']);

			var commitHash:String;

			try // read the output of the process
			{
				commitHash = process.stdout.readLine();
			}
			catch (e) // leave it as blank in the event of an error
			{
				commitHash = '';
			}
			var trimmedCommitHash:String = commitHash.substr(0, 7);

			// Generates a string expression
			return trimmedCommitHash;
			#end
			return '';
	}*/
	public static function getFramerate(Int:Int, multiply:Bool = false)
	{
		var frame:Int = 24;
		if (multAnims)
			frame = multiply ? Std.int(Int * PlayState.instance.playbackRate) : Std.int(Int / PlayState.instance.playbackRate);
		return frame;
	}

	public static function updatescreenratio()
	{
		#if !mobile
		@:privateAccess
		FlxG.width = 1280;
		@:privateAccess
		FlxG.height = 720;
		@:privateAccess
		if (!(FlxG.scaleMode is RatioScaleMode)) // just to be sure yk.
			FlxG.scaleMode = new RatioScaleMode();
		Application.current.window.borderless = false;
		#end
	}

	override function create()
	{
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		if (!skip)
			openSubState(new CustomFadeTransition(0.7, true));

		FlxTransitionableState.skipNextTransOut = false;
	}

	#if (VIDEOS_ALLOWED && windows)
	override public function onFocus():Void
	{
		FlxVideo.onFocus();
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		FlxVideo.onFocusLost();
		super.onFocusLost();
	}
	#end

	override function update(elapsed:Float)
	{
		// everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		if (FlxG.save.data != null)
			FlxG.save.data.fullscreen = FlxG.fullscreen;

		super.update(elapsed);
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor(((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / Conductor.stepCrochet);
	}

	public static function switchStateStuff(nextState:FlxState) // yes, this is a mess. -Luis
	{
		updatescreenratio();
		FlxG.cameras.bgColor = FlxColor.BLACK; // since someone called Luis decided to make the fucking playstate's bg dynamic on qt's stages, he needed to put this here.
		multAnims = false;
		Main.fpsVar.setPosition(10, 3);
		Application.current.window.title = Main.gameTitle;
		Application.current.window.setIcon(lime.utils.Assets.getImage('assets/art/iconOG.png'));
	}

	public static function justswitchState(nextState:FlxState) // without the custom transition
	{
		switchStateStuff(nextState);
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		if (nextState == FlxG.state)
			FlxG.resetState();
		else
			FlxG.switchState(nextState);
		return nextState;
	}

	public static function switchState(nextState:FlxState)
	{
		// Custom made Trans in
		FlxTransitionableState.skipNextTransIn = false;
		FlxTransitionableState.skipNextTransOut = false;
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if (!FlxTransitionableState.skipNextTransIn)
		{
			leState.openSubState(new CustomFadeTransition(0.6, false));
			if (nextState == FlxG.state)
			{
				CustomFadeTransition.finishCallback = function()
				{
					switchStateStuff(nextState);
					FlxG.resetState();
				};
			}
			else
			{
				CustomFadeTransition.finishCallback = function()
				{
					switchStateStuff(nextState);
					FlxG.switchState(nextState);
				};
			}
			return;
		}
		FlxG.switchState(nextState);
	}

	public static function resetState()
		MusicBeatState.switchState(FlxG.state);

	public static function getState():MusicBeatState
	{
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function stepHit():Void
		if (curStep % 4 == 0)
			beatHit();

	public function beatHit():Void
	{
	}
}
