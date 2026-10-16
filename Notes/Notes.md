#  <#Notes#>

TODO:
- [x] make a RingBuffer class
- [x] keep a ring buffer of previous frame-diff values 
(actually, a timestamped buffer of a constant amount of time)    
- [x] add a view showing where in the timeline the high-diff frames are
- [ ] guess frequency based on buffer of frame diff (maybe just count, rather than fft?)
- [ ] add a picker to pick which camera
- [ ] add a slider to zoom
- [ ] HDR? maybe make a mask - everything over 1.0 == bright enough to process?
- [ ] figure out why temporal filter is so slow
- [ ] write metal shaders for temporal filter, et al
- [ ] refactor things so that previews work
- [ ] subsample input image if blur is big enough

TODO?:
- [ ] use `CMTime` timestamps instead of `Date`?
- [ ] 

Info on implementing sheet views:
https://21zerixpm.medium.com/bottom-sheets-in-swiftui-modal-presentations-done-right-bc4ab6825d02
https://www.createwithswift.com/exploring-interactive-bottom-sheets-in-swiftui/

Info on writing metal image filters:
https://www.createwithswift.com/custom-parameters-and-animation-with-metal-shaders/

TODO (for previews): get rid of view dependencies on whole model, just use the parts they need(?)



