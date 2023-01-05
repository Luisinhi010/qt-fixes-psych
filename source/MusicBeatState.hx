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
#if mobile
import mobile.MobileControls;
import mobile.flixel.FlxVirtualPad;
import flixel.FlxCamera;
import flixel.input.actions.FlxActionInput;
import flixel.util.FlxDestroyUtil;
#end

class MusicBeatState extends FlxUIState
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

	#if mobile
	var mobileControls:MobileControls;
	var virtualPad:FlxVirtualPad;
	var trackedInputsMobileControls:Array<FlxActionInput> = [];
	var trackedInputsVirtualPad:Array<FlxActionInput> = [];

	public function addVirtualPad(DPad:FlxDPadMode, Action:FlxActionMode)
	{
		if (virtualPad != null)
			removeVirtualPad();

		virtualPad = new FlxVirtualPad(DPad, Action);
		add(virtualPad);

		controls.setVirtualPadUI(virtualPad, DPad, Action);
		trackedInputsVirtualPad = controls.trackedInputsUI;
		controls.trackedInputsUI = [];
	}

	public function removeVirtualPad()
	{
		if (trackedInputsVirtualPad != [])
			controls.removeVirtualControlsInput(trackedInputsVirtualPad);

		if (virtualPad != null)
			remove(virtualPad);
	}

	public function addMobileControls(DefaultDrawTarget:Bool = true)
	{
		if (mobileControls != null)
			removeMobileControls();

		mobileControls = new MobileControls();

		switch (MobileControls.mode)
		{
			case 'Pad-Right' | 'Pad-Left' | 'Pad-Custom':
				controls.setVirtualPadNOTES(mobileControls.virtualPad, RIGHT_FULL, NONE);
			case 'Pad-Duo':
				controls.setVirtualPadNOTES(mobileControls.virtualPad, BOTH_FULL, NONE);
			case 'Hitbox':
				controls.setHitBox(mobileControls.hitbox);
			case 'Keyboard': // do nothing
		}

		trackedInputsMobileControls = controls.trackedInputsNOTES;
		controls.trackedInputsNOTES = [];

		var camControls:FlxCamera = new FlxCamera();
		FlxG.cameras.add(camControls, DefaultDrawTarget);
		camControls.bgColor.alpha = 0;

		mobileControls.cameras = [camControls];
		mobileControls.visible = false;
		add(mobileControls);
	}

	public function removeMobileControls()
	{
		if (trackedInputsMobileControls != [])
			controls.removeVirtualControlsInput(trackedInputsMobileControls);

		if (mobileControls != null)
			remove(mobileControls);
	}

	public function addVirtualPadCamera(DefaultDrawTarget:Bool = true)
	{
		if (virtualPad != null)
		{
			var camControls:FlxCamera = new FlxCamera();
			FlxG.cameras.add(camControls, DefaultDrawTarget);
			camControls.bgColor.alpha = 0;
			virtualPad.cameras = [camControls];
		}
	}
	#end

	override function destroy()
	{
		#if mobile
		if (trackedInputsMobileControls != [])
			controls.removeVirtualControlsInput(trackedInputsMobileControls);

		if (trackedInputsVirtualPad != [])
			controls.removeVirtualControlsInput(trackedInputsVirtualPad);
		#end

		super.destroy();

		#if mobile
		if (virtualPad != null)
		{
			virtualPad = FlxDestroyUtil.destroy(virtualPad);
			virtualPad = null;
		}

		if (mobileControls != null)
		{
			mobileControls = FlxDestroyUtil.destroy(mobileControls);
			mobileControls = null;
		}
		#end
	}

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
		var frame:Int = Int;
		if (multAnims)
			frame = multiply ? Std.int(Int * PlayState.instance.playbackRate) : Std.int(Int / PlayState.instance.playbackRate);
		return frame;
	}

	public static function updatewindowres(?width:Int, ?height:Int)
	{
		#if desktop
		if (!FlxG.fullscreen)
		{
			var lastres:Array<Int> = [Application.current.window.width, Application.current.window.height];
			var windowspos:Array<Int> = [Application.current.window.x, Application.current.window.y];
			var res:Array<Int> = [
				Std.parseInt(ClientPrefs.screenRes.split('x')[0]),
				Std.parseInt(ClientPrefs.screenRes.split('x')[1])
			];
			if (width != null)
				res[0] = width;
			if (height != null)
				res[1] = height;
			FlxG.resizeWindow(res[0], res[1]);
			Application.current.window.move(Std.int(windowspos[0] - (res[0] - lastres[0]) / 2), Std.int(windowspos[1] - (res[1] - lastres[1]) / 2));
		}
		#end
		// this is the most stupid code i ever done -Luis
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
