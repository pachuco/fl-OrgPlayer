package 
{
    import flash.display.Sprite;
    import flash.events.*;
    import flash.events.SampleDataEvent;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.utils.ByteArray;
    import OrgPlayer.*;
    
    import flash.display.SimpleButton
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.net.FileReference;
    import flash.net.FileFilter;
    
    /**
     * ...
     * @author assnuts
     */
    public class Main extends Sprite 
    {
        
        //[Embed(source="mus/MIRACLEMATTER.ORG", mimeType="application/octet-stream")]
        //[Embed(source="mus/REACTOR.ORG", mimeType="application/octet-stream")]
        //[Embed(source="mus/SHOP.org", mimeType="application/octet-stream")]
        //[Embed(source="mus/gestation.org", mimeType="application/octet-stream")]
        //[Embed(source="mus/runny yolk.org", mimeType="application/octet-stream")]
        //[Embed(source="mus/Tower.org", mimeType="application/octet-stream")]
        //[Embed(source="mus/not comfortable to use.org", mimeType="application/octet-stream")]
        //private const org_data:Class;
        
        [Embed(source="orgsamp.dat", mimeType="application/octet-stream")]
        private const smp_data:Class;
        
        
        private var buf_size:uint = 4092;
        
        private var sc:SoundChannel;
        private var audio_out:Sound;
        private var replayer:Organya;
        
        private var fr:FileReference;
        private var ff:FileFilter;
        
        public function Main():void 
        {
            if (stage) init();
            else addEventListener(Event.ADDED_TO_STAGE, init);
        }
        
        private function init(e:Event = null):void 
        {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            // entry point
            
            audio_out = new Sound();
            audio_out.addEventListener(SampleDataEvent.SAMPLE_DATA, audio_loop);
            
            
            
            
            
            
            
            
            
            
            fr = new FileReference();
            fr.addEventListener(Event.SELECT, onFileSelected);
            ff = new FileFilter("Organya files", "*.org;org.*");
            
            var playButton:SimpleButton = new SimpleButton();
            playButton.upState = makeButton(0xDDDDDD, 100, 20, 10, "LOAD");
            playButton.overState = makeButton(0xEEEEEE, 100, 20, 10, "LOAD");
            playButton.downState = makeButton(0xCCCCCC, 100, 20, 10, "LOAD");
            playButton.hitTestState = playButton.upState;
            playButton.addEventListener(MouseEvent.MOUSE_DOWN, onClickButtan);
            playButton.x = (stage.stageWidth - playButton.width) / 2;
            playButton.y = (stage.stageHeight - playButton.height) / 2;
            addChild(playButton);
        }
        
        private function makeButton(color:uint, width:int, height:int, round:int, text:String):Sprite
        {
            var t:TextField = new TextField();
            var s:Sprite = new Sprite();
            s.graphics.lineStyle(2);
            s.graphics.beginFill(color);
            s.graphics.drawRoundRect(0, 0, width, height, round);
            s.graphics.endFill();
            
            t.text = text;
            t.selectable = false;
            t.width = width;
            t.autoSize = TextFieldAutoSize.CENTER;
            s.addChild(t);
            return s;
        }
        
        private function onClickButtan(e:MouseEvent):void{
            fr.browse([ff]);
        }
        
        private function onFileSelected(evt:Event):void{ 

            var ass:Function = function(event:Event) {
                if(sc) sc.stop();
                replayer = new Organya( fr.data,
                                        new smp_data() as ByteArray);
                sc = audio_out.play();
            }
                
            fr.addEventListener(Event.COMPLETE, ass); 
            fr.load();
        } 
        
        private function audio_loop( event:SampleDataEvent ):void{
            replayer.getSampleHunk( event.data, buf_size );
        }
        
    }
    
}