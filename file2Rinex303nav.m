function outCell = file2Rinex303nav( fileName, varargin )
%file2Rinex303nav Function that extracts the ephemeris parameters from a BRDM unified file
% for GPS, Galileo, SBAS, GLONASS, BEIDOU, IRNSS, QZSS
%
% USAGE:
%   outCell = file2Rinex303nav( fileName );
%   outCell = file2Rinex303nav( fileName, outcell );
% 
% INPUT PARAMETERS:
%   filename                    : Filename of the ephemeris file to be read
%   outcell                     : Data structure to append the read
%                                 ephemeris data from the file
% 
% OUTPUT VARIABLE:
%   outCell                     : Data structure containing all ephemeris
%                                 parameter
%
%
%   outCell{X}{Y}               : X -> system:
%                                       GPS 1
%                                       SBAS 2
%                                       GLONASS 3
%                                       GALILEO 4
%                                       BEIDOU 5
%                                       IRNSS 6
%                                       QZSS 7
%                                 Y -> Satellite number (SVN)
%
% Version log (main changes)
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

fp=fopen(fileName,'r');
C = fscanf(fp,'%c');
fclose(fp);
end_position = strfind(C,'END OF HEADER')+19+2;

header = C(1:end_position-1);
body = reshape(C(end_position:end), 81, [])';



if(str2double(header(1,1:9))~=3.03)
    display('Rinex version does not match!');
    return
end


if(isempty(varargin))
    
    outCell = cell(7,1);
    
    outCell{1} = cell(32,1);
    outCell{2} = cell(39,1);
    outCell{3} = cell(27,1);
    outCell{4} = cell(36,1);
    outCell{5} = cell(35,1);
    outCell{6} = cell(7,1);
    outCell{7} = cell(7,1);
else
    outCell = varargin{1};
end
    
numLinesGPS = sum(body(:,1) ~= ' ');
temp = strsplit(fileName,'\');
h = waitbar(0,['Reading ephemeris file ' temp{end}]);

for ii=1:numLinesGPS
    waitbar(  ii/numLinesGPS )

    tempSatSystem = body(1,1);    
    
    switch tempSatSystem
        case 'G'
            tempSatSystem = 1;
            meas = body(1:8,:);
            body = body(9:end,:);
        case 'S'
            tempSatSystem = 2;
            meas = body(1:4,:);
            body = body(5:end,:);
        case 'R'
            tempSatSystem = 3;
            meas = body(1:4,:);
            body = body(5:end,:);
        case 'E'
            tempSatSystem = 4;
            meas = body(1:8,:);
            body = body(9:end,:);
        case 'C'
            tempSatSystem = 5;
            meas = body(1:8,:);
            body = body(9:end,:);
        case 'I'
            tempSatSystem = 6;
            meas = body(1:8,:);
            body = body(9:end,:);
        case 'J'
            tempSatSystem = 7;
            meas = body(1:8,:);
            body = body(9:end,:);
        otherwise
            tempSatSystem = 0;
    end

    if(tempSatSystem>0)
        tempSatNum = str2double(meas(1,2:3));
        tempEpoch = etime(str2num(meas(1,5:23)), [1980 01 06 00 00 00]);
        
        if(sum(tempSatSystem==[1 4 5 6 7]))
                
            a012 =  str2num(reshape(meas(1,24:80),[],3)');
            line1 = str2num(reshape(meas(2,5:80), [], 4)');
            line2 = str2num(reshape(meas(3,5:80), [], 4)');
            line3 = str2num(reshape(meas(4,5:80), [], 4)');
            line4 = str2num(reshape(meas(5,5:80), [], 4)');
            line5 = str2num(reshape(meas(6,5:80), [], 4)');
            line6 = str2num(reshape(meas(7,5:80), [], 4)');
            line7 = str2num(reshape(meas(8,5:80), [], 4)');
            
            % Following the parameter order in https://gssc.esa.int/navipedia/index.php/GPS_and_Galileo_Satellite_Coordinates_Computation
            % [GPSTime SatNum 16 epoch parameters]
            tempEphemeris = [...
                tempEpoch% toc (+ weeknum*7*24*3600)                            1
                line3(1) % toe
                line2(4) % sqrt(a)
                line2(2) % e                                                    4
                
                line1(4) % M0                                                   5
                line4(3) % omega
                line4(1) % i0
                line3(3) % omega0                                               8
                
                line1(3) % DeltaN                                               9
                line5(1) % i dot
                line4(4) % omega dot
                line2(1) % cuc                                                  12
                
                line2(3) % cus                                                  13
                line4(2) % crc
                line1(2) % crs
                line3(2) % cic                                                  16
                
                line3(4) % cis                                                  17
                a012(1)  % a0
                a012(2)  % a1
                a012(3)  % a2                                                   20
                
                line6(3) % tgd                                                  21
                ]';
        elseif(sum(tempSatSystem==[2 3]))
            timeline =  str2num(reshape(meas(1,24:80),[],3)');
            line1 = str2num(reshape(meas(2,5:80), [], 4)');
            line2 = str2num(reshape(meas(3,5:80), [], 4)');
            line3 = str2num(reshape(meas(4,5:80), [], 4)');
            
            tempEphemeris = [...
                tempEpoch% toc (+ weeknum*7*24*3600)                            1
                line1(1) % x
                line2(1) % y
                line3(1) % z                                                    4
                
                line1(2) % vx                                                   5
                line2(2) % vy
                line3(2) % vz                                                   
                line1(3) % aX                                                   8
                
                line2(3) % aY                                                   9
                line3(3) % aZ
                timeline(1) %af0
                timeline(2) %af1                                                12
                ]';
            if(tempSatSystem==2)
                tempSatNum = tempSatNum - 19;
            end
            
        end
        if(isempty(outCell{tempSatSystem}{tempSatNum}))
            outCell{tempSatSystem}{tempSatNum} = tempEphemeris;
        else
            if(sum(tempEpoch==outCell{tempSatSystem}{tempSatNum}(:,1))==0)
                outCell{tempSatSystem}{tempSatNum} = [outCell{tempSatSystem}{tempSatNum}; tempEphemeris];
            end
        end
    end
    
    
end
close(h)

end