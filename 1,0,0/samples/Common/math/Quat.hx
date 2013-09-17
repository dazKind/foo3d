/**
 * ...
 * @author Michael
 */

package math;
#if flash
import flash.geom.Vector3D;
#end

class Quat 
{
    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var w:Float;
    
    public static inline function create(_x:Float, _y:Float, _z:Float, _w:Float):Quat
    {
        var q:Quat = new Quat();
        q.x = _x;
        q.y = _y;
        q.z = _z;
        q.w = _w;
        return q;
    }
    
    public static inline function createFromAxisAngle(_x:Float, _y:Float, _z:Float, _angle:Float):Quat
    {
        var q:Quat = new Quat();
        var hAng:Float = _angle * MathUtils.HALF_DEG2RAD;
        var fSin:Float = Math.sin(hAng);
        q.x = _x * fSin;
        q.y = _y * fSin;
        q.z = _z * fSin;
        q.w = Math.cos(hAng);
        return q;
    }
    
    public static inline function createFromEulers(_eulerX:Float, _eulerY:Float, _eulerZ:Float):Quat
    {
        var h:Float = _eulerY * MathUtils.HALF_DEG2RAD;
        var a:Float = _eulerZ * MathUtils.HALF_DEG2RAD;
        var b:Float = _eulerX * MathUtils.HALF_DEG2RAD;
        
        var c1:Float = Math.cos(h);
        var s1:Float = Math.sin(h);
        var c2:Float = Math.cos(a);
        var s2:Float = Math.sin(a);
        var c3:Float = Math.cos(b);
        var s3:Float = Math.sin(b);
        var c1c2:Float = c1*c2;
        var s1s2:Float = s1*s2;
        var q:Quat = Quat.create(
            c1c2*s3 + s1s2*c3,
            s1*c2*c3 + c1*s2*s3,
            c1*s2*c3 - s1*c2*s3,
            c1c2*c3 - s1s2*s3
        );
        q.normalize();
        return q;
    }
    
    inline public static function createFromMat44(_mat:Mat44):Quat
    {
        var q = new Quat();
        var ftrace:Float = _mat.rawData[0] + _mat.rawData[5] + _mat.rawData[10];
        var froot:Float = 0;

        if ( ftrace > 0.0 )
        {
            // |w| > 1/2, may as well choose w > 1/2
            froot = Math.sqrt(ftrace + 1.0);  // 2w
            q.w = 0.5 * froot;
            froot = 0.5 / froot;  // 1/(4w)
            q.x = (_mat.rawData[9] - _mat.rawData[6]) * froot;
            q.y = (_mat.rawData[2] - _mat.rawData[8]) * froot;
            q.z = (_mat.rawData[4] - _mat.rawData[1]) * froot;
        }
        else
        {
            // |w| <= 1/2
            var s_iNext:Array<Int> = [1, 2, 0];
            var i:Int = 0;
            if ( _mat.rawData[5] > _mat.rawData[0] )
                i = 1;
            if ( _mat.rawData[10] > _mat.get(i, i) )
                i = 2;
            var j:Int = s_iNext[i];
            var k:Int = s_iNext[j];

            froot = Math.sqrt(_mat.get(i, i) - _mat.get(j, j) - _mat.get(k, k) + 1.0);

            var apkQuat:Array<Float> = [ 0.0, 0.0, 0.0 ];
            apkQuat[i] = 0.5 * froot;
            
            froot = 0.5 / froot;
            
            q.w = (_mat.get(k, j)-_mat.get(j, k))*froot;
            apkQuat[j] = (_mat.get(j, i)+_mat.get(i, j))*froot;
            apkQuat[k] = (_mat.get(k, i) + _mat.get(i, k)) * froot;
            q.x = apkQuat[0];
            q.y = apkQuat[1];
            q.z = apkQuat[2];
        }
        return q;
    }
    
    public function new() 
    {
        this.x = 0;
        this.y = 0;
        this.z = 0;
        this.w = 1;
    }

#if debug
    public inline function toString():String
    {
        return "math.Quat(" + this.x + ", " + this.y  + ", " + this.z + ", " + this.w + ")";
    }        
#end

    // operators return a new quat!
    public static inline function mult(_q0:Quat, _q1:Quat):Quat
    {
        var q:Quat = new Quat();

        q.x = _q0.y * _q1.z - _q0.z * _q1.y + _q1.x * _q0.w + _q0.x * _q1.w;
        q.y = _q0.z * _q1.x - _q0.x * _q1.z + _q1.y * _q0.w + _q0.y * _q1.w;
        q.z = _q0.x * _q1.y - _q0.y * _q1.x + _q1.z * _q0.w + _q0.z * _q1.w;
        q.w = _q0.w * _q1.w - (_q0.x * _q1.x + _q0.y * _q1.y + _q0.z * _q1.z);
        
        return q;
    }
            
    inline public static function add(_q0:Quat, _q1:Quat):Quat
    {
        var q:Quat = new Quat();
        q.x = _q0.x + _q1.x;
        q.y = _q0.y + _q1.y;
        q.z = _q0.z + _q1.z;
        q.w = _q0.w + _q1.w;
        return q;
    }
    
    inline public static function subtract(_q0:Quat, _q1:Quat):Quat
    {
        var q:Quat = new Quat();
        q.x = _q0.x - _q1.x;
        q.y = _q0.y - _q1.y;
        q.z = _q0.z - _q1.z;
        q.w = _q0.w - _q1.w;
        return q;
    }
    
    public static inline function dot(_v0:Quat, _v1:Quat):Float // dot product
    {
        return _v0.x * _v1.x + _v0.y * _v1.y + _v0.z * _v1.z + _v0.w * _v1.w;
    }
    
    inline public static function slerp(_q0:Quat, _q1:Quat, _t:Float):Quat
    {
        var res:Quat = _q1.clone();
        
        var cTheta:Float = _q0.x * _q1.x + _q0.y * _q1.y + _q0.z * _q1.z + _q0.w * _q1.w;
        
        if (cTheta < 0)
        {
            cTheta = -cTheta;
            res.x = -_q1.x;
            res.y = -_q1.y;
            res.z = -_q1.z;
            res.w = -_q1.w;
        }
        
        var scale0:Float = 1 - _t;
        var scale1:Float = _t;
        
        if (1 - cTheta > 0.001)
        {
            var theta:Float = Math.acos(cTheta);
            var sinTheta:Float = Math.sin(theta);
            scale0 = Math.sin(((1 - _t) * theta) / sinTheta);
            scale1 = Math.sin((_t * theta) / sinTheta);
        }
        
        return Quat.create(
            _q0.x * scale0 + res.x * scale1,
            _q0.y * scale0 + res.y * scale1,
            _q0.z * scale0 + res.z * scale1,
            _q0.w * scale0 + res.w * scale1
        );
    }
    
    inline public static function nlerp(_q0:Quat, _q1:Quat, _t:Float):Quat
    {
        var res:Quat = null;
        var cTheta:Float = _q0.x * _q1.x + _q0.y * _q1.y + _q0.z * _q1.z + _q0.w * _q1.w;
        
        if (cTheta < 0)
            res = Quat.create(
                _q0.x + ( -_q1.x - _q0.x) * _t, 
                _q0.y + ( -_q1.y - _q0.y) * _t,
                _q0.z + ( -_q1.z - _q0.z) * _t,
                _q0.w + ( -_q1.w - _q0.w) * _t
            );
        else
            res = Quat.create(
                _q0.x + (_q1.x - _q0.x) * _t, 
                _q0.y + (_q1.y - _q0.y) * _t,
                _q0.z + (_q1.z - _q0.z) * _t,
                _q0.w + (_q1.w - _q0.w) * _t
            );
        
        var inv:Float = 1.0 / (res.x * res.x + res.y * res.y + res.z * res.z + res.w * res.w);
        res.x *= inv;
        res.y *= inv;
        res.z *= inv;
        res.w *= inv;
        return res;
    }
    
    public inline function normalize():Float
    {
        var len:Float = Math.sqrt(x * x + y * y + z * z + w * w);
        this.x /= len;
        this.y /= len;
        this.z /= len;
        this.w /= len;
        return len;
    }
    
    inline public function clone():Quat
    {
        return Quat.create(this.x, this.y, this.z, this.w);
    }
    
    public inline function inverted():Quat
    {
        var q:Quat = null;
        var norm:Float = w*w+x*x+y*y+z*z;
        if ( norm > 0.0 )
        {
            var invNorm:Float = 1.0/norm;
            q = Quat.create(-x*invNorm,-y*invNorm,-z*invNorm, w*invNorm);
        }
        return q;
    }
    
    inline public function transform(_v:Vec3):Vec3
    {
        var qvec:Vec3 = new Vec3();
        qvec.x = this.x;
        qvec.y = this.y;
        qvec.z = this.z;
        var uv:Vec3 = Vec3.mult(qvec, _v);
        var uuv:Vec3 = Vec3.mult(qvec, uv);
        
        uv = Vec3.mult_scalar(uv, 2 * this.w);
        uuv = Vec3.mult_scalar(uuv, 2);
        
        return Vec3.add(_v, Vec3.add(uv, uuv));
    }
    
    inline public static function rotateX(_a:Float):Quat
    {
        var a:Float = _a * MathUtils.HALF_DEG2RAD;
        var q:Quat = new Quat();
        q.x = Math.sin(a);
        q.y = q.z = 0;
        q.w = Math.cos(a);
        return q;
    }
    
    inline public static function rotateY(_a:Float):Quat
    {
        var a:Float = _a * MathUtils.HALF_DEG2RAD;
        var q:Quat = new Quat();
        q.y = Math.sin(a);
        q.x = q.z = 0;
        q.w = Math.cos(a);
        return q;
    }
    
    inline public static function rotateZ(_a:Float):Quat
    {
        var a:Float = _a * MathUtils.HALF_DEG2RAD;
        var q:Quat = new Quat();
        q.z = Math.sin(a);
        q.x = q.y = 0;
        q.w = Math.cos(a);
        return q;
    }
    
    inline public function getPitch(_reprojectAxis:Bool):Float // x
    {
        var res:Float = 0;
        if (_reprojectAxis)
        {
            var fTx:Float  = 2.0*x;
            var fTy:Float  = 2.0*y;
            var fTz:Float  = 2.0*z;
            var fTwx:Float = fTx*w;
            var fTxx:Float = fTx*x;
            var fTyz:Float = fTz*y;
            var fTzz:Float = fTz*z;
            res = Math.atan2(fTyz+fTwx, 1.0-(fTxx+fTzz));
        }
        else
            res = Math.atan2(2*(y*z + w*x), w*w - x*x - y*y + z*z);
        return res;
    }
    
    inline public function getYaw(_reprojectAxis:Bool):Float // y
    {
        var res:Float = 0;
        if (_reprojectAxis)
        {
            var fTx:Float  = 2.0*x;
            var fTy:Float  = 2.0*y;
            var fTz:Float  = 2.0*z;
            var fTwy:Float = fTy*w;
            var fTxx:Float = fTx*x;
            var fTxz:Float = fTz*x;
            var fTyy:Float = fTy*y;
            res = Math.atan2(fTxz+fTwy, 1.0-(fTxx+fTyy));
        }
        else
            res = Math.asin(-2*(x*z - w*y));
        return res;
    }
    
    inline public function getRoll(_reprojectAxis:Bool):Float // z
    {
        var res:Float = 0;
        if (_reprojectAxis)
        {
            var fTx:Float  = 2.0*x;
            var fTy:Float  = 2.0*y;
            var fTz:Float  = 2.0*z;
            var fTwz:Float = fTz*w;
            var fTxy:Float = fTy*x;
            var fTyy:Float = fTy*y;
            var fTzz:Float = fTz * z;
            res = Math.atan2(fTxy + fTwz, 1.0 - (fTyy + fTzz));
        }
        else
            res = Math.atan2(2*(x*y + w*z), w*w + x*x - y*y - z*z);
        return res;
    }
    
#if flash
    inline public function toVector3D():Vector3D
    {
        return new Vector3D(x, y, z, w);
    }
#end
}