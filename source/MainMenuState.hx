package;

import sys.FileSystem;
import flixel.util.FlxTimer;
import flixel.addons.display.FlxBackdrop;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.mouse.FlxMouseEvent;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import Shaders.BWShader;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;
using lore.FlxSpriteTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.6.3'; // This is also used for Discord RPC
	public static var qtmodVersion:String = '2.2';
	public static var qtfixesVersion:String = '1.0';
	public static var curSelected:Int = 0;

	public var menuItems:FlxTypedGroup<FlxSprite>;

	public var sideOffset:Float = 100;

	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	public var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		#if !switch 'donate', #end
		'options'
	];

	public var bg:FlxSprite;
	public var magenta:FlxSprite;
	public var camFollow:FlxObject;
	public var camFollowPos:FlxObject;
	public var debugKeys:Array<FlxKey>;

	public var date:Date = Date.now();
	public var noname:Bool = false;

	public static var dateNow:String = Date.now().toString();

	public static var usecontrols:Bool = true;

	var checker:FlxBackdrop;
	var iconBG:FlxSprite;
	var icon:HealthIcon;
	var vignette1:OverlaySprite;
	var lastalpha:Float;
	var blackshader:BWShader;
	var realgood:Bool;
	var totermination:Bool;

	function onMouseDown(object:FlxObject)
	{
		if (!selectedSomethin && usecontrols)
			for (obj in menuItems.members)
			{
				if (obj == object)
				{
					accept();
					break;
				}
			}
	}

	function onMouseUp(object:FlxObject)
	{
	}

	function onMouseOver(object:FlxObject)
	{
		if (!selectedSomethin && usecontrols)
		{
			for (idx in 0...menuItems.members.length)
			{
				var obj = menuItems.members[idx];
				if (obj == object)
				{
					if (idx != curSelected)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'));
						changeItem(idx, true);
					}
				}
			}
		}
	}

	function onMouseOut(object:FlxObject)
	{
	}

	function accept()
	{
		if (optionShit[curSelected] == 'donate')
			CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
		else
		{
			selectedSomethin = true;
			// usecontrols = false;
			FlxG.sound.play(Paths.sound('confirmMenu'));

			if (ClientPrefs.flashing)
				FlxFlicker.flicker(magenta, 1.1, 0.15, false);

			menuItems.forEach(function(spr:FlxSprite)
			{
				if (curSelected != spr.ID)
				{
					FlxTween.tween(spr, {alpha: 0}, 0.4, {
						ease: FlxEase.quadOut,
						onComplete: function(twn:FlxTween)
						{
							spr.kill();
						}
					});
				}
				else
				{
					FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
					{
						var daChoice:String = optionShit[curSelected];

						switch (daChoice)
						{
							case 'story_mode':
								MusicBeatState.switchState(new StoryMenuState());
							case 'freeplay':
								MusicBeatState.switchState(new FreeplayState());
							#if MODS_ALLOWED
							case 'mods':
								MusicBeatState.switchState(new ModsMenuState());
							#end
							case 'awards':
								MusicBeatState.switchState(new AchievementsMenuState());
							case 'credits':
								MusicBeatState.switchState(new CreditsState());
							case 'options':
								LoadingState.loadAndSwitchState(new options.OptionsState());
						}
					});
				}
			});
		}
	}

	override function closeSubState()
	{
		usecontrols = true;
		selectedSomethin = false;
		super.closeSubState();
		if (realgood)
			vignette1.alpha = lastalpha;
	}

	override function create()
	{
		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		trace(dateNow);
		#if sys
		if (CoolUtil.getUsernameOption())
			trace(CoolUtil.getUsername());
		#end

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		realgood = (!ClientPrefs.lowQuality && !ClientPrefs.optimize);
		totermination = (Achievements.isAchievementUnlocked('qtweek_hard')
			&& !(Achievements.isAchievementUnlocked('termination_beat') || Achievements.isAchievementUnlocked('termination_old')));
		trace(totermination);
		// totermination = true;

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuMain'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.antialiasing;
		bg.color = 0xFFFBE565;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuMain'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.antialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);

		checker = new FlxBackdrop(Paths.image('luis/qt-fixes/Checker'));
		checker.alpha = 0.4;
		add(checker);
		checker.scrollFactor.set(0, 0.07);
		checker.velocity.x -= 45;
		checker.velocity.y -= 16;

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140) + offset);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6)
				scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.antialiasing;
			menuItem.updateHitbox();
			menuItem.x = (FlxG.width - 150) - (menuItem.width);

			FlxMouseEvent.add(menuItem, onMouseDown, onMouseUp, onMouseOver, onMouseOut);
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		if (realgood)
		{
			iconBG = new FlxSprite().loadGraphic(Paths.image('luis/qt-fixes/iconbackground'));
			iconBG.y = FlxG.height - iconBG.height;
			iconBG.scrollFactor.set();
			iconBG.updateHitbox();
			iconBG.antialiasing = ClientPrefs.antialiasing;
			add(iconBG);
			vignette1 = new OverlaySprite('luis/qt-fixes/vignettealt');
			vignette1.usewindowscale = false;
			vignette1.alpha = 0;
			add(vignette1);
		}

		icon = new HealthIcon('bf');
		icon.antialiasing = ClientPrefs.antialiasing;
		icon.x = 70;
		icon.y = FlxG.height - 180;
		icon.scrollFactor.set();
		icon.updateHitbox();
		add(icon);

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

		var versionShit:FlxText = new FlxText(0, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.screenCenter(X);
		versionShit.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		var versionShitfnf:FlxText = new FlxText(0, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShitfnf.scrollFactor.set();
		versionShitfnf.screenCenter(X);
		versionShitfnf.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShitfnf);

		var qtVersion:FlxText = new FlxText(FlxG.width - 270, FlxG.height - 44, 0, "QT Mod Version - v" + qtmodVersion, 12);
		qtVersion.x -= qtVersion.width;
		qtVersion.scrollFactor.set();
		qtVersion.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		add(qtVersion);

		var fixesVersion:FlxText = new FlxText(qtVersion.x, FlxG.height - 24, 0, "QT Fixes Version - v" + qtfixesVersion, 12);
		fixesVersion.scrollFactor.set();
		fixesVersion.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		add(fixesVersion);
		FlxG.mouse.visible = true;
		FlxG.mouse.useSystemCursor = false;

		if (realgood)
			add(vignette1);

		if (totermination)
		{
			if (!FreeplayState.curPlaying)
				FlxG.sound.music.pitch = 0.4;
			menuItems.members[1].color = CoolUtil.returnColor('red');
			blackshader = new BWShader(0.01, 0.12, true);
			// MainMenuState.menuItems.members[1].shader = blackshader.shader;
			bg.color = CoolUtil.returnColor('gray');
			magenta.color = CoolUtil.returnColor('black');
			checker.visible = false;
			if (realgood)
			{
				vignette1.visible = false;
				iconBG.shader = blackshader.shader;
			}

			changeItem(1, true);
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
				add(achievementBG);
			}

			var achievement:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('AchievementBG', 'preload'));
			achievement.setGraphicSize(Std.int(achievement.width * 0.9));
			achievement.updateHitbox();
			achievement.antialiasing = ClientPrefs.antialiasing;
			achievement.x = sidesoffset;
			achievement.y = sidesoffset;
			achievement.color = CoolUtil.returnColor('black');
			achievement.scrollFactor.set();
			add(achievement);

			var achievementIcon:FlxSprite = new FlxSprite(0, achievement.y + 70);
			achievementIcon.loadGraphic(Paths.image('achievements/termination_beat', 'preload'));
			achievementIcon.scrollFactor.set();
			achievementIcon.setGraphicSize(Std.int(achievementIcon.width * 0.6));
			achievementIcon.updateHitbox();
			achievementIcon.centerOnSprite(achievement, X);
			achievementIcon.antialiasing = ClientPrefs.antialiasing;
			achievementIcon.shader = blackshader.shader;
			add(achievementIcon);

			var achievementText:FlxText = new FlxText(0, 0, 290, Locale.get("achievementdesctermination_beat"), textsize);
			achievementText.setFormat(Paths.font("vcr.ttf"), textsize, CoolUtil.returnColor('white'), "center");
			achievementText.centerOnSprite(achievement, XY);
			achievementText.y += 50;
			achievementText.scrollFactor.set();
			add(achievementText);
		}

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18 && !Achievements.isAchievementUnlocked('friday_night_play'))
		{
			Achievements.achievementsMap.set('friday_night_play', true);
			giveAchievement('friday_night_play');
			ClientPrefs.saveSettings();
		}

		/*if (/*ClientPrefs.framerate <= 60 && !ClientPrefs.shaders
				&& ClientPrefs.lowQuality
				&& !ClientPrefs.antialiasing
				&& !Achievements.isAchievementUnlocked('toastie'))
			{
				Achievements.achievementsMap.set('toastie', true);
				giveAchievement('toastie');
				ClientPrefs.saveSettings();
			}
		 */
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement(achievement:String)
	{
		add(new AchievementObject(achievement, camAchievement));
		FlxG.sound.play(Paths.sound('LuisAchievement', 'preload'));
		trace('Giving achievement "$achievement"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		Conductor.songPosition = FlxG.sound.music.time;

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin && usecontrols)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-FlxG.mouse.wheel);
			}

			if (controls.BACK || FlxG.mouse.justPressedRight #if android || FlxG.android.justPressed.BACK #end)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
				accept();
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);

		menuItems.forEach(function(menuItem:FlxSprite)
		{
			if (!selectedSomethin)
				menuItem.alpha = (menuItem.ID == curSelected) ? 1 : 0.8;

			menuItem.x = FlxG.width - menuItem.width - sideOffset;
		});
		if (totermination)
			menuItems.members[1].screenCenter(X);
	}

	function changeItem(huh:Int = 0, force:Bool = false)
	{
		if (force)
			curSelected = huh;
		else
		{
			curSelected += huh;

			if (curSelected >= menuItems.length)
				curSelected = 0;
			if (curSelected < 0)
				curSelected = menuItems.length - 1;
		}

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				if (menuItems.length > 4)
					add = menuItems.length * 8;

				var mid = spr.getGraphicMidpoint();
				camFollow.setPosition(mid.x, mid.y - add);
				mid.put();
				spr.centerOffsets();
			}
		});
	}
}
