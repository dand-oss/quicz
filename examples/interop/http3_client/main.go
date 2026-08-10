package main

import (
	"bytes"
	"context"
	"crypto/tls"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/quic-go/quic-go/http3"
)

func main() {
	tlsConfig := &tls.Config{InsecureSkipVerify: true}
	transport := &http3.Transport{TLSClientConfig: tlsConfig}
	defer transport.Close()
	client := &http.Client{Transport: transport, Timeout: 10 * time.Second}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// 1. POST /echo with body
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, "https://127.0.0.1:4433/echo", bytes.NewReader([]byte("hello-qpack-body")))
	resp, err := client.Do(req)
	if err != nil { fmt.Println("POST /echo fail:", err); return }
	body, _ := io.ReadAll(resp.Body)
	fmt.Printf("POST /echo status=%d body=%q\n", resp.StatusCode, body)

	// 2. GET /stream
	resp2, err := client.Get("https://127.0.0.1:4433/stream")
	if err != nil { fmt.Println("GET /stream fail:", err); return }
	b2, _ := io.ReadAll(resp2.Body)
	fmt.Printf("GET /stream status=%d len=%d\n", resp2.StatusCode, len(b2))

	// 3. GET / again (dynamic table warm)
	resp3, err := client.Get("https://127.0.0.1:4433/")
	if err != nil { fmt.Println("GET / round2 fail:", err); return }
	b3, _ := io.ReadAll(resp3.Body)
	fmt.Printf("GET / round2 status=%d body=%q\n", resp3.StatusCode, b3)
}
