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
            tactive         :Boolean,
            makeEven        :Boolean, //m
            tfreq           :Number,
            tpos            :Number,
            lvol            :Number,
            rvol            :Number;
        
        
        public function Voice() 
        {
            
        }
        
    }

}