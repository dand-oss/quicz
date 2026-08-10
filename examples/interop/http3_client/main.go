// quic-go HTTP/3 client probe: real third-party H3 stack against a quicz
// h3-server. GETs the root path and prints the status + body.
//
// Usage: go run main.go [addr] [path]
//   addr defaults to 127.0.0.1:4433, path defaults to "/".
package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	"github.com/quic-go/quic-go/http3"
)

func main() {
	addr := "127.0.0.1:4433"
	path := "/"
	if len(os.Args) > 1 {
		addr = os.Args[1]
	}
	if len(os.Args) > 2 {
		path = os.Args[2]
	}

	// InsecureSkipVerify so the loopback test certificate is accepted.
	tlsConfig := &tls.Config{InsecureSkipVerify: true}
	transport := &http3.Transport{TLSClientConfig: tlsConfig}
	defer transport.Close()

	client := &http.Client{Transport: transport, Timeout: 10 * time.Second}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://"+addr+path, nil)
	if err != nil {
		fmt.Println("request:", err)
		os.Exit(1)
	}

	resp, err := client.Do(req)
	if err != nil {
		fmt.Println("http3 client:", err)
		os.Exit(1)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	fmt.Printf("status=%d body=%q\n", resp.StatusCode, body)
	if resp.StatusCode != 200 {
		os.Exit(1)
	}
}