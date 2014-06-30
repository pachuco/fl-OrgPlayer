package orgPlayer 
{
	/**
     * ...
     * @author assnuts
     */
    public class Cons 
    {
        public static const
        
        //megabytes * 1024 * 1024 / chan / ByteArrays
        arbitraryPosLimit :uint = 24 * 1024 * 1024 / 16 / 5,
        maxEvents         :uint = 4096,
        maxNote           :uint = 95,
        maxPan            :uint = 12,
        
        
        
        sampleRate:uint = 44100,
        
        charSet:String  = "us-ascii",
        
        noteFreq:Vector.<uint> = Vector.<uint>([ 
            33408, // C
            35584, // C#
            37632, // D
            39808, // D#
            42112, // E
            44672, // F
            47488, // F#
            50048, // G
            52992, // G#
            56320, // A
            59648, // A#
            63232  // B
        ]);
        
    }

}