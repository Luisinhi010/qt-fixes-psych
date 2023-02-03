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
		title = Locale.get("visualsUIOption");
		rpcTitle = 'Visuals & UI Settings Menu'; // for Discord Rich Presence

		var option:Option = new Option(Locale.get("localevisualsUIText"), Locale.get("localevisualsUIDesc"), 'locale', 'string', 'en-US',
			CoolUtil.coolTextFile(Paths.getPath('locale/list.txt', TEXT)));
		addOption(option);
		option.onChange = Locale.init;

		var option:Option = new Option(Locale.get("colorblindFiltervisualsUIText"), Locale.get("colorblindFiltervisualsUIDesc"), 'colorblindFilter', 'string',
			'NONE', ['NONE', "DEUTERANOPIA", "PROTANOPIA", "TRITANOPIA" /*, "BLACK & WHITE"*/]);
		#if debug option.description += "\nCan use a lot of resources in debug mode depending on system configuration, so it's recommended to lower the FPS cap."; #end
		option.onChange = lore.Colorblind.updateFilter;
		addOption(option);

		var option:Option = new Option(Locale.get("camMovevisualsUIText"), Locale.get("camMovevisualsUIDesc"), 'camMove', 'bool', true);
		addOption(option);

		var option:Option = new Option(Locale.get("flashingvisualsUIText"), Locale.get("flashingvisualsUIDesc"), 'flashing', 'bool', true);
		addOption(option);

		var option:Option = new Option(Locale.get("camZoomsvisualsUIText"), Locale.get("camZoomsvisualsUIDesc"), 'camZooms', 'bool', true);
		addOption(option);

		var option:Option = new Option(Locale.get("scoreZoomvisualsUIText"), Locale.get("scoreZoomvisualsUIDesc"), 'scoreZoom', 'bool', true);
		addOption(option);

		var option:Option = new Option(Locale.get("pauseMusicvisualsUIText"), Locale.get("pauseMusicvisualsUIDesc"), 'pauseMusic', 'string', 'Tea Time',
			['None', 'Breakfast', 'Tea Time']);
		addOption(option);
		option.onChange = onChangePauseMusic;

		var option:Option = new Option(Locale.get("comboStackingvisualsUIText"), Locale.get("comboStackingvisualsUIDesc"), 'comboStacking', 'bool', true);
		addOption(option);

		#if sys
		var option:Option = new Option(Locale.get("usePlayerUsernamevisualsUIText"), Locale.get("usePlayerUsernamevisualsUIDesc"), 'usePlayerUsername',
			'bool', false);
		addOption(option);
		#end

		#if !mobile
		var option:Option = new Option(Locale.get("showFPSvisualsUIText"), Locale.get("showFPSvisualsUIDesc"), 'showFPS', 'bool', true);
		addOption(option);

		var option:Option = new Option(Locale.get("showMEMvisualsUIText"), Locale.get("showMEMvisualsUIDesc"), 'showMEM', 'bool',
			true); // Show Mem Pr: https://github.com/ShadowMario/FNF-PsychEngine/pull/9554/
		addOption(option);

		var option:Option = new Option(Locale.get("showStatevisualsUIText"), Locale.get("showStatevisualsUIDesc"), 'showState', 'bool', false);
		addOption(option);
		#end

		super();
	}

	var changedMusic:Bool = false;

	function onChangePauseMusic()
	{
		if (ClientPrefs.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic)));

		changedMusic = true;
	}

	override function destroy()
	{
		if (changedMusic)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		super.destroy();
	}
}
