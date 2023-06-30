package hud;

import flixel.group.FlxGroup;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
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
class GameHUD extends FlxGroup
{
	// Locale ['Score: ', 'Misses: ', 'Rating: ', 'Combo Breaks: ', 'Accuracy: ']
	public var locale:Array<String> = [
		Locale.get("scoreHudText"),
		Locale.get("missesHudText"),
		Locale.get("ratingHudText"),
		Locale.get("missesKadeHudText"),
		Locale.get("ratingKadeHudText")
	];

	// health
	public var healthBarBG:AttachedFlxSprite;
	public var healthBar:FlxBar;
	public var health:Float = 1;
	public var healthBarFG:AttachedFlxSprite;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var coloredHealthBar:Bool;

	// timer
	public var timeBarBG:AttachedFlxSprite;
	public var timeBar:FlxBar;
	public var timeBarUi:String;
	public var updateTimePos:Bool = true;

	public var timeTxt:FlxText;
	public var songName:String = "";
	public var fucktimer(default, set):Bool = false;

	public function set_fucktimer(value:Bool):Bool
	{
		fucktimer = value;
		if (timeTxt != null)
		{
			if (value)
				timeTxt.text = (timeBarUi == 'Kade Engine') ? 'ERROR' : (timeBarUi == 'Psych Engine') ? '?:??' : '?:??'
					+ '  '
					+ "SYSTEM ERROR"
					+ '  '
					+ '?:??';
			else if (timeBarUi == 'Kade Engine')
				timeTxt.text = songName;
			timeTxt.screenCenter(X);
		}
		return value;
	}

	public var updateTime:Bool = false;
	public var songPercent:Float = 0;

	// score bla bla bla
	public var scoreTxt:FlxText;
	public var scoreTxtTween:FlxTween;
	public var kadescore(default, set):Bool = false;

	public function set_kadescore(value:Bool):Bool
	{
		kadescore = value;
		scoreTxt.size = value ? 16 : 20;
		updateScore();
		return value;
	}

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	var hudadded:Bool = false;

	public function new()
	{
		super();
		create();
	}

	function create():Void
	{
		if (!hudadded)
		{
			// set up the Time Bar
			songName = PlayState.SONG.song.replace("-", " ").replace("_", " ");
			coloredHealthBar = PlayState.instance.coloredHealthBar;
			timeBarUi = PlayState.instance.timeBarUi;
			sys.thread.Thread.create(() ->
			{
				var showTime:Bool = ClientPrefs.timeBar;
				timeTxt = new FlxText(0, ClientPrefs.downScroll ? FlxG.height - 40 : 10, 0, songName, 32);
				timeTxt.setFormat(Paths.font("vcr.ttf"), 32, PlayState.instance.inhumancolor1, CENTER, FlxTextBorderStyle.OUTLINE,
					PlayState.instance.inhumancolor2);
				timeTxt.scrollFactor.set();
				timeTxt.alpha = 0;
				timeTxt.borderSize = PlayState.instance.inhumanSong ? 2 : 1.5;
				timeTxt.visible = showTime;
				if (timeBarUi == 'Kade Engine')
				{
					timeTxt.y += ClientPrefs.downScroll ? 5 : -5;
					timeTxt.size = 18;
				}
				timeTxt.screenCenter(X);

				timeBarBG = new AttachedFlxSprite((timeBarUi == 'Kade Engine') ? 'healthBar' : 'timeBar');
				timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
				timeBarBG.scrollFactor.set();
				timeBarBG.alpha = 0;
				timeBarBG.visible = showTime;
				timeBarBG.color = FlxColor.BLACK;
				timeBarBG.xAdd = -4;
				timeBarBG.yAdd = -4;
				timeBarBG.screenCenter(X);

				timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4 - ((timeBarUi == 'Kade Engine') ? 5 : 0), LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8),
					Std.int(timeBarBG.height - 8), this, 'songPercent', 0, 1);
				timeBar.screenCenter(X);
				timeBar.scrollFactor.set();
				if (!ClientPrefs.lowQuality || !ClientPrefs.optimize)
					timeBar.numDivisions = 1000;
				timeBar.alpha = 0;
				timeBar.visible = showTime;
				timeBarBG.sprTracker = timeBar;

				add(timeBarBG);
				add(timeBar);
				add(timeTxt);

				updateTime = showTime;
			});

			// set up the Health Bar

			healthBarBG = new AttachedFlxSprite('healthBarNew');
			healthBarBG.y = FlxG.height * 0.89;
			healthBarBG.screenCenter(X);
			healthBarBG.scrollFactor.set();
			healthBarBG.visible = !PlayState.instance.cpuControlled;
			healthBarBG.xAdd = -4;
			healthBarBG.yAdd = -4;
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
			healthBarBG.sprTracker = healthBar;
			healthBarBG.copyVisible = true;

			healthBarFG = new AttachedFlxSprite('healthBar');
			healthBarFG.y = healthBarBG.y;
			healthBarFG.x = healthBarBG.x;
			healthBarFG.height = healthBarBG.height;
			healthBarFG.width = healthBarBG.width; // same position, height and width than healthBarBG
			healthBarFG.scrollFactor.set(healthBarBG.scrollFactor.x, healthBarBG.scrollFactor.y);
			healthBarFG.visible = healthBarBG.visible;
			healthBarFG.xAdd = -4;
			healthBarFG.yAdd = -4;
			healthBarFG.sprTracker = healthBar;
			healthBarFG.copyVisible = true;

			add(healthBarBG);
			add(healthBar);
			add(healthBarFG);

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
			}

			// set up Score
			scoreTxt = new FlxText(0, healthBarBG.y + healthBarBG.height + 36, FlxG.width, "", 20);
			scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, PlayState.instance.inhumancolor1, CENTER, FlxTextBorderStyle.OUTLINE,
				PlayState.instance.inhumancolor2);
			scoreTxt.scrollFactor.set();
			scoreTxt.borderSize = PlayState.instance.inhumanSong ? 1 : 1.5;
			scoreTxt.screenCenter(X);
			if (!PlayState.instance.forceMiddleScroll)
				scoreTxt.x += 140;
			scoreTxt.visible = !PlayState.instance.cpuControlled;
			add(scoreTxt);

			botplayTxt = new FlxText(FlxG.width - 250, (ClientPrefs.downScroll ? 120 : FlxG.height - 120), 0, "BOTPLAY", 20);
			botplayTxt.setFormat(Paths.font("vcr.ttf"), 42, PlayState.instance.inhumancolor1, RIGHT, FlxTextBorderStyle.OUTLINE,
				PlayState.instance.inhumancolor2);
			botplayTxt.scrollFactor.set();
			if (PlayState.instance.forceMiddleScroll)
				botplayTxt.screenCenter(X);
			botplayTxt.borderSize = PlayState.instance.inhumanSong ? 2 : 4;
			botplayTxt.borderQuality = 2;
			botplayTxt.visible = PlayState.instance.cpuControlled;
			add(botplayTxt);

			hudadded = true;
			set_fucktimer(fucktimer);
			reloadSongPosBarColors(fucktimer);
			reloadHealthBarColors(fucktimer);
			updateScore();
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (hudadded)
		{
			health = PlayState.instance.health;

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

				if (timeBarUi != 'Kade Engine' && !fucktimer)
					timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false)
						+ ((timeBarUi == 'Psych Engine') ? '' : '  ' + songName + '  ' + PlayState.instance.songLengthTxt);

				if (updateTimePos)
					timeTxt.screenCenter(X);
			}
		}
	}

	public var tempScore:String = "";
	public var scoreSeparator:String = ' | ';
	public var displayRatings:Bool = true;

	public function updateScore()
	{
		if (hudadded)
		{
			var songScore:Int = PlayState.instance.songScore;
			var songMisses:Int = PlayState.instance.songMisses;
			var ratingName:String = PlayState.instance.ratingName;
			var ratingPercent:Float = PlayState.instance.ratingPercent;
			var ratingFC:String = PlayState.instance.ratingFC;

			// of course I would go back and fix my code, of COURSE @BeastlyGhost;
			tempScore = locale[0] + songScore;
			var ratingString = '';

			if (kadescore)
			{
				if (displayRatings)
				{
					ratingString = scoreSeparator + locale[3] + songMisses + scoreSeparator + locale[4];

					if (ratingName != '?')
					{
						ratingString += ((Math.floor(ratingPercent * 10000) / 100)) + '%' + scoreSeparator;

						switch (ratingFC)
						{
							case 'SFC':
								ratingString += '(MFC) AAAA:';
							case 'GFC':
								ratingString += '(GFC) AAA:';
							case 'FC':
								ratingString += '(FC) AA:';
							default:
								ratingString += (songMisses < 10) ? '(SDCB) A:' : '(Clear) A:';
						}
					}
					else
						ratingString += '0%' + scoreSeparator + 'N/A';
				}
			}
			else if (displayRatings)
			{
				ratingString = scoreSeparator + locale[1] + songMisses;
				ratingString += scoreSeparator + locale[2] + ratingName;
				ratingString += (ratingName != '?' ? ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' : '');
				ratingString += (ratingFC != null && ratingFC != '' ? ' - ' + ratingFC : '');
			}

			tempScore += ratingString + '\n';
			scoreTxt.text = tempScore;
		}
	}

	public function reloadHealthBarColors(blue:Bool = false)
	{
		if (hudadded)
		{
			var dadHealthColorArray:Array<Int> = coloredHealthBar
				&& !ClientPrefs.optimize ? PlayState.instance.dad.healthColorArray : [255, 0, 0];
			var bfHealthColorArray:Array<Int> = coloredHealthBar
				&& !ClientPrefs.optimize ? PlayState.instance.boyfriend.healthColorArray : [102, 255, 51];

			var dadcolor:FlxColor = FlxColor.fromRGB(dadHealthColorArray[0], dadHealthColorArray[1], dadHealthColorArray[2]);
			var bfcolor:FlxColor = FlxColor.fromRGB(bfHealthColorArray[0], bfHealthColorArray[1], bfHealthColorArray[2]);

			if (blue && coloredHealthBar)
				healthBar.createGradientBar([FlxColor.CYAN, dadcolor, dadcolor], [FlxColor.CYAN, bfcolor, bfcolor], 1, 90);
			else
				healthBar.createFilledBar(dadcolor, bfcolor);

			healthBar.updateBar();
		}
	}

	public function reloadSongPosBarColors(blue:Bool = false)
	{
		if (hudadded)
		{
			var dadHealthColorArray:Array<Int> = coloredHealthBar
				&& !ClientPrefs.optimize ? PlayState.instance.dad.healthColorArray : [255, 0, 0];
			var bfHealthColorArray:Array<Int> = coloredHealthBar
				&& !ClientPrefs.optimize ? PlayState.instance.boyfriend.healthColorArray : [102, 255, 51];

			var dadcolor:FlxColor = FlxColor.fromRGB(dadHealthColorArray[0], dadHealthColorArray[1], dadHealthColorArray[2]);
			var bfcolor:FlxColor = FlxColor.fromRGB(bfHealthColorArray[0], bfHealthColorArray[1], bfHealthColorArray[2]);

			if (timeBarUi != 'Qt Fixes')
				timeBar.createFilledBar((timeBarUi == 'Kade Engine') ? FlxColor.GRAY : FlxColor.BLACK,
					(timeBarUi == 'Kade Engine') ? FlxColor.LIME : FlxColor.WHITE);
			else if (blue && !ClientPrefs.optimize)
				timeBar.createGradientBar([FlxColor.BLUE, dadcolor, bfcolor], [FlxColor.BLUE, FlxColor.BLUE, FlxColor.CYAN], 1, 90);
			else
				timeBar.createGradientBar([dadcolor, bfcolor], [0xFFFFFFFF, 0xFFFFFFFF, 0x88222222], 1, 90);

			timeBar.updateBar();
		}
	}

	// Code from the Lullaby mod. You should check it out if you haven't already.	=D
	public function reduceMaxHealth():Void
	{
		if (hudadded)
		{
			remove(healthBar);
			var newWidth:Int = Std.int(healthBarBG.width - 8) - Std.int(healthBar.width * (PlayState.instance.maxHealth / 2));
			healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, newWidth, Std.int(healthBarBG.height - 8), this, 'health',
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
	}

	public function beatHit()
	{
		if (!ClientPrefs.optimize && hudadded)
		{
			iconP1.scale.set(1.2, 1.2);
			iconP2.scale.set(1.2, 1.2);

			iconP1.updateHitbox();
			iconP2.updateHitbox();
		}
	}
}
