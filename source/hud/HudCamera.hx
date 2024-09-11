package hud;

import flixel.system.FlxAssets.FlxShader;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;
import openfl.display.BitmapData;
import flixel.graphics.frames.FlxFrame;
import flixel.FlxObject;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.FlxCamera;

class HudCamera extends FlxCamera
{
	public var downscroll:Bool = false;

	public override function update(elapsed:Float)
	{
		super.update(elapsed);
		// flipY = downscroll;
	}

	/*public override function drawPixels(?frame:FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
				?smoothing:Bool = false, ?shader:FlxShader):Void
		{
			if (downscroll)
			{
				matrix.scale(1, -1);
				matrix.translate(0, height);
			}
			super.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader);
	}*/
	public override function alterScreenPosition(spr:FlxObject, pos:FlxPoint)
	{
		if (downscroll)
			pos.set(pos.x, height - pos.y - spr.height);

		return pos;
	}
}
