package main

import (
	"flag"
	"fmt"
	"net"
	"os"
	"strings"
)

func CheckIP(ip string) bool {

	if net.ParseIP(ip) != nil {
		//fmt.Printf("right ip address\n")
	} else {
		//fmt.Printf("wrong ip addres\n")
		return false
	}

	if strings.Contains(ip, ":") {
		//fmt.Printf("IPv6 address\n")
	} else {
		//fmt.Printf("IPv4 address\n")
		return false
	}

	return true
}

func CheckName(domain string) bool {
	var tmp int = 0
	length := len(domain)

	if length > 255 {
		return false
	}

	for i := 0; i < length; i++ {
		c := domain[i]
		switch {
		case '0' <= c && c <= '9':
		case 'a' <= c && c <= 'z':
		case 'A' <= c && c <= 'Z':
		case '.' == c:
			if tmp > 63 {
				return false
			} else {
				tmp = 0
				continue
			}
		case '-' == c:
		default:
			return false
		}

		tmp++
	}

	return true
}

func main() {

	var (
		DOMAIN  string
		ADDRESS string
        RealAddr []string
		ret     int
	)

    if len(os.Args) < 3 {
        fmt.Println("Usage: ", os.Args[0], "-ns", "domain", "-addr", "'IPv6 Address'")
        fmt.Println("Usage: ", os.Args[0], "-ns=domain", "-addr='IPv6 Address'")
        fmt.Println("Usage: ", os.Args[0], "-addr='IPv6 Address'")
        os.Exit(5)
    }


	flag.StringVar(&DOMAIN, "ns", "ns1.sld.net.", "name server(FQDN)")
	flag.StringVar(&ADDRESS, "addr", "240c:f:1:22::1", "'IPv6 Address'")

	flag.Parse()

    if len(os.Args) == 5 {
	    if CheckName(DOMAIN) {
	    	fmt.Println("Domain: ", DOMAIN, "OK")
	    	ret = 0
	    } else {
	    	ret = 1
	    	fmt.Println("Domain: ", DOMAIN, "ERROR")
	    }

	    if CheckIP(ADDRESS) {
	    	fmt.Println("IPv6 Address:", ADDRESS, "OK")
	    } else {
	    	ret = 2
	    	fmt.Println("IPv6 Address:", ADDRESS, "ERROR")
	    }

        var err error
        if RealAddr, err = net.LookupHost(DOMAIN); err != nil {
            ret = 3
            fmt.Println(err)
            os.Exit(ret)
        } 

       if net.ParseIP(RealAddr[0]).Equal(net.ParseIP(ADDRESS)) {
           ret = 0
           fmt.Println("IPv6 Address match,", "dig: ", RealAddr[0],"Input: ", ADDRESS)
       } else {
            ret = 4
            fmt.Println("IPv6 Address do not match,", "dig: ", RealAddr[0],"Input: ", ADDRESS)
       }

    } else if len(os.Args) == 3 {
	    if CheckIP(ADDRESS) {
	    	fmt.Println("IPv6 Address:", ADDRESS, "OK")
	    } else {
	    	ret = 2
	    	fmt.Println("IPv6 Address:", ADDRESS, "ERROR")
	    }

    } else {
	    	ret = 5
    } 
    

	os.Exit(ret)
}
