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
	public var healthBarFG:AttachedSprite;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	public var songNameTxt:FlxText;
	public var timeleftTxt:FlxText;
	public var timesongTxt:FlxText;
	public var fucktimer:Bool = false;
	public var updateTime:Bool = true;
	public var songPercent:Float = 0;

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

		var showTime:Bool = ClientPrefs.timeBar;

		songNameTxt = new FlxText(0, 10, 400, StringTools.replace(PlayState.SONG.song, "-", " "), 24);
		songNameTxt.setFormat(Paths.font("vcr.ttf"), 32, PlayState.instance.inhumancolor1, CENTER, FlxTextBorderStyle.OUTLINE, PlayState.instance.inhumancolor2);
		songNameTxt.scrollFactor.set();
		songNameTxt.alpha = 0;
		songNameTxt.borderSize = PlayState.instance.inhumanSong ? 2 : 1.5;
		songNameTxt.visible = showTime;
		if (ClientPrefs.downScroll)
			songNameTxt.y = FlxG.height - 40;
		songNameTxt.screenCenter(X);

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = songNameTxt.x;
		timeBarBG.y = songNameTxt.y + (songNameTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		reloadSongPosBarColors(PlayState.instance.qtIsBlueScreened);
		if (!ClientPrefs.lowQuality)
			timeBar.numDivisions = 1000;
		// if low quality will be 100
		// else will be 1000
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		timeBarBG.sprTracker = timeBar;

		timeleftTxt = new FlxText(timeBar.x + 260, songNameTxt.y, 400, "", 32);
		timeleftTxt.setFormat(Paths.font("vcr.ttf"), 32, PlayState.instance.inhumancolor1, CENTER, FlxTextBorderStyle.OUTLINE, PlayState.instance.inhumancolor2);
		timeleftTxt.scrollFactor.set();
		timeleftTxt.alpha = 0;
		timeleftTxt.borderSize = PlayState.instance.inhumanSong ? 2 : 1.5;
		timeleftTxt.visible = showTime;

		timesongTxt = new FlxText(timeBar.x - 260, songNameTxt.y, 400, "", 32);
		timesongTxt.setFormat(Paths.font("vcr.ttf"), 32, PlayState.instance.inhumancolor1, CENTER, FlxTextBorderStyle.OUTLINE, PlayState.instance.inhumancolor2);
		timesongTxt.scrollFactor.set();
		timesongTxt.alpha = 0;
		timesongTxt.borderSize = PlayState.instance.inhumanSong ? 2 : 1.5;
		timesongTxt.visible = showTime;

		add(timeBarBG);
		add(timeBar);
		add(songNameTxt);
		add(timeleftTxt);
		add(timesongTxt);

		updateTime = showTime;

		// set up the Health Bar

		healthBarBG = new AttachedSprite('healthBarNew');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if (ClientPrefs.downScroll)
			healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		if (!ClientPrefs.downScroll)
			healthBar.y += 18;
		if (!ClientPrefs.lowQuality)
			healthBar.numDivisions = 800;

		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		healthBarFG = new AttachedSprite('healthBar');
		healthBarFG.y = healthBarBG.y;
		healthBarFG.x = healthBarBG.x;
		healthBarFG.height = healthBarBG.height;
		healthBarFG.width = healthBarBG.width; // same position, height and width than healthBarBG
		healthBarFG.scrollFactor.set();
		healthBarFG.visible = !ClientPrefs.hideHud;
		healthBarFG.xAdd = -4;
		healthBarFG.yAdd = -4;
		add(healthBarFG);
		healthBarFG.sprTracker = healthBar;

		iconP1 = new HealthIcon(PlayState.instance.boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(PlayState.instance.dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors(PlayState.instance.qtIsBlueScreened);

		// set up Score

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 26);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, PlayState.instance.inhumancolor1, CENTER, FlxTextBorderStyle.OUTLINE, PlayState.instance.inhumancolor2);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = PlayState.instance.inhumanSong ? 1 : 1.5;
		scoreTxt.y += ClientPrefs.downScroll ? 10 : -110;
		scoreTxt.screenCenter(X);
		if (!PlayState.instance.forceMiddleScroll)
			scoreTxt.x += 140;
		scoreTxt.visible = !PlayState.instance.cpuControlled;
		if (ClientPrefs.hideHud)
			scoreTxt.alpha = 0; // sorry
		add(scoreTxt); // new scoreTxt code

		botplayTxt = new FlxText(FlxG.width - 250, healthBarBG.y + (FlxG.save.data.downscroll ? 120 : -120), 0, "BOTPLAY", 20);
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

		healthBar.percent = (PlayState.instance.health * 50);

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
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
		else
			iconP1.animation.curAnim.curFrame = 0;
		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

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

			if (fucktimer)
				timesongTxt.text = FlxG.random.int(0, 9) + ":" + FlxG.random.int(0, 99);
			else
				timesongTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
		}

		updateScore();
	}

	public function updateScore()
	{
		var score = PlayState.instance.songScore;
		var misses = PlayState.instance.songMisses;
		var rating = PlayState.instance.ratingName;

		if (PlayState.instance.ratingName == '?')
			scoreTxt.text = 'Score: ' + score + ' | Misses: ' + misses + ' | Rating: ?';
		else
			scoreTxt.text = 'Score: ' + score + ' | Misses: ' + misses + ' | Rating: ' + rating + ' ('
				+ Highscore.floorDecimal(PlayState.instance.ratingPercent * 100, 2) + '%)' + ' - ' + PlayState.instance.ratingFC; // peeps wanted no integer rating
	}

	public function reloadHealthBarColors(blue:Bool = false)
	{
		var dadcolor:FlxColor = FlxColor.fromRGB(PlayState.instance.dad.healthColorArray[0], PlayState.instance.dad.healthColorArray[1], PlayState.instance.dad.healthColorArray[2]);
		var bfcolor:FlxColor = FlxColor.fromRGB(PlayState.instance.boyfriend.healthColorArray[0], PlayState.instance.boyfriend.healthColorArray[1], PlayState.instance.boyfriend.healthColorArray[2]);
		if (blue)
			healthBar.createGradientBar([FlxColor.BLUE, dadcolor, dadcolor], [FlxColor.BLUE, bfcolor, bfcolor], 1, 90);
		else
			healthBar.createFilledBar(dadcolor, bfcolor);

		healthBar.updateBar();
	}

	public function reloadSongPosBarColors(blue:Bool = false)
	{
		// timeBar.createFilledBar(FlxColor.BLUE, FlxColor.BLUE);
		if (blue)
			timeBar.createGradientBar([FlxColor.BLUE], [FlxColor.BLUE, FlxColor.BLUE, FlxColor.CYAN], 1, 90);
		else
			timeBar.createGradientBar([0xFF000000], [0xFFFFFFFF, 0xFFFFFFFF, 0x88222222], 1, 90);
	}

	// Code from the Lullaby mod. You should check it out if you haven't already.	=D
	public function reduceMaxHealth():Void
	{
		remove(healthBar);
		healthBar = new FlxBar(healthBarBG.x
			+ 4, healthBarBG.y
			+ 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8)
			- Std.int(healthBar.width * (PlayState.instance.maxHealth / 2)),
			Std.int(healthBarBG.height - 8), this, 'health', PlayState.instance.maxHealth, 2);
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.hideHud;
		remove(healthBarFG);
		remove(iconP1);
		remove(iconP2);
		add(healthBar);
		add(healthBarFG);
		add(iconP1);
		add(iconP2);
		reloadHealthBarColors(PlayState.instance.qtIsBlueScreened);
	}

	public function beatHit()
	{
		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();
	}
}