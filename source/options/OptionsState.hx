package options;

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
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

using StringTools;

class OptionsState extends MusicBeatState
{
	static var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals and UI',
		'Gameplay',
		'Game Hud'
	];

	private var grpOptions:FlxTypedGroup<Alphabet>;

	public static var things:Map<String, Void->Void>;

	public static var pauseMenu:Bool = false;

	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;

	function openSelectedSubstate(label:String)
	{
		/*switch (label)
			{
				case 'Note Colors':
					openSubState(new options.NotesSubState());
				case 'Controls':
					openSubState(new options.ControlsSubState());
				case 'Graphics':
					openSubState(new options.GraphicsSettingsSubState());
				case 'Visuals and UI':
					openSubState(new options.VisualsUISubState());
				case 'Game Hud':
					openSubState(new options.GameHudSubState());
				case 'Gameplay':
					openSubState(new options.GameplaySettingsSubState());
				case 'Adjust Delay and Combo':
					LoadingState.loadAndSwitchState(new options.NoteOffsetState());
		}*/
		things.get(label)();
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create()
	{
		options = [
			Locale.get("noteColorsOption"),
			Locale.get("controlsOption"),
			Locale.get("delayOption"),
			Locale.get("graphicsOption"),
			Locale.get("visualsUIOption"),
			Locale.get("gameplayOption"),
			Locale.get("gameHUDOption")
		];
		things = [
			options[0] => function() openSubState(new options.NotesSubState()),
			options[1] => function() openSubState(new options.ControlsSubState()),
			options[2] => function() LoadingState.loadAndSwitchState(new options.NoteOffsetState()),
			options[3] => function() openSubState(new options.GraphicsSettingsSubState()),
			options[4] => function() openSubState(new options.VisualsUISubState()),
			options[5] => function() openSubState(new options.GameplaySettingsSubState()),
			options[6] => function() openSubState(new options.GameHudSubState())
		];

		#if desktop
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.updateHitbox();

		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.scaleX = 0.9;
			optionText.scaleY = 0.9;
			optionText.screenCenter();
			optionText.y += (90 * (i - (options.length / 2))) + 40;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		selectorLeft.scaleX = 0.9;
		selectorLeft.scaleY = 0.9;
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		selectorRight.scaleX = 0.9;
		selectorRight.scaleY = 0.9;
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);
		if (FlxG.mouse.wheel != 0)
			changeSelection(-FlxG.mouse.wheel);

		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (pauseMenu)
			{
				MusicBeatState.switchState(new PlayState());
				FlxG.sound.music.stop();
				pauseMenu = false;
			}
			else
				MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.ACCEPT || FlxG.mouse.justPressed)
			openSelectedSubstate(options[curSelected]);
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}
