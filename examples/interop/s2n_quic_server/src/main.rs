//! s2n-quic QUIC echo server for interop testing.
//! Usage: cargo run --release -- 127.0.0.1:4433

use s2n_quic::Server;
use std::net::SocketAddr;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let addr: SocketAddr = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "127.0.0.1:4433".into())
        .parse()?;

    let cert = std::env::var("CERT").unwrap_or_else(|_| "cert.pem".into());
    let key = std::env::var("KEY").unwrap_or_else(|_| "key.pem".into());

    let mut server = Server::builder()
        .with_tls((cert, key))?
        .with_io(addr)?
        .start()?;

    println!("s2n-quic server listening on {addr}");

    while let Some(mut conn) = server.accept().await {
        tokio::spawn(async move {
            println!("new connection from {:?}", conn.remote_addr());
            while let Ok(Some(mut stream)) = conn.accept_bidirectional_stream().await {
                tokio::spawn(async move {
                    let mut buf = vec![0u8; 65535];
                    while let Ok(Some(n)) = stream.receive(&mut buf).await {
                        if n > 0 {
                            println!("request: {:?}", String::from_utf8_lossy(&buf[..n]));
                            let _ = stream.send(b"Hello from s2n-quic!").await;
                            let _ = stream.finish().await;
                        }
                    }
                });
            }
        });
    }

    Ok(())
}
