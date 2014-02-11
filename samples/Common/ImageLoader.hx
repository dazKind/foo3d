package ;

#if js
import js.html.Image;
#elseif cpp
import format.png.Data;
#end


class ImageLoader {

    public static function loadImage(_src:String, _cb:Dynamic->Void):Void {
#if js
        var img = new Image();
        img.onload = function(_){
            _cb(untyped img);
        };
        img.src = _src;
#elseif flash
        var loader = new flash.display.Loader();
        var request = new flash.net.URLRequest(_src);
        loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, function(_evt:Dynamic) 
        {
            var src = cast(loader.content, flash.display.Bitmap).bitmapData;
            var flipped:flash.display.BitmapData = new flash.display.BitmapData(src.width, src.height, true, 0);
            var matrix = new flash.geom.Matrix( 1, 0, 0, -1, 0, src.height);
            flipped.draw(src, matrix, null, null, null, true);
            _cb(untyped flipped);
        });
        loader.load(request);
#elseif cpp
    #if lime 
        var bytes = ByteArrayTools.toBytes(lime.utils.Assets.getBytes(_src));
        var input = new haxe.io.BytesInput(bytes, 0, bytes.length);
        var img = new format.png.Reader(input).read();
    #else
        var handle = sys.io.File.read(_src, true);
        var img = new format.png.Reader(handle).read();
        handle.close();
    #end
        var header = format.png.Tools.getHeader(img);
        var data:haxe.io.Bytes = format.png.Tools.extract32(img);
        
        // normalize data (flip, bgra -> rgba)
        var tmp:haxe.io.Bytes = haxe.io.Bytes.alloc(data.length);
        var stride:Int = Std.int(data.length/header.height);
        for (y in 0...header.height) {
            var line = data.sub((header.height-y-1)*stride, stride);
            for (x in 0...header.width) {
                var a = line.get(x*4);
                var b = line.get((x*4)+1);
                var c = line.get((x*4)+2);
                line.set(x*4,       c);
                line.set((x*4)+1,   b);
                line.set((x*4)+2,   a);
            }
            tmp.blit(y*stride, line, 0, stride);
        }
        _cb(untyped tmp.getData());
#end
    }
}