# auto-sfz

auto-sfz defines groups and key mappings for an SFZ file based on a given directory (avoid spaces in the directory path) 
<br> 

for each subfolder in the directory, a group will be defined 
<br>  

for each audio file in the subfolder, a region will be defined (inside that group)
<br> 

audio file names must start with the note (C, C#, D, D#, E, F, F#, G, G#, A, A#, B) followed by the octave
i.e. C1, G#4 etc. 
<br>

regions are defined to "stretch" downward to cover all midi notes in between their key center and the next lowest provided sample's key center 
<br>

give it a try by running the compiled executable, or build it yourself in xcode 
<br>

have feedback on how to improve this? feel free to open an issue 
<br>

some ideas 
- figure out a spec for parsing / defining round robins 
- parse "meta data" from folder name to define group-level opcodes 

https://sfzformat.com/
