package math;

#if flash
import flash.geom.Matrix3D;
#end

/*
    0 = 11
    1 = 12
    2 = 13
    3 = 14

    4 = 21
    5 = 22
    6 = 23
    7 = 24

    8 = 31
    9 = 32
    10 = 33
    11 = 34

    12 = 41
    13 = 42
    14 = 43
    15 = 44
    
    
    
    
    
    0 = 00
    1 = 01
    2 = 02
    3 = 03

    4 = 10
    5 = 11
    6 = 12
    7 = 13

    8 = 20
    9 = 21
    10 = 22
    11 = 23

    12 = 30
    13 = 31
    14 = 32
    15 = 33
*/

class Mat44
{
    public var rawData:Array<Float>;
    
    public static inline function create(_m:Array<Float> = null):Mat44
    {
        var m:Mat44 = new Mat44();
        if (_m != null)
            m.rawData = _m;
        return m;
    }
    
    public function new() 
    {
        rawData = new Array<Float>();
        rawData[0] = 1;
        rawData[1] = 0;
        rawData[2] = 0;
        rawData[3] = 0;
        
        rawData[4] = 0;
        rawData[5] = 1;
        rawData[6] = 0;
        rawData[7] = 0;
        
        rawData[8] = 0;
        rawData[9] = 0;
        rawData[10] = 1;
        rawData[11] = 0;
        
        rawData[12] = 0;
        rawData[13] = 0;
        rawData[14] = 0;
        rawData[15] = 1;
    }

#if debug
    public inline function toString():String
    {
        return "math.Mat44:\n" + 
            rawData[0]+ " " +rawData[1]+ " " +rawData[2]+ " " +rawData[3]+ "\n" +
            rawData[4]+ " " +rawData[5]+ " " +rawData[6]+ " " +rawData[7]+ "\n" +
            rawData[8]+ " " +rawData[9]+ " " +rawData[10]+ " " +rawData[11]+ "\n" +
            rawData[12] + " " +rawData[13] + " " +rawData[14] + " " +rawData[15];
    }
#end


#if flash
    inline public static function createFromMatrix3D(_m:Matrix3D):Mat44
    {
        var m:Mat44 = new Mat44();
        m.rawData[0] = _m.rawData[0];
        m.rawData[1] = _m.rawData[1];
        m.rawData[2] = _m.rawData[2];
        m.rawData[3] = _m.rawData[3];
        m.rawData[4] = _m.rawData[4];
        m.rawData[5] = _m.rawData[5];
        m.rawData[6] = _m.rawData[6];
        m.rawData[7] = _m.rawData[7];
        m.rawData[8] = _m.rawData[8];
        m.rawData[9] = _m.rawData[9];
        m.rawData[10] = _m.rawData[10];
        m.rawData[11] = _m.rawData[11];
        m.rawData[12] = _m.rawData[12];
        m.rawData[13] = _m.rawData[13];
        m.rawData[14] = _m.rawData[14];
        m.rawData[15] = _m.rawData[15];
        return m;
    }
#end

    public static inline function createOrthoLH(_l:Float, _r:Float, _t:Float, _b:Float, _n:Float, _f:Float):Mat44
    {
        var m:Mat44 = new Mat44();
        
        m.rawData[0] = 2 / (_r - _l);
        m.rawData[5] = 2 / (_t - _b);
        m.rawData[10] = -2 / (_f - _n);
        m.rawData[12] = -(_r + _l) / (_r - _l);
        m.rawData[13] = -(_t + _b) / (_t - _b);
        m.rawData[14] = -(_f + _n) / (_f - _n);

        return m;
    }
    
    public static inline function createPerspLH(_fov:Float, _aspect:Float, _nz:Float, _fz:Float):Mat44
    {
        var ymax:Float = _nz * Math.tan(MathUtils.HALF_DEG2RAD * _fov);
        var xmax:Float = ymax * _aspect;
        
        return createPerspOffCenterLH(xmax, ymax, _nz, _fz);
    }
    
    public static inline function createPerspOffCenterLH(    _maxX:Float, _maxY:Float, 
                                                            _nz:Float, _fz:Float):Mat44
    {
        var m:Mat44 = new Mat44();
        
        m.rawData[0] = 2 * _nz / (_maxX * 2);
        m.rawData[5] = 2 * _nz / (_maxY * 2);
        m.rawData[8] = 0; // ???
        m.rawData[9] = 0; // ???
        m.rawData[10] = -(_fz + _nz) / (_fz - _nz);
        m.rawData[11] = -1;
        m.rawData[14] = -2 * _fz * _nz / (_fz - _nz);
        m.rawData[15] = 0;

        return m;
    }

    public static inline function createTranslation(_x:Float, _y:Float, _z:Float):Mat44
    {
        var m:Mat44 = new Mat44();
        m.setTranslation(_x, _y, _z);
        return m;
    }
    
    public static inline function mult(_m1:Mat44, _m2:Mat44):Mat44
    {
        var r:Mat44 = new Mat44();
        
        r.rawData[0] = _m1.rawData[0] * _m2.rawData[0] + _m1.rawData[4] * _m2.rawData[1] + _m1.rawData[8] * _m2.rawData[2] + _m1.rawData[12] * _m2.rawData[3];
        r.rawData[1] = _m1.rawData[1] * _m2.rawData[0] + _m1.rawData[5] * _m2.rawData[1] + _m1.rawData[9] * _m2.rawData[2] + _m1.rawData[13] * _m2.rawData[3];
        r.rawData[2] = _m1.rawData[2] * _m2.rawData[0] + _m1.rawData[6] * _m2.rawData[1] + _m1.rawData[10] * _m2.rawData[2] + _m1.rawData[14] * _m2.rawData[3];
        r.rawData[3] = _m1.rawData[3] * _m2.rawData[0] + _m1.rawData[7] * _m2.rawData[1] + _m1.rawData[11] * _m2.rawData[2] + _m1.rawData[15] * _m2.rawData[3];

        r.rawData[4] = _m1.rawData[0] * _m2.rawData[4] + _m1.rawData[4] * _m2.rawData[5] + _m1.rawData[8] * _m2.rawData[6] + _m1.rawData[12] * _m2.rawData[7];
        r.rawData[5] = _m1.rawData[1] * _m2.rawData[4] + _m1.rawData[5] * _m2.rawData[5] + _m1.rawData[9] * _m2.rawData[6] + _m1.rawData[13] * _m2.rawData[7];
        r.rawData[6] = _m1.rawData[2] * _m2.rawData[4] + _m1.rawData[6] * _m2.rawData[5] + _m1.rawData[10] * _m2.rawData[6] + _m1.rawData[14] * _m2.rawData[7];
        r.rawData[7] = _m1.rawData[3] * _m2.rawData[4] + _m1.rawData[7] * _m2.rawData[5] + _m1.rawData[11] * _m2.rawData[6] + _m1.rawData[15] * _m2.rawData[7];

        r.rawData[8] = _m1.rawData[0] * _m2.rawData[8] + _m1.rawData[4] * _m2.rawData[9] + _m1.rawData[8] * _m2.rawData[10] + _m1.rawData[12] * _m2.rawData[11];
        r.rawData[9] = _m1.rawData[1] * _m2.rawData[8] + _m1.rawData[5] * _m2.rawData[9] + _m1.rawData[9] * _m2.rawData[10] + _m1.rawData[13] * _m2.rawData[11];
        r.rawData[10] = _m1.rawData[2] * _m2.rawData[8] + _m1.rawData[6] * _m2.rawData[9] + _m1.rawData[10] * _m2.rawData[10] + _m1.rawData[14] * _m2.rawData[11];
        r.rawData[11] = _m1.rawData[3] * _m2.rawData[8] + _m1.rawData[7] * _m2.rawData[9] + _m1.rawData[11] * _m2.rawData[10] + _m1.rawData[15] * _m2.rawData[11];

        r.rawData[12] = _m1.rawData[0] * _m2.rawData[12] + _m1.rawData[4] * _m2.rawData[13] + _m1.rawData[8] * _m2.rawData[14] + _m1.rawData[12] * _m2.rawData[15];
        r.rawData[13] = _m1.rawData[1] * _m2.rawData[12] + _m1.rawData[5] * _m2.rawData[13] + _m1.rawData[9] * _m2.rawData[14] + _m1.rawData[13] * _m2.rawData[15];
        r.rawData[14] = _m1.rawData[2] * _m2.rawData[12] + _m1.rawData[6] * _m2.rawData[13] + _m1.rawData[10] * _m2.rawData[14] + _m1.rawData[14] * _m2.rawData[15];
        r.rawData[15] = _m1.rawData[3] * _m2.rawData[12] + _m1.rawData[7] * _m2.rawData[13] + _m1.rawData[11] * _m2.rawData[14] + _m1.rawData[15] * _m2.rawData[15];
        
        return r;
    }
    
    inline public function clone():Mat44
    {
        var m:Mat44 = new Mat44();
        m.rawData[0] = this.rawData[0];
        m.rawData[1] = this.rawData[1];
        m.rawData[2] = this.rawData[2];
        m.rawData[3] = this.rawData[3];
        m.rawData[4] = this.rawData[4];
        m.rawData[5] = this.rawData[5];
        m.rawData[6] = this.rawData[6];
        m.rawData[7] = this.rawData[7];
        m.rawData[8] = this.rawData[8];
        m.rawData[9] = this.rawData[9];
        m.rawData[10] = this.rawData[10];
        m.rawData[11] = this.rawData[11];
        m.rawData[12] = this.rawData[12];
        m.rawData[13] = this.rawData[13];
        m.rawData[14] = this.rawData[14];
        m.rawData[15] = this.rawData[15];
        return m;
    }
    
    inline public function get(_i:Int, _j:Int):Float
    {
        return this.rawData[(_i * 4) + _j];
    }
    
    inline public function transform(_v:Vec3):Vec3
    {
        var d:Float = 1 / (this.rawData[3] * _v.x + this.rawData[7] * _v.y + this.rawData[11] * _v.z + this.rawData[15]);
        var v:Vec3 = new Vec3();
        v.x = (_v.x * this.rawData[0] + _v.y * this.rawData[4] + _v.z * this.rawData[8] + this.rawData[12]) * d;
        v.y = (_v.x * this.rawData[1] + _v.y * this.rawData[5] + _v.z * this.rawData[9] + this.rawData[13]) * d;
        v.z = (_v.x * this.rawData[2] + _v.y * this.rawData[6] + _v.z * this.rawData[10] + this.rawData[14]) * d;
        return v;
    }
    
    inline public function setOrientation(_q:Quat):Void 
    {
        var Tx:Float = 2 * _q.x;
        var Ty:Float = 2 * _q.y;
        var Tz:Float = 2 * _q.z;
        
        var Twx:Float = Tx * _q.w;
        var Twy:Float = Ty * _q.w;
        var Twz:Float = Tz * _q.w;
        
        var Txx:Float = Tx * _q.x;
        var Txy:Float = Ty * _q.x;
        var Txz:Float = Tz * _q.x;
        
        var Tyy:Float = Ty * _q.y;
        var Tyz:Float = Tz * _q.y;
        var Tzz:Float = Tz * _q.z;
        
        this.rawData[0] = 1 - (Tyy + Tzz);
        this.rawData[1] = Txy - Twz;
        this.rawData[2] = Txz + Twy;
        
        this.rawData[4] = Txy + Twz;
        this.rawData[5] = 1 - (Txx + Tzz);
        this.rawData[6] = Tyz - Twx;
        
        this.rawData[8] = Txz - Twy;
        this.rawData[9] = Tyz + Twx;
        this.rawData[10] = 1 - (Txx + Tyy);
    }
    
    inline public function appendScale(_x:Float, _y:Float, _z:Float):Void 
    { 
        this.rawData[0] *= _x;
        this.rawData[5] *= _y;
        this.rawData[10] *= _z;
    }
    
    inline public function setScale(_x:Float, _y:Float, _z:Float):Void 
    { 
        this.rawData[0] = _x;
        this.rawData[5] = _y;
        this.rawData[10] = _z;
    }

    inline public function appendTranslation(_x:Float, _y:Float, _z:Float):Void 
    {
        this.rawData[12] += _x;
        this.rawData[13] += _y;
        this.rawData[14] += _z;
    }
    
    inline public function setTranslation(_x:Float, _y:Float, _z:Float):Void 
    {
        this.rawData[12] = _x;
        this.rawData[13] = _y;
        this.rawData[14] = _z;
    }
    
    inline public function getTranslation():Vec3
    {
        return Vec3.create(this.rawData[12], this.rawData[13], this.rawData[14]);
    }
    
    inline public function recompose(_o:Quat, _s:Vec3, _t:Vec3):Void
    {
        var rot:Mat44 = new Mat44();
        rot.setOrientation(_o);
        
        var scale:Mat44 = new Mat44();
        scale.setScale(_s.x, _s.y, _s.z);
        
        this.rawData = Mat44.mult(rot, scale).rawData;
        setTranslation(_t.x, _t.y, _t.z);
    }
    
    public inline function determinant():Float
    {
        return      (this.rawData[0] * this.rawData[5] - this.rawData[1] * this.rawData[4]) * (this.rawData[10] * this.rawData[15] - this.rawData[11] * this.rawData[14])
                -(this.rawData[0] * this.rawData[6] - this.rawData[2] * this.rawData[4]) * (this.rawData[9] * this.rawData[15] - this.rawData[11] * this.rawData[13])
                +(this.rawData[0] * this.rawData[7] - this.rawData[3] * this.rawData[4]) * (this.rawData[9] * this.rawData[14] - this.rawData[10] * this.rawData[13])
                +(this.rawData[1] * this.rawData[6] - this.rawData[2] * this.rawData[5]) * (this.rawData[8] * this.rawData[15] - this.rawData[11] * this.rawData[12])
                -(this.rawData[1] * this.rawData[7] - this.rawData[3] * this.rawData[5]) * (this.rawData[8] * this.rawData[14] - this.rawData[10] * this.rawData[12])
                +(this.rawData[2] * this.rawData[7] - this.rawData[3] * this.rawData[6]) * (this.rawData[8] * this.rawData[13] - this.rawData[9] * this.rawData[12]);
    }
    
    public inline function inverted():Mat44
    {
        var m00:Float = this.rawData[0]; var m01:Float = this.rawData[1]; var m02:Float = this.rawData[2]; var m03:Float = this.rawData[3];
        var m10:Float = this.rawData[4]; var m11:Float = this.rawData[5]; var m12:Float = this.rawData[6]; var m13:Float = this.rawData[7];
        var m20:Float = this.rawData[8]; var m21:Float = this.rawData[9]; var m22:Float = this.rawData[10]; var m23:Float = this.rawData[11];
        var m30:Float = this.rawData[12]; var m31:Float = this.rawData[13]; var m32:Float = this.rawData[14]; var m33:Float = this.rawData[15];
        
        var v0:Float = m20 * m31 - m21 * m30;
        var v1:Float = m20 * m32 - m22 * m30;
        var v2:Float = m20 * m33 - m23 * m30;
        var v3:Float = m21 * m32 - m22 * m31;
        var v4:Float = m21 * m33 - m23 * m31;
        var v5:Float = m22 * m33 - m23 * m32;

        var t00:Float =  (v5 * m11 - v4 * m12 + v3 * m13);
        var t10:Float = - (v5 * m10 - v2 * m12 + v1 * m13);
        var t20:Float =  (v4 * m10 - v2 * m11 + v0 * m13);
        var t30:Float = - (v3 * m10 - v1 * m11 + v0 * m12);

        var invDet:Float = 1 / (t00 * m00 + t10 * m01 + t20 * m02 + t30 * m03);

        var d00:Float = t00 * invDet;
        var d10:Float = t10 * invDet;
        var d20:Float = t20 * invDet;
        var d30:Float = t30 * invDet;

        var d01:Float = - (v5 * m01 - v4 * m02 + v3 * m03) * invDet;
        var d11:Float =  (v5 * m00 - v2 * m02 + v1 * m03) * invDet;
        var d21:Float = - (v4 * m00 - v2 * m01 + v0 * m03) * invDet;
        var d31:Float =  (v3 * m00 - v1 * m01 + v0 * m02) * invDet;

        v0 = m10 * m31 - m11 * m30;
        v1 = m10 * m32 - m12 * m30;
        v2 = m10 * m33 - m13 * m30;
        v3 = m11 * m32 - m12 * m31;
        v4 = m11 * m33 - m13 * m31;
        v5 = m12 * m33 - m13 * m32;

        var d02:Float =  (v5 * m01 - v4 * m02 + v3 * m03) * invDet;
        var d12:Float = - (v5 * m00 - v2 * m02 + v1 * m03) * invDet;
        var d22:Float =  (v4 * m00 - v2 * m01 + v0 * m03) * invDet;
        var d32:Float = - (v3 * m00 - v1 * m01 + v0 * m02) * invDet;

        v0 = m21 * m10 - m20 * m11;
        v1 = m22 * m10 - m20 * m12;
        v2 = m23 * m10 - m20 * m13;
        v3 = m22 * m11 - m21 * m12;
        v4 = m23 * m11 - m21 * m13;
        v5 = m23 * m12 - m22 * m13;

        var d03:Float = - (v5 * m01 - v4 * m02 + v3 * m03) * invDet;
        var d13:Float =  (v5 * m00 - v2 * m02 + v1 * m03) * invDet;
        var d23:Float = - (v4 * m00 - v2 * m01 + v0 * m03) * invDet;
        var d33:Float =  (v3 * m00 - v1 * m01 + v0 * m02) * invDet;
        
        var m:Mat44 = new Mat44();
        m.rawData[0] = d00;
        m.rawData[1] = d01;
        m.rawData[2] = d02;
        m.rawData[3] = d03;
        
        m.rawData[4] = d10;
        m.rawData[5] = d11;
        m.rawData[6] = d12;
        m.rawData[7] = d13;
        
        m.rawData[8] = d20;
        m.rawData[9] = d21;
        m.rawData[10] = d22;
        m.rawData[11] = d23;
        
        m.rawData[12] = d30;
        m.rawData[13] = d31;
        m.rawData[14] = d32;
        m.rawData[15] = d33;

        return m;
    }
    
#if flash
    inline public function toMatrix():Matrix3D
    {
        return new Matrix3D(flash.Vector.ofArray([
            rawData[0], rawData[1], rawData[2], rawData[3], 
            rawData[4], rawData[5], rawData[6], rawData[7], 
            rawData[8], rawData[9], rawData[10], rawData[11], 
            rawData[12], rawData[13], rawData[14], rawData[15],
        ]));
    }
#end
}
