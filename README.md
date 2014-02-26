DSPView
=======

DSPView is a MATLAB framework for ultrasound B-mode, velocity, strain and elastographic processing. 
It has a simple GUI which lets you easily try out different estimators, filters and parameters. The output
images updates in real-time, enabling quick prototyping and making it easy to get an intuitive understanding
of the digital signal processing involved. 

![Flow_chart](http://tboerstad.github.io/DSPView/img/flow_chart.png)

Demonstration video
=======
[![Video](http://tboerstad.github.com/DSPView/img/youtube_link.png)](http://youtu.be/OepJFh9cgp4)

Screenshot
=======
![Screenshot](http://tboerstad.github.io/DSPView/img/screenshot.png)

Documentation
=======
A [quickstart guide](documentation/quickstart.pdf) can be found in the documentation folder.

The .m files themselves have comments, and support the default MATLAB help system ("help DSPView")

The underlaying estimators and algorithms are documented in the master's thesis,
[Intraoperative Ultrasound Strain Imaging of Brain Tumors](http://bit.ly/GNmyhO), 
for which DSPView was developed. 

The thesis also references a paper [comparing ultrasound velocity estimators](http://github.com/tboerstad/DSPView/blob/gh-pages/doc/Comparison_of_three_ultrasound_velocity_estimators_for_strain_imaging_of_the_brain.pdf)
