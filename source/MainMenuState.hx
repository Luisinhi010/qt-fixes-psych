package;

#if cpp import sys.FileSystem; #end
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
	public static var psychEngineVersion:String = '0.6.3'; // This is also used for Discord RPC
	public static var qtmodVersion:String = '2.2';
	public static var qtfixesVersion:String = '1.0';
	public static var curSelected:Int = 0;

	#if sys
	var helloText:FlxText;
	#end

	public var alignment:MainMenuItemAlignment = CENTER;

	public var menuItems:FlxTypedGroup<MainMenuItem>;

	public var sideOffset:Float = 100;

	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var defaultoptions:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		#if !switch 'donate', #end
		'options'
	];

	public var optionShit:Array<String> = [];

	public var bg:FlxSprite;
	public var magenta:FlxSprite;
	public var camFollow:FlxObject;
	public var camFollowPos:FlxObject;
	public var debugKeys:Array<FlxKey>;

	public var versionShitfnf:FlxText;
	public var versionShit:FlxText;

	public var date:Date = Date.now();
	public var noname:Bool = false;

	public static var dateNow:String = Date.now().toString();

	public static var usecontrols:Bool = true;

	public var menuScript:ScriptHandler;
	public var bgPath:String = 'menuDesat';

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
		menuScript.callFunc('accept', [curSelected]);
		if (optionShit[curSelected] == 'donate')
			CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
		else
		{
			selectedSomethin = true;
			// usecontrols = false;
			FlxG.sound.play(Paths.sound('confirmMenu'));

			if (ClientPrefs.flashing)
				FlxFlicker.flicker(magenta, 1.1, 0.15, false);

			menuItems.forEach(function(spr:MainMenuItem)
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
						menuScript.callFunc('stateSwitch', [daChoice]);

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
						menuScript.callFunc('postStateSwitch', [daChoice]);
					});
				}
			});
		}
	}

	override function closeSubState()
	{
		menuScript.callFunc('closeSubState', []);
		usecontrols = true;
		selectedSomethin = false;
		super.closeSubState();
		#if sys
		helloText.visible = CoolUtil.getUsernameOption();
		helloText.text = "Hello " + CoolUtil.getUsername();
		#end
		menuScript.callFunc('postCloseSubState', []);
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

		menuScript = new ScriptHandler(Paths.Script('MainMenuState'));

		menuScript.setVar('MainMenuState', this);
		menuScript.setVar('members', members);
		menuScript.setVar('qtmodVersion', qtmodVersion);
		menuScript.setVar('qtfixesVersion', qtfixesVersion);

		menuScript.callFunc('create', []);

		var createOver:Dynamic = menuScript.callFunc('overrideCreate', []);
		if (createOver != null)
			return;

		if (optionShit.length < 1)
			optionShit = defaultoptions;

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		bg = new FlxSprite(-80).loadGraphic(Paths.image(bgPath));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.color = 0xFFFBE565;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image(bgPath));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);

		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<MainMenuItem>();
		add(menuItems);

		var scale:Float = 1;

		for (i in 0...optionShit.length)
		{
			menuScript.callFunc('optionSetup', [i]);
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:MainMenuItem = new MainMenuItem(0, (i * 140) + offset);
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
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			menuItem.updateHitbox();
			menuItem.x = (FlxG.width - 150) - (menuItem.width);

			FlxMouseEventManager.add(menuItem, onMouseDown, onMouseUp, onMouseOver, onMouseOut);
			menuScript.setVar('menuItem', menuItem);
			menuScript.callFunc('postOptionSetup', [i]);
		}

		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;
		FlxG.camera.follow(camFollowPos, null, 1);

		versionShit = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		versionShitfnf = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShitfnf.scrollFactor.set();
		versionShitfnf.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShitfnf);

		#if sys
		helloText = new FlxText(30, 100, 0, 'Hello ' + CoolUtil.getUsername(), 32);
		helloText.scrollFactor.set();
		helloText.setFormat(Paths.font("FridayNightFunkin.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		helloText.visible = CoolUtil.getUsernameOption();
		add(helloText);
		#end

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
		{
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if (!Achievements.isAchievementUnlocked('friday_night_play'))
			{ // It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set('friday_night_play', true);
				giveAchievement('friday_night_play');
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
		/*#if sys
			if (TitleState.getplayernameoption)
			{
				openSubState(new ConfirmUserOption());
				FlxG.sound.play(Paths.sound('scrollMenu'));
				usecontrols = false;
				selectedSomethin = true;
				TitleState.getplayernameoption = false;
			}
			#end */
		menuScript.callFunc('postCreate', []);
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement(achievement:String)
	{
		add(new AchievementObject(achievement, camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "$achievement"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		menuScript.callFunc('update', [elapsed]);

		var setupOver:Dynamic = menuScript.callFunc('overrideUpdate', [elapsed]);
		if (setupOver != null)
			return;

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

			if (controls.BACK || FlxG.mouse.justPressedRight #if android || FlxG.android.justReleased.BACK #end)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT /*|| FlxG.mouse.justPressed*/)
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

		menuItems.forEach(function(menuItem:MainMenuItem)
		{
			if (menuItem.autoPos)
			{
				switch (alignment)
				{
					case LEFT:
						menuItem.x = sideOffset;
					case CENTER | MIDDLE:
						menuItem.screenCenter(X);
					case RIGHT:
						menuItem.x = FlxG.width - menuItem.width - sideOffset;
				}
			}
		});
		menuScript.callFunc('postUpdate', [elapsed]);
	}

	override function beatHit()
	{
		super.beatHit();
		menuScript.callFunc('beatHit', [curBeat]);
	}

	override function stepHit()
	{
		super.stepHit();
		menuScript.callFunc('stepHit', [curStep]);
	}

	function changeItem(huh:Int = 0, force:Bool = false)
	{
		menuScript.callFunc('changeItem', [huh]);
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

		menuItems.forEach(function(spr:MainMenuItem)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			spr.z = 0;

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				if (menuItems.length > 4)
					add = menuItems.length * 8;

				spr.z = 1;
				var mid = spr.getGraphicMidpoint();
				camFollow.setPosition(mid.x, mid.y - add);
				mid.put();
				spr.centerOffsets();
			}
		});
		// menuItems.sort(byZ, flixel.util.FlxSort.ASCENDING);
		menuScript.callFunc('postChangeItem', [huh]);
	}

	public static inline function byZ(Order:Int, Obj1:MainMenuItem, Obj2:MainMenuItem):Int
		return flixel.util.FlxSort.byValues(Order, Obj1.z, Obj2.z);
}

@:enum abstract MainMenuItemAlignment(String)
{
	public var LEFT = "left";
	public var CENTER = "center";
	public var MIDDLE = "middle";
	public var RIGHT = "right";
}

class MainMenuItem extends FlxSprite
{
	public var z:Int = 0;
	public var autoPos:Bool = true;
	public var autoScale:Bool = true;
}
