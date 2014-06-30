package orgPlayer.struct 
{
    /**
     * ...
     * @author me
     */
    
    import flash.utils.ByteArray;
    import orgPlayer.Tools;
    
    public class Track 
    {
        public var
        /*uint16     */ freq            :uint,
        /*uint8      */ instrument      :uint,
        /*uint8      */ pi              :uint,
        /*uint16     */ trackSize       :uint,
        
        
                        activity        :ByteArray,
        
        /*uint8[]    */ note            :ByteArray,
        /*uint8[]    */ duration        :ByteArray,
        /*uint8[]    */ volume          :ByteArray,
        /*uint8[]    */ pan             :ByteArray;
        
        public function Track() 
        {
            
        }
        
    }

}