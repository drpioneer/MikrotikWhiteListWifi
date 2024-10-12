# Script for blocking unknown wifi clients by drPioneer
# https://forummikrotik.ru/viewtopic.php?p=91303#p91303
# tested on ROS 6.49.17 (capsman) & ROS 7.16 (wifiwave2 or wifi-qcom)
# updated 2024/10/12

:do {
  :local AvailableWifiwave2 do={ # wifiwave2 package search function
    :local counter 0;
    :local package "";
    :do {
      :set $package ([system package print as-value]->$counter->"name");
      :if ($package="wifiwave2") do={:return "/interface wifiwave2"}
      :if ($package="wifi-qcom") do={:return "/interface wifi"}
      :set $counter ($counter+1);
    } while ([:len $package]!=0);
    :return "/caps";
  }

  :local ReplacingChars do={ # character replacement function
    :if ([:typeof $1]!="str" or [:len $1]=0) do={:return ""}
    :local source {"\22"};
    :local destin {"\27"};
    :local result "";
    :for i from=0 to=([:len $1]-1) do={
      :local char [:pick $1 $i];
      :local index [:find $source $char];
      :if ($index>-1) do={:set $char [:pick $destin $index]};
      :set $result "$result$char";
    }
    :return $result;
  }

  # main body of the script
  :local counter 0;
  :local interface [$AvailableWifiwave2];
  :local reject [[:parse "$interface access-list find action=reject"]];
  :if ([:len $reject]!=0) do={[[:parse "$interface access-list remove $reject"]]}
  :if ([:len [/ip dhcp-server lease find]]=0) do={:put ("Wifi clients not found in DHCP list.")}
  :put ("List of allowed wifi clients:");
  :foreach wlanClients in=[/ip dhcp-server lease find comment~"wifi"] do={
    :local presence false;
    :local wlanMAC ([/ip dhcp-server lease get $wlanClients mac-address]);
    :local wlanComment ([$ReplacingChars [/ip dhcp-server lease get $wlanClients comment]]);
    :set $counter ($counter+1);
    :put ("$counter $wlanMAC $wlanComment");
    :foreach accessList in=[[:parse "$interface access-list find"]] do={
      :local accessMAC ([[:parse "$interface access-list get $accessList mac-address"]]);
      :if ($wlanMAC=$accessMAC) do={:set $presence true}
    }
    :if (!$presence) do={[[:parse "$interface access-list add mac-address=$wlanMAC comment=\"$wlanComment\" action=accept"]]}
  }
  [[:parse "$interface access-list add action=reject"]];
} on-error={ # when emergency break script ->
    :put "Script error something didn't work when generating a list of allowed WIFI clients";
}
