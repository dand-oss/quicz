use bytes::Bytes;
use s2n_quic::Server;
use s2n_quic::provider::tls::s2n_tls;
use std::net::SocketAddr;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let addr: SocketAddr = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "127.0.0.1:4433".into())
        .parse()?;

    let cert_path = std::env::var("CERT").unwrap_or_else(|_| "cert.pem".into());
    let key_path = std::env::var("KEY").unwrap_or_else(|_| "key.pem".into());
    let cert_pem = std::fs::read_to_string(&cert_path)?;
    let key_pem = std::fs::read_to_string(&key_path)?;

    let tls = s2n_tls::Server::builder()
        .with_application_protocols([b"hq-interop".as_ref()])?
        .with_certificate(&cert_pem, &key_pem)?
        .build()?;

    let mut server = Server::builder()
        .with_tls(tls)?
        .with_io(addr)?
        .start()?;

    println!("s2n-quic server listening on {addr}");

    while let Some(mut conn) = server.accept().await {
        tokio::spawn(async move {
            println!("new connection from {:?}", conn.remote_addr());
            while let Ok(Some(mut stream)) = conn.accept_bidirectional_stream().await {
                tokio::spawn(async move {
                    if let Ok(Some(data)) = stream.receive().await {
                        println!("request: {:?}", String::from_utf8_lossy(&data));
                        let response = Bytes::copy_from_slice(&data);
                        let _ = stream.send(response).await;
                        let _ = stream.finish();
                    }
                });
            }
        });
    }
    Ok(())
}
