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
            song         :Song,
            
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
            resStream.endian = Endian.BIG_ENDIAN;
            //---------------------------------------------
            frameLen = 1.0/Cons.sampleRate;
            
            //read sample data in from the resource file
            var mqty:uint = resStream.readUnsignedByte();
            var mlen:uint = 0;
            var i:uint, j:uint;
            
            for(i = 0; i < 3; i++)
            {
                mlen <<= 8;
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
            
            percSampleRate  = resStream.readUnsignedByte() << 8;
            percSampleRate += resStream.readUnsignedByte() - 256;
            for(i = 0; i < drums.length; i++){
                mlen = 0;
                for(j = 0; j < 3; j++){
                    mlen <<= 8;
                    mlen += resStream.readUnsignedByte();
                }
                if(mlen) resStream.readBytes(drums[i], 0, mlen);
            }
            //resStream.close();
            resStream.position = 0;
        }
        
        public function loadSong(orgStream:ByteArray):Song{
            orgStream.position = 0;
            orgStream.endian = Endian.LITTLE_ENDIAN;
            
            var song:Song = new Song();
            var track:Track;
            
            //check the first 6 bytes of the org file
            var header:String = orgStream.readMultiByte(6, Cons.charSet);
            if      (header == "Org-02") song.version = 2
            else if (header == "Org-03") song.version = 3
            else    return null;
            
            var i:uint, j:uint, k:uint;
            reset();
            
            //get the wait value (clickLen), start point (loopPoint), and end point (songLen)
            song.wait           = orgStream.readUnsignedShort();
            song.beatPerMeasure = orgStream.readUnsignedByte();
            song.clickPerBeat   = orgStream.readUnsignedByte();
            song.loopStart      = orgStream.readUnsignedInt();
            song.loopEnd        = orgStream.readUnsignedInt();
            
            //read track data
            for each (track in song.tracks)
            {
                track.freq       = orgStream.readUnsignedShort();
                track.instrument = orgStream.readUnsignedByte();
                track.pi         = orgStream.readUnsignedByte();
                track.trackSize  = orgStream.readUnsignedShort();
            }
            
            
            trace("kuk");
            //for each track
            for each (track in song.tracks)
            {
                var trackSize:uint = track.trackSize;
                var positions:Vector.<int>   = new Vector.<int>(track.trackSize, true);
                var notes:Vector.<uint>      = new Vector.<uint>(track.trackSize, true);
                var durations:Vector.<uint>  = new Vector.<uint>(track.trackSize, true);
                var volumes:Vector.<uint>    = new Vector.<uint>(track.trackSize, true);
                var pans:Vector.<uint>       = new Vector.<uint>(track.trackSize, true);
                
                for (j = 0; j < trackSize; j++) positions[j] = orgStream.readInt();
                for (j = 0; j < trackSize; j++) notes[j]     = orgStream.readUnsignedByte();
                for (j = 0; j < trackSize; j++) durations[j] = orgStream.readUnsignedByte();
                for (j = 0; j < trackSize; j++) volumes[j]   = orgStream.readUnsignedByte();
                for (j = 0; j < trackSize; j++) pans[j]      = orgStream.readUnsignedByte();
                
                var maxPos:uint = 0;
                for each(var pos:int in positions) maxPos = (pos > maxPos && pos < Cons.arbitraryPosLimit) ? pos : maxPos;
                maxPos = song.loopEnd > maxPos ? song.loopEnd : maxPos;
                trace(maxPos);
                track.activity = new ByteArray();
                track.note     = new ByteArray();
                track.duration = new ByteArray();
                track.volume   = new ByteArray();
                track.pan      = new ByteArray();
                track.activity.length = maxPos;
                track.note.length     = maxPos;
                track.duration.length = maxPos;
                track.volume.length   = maxPos;
                track.pan.length      = maxPos;
                
                for(i = 0; i < trackSize; i++){
                    //put a "marker" in the data array indicating that there is an event there
                    var time:uint = positions[i];
                    
                    if (i > Cons.maxEvents) break;
                    if (time >= maxPos) continue;
                    if (time < 0) continue;
                    if (time >= Cons.arbitraryPosLimit) continue;
                    track.activity[time] = 1;
                }
                
                var volume:uint=0, pan:uint=0, index:uint=0, duration:uint=0;
                for (j = 0; j < song.loopEnd; j++) {
                    var note:uint = 255;
                    
                    if(track.activity[j]){
                        //notes:   0-95, 255
                        note         = notes[index];
                        note         = (note > Cons.maxNote && note != 255) ? 255 : note;
                        //lengths: 1-255
                        duration     = durations[index];
                        duration     = duration == 0 ? 1 : duration;
                        //vols:    0-254, 255
                        volume       = volumes[index];
                        //pans:    0-12, 255
                        pan          = pans[index];
                        pan          = (pan > Cons.maxPan && pan != 255) ? 255 : pan;
                        
                        index++;
                        
                        track.note[j]     = note;
                        track.duration[j] = duration;
                        track.volume[j]   = volume;
                        track.pan[j]      = pan;
                    }else
                    {
                        track.note[j]     = 255;
                        track.duration[j] = 255;
                        track.volume[j]   = 255;
                        track.pan[j]      = 255;
                    }
                }
                
            }
            //orgStream.close();
            orgStream.position = 0;
            this.song = song;
            return song;
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
            var i:uint, j:uint, k:uint, l:uint;
            var voice:Voice, track:Track;
            
            var clickLen :uint = Cons.sampleRate * song.wait / 1000.0+0.5;
            var loopStart:uint = song.loopStart;
            var loopEnd  :uint = song.loopEnd;
            
            for(l = 0; l < numSamples; l++){
                //the variable sample keeps track of which sample is currently being played
                //increment it and check if it was a multiple of clickLen before being incremented
                //if it is, move to the next click and process any data for that click
                if ((sample++) % clickLen == 0)
                {
                    //for each track
                    for (j = 0; j < 16; j++)
                    {
                        voice = voices[j];
                        track = song.tracks[j];
                        voice.clicksLeft--;
                        
                        //get the note, volume, and pan values for this track at this click
                        var activity:uint = track.activity[click];
                        var note:uint     = track.note[click];
                        var duration:uint = track.duration[click];
                        var volume:uint   = track.volume[click];
                        var pan:uint      = track.pan[click];
                        
                        if (voice.clicksLeft<=0 && j < 8) voice.tactive = false;
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
                                for(i = 11; i < note; i+=12) voice.periodsLeft += 4;
                            }
                            voice.clicksLeft = duration;
                            voice.tactive = true;
                            voice.tpos    = 0.0;
                            
                            var foff:Number   = (track.freq-1000)/256;
                            for(k = 24; k <= note; k+=12) if(k != 36) foff *= 2;
                            
                            if (j < 8)
                            {
                                voice.tfreq    = frameLen*(440.0*Math.pow(2.0,(note-45)/12.0)+foff);
                                voice.pointqty = 1024;
                                for(i = 11; i < note; i+=12) voice.pointqty /= 2;
                                voice.makeEven = voice.pointqty <= 256;
                            }else
                            {
                                voice.tfreq    = frameLen*note*percSampleRate;
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
                    if(callBack != null) callBack();
                }
                
                var lsamp:int=0, rsamp:int=0;
                for(j = 0; j < 16; j++){
                    voice = voices[j];
                    track = song.tracks[j];
                    
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