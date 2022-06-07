package;

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

	var stageSuffix:String = "";
	var TerminationText:FlxSprite;
	var killedByGAMEOVER:String = "idfk";
	var killedByTextDisplay:FlxText;
	var textGenerated:Bool = false;

	public static var characterName:String = 'bf';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static var instance:GameOverSubstate;

	public static function resetVariables()
	{
		characterName = 'bf';
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

	public function new(killedBy:String, x:Float, y:Float, camX:Float, camY:Float)
	{
		super();

		var red:FlxSprite = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.RED);
		red.alpha = 1;
		add(red);
		FlxTween.tween(red, {alpha: 0}, 0.3, {ease: FlxEase.linear});

		var luisOverlayShit:BGSprite = new BGSprite('luis/qt-fixes/vignette');
		luisOverlayShit.setGraphicSize(FlxG.width, FlxG.height);
		luisOverlayShit.screenCenter();
		luisOverlayShit.x += (FlxG.width / 2) - 60;
		luisOverlayShit.y += (FlxG.height / 2) - 20;
		luisOverlayShit.updateHitbox();
		FlxTween.tween(luisOverlayShit, {alpha: 0}, 0.5, {ease: FlxEase.linear});

		PlayState.instance.setOnLuas('inGameOver', true);

		Conductor.songPosition = 0;

		boyfriend = new Boyfriend(x, y, characterName);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);

		trace("Cause Of Death: ", killedBy);
		killedByGAMEOVER = killedBy;
		if (killedByGAMEOVER == "sawblade")
		{
			// For telling the player how to dodge in Termination.
			// I'm telling the player how to dodge after they've first died to the first saw blade to also communicate that sawblades aren't that healthy.
			// UPDATE - Tutorial text on TV screens now. This isn't necessary, but might as well reuse this for a custom "funny death" animation. -Haz
			TerminationText = new FlxSprite();
			TerminationText.frames = Paths.getSparrowAtlas('hazard/qt-port/sawkillanimation2');
			// TerminationText.animation.addByPrefix('normal', 'kb_attack_animation_kill_idle', 24, true);
			TerminationText.animation.addByIndices('normal', 'kb_attack_animation_kill_moving', [0], "", 24, false);
			TerminationText.animation.addByPrefix('animate', 'kb_attack_animation_kill_moving', 24, true);
			TerminationText.x = x - 1175; // negative = left
			TerminationText.y = y + 500; // positive = down
			TerminationText.antialiasing = ClientPrefs.globalAntialiasing;
			TerminationText.animation.play("normal");
			add(TerminationText);
		}

		camFollow = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);

		FlxG.sound.play(Paths.sound(deathSoundName));
		Conductor.changeBPM(100);
		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');

		var exclude:Array<Int> = [];

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);
		add(luisOverlayShit);
	}

	var isFollowingAlready:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.callOnLuas('onUpdate', [elapsed]);
		if (updateCamera)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.THISISFUCKINGDISGUSTINGPLEASESAVEME = false;

			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('qtMenu'));
			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
		}

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
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
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
		if (killedByGAMEOVER == "sawblade")
		{
			TerminationText.animation.play("animate");
		}
		FlxTween.tween(FlxG.camera, {zoom: 0.86}, 2.2, {ease: FlxEase.quadInOut}); // To ensure you can read the death text.
		displayDeathText(false);
	}

	function displayDeathText(instantAppear:Bool = false):Void
	{
		if (!textGenerated)
		{
			if (killedByGAMEOVER == "sawblade")
			{
				var dodgeKey:String = InputFormatter.getKeyName(ClientPrefs.keyBinds.get('qt_dodge')[0]);
				if (dodgeKey == "---")
				{
					// If for some reason the first input is blank, tries to grab the 2nd input.
					dodgeKey = InputFormatter.getKeyName(ClientPrefs.keyBinds.get('qt_dodge')[1]);
				}

				// trace("DodgeKey = ",dodgeKey);
				killedByTextDisplay = new FlxText(boyfriend.x - 48, boyfriend.y - 56, 0,
					("Died due to missing a sawblade. (Press " + dodgeKey + " to dodge!)"), 28);
				killedByTextDisplay.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER);
			}
			else if (killedByGAMEOVER == "hurt")
			{
				killedByTextDisplay = new FlxText(boyfriend.x, boyfriend.y - 56, 0, "Died to a hurt note. (Health)", 32);
				killedByTextDisplay.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
			}
			else if (killedByGAMEOVER == "reset")
			{
				killedByTextDisplay = new FlxText(boyfriend.x, boyfriend.y - 56, 0, "Reset button pressed.", 32);
				killedByTextDisplay.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
			}
			else
			{
				killedByTextDisplay = new FlxText(boyfriend.x, boyfriend.y - 56, 0, "Died to missing a note. (Health)", 32);
				killedByTextDisplay.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
			}
			textGenerated = true;

			if (!instantAppear)
			{
				killedByTextDisplay.alpha = 0;
				add(killedByTextDisplay);
				FlxTween.tween(killedByTextDisplay, {alpha: 1}, 1, {ease: FlxEase.sineOut});
			}
			else
			{
				add(killedByTextDisplay);
			}
		}
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			if (killedByGAMEOVER == "sawblade")
				TerminationText.animation.stop();
			displayDeathText(true);
			boyfriend.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
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
