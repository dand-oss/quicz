//! quiche QUIC echo server for interop testing.
//! Usage: cargo run --release -- 127.0.0.1:4433

use std::collections::HashMap;
use std::net::{SocketAddr, UdpSocket};

fn main() {
    let addr: SocketAddr = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "127.0.0.1:4433".into())
        .parse()
        .expect("valid addr");

    let socket = UdpSocket::bind(addr).expect("bind");
    println!("quiche server listening on {addr}");

    let mut config = quiche::Config::new(quiche::PROTOCOL_VERSION).expect("config");
    config
        .set_application_protos(&[b"hq-interop"])
        .expect("alpn");
    config.set_max_idle_timeout(30_000);
    config.set_max_recv_udp_payload_size(8192);
    config.set_max_send_udp_payload_size(8192);
    config.set_initial_max_data(1_048_576);
    config.set_initial_max_stream_data_bidi_local(1_048_576);
    config.set_initial_max_stream_data_bidi_remote(1_048_576);
    config.set_initial_max_streams_bidi(128);
    config.set_initial_max_streams_uni(128);

    let cert = std::env::var("CERT").unwrap_or_else(|_| "cert.pem".into());
    let key = std::env::var("KEY").unwrap_or_else(|_| "key.pem".into());
    config
        .load_cert_chain_from_pem_file(&cert)
        .expect("load cert");
    config.load_priv_key_from_pem_file(&key).expect("load key");

    let mut conns: HashMap<quiche::ConnectionId<'static>, quiche::Connection> = HashMap::new();
    let mut buf = [0u8; 65535];

    loop {
        let (n, peer) = match socket.recv_from(&mut buf) {
            Ok(v) => v,
            Err(_) => continue,
        };

        let (conn_id, _) = match quiche::ConnectionId::from_ref(&buf[6..14]) {
            id => (id, ()),
        };

        let conn = conns.entry(conn_id.to_owned()).or_insert_with(|| {
            quiche::accept(&conn_id, None, peer, &mut config).expect("accept")
        });

        if conn.recv(&mut buf[..n]).is_err() {
            continue;
        }

        for sid in conn.readable() {
            let mut sbuf = [0u8; 65535];
            while let Ok((read, fin)) = conn.stream_recv(sid, &mut sbuf) {
                if read > 0 {
                    println!("request: {:?}", String::from_utf8_lossy(&sbuf[..read]));
                    let _ = conn.stream_send(sid, b"Hello from quiche!", true);
                }
                if fin {
                    break;
                }
            }
        }

        let mut out = [0u8; 65535];
        while let Ok((write, _)) = conn.send(&mut out) {
            if write > 0 {
                let _ = socket.send_to(&out[..write], peer);
            }
        }

        if conn.is_closed() {
            conns.remove(&conn_id);
        }
    }
}
