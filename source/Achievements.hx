import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.FlxG;

using StringTools;
using lore.FlxSpriteTools;

class Achievements
{
	public static var achievementsStuff:Array<Dynamic> = [
		// Achievement save tag, Unlocks after, Hidden achievement
		// Set unlock after to "null" if it doesnt unlock after a week!!
		// Now the name and Description are on the lang.json
		['friday_night_play', null, true],
		['tutorial_hard', null, false],
		['tutorial_harder', null, true], // fuck you, qt fixes ported to 0.6.3
		['qtweek_hard', null, true],
		['termination_beat', null, false],
		['termination_old', null, false],
		['cessation_beat', null, false],
		['sawblade_death', null, false],
		['sawblade_hell', null, false],
		['taunter', null, false],
		['cessation_troll', null, true],
		['freeplay_depths', null, true],
		['ur_bad', null, false],
		['ur_good', null, false],
		['toastie', false]
	];
	public static var achievementsMap:Map<String, Bool> = new Map<String, Bool>();

	public static var sawbladeDeath:Int = 0;

	public static function unlockAchievement(tag:String):Void
	{
		FlxG.log.add('Completed achievement "' + tag + '"');
		achievementsMap.set(tag, true);
		FlxG.sound.play(Paths.sound('LuisAchievement', 'preload'));
	}

	public static function isAchievementUnlocked(tag:String)
	{
		if (achievementsMap.exists(tag) && achievementsMap.get(tag))
			return true;

		return false;
	}

	public static function getAchievementIndex(tag:String)
	{
		for (i in 0...achievementsStuff.length)
			if (achievementsStuff[i][0] == tag)
				return i;

		return -1;
	}

	public static function loadAchievements():Void
	{
		if (FlxG.save.data != null)
		{
			if (FlxG.save.data.achievementsMap != null)
				achievementsMap = FlxG.save.data.achievementsMap;

			if (sawbladeDeath == 0 && FlxG.save.data.sawbladeDeath != null)
				sawbladeDeath = FlxG.save.data.sawbladeDeath;
		}
	}
}

class AttachedAchievement extends FlxSprite
{
	public var sprTracker:FlxSprite;

	private var tag:String;

	public function new(x:Float = 0, y:Float = 0, name:String)
	{
		super(x, y);

		changeAchievement(name);
		antialiasing = ClientPrefs.antialiasing;
	}

	public function changeAchievement(tag:String)
	{
		this.tag = tag;
		reloadAchievementImage();
	}

	public function reloadAchievementImage()
	{
		if (Achievements.isAchievementUnlocked(tag))
			loadGraphic(Paths.image('achievements/' + tag));
		else
			loadGraphic(Paths.image('achievements/lockedachievement'));

		scale.set(0.7, 0.7);
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		if (sprTracker != null)
			setPosition(sprTracker.x - 130, sprTracker.y + 25);

		super.update(elapsed);
	}
}

class AchievementObject extends FlxSpriteGroup
{
	public var onFinish:Void->Void = null;

	var alphaTween:FlxTween;

	var textsize:Int = 20;

	public function new(name:String, ?camera:FlxCamera = null, sidesoffset:Float = 40)
	{
		super(x, y);
		ClientPrefs.saveSettings();

		var id:Int = Achievements.getAchievementIndex(name);
		var achievementBG:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('AchievementBG' /*, 'preload'*/));
		achievementBG.setGraphicSize(Std.int(achievementBG.width * 0.9));
		achievementBG.updateHitbox();
		achievementBG.antialiasing = ClientPrefs.antialiasing;
		achievementBG.x = sidesoffset;
		achievementBG.y = (ClientPrefs.downScroll && FunkinLua.hscript != null) ? FlxG.height - achievementBG.height - sidesoffset : sidesoffset;
		if (name == 'freeplay_depths' || name == 'cessation_beat')
			achievementBG.screenCenter();
		achievementBG.color = FlxColor.BLACK;
		FlxTween.color(achievementBG, 0.6, FlxColor.RED, achievementBG.color, {
			ease: FlxEase.quadInOut,
		});

		achievementBG.scrollFactor.set();
		add(achievementBG);

		var achievementIcon:FlxSprite = new FlxSprite(0, achievementBG.y + 70);
		var achievementIconAnimated:FlxSprite = new FlxSprite(0, achievementIcon.y);
		for (icon in [achievementIcon, achievementIconAnimated])
		{
			icon.loadGraphic(Paths.image('achievements/' + name));
			icon.scrollFactor.set();
			icon.setGraphicSize(Std.int(icon.width * 0.6));
			icon.updateHitbox();
			icon.centerOnSprite(achievementBG, X);
			icon.antialiasing = ClientPrefs.antialiasing;
		}
		achievementIconAnimated.visible = false;

		var achievementName:FlxText = new FlxText(0, achievementIcon.y + 100, 250, Locale.get("achievementname" + Achievements.achievementsStuff[id][0]),
			textsize);
		achievementName.centerOnSprite(achievementBG, X);
		achievementName.setFormat(Paths.font("vcr.ttf"), textsize, FlxColor.WHITE, CENTER);
		achievementName.scrollFactor.set();

		var achievementText:FlxText = new FlxText(0, 0, 290, Locale.get("achievementdesc" + Achievements.achievementsStuff[id][0]), textsize);
		achievementText.centerOnSprite(achievementBG, X);
		achievementText.setFormat(Paths.font("vcr.ttf"), textsize, FlxColor.WHITE, CENTER);
		achievementText.y = (achievementBG.y + achievementBG.height) - achievementText.height - 20;
		achievementText.scrollFactor.set();

		add(achievementName);
		add(achievementText);
		add(achievementIconAnimated);
		add(achievementIcon);

		@:privateAccess
		var cam:Array<FlxCamera> = FlxCamera._defaultCameras;
		if (camera != null)
			cam = [camera];

		alpha = 0;
		achievementBG.cameras = cam;
		achievementName.cameras = cam;
		achievementText.cameras = cam;
		achievementIconAnimated.cameras = cam;
		achievementIcon.cameras = cam;
		var alphaTween = FlxTween.tween(this, {alpha: 1}, 0.4, {
			onComplete: function(twn:FlxTween)
			{
				achievementIconAnimated.visible = true;
				var scale:Array<Float> = [achievementIconAnimated.scale.x, achievementIconAnimated.scale.x + 0.4]; // original scale, animated scale
				FlxTween.tween(achievementIconAnimated, {alpha: 0, "scale.x": scale[1], "scale.y": scale[1]}, 2, {
					onComplete: function(twn:FlxTween)
					{
						achievementIconAnimated.scale.set(scale[0], scale[0]);
						achievementIconAnimated.visible = false;
					}
				});
				alphaTween = FlxTween.tween(this, {alpha: 0}, 0.4, {
					startDelay: 2.5,
					onComplete: function(twn:FlxTween)
					{
						alphaTween = null;
						remove(this);
						if (onFinish != null)
							onFinish();
					}
				});
			}
		});
	}

	override function destroy()
	{
		if (alphaTween != null)
			alphaTween.cancel();

		super.destroy();
	}
}
