fl-OrgPlayer
============
http://www.cavestory.org/forums/index.php?/topic/2695-orgs-in-java/

AS3 port of Wedge of Cheese's Java Organya replayer. Why would anyone need one for AS3? Who knows...

Both Org-02 and Org-03 supported.



Current state:
Functional, more accurate than liborganya. Ungodly code mess.



TODO:

 *Clean up the code. Lots of things here:
 
 **Towers to pancakes; replace vertical vectors with horizontal classes.
 
 **Separate song data from playback.
 
 **Look trough all note positions for the biggest instead of using Song.loopEnd for allocating tracks.
 
 **Use bitwise operation instead of mult where 16 bit values are read.
 
 
 
 
 *Reproduce Organya's handling of melodic samples, per octave.
 
 *Replace WoC's samplebank format with own, better one.
 
 *Deal with drumsample mapping(Xerxes vs original OrgMaker v2 mapping) and 'Cave Story' mode.
 
 *Synthesize instruments from PXTs.
 
 *Port this back to C, where it's actually useful.
 
