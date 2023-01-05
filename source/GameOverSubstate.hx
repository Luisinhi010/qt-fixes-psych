package;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flash.text.TextField;

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Boyfriend;

	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;

	var stageSuffix:String = "";
	var TerminationText:FlxSprite;
	var killedByGAMEOVER:String = "idfk";
	var killedByTextDisplay:FlxText;
	var textGenerated:Bool = false;
	var songSpeed:Float = 1;

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static var instance:GameOverSubstate;

	public var groupSprite:FlxTypedGroup<FlxSprite>;

	public static function resetVariables()
	{
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
	}

	override function create()
	{
		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);
		textGenerated = false;
		super.create();
	}

	public function new(killedBy:String, x:Float, y:Float, camX:Float, camY:Float, songSpeed:Float = 1)
	{
		super();
		this.songSpeed = songSpeed;

		groupSprite = new FlxTypedGroup<FlxSprite>();
		add(groupSprite);

		var red:FlxSprite = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.RED);
		red.alpha = 1;
		groupSprite.add(red);
		FlxTween.tween(red, {alpha: 0}, 0.3, {ease: FlxEase.linear});

		var luisOverlayShit:BGSprite = new BGSprite('luis/qt-fixes/vignette');
		if (!ClientPrefs.optimize)
		{
			luisOverlayShit.setGraphicSize(FlxG.width, FlxG.height);
			luisOverlayShit.screenCenter();
			luisOverlayShit.x += (FlxG.width / 2) - 60;
			luisOverlayShit.y += (FlxG.height / 2) - 20;
			luisOverlayShit.updateHitbox();
			if (FlxG.camera.zoom < 1)
				luisOverlayShit.scale.scale(1 / FlxG.camera.zoom);

			FlxTween.tween(luisOverlayShit, {alpha: 0}, 0.5, {ease: FlxEase.linear});
		}

		PlayState.instance.setOnLuas('inGameOver', true);

		Conductor.songPosition = 0;

		if (!ClientPrefs.optimize)
		{
			boyfriend = new Boyfriend(x, y, characterName);
			boyfriend.x += boyfriend.positionArray[0];
			boyfriend.y += boyfriend.positionArray[1];
			groupSprite.add(boyfriend);
		}

		trace("Cause Of Death: ", killedBy);
		killedByGAMEOVER = killedBy;
		if (killedByGAMEOVER == "sawblade" && !ClientPrefs.optimize)
		{
			// For telling the player how to dodge in Termination.
			// I'm telling the player how to dodge after they've first died to the first saw blade to also communicate that sawblades aren't that healthy.
			// UPDATE - Tutorial text on TV screens now. This isn't necessary, but might as well reuse this for a custom "funny death" animation. -Haz
			TerminationText = new FlxSprite();
			TerminationText.frames = Paths.getSparrowAtlas('hazard/qt-port/sawkillanimation2');
			TerminationText.animation.addByIndices('normal', 'kb_attack_animation_kill_moving', [0], "", 24, false);
			TerminationText.animation.addByPrefix('animate', 'kb_attack_animation_kill_moving', 24, true);
			TerminationText.x = x - 1175; // negative = left
			TerminationText.y = y + 500; // positive = down
			TerminationText.antialiasing = ClientPrefs.globalAntialiasing;
			TerminationText.animation.play("normal");
			groupSprite.add(TerminationText);
			#if ACHIEVEMENTS_ALLOWED
			if (Achievements.sawbladeDeath >= 24 && !Achievements.isAchievementUnlocked('sawblade_death'))
			{
				var achievementObj:Achievements.AchievementObject = null;
				achievementObj = new Achievements.AchievementObject('sawblade_death');
				Achievements.achievementsMap.set('sawblade_death', true);
				FlxG.sound.play(Paths.sound('hazard/attack', 'shared'), 0.4);
				achievementObj.scrollFactor.set();
				achievementObj.updateHitbox();
				achievementObj.setPosition(achievementObj.x / FlxG.camera.zoom, achievementObj.y / FlxG.camera.zoom);
				add(achievementObj);
				FlxG.save.flush();
				ClientPrefs.saveSettings();
			}
			#end
		}

		camFollow = new FlxPoint(ClientPrefs.optimize ? x : boyfriend.getGraphicMidpoint().x, ClientPrefs.optimize ? y : boyfriend.getGraphicMidpoint().y);

		if (ClientPrefs.optimize)
			FlxG.sound.play(Paths.sound(deathSoundName), 1, false, null, true, coolStartDeath.bind()).pitch = songSpeed;
		else
			FlxG.sound.play(Paths.sound(deathSoundName), 1).pitch = songSpeed;

		Conductor.changeBPM(100);
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		if (!ClientPrefs.optimize)
			boyfriend.playAnim('firstDeath');

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);
		if (!ClientPrefs.optimize)
			groupSprite.add(luisOverlayShit);
	}

	var isFollowingAlready:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.callOnLuas('onUpdate', [elapsed]);
		if (updateCamera && !ClientPrefs.optimize)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (controls.ACCEPT)
			endBullshit();

		if (controls.BACK)
		{
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;
			PlayState.THISISFUCKINGDISGUSTINGPLEASESAVEME = false;

			WeekData.loadTheFirstEnabledMod();
			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
		}

		if (!ClientPrefs.optimize && boyfriend != null)
			if (boyfriend.animation.curAnim.name == 'firstDeath')
			{
				if (boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
				{
					FlxG.camera.follow(camFollowPos, LOCKON, 1);
					updateCamera = true;
					isFollowingAlready = true;
				}

				if (boyfriend.animation.curAnim.finished)
				{
					coolStartDeath();
					boyfriend.startedDeath = true;
				}
			}

		if (FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;

		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}

	override function beatHit()
	{
		super.beatHit();

		// FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.music(loopSoundName), volume);
		FlxG.sound.music.pitch = songSpeed;
		if (killedByGAMEOVER == "sawblade" && !ClientPrefs.optimize)
			TerminationText.animation.play("animate");

		FlxTween.tween(FlxG.camera, {zoom: 0.86}, 2.2, {ease: FlxEase.quadInOut}); // To ensure you can read the death text.
		displayDeathText(false);
	}

	function displayDeathText(instantAppear:Bool = false):Void
	{
		var xy:Array<Float> = [ClientPrefs.optimize ? 0 : boyfriend.x, ClientPrefs.optimize ? 0 : boyfriend.y];
		if (!textGenerated)
		{
			if (killedByGAMEOVER == "sawblade")
			{
				var dodgeKey:String = ClientPrefs.getkeys('qt_dodge');

				killedByTextDisplay = new FlxText(xy[0] - 130, xy[1] - 56, 0, ("Died due to missing a sawblade. (Press $" + dodgeKey + "$ to dodge!)"), 28);
				killedByTextDisplay.applyMarkup("Died due to missing a sawblade. (Press $" + dodgeKey + "$ to dodge!)",
					[new FlxTextFormatMarkerPair(new FlxTextFormat(FlxColor.RED), "$")]);
				killedByTextDisplay.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER);
			}
			else if (killedByGAMEOVER == "hurt")
			{
				killedByTextDisplay = new FlxText(xy[0], xy[1] - 56, 0, "Died to a hurt note. (Health)", 32);
				killedByTextDisplay.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
			}
			else if (killedByGAMEOVER == "reset")
			{
				killedByTextDisplay = new FlxText(xy[0], xy[1] - 56, 0, "Reset button pressed.", 32);
				killedByTextDisplay.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
			}
			else
			{
				killedByTextDisplay = new FlxText(xy[0], xy[1] - 56, 0, "Died to missing a note. (Health)", 32);
				killedByTextDisplay.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
			}
			textGenerated = true;

			if (!instantAppear)
			{
				killedByTextDisplay.alpha = 0;
				groupSprite.add(killedByTextDisplay);
				FlxTween.tween(killedByTextDisplay, {alpha: 1}, 1, {ease: FlxEase.sineOut});
			}
			else
				groupSprite.add(killedByTextDisplay);

			if (ClientPrefs.optimize)
			{
				killedByTextDisplay.screenCenter();
				killedByTextDisplay.scrollFactor.set();
			}
		}
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			if (killedByGAMEOVER == "sawblade" && !ClientPrefs.optimize)
				TerminationText.animation.stop();
			displayDeathText(true);
			if (!ClientPrefs.optimize)
				boyfriend.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName), 1).pitch = songSpeed;
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
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
