# GPS/Galileo/Beidou/IRNSS/QZSS satellite position calculator for MATLAB

Function that computes the ECEF coordinates of the desired GPS/Galileo/Beidou/IRNSS/QZSS
satellites by automatically downloading the multiconstellation BRDM ephemeris
file from ftp://ftp.cddis.eosdis.nasa.gov. The ephemeris are stored for later reuse.

Computable dates: from 1/Jan/2013 until two days ago (to ensure the ephemeris file will be uploaded to the server).

All the contents were developed for the [passive remote sensing group (RSLab)](https://prs.upc.edu/) as a part of the [Remote Sensing Laboratory](http://www.tsc.upc.edu/en/research/rslab), a research line of the [CommmSensLab Group](http://www.tsc.upc.edu/en/research/commsenslab) at the [Signal Theory and Communications Department (TSC)](http://www.tsc.upc.edu/en) of the [Universitat Politècnica de Catalunya (UPC)](http://www.upc.edu/?set_language=en).

New versions of this program may be found at [GitHub](https://github.com/onrubia/computeSatellitePosition). 

## REQUIREMENTS
* 7-zip or Winrar : required to decompress the ephemeris files.

## CONTENT
* computeSatellitePoisition : Code that computes the ECEF satellite position from a vector of GPS times, a vector of GNSS satellites, and a vector of the GNSS systems of each satellite.

* file2Rinex303nav : Code that reads the BRDM mixed RINEX file to parse the ephemeris

* getSatECED : Code that given a time and an ephemeris computes the ECEF position

## USAGE:
  [x,y,z] = computeSatellitePoisition(gpstime, satnum, satsys, outputfolder);
	
  [x,y,z] = computeSatellitePoisition(gpstime, satnum, satsys, outputfolder, rec_pos);

**INPUT PARAMETERS:**
 * gpstime                     : GPS time in seconds
 
 * satnum                      : Satellite number
 
 * satsys                     : Satellite system (GPS 1, SBAS 2, GLONASS 3, GALILEO 4, BEIDOU 5, IRNSS 6, QZSS 7). NOTE: each satnum needs a satsys
 
 * outputfolder                : folder to store the downloaded ephemeris files (they are reused in future executions).
 
 * rec_pos                     : (optional) receiver position, for sagnac correction.

**OUTPUT VARIABLE:**
* x(ii,jj)                    : X Satellite ECEF position. Dimension ii corresponds to time,  dimension jj: corresponds to a pair of satellite number and system. 

* y(ii,jj)                    : Y Satellite ECEF position. Dimension ii corresponds to time,  dimension jj: corresponds to a pair of satellite number and system. 

* z(ii,jj)                    : Z Satellite ECEF position. Dimension ii corresponds to time,  dimension jj: corresponds to a pair of satellite number and system. 

NOTE: a NaN value in x,y,z happens when the program is not able to solve
the Kepler equation for Eccentric Anomaly with the recursive method OR
there was no ephemeris data of that particular satellite in the files
downloaded from ftp://ftp.cddis.eosdis.nasa.gov

## EXAMPLE:

To compute the satellite possition of the GPS satellites 1 and 5, and the
the satellite possition of the Galileo satellites 8 and 9, in the GPS
dates (NO LEAP SECONDS ACCOUNTED) April 30th, 2018, 03:46:40 (GPS week 1999,
GPS seconds 100000) to April 30th, 2018, 17:40:00 (GPS week 1999, GPS 
seconds 150000) in steps of 5 seconds and to store the ephemeris in
folder "gnss"

gpsweek = 1999;

gpsseconds = 100000:5:150000;

gpstime = gpsweek*(24*7*3600) + gpsseconds;

satnum = [ 1 5 8 9 ];

satsys = [ 1 1 4 4 ];

outputfolder = 'gnss';

[x,y,z] = computeSatellitePosition(gpstime, satnum, satsys, outputfolder);

## Licence
You may find a specific licence files in each directory.

## Contact
Raul Onrubia (onrubia at tsc.upc.edu)
