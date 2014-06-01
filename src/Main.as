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
        
        private var tf:TextField;
        
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
            
            var playButton:SimpleButton = makeButton("LOAD", onClickLoadButtan);
            playButton.x = (stage.stageWidth - playButton.width) / 8*1;
            playButton.y = (stage.stageHeight - playButton.height) / 4*3;
            addChild(playButton);
            
            var loadButton:SimpleButton = makeButton("PLAY", onClickPlayButtan);
            loadButton.x = (stage.stageWidth - playButton.width) / 8*7;
            loadButton.y = (stage.stageHeight - playButton.height) / 4*3;
            addChild(loadButton);
            
            tf = makeTextField("");
            tf.x = stage.stageWidth / 2;
            tf.y = stage.stageHeight  / 8;
            addChild(tf);
        }
        
        private function makeButton(text:String, callback:Function, width:int=75, height:int=20, round:int=10):SimpleButton
        {
            var makeButt:Function = function(text:String, color:uint, width:int, height:int, round:int):Sprite {
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
            
            var buttan:SimpleButton = new SimpleButton();
            buttan.upState   = makeButt(text, 0xDDDDDD, width, height, round);
            buttan.overState = makeButt(text, 0xEEEEEE, width, height, round);
            buttan.downState = makeButt(text, 0xCCCCCC, width, height, round);
            buttan.hitTestState = buttan.upState;
            buttan.addEventListener(MouseEvent.MOUSE_DOWN, callback);
            return buttan;
            
        }
        
        private function makeTextField(text:String):TextField
        {
            var t:TextField = new TextField();
            
            t.text = text;
            t.selectable = false;
            t.width = width;
            t.autoSize = TextFieldAutoSize.CENTER;
            return t;
        }
        
        private function onClickLoadButtan(e:MouseEvent):void{
            fr.browse([ff]);
        }
        
        private function onClickPlayButtan(e:MouseEvent):void{
            if(sc) {
                sc.stop();
                sc = null;
            }
            else if(replayer){
                sc = audio_out.play();
            }
            
        }
        
        private function onFileSelected(evt:Event):void{ 

            var ass:Function = function(event:Event):void {
                if(sc) {
                    sc.stop();
                    sc = null;
                }
                replayer = new Organya( fr.data,
                                        new smp_data() as ByteArray);
                sc = audio_out.play();
                tf.text=fr.name;
            }
                
            fr.addEventListener(Event.COMPLETE, ass); 
            fr.load();
        } 
        
        private function audio_loop( event:SampleDataEvent ):void{
            replayer.getSampleHunk( event.data, buf_size );
        }
        
    }
    
}