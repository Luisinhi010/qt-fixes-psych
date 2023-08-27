package;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import lime.utils.Assets;

using StringTools;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<AttachedFlxSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var descText:FlxText;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var descBox:AttachedFlxSprite;

	var offsetThing:Float = -75;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);
		bg.screenCenter();

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		#if MODS_ALLOWED
		var path:String = 'modsList.txt';
		if (FileSystem.exists(path))
		{
			var leMods:Array<String> = CoolUtil.coolTextFile(path);
			for (i in 0...leMods.length)
			{
				if (leMods.length > 1 && leMods[0].length > 0)
				{
					var modSplit:Array<String> = leMods[i].split('|');
					if (!Paths.ignoreModFolders.contains(modSplit[0].toLowerCase()) && !modsAdded.contains(modSplit[0]))
					{
						if (modSplit[1] == '1')
							pushModCreditsToList(modSplit[0]);
						else
							modsAdded.push(modSplit[0]);
					}
				}
			}
		}

		var arrayOfFolders:Array<String> = Paths.getModDirectories();
		arrayOfFolders.push('');
		for (folder in arrayOfFolders)
		{
			pushModCreditsToList(folder);
		}
		#end

		// https://convertingcolors.com
		var pisspoop:Array<Array<String>> = [
			// Name - Icon name - Description - Link - RGB bg/desctext Color
			['QT Fixes'],
			[
				'Luis Com "S"',
				'luis',
				"Programming, having the ideias n' stuff",
				'https://twitter.com/Luis_ComS_01',
				'215, 169, 104'
			],
			[
				'BeastlyGabi',
				'Ghost',
				"Also Programming, Updated Hud's code\nHelp em if you can!",
				'https://twitter.com/CrowPlexus',
				'0, 190, 250'
			],
			[''],
			['QT Fixes Contributors'],
			[
				'NooBZiiTo',
				'noobziito',
				"New Qt's note skin",
				'https://twitter.com/NooBZiiTo1',
				'0, 80, 15'
			],
			[
				'Zahaire15',
				'zahaire',
				"New Qt's Icon",
				'https://twitter.com/Zahaire15',
				'255, 160, 203'
			],
			[
				'DrkFon376',
				'drkfon',
				"Qt nervous's Icon",
				'https://twitter.com/drkfon376',
				'10, 10, 200'
			],
			[
				'Yoshi Crafter29',
				'yoshicrafter29',
				"Blue Screen Shader and\nFixed Shader's Code",
				'https://twitter.com/fnfcodenameeg', // he privated his twitter, original: https://twitter.com/YoshiCrafter29
				'255, 204, 157'
			],
			[''],
			['QT Mod Team'],
			[
				'Hazard24',
				'hazard',
				'Programming, Music, Charting, Animation, SFX',
				'https://twitter.com/Hazard248',
				'240, 210, 0'
			],
			[
				'CountNightshade',
				'nightshade',
				'Art, Character Design',
				'https://twitter.com/CountNightshade',
				'153, 48, 187'
			],
			[''],
			['Special Thanks'],
			[
				'sayofthelor',
				'bean',
				'Took some stuff From Lore Engine',
				'https://twitter.com/sayofthelor',
				'102, 51, 153'
			],
			[
				'Psych Engine GitHub',
				'psychdiscord',
				'Some Comits & PRs from the github',
				'https://github.com/ShadowMario/FNF-PsychEngine',
				'101, 39, 199'
			],
			[''],
			['Psych Engine Team'],
			[
				'Shadow Mario',
				'shadowmario',
				'Main Programmer of Psych Engine',
				'https://twitter.com/Shadow_Mario_',
				'68, 68, 68'
			],
			[
				'RiverOaken',
				'river',
				'Main Artist/Animator of Psych Engine',
				'https://twitter.com/RiverOaken',
				'180, 47, 113'
			],
			[''],
			['Former Engine Members'],
			[
				'bb-panzu',
				'bb',
				'Ex-Programmer of Psych Engine',
				'https://twitter.com/bbpnz213',
				'62, 129, 58'
			],
			[''],
			['Engine Contributors'],
			[
				'iFlicky',
				'flicky',
				'Composer of Psync and Tea Time\nMade the Dialogue Sounds',
				'https://twitter.com/flicky_i',
				'158, 41, 207'
			],
			[
				'SqirraRNG',
				'sqirra',
				#if CRASH_HANDLER 'Crash Handler and ' + #end
				'Base code for\nChart Editor\'s Waveform',
				'https://twitter.com/gedehari',
				'225, 132, 58'
			],
			[
				'EliteMasterEric',
				'mastereric',
				'Runtime Shaders support',
				'https://twitter.com/EliteMasterEric',
				'255, 189, 64'
			],
			[
				'PolybiusProxy',
				'proxy',
				'.MP4 Video Loader Library (hxCodec)',
				'null', // F
				'220, 210, 148'
			],
			[
				'KadeDev',
				'kade',
				'Fixed some cool stuff on Chart Editor\nand other PRs',
				'https://twitter.com/kade0912',
				'100, 162, 80'
			],
			[
				'Keoiki',
				'keoiki',
				'Note Splash Animations',
				'https://twitter.com/Keoiki_',
				'210, 210, 210'
			],
			[
				'Nebula the Zorua',
				'nebula',
				'LUA JIT Fork and some Lua reworks',
				'https://twitter.com/Nebula_Zorua',
				'125, 64, 178'
			],
			[
				'Smokey',
				'smokey',
				'Sprite Atlas Support',
				'https://twitter.com/Smokey_5_',
				'72, 61, 146'
			],
			[''],
			["Funkin' Crew"],
			[
				'ninjamuffin99',
				'ninjamuffin99',
				"Programmer of Friday Night Funkin'",
				'https://twitter.com/ninja_muffin99',
				'207, 45, 45'
			],
			[
				'PhantomArcade',
				'phantomarcade',
				"Animator of Friday Night Funkin'",
				'https://twitter.com/PhantomArcade3K',
				'250, 220, 69'
			],
			[
				'evilsk8r',
				'evilsk8r',
				"Artist of Friday Night Funkin'",
				'https://twitter.com/evilsk8r',
				'90, 189, 75'
			],
			[
				'kawaisprite',
				'kawaisprite',
				"Composer of Friday Night Funkin'",
				'https://twitter.com/kawaisprite',
				'55, 143, 199'
			]
		];

		for (i in pisspoop)
			creditsStuff.push(i);

		for (i in 0...creditsStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(FlxG.width / 2, 300, creditsStuff[i][0], !isSelectable);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			optionText.changeX = false;
			optionText.snapToPosition();
			grpOptions.add(optionText);

			if (isSelectable)
			{
				if (creditsStuff[i][5] != null)
					Paths.currentModDirectory = creditsStuff[i][5];

				var icon:AttachedFlxSprite = new AttachedFlxSprite('credits/' + creditsStuff[i][1]);
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;

				// using a FlxGroup is too much fuss!
				iconArray.push(icon);
				add(icon);
				Paths.currentModDirectory = '';

				if (curSelected == -1)
					curSelected = i;
			}
			else
				optionText.alignment = CENTERED;
		}

		descBox = new AttachedFlxSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.xAdd = -10;
		descBox.yAdd = -10;
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		descBox.copyAlpha = false;
		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2;
		descBox.sprTracker = descText;
		add(descText);

		bg.color = descText.color = getCurrentBGColor();
		intendedColor = bg.color;
		descText.borderColor = FlxColor.WHITE - descText.color;
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if (!quitting)
		{
			if (creditsStuff.length > 1)
			{
				var shiftMult:Int = 1;
				if (FlxG.keys.pressed.SHIFT)
					shiftMult = 3;

				var upP = controls.UI_UP_P;
				var downP = controls.UI_DOWN_P;

				if (upP)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (downP)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}
				if (FlxG.mouse.wheel != 0)
				{
					changeSelection(-FlxG.mouse.wheel);
					holdTime = 0;
				}

				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}
			}

			if ((controls.ACCEPT || FlxG.mouse.justPressed)
				&& (creditsStuff[curSelected][3] == null || creditsStuff[curSelected][3].length > 4))
				CoolUtil.browserLoad(creditsStuff[curSelected][3]);

			if (controls.BACK || FlxG.mouse.justPressedRight)
			{
				if (colorTween != null)
					colorTween.cancel();

				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				quitting = true;
			}
		}

		for (item in grpOptions.members)
		{
			if (!item.bold)
			{
				var lerpVal:Float = CoolUtil.boundTo(elapsed * 12, 0, 1);
				if (item.targetY == 0)
				{
					var lastX:Float = item.x;
					item.screenCenter(X);
					item.x = FlxMath.lerp(lastX, item.x - 70, lerpVal);
				}
				else
					item.x = FlxMath.lerp(item.x, 200 + -40 * Math.abs(item.targetY), lerpVal);
			}
		}
		super.update(elapsed);
	}

	var moveTween:FlxTween = null;

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do
		{
			curSelected += change;
			if (curSelected < 0)
				curSelected = creditsStuff.length - 1;
			if (curSelected >= creditsStuff.length)
				curSelected = 0;
		}
		while (unselectableCheck(curSelected));

		var newColor:Int = getCurrentBGColor();
		if (newColor != intendedColor)
		{
			if (colorTween != null)
				colorTween.cancel();

			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween)
				{
					colorTween = null;
				},
				onUpdate: function(twn:FlxTween)
				{
					descText.color = bg.color;
					descText.borderColor = FlxColor.WHITE - descText.color;
				}
			});
		}

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit - 1))
			{
				item.alpha = 0.6;
				if (item.targetY == 0)
					item.alpha = 1;
			}
		}

		descText.text = creditsStuff[curSelected][2];
		descText.y = FlxG.height - descText.height + offsetThing - 60;

		if (moveTween != null)
			moveTween.cancel();
		moveTween = FlxTween.tween(descText, {y: descText.y + 75}, 0.25, {ease: FlxEase.sineOut});

		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
	}

	#if MODS_ALLOWED
	private var modsAdded:Array<String> = [];

	function pushModCreditsToList(folder:String)
	{
		if (modsAdded.contains(folder))
			return;

		var creditsFile:String = null;
		if (folder != null && folder.trim().length > 0)
			creditsFile = Paths.mods(folder + '/data/credits.txt');
		else
			creditsFile = Paths.mods('data/credits.txt');

		if (FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for (i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if (arr.length >= 5)
					arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
		modsAdded.push(folder);
	}
	#end

	function getCurrentBGColor()
	{
		var colors:Array<String> = creditsStuff[curSelected][4].split(',');
		return FlxColor.fromRGB(Std.parseInt(colors[0]), Std.parseInt(colors[1]), Std.parseInt(colors[2]));
	}

	private function unselectableCheck(num:Int):Bool
		return creditsStuff[num].length <= 1;
}
