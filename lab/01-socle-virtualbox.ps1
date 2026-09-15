# MediConnect - Construction du socle VirtualBox
# Usage : powershell -ExecutionPolicy Bypass -File .\lab\01-socle-virtualbox.ps1
# Prerequis : VirtualBox 7.x, OVA CSNx v4.8, VM pfSense existante

$vbm = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

# 1. Reseau NAT dedie au projet (Internet simule)
& $vbm natnetwork add --netname NatMediConnect --network "192.36.253.0/24" --enable --dhcp off

# 2. Import de l'OVA (fait via l'interface graphique, deux fois)
#    Import 1 : MC-FW-EXT, MC-Client-LAN (serveur supprime)
#    Import 2 : MC-FW-B,   MC-Client-B   (serveur supprime)
#    Option : generer de nouvelles adresses MAC

# 3. Pare-feu interne : clone integral du pfSense
& $vbm clonevm "pfSense" --name "MC-FW-INT" --mode machine --register

# 4. Branchement des cartes reseau
# FW-EXT : em0=out, em1=transit, em2=dmz_relais, em3=demo
& $vbm modifyvm "MC-FW-EXT" --nic1 natnetwork --nat-network1 NatMediConnect --nic2 intnet --intnet2 mc_transit --nic3 intnet --intnet3 mc_dmz_relais --nic4 intnet --intnet4 mc_demo
# FW-B : em0=out, em1=lan site B
& $vbm modifyvm "MC-FW-B" --nic1 natnetwork --nat-network1 NatMediConnect --nic2 intnet --intnet2 mc_lan_site_b --nic3 none --nic4 none
# FW-INT : WAN=transit, LAN=lan siege, OPT1=srv_app, OPT2=serveurs, OPT3=admin
& $vbm modifyvm "MC-FW-INT" --nic1 intnet --intnet1 mc_transit --nic2 intnet --intnet2 mc_lan_siege --nic3 intnet --intnet3 mc_srv_app --nic4 intnet --intnet4 mc_serveurs --nic5 intnet --intnet5 mc_admin --nictype5 82540EM --cableconnected5 on --nic6 none --nic7 none --nic8 none
# Clients
& $vbm modifyvm "MC-Client-LAN" --nic1 intnet --intnet1 mc_lan_siege
& $vbm modifyvm "MC-Client-B" --nic1 intnet --intnet1 mc_lan_site_b

# 5. Verification
foreach ($vm in "MC-FW-EXT","MC-FW-B","MC-FW-INT","MC-Client-LAN","MC-Client-B") {
  "== $vm"
  & $vbm showvminfo $vm --machinereadable | Select-String '^(nic\d|intnet\d|nat-network\d)='
}

# 6. Instantane de reference
foreach ($vm in "MC-FW-EXT","MC-FW-B","MC-FW-INT","MC-Client-LAN","MC-Client-B") {
  & $vbm snapshot $vm take "PROJET-INIT" --description "Cartes reseau branchees, avant configuration"
}
