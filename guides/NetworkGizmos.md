# Network Gismos! 

Hello! Thank you for coming! We're going to look at three different tools for inspecting our networks! 

The first tool we'll use is called nmap, you can install it for unix environments or windows. It's a command line tool for assessing serviceable ports in networks. It is also helpful for groking network subneting and cidr notation. 

Let's see what we get when we query some IP address...

dns.google  
`nmap 8.8.8.8`

local? 
`nmap 127.0.0.1`

how about we look beyond the standard service ports?

`nmap 127.0.0.1 -p- -Pn`

Let's start a python app and see what we get... 

`python app.py`

`nmap 127.0.0.1 `

Nice, how about scanning a subnet 

`nmap 10.0.0.0/27`

Now that we started port scanning a subnet let's move to our next tool. 
Wireshark. 
It's a tool for monitoring network activity on your machine. Let's do a couple things and see it working. 

First let's filter by IP address

`ip.addr == `

Then let's filter by port number 

`tcp.port == 80 || udp.port == 80`

`tcp.port == 5000 || udp.port == 5000`

How about filtering by a range of ip addresses? CIDR Block! 

`ip.addr==10.0.0.0/20`

Now that we're looking at that range let's go port scan again. 

`nmap 10.0.0.0/27`

`nmap 10.0.0.4 -Pn`

Neat! Well what's the last tool? The final tool is the network manager in azure. 
Here we can see a topoplogy of our network and gain insights into how our network applicances are connected in the cloud. 

Let's make take a look 

portal > search network manager > get the list view of network manager resources and select topology on the left. 

Here we can see an overview of our global azure footprint. 

Let's zoom in on our hub subnet. In this hub subnet we see a couple different things including a gateway. This gateway subnet is our portal to our private network. 

Let's connect via vpn to this network and revisit some of our commands from earlier. 

`nmap 10.0.0.0/26`

now that we're on the VPN we can see our appliances, let's jump into a vm in the network to keep poking around. 

We've deployed the website we ran earlier to two different app services, one is in a typical app services here: 

https://app-timinhou-dev-eu.azurewebsites.net/ 

The other one in the us is only accessible via private endpoint

https://app-timinhou-dev-us.azurewebsites.net/

We can port scan for it to no avail and visit the site and get a 403, but let's jump over to our jumpbox and use some of the same tools. 


`nmap 10.0.8.132`

and visit the site... Let's go back to the topology view and revisit what that looks like in the portal. 

These tools can be invaluable for understanding the flow of network traffic in our topologies and helped me grasp what's actually happening when I flip switches in the azure portal. In the process of making this talk I came across a number of other tools that could be essential to network investigation that I I'll list here. 

nslookup 
ipconfig / ifconfig 

## More fun

https://urlscan.io/

https://dnsdumpster.com/



## References 

Internet Assigned Numbers Authority: 
https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml 


## ARCHIVE 

We enable services on specific ports.


1. tool is wireshark

wireshark gives us a way to capture and log all the network traffic on our machine. 
Let's see what that looks like on 


2. tool is a port scan

How do install nmap for powershell



$ipAddress = "192.168.0.1"  # Replace with the target IP address
$portRange = "1-1000"       # Replace with the range of ports you want to scan

$nmapPath = "C:\Path\To\nmap.exe"  # Replace with the actual path to the Nmap executable

# Run Nmap port scan
& $nmapPath -p $portRange $ipAddress


nmap app-timinhou-dev-eu.azurewebsites.net

3. tool is topology view in the azure portal 


4. tool is nslookup for figuring out what's happening with DNS 


Okay, let's see what this does in Azure between each step. 

Create a VM in a vnet 


port scan:  
check all ports -p- :
even if probes are being blocked -Pn 
`nmap -v 10.0.0.0/28 -p- -Pn`

Port scan the vnet gateway 
`nmap -v 172.16.200.6 -p- -Pn -A -O -sV -sC --script vuln`

port scan the vnet gateway public ip 
`sudo nmap -v 4.223.122.171 -p- -Pn -A -O -sV -sC --script vuln` 

52.147.219.192

create vnet peering from sweden hub to spoke1 

az network vnet peering create --name peer-hub-spoke1 -g rg-timinhou-dev-hub --vnet-name vnet-timinhou-dev-swedencentral --remote-vnet /subscriptions/bcd954b7-b360-4993-8223-50c04fc1e0f9/resourceGroups/spoke1-vnet-rg/providers/Microsoft.Network/virtualNetworks/spoke1-vnet --allow-vnet-access

az network vnet peering create --name peer-spoke1-hub -g spoke1-vnet-rg --vnet-name spoke1-vnet --remote-vnet /subscriptions/bcd954b7-b360-4993-8223-50c04fc1e0f9/resourceGroups/rg-timinhou-dev-hub/providers/Microsoft.Network/virtualNetworks/vnet-timinhou-dev-swedencentral --allow-vnet-access

az network vnet peering create --name peer-spoke2-hub -g spoke2-vnet-rg --vnet-name spoke2-vnet --remote-vnet /subscriptions/bcd954b7-b360-4993-8223-50c04fc1e0f9/resourceGroups/rg-timinhou-dev-hub/providers/Microsoft.Network/virtualNetworks/vnet-timinhou-dev-swedencentral --allow-vnet-access

az network vnet peering create --name peer-hub-spoke2 -g rg-timinhou-dev-hub --vnet-name vnet-timinhou-dev-swedencentral --remote-vnet /subscriptions/bcd954b7-b360-4993-8223-50c04fc1e0f9/resourceGroups/spoke2-vnet-rg/providers/Microsoft.Network/virtualNetworks/spoke2-vnet --allow-vnet-access


az network nic show-effective-route-table --name spoke1-nic --resource-group spoke1-vnet-rg -o table

az network route-table list --resource-group spoke1-vnet-rg --output table
az network vnet subnet show --name workload --vnet-name spoke1-vnet --resource-group spoke1-vnet-rg --query routeTable.id -o tsv


az network route-table route create --resource-group hub-nva-rg --route-table-name spoke1-rt --name default --address-prefix 0.0.0
.0/0 --next-hop-type Internet


az network vnet subnet create --resource-group spoke1-vnet-rg --vnet-name spoke1-vnet --n snet-spoke1-dev-eastus --address-prefixes 10.1.1.0/24

10.1.0.64/27

 nmap 10.0.0.0/27