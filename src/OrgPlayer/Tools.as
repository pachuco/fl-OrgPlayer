package orgPlayer 
{
    /**
     * ...
     * @author assnuts
     */
    
    
    import flash.utils.*;
    
    public class Tools 
    {
        
        public static function r_0TString(ba:ByteArray, max:int):String
        {
            var str:String;
            var i:uint;
            var pos:uint = ba.position;
            var char:uint;
            var isZero:Boolean = false;
            
            //check first where 0x00 occurs, if at all
            for (i = 0; i < max; i++ )
            {
                char = ba.readUnsignedByte();
                if (char == 0x00) break;
            }
            
            //read actual string
            ba.position = pos;
            str = ba.readMultiByte(i+1, "US-ASCII");
            
            //discard the rest of the string if previous char was not 0x00
            //walk untill either zero terminator is found or our legs break
            while (char != 0x00)
            {
                char = ba.readUnsignedByte();
            }
            
            return str;
        }
        
        public static function getClassFromObject(obj:Object):Class
        {
            return Class(getDefinitionByName(getQualifiedClassName(obj)));
        }
        
        public static function malloc_1DVector(type:Class, size:uint=0, isFixed:Boolean=false):*
        {
            //gracefully stolen from Godfather; http://stackoverflow.com/a/6705178
            var objects:*;
            var i:int;
            var kuk:*;
            
            //deal with primitive types faster
            if (type is int)
            {
                objects = new Vector.<int>(size, isFixed);
            }
            else if (type is uint)
            {
                objects = new Vector.<uint>(size, isFixed);
            }
            else if (type is Number)
            {
                objects = new Vector.<Number>(size, isFixed);
                //AS3 Number initializes to NaN
                //C float initializes to 0.0
                for each (kuk in objects) kuk = 0.0;
            }
            else
            {
                var className   : String = getQualifiedClassName(type);
                var vectorClass : Class  = Class(getDefinitionByName("Vector.<" + className + ">"));
                
                objects = new vectorClass(size, isFixed);
                for (i = 0; i < size; i++)  objects[i] = new type();
                //if dealing with ByteArrays, set endianess to small.
                //Saves headaches.
                if(type is ByteArray)    for each(kuk in objects) kuk.endian = Endian.LITTLE_ENDIAN;
            }
            return objects;
        }
        
        public static function malloc_2DVector(type:Class, outerSize:uint=0, innerSize:uint=0, isOuterFixed:Boolean=false, isInnerFixed:Boolean=false):*
        {
            var objects:Vector.<*>;
            var i:int;

            var className   : String = getQualifiedClassName(type);
            var vectorClass : Class  = Class(getDefinitionByName("Vector.<Vector.<" + className + ">>"));
            objects = new vectorClass(outerSize, isOuterFixed);
            
            for(i=0; i<outerSize; i++)       objects[i] = malloc_1DVector(type, innerSize, isInnerFixed);
            
            return objects;
        }
        
    }

}