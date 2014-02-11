package math;

#if flash
import flash.geom.Vector3D;
#end

class Vec3 
{
    public static var LEFT:Vec3     = Vec3.create(1, 0, 0);
    public static var UP:Vec3         = Vec3.create(0, 1, 0);
    public static var FORWARD:Vec3     = Vec3.create(0, 0, 1);
    
    public var x:Float;
    public var y:Float;
    public var z:Float;
    
    public inline static function create(_x:Float, _y:Float, _z:Float):Vec3
    {
        var v:Vec3 = new Vec3();
        v.x = _x;
        v.y = _y;
        v.z = _z;
        return v;
    }
    
    public function new() 
    {
        this.x = 0;
        this.y = 0;
        this.z = 0;
    }
#if flash
    inline public static function createFromVector3D(_v:Vector3D):Vec3
    {
        return Vec3.create(_v.x, _v.y, _v.z);
    }
#end

#if debug
    public inline function toString():String
    {
        return "math.Vec3(" + this.x + ", " + this.y + ", " + this.z + ")";
    }
#end
    
    public static inline function mult(_v0:Vec3, _v1:Vec3):Vec3 // cross product
    {
        var v:Vec3 = new Vec3();
        v.x = _v0.y * _v1.z - _v0.z * _v1.y;
        v.y = _v0.z * _v1.x - _v0.x * _v1.z;
        v.z = _v0.x * _v1.y - _v0.y * _v1.x;
        return v;
    }
    
    public static inline function mult_scalar(_v0:Vec3, _s:Float):Vec3
    {
        var v:Vec3 = new Vec3();
        v.x = _v0.x * _s;
        v.y = _v0.y * _s;
        v.z = _v0.z * _s;
        return v;
    }
    
    public static inline function mult_scalarVect(_v0:Vec3, _v1:Vec3):Vec3
    {
        var v:Vec3 = new Vec3();
        v.x = _v0.x * _v1.x;
        v.y = _v0.y * _v1.y;
        v.z = _v0.z * _v1.z;
        return v;
    }
    
    public static inline function dot(_v0:Vec3, _v1:Vec3):Float // dot product
    {
        return _v0.x * _v1.x + _v0.y * _v1.y + _v0.z * _v1.z;
    }
    
    public static inline function add(_v0:Vec3, _v1:Vec3):Vec3
    {
        var v:Vec3 = new Vec3();
        v.x = _v0.x + _v1.x;
        v.y = _v0.y + _v1.y;
        v.z = _v0.z + _v1.z;
        return v;
    }
    
    public static inline function subtract(_v0:Vec3, _v1:Vec3):Vec3
    {
        var v:Vec3 = new Vec3();
        v.x = _v0.x - _v1.x;
        v.y = _v0.y - _v1.y;
        v.z = _v0.z - _v1.z;
        return v;
    }
    
    public static inline function equals(_v0:Vec3, _v1:Vec3):Bool
    {
        return _v0.x == _v1.x && _v0.y == _v1.y && _v0.z == _v1.z;
    }
    
    public static inline function equals2(_v0:Vec3, _v1:Vec3, _tol:Float):Bool
    {
        return ((Math.abs(_v0.x - _v1.x) < _tol) && (Math.abs(_v0.y - _v1.y) < _tol) && (Math.abs(_v0.z - _v1.z) < _tol));
    }
    
    public static inline function lerp(_v0:Vec3, _v1:Vec3, _t:Float):Vec3
    {
        return Vec3.create(_v0.x + (_v1.x - _v0.x) * _t, _v0.y + (_v1.y - _v0.y) * _t, _v0.z + (_v1.z - _v0.z) * _t);
    }
    
    inline public function clone():Vec3
    {
        return Vec3.create(this.x, this.y, this.z);
    }
    
    public inline function normalize():Float
    {
        var len:Float = this.length();
        this.x /= len;
        this.y /= len;
        this.z /= len;
        return len;
    }
    
    public inline function length():Float { return Math.sqrt(Vec3.dot(this, this)); }
    public inline function lengthSquared():Float { return Vec3.dot(this, this); }
    
    public inline function set(_x:Float, _y:Float, _z:Float):Void
    {
        this.x = _x;
        this.y = _y;
        this.z = _z;
    }
    
#if flash
    inline public function toVector3D():Vector3D
    {
        return new Vector3D(x, y, z);
    }
#end
}