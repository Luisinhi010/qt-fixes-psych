import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.FlxG;

using StringTools;

class Achievements
{
	public static var achievementsStuff:Array<Dynamic> = [
		// Name, Description, Achievement save tag, Unlocks after, Hidden achievement
		// Set unlock after to "null" if it doesnt unlock after a week!!
		[
			"Freaky on a Friday Night",
			"Play on a Friday... Night.",
			'friday_night_play',
			null,
			true
		],
		["Press space to dodge!", "Beat Tutorial on Hard?", 'tutorial_hard', null, false],
		["Going to be hard.", "Beat Tutorial on Harder.", 'tutorial_harder', null, true], // fuck you, qt fixes ported to 0.6.3
		[
			"Not so cute",
			"Complete QT week on Hard or Harder difficulty. (Unlocks Termination)",
			'qtweek_hard',
			null,
			true
		],
		[
			"System Error",
			"Beat Termination. (Unlocks Cessation)",
			'termination_beat',
			null,
			false
		],
		[
			"It was meant to be a joke",
			"Beat Termination-Classic. (Unlocks Cessation)",
			'termination_old',
			null,
			false
		],
		["Goodbye!", "Beat Cessation.", 'cessation_beat', null, false],
		["Ouch!", "Get hit by a sawblade 24 times.", 'sawblade_death', null, false],
		[
			"Too close for comfort",
			"Beat Termination after being hit 3 times by sawblades.",
			'sawblade_hell',
			null,
			false
		],
		[
			"Playing with fire",
			"Taunt over 100 times in Termination and win.",
			'taunter',
			null,
			false
		],
		[
			"Just kidding lol",
			"Get the 1/5 chance in Cessation.",
			'cessation_troll',
			null,
			true
		],
		["Inhuman", "Went into the depths of Freeplay...", 'freeplay_depths', null, true],
		[
			"What a Funkin' Disaster!",
			"Complete a Song with a rating lower than 20%.",
			'ur_bad',
			null,
			false
		],
		[
			"Perfectionist",
			"Complete a Song with a rating of 100%.",
			'ur_good',
			null,
			false
		],
		[
			"Toaster Gamer",
			"Have you tried to run the game on a toaster?",
			'toastie',
			false
		]
	];
	public static var achievementsMap:Map<String, Bool> = new Map<String, Bool>();

	public static var sawbladeDeath:Int = 0;

	public static function unlockAchievement(name:String):Void
	{
		FlxG.log.add('Completed achievement "' + name + '"');
		achievementsMap.set(name, true);
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
	}

	public static function isAchievementUnlocked(name:String)
	{
		if (achievementsMap.exists(name) && achievementsMap.get(name))
			return true;

		return false;
	}

	public static function getAchievementIndex(name:String)
	{
		for (i in 0...achievementsStuff.length)
			if (achievementsStuff[i][2] == name)
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
		antialiasing = ClientPrefs.globalAntialiasing;
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

	public function new(name:String, ?camera:FlxCamera = null)
	{
		super(x, y);
		ClientPrefs.saveSettings();

		var id:Int = Achievements.getAchievementIndex(name);
		var achievementBG:FlxSprite = new FlxSprite(60, 50).makeGraphic(420, 120, FlxColor.BLACK);
		achievementBG.scrollFactor.set();

		var achievementIcon:FlxSprite = new FlxSprite(achievementBG.x + 10, achievementBG.y + 10).loadGraphic(Paths.image('achievements/' + name));
		achievementIcon.scrollFactor.set();
		achievementIcon.setGraphicSize(Std.int(achievementIcon.width * (2 / 3)));
		achievementIcon.updateHitbox();
		achievementIcon.antialiasing = ClientPrefs.globalAntialiasing;

		var achievementName:FlxText = new FlxText(achievementIcon.x + achievementIcon.width + 20, achievementIcon.y + 16, 280,
			Achievements.achievementsStuff[id][0], 16);
		achievementName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementName.scrollFactor.set();

		var achievementText:FlxText = new FlxText(achievementName.x, achievementName.y + 32, 280, Achievements.achievementsStuff[id][1], 16);
		achievementText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementText.scrollFactor.set();

		add(achievementBG);
		add(achievementName);
		add(achievementText);
		add(achievementIcon);

		@:privateAccess
		var cam:Array<FlxCamera> = FlxG.cameras.defaults;
		if (camera != null)
			cam = [camera];

		alpha = 0;
		achievementBG.cameras = cam;
		achievementName.cameras = cam;
		achievementText.cameras = cam;
		achievementIcon.cameras = cam;
		alphaTween = FlxTween.tween(this, {alpha: 1}, 0.5, {
			onComplete: function(twn:FlxTween)
			{
				alphaTween = FlxTween.tween(this, {alpha: 0}, 0.5, {
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
