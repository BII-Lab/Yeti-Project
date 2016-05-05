package main

import (
    "fmt"
    "bufio"
    "flag"
    "io"
    "os"
    "strings"
    "strconv"
    "github.com/miekg/dns"
)

var (
    flags     uint16
    protocol uint8
    algorithm uint8
    publickey string

)

func ParseDNSKEY(dnskey string) {
    str := strings.Split(dnskey, " ")

    // flag
    flag1,_ := strconv.Atoi(str[3])
    flags = uint16(flag1)

    //protocol
    protocol1,_ := strconv.Atoi(str[4])
    protocol = uint8(protocol1)

    // algorithm
    algorithm1,_ := strconv.Atoi(str[5])
    algorithm = uint8(algorithm1)

    // public key
    publickey = strings.Join(str[6:], "")

    //fmt.Println(flags, protocol, algorithm, publickey)
    
}

func ReadLine(fileName string, handler func(string)) error {
    f, err := os.Open(fileName)
    if err != nil {
        return err
    }
    defer f.Close()
    var root bool
    buf := bufio.NewReader(f)
    for {
        line, err := buf.ReadString('\n')
        line = strings.TrimSpace(line) 
        if err != nil {
            if err == io.EOF && root {
                return nil
            }
            return err
        }
        
        // handle DNSKEY line 
        if line[0] == '.' {
            root = true
            handler(line)
            return nil
        }
    }

    return nil
}

func CalcTag(flags uint16, algorithm uint8, publickey string)uint16 {
        key := new(dns.DNSKEY)
        key.Hdr.Name = "."
        key.Hdr.Rrtype = dns.TypeDNSKEY
        key.Hdr.Class = dns.ClassINET
        key.Hdr.Ttl = 3600
        key.Flags = flags
        key.Protocol = 3
        key.Algorithm = algorithm
        key.PublicKey = publickey

        return key.KeyTag()
}

func main() {

    if len(os.Args) < 3 {
        fmt.Println("Usage: ", os.Args[0], "-f", "key-file-name")
        os.Exit(1)
    }

    userFile := flag.String("f", "zsk.key", "key file name")
    flag.Parse()
    
    if userFile == nil {
        fmt.Println("Usage: ", os.Args[0], "-f", "key-file-name")
        os.Exit(1)
    }

    if err := ReadLine(*userFile, ParseDNSKEY); err != nil {
       fmt.Println(err) 
       os.Exit(1)
    }

    filename := fmt.Sprintf("K.+%03d+%d", algorithm, CalcTag(flags, algorithm, publickey))
    fmt.Println(filename)
}
