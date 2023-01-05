package;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

class ClientPrefs
{
	public static var qtOldVocals:Bool = false; // Here because some people (such as myself) prefer the old vocals from the original mod.
	public static var qtSkipCutscene:Bool = false; // Because the cutscene caused problems in the original mod. This is here in case it causes problems still.
	public static var qtBonk:Bool = false; // Switches the sawblade sound back to the original placeholder I was using because the Bonk is fucking hilarious.
	public static var hurtNoteAlpha:Float = 0.6; // Hurt notes transparency. Useful to allow your brain to focus on the more opaque, non-hurt notes.
	public static var charactershaders:Bool = true;
	public static var gpurendering:Bool = false;
	public static var precache:Bool = false;
	public static var persistentCaching:Bool = false;

	public static var camMove:Bool = true; // Camera Movement
	#if sys
	public static var usePlayerUsername:Bool = false;
	#end
	public static var laneunderlay:Bool = false;
	public static var laneunderlayAlpha:Float = 0.5;

	public static var optimize:Bool = false; // Pr: https://github.com/ShadowMario/FNF-PsychEngine/pull/10532
	public static var colorblindFilter:String = "OFF";
	public static var inputSystem:String = 'Psych';
	public static var verticalHealthBar:String = 'Disabled';

	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var opponentStrums:Bool = true;
	#if !mobile
	public static var showFPS:Bool = true;
	public static var showMEM:Bool = true; // Show Mem Pr: https://github.com/ShadowMario/FNF-PsychEngine/pull/9554/
	public static var showState:Bool = false;
	#end
	#if desktop
	public static var autoPause:Bool = true; // Pr: https://github.com/ShadowMario/FNF-PsychEngine/pull/4622/
	#end
	public static var flashing:Bool = true;
	public static var globalAntialiasing:Bool = true;
	public static var noteSplashes:Bool = true;
	public static var lowQuality:Bool = false;
	public static var shaders:Bool = true;
	public static var framerate:Int = 60;
	public static var cursing:Bool = true;
	public static var violence:Bool = true;
	public static var camZooms:Bool = true;
	public static var noteOffset:Int = 0;
	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	public static var ghostTapping:Bool = true;
	public static var timeBar:Bool = true;
	public static var scoreZoom:Bool = true;
	public static var noReset:Bool = false;
	public static var healthBarAlpha:Float = 1;
	public static var controllerMode:Bool = false;
	#if desktop
	public static var screenRes:String = '1280x720'; // Pr: https://github.com/ShadowMario/FNF-PsychEngine/pull/5163
	public static var fullscreen:Bool = false;
	#end
	public static var coloredHealthBar:Bool = true; // Pr: https://github.com/ShadowMario/FNF-PsychEngine/pull/10550/
	public static var hitsoundVolume:Float = 0;
	public static var pauseMusic:String = 'Tea Time';
	public static var comboStacking = true;
	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];

	public static var comboOffset:Array<Int> = [0, 0, 0, 0];
	public static var ratingOffset:Int = 0;
	public static var sickWindow:Int = 45;
	public static var goodWindow:Int = 90;
	public static var badWindow:Int = 135;
	public static var safeFrames:Float = 10;

	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		// Key Bind, Name for ControlsSubState
		'note_left' => [A, LEFT],
		'note_down' => [S, DOWN],
		'note_up' => [W, UP],
		'note_right' => [D, RIGHT],
		'qt_dodge' => [SPACE, NONE],
		'qt_taunt' => [SHIFT, NONE],
		'ui_left' => [A, LEFT],
		'ui_down' => [S, DOWN],
		'ui_up' => [W, UP],
		'ui_right' => [D, RIGHT],
		'accept' => [SPACE, ENTER],
		'back' => [BACKSPACE, ESCAPE],
		'pause' => [ENTER, ESCAPE],
		'reset' => [R, NONE],
		'volume_mute' => [ZERO, NONE],
		'volume_up' => [NUMPADPLUS, PLUS],
		'volume_down' => [NUMPADMINUS, MINUS],
		'debug_1' => [SEVEN, NONE],
		'debug_2' => [EIGHT, NONE]
	];

	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static function loadDefaultKeys()
		defaultKeys = keyBinds.copy();

	public static function saveSettings()
	{
		FlxG.save.data.qtOldVocals = qtOldVocals;
		FlxG.save.data.qtSkipCutscene = qtSkipCutscene;
		FlxG.save.data.qtBonk = qtBonk;
		FlxG.save.data.hurtNoteAlpha = hurtNoteAlpha;
		FlxG.save.data.shaders = shaders;
		FlxG.save.data.charactershaders = charactershaders;
		#if desktop
		FlxG.save.data.gpurendering = gpurendering;
		FlxG.save.data.precache = precache;
		#end
		FlxG.save.data.persistentCaching = persistentCaching;

		FlxG.save.data.camMove = camMove;
		#if sys
		FlxG.save.data.usePlayerUsername = usePlayerUsername;
		#end
		FlxG.save.data.laneunderlay = laneunderlay;
		FlxG.save.data.laneunderlayAlpha = laneunderlayAlpha;

		FlxG.save.data.optimize = optimize;
		FlxG.save.data.downScroll = downScroll;
		FlxG.save.data.colorblindFilter = colorblindFilter;
		FlxG.save.data.inputSystem = inputSystem;
		FlxG.save.data.verticalHealthBar = verticalHealthBar;

		FlxG.save.data.middleScroll = middleScroll;
		FlxG.save.data.opponentStrums = opponentStrums;
		#if !mobile
		FlxG.save.data.showFPS = showFPS;
		FlxG.save.data.showMEM = showMEM;
		FlxG.save.data.showState = showState;
		#end
		#if desktop
		FlxG.save.data.autoPause = autoPause;
		#end
		FlxG.save.data.flashing = flashing;
		FlxG.save.data.globalAntialiasing = globalAntialiasing;
		FlxG.save.data.noteSplashes = noteSplashes;
		FlxG.save.data.lowQuality = lowQuality;
		FlxG.save.data.shaders = shaders;
		FlxG.save.data.framerate = framerate;
		// FlxG.save.data.cursing = cursing;
		// FlxG.save.data.violence = violence;
		FlxG.save.data.camZooms = camZooms;
		FlxG.save.data.noteOffset = noteOffset;
		FlxG.save.data.arrowHSV = arrowHSV;
		FlxG.save.data.ghostTapping = ghostTapping;
		FlxG.save.data.timeBar = timeBar;
		FlxG.save.data.scoreZoom = scoreZoom;
		FlxG.save.data.noReset = noReset;
		FlxG.save.data.healthBarAlpha = healthBarAlpha;
		FlxG.save.data.comboOffset = comboOffset;
		FlxG.save.data.achievementsMap = Achievements.achievementsMap;
		FlxG.save.data.sawbladeDeath = Achievements.sawbladeDeath;

		FlxG.save.data.ratingOffset = ratingOffset;
		FlxG.save.data.sickWindow = sickWindow;
		FlxG.save.data.goodWindow = goodWindow;
		FlxG.save.data.badWindow = badWindow;
		FlxG.save.data.safeFrames = safeFrames;
		FlxG.save.data.gameplaySettings = gameplaySettings;
		FlxG.save.data.controllerMode = controllerMode;
		#if desktop
		FlxG.save.data.screenRes = screenRes;
		FlxG.save.data.fullscreen = fullscreen;
		#end
		FlxG.save.data.coloredHealthBar = coloredHealthBar;
		FlxG.save.data.hitsoundVolume = hitsoundVolume;
		FlxG.save.data.pauseMusic = pauseMusic;
		FlxG.save.data.comboStacking = comboStacking;

		FlxG.save.flush();

		var save:FlxSave = new FlxSave();
		save.bind('Qt_controls'
			#if (flixel < "5.0.0"), 'Luis' #end); // Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		save.data.customControls = keyBinds;
		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs()
	{
		if (FlxG.save.data.qtOldVocals != null)
			qtOldVocals = FlxG.save.data.qtOldVocals;

		if (FlxG.save.data.qtSkipCutscene != null)
			qtSkipCutscene = FlxG.save.data.qtSkipCutscene;

		if (FlxG.save.data.qtBonk != null)
			qtBonk = FlxG.save.data.qtBonk;

		if (FlxG.save.data.hurtNoteAlpha != null)
			hurtNoteAlpha = FlxG.save.data.hurtNoteAlpha;

		if (FlxG.save.data.shaders != null)
			shaders = FlxG.save.data.shaders;

		if (FlxG.save.data.charactershaders != null)
			charactershaders = FlxG.save.data.charactershaders;

		#if desktop
		if (FlxG.save.data.gpurendering != null)
			gpurendering = FlxG.save.data.gpurendering;
		if (FlxG.save.data.precache != null)
			precache = FlxG.save.data.precache;
		#end
		if (FlxG.save.data.persistentCaching != null)
			persistentCaching = FlxG.save.data.persistentCaching;

		if (FlxG.save.data.camMove != null)
			camMove = FlxG.save.data.camMove;

		#if sys
		if (FlxG.save.data.usePlayerUsername != null)
			usePlayerUsername = FlxG.save.data.usePlayerUsername;
		#end

		if (FlxG.save.data.laneunderlay != null)
			laneunderlay = FlxG.save.data.laneunderlay;

		if (FlxG.save.data.laneunderlayAlpha != null)
			laneunderlayAlpha = FlxG.save.data.laneunderlayAlpha;

		if (FlxG.save.data.optimize != null)
			optimize = FlxG.save.data.optimize;

		if (FlxG.save.data.colorblindFilter != null)
			colorblindFilter = FlxG.save.data.colorblindFilter;

		if (FlxG.save.data.inputSystem != null)
			inputSystem = FlxG.save.data.inputSystem;

		if (FlxG.save.data.verticalHealthBar != null)
			verticalHealthBar = FlxG.save.data.verticalHealthBar;

		if (FlxG.save.data.downScroll != null)
			downScroll = FlxG.save.data.downScroll;

		if (FlxG.save.data.middleScroll != null)
			middleScroll = FlxG.save.data.middleScroll;

		if (FlxG.save.data.opponentStrums != null)
			opponentStrums = FlxG.save.data.opponentStrums;

		#if !mobile
		if (FlxG.save.data.showFPS != null)
		{
			showFPS = FlxG.save.data.showFPS;
			if (Main.fpsVar != null)
				Main.fpsVar.visible = showFPS;
		}
		if (FlxG.save.data.showMEM != null)
		{
			showMEM = FlxG.save.data.showMEM;
			if (Main.fpsVar != null)
				Main.fpsVar.visible = showMEM;
		}
		if (FlxG.save.data.showState != null)
			showState = FlxG.save.data.showState;
		#end

		#if desktop
		if (FlxG.save.data.autoPause != null)
			autoPause = FlxG.save.data.autoPause;
		#end
		if (FlxG.save.data.flashing != null)
			flashing = FlxG.save.data.flashing;

		if (FlxG.save.data.globalAntialiasing != null)
			globalAntialiasing = FlxG.save.data.globalAntialiasing;

		if (FlxG.save.data.noteSplashes != null)
			noteSplashes = FlxG.save.data.noteSplashes;

		if (FlxG.save.data.lowQuality != null)
			lowQuality = FlxG.save.data.lowQuality;

		if (FlxG.save.data.shaders != null)
			shaders = FlxG.save.data.shaders;

		if (FlxG.save.data.framerate != null)
		{
			framerate = FlxG.save.data.framerate;
			if (framerate > FlxG.drawFramerate)
			{
				FlxG.updateFramerate = framerate;
				FlxG.drawFramerate = framerate;
			}
			else
			{
				FlxG.drawFramerate = framerate;
				FlxG.updateFramerate = framerate;
			}
		}
		if (FlxG.save.data.camZooms != null)
			camZooms = FlxG.save.data.camZooms;

		if (FlxG.save.data.noteOffset != null)
			noteOffset = FlxG.save.data.noteOffset;

		if (FlxG.save.data.arrowHSV != null)
			arrowHSV = FlxG.save.data.arrowHSV;

		if (FlxG.save.data.ghostTapping != null)
			ghostTapping = FlxG.save.data.ghostTapping;

		if (FlxG.save.data.timeBar != null)
			timeBar = FlxG.save.data.timeBar;

		if (FlxG.save.data.scoreZoom != null)
			scoreZoom = FlxG.save.data.scoreZoom;

		if (FlxG.save.data.noReset != null)
			noReset = FlxG.save.data.noReset;

		if (FlxG.save.data.healthBarAlpha != null)
			healthBarAlpha = FlxG.save.data.healthBarAlpha;

		if (FlxG.save.data.comboOffset != null)
			comboOffset = FlxG.save.data.comboOffset;

		if (FlxG.save.data.ratingOffset != null)
			ratingOffset = FlxG.save.data.ratingOffset;

		if (FlxG.save.data.sickWindow != null)
			sickWindow = FlxG.save.data.sickWindow;

		if (FlxG.save.data.goodWindow != null)
			goodWindow = FlxG.save.data.goodWindow;

		if (FlxG.save.data.badWindow != null)
			badWindow = FlxG.save.data.badWindow;

		if (FlxG.save.data.safeFrames != null)
			safeFrames = FlxG.save.data.safeFrames;

		if (FlxG.save.data.controllerMode != null)
			controllerMode = FlxG.save.data.controllerMode;

		#if desktop
		if (FlxG.save.data.screenRes != null)
			screenRes = FlxG.save.data.screenRes;

		if (FlxG.save.data.fullscreen != null)
		{
			fullscreen = FlxG.save.data.fullscreen;
			FlxG.fullscreen = fullscreen;
		}
		#end

		if (FlxG.save.data.hitsoundVolume != null)
			hitsoundVolume = FlxG.save.data.hitsoundVolume;

		if (FlxG.save.data.pauseMusic != null)
			pauseMusic = FlxG.save.data.pauseMusic;

		if (FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
				gameplaySettings.set(name, value);
		}

		// flixel automatically saves your volume!
		if (FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;

		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;

		if (FlxG.save.data.coloredHealthBar != null)
			coloredHealthBar = FlxG.save.data.coloredHealthBar;

		if (FlxG.save.data.comboStacking != null)
			comboStacking = FlxG.save.data.comboStacking;

		var save:FlxSave = new FlxSave();
		save.bind('Qt_controls' #if (flixel < "5.0.0"), 'Luis' #end);
		if (save != null && save.data.customControls != null)
		{
			var loadedControls:Map<String, Array<FlxKey>> = save.data.customControls;
			for (control => keys in loadedControls)
				keyBinds.set(control, keys);

			reloadControls();
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic
	{
		return /*PlayState.isStoryMode ? defaultValue : */ (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}

	public static function getkeys(keyname:String) // for lazyness
	{
		var keys:Array<String> = [];
		for (i in 0...2)
		{
			var dodgeKey:String = InputFormatter.getKeyName(keyBinds.get(keyname)[i]);
			keys[i] = dodgeKey;
		}
		return keys[0] == '---' ? keys[1] : keys[1] == '---' ? keys[0] : keys[0] + ' or ' + keys[1];
	}

	public static function reloadControls()
	{
		PlayerSettings.player1.controls.setKeyboardScheme(KeyboardScheme.Solo);

		muteKeys = copyKey(keyBinds.get('volume_mute'));
		volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		volumeUpKeys = copyKey(keyBinds.get('volume_up'));
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
	}

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}

	public static var loadedSettings:Bool = false;

	public static function loadSettings()
	{
		if (!loadedSettings)
		{
			loadDefaultKeys();
			FlxG.game.focusLostFramerate = 60;
			FlxG.sound.muteKeys = muteKeys;
			FlxG.sound.volumeDownKeys = volumeDownKeys;
			FlxG.sound.volumeUpKeys = volumeUpKeys;
			FlxG.keys.preventDefaultKeys = [TAB];
			PlayerSettings.init();
			FlxG.save.bind('funkin', 'Luis');
			loadPrefs();
			Highscore.load();
			if (FlxG.save.data.weekCompleted != null)
				StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
			loadedSettings = true;
		}
	}
}
