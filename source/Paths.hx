package;

import lime.media.vorbis.VorbisFile;
import lime.media.AudioBuffer;
import openfl.geom.Point;
import openfl.filters.BlurFilter;
import openfl.geom.Matrix;
import openfl.system.System;
import openfl.geom.Rectangle;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import haxe.Json;
#if desktop
import openfl.display3D.textures.RectangleTexture;
#end
import flash.media.Sound;

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	#if MODS_ALLOWED
	public static var ignoreModFolders:Array<String> = [
		'characters', 'custom_events', 'custom_notetypes', 'data', 'songs', 'music', 'sounds', 'shaders', 'locale', 'videos', 'images', 'stages', 'weeks',
		'fonts', 'scripts', 'achievements', 'classes'
	];
	#end

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [
		'assets/music/freakyMenu.$SOUND_EXT',
		'assets/shared/music/breakfast.$SOUND_EXT',
		'assets/shared/music/tea-time.$SOUND_EXT',
	];

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null)
				{
					// remove the key from all cache maps
					FlxG.bitmap._cache.remove(key);
					openfl.Assets.cache.removeBitmapData(key);
					currentTrackedAssets.remove(key);

					// and get rid of the object
					obj.persist = false; // make sure the garbage collector actually clears it up
					obj.destroyOnNoUse = true;
					// obj.texture = null;
					obj.bitmap.dispose();
					obj.bitmap.disposeImage();
					obj.destroy();
				}
			}
		}

		// run the garbage collector for good measure lmfao
		MemoryUtils.clearMajor();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory(?cleanUnused:Bool = false)
	{
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
			{
				// trace('test: ' + dumpExclusions, key);
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	static public var currentModDirectory:String = '';
	static public var currentLevel:String;

	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function getPath(file:String, ?type:AssetType = TEXT, ?library:Null<String> = null, ?modsAllowed:Bool = false):String
	{
		/*#if MODS_ALLOWED
			if (modsAllowed)
			{
				var modded:String = modFolders(file);
				if (FileSystem.exists(modded))
					return modded;
			}
			#end */
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);

	inline static function getLibraryPathForce(file:String, library:String)
	{
		var returnPath = '$library:assets/$library/$file';
		return returnPath;
	}

	inline public static function getPreloadPath(file:String = '')
		return 'assets/$file';

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
		return getPath(file, type, library);

	inline static public function txt(key:String, ?library:String)
		return getPath('data/$key.txt', TEXT, library);

	inline static public function xml(key:String, ?library:String)
		return getPath('data/$key.xml', TEXT, library);

	inline static public function json(key:String, ?library:String)
		return getPath('data/$key.json', TEXT, library);

	inline static public function shaderFragment(key:String, ?library:String)
		return getPath('shaders/$key.frag', TEXT, library);

	inline static public function shaderVertex(key:String, ?library:String)
		return getPath('shaders/$key.vert', TEXT, library);

	inline static public function localeFile(key:String, ?library:String)
		return getPath('locale/$key/lang.json', TEXT, library);

	inline static public function lua(key:String, ?library:String)
		return getPath('$key.lua', TEXT, library);

	inline static public function Script(key:String)
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(modFolders('classes/$key.hx')))
			return modFolders('classes/$key.hx');
		#end
		if (FileSystem.exists(getPreloadPath('classes/$key.hx')))
			return getPreloadPath('classes/$key.hx');

		trace('File for script $key.hx not found!');
		return null;
	}

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if (FileSystem.exists(file))
			return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
		return sound(key + FlxG.random.int(min, max), library);

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function voices(song:String):Any // i shoud improve this late :whhyyyy:
	{
		#if html5
		return 'songs:assets/songs/${formatToSongPath(song)}/Voices.$SOUND_EXT';
		#else
		var songKey:String = '${formatToSongPath(song)}/Voices';
		var voices = returnSound('songs', songKey);
		return voices;
		#end
	}

	inline static public function voicesCLASSIC(song:String):Any
	{
		#if html5
		return 'songs:assets/songs/${formatToSongPath(song)}/Voices-classic.$SOUND_EXT';
		#else
		var songKey:String = '${formatToSongPath(song)}/Voices-classic';
		var voices = returnSound('songs', songKey);
		return voices;
		#end
	}

	inline static public function voicesOLD(song:String):Any
	{
		#if html5
		return 'songs:assets/songs/${formatToSongPath(song)}/Voices-old.$SOUND_EXT';
		#else
		var songKey:String = '${formatToSongPath(song)}/Voices-old';
		var voices = returnSound('songs', songKey);
		return voices;
		#end
	}

	inline static public function inst(song:String):Any
	{
		#if html5
		return 'songs:assets/songs/${formatToSongPath(song)}/Inst.$SOUND_EXT';
		#else
		var songKey:String = '${formatToSongPath(song)}/Inst';
		var inst = returnSound('songs', songKey);
		return inst;
		#end
	}

	inline static public function instOLD(song:String):Any
	{
		#if html5
		return 'songs:assets/songs/${formatToSongPath(song)}/Inst-old.$SOUND_EXT';
		#else
		var songKey:String = '${formatToSongPath(song)}/Inst-old';
		var inst = returnSound('songs', songKey);
		return inst;
		#end
	}

	inline static public function image(key:String, ?library:String, ?text:Bool = false):FlxGraphic
	{
		var returnAsset:FlxGraphic = returnGraphic(key, library, text);
		return returnAsset;
	}

	inline static public function imageRandom(key:String, min:Int, max:Int, ?library:String, ?text:Bool = false)
		return image(key + FlxG.random.int(min, max), library, text);

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key)))
			return File.getContent(modFolders(key));
		#end

		if (FileSystem.exists(getPreloadPath(key)))
			return File.getContent(getPreloadPath(key));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(key, currentLevel);
				if (FileSystem.exists(levelPath))
					return File.getContent(levelPath);
			}

			levelPath = getLibraryPathForce(key, 'shared');
			if (FileSystem.exists(levelPath))
				return File.getContent(levelPath);
		}
		#end
		var path:String = getPath(key, TEXT);
		if (OpenFlAssets.exists(path, TEXT))
			return Assets.getText(path);
		return null;
	}

	inline static public function font(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if (FileSystem.exists(file))
			return file;
		#end
		return 'assets/fonts/$key';
	}

	inline static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String)
	{
		#if MODS_ALLOWED
		if ((FileSystem.exists(mods(currentModDirectory + '/' + key)) || FileSystem.exists(mods(key))) && !ignoreMods)
			return true;
		#end

		if (OpenFlAssets.exists(getPath(key, type)))
			return true;

		return false;
	}

	// less optimized but automatic handling
	static public function getAtlas(key:String, ?library:String = null):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(modsXml(key)) || OpenFlAssets.exists(getPath('images/$key.xml', library), TEXT))
		#else
		if (OpenFlAssets.exists(getPath('images/$key.xml', library)))
		#end
		{
			return getSparrowAtlas(key, library);
		}
		return getPackerAtlas(key, library);
	}

	inline static public function getSparrowAtlas(key:String, ?library:String, ?text:Bool = false):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key, library, text);
		var xmlExists:Bool = false;
		if (FileSystem.exists(modsXml(key)))
			xmlExists = true;

		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key, library, text)),
			(xmlExists ? File.getContent(modsXml(key)) : file('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library, text), file('images/$key.xml', library));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?library:String, ?text:Bool = false)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key, library, text);
		var txtExists:Bool = false;
		if (FileSystem.exists(modsTxt(key)))
			txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library, text)),
			(txtExists ? File.getContent(modsTxt(key)) : file('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library, text), file('images/$key.txt', library));
		#end
	}

	inline static public function formatToSongPath(path:String)
	{
		var invalidChars:EReg = ~/[~&\\;:<>#]+/g;
		var hideChars:EReg = ~/[.,'"%?!]+/g;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	static public function returnGraphic(key:String, ?library:String = null, ?text:Bool = false):FlxGraphic
	{
		var bitmap:BitmapData = null;
		var file:String = null;

		#if MODS_ALLOWED
		file = modsImages(key);
		#end

		if (file == null || !currentTrackedAssets.exists(file))
			file = getPath('images/$key.png', IMAGE, library);

		if (currentTrackedAssets.exists(file))
		{
			var cachedGraphic:FlxGraphic = currentTrackedAssets.get(file);
			localTrackedAssets.push(file);
			return cachedGraphic;
		}

		bitmap = OpenFlAssets.getBitmapData(file);

		if (bitmap != null)
		{
			localTrackedAssets.push(file);
			var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
			newGraphic.persist = true;
			newGraphic.destroyOnNoUse = false;
			currentTrackedAssets.set(file, newGraphic);
			return newGraphic;
		}

		trace('Image "$key" is returning null.');
		return null;
	}

	public static function reduceBitmapDataQuality(source:BitmapData, applyblur:Bool = true, by:Int = 2):BitmapData
	{
		var halfby:Float = 1 / by;
		var halfWidth:Int = Math.ceil(source.width / by);
		var halfHeight:Int = Math.ceil(source.height / by);
		var reducedBitmapData:BitmapData = new BitmapData(halfWidth, halfHeight, true, 0);
		var matrix:Matrix = new Matrix();
		matrix.scale(halfby, halfby);
		reducedBitmapData.draw(source, matrix, null, null, null, true);
		matrix.identity();
		matrix.scale(by, by);
		if (applyblur)
			reducedBitmapData.applyFilter(reducedBitmapData, reducedBitmapData.rect, new Point(), new BlurFilter(by / 2, by / 2, Std.int(by / 2)));
		var resultBitmapData:BitmapData = new BitmapData(source.width, source.height, true, 0);
		var resultMatrix:Matrix = new Matrix();
		resultMatrix.scale(by, by);
		resultBitmapData.draw(reducedBitmapData, resultMatrix, null, null, null, true);
		return resultBitmapData;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function returnSound(path:String, key:String, ?library:String, stream:Bool = false)
	{
		var sound:Sound = null;
		var file:String = null;

		#if MODS_ALLOWED
		file = modsSounds(path, key);
		if (currentTrackedSounds.exists(file))
		{
			localTrackedAssets.push(file);
			return currentTrackedSounds.get(file);
		}
		else if (FileSystem.exists(file))
		{
			#if lime_vorbis
			if (stream)
				sound = Sound.fromAudioBuffer(AudioBuffer.fromVorbisFile(VorbisFile.fromFile(file)));
			else
			#end
			sound = Sound.fromFile(file);
		}
		else
		#end
		{
			// I hate this so god damn much
			var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
			file = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
			if (path == 'songs')
				gottenPath = 'songs:' + gottenPath;
			if (currentTrackedSounds.exists(file))
			{
				localTrackedAssets.push(file);
				return currentTrackedSounds.get(file);
			}
			else if (OpenFlAssets.exists(gottenPath, SOUND))
			{
				#if lime_vorbis
				if (stream)
					sound = OpenFlAssets.getMusic(gottenPath);
				else
				#end
				sound = OpenFlAssets.getSound(gottenPath);
			}
		}

		if (sound != null)
		{
			localTrackedAssets.push(file);
			currentTrackedSounds.set(file, sound);
			return sound;
		}
		trace('oh no Sound: "$key" is returning null NOOOO');
		return null;
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
		return 'mods/' + key;

	inline static public function modsFont(key:String)
		return modFolders('fonts/' + key);

	inline static public function modsJson(key:String)
		return modFolders('data/' + key + '.json');

	inline static public function modsVideo(key:String)
		return modFolders('videos/' + key + '.' + VIDEO_EXT);

	inline static public function modsSounds(path:String, key:String)
		return modFolders(path + '/' + key + '.' + SOUND_EXT);

	inline static public function modsImages(key:String)
		return modFolders('images/' + key + '.png');

	inline static public function modsXml(key:String)
		return modFolders('images/' + key + '.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/' + key + '.txt');

	inline static public function modsLocaleFile(key:String)
		return modFolders('locale/$key/lang.json');

	static public function modFolders(key:String)
	{
		if (currentModDirectory != null && currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(currentModDirectory + '/' + key);
			if (FileSystem.exists(fileToCheck))
				return fileToCheck;
		}

		for (mod in getGlobalMods())
		{
			var fileToCheck:String = mods(mod + '/' + key);
			if (FileSystem.exists(fileToCheck))
				return fileToCheck;
		}
		return 'mods/' + key;
	}

	public static var globalMods:Array<String> = [];

	static public function getGlobalMods()
		return globalMods;

	static public function pushGlobalMods() // prob a better way to do this but idc
	{
		globalMods = [];
		var path:String = 'modsList.txt';
		if (FileSystem.exists(path))
		{
			var list:Array<String> = CoolUtil.coolTextFile(path);
			for (i in list)
			{
				var dat = i.split("|");
				if (dat[1] == "1")
				{
					var folder = dat[0];
					var path = Paths.mods(folder + '/pack.json');
					if (FileSystem.exists(path))
					{
						try
						{
							var rawJson:String = File.getContent(path);
							if (rawJson != null && rawJson.length > 0)
							{
								var stuff:Dynamic = Json.parse(rawJson);
								var global:Bool = Reflect.getProperty(stuff, "runsGlobally");
								if (global)
									globalMods.push(dat[0]);
							}
						}
						catch (e:Dynamic)
						{
							trace(e);
						}
					}
				}
			}
		}
		return globalMods;
	}

	static public function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		var modsFolder:String = mods();
		if (FileSystem.exists(modsFolder))
		{
			for (folder in FileSystem.readDirectory(modsFolder))
			{
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (sys.FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder) && !list.contains(folder))
				{
					list.push(folder);
				}
			}
		}
		return list;
	}
	#end
}
