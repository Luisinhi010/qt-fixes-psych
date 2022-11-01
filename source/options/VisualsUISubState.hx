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

class VisualsUISubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu'; // for Discord Rich Presence

		var option:Option = new Option('Note Splashes', "If unchecked, hitting \"Sick!\" notes won't show particles.", 'noteSplashes', 'bool', true);
		addOption(option);

		var option:Option = new Option('Hurt note transparency', "Allows you to customise how opaque the hurt notes are to allow you to read charts easier.",
			'hurtNoteAlpha', 'percent', 1);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Lane Underlay', 'If unchecked, will appear a Lane Underlay.', 'laneunderlay', 'bool', false);
		addOption(option);

		var option:Option = new Option('Lane Underlay transparency', "Allows you to customise how opaque the Lane Underlay are.", 'laneunderlayAlpha',
			'percent', 0.6);
		option.scrollSpeed = 1.6;
		option.minValue = 0.1;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Camera Movement', 'If unchecked, the camera won\'t move when you hit a note.', 'camMove', 'bool', true);
		addOption(option);

		var option:Option = new Option('Show Time Bar', 'If checked, will show the bar showing\n how much time was elapsed/song name/song length.', 'timeBar',
			'bool', true);
		addOption(option);

		var option:Option = new Option('Flashing Lights', "Uncheck this if you're sensitive to flashing lights!", 'flashing', 'bool', true);
		addOption(option);

		var option:Option = new Option('Camera Zooms', "If unchecked, the camera won't zoom in on a beat hit.", 'camZooms', 'bool', true);
		addOption(option);

		var option:Option = new Option('Score Text Zoom on Hit', "If unchecked, disables the Score text zooming\neverytime you hit a note.", 'scoreZoom',
			'bool', true);
		addOption(option);

		var option:Option = new Option('Icon Colored Health Bar', "If unchecked, the health bar will have set colors\nrather than colors based on the icons.",
			'coloredHealthBar', 'bool', true);
		addOption(option);

		var option:Option = new Option('Short Score text', "If checked, Makes the Score text shorter, \nshowing only Score and Misses", 'short', 'bool',
			false);
		addOption(option);

		var option:Option = new Option('Health Bar Transparency', 'How much transparent should the health bar and icons be.', 'healthBarAlpha', 'percent', 1);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		#if !mobile
		var option:Option = new Option('FPS Counter', 'If unchecked, hides the FPS Counter.', 'showFPS', 'bool', true);
		addOption(option);

		var option:Option = new Option('Memory Counter', 'If unchecked, hides the Memory Counter.', 'showMEM', 'bool',
			true); // Show Mem Pr: https://github.com/ShadowMario/FNF-PsychEngine/pull/9554/
		addOption(option);

		var option:Option = new Option('Show Current State',
			"Whether to display the current state and substate of the game example: \n(State: options.OptionsState) \n(SubState: options.VisualsUISubState)",
			'showState', 'bool', false);
		addOption(option);
		#end

		/*#if sys
			var option:Option = new Option("Use username", "If checked, this mod will\nuse your computer's username \nin some menus", 'usePlayerUsername', 'bool',
				false);
			addOption(option);
			#end */

		super();
	}
}
