noflags() {
	echo ".............................."
    echo "Usage: install-nort"
    echo "Example: install-nort"
    echo ".............................."
    exit 1
}

message() {
	echo "╒════════════════════════════════════════════════════════════════════════════════>>"
	echo "| $1"
	echo "╘════════════════════════════════════════════<<<"
}

error() {
	message "An error occured, you must fix it to continue!"
	exit 1
}


prepdependencies() {
	message "Installing dependencies..."
	sudo apt-get update
	sudo apt-get install automake libdb++-dev build-essential libtool autotools-dev autoconf pkg-config libssl-dev libboost-all-dev libminiupnpc-dev git software-properties-common python-software-properties g++ bsdmainutils libevent-dev -y
	sudo add-apt-repository ppa:bitcoin/bitcoin -y
	sudo apt-get update
	sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
}

createswap() {
	message "Creating 2GB temporary swap file...this may take a few minutes..."
	sudo dd if=/dev/zero of=/swapfile bs=1M count=2000
	sudo mkswap /swapfile
	sudo chown root:root /swapfile
	sudo chmod 0600 /swapfile
	sudo swapon /swapfile

	#make swap permanent
	sudo echo "/swapfile none swap sw 0 0" >> /etc/fstab
}

clonerepo() {
	message "Cloning from github repository..."
  	cd ~/
	git clone https://github.com/zabtc/Northern.git
}

compile() {
	cd Northern
	message "Preparing to build..."
	./autogen.sh
	if [ $? -ne 0 ]; then error; fi
	message "Configuring build options..."
	./configure $1 --disable-tests
	if [ $? -ne 0 ]; then error; fi
	message "Building Northern...this may take a few minutes..."
	make
	if [ $? -ne 0 ]; then error; fi
	message "Installing Northern..."
	sudo make install
	if [ $? -ne 0 ]; then error; fi
}

createconf() {
	message "Creating northern.conf..."
	MNPRIVKEY="2aJdbYXcR3PbFgAX15778yoyb88PoAqaN2XAZWPFdcUNKsEHAs6"
	CONFDIR=~/.northern
	CONFILE=$CONFDIR/northern.conf
	if [ ! -d "$CONFDIR" ]; then mkdir $CONFDIR; fi
	if [ $? -ne 0 ]; then error; fi
	
	mnip=$(curl -s https://api.ipify.org)
	rpcuser=$(date +%s | sha256sum | base64 | head -c 10 ; echo)
	rpcpass=$(openssl rand -base64 32)
	printf "%s\n" "rpcuser=$rpcuser" "rpcpassword=$rpcpass" "rpcallowip=127.0.0.1" "listen=1" "server=1" "daemon=1" "maxconnections=256" "rpcport=9332" "externalip=$mnip" "bind=$mnip" "masternode=1" "masternodeprivkey=$MNPRIVKEY" "masternodeaddr=$mnip:6942" > $CONFILE

        northernd
        message "Wait 10 seconds for daemon to load..."
        sleep 20s
        MNPRIVKEY=$(northern-cli masternode genkey)
	northern-cli stop
	message "wait 10 seconds for daemon to stop..."
        sleep 10s
	sudo rm $CONFILE
	message "Updating northern.conf..."
        printf "%s\n" "rpcuser=$rpcuser" "rpcpassword=$rpcpass" "rpcallowip=127.0.0.1" "listen=1" "server=1" "daemon=1" "maxconnections=256" "rpcport=9332" "externalip=$mnip" "bind=$mnip" "masternode=1" "masternodeprivkey=$MNPRIVKEY" "masternodeaddr=$mnip:6942" "addnode=207.246.69.246" "addnode=209.250.233.104" "addnode=45.77.82.101" "addnode=138.68.167.127" "addnode=45.77.218.53" "addnode=207.246.86.118" "addnode=207.246.71.67" "addnode=173.199.123.21" "addnode=149.56.4.241" "addnode=149.56.4.242" "addnode=149.56.4.243" "addnode=149.56.4.244" "addnode=149.56.4.245" "addnode=149.56.4.246" "addnode=149.56.4.247"> $CONFILE

}

success() {
	northernd
	message "SUCCESS! Your northernd has started. Masternode.conf setting below..."
	message "MN $mnip:6942 $MNPRIVKEY TXHASH INDEX"
	exit 0
}

install() {
#	prepdependencies
#	createswap
	clonerepo
	compile $1
	createconf
	success
}

#main
#default to --without-gui
install --without-gui
