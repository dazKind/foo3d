package ;


import haxe.io.Bytes;
import haxe.io.BytesInput;

#if js
import js.html.XMLHttpRequest;
#end

class Binary
{
    public static function load(_url:String):Bytes
    {
#if js
        // parse the binarydata
        var load_binary_resource = function(_url2) {
            var req = new XMLHttpRequest();
            req.open('GET', _url2, false);

            // The following line says we want to receive data as Binary and not as Unicode
            req.overrideMimeType('text/plain; charset=x-user-defined');
            req.send(null);

            if (req.status != 200 && req.readyState != 4)
                throw "invalid data";

            return req.responseText;
        };

        var s = load_binary_resource(_url);

        var a = new Array();

        // utf8-decode
        for( i in 0...s.length ) {
            var c : Int = StringTools.fastCodeAt(s,i);
            a.push(c & 0xff);
        }

        return Bytes.ofData(a);
#elseif flash
        return haxe.Resource.getBytes(_url);
#elseif lime
        return ByteArrayTools.toBytes(lime.utils.Assets.getBytes(_url));
#else
        return sys.io.File.getBytes(_url);
#end
    }
}