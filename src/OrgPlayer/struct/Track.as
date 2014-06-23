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
        /*uint8      */ pi              :uint;
        private var
        /*uint16     */ rowNumT         :uint;
        public var
        /*&rows[]    */ rows            :Vector.<Row>;
        
        public function Track() 
        {
            
        }
        
        public function set rowNum(val:uint):void
        {
            rowNumT = val;
            rows = Tools.pool1DVector(Row, val);
        }
        
        public function get rowNum():uint
        {
            return rowNumT;
        }
        
    }

}