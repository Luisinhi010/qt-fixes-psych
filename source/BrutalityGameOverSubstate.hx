package;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxCamera;
import flixel.FlxSprite;

using StringTools;

// PORTED FROM INHUMAN LMAOOOO
class BrutalityGameOverSubstate extends MusicBeatSubstate
{
	public var deathTexts:Map<String, String> = [
		'sawblade' => Locale.get("sawbladeDeath"),
		'hurt' => Locale.get("hurtDeath"),
		'reset' => Locale.get("resetDeath"),
		'default' => Locale.get("defaultDeath")
	];

	public static var characterName:String = 'amelia';

	public static var deathSoundName:String = 'hazard/inhuman_loss_sfx';
	public static var loopSoundName:String = 'inhuman_gameOver';
	public static var endSoundName:String = 'inhuman_gameOverEnd';

	var retry:FlxSprite;
	var connection:FlxSprite;
	var hazardNoise:FlxSprite;
	var noiseFading:Bool = false;
	var musicplaying:Bool = false;
	var hazardInterlopeLaugh:FlxSprite; // Used by Amelia in Interlope when taunting player
	var screenScanBar:BGSprite; // idfk what this is called

	public static var instance:BrutalityGameOverSubstate;

	public static function resetVariables()
	{
		characterName = 'amelia';
		deathSoundName = 'hazard/inhuman_loss_sfx';
		loopSoundName = 'inhuman_gameOver';
		endSoundName = 'inhuman_gameOverEnd';
	}

	var killedByGAMEOVER:String = "idfk";
	var killedByTextDisplay:FlxText;
	var textGenerated:Bool = false;
	var scoreTxt:FlxText;

	override function create()
	{
		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);

		super.create();
	}

	public function new(killedBy:String)
	{
		musicplaying = false;

		trace("Killed by: ", killedBy);
		trace("Character: ", characterName);

		PlayState.instance.setOnLuas('inGameOver', true);
		super();

		Conductor.songPosition = 0;
		for (i in FlxG.cameras.list)
			if (i != null)
				FlxTween.cancelTweensOf(i);
		FlxG.cameras.reset();

		if ((!ClientPrefs.lowQuality || !ClientPrefs.optimize) && FlxG.random.bool(28))
		{ // 28% chance of Amelia laughing in the gameover screen.
			hazardInterlopeLaugh = new FlxSprite();
			hazardInterlopeLaugh.frames = Paths.getSparrowAtlas('hazard/inhuman-port/ameliaTaunt');
			hazardInterlopeLaugh.animation.addByPrefix('laugh1', 'Amelia_Chuckle', 24, true);
			hazardInterlopeLaugh.antialiasing = ClientPrefs.globalAntialiasing;
			hazardInterlopeLaugh.setGraphicSize(Std.int(hazardInterlopeLaugh.width * 0.7));
			hazardInterlopeLaugh.screenCenter();
			hazardInterlopeLaugh.y += 200;
			hazardInterlopeLaugh.animation.play("laugh1");
			hazardInterlopeLaugh.alpha = 0.55;
			add(hazardInterlopeLaugh);
		}

		connection = new FlxSprite();
		connection.frames = Paths.getSparrowAtlas('hazard/inhuman-port/gameOver/connection');
		connection.animation.addByPrefix('retry', "gameover-lost-retry", 24, true);
		connection.animation.addByPrefix('idle', "gameover-lost-loop", 24, true);
		connection.screenCenter();
		connection.y -= 140;
		connection.antialiasing = ClientPrefs.globalAntialiasing;
		add(connection);
		connection.animation.play('idle');

		retry = new FlxSprite();
		retry.frames = Paths.getSparrowAtlas('hazard/inhuman-port/gameOver/retry');
		retry.animation.addByPrefix('empty', "gameover-retry-introEMPTY.png", 24, true);
		retry.animation.addByPrefix('start', "gameover-retry-start", 4, false);
		retry.animation.addByPrefix('idle', "gameover-retry-loop", 1, true);
		retry.setGraphicSize(Std.int(retry.width * 0.375));
		retry.screenCenter();
		retry.x -= 150;
		retry.y += 200;
		retry.antialiasing = ClientPrefs.globalAntialiasing;
		add(retry);
		retry.alpha = 0;
		retry.animation.play('empty');

		killedByGAMEOVER = killedBy;
		displayDeathText(false);

		scoreTxt = new FlxText(0, FlxG.height, FlxG.width, PlayState.instance.gameHUD.scoreTxt.text, 24);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.RED, CENTER, FlxTextBorderStyle.NONE, FlxColor.RED);
		scoreTxt.y -= scoreTxt.height + 5;
		scoreTxt.alpha = 0.8;
		scoreTxt.scrollFactor.set();
		scoreTxt.screenCenter(X);
		scoreTxt.updateHitbox();
		scoreTxt.visible = !PlayState.instance.cpuControlled;
		add(scoreTxt);

		if (!ClientPrefs.lowQuality || !ClientPrefs.optimize)
		{
			screenScanBar = new BGSprite(null, -FlxG.width, -FlxG.height, 0, 0);
			screenScanBar.makeGraphic(Std.int(FlxG.width * 3), 20, FlxColor.GRAY);
			screenScanBar.alpha = 0.06;
			screenScanBar.y = -40;
			add(screenScanBar);
		}

		hazardNoise = new FlxSprite();
		hazardNoise.frames = Paths.getSparrowAtlas('hazard/inhuman-port/noise');
		hazardNoise.animation.addByPrefix('idle', 'noise', 48, true);
		hazardNoise.antialiasing = ClientPrefs.globalAntialiasing;
		hazardNoise.setGraphicSize(Std.int(hazardNoise.width * 3.4));
		hazardNoise.screenCenter();
		hazardNoise.x += 235;
		hazardNoise.y += 235;
		hazardNoise.alpha = 1;
		hazardNoise.animation.play("idle");
		add(hazardNoise);

		FlxG.sound.play(Paths.sound(deathSoundName));
		Conductor.changeBPM(115);

		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			FlxG.sound.playMusic(Paths.music(loopSoundName), 0);
			musicplaying = true;
		});
	}

	function displayDeathText(instantAppear:Bool = false):Void
	{
		if (!textGenerated)
		{
			var deathMessage:String = deathTexts.get(deathTexts.exists(killedByGAMEOVER) ? killedByGAMEOVER : 'default').replace('$', '');
			killedByTextDisplay = new FlxText(0, 0, 0, deathMessage, 32);
			killedByTextDisplay.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.RED, CENTER, FlxTextBorderStyle.NONE, FlxColor.RED);
			killedByTextDisplay.screenCenter();
			killedByTextDisplay.scrollFactor.set();
			add(killedByTextDisplay);
			if (instantAppear)
				killedByTextDisplay.alpha = 0.8;
			else
			{
				killedByTextDisplay.alpha = 0;
				FlxTween.tween(killedByTextDisplay, {alpha: 0.8}, 1.5, {ease: FlxEase.sineOut, startDelay: 1.5});
			}
			textGenerated = true;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (musicplaying && FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.25 * FlxG.elapsed;
		}

		if (!ClientPrefs.lowQuality)
		{
			screenScanBar.y += 70 * elapsed;
			if (screenScanBar.y > FlxG.width / 1.75)
				screenScanBar.y = -50;
		}

		PlayState.instance.callOnLuas('onUpdate', [elapsed]);

		if (!noiseFading)
		{
			noiseFading = true;
			new FlxTimer().start(0.795, function(tmr:FlxTimer)
			{
				FlxTween.tween(hazardNoise, {alpha: 0}, 1.25, {ease: FlxEase.quadOut});
			});

			new FlxTimer().start(0.96, function(tmr:FlxTimer)
			{
				if (hazardInterlopeLaugh != null)
					FlxTween.tween(hazardInterlopeLaugh, {alpha: 0}, 1.36, {ease: FlxEase.quadOut});

				retry.animation.play('start');
				retry.alpha = 0.8;
			});
		}

		if (retry.animation.curAnim.name == 'start' && retry.animation.curAnim.finished)
			retry.animation.play('idle');

		if (controls.ACCEPT)
			endBullshit();

		if (controls.BACK)
		{
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.THISISFUCKINGDISGUSTINGPLEASESAVEME = false;

			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new MainMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
		}

		if (FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;

		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			connection.animation.play('retry');
			if (ClientPrefs.flashing)
				flixel.effects.FlxFlicker.flicker(connection, 2.7, 0.20, true);
			FlxTween.tween(retry, {alpha: 0}, .7, {
				ease: FlxEase.cubeInOut,
				onComplete: function(twn:FlxTween)
				{
					remove(retry);
				}
			});
			displayDeathText(true);
			isEnding = true;
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					MusicBeatState.resetState();
				});
			});
			PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
		}
	}
}
