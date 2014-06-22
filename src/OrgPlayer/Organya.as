package OrgPlayer{
    import flash.utils.Endian;
    import flash.utils.ByteArray;
    import flash.utils.*;
	/**
     * ...
     * @author me
     */
    public class Organya{
        
        public var isSongLoaded:Boolean = false;
        
        private var
            orgVersion      :uint,
            
            melody          :Vector.<ByteArray>,
            drums           :Vector.<ByteArray>,
            
            clickLen        :int,
            loopPoint       :int,
            songLen         :int,
            sample          :int=0,
            click           :int=0,
            percSampleRate  :int,
            
            instruments     :Vector.<int>,
            tracksizes      :Vector.<int>,
            periodsLeft     :Vector.<int>,
            pointqty        :Vector.<int>,
            
            data            :Vector.<Vector.<int>>,
            
            tactive         :Vector.<Boolean>,
            pi              :Vector.<Boolean>,
            makeEven        :Vector.<Boolean>,
            
            tfreq           :Vector.<Number>,
            tpos            :Vector.<Number>,
            freqoff         :Vector.<Number>,
            
            lvol            :Vector.<Number>,
            rvol            :Vector.<Number>;
            
        private var frameLen                :Number;
        
        private static const freqDivisor    :int=256;
        private static const sampleRate     :Number=44100;
        
        private static function unsign(b:int):int{
            if(b<0) b+=256;
            return b;
        }
        
        private static function   sign(b:int):int{
            if(b>=128) b-=256
            return b;
        }
        
        
        private static function interpretVol(vol:Number):Number{
            return Math.pow(10,vol-1);
        }
        
        //do not call this method during playback
        //adding the "sychronized" keyword to both this method and the getSampleFrame method would allow it
        //but that might also cause liveness issues
        public function reset():void{
            sample=click=0;
            periodsLeft = new Vector.<int>    ( 16, true );
            tactive     = new Vector.<Boolean>( 16, true );
            tfreq       = new Vector.<Number> ( 16, true );
            tpos        = new Vector.<Number> ( 16, true );
            lvol        = new Vector.<Number> ( 16, true );
            rvol        = new Vector.<Number> ( 16, true );
            pointqty    = new Vector.<int>    ( 8 , true );
            makeEven    = new Vector.<Boolean>( 8 , true );
        }
        
        public function Organya(resStream:ByteArray){ 
            
            melody      = new Vector.<ByteArray>;
            drums       = new Vector.<ByteArray>;
            
            resStream.position=0;
            resStream.endian = Endian.LITTLE_ENDIAN;
            //---------------------------------------------
            frameLen=1.0/sampleRate;
            
            //read sample data in from the resource file
            var mqty:int=resStream.readUnsignedByte();
            var mlen:int=0;
            var i:int, j:int;
            
            for(i=0;i<3;i++){mlen*=256;mlen+=resStream.readUnsignedByte()}
            
            //melody=new byte[mqty][mlen];
            //butt[outer][inner];
            melody=Tools.pool1DVector(ByteArray, mqty, true);
            
            var b:ByteArray;
            for each( b in melody){
                if(mlen)resStream.readBytes(b, 0, mlen);
            }
            drums=Tools.pool1DVector(ByteArray, resStream.readUnsignedByte(), true);
            
            percSampleRate=256*resStream.readUnsignedByte();
            percSampleRate+=resStream.readUnsignedByte();
            for(i=0;i<drums.length;i++){
                mlen=0;
                for(j=0;j<3;j++){
                    mlen*=256;
                    mlen+=resStream.readUnsignedByte();
                }
                if(mlen) resStream.readBytes(drums[i], 0, mlen);
            }
            //resStream.close();
            resStream.position=0;
        }
        
        public function loadSong(orgStream:ByteArray):Boolean{
            orgStream.position=0;
            orgStream.endian = Endian.LITTLE_ENDIAN;
            
            //check the first 6 bytes of the org file
            var header:String = orgStream.readMultiByte(6, "us-ascii");
            if      (header == "Org-02") orgVersion=2
            else if (header == "Org-03") orgVersion=3
            else    return false;
            
            var i:int, j:int, k:int;
            sample      = 0;
            click       = 0;
            data        = new Vector.<Vector.<int>>;
            pi          = new Vector.<Boolean>( 16, true );
            freqoff     = new Vector.<Number> ( 16, true );
            reset();
            
            //an array to temporarily store small chunks of data from the org file
            var stuff:ByteArray=new ByteArray();
            
            //read 12 bytes of data into the array
            orgStream.readBytes(stuff,0,12);
            
            //get the wait value (clickLen), start point (loopPoint), and end point (songLen)
            clickLen=int(sampleRate*(stuff[0]+256*stuff[1])/1000.0+.5);
            loopPoint=stuff[4]+256*stuff[5];
            songLen=stuff[8]+256*stuff[9];
            
            //read track data
            instruments = new Vector.<int>( 16, true );
            tracksizes  = new Vector.<int>( 16, true );
            for(i=0;i<16;i++){
                //read and process the "freq" value
                var freq:int=orgStream.readUnsignedByte();
                freq+=orgStream.readUnsignedByte()*256;
                freqoff[i]=(freq-1000.0)/freqDivisor;
                
                instruments[i]=orgStream.readUnsignedByte();
                orgStream.readBytes(stuff,0,3);
                tracksizes[i]=stuff[1]+256*stuff[2];
                pi[i]=stuff[0]>0;
            }
            
            //read event data
            //data=new int[16][songLen];
            //data=_newData( 16, songLen);
            data=Tools.pool2DVector(int, 16, songLen, true);
            
            
            //for each track
            for(i=0;i<16;i++){
                var volume:int=0,hold:int=0,pan:int=0;
                //tracksizes[i] is the number of events (resources) for track i
                for(j=0;j<tracksizes[i];j++){
                    //read the time that the event occurs
                    orgStream.readBytes(stuff,0,4);
                    var time:int=stuff[0]+256*stuff[1];
                    
                    //put a "marker" in the data array indicating that there is an event there
                    if(time<songLen) data[i][time]=1;
                }
                
                //read all resource data for this track into the resdata array
                //4 bytes per resource: note, duration, volume, pan
                var resdata:ByteArray=new ByteArray();
                if(tracksizes[i]) orgStream.readBytes(resdata,0,tracksizes[i]*4);
                //index keeps track of which resource is next to be processed
                var index:int=0;
                
                //for each "click" in the song
                for(j=0;j<songLen;j++){
                    var note:int=255;
                    
                    //if this track has a resource at this position in the song
                    if(data[i][j]==1){
                        //store the 4 bytes for this resource into the stuff array 
                        for(k=0;k<4;k++) stuff[k]=resdata[index+tracksizes[i]*k];
                        
                        index++;
                        
                        //for note, volume, and pan, a value of 255 indicates no change
                        
                        //if the note changes, set the value of hold to the duration,
                        //and mark that the sound should be re-triggered at this point
                        note=stuff[0];
                        if(note<255) hold=stuff[1];
                        
                        //get the volume and pan values
                        var v:int=stuff[2];
                        if(v<255) volume=v;
                        var p:int=stuff[3];
                        if(p<255) pan=p;
                    }
                    
                    //the variable hold keeps track of how much longer the note needs to be held
                    //I use the note value 256 to indicate the note release
                    if(note==255 && hold>0){hold--;}
                    if(hold==0) note=256;
                    
                    //store the note, volume, and pan into the data array
                    data[i][j]=65536*note+256*volume+pan;
                }
            }
            //orgStream.close();
            orgStream.position=0;
            return isSongLoaded = true;
        }
        
        public function getSampleHunk(outBuf:ByteArray, numSamples:int):void{
            outBuf.endian = Endian.LITTLE_ENDIAN;
            var i:int, j:int, k:int, l:int;
            for(l=0;l<numSamples;l++){
                //the variable sample keeps track of which sample is currently being played
                //increment it and check if it was a multiple of clickLen before being incremented
                //if it is, move to the next click and process any data for that click
                if((sample++)%clickLen==0){
                    //for each track
                    for(j=0;j<16;j++){
                        //get the note, volume, and pan values for this track at this click
                        var tvolume:int=(data[j][click]%65536)/256;
                        var note:int=data[j][click]/65536;
                        var tpan:Number=(data[j][click]%256-6)/6.0;
                        lvol[j]=rvol[j]=255*interpretVol(tvolume/255.0);
                        if(tpan<0) rvol[j]*=interpretVol(1+tpan);
                        if(tpan>0) lvol[j]*=interpretVol(1-tpan);
                        
                        if(note==256 && j<8) tactive[j]=false;
                        if(note<255){
                            if(pi[j]){
                                periodsLeft[j]=4;
                                for(i=11;i<note;i+=12) periodsLeft[j]+=4;
                            }
                            tactive[j]=true;
                            tpos[j]=0.0;
                            var foff:Number=freqoff[j];
                            for(k=24;k<=note;k+=12) if(k!=36) foff*=2;
                            tfreq[j]=frameLen*(j<8? 440.0*Math.pow(2.0,(note-45)/12.0)+foff:note*percSampleRate);
                            if(j<8){
                                pointqty[j]=1024;
                                for(i=11;i<note;i+=12) pointqty[j]/=2;
                                makeEven[j]=pointqty[j]<=256;
                            }
                        }
                    }
                    //increment click
                    //check to see if we've reached the end of the song, and loop back if so
                    if(++click==songLen){
                        click=loopPoint;
                        sample=click*clickLen+1;
                    }
                }
                
                var lsamp:int=0, rsamp:int=0;
                for(j=0;j<16;j++){
                    if(tactive[j]){
                        var ins:int=instruments[j];
                        var samp1:int,samp2:int,pos:Number=tpos[j];
                        var pos1:int, pos2:int
                        if(j<8){
                            var size:int=pointqty[j];
                            pos*=size;
                            pos1=uint(pos);
                            pos-=pos1;
                            pos2=pos1+1;
                            if(pos2==size) pos2=0;
                            if(makeEven[j]){pos1-=pos1%2;pos2-=pos2%2;}
                            samp1=sign(melody[ins][uint((pos1*256)/size)]);
                            samp2=sign(melody[ins][uint((pos2*256)/size)]);
                        }else{
                            pos1=uint(pos);
                            pos-=pos1;
                            var drum:ByteArray=drums[ins];
                            samp1=sign(drum[pos1++]);
                            samp2=pos1<drum.length? sign(drum[pos1]):0;
                        }
                        
                        //do interpolation
                        var samp:Number=(samp1+pos*(samp2-samp1));
                        
                        //multiply the sample frame by the left and right volume, and add it to the output
                        lsamp+=lvol[j]*samp;
                        rsamp+=rvol[j]*samp;
                        
                        tpos[j]+=tfreq[j];
                        while(tpos[j]>=1.0 && j<8 && tactive[j]){
                            tpos[j]--;
                            if(pi[j]) if(--periodsLeft[j]==0) tactive[j]=false;
                        }
                        if(j>=8) if(tpos[j]>=drums[ins].length) tactive[j]=false;
                    }
                }
                outBuf.writeFloat(rsamp/0xFFFF);
                outBuf.writeFloat(lsamp/0xFFFF);
            }
        }
    }
}