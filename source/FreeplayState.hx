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
import flixel.input.mouse.FlxMouseEventManager;
import flash.events.MouseEvent;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import WeekData;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;

	private static var curSelected:Int = 0;

	var curDifficulty:Int = -1;

	private static var lastDifficultyName:String = '';

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	public var qt_gas:FlxSprite;

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var lastSongLocation:Int; // Where to loop to when looping up.
	var lastSongColor:Int; // Just set to Cessation's colour. Used for when the background darkens to black as you descend.
	var amountToTakeAway:Int = 0; // How deep you are in the depths.
	var downLoopCounter:Int; // Starts at 0, but each time you loop around, will increment by 1. Once it reaches 10 or above, it will allow you to go into the depths. Resets if you go up even once.

	public static var usecontrols:Bool = true; // for some reason you can still use the controls when you reset your score???? -Luis

	// nvm persistentUpdate does that but since i put the camera zoom i will use usecontrols for more things -Luis

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		persistentUpdate = true;
		usecontrols = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length)
		{
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
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		WeekData.setDirectoryFromWeek();
		// addSong("Interlope", 0, 'invis', FlxColor.fromRGB(0, 0, 0));
		addSong("Carefree", 0, 'qt-menu', FlxColor.fromRGB(249, 64, 148));
		addSong("Careless", 0, 'qt_annoyed', FlxColor.fromRGB(100, 90, 90));
		addSong("Censory-Overload", 0, 'kb', FlxColor.fromRGB(69, 69, 69));
		// If beaten Story on Hard
		if (Achievements.achievementsMap.exists(Achievements.achievementsStuff[2][2]))
			addSong("Termination", 0, 'kb', FlxColor.fromRGB(255, 26, 26));
		// If beaten Termination or Termination-Classic
		if (Achievements.achievementsMap.exists(Achievements.achievementsStuff[3][2])
			|| Achievements.achievementsMap.exists(Achievements.achievementsStuff[4][2]))
			addSong("Cessation", 0, 'qtkb', FlxColor.fromRGB(130, 180, 255));

		lastSongLocation = songs.length - 1;
		lastSongColor = songs[lastSongLocation].color; // Keep this the same colour as Cessation!
		// If beaten cessation:
		if (Achievements.achievementsMap.exists(Achievements.achievementsStuff[5][2]))
		{
			for (i in 0...20)
			{
				addSong("", 0, 'invis', FlxColor.fromRGB(0, 0, 0));
			}
			addSong("Interlope", 0, 'invis', FlxColor.fromRGB(0, 0, 0));
		}

		/*//KIND OF BROKEN NOW AND ALSO PRETTY USELESS//

			var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));
			for (i in 0...initSonglist.length)
			{
				if(initSonglist[i] != null && initSonglist[i].length > 0) {
					var songArray:Array<String> = initSonglist[i].split(":");
					addSong(songArray[0], 0, songArray[1], Std.parseInt(songArray[2]));
				}
		}*/

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			Paths.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
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

		#if PRELOAD_ALL
		if (!ClientPrefs.lowQuality)
		{
			qt_gas = new FlxSprite();
			qt_gas.frames = Paths.getSparrowAtlas('hazard/qt-port/stage/Gas_Release', 'shared'); // for some reason this returning null?
			qt_gas.animation.addByPrefix('burst', 'Gas_Release', 38, false);
			qt_gas.animation.addByPrefix('burstALT', 'Gas_Release', 49, false);
			qt_gas.animation.addByPrefix('burstFAST', 'Gas_Release', 76, false);
			qt_gas.animation.addByIndices('burstLoop', 'Gas_Release', [12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23], "", 38, true);
			qt_gas.setGraphicSize(Std.int(qt_gas.width * 1.8));
			qt_gas.antialiasing = ClientPrefs.globalAntialiasing;
			qt_gas.scrollFactor.set();
			qt_gas.alpha = 0.63;
			qt_gas.setPosition(450, 0);
			add(qt_gas);
		}
		#end

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
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));

		changeSelection();
		changeDiff();

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

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
		FlxG.camera.zoom = 1.1;
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	/*public function addWeek(songs:Array<String>, weekNum:Int, weekColor:Int, ?songCharacters:Array<String>)
		{
			if (songCharacters == null)
				songCharacters = ['bf'];

			var num:Int = 0;
			for (song in songs)
			{
				addSong(song, weekNum, songCharacters[num]);
				this.songs[this.songs.length-1].color = weekColor;

				if (songCharacters.length != 1)
					num++;
			}
	}*/
	var instPlaying:Int = -1;

	private static var vocals:FlxSound = null;

	var holdTime:Float = 0;

	public var instPlayingtxt:String = "N/A"; // its not really a text but who cares?

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7 && songs[curSelected].songName != "" && songs[curSelected].songName != "Interlope")
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		#if PRELOAD_ALL
		Conductor.songPosition = FlxG.sound.music.time;
		#end

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
		{ // Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

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
						{
							changeDiff(0, true);
						}
						else if (songs[curSelected].songName == "")
						{
							// v2.2 update: Scrolling isn't forcefully stopped now when scrolling down if you've already beaten Interlope to make accessing it easier.
							if (!Achievements.achievementsMap.exists(Achievements.achievementsStuff[10][2]))
								holdTime = 0; // Forces scrolling to stop on secret shit.
							changeDiff();
						}
						else
						{
							changeDiff();
						}
					}
				}
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				changeDiff();
			}

			if (controls.UI_LEFT_P)
				changeDiff(-1);
			else if (controls.UI_RIGHT_P)
				changeDiff(1);
			else if (upP || downP)
			{
				// Forces Termination to start on 'Very-Hard'
				if (songs[curSelected].songName.toLowerCase() == "termination")
				{
					changeDiff(0, true);
				}
				else
				{
					changeDiff();
				}
			}

			if (controls.BACK)
			{
				persistentUpdate = false;
				if (colorTween != null)
				{
					colorTween.cancel();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}

			if (ctrl)
			{
				openSubState(new GameplayChangersSubstate(true));
				usecontrols = false;
			}
			#if PRELOAD_ALL
			else if (space && songs[curSelected].songName != "" && songs[curSelected].songName != "Interlope")
			{
				if (instPlaying != curSelected)
				{
					destroyFreeplayVocals();
					FlxG.sound.music.volume = 0;
					Paths.currentModDirectory = songs[curSelected].folder;
					var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
					PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
					if (PlayState.SONG.needsVoices)
					{
						if (ClientPrefs.qtOldVocals)
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
					instPlayingtxt = songs[curSelected].songName.toLowerCase();
					FlxG.sound.list.add(vocals);
					FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
					vocals.play();
					vocals.persist = true;
					vocals.looped = true;
					vocals.volume = 0.7;
					instPlaying = curSelected;
				}
			}
			#end
		else if (accepted && songs[curSelected].songName != "")
		{
			persistentUpdate = false;
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
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
			usecontrols = false;
		}
		}
		super.update(elapsed);
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
		{
			curDifficulty = 1; // Cessation only has normal difficulty!
		}
		else
		{
			if (curDifficulty < 0)
				curDifficulty = CoolUtil.difficulties.length - 1;
			if (curDifficulty >= CoolUtil.difficulties.length)
				curDifficulty = 0;
		}

		if (songs[curSelected].songName.toLowerCase() != "termination"
			&& songs[curSelected].songName.toLowerCase() != "cessation"
			&& songs[curSelected].songName != ""
			&& songs[curSelected].songName != "Interlope") // i hate myself
		{
			switch (curDifficulty)
			{
				case 0:
					FlxTween.color(diffText, 0.3, diffText.color, FlxColor.GREEN, {ease: FlxEase.quadInOut});

				case 1:
					FlxTween.color(diffText, 0.3, diffText.color, FlxColor.YELLOW, {ease: FlxEase.quadInOut});

				case 2:
					FlxTween.color(diffText, 0.3, diffText.color, FlxColor.RED, {ease: FlxEase.quadInOut});

				case 3:
					FlxTween.color(diffText, 0.3, diffText.color, 0xFF960000, {ease: FlxEase.quadInOut});

				default:
					FlxTween.color(diffText, 0.3, diffText.color, FlxColor.WHITE, {ease: FlxEase.quadInOut});
			}
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
				diffText.text = '< Classic >';
				FlxTween.color(diffText, 0.3, diffText.color, FlxColor.RED, {ease: FlxEase.quadInOut});
			}
			else
			{
				diffText.text = '< Very Hard >';
				FlxTween.color(diffText, 0.3, diffText.color, 0xFF960000, {ease: FlxEase.quadInOut});
			}
		}
		else if (songs[curSelected].songName.toLowerCase() == "cessation")
		{
			diffText.text = '< Future >';
			FlxTween.color(diffText, 0.3, diffText.color, FlxColor.CYAN, {ease: FlxEase.quadInOut});
		}
		else if (songs[curSelected].songName == "")
		{
			diffText.text = '';
			FlxTween.color(diffText, 0.3, diffText.color, FlxColor.TRANSPARENT, {ease: FlxEase.quadInOut});
		}
		else if (songs[curSelected].songName == "Interlope")
		{
			diffText.text = '< ??? >';
			FlxTween.color(diffText, 0.3, diffText.color, FlxColor.RED, {ease: FlxEase.quadInOut});
		}
		else
		{
			diffText.text = '< ' + CoolUtil.difficultyString() + ' >';
		}

		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
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
		var targetCount:Int = Achievements.achievementsMap.exists(Achievements.achievementsStuff[10][2]) ? 5 : 9;
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
				if (Achievements.achievementsMap.exists(Achievements.achievementsStuff[5][2])) // Only adds to the downLoopCounter if you've beaten Cessation
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
		{
			amountToTakeAway = 0;
		}

		// decreasing volume when going down down down
		if (songs[curSelected].songName == "")
		{
			FlxG.sound.music.volume = 0.7 - amountToTakeAway * 0.05;
			if (vocals != null)
			{
				vocals.volume = 0.7 - amountToTakeAway * 0.05;
			}
		}
		else if (songs[curSelected].songName == "Interlope")
		{
			FlxG.sound.music.volume = 0;
			if (vocals != null)
			{
				vocals.volume = 0;
			}
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

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
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
			{
				CoolUtil.difficulties = diffs;
			}
		}

		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		// trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if (newPos > -1)
			curDifficulty = newPos;
	}

	private function positionHighscore()
	{
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	#if PRELOAD_ALL
	override function stepHit()
	{
		super.stepHit();
		if (amountToTakeAway < 1)
		{
			if (instPlayingtxt.toLowerCase() == "termination")
			{
				switch (curStep)
				{
					case 1:
						FlxG.camera.shake(0.002, 1);
					case 32:
						FlxG.camera.shake(0.002, 1);
					case 64:
						FlxG.camera.shake(0.002, 1);
					case 96:
						FlxG.camera.shake(0.002, 2);
					case 2808:
						FlxG.camera.shake(0.0075, 0.675);
				}
			}
		}
	}
	#end

	#if PRELOAD_ALL
	override function beatHit()
	{
		super.beatHit();
		if (amountToTakeAway < 1)
		{
			if (FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
				FlxG.camera.zoom += 0.015;

			switch (instPlayingtxt.toLowerCase())
			{
				case 'termination':
					if (curBeat >= 192 && curBeat <= 320) // 1st drop
					{
						if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
							FlxG.camera.zoom += 0.0075;
					}
					else if (curBeat >= 512 && curBeat <= 640) // 1st drop
					{
						if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
							FlxG.camera.zoom += 0.0075;
					}
					else if (curBeat >= 832 && curBeat <= 1088) // last drop
					{
						if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
							FlxG.camera.zoom += 0.0075;
					}
				case 'censory-overload':
					if (curBeat == 241 || curBeat == 249 || curBeat == 257 || curBeat == 265 || curBeat == 273 || curBeat == 281 || curBeat == 289
						|| curBeat == 293 || curBeat == 297 || curBeat == 301 || curBeat == 497 || curBeat == 505 || curBeat == 513 || curBeat == 521
						|| curBeat == 529 || curBeat == 537 || curBeat == 545 || curBeat == 549 || curBeat == 553 || curBeat == 557)
					{
						if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
							FlxG.camera.zoom += 0.0075;
					}
					if (curBeat >= 80 && curBeat <= 208) // first drop
					{
						if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
							FlxG.camera.zoom += 0.0075;
						if (curBeat % 16 == 0)
							Gas_Release('burst');
					}
					else if (curBeat >= 304 && curBeat <= 432) // second drop
					{
						if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
							FlxG.camera.zoom += 0.0075;

						// Gas Release effect
						if (curBeat % 8 == 0)
							Gas_Release('burstALT');
					}
					else if (curBeat >= 560 && curBeat <= 688)
					{ // third drop
						if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
							FlxG.camera.zoom += 0.0075;

						// Gas Release effect
						if (curBeat % 4 == 0)
							Gas_Release('burstFAST');
					}
					else if (curBeat == 702)
						Gas_Release('burst');
					else if (curBeat >= 832 && curBeat <= 960)
					{ // final drop
						if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
							FlxG.camera.zoom += 0.0075;

						// Gas Release effect
						if (curBeat % 4 == 2)
							Gas_Release('burstFAST');
					}
			}
		}
	}
	#end

	#if PRELOAD_ALL
	function Gas_Release(anim:String = 'burst')
	{
		if (!ClientPrefs.lowQuality)
			if (qt_gas != null)
				qt_gas.animation.play(anim);
	}
	#end
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
