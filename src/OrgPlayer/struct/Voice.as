package orgPlayer.struct 
{
	/**
     * ...
     * @author assnuts
     */
    public class Voice 
    {
        //Everything marked with 'm' is property used by melody voices
        public var
            periodsLeft     :uint,    //m
            pointqty        :uint,    //m
            active          :uint,
            makeEven        :uint,    //m
            tfreq           :Number = 0,
            lvol            :Number = 0,
            rvol            :Number = 0,
            
            vol             :Number = 0,
            pan             :Number = 0,
            
            clicksLeft      :int,
            
            tpos            :Number = 0;
        
        
        public function Voice() 
        {
        }
        
    }

}