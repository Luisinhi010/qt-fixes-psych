package hud;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import flixel.util.FlxStringUtil;

using StringTools;

/**
 *	usually this class would be way more simple when it comes to objects
 *	but due to this mod being a literal giant in terms of content, I had to make it
 *	the way it currently is, while also transferring some PlayState stuff to here aside from the
 *	actual hud -BeastlyGhost
**/
class GameHUD extends FlxTypedGroup<FlxBasic>
{
	// health
	public var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	public var health:Float = 1;
	public var healthBarFG:AttachedSprite;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	// timer
	public var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;
	public var songNameTxt:FlxText;
	public var songName:String = "";
	public var fucktimer(default, set):Bool = false;

	function set_fucktimer(value:Bool):Bool
	{
		fucktimer = value;
		if (value = true && songNameTxt != null)
			songNameTxt.text = "?:??" + '  ' + "SYSTEM ERROR" + '  ' + "?:??";
		return value;
	}

	public var updateTime:Bool = true;
	public var songPercent:Float = 0;

	// score bla bla bla
	public var scoreTxt:FlxText;
	public var scoreTxtTween:FlxTween;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public static var instance:GameHUD;

	public function new()
	{
		super();

		instance = this;

		// set up the Time Bar
		songName = PlayState.SONG.song.replace("-", " ").replace("_", " ");

		var showTime:Bool = ClientPrefs.timeBar;

		songNameTxt = new FlxText(0, ClientPrefs.downScroll ? FlxG.height - 40 : 10, 0, songName, 32);
		songNameTxt.setFormat(Paths.font("vcr.ttf"), 32, PlayState.instance.inhumancolor1, CENTER, FlxTextBorderStyle.OUTLINE,
			PlayState.instance.inhumancolor2);
		songNameTxt.scrollFactor.set();
		songNameTxt.alpha = 0;
		songNameTxt.borderSize = PlayState.instance.inhumanSong ? 2 : 1.5;
		songNameTxt.visible = showTime;
		songNameTxt.screenCenter(X);

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.y = songNameTxt.y + (songNameTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.screenCenter(X);
		timeBar.scrollFactor.set();
		reloadSongPosBarColors(fucktimer);
		if (!ClientPrefs.lowQuality || !ClientPrefs.optimize)
			timeBar.numDivisions = 1000;
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		timeBarBG.sprTracker = timeBar;

		add(timeBarBG);
		add(timeBar);
		add(songNameTxt);

		updateTime = showTime;

		// set up the Health Bar

		healthBarBG = new AttachedSprite('healthBarNew');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !PlayState.instance.cpuControlled;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if (ClientPrefs.downScroll)
			healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		if (!ClientPrefs.downScroll)
			healthBar.y += 18;
		if (!ClientPrefs.lowQuality || !ClientPrefs.optimize)
			healthBar.numDivisions = 800;

		healthBar.scrollFactor.set();
		healthBar.visible = !PlayState.instance.cpuControlled;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;
		healthBarBG.copyVisible = true;

		healthBarFG = new AttachedSprite('healthBar');
		healthBarFG.y = healthBarBG.y;
		healthBarFG.x = healthBarBG.x;
		healthBarFG.height = healthBarBG.height;
		healthBarFG.width = healthBarBG.width; // same position, height and width than healthBarBG
		healthBarFG.scrollFactor.set(healthBarBG.scrollFactor.x, healthBarBG.scrollFactor.y);
		healthBarFG.visible = healthBarBG.visible;
		healthBarFG.xAdd = -4;
		healthBarFG.yAdd = -4;
		add(healthBarFG);
		healthBarFG.sprTracker = healthBar;
		healthBarFG.copyVisible = true;

		if (!ClientPrefs.optimize)
		{
			iconP1 = new HealthIcon(PlayState.instance.boyfriend.healthIcon, true);
			iconP1.y = healthBar.y - 75;
			iconP1.visible = !PlayState.instance.cpuControlled;
			iconP1.alpha = ClientPrefs.healthBarAlpha;
			add(iconP1);

			iconP2 = new HealthIcon(PlayState.instance.dad.healthIcon, false);
			iconP2.y = healthBar.y - 75;
			iconP2.visible = !PlayState.instance.cpuControlled;
			iconP2.alpha = ClientPrefs.healthBarAlpha;
			add(iconP2);
			// lime.app.Application.current.window.setIcon(iconP2.pixels.image);
		}
		reloadHealthBarColors(fucktimer);

		// set up Score

		var xPos:Int = ClientPrefs.downScroll ? 10 : FlxG.height - 45;

		scoreTxt = new FlxText(0, !PlayState.instance.inhumanSong ? healthBarBG.y + 36 : xPos - 5, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, PlayState.instance.inhumancolor1, CENTER, FlxTextBorderStyle.OUTLINE, PlayState.instance.inhumancolor2);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = PlayState.instance.inhumanSong ? 1 : 1.5;
		if (!PlayState.instance.inhumanSong)
			scoreTxt.y += ClientPrefs.downScroll ? 10 : -110;
		scoreTxt.screenCenter(X);
		if (!PlayState.instance.forceMiddleScroll)
			scoreTxt.x += 140;
		scoreTxt.visible = !PlayState.instance.cpuControlled;
		add(scoreTxt);

		if (PlayState.instance.inhumanSong)
		{
			healthBar.angle = 90;
			healthBar.x = FlxG.width - healthBar.height;
			healthBar.screenCenter(Y);
			if (!ClientPrefs.optimize)
			{
				iconP1.visible = false;
				iconP2.visible = false;
			}
		}

		botplayTxt = new FlxText(FlxG.width - 250, (ClientPrefs.downScroll ? 120 : FlxG.height - 120), 0, "BOTPLAY", 20);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 42, PlayState.instance.inhumancolor1, RIGHT, FlxTextBorderStyle.OUTLINE, PlayState.instance.inhumancolor2);
		botplayTxt.scrollFactor.set();
		if (PlayState.instance.forceMiddleScroll)
			botplayTxt.screenCenter(X);
		botplayTxt.borderSize = PlayState.instance.inhumanSong ? 2 : 4;
		botplayTxt.borderQuality = 2;
		botplayTxt.visible = PlayState.instance.cpuControlled;
		add(botplayTxt);

		updateScore();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		health = (Math.abs(health - PlayState.instance.health) < .1)
			&& healthBar.visible ? PlayState.instance.health : FlxMath.lerp(health, PlayState.instance.health,
				CoolUtil.boundTo(1 - (elapsed * 2 * PlayState.instance.playbackRate), 0, 1)); // kinda inspired by andromeda smooth health bar

		if (!ClientPrefs.optimize)
		{
			var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * PlayState.instance.playbackRate), 0, 1));
			iconP1.scale.set(mult, mult);
			iconP1.updateHitbox();

			var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * PlayState.instance.playbackRate), 0, 1));
			iconP2.scale.set(mult, mult);
			iconP2.updateHitbox();

			var iconOffset:Int = 26;
			iconP1.x = healthBar.x
				+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
				+ (150 * iconP1.scale.x - 150) / 2
				- iconOffset;
			iconP2.x = healthBar.x
				+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
				- (150 * iconP2.scale.x) / 2
				- iconOffset * 2;

			if (healthBar.percent < 20)
				iconP1.animation.curAnim.curFrame = 1;
			else if (healthBar.percent > 80 && iconP1.hasWinning)
				iconP1.animation.curAnim.curFrame = 2;
			else
				iconP1.animation.curAnim.curFrame = 0;

			if (healthBar.percent > 80)
				iconP2.animation.curAnim.curFrame = 1;
			else if (healthBar.percent < 20 && iconP2.hasWinning)
				iconP2.animation.curAnim.curFrame = 2;
			else
				iconP2.animation.curAnim.curFrame = 0;
		}

		if (botplayTxt.visible)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (updateTime)
		{
			var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
			var secondsTotal:Int = Math.floor(curTime / 1000);
			if (curTime < 0)
				curTime = 0;

			songPercent = (curTime / PlayState.instance.songLength);

			if (secondsTotal < 0)
				secondsTotal = 0;

			if (!fucktimer)
				songNameTxt.text = FlxStringUtil.formatTime(secondsTotal, false) + '  ' + songName + '  ' + PlayState.instance.songLengthTxt;

			songNameTxt.screenCenter(X);
		}
	}

	public var tempScore:String = "";
	public var scoreSeparator:String = ' | ';
	public var displayRatings:Bool = true;

	public function updateScore()
	{
		var songScore:Int = PlayState.instance.songScore;
		var songMisses:Int = PlayState.instance.songMisses;
		var ratingName:String = PlayState.instance.ratingName;
		var ratingPercent:Float = PlayState.instance.ratingPercent;
		var ratingFC:String = PlayState.instance.ratingFC;

		// of course I would go back and fix my code, of COURSE @BeastlyGhost;
		tempScore = "Score: " + songScore;

		if (displayRatings)
		{
			tempScore += scoreSeparator + "Misses: " + songMisses;
			tempScore += scoreSeparator + "Rating: " + ratingName;
			tempScore += (ratingName != '?' ? ' (${Highscore.floorDecimal(ratingPercent * 100, 2)}%)' : '');
			tempScore += (ratingFC != null && ratingFC != '' ? ' - $ratingFC' : '');
		}
		tempScore += '\n';

		scoreTxt.text = tempScore;
	}

	public function reloadHealthBarColors(blue:Bool = false)
	{
		var dadcolor:FlxColor = 0xFFFF0000;
		var bfcolor:FlxColor = 0xFF66FF33;

		if (ClientPrefs.coloredHealthBar && !ClientPrefs.optimize)
		{
			dadcolor = FlxColor.fromRGB(PlayState.instance.dad.healthColorArray[0], PlayState.instance.dad.healthColorArray[1],
				PlayState.instance.dad.healthColorArray[2]);

			bfcolor = FlxColor.fromRGB(PlayState.instance.boyfriend.healthColorArray[0], PlayState.instance.boyfriend.healthColorArray[1],
				PlayState.instance.boyfriend.healthColorArray[2]);
		}
		if (blue && !ClientPrefs.optimize)
			healthBar.createGradientBar([FlxColor.CYAN, dadcolor, dadcolor], [FlxColor.CYAN, bfcolor, bfcolor], 1, 90);
		else
			healthBar.createFilledBar(dadcolor, bfcolor);

		healthBar.updateBar();
	}

	public function reloadSongPosBarColors(blue:Bool = false)
	{
		var dadcolor:FlxColor = 0xFFFF0000;
		var bfcolor:FlxColor = 0xFF66FF33;

		if (ClientPrefs.coloredHealthBar && !ClientPrefs.optimize)
		{
			dadcolor = FlxColor.fromRGB(PlayState.instance.dad.healthColorArray[0], PlayState.instance.dad.healthColorArray[1],
				PlayState.instance.dad.healthColorArray[2]);

			bfcolor = FlxColor.fromRGB(PlayState.instance.boyfriend.healthColorArray[0], PlayState.instance.boyfriend.healthColorArray[1],
				PlayState.instance.boyfriend.healthColorArray[2]);
		}

		if (blue && !ClientPrefs.optimize)
			timeBar.createGradientBar([FlxColor.BLUE, dadcolor, bfcolor], [FlxColor.BLUE, FlxColor.BLUE, FlxColor.CYAN], 1, 90);
		else
			timeBar.createGradientBar([dadcolor, bfcolor], [0xFFFFFFFF, 0xFFFFFFFF, 0x88222222], 1, 90);

		timeBar.updateBar();
	}

	// Code from the Lullaby mod. You should check it out if you haven't already.	=D
	public function reduceMaxHealth():Void
	{
		remove(healthBar);
		healthBar = new FlxBar(healthBarBG.x
			+ 4, healthBarBG.y
			+ 4, RIGHT_TO_LEFT,
			Std.int(healthBarBG.width - 8)
			- Std.int(healthBar.width * (PlayState.instance.maxHealth / 2)), Std.int(healthBarBG.height - 8), this, 'health',
			PlayState.instance.maxHealth, 2);
		healthBar.scrollFactor.set();
		healthBar.visible = !PlayState.instance.cpuControlled;
		remove(healthBarFG);
		if (!ClientPrefs.optimize)
		{
			remove(iconP1);
			remove(iconP2);
		}
		add(healthBar);
		add(healthBarFG);
		if (!ClientPrefs.optimize)
		{
			add(iconP1);
			add(iconP2);
		}
		reloadHealthBarColors(fucktimer);
	}

	public function beatHit()
	{
		if (!ClientPrefs.optimize)
		{
			iconP1.scale.set(1.2, 1.2);
			iconP2.scale.set(1.2, 1.2);

			iconP1.updateHitbox();
			iconP2.updateHitbox();
		}
	}
}
