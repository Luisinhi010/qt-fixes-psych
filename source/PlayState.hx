package;

import flixel.graphics.FlxGraphic;
#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.Shader;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
import Shaders;
#if sys
import sys.FileSystem;
#end

import hud.*;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4], // From 20% to 39%
		['Bad', 0.5], // From 40% to 49%
		['Bruh', 0.6], // From 50% to 59%
		['Meh', 0.69], // From 60% to 68%
		['Nice', 0.7], // 69%
		['Good', 0.8], // From 70% to 79%
		['Great', 0.9], // From 80% to 89%
		['Sick!', 1], // From 90% to 99%
		['Perfect!!', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];

	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var interlopeIntroTweens:Map<String, FlxTween> = new Map<String, FlxTween>(); // Added in v2.2 so that the custom arrow intro works if intro skip.
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var shader_chromatic_abberation:ChromaticAberrationEffect;
	public var camGameShaders:Array<ShaderEffect> = [];
	public var camHUDShaders:Array<ShaderEffect> = [];
	public var camGASShaders:Array<ShaderEffect> = [];
	public var camOtherShaders:Array<ShaderEffect> = [];

	// event variables
	private var isCameraOnForcedPos:Bool = false;

	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public var shaderUpdates:Array<Float->Void> = [];

	public static var curStage:String = '';
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;

	public var blueshader = new CustomBlueShader(); // its 'blue' shader but you can put any color for it, but default is blue

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<Dynamic> = [];

	private var strumLine:FlxSprite;

	// Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;

	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var maxHealth:Float = 0; // Totally not stolen from Lullaby lol
	public var combo:Int = 0;

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;

	public var endingSong:Bool = false;

	private var startingSong:Bool = false;
	
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camGAS:FlxCamera;
	public var camOther:FlxCamera;

	public var camDisplaceX:Float = 0;
	public var camDisplaceY:Float = 0; // might not use depending on result
	public var cameraSpeed:Float = 1;

	var camHudyshit:Float = 0;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;
	var wiggleShit:WiggleEffect = new WiggleEffect();

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var camX:Int = 0;
	public var camY:Int = 0;
	public var cameramove:Bool = true;
	public var forcecameramove:Bool = false;

	public var kbsawbladecamXdad:Int = 0;
	public var forcecameratoplayer2:Bool = false;

	public var defaultCamZoom:Float = 1.05;

	var dacamera:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;

	public var songLength:Float = 0;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	// Lua shit
	public static var instance:PlayState;

	public var luaArray:Array<FunkinLua> = [];

	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;

	// Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;
	var sawbladeHits:Int = 0;
	var tauntCounter:Int = 0;
	var cessationTrollDone:Bool = false;

	// HAZARD SHIT
	var godMode:Bool = false; // For testing shit.

	private var dodgeKey:Array<FlxKey>;
	private var tauntKey:Array<FlxKey>;

	var healthLossMultiplier:Float = 1;
	var healthGainMultiplier:Float = 1; // To make Termination health gain more... fair?
	var dadDrainHealth:Float = 0; // Because I like how the opponent takes health away when hitting notes in other mods, even if it isn't that much.
	var dadDrainHealthSustain:Bool = false; // Used in Censory-Overload Harder difficulty. Allows for sustain notes to drain health (at a massively reduced rate)

	// Ew. Don't talk about this please. This variable doesn't exist.
	public static var THISISFUCKINGDISGUSTINGPLEASESAVEME:Bool = true;

	var endingCutsceneDone:Bool = false; // To ensure that the ending dialogue doesn't repeat itself. Doing this because achievements kept restarting the dialogue.

	// Ported from Inhuman LMAO
	private var fogShitDEBUG:FogThing;
	private var fogShitGroup:FlxTypedGroup<FogThing>;
	var skippedIntro:Bool = false;
	var introSkip:Int = 0;
	var introSkipSprite:BGSprite;
	var discordDifficultyOverrideShouldUse:Bool = false;
	var discordDifficultyOverride:String = "???";

	public var inhumanSong:Bool = false;
	public var inhumancolor1:FlxColor;
	public var inhumancolor2:FlxColor;

	var disableDefaultCamZooming:Bool = false;
	var disableArrowIntro:Bool = false;
	public var forceMiddleScroll:Bool = false;
	var controlsPlayer2:Bool = false; // Set to true if you are doing modchart shit. Stops middle scroll from disabling player2's notes and the player can hit them as if they were player 1 notes (if that makes sense?)
	var causeOfDeath:String = 'health';

	// 'health' / null 	= death by health
	// 'hurt' 			= death by hurt note
	// 'sawblade' 		= death by sawblade
	// QT Week port
	var streetBG:FlxSprite;
	var qt_tv01:FlxSprite;
	var cessationTroll:FlxSprite;
	var streetBGerror:FlxSprite;
	var streetFrontError:FlxSprite;
	var bfDodging:Bool = false;
	var bfCanDodge:Bool = false;
	var bfDodgeTiming:Float = 0.222; // 0.22625 for single sawblades (most forgiving), 0.222 for double sawblade variation
	var bfDodgeCooldown:Float = 0.102; // 0.1135 for single sawblades (most forgiving), 0.102 for double sawblade variation
	var canSkipEndScreen:Bool = false; // This is set to true at the "thanks for playing" screen. Once true, in update, if enter is pressed it'll skip to the main menu.
	var kb_attack_alert:FlxSprite;
	var kb_attack_saw:FlxSprite;

	// For changing the visuals -Haz
	public var qtIsBlueScreened:Bool = false; // lmao this var is back in here

	public var pincer1:FlxSprite;
	public var pincer2:FlxSprite;
	public var pincer3:FlxSprite;
	public var pincer4:FlxSprite; // i would made the pincers a flx group but not now, but i really need to do it

	var pincers:Array<FlxSprite> = [];

	var hazardRandom:Int = 1; // This integer is randomised upon song start between 1-5.

	var qtSawbladeAdded:Bool = false;
	var qtAlertAdded:Bool = false;
	var freezeNotes:Bool = false; // Used for Terminate's ending
	var gfScared:Bool = false;
	var qtTVstate:Int = 0;

	/*
	 *	0 = static
	 *	1 = alert
	 *	2 = instructions part 1
	 *	3 = instructions part 2
	 *	9 = drop
	 *	4 = watch out
	 *	5 = brutality labs moment
	 *	6 = glitch
	 *	7 = bluescreen
	 *	8 = heart
	 *	69 or 420 = sus
	 */
	// More Inhuman-Port Shit
	var noteSpeen:Int = 0; // Used for interlope
	var opponentNoteColourChange:Bool = false; // Set to true to set the opponent notes red.
	var hazardModChartEffect:Int = 0;
	// 0 = no effect
	// 1 = scrolling to the side 			- 	Variable1 = speed
	// 2 = KB screen shake
	// 3 = Interlope main effect
	// 4 = Interlope scrolling effect		-	Variable1 = Lerp% (0 = no effect, 1 = full effect)
	// 5 = Interlope main effect + fake
	// 6 = ScrollSpeed Pulse effect
	// 7 = 'her' Spin Effect (oooooo I wonder what this is forrrr oooooooOOOOOOOOoooo~)
	var hazardModChartVariable1:Float = 0;

	public var hazardModChartDefaultStrumX:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0];
	public var hazardModChartDefaultStrumY:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0];

	var wiggleShitShowCAMERA:WiggleEffect = null;
	var wiggleShitShow:WiggleEffect = null;
	var interlopeChroma:ChromaticAberrationEffect = null;
	var interlopeChromaIntensity:Float = 0;
	var interlopeFadeinShader:TiltshiftEffect = null;
	var interlopeFadeinShaderIntensity:Float = 4;
	var interlopeFadeinShaderFading:Bool = false;

	var hazardBG:BGSprite;
	var hazardBGkb:FlxSprite; // Used for KB and Cinder's song
	var hazardBlack:BGSprite; // Black is ontop of camera!
	var hazardInterlopeLaugh:FlxSprite; // Used by Amelia in Interlope when taunting player
	var hazardOverlayShit:BGSprite;
	var luisOverlayShit:BGSprite;
	var luisOverlayWarning:BGSprite;
	var hazardBGpulsing:Bool = false; // Set to true to pulse the background in some sections.
	var interlopeIntroTween:FlxTween;
	var interlopeIntroTweenHUD:FlxTween;

	var hazardAlarmLeft:BGSprite;
	var hazardAlarmRight:BGSprite;

	public var luisModChartDefaultStrumY:Float = 0;

	// for censory overload
	var censoryChroma:ChromaticAberrationEffect = null;
	var censoryChromaIntensity:Float = 0;
	var qt_gas01:FlxSprite;
	var qt_gas02:FlxSprite;
	var qt_gaskb:FlxSprite; // haz had a ideia to make the gas came out of kb.

	// for more modcharts
	public var fancyModchartStrumX:Array<Float> = [0, 0];
	public var fancyModchartStrumY:Array<Float> = [0, 0];
	public var moreStrumX:Bool = false; // i dont remember why i put this here...

	// separating hud from PlayState because it's dumb as fuck to have it here
	public static var gameHUD:GameHUD;

	private var allUIs:Array<FlxCamera> = [];

	override public function create()
	{
		Paths.clearStoredMemory();

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));

		dodgeKey = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('qt_dodge'));
		tauntKey = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('qt_taunt'));

		Achievements.loadAchievements();

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		shader_chromatic_abberation = new ChromaticAberrationEffect();

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camGAS = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camGAS.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		allUIs.push(camHUD);

		// FlxG.cameras.reset(camGame);
		// FlxG.cameras.add(camHUD);
		// FlxG.cameras.add(camGAS);
		// FlxG.cameras.add(camOther);
		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.setDefaultDrawTarget(camHUD, false);
		FlxG.cameras.add(camGAS);
		FlxG.cameras.setDefaultDrawTarget(camGAS, false);
		FlxG.cameras.add(camOther);
		FlxG.cameras.setDefaultDrawTarget(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		// FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;
		// FlxG.cameras.setDefaultDrawTarget(camGame, true);

		camGAS.flashSprite.scaleY *= ClientPrefs.downScroll ? -1 : 1;
		// this is lazy but works ;) -Luis

		// camHUD.flashSprite.scaleX *= -1;

		for (camera in [camGame, camHUD, camGAS, camOther])
			camera.antialiasing = ClientPrefs.globalAntialiasing;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		BrutalityGameOverSubstate.resetVariables();
		causeOfDeath = 'health';
		THISISFUCKINGDISGUSTINGPLEASESAVEME = true;
		endingCutsceneDone = false;
		var songName:String = Paths.formatToSongPath(SONG.song);

		forceMiddleScroll = ClientPrefs.middleScroll;

		curStage = PlayState.SONG.stage;
		// trace('stage is: ' + curStage);
		if (PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1)
		{
			switch (songName)
			{
				case 'carefree':
					curStage = 'street-cute';
				case 'careless':
					curStage = 'street-real';
				case 'cessation':
					curStage = 'street-cessation';
				case 'censory-overload' | 'terminate':
					curStage = 'street-kb';
				case 'termination':
					curStage = 'street-termination';
				default:
					curStage = 'stage';
			}
		}

		var stageData:StageFile = StageData.getStageFile(curStage);
		if (stageData == null)
		{ // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100]
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': // Week 1
				disableDefaultCamZooming = true;
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);

				if (!ClientPrefs.lowQuality)
				{
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}

			// QT port
			case 'street-cessation':
				dadDrainHealth = 0.0116;
				healthLossMultiplier = 1.125;
				discordDifficultyOverrideShouldUse = true;
				discordDifficultyOverride = "Future";

				hazardBG = new BGSprite('hazard/qt-port/stage/streetBackCute', -750, -145, 0.95, 0.95);
				add(hazardBG);

				var streetFront:BGSprite = new BGSprite('hazard/qt-port/stage/streetFrontCute', -820, 710, 0.95, 0.95);
				streetFront.setGraphicSize(Std.int(streetFront.width * 1.15));
				streetFront.updateHitbox();
				add(streetFront);

				qt_tv01 = new FlxSprite();
				qt_tv01.frames = Paths.getSparrowAtlas('hazard/qt-port/stage/TV_V6');
				qt_tv01.animation.addByPrefix('idle', 'TV_Idle', 24, true);
				qt_tv01.animation.addByPrefix('alert', 'TV_Attention', 28, false);
				qt_tv01.animation.addByPrefix('sus', 'TV_sus', 24, true);
				qt_tv01.animation.addByPrefix('heart', 'TV_End', 24, false);
				qt_tv01.animation.addByPrefix('eye', 'TV_brutality', 24, true); // Replaced the hex eye with the brutality symbols for more accurate lore.
				qt_tv01.animation.addByPrefix('error', 'TV_Error', 24, true);
				qt_tv01.animation.addByPrefix('404', 'TV_Bluescreen', 24, true);
				qt_tv01.animation.addByPrefix('watch', 'TV_Watchout', 24, true);
				qt_tv01.animation.addByPrefix('drop', 'TV_Drop', 24, true);
				qt_tv01.animation.addByPrefix('instructions', 'TV_Instructions-Normal', 24, true);
				qt_tv01.animation.addByPrefix('gl', 'TV_GoodLuck', 24, true);
				qt_tv01.animation.addByPrefix('heart', 'TV_End', 24, false);
				qt_tv01.animation.addByPrefix('eyeRight', 'TV_eyeRight', 24, false);
				qt_tv01.animation.addByPrefix('eyeLeft', 'TV_eyeLeft', 24, false);
				qt_tv01.setPosition(-62, 540);
				qt_tv01.setGraphicSize(Std.int(qt_tv01.width * 1.2));
				qt_tv01.updateHitbox();
				qt_tv01.antialiasing = ClientPrefs.globalAntialiasing;
				qt_tv01.scrollFactor.set(0.9, 0.9);
				add(qt_tv01);
				qt_tv01.animation.play('heart');
				qtTVstate = 8;

				cessationTroll = new FlxSprite(-62, 540).loadGraphic(Paths.image('hazard/qt-port/justkidding'));
				cessationTroll.setGraphicSize(Std.int(cessationTroll.width * 0.9));
				cessationTroll.cameras = [camHUD];
				cessationTroll.x = FlxG.width - 950;
				cessationTroll.y = 205;

			case 'street-cute':
				dadDrainHealth = 0.011;
				healthLossMultiplier = 1.1;

				hazardBG = new BGSprite('hazard/qt-port/stage/streetBackCute', -750, -145, 0.95, 0.95);
				add(hazardBG);

				var streetFront:BGSprite = new BGSprite('hazard/qt-port/stage/streetFrontCute', -820, 710, 0.95, 0.95);
				streetFront.setGraphicSize(Std.int(streetFront.width * 1.15));
				streetFront.updateHitbox();
				add(streetFront);

				qt_tv01 = new FlxSprite(-62, 540).loadGraphic(Paths.image('hazard/qt-port/stage/TV_V2_off'));
				qt_tv01.setGraphicSize(Std.int(qt_tv01.width * 1.2));
				qt_tv01.updateHitbox();
				qt_tv01.antialiasing = true;
				qt_tv01.scrollFactor.set(0.9, 0.9);
				qt_tv01.active = false;
				add(qt_tv01);

			case 'street-real':
				dadDrainHealth = 0.0115;
				healthLossMultiplier = 1.125;

				hazardBG = new BGSprite('hazard/qt-port/stage/streetBack', -750, -145, 0.95, 0.95);
				add(hazardBG);

				var streetFront:FlxSprite = new FlxSprite(-820, 710).loadGraphic(Paths.image('hazard/qt-port/stage/streetFront'));
				streetFront.setGraphicSize(Std.int(streetFront.width * 1.15));
				streetFront.updateHitbox();
				streetFront.antialiasing = ClientPrefs.globalAntialiasing;
				streetFront.scrollFactor.set(0.95, 0.95);
				streetFront.active = false;
				add(streetFront);

				qt_tv01 = new FlxSprite();
				qt_tv01.frames = Paths.getSparrowAtlas('hazard/qt-port/stage/TV_V6');
				qt_tv01.animation.addByPrefix('idle', 'TV_Idle', 24, true);
				qt_tv01.animation.addByPrefix('alert', 'TV_Attention', 26, false);
				// qt_tv01.animation.addByPrefix('eye', 'TV_eyes', 24, true);
				qt_tv01.animation.addByPrefix('eye', 'TV_brutality', 24, true); // Replaced the hex eye with the brutality symbols for more accurate lore.
				qt_tv01.animation.addByPrefix('eyeLeft', 'TV_eyeLeft', 24, false);
				qt_tv01.animation.addByPrefix('eyeRight', 'TV_eyeRight', 24, false);
				qt_tv01.animation.addByPrefix('error', 'TV_Error', 24, true);
				qt_tv01.animation.addByPrefix('404', 'TV_Bluescreen', 24, true);
				qt_tv01.animation.addByPrefix('watch', 'TV_Watchout', 24, true);
				qt_tv01.animation.addByPrefix('drop', 'TV_Drop', 24, true);
				qt_tv01.animation.addByPrefix('sus', 'TV_sus', 24, true);
				qt_tv01.animation.addByPrefix('instructions', 'TV_Instructions-Normal', 24, true);
				qt_tv01.animation.addByPrefix('gl', 'TV_GoodLuck', 24, true);
				qt_tv01.animation.addByPrefix('heart', 'TV_End', 24, false);

				qt_tv01.setPosition(-62, 540);
				qt_tv01.setGraphicSize(Std.int(qt_tv01.width * 1.2));
				qt_tv01.updateHitbox();
				qt_tv01.antialiasing = ClientPrefs.globalAntialiasing;
				qt_tv01.scrollFactor.set(0.9, 0.9);
				add(qt_tv01);
				qt_tv01.animation.play('idle');

			case 'street-kb':
				dadDrainHealth = 0.01185;
				healthLossMultiplier = 1.075;

				if (!ClientPrefs.lowQuality)
				{
					// Far Back Layer - Error (blue screen)
					var errorBG:BGSprite = new BGSprite('hazard/qt-port/stage/streetError', -750, -145, 0.95, 0.95);
					add(errorBG);

					// Back Layer - Error (glitched version of normal Back)
					streetBGerror = new FlxSprite(-750, -145).loadGraphic(Paths.image('hazard/qt-port/stage/streetBackError'));
					streetBGerror.antialiasing = ClientPrefs.globalAntialiasing;
					streetBGerror.scrollFactor.set(0.95, 0.95);
					add(streetBGerror);
				}

				// Back Layer - Normal
				streetBG = new FlxSprite(-750, -145).loadGraphic(Paths.image('hazard/qt-port/stage/streetBack'));
				streetBG.antialiasing = true;
				streetBG.scrollFactor.set(0.95, 0.95);
				add(streetBG);

				// Front Layer - Normal
				var streetFront:BGSprite = new BGSprite('hazard/qt-port/stage/streetFront', -820, 710, 0.95, 0.95);
				streetFront.setGraphicSize(Std.int(streetFront.width * 1.15));
				streetFront.updateHitbox();
				add(streetFront);

				if (!ClientPrefs.lowQuality)
				{
					// Front Layer - Error (changes to have a glow)
					streetFrontError = new FlxSprite(-820, 710).loadGraphic(Paths.image('hazard/qt-port/stage/streetFrontError'));
					streetFrontError.setGraphicSize(Std.int(streetFrontError.width * 1.15));
					streetFrontError.updateHitbox();
					streetFrontError.antialiasing = ClientPrefs.globalAntialiasing;
					streetFrontError.scrollFactor.set(0.95, 0.95);
					streetFrontError.active = false;
					add(streetFrontError);
					streetFrontError.visible = false;
				}

				qt_tv01 = new FlxSprite();
				qt_tv01.frames = Paths.getSparrowAtlas('hazard/qt-port/stage/TV_V6');
				qt_tv01.animation.addByPrefix('idle', 'TV_Idle', 24, true);
				qt_tv01.animation.addByPrefix('eye', 'TV_brutality', 24, true);
				qt_tv01.animation.addByPrefix('error', 'TV_Error', 24, true);
				qt_tv01.animation.addByPrefix('404', 'TV_Bluescreen', 24, true);
				qt_tv01.animation.addByPrefix('alert', 'TV_Attention', 32, false);
				qt_tv01.animation.addByPrefix('watch', 'TV_Watchout', 24, true);
				qt_tv01.animation.addByPrefix('drop', 'TV_Drop', 24, true);
				qt_tv01.animation.addByPrefix('sus', 'TV_sus', 24, true);
				qt_tv01.animation.addByPrefix('instructions', 'TV_Instructions-Normal', 24, true);
				qt_tv01.animation.addByPrefix('gl', 'TV_GoodLuck', 24, true);
				qt_tv01.animation.addByPrefix('heart', 'TV_End', 24, false);
				qt_tv01.animation.addByPrefix('eyeRight', 'TV_eyeRight', 24, false);
				qt_tv01.animation.addByPrefix('eyeLeft', 'TV_eyeLeft', 24, false);
				qt_tv01.animation.addByPrefix('heart', 'TV_End', 24, false);
				qt_tv01.setPosition(-62, 540);
				qt_tv01.setGraphicSize(Std.int(qt_tv01.width * 1.2));
				qt_tv01.updateHitbox();
				qt_tv01.antialiasing = ClientPrefs.globalAntialiasing;
				qt_tv01.scrollFactor.set(0.9, 0.9);
				add(qt_tv01);
				qt_tv01.animation.play('idle');

			case 'street-termination':
				disableArrowIntro = true;
				discordDifficultyOverrideShouldUse = true;
				if (storyDifficulty == 2)
				{
					discordDifficultyOverride = "Classic";
					healthLossMultiplier = 2.175; // That's alotta damage!
					healthGainMultiplier = 1.085;
					dadDrainHealth = 0; // No health drain on classic because... well the original didn't have it. This version is already brutal with health loss on miss anyway.
				}
				else
				{
					discordDifficultyOverride = "Very Hard";
					healthLossMultiplier = 1.288;
					healthGainMultiplier = 1.051;
					dadDrainHealth = 0.014625;
				}

				if (!ClientPrefs.lowQuality)
				{
					// Far Back Layer - Error (blue screen)
					var errorBG:FlxSprite = new FlxSprite(-600, -150).loadGraphic(Paths.image('hazard/qt-port/stage/streetError'));
					errorBG.antialiasing = ClientPrefs.globalAntialiasing;
					errorBG.scrollFactor.set(0.95, 0.95);
					errorBG.active = false;
					add(errorBG);

					// Back Layer - Error (glitched version of normal Back)
					streetBGerror = new FlxSprite(-750, -145).loadGraphic(Paths.image('hazard/qt-port/stage/streetBackError'));
					streetBGerror.antialiasing = ClientPrefs.globalAntialiasing;
					streetBGerror.scrollFactor.set(0.95, 0.95);
					add(streetBGerror);
				}

				// Back Layer - Normal
				streetBG = new FlxSprite(-750, -145).loadGraphic(Paths.image('hazard/qt-port/stage/streetBack'));
				streetBG.antialiasing = ClientPrefs.globalAntialiasing;
				streetBG.scrollFactor.set(0.95, 0.95);
				add(streetBG);

				// Front Layer - Normal
				var streetFront:FlxSprite = new FlxSprite(-820, 710).loadGraphic(Paths.image('hazard/qt-port/stage/streetFront'));
				streetFront.setGraphicSize(Std.int(streetFront.width * 1.15));
				streetFront.updateHitbox();
				streetFront.antialiasing = ClientPrefs.globalAntialiasing;
				streetFront.scrollFactor.set(0.95, 0.95);
				streetFront.active = false;
				add(streetFront);

				if (!ClientPrefs.lowQuality)
				{
					// Front Layer - Error (changes to have a glow)
					streetFrontError = new FlxSprite(-820, 710).loadGraphic(Paths.image('hazard/qt-port/stage/streetFrontError'));
					streetFrontError.setGraphicSize(Std.int(streetFrontError.width * 1.15));
					streetFrontError.updateHitbox();
					streetFrontError.antialiasing = ClientPrefs.globalAntialiasing;
					streetFrontError.scrollFactor.set(0.95, 0.95);
					streetFrontError.active = false;
					add(streetFrontError);
					streetFrontError.visible = false;
				}

				qt_tv01 = new FlxSprite();
				qt_tv01.frames = Paths.getSparrowAtlas('hazard/qt-port/stage/TV_V6');
				qt_tv01.animation.addByPrefix('idle', 'TV_Idle', 24, true);
				qt_tv01.animation.addByPrefix('eye', 'TV_brutality', 24, true); // Replaced the hex eye with the brutality symbols for more accurate lore.
				qt_tv01.animation.addByPrefix('error', 'TV_Error', 24, true);
				qt_tv01.animation.addByPrefix('404', 'TV_Bluescreen', 24, true);
				qt_tv01.animation.addByPrefix('alert', 'TV_Attention', 36, false);
				qt_tv01.animation.addByPrefix('drop', 'TV_Drop', 24, true);
				qt_tv01.animation.addByPrefix('sus', 'TV_sus', 24, true);
				qt_tv01.animation.addByPrefix('instructions', 'TV_Instructions-Normal', 24, true);
				qt_tv01.animation.addByPrefix('gl', 'TV_GoodLuck', 24, true);
				qt_tv01.animation.addByPrefix('heart', 'TV_End', 24, false);
				qt_tv01.animation.addByPrefix('watch', 'TV_Watchout', 24, true);
				qt_tv01.animation.addByPrefix('eyeRight', 'TV_eyeRight', 24, false);
				qt_tv01.animation.addByPrefix('eyeLeft', 'TV_eyeLeft', 24, false);
				qt_tv01.animation.addByPrefix('heart', 'TV_End', 24, false);
				qt_tv01.setPosition(-62, 540);
				qt_tv01.setGraphicSize(Std.int(qt_tv01.width * 1.2));
				qt_tv01.updateHitbox();
				qt_tv01.antialiasing = ClientPrefs.globalAntialiasing;
				qt_tv01.scrollFactor.set(0.9, 0.9);
				add(qt_tv01);
				qt_tv01.animation.play('idle');

			// Inhuman / Brutality Labs
			case 'depths': // yes

				forceMiddleScroll = true;
				// disableDefaultCamZooming = true;
				// idk if will have Cam Zooming in inhuman (prob not) but here i will let Cam Zooming activate because yes
				discordDifficultyOverrideShouldUse = true;
				discordDifficultyOverride = "Trespasing";
				defaultCamZoom = 0.5;
				inhumanSong = true;
				introSkip = 48; // in seconds
				camHUD.visible = false;
				skipCountdown = true;
				disableArrowIntro = true;

				hazardBGkb = new FlxSprite();
				hazardBGkb.frames = Paths.getSparrowAtlas('hazard/inhuman-port/backPulsing'); // Before you start asking questions, yes, KB has a pulsing background in the Inhuman mod. I'm just reusing shit because I'm lazy lmao -Haz.
				hazardBGkb.animation.addByPrefix('pulse', 'kbBACK-pulse', 24, false);
				hazardBGkb.x = -590;
				hazardBGkb.y = -250;
				hazardBGkb.antialiasing = ClientPrefs.globalAntialiasing;
				hazardBGkb.scrollFactor.set(1, 1);
				hazardBGkb.setGraphicSize(Std.int(hazardBGkb.width * 1.1));
				hazardBGkb.updateHitbox();
				// hazardBGkb.alpha=0;
				hazardBGkb.animation.play('pulse');
				add(hazardBGkb);

				if (!ClientPrefs.lowQuality)
				{
					wiggleShitShow = new WiggleEffect();
					wiggleShitShow.effectType = WiggleEffectType.DREAMY;
					wiggleShitShow.waveAmplitude = 0.013;
					wiggleShitShow.waveFrequency = 4.4;
					wiggleShitShow.waveSpeed = 1;
					hazardBGkb.shader = wiggleShitShow.shader;
					// FlxG.camera.setFilters([new ShaderFilter(cast wiggleShitShow.shader)]);

					fogShitGroup = new FlxTypedGroup<FogThing>();
					// upper layer
					for (i in 0...20)
					{
						var fogShit:FogThing = new FogThing();
						fogShit.setPosition((i * 204) - 1250, FlxG.random.float(-6, 18));
						fogShit.alpha = 0.3;
						fogShit.isUpperLayer = true;
						fogShit.updateHitbox();
						fogShitGroup.add(fogShit);
					}
					// lower layer
					for (i in 0...20)
					{
						var fogShit:FogThing = new FogThing();
						fogShit.setPosition((i * 204) - 1250, 50 + FlxG.random.float(-24, 24));
						fogShit.alpha = 0.49;
						fogShit.isUpperLayer = false;
						fogShit.updateHitbox();
						fogShitGroup.add(fogShit);
					}
					add(fogShitGroup);

					hazardInterlopeLaugh = new FlxSprite();
					hazardInterlopeLaugh.frames = Paths.getSparrowAtlas('hazard/inhuman-port/ameliaTaunt');
					hazardInterlopeLaugh.animation.addByPrefix('laugh1', 'Amelia_Chuckle', 24, true);
					hazardInterlopeLaugh.animation.addByPrefix('laugh2', 'Amelia_Laugh', 30, true);
					hazardInterlopeLaugh.antialiasing = ClientPrefs.globalAntialiasing;
					hazardInterlopeLaugh.setGraphicSize(Std.int(hazardInterlopeLaugh.width * 1.3));
					hazardInterlopeLaugh.screenCenter();
					hazardInterlopeLaugh.x += 272;
					hazardInterlopeLaugh.y += 260;
					hazardInterlopeLaugh.animation.play("laugh1");
					hazardInterlopeLaugh.alpha = 0;
					add(hazardInterlopeLaugh);
				}

				hazardBlack = new BGSprite(null, -FlxG.width, -FlxG.height, 0, 0);
				hazardBlack.makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.BLACK);
				hazardBlack.alpha = 1;
				hazardBlack.cameras = [camOther];
				add(hazardBlack);

				for (hud in allUIs) {
					hud.visible = true;
					hud.alpha = 0;
				}
		}

		// Moved gas effect to be useable across all songs!
		if (!ClientPrefs.lowQuality)
		{
			qt_gas01 = new FlxSprite();
			qt_gas02 = new FlxSprite();
			qt_gaskb = new FlxSprite();
			for (gas in [qt_gas01, qt_gas02, qt_gaskb])
			{
				gas.frames = Paths.getSparrowAtlas('hazard/qt-port/stage/Gas_Release');
				gas.animation.addByPrefix('burst', 'Gas_Release', 38, false);
				gas.animation.addByPrefix('burstALT', 'Gas_Release', 49, false);
				gas.animation.addByPrefix('burstFAST', 'Gas_Release', 76, false);
				gas.animation.addByIndices('burstLoop', 'Gas_Release', [12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23], "", 38, true);
				gas.antialiasing = true;
				gas.alpha = 0.62;
			}
			// qt_gaskb.screenCenter();
			qt_gaskb.setGraphicSize(Std.int(qt_gaskb.width * 1.6));
			qt_gaskb.updateHitbox();

			qt_gas01.setPosition(-500, -70);
			qt_gas01.setGraphicSize(Std.int(qt_gas01.width * 2.5));
			qt_gas01.angle = -31;
			qt_gas01.scrollFactor.set();
			qt_gas02.setPosition(565, -70);
			qt_gas02.setGraphicSize(Std.int(qt_gas02.width * 2.5));
			qt_gas02.angle = 31;
			qt_gas02.scrollFactor.set();
		}

		// Made Terminate have the same intro as Termination to freak even more people out LMAO.
		if (SONG.song.toLowerCase() == "terminate")
			disableArrowIntro = true;

		if (!ClientPrefs.lowQuality) // added ClientPrefs.lowQuality because why have it on low quality?
		{
			luisOverlayShit = new BGSprite('luis/qt-fixes/vignette');
			luisOverlayShit.setGraphicSize(FlxG.width, FlxG.height);
			luisOverlayShit.screenCenter();
			luisOverlayShit.x += (FlxG.width / 2) - 60;
			luisOverlayShit.y += (FlxG.height / 2) - 20;
			luisOverlayShit.updateHitbox();
			luisOverlayShit.alpha = 0.001;
			luisOverlayShit.cameras = [camOther];
			add(luisOverlayShit);

			if (ClientPrefs.flashing)
			{
				luisOverlayWarning = new BGSprite('luis/qt-fixes/vignette');
				luisOverlayWarning.setGraphicSize(FlxG.width, FlxG.height);
				luisOverlayWarning.screenCenter();
				luisOverlayWarning.x += (FlxG.width / 2) - 60;
				luisOverlayWarning.y += (FlxG.height / 2) - 20;
				luisOverlayWarning.updateHitbox();
				luisOverlayWarning.alpha = 0.001;
				luisOverlayWarning.cameras = [camOther];
				add(luisOverlayWarning);
			}

			if (ClientPrefs.flashing)
			{
				hazardOverlayShit = new BGSprite('hazard/inhuman-port/alert-vignette');
				hazardOverlayShit.setGraphicSize(FlxG.width, FlxG.height);
				hazardOverlayShit.screenCenter();
				hazardOverlayShit.x += (FlxG.width / 2) - 60; // Mmmmmm scuffed positioning, my favourite!
				hazardOverlayShit.y += (FlxG.height / 2) - 20;
				hazardOverlayShit.updateHitbox();
				hazardOverlayShit.alpha = 0.001;
				hazardOverlayShit.cameras = [camOther];
				add(hazardOverlayShit);
			}
		} // change layering to better optimization.
		// ok before you make questions, this will help the persons that have ClientPrefs.flashing on and ClientPrefs.lowQuality off

		// Alert!
		kb_attack_alert = new FlxSprite();
		kb_attack_alert.frames = Paths.getSparrowAtlas('hazard/qt-port/attack_alert_NEW');
		kb_attack_alert.animation.addByPrefix('alert', 'kb_attack_animation_alert-single', 24, false);
		kb_attack_alert.animation.addByPrefix('alertDOUBLE', 'kb_attack_animation_alert-double', 24, false);
		kb_attack_alert.animation.addByPrefix('alertTRIPLE', 'kb_attack_animation_alert-triple', 24, false);
		kb_attack_alert.animation.addByPrefix('alertQUAD', 'kb_attack_animation_alert-quad', 24, false);
		kb_attack_alert.antialiasing = ClientPrefs.globalAntialiasing;
		kb_attack_alert.setGraphicSize(Std.int(kb_attack_alert.width * 1.5));
		kb_attack_alert.cameras = [camHUD];
		kb_attack_alert.x = FlxG.width - 700;
		kb_attack_alert.y = 205;
		// kb_attack_alert.animation.play("alert"); //Placeholder, change this to start already hidden or whatever.

		// Saw that one coming!
		kb_attack_saw = new FlxSprite();
		kb_attack_saw.frames = Paths.getSparrowAtlas('hazard/qt-port/attackv7');
		kb_attack_saw.animation.addByPrefix('fire', 'kb_attack_animation_fire', 24, false);
		kb_attack_saw.animation.addByPrefix('prepare', 'kb_attack_animation_prepare', 24, false);
		kb_attack_saw.setGraphicSize(Std.int(kb_attack_saw.width * 1.15));
		kb_attack_saw.antialiasing = ClientPrefs.globalAntialiasing;
		kb_attack_saw.setPosition(-960, BF_Y + 450); // now sawblades have the (almost) the same y than the bf y
		kb_attack_saw.offset.set(-360, 0); // update the offset before

		sawbladeHits = 0;
		tauntCounter = 0;

		// Adding sawblades and pincers to every song so all songs can use them!
		// Pincer shit for moving notes around for a little bit of trollin'
		pincer1 = new FlxSprite(0, 0).loadGraphic(Paths.image('hazard/qt-port/pincer-close'));
		pincer1.antialiasing = ClientPrefs.globalAntialiasing;
		pincer1.scrollFactor.set();
		pincer2 = new FlxSprite(0, 0).loadGraphic(Paths.image('hazard/qt-port/pincer-close'));
		pincer2.antialiasing = ClientPrefs.globalAntialiasing;
		pincer2.scrollFactor.set();
		pincer3 = new FlxSprite(0, 0).loadGraphic(Paths.image('hazard/qt-port/pincer-close'));
		pincer3.antialiasing = ClientPrefs.globalAntialiasing;
		pincer3.scrollFactor.set();
		pincer4 = new FlxSprite(0, 0).loadGraphic(Paths.image('hazard/qt-port/pincer-close'));
		pincer4.antialiasing = ClientPrefs.globalAntialiasing;
		pincer4.scrollFactor.set();

		pincers = [pincer1, pincer2, pincer3, pincer4];

		for (sprite in [pincer1, pincer2, pincer3, pincer4])
		{
			if (ClientPrefs.downScroll)
			{
				sprite.angle = 270;
				sprite.offset.set(192, -75);
			}
			else
			{
				sprite.angle = 90;
				sprite.offset.set(218, 240);
			}
		}

		// For the 'alarm' effect. Only added if flashling lights is allowed and low quality is off.
		if (ClientPrefs.flashing && !ClientPrefs.lowQuality)
		{
			hazardAlarmLeft = new BGSprite('hazard/inhuman-port/back-Gradient', -600, -480, 0.5, 0.5);
			hazardAlarmLeft.setGraphicSize(Std.int(hazardAlarmLeft.width * 1.1));
			hazardAlarmLeft.updateHitbox();
			hazardAlarmLeft.alpha = 0;
			hazardAlarmLeft.color = FlxColor.RED;
			hazardAlarmLeft.cameras = [camOther];
			hazardAlarmLeft.x -= 85;
			add(hazardAlarmLeft);
			hazardAlarmRight = new BGSprite('hazard/inhuman-port/back-Gradient', -600, -480, 0.5, 0.5);
			hazardAlarmRight.setGraphicSize(Std.int(hazardAlarmRight.width * 1.1));
			hazardAlarmRight.updateHitbox();
			hazardAlarmRight.flipX = true;
			hazardAlarmRight.alpha = 0;
			hazardAlarmRight.color = FlxColor.RED;
			hazardAlarmRight.cameras = [camOther];
			hazardAlarmRight.x -= 85;
			add(hazardAlarmRight);
		}

		if (!ClientPrefs.lowQuality)
			add(qt_gaskb);

		if (curStage != 'depths')
		{
			add(gfGroup);

			add(dadGroup);
			add(boyfriendGroup);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if (FileSystem.exists(Paths.modFolders(luaFile)))
		{
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if (FileSystem.exists(luaFile))
				doPush = true;
		}

		if (doPush)
			luaArray.push(new FunkinLua(luaFile));
		#end

		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1)
		{
			gfVersion = 'gf';
			SONG.gfVersion = gfVersion; // Fix for the Chart Editor
		}

		gf = new Character(0, 0, gfVersion);
		startCharacterPos(gf);
		gf.scrollFactor.set(0.95, 0.95);
		gfGroup.add(gf);
		startCharacterLua(gf.curCharacter);

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);

		qt_gaskb.visible = (dad.curCharacter.startsWith("kb") && !dad.curCharacter.startsWith("kb-classic"));

		blueshader.shader.enabled.value = [true];
		blueshader.shader.r.value = [1];
		blueshader.shader.g.value = [0];
		blueshader.shader.b.value = [0.1];
		blueshader.shader.passes.value = [150];

		for (char in [boyfriend, gf, dad])
			char.shader = blueshader.shader;
		// testing

		var camPos:FlxPoint = new FlxPoint(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);
		camPos.x += gf.cameraPosition[0];
		camPos.y += gf.cameraPosition[1];

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			gf.visible = false;
		}

		var file:String = Paths.json(songName + '/dialogue'); // Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file))
			dialogueJson = DialogueBoxPsych.parseDialogue(file);

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); // Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file))
			dialogue = CoolUtil.coolTextFile(file);

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(forceMiddleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if (ClientPrefs.downScroll)
			strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		luisModChartDefaultStrumY = strumLine.y;

		inhumancolor1 = inhumanSong ? FlxColor.BLACK : FlxColor.WHITE;
		inhumancolor2 = inhumanSong ? FlxColor.RED : FlxColor.BLACK;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if (FileSystem.exists(luaToLoad))
				luaArray.push(new FunkinLua(luaToLoad));
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if (FileSystem.exists(luaToLoad))
					luaArray.push(new FunkinLua(luaToLoad));
			}
		}
		for (event in eventPushedMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if (FileSystem.exists(luaToLoad))
				luaArray.push(new FunkinLua(luaToLoad));
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
				if (FileSystem.exists(luaToLoad))
					luaArray.push(new FunkinLua(luaToLoad));
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		gameHUD = new GameHUD();
		add(gameHUD);

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		gameHUD.cameras = [camHUD];
		doof.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));
		#end

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				case 'carefree':
					FlxG.sound.playMusic(Paths.music('carefree-dialogue-loop'), 0);
					FlxG.sound.music.fadeIn(1, 0, 0.75);
					startDialogue(dialogueJson);

				case 'careless' | 'terminate':
					startDialogue(dialogueJson);

				// Careless, Cessation, and Terminate all have ending dialogue.

				case 'censory-overload':
					kbWakesUp();

				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
			epicStuff();
		}
		RecalculateRating();

		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		// BRUH DON'T WORRY, I HAVE NO FUCKING IDEA HOW HAXE WORKS EITHER -Haz
		// WAIT, WHAT IS HAXE?!?? -Luis
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');
		CoolUtil.precacheSound('hazard/alert');
		CoolUtil.precacheSound('hazard/alertDouble');
		CoolUtil.precacheSound('hazard/alertTriple');
		CoolUtil.precacheSound('hazard/alertQuadruple');
		CoolUtil.precacheSound('hazard/attack');
		CoolUtil.precacheSound('hazard/attack-double');
		CoolUtil.precacheSound('hazard/attack-triple');
		CoolUtil.precacheSound('hazard/attack-quadruple');

		introSkipSprite = new BGSprite('hazard/inhuman-port/skip-hint', -600, -480, 0.5, 0.5);
		introSkipSprite.setGraphicSize(Std.int(introSkipSprite.width * 2));
		introSkipSprite.updateHitbox();
		introSkipSprite.cameras = [camOther]; // Moved from HUD to OTHER so that the HUD shaders don't fuck over the text. Also so that it can appear without fading in at the start
		introSkipSprite.screenCenter();

		#if desktop
		// Updating Discord Rich Presence.
		if (discordDifficultyOverrideShouldUse)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + discordDifficultyOverride + ")", gameHUD.iconP2.getCharacter());
		else
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", gameHUD.iconP2.getCharacter());
		#end

		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		callOnLuas('onCreatePost', []);

		/*for (n in unspawnNotes)
			if (n.noteType != "Hurt Note")
				n.mustPress = true; */

		dacamera = defaultCamZoom;

		super.create();

		Paths.clearUnusedMemory();
		CustomFadeTransition.nextCamera = camOther;
	}

	function kbWakesUp():Void
	{
		FlxG.sound.playMusic(Paths.music('spooky_ambience'), 0);
		FlxG.sound.music.fadeIn(1, 0, 0.75);
		if (ClientPrefs.qtSkipCutscene)
			startDialogue(dialogueJson);
		else
		{
			// Lazily copy and pastes code from schoolIntro but in a cute way~ -Haz
			// Not cute -Luis
			var black:FlxSprite = new FlxSprite(-300, -100).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			black.scrollFactor.set();
			var senpaiEvil:FlxSprite = new FlxSprite();
			var horrorStage:FlxSprite = new FlxSprite();
			for (hud in allUIs)
				hud.visible = false;
			// BG
			horrorStage.frames = Paths.getSparrowAtlas('hazard/qt-port/stage/horrorbg');
			horrorStage.animation.addByPrefix('idle', 'Symbol 10 instance ', 24, false);
			horrorStage.antialiasing = ClientPrefs.globalAntialiasing;
			horrorStage.scrollFactor.set();
			horrorStage.screenCenter();
			// QT sprite
			senpaiEvil.frames = Paths.getSparrowAtlas('hazard/qt-port/cutscenev3');
			senpaiEvil.animation.addByPrefix('idle', 'final_edited', 24, false);
			senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 0.875));
			senpaiEvil.scrollFactor.set();
			senpaiEvil.updateHitbox();
			senpaiEvil.screenCenter();
			senpaiEvil.x -= 140;
			senpaiEvil.y -= 55;
			add(horrorStage);
			inCutscene = true;

			new FlxTimer().start(0.3, function(tmr:FlxTimer)
			{
				black.alpha -= 0.125;
				if (black.alpha > 0)
					tmr.reset(0.3);
				else
				{
					add(senpaiEvil);
					senpaiEvil.alpha = 0;
					new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
					{
						senpaiEvil.alpha += 0.15;
						if (senpaiEvil.alpha < 1)
						{
							swagTimer.reset();
						}
						else
						{
							senpaiEvil.animation.play('idle');
							horrorStage.animation.play('idle');
							FlxG.sound.play(Paths.sound('hazard/music-box-horror'), 0.9, false, null, true, function()
							{
								remove(senpaiEvil);
								remove(horrorStage);
								for (hud in allUIs)
									hud.visible = true;
								FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
								{
									startDialogue(dialogueJson);
								}, true);
							});
							new FlxTimer().start(13, function(deadTime:FlxTimer)
							{
								FlxG.camera.fade(FlxColor.WHITE, 3, false);
							});
						}
					});
					remove(black);
				}
			});
		}
	}

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes)
			{
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
			for (note in unspawnNotes)
			{
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	public function addTextToDebug(text:String)
	{
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText)
		{
			spr.y += 20;
		});

		if (luaDebugGroup.members.length > 34)
		{
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if (!gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		if (FileSystem.exists(Paths.modFolders(luaFile)))
		{
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if (FileSystem.exists(luaFile))
				doPush = true;
		}

		if (doPush)
		{
			for (lua in luaArray)
			{
				if (lua.scriptName == luaFile)
					return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	public function addShaderToCamera(cam:String, effect:ShaderEffect)
	{ // STOLE FROM ANDROMEDA
		// Update v2.2 hotfix: Shaders now only work if the user enables them to avoid crashes.
		if (!ClientPrefs.noShaders)
		{
			switch (cam.toLowerCase())
			{
				case 'camgas' | 'gas':
					camGASShaders.push(effect);
					var newCamEffects:Array<BitmapFilter> = []; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for (i in camGASShaders)
					{
						newCamEffects.push(new ShaderFilter(i.shader));
					}
					camGAS.setFilters(newCamEffects);
				case 'camhud' | 'hud':
					camHUDShaders.push(effect);
					var newCamEffects:Array<BitmapFilter> = [];
					for (i in camHUDShaders)
					{
						newCamEffects.push(new ShaderFilter(i.shader));
					}
					camHUD.setFilters(newCamEffects);
				case 'camother' | 'other':
					camOtherShaders.push(effect);
					var newCamEffects:Array<BitmapFilter> = [];
					for (i in camOtherShaders)
					{
						newCamEffects.push(new ShaderFilter(i.shader));
					}
					camOther.setFilters(newCamEffects);
				case 'camgame' | 'game':
					camGameShaders.push(effect);
					var newCamEffects:Array<BitmapFilter> = [];
					for (i in camGameShaders)
					{
						newCamEffects.push(new ShaderFilter(i.shader));
					}
					camGame.setFilters(newCamEffects);
				default:
					if (modchartSprites.exists(cam))
					{
						Reflect.setProperty(modchartSprites.get(cam), "shader", effect.shader);
					}
					else if (modchartTexts.exists(cam))
					{
						Reflect.setProperty(modchartTexts.get(cam), "shader", effect.shader);
					}
					else
					{
						var OBJ = Reflect.getProperty(PlayState.instance, cam);
						Reflect.setProperty(OBJ, "shader", effect.shader);
					}
			}
		}
	}

	public function removeShaderFromCamera(cam:String, effect:ShaderEffect)
	{
		if (!ClientPrefs.noShaders)
		{
			switch (cam.toLowerCase())
			{
				case 'camgas' | 'gas':
					camGASShaders.remove(effect);
					var newCamEffects:Array<BitmapFilter> = [];
					for (i in camGASShaders)
					{
						newCamEffects.push(new ShaderFilter(i.shader));
					}
					camGAS.setFilters(newCamEffects);
				case 'camhud' | 'hud':
					camHUDShaders.remove(effect);
					var newCamEffects:Array<BitmapFilter> = [];
					for (i in camHUDShaders)
					{
						newCamEffects.push(new ShaderFilter(i.shader));
					}
					camHUD.setFilters(newCamEffects);
				case 'camother' | 'other':
					camOtherShaders.remove(effect);
					var newCamEffects:Array<BitmapFilter> = [];
					for (i in camOtherShaders)
					{
						newCamEffects.push(new ShaderFilter(i.shader));
					}
					camOther.setFilters(newCamEffects);
				default:
					camGameShaders.remove(effect);
					var newCamEffects:Array<BitmapFilter> = [];
					for (i in camGameShaders)
					{
						newCamEffects.push(new ShaderFilter(i.shader));
					}
					camGame.setFilters(newCamEffects);
			}
		}
	}

	// When testing with shaders, some seemed to flip the camera? This is here to hopefully counter it.
	public function flippyTime(cam:String)
	{
		switch (cam.toLowerCase())
		{
			case 'camgas' | 'gas':
				camGAS.setScale(camHUD.scaleX * -1, camHUD.scaleY);
			case 'camhud' | 'hud':
				camHUD.setScale(camHUD.scaleX * -1, camHUD.scaleY);
			case 'camother' | 'other':
				camOther.setScale(camHUD.scaleX * -1, camHUD.scaleY);
			default:
				camGame.setScale(camHUD.scaleX * -1, camHUD.scaleY);
		}
	}

	public function clearShaderFromCamera(cam:String)
	{
		switch (cam.toLowerCase())
		{
			case 'camgas' | 'gas':
				camGASShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camGAS.setFilters(newCamEffects);
			case 'camhud' | 'hud':
				camHUDShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camHUD.setFilters(newCamEffects);
			case 'camother' | 'other':
				camOtherShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camOther.setFilters(newCamEffects);
			default:
				camGameShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camGame.setFilters(newCamEffects);
		}
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String):Void
	{
	#if VIDEOS_ALLOWED
	var foundFile:Bool = false;
	var fileName:String = #if MODS_ALLOWED Paths.modFolders('videos/' + name + '.' + Paths.VIDEO_EXT); #else ''; #end
	#if sys
	if (FileSystem.exists(fileName))
	{
		foundFile = true;
	}
	#end

	if (!foundFile)
	{
		fileName = Paths.video(name);
		#if sys
		if (FileSystem.exists(fileName))
		{
		#else
		if (OpenFlAssets.exists(fileName))
		{
		#end
			foundFile = true;
		}
		} if (foundFile)
		{
			inCutscene = true;
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);

			(new FlxVideo(fileName)).finishCallback = function()
			{
				remove(bg);
				startAndEnd();
			}
			return;
		}
		else
		{
			FlxG.log.warn('Couldnt find video file: ' + fileName);
			startAndEnd();
		}
		#end
		startAndEnd();
	}

	function startAndEnd()
	{
		if (endingSong)
		{
			endSong();
			// trace("EndSong triggerd from Start And End");
		}
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;

	public var psychDialogue:DialogueBoxPsych;

	// You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null)
			return;

		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;
			CoolUtil.precacheSound('dialogue/dialogue');
			CoolUtil.precacheSound('dialogue/generic');
			CoolUtil.precacheSound('dialogue/kb');
			CoolUtil.precacheSound('dialogue/qt');
			CoolUtil.precacheSound('dialogue/gf');
			CoolUtil.precacheSound('dialogue/bf');
			CoolUtil.precacheSound('dialogue/qt_error');
			CoolUtil.precacheSound('dialogue/dialogueClose');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if (endingSong)
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					if (SONG.song.toLowerCase() == "cessation")
						endScreenHazard();
					else
					{
						endSong();
						// trace("endSong triggerd from Dialogue top");
					}
				}
			}
			else
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if (endingSong)
			{
				if (SONG.song.toLowerCase() == "cessation")
					endScreenHazard();
				else
				{
					endSong();
					// trace("endSong triggerd from Dialogue bottom");
				}
			}
			else
			{
				if (SONG.song.toLowerCase() == 'carefree' || SONG.song.toLowerCase() == 'censory-overload')
				{
					FlxG.sound.music.fadeOut(1.5, 0);
				}
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
					add(dialogueBox);
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public function startCountdown():Void
	{
		if (startedCountdown)
		{
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if (ret != FunkinLua.Function_Stop)
		{
			reloadStatics(false, true);

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if (skipCountdown)
			{
				Conductor.songPosition = 0;
				Conductor.songPosition -= Conductor.crochet;
				swagCounter = 3;
				for (hud in allUIs)
					hud.visible = true;
			}
			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (!gfScared
					&& tmr.loopsLeft % gfSpeed == 0
					&& !gf.stunned
					&& gf.animation.curAnim.name != null
					&& !gf.animation.curAnim.name.startsWith("sing"))
				{
					gf.dance();
				}
				if (tmr.loopsLeft % 2 == 0)
				{
					if (boyfriend.animation.curAnim != null
						&& !boyfriend.animation.curAnim.name.startsWith('sing')
						&& !bfDodging
						&& !boyfriend.stunned)
					{
						boyfriend.dance();
					}
					if (dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
					{
						dad.dance();
						camX = 0;
						camY = 0;
					}
				}
				else if (dad.danceIdle
					&& dad.animation.curAnim != null
					&& !dad.stunned
					&& !dad.curCharacter.startsWith('gf')
					&& !dad.animation.curAnim.name.startsWith("sing"))
				{
					dad.dance();
					camX = 0;
					camY = 0;
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						add(countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.scrollFactor.set();

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						add(countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						if (!skipCountdown)
						{
							countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
							countdownGo.scrollFactor.set();

							countdownGo.updateHitbox();

							countdownGo.screenCenter();
							countdownGo.antialiasing = antialias;
							add(countdownGo);
							FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
								ease: FlxEase.cubeInOut,
								onComplete: function(twn:FlxTween)
								{
									remove(countdownGo);
									countdownGo.destroy();
								}
							});
							FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						}
					case 4:
				}

				/*notes.forEachAlive(function(note:Note)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if (forceMiddleScroll && !note.mustPress)
						{
							note.alpha *= 0.5;
						}
					});
				 */ // i was trying to find what was causing the notes not showing up and hazard figured this out, i don't fucking know why this exists but we decided to comment as it was a better option -Luis
				// inhuman leak???!?!?!
				// nah sussy you
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	function startNextDialogue()
	{
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue()
	{
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		if (introSkip > 0 && deathCounter > 0)
		{
			introSkipSprite.alpha = 0;
			add(introSkipSprite);
			// Make introskipsprite fade in because it looks nicer
			FlxTween.tween(introSkipSprite, {alpha: 0.49}, 1.25);
			new FlxTimer().start(5, function(tmr:FlxTimer)
			{
				FlxTween.tween(introSkipSprite, {alpha: 0.08}, 1.5, {ease: FlxEase.quadInOut});
			});
		}

		for (i in 0...8)
			hazardModChartDefaultStrumY[i] = luisModChartDefaultStrumY;

		for (i in 0...playerStrums.length)
		{
			hazardModChartDefaultStrumX[i] = opponentStrums.members[i].x;
			hazardModChartDefaultStrumX[i + 4] = playerStrums.members[i].x;
			// trace("Strum1 X = ", hazardModChartDefaultStrumX[i+4]);
		}

		for (i in 0...playerStrums.length)
		{
			setOnLuas('defaultPlayerStrumX' + i, hazardModChartDefaultStrumX[i + 4]);
			setOnLuas('defaultPlayerStrumY' + i, hazardModChartDefaultStrumY[i + 4]);
		}
		for (i in 0...opponentStrums.length)
		{
			setOnLuas('defaultOpponentStrumX' + i, hazardModChartDefaultStrumX[i]);
			setOnLuas('defaultOpponentStrumY' + i,
				hazardModChartDefaultStrumY[i]); // changed to "hazardModChartDefaultStrum" because the new notes animation takes a year to finish, and because was supposed to works like this before??? -Luis
			// if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
		}

		hazardRandom = FlxG.random.int(1, 5);
		FlxG.log.notice(('Cessation Random Roll:' + hazardRandom));

		if (SONG.song.toLowerCase() == "interlope")
		{
			remove(hazardBlack); // Layering moment LMAO
			add(hazardBlack);

			// Shaders? Pog
			if (!ClientPrefs.lowQuality && !ClientPrefs.noShaders)
			{
				// Disables with flashing lights just to be safe.
				if (ClientPrefs.flashing)
				{
					interlopeChroma = new ChromaticAberrationEffect(0);
					addShaderToCamera("hud", interlopeChroma);
				}
				interlopeFadeinShader = new TiltshiftEffect(4, 0);
				addShaderToCamera("hud", interlopeFadeinShader);

				addShaderToCamera("hud", new GrainEffect(0.575, 2, true));
				addShaderToCamera("game", new GrainEffect(1.1, 0.95, true));
			}
			for (i in 0...opponentStrums.length)
			{
				opponentStrums.members[i].alpha = 0;
				opponentStrums.members[i].x = hazardModChartDefaultStrumX[i + 4];
				// FlxTween.tween(i, {alpha: 0}, 0.5, {ease: FlxEase.linear});
			}
			for (i in 0...playerStrums.length)
			{
				playerStrums.members[i].angle = 360;
				playerStrums.members[i].x -= 90;
				playerStrums.members[i].y += ClientPrefs.downScroll ? -130 : 130;
			}
			interlopeIntroTween = FlxTween.tween(hazardBlack, {alpha: 0.5}, 24, {
				onComplete: function(twn:FlxTween)
				{
					interlopeIntroTween = null;
				}
			});

			interlopeIntroTweenHUD = FlxTween.tween(camHUD, {alpha: 1}, 24, {
				onComplete: function(twn:FlxTween)
				{
					interlopeIntroTweenHUD = null;
				}
			});
		}
		else if (!disableDefaultCamZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
		{
			FlxG.camera.zoom += 0.0075;
			//camHUD.zoom += 0.015;
			for (hud in allUIs)
				hud.zoom += 0.015;
		}
		if (SONG.song.toLowerCase() == 'censory-overload')
			gfSpeed = 2;

		bfCanDodge = SONG.dodgeEnabled;

		if (!ClientPrefs.lowQuality && !ClientPrefs.noShaders && ClientPrefs.flashing)
		{
			censoryChroma = new ChromaticAberrationEffect(0);
			addShaderToCamera("hud", censoryChroma);
		}

		if (!ClientPrefs.lowQuality)
		{
			add(qt_gas01);
			qt_gas01.cameras = [camGAS];
			add(qt_gas02);
			qt_gas02.cameras = [camGAS];
		}

		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		// Use this path for classic termination
		if (Paths.formatToSongPath(SONG.song) == 'termination' && storyDifficulty == 2)
			FlxG.sound.playMusic(Paths.instOLD(PlayState.SONG.song), 1, false);
		else
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);

		// FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = finishSong;
		vocals.play();

		if (paused)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		if (SONG.song.toLowerCase() == "terminate") // Fakes the timebar
			songLength = 316219;
		songLengthTxt = FlxStringUtil.formatTime(Math.floor((songLength) / 1000), false);
		gameHUD.timeleftTxt.text = songLengthTxt; // :kachow:
		// trace("I wonder what the length of this song is? ", songLength);
		// Termination returns 316219
		// Tutorial returns 67213
		FlxTween.tween(gameHUD.timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(gameHUD.songNameTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(gameHUD.timeleftTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(gameHUD.timesongTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		if (discordDifficultyOverrideShouldUse)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + discordDifficultyOverride + ")", gameHUD.iconP2.getCharacter(), true, songLength);
		else
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", gameHUD.iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype', 'multiplicative');

		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			// Use this path for classic termination
			if (Paths.formatToSongPath(SONG.song) == 'termination' && storyDifficulty == 2)
				vocals = new FlxSound().loadEmbedded(Paths.voicesOLD(PlayState.SONG.song));
			else
			{
				if (ClientPrefs.qtOldVocals && Paths.formatToSongPath(SONG.song) != 'interlope')
					vocals = new FlxSound().loadEmbedded(Paths.voicesCLASSIC(PlayState.SONG.song));
				else
					vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
			}
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		// Use this path for classic termination
		// I don't even know what the fuck this even is lmao
		if (Paths.formatToSongPath(SONG.song) == 'termination' && storyDifficulty == 2)
			FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.instOLD(PlayState.SONG.song)));
		else
			FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if sys
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file))
		{
		#else
		if (OpenFlAssets.exists(file))
		{
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) // Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:Array<Dynamic> = [
						newEventNote[0] + ClientPrefs.noteOffset - eventNoteEarlyTrigger(newEventNote),
						newEventNote[1],
						newEventNote[2],
						newEventNote[3]
					];
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;
				var oldNote:Note;

				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
				var swagNote:Note;

				swagNote = new Note(daStrumTime, daNoteData, oldNote, false, false, gottaHitNote, gottaHitNote ? boyfriend.noteSkinFile : dad.noteSkinFile);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));
				swagNote.noteType = songNotes[3];
				if (!Std.isOfType(songNotes[3], String))
					swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts
				swagNote.scrollFactor.set();
				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);
				var floorSus:Int = Math.floor(susLength);

				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note;

						sustainNote = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)),
							daNoteData, oldNote, true, false, gottaHitNote, gottaHitNote ? boyfriend.noteSkinFile : dad.noteSkinFile);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < 4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);
						if (sustainNote.mustPress)
							sustainNote.x += FlxG.width / 2; // general offset
						else if (forceMiddleScroll)
						{
							sustainNote.x += 310;
							if (daNoteData > 1) // Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}
				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2; // general offset
				else if (forceMiddleScroll)
				{
					swagNote.x += 310;
					if (daNoteData > 1) // Up and Right
						swagNote.x += FlxG.width / 2 + 25;
				}
				if (!noteTypeMap.exists(swagNote.noteType))
					noteTypeMap.set(swagNote.noteType, true);
			}
			daBeats += 1;
		}
		for (event in songData.events) // Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:Array<Dynamic> = [
					newEventNote[0] + ClientPrefs.noteOffset - eventNoteEarlyTrigger(newEventNote),
					newEventNote[1],
					newEventNote[2],
					newEventNote[3]
				];
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}
		// trace(unspawnNotes.length);
		// playerCounter += 1;
		unspawnNotes.sort(sortByShit);
		if (eventNotes.length > 1)
		{ // No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:Array<Dynamic>)
	{
		switch (event[1])
		{
			case 'Change Character OPTIONAL':
				if (!ClientPrefs.lowQuality)
				{
					var charType:Int = 0;
					switch (event[2].toLowerCase())
					{
						case 'gf' | 'girlfriend' | '1':
							charType = 2;
						case 'dad' | 'opponent' | '0':
							charType = 1;
						default:
							charType = Std.parseInt(event[2]);
							if (Math.isNaN(charType)) charType = 0;
					}

					var newCharacter:String = event[3];
					addCharacterToList(newCharacter, charType);
				}

			case 'Change Character':
				var charType:Int = 0;
				switch (event[2].toLowerCase())
				{
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event[2]);
						if (Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event[3];
				addCharacterToList(newCharacter, charType);
		}

		if (!eventPushedMap.exists(event[1]))
		{
			eventPushedMap.set(event[1], true);
		}
	}

	function eventNoteEarlyTrigger(event:Array<Dynamic>):Float
	{
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event[1]]);
		if (returnedValue != 0)
		{
			return returnedValue;
		}

		switch (event[1])
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position

			// These events are called early so that the sound effects they play remain synced to the music with people playing with note offset.
			// However, the actual mechanics are put on a timer so that they can still be synced to the charting.
			case 'KB_Alert' | 'KB_AlertDouble' | 'KB_AttackPrepare' | 'KB_AttackFire' | 'KB_AttackFireDOUBLE':
				if (ClientPrefs.noteOffset <= 0)
				{
					return 0;
				}
				else
				{
					return ClientPrefs.noteOffset;
				}
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	function removeStatics():Void
	{
		playerStrums.forEach(function(todel:StrumNote)
		{
			playerStrums.remove(todel);
			todel.destroy();
		});
		opponentStrums.forEach(function(todel:StrumNote)
		{
			opponentStrums.remove(todel);
			todel.destroy();
		});
		strumLineNotes.forEach(function(todel:StrumNote)
		{
			strumLineNotes.remove(todel);
			todel.destroy();
		});
	}

	private function generateStaticArrows(player:Int, twens:Bool = true, skin:String = 'NOTE_assets'):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1 && forceMiddleScroll)
				targetAlpha = 0.35;

			var babyArrow:StrumNote = new StrumNote(forceMiddleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player, skin);

			babyArrow.downScroll = ClientPrefs.downScroll;

			if (twens)
			{
				if (!disableArrowIntro)
				{
					if (!isStoryMode)
					{
						babyArrow.y += (ClientPrefs.downScroll ? 100 : -100);
						babyArrow.alpha = 0;
						if (!forceMiddleScroll)
						{
							if (player < 1)
								FlxTween.tween(babyArrow, {y: babyArrow.y - (ClientPrefs.downScroll ? 100 : -100), alpha: targetAlpha}, 2,
									{ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
							else
								FlxTween.tween(babyArrow, {y: babyArrow.y - (ClientPrefs.downScroll ? 100 : -100), alpha: targetAlpha}, 2,
									{ease: FlxEase.circOut, startDelay: 1.1 - (0.2 * i)});
						}
						else
							FlxTween.tween(babyArrow, {y: babyArrow.y - (ClientPrefs.downScroll ? 100 : -100), alpha: targetAlpha}, 2,
								{ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
					}
					else
					{
						babyArrow.alpha = targetAlpha;
					}
				}
				else
				{
					babyArrow.alpha = 0;
				}
			}
			else
				babyArrow.alpha = targetAlpha;

			if (player == 1)
				playerStrums.add(babyArrow);
			else
			{
				if (forceMiddleScroll)
				{
					babyArrow.x += 310;
					if (i > 1) // Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
				}
				opponentStrums.add(babyArrow);
			}
			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	private function reloadStatics(needremove = true, twens = false)
	{
		if (needremove)
			removeStatics();
		generateStaticArrows(0, twens, dad.noteSkinFile);
		generateStaticArrows(1, twens, boyfriend.noteSkinFile);
	}

	private function reloadStaticsEvent()
	{
		removeStatics();
		generateStaticArrows(0, false, dad.noteSkinFile);
		generateStaticArrows(1, false, boyfriend.noteSkinFile);
	}

	function openSubStatePauseShit()
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if (interlopeIntroTween != null)
				interlopeIntroTween.active = false;

			if (interlopeIntroTweenHUD != null)
				interlopeIntroTweenHUD.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length)
			{
				if (chars[i].colorTween != null)
				{
					chars[i].colorTween.active = false;
				}
			}

			for (tween in modchartTweens)
			{
				tween.active = false;
			}
			for (tween in interlopeIntroTweens)
			{
				tween.active = false;
			}
			for (timer in modchartTimers)
			{
				timer.active = false;
			}
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		openSubStatePauseShit();
		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length)
			{
				if (chars[i].colorTween != null)
				{
					chars[i].colorTween.active = true;
				}
			}

			if (interlopeIntroTween != null)
				interlopeIntroTween.active = true;

			if (interlopeIntroTweenHUD != null)
				interlopeIntroTweenHUD.active = true;

			for (tween in modchartTweens)
			{
				tween.active = true;
			}
			for (tween in interlopeIntroTweens)
			{
				tween.active = true;
			}
			for (timer in modchartTimers)
			{
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (discordDifficultyOverrideShouldUse)
			{
				if (startTimer.finished)
				{
					DiscordClient.changePresence(detailsText, SONG.song
						+ " ("
						+ discordDifficultyOverride
						+ ")", gameHUD.iconP2.getCharacter(), true,
						songLength
						- Conductor.songPosition
						- ClientPrefs.noteOffset);
				}
				else
				{
					DiscordClient.changePresence(detailsText, SONG.song + " (" + discordDifficultyOverride + ")", gameHUD.iconP2.getCharacter());
				}
			}
			else
			{
				if (startTimer.finished)
				{
					DiscordClient.changePresence(detailsText, SONG.song
						+ " ("
						+ storyDifficultyText
						+ ")", gameHUD.iconP2.getCharacter(), true,
						songLength
						- Conductor.songPosition
						- ClientPrefs.noteOffset);
				}
				else
				{
					DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", gameHUD.iconP2.getCharacter());
				}
			}
			#end
		}

		super.closeSubState();
	}

	private function strumCameraRoll(cStrum:FlxTypedGroup<StrumNote>, mustHit:Bool)
	{
		if (!ClientPrefs.camMove)
		{
			var camDisplaceExtend:Float = 15;
			if (PlayState.SONG.notes[Std.int(curStep / 16)] != null)
			{
				if ((PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && mustHit)
					|| (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && !mustHit))
				{
					camDisplaceX = 0;
					if (cStrum.members[0].animation.curAnim.name == 'confirm')
						camDisplaceX -= camDisplaceExtend;
					if (cStrum.members[3].animation.curAnim.name == 'confirm')
						camDisplaceX += camDisplaceExtend;
					
					camDisplaceY = 0;
					if (cStrum.members[1].animation.curAnim.name == 'confirm')
						camDisplaceY += camDisplaceExtend;
					if (cStrum.members[2].animation.curAnim.name == 'confirm')
						camDisplaceY -= camDisplaceExtend;

				}
			}
		}
		//
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				if (discordDifficultyOverrideShouldUse)
					DiscordClient.changePresence(detailsText, SONG.song
						+ " ("
						+ discordDifficultyOverride
						+ ")", gameHUD.iconP2.getCharacter(), true,
						songLength
						- Conductor.songPosition
						- ClientPrefs.noteOffset);
				else
					DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", gameHUD.iconP2.getCharacter());
			}
			else
			{
				if (discordDifficultyOverrideShouldUse)
					DiscordClient.changePresence(detailsText, SONG.song + " (" + discordDifficultyOverride + ")", gameHUD.iconP2.getCharacter());
				else
					DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", gameHUD.iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (discordDifficultyOverrideShouldUse)
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + discordDifficultyOverride + ")", gameHUD.iconP2.getCharacter());
			else
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", gameHUD.iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if (finishTimer != null)
			return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var songLengthTxt = "N/A";

	override public function update(elapsed:Float)
	{
		callOnLuas('onUpdate', [elapsed]);

		var currentBeat = (Conductor.songPosition / Conductor.crochet);

		if (hazardOverlayShit != null && !ClientPrefs.lowQuality && ClientPrefs.flashing)
		{
			if (hazardOverlayShit.alpha > 0) // Seperate if check because I'm paranoid of a crash -Haz
				hazardOverlayShit.alpha -= 1.2 * elapsed;
		}

		if (luisOverlayWarning != null && !ClientPrefs.lowQuality && ClientPrefs.flashing)
		{
			if (luisOverlayWarning.alpha > 0) // dont ask -Luis
				luisOverlayWarning.alpha -= 1.2 * elapsed;
		}
		if (!ClientPrefs.noShaders)
		{
			if (interlopeChroma != null && ClientPrefs.flashing)
			{
				if (interlopeChromaIntensity > 0)
				{
					// Effect is reduced at a much faster rate for swapping bullshit
					if (hazardModChartEffect == 5 || hazardModChartEffect == 3)
						interlopeChromaIntensity -= 0.082 * elapsed;
					else
						interlopeChromaIntensity -= 0.040 * elapsed;
				}
				else if (interlopeChromaIntensity < 0)
					interlopeChromaIntensity = 0; // Stop going below zero
				interlopeChroma.setChrome(interlopeChromaIntensity);
			}

			if (interlopeFadeinShader != null)
			{
				if (interlopeFadeinShaderFading)
				{
					if (interlopeFadeinShaderIntensity > 0)
						interlopeFadeinShaderIntensity -= 0.208 * elapsed;
					else if (interlopeFadeinShaderIntensity < 0)
					{
						interlopeFadeinShaderIntensity = 0; // Stop going below zero
						interlopeFadeinShaderFading = false;
					}
				}
				interlopeFadeinShader.setTiltShit(interlopeFadeinShaderIntensity);
			}

			if (censoryChroma != null && !ClientPrefs.lowQuality && ClientPrefs.flashing)
			{
				if (censoryChromaIntensity > 0)
					censoryChromaIntensity -= 0.05 * elapsed;
				else if (censoryChromaIntensity < 0)
					censoryChromaIntensity = 0; // Stop going below zero
				censoryChroma.setChrome(censoryChromaIntensity);
			}

			if (wiggleShitShow != null)
				wiggleShitShow.update(elapsed);

			if (wiggleShitShowCAMERA != null)
				wiggleShitShowCAMERA.update(elapsed);
		}

		// modchart case
		switch (hazardModChartEffect)
		{
			case 4:
				for (i in 0...playerStrums.length)
				{
					playerStrums.members[i].x = FlxMath.lerp(hazardModChartDefaultStrumX[i + 4],
						hazardModChartDefaultStrumX[i + 4] + (Math.sin((Conductor.songPosition / (Conductor.crochet * 16)) * Math.PI) * -200),
						hazardModChartVariable1);
				}

			case 1:
				// Scrolling effect
				// x spacing is 112!!!! -Haz
				// New logic:
				// Scrolling Horizontal
				for (i in 0...playerStrums.length)
				{
					playerStrums.members[i].x += hazardModChartVariable1;
					opponentStrums.members[i].x += hazardModChartVariable1;
					// if(i == 1) trace(playerStrums.members[i].x);
				}

				// Checking if it needs to be looped around
				if (hazardModChartVariable1 > 0)
				{
					if (playerStrums.members[1].x >= 1400)
					{
						playerStrums.members[2].x = -270;
						playerStrums.members[1].x = playerStrums.members[2].x - 112;
						playerStrums.members[3].x = playerStrums.members[2].x + 112;
						playerStrums.members[0].x = playerStrums.members[2].x - 224;
					}
				}
				else
				{
					if (playerStrums.members[2].x <= -270)
					{
						playerStrums.members[1].x = 1400;
						playerStrums.members[0].x = playerStrums.members[1].x - 112;
						playerStrums.members[2].x = playerStrums.members[1].x + 112;
						playerStrums.members[3].x = playerStrums.members[1].x + 224;
					}
				}
				if (hazardModChartVariable1 > 0)
				{
					if (opponentStrums.members[1].x >= 1400)
					{
						opponentStrums.members[2].x = -270;
						opponentStrums.members[1].x = opponentStrums.members[2].x - 112;
						opponentStrums.members[3].x = opponentStrums.members[2].x + 112;
						opponentStrums.members[0].x = opponentStrums.members[2].x - 224;
					}
				}
				else
				{
					if (opponentStrums.members[2].x <= -270)
					{
						opponentStrums.members[1].x = 1400;
						opponentStrums.members[0].x = opponentStrums.members[1].x - 112;
						opponentStrums.members[2].x = opponentStrums.members[1].x + 112;
						opponentStrums.members[3].x = opponentStrums.members[1].x + 224;
					}
				}

			case 7:
				// Speen (code from Inhuman mod. Does this count as an Inhuman mod leak?)
				for (i in 0...playerStrums.length)
				{
					if (i % 2 == 0)
					{
						playerStrums.members[i].x = hazardModChartDefaultStrumX[i + 4] + 55 + (Math.cos(currentBeat * Math.PI) * -55);
						playerStrums.members[i].y = hazardModChartDefaultStrumY[i + 4] + (Math.sin(currentBeat * Math.PI) * -55);
					}
					else
					{
						playerStrums.members[i].x = hazardModChartDefaultStrumX[i + 4] - 55 + (Math.cos(currentBeat * Math.PI) * 55);
						playerStrums.members[i].y = hazardModChartDefaultStrumY[i + 4] + (Math.sin(currentBeat * Math.PI) * 55);
					}
				}

			case 2:
				// Screen shaking effect (Termination)
				camHUD.angle = Math.sin(currentBeat * Math.PI) * 5;

			default:
				// do nothing
		}

		for (i in 0...opponentStrums.length)
		{
			if (hazardModChartDefaultStrumX[i] != 0 && fancyModchartStrumX[0] != 0)
				opponentStrums.members[i].x = hazardModChartDefaultStrumX[i] + fancyModchartStrumX[0] * (Math.sin((currentBeat + i * 0.25) * Math.PI));
			if (hazardModChartDefaultStrumY[i] != 0 && fancyModchartStrumY[0] != 0)
				opponentStrums.members[i].y = hazardModChartDefaultStrumY[i] + fancyModchartStrumY[0] * (Math.cos((currentBeat + i * 0.25) * Math.PI));
		}

		for (i in 0...playerStrums.length)
		{
			if (hazardModChartDefaultStrumX[i + 4] != 0 && fancyModchartStrumX[1] != 0)
				playerStrums.members[i].x = hazardModChartDefaultStrumX[i + 4] + fancyModchartStrumX[1] * (Math.sin((currentBeat + i * 0.25) * Math.PI));
			if (hazardModChartDefaultStrumY[i + 4] != 0 && fancyModchartStrumY[1] != 0)
				playerStrums.members[i].y = hazardModChartDefaultStrumY[i + 4] + fancyModchartStrumY[1] * (Math.cos((currentBeat + i * 0.25) * Math.PI));
		}

		if (!inCutscene)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if (!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle'))
			{
				boyfriendIdleTime += elapsed;
				if (boyfriendIdleTime >= 0.15) // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
			}
			else
				boyfriendIdleTime = 0;
		}

		super.update(elapsed);

		if (controls.PAUSE) // Modified so that enter can skip the thanks for playing screen.
		{
			if (startedCountdown && canPause)
			{
				var ret:Dynamic = callOnLuas('onPause', []);
				if (ret != FunkinLua.Function_Stop)
				{
					persistentUpdate = false;
					persistentDraw = true;
					paused = true;
					if (FlxG.sound.music != null)
					{
						FlxG.sound.music.pause();
						vocals.pause();
					}
					openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
					#if desktop
					if (discordDifficultyOverrideShouldUse)
						DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + discordDifficultyOverride + ")", gameHUD.iconP2.getCharacter());
					else
						DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", gameHUD.iconP2.getCharacter());
					#end
				}
			}
			else if (canSkipEndScreen)
				endSong();
		}
		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			openChartEditor();
		}
		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		if (health > 2)
			health = 2;
		else if (health < maxHealth && godMode)
			health = 0;

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene)
		{
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(dad.curCharacter));
		}
		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
			moveCameraSection(Std.int(curStep / 16));

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				/*if (Conductor.songPosition >= 0)
				startSong(); */
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;
			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;
				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}
		}
		if (!disableDefaultCamZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
			causeOfDeath = 'reset';
		}
		doDeathCheck();

		var gasOffset:Array<Int> = [];
		if (dad.curCharacter.startsWith("kb")
			&& !dad.curCharacter.startsWith("kb-classic")
			&& qt_gaskb != null
			&& !ClientPrefs.lowQuality)
		{
			switch (dad.animation.name)
			{
				case 'danceRight':
					switch (dad.animation.curAnim.curFrame)
					{
						case 0:
							gasOffset[0] = -948;
							gasOffset[1] = -718;
							gasOffset[2] = -34;
						case 1:
							gasOffset[0] = -945;
							gasOffset[1] = -718;
							gasOffset[2] = -33;
						case 2:
							gasOffset[0] = -960;
							gasOffset[1] = -718;
							gasOffset[2] = -33;
						case 3 | 4:
							gasOffset[0] = -958;
							gasOffset[1] = -717;
							gasOffset[2] = -33;
						case 5:
							gasOffset[0] = -946;
							gasOffset[1] = -715;
							gasOffset[2] = -32;
						case 6 | 7 | 8 | 9:
							gasOffset[0] = -939;
							gasOffset[1] = -717;
							gasOffset[2] = -32;
					}
				case 'danceLeft':
					switch (dad.animation.curAnim.curFrame)
					{
						case 0:
							gasOffset[0] = -914;
							gasOffset[1] = -718;
							gasOffset[2] = -29;
						case 1:
							gasOffset[0] = -912;
							gasOffset[1] = -716;
							gasOffset[2] = -29;
						case 2 | 3 | 4 | 5:
							gasOffset[0] = -903;
							gasOffset[1] = -717;
							gasOffset[2] = -28;
						case 6 | 7 | 8 | 9:
							gasOffset[0] = -920;
							gasOffset[1] = -718;
							gasOffset[2] = -28;
					}
				case 'idle-alt':
					switch (dad.animation.curAnim.curFrame)
					{
						case 0:
							gasOffset[0] = -785;
							gasOffset[1] = -722;
							gasOffset[2] = -13;
						case 1:
							gasOffset[0] = -785;
							gasOffset[1] = -714;
							gasOffset[2] = -13;
						case 2 | 3 | 4 | 5:
							gasOffset[0] = -782;
							gasOffset[1] = -711;
							gasOffset[2] = -13;
						case 6:
							gasOffset[0] = -784;
							gasOffset[1] = -714;
							gasOffset[2] = -13;
						case 7 | 8 | 9:
							gasOffset[0] = -787;
							gasOffset[1] = -718;
							gasOffset[2] = -13;
					}
				case 'idle':
					gasOffset[0] = FlxG.random.int(-815, -819);
					gasOffset[1] = FlxG.random.int(-738, -745);
					gasOffset[2] = -13;
				case 'singLEFT':
					switch (dad.animation.curAnim.curFrame)
					{
						case 0 | 1:
							gasOffset[0] = -1155;
							gasOffset[1] = -514;
							gasOffset[2] = -64;
						case 2:
							gasOffset[0] = -1120;
							gasOffset[1] = -523;
							gasOffset[2] = -64;
						case 3 | 4:
							gasOffset[0] = -1115;
							gasOffset[1] = -522;
							gasOffset[2] = -60;
					}
				case 'singRIGHT':
					switch (dad.animation.curAnim.curFrame)
					{
						case 0 | 1:
							gasOffset[0] = -731;
							gasOffset[1] = -769;
							gasOffset[2] = -8;
						case 2:
							gasOffset[0] = -758;
							gasOffset[1] = -771;
							gasOffset[2] = -9;
						case 3 | 4:
							gasOffset[0] = -767;
							gasOffset[1] = -771;
							gasOffset[2] = -11;
					}
				case 'singUP':
					switch (dad.animation.curAnim.curFrame)
					{
						case 0:
							gasOffset[0] = -850;
							gasOffset[1] = -821;
							gasOffset[2] = -14;
						case 1:
							gasOffset[0] = -844;
							gasOffset[1] = -814;
							gasOffset[2] = -13;
						case 2:
							gasOffset[0] = -843;
							gasOffset[1] = -803;
							gasOffset[2] = -13;
						case 3:
							gasOffset[0] = -840;
							gasOffset[1] = -791;
							gasOffset[2] = -13;
						case 4:
							gasOffset[0] = -837;
							gasOffset[1] = -786;
							gasOffset[2] = -13;
					}
				case 'singDOWN':
					switch (dad.animation.curAnim.curFrame)
					{
						case 0 | 1:
							gasOffset[0] = -909;
							gasOffset[1] = -582;
							gasOffset[2] = -30;
						case 2:
							gasOffset[0] = -910;
							gasOffset[1] = -589;
							gasOffset[2] = -30;
						case 3 | 4:
							gasOffset[0] = -905;
							gasOffset[1] = -584;
							gasOffset[2] = -30;
					}
			}
			qt_gaskb.x = dad.x + gasOffset[0];
			qt_gaskb.y = dad.y + gasOffset[1];
			qt_gaskb.angle = gasOffset[2]; // Yoshubs, sorry.
		}

		if (unspawnNotes[0] != null)
		{
			var time:Float = 3000; // shit be werid on 4:3
			if (songSpeed < 1)
				time /= songSpeed;
			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}
		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;

			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if (!daNote.mustPress)
					strumGroup = opponentStrums;

				// unoptimised asf camera control based on strums
				strumCameraRoll(strumGroup, (strumGroup == playerStrums));

				var strumX:Float = strumGroup.members[daNote.noteData].x;
				var strumY:Float = strumGroup.members[daNote.noteData].y;
				var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
				var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
				var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
				var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				if (!freezeNotes)
				{
					if (strumScroll) // Downscroll

						daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					else // Upscroll

						daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
				}

				var angleDir = strumDirection * Math.PI / 180;
				if (daNote.copyAngle)
					daNote.angle = strumDirection - 90 + strumAngle;

				if (daNote.copyAlpha)
					daNote.alpha = strumAlpha;

				if (daNote.noteType == "Hurt Note")
					daNote.alpha *= ClientPrefs.hurtNoteAlpha;

				if (daNote.copyX)
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

				if (daNote.copyY && !freezeNotes)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

					// Jesus fuck this took me so much mother fucking time AAAAAAAAAA
					if (strumScroll && daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith('end'))
						{
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;

							daNote.y -= 19;
						}
						daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}

				if (!daNote.haveCustomTexture && !ClientPrefs.lowQuality)
					if (daNote.gfNote)
						daNote.texture = gf.noteSkinFile;
					else
						daNote.texture = daNote.mustPress ? boyfriend.noteSkinFile : dad.noteSkinFile;
				// ayo i just love this

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote && !dad.stunned && !daNote.hitCausesMiss)
					opponentNoteHit(daNote);

				if (Conductor.songPosition > noteKillOffset + daNote.strumTime && !freezeNotes) // kill the notes that opponent dont presses
				{
					if (!daNote.mustPress && daNote.ignoreNote && daNote.hitCausesMiss && daNote.tooLate)
					{
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}

				if (daNote.mustPress && cpuControlled)
				{
					if (daNote.isSustainNote)
					{
						if (daNote.canBeHit)
							goodNoteHit(daNote);
					}
					else if (daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress))
						goodNoteHit(daNote);
				}

				var center:Float = strumY + Note.swagWidth / 2;
				if (strumGroup.members[daNote.noteData].sustainReduce
					&& daNote.isSustainNote
					&& (daNote.mustPress || !daNote.ignoreNote)
					&& (!daNote.mustPress
						|| ((daNote.wasGoodHit || !daNote.hitCausesMiss) || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					if (strumScroll)
					{
						if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
					else
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}

				if (opponentNoteColourChange && !daNote.mustPress)
					daNote.color = FlxColor.GRAY; // darken
				else
					daNote.color = FlxColor.WHITE; // back to normal

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime && !freezeNotes)
				{
					if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
						noteMiss(daNote);

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}
		checkEventNote();
		if (!inCutscene)
		{
			if (!cpuControlled)
				keyShit();
			else if (!bfDodging
				&& !boyfriend.stunned
				&& boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
				&& boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
			}
		}
		if (!endingSong && !startingSong)
		{
			if (!skippedIntro && introSkip > 0)
			{
				if (Conductor.songPosition < introSkip * 1000)
				{
					if (FlxG.keys.justPressed.SPACE && deathCounter > 0)
					{ // skip to the future! wow!
						skipIntro();
					}
				}
				else if (!skippedIntro)
				{
					skippedIntro = true;
					remove(introSkipSprite);
					trace("Didn't skip Intro!");
				}
			}
		}
		#if debug
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.FIVE)
			{
				godMode = !godMode;
				if (godMode)
					gameHUD.scoreTxt.color = FlxColor.CYAN;
				else
					gameHUD.scoreTxt.color = FlxColor.WHITE;
			}
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO)
			{ // Go 10 seconds into the future :O
				FlxG.sound.music.pause();
				vocals.pause();
				Conductor.songPosition += 10000;
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.strumTime + 800 < Conductor.songPosition)
					{
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});

				for (i in 0...unspawnNotes.length)
				{
					var daNote:Note = unspawnNotes[0];

					if (daNote.strumTime + 800 >= Conductor.songPosition)
					{
						break;
					}
					daNote.active = false;
					daNote.visible = false;
					daNote.kill();
					unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
					daNote.destroy();
				}
				health = 1.8; // Restores health?
				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.play();
				vocals.time = Conductor.songPosition;
				vocals.play();
			}
		}
		#end
		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
		for (i in shaderUpdates)
		{
			i(elapsed);
		}
	}

	function skipIntro()
	{
		trace("Skipped Intro!");
		skippedIntro = true;
		remove(introSkipSprite);
		if (SONG.song.toLowerCase() == "interlope")
		{
			if (interlopeIntroTween != null)
				interlopeIntroTween.cancel();
			if (interlopeIntroTweenHUD != null)
				interlopeIntroTweenHUD.cancel();
			for (tween in interlopeIntroTweens)
			{ // Stops moving the arrows
				tween.cancel();
			}

			camHUD.visible = true;
			camHUD.alpha = 1;
			for (i in 0...playerStrums.length)
			{
				// Forces arrows into starting positions
				playerStrums.members[i].angle = 0;
				playerStrums.members[i].alpha = 1;
				playerStrums.members[i].x = hazardModChartDefaultStrumX[i + 4];
				playerStrums.members[i].y = hazardModChartDefaultStrumY[i + 4];
			}
		}

		FlxG.sound.music.pause();
		#if debug
		health = 2; // Don't change health
		#end
		vocals.pause();
		Conductor.songPosition = introSkip * 1000;
		notes.forEachAlive(function(daNote:Note)
		{
			if (daNote.strumTime + 800 < Conductor.songPosition)
			{
				daNote.active = false;
				daNote.visible = false;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
		});
		for (i in 0...unspawnNotes.length)
		{
			var daNote:Note = unspawnNotes[0];
			if (daNote.strumTime + 800 >= Conductor.songPosition)
			{
				break;
			}

			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
			daNote.destroy();
		}

		FlxG.sound.music.time = Conductor.songPosition;
		FlxG.sound.music.play();

		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	function epicStuff()
	{
		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		// Don't spoil the fun for others.
		if (!ClientPrefs.lowQuality && !usedPractice) // if have bot play on will dont have the lore, simple :)
		{ // Don't do secrets if on low quality.
			var wack:Bool = false;
			if (SONG.song.toLowerCase() == "interlope")
				wack = FlxG.random.bool(10); // Increased chance for secrets in Interlope.
			else
				wack = FlxG.random.bool(5);
			if (wack)
			{
				var horror:FlxSprite;
				var wack:Int = FlxG.random.int(1, 9);
				// Update v2.1, Interlope screen is 100% now after Cessation. Will be like this until you've beaten Interlope.
				if (!Achievements.achievementsMap.exists(Achievements.achievementsStuff[10][2])
					&& Achievements.achievementsMap.exists(Achievements.achievementsStuff[5][2]))
				{ // If you can access Interlope, allows for the Interlope hint to be shown.
					wack = 100;
				}
				switch (wack)
				{
					case 2:
						horror = new FlxSprite(-80).loadGraphic(Paths.image('hazard/qt-port/stage/topsecretfolder/DoNotLook/horrorSecret02'));
					case 3:
						horror = new FlxSprite(-80).loadGraphic(Paths.image('hazard/qt-port/stage/topsecretfolder/DoNotLook/horrorSecret03'));
					case 4:
						horror = new FlxSprite(-80).loadGraphic(Paths.image('hazard/qt-port/stage/topsecretfolder/DoNotLook/horrorSecret04'));
					case 5:
						horror = new FlxSprite(-80).loadGraphic(Paths.image('hazard/qt-port/stage/topsecretfolder/DoNotLook/horrorSecret05'));
					case 6:
						horror = new FlxSprite(-80).loadGraphic(Paths.image('hazard/qt-port/stage/topsecretfolder/DoNotLook/horrorSecret06'));
					case 7:
						horror = new FlxSprite(-80).loadGraphic(Paths.image('hazard/qt-port/stage/topsecretfolder/DoNotLook/horrorSecret07'));
					case 8:
						horror = new FlxSprite(-80).loadGraphic(Paths.image('hazard/qt-port/stage/topsecretfolder/DoNotLook/horrorSecret08'));
					case 9:
						horror = new FlxSprite(-80)
							.loadGraphic(Paths.image('hazard/qt-port/stage/topsecretfolder/DoNotLook/horrorSecret09')); // v2.2 final secret screen.
					case 100: // Interlope secret screen
						horror = new FlxSprite(-80).loadGraphic(Paths.image('hazard/qt-port/stage/topsecretfolder/DoNotLook/horrorSecretInterlope'));
					default:
						horror = new FlxSprite(-80).loadGraphic(Paths.image('hazard/qt-port/stage/topsecretfolder/DoNotLook/horrorSecret01'));
				}
				horror.scrollFactor.x = 0;
				horror.scrollFactor.y = 0.15;
				horror.setGraphicSize(Std.int(horror.width * 1.1));
				horror.updateHitbox();
				horror.screenCenter();
				horror.antialiasing = ClientPrefs.globalAntialiasing;
				horror.cameras = [camOther];
				var visiblityShit:Bool = camHUD.visible; // In case the HUD starts invisible or visible, I do this shit instead.
				for (hud in allUIs)
					hud.visible = false; // nah looks good, i would update to the Paths.imagerandom put idk anymore xd
				add(horror);

				new FlxTimer().start(0.7, function(tmr:FlxTimer)
				{
					camHUD.visible = visiblityShit;
					remove(horror);
				});
			}
		}
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		THISISFUCKINGDISGUSTINGPLEASESAVEME = false;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; // Don't mess with this on Lua!!!

	function doDeathCheck(?skipHealthCheck:Bool = false)
	{
		if (((skipHealthCheck && instakillOnMiss) || health <= maxHealth) && !practiceMode && !isDead && !godMode)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if (ret != FunkinLua.Function_Stop)
			{
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens)
				{
					tween.active = true;
				}
				for (tween in interlopeIntroTweens)
				{
					tween.active = true;
				}
				for (timer in modchartTimers)
				{
					timer.active = true;
				}
				if (inhumanSong)
				{ // Use INHUMAN gameover screen instead of vanilla.
					BrutalityGameOverSubstate.characterName = 'amelia'; // i mean this is good, but i guess would be better use the new function for this :kubeB:
					openSubState(new BrutalityGameOverSubstate(causeOfDeath, this));
				}
				else
					openSubState(new GameOverSubstate(causeOfDeath, boyfriend.getScreenPosition().x - boyfriend.positionArray[0],
						boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				if (discordDifficultyOverrideShouldUse)
					DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + discordDifficultyOverride + ")", gameHUD.iconP2.getCharacter());
				else
					DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", gameHUD.iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0][0];
			if (Conductor.songPosition < leStrumTime)
			{
				break;
			}

			var value1:String = '';
			if (eventNotes[0][2] != null)
				value1 = eventNotes[0][2];

			var value2:String = '';
			if (eventNotes[0][3] != null)
				value2 = eventNotes[0][3];

			triggerEventNote(eventNotes[0][1], value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String)
	{
		var pressed:Bool = Reflect.getProperty(controls, key);
		// trace('Control result: ' + pressed);
		return pressed;
	}

	public function kbATTACK_ALERT(alertType:Int = 1, playSound:Bool = true):Void
	{
		// Feel free to add your own alert types in here. Make sure that the alert sprite has the animation and the sound is also available.
		switch (alertType)
		{
			case 2:
				if (playSound)
					FlxG.sound.play(Paths.sound('hazard/alertDouble'), 1);

				if (ClientPrefs.noteOffset <= 0)
					kbATTACK_ALERT_PART2(0.55, 'alertDOUBLE');
				else
				{
					new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer)
					{
						kbATTACK_ALERT_PART2(0.55, 'alertDOUBLE');
					});
				}

			case 3:
				if (playSound)
					FlxG.sound.play(Paths.sound('hazard/alertTriple'), 1);

				if (ClientPrefs.noteOffset <= 0)
					kbATTACK_ALERT_PART2(0.5875, 'alertTRIPLE');
				else
				{
					new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer)
					{
						kbATTACK_ALERT_PART2(0.5875, 'alertTRIPLE');
					});
				}

			case 4:
				if (playSound)
					FlxG.sound.play(Paths.sound('hazard/alertQuadruple'), 1);

				if (ClientPrefs.noteOffset <= 0)
					kbATTACK_ALERT_PART2(0.6, 'alertQUAD');
				else
				{
					new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer)
					{
						kbATTACK_ALERT_PART2(0.6, 'alertQUAD');
					});
				}

			default:
				if (playSound)
					FlxG.sound.play(Paths.sound('hazard/alert'), 1);

				// Not the best way to do offset since I fear lag can lead to an offsync sawblade, but hey I tried at least and it's better then no support at all. -Haz
				if (ClientPrefs.noteOffset <= 0)
					kbATTACK_ALERT_PART2(0.49, 'alert');
				else
				{
					new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer)
					{
						kbATTACK_ALERT_PART2(0.49, 'alert');
					});
				}
		}
	}

	function kbATTACK_ALERT_PART2(newAlpha:Float, animationToPlay:String):Void
	{
		if (!qtAlertAdded)
		{
			add(kb_attack_alert);
			qtAlertAdded = true;
		}

		// NewAlpha is for the alert overlay vigenette.
		if (!ClientPrefs.lowQuality && ClientPrefs.flashing && hazardOverlayShit != null)
			hazardOverlayShit.alpha = newAlpha;

		kb_attack_alert.animation.play(animationToPlay);
		switch (animationToPlay)
		{
			default:
				kb_attack_alert.offset.set(0, 0);
			case "alertQUAD":
				kb_attack_alert.offset.set(152, 38);
			case "alertTRIPLE":
				kb_attack_alert.offset.set(150, 56);
			case "alertDOUBLE":
				kb_attack_alert.offset.set(70, 5);
		}
	}

	function kbATTACK_DELAYED(state:Bool = false, soundToPlay:String = 'hazard/attack', instaKill:Bool = false)
	{
		if (state)
		{
			if (!qtSawbladeAdded)
			{
				add(kb_attack_saw);
				qtSawbladeAdded = true;
			}
			// Play saw attack animation
			kb_attack_saw.animation.play('fire');
			kb_attack_saw.offset.set(1800, -70);
			FlxG.camera.shake(0.001675, 0.6);
			camHUD.shake(0.001675, 0.2);
			if (ClientPrefs.flashing && !ClientPrefs.lowQuality)
			{
				if (luisOverlayWarning != null)
					luisOverlayWarning.alpha = 0.44;
				if (censoryChroma != null)
					censoryChromaIntensity = 0.01;
			}
			if (cpuControlled)
				bfDodge();
			// Slight delay for animation. Yeah I know I should be doing this using curStep and curBeat and what not, but I'm lazy -Haz
			new FlxTimer().start(0.09, function(tmr:FlxTimer)
			{
				if (!bfDodging)
				{
					if (!godMode)
					{
						sawbladeHits++;
						trace("sawbladeHits: " + sawbladeHits);

						// Classic Termination sawblade which instakill.
						// After 3rd sawblade, will guarantee an instakill.
						if ((instaKill || sawbladeHits > 3 || (storyDifficulty == 2 && SONG.song.toLowerCase() == "termination")))
						{
							// MURDER THE BITCH!
							trace("Instakill sawblade missed");
							health -= 404;
							causeOfDeath = "sawblade";
							#if ACHIEVEMENTS_ALLOWED
							Achievements.sawbladeDeath++;
							FlxG.save.data.sawbladeDeath = Achievements.sawbladeDeath;
							var achieve:String = checkForAchievement(['sawblade_death']);
							if (achieve != null)
								startAchievement(achieve);
							else
								FlxG.save.flush();

							FlxG.log.add('ClassicBonks: ' + Achievements.sawbladeDeath);
							#end
						}
						else
						{
							health -= 0.265;
							if (health >= maxHealth + 0.51125)
							{
								maxHealth = maxHealth + 0.51125;
								gameHUD.reduceMaxHealth();
								// Only reduce max health if possible. This is here to hopefully avoid a crash with the regerneating the bar or something.
							}
							// mmmmm I loved scuffed code. But it works!
							if (health < maxHealth)
							{ // If the health is too low after the sawblade, sawblade kills you.
								health -= 404; // v2.1, I forgot to add this line of code so errr, now sawblades actually kill you again :D
								// srs?
								causeOfDeath = "sawblade";
								#if ACHIEVEMENTS_ALLOWED
								Achievements.sawbladeDeath++;
								FlxG.save.data.sawbladeDeath = Achievements.sawbladeDeath;
								var achieve:String = checkForAchievement(['sawblade_death']);
								if (achieve != null)
									startAchievement(achieve);
								else
									FlxG.save.flush();

								FlxG.log.add('Bonks: ' + Achievements.sawbladeDeath);
								#end
							}
							else
							{
								// Done so that the sound doesn't play if the sawblade would've killed the player.
								if (ClientPrefs.qtBonk)
									FlxG.sound.play(Paths.sound('bonk'), 1); // This is fucking amazing. // true
								else
									FlxG.sound.play(Paths.sound('hazard/sawbladeHit'), 1); // Ouch
							}
							boyfriend.stunned = true;
							boyfriend.playAnim('hurt', true);
							new FlxTimer().start(0.495, function(tmr:FlxTimer)
							{
								boyfriend.stunned = false;
							});
						}
					}
				}
			});
		}
		else
		{
			// Forces BF to be able to dodge again in preperation for the sawblade. Mainly useful for the Double Sawblade.
			bfCanDodge = true;
			kb_attack_saw.animation.play('prepare');
			kb_attack_saw.offset.set(-370, -10);
		}
	}

	public function KBATTACK(state:Bool = false, soundToPlay:String = 'hazard/attack', instaKill:Bool = false):Void
	{
		if (state)
			FlxG.sound.play(Paths.sound(soundToPlay), 0.765);

		if (!qtSawbladeAdded)
		{
			add(kb_attack_saw);
			qtSawbladeAdded = true;
		}

		if (ClientPrefs.noteOffset <= 0)
			kbATTACK_DELAYED(state, soundToPlay, instaKill);
		else
			new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer)
			{
				kbATTACK_DELAYED(state, soundToPlay, instaKill);
			});
	}

	// Pincer logic, used by the modchart but can be hardcoded like saws if you want.
	public function KBPINCER_PREPARE(laneID:Int, goAway:Bool):Void
	{
		// 1 = BF far left, 4 = BF far right. This only works for BF!
		// Update! 5 now refers to the far left lane (KB side). Mainly used for the shaking section or whatever.
		// UPDATE 2! 6 now refers to the far right lane (KB side). Used for the screen shasking effect when in middle scroll.
		pincer1.cameras = [camHUD];
		pincer2.cameras = [camHUD];
		pincer3.cameras = [camHUD];
		pincer4.cameras = [camHUD];

		// This is probably the most disgusting code I've ever written in my life.
		// OH MY FUCKING GOD HAZARD, YOU DIDN'T EVEN FIX THIS AWFUL SHIT? WHY?! FUCK YOU FOR LEAVING THIS HERE! -Future Haz
		// All because I can't be bothered to learn arrays and shit.
		// Would've converted this to a switch case but I'm too scared to change it so deal with it.
		if (laneID == 1)
		{
			pincer1.loadGraphic(Paths.image('hazard/qt-port/pincer-open'), false);
			if (ClientPrefs.downScroll)
			{
				if (!goAway)
				{
					pincer1.setPosition(strumLineNotes.members[4].x, strumLineNotes.members[4].y + 500);
					add(pincer1);
					FlxTween.tween(pincer1, {y: strumLineNotes.members[4].y}, 0.3, {ease: FlxEase.elasticOut});
				}
				else
				{
					FlxTween.tween(pincer1, {y: strumLineNotes.members[4].y + 500}, 0.4, {
						ease: FlxEase.backIn,
						onComplete: function(twn:FlxTween)
						{
							remove(pincer1);
						}
					});
				}
			}
			else
			{
				if (!goAway)
				{
					pincer1.setPosition(strumLineNotes.members[4].x, strumLineNotes.members[4].y - 500);
					add(pincer1);
					FlxTween.tween(pincer1, {y: strumLineNotes.members[4].y}, 0.3, {ease: FlxEase.elasticOut});
				}
				else
				{
					FlxTween.tween(pincer1, {y: strumLineNotes.members[4].y - 500}, 0.4, {
						ease: FlxEase.backIn,
						onComplete: function(twn:FlxTween)
						{
							remove(pincer1);
						}
					});
				}
			}
		}
		else if (laneID == 5)
		{ // Targets far left note for Dad (KB). Used for the screenshake thing
			pincer1.loadGraphic(Paths.image('hazard/qt-port/pincer-open'), false);
			if (ClientPrefs.downScroll)
			{
				if (!goAway)
				{
					pincer1.setPosition(strumLineNotes.members[0].x, strumLineNotes.members[0].y + 500);
					add(pincer1);
					FlxTween.tween(pincer1, {y: strumLineNotes.members[0].y}, 0.3, {ease: FlxEase.elasticOut});
				}
				else
				{
					FlxTween.tween(pincer1, {y: strumLineNotes.members[0].y + 500}, 0.4, {
						ease: FlxEase.backIn,
						onComplete: function(twn:FlxTween)
						{
							remove(pincer1);
						}
					});
				}
			}
			else
			{
				if (!goAway)
				{
					pincer1.setPosition(strumLineNotes.members[0].x, strumLineNotes.members[0].y - 500);
					add(pincer1);
					FlxTween.tween(pincer1, {y: strumLineNotes.members[0].y}, 0.3, {ease: FlxEase.elasticOut});
				}
				else
				{
					FlxTween.tween(pincer1, {y: strumLineNotes.members[0].y - 500}, 0.4, {
						ease: FlxEase.backIn,
						onComplete: function(twn:FlxTween)
						{
							remove(pincer1);
						}
					});
				}
			}
		}
		else if (laneID == 6)
		{ // Targets far right note for Dad (KB). Used for the screenshake thing when middle scrolling
			pincer2.loadGraphic(Paths.image('hazard/qt-port/pincer-open'), false);
			if (ClientPrefs.downScroll)
			{
				if (!goAway)
				{
					pincer2.setPosition(strumLineNotes.members[3].x, strumLineNotes.members[3].y + 500);
					add(pincer2);
					FlxTween.tween(pincer2, {y: strumLineNotes.members[3].y}, 0.3, {ease: FlxEase.elasticOut});
				}
				else
				{
					FlxTween.tween(pincer2, {y: strumLineNotes.members[3].y + 500}, 0.4, {
						ease: FlxEase.backIn,
						onComplete: function(twn:FlxTween)
						{
							remove(pincer2);
						}
					});
				}
			}
			else
			{
				if (!goAway)
				{
					pincer2.setPosition(strumLineNotes.members[3].x, strumLineNotes.members[3].y - 500);
					add(pincer2);
					FlxTween.tween(pincer2, {y: strumLineNotes.members[3].y}, 0.3, {ease: FlxEase.elasticOut});
				}
				else
				{
					FlxTween.tween(pincer2, {y: strumLineNotes.members[3].y - 500}, 0.4, {
						ease: FlxEase.backIn,
						onComplete: function(twn:FlxTween)
						{
							remove(pincer2);
						}
					});
				}
			}
		}
		else if (laneID == 2)
		{
			pincer2.loadGraphic(Paths.image('hazard/qt-port/pincer-open'), false);
			if (ClientPrefs.downScroll)
			{
				if (!goAway)
				{
					pincer2.setPosition(strumLineNotes.members[5].x, strumLineNotes.members[5].y + 500);
					add(pincer2);
					FlxTween.tween(pincer2, {y: strumLineNotes.members[5].y}, 0.3, {ease: FlxEase.elasticOut});
				}
				else
				{
					FlxTween.tween(pincer2, {y: strumLineNotes.members[5].y + 500}, 0.4, {
						ease: FlxEase.backIn,
						onComplete: function(twn:FlxTween)
						{
							remove(pincer2);
						}
					});
				}
			}
			else
			{
				if (!goAway)
				{
					pincer2.setPosition(strumLineNotes.members[5].x, strumLineNotes.members[5].y - 500);
					add(pincer2);
					FlxTween.tween(pincer2, {y: strumLineNotes.members[5].y}, 0.3, {ease: FlxEase.elasticOut});
				}
				else
				{
					FlxTween.tween(pincer2, {y: strumLineNotes.members[5].y - 500}, 0.4, {
						ease: FlxEase.backIn,
						onComplete: function(twn:FlxTween)
						{
							remove(pincer2);
						}
					});
				}
			}
		}
		else if (laneID == 3)
		{
			pincer3.loadGraphic(Paths.image('hazard/qt-port/pincer-open'), false);
			if (ClientPrefs.downScroll)
			{
				if (!goAway)
				{
					pincer3.setPosition(strumLineNotes.members[6].x, strumLineNotes.members[6].y + 500);
					add(pincer3);
					FlxTween.tween(pincer3, {y: strumLineNotes.members[6].y}, 0.3, {ease: FlxEase.elasticOut});
				}
				else
				{
					FlxTween.tween(pincer3, {y: strumLineNotes.members[6].y + 500}, 0.4, {
						ease: FlxEase.backIn,
						onComplete: function(twn:FlxTween)
						{
							remove(pincer3);
						}
					});
				}
			}
			else
			{
				if (!goAway)
				{
					pincer3.setPosition(strumLineNotes.members[6].x, strumLineNotes.members[6].y - 500);
					add(pincer3);
					FlxTween.tween(pincer3, {y: strumLineNotes.members[6].y}, 0.3, {ease: FlxEase.elasticOut});
				}
				else
				{
					FlxTween.tween(pincer3, {y: strumLineNotes.members[6].y - 500}, 0.4, {
						ease: FlxEase.backIn,
						onComplete: function(twn:FlxTween)
						{
							remove(pincer3);
						}
					});
				}
			}
		}
		else if (laneID == 4)
		{
			pincer4.loadGraphic(Paths.image('hazard/qt-port/pincer-open'), false);
			if (ClientPrefs.downScroll)
			{
				if (!goAway)
				{
					pincer4.setPosition(strumLineNotes.members[7].x, strumLineNotes.members[7].y + 500);
					add(pincer4);
					FlxTween.tween(pincer4, {y: strumLineNotes.members[7].y}, 0.3, {ease: FlxEase.elasticOut});
				}
				else
				{
					FlxTween.tween(pincer4, {y: strumLineNotes.members[7].y + 500}, 0.4, {
						ease: FlxEase.backIn,
						onComplete: function(twn:FlxTween)
						{
							remove(pincer4);
						}
					});
				}
			}
			else
			{
				if (!goAway)
				{
					pincer4.setPosition(strumLineNotes.members[7].x, strumLineNotes.members[7].y - 500);
					add(pincer4);
					FlxTween.tween(pincer4, {y: strumLineNotes.members[7].y}, 0.3, {ease: FlxEase.elasticOut});
				}
				else
				{
					FlxTween.tween(pincer4, {y: strumLineNotes.members[7].y - 500}, 0.4, {
						ease: FlxEase.backIn,
						onComplete: function(twn:FlxTween)
						{
							remove(pincer4);
						}
					});
				}
			}
		}
		else
		{
			trace("Invalid LaneID for pincer");
		}
	}

	function TerminationIntroShit(state:Int, playerShit:Bool):Void
	{
		FlxG.camera.shake(0.002, 1);
		camHUD.shake(0.002, 1);
		if (playerShit)
		{
			playerStrums.members[state].y += (ClientPrefs.downScroll ? 100 : -100);
			FlxTween.tween(playerStrums.members[state], {y: hazardModChartDefaultStrumY[state], alpha: 1}, 1.22, {ease: FlxEase.cubeOut});
		}
		else
		{
			opponentStrums.members[state].y += (ClientPrefs.downScroll ? 100 : -100);
			FlxTween.tween(opponentStrums.members[state], {y: hazardModChartDefaultStrumY[state], alpha: forceMiddleScroll ? 0.35 : 1}, 1.22,
				{ease: FlxEase.cubeOut});
		}
	}

	function TerminationOutroShit(state:Int):Void
	{
		if (state > 3)
		{
			// trace("Bye bye player", state-4);
			FlxTween.tween(playerStrums.members[state - 4], {alpha: 0}, 1.1, {ease: FlxEase.sineInOut});
		}
		else
		{
			// trace("Bye bye opponent", state);
			FlxTween.tween(opponentStrums.members[state], {alpha: 0}, 1.1, {ease: FlxEase.sineInOut});
		}
	}

	public function KBPINCER_GRAB(laneID:Int):Void
	{
		switch (laneID)
		{
			case 1 | 5:
				pincer1.loadGraphic(Paths.image('hazard/qt-port/pincer-close'), false);
			case 2:
				pincer2.loadGraphic(Paths.image('hazard/qt-port/pincer-close'), false);
			case 3:
				pincer3.loadGraphic(Paths.image('hazard/qt-port/pincer-close'), false);
			case 4:
				pincer4.loadGraphic(Paths.image('hazard/qt-port/pincer-close'), false);
			default:
				trace("Invalid LaneID for pincerGRAB");
		}
	}

	public function qtStreetTV(stateID:Int)
	{
		/*Use to control the TV's on QT's stage.
		0 = static
		1 = alert
		2 = instructions part 1
		3 = instructions part 2
		4 = watch out
		5 = BLabs moment 
		6 = Glitch
		7 = Bluescreen
		8 = incoming drop */
		switch (stateID)
		{
			case 0:
				qt_tv01.animation.play("idle");
			case 2:
				qt_tv01.animation.play("instructions");
			case 3:
				qt_tv01.animation.play("gl");
			case 1:
				qt_tv01.animation.play("alert");
			case 4:
				qt_tv01.animation.play("watch");
			case 5:
				qt_tv01.animation.play("eye");
			case 6:
				qt_tv01.animation.play("error");
			case 7:
				qt_tv01.animation.play("404");
			case 9:
				qt_tv01.animation.play("drop");
			case 8:
				qt_tv01.animation.play("heart");
			case 420 | 69:
				qt_tv01.animation.play("sus");
		}
		qtTVstate = stateID;
	}

	public function qtStreetBG(stateID:Int)
	{
		switch (stateID)
		{
			case 1:
				// Change to glitch background
				if (!ClientPrefs.lowQuality)
				{
					streetBGerror.visible = true;
					streetBG.visible = false;
				}
				FlxG.camera.shake(0.0078, 0.675);
			// dadDrainHealth=0.0055; //Reducing health drain because fuck me that's a lot of notes!
			// healthLossMultiplier=1.1375; //More forgiving because fuck me that's a lot of notes!
			// healthGainMultiplier=1.125;
			case 2:
				if (!ClientPrefs.lowQuality)
				{
					qtIsBlueScreened = true;
					streetBG.visible = false;
					streetBGerror.visible = false;
					streetFrontError.visible = true;

					gameHUD.songNameTxt.text = "SYSTEM ERROR";
					gameHUD.timeleftTxt.text = "?:??";
					gameHUD.fucktimer = true;
					gameHUD.songNameTxt.screenCenter(X);
				}
			case 0:
				if (!ClientPrefs.lowQuality)
				{
					qtIsBlueScreened = false;
					streetBG.visible = true;
					streetFrontError.visible = false;

					gameHUD.songNameTxt.text = StringTools.replace(SONG.song, "-", " ");
					gameHUD.timeleftTxt.text = songLengthTxt;
					gameHUD.fucktimer = false;
					gameHUD.songNameTxt.screenCenter(X);
				}
		}
		gameHUD.reloadSongPosBarColors(qtIsBlueScreened);
		gameHUD.reloadHealthBarColors(qtIsBlueScreened);
	}

	function terminateEndEarly():Void
	{
		qt_tv01.animation.play("error");
		disableDefaultCamZooming = true;
		canPause = false;
		inCutscene = true;
		new FlxTimer().start(0.021, function(tmr:FlxTimer) // Slight delay
		{
			dad.stunned = true;
			freezeNotes = true;
			dad.playAnim('singLEFT', true);
			dad.singDuration = 9999;
			cameramove = false;
		});
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String)
	{
		switch (eventName)
		{
			// Hazard Events
			case 'gfScared':
				gfScared = value1.toLowerCase() == "true";
			case 'newLossMultiplier':
				var value:Float = Std.parseFloat(value1);
				if (Math.isNaN(value))
					value = 1;
				healthLossMultiplier = value;
			case 'newHealthGainMultiplier':
				var value:Float = Std.parseFloat(value1);
				if (Math.isNaN(value))
					value = 1;
				healthGainMultiplier = value;
			case 'newDadDrainHealthValue':
				if (value1.toLowerCase() != "skip")
				{
					var value:Float = Std.parseFloat(value1);
					if (Math.isNaN(value))
						value = 0;
					dadDrainHealth = value;
				}
				if (value2.toLowerCase() == "false")
					dadDrainHealthSustain = false;
				else if (value2.toLowerCase() == "true")
					dadDrainHealthSustain = true;

			case 'newDodgeCooldown':
				var value:Float = Std.parseFloat(value1);
				if (Math.isNaN(value))
					value = 0;
				bfDodgeCooldown = value;
			case 'newDodgeDuration':
				var value:Float = Std.parseFloat(value1);
				if (Math.isNaN(value))
					value = 0;
				bfDodgeTiming = value;

			case 'streetTV state':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value))
					value = 0;
				qtStreetTV(value);
			case 'streetBG state':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value))
					value = 0;
				// 0 = normal
				// 1 = glitch
				// 2 = bluescreen
				qtStreetBG(value);
			// trace("BG state =",value);

			case 'Rotating':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value))
					value = 0;
				if (value == 3)
				{
					noteSpeen = 0;
					for (i in 0...playerStrums.length)
					{
						FlxTween.tween(playerStrums.members[i], {angle: 0, x: hazardModChartDefaultStrumX[i + 4], y: hazardModChartDefaultStrumY[i + 4]}, 0.39,
							{ease: FlxEase.quadInOut});
					}
					for (i in 0...opponentStrums.length)
					{
						FlxTween.tween(opponentStrums.members[i], {angle: 0, x: hazardModChartDefaultStrumX[i], y: hazardModChartDefaultStrumY[i]}, 0.39,
							{ease: FlxEase.quadInOut});
					}
				}
				else
				{
					noteSpeen = value;
				}

			case 'Gas Effect':
				switch (value1.toLowerCase().trim())
				{
					case "burst":
						Gas_Release('burst');
					case "burstfast" | "burstfalt":
						Gas_Release('burstALT');
					case "burstfaster":
						Gas_Release('burstFAST');
					case "burstloop":
						Gas_Release('burstLoop');
					default:
						Gas_Release();
				}

			case 'Alarm Gradient':
				if (ClientPrefs.flashing && !ClientPrefs.lowQuality)
				{
					// Value 1  = which side
					// Value 2 = alpha to fade to
					var targetAlpha:Float = Std.parseFloat(value2);
					if (Math.isNaN(targetAlpha))
						targetAlpha = 0;

					if (value1.toLowerCase() == "left")
					{
						// hazardBGashley is gradient flipped
						FlxTween.tween(hazardAlarmLeft, {alpha: targetAlpha}, 0.25, {
							ease: FlxEase.quartOut,
							onComplete: function(twn:FlxTween)
							{
								FlxTween.tween(hazardAlarmLeft, {alpha: 0}, 0.36, {ease: FlxEase.cubeOut});
							}
						});
					}
					else if (value1.toLowerCase() == "right")
					{
						// hazardBGblank is gradient
						FlxTween.tween(hazardAlarmRight, {alpha: targetAlpha}, 0.25, {
							ease: FlxEase.quartOut,
							onComplete: function(twn:FlxTween)
							{
								FlxTween.tween(hazardAlarmRight, {alpha: 0}, 0.36, {ease: FlxEase.cubeOut});
							}
						});
					}
					else
					{
						FlxG.log.warn('Value 1 for alarm has to either be "right" or "left"');
					}
				}

			case 'CessationTroll':
				if (curSong.toLowerCase() == 'cessation')
				{
					var value:Int = Std.parseInt(value1);
					if (Math.isNaN(value))
						value = 0;

					var valueFORCE:Int = Std.parseInt(value2);
					if (Math.isNaN(valueFORCE))
						valueFORCE = 0;

					if ((hazardRandom == 5 || valueFORCE == 1) && !cpuControlled)
					{
						if (value == 0)
						{
							add(kb_attack_alert);
							kbATTACK_ALERT(1);
						}
						else if (value == 1)
							kbATTACK_ALERT(1);
						else if (value == 2)
						{
							FlxG.sound.play(Paths.sound('hazard/bruh'), 0.75);
							add(cessationTroll);
						}
						else if (value == 3)
							remove(cessationTroll);

						cessationTrollDone = true;
					}
				}
				else
				{
					FlxG.log.notice("CessationTroll only works on Cessation!");
				}

			case 'InterlopeEffect' | '??????':
				var modChartEffectShit:Int = Std.parseInt(value1);
				if (Math.isNaN(modChartEffectShit))
					modChartEffectShit = 0;

				hazardModChartEffect = modChartEffectShit;

				var value:Int = Std.parseInt(value2);
				if (Math.isNaN(value))
					value = 0;

				switch (value)
				{
					case 1:
						if (!skippedIntro)
						{
							interlopeFadeinShaderFading = true;
							interlopeIntroTweens.set("introEffect1", FlxTween.tween(playerStrums.members[0], {
								alpha: 1,
								angle: 0,
								x: hazardModChartDefaultStrumX[4],
								y: hazardModChartDefaultStrumY[4]
							}, 6, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									interlopeIntroTweens.remove("introEffect1");
								}
							}));
							// FlxTween.tween(playerStrums.members[0], {alpha: 1, angle: 0, x:hazardModChartDefaultStrumX[4], y:hazardModChartDefaultStrumY[4]}, 6, {ease: FlxEase.quadOut});
						}
					case 2:
						if (!skippedIntro)
						{
							interlopeIntroTweens.set("introEffect2", FlxTween.tween(playerStrums.members[1], {
								alpha: 1,
								angle: 0,
								x: hazardModChartDefaultStrumX[5],
								y: hazardModChartDefaultStrumY[5]
							}, 6, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									interlopeIntroTweens.remove("introEffect2");
								}
							}));
							// FlxTween.tween(playerStrums.members[1], {alpha: 1, angle: 0, x:hazardModChartDefaultStrumX[5], y:hazardModChartDefaultStrumY[5]}, 6, {ease: FlxEase.quadOut});
						}
					case 3:
						if (!skippedIntro)
						{
							interlopeIntroTweens.set("introEffect3", FlxTween.tween(playerStrums.members[2], {
								alpha: 1,
								angle: 0,
								x: hazardModChartDefaultStrumX[6],
								y: hazardModChartDefaultStrumY[6]
							}, 6, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									interlopeIntroTweens.remove("introEffect3");
								}
							}));
							// FlxTween.tween(playerStrums.members[2], {alpha: 1, angle: 0, x:hazardModChartDefaultStrumX[6], y:hazardModChartDefaultStrumY[6]}, 6, {ease: FlxEase.quadOut});
						}
					case 4:
						if (!skippedIntro)
						{
							interlopeIntroTweens.set("introEffect4", FlxTween.tween(playerStrums.members[3], {
								alpha: 1,
								angle: 0,
								x: hazardModChartDefaultStrumX[7],
								y: hazardModChartDefaultStrumY[7]
							}, 6, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									interlopeIntroTweens.remove("introEffect4");
								}
							}));
							// FlxTween.tween(playerStrums.members[3], {alpha: 1, angle: 0, x:hazardModChartDefaultStrumX[7], y:hazardModChartDefaultStrumY[7]}, 6, {ease: FlxEase.quadOut});
						}
					case 5: // First Chuckle
						interlopeFadeinShaderFading = false;
						interlopeFadeinShaderIntensity = 1.2;
						hazardBlack.alpha = 0.75;
						opponentNoteColourChange = true;
						for (i in 0...opponentStrums.length)
						{
							opponentStrums.members[i].x = hazardModChartDefaultStrumX[i];
							opponentStrums.members[i].color = FlxColor.GRAY;
							FlxTween.tween(opponentStrums.members[i], {alpha: 0.325}, 0.55, {ease: FlxEase.linear});
						}

						if (!ClientPrefs.lowQuality)
						{
							hazardInterlopeLaugh.animation.play("laugh1");
							hazardInterlopeLaugh.alpha = 0.3;
							defaultCamZoom += 0.17;
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.6, {ease: FlxEase.quartInOut});
						}
					case 6: // Begin
						interlopeFadeinShaderFading = false;
						interlopeFadeinShaderIntensity = 0;
						hazardBlack.alpha = 0;
						if (!ClientPrefs.lowQuality)
						{
							hazardInterlopeLaugh.alpha = 0;
							defaultCamZoom = dacamera;
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.6, {ease: FlxEase.quartInOut});
						}
					case 7: // drums begin
						hazardModChartVariable1 = 0;
						FlxTween.num(0, 1, 6, {type: ONESHOT}, function(v)
						{
							hazardModChartVariable1 = v;
						});
					case 17: // Begin halfway point
						for (i in 0...opponentStrums.length)
						{
							opponentStrums.members[i].color = FlxColor.GRAY;
							FlxTween.tween(opponentStrums.members[i], {alpha: 0.95, x: playerStrums.members[i].x}, 7, {ease: FlxEase.quadInOut});
						}
					case 18: // Begin halfway point
						for (i in 0...opponentStrums.length)
						{
							FlxTween.tween(opponentStrums.members[i], {alpha: 0, x: hazardModChartDefaultStrumX[i]}, 0.75, {ease: FlxEase.linear});
						}

					case 19: // MMM BASS (right before)
						for (i in 0...playerStrums.length)
						{
							FlxTween.tween(playerStrums.members[i], {x: hazardModChartDefaultStrumX[i + 4]}, 0.77922, {ease: FlxEase.linear});
						}
					case 20: // Bass Chroma distort
						if (interlopeChroma != null) interlopeChromaIntensity = 0.045;

					case 8: // 2nd chuckle
						if (!ClientPrefs.lowQuality)
						{
							hazardInterlopeLaugh.animation.play("laugh1");
							modchartTweens.set("interlopeTaunt", FlxTween.tween(hazardInterlopeLaugh, {alpha: 0.55}, 0.33, {
								ease: FlxEase.linear,
								onComplete: function(twn:FlxTween)
								{
									modchartTweens.remove("interlopeTaunt");
								}
							}));
							defaultCamZoom += 0.17;
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.6, {ease: FlxEase.quartInOut});
						}
					case 9: // main effect start
						hazardBGpulsing = true;
						if (!ClientPrefs.lowQuality)
						{
							hazardInterlopeLaugh.alpha = 0;
							defaultCamZoom = dacamera;
							FlxG.camera.zoom = defaultCamZoom;
						}
					case 10: // laugh
						opponentNoteColourChange = true;
						hazardBGpulsing = false;
						if (!ClientPrefs.lowQuality)
						{
							hazardInterlopeLaugh.x += 175;
							hazardInterlopeLaugh.animation.play("laugh2");
							modchartTweens.set("interlopeTaunt", FlxTween.tween(hazardInterlopeLaugh, {alpha: 0.8}, 0.325, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									modchartTweens.remove("interlopeTaunt");
								}
							}));
							defaultCamZoom += 0.19;
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.4, {ease: FlxEase.elasticOut});
						}
						for (i in 0...opponentStrums.length)
						{
							opponentStrums.members[i].color = FlxColor.GRAY;
							opponentStrums.members[i].x = playerStrums.members[i].x;
							playerStrums.members[i].x = hazardModChartDefaultStrumX[i + 4] + 300;

							// FlxTween.tween(opponentStrums.members[i], {alpha: 0.4}, 0.5, {ease: FlxEase.linear});
							// FlxTween.tween(opponentStrums.members[i], {x: playerStrums.members[i].x-600}, 0.7, {ease: FlxEase.quadOut});

							// This is probably going to break something. I don't care.
							// nah
							modchartTweens.set("interlopeOpponentMove", FlxTween.tween(opponentStrums.members[i], {x: playerStrums.members[i].x - 600}, 0.7, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									modchartTweens.remove("interlopeOpponentMove");
								}
							}));
							modchartTweens.set("interlopeOpponentAlpha", FlxTween.tween(opponentStrums.members[i], {alpha: 0.4}, 0.5, {
								ease: FlxEase.linear,
								onComplete: function(twn:FlxTween)
								{
									modchartTweens.remove("interlopeOpponentAlpha");
								}
							}));
						}
						FlxTween.tween(camHUD, {angle: 0}, 0.5, {ease: FlxEase.expoInOut});

					case 11: // after laugh
						hazardBGpulsing = true;
						if (!ClientPrefs.lowQuality)
						{
							hazardInterlopeLaugh.alpha = 0;
							defaultCamZoom = dacamera;
							FlxG.camera.zoom = defaultCamZoom;
						}
					case 12: // pulse begin
						hazardBGpulsing = true;

					case 13: // finish
						hazardBGpulsing = false;
						FlxTween.tween(playerStrums.members[0], {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(playerStrums.members[1], {alpha: 0}, 1, {ease: FlxEase.linear});
						FlxTween.tween(playerStrums.members[2], {alpha: 0}, 1, {ease: FlxEase.linear});
						modchartTweens.set("interlopeEndingFadeToBlack", FlxTween.tween(hazardBlack, {alpha: 0.5}, 2.7, {
							ease: FlxEase.linear,
							onComplete: function(twn:FlxTween)
							{
								modchartTweens.remove("interlopeEndingFadeToBlack");
							}
						}));
					case 14:
						FlxTween.tween(playerStrums.members[3], {alpha: 0.375}, 1, {ease: FlxEase.linear});
					case 15:
						FlxTween.tween(playerStrums.members[3], {alpha: 0}, 0.375, {ease: FlxEase.linear});

						modchartTweens.set("interlopeEndingFadeToBlack2", FlxTween.tween(hazardBlack, {alpha: 1}, 0.475, {
							ease: FlxEase.linear,
							onComplete: function(twn:FlxTween)
							{
								modchartTweens.remove("interlopeEndingFadeToBlack2");
							}
						}));
					case 16:
						hazardBGpulsing = false;
						for (i in 0...playerStrums.length)
						{
							FlxTween.tween(playerStrums.members[i], {x: hazardModChartDefaultStrumX[i + 4]}, 0.5, {ease: FlxEase.quadInOut});
						}
						for (i in 0...opponentStrums.length)
						{
							FlxTween.tween(opponentStrums.members[i], {alpha: 0}, 0.45, {ease: FlxEase.linear});
						}
						FlxTween.tween(camHUD, {angle: 0}, 0.5, {ease: FlxEase.expoInOut});
				}

			// XD
			case 'TerminateEndEarly':
				terminateEndEarly();

			// Termination shit
			case 'TerminationIntro':
				var value:Int = Std.parseInt(value1);
				var playShit:Bool = false;
				if (value2 == "player")
				{
					playShit = true;
				}
				TerminationIntroShit(value, playShit);
			case 'TerminationOutro':
				var value:Int = Std.parseInt(value1);
				TerminationOutroShit(value);

			case 'KB_Alert':
				var alertType:Int = Std.parseInt(value1);
				if (Math.isNaN(alertType))
				{
					// If value 1 isn't a number, checks if the player wrote it as words instead
					switch (value1)
					{
						case "double":
							alertType = 2;
						case "triple":
							alertType = 3;
						case "quadruple" | "quad":
							alertType = 4;
						default:
							alertType = 1;
					}
				}
				kbATTACK_ALERT(alertType);
			case 'KB_AlertDouble':
				// Kept for legacy support
				kbATTACK_ALERT(2);
			case 'KB_AttackPrepare':
				KBATTACK(false);
				if (value1 != '0')
					kbATTACK_ALERT();

			case 'KB_AttackFire':
				// For playing different sounds:
				var soundToPlay:String = value1.toLowerCase();
				if (soundToPlay == null || soundToPlay == " " || soundToPlay == "" || soundToPlay == "single" || soundToPlay == "1")
					soundToPlay = "hazard/attack";
				else
				{
					soundToPlay = "hazard/attack-" + soundToPlay;
					trace("sawblade sound file: ", ("hazard/attack-" + soundToPlay));
				}

				// Checking if it should be an insta-kill sawblade.

				KBATTACK(true, soundToPlay, (value2 == '1' || value2 == 'instakill'));

			case 'KB_AttackFireDOUBLE':
				// Kept for legacy support
				if (value1 == '1')
					KBATTACK(false);
				else
					KBATTACK(true, "hazard/attack-double", (value2 == '1' || value2 == 'instakill'));

			case 'KB_Pincer':
				switch (Std.parseInt(value1))
				{
					// An awful way to convert the modchart shit from lua, but fuck you.
					// first pincer move

					case 0:
						KBPINCER_PREPARE(3, false);
					case 1:
						KBPINCER_GRAB(3);

						if (ClientPrefs.downScroll)
						{
							FlxTween.tween(playerStrums.members[2], {y: hazardModChartDefaultStrumY[6] - 70}, 0.25, {ease: FlxEase.quadOut});
							FlxTween.tween(pincer3, {y: hazardModChartDefaultStrumY[6] - 70}, 0.25, {ease: FlxEase.quadOut});
						}
						else
						{
							FlxTween.tween(playerStrums.members[2], {y: hazardModChartDefaultStrumY[6] + 70}, 0.25, {ease: FlxEase.quadOut});
							FlxTween.tween(pincer3, {y: hazardModChartDefaultStrumY[6] + 70}, 0.25, {ease: FlxEase.quadOut});
						}

					case 2:
						KBPINCER_PREPARE(3, true);

					// 2nd pincer move
					case 3:
						KBPINCER_PREPARE(3, false);
						KBPINCER_PREPARE(1, false);
					case 4:
						KBPINCER_GRAB(1);
						KBPINCER_GRAB(3);
						FlxTween.tween(playerStrums.members[2], {y: hazardModChartDefaultStrumY[6]}, 0.3, {ease: FlxEase.quadOut});
						FlxTween.tween(pincer3, {y: hazardModChartDefaultStrumY[6]}, 0.3, {ease: FlxEase.quadOut});
						if (ClientPrefs.downScroll)
						{
							FlxTween.tween(playerStrums.members[0], {x: hazardModChartDefaultStrumX[4] - 25, y: hazardModChartDefaultStrumY[4] - 62}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(pincer1, {x: hazardModChartDefaultStrumX[4] - 25, y: hazardModChartDefaultStrumY[4] - 62}, 0.25,
								{ease: FlxEase.quadOut});
						}
						else
						{
							FlxTween.tween(playerStrums.members[0], {x: hazardModChartDefaultStrumX[4] - 25, y: hazardModChartDefaultStrumY[4] + 62}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(pincer1, {x: hazardModChartDefaultStrumX[4] - 25, y: hazardModChartDefaultStrumY[4] + 62}, 0.25,
								{ease: FlxEase.quadOut});
						}
					case 5:
						KBPINCER_PREPARE(3, true);
						KBPINCER_PREPARE(1, true);

					// 3rd pincer move
					case 6:
						KBPINCER_PREPARE(1, false);
						KBPINCER_PREPARE(2, false);
						KBPINCER_PREPARE(4, false);
					case 7:
						KBPINCER_GRAB(1);
						KBPINCER_GRAB(2);
						KBPINCER_GRAB(4);
						FlxTween.tween(playerStrums.members[0], {x: hazardModChartDefaultStrumX[4], y: hazardModChartDefaultStrumY[4]}, 0.3,
							{ease: FlxEase.quadOut});
						FlxTween.tween(pincer1, {x: hazardModChartDefaultStrumX[4], y: hazardModChartDefaultStrumY[4]}, 0.3, {ease: FlxEase.quadOut});
						if (ClientPrefs.downScroll)
						{
							FlxTween.tween(playerStrums.members[3], {x: hazardModChartDefaultStrumX[7] + 50, y: hazardModChartDefaultStrumY[7] - 40}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(pincer4, {x: hazardModChartDefaultStrumX[7] + 50, y: hazardModChartDefaultStrumY[7] - 40}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(playerStrums.members[1], {x: hazardModChartDefaultStrumX[5] + 11, y: hazardModChartDefaultStrumY[5] - 70}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(pincer2, {x: hazardModChartDefaultStrumX[5] + 11, y: hazardModChartDefaultStrumY[5] - 70}, 0.25,
								{ease: FlxEase.quadOut});
						}
						else
						{
							FlxTween.tween(playerStrums.members[3], {x: hazardModChartDefaultStrumX[7] + 50, y: hazardModChartDefaultStrumY[7] + 40}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(pincer4, {x: hazardModChartDefaultStrumX[7] + 50, y: hazardModChartDefaultStrumY[7] + 40}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(playerStrums.members[1], {x: hazardModChartDefaultStrumX[5] + 11, y: hazardModChartDefaultStrumY[5] + 70}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(pincer2, {x: hazardModChartDefaultStrumX[5] + 11, y: hazardModChartDefaultStrumY[5] + 70}, 0.25,
								{ease: FlxEase.quadOut});
						}
					case 8:
						KBPINCER_PREPARE(4, true);
						KBPINCER_PREPARE(2, true);
						KBPINCER_PREPARE(1, true);

					// 4th pincer move
					case 9:
						KBPINCER_PREPARE(1, false);
						KBPINCER_PREPARE(2, false);
						KBPINCER_PREPARE(3, false);
						KBPINCER_PREPARE(4, false);
					case 10:
						KBPINCER_GRAB(1);
						KBPINCER_GRAB(2);
						KBPINCER_GRAB(3);
						KBPINCER_GRAB(4);
						if (ClientPrefs.downScroll)
						{
							FlxTween.tween(playerStrums.members[0], {x: hazardModChartDefaultStrumX[4] - 16, y: hazardModChartDefaultStrumY[4] - 32}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(pincer1, {x: hazardModChartDefaultStrumX[4] - 16, y: hazardModChartDefaultStrumY[4] - 32}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(playerStrums.members[1], {x: hazardModChartDefaultStrumX[5], y: hazardModChartDefaultStrumY[5] + 11}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(pincer2, {x: hazardModChartDefaultStrumX[5], y: hazardModChartDefaultStrumY[5] + 11}, 0.25, {ease: FlxEase.quadOut});
							FlxTween.tween(playerStrums.members[3], {x: hazardModChartDefaultStrumX[7] + 16, y: hazardModChartDefaultStrumY[7] - 32}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(pincer4, {x: hazardModChartDefaultStrumX[7] + 16, y: hazardModChartDefaultStrumY[7] - 32}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(playerStrums.members[2], {x: hazardModChartDefaultStrumX[6], y: hazardModChartDefaultStrumY[6] + 11}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(pincer3, {x: hazardModChartDefaultStrumX[6], y: hazardModChartDefaultStrumY[6] + 11}, 0.25, {ease: FlxEase.quadOut});
							FlxTween.tween(playerStrums.members[3], {angle: -40}, 0.25, {ease: FlxEase.linear});
							FlxTween.tween(playerStrums.members[0], {angle: 40}, 0.25, {ease: FlxEase.linear});
						}
						else
						{
							FlxTween.tween(playerStrums.members[0], {x: hazardModChartDefaultStrumX[4] - 16, y: hazardModChartDefaultStrumY[4] + 32}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(pincer1, {x: hazardModChartDefaultStrumX[4] - 16, y: hazardModChartDefaultStrumY[4] + 32}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(playerStrums.members[1], {x: hazardModChartDefaultStrumX[5], y: hazardModChartDefaultStrumY[5] - 11}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(pincer2, {x: hazardModChartDefaultStrumX[5], y: hazardModChartDefaultStrumY[5] - 11}, 0.25, {ease: FlxEase.quadOut});
							FlxTween.tween(playerStrums.members[3], {x: hazardModChartDefaultStrumX[7] + 16, y: hazardModChartDefaultStrumY[7] + 32}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(pincer4, {x: hazardModChartDefaultStrumX[7] + 16, y: hazardModChartDefaultStrumY[7] + 32}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(playerStrums.members[2], {x: hazardModChartDefaultStrumX[6], y: hazardModChartDefaultStrumY[6] - 11}, 0.25,
								{ease: FlxEase.quadOut});
							FlxTween.tween(pincer3, {x: hazardModChartDefaultStrumX[6], y: hazardModChartDefaultStrumY[6] - 11}, 0.25, {ease: FlxEase.quadOut});
							FlxTween.tween(playerStrums.members[3], {angle: 40}, 0.25, {ease: FlxEase.linear});
							FlxTween.tween(playerStrums.members[0], {angle: -40}, 0.25, {ease: FlxEase.linear});
						}
					case 11:
						KBPINCER_PREPARE(1, true);
						KBPINCER_PREPARE(2, true);
						KBPINCER_PREPARE(3, true);
						KBPINCER_PREPARE(4, true);

					// Long section
					case 12:
						KBPINCER_PREPARE(4, false);
						KBPINCER_PREPARE(1, false);
					case 13:
						KBPINCER_GRAB(1);
						KBPINCER_GRAB(4);
						FlxTween.tween(playerStrums.members[0], {x: hazardModChartDefaultStrumX[4], y: hazardModChartDefaultStrumY[4] + 75}, 0.75,
							{ease: FlxEase.quadInOut});
						FlxTween.tween(pincer1, {x: hazardModChartDefaultStrumX[4], y: hazardModChartDefaultStrumY[4] + 75}, 0.75, {ease: FlxEase.quadInOut});
						FlxTween.tween(playerStrums.members[3], {x: hazardModChartDefaultStrumX[7], y: hazardModChartDefaultStrumY[7] - 75}, 0.75,
							{ease: FlxEase.quadInOut});
						FlxTween.tween(pincer4, {x: hazardModChartDefaultStrumX[7], y: hazardModChartDefaultStrumY[7] - 75}, 0.75, {ease: FlxEase.quadInOut});
					case 14:
						FlxTween.tween(playerStrums.members[0], {x: hazardModChartDefaultStrumX[7]}, 0.9, {ease: FlxEase.quadInOut});
						FlxTween.tween(pincer1, {x: hazardModChartDefaultStrumX[7]}, 0.9, {ease: FlxEase.quadInOut});
						FlxTween.tween(playerStrums.members[3], {x: hazardModChartDefaultStrumX[4]}, 0.9, {ease: FlxEase.quadInOut});
						FlxTween.tween(pincer4, {x: hazardModChartDefaultStrumX[4]}, 0.9, {ease: FlxEase.quadInOut});
					case 15:
						FlxTween.tween(playerStrums.members[0], {x: hazardModChartDefaultStrumX[7], y: hazardModChartDefaultStrumY[7]}, 0.75,
							{ease: FlxEase.quadInOut});
						FlxTween.tween(pincer1, {x: hazardModChartDefaultStrumX[7], y: hazardModChartDefaultStrumY[7]}, 0.75, {ease: FlxEase.quadInOut});
						FlxTween.tween(playerStrums.members[3], {x: hazardModChartDefaultStrumX[4], y: hazardModChartDefaultStrumY[4]}, 0.75,
							{ease: FlxEase.quadInOut});
						FlxTween.tween(pincer4, {x: hazardModChartDefaultStrumX[4], y: hazardModChartDefaultStrumY[4]}, 0.75, {ease: FlxEase.quadInOut});

						FlxTween.tween(playerStrums.members[3], {angle: 0}, 0.725, {ease: FlxEase.quadOut});
						FlxTween.tween(playerStrums.members[0], {angle: 0}, 0.725, {ease: FlxEase.quadOut});
					case 16:
						KBPINCER_PREPARE(4, true);
						KBPINCER_PREPARE(1, true);
						KBPINCER_PREPARE(3, false);
						KBPINCER_PREPARE(2, false);
					case 17:
						KBPINCER_GRAB(2);
						KBPINCER_GRAB(3);
						FlxTween.tween(playerStrums.members[2], {x: hazardModChartDefaultStrumX[6], y: hazardModChartDefaultStrumY[6] + 75}, 0.75,
							{ease: FlxEase.quadInOut});
						FlxTween.tween(pincer3, {x: hazardModChartDefaultStrumX[6], y: hazardModChartDefaultStrumY[6] + 75}, 0.75, {ease: FlxEase.quadInOut});
						FlxTween.tween(playerStrums.members[1], {x: hazardModChartDefaultStrumX[5], y: hazardModChartDefaultStrumY[5] - 75}, 0.75,
							{ease: FlxEase.quadInOut});
						FlxTween.tween(pincer2, {x: hazardModChartDefaultStrumX[5], y: hazardModChartDefaultStrumY[5] - 75}, 0.75, {ease: FlxEase.quadInOut});
					case 18:
						FlxTween.tween(playerStrums.members[2], {x: hazardModChartDefaultStrumX[5]}, 0.9, {ease: FlxEase.quadInOut});
						FlxTween.tween(pincer3, {x: hazardModChartDefaultStrumX[5]}, 0.9, {ease: FlxEase.quadInOut});
						FlxTween.tween(playerStrums.members[1], {x: hazardModChartDefaultStrumX[6]}, 0.9, {ease: FlxEase.quadInOut});
						FlxTween.tween(pincer2, {x: hazardModChartDefaultStrumX[6]}, 0.9, {ease: FlxEase.quadInOut});
					case 19:
						FlxTween.tween(playerStrums.members[2], {x: hazardModChartDefaultStrumX[5], y: hazardModChartDefaultStrumY[5]}, 0.75,
							{ease: FlxEase.quadInOut});
						FlxTween.tween(pincer3, {x: hazardModChartDefaultStrumX[5], y: hazardModChartDefaultStrumY[5]}, 0.75, {ease: FlxEase.quadInOut});
						FlxTween.tween(playerStrums.members[1], {x: hazardModChartDefaultStrumX[6], y: hazardModChartDefaultStrumY[6]}, 0.75,
							{ease: FlxEase.quadInOut});
						FlxTween.tween(pincer2, {x: hazardModChartDefaultStrumX[6], y: hazardModChartDefaultStrumY[6]}, 0.75, {ease: FlxEase.quadInOut});
					case 20:
						KBPINCER_PREPARE(3, true);
						KBPINCER_PREPARE(2, true);
					case 21:
						for (i in 0...playerStrums.length)
						{
							FlxTween.tween(playerStrums.members[i], {angle: 0, x: hazardModChartDefaultStrumX[i + 4], y: hazardModChartDefaultStrumY[i + 4]},
								1.375, {ease: FlxEase.quadInOut});
						}
					case 22: // Prepare screenshake
						KBPINCER_PREPARE(5, false);
						if (forceMiddleScroll) KBPINCER_PREPARE(6, false); else KBPINCER_PREPARE(4, false);
					case 23: // SHAKEY SHAKEY
						KBPINCER_GRAB(1);
						if (forceMiddleScroll)
							KBPINCER_GRAB(2);
						else
							KBPINCER_GRAB(4);
						hazardModChartEffect = 2;
					case 24: // Screenshake end
						KBPINCER_PREPARE(5, true);
						if (forceMiddleScroll)
							KBPINCER_PREPARE(6, true);
						else
							KBPINCER_PREPARE(4, true);
						hazardModChartEffect = 0;
						camHUD.angle = 0;
				}

			case 'ShaderTesting':
				switch (value1.toLowerCase())
				{
					case "clear":
						clearShaderFromCamera(value2);
						clearShaderFromCamera(value2);
						clearShaderFromCamera(value2);

					case "bloom":
						addShaderToCamera(value2, new BloomEffect(1.0 / 512.0, 0.35));

					case "chroma":
						addShaderToCamera(value2, new ChromaticAberrationEffect(0.005));

					case "scanline":
						addShaderToCamera(value2, new ScanlineEffect(false));

					case "grain":
						addShaderToCamera(value2, new GrainEffect(0.1, 0.3, false));

					case "glitch":
						addShaderToCamera(value2, new GlitchEffect(0.1, 0.1, 0.1));

					case "vcr":
						addShaderToCamera(value2, new VCRDistortionEffect(0.05, true, true, true));

					case "3d":
						addShaderToCamera(value2, new ThreeDEffect(0.3, 0.15, 0, 0.2));
				}

			// Luis events

			case 'set vignette':
				if (!ClientPrefs.lowQuality)
				{
					// Value 1  = what time
					// Value 2 = alpha or pre deffinition of
					var time:Float = Std.parseFloat(value1);
					var targetAlpha:Float = Std.parseFloat(value2);
					if (Math.isNaN(time))
						time = 0.5;
					if (Math.isNaN(targetAlpha))
						targetAlpha = 0;

					switch (value2.toLowerCase().trim())
					{
						case 'bump': FlxTween.tween(luisOverlayShit, {alpha: 0.5}, time, {
								ease: FlxEase.quartOut,
								onComplete: function(twn:FlxTween)
								{
									FlxTween.tween(luisOverlayShit, {alpha: 0}, time, {ease: FlxEase.cubeOut});
								}
							});
						case 'camerabump':
							FlxTween.tween(luisOverlayShit, {alpha: 0.5}, 0.2, {
								ease: FlxEase.quartOut,
								onComplete: function(twn:FlxTween)
								{
									FlxTween.tween(luisOverlayShit, {alpha: 0}, time - 0.2, {ease: FlxEase.cubeOut});
								}
							});
						default:
							FlxTween.tween(luisOverlayShit, {alpha: targetAlpha}, time, {ease: FlxEase.cubeOut});
					}
				}

			case 'set camzoom':
				// Value 1  = what time
				// Value 2 = what zoom
				var time:Float = Std.parseFloat(value1);
				var zoom:Float = Std.parseFloat(value2);

				if (Math.isNaN(time) || time <= 0)
					time = 0.6;

				defaultCamZoom = zoom;
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, time);
				trace("zoom ", zoom + " time ", time);

			case 'censory overload events': // from original qt fixes
				var shit:Float = Std.parseFloat(value1);
				switch (shit)
				{
					case 1:
						if (!ClientPrefs.lowQuality)
							FlxTween.tween(luisOverlayShit, {alpha: 1}, 1.5, {
								ease: FlxEase.quadInOut
							});
						defaultCamZoom += 1;
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 1.5);
					case 2:
						if (!ClientPrefs.lowQuality)
							FlxTween.tween(luisOverlayShit, {alpha: 0.2}, 0.9, {
								ease: FlxEase.quadInOut
							});
						defaultCamZoom = dacamera;
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.9);
					case 3:
						if (!ClientPrefs.lowQuality)
							FlxTween.tween(luisOverlayShit, {alpha: 0.5}, 0.5, {
								ease: FlxEase.quadInOut
							});
						defaultCamZoom -= 0.09;
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
					case 4:
						defaultCamZoom = dacamera;
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.2);
					case 5:
						if (!ClientPrefs.lowQuality) FlxTween.tween(luisOverlayShit, {alpha: 0}, 0.5, {
							ease: FlxEase.quadInOut
						});
					case 6:
						defaultCamZoom += 0.5;
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 4.8);
					case 7:
						defaultCamZoom = dacamera;
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.2);
					case 8:
						if (!ClientPrefs.lowQuality) FlxTween.tween(luisOverlayShit, {alpha: 0.5}, 1, {
							ease: FlxEase.quadInOut
						});
					case 9:
						if (!ClientPrefs.lowQuality) FlxTween.tween(luisOverlayShit, {alpha: 1}, 0.2, {
							ease: FlxEase.quadInOut
						});
					case 10:
						if (!ClientPrefs.lowQuality) FlxTween.tween(luisOverlayShit, {alpha: 0.1}, 0.4, {
							ease: FlxEase.quadInOut
						});
					case 11:
						defaultCamZoom -= 0.09;
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.2);
					case 12:
						if (!ClientPrefs.lowQuality)
							FlxTween.tween(luisOverlayShit, {alpha: 0.7}, 0.4, {
								ease: FlxEase.quadInOut
							});
						defaultCamZoom = dacamera;
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.4);
					case 13:
						if (!ClientPrefs.lowQuality) FlxTween.tween(luisOverlayShit, {alpha: 0.1}, 0.4, {
							ease: FlxEase.quadInOut
						});
					case 14:
						if (!ClientPrefs.lowQuality) FlxTween.tween(luisOverlayShit, {alpha: 0.5}, 0.3, {
							ease: FlxEase.quadInOut
						});
					case 15:
						if (!ClientPrefs.lowQuality) FlxTween.tween(luisOverlayShit, {alpha: 0.2}, 0.3, {
							ease: FlxEase.quadInOut
						});
				}

			case 'censory final events':
				var shit:Float = Std.parseFloat(value1);

				switch (shit)
				{
					case 1:
						FlxTween.tween(strumLineNotes.members[0], {alpha: 0}, 0.2, {ease: FlxEase.sineInOut});
						FlxTween.tween(strumLineNotes.members[4], {alpha: 0}, 0.2, {ease: FlxEase.sineInOut});
						FlxTween.tween(gameHUD.scoreTxt, {alpha: 0}, 0.2, {ease: FlxEase.sineInOut});
					case 2:
						FlxTween.tween(strumLineNotes.members[1], {alpha: 0}, 0.2, {ease: FlxEase.sineInOut});
						FlxTween.tween(strumLineNotes.members[5], {alpha: 0}, 0.2, {ease: FlxEase.sineInOut});
						FlxTween.tween(gameHUD.iconP1, {alpha: 0}, 0.2, {ease: FlxEase.sineInOut});
						FlxTween.tween(gameHUD.iconP2, {alpha: 0}, 0.2, {ease: FlxEase.sineInOut});
					case 3:
						FlxTween.tween(strumLineNotes.members[2], {alpha: 0}, 0.2, {ease: FlxEase.sineInOut});
						FlxTween.tween(strumLineNotes.members[6], {alpha: 0}, 0.2, {ease: FlxEase.sineInOut});
						FlxTween.tween(gameHUD.healthBar, {alpha: 0}, 0.2, {ease: FlxEase.sineInOut});
					case 4:
						FlxTween.tween(strumLineNotes.members[3], {alpha: 0}, 0.2, {ease: FlxEase.sineInOut});
						FlxTween.tween(strumLineNotes.members[7], {alpha: 0}, 0.2, {ease: FlxEase.sineInOut});
				}

			case 'reset notes pos':
				var time:Float = Std.parseFloat(value1);

				if (Math.isNaN(time) || time <= 0)
					time = 0.6;

				fancyModchartStrumX = [0, 0];
				fancyModchartStrumY = [0, 0];

				for (i in 0...strumLineNotes.length)
					FlxTween.tween(strumLineNotes.members[i], {x: hazardModChartDefaultStrumX[i], y: hazardModChartDefaultStrumY[i]}, time,
						{ease: FlxEase.quadInOut});

			case 'notes modchart opponent':
				var susX:Float = Std.parseFloat(value1);
				var susY:Float = Std.parseFloat(value2);

				if (Math.isNaN(susX) || susX == 0 || value1 == '')
					susX = 0;

				if (Math.isNaN(susY) || susY == 0 || value2 == '')
					susY = 0;

				fancyModchartStrumX[0] = susX;
				fancyModchartStrumY[0] = susY;

			case 'notes modchart player':
				var susX:Float = Std.parseFloat(value1);
				var susY:Float = Std.parseFloat(value2);

				/*for (sus in [susX, susY])
				if (Math.isNaN(sus) || sus == 0)
					sus = 0; */ // for some reason when you doenst put anything on any value will return null or whaterer

				if (Math.isNaN(susX) || susX == 0 || value1 == '')
					susX = 0;

				if (Math.isNaN(susY) || susY == 0 || value2 == '')
					susY = 0;

				fancyModchartStrumX[1] = susX;
				fancyModchartStrumY[1] = susY;

			case 'censory Chroma':
				if (censoryChroma != null && !ClientPrefs.noShaders && !ClientPrefs.lowQuality && ClientPrefs.flashing)
				{
					var force:Float = Std.parseFloat(value1);

					if (Math.isNaN(force) || force <= 0)
						force = 0.018;

					censoryChromaIntensity = force;
					// remember 0.018
					// trace("force " + force);
				}

			case 'blue screen shader':
				if (blueshader != null && !ClientPrefs.noShaders)
					blueshader.shader.enabled.value = value1.toLowerCase().trim() == 'true' ? [true] : [false];

			// back to psych engine events

			case 'Hey!':
				var value:Int = 2;
				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0)
					time = 0.6;

				if (value != 0)
				{
					if (dad.curCharacter.startsWith('gf'))
					{ // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					}
					else
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				if (value != 1 && !boyfriend.stunned && !bfDodging)
				{ // Boyfriend dodge/stun take priority.
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value))
					value = 1;
				gfSpeed = value;

			case 'Add Camera Zoom':
				if (!disableDefaultCamZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom))
						camZoom = 0.015;
					if (Math.isNaN(hudZoom))
						hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Play Animation':
				trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if (Math.isNaN(val2))
							val2 = 0;

						switch (val2)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				char.playAnim(value1, true);
				char.specialAnim = true;

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 0;
				if (Math.isNaN(val2))
					val2 = 0;

				isCameraOnForcedPos = false;
				if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
				{
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch (value1.toLowerCase())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val))
							val = 0;

						switch (val)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				char.idleSuffix = value2;
				char.recalculateDanceIdle();

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null)
						duration = Std.parseFloat(split[0].trim());
					if (split[1] != null)
						intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration))
						duration = 0;
					if (Math.isNaN(intensity))
						intensity = 0;

					if (duration > 0 && intensity != 0)
						targetsArray[i].shake(intensity, duration);
				}

			// V2.1, made it so the the change character event is completely skipped when in low quality. Kept the original event if somebody had a song where the character change is actually important.
			case 'Change Character OPTIONAL':
				if (!ClientPrefs.lowQuality)
					changeCharacter(value1, value2);

			case 'Change Character':
				changeCharacter(value1, value2);

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 1;
				if (Math.isNaN(val2))
					val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if (val2 <= 0)
					songSpeed = newValue;
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection(?id:Int = 0):Void
	{
		if (SONG.notes[id] == null)
			return;

		if (SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0];
			camFollow.y += gf.cameraPosition[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;

	public function moveCamera(isDad:Bool)
	{
		if (isDad || forcecameratoplayer2)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0];
			camFollow.y += dad.cameraPosition[1];
			if ((cameramove && dad.curCharacter.startsWith("kb")) || forcecameramove)
			{
				camFollow.y += camY;

				camFollow.x += camX;
			}

			camFollow.x += kbsawbladecamXdad;

			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0];
			camFollow.y += boyfriend.cameraPosition[1];

			tweenCamOut();
		}
	}

	function tweenCamIn()
	{
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3)
		{
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween)
				{
					cameraTwn = null;
				}
			});
		}
	}

	function tweenCamOut()
	{
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
		{
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween)
				{
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float)
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function startEndingDialogue()
	{
		if ((isStoryMode || SONG.song.toLowerCase() == "cessation") && !endingCutsceneDone)
		{
			var file:String = Paths.json(Paths.formatToSongPath(SONG.song) + '/dialogueEND'); // Checks for json/Psych Engine dialogue

			// Terminate harder difficulty dialogue lmao
			if (SONG.song.toLowerCase() == "terminate" && storyDifficulty == 3)
			{
				file = Paths.json(Paths.formatToSongPath(SONG.song) + '/dialogueEND-alt');
				if (OpenFlAssets.exists(file))
				{
					canPause = false;
					inCutscene = true;
					disableDefaultCamZooming = true;
					endingCutsceneDone = true;
					dialogueJson = DialogueBoxPsych.parseDialogue(file);
					startDialogue(dialogueJson);
				}
				else
					file = Paths.json(Paths.formatToSongPath(SONG.song) + '/dialogueEND'); // Defaults back to normal end dialogue if couldn't find -alt
			}

			if (OpenFlAssets.exists(file))
			{
				canPause = false;
				inCutscene = true;
				disableDefaultCamZooming = true;
				endingCutsceneDone = true;
				dialogueJson = DialogueBoxPsych.parseDialogue(file);
				startDialogue(dialogueJson);
			}
			else
				endSong(); // trace("endSong triggerd from start ending dialogue");
		}
		else
			endSong(); // trace("endSong triggerd from ending dialogue FAIL");
	}

	function finishSong():Void
	{
		if (!endingSong)
		{ // Done to ensure this only triggers once.
			var finishCallback:Void->Void = startEndingDialogue;

			gameHUD.updateTime = false;
			FlxG.sound.music.volume = 0;
			vocals.volume = 0;
			vocals.pause();
			endingSong = true; // So that the dialogue knows what to do after the dialogue is over.

			if (ClientPrefs.noteOffset <= 0)
				finishCallback();
			else
			{
				finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer)
				{
					finishCallback();
				});
			}
		}
	}

	function endScreenHazard():Void // For displaying the "thank you for playing" screen on Cessation
	{
		var black:FlxSprite = new FlxSprite(-300, -100).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
		black.scrollFactor.set();

		var screen:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('hazard/qt-port/FinalScreen'));
		screen.setGraphicSize(Std.int(screen.width * 0.625));
		screen.antialiasing = ClientPrefs.globalAntialiasing;
		screen.scrollFactor.set();
		screen.screenCenter();

		var hasTriggeredAlready:Bool = false;

		screen.alpha = 0;
		black.alpha = 0;

		add(black);
		add(screen);

		FlxTween.tween(camHUD, {alpha: 0}, 1, {ease: FlxEase.linear});

		// Fade in code stolen from schoolIntro() >:3
		new FlxTimer().start(0.15, function(swagTimer:FlxTimer)
		{
			black.alpha += 0.075;
			if (black.alpha < 1)
			{
				swagTimer.reset();
			}
			else
			{
				screen.alpha += 0.075;
				if (screen.alpha < 1)
					swagTimer.reset();

				canSkipEndScreen = true;
				// Wait 12 seconds, then do shit -Haz
				new FlxTimer().start(12, function(tmr:FlxTimer)
				{
					if (!hasTriggeredAlready)
					{
						hasTriggeredAlready = true;
						endSong();
					}
				});
			}
		});
	}

	public var transitioning = false;

	public function endSong():Void
	{
		// Should kill you if you tried to cheat
		// Added a check to make sure this is executed for terminate because of how fucked the notes get -Haz
		if (!startingSong && Paths.formatToSongPath(SONG.song) != 'terminate')
		{
			notes.forEach(function(daNote:Note)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss * healthLossMultiplier;
				}
			});
			for (daNote in unspawnNotes)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss * healthLossMultiplier;
				}
			}

			if (doDeathCheck())
				return;
		}

		gameHUD.timeBarBG.visible = false;
		gameHUD.timeBar.visible = false;
		gameHUD.songNameTxt.visible = false;
		gameHUD.timeleftTxt.visible = false;
		gameHUD.timesongTxt.visible = false;
		canPause = false;
		endingSong = true;
		disableDefaultCamZooming = true;
		inCutscene = false;
		gameHUD.updateTime = false;
		THISISFUCKINGDISGUSTINGPLEASESAVEME = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if (achievementObj != null)
		{
			return;
		}
		else
		{
			var achieve:String = checkForAchievement();

			if (achieve != null)
			{
				startAchievement(achieve);
				return;
			}
		}
		#end

		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if (ret != FunkinLua.Function_Stop && !transitioning)
		{
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if (Math.isNaN(percent))
					percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('qtMenu'));

					cancelMusicFadeTween();
					if (FlxTransitionableState.skipNextTransIn)
					{
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if (!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false))
					{
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelMusicFadeTween();
				if (FlxTransitionableState.skipNextTransIn)
				{
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				if (Paths.formatToSongPath(SONG.song) == 'cessation')
				{
					trace("Play Cessation end music.");
					FlxG.sound.playMusic(Paths.music('thanks'));
				}
				else
				{
					FlxG.sound.playMusic(Paths.music('qtMenu'));
				}
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;

	function startAchievement(achieve:String)
	{
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}

	function achievementEnd():Void
	{
		achievementObj = null;
		if (endingSong && !inCutscene)
		{
			endSong();
			// trace("endSong triggerd from achievement end");
		}
	}
	#end

	public function KillNotes()
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		// trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		// tryna do MS based judgment due to popular demand
		var daRating:String = Conductor.judgeNote(note, noteDiff);

		switch (daRating)
		{
			case "shit": // shit
				totalNotesHit += 0;
				score = 50;
				shits++;
			case "bad": // bad
				totalNotesHit += 0.5;
				score = 100;
				bads++;
			case "good": // good
				totalNotesHit += 0.75;
				score = 200;
				goods++;
			case "sick": // sick
				totalNotesHit += 1;
				sicks++;
		}

		if (daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note, true, boyfriend.splashSkinFile);

			// Makes KB's strums move back a bit to show his power... or something idfk it looks cool okay? -Haz
			// Ported for BF. I don't know but it feels pretty buggy ngl
			/*if (boyfriend.curCharacter.startsWith('kb') && !note.isSustainNote)
			{
				// trace("KB shit");
				playerStrums.members[note.noteData].y = hazardModChartDefaultStrumY[note.noteData + 4] + (ClientPrefs.downScroll ? 22 : -22);
				FlxTween.tween(playerStrums.members[note.noteData], {y: hazardModChartDefaultStrumY[note.noteData + 4]}, 0.126, {ease: FlxEase.cubeOut});
		}*/
			// commented because it is buggy, i will try to fix that beause its very cool
		}

		if (!practiceMode && !cpuControlled)
		{
			songScore += score;
			songHits++;
			totalPlayed++;
			RecalculateRating();

			if (ClientPrefs.scoreZoom)
			{
				if (gameHUD.scoreTxtTween != null)
				{
					gameHUD.scoreTxtTween.cancel();
				}
				gameHUD.scoreTxt.scale.x = 1.075;
				gameHUD.scoreTxt.scale.y = 1.075;
				gameHUD.scoreTxtTween = FlxTween.tween(gameHUD.scoreTxt.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween)
					{
						gameHUD.scoreTxtTween = null;
					}
				});
			}
		}

		/* if (combo > 60)
			daRating = 'sick';
		else if (combo > 12)
			daRating = 'good'
		else if (combo > 4)
			daRating = 'bad';
	 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = !ClientPrefs.hideHud;
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = !ClientPrefs.hideHud;
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		insert(members.indexOf(strumLineNotes), rating);

		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.antialiasing = ClientPrefs.globalAntialiasing;
		comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		comboSpr.antialiasing = ClientPrefs.globalAntialiasing;

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if (combo >= 1000)
		{
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			numScore.antialiasing = ClientPrefs.globalAntialiasing;
			numScore.setGraphicSize(Std.int(numScore.width * 0.5));

			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			// if (combo >= 10 || combo == 0)
			insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
		trace(combo);
		trace(seperatedScore);
	 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		// trace('Pressed: ' + eventKey);

		if (!cpuControlled && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if (!boyfriend.stunned && generatedMusic && !endingSong)
			{
				// more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				// var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if (daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
							// notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				if (sortedNotesList.length > 0)
				{
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes)
						{
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
							{
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							}
							else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped)
						{
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}
					}
				}
				else if (canMiss)
				{
					noteMissPress(key);
					callOnLuas('noteMissPress', [key]);
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if (spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			if (controlsPlayer2)
			{
				var spr:StrumNote = opponentStrums.members[key];
				if (spr != null)
				{
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}
			}
			callOnLuas('onKeyPress', [key]);
		}
		// trace('pressed: ' + controlArray);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if (!cpuControlled && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			if (controlsPlayer2)
			{
				var spr:StrumNote = opponentStrums.members[key];
				if (spr != null)
				{
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			}
			callOnLuas('onKeyRelease', [key]);
		}
		// trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Oh come on, really? You're not even going to change the dodge code?!
	// Dodge code, yes it's bad but oh well. -Haz
	// var dodgeButton = controls.ACCEPT; //I have no idea how to add custom controls so fuck it. -Haz
	function bfDodge():Void
	{
		// trace('DODGE START!');
		bfDodging = true;
		bfCanDodge = false;

		// if(qtIsBlueScreened)
		// boyfriend404.playAnim('dodge');
		// else
		boyfriend.playAnim('dodge');

		FlxG.sound.play(Paths.sound('hazard/dodge01'));

		// Wait, then set bfDodging back to false. -Haz
		// V1.2 - Timer lasts a bit longer (by 0.00225)
		new FlxTimer().start(bfDodgeTiming, function(tmr:FlxTimer) // COMMENT THIS IF YOU WANT TO USE DOUBLE SAW VARIATIONS!
		{
			bfDodging = false;
			boyfriend.dance(); // V1.3 = This forces the animation to end when you are no longer safe as the animation keeps misleading people.
			// trace('DODGE END!');
			// Cooldown timer so you can't keep spamming it.
			new FlxTimer().start(bfDodgeCooldown, function(tmr:FlxTimer)
			{
				bfCanDodge = true;
				// trace('DODGE RECHARGED!');
			});
		});
	}

	// Hold notes
	private function keyShit():Void
	{
		if (SONG.dodgeEnabled)
		{
			// FlxG.keys.justPressed.SPACE
			if (FlxG.keys.anyJustPressed(dodgeKey) && !bfDodging && bfCanDodge)
			{
				bfDodge();
			}
		}

		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [
				controls.NOTE_LEFT_P,
				controls.NOTE_DOWN_P,
				controls.NOTE_UP_P,
				controls.NOTE_RIGHT_P
			];
			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					goodNoteHit(daNote);
				}
			});

			// Fuck you, I added a taunt button because it's funny! -Haz
			// FlxG.keys.justPressed.SHIFT
			if (!inhumanSong
				&& FlxG.keys.anyJustPressed(tauntKey)
				&& !bfDodging
				&& !controlHoldArray.contains(true)
				&& !boyfriend.animation.curAnim.name.endsWith('miss')
				&& boyfriend.specialAnim == false)
			{
				boyfriend.playAnim('hey', true);
				boyfriend.specialAnim = true;
				boyfriend.heyTimer = 0.59;
				FlxG.sound.play(Paths.sound('hey'));
				tauntCounter++;
				trace("taunts: ", tauntCounter);
			}

			if (controlHoldArray.contains(true) && !endingSong)
			{
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null)
					startAchievement(achieve);
				#end
			}
			else if (!boyfriend.stunned
				&& !bfDodging
				&& boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
				&& boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [
				controls.NOTE_LEFT_R,
				controls.NOTE_DOWN_R,
				controls.NOTE_UP_R,
				controls.NOTE_RIGHT_R
			];
			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void
	{ // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note
				&& daNote.mustPress
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;
		// Less miss health when stunned since you can't really do anything while stunned and it'll be too unfair to deal full damage.
		health -= (daNote.missHealth * healthLoss * healthLossMultiplier) * (boyfriend.stunned ? 0.195 : 1);
		causeOfDeath = 'health';
		if (instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		// For testing purposes
		// trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;
		if (!practiceMode)
			songScore -= 10;

		totalPlayed++;
		RecalculateRating();

		var char:Character = boyfriend;
		if (daNote.gfNote)
		{
			char = gf;
		}

		if (char.hasMissAnimations && !bfDodging && !boyfriend.stunned)
		{
			var daAlt = '';
			if (daNote.noteType == 'Alt Animation')
				daAlt = '-alt';

			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [
			notes.members.indexOf(daNote),
			daNote.noteData,
			daNote.noteType,
			daNote.isSustainNote
		]);
	}

	function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss * healthLossMultiplier;
			if (instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (ClientPrefs.ghostTapping)
				return;

			if (combo > 5 && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if (!practiceMode)
				songScore -= 10;
			if (!endingSong)
			{
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
		});*/

			// Would be cool to make BF change colour when missing while dodging / stunned to communicate that the player is still missing in these states. -Haz
			// Update, I decided to implement this!
			if (boyfriend.hasMissAnimations && !bfDodging && !boyfriend.stunned)
				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			if (boyfriend.hasMissAnimations && (bfDodging || boyfriend.stunned))
				boyfriend.color = FlxColor.BLUE;

			vocals.volume = 0;
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		// Dad Health Drain Code. It's scuffed, but gets the job done -Haz
		// Only works on Hard difficulty.
		// v2.2: Updated to support Harder difficulty.
		if ((storyDifficulty == 2
			|| storyDifficulty == 3
			|| SONG.song.toLowerCase() == "termination"
			|| SONG.song.toLowerCase() == "cessation")
			&& dadDrainHealth > 0)
		{
			// prevents health drain if the drain would kill the player.
			if (health - dadDrainHealth - 0.1 > maxHealth)
			{
				// And here I thought that this code couldn't get any worse. What is wrong with me?

				// Health drain on sustain notes. Note that this is ignored if you've been hit by 2 or more sawblades.
				if (dadDrainHealthSustain && note.isSustainNote && sawbladeHits < 2)
				{
					switch (sawbladeHits)
					{
						case 0:
							if (health < 1.35)
							{
								if (health < 0.8)
								{
									// trace("0 - AWWW SHIT");
									health -= dadDrainHealth / 8.1; // Massively nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
								}
								else
								{
									// trace("0 - fuck you, you're above halfway now");
									health -= dadDrainHealth / 5.7; // nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
								}
							}
							else
							{
								// trace("0 - Nah, no nerfing just yet");
								health -= dadDrainHealth / 4.375;
							}
						case 1:
							if (health < 1.5)
							{
								if (health < 1)
								{
									// trace("1 - AWWW SHIT");
									health -= dadDrainHealth / 8.62; // Massively nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
								}
								else
								{
									// trace("1 - fuck you, you're above halfway now");
									health -= dadDrainHealth / 6.1; // nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
								}
							}
							else
							{
								// trace("1 - Nah, no nerfing just yet");
								health -= dadDrainHealth / 4.38;
							}
						case 2:
							if (health < 1.8125)
							{
								if (health < 1.43)
								{
									// trace("2 - AWWW SHIT");
									health -= dadDrainHealth / 9.3; // Massively nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
								}
								else
								{
									// trace("2 - fuck you, you're above halfway now");
									health -= dadDrainHealth / 6.65; // nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
								}
							}
							else
							{
								// trace("2 - Nah, no nerfing just yet");
								health -= dadDrainHealth / 4.46;
							}
						default:
							// This shouldn't trigger in normal circumstances.
							if (health < 1.6)
							{
								// trace("DEFAULT - AWWW SHIT");
								health -= dadDrainHealth / 8.25; // Massively nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
							}
							else
							{
								// trace("DEFAULT - fuck you, you're above halfway now");
								health -= dadDrainHealth / 6.25; // nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
							}
					}
				}
				else if (!note.isSustainNote)
				{
					if (sawbladeHits > 3)
					{
						health -= dadDrainHealth / 3.15; // At this point, just constantly nerf the opponent.
						// trace("+3 - You're completely fucked.");
					}
					else
					{
						switch (sawbladeHits)
						{
							case 0:
								if (health < 1.35)
								{
									if (health < 0.8)
									{
										// trace("0 - AWWW SHIT");
										health -= dadDrainHealth / 3; // Massively nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
									}
									else
									{
										// trace("0 - fuck you, you're above halfway now");
										health -= dadDrainHealth / 1.75; // nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
									}
								}
								else
								{
									// trace("0 - Nah, no nerfing just yet");
									health -= dadDrainHealth;
								}
							case 1:
								if (health < 1.5)
								{
									if (health < 1)
									{
										// trace("1 - AWWW SHIT");
										health -= dadDrainHealth / 3; // Massively nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
									}
									else
									{
										// trace("1 - fuck you, you're above halfway now");
										health -= dadDrainHealth / 1.77; // nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
									}
								}
								else
								{
									// trace("1 - Nah, no nerfing just yet");
									health -= dadDrainHealth / 1.1;
								}
							case 2:
								if (health < 1.8125)
								{
									if (health < 1.45)
									{
										// trace("2 - AWWW SHIT");
										health -= dadDrainHealth / 3.1; // Massively nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
									}
									else
									{
										// trace("2 - fuck you, you're above halfway now");
										health -= dadDrainHealth / 2; // nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
									}
								}
								else
								{
									// trace("2 - Nah, no nerfing just yet");
									health -= dadDrainHealth / 1.2;
								}
							case 3:
								if (health < 1.82)
								{
									// trace("3 - AWWW SHIT");
									health -= dadDrainHealth / 3.3; // Massively nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
								}
								else
								{
									// trace("3 - fuck you, you're above halfway now");
									health -= dadDrainHealth / 2.4; // nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
								}
							default:
								// This shouldn't trigger in normal circumstances.
								if (health < 1.6)
								{
									// trace("DEFAULT - AWWW SHIT");
									health -= dadDrainHealth / 3; // Massively nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
								}
								else
								{
									// trace("DEFAULT - fuck you, you're above halfway now");
									health -= dadDrainHealth / 1.5; // nerfs the amount of health Opponent can recover if over halfway to give the player more room to breath health-wise.
								}
						}
					}
				}
			}
		}

		if (note.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if (!note.noAnimation)
		{ // Added ignoreNote and hitMiss check to stop animations from playing from hurt notes. -Haz
			// removed because now they dont press the note anymore lmao - Luis
			var altAnim:String = "";

			if ((dad.curCharacter == "qt_annoyed" || dad.curCharacter == "qt-nervous") && FlxG.random.int(1, 18) == 2)
			{
				// Code for QT's random "glitch" alt animation to play.
				altAnim = '-alt';

				// Probably a better way of doing this by using the random int and throwing that at the end of the string... but I'm stupid and lazy. -Haz
				switch (FlxG.random.int(1, 3))
				{
					case 2:
						FlxG.sound.play(Paths.sound('hazard/glitch-error02'));
					case 3:
						FlxG.sound.play(Paths.sound('hazard/glitch-error03'));
					default:
						FlxG.sound.play(Paths.sound('hazard/glitch-error01'));
				}

				// 10% chance of an eye appearing on TV when glitching
				if (curStage == "street-real" && FlxG.random.bool(10))
				{
					if (!(curBeat >= 190 && curStep <= 898))
					{ // Makes sure the alert animation stuff isn't happening when the TV is playing the alert animation.
						if (FlxG.random.bool(52)) // Randomises whether the eye appears on left or right screen.
							qt_tv01.animation.play('eyeLeft');
						else
							qt_tv01.animation.play('eyeRight');

						qt_tv01.animation.finishCallback = function(pog:String)
						{
							if (qt_tv01.animation.curAnim.name == 'eyeLeft' || qt_tv01.animation.curAnim.name == 'eyeRight')
							{ // Making sure this only executes for only the eye animation played by the random chance. Probably a better way of doing it, but eh. -Haz
								qt_tv01.animation.play('idle', true);
							}
						}
					}
				}
			}
			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation')
					altAnim = '-alt';

			if (SONG.song.toLowerCase() == "cessation")
			{
				if (curBeat >= 199 && curBeat <= 262) // first drop

					altAnim = '-together';
				else if (curBeat >= 300)
					altAnim = '-together';
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if (note.gfNote)
				char = gf;

			if ((cameramove && char.curCharacter.startsWith("kb") && !char.curCharacter.startsWith("kb-classic")) || forcecameramove)
				movecamera(note);

			char.playAnim(animToPlay, true);
			char.holdTimer = 0;
		}

		if (!note.isSustainNote)
		{
			if (!note.noteSplashDisabled && !ClientPrefs.lowQuality /* && !forceMiddleScroll*/)
				spawnNoteSplashOnNote(note, false, note.noteSplashTexture == 'noteSplashes' ? dad.splashSkinFile : note.noteSplashTexture);

			// Makes KB's strums move back a bit to show his power... or something idfk it looks cool okay? -Haz
			// alr xd
			if ((dad.curCharacter.startsWith('kb') || note.noteType.startsWith('Kb Note')))
			{
				opponentStrums.members[note.noteData].y = hazardModChartDefaultStrumY[note.noteData] + (ClientPrefs.downScroll ? 23 : -23);
				FlxTween.tween(opponentStrums.members[note.noteData], {y: hazardModChartDefaultStrumY[note.noteData]}, 0.126, {ease: FlxEase.cubeOut});
			}
			if ((dad.noteSkinFile.startsWith('NOTE_assets_Kb')
				|| note.noteType.startsWith('Kb Note')
				|| dad.noteSkinFile == 'NOTE_assets_Qt')) // the new qt's note skin dont need to have custom scale anim
			{
				var scalex:Float = 0.694267515923567;
				var scaley:Float = 0.694267515923567;

				opponentStrums.members[note.noteData].scale.x = scalex + 0.2;
				opponentStrums.members[note.noteData].scale.y = scaley + 0.2;

				FlxTween.tween(opponentStrums.members[note.noteData].scale, {y: scaley, x: scalex}, 0.126, {ease: FlxEase.cubeOut});
			}
		}

		if (SONG.needsVoices && !inhumanSong) // Player2/Opponent can't restore vocals, only player1 can.
			vocals.volume = 1;

		var time:Float = 0.15;
		if (!controlsPlayer2 || cpuControlled)
		{
			if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				time += 0.15;

			StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % 4, time, note.noteType.startsWith('Kb Note'));
		}
		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [
			notes.members.indexOf(note),
			Math.abs(note.noteData),
			note.noteType,
			note.isSustainNote
		]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (cpuControlled && (note.ignoreNote || note.hitCausesMiss))
				return;

			if (note.hitCausesMiss)
			{
				noteMiss(note);

				if (!note.noteSplashDisabled && !note.isSustainNote)
					spawnNoteSplashOnNote(note, true, note.noteSplashTexture);

				causeOfDeath = "hurt";

				switch (note.noteType)
				{
					case 'Hurt Note' | 'Invisible Hurt Note': // Hurt notes
						if (boyfriend.animation.getByName('hurt') != null)
						{
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				// hitsound ported from charting state LMAO.
				if (ClientPrefs.hitsoundVolume > 0)
					FlxG.sound.play(Paths.sound('ChartingTick'), ClientPrefs.hitsoundVolume).pan = note.noteData < 4 ? -0.3 : 0.3; // would be coolio

				combo += 1;
				popUpScore(note);
				if (combo > 9999)
					combo = 9999;

				// Fuck you, no health gain on sustain notes.
				health += note.hitHealth * healthGain * healthGainMultiplier;
			}

			if (!note.noAnimation && !bfDodging && !boyfriend.stunned)
			{
				var daAlt = '';
				if (note.noteType == 'Alt Animation')
					daAlt = '-alt';

				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				if (note.gfNote)
				{
					gf.playAnim(animToPlay + daAlt, true);
					gf.holdTimer = 0;
				}
				else
				{
					boyfriend.playAnim(animToPlay + daAlt, true);
					boyfriend.holdTimer = 0;
				}
				// }
				if (note.noteType == 'Hey!')
				{
					if (boyfriend.animOffsets.exists('hey'))
					{
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if (gf.animOffsets.exists('cheer'))
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if (cpuControlled)
			{
				var time:Float = 0.15;
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			}
			else
			{
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note, isPlayer:Bool, skin:String = 'noteSplashes')
	{
		if (ClientPrefs.noteSplashes && note != null)
		{
			if (!isPlayer)
			{
				var strum:StrumNote = opponentStrums.members[note.noteData];
				if (strum != null)
					spawnNoteSplash(strum.x, strum.y, note.noteData, note, false, skin, strum.alpha / 2);
			}
			else
			{
				var strum:StrumNote = playerStrums.members[note.noteData];
				if (strum != null)
					spawnNoteSplash(strum.x, strum.y, note.noteData, note, true, skin, strum.alpha / 2);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null, isPlayer:Bool, Skin:String, alpha:Float)
	{
		var skin:String;

		skin = Skin;

		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if (note != null)
		{
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, Skin, hue, sat, brt, isPlayer, alpha);
		if (inhumanSong && !isPlayer)
			grpNoteSplashes.insert(members.indexOf(strumLineNotes), splash);
		else
			grpNoteSplashes.add(splash);
	}

	private var preventLuaRemove:Bool = false;

	override function destroy()
	{
		preventLuaRemove = true;
		for (i in 0...luaArray.length)
		{
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.destroy();
	}

	public static function cancelMusicFadeTween()
	{
		if (FlxG.sound.music.fadeTween != null)
		{
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua)
	{
		if (luaArray != null && !preventLuaRemove)
		{
			luaArray.remove(lua);
		}
	}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}

		// if(interlopeChroma != null){
		// trace("intensity:",interlopeChromaIntensity);
		// trace("intensity:",interlopeFadeinShaderIntensity);
		// }

		if (curStep == lastStepHit)
		{
			return;
		}

		// if(fogShitDEBUG != null){
		//	trace("FogShitDEBUG X: ",fogShitDEBUG.x);
		// }

		if (fogShitGroup != null && !ClientPrefs.lowQuality && curStage == 'depths')
		{
			fogShitGroup.forEach(function(fog:FogThing)
			{
				fog.x += fog.movementSpeed;
				if (fog.x >= 2050)
				{
					// trace("LoopBack!!!");
					fog.x = -2050;
					if (!fog.isUpperLayer)
						fog.y = 50 + FlxG.random.float(-24, 24);
					else
						fog.y = FlxG.random.float(-6, 18);
					fog.regenerate();
				}
			});
		}

		if (gfScared && curStep % 2 == 0)
		{
			gf.playAnim('scared', true);
			// if(!ClientPrefs.lowQuality)
			// gf404.playAnim('scared', true);
		}

		// v2.2 update: Opponent arrows now just copy the rotation of the players notes so they never desync.
		// err, haz, Hire me for Inhuman/j
		switch (noteSpeen) // changed the entire code just because this MAY help with something
		{
			case 1:
				if (curStep % 2 == 0)
					rotate_notes();
			case 2:
				rotate_notes();
		}

		lastStepHit = curStep;

		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat)
		{
			// trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (hazardBGpulsing && ClientPrefs.flashing)
			hazardBGkb.animation.play('pulse');

		if (hazardModChartEffect == 6)
			interlope_scrollspeed() // scrollspeed pulse effect
		else if (hazardModChartEffect == 5 || hazardModChartEffect == 3)
		{
			if (interlopeChroma != null)
				interlopeChromaIntensity = 0.018;
			if (curBeat % 2 == 0)
			{
				trace("Left");
				for (i in 0...playerStrums.length)
				{
					playerStrums.members[i].x = hazardModChartDefaultStrumX[i + 4] - 300;
					opponentStrums.members[i].x = hazardModChartDefaultStrumX[i + 4] + 300;
				}
				camHUD.angle = ClientPrefs.downScroll ? 1 : -1;
				FlxTween.tween(camHUD, {angle: ClientPrefs.downScroll ? 2.3 : -2.3}, 0.4, {ease: FlxEase.elasticOut});
			}
			else
			{
				trace("Right");
				for (i in 0...playerStrums.length)
				{
					playerStrums.members[i].x = hazardModChartDefaultStrumX[i + 4] + 300;
					opponentStrums.members[i].x = hazardModChartDefaultStrumX[i + 4] - 300;
				}
				camHUD.angle = ClientPrefs.downScroll ? -1 : 1;
				FlxTween.tween(camHUD, {angle: ClientPrefs.downScroll ? -2.3 : 2.3}, 0.4, {ease: FlxEase.elasticOut});
			}
		}

		if (qtTVstate == 8)
			qt_tv01.animation.play("heart", true);
		else if (qtTVstate == 1)
			qt_tv01.animation.play("alert", true);

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				// FlxG.log.add('CHANGED BPM!');
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			setOnLuas('altAnim', SONG.notes[Math.floor(curStep / 16)].altAnim);
			setOnLuas('gfSection', SONG.notes[Math.floor(curStep / 16)].gfSection);
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (!disableDefaultCamZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		gameHUD.beatHit();

		if (!gfScared
			&& curBeat % gfSpeed == 0
			&& !gf.stunned
			&& gf.animation.curAnim.name != null
			&& !gf.animation.curAnim.name.startsWith("sing"))
		{
			gf.dance();
		}

		if (curBeat % 2 == 0)
		{
			if (!bfDodging
				&& !boyfriend.stunned
				&& boyfriend.animation.curAnim.name != null
				&& !boyfriend.animation.curAnim.name.startsWith("sing"))
			{
				boyfriend.dance();
			}
			if (dad.animation.curAnim.name != null && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned)
			{
				dad.dance();
				camX = 0;
				camY = 0;
			}
		}
		else if (dad.danceIdle
			&& dad.animation.curAnim.name != null
			&& !dad.curCharacter.startsWith('gf')
			&& !dad.animation.curAnim.name.startsWith("sing")
			&& !dad.stunned)
		{
			dad.dance();
			camX = 0;
			camY = 0;
		}

		switch (SONG.song.toLowerCase())
		{
			case 'interlope':
				if ((curBeat >= 448 && curBeat < 510) || (curBeat >= 512 && curBeat < 574) || (curBeat >= 575 && curBeat < 640))
				{
					if (!disableDefaultCamZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.0075;
						camHUD.zoom += 0.015;
					}
				}
			case 'termination':
				if (curBeat >= 192 && curBeat <= 320) // 1st drop
				{
					if (!disableDefaultCamZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.0075;
						camHUD.zoom += 0.015;
					}
				}
				else if (curBeat >= 512 && curBeat <= 640) // 1st drop
				{
					if (!disableDefaultCamZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.0075;
						camHUD.zoom += 0.015;
					}
				}
				else if (curBeat >= 832 && curBeat <= 1088) // last drop
				{
					if (!disableDefaultCamZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.0075;
						camHUD.zoom += 0.015;
					}
				}
			case 'censory-overload':
				if (curBeat == 241 || curBeat == 249 || curBeat == 257 || curBeat == 265 || curBeat == 273 || curBeat == 281 || curBeat == 289
					|| curBeat == 293 || curBeat == 297 || curBeat == 301 || curBeat == 497 || curBeat == 505 || curBeat == 513 || curBeat == 521
					|| curBeat == 529 || curBeat == 537 || curBeat == 545 || curBeat == 549 || curBeat == 553 || curBeat == 557)
				{
					if (!disableDefaultCamZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.0075;
						camHUD.zoom += 0.015;
					}
				}
				if (curBeat >= 80 && curBeat <= 208) // first drop
				{
					if (!disableDefaultCamZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.0075;
						camHUD.zoom += 0.015;
					}
					// Gas Release effect
					if (curBeat % 16 == 0)
					{
						Gas_Release('burst');
					}
				}
				else if (curBeat >= 304 && curBeat <= 432) // second drop
				{
					if (!disableDefaultCamZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.0075;
						camHUD.zoom += 0.015;
					}

					// Gas Release effect
					if (curBeat % 8 == 0)
					{
						Gas_Release('burstALT');
					}
				}
				else if (curBeat >= 560 && curBeat <= 688)
				{ // third drop
					if (!disableDefaultCamZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.0075;
						camHUD.zoom += 0.015;
					}
					// Gas Release effect
					if (curBeat % 4 == 0)
						Gas_Release('burstFAST');
				}
				else if (curBeat == 702)
					Gas_Release('burst');
				else if (curBeat >= 832 && curBeat <= 960)
				{ // final drop
					if (!disableDefaultCamZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.0075;
						camHUD.zoom += 0.015;
					}

					// Gas Release effect
					if (curBeat % 4 == 2)
						Gas_Release('burstFAST');
				}
		}
		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); // DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	public var closeLuas:Array<FunkinLua> = [];

	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic
	{
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			var ret:Dynamic = luaArray[i].call(event, args);
			if (ret != FunkinLua.Function_Continue)
				returnVal = ret;
		}

		for (i in 0...closeLuas.length)
		{
			luaArray.remove(closeLuas[i]);
			closeLuas[i].stop();
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic)
	{
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
			luaArray[i].set(variable, arg);
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float, usekb:Bool = false)
	{
		var spr:StrumNote = null;
		if (isDad)
			spr = strumLineNotes.members[id];
		else
			spr = playerStrums.members[id];

		var animToPlay:String = (usekb ? 'kbconfirm' : 'confirm');
		if (spr != null)
		{
			if (spr.texture.startsWith('NOTE_assets_Qt'))
				spr.playAnim(animToPlay, true);
			else
				spr.playAnim('confirm', true);
			spr.resetAnim = time;
			// i know what i'm doing, relax -Luis
			// btw now is 5 am
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;

	public function RecalculateRating()
	{
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if (ret != FunkinLua.Function_Stop)
		{
			if (totalPlayed < 1) // Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				// trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if (ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length - 1)
					{
						if (ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0)
				ratingFC = "SFC";
			if (goods > 0)
				ratingFC = "GFC";
			if (bads > 0 || shits > 0)
				ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10)
				ratingFC = "SDCB";
			else if (songMisses >= 10)
				ratingFC = "Clear";
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	public static var othersCodeName:String = 'otherAchievements';

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if (chartingMode)
			return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		var achievementsToCheck:Array<String> = achievesToCheck;
		if (achievementsToCheck == null)
		{
			achievementsToCheck = [];
			for (i in 0...Achievements.achievementsStuff.length)
			{
				achievementsToCheck.push(Achievements.achievementsStuff[i][2]);
			}
			achievementsToCheck.push(othersCodeName);
		}

		for (i in 0...achievementsToCheck.length)
		{
			var achievementName:String = achievementsToCheck[i];
			var unlock:Bool = false;

			for (json in Achievements.loadedAchievements)
			{ // Requires jsons for call
				var ret:Dynamic = callOnLuas('onCheckForAchievement', [json.icon]); // Set custom goals

				// IDK, like
				// if getProperty('misses') > 10 and leName == 'lmao_skill_issue' then return Function_Continue end

				if (ret == FunkinLua.Function_Continue && !Achievements.isAchievementUnlocked(json.icon) && json.customGoal && !unlock)
				{
					unlock = true;
					achievementName = json.icon;
				}
			}

			if (!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled && !unlock)
			{
				switch (achievementName)
				{
					case 'sawblade_death':
						if (Achievements.sawbladeDeath >= 24)
						{
							unlock = true;
						}
					case 'sawblade_hell':
						if (Paths.formatToSongPath(SONG.song) == 'termination' && !usedPractice && sawbladeHits >= 3)
						{
							unlock = true;
						}
					case 'taunter':
						if (Paths.formatToSongPath(SONG.song) == 'termination' && !usedPractice && tauntCounter > 100)
						{
							unlock = true;
						}
					case 'tutorial_hard':
						if (Paths.formatToSongPath(SONG.song) == 'tutorial' && !usedPractice && CoolUtil.difficultyString() == 'HARD')
						{
							unlock = true;
						}
					case 'qtweek_hard':
						if (WeekData.getWeekFileName().toLowerCase() == 'qt'
							&& isStoryMode
							&& CoolUtil.difficultyString() == 'HARD'
							&& storyPlaylist.length <= 1
							&& !changedDifficulty
							&& !usedPractice)
						{
							unlock = true;
						} // Can unlock the achievement if playing on Harder.
						else if (WeekData.getWeekFileName().toLowerCase() == 'qt'
							&& isStoryMode
							&& CoolUtil.difficultyString() == 'HARDER'
							&& storyPlaylist.length <= 1
							&& !changedDifficulty
							&& !usedPractice)
						{
							unlock = true;
						}
					case 'ur_bad':
						if (ratingPercent < 0.2 && !usedPractice && Paths.formatToSongPath(SONG.song) != 'terminate')
						{
							unlock = true;
						}
					case 'ur_good':
						if (ratingPercent >= 1 && !usedPractice && Paths.formatToSongPath(SONG.song) != 'terminate')
						{
							unlock = true;
						}
					case 'termination_beat':
						if (Paths.formatToSongPath(SONG.song) == 'termination' && !usedPractice && storyDifficulty == 1)
						{
							unlock = true;
						}
					case 'termination_old':
						if (Paths.formatToSongPath(SONG.song) == 'termination' && !usedPractice && storyDifficulty == 2)
						{
							unlock = true;
						}
					case 'cessation_beat':
						if (Paths.formatToSongPath(SONG.song) == 'cessation' && !usedPractice)
						{
							unlock = true;
						}
					case 'cessation_troll':
						if (Paths.formatToSongPath(SONG.song) == 'cessation' && cessationTrollDone == true)
						{ // Can still be gotten even if you used practise
							unlock = true;
							// cessationTrollDone
						}
					case 'freeplay_depths':
						if (Paths.formatToSongPath(SONG.song) == 'interlope' && !usedPractice)
						{
							unlock = true;
						}
				}
			}

			if (unlock)
			{
				Achievements.unlockAchievement(achievementName);
				return achievementName;
			}
		}
		return null;
	}
	#end

	// ported somethings to function down here cuz no code flood -Luis

	public function movecamera(danote:Note = null) // well i tried
	{
		var cameraposX:Array<Int> = [-130, -40, -50, 65];
		var cameraposXextended:Array<Int> = [-150, -45, -53, 84];
		var cameraposY:Array<Int> = [20, 30, -70, -20];
		var cameraposYextended:Array<Int> = [25, 50, -85, -30];

		if (danote == null)
			return;

		if (danote.isSustainNote)
		{
			if (danote.animation.curAnim.name.endsWith('end'))
			{
				camX = cameraposX[Std.int(Math.abs(danote.noteData))];
				camY = cameraposY[Std.int(Math.abs(danote.noteData))];
			}
			else
			{
				camX = cameraposXextended[Std.int(Math.abs(danote.noteData))];
				camY = cameraposYextended[Std.int(Math.abs(danote.noteData))];
			}
		}
		else if (!danote.isSustainNote)
		{
			camX = cameraposXextended[Std.int(Math.abs(danote.noteData))];
			camY = cameraposYextended[Std.int(Math.abs(danote.noteData))];
			switch (Math.abs(danote.noteData % 4)) // i'm stupid
			{
				case 0:
					new FlxTimer().start(0.4, function(tmr:FlxTimer)
					{
						if (camX == cameraposXextended[0])
							camX = cameraposX[0];
						if (camY == cameraposYextended[0])
							camY = cameraposY[0];
					});
				case 1:
					new FlxTimer().start(0.4, function(tmr:FlxTimer)
					{
						if (camY == cameraposYextended[1])
							camY = cameraposY[1];
						if (camX == cameraposXextended[1])
							camX = cameraposX[1];
					});
				case 2:
					new FlxTimer().start(0.4, function(tmr:FlxTimer)
					{
						if (camY == cameraposYextended[2])
							camY = cameraposY[2];
						if (camX == cameraposXextended[2])
							camX = cameraposX[2];
					});
				case 3:
					new FlxTimer().start(0.4, function(tmr:FlxTimer)
					{
						if (camX == cameraposXextended[3])
							camX = cameraposX[3];
						if (camY == cameraposYextended[3])
							camY = cameraposY[3];
					});
			}
		}
	}

	public function Gas_Release(anim:String = 'burst')
	{
		if (!ClientPrefs.lowQuality)
		{
			if (qt_gas01 != null)
				qt_gas01.animation.play(anim);
			if (qt_gas02 != null)
				qt_gas02.animation.play(anim);
			if (qt_gaskb != null)
				qt_gaskb.animation.play(anim);
		}
	}

	public function interlope_scrollspeed()
	{
		if (songSpeedType != "constant")
		{
			var scrollSpeedShit:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			songSpeed = 1;
			songSpeedTween = FlxTween.tween(this, {songSpeed: scrollSpeedShit}, 0.37, {
				ease: FlxEase.sineOut,
				onComplete: function(twn:FlxTween)
				{
					songSpeedTween = null;
				}
			});
		}
	}

	public function rotate_notes()
	{
		for (i in 0...playerStrums.length)
		{
			playerStrums.members[i].angle += 22.5;
			if (playerStrums.members[i].angle >= 360)
				playerStrums.members[i].angle = (playerStrums.members[i].angle % 360) * 360;

			opponentStrums.members[i].angle = playerStrums.members[i].angle;
		}
	}

	public function changeCharacter(value1, value2)
	{
		var charType:Int = 0;
		switch (value1)
		{
			case 'gf' | 'girlfriend':
				charType = 2;
			case 'dad' | 'opponent':
				charType = 1;
			default:
				charType = Std.parseInt(value1);
				if (Math.isNaN(charType))
					charType = 0;
		}

		switch (charType)
		{
			case 0:
				if (boyfriend.curCharacter != value2)
				{
					if (!boyfriendMap.exists(value2))
						addCharacterToList(value2, charType);

					var lastAlpha:Float = boyfriend.alpha;
					boyfriend.alpha = 0.00001;
					boyfriend = boyfriendMap.get(value2);
					boyfriend.alpha = lastAlpha;
					gameHUD.iconP1.changeIcon(boyfriend.healthIcon);
				}
				setOnLuas('boyfriendName', boyfriend.curCharacter);

			case 1:
				if (dad.curCharacter != value2)
				{
					if (!dadMap.exists(value2))
						addCharacterToList(value2, charType);

					var wasGf:Bool = dad.curCharacter.startsWith('gf');
					var lastAlpha:Float = dad.alpha;
					dad.alpha = 0.00001;
					dad = dadMap.get(value2);
					if (!dad.curCharacter.startsWith('gf'))
					{
						if (wasGf)
							gf.visible = true;
					}
					else
						gf.visible = false;

					dad.alpha = lastAlpha;
					gameHUD.iconP2.changeIcon(dad.healthIcon);
					qt_gaskb.visible = (value2.startsWith("kb") && !value2.startsWith("kb-classic"));
				}
				setOnLuas('dadName', dad.curCharacter);

			case 2:
				if (gf.curCharacter != value2)
				{
					if (!gfMap.exists(value2))
						addCharacterToList(value2, charType);

					var lastAlpha:Float = gf.alpha;
					gf.alpha = 0.00001;
					gf = gfMap.get(value2);
					gf.alpha = lastAlpha;
				}
				setOnLuas('gfName', gf.curCharacter);
		}
		gameHUD.reloadHealthBarColors(qtIsBlueScreened);
		if (!ClientPrefs.lowQuality)
			reloadStaticsEvent();
	}
}
