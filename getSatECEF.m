function sat_ecef = getSatECEF(t,eph, varargin)
%getSatECEF Function that computes the ECEF coordinates of satellites using 16 epehemeris data.
%
% USAGE:
%   sat_ecef = getSatECEF(t,eph);
%   sat_ecef = getSatECEF(t,eph, rcv_ecef);
% 
% INPUT PARAMETERS:
%   t                           : GPS time in seconds of the current week
%   eph                         : Satellite ephemeris
%   rcv_ecef                    : rec_ecef position for sagnac error correction 
% 
% OUTPUT VARIABLE:
%   sat_ecef(1:3)               : Satellite ECEF position (X,Y,Z)
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
%
%
% Code Based on The Essential GNSS Project: http://gnsstk.sourceforge.net/index.html
%
% Copyright (c) 2007, refer to 'author' doxygen tags in the source code
% Point of Contact: Glenn D. MacGougan <glenn_macgougan at users.sourceforge.net>
% 
% Redistribution and use in source and binary forms, with or without modification, are permitted provided the following conditions are met:
% 
%    o Redistributions of source code must retain the above copyright notice,
%      this list of conditions and the following disclaimer.
%    o Redistributions in binary form must reproduce the above copyright notice,
%      this list of conditions and the following disclaimer in the documentation
%      and/or other materials provided with the distribution.
%    o The name(s) of the contributor(s) may not be used to endorse or promote
%      products derived from this software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR
% IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
% OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
% NO EVENT SHALL THE CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
% OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
% WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE. 

if(~isempty(varargin))
    rcv_ecef = varargin{1};
    rcv_ecef = rcv_ecef(:)';
    range = 0.070;
    limit_iter = 2;
else
    rcv_ecef = [0 0 0];
    range = 0;
    limit_iter = 1;
end

% Speed of light
c = 2.99792458e8;

% Earth's universal gravitational parameter, m^3/s^2
% mu = 3.986004418e14;
mu = 3.986005e14;

% earth rotation rate, rad/s
Omegae_dot = 7.2921151467e-5;

% ephemeris parameters
toc         =  mod(eph(1), 7*24*3600);
toe         =  eph(2);
sqrta       =  eph(3);
ecc         =  eph(4);
M0          =  eph(5);
omega       =  eph(6);
i0          =  eph(7);
Omega0      =  eph(8);
deltan      =  eph(9);
idot        =  eph(10);
Omegadot    =  eph(11);
cuc         =  eph(12);
cus         =  eph(13);
crc         =  eph(14);
crs         =  eph(15);
cic         =  eph(16);
cis         =  eph(17);
af0         =  eph(18);
af1         =  eph(19);
af2         =  eph(20);
tgd         =  eph(21);

% Semi-major axis
A = sqrta.^2; 

% Computed Mean Motion
n0 = sqrt(mu/(A.^3));

% Time from ephemeris reference epoch
tk = t - toe;
if (tk>302400)
    tk = tk - 2*302400;
elseif(tk<-302400)
    tk = tk + 2*302400;
end

% Time of clock
tc = t - toc;
if (tc>302400)
    tc = tc - 2*302400;
elseif(tc<-302400)
    tc = tc + 2*302400;
end

% Corrected mean motion
n = n0 + deltan;

% mean anomaly at t
M = M0 + n*tk;

% Kepler equation for Eccentric Anomaly
E_old = M;
dE = 1;
% while (dE > 1e-12)
jj = 1;
while (dE > 1e-11)
  E = M + ecc*sin(E_old);
  dE = abs(E-E_old);
  E_old = E;
  jj = jj +1;
  if(jj>10)
      sat_ecef = [NaN; NaN; NaN];
      return
  end
end

% Relativistic correction
dtr = -2*sqrt(mu)/(c.^2) * ecc * sqrta * sin(E);

% Clock bias
dt =  af0 + af1*tc + af2*tc^2 - tgd + dtr;



% Time from ephemeris reference epoch
tk = t - toe + dt;
if (tk>302400)
    tk = tk - 2*302400;
elseif(tk<-302400)
    tk = tk + 2*302400;
end

for ii=1:limit_iter
    % mean anomaly at t
    M = M0 + n*tk;
    
    % Kepler euqation for Eccentric Anomaly
    E_old = M;
    dE = 1;
    % while (dE > 1e-12)
    jj = 1;
    while (dE > 1e-11)
        E = M + ecc*sin(E_old);
        dE = abs(E-E_old);
        E_old = E;
        jj = jj +1;
        if(jj>10)
            sat_ecef = [NaN; NaN; NaN];
            return
        end
    end
    
    
    % True anomaly
    vk = atan2(sqrt(1-ecc^2)*sin(E), cos(E)-ecc);
    
    % Argument of latitude
    phik = omega + vk;
    phik = rem(phik,2*pi);

    % Second harmonic perturbations
    delta_uk = cus*sin(2*phik) + cuc*cos(2*phik);
    delta_rk = crs*sin(2*phik) + crc*cos(2*phik);
    delta_ik = cis*sin(2*phik) + cic*cos(2*phik);
    
    % Corrected argument of latitude
    u_k = phik + delta_uk;
    
    % Corrected radius
    rk = A*(1-ecc*cos(E)) + delta_rk;
    
    % Corrected inclination
    ik = i0 + idot*tk + delta_ik;
    
    x_kp = rk*cos(u_k);
    y_kp = rk*sin(u_k);
    
    % longitude of ascending node
    Omega_k = Omega0 + (Omegadot-Omegae_dot)*tk - Omegae_dot*(toe+range);
    
    sat_ecef = [...
        x_kp * cos(Omega_k) - y_kp * cos(ik) * sin(Omega_k)
        x_kp * sin(Omega_k) + y_kp * cos(ik) * cos(Omega_k)
        y_kp * sin(ik)
        ];  
    
    range = norm(rcv_ecef-sat_ecef') / c;
end






