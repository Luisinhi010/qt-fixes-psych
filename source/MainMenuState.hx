package;

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
import flixel.input.mouse.FlxMouseEventManager;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.5.1'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		// #if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED
		'awards',
		#end
		'credits',
		'options'
	];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;
	var vignette1:BGSprite;
	var checker:FlxBackdrop;

	public var iconBG:FlxSprite;
	public var icon:HealthIcon;

	var date = Date.now();
	var noname:Bool = false;
	var shit:FlxText;

	var t = DateTools.format(Date.now(), "%Y/%m/%d-%H:%M:%S"); // 2022/05/10-20:08:21

	var custommouse:CustomMouse;

	function onMouseDown(object:FlxObject)
	{
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
		if (!selectedSomethin)
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
		{
			if (optionShit[curSelected] == 'donate')
			{
				CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
			}
			else
			{
				selectedSomethin = true;
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
	}

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		trace(t);
		trace(Main.getUsername());

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);

		// magenta.scrollFactor.set();

		if (!ClientPrefs.lowQuality)
		{
			checker = new FlxBackdrop(Paths.image('luis/qt-fixes/Checker'), 0.2, 0.2, true, true);
			checker.alpha = 0.5;
			add(checker);
			checker.scrollFactor.set(0, 0.07);
			checker.velocity.x -= 45;
			checker.velocity.y -= 16;
		}

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

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
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6)
				scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			// menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();

			FlxMouseEventManager.add(menuItem, onMouseDown, onMouseUp, onMouseOver, onMouseOut);
		}

		// FlxG.mouse.useSystemCursor = true;
		// FlxG.mouse.visible = true;
		// custom mouse lmao
		FlxG.camera.follow(camFollowPos, null, 1);

		if (!ClientPrefs.lowQuality)
		{
			iconBG = new FlxSprite().loadGraphic(Paths.image('luis/qt-fixes/iconbackground'));
			iconBG.scrollFactor.set();
			iconBG.updateHitbox();
			iconBG.antialiasing = ClientPrefs.globalAntialiasing;
			add(iconBG);
		}

		icon = new HealthIcon('bf');
		icon.antialiasing = ClientPrefs.globalAntialiasing;
		icon.x = 70;
		icon.y = FlxG.height - 180;
		icon.scrollFactor.set();
		icon.updateHitbox();
		add(icon);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionShit.screenCenter(X);
		add(versionShit);

		var versionShitfnf:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShitfnf.scrollFactor.set();
		versionShitfnf.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionShitfnf.screenCenter(X);
		add(versionShitfnf);

		var qtVersion:FlxText = new FlxText(FlxG.width - 215, FlxG.height - 24, 0, "QT Mod Version - v2.2", 12);
		qtVersion.scrollFactor.set();
		qtVersion.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(qtVersion);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();
		custommouse = new CustomMouse(FlxG.mouse.x, FlxG.mouse.y);
		add(custommouse);

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
		{
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if (!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2]))
			{ // It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		vignette1 = new BGSprite('luis/qt-fixes/vignettealt');
		vignette1.setGraphicSize(FlxG.width, FlxG.height);
		vignette1.alpha = 0;
		vignette1.scrollFactor.set(0, 0);
		vignette1.updateHitbox();
		vignette1.screenCenter();
		vignette1.antialiasing = true;
		add(vignette1);

		switch (FlxG.random.int(1, 5))
		{
			case 1:
				icon.changeIcon('bf');
				icon.setGraphicSize(Std.int(icon.width * 2));
				if (!ClientPrefs.lowQuality && iconBG != null)
					iconBG.color = FlxColor.CYAN;
			case 2:
				icon.changeIcon('gf');
				icon.setGraphicSize(Std.int(icon.width * 2));
				if (!ClientPrefs.lowQuality && iconBG != null)
					iconBG.color = FlxColor.RED;
			case 3:
				icon.changeIcon('kb');
				icon.setGraphicSize(Std.int(icon.width * 1.9));
				if (!ClientPrefs.lowQuality && iconBG != null)
					iconBG.color = FlxColor.GRAY;
				switch (FlxG.random.int(1, 2))
				{
					case 1:
						vignette1.alpha = 0.5;
						icon.animation.curAnim.curFrame = 0;
					case 2:
						vignette1.alpha = 0.8;
						icon.animation.curAnim.curFrame = 1;
				}
			case 4:
				icon.changeIcon('qt-menu');
				icon.setGraphicSize(Std.int(icon.width * 1.9));
				if (!ClientPrefs.lowQuality && iconBG != null)
					iconBG.color = FlxColor.PINK;
				switch (FlxG.random.int(1, 2))
				{
					case 1:
						vignette1.alpha = 0.1;
						icon.animation.curAnim.curFrame = 0;
					case 2:
						vignette1.alpha = 0.7;
						icon.animation.curAnim.curFrame = 1;
				}
			case 5:
				icon.changeIcon('qt_annoyed');
				icon.setGraphicSize(Std.int(icon.width * 1.9));
				if (!ClientPrefs.lowQuality && iconBG != null)
					iconBG.color = FlxColor.PINK;
				vignette1.alpha = 0.7;
		}

		if (!ClientPrefs.lowQuality)
		{
			if (checker != null)
				checker.color = iconBG.color;
			custommouse.color = iconBG.color;
		}

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement()
	{
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		custommouse.updatemouse();

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
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

			if (controls.BACK)
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
			/*if (controls.RESET)
				{
					BrutalityGameOverSubstate.characterName = 'amelia';
					openSubState(new BrutalityGameOverSubstate('health', (new PlayState())));
			}*/
			#end
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});
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
				{
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
		});
	}
}
