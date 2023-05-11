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

class MusicBeatState extends #if ZoroModchartingTools modcharting.ModchartMusicBeatState #else FlxUIState #end
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	public static var camBeat:FlxCamera;

	// public static var commitHash:String = getGitCommitHash();
	public static var multAnims:Bool = false; // animations multiplyed by Playstate's PlaybackRate
	public static var changedRes:Bool = false;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function destroy()
		super.destroy();

	public static function updatewindowres(?width:Int, ?height:Int):Void
	{
		#if desktop
		if (!FlxG.fullscreen)
		{
			var lastRes:Array<Int> = [Application.current.window.width, Application.current.window.height];
			var windowsPos:Array<Int> = [Application.current.window.x, Application.current.window.y];
			var res:Array<Int> = [
				width != null ? width : Std.parseInt(ClientPrefs.screenRes.split('x')[0]),
				height != null ? height : Std.parseInt(ClientPrefs.screenRes.split('x')[1])
			];
			FlxG.resizeWindow(res[0], res[1]);
			Application.current.window.move(Std.int(windowsPos[0] - (res[0] - lastRes[0]) / 2), Std.int(windowsPos[1] - (res[1] - lastRes[1]) / 2));
		}
		#end
	}

	public static function updatescreenratio()
	{
		#if desktop
		@:privateAccess {
			FlxG.width = 1280;
			FlxG.height = 720;
		}
		if (changedRes)
		{
			updatewindowres();
			changedRes = false;
		}
		if (!(FlxG.scaleMode is RatioScaleMode)) // just to be sure yk.
			FlxG.scaleMode = new RatioScaleMode();
		Application.current.window.borderless = false;
		#end
	}

	override function create()
	{
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;

		var mousecursor:FlxSprite = new FlxSprite().loadGraphic(Paths.image('Default/cursor'));
		FlxG.mouse.load(mousecursor.pixels);
		super.create();

		if (!skip)
			openSubState(new CustomFadeTransition(0.7, true));

		FlxTransitionableState.skipNextTransOut = false;
	}

	override function update(elapsed:Float)
	{
		// everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0)
				stepHit();

			if (PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if (FlxG.save.data != null)
			FlxG.save.data.fullscreen = FlxG.fullscreen;

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0)
			return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep)
					break;

				curSection++;
			}
		}

		if (curSection > lastSection)
			sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchStateStuff()
	{
		updatescreenratio();
		FlxG.mouse.visible = false;
		FlxG.cameras.bgColor = FlxColor.BLACK;
		multAnims = false;
		Main.fpsVar.setPosition(10, 3);
		setwindowproperties();
	}

	private static function setwindowproperties()
	{
		Application.current.window.title = Main.gameTitle;
		Application.current.window.setIcon(lime.utils.Assets.getImage('assets/art/iconOG.png'));
	}

	public static function justswitchState(nextState:FlxState)
	{
		switchStateStuff();
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		if (nextState == FlxG.state)
			FlxG.resetState();
		else
			FlxG.switchState(nextState);
		return nextState;
	}

	public static function switchState(nextState:FlxState, transitionToState:Bool = true)
	{
		// Custom made Trans in
		FlxTransitionableState.skipNextTransIn = false;
		FlxTransitionableState.skipNextTransOut = false;
		if (transitionToState)
		{
			var curState:Dynamic = FlxG.state;
			var leState:MusicBeatState = curState;
			if (!FlxTransitionableState.skipNextTransIn)
			{
				leState.openSubState(new CustomFadeTransition(0.6, false));
				CustomFadeTransition.finishCallback = function()
				{
					switchStateStuff();
					if (nextState == FlxG.state)
						FlxG.resetState();
					else
						FlxG.switchState(nextState);
				};
				return;
			}
		}
		if (nextState == FlxG.state)
			FlxG.resetState();
		else
			FlxG.switchState(nextState);
	}

	public static function resetState()
		MusicBeatState.switchState(FlxG.state);

	inline public static function getState():MusicBeatState
		return cast(FlxG.state, MusicBeatState);

	public function stepHit():Void
		if (curStep % 4 == 0)
			beatHit();

	public function beatHit():Void
	{
	}

	public function sectionHit():Void
	{
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
