The dataset "elastographic_phantom_rec.mat" is a recording of on an elastographic
phantom. The phantom has a stiff inclusion slightly north-west of the center of the image,
which is only visible when you enable elastographic processing. 

The recording was made by compressing and decompressing the phantom by hand, using the 
ultrasound probe to push down on the phantom. Due to me being human, the motion is non-ideal.
There is some movement in the lateral direction, causing decorrelation of the RF-data,
 and the axial movement is also not perfectly periodic.

File format:
Due to licensing issues, the support for reading .rf file formats was removed.
DSPview now expects a .mat file with the following variables:

rf_data_set               : A three dimensional matrix. 1st dimension (rows) is depth,
	                    2nd (column) is lateral (sideways) and 3rd is slow-time. 
pulse_repetition_frequency: The frequency between scans in the same scan line (column)
rf_sampling_frequency     : The sampling frequency in the depth dimension
transducer_pitch          : The lateral distance between scan lines. 
