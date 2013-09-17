package ;


import haxe.io.Bytes;
import haxe.io.BytesInput;

#if js
import js.html.XMLHttpRequest;
#end

class Binary
{
    public static function readFloat(_d:BytesInput):Float
    {
#if js
        // readByte reads in sequentially(bigendian)
        // flip the bytes to account for that
        var bytes = [];
        bytes.push(_d.readByte());
        bytes.push(_d.readByte());
        bytes.push(_d.readByte());
        bytes.push(_d.readByte());
        if (!_d.bigEndian)
            bytes.reverse();
        var sign = 1 - ((bytes[0] >> 7) << 1);
        var exp = (((bytes[0] << 1) & 0xFF) | (bytes[1] >> 7)) - 127;
        var sig = ((bytes[1] & 0x7F) << 16) | (bytes[2] << 8) | bytes[3];
        if (sig == 0 && exp == -127)
            return 0.0;
        return sign*(1 + Math.pow(2, -23)*sig) * Math.pow(2, exp);
#else
        return _d.readFloat();
#end
    }
    public static function load(_url:String):Bytes
    {
#if js
        // parse the modeldata
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
#else
        return null;
#end
    }
}