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

using StringTools;

/**
*	usually this class would be way more simple in terms of the contents of it
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

	public var scoreTxt:FlxText;
	public var scoreTxtTween:FlxTween;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public static var instance:GameHUD;

	public function new()
	{
		super();

		instance = this;

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