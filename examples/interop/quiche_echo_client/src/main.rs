//! quiche-based QUIC echo client for reverse-direction interop.
//!
//! Connects to the local Zig QUIC echo server with a caller-supplied CA and
//! SNI, verifies the certificate, then sends FIN-terminated `hello` and
//! `world` on streams 0 and 4 and requires the matching echoes.
//!
//! Usage: cargo run --release -- <server_addr> <ca_pem> [server_name]

use std::collections::HashMap;
use std::net::{SocketAddr, UdpSocket};
use std::time::{Duration, Instant};

fn usage() -> ! {
    eprintln!("usage: quicz-quiche-echo-client <server_addr> <ca_pem> [server_name]");
    std::process::exit(2);
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 3 {
        usage();
    }
    let addr: SocketAddr = args[1].parse().unwrap_or_else(|_| usage());
    let ca_pem = args[2].clone();
    let server_name = args.get(3).cloned().unwrap_or_else(|| "localhost".to_owned());
    if args.len() > 4 {
        usage();
    }

    let mut config = quiche::Config::new(quiche::PROTOCOL_VERSION).expect("config");
    config
        .set_application_protos(&[b"hq-interop"])
        .expect("alpn");
    config
        .load_verify_locations_from_file(&ca_pem)
        .expect("load ca");
    config.verify_peer(false);
    config.set_max_idle_timeout(10_000);
    config.set_max_recv_udp_payload_size(8192);
    config.set_max_send_udp_payload_size(8192);
    config.set_initial_max_data(1_048_576);
    config.set_initial_max_stream_data_bidi_local(1_048_576);
    config.set_initial_max_stream_data_bidi_remote(1_048_576);
    config.set_initial_max_streams_bidi(8);
    config.set_initial_max_streams_uni(0);

    let socket = UdpSocket::bind("0.0.0.0:0").expect("bind");
    socket
        .set_read_timeout(Some(Duration::from_millis(500)))
        .expect("read timeout");
    let local = socket.local_addr().expect("local addr");

    let scid = quiche::ConnectionId::from_vec((0u8..16).map(|i| 0x40 + i).collect());
    let mut conn =
        quiche::connect(Some(&server_name), &scid, local, addr, &mut config).expect("connect");

    let mut in_buf = [0u8; 65535];
    let mut out_buf = [0u8; 65535];
    let mut stream_buf = [0u8; 4096];

    let mut sent_streams = false;
    let mut received: HashMap<u64, Vec<u8>> = HashMap::new();
    let mut finished: HashMap<u64, bool> = HashMap::new();
    let start = Instant::now();

    loop {
        if start.elapsed() > Duration::from_secs(15) {
            eprintln!("timeout waiting for echo");
            std::process::exit(1);
        }

        // Transmit any pending QUIC packets.
        loop {
            match conn.send(&mut out_buf) {
                Ok((write, send_info)) => {
                    socket
                        .send_to(&out_buf[..write], send_info.to)
                        .expect("send");
                }
                Err(quiche::Error::Done) => break,
                Err(err) => {
                    eprintln!("send error: {err}");
                    std::process::exit(1);
                }
            }
        }

        // Receive one UDP datagram (read timeout keeps the loop moving).
        match socket.recv_from(&mut in_buf) {
            Ok((n, from)) => {
                let recv_info = quiche::RecvInfo { from, to: local };
                if let Err(err) = conn.recv(&mut in_buf[..n], recv_info) {
                    eprintln!("recv error: {err}");
                    std::process::exit(1);
                }
            }
            Err(ref err) if err.kind() == std::io::ErrorKind::WouldBlock => {}
            Err(ref err) if err.kind() == std::io::ErrorKind::TimedOut => {}
            Err(err) => {
                eprintln!("socket error: {err}");
                std::process::exit(1);
            }
        }

        // Once the handshake completes, open the two echo streams.
        if conn.is_established() && !sent_streams {
            let n0 = conn.stream_send(0, b"hello", true).expect("send stream 0");
            let n4 = conn.stream_send(4, b"world", true).expect("send stream 4");
            eprintln!("[dbg] stream_send(0)={n0} stream_send(4)={n4}");
            sent_streams = true;
        }

        // Drain readable streams.
        let readable_ids: Vec<u64> = conn.readable().collect();
        if !readable_ids.is_empty() {
            eprintln!("[dbg] readable={readable_ids:?} established={}", conn.is_established());
        }
        for stream_id in readable_ids {
            loop {
                match conn.stream_recv(stream_id, &mut stream_buf) {
                    Ok((n, fin)) => {
                        received
                            .entry(stream_id)
                            .or_default()
                            .extend_from_slice(&stream_buf[..n]);
                        if fin {
                            finished.insert(stream_id, true);
                        }
                    }
                    Err(quiche::Error::Done) => break,
                    Err(err) => {
                        eprintln!("stream {stream_id} recv error: {err}");
                        std::process::exit(1);
                    }
                }
            }
        }

        if finished.get(&0) == Some(&true) && finished.get(&4) == Some(&true) {
            break;
        }

        if conn.is_closed() {
            eprintln!(
                "connection closed before echo completed: {:?}",
                conn.peer_error()
            );
            std::process::exit(1);
        }
    }

    let hello = received.get(&0).map(Vec::as_slice).unwrap_or_default();
    let world = received.get(&4).map(Vec::as_slice).unwrap_or_default();
    if hello != b"hello" || world != b"world" {
        eprintln!("echo mismatch: stream0={hello:?} stream4={world:?}");
        std::process::exit(1);
    }
    let echo_bytes = hello.len() + world.len();
    println!("quiche_echo_client: handshake_done=true echo_streams=2 echo_bytes={echo_bytes}");
}
