package nme;


import openfl.Assets;


class AssetData {

	
	public static var className = new Map <String, Dynamic> ();
	public static var library = new Map <String, LibraryType> ();
	public static var path = new Map <String, String> ();
	public static var type = new Map <String, AssetType> ();
	
	private static var initialized:Bool = false;
	
	
	public static function initialize ():Void {
		
		if (!initialized) {
			
			path.set ("resources/fire.png", "resources/fire.png");
			type.set ("resources/fire.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/flash_player_32.png", "resources/flash_player_32.png");
			type.set ("resources/flash_player_32.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/hills_0.png", "resources/hills_0.png");
			type.set ("resources/hills_0.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/hills_1.png", "resources/hills_1.png");
			type.set ("resources/hills_1.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/hills_2.png", "resources/hills_2.png");
			type.set ("resources/hills_2.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/hills_3.png", "resources/hills_3.png");
			type.set ("resources/hills_3.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/hills_4.png", "resources/hills_4.png");
			type.set ("resources/hills_4.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/hills_5.png", "resources/hills_5.png");
			type.set ("resources/hills_5.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/HTML5_Badge_32.png", "resources/HTML5_Badge_32.png");
			type.set ("resources/HTML5_Badge_32.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/old/lava.png", "resources/old/lava.png");
			type.set ("resources/old/lava.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/old/lava_glow.png", "resources/old/lava_glow.png");
			type.set ("resources/old/lava_glow.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/old/lava_glow2.png", "resources/old/lava_glow2.png");
			type.set ("resources/old/lava_glow2.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/old/nightly.png", "resources/old/nightly.png");
			type.set ("resources/old/nightly.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/old/nightly2.png", "resources/old/nightly2.png");
			type.set ("resources/old/nightly2.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/old/nightly3.png", "resources/old/nightly3.png");
			type.set ("resources/old/nightly3.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/old/tekkblade2.png", "resources/old/tekkblade2.png");
			type.set ("resources/old/tekkblade2.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/old/tekkblade3.png", "resources/old/tekkblade3.png");
			type.set ("resources/old/tekkblade3.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/old/tekkblade_glow2.png", "resources/old/tekkblade_glow2.png");
			type.set ("resources/old/tekkblade_glow2.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/p_0.png", "resources/p_0.png");
			type.set ("resources/p_0.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/p_1.png", "resources/p_1.png");
			type.set ("resources/p_1.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/p_2.png", "resources/p_2.png");
			type.set ("resources/p_2.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/p_3.png", "resources/p_3.png");
			type.set ("resources/p_3.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/p_4.png", "resources/p_4.png");
			type.set ("resources/p_4.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/p_5.png", "resources/p_5.png");
			type.set ("resources/p_5.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/tekkblade.md2", "resources/tekkblade.md2");
			type.set ("resources/tekkblade.md2", Reflect.field (AssetType, "binary".toUpperCase ()));
			path.set ("resources/tekkblade.png", "resources/tekkblade.png");
			type.set ("resources/tekkblade.png", Reflect.field (AssetType, "image".toUpperCase ()));
			path.set ("resources/uv.png", "resources/uv.png");
			type.set ("resources/uv.png", Reflect.field (AssetType, "image".toUpperCase ()));
			
			
			initialized = true;
			
		}
		
	}
	
	
}





























