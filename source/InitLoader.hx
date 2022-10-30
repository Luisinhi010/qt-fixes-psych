package;

import cpp.ConstCharStar;
import flixel.FlxG;
import flixel.FlxState;
import openfl.system.Capabilities;

class InitLoader extends FlxState
{
	override public function create()
	{
		super.create();
		WindowsData.setWindowColorMode(DARK);
		var cpu:Bool = Capabilities.supports64BitProcesses; // too lazy for changing this
		var ram:Int = WindowsData.obtainRAM(); // cuz i cant put a cpp code with uncaughtErrorEvents
		trace('Ram: ' + ram + ' Cpu: ' + cpu);
		trace(Capabilities.language); // for testing
		trace(Capabilities.os);
		trace(Capabilities.cpuArchitecture);
		trace(Capabilities.version);
		checkSpecs(cpu, ram);
		ClientPrefs.loadSettings(); // precase is disabled for testing
		/*if (FlxG.save.data.precache == null)
				{
					FlashingState.precachewarning = true;
					FlxG.switchState(new FlashingState());
				}
				else 
			{
				if (ClientPrefs.precache && !Cache.loaded)
						FlxG.switchState(new Cache());
					else */
		FlxG.switchState(new TitleState());
		// }
	}

	function checkSpecs(cpu:Bool, ram:Int)
		if (!cpu && ram < 4096)
			messageBox("QT Fixes",
				"Your PC does not meet the requirements Qt fixes has.\nWhile you can still play the mod, you may experience frame drops and/or lag spikes.\n\nDo you want to play anyway?");

	function messageBox(title:ConstCharStar = null, msg:ConstCharStar = null)
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
