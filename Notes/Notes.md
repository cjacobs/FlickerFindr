#  <#Notes#>

TODO:
- [x] make a RingBuffer class
- [x] keep a ring buffer of previous frame-diff values 
(actually, a timestamped buffer of a constant amount of time)    
- [ ] guess frequency based on buffer of frame diff (maybe just count, rather than fft?)
- [ ] add a picker to pick which camera
- [ ] add a slider to zoom
- [ ] HDR? maybe make a mask - everything over 1.0 == bright enough to process?
- [ ] figure out why temporal filter is so slow
