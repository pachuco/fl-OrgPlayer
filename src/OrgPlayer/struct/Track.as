package OrgPlayer.struct 
{
    /**
     * ...
     * @author me
     */
    
    import OrgPlayer.Tools;
    
    public class Track 
    {
        public var
        /*uint16     */ freq            :uint,
        /*uint8      */ instrument      :uint,
        /*uint8      */ pi              :uint,
        /*uint16     */ rowNum          :uint,
        /*&rows[]    */ rows            :Vector.<Row>;
        
        public function Track() 
        {
            rows = Tools.pool1DVector(Row);
        }
        
    }

}