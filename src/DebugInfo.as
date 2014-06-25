package  
{
	/**
     * ...
     * @author assnuts
     */
    public class DebugInfo extends Sprite
    {
        
        public function DebugInfo() 
        {
            if (stage) init();
            else addEventListener(Event.ADDED_TO_STAGE, init);
        }
        
        private function init(e:Event = null):void 
        {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            // entry point
            
            
        }
    }

}