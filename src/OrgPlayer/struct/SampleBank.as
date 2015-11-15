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
        //header sig                                            6 bytes
        public static const MAGIC:String = "ORGBNK";
        public var
        //bank version                                          1 byte
        verbank         :uint,
        //song version bank is made for                         1 byte
        verorg          :uint,
        //number of melody samples                              1 byte
        snumMelo        :uint,
        //number of drum samples                                1 byte
        snumDrum        :uint,
        //length of one melody sample                           2 bytes
        lenMelo         :uint,
        //table of drum sample lengths                          4 bytes * snumDrum
        tblLenDrum      :Vector.<uint>,
        //table of 0-terminated drum sample name strings        x bytes * snumDrum; x <= 22
        tblNameDrum     :Vector.<String>,
        //melody samples                                        snumMelo * lenMelo bytes
        melody          :Vector.<int>,
        //drum samples                                          snumDrum * tblLenDrum[i] bytes
        drums           :Vector.<int>;
        //--------------------------------------------------------
        
        //not in file structure
        //drum offsets
        public var tblOffDrum:Vector.<uint>;
        //length of all drum samples together
        public var lenAllDrm:uint;
        
        public function SampleBank(resStream:ByteArray) 
        {
            resStream.position = 0;
            resStream.endian = Endian.BIG_ENDIAN;
            //---------------------------------------------
            
            var dlen:uint;
            var i:uint, j:uint;
            var b:ByteArray, x:int, off:uint;
            
            //read sample data in from the resource file
            
            //signature
            if (resStream.readMultiByte(6, "US-ASCII") != MAGIC) return;
            
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
            
            //drum sample length and offset tables
            tblLenDrum = new Vector.<uint>(snumDrum, true);
            tblOffDrum = new Vector.<uint>(snumDrum, true);
            lenAllDrm = 0;
            off = 0;
            for(i = 0; i < snumDrum; i++){
                dlen = 0;
                dlen = (dlen << 8) + resStream.readUnsignedByte();
                dlen = (dlen << 8) + resStream.readUnsignedByte();
                dlen = (dlen << 8) + resStream.readUnsignedByte();
                dlen = (dlen << 8) + resStream.readUnsignedByte();
                tblLenDrum[i] = dlen;
                lenAllDrm += dlen;
                //offsets
                tblOffDrum[i] = off;
                off += dlen;
            }
            
            //drum sample names
            tblNameDrum = new Vector.<String>(snumDrum, true);
            for (i = 0; i < snumDrum; i++) {
                tblNameDrum[i] = Tools.r_0TString(resStream, 22);
            }
            
            
            //melody waves
            melody = new Vector.<int>(snumMelo * lenMelo);
            b = new ByteArray();
            resStream.readBytes(b, 0, snumMelo * lenMelo);
            for (i = 0; i < snumMelo * lenMelo; i++) {
                x = b[i];
                if(x >= 128) x -= 256
                melody[i] = x;
            }
            
            //drum waves
            drums = new Vector.<int>(lenAllDrm);
            b = new ByteArray();
            resStream.readBytes(b, 0, lenAllDrm);
            for (i = 0; i < lenAllDrm; i++) {
                x = b[i];
                x = x - 128;
                drums[i] = x;
            }
            //go home
            resStream.position = 0;
        }
        
    }

}