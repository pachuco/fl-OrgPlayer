package  
{
    import flash.display.Sprite;
    import flash.events.*;
    import orgTP0.*;
    //import debug.*;
    
	/**
     * ...
     * @author assnuts
     */
    public class Main extends Sprite
    {
        private var tp:TestPlayer;
        
        public function Main() 
        {
            if (stage) init();
            else addEventListener(Event.ADDED_TO_STAGE, init);
        }
        
        private function init(e:Event = null):void 
        {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            // entry point
            
            tp = new TestPlayer();
            addChild(tp);
        }
    }

}