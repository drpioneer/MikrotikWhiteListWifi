
# Script for blocking unknown wifi clients by drPioneer
# https://forummikrotik.ru/viewtopic.php?p=82674#p82674
# tested on ROS 6.49
# updated 2021/12/09

:if ([:len [ /ip dhcp-server lease find comment~"wifi"; ]] = 0) do={ 
    :put ("Wifi clients not found in DHCP list."); 
} else={
    :if ([:len [ /caps access-list find comment="Blocking unknown wifi clients" action=reject; ]] > 0) do={ 
        /caps access-list remove [ /caps access-list find comment="Blocking unknown wifi clients" action=reject ]; 
    }
    :foreach wlanClients in=[ /ip dhcp-server lease find comment~"wifi"] do={
        :local wlanMAC     ([ /ip dhcp-server lease get $wlanClients mac-address; ]);
        :local wlanComment ([ /ip dhcp-server lease get $wlanClients comment; ]);
        :local counter 0;
        :foreach accessList in=[ /caps access-list find; ] do={
            :local accessMAC  ([ /caps access-list get $accessList mac-address; ]);
            :if ($wlanMAC = $accessMAC) do={ :set counter ($counter + 1); }
        } 
        :if (counter = 0) do={ 
            /caps access-list add mac-address=$wlanMAC comment=$wlanComment action=accept; 
        }
    }
    /caps access-list add comment="Blocking unknown wifi clients" action=reject;
}
