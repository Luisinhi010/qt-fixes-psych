package;

import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.graphics.frames.FlxAtlasFrames;

class NoteSplash extends FlxSprite
{
	public var colorSwap:ColorSwap = null;
	public var colorMask:ColorMask = null;

	private var idleAnim:String;
	private var textureLoaded:String = null;
	private var isPlayer:Bool = false;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0)
	{
		super(x, y);

		var realtexture:String = 'Splashes/noteSplashes';

		loadAnims(realtexture);

		colorSwap = new ColorSwap();
		colorMask = new ColorMask();

		setupNoteSplash(x, y, note);
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = 'noteSplashes', color:FlxColor = FlxColor.WHITE, hueColor:Float = 0,
			satColor:Float = 0, brtColor:Float = 0, ?isPlayer:Bool = false, thealpha:Float = 0.6)
	{
		shader = null;
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		alpha = thealpha;
		this.isPlayer = isPlayer;

		if (texture == null)
			texture = 'noteSplashes';

		if (textureLoaded != texture)
			loadAnims(texture, true);

		if (isPlayer)
			if (ClientPrefs.useRGB)
				colorMask.rCol = color;
			else
			{
				colorSwap.hue = hueColor;
				colorSwap.saturation = satColor;
				colorSwap.brightness = brtColor;
			}
		offset.set(10, 10);

		var animNum:Int = FlxG.random.int(1, 2);
		animation.play('note' + note + '-' + animNum, true);
		if (animation.curAnim != null)
			animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
	}

	public function loadAnims(skin:String, reloadshaders:Bool = false)
	{
		var name:String = 'Splashes/' + skin;
		if (!Paths.fileExists('images/' + name + '.png', IMAGE, false, 'shared'))
			name = skin;
		if (!Paths.fileExists('images/' + name + '.png', IMAGE, false, 'shared'))
			name = 'Splashes/noteSplashes';

		if (isPlayer && reloadshaders)
			if (ClientPrefs.useRGB && skin == 'noteSplashes')
			{
				name = 'Splashes/noteSplashesRGB';
				shader = colorMask.shader;
			}
			else
				shader = colorSwap.shader;

		frames = Paths.getSparrowAtlas(name, null, ClientPrefs.gpurendering);
		for (i in 1...3)
		{
			animation.addByPrefix("note0-" + i, "note splash purple " + i, 24, false);
			animation.addByPrefix("note1-" + i, "note splash blue " + i, 24, false);
			animation.addByPrefix("note2-" + i, "note splash green " + i, 24, false);
			animation.addByPrefix("note3-" + i, "note splash red " + i, 24, false);
		}
	}

	override function update(elapsed:Float)
	{
		if (animation.curAnim != null)
			if (animation.curAnim.finished)
				kill();

		super.update(elapsed);
	}
}
