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

class GameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Locale.get("gameplayOption");
		rpcTitle = 'Gameplay Settings Menu'; // for Discord Rich Presence

		var option:Option = new Option(Locale.get("qtOldVocalsgameplayText"), Locale.get("qtOldVocalsgameplayDesc"), 'qtOldVocals', 'bool', false);
		addOption(option);

		var option:Option = new Option(Locale.get("qtSkipCutscenegameplayText"), Locale.get("qtSkipCutscenegameplayDesc"), 'qtSkipCutscene', 'bool', false);
		addOption(option);

		var option:Option = new Option(Locale.get("hitsoundVolumegameplayText"), Locale.get("hitsoundVolumegameplayDesc"), 'hitsoundVolume', 'percent', 0);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = onChangeHitsoundVolume;
		addOption(option);

		var option:Option = new Option(Locale.get("ghostTappinggameplayText"), Locale.get("ghostTappinggameplayDesc"), 'ghostTapping', 'bool', true);
		addOption(option);

		#if desktop
		var option:Option = new Option(Locale.get("autoPausegameplayText"), Locale.get("autoPausegameplayDesc"), 'autoPause', 'bool', true);
		addOption(option);

		option.onChange = onToggleAutoPause;
		#end

		var option:Option = new Option(Locale.get("noResetgameplayText"), Locale.get("noResetgameplayDesc"), 'noReset', 'bool', false);
		addOption(option);

		var option:Option = new Option(Locale.get("controllerModegameplayText"), Locale.get("controllerModegameplayDesc"), 'controllerMode', 'bool', false);
		addOption(option);

		var option:Option = new Option(Locale.get("ratingOffsetgameplayText"), Locale.get("ratingOffsetgameplayDesc"), 'ratingOffset', 'int', 0);
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		var option:Option = new Option(Locale.get("sickWindowgameplayText"), Locale.get("sickWindowgameplayDesc"), 'sickWindow', 'int', 45);
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 15;
		option.maxValue = 45;
		addOption(option);

		var option:Option = new Option(Locale.get("goodWindowgameplayText"), Locale.get("goodWindowgameplayDesc"), 'goodWindow', 'int', 90);
		option.displayFormat = '%vms';
		option.scrollSpeed = 30;
		option.minValue = 15;
		option.maxValue = 90;
		addOption(option);

		var option:Option = new Option(Locale.get("badWindowgameplayText"), Locale.get("badWindowgameplayDesc"), 'badWindow', 'int', 135);
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 135;
		addOption(option);

		var option:Option = new Option(Locale.get("safeFramesgameplayText"), Locale.get("safeFramesgameplayDesc"), 'safeFrames', 'float', 10);
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option(Locale.get("inputSystemgameplayText"), Locale.get("inputSystemgameplayDesc"), 'inputSystem', 'string', 'Psych',
			['Kade', 'Psych']);
		addOption(option);

		var option:Option = new Option(Locale.get("qtBonkgameplayText"), Locale.get("qtBonkgameplayDesc"), 'qtBonk', 'bool', false);
		addOption(option);
		super();
	}

	#if desktop
	function onToggleAutoPause()
	{
		FlxG.autoPause = ClientPrefs.autoPause;
	}
	#end

	function onChangeHitsoundVolume()
		FlxG.sound.play(Paths.sound('ChartingTick'), ClientPrefs.hitsoundVolume);
}
