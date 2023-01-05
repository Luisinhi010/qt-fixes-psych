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

	public var player:Int;

	public var multiplier:Float = 0;

	public var texture(default, set):String = null;

	public function set_texture(value:String):String
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

		texture = skinnote; // Load texture and anims

		scrollFactor.set();
		multiplier = MusicBeatState.multAnims ? PlayState.instance.playbackRate : 1;
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if (animation.curAnim != null)
			lastAnim = animation.curAnim.name;

		var name:String = 'Notes/' + texture;
		if (!Paths.fileExists('images/' + name + '.png', IMAGE, false, 'shared'))
			name = texture;
		if (!Paths.fileExists('images/' + name + '.png', IMAGE, false, 'shared'))
			name = 'Notes/NOTE_assets';

		frames = Paths.getSparrowAtlas(name, null, ClientPrefs.gpurendering);
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
			animation.addByPrefix('kbconfirm', lowerCaseAnim + ' kbconfirm', 24, false);

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
			resetAnim -= elapsed * multiplier;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
		if (animation.curAnim.name == 'confirm' || animation.curAnim.name == 'kbconfirm')
			centerOrigin();

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false)
	{
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		if (animation.curAnim == null || animation.curAnim.name == 'static' || animation.curAnim.name == 'kbconfirm')
		{
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		}
		else
		{
			if (player > 0 && (noteData > -1 && noteData < ClientPrefs.arrowHSV.length))
			{
				colorSwap.hue = ClientPrefs.arrowHSV[noteData][0] / 360;
				colorSwap.saturation = ClientPrefs.arrowHSV[noteData][1] / 100;
				colorSwap.brightness = ClientPrefs.arrowHSV[noteData][2] / 100;
			}

			if (animation.curAnim.name == 'confirm' || animation.curAnim.name == 'kbconfirm')
				centerOrigin();
		}
	}
}
