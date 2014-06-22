package OrgPlayer 
{
    /**
     * ...
     * @author assnuts
     */
    
    
    import flash.utils.*;
    
    public class Tools 
    {
        
        public function Tools() 
        {
            
        }
        
        public static function getClassFromObject(obj:Object):Class
        {
            return Class(getDefinitionByName(getQualifiedClassName(obj)));
        }
        
        public static function pool1DVector(type:Class, size:uint=0, isFixed:Boolean=false):*
        {
            //gracefully stolen from Godfather; http://stackoverflow.com/a/6705178
            var objects:*;
            var i:int;
            var ba:ByteArray;
            
            var className   : String = getQualifiedClassName(type);
            var vectorClass : Class  = Class(getDefinitionByName("Vector.<" + className + ">"));
            objects = new vectorClass(size, isFixed);
            
            for(i=0; i<size; i++)           objects[i] = new type();
            if(vectorClass is ByteArray)    for each(ba in objects) ba.endian = Endian.LITTLE_ENDIAN;
            
            return objects;
        }
        
        public static function pool2DVector(type:Class, outerSize:uint=0, innerSize:uint=0, isOuterFixed:Boolean=false, isInnerFixed:Boolean=false):*
        {
            var objects:Vector.<*>;
            var i:int;

            var className   : String = getQualifiedClassName(type);
            var vectorClass : Class  = Class(getDefinitionByName("Vector.<Vector.<" + className + ">>"));
            objects = new vectorClass(outerSize, isOuterFixed);
            
            for(i=0; i<outerSize; i++)       objects[i] = pool1DVector(type, innerSize, isInnerFixed);
            
            return objects;
        }
        
    }

}