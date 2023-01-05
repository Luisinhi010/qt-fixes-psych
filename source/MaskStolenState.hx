package; // https://stackoverflow.com/questions/48075991/is-there-a-way-to-apply-an-alpha-mask-to-a-flxcamera

import flixel.tweens.FlxTween;
import flash.geom.Matrix;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import openfl.geom.Point;

using flixel.util.FlxSpriteUtil;

class MaskStolenState extends FlxState
{
	static inline var CAMERA_SIZE = 100;

	var maskedCamera:FlxCamera;
	var cameraSprite:FlxSprite;
	var mask:FlxSprite;
	var selectedSomethin:Bool = false;

	override public function create():Void
	{
		super.create();
		/*@:privateAccess {
				FlxG.width = 192;
				FlxG.height = 244;
			}
			FlxG.resizeWindow(192, 244);
			MusicBeatState.changedRes = true; */

		maskedCamera = new FlxCamera(0, 0, CAMERA_SIZE, CAMERA_SIZE);
		maskedCamera.bgColor = FlxColor.WHITE;
		maskedCamera.scroll.x = 50;
		FlxG.cameras.add(maskedCamera);

		// this is a bit of a hack - we need this camera to be rendered so we can copy the content
		// onto the sprite, but we don't want to actually *see* it, so just move it off-screen
		maskedCamera.x = FlxG.width;

		cameraSprite = new FlxSprite();
		cameraSprite.makeGraphic(CAMERA_SIZE, CAMERA_SIZE, FlxColor.WHITE, true);
		cameraSprite.x = 50;
		cameraSprite.y = 100;
		cameraSprite.cameras = [FlxG.camera];
		add(cameraSprite);

		mask = new FlxSprite(FlxGraphic.fromClass(GraphicLogo));

		var redSquare = new FlxSprite(0, 25);
		redSquare.makeGraphic(50, 50, FlxColor.RED);
		add(redSquare);
		FlxTween.tween(redSquare, {x: 150}, 1, {type: FlxTweenType.PINGPONG});
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var pixels = cameraSprite.pixels;
		if (FlxG.renderBlit)
			pixels.copyPixels(maskedCamera.buffer, maskedCamera.buffer.rect, new Point());
		else
			pixels.draw(maskedCamera.canvas);

		cameraSprite.alphaMaskFlxSprite(mask, cameraSprite);

		if (!selectedSomethin)
		{
			if (FlxG.keys.justPressed.ESCAPE)
				MusicBeatState.switchState(new MainMenuState());
			selectedSomethin = true;
		}
	}
}
