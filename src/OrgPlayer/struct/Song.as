package orgPlayer.struct 
{
    /**
     * ...
     * @author me
     */
    
    import orgPlayer.Tools;
    
    public class Song 
    {
        public var
        /*uint8      */ version         :uint, //Org-02 Org-03
        /*uint16     */ wait            :uint,
        /*uint8      */ beatPerMeasure  :uint,
        /*uint8      */ clickPerBeat    :uint,
        /*uint32     */ loopStart       :uint,
        /*uint32     */ loopEnd         :uint,
        /*&tracks[16]*/ tracks          :Vector.<Track>;
        
        public function Song() 
        {
            tracks = Tools.malloc_1DVector(Track, 16, true);
        }
        
    }

}