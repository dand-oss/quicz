package main

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"context"
	"fmt"
	"os"
	"math/big"
	"net"
	"time"

	"github.com/quic-go/quic-go"
)

func generateTLSConfig() *tls.Config {
	// Support loading certs from CERT/KEY env vars for interop testing
	certFile := os.Getenv("CERT")
	keyFile := os.Getenv("KEY")
	if certFile != "" && keyFile != "" {
		cert, err := tls.LoadX509KeyPair(certFile, keyFile)
		if err == nil {
			return &tls.Config{
				Certificates: []tls.Certificate{cert},
				NextProtos:   []string{"hq-interop"},
			}
		}
		fmt.Printf("failed to load cert/key from %s/%s: %v, generating self-signed\n", certFile, keyFile, err)
	}
	key, _ := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	tmpl := &x509.Certificate{
		SerialNumber: big.NewInt(1),
		Subject:      pkix.Name{Organization: []string{"quicz interop"}},
		NotBefore:    time.Now().Add(-time.Hour),
		NotAfter:     time.Now().Add(24 * time.Hour),
		DNSNames:     []string{"localhost", "server", "server4"},
		IPAddresses:  []net.IP{net.ParseIP("127.0.0.1")},
	}
	certDER, _ := x509.CreateCertificate(rand.Reader, tmpl, tmpl, &key.PublicKey, key)
	cert := tls.Certificate{
		Certificate: [][]byte{certDER},
		PrivateKey:  key,
	}
	return &tls.Config{
		Certificates: []tls.Certificate{cert},
		NextProtos:   []string{"hq-interop"},
	}
}

func main() {
	addr := "127.0.0.1:4433"
	if len(os.Args) > 1 {
		addr = os.Args[1]
	}
	tlsConf := generateTLSConfig()
	quicConf := &quic.Config{
		MaxIdleTimeout:  30 * time.Second,
		KeepAlivePeriod: 10 * time.Second,
	}

	listener, err := quic.ListenAddr(addr, tlsConf, quicConf)
	if err != nil {
		fmt.Printf("failed to listen: %v\n", err)
		return
	}
	defer listener.Close()
	fmt.Printf("quic-go simple server listening on %s\n", addr)

	for {
		conn, err := listener.Accept(context.Background())
		if err != nil {
			fmt.Printf("accept error: %v\n", err)
			continue
		}
		go handleConn(conn)
	}
}

func handleConn(conn *quic.Conn) {
	fmt.Printf("new connection from %s\n", conn.RemoteAddr())
	for {
		stream, err := conn.AcceptStream(context.Background())
		if err != nil {
			break
		}
		go func(s *quic.Stream) {
			buf := make([]byte, 4096)
			n, _ := s.Read(buf)
			path := string(buf[:n])
			fmt.Printf("request: %s\n", path)
			s.Write([]byte("Hello from quic-go!"))
			s.Close()
		}(stream)
	}
}
