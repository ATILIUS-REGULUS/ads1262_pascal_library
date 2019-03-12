# Pascal library for ADS1262 on Raspberry Pi 3B

### Connection
The following connection is used between ads1262 and the Raspberry Pi:

![images/raspberry_ads1262_library_steckplatine_transparent.png](images/raspberry_ads1262_library_steckplatine_transparent.png)<br>

### Source Code
The source code was developed with codetyphon on the Raspberry Pi 3B, but should also work with Lazarus.

### Compiling
The file go.sh can be used for compiling, please check the path inside go.sh and adept it to your own source path.

### License
GNU LESSER GENERAL PUBLIC LICENSE Version 3, 29 June 2007

### Comments
The configuration uses AIN0 and AINCOM for the input signals. Please note that this configuration expects that the input signals are differential inputs which are not coupled to a potential of the ADC, e.g. a coil.
The AINCOM input is then coupled by VBIAS mode to a level shift voltage : VBIAS = (AVDD + AVSS) / 2.<br />
This source code was developed for a seismometer project.<br />
More information at http://www.seismometer.info.

### Contact info
Author  : Dr. Jürgen Abel<br />
Website : https://www.juergen-abel.info/<br />
