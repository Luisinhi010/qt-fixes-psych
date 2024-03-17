package;

#if HAXE_EXTENSION
import flixel.*;
import tea.SScript;
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
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import codename.FlxFixedShader;
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
class ScriptHandler #if HAXE_EXTENSION extends SScript #end
{
	public function new(?scriptPath:String, ?preset:Bool = true)
	{
		#if HAXE_EXTENSION
		if (scriptPath == null)
			return;
		super(scriptPath, preset);
		trace('Running script: ' + scriptPath);
		traces = false;
		#end
	}

	#if HAXE_EXTENSION
	override public function preset():Void
	{
		super.preset();

		// here we set up the built-in imports
		// these should work on *any* script;

		// CLASSES (FLIXEL);
		setClass(FlxG);
		setClass(FlxBasic);
		setClass(FlxObject);
		setClass(FlxCamera);
		setClass(FlxSprite);
		setClass(FlxText);
		setClass(FlxText);
		set('FlxTextBorderStyle', FlxTextBorderStyle);
		setClass(flixel.addons.display.FlxRuntimeShader);
		setClass(FlxSound);
		setClass(flixel.FlxState);
		setClass(flixel.FlxSubState);
		setClass(FlxTimer);
		setClass(FlxTween);
		setClass(FlxEase);
		setClass(FlxMath);
		setClass(FlxGroup);
		setClass(FlxTypedGroup);
		setClass(FlxSpriteGroup);
		setClass(FlxTypedSpriteGroup);
		setClass(FlxStringUtil);
		setClass(FlxAtlasFrames);
		setClass(FlxSort);
		setClass(Application);
		setClass(FlxGraphic);
		setClass(File);
		setClass(FlxTrail);
		setClass(FlxFixedShader);
		setClass(FlxBar);
		setClass(FlxBackdrop);
		setClass(StageSizeScaleMode);
		set('FlxBarFillDirection', FlxBarFillDirection);
		#if (flixel < "5.0.0")
		set('FlxAxes', FlxAxes);
		set('FlxPoint', FlxPoint);
		#end
		setClass(GraphicsShader);
		setClass(ShaderFilter);

		// CLASSES (Qt fixes);
		setClass(CustomMouse);
		setClass(InitLoader);
		setClass(WindowsData);
		setClass(GPUTools);
		setClass(OverlaySprite);
		setClass(InputFormatter);
		setClass(CachingState);
		setClass(FogThing);
		setClass(ColorMask);
		setClass(AttachedFlxText);

		// CLASSES (Lore engine):
		setClass(Locale);
		setClass(lore.Colorblind);

		// CLASSES (BASE);
		setClass(BGSprite);
		setClass(HealthIcon);
		setClass(MusicBeatState);
		setClass(MusicBeatSubstate);
		setClass(AttachedFlxSprite);
		setClass(AttachedText);
		setClass(Discord.DiscordClient);
		setClass(Alphabet);
		setClass(Character);
		setClass(Controls);
		setClass(CoolUtil);
		setClass(Conductor);
		setClass(PlayState);
		set('game', PlayState.instance);
		setClass(Main);
		setClass(Note);
		setClass(NoteSplash);
		setClass(StrumNote);
		setClass(Paths);
		setClass(FunkinLua);
		setClass(Achievements);
		setClass(ClientPrefs);
		setClass(ColorSwap);
		set("trace", traace);

		set('getVarFromClass', function(instance:String, variable:String)
		{
			Reflect.field(Type.resolveClass(instance), variable);
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

		set('sys', #if sys true #else false #end);
	}
	#end

	public function callFunc(key:String, args:Array<Dynamic>) // bruh
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
