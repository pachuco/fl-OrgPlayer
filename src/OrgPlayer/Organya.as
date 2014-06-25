package orgPlayer{
    import flash.utils.Endian;
    import flash.utils.ByteArray;
    import flash.utils.*;
    import orgPlayer.struct.*;
    /**
     * ...
     * @author me
     */
    public class Organya{
        
        private var
            orgSong         :Song,
            
            melody          :Vector.<ByteArray>,
            drums           :Vector.<ByteArray>,
            
            sample          :int=0,
            click           :uint=0,
            percSampleRate  :uint,
            
            voices          :Vector.<Voice>;
            
        private var frameLen                :Number;
        
        public var callBack:Function;
        
        private static function unsign(b:int):int{
            if(b < 0) b    += 256;
            return b;
        }
        
        private static function   sign(b:int):int{
            if(b >= 128) b -= 256
            return b;
        }
        
        
        private static function interpretVol(vol:Number):Number{
            return Math.pow(10,vol-1);
        }
        
        //do not call this method during playback
        //adding the "sychronized" keyword to both this method and the getSampleFrame method would allow it
        //but that might also cause liveness issues
        public function reset():void{
            sample = click = 0;
            for (var i:uint; i<16; i++)
            {
                voices[i].periodsLeft = 0;
                voices[i].pointqty    = 0;
                voices[i].tactive     = false;
                voices[i].makeEven    = false;
                voices[i].tfreq       = 0.0;
                voices[i].tpos        = 0.0;
                voices[i].lvol        = 0.0;
                voices[i].rvol        = 0.0;
            }
        }
        
        public function Organya(resStream:ByteArray){ 
            melody      = new Vector.<ByteArray>;
            drums       = new Vector.<ByteArray>;
            voices      = Tools.pool1DVector(Voice, 16, true);
            
            resStream.position = 0;
            resStream.endian = Endian.LITTLE_ENDIAN;
            //---------------------------------------------
            frameLen = 1.0/Cons.sampleRate;
            
            //read sample data in from the resource file
            var mqty:uint = resStream.readUnsignedByte();
            var mlen:uint = 0;
            var i:uint, j:uint;
            
            for(i = 0; i < 3; i++)
            {
                mlen *= 256;
                mlen += resStream.readUnsignedByte()
            }
            
            //melody=new byte[mqty][mlen];
            //butt[outer][inner];
            melody = Tools.pool1DVector(ByteArray, mqty, true);
            
            var b:ByteArray;
            for each( b in melody){
                if(mlen) resStream.readBytes(b, 0, mlen);
            }
            drums = Tools.pool1DVector(ByteArray, resStream.readUnsignedByte(), true);
            
            percSampleRate  = 256*resStream.readUnsignedByte();
            percSampleRate += resStream.readUnsignedByte();
            for(i = 0; i < drums.length; i++){
                mlen = 0;
                for(j = 0; j < 3; j++){
                    mlen *= 256;
                    mlen += resStream.readUnsignedByte();
                }
                if(mlen) resStream.readBytes(drums[i], 0, mlen);
            }
            //resStream.close();
            resStream.position = 0;
        }
        
        public function loadSong(orgStream:ByteArray):Song{
            orgSong = new Song();
            orgStream.position = 0;
            orgStream.endian = Endian.LITTLE_ENDIAN;
            var track:Track;
            
            //check the first 6 bytes of the org file
            var header:String = orgStream.readMultiByte(6, "us-ascii");
            if      (header == "Org-02") orgSong.version = 2
            else if (header == "Org-03") orgSong.version = 3
            else    return null;
            
            var i:uint, j:uint;
            sample      = 0;
            click       = 0;
            reset();
            
            //get the wait value (clickLen), start point (loopPoint), and end point (songLen)
            orgSong.clickLen       = orgStream.readUnsignedShort();
            orgSong.beatPerMeasure = orgStream.readUnsignedByte();
            orgSong.clickPerBeat   = orgStream.readUnsignedByte();
            orgSong.loopStart      = orgStream.readUnsignedInt();
            orgSong.loopEnd        = orgStream.readUnsignedInt();
            
            //read track data
            for each (track in orgSong.tracks)
            {
                track.freq       = orgStream.readUnsignedShort();
                track.instrument = orgStream.readUnsignedByte();
                track.pi         = orgStream.readUnsignedByte();
                track.trackSize  = orgStream.readUnsignedShort();
            }
            
            //read event data
            //data=new int[16][songLen];
            for each (track in orgSong.tracks)
            {
                //track.pos.length      = orgSong.loopEnd;
                track.note.length     = orgSong.loopEnd;
                track.duration.length = orgSong.loopEnd;
                track.volume.length   = orgSong.loopEnd;
                track.pan.length      = orgSong.loopEnd;
            }
            
            
            //for each track
            for each (track in orgSong.tracks)
            {
                var pos:uint=0, hold:uint=0,volume:uint=0, pan:uint=0, index:uint=0;
                var trackSize:uint = track.trackSize;
                
                var positions:Vector.<uint>  = new Vector.<uint>(track.trackSize, true);
                var notes:Vector.<uint>      = new Vector.<uint>(track.trackSize, true);
                var durations:Vector.<uint>  = new Vector.<uint>(track.trackSize, true);
                var volumes:Vector.<uint>    = new Vector.<uint>(track.trackSize, true);
                var pans:Vector.<uint>       = new Vector.<uint>(track.trackSize, true);
                
                for (j = 0; j < trackSize; j++) positions[j] = orgStream.readUnsignedInt();
                for (j = 0; j < trackSize; j++) notes[j]     = orgStream.readUnsignedByte();
                for (j = 0; j < trackSize; j++) durations[j] = orgStream.readUnsignedByte();
                for (j = 0; j < trackSize; j++) volumes[j]   = orgStream.readUnsignedByte();
                for (j = 0; j < trackSize; j++) pans[j]      = orgStream.readUnsignedByte();
                
                for(i = 0; i < trackSize; i++){
                    //put a "marker" in the data array indicating that there is an event there
                    var time:uint = positions[i];
                    if(time<orgSong.loopEnd) track.note[time]=1 ;
                }
                
                for(i = 0; i < orgSong.loopEnd; i++){
                    var note:uint = 255;
                    
                    if(track.note[i] == 1){
                        //for note, volume, and pan, a value of 255 indicates no change
                        //if the note changes, set the value of hold to the duration,
                        //and mark that the sound should be re-triggered at this point
                        
                        //notes: 0-95, 255
                        note              = notes[index]
                        note              = (note > 95 && note != 255) ? 95 : note;
                        if(note<255) hold = durations[index];
                        
                        //vols: 0-254, 255
                        var v:uint        = volumes[index];
                        if(v<255) volume  = v;
                        
                        //pans: 0-12, 255
                        var p:uint        = pans[index];
                        p                 = (p > 12 && p != 255) ? 12 : p;
                        if(p<255) pan     = p;
                        
                        index++;
                    }
                    
                    //the variable hold keeps track of how much longer the note needs to be held
                    //I use the note value 256 to indicate the note release
                    if(note == 255 && hold>0) hold--;
                    if(hold == 0            ) note = 256;
                    
                    track.note[i]   = note;
                    track.volume[i] = volume;
                    track.pan[i]    = pan;
                }
                
            }
            //orgStream.close();
            orgStream.position = 0;
            return orgSong;
        }
        
        public function getSampleHunk(outBuf:ByteArray, numSamples:uint):void{
            outBuf.endian = Endian.LITTLE_ENDIAN;
            var i:uint, j:uint, k:uint, l:uint;
            var voice:Voice, track:Track;
            
            var clickLen :uint = Cons.sampleRate * orgSong.clickLen / 1000.0+0.5;
            var loopStart:uint = orgSong.loopStart;
            var loopEnd  :uint = orgSong.loopEnd;
            
            for(l = 0; l < numSamples; l++){
                //the variable sample keeps track of which sample is currently being played
                //increment it and check if it was a multiple of clickLen before being incremented
                //if it is, move to the next click and process any data for that click
                if((sample++)%clickLen == 0){
                    //for each track
                    for(j=0;j<16;j++){
                        voice = voices[j];
                        track = orgSong.tracks[j];
                        
                        //get the note, volume, and pan values for this track at this click
                        var tvolume:uint    = track.volume[click];
                        var note:uint       = track.note[click];
                        var tpan:Number     = (track.pan[click]-6)/6.0;
                        voice.lvol  = voice.rvol = 255*interpretVol(tvolume/255.0);
                        if(tpan<0) voice.rvol *= interpretVol(1+tpan);
                        if(tpan>0) voice.lvol *= interpretVol(1-tpan);
                        
                        if(note== 256 && j<8) voice.tactive=false;
                        if(note < 255){
                            if(track.pi){
                                voice.periodsLeft = 4;
                                for(i = 11; i < note; i+=12) voice.periodsLeft += 4;
                            }
                            voice.tactive = true;
                            voice.tpos    = 0.0;
                            var foff:Number   = (track.freq-1000)/256;
                            for(k = 24; k <= note; k+=12) if(k != 36) foff *= 2;
                            
                            if(j < 8){
                                voice.tfreq    = frameLen*(440.0*Math.pow(2.0,(note-45)/12.0)+foff);
                                voice.pointqty = 1024;
                                for(i = 11; i < note; i+=12) voice.pointqty /= 2;
                                voice.makeEven = voice.pointqty <= 256;
                            }else{
                                voice.tfreq    = frameLen*note*percSampleRate;
                            }
                        }
                    }
                    //increment click
                    //check to see if we've reached the end of the song, and loop back if so
                    if(++click == loopEnd){
                        click  = loopStart;
                        sample = click*clickLen+1;
                    }
                    if(callBack != null) callBack();
                }
                
                var lsamp:int=0, rsamp:int=0;
                for(j = 0; j < 16; j++){
                    voice = voices[j];
                    track = orgSong.tracks[j];
                    
                    if(voice.tactive){
                        var ins:int = track.instrument;
                        var samp1:int, samp2:int, pos:Number;
                        var pos1:int, pos2:int
                        
                        pos = voice.tpos;
                        if(j < 8){
                            var size:int = voice.pointqty;
                            pos *= size;
                            pos1 = uint(pos);
                            pos -= pos1;
                            pos2 = pos1+1;
                            if(pos2 == size) pos2 = 0;
                            //I dunno what this does, but it's working.
                            if(voice.makeEven)
                            {
                                pos1 -= pos1%2;
                                pos2 -= pos2%2;
                            }
                            
                            samp1 = sign(melody[ins][uint((pos1*256)/size)]);
                            samp2 = sign(melody[ins][uint((pos2*256)/size)]);
                        }else{
                            pos1  = uint(pos);
                            pos  -= pos1;
                            var drum:ByteArray = drums[ins];
                            samp1 = sign(drum[pos1++]);
                            samp2 = pos1 < drum.length ? sign(drum[pos1]) : 0;
                        }
                        
                        //do interpolation
                        var samp:Number = (samp1+pos*(samp2-samp1));
                        
                        //multiply the sample frame by the left and right volume, and add it to the output
                        lsamp          += voice.lvol*samp;
                        rsamp          += voice.rvol*samp;
                        voice.tpos     += voice.tfreq;
                        
                        while(voice.tpos >= 1.0 && j < 8 && voice.tactive){
                            voice.tpos--;
                            if(track.pi) if(--voice.periodsLeft == 0) voice.tactive = false;
                        }
                        if(j >= 8) if(voice.tpos >= drums[ins].length) voice.tactive = false;
                    }
                }
                outBuf.writeFloat(rsamp/0xFFFF);
                outBuf.writeFloat(lsamp/0xFFFF);
            }
        }
        
        
    }
}