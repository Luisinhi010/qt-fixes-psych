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
import flixel.FlxBasic;

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var controls(get, never):Controls;

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
		if (MusicBeatState.getUsername() != null && ClientPrefs.usePlayerUsername && FlxG.save.data.usePlayerUsername != null)
			return true;
		#end
		return false;
	}

	public static function updatescreenratio()
	{
		#if !android
		@:privateAccess
		FlxG.width = 1280;
		@:privateAccess
		FlxG.height = 720;
		#end
		FlxG.scaleMode = new RatioScaleMode();
	}

	override function create()
	{
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		if (!skip)
		{
			openSubState(new CustomFadeTransition(0.7, true));
		}
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

	public static function justswitchState(nextState:FlxState) // without the custom transition
	{
		Main.initialState = Type.getClass(nextState);
		FlxG.switchState(nextState);
		updatescreenratio();
		return;
	}

	public static function switchState(nextState:FlxState)
	{
		// Custom made Trans in
		Main.initialState = Type.getClass(nextState);
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		updatescreenratio();
		if (!FlxTransitionableState.skipNextTransIn)
		{
			leState.openSubState(new CustomFadeTransition(0.6, false));
			if (nextState == FlxG.state)
			{
				CustomFadeTransition.finishCallback = function()
				{
					FlxG.resetState();
				};
				// trace('resetted');
			}
			else
			{
				CustomFadeTransition.finishCallback = function()
				{
					FlxG.switchState(nextState);
				};
				// trace('changed state');
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	var loadedCompletely:Bool = false;

	public function load()
	{
		loadedCompletely = true;

		trace("State loaded!");
	}

	public static function resetState()
	{
		MusicBeatState.switchState(FlxG.state);
	}

	public static function getState():MusicBeatState
	{
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// do literally nothing dumbass
	}
}
