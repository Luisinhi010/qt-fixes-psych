package;

import flixel.FlxG;
import flixel.system.FlxAssets.FlxShader;

class CustomBlueShader // stoled from yoshi engine termination port (by yoshi crafter)
{
	public var shader(default, null):BlueShader = new BlueShader();

	public function new()
	{
		shader.enabled.value = [false];
		shader.diffX.value = [-0.01];
		shader.diffX2.value = [0.01];
		shader.diffY.value = [-0.01];
		shader.r.value = [0];
		shader.g.value = [0.1];
		shader.b.value = [1];
		shader.a.value = [0.75];
		shader.passes.value = [50];
		shader.clipRect.value = [0, 0, 1, 1];
	}
}

class BlueShader extends FlxFixedShader
{
	@:glFragmentSource('#pragma header

	uniform bool enabled=true;
	
	uniform float diffX=0;
	uniform float diffY=0;
	uniform float diffX2=0;
	uniform float diffY2=0;
	
	uniform float r=0;
	uniform float g=0;
	uniform float b=0;
	uniform float a=0;
	
	uniform int passes=10;
	
	uniform vec4 clipRect=vec4(0,0,1,1);
	
	// uniform float alphaReturn = 0;
	
	void main(){
		vec4 color=flixel_texture2D(bitmap,openfl_TextureCoordv);
		if(!enabled){
			gl_FragColor=color;
			return;
		}
		if(color.a<.1){
			gl_FragColor=vec4(0.,0.,0.,0.);
		}else{
			/*
			vec2 diff = vec2(diffX, diffY);
			vec4 diffColor = flixel_texture2D(bitmap, openfl_TextureCoordv + diff);
			*/
			
			// shadow alpha
			float alpha = 0;
			for(int i = 1; i < passes; ++i) {
				float fPasses = passes;
				float distX = (diffX2 - diffX) * (i / fPasses) + diffX;
				float distY = (diffY2 - diffY) * (i / fPasses) + diffY;
				float pixelX = openfl_TextureCoordv.x + (distX * (i / fPasses));
				float pixelY = openfl_TextureCoordv.y + (distY * (i / fPasses));
				float a = 1.0 * ((fPasses - i) / fPasses);
				if (pixelX > clipRect.r && pixelX < clipRect.r + clipRect.b && pixelY > clipRect.g && pixelY < clipRect.g + clipRect.a) {
					float al = flixel_texture2D(bitmap, vec2(pixelX, pixelY)).a;
					a = (1.0 - (al / color.a)) * abs((fPasses - i - (abs(diffX2 - diffX) / fPasses)) / (fPasses * 2));
				}
				if (alpha < a) alpha = a;
			}
			/*
			for(int i=1;i<10;++i) {
				float pixelX = openfl_TextureCoordv.x + (diffX * (i / 5));
				float pixelY = openfl_TextureCoordv.y + (diffY * (i / 5));
				float a = 0;
				if (pixelX > clipRect.r && pixelX < clipRect.r + clipRect.b && pixelY > clipRect.g && pixelY < clipRect.g + clipRect.a) {
					float alpha = flixel_texture2D(bitmap, vec2(pixelX, pixelY)).a;
					
					a = alpha;
				}
				if (a < alpha) alpha = a;
			}
			*/
			
			float shadowAlpha=(alpha)*a;
			// float shadowAlpha = (1 - (diffColor.a)) * a;
			
			float nr=(color.r*(1-shadowAlpha))+(r*shadowAlpha);
			float ng=(color.g*(1-shadowAlpha))+(g*shadowAlpha);
			float nb=(color.b*(1-shadowAlpha))+(b*shadowAlpha);
			float na=color.a;
			// alphaReturn = shadowAlpha;
			gl_FragColor=vec4(nr,ng,nb,na);
		}
	}')
	public function new()
	{
		super();
	}
}
