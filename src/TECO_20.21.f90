162
if (use_plinit .eq. 11 .or. use_plinit .eq. 12) then
stdm=1.8!1.6!stdm shallow layer conc std
stdmc=stdm!1.6!stdmc deep layer conc std
elseif (use_plinit .eq. 14) then
stdm=2.25!2.
stdmc=stdm!2.
else
stdm=2.7!2.4
stdmc=stdm
endif

172
if (use_plinit .eq. 11 .or. use_plinit .eq. 12) then
stdm=1.6!1.6!stdm shallow layer conc std
stdmc=stdm!1.6!stdmc deep layer conc std
elseif (use_plinit .eq. 14) then
stdm=2.!2.
stdmc=stdm!2.
else
stdm=2.4!2.4
stdmc=stdm
endif
