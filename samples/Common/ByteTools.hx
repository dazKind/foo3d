package ;

import haxe.io.Bytes;
import haxe.io.BytesOutput;

class ByteTools {
	public static function floats(_floats:Array<Float>):Bytes {
		var out:BytesOutput = new BytesOutput();
		for (f in _floats)
			out.writeFloat(f);
		return out.getBytes();
	}

	public static function uShorts(_ints:Array<Int>):Bytes {
		var out:BytesOutput = new BytesOutput();
		for (i in _ints)
			out.writeUInt16(i);
		return out.getBytes();	
	}
}