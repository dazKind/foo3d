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
#elseif (flash || nme)
        var loader = new flash.display.Loader();
        var request = new flash.net.URLRequest(_src);
        loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, function(_evt:Dynamic) 
        {
            _cb(untyped loader.content.bitmapData);
        });
        loader.load(request);
#elseif cpp
        var handle = sys.io.File.read(_src, true);
        var d = new format.png.Reader(handle).read();
        var hdr = format.png.Tools.getHeader(d);
        var bytes = extract32(d);
        var data = bytes.getData();
        _cb(untyped data);
        handle.close();
#end
    }

#if cpp
    static inline function filter( rgba : #if flash10 format.tools.MemoryBytes #else haxe.io.Bytes #end, x, y, stride, prev, p ) {
        var b = rgba.get(p - stride);
        var c = x == 0 || y == 0  ? 0 : rgba.get(p - stride - 4);
        var k = prev + b - c;
        var pa = k - prev; if( pa < 0 ) pa = -pa;
        var pb = k - b; if( pb < 0 ) pb = -pb;
        var pc = k - c; if( pc < 0 ) pc = -pc;
        return (pa <= pb && pa <= pc) ? prev : (pb <= pc ? b : c);
    }

    public static function extract32( d : Data ) : haxe.io.Bytes {
        var h = format.png.Tools.getHeader(d);
        var rgba = haxe.io.Bytes.alloc(h.width * h.height * 4);
        var data = null;
        var fullData : haxe.io.BytesBuffer = null;
        for( c in d )
                switch( c ) {
                case CData(b):
                        if( fullData != null )
                                fullData.add(b);
                        else if( data == null )
                                data = b;
                        else {
                                fullData = new haxe.io.BytesBuffer();
                                fullData.add(data);
                                fullData.add(b);
                                data = null;
                        }
                default:
                }
        if( fullData != null )
                data = fullData.getBytes();
        if( data == null )
                throw "Data not found";
        data = format.tools.Inflate.run(data);
        var r = 0, w = 0;
        var alpha_b:Bool=false;
        switch( h.color ) {
        case ColTrue(alpha):
                alpha_b = true;
                if( h.colbits != 8 )
                        throw "Unsupported color mode";
                var width = h.width;
                var stride = (alpha ? 4 : 3) * width + 1;
                if( data.length < h.height * stride ) throw "Not enough data";

                #if flash10
                var bytes = data.getData();
                var start = h.height * stride;
                bytes.length = start + h.width * h.height * 4;
                if( bytes.length < 1024 ) bytes.length = 1024;
                flash.Memory.select(bytes);
                var realData = data, realRgba = rgba;
                var data = format.tools.MemoryBytes.make(0);
                var rgba = format.tools.MemoryBytes.make(start);
                #end
                //ABRG
                for( y in 0...h.height ) {
                        var f = data.get(r++);
                        //trace("f:"+f);
                        switch( f ) {
                        case 0://Each byte is unchanged.
                                if( alpha )
                                        for( x in 0...width ) {
                                                rgba.set(w++,data.get(r+0));//R
                                                rgba.set(w++,data.get(r+1));//G
                                                rgba.set(w++,data.get(r+2));//B
                                                rgba.set(w++,data.get(r+3));//A
                                                r += 4;
                                        }
                                else
                                        for( x in 0...width ) {
                                                rgba.set(w++,data.get(r+0));//R
                                                rgba.set(w++,data.get(r+1));//G
                                                rgba.set(w++,data.get(r+2));//B
                                                rgba.set(w++,0xFF);//A
                                                r += 3;
                                        }
                        case 1://Each byte is replaced with the difference between it and the 'corresponding byte' to its left.
                                var cr = 0, cg = 0, cb = 0, ca = 0;
                                if( alpha )
                                        for( x in 0...width ) {
                                                cr += data.get(r + 0);  rgba.set(w++,cr);//R
                                                cg += data.get(r + 1);  rgba.set(w++,cg);//G
                                                cb += data.get(r + 2);  rgba.set(w++,cb);//B
                                                ca += data.get(r + 3);  rgba.set(w++,ca);//A
                                                r += 4;
                                        }
                                else
                                        for( x in 0...width ) {
                                                cr += data.get(r + 0);  rgba.set(w++,cr);//R
                                                cg += data.get(r + 1);  rgba.set(w++,cg);//G
                                                cb += data.get(r + 2);  rgba.set(w++,cb);//B
                                                rgba.set(w++, 0xFF);//A
                                                r += 3;
                                        }
                        case 2://Each byte is replaced with the difference between it and the byte above it (in the previous row, as it was before filtering).
                                var stride = y == 0 ? 0 : width * 4;
                                if( alpha )
                                        for( x in 0...width ) {
                                                rgba.set(w, data.get(r + 0) + rgba.get(w - stride));    w++;//R
                                                rgba.set(w, data.get(r + 1) + rgba.get(w - stride));    w++;//G
                                                rgba.set(w, data.get(r + 2) + rgba.get(w - stride));    w++;//B
                                                rgba.set(w, data.get(r + 3) + rgba.get(w - stride));    w++;//A
                                                r += 4;
                                        }
                                else
                                        for( x in 0...width ) {
                                                rgba.set(w, data.get(r + 0) + rgba.get(w - stride));    w++;//R
                                                rgba.set(w, data.get(r + 1) + rgba.get(w - stride));    w++;//G
                                                rgba.set(w, data.get(r + 2) + rgba.get(w - stride));    w++;//B
                                                rgba.set(w++,0xFF);//A
                                                r += 3;
                                        }
                        case 3://Each byte is replaced with the difference between it and the average of the corresponding bytes to its left and above it, truncating any fractional part.
                                var cr = 0, cg = 0, cb = 0, ca = 0;
                                var stride = y == 0 ? 0 : width * 4;
                                if( alpha )
                                        for( x in 0...width ) {
                                                cr = (data.get(r + 0) + ((cr + rgba.get(w - stride)) >> 1)) & 0xFF; rgba.set(w++, cr);//R
                                                cg = (data.get(r + 1) + ((cg + rgba.get(w - stride)) >> 1)) & 0xFF; rgba.set(w++, cg);//G
                                                cb = (data.get(r + 2) + ((cb + rgba.get(w - stride)) >> 1)) & 0xFF; rgba.set(w++, cb);//B
                                                ca = (data.get(r + 3) + ((ca + rgba.get(w - stride)) >> 1)) & 0xFF; rgba.set(w++, ca);//A
                                                r += 4;
                                        }
                                else
                                        for( x in 0...width ) {
                                                cr = (data.get(r + 0) + ((cr + rgba.get(w - stride)) >> 1)) & 0xFF; rgba.set(w++, cr);//R
                                                cg = (data.get(r + 1) + ((cg + rgba.get(w - stride)) >> 1)) & 0xFF; rgba.set(w++, cg);//G
                                                cb = (data.get(r + 2) + ((cb + rgba.get(w - stride)) >> 1)) & 0xFF; rgba.set(w++, cb);//B
                                                rgba.set(w++, 0xFF);//A
                                                r += 3;
                                        }
                        case 4://Each byte is replaced with the difference between it and the Paeth predictor of the corresponding bytes to its left, above it, and to its upper left.
                                var stride = width * 4;
                                var cr = 0, cg = 0, cb = 0, ca = 0;
                                if( alpha )
                                        for( x in 0...width ) {
                                                cr = (filter(rgba, x, y, stride, cr, w) + data.get(r + 0)) & 0xFF; rgba.set(w++, cr);//R
                                                cg = (filter(rgba, x, y, stride, cg, w) + data.get(r + 1)) & 0xFF; rgba.set(w++, cg);//G
                                                cb = (filter(rgba, x, y, stride, cb, w) + data.get(r + 2)) & 0xFF; rgba.set(w++, cb);//B
                                                ca = (filter(rgba, x, y, stride, ca, w) + data.get(r + 3)) & 0xFF; rgba.set(w++, ca);//A
                                                r += 4;
                                        }
                                else
                                        for( x in 0...width ) {
                                                cr = (filter(rgba, x, y, stride, cr, w) + data.get(r + 0)) & 0xFF; rgba.set(w++, cr);//R
                                                cg = (filter(rgba, x, y, stride, cg, w) + data.get(r + 1)) & 0xFF; rgba.set(w++, cg);//G
                                                cb = (filter(rgba, x, y, stride, cb, w) + data.get(r + 2)) & 0xFF; rgba.set(w++, cb);//B
                                                rgba.set(w++, 0xFF);//A
                                                r += 3;
                                        }
                        default:
                                throw "Invalid filter "+f;
                        }
                }

                #if flash10
                var b = realRgba.getData();
                b.position = 0;
                b.writeBytes(realData.getData(), start, h.width * h.height * 4);
                #end

        default:
                throw "Unsupported color mode "+Std.string(h.color);
        }
        return rgba;
    }
#end
}