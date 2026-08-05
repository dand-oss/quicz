//! s2n-quic-based QUIC echo client for reverse-direction interop.
//!
//! Connects to the local Zig QUIC echo server with a caller-supplied CA and
//! SNI, verifies the certificate, then sends FIN-terminated `hello` and
//! `world` on two bidirectional streams and requires the matching echoes.
//!
//! Usage: cargo run --release -- <server_addr> <ca_pem> [server_name]

use std::net::SocketAddr;

use s2n_quic::{client::Connect, Client};

fn usage() -> ! {
    eprintln!("usage: quicz-s2n-echo-client <server_addr> <ca_pem> [server_name]");
    std::process::exit(2);
}

async fn receive_to_end(
    stream: &mut s2n_quic::stream::BidirectionalStream,
) -> Result<Vec<u8>, Box<dyn std::error::Error + Send + Sync>> {
    let mut out = Vec::new();
    while let Some(chunk) = stream.receive().await? {
        out.extend_from_slice(&chunk);
    }
    Ok(out)
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 3 {
        usage();
    }
    let addr: SocketAddr = args[1].parse().unwrap_or_else(|_| usage());
    let ca_pem = std::fs::read(&args[2])?;
    let server_name = args.get(3).cloned().unwrap_or_else(|| "localhost".to_owned());
    if args.len() > 4 {
        usage();
    }

    // rustls provider: ensures X25519 key share support (s2n-tls on macOS
    // may not include X25519 in its default curve list). The
    // `provider-tls-rustls` feature makes this the default provider.
    //
    // NOTE: with_certificate() treats `&[u8]`/`Vec<u8>` input as DER without
    // parsing; PEM input must go through the `&str`/`String` impl.
    let ca_pem = std::fs::read_to_string(&args[2])?;
    let tls = s2n_quic::provider::tls::default::Client::builder()
        .with_certificate(ca_pem.as_str())?
        .with_application_protocols([b"hq-interop".as_ref()].into_iter())?
        .build()?;

    let client = Client::builder()
        .with_tls(tls)?
        .with_io("0.0.0.0:0")?
        .start()?;

    let connect = Connect::new(addr).with_server_name(server_name.as_str());
    let mut connection = client.connect(connect).await?;

    let mut stream0 = connection.open_bidirectional_stream().await?;
    stream0.send(bytes::Bytes::from_static(b"hello")).await?;
    stream0.finish()?;
    let mut stream4 = connection.open_bidirectional_stream().await?;
    stream4.send(bytes::Bytes::from_static(b"world")).await?;
    stream4.finish()?;

    let echo0 = receive_to_end(&mut stream0).await?;
    let echo4 = receive_to_end(&mut stream4).await?;
    if echo0 != b"hello" || echo4 != b"world" {
        eprintln!("echo mismatch: stream0={echo0:?} stream1={echo4:?}");
        std::process::exit(1);
    }
    let echo_bytes = echo0.len() + echo4.len();
    println!("s2n_echo_client: handshake_done=true echo_streams=2 echo_bytes={echo_bytes}");
    Ok(())
}
