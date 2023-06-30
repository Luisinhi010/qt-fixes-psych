package; // a very scuffed class for overlays, got unused.

import flixel.FlxSprite;
import lime.app.Application;
import flixel.FlxG;

class OverlaySprite extends FlxSprite
{
	public var usewindowscale(default, set):Bool = true;

	public function set_usewindowscale(value:Bool):Bool
	{
		usewindowscale = value;
		repos();
		return value;
	}

	public var initialWidth:Float;
	public var initialHeight:Float;

	public function new(image:String, ?library:String)
	{
		super();
		if (image != null && Paths.fileExists('images/' + image + '.png', IMAGE, false, library))
		{
			loadGraphic(Paths.image(image, library));
			create();
		}
	}

	public function create()
	{
		initialWidth = width;
		initialHeight = height;
		width = 1280;
		height = 720;
		repos();

		scrollFactor.set(0, 0);
		updateHitbox();
		antialiasing = ClientPrefs.globalAntialiasing;

		FlxG.signals.gameResized.add(repos);
	}

	public function repos(w:Int = 0, h:Int = 0)
	{
		var res:Array<Int> = [Application.current.window.width, Application.current.window.height];
		if (!usewindowscale)
			res = [FlxG.width, FlxG.height];
		x = (res[0] - width) / 2;
		y = (res[1] - height) / 2;
	}

	public override function destroy()
		FlxG.signals.gameResized.remove(repos);
}
