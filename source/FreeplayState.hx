package;

import flixel.FlxObject;
#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import lime.utils.Assets;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import WeekData;
#if MODS_ALLOWED
#if cpp import sys.FileSystem; #end
#end
using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	private static var curSelected:Int = 0;

	var curDifficulty:Int = -1;

	private static var lastDifficultyName:String = '';

	public var scoreBG:FlxSprite;
	public var scoreText:FlxText;
	public var diffText:FlxText;
	public var lerpScore:Int = 0;
	public var lerpRating:Float = 0;
	public var intendedScore:Int = 0;
	public var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;

	public static var curPlaying:Bool = false;

	public static var curInstPlaying:Int = -1;
	public static var curInstPlayingtxt:String = "N/A";

	public var instPlaying:Int = -1; // script handler doesnt work with static var for some reason?
	public var instPlayingtxt:String = "N/A"; // its not really a text but who cares?

	public var iconArray:Array<HealthIcon> = [];

	public var bg:FlxSprite;
	public var intendedColor:Int;
	public var colorTween:FlxTween;
	public var scorecolorDifficulty:Map<String, FlxColor> = [
		'EASY' => FlxColor.GREEN,
		'NORMAL' => FlxColor.YELLOW,
		'HARD' => FlxColor.RED,
		'HARDER' => 0xFF960000
	];
	public var curStringDifficulty:String = 'NORMAL';

	public var lastSongLocation:Int; // Where to loop to when looping up.
	public var lastSongColor:Int; // Just set to Cessation's colour. Used for when the background darkens to black as you descend.
	public var amountToTakeAway:Int = 0; // How deep you are in the depths.
	public var downLoopCounter:Int; // Starts at 0, but each time you loop around, will increment by 1. Once it reaches 10 or above, it will allow you to go into the depths. Resets if you go up even once.

	public var menuScript:ScriptHandler;
	public var bgPath:String = 'menuDesat';

	public static var usecontrols:Bool = true; // for some reason you can still use the controls when you reset your score???? -Luis

	// nvm persistentUpdate does that but since i put the camera zoom i will use usecontrols for more things -Luis

	override function create()
	{
		// Paths.clearStoredMemory();
		// Paths.clearUnusedMemory();
		instPlaying = curInstPlaying;
		instPlayingtxt = curInstPlayingtxt;

		persistentUpdate = usecontrols = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		DiscordClient.changePresence("In the Menus", null);
		#end

		menuScript = new ScriptHandler(Paths.Script('FreeplayState'));

		menuScript.setVar('FreeplayState', this);
		menuScript.setVar('add', add);
		menuScript.setVar('insert', insert);
		menuScript.setVar('members', members);
		menuScript.setVar('remove', remove);

		menuScript.callFunc('create', []);

		var createOver:Dynamic = menuScript.callFunc('overrideCreate', []);
		if (createOver != null)
			return;

		for (i in 0...WeekData.weeksList.length)
		{
			if (weekIsLocked(WeekData.weeksList[i]))
				continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if (colors == null || colors.length < 3)
					colors = [146, 113, 253];
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		WeekData.loadTheFirstEnabledMod();
		// addSong("Interlope", 0, 'invis', FlxColor.fromRGB(0, 0, 0));
		addSong("Carefree", 0, 'qt-menu', FlxColor.fromRGB(249, 64, 148));
		addSong("Careless", 0, 'qt_annoyed', FlxColor.fromRGB(100, 90, 90));
		addSong("Censory-Overload", 0, 'kb', FlxColor.fromRGB(69, 69, 69));
		if (Achievements.isAchievementUnlocked('qtweek_hard'))
			addSong("Termination", 0, 'kb', FlxColor.fromRGB(255, 26, 26));
		if (Achievements.isAchievementUnlocked('termination_beat') || Achievements.isAchievementUnlocked('termination_old'))
			addSong("Cessation", 0, 'qtkb', FlxColor.fromRGB(130, 180, 255));

		lastSongLocation = songs.length - 1;
		lastSongColor = songs[lastSongLocation].color; // Keep this the same colour as Cessation!
		if (Achievements.isAchievementUnlocked('cessation_beat'))
		{
			for (i in 0...20)
				addSong("", 0, 'invis', FlxColor.fromRGB(0, 0, 0));
			addSong("Interlope", 0, 'invis', FlxColor.fromRGB(0, 0, 0));
		}

		bg = new FlxSprite().loadGraphic(Paths.image(bgPath));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.isMenuItem = true;
			songText.targetY = i - curSelected;
			grpSongs.add(songText);

			var maxWidth = 980;
			if (songText.width > maxWidth)
				songText.scaleX = maxWidth / songText.width;

			songText.snapToPosition();

			Paths.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			icon.canBounce = true;
			if (curPlaying && i == curInstPlaying)
			{
				if (icon.hasWinning)
					icon.animation.curAnim.curFrame = 2;
			}
			iconArray.push(icon);
			add(icon);
		}
		WeekData.setDirectoryFromWeek();
		for (k => s in songs)
		{
			if (s.songName.toLowerCase() == FlxG.save.data.lastSelectedSong)
			{
				curSelected = k;
				break;
			}
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		if (curSelected >= songs.length)
			curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		if (lastDifficultyName == '')
			lastDifficultyName = CoolUtil.defaultDifficulty;

		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));

		changeSelection();
		changeDiff();

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);
		super.create();
		menuScript.callFunc('postCreate', []);
	}

	override function closeSubState()
	{
		menuScript.callFunc('closeSubState', []);
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked
			&& leWeek.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	public static var vocals:FlxSound = null;

	public var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		menuScript.callFunc('update', [elapsed]);

		var setupOver:Dynamic = menuScript.callFunc('overrideUpdate', [elapsed]);
		if (setupOver != null)
			return;

		if (FlxG.sound.music.volume < 0.7 && songs[curSelected].songName != "" && songs[curSelected].songName != "Interlope")
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if (vocals != null)
				vocals.volume = FlxG.sound.music.volume;
		}

		Conductor.songPosition = FlxG.sound.music.time;

		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if (ratingSplit.length < 2)
		{ // No decimals, add an empty space
			ratingSplit.push('');
		}

		while (ratingSplit[1].length < 2)
			ratingSplit[1] += '0';

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		if (usecontrols)
		{
			var upP = controls.UI_UP_P;
			var downP = controls.UI_DOWN_P;
			var accepted = controls.ACCEPT;
			var space = FlxG.keys.justPressed.SPACE;
			var ctrl = FlxG.keys.justPressed.CONTROL;

			var shiftMult:Int = 1;
			// if(FlxG.keys.pressed.SHIFT) shiftMult = 3; //No shift multiplier because there isn't that many songs + paranoid about it breaking interlope secret pacing

			if (songs.length > 1)
			{
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

				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
						// Makes sure the difficulty text is updated when holding down.
						// Forces Termination to start on 'Very-Hard'
						if (songs[curSelected].songName.toLowerCase() == "termination")
							changeDiff(0, true);
						else if (songs[curSelected].songName == "")
						{
							// v2.2 update: Scrolling isn't forcefully stopped now when scrolling down if you've already beaten Interlope to make accessing it easier.
							if (!Achievements.isAchievementUnlocked('freeplay_depths'))
								holdTime = 0; // Forces scrolling to stop on secret shit.
							changeDiff();
						}
						else
							changeDiff();
					}
				}

				if (FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					if (FlxG.keys.pressed.SHIFT)
						changeDiff(FlxG.mouse.wheel);
					else
						changeSelection(-FlxG.mouse.wheel, false);
					changeDiff();
				}
			}

			if (controls.UI_LEFT_P)
				changeDiff(-1);
			else if (controls.UI_RIGHT_P)
				changeDiff(1);
			else if (upP || downP)
			{
				// Forces Termination to start on 'Very-Hard'
				if (songs[curSelected].songName.toLowerCase() == "termination")
					changeDiff(0, true);
				else
					changeDiff();
			}

			if (controls.BACK || FlxG.mouse.justPressedRight #if android || FlxG.android.justReleased.BACK #end)
			{
				persistentUpdate = false;
				if (colorTween != null)
					colorTween.cancel();

				if (songs[curSelected].songName != "interlope" && songs[curSelected].songName != "")
					FlxG.save.data.lastSelectedSong = songs[curSelected].songName.toLowerCase();
				else
					FlxG.save.data.lastSelectedSong = 'tutorial';

				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}

			if (ctrl)
			{
				openSubState(new GameplayChangersSubstate(true));
				usecontrols = false;
			}
			else if ((space || FlxG.mouse.justPressedMiddle)
				&& songs[curSelected].songName != ""
				&& songs[curSelected].songName != "Interlope")
			{
				if (curInstPlaying != curSelected)
				{
					#if PRELOAD_ALL
					destroyFreeplayVocals();
					FlxG.sound.music.volume = 0;
					Paths.currentModDirectory = songs[curSelected].folder;
					var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
					PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
					if (PlayState.SONG.needsVoices)
					{
						if (ClientPrefs.qtOldVocals && PlayState.SONG.haveoldvoices)
							vocals = new FlxSound().loadEmbedded(Paths.voicesCLASSIC(PlayState.SONG.song));
						else
							vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
					}
					else
						vocals = new FlxSound();

					PlayState.THISISFUCKINGDISGUSTINGPLEASESAVEME = false; // Forces playstate to not have this to true so it stops CoolUtil from breaking difficulty selection (or something). IDFK IT JUST WORKS SHUT UP I DON'T WANT FUCKING TO TALK ABOUT THIS VARIABLE

					Conductor.songPosition = FlxG.sound.music.time;
					Conductor.mapBPMChanges(PlayState.SONG);
					Conductor.changeBPM(PlayState.SONG.bpm);
					curInstPlayingtxt = instPlayingtxt = songs[curSelected].songName.toLowerCase();
					FlxG.sound.list.add(vocals);
					FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
					vocals.play();
					vocals.persist = true;
					vocals.looped = true;
					vocals.volume = 0.7;
					curInstPlaying = instPlaying = curSelected;
					for (i in 0...iconArray.length)
						iconArray[i].animation.curAnim.curFrame = 0;
					iconArray[curInstPlaying].bounce();
					if (iconArray[curInstPlaying].hasWinning)
						iconArray[curInstPlaying].animation.curAnim.curFrame = 2;
					curPlaying = true;
					#end
				}
			}
			else if ((accepted || FlxG.mouse.justPressed) && songs[curSelected].songName != "")
			{
				persistentUpdate = false;
				curInstPlayingtxt = instPlayingtxt = '';
				curPlaying = false;
				curInstPlaying = instPlaying = -1;
				var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
				var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
				trace(poop);

				PlayState.SONG = Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;

				if (songs[curSelected].songName != "interlope")
					FlxG.save.data.lastSelectedSong = songs[curSelected].songName.toLowerCase(); // dont kill me yoshi
				else
					FlxG.save.data.lastSelectedSong = 'tutorial';

				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
				if (colorTween != null)
					colorTween.cancel();

				if (FlxG.keys.pressed.SHIFT)
					LoadingState.loadAndSwitchState(new ChartingState());
				else
					LoadingState.loadAndSwitchState(new PlayState());

				FlxG.sound.music.volume = 0;

				destroyFreeplayVocals();
			}
			else if (controls.RESET && songs[curSelected].songName != "")
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
		}
		super.update(elapsed);
		menuScript.callFunc('postUpdate', [elapsed]);
	}

	public static function destroyFreeplayVocals()
	{
		if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0, ?jank:Bool = false)
	{
		menuScript.callFunc('changeDiff', [change]);
		if (jank)
			curDifficulty = 1;
		else
			curDifficulty += change;

		if (songs[curSelected].songName.toLowerCase() == "termination")
		{
			// Termination only has 'normal' and 'hard'. hard is used for termination classic
			if (curDifficulty < 1)
				curDifficulty = 2;
			if (curDifficulty > 2)
				curDifficulty = 1;
		}
		else if (songs[curSelected].songName.toLowerCase() == "cessation" || songs[curSelected].songName.toLowerCase() == "interlope")
			curDifficulty = 1; // Cessation only has normal difficulty!
		else
		{
			if (curDifficulty < 0)
				curDifficulty = CoolUtil.difficulties.length - 1;
			if (curDifficulty >= CoolUtil.difficulties.length)
				curDifficulty = 0;
		}

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		if (songs[curSelected].songName.toLowerCase() == "termination")
		{
			if (curDifficulty == 2)
			{
				curStringDifficulty = 'CLASSIC';
				diffText.text = '< ' + curStringDifficulty + ' >';
			}
			else
			{
				curStringDifficulty = 'VERY HARD';
				diffText.text = '< ' + curStringDifficulty + ' >';
			}
		}
		else if (songs[curSelected].songName.toLowerCase() == "cessation")
		{
			curStringDifficulty = 'FUTURE';
			diffText.text = '< ' + curStringDifficulty + ' >';
		}
		else if (songs[curSelected].songName == "")
		{
			curStringDifficulty = '';
			diffText.text = curStringDifficulty;
		}
		else if (songs[curSelected].songName == "Interlope")
		{
			curStringDifficulty = '???';
			diffText.text = '< ' + curStringDifficulty + ' >';
		}
		else
		{
			curStringDifficulty = CoolUtil.difficultyString();
			diffText.text = '< ' + curStringDifficulty + ' >';
		}

		FlxTween.color(diffText, 0.3, diffText.color,
			scorecolorDifficulty.exists(curStringDifficulty) ? scorecolorDifficulty.get(curStringDifficulty) : FlxColor.WHITE, {
				ease: FlxEase.quadInOut
			});

		positionHighscore();
		menuScript.callFunc('postChangeDiff', [change]);
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		menuScript.callFunc('changeSelection', [change]);
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
		{
			downLoopCounter = 0; // Resets if you loop upwards instead.
			curSelected = lastSongLocation;
			amountToTakeAway = 0;
		}

		// v2.2 update, It's now much quicker to access Interlope if you've already beaten it (if beaten, targetCount is 5, otherwise it'll be 9.).
		var targetCount:Int = Achievements.isAchievementUnlocked('freeplay_depths') ? 5 : 9;
		if (downLoopCounter >= targetCount)
		{
			if (curSelected >= songs.length)
			{
				downLoopCounter = 11; // Won't go any higher to avoid some overflow bullshit if somebody tried hard enough.
				curSelected = 0;
				amountToTakeAway = 0;
			}
		}
		else
		{
			if (curSelected > lastSongLocation)
			{
				if (Achievements.isAchievementUnlocked('cessation_beat')) // Only adds to the downLoopCounter if you've beaten Cessation
					downLoopCounter++; // Add 1 to the downLoopCounter.
				curSelected = 0;
				amountToTakeAway = 0;
			}
		}

		if (songs[curSelected].songName == "" || songs[curSelected].songName == "Interlope")
		{
			if (change > 0)
				amountToTakeAway++;
			if (change < 0)
				amountToTakeAway--;
		}
		else
			amountToTakeAway = 0;

		// decreasing volume when going down down down
		if (songs[curSelected].songName == "")
		{
			FlxG.sound.music.volume = 0.7 - amountToTakeAway * 0.05;
			if (vocals != null)
				vocals.volume = 0.7 - amountToTakeAway * 0.05;
		}
		else if (songs[curSelected].songName == "Interlope")
		{
			FlxG.sound.music.volume = 0;
			if (vocals != null)
				vocals.volume = 0;
		}

		if (songs[curSelected].songName != "")
		{
			var newColor:Int = songs[curSelected].color;
			if (newColor != intendedColor)
			{
				if (colorTween != null)
				{
					colorTween.cancel();
				}
				intendedColor = newColor;
				colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
					onComplete: function(twn:FlxTween)
					{
						colorTween = null;
					}
				});
			}
		}
		else
		{
			// darken BG
			colorTween = FlxTween.color(bg, 0.5, bg.color,
				FlxColor.subtract(lastSongColor, FlxColor.fromRGB(amountToTakeAway * 17, amountToTakeAway * 17, amountToTakeAway * 17, 0)), {
					onComplete: function(twn:FlxTween)
					{
						colorTween = null;
					}
				});
		}

		if (amountToTakeAway > 0)
			trace("Shit to take away: " + amountToTakeAway);

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
			iconArray[i].alpha = 0.6;

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}

		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if (diffStr != null)
			diffStr = diffStr.trim(); // Fuck you HTML5

		if (diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if (diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if (diffs[i].length < 1)
						diffs.remove(diffs[i]);
				}
				--i;
			}

			if (diffs.length > 0 && diffs[0].length > 0)
				CoolUtil.difficulties = diffs;
		}

		if (CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		else
			curDifficulty = 0;

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		if (newPos > -1)
			curDifficulty = newPos;
		menuScript.callFunc('postChangeSelection', [change]);
	}

	private function positionHighscore()
	{
		menuScript.callFunc('positionHighscore', []);
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	override function beatHit()
	{
		super.beatHit();
		menuScript.callFunc('beatHit', [curBeat]);
		if (curPlaying)
		{
			if (iconArray != null)
				if (iconArray[curInstPlaying] != null)
					iconArray[curInstPlaying].bounce(); // xd --BedrockEngine Luis, xd indeed. -Luis now
			// https://github.com/Luisinhi010/FNF-BedrockEngine-Legacy/blob/9c750504dfe6f65b746600d138c23f9b24f991d8/source/meta/state/menus/FreeplayState.hx#L428
			/**
			 * good times. -Luis
			 */
			if (amountToTakeAway < 1 && ClientPrefs.camZooms && curBeat % 4 == 0)
				FlxG.camera.zoom += 0.015;
		}
	}

	override function stepHit()
	{
		super.stepHit();
		menuScript.callFunc('stepHit', [curStep]);
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Paths.currentModDirectory;
		if (this.folder == null)
			this.folder = '';
	}
}
