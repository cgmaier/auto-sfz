# auto-sfz

auto-sfz defines groups and key mappings for an SFZ file based on a given directory (avoid spaces in the directory path) 
<br> 

for each subfolder in the directory, a group will be defined 
<br>  

for each audio file in the subfolder, a region will be defined (inside that group)
<br> 

audio file names must start with or preceed an underscore with the note name (C, C#, D, D#, E, F, F#, G, G#, A, A#, B) immediately followed by the octave number 
i.e. C1.wav, flutes_G#4.wav etc. 
<br>

regions span downward in order to cover all unnacounted-for midi notes between their key center and the next lowest provided region's key center 
<br>

give it a try by running the compiled executable, or build it yourself in xcode 
<br>

have feedback on how to improve this? feel free to open an issue 
<br>

some ideas 
- figure out how to generate round-robins  
- parse folder name for group-level opcodes

https://sfzformat.com/
