package orgPlayer.struct 
{
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    import orgPlayer.Tools;
    import orgPlayer.Cons;
    
    public class SampleBank 
    {
        //Bank format structure
        //Everything is big endian unless stated otherwise
        
        //--------------------------------------------------------
        //header sig
        //6 bytes
        public static const SIG:String = "ORGBNK";
        
        public var
        //bank version
        //1 byte
        verbank         :uint,
        
        //song version bank is made for
        //1 byte
        verorg          :uint,
        
        //number of melody samples
        //1 byte
        snumMelo        :uint,
        
        //number of drum samples
        //1 byte
        snumDrum        :uint,
        
        //length of one melody sample
        //2 bytes
        lenMelo         :uint,
        
        //table of drum sample lengths
        //4 bytes * snumDrum
        tblLenDrum      :Vector.<uint>,
        
        //table of 0-terminated drum sample name strings
        //x bytes * snumDrum
        //x <= 22
        tblNameDrum     :Vector.<String>,
        
        //melody samples
        //snumMelo * lenMelo bytes
        melody          :Vector.<ByteArray>,
        
        //drum samples
        //snumDrum * tblLenDrum[i] bytes
        drums           :Vector.<ByteArray>;
        //--------------------------------------------------------
        
        public function SampleBank(resStream:ByteArray) 
        {
            melody      = new Vector.<ByteArray>;
            drums       = new Vector.<ByteArray>;
            
            resStream.position = 0;
            resStream.endian = Endian.BIG_ENDIAN;
            //---------------------------------------------
            
            var dlen:uint;
            var i:uint, j:uint;
            
            //read sample data in from the resource file
            
            //signature
            if (resStream.readMultiByte(6, "US-ASCII") != SIG) return;
            
            //bank version
            verbank = resStream.readUnsignedByte();
            
            //Organya song version this bank is intended for
            verorg  = resStream.readUnsignedByte();
            
            //number of melody samples
            snumMelo = resStream.readUnsignedByte();
            //number of drums
            snumDrum = resStream.readUnsignedByte();
            
            //length of each melody sample
            lenMelo = 0;
            lenMelo = (lenMelo << 8) + resStream.readUnsignedByte();
            lenMelo = (lenMelo << 8) + resStream.readUnsignedByte();
            
            //drum sample length table
            tblLenDrum = new Vector.<uint>(snumDrum, true);
            for(i = 0; i < snumDrum; i++){
                dlen = 0;
                dlen = (dlen << 8) + resStream.readUnsignedByte();
                dlen = (dlen << 8) + resStream.readUnsignedByte();
                dlen = (dlen << 8) + resStream.readUnsignedByte();
                dlen = (dlen << 8) + resStream.readUnsignedByte();
                tblLenDrum[i] = dlen;
            }
            
            //drum sample names
            tblNameDrum = new Vector.<String>(snumDrum, true);
            for (i = 0; i < snumDrum; i++) {
                tblNameDrum[i] = Tools.r_0TString(resStream, 22);
            }
            
            
            //melody waves
            melody = Tools.malloc_1DVector(ByteArray, snumMelo, true);
            var b:ByteArray;
            for each( b in melody){
                if(lenMelo) resStream.readBytes(b, 0, lenMelo);
            }
            
            //drum waves
            drums = Tools.malloc_1DVector(ByteArray, snumDrum, true);
            for(i = 0; i < snumDrum; i++){
                dlen = tblLenDrum[i];
                if (dlen) resStream.readBytes(drums[i], 0, dlen);
                var drum:ByteArray = drums[i];
                for (j = 0; j < dlen; j++ ) {
                    //convert to signed byte
                    drum[j] = drum[j] + 128; // & 0xFF
                }
            }
            
            //go home
            resStream.position = 0;
        }
        
    }

}