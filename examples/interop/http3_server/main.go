// quic-go HTTP/3 server: real third-party H3 stack for quicz to connect to
// (reverse direction of http3_client). Serves / and POST /echo.
//
// Usage: go run main.go [addr]
//   addr defaults to 127.0.0.1:4439.
package main

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"fmt"
	"io"
	"math/big"
	"net"
	"net/http"
	"os"
	"time"

	"github.com/quic-go/quic-go/http3"
)

func main() {
	addr := "127.0.0.1:4439"
	if len(os.Args) > 1 {
		addr = os.Args[1]
	}

	// Self-signed ECDSA P-256 certificate for 127.0.0.1 / localhost.
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		panic(err)
	}
	tmpl := &x509.Certificate{
		SerialNumber: big.NewInt(1),
		Subject:      pkix.Name{CommonName: "quicz-go-h3-server"},
		NotBefore:    time.Now().Add(-time.Hour),
		NotAfter:     time.Now().Add(24 * time.Hour),
		KeyUsage:     x509.KeyUsageDigitalSignature | x509.KeyUsageCertSign,
		ExtKeyUsage:  []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		BasicConstraintsValid: true,
		IsCA:         true,
		IPAddresses:  []net.IP{net.ParseIP("127.0.0.1")},
		DNSNames:     []string{"localhost"},
	}
	der, err := x509.CreateCertificate(rand.Reader, tmpl, tmpl, &key.PublicKey, key)
	if err != nil {
		panic(err)
	}
	cert := tls.Certificate{Certificate: [][]byte{der}, PrivateKey: key}

	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/echo" {
			body, _ := io.ReadAll(r.Body)
			w.Header().Set("content-type", "application/octet-stream")
			w.Write(body)
			return
		}
		if r.URL.Path == "/headers" {
			w.Header().Set("x-quicz-probe", "yes")
			w.Header().Set("server", "go-http3")
		}
		w.Header().Set("content-type", "text/plain")
		w.Write([]byte("Hello from go http3 server"))
	})

	server := &http3.Server{
		Addr:      addr,
		TLSConfig: &tls.Config{Certificates: []tls.Certificate{cert}, MinVersion: tls.VersionTLS13},
		Handler:   handler,
	}
	fmt.Printf("go http3 server listening on https://%s\n", addr)
	if err := server.ListenAndServe(); err != nil {
		fmt.Println("server:", err)
		os.Exit(1)
	}
}
