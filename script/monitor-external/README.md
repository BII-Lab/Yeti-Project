# How to deploy monitoring on Yeti root name server


 scripts from dns-orac ditl-tools

 capture DNS packet on DNS servers and save as pcap file, then send to Yeti
 storage server

 please refer to <https://github.com/BII-Lab/Yeti-Project/blob/master/doc/Capture.md>


0. setup.sh
------------
    install dnscap and wrapsrv

1. capture-dnscap.sh
------------
    1) capture-pcapdump.sh
     capture DNS packet with dnscap <https://github.com/verisign/dnscap>

    2) capture-pcapdump.sh  
       capture DNS packet with pcapdump
       <https://packages.debian.org/sid/pcaputils>  
     You *need* the patch in <https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=545985>  
     
2. data-commit.sh
------------
    submit DNS packet via ssh
    
    notice: use ssh PubkeyAuthentication, so user should provide ssh public key

3. settings.sh
------------
   configure option for dnscap/pcapdump  
   configure SSH_ID as user's SSH private key  
   configure SAVEDIR to store pacp file  
   configure KICK_CMD, choose dnscap or pcapdump  
   such as capture interval, ethernet interface, tcp support, fragment and so on  

4. how to run
------------
    1) setup
       you should run command 'bash setup.sh', this will install dnscap and wrapsrv
       if you want to install dnscap or wrapsrv, try 'bash setup.sh dnscap' or 'bash setup.sh wrapsrv'
    2) run dnscap
        sh capture-dnscap.sh
    3) add task in crontab, monitor dnscap process
       "*       *       *       *       *       root	pgrep dnscap || (cd /path/of/capture-dnscap.sh && sh capture-dnscap.sh)"


5. note
------------
    on ubuntu 14.04.2(kernel 4.0.7), dnscap works well.
    on Centos 6(kernel 2.6.32.*), dnscap works well.
    on FreeBSD 10.0, dnscap works well.
	
    linux kernel below 3.19, dnscap sometimes lost packets.
    so if choose Linux and use dnscap to capture packet, please upgrage your kernel.
