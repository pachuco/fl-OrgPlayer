package orgPlayer{
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    import flash.utils.*;
    import orgPlayer.struct.*;
    /**
     * ...
     * @author me
     */
    public class Organya{
        
        private const TRUE:uint  = 1;
        private const FALSE:uint = 0;
        
        private var
            song            :Song,
            sb              :SampleBank,
            
            sample          :int=0,
            click           :uint=0,
            
            voices          :Vector.<Voice>,
            
            frameLen        :Number;
        
        
        [inline]
        private static function unsign(b:int):int{
            if(b < 0) b    += 256;
            return b;
        }
        
        [inline]
        private static function   sign(b:int):int{
            if(b >= 128) b -= 256
            return b;
        }
        
        
        private static function interpretVol(vol:Number):Number{
            return Math.pow(10,vol-1);
        }
        
        public function reset():void{
            sample = click = 0;
            for (var i:uint; i<16; i++)
            {
                voices[i].periodsLeft = 0;
                voices[i].pointqty    = 0;
                voices[i].active      = FALSE;
                voices[i].makeEven    = FALSE;
                voices[i].tfreq       = 0.0;
                voices[i].tpos        = 0.0;
                voices[i].lvol        = 0.0;
                voices[i].rvol        = 0.0;
            }
        }
        
        public function Organya(resStream:ByteArray){ 
            voices      = Tools.malloc_1DVector(Voice, 16, true);
            //---------------------------------------------
            frameLen = 1.0/Cons.sampleRate;
            
            sb = new SampleBank(resStream);
        }
        
        public function loadSong(orgStream:ByteArray):Song{
            song = new Song(orgStream);
            if (song.version) {
                reset();
                return song;
            }
            return null;
        }
        
        public function saveSong(song:Song):ByteArray
        {
            var track:Track, kuk:uint;
            var i:uint, j:uint, k:uint;
            
            var lengths:Vector.<uint> = new Vector.<uint>(16, true);
            
            
            var data:ByteArray = new ByteArray();
            data.endian = Endian.LITTLE_ENDIAN;
            
            //if this were C, we would calculate some sizes here for malloc
            //
            
            //header and song info
            if      (song.version == 2) data.writeMultiByte("Org-02", Cons.charSet)
            else if (song.version == 3) data.writeMultiByte("Org-03", Cons.charSet)
            else    return null;
            data.writeShort       (song.wait);
            data.writeByte        (song.beatPerMeasure);
            data.writeByte        (song.clickPerBeat);
            data.writeUnsignedInt (song.loopStart);
            data.writeUnsignedInt (song.loopEnd);
            
            //all tracks info
            for (i = 0; i<16; i++ )
            {
                track = song.tracks[i];
                var len:uint = track.activity.length;
                tlen = 0;
                
                data.writeShort       (track.freq);
                data.writeByte        (track.instrument);
                data.writeByte        (track.pi);
                var tlen:uint;
                for each (kuk in track.activity) if (kuk) tlen++;
                tlen = tlen > Cons.maxEvents ? Cons.maxEvents : tlen; 
                data.writeShort       (tlen);
                lengths[i] = tlen;
            }
            
            //track data
            for (i = 0; i < 16; i++ )
            {
                track = song.tracks[i];
                len   = track.activity.length;
                
                //position
                for (j = 0; j < len; j++ )
                {
                    if (j > Cons.maxEvents) break;
                    if (track.activity[j]) data.writeUnsignedInt(j);
                }
                //notes
                for (j = 0; j < len; j++ )
                {
                    if (j > Cons.maxEvents) break;
                    if (track.activity[j]) data.writeByte(track.note[j]);
                }
                //duration
                for (j = 0; j < len; j++ )
                {
                    if (j > Cons.maxEvents) break;
                    if (track.activity[j]) data.writeByte(track.duration[j]);
                }
                //volume
                for (j = 0; j < len; j++ )
                {
                    if (j > Cons.maxEvents) break;
                    if (track.activity[j]) data.writeByte(track.volume[j]);
                }
                //pan
                for (j = 0; j < len; j++ )
                {
                    if (j > Cons.maxEvents) break;
                    if (track.activity[j]) data.writeByte(track.pan[j]);
                }
            }
            
            data.position = 0;
            return data;
        }
        
        public function getSampleHunk(outBuf:ByteArray, numSamples:uint):void
        {
            outBuf.endian = Endian.LITTLE_ENDIAN;
            var i:uint, j:uint;
            var voice:Voice, track:Track;
            
            var clickLen :uint = Cons.sampleRate * song.wait / 1000.0+0.5;
            
            for (i = 0; i < numSamples; i++) {
                
                if ((sample++) % clickLen == 0) advanceBeat();
                
                var lsamp:int=0, rsamp:int=0;
                for(j = 0; j < 16; j++){
                    voice = voices[j];
                    track = song.tracks[j];
                    
                    if(voice.active){
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
                            
                            samp1 = sign(sb.melody[ins][uint((pos1*256)/size)]);
                            samp2 = sign(sb.melody[ins][uint((pos2*256)/size)]);
                        }else{
                            pos1  = uint(pos);
                            pos  -= pos1;
                            var drum:ByteArray = sb.drums[ins];
                            samp1 = sign(drum[pos1++]);
                            samp2 = pos1 < drum.length ? sign(drum[pos1]) : 0;
                        }
                        
                        //do interpolation
                        var samp:Number = (samp1+pos*(samp2-samp1));
                        
                        //multiply the sample frame by the left and right volume, and add it to the output
                        lsamp          += voice.lvol*samp;
                        rsamp          += voice.rvol*samp;
                        voice.tpos     += voice.tfreq;
                        
                        while(int(voice.tpos >= 1.0) & int(j < 8) & voice.active){
                            voice.tpos--;
                            if(track.pi) if(--voice.periodsLeft == 0) voice.active = FALSE;
                        }
                        if(j >= 8) if(voice.tpos >= sb.drums[ins].length) voice.active = FALSE;
                    }
                }
                outBuf.writeFloat(rsamp/0xFFFF);
                outBuf.writeFloat(lsamp/0xFFFF);
            }
        }
        
        private function advanceBeat():void
        {
            var i:uint, j:uint;
            var voice:Voice, track:Track;
            var loopStart:uint = song.loopStart;
            var loopEnd  :uint = song.loopEnd;
            
            var clickLen :uint = Cons.sampleRate * song.wait / 1000.0+0.5;
            
            //for each track
            for (i = 0; i < 16; i++)
            {
                voice = voices[i];
                track = song.tracks[i];
                voice.clicksLeft--;
                
                //get the note, volume, and pan values for this track at this click
                var activity:uint = track.activity[click];
                var note:uint     = track.note[click];
                var duration:uint = track.duration[click];
                var volume:uint   = track.volume[click];
                var pan:uint      = track.pan[click];
                
                if (int(voice.clicksLeft<=0) & int(i < 8)) voice.active = FALSE;
                if (!activity)    continue;
                
                if (volume <= 254)          voice.vol = 255*interpretVol(volume/255.0);
                if (pan <= Cons.maxPan)     voice.pan = (pan - 6) / 6.0;
                
                voice.lvol  = voice.rvol = voice.vol;
                if(voice.pan<0) voice.lvol *= interpretVol(1+voice.pan);
                if(voice.pan>0) voice.rvol *= interpretVol(1-voice.pan);
                
                if (note <= Cons.maxNote)
                {
                    if (track.pi)
                    {
                        voice.periodsLeft = 4;
                        for(j = 11; j < note; j+=12) voice.periodsLeft += 4;
                    }
                    voice.clicksLeft = duration;
                    voice.active  = TRUE;
                    voice.tpos    = 0.0;
                    
                    var foff:Number   = (track.freq-1000)/256;
                    for(j = 24; j <= note; j+=12) if(j != 36) foff *= 2;
                    
                    if (i < 8)
                    {
                        voice.tfreq    = frameLen*(440.0 * Math.pow(2.0,(note-45)/12.0) + foff);
                        voice.pointqty = 1024;
                        for(j = 11; j < note; j+=12) voice.pointqty /= 2;
                        voice.makeEven = voice.pointqty <= 256 ? TRUE : FALSE;
                    }else
                    {
                        voice.tfreq    = frameLen*note*800;
                    }
                }
            }
            //increment click
            //check to see if we've reached the end of the song, and loop back if so
            if (++click == loopEnd)
            {
                click  = loopStart;
                sample = click*clickLen+1;
            }
            //if(callBack != null) callBack();
        }
        
    }
}