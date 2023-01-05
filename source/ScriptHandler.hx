package;

#if HAXE_EXTENSION
import flixel.*;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.effects.FlxTrail;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.*;
import flixel.system.*;
import flixel.system.scaleModes.StageSizeScaleMode;
import flixel.text.FlxText;
import flixel.tweens.*;
import flixel.ui.FlxBar;
import flixel.util.*;
import lime.app.Application;
import openfl.display.GraphicsShader;
import openfl.filters.ShaderFilter;
import Discord.DiscordClient as Discord;
import shadertoy.FlxShaderToyRuntimeShader;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import sys.io.File;

using StringTools;
#end

/**
 * alot of scripts
 * based on Ghost's Forever Underscore
 * @see https://github.com/BeastlyGhost/Forever-Engine-Underscore/blob/master/source/base/ScriptHandler.hx
 * and on Lore engine FuckinHX/Yoshi engine's HxScript support 
 * @see https://github.com/sayofthelor/lore-engine/blob/main/source/lore/FunkinHX.hx
 */
class ScriptHandler #if HAXE_EXTENSION extends SScript implements IFlxDestroyable #end
{
	var ignoreErrors:Bool = false;

	public function new(file:String, ?preset:Bool = true)
	{
		#if HAXE_EXTENSION
		if (file == null)
			return;
		super(file, preset);
		trace('Running script: ' + file);
		traces = false;
		#end
	}

	#if HAXE_EXTENSION
	override public function preset():Void
	{
		super.preset();

		// here we set up the built-in imports
		// these should work on *any* script;

		// CLASSES (HAXE)
		set('Type', Type);
		set('Math', Math);
		set('Std', Std);
		set('Date', Date);

		// CLASSES (FLIXEL);
		set('FlxG', FlxG);
		set('FlxBasic', FlxBasic);
		set('FlxObject', FlxObject);
		set('FlxCamera', FlxCamera);
		set('FlxSprite', FlxSprite);
		set('FlxText', FlxText);
		set('FlxText', FlxText);
		set('FlxTextBorderStyle', FlxTextBorderStyle);
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		set('FlxSound', FlxSound);
		set('FlxState', flixel.FlxState);
		set('FlxSubState', flixel.FlxSubState);
		set('FlxTimer', FlxTimer);
		set('FlxTween', FlxTween);
		set('FlxEase', FlxEase);
		set('FlxMath', FlxMath);
		set('FlxGroup', FlxGroup);
		set('FlxTypedGroup', FlxTypedGroup);
		set('FlxSpriteGroup', FlxSpriteGroup);
		set('FlxTypedSpriteGroup', FlxTypedSpriteGroup);
		set('FlxStringUtil', FlxStringUtil);
		set('FlxAtlasFrames', FlxAtlasFrames);
		set('FlxSort', FlxSort);
		set('Application', Application);
		set('FlxGraphic', FlxGraphic);
		set('File', File);
		set('FlxTrail', FlxTrail);
		set('FlxShader', FlxFixedShader);
		set('FlxBar', FlxBar);
		set('FlxBackdrop', FlxBackdrop);
		set('StageSizeScaleMode', StageSizeScaleMode);
		set('FlxBarFillDirection', FlxBarFillDirection);
		#if (flixel < "5.0.0")
		set('FlxAxes', FlxAxes);
		set('FlxPoint', FlxPoint);
		#end
		set('GraphicsShader', GraphicsShader);
		set('ShaderFilter', ShaderFilter);

		// CLASSES (Qt fixes);
		set('CustomMouse', CustomMouse);
		set('InitLoader', InitLoader);
		set('WindowsData', WindowsData);
		set('GPUTools', GPUTools);
		set('OverlaySprite', OverlaySprite);
		set('InputFormatter', InputFormatter);
		set('Cache', Cache);
		set('FogThing', FogThing);

		// CLASSES (BASE);
		set('BGSprite', BGSprite);
		set('HealthIcon', HealthIcon);
		set('AttachedSprite', AttachedSprite);
		set('AttachedText', AttachedText);
		set('Discord', Discord);
		set('Alphabet', Alphabet);
		set('Character', Character);
		set('Controls', Controls);
		set('CoolUtil', CoolUtil);
		set('Conductor', Conductor);
		set('PlayState', PlayState);
		set('game', PlayState.instance);
		set('Main', Main);
		set('Note', Note);
		set('NoteSplash', NoteSplash);
		set('StrumNote', StrumNote);
		set('Paths', Paths);
		set('FunkinLua', FunkinLua);
		set('Achievements', Achievements);
		set('ClientPrefs', ClientPrefs);
		set("trace", traace);

		set('getVarFromClass', function(instance:String, variable:String)
		{
			Reflect.field(Type.resolveClass(instance), variable);
		});

		set("create", function()
		{
		});
		set("createPost", function()
		{
		});
		set("update", function(elapsed:Float)
		{
		});
		set("updatePost", function(elapsed:Float)
		{
		});
		set("startCountdown", function()
		{
		});
		set("onCountdownStarted", function()
		{
		});
		set("onCountdownTick", function(tick:Int)
		{
		});
		set("onUpdateScore", function(miss:Bool)
		{
		});
		set("onNextDialogue", function(counter:Int)
		{
		});
		set("onSkipDialogue", function()
		{
		});
		set("onSongStart", function()
		{
		});
		set("eventEarlyTrigger", function(eventName:String)
		{
		});
		set("onResume", function()
		{
		});
		set("onPause", function()
		{
		});
		set("onSpawnNote", function(note:Note)
		{
		});
		set("onGameOver", function()
		{
		});
		set("onEvent", function(name:String, val1:Dynamic, val2:Dynamic)
		{
		});
		set("onMoveCamera", function(char:String)
		{
		});
		set("onEndSong", function()
		{
		});
		set("onGhostTap", function(key:Int)
		{
		});
		set("onKeyPress", function(key:Int)
		{
		});
		set("onKeyRelease", function(key:Int)
		{
		});
		set("noteMiss", function(note:Note)
		{
		});
		set("noteMissPress", function(direction:Int)
		{
		});
		set("opponentNoteHit", function(note:Note)
		{
		});
		set("goodNoteHit", function(note:Note)
		{
		});
		set("noteHit", function(note:Note)
		{
		});
		set("stepHit", function()
		{
		});
		set("beatHit", function()
		{
		});
		set("sectionHit", function()
		{
		});
		set("onRecalculateRating", function()
		{
		});
		set("onHeadBop", function(name:String)
		{
		});
		set("onGameOverStart", function()
		{
		});
		set("onGameOverConfirm", function()
		{
		});
		set("destroy", function()
		{
		});

		FlxG.signals.focusGained.add(function()
		{
			call("focusGained", []);
		});
		FlxG.signals.focusLost.add(function()
		{
			call("focusLost", []);
		});
		FlxG.signals.gameResized.add(function(w:Int, h:Int)
		{
			call("gameResized", [w, h]);
		});
		FlxG.signals.postDraw.add(function()
		{
			call("postDraw", []);
		});
		FlxG.signals.postGameReset.add(function()
		{
			call("postGameReset", []);
		});
		FlxG.signals.postGameStart.add(function()
		{
			call("postGameStart", []);
		});
		FlxG.signals.postStateSwitch.add(function()
		{
			call("postStateSwitch", []);
		});

		#if windows
		set('buildTarget', 'windows');
		#elseif linux
		set('buildTarget', 'linux');
		#elseif mac
		set('buildTarget', 'mac');
		#elseif html5
		set('buildTarget', 'browser');
		#elseif android
		set('buildTarget', 'android');
		#else
		set('buildTarget', 'unknown');
		#end
	}
	#end

	public function callFunc(key:String, args:Array<Dynamic>)
	{
		#if HAXE_EXTENSION
		if (this == null || interp == null)
			return null;
		else
			return call(key, args);
		#else
		return null;
		#end
	}

	public function setVar(key:String, value:Dynamic)
	{
		#if HAXE_EXTENSION
		if (this == null || interp == null)
			return null;
		else
			return set(key, value);
		#else
		return null;
		#end
	}

	public function traace(text:String):Void
	{
		#if HAXE_EXTENSION
		var posInfo:haxe.PosInfos = interp.posInfos();
		#if sys Sys.println #else js.Browser.console.log #end (scriptFile + ":" + posInfo.lineNumber + ": " + text);
		#end
	}

	#if HAXE_EXTENSION
	public function destroy():Void
	{
		interp = null;
		scriptFile = null;
	}

	public function varExists(key:String):Bool
	{
		if (this != null && interp != null)
			return exists(key);
		return false;
	}

	public function getVar(key:String):Dynamic
	{
		if (this != null && interp != null)
			return get(key);
		return null;
	}
	#end
}
