package 
{
    import flash.display.Sprite;
    import flash.events.*;
    import flash.events.SampleDataEvent;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.utils.ByteArray;
    import orgPlayer.*;
    import orgPlayer.struct.*;
    
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
        
        private var scs:Vector.<SoundChannel>;
        
        private var audio_out:Sound;
        private var replayer:Organya;
        private var orgSong:Song;
        
        private var fr:FileReference;
        private var ff:FileFilter;
        
        private var tf:TextField;
        
        private var loadButton:SimpleButton;
        private var saveButton:SimpleButton;
        private var playButton:SimpleButton;
        private var pauseButton:SimpleButton;
        private var stopButton:SimpleButton;
        private var activity:Sprite;
        private var inactivity:Sprite;
        
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
            replayer = new Organya( new smp_data() as ByteArray);
            scs = new Vector.<SoundChannel>();
            
            //-------------
            activity = new Sprite();
            activity.graphics.beginFill(0x46B525);
            activity.graphics.drawRect(0, 0, stage.stageWidth/2, 20);
            activity.graphics.endFill();
            activity.x = stage.stageWidth/2;
            activity.y = stage.stageHeight / 40*38 +2;
            activity.visible = false;
            addChild(activity);
            inactivity = new Sprite();
            inactivity.graphics.beginFill(0xE3491A);
            inactivity.graphics.drawRect(0, 0, stage.stageWidth/2, 20);
            inactivity.graphics.endFill();
            inactivity.x = stage.stageWidth/2;
            inactivity.y = stage.stageHeight / 40*38 +2;
            inactivity.visible = true;
            addChild(inactivity);
            //-------------
            
            
            
            
            
            
            
            
            fr = new FileReference();
            ff = new FileFilter("Organya files", "*.org;org.*");
            
            loadButton = makeButton("LOAD", onClickLoadButtan);
            loadButton.x = (stage.stageWidth - loadButton.width) / 8*0 + 3;
            loadButton.y = (stage.stageHeight - loadButton.height) / 20*19;
            addChild(loadButton);
            
            saveButton = makeButton("SAVE", onClickSaveButtan);
            saveButton.x = (stage.stageWidth - saveButton.width) / 8*0 + 83;
            saveButton.y = (stage.stageHeight - saveButton.height) / 20*19;
            //addChild(saveButton);
            
            playButton = makeButton("PLAY", onClickPlayButtan);
            playButton.x = (stage.stageWidth - playButton.width) / 15*15 -80*2;
            playButton.y = (stage.stageHeight - playButton.height) / 20*19;
            addChild(playButton);
            
            pauseButton = makeButton("PAUSE", onClickPauseButtan);
            pauseButton.x = (stage.stageWidth - pauseButton.width) / 15*15 -80*1 ;
            pauseButton.y = (stage.stageHeight - pauseButton.height) / 20*19;
            addChild(pauseButton);
            
            stopButton = makeButton("SOTP", onClickStopButtan);
            stopButton.x = (stage.stageWidth - stopButton.width) / 15*15;
            stopButton.y = (stage.stageHeight - stopButton.height) / 20*19;
            addChild(stopButton);
            
            tf = makeTextField("");
            tf.x = stage.stageWidth / 2;
            tf.y = stage.stageHeight  / 20;
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
        
        private function stopSomeAudio():void{
            var sc:SoundChannel = scs.pop();
            if(sc){
                sc.stop();
                sc = null;
            }
            if(scs.length == 0){
                activity.visible = false;
                inactivity.visible = true;
            }
        }
        
        private function stopAllAudio():void{
            var sc:SoundChannel;
            for each(sc in scs){
                sc.stop();
                sc = null;
            }
            scs = new Vector.<SoundChannel>();
            activity.visible = false;
            inactivity.visible = true;
        }
        
        private function onClickLoadButtan(e:MouseEvent):void {
            fr.addEventListener(Event.SELECT, onLoadFileSelected);
            fr.browse([ff]);
        }
        
        private function onClickSaveButtan(e:MouseEvent):void {
            //if (orgSong) fr.save(replayer.saveSong(orgSong), tf.text);
        }
        
        private function onClickPlayButtan(e:MouseEvent):void{
            var isPlaying:Boolean = false;
            if(orgSong && isPlaying != true){
                activity.visible = true;
                inactivity.visible = false;
                scs.push(audio_out.play());
            }
            
        }
        
        private function onClickPauseButtan(e:MouseEvent):void{
            stopSomeAudio();
        }
        
        private function onClickStopButtan(e:MouseEvent):void{
            stopAllAudio();
            replayer.reset();
        }
        
        private function onLoadFileSelected(evt:Event):void {
            var ass:Function = function(event:Event):void {
                onClickPauseButtan(null);
                orgSong = replayer.loadSong(fr.data);
                if (orgSong) tf.text=fr.name;
                onClickPlayButtan(null);
            }
            stopAllAudio();
            fr.addEventListener(Event.COMPLETE, ass); 
            fr.load();
            
            fr.removeEventListener(Event.SELECT, onLoadFileSelected);
        }
        
        private function audio_loop( event:SampleDataEvent ):void{
            replayer.getSampleHunk( event.data, buf_size );
        }
        
    }
    
}