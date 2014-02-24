package math;

class MathUtils
{
    inline public static var DEG2RAD:Float = 0.017453292519943295769236907684886;

    inline public static var HALF_DEG2RAD:Float = 0.0087266462599716478846184538424431;

    inline public static var RAD2DEG:Float = 57.295779513082320876798154814105;

    inline public static var PIHALF = 1.5707963267948966;
    
    inline public static function toScreen(_v:Vec3, _width:Float, _height:Float):Vec3
    {
        var v:Vec3 = new Vec3();
        v.x = ((_width - 1) * (_v.x + 1)) * 0.5;
        v.y = _height - (((_height - 1) * (_v.y + 1)) * 0.5);
        v.z = _v.z;
        return v;
    }
    
    inline public static function toScreenX(_x:Float, _width:Float):Float
    {
        return ((_width - 1) * (_x + 1)) * 0.5;
    }
    
    inline public static function toScreenY(_y:Float, _height:Float):Float
    {
        return _height - (((_height - 1) * (_y + 1)) * 0.5);
    }
    
    inline public static function getRelativeYaw(vDir:Vec3, m:Mat44):Float {
        // front component vector
        var fFront:Float =
             vDir.x * m.rawData[2]
            -vDir.y * m.rawData[6]
            -vDir.z * m.rawData[10];
        // left component
        var fLeft:Float =
             vDir.x * m.rawData[0]
            -vDir.y * m.rawData[4]
            -vDir.z * m.rawData[8];
        // relative heading is arctan of angle between front and left
        return Math.atan2(fLeft, fFront);
    }
    
    inline public static function getRelativePitch(vDir:Vec3, m:Mat44):Float {
        // get front component of vector
        var fFront:Float =
             vDir.x * m.rawData[2]
            -vDir.y * m.rawData[6]
            -vDir.z * m.rawData[10];
        // get up component of vector
        var fUp:Float = 
            -vDir.x * m.rawData[1]
            +vDir.y * m.rawData[5]
            +vDir.z * m.rawData[9];
        // relative pitch is arctan of angle between front and up
        return Math.atan2(fUp, fFront);
    }
    
    inline public static function getRelativeRoll(vDir:Vec3, m:Mat44):Float {
        // get left component of vector
        var fLeft:Float = 
             vDir.x * m.rawData[0]
            -vDir.y * m.rawData[4]
            -vDir.z * m.rawData[8];
        // get up component of vector
        var fUp:Float = 
            -vDir.x * m.rawData[1]
            +vDir.y * m.rawData[5]
            +vDir.z * m.rawData[9];
        // relative yaw is arctan of angle between left and up
        return Math.atan2(fUp, fLeft);
    }
    
    inline public static function polarToCartesian(_pol:Vec3):Vec3
    {
        return Vec3.create(
                _pol.x * Math.sin(_pol.z + PIHALF) * Math.sin(_pol.y),
                _pol.x * Math.cos(_pol.z + PIHALF),
                _pol.x * Math.sin(_pol.z + PIHALF) * Math.cos(_pol.y)
            );
    }
    
    inline public static function cartesianToPolar(_cart:Vec3):Vec3
    {
        return Vec3.create(
                Math.sqrt(_cart.x * _cart.x + _cart.y * _cart.y + _cart.z * _cart.z),
                Math.atan2(_cart.z, _cart.x),
                Math.acos(_cart.y / _cart.x) - PIHALF
            );
    }
    
}