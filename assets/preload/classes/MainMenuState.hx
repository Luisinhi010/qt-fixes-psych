import flixel.math.FlxPoint;
import CoolUtil;
import Shaders;
import FreeplayState;
import flixel.math.FlxPoint;
import openfl.filters.BlurFilter;
import lore.FlxSpriteTools;

function create()
{
	MainMenuState.alignment = "right";
	MainMenuState.optionShit = ['story_mode', 'freeplay', 'mods', 'awards', 'credits', 'options'];
	MainMenuState.bgPath = 'menuMain';
}

var checker:FlxBackdrop;
var iconBG:FlxSprite;
var icon:HealthIcon;
var vignette1:OverlaySprite;
var lastalpha:Float;
var blackshader:BWShader = new BWShader(0.01, 0.12, true);
var realgood:Bool = true;
var totermination:Bool = false;

// var iconXY:FlxPoint;

function postCreate()
{
	realgood = (!ClientPrefs.lowQuality && !ClientPrefs.optimize);
	totermination = (Achievements.isAchievementUnlocked('qtweek_hard')
		&& !(Achievements.isAchievementUnlocked('termination_beat') || Achievements.isAchievementUnlocked('termination_old')));
	trace(totermination);
	// MainMenuState.bg.shader = blackshader.shader;

	checker = new FlxBackdrop(Paths.image('luis/qt-fixes/Checker'), 0.2, 0.2, true, true);
	checker.alpha = 0.4;
	MainMenuState.insert(MainMenuState.members.indexOf(MainMenuState.menuItems), checker);
	checker.scrollFactor.set(0, 0.07);
	checker.velocity.x -= 45;
	checker.velocity.y -= 16;

	if (realgood)
	{
		iconBG = new FlxSprite().loadGraphic(Paths.image('luis/qt-fixes/iconbackground'));
		iconBG.y = FlxG.height - iconBG.height;
		iconBG.scrollFactor.set();
		iconBG.updateHitbox();
		iconBG.antialiasing = ClientPrefs.antialiasing;
		MainMenuState.add(iconBG);
	}

	icon = new HealthIcon('bf');
	icon.antialiasing = ClientPrefs.antialiasing;
	icon.x = 70;
	icon.y = FlxG.height - 180;
	// iconXY = new FlxPoint(icon.x, icon.y);
	icon.scrollFactor.set();
	icon.updateHitbox();
	MainMenuState.add(icon);

	MainMenuState.versionShit.screenCenter(FlxAxes.X);
	MainMenuState.versionShit.alignment = "center";
	MainMenuState.versionShitfnf.screenCenter(FlxAxes.X);
	MainMenuState.versionShitfnf.alignment = "center";
	var qtVersion:FlxText = new FlxText(FlxG.width - 270, FlxG.height - 44, 0, "QT Mod Version - v" + qtmodVersion, 12);
	qtVersion.x -= qtVersion.width;
	qtVersion.scrollFactor.set();
	qtVersion.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFFFF, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
	MainMenuState.add(qtVersion);

	var fixesVersion:FlxText = new FlxText(qtVersion.x, FlxG.height - 24, 0,
		"QT Fixes Version - v" + qtfixesVersion /*+ ' (' + MusicBeatState.commitHash + ')'*/, 12);
	fixesVersion.scrollFactor.set();
	fixesVersion.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFFFF, "center", FlxTextBorderStyle.OUTLINE, 0xFF000000);
	MainMenuState.add(fixesVersion);
	FlxG.mouse.visible = true;
	FlxG.mouse.useSystemCursor = false;

	if (realgood)
	{
		vignette1 = new OverlaySprite('luis/qt-fixes/vignettealt');
		vignette1.usewindowscale = false;
		vignette1.alpha = 0;
		MainMenuState.add(vignette1);
	}

	var random:Int = FlxG.random.int(1, 5);
	var innerrandom:Int = FlxG.random.int(1, 2);

	if (totermination)
	{
		random = 3;
		innerrandom = 1;
	}

	switch (random)
	{
		case 1:
			icon.changeIcon('bf');
			icon.setGraphicSize(Std.int(icon.width * 2));
			if (realgood)
				iconBG.color = CoolUtil.returnColor('cyan');
		case 2:
			icon.changeIcon('gf');
			icon.setGraphicSize(Std.int(icon.width * 2));
			if (realgood)
				iconBG.color = CoolUtil.returnColor('red');
		case 3:
			icon.changeIcon('kb');
			icon.setGraphicSize(Std.int(icon.width * 1.9));
			if (realgood)
				iconBG.color = CoolUtil.returnColor('gray');
			switch (innerrandom)
			{
				case 1:
					if (realgood)
						vignette1.alpha = 0.5;
					icon.animation.curAnim.curFrame = 0;
				case 2:
					if (realgood)
						vignette1.alpha = 0.8;
					icon.animation.curAnim.curFrame = 1;
			}
		case 4:
			icon.changeIcon('qt-menu');
			icon.setGraphicSize(Std.int(icon.width * 1.9));
			if (realgood)
				iconBG.color = CoolUtil.returnColor('pink');
			switch (innerrandom)
			{
				case 1:
					if (realgood)
						vignette1.alpha = 0.1;
					icon.animation.curAnim.curFrame = 0;
				case 2:
					if (realgood)
						vignette1.alpha = 0.7;
					icon.animation.curAnim.curFrame = 1;
			}
		case 5:
			icon.changeIcon('qt_annoyed');
			icon.setGraphicSize(Std.int(icon.width * 1.9));
			if (realgood)
			{
				iconBG.color = CoolUtil.returnColor('pink');
				vignette1.alpha = 0.7;
			}
	}
	trace(icon.getCharacter());

	if (realgood)
	{
		if (checker != null)
			checker.color = iconBG.color;

		lastalpha = vignette1.alpha;
	}

	// updateui();
	if (totermination)
	{
		if (!FreeplayState.curPlaying)
			FlxG.sound.music.pitch = 0.4;
		MainMenuState.menuItems.members[1].color = CoolUtil.returnColor('red');
		// MainMenuState.menuItems.members[1].shader = blackshader.shader;
		MainMenuState.bg.color = CoolUtil.returnColor('gray');
		MainMenuState.magenta.color = CoolUtil.returnColor('black');
		checker.visible = false;
		if (realgood)
		{
			vignette1.visible = false;
			iconBG.shader = blackshader.shader;
		}

		MainMenuState.changeItem(1, true);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		var sidesoffset:Int = 40;
		var textsize:Int = 20;

		if (realgood)
		{
			var achievementBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('luis/qt-fixes/iconbackground'));
			achievementBG.scrollFactor.set();
			achievementBG.flipY = true;
			achievementBG.antialiasing = ClientPrefs.antialiasing;
			achievementBG.color = CoolUtil.returnColor('black');
			MainMenuState.add(achievementBG);
		}

		var achievement:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('AchievementBG', 'preload'));
		achievement.setGraphicSize(Std.int(achievement.width * 0.9));
		achievement.updateHitbox();
		achievement.antialiasing = ClientPrefs.antialiasing;
		achievement.x = sidesoffset;
		achievement.y = sidesoffset;
		achievement.color = CoolUtil.returnColor('black');
		achievement.scrollFactor.set();
		MainMenuState.add(achievement);

		var achievementIcon:FlxSprite = new FlxSprite(0, achievement.y + 70);
		achievementIcon.loadGraphic(Paths.image('achievements/termination_beat', 'preload'));
		achievementIcon.scrollFactor.set();
		achievementIcon.setGraphicSize(Std.int(achievementIcon.width * 0.6));
		achievementIcon.updateHitbox();
		FlxSpriteTools.centerOnSprite(achievementIcon, achievement, FlxAxes.X);
		achievementIcon.antialiasing = ClientPrefs.antialiasing;
		achievementIcon.shader = blackshader.shader;
		MainMenuState.add(achievementIcon);

		var achievementText:FlxText = new FlxText(0, 0, 290, Locale.get("achievementdesctermination_beat"), textsize);
		achievementText.setFormat(Paths.font("vcr.ttf"), textsize, CoolUtil.returnColor('white'), "center");
		FlxSpriteTools.centerOnSprite(achievementText, achievement, FlxAxes.XY);
		achievementText.y += 50;
		achievementText.scrollFactor.set();
		MainMenuState.add(achievementText);
	}
}

function postUpdate(elapsed:Float)
{
	if (totermination)
	{
		MainMenuState.menuItems.members[1].screenCenter(FlxAxes.X);
		// icon.setPosition(iconXY.x + FlxG.random.int(1, 5), iconXY.y + FlxG.random.int(1, 5));
	}
}

function postcloseSubState()
{
	if (realgood)
		vignette1.alpha = lastalpha;
}
/*function beatHit(curBeat) // testing other functions
	{
	MainMenuState.alignment = curBeat % 2 == 0 ? "right" : "left";
	totermination = !totermination;
	updateui();

 */
