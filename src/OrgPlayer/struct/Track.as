package orgPlayer.struct 
{
    /**
     * ...
     * @author me
     */
    
    import orgPlayer.Tools;
    
    public class Track 
    {
        public var
        /*uint16     */ freq            :uint,
        /*uint8      */ instrument      :uint,
        /*uint8      */ pi              :uint,
        /*uint16     */ trackSize       :uint,
        
                        activity        :Vector.<uint>,
        ///*uint32[]   */ pos             :Vector.<uint>,
        /*uint8[]    */ note            :Vector.<uint>,
        /*uint8[]    */ duration        :Vector.<uint>,
        /*uint8[]    */ volume          :Vector.<uint>,
        /*uint8[]    */ pan             :Vector.<uint>;
        
        public function Track() 
        {
            //pos      = new Vector.<uint>();
            note     = new Vector.<uint>();
            duration = new Vector.<uint>();
            volume   = new Vector.<uint>();
            pan      = new Vector.<uint>();
        }
        
    }

}