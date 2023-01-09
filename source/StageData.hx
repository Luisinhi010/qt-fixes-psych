package;

#if MODS_ALLOWED
import sys.io.File;
#if cpp import sys.FileSystem; #end
#else
import openfl.utils.Assets;
#end
import haxe.Json;
import haxe.format.JsonParser;
import Song;

using StringTools;

typedef StageFile =
{
	var directory:String;
	var defaultZoom:Float;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;
	var hide_girlfriend:Bool;
	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;
	var camera_girlfriend:Array<Float>;
	var camera_speed:Null<Float>;
}

class StageData
{
	public static var forceNextDirectory:String = null;

	public static function loadDirectory(SONG:SwagSong)
	{
		var stage:String = '';
		if (SONG.stage != null)
		{
			stage = SONG.stage;
		}
		else if (SONG.song != null)
		{
			switch (SONG.song.toLowerCase().replace(' ', '-'))
			{
				case 'carefree':
					stage = 'street-cute';
				case 'careless':
					stage = 'street-real';
				case 'cessation':
					stage = 'street-cessation';
				case 'censory-overload' | 'terminate':
					stage = 'street-kb';
				case 'termination':
					stage = 'street-termination';
				default:
					stage = 'stage';
			}
		}
		else
			stage = 'stage';

		var stageFile:StageFile = getStageFile(stage);
		if (stageFile == null)
			forceNextDirectory = '';
		else
			forceNextDirectory = stageFile.directory;
	}

	public static function getStageFile(stage:String):StageFile
	{
		var rawJson:String = null;
		var path:String = Paths.getPreloadPath('stages/' + stage + '.json');

		#if MODS_ALLOWED
		var modPath:String = Paths.modFolders('stages/' + stage + '.json');
		if (FileSystem.exists(SUtil.getStorageDirectory() + modPath))
			rawJson = File.getContent(modPath);
		else if (FileSystem.exists(SUtil.getStorageDirectory() + path))
			rawJson = File.getContent(path);
		#else
		if (Assets.exists(path))
			rawJson = Assets.getText(path);
		#end
	else
		return null;

		return cast Json.parse(rawJson);
	}
}
