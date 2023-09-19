package;

#if cpp
import cpp.ConstCharStar;
import cpp.UInt64;
#end
import flixel.FlxG;
import flixel.FlxState;
import openfl.system.Capabilities;

class InitLoader extends FlxState
{
	public static final Cpu:Bool = Capabilities.supports64BitProcesses; // too lazy for changing this
	public static final Ram:UInt64 = WindowsData.obtainRAM(); // cuz i cant put a cpp code with uncaughtErrorEvents
	public static var System(get, null):String = '';

	static function get_System():String
	{
		if (System == '')
			System = lime.system.System.platformLabel;

		return System;
	}

	public static var SystemVer(get, null):String = '';

	static function get_SystemVer():String
	{
		if (SystemVer == '')
			SystemVer = lime.system.System.platformVersion;

		return SystemVer;
	}

	// public static final Lang:String = Capabilities.language;
	// public static final Os:String = Capabilities.os;

	override public function create()
	{
		super.create();

			#if cpp
			WindowsData.enableVisualStyles();
			WindowsData.setWindowColorMode(DARK);

			checkSpecs(Cpu, Ram);
			ClientPrefs.loadSettings();
			lore.Colorblind.updateFilter();
			Locale.init();
			#end
			FlxG.switchState(new TitleState());
	}

	function checkSpecs(cpu:Bool, ram:UInt64)
		if (!cpu && ram <= 4096)
			messageBox("QT Fixes",
				"Your PC does not meet the requirements Qt fixes has.\nWhile you can still play the mod, you may experience frame drops and/or lag spikes.\n\nDo you want to play anyway?");

	function messageBox(title #if cpp :ConstCharStar #end = null, msg #if cpp :ConstCharStar #end = null)
	{
		#if windows
		var msgID:Int = untyped MessageBox(null, msg, title, untyped __cpp__("MB_ICONQUESTION | MB_YESNO"));

		if (msgID == 7)
			Sys.exit(0);

		return true;
		#else
		lime.app.Application.current.window.alert(cast msg, cast title);
		return true;
		#end
	}
}
