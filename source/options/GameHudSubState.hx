package options;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;

using StringTools;

class GameHudSubState extends BaseOptionsMenu
{
	public var strumLineNotes:FlxTypedGroup<StrumNote> = null;

	public function new()
	{
		title = Locale.get("gameHUDOption");
		rpcTitle = 'Game Hud Settings Menu'; // for Discord Rich Presence

		var option:Option = new Option(Locale.get("noteSplashesgamehudText"), Locale.get("noteSplashesgamehudDesc"), 'noteSplashes', 'bool', true);
		addOption(option);

		var option:Option = new Option(Locale.get("hurtNoteAlphagamehudText"), Locale.get("hurtNoteAlphagamehudDesc"), 'hurtNoteAlpha', 'percent', 1);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option(Locale.get("downScrollgamehudText"), Locale.get("downScrollgamehudDesc"), 'downScroll', 'bool', false);
		option.onChange = reposNotes;
		addOption(option);

		var option:Option = new Option(Locale.get("middleScrollgamehudText"), Locale.get("middleScrollgamehudDesc"), 'middleScroll', 'bool', false);
		option.onChange = reposNotes;
		addOption(option);

		var option:Option = new Option(Locale.get("opponentStrumsgamehudText"), Locale.get("opponentStrumsgamehudDesc"), 'opponentStrums', 'bool', true);
		addOption(option);

		var option:Option = new Option(Locale.get("laneunderlaygamehudText"), Locale.get("laneunderlaygamehudDesc"), 'laneunderlay', 'bool', false);
		addOption(option);

		var option:Option = new Option(Locale.get("laneunderlayAlphagamehudText"), Locale.get("laneunderlayAlphagamehudDesc"), 'laneunderlayAlpha', 'percent',
			0.6);
		option.scrollSpeed = 1.6;
		option.minValue = 0.1;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option(Locale.get("timeBargamehudText"), Locale.get("timeBargamehudDesc"), 'timeBar', 'bool', true);
		addOption(option);

		var option:Option = new Option(Locale.get("timeBarUigamehudText"), Locale.get("timeBarUigamehudDesc"), 'timeBarUi', 'string', 'Psych Engine',
			['Qt Fixes', 'Psych Engine', 'Kade Engine']);
		addOption(option);

		var option:Option = new Option(Locale.get("coloredHealthBargamehudText"), Locale.get("coloredHealthBargamehudDesc"), 'coloredHealthBar', 'bool', true);
		addOption(option);

		var option:Option = new Option(Locale.get("healthBarAlphagamehudText"), Locale.get("healthBarAlphagamehudDesc"), 'healthBarAlpha', 'percent', 1);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		super();
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		generateStaticArrows();
		insert(members.indexOf(descBox) - 1, strumLineNotes);
	}

	private function generateStaticArrows():Void
		for (i in 0...4)
		{
			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? -278 : 48, ClientPrefs.downScroll ? 570 : 50, i, 1, 'NOTE_assets');
			babyArrow.downScroll = ClientPrefs.downScroll;
			babyArrow.scrollFactor.set();
			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}

	public function reposNotes()
		for (i in 0...4)
		{
			strumLineNotes.members[i].x = ClientPrefs.middleScroll ? -278 : 48;
			strumLineNotes.members[i].y = ClientPrefs.downScroll ? 570 : 50;
			strumLineNotes.members[i].postAddedToGroup();
		}
}
