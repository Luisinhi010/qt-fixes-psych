package lore; // as you can see, theres more options here than have in VisualUiSubState.hx, thats because i'm dumb :D -Luis

// og https://github.com/sayofthelor/lore-engine/blob/main/source/lore/Colorblind.hx
import flixel.FlxG;
import openfl.filters.ColorMatrixFilter;
import openfl.filters.BitmapFilter;

// author @sayofthelor
class Colorblind
{
	public static var filters:Array<BitmapFilter> = []; // the filters the game has active
	public static var gameFilters:Map<String, {filter:BitmapFilter, ?onUpdate:Void->Void}> = [
		"INVERT" => {
			var matrix:Array<Float> = [
				-1,  0,  0, 0, 255,
				 0, -1,  0, 0, 255,
				 0,  0, -1, 0, 255,
				 0,  0,  0, 1,   0,
			];
			{filter: new ColorMatrixFilter(matrix)}
		},
		"BLACK & WHITE" => {
			var rc:Float = 1 / 3;
			var gc:Float = 1 / 2;
			var bc:Float = 1 / 6;
			var matrix:Array<Float> = [rc, gc, bc, 0, 0, rc, gc, bc, 0, 0, rc, gc, bc, 0, 0, 0, 0, 0, 1, 0];
			{filter: new ColorMatrixFilter(matrix)}
		},
		"DEUTERANOPIA" => {
			var matrix:Array<Float> = [
				0.43, 0.72, -.15, 0, 0,
				0.34, 0.57, 0.09, 0, 0,
				-.02, 0.03,    1, 0, 0,
				   0,    0,    0, 1, 0,
			];
			{filter: new ColorMatrixFilter(matrix)}
		},
		"PROTANOPIA" => {
			var matrix:Array<Float> = [
				0.20, 0.99, -.19, 0, 0,
				0.16, 0.79, 0.04, 0, 0,
				0.01, -.01,    1, 0, 0,
				   0,    0,    0, 1, 0,
			];
			{filter: new ColorMatrixFilter(matrix)}
		},
		"TRITANOPIA" => {
			var matrix:Array<Float> = [
				0.97, 0.11, -.08, 0, 0,
				0.02, 0.82, 0.16, 0, 0,
				0.06, 0.88, 0.18, 0, 0,
				   0,    0,    0, 1, 0,
			];
			{filter: new ColorMatrixFilter(matrix)}
		}
	];

	public static function updateFilter()
	{
		filters = [];
		FlxG.game.setFilters(filters);
		if (ClientPrefs.colorblindFilter != "NONE" && gameFilters.get(ClientPrefs.colorblindFilter) != null)
		{
			var realFilter = gameFilters.get(ClientPrefs.colorblindFilter).filter;
			if (realFilter != null)
				filters.push(realFilter);
		}
		FlxG.game.setFilters(filters);
	}
}
