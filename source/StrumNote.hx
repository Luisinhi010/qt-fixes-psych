package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class StrumNote extends FlxSprite
{
	private var dirArray:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];

	private var colorSwap:ColorSwap;

	public var resetAnim:Float = 0;

	private var noteData:Int = 0;

	public var direction:Float = 90; // plan on doing scroll directions soon -bb
	public var downScroll:Bool = false; // plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;

	private var player:Int;

	public var texture(default, set):String = null;

	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int, ?skinnote:String = 'NOTE_assets')
	{
		colorSwap = new ColorSwap();
		if (player > 0)
			shader = colorSwap.shader;
		noteData = leData;
		this.player = player;
		this.noteData = leData;
		super(x, y);

		var skin:String = skinnote;
		texture = skin; // Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if (animation.curAnim != null)
			lastAnim = animation.curAnim.name;

		{
			frames = Paths.getSparrowAtlas("Notes/" + texture);
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			antialiasing = ClientPrefs.globalAntialiasing;
			setGraphicSize(Std.int(width * 0.7));

			var lowerCaseAnim:String = dirArray[noteData % 4].toLowerCase();
			animation.addByPrefix('static', 'arrow' + dirArray[noteData % 4]);
			animation.addByPrefix('pressed', lowerCaseAnim + ' press', 24, false);
			animation.addByPrefix('confirm', lowerCaseAnim + ' confirm', 24, false);

			if (texture.startsWith('NOTE_assets_Qt')) // more animations to the qt notes
			{
				switch (Math.abs(noteData))
				{
					case 0:
						animation.addByPrefix('kbconfirm', 'left kbconfirm', 24, false);
					case 1:
						animation.addByPrefix('kbconfirm', 'down kbconfirm', 24, false);
					case 2:
						animation.addByPrefix('kbconfirm', 'up kbconfirm', 24, false);
					case 3:
						animation.addByPrefix('kbconfirm', 'right kbconfirm', 24, false);
				}
			}
		}
		updateHitbox();

		if (lastAnim != null)
			playAnim(lastAnim, true);
	}

	public function postAddedToGroup()
	{
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}

	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
		if (animation.curAnim.name == 'confirm')
			centerOrigin();

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false)
	{
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		if (animation.curAnim == null || animation.curAnim.name == 'static')
		{
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		}
		else
		{
			if (player > 0)
			{
				colorSwap.hue = ClientPrefs.arrowHSV[noteData % 4][0] / 360;
				colorSwap.saturation = ClientPrefs.arrowHSV[noteData % 4][1] / 100;
				colorSwap.brightness = ClientPrefs.arrowHSV[noteData % 4][2] / 100;
			}

			if (animation.curAnim.name == 'confirm')
				centerOrigin();
		}
	}
}
