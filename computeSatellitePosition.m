function [x,y,z] = computeSatellitePosition(gpstime, satnum, satsys, outputfolder, varargin)
% Function that computes the ECEF coordinates of the desired GPS/Galileo/Beidou/IRNSS/QZSS
% satellites by automatically downloading the multiconstellation BRDM ephemeris
% file from ftp://ftp.cddis.eosdis.nasa.gov. Requires 7zip or WinRar to decompress
% the downloaded ephemeris files. The ephemeris are stored for later reuse.
%
% USAGE:
%   [x,y,z] = computeSatellitePoisition(gpstime, satnum, satsys, outputfolder);
%   [x,y,z] = computeSatellitePoisition(gpstime, satnum, satsys, outputfolder, rec_pos);
% 
% INPUT PARAMETERS:
%   gpstime                     : GPS time in seconds
%   satnum                      : Satellite number
%   satsys                      : Satellite system 
%                                       GPS 1
%                                       SBAS 2
%                                       GLONASS 3
%                                       GALILEO 4
%                                       BEIDOU 5
%                                       IRNSS 6
%                                       QZSS 7
%                               NOTE: each satnum needs a satsys
%   outputfolder                : folder to store the downloaded ephemeris
%                                 files (they are reused in future
%                                 executions).
%   rec_pos                     : (optional) receiver position, for sagnac correction.
%
% OUTPUT VARIABLE:
%   x(ii,jj)                    : X Satellite ECEF position
%                                   dimension ii: corresponds to time
%                                   dimension jj: corresponds to a pair of
%                                   satellite number and system
%   y(ii,jj)                    : Y Satellite ECEF position
%                                   dimension ii: corresponds to time
%                                   dimension jj: corresponds to a pair of
%                                   satellite number and system
%   z(ii,jj)                    : Z Satellite ECEF position
%                                   dimension ii: corresponds to time
%                                   dimension jj: corresponds to a pair of
%                                   satellite number and system
%
% NOTE: a NaN value in x,y,z happens when the program is not able to solve
% the Kepler equation for Eccentric Anomaly with the recursive method OR
% there was no ephemeris data of that particular satellite in the files
% downloaded from ftp://ftp.cddis.eosdis.nasa.gov
%
% EXAMPLE:
% To compute the satellite possition of the GPS satellites 1 and 5, and the
% the satellite possition of the Galileo satellites 8 and 9, in the GPS
% dates (NO LEAP SECONDS ACCOUNTED) April 30th, 2018, 03:46:40 (GPS week 1999,
% GPS seconds 100000) to April 30th, 2018, 17:40:00 (GPS week 1999, GPS 
% seconds 150000) in steps of 5 seconds and to store the ephemeris in
% folder "gnss"
% 
% gpsweek = 1999;
% gpsseconds = 100000:5:150000;
% gpstime = gpsweek*(24*7*3600) + gpsseconds;
% satnum = [ 1 5 8 9 ];
% satsys = [ 1 1 4 4 ];
% outputfolder = 'gnss';
% [x,y,z] = computeSatellitePosition(gpstime, satnum, satsys, outputfolder);
% 
% 
% % Version log (main changes)
%   21/03/2019 --> Log started
%--------------------------------------------------------------------------
% Author: Raul Onrubia (onrubia [at] tsc.upc.edu) 
% Copyright 2019 Raul Onrubia
% License: GNU GPLv3
%==========================================================================
% Copyright 2019 Raul Onrubia
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

gpstime = gpstime(:);
satnum = satnum(:);
satsys = satsys(:);

gpstime = gpstime((gpstime> seconds(datetime(2013,1,1) - datetime(1980,1,6))) & (gpstime< (seconds(datetime('now')-datetime(1980,1,6))- 48*3600) ));

if(isempty(gpstime))
    disp('GPSTime out of the limits [Jan 1st, 2013 -> Today - 48h]')
    return
elseif(length(satnum)~=length(satsys))
    disp('Wrong satmnum & satsys format : For each satnum there must be a satsys')
    return
end
    

x = nan(length(gpstime), length(satnum));
y = nan(length(gpstime), length(satnum));
z = nan(length(gpstime), length(satnum));

newDates = datetime(1980,1,6) + seconds(gpstime);

requiredDays = num2str(day(newDates,'dayofyear'));
requiredDays(requiredDays==' ')='0';

addressString = [repmat('gnss/data/campaign/mgex/daily/rinex3/', [length(newDates) 1]) num2str(year(newDates)) repmat('/brdm/brdm', [length(newDates) 1]) requiredDays repmat('0.18p.Z', [length(newDates) 1])];
addressString = unique(addressString, 'rows');
filenamesToDownload = addressString(:,48:end);

firstime = 1;
for ii=1:size(addressString,1)
    
    if ~isfile(['gnss\' filenamesToDownload(ii,1:end-2)])
         if(firstime == 1)
             ftpobj = ftp('ftp.cddis.eosdis.nasa.gov');
             [uncompressfilename, uncompressfilepath] = uigetfile('.exe', 'Select a 7zip/WinRAR Tool');
             firstime = 0;
         end
         mget(ftpobj,addressString(ii,:));    
         movefile(addressString(ii,:), ['gnss\' filenamesToDownload(ii,:)])
    end
end

if(firstime==0)
    [~, ~] = rmdir('gnss\*', 's');

    outputfolder(outputfolder=='/') = '\';

    if(strcmp(uncompressfilename, 'Rar.exe') || strcmp(uncompressfilename, 'UnRar.exe'))
        uncompressfilename = 'WinRAR.exe';
    end

    if(strcmp(uncompressfilename, '7z.exe'))
        system(['"' uncompressfilepath uncompressfilename '" e ' pwd '\gnss\*.Z -y -o' outputfolder])
    elseif(strcmp(uncompressfilename, 'WinRAR.exe'))
        system(['"' uncompressfilepath uncompressfilename '" e -y gnss\*.Z ' outputfolder])
    else
        disp('Unsuported Unzip Tool')
        disp('Get 7zip for free from:')
        disp('           https://www.7-zip.org/download.html')
        disp('OR Get WinRar from:')
        disp('           https://www.winrar.es/descargas')
        return
    end

    delete('gnss\*.Z')
    info = dir('gnss');
    if(size(info,1)==2)
        rmdir('gnss', 's');
    end
end


allEphemerisData = file2Rinex303nav([outputfolder '\' filenamesToDownload(1,1:end-2)]);


for ii=2:size(filenamesToDownload,1)
    allEphemerisData = file2Rinex303nav([outputfolder '\' filenamesToDownload(ii,1:end-2)], allEphemerisData);
end


h = waitbar(0,'Computing ECEF coordinates');

totalel = length(satnum) * length(gpstime);

for ii=1:length(satnum)
    if(ismember(satsys(ii), [1 4 5 6 7 ]))
        if(~isempty(allEphemerisData{satsys(ii)}{satnum(ii)}))
            satEphData = allEphemerisData{satsys(ii)}{satnum(ii)};


            for jj=1:length(gpstime)
                if(numel(satEphData)>20)
                    [~,pos] = min(abs(satEphData(:,1) - gpstime(jj)));
                    satEphData = satEphData(pos,:);
                end

                gpssecofweek = mod(gpstime(jj), 7*24*3600);
                
                if(isempty(varargin))
                    sat_ecef = getSatECEF(gpssecofweek,satEphData);
                else
                    sat_ecef = getSatECEF(gpssecofweek,satEphData, varargin{1});
                end

                x(jj, ii) = sat_ecef(1);
                y(jj, ii) = sat_ecef(2);
                z(jj, ii) = sat_ecef(3);
                
                waitbar(((ii-1)*length(gpstime)+(jj))/totalel);
            end
        end
    end
   waitbar(((ii-1)*length(gpstime)+(jj))/totalel);
end
close(h);


end

