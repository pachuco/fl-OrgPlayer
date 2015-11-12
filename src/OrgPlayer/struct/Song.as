package orgPlayer.struct 
{
    /**
     * ...
     * @author me
     */
    
    import orgPlayer.Cons;
    import orgPlayer.Tools;
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    
    public class Song 
    {
        public var
        /*uint8      */ version         :uint, //Org-02 Org-03
        /*uint16     */ wait            :uint,
        /*uint8      */ beatPerMeasure  :uint,
        /*uint8      */ clickPerBeat    :uint,
        /*uint32     */ loopStart       :uint,
        /*uint32     */ loopEnd         :uint,
        /*&tracks[16]*/ tracks          :Vector.<Track>;
        
        public function Song(orgStream:ByteArray) 
        {
            tracks = Tools.malloc_1DVector(Track, 16, true);
            
            orgStream.position = 0;
            orgStream.endian = Endian.LITTLE_ENDIAN;
            
            var track:Track;
            
            //check the first 6 bytes of the org file
            var header:String = orgStream.readMultiByte(6, Cons.charSet);
            if      (header == "Org-02") version = 2
            else if (header == "Org-03") version = 3
            else {
                version = 0;
                return;
            }
            
            var i:uint, j:uint, k:uint;
            
            //get the wait value (clickLen), start point (loopPoint), and end point (songLen)
            wait           = orgStream.readUnsignedShort();
            beatPerMeasure = orgStream.readUnsignedByte();
            clickPerBeat   = orgStream.readUnsignedByte();
            loopStart      = orgStream.readUnsignedInt();
            loopEnd        = orgStream.readUnsignedInt();
            
            //read track data
            for each (track in tracks)
            {
                track.freq       = orgStream.readUnsignedShort();
                track.instrument = orgStream.readUnsignedByte();
                track.pi         = orgStream.readUnsignedByte();
                track.trackSize  = orgStream.readUnsignedShort();
            }
            
            //for each track
            for each (track in tracks)
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
                maxPos = loopEnd > maxPos ? loopEnd : maxPos;
                
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
                for (j = 0; j < loopEnd; j++) {
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
        }
        
        
    }

}