//! quiche QUIC echo server for interop testing.
//! Properly routes packets using quiche's header parsing for both
//! long-header (Initial/Handshake) and short-header (1-RTT) packets.

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

    // Map from server-local SCID bytes -> connection
    let mut conns: HashMap<Vec<u8>, quiche::Connection> = HashMap::new();
    let mut buf = [0u8; 65535];

    loop {
        let (n, peer) = match socket.recv_from(&mut buf) {
            Ok(v) => v,
            Err(_) => continue,
        };

        let recv_info = quiche::RecvInfo {
            from: peer,
            to: addr,
        };

        // Parse the packet header to extract the DCID (which is our SCID for routing)
        let hdr = match quiche::Header::from_slice(&mut buf[..n], 8) {
            Ok(v) => v,
            Err(_) => continue,
        };

        let conn_id = hdr.dcid.to_vec();

        // Get or create connection
        if !conns.contains_key(&conn_id) {
            // Only create connections for Initial packets (long header with Initial type)
            if !matches!(hdr.ty, quiche::Type::Initial) {
                continue;
            }
            let scid = quiche::ConnectionId::from_ref(&conn_id);
            match quiche::accept(&scid, None, addr, peer, &mut config) {
                Ok(conn) => {
                    println!("new connection (dcid={:x?})", &conn_id);
                    conns.insert(conn_id.clone(), conn);
                }
                Err(e) => {
                    eprintln!("accept error: {e:?}");
                    continue;
                }
            }
        }

        let conn = match conns.get_mut(&conn_id) {
            Some(c) => c,
            None => continue,
        };

        // Process incoming packet
        if let Err(e) = conn.recv(&mut buf[..n], recv_info) {
            eprintln!("recv error: {e:?}");
            // Don't remove connection on transient errors
        }

        // Echo readable streams
        let readable: Vec<u64> = conn.readable().collect();
        for sid in readable {
            let mut sbuf = [0u8; 65535];
            loop {
                match conn.stream_recv(sid, &mut sbuf) {
                    Ok((read, fin)) => {
                        if read > 0 {
                            println!("request: {:?}", String::from_utf8_lossy(&sbuf[..read]));
                            let _ = conn.stream_send(sid, &sbuf[..read], true);
                        }
                        if fin {
                            break;
                        }
                    }
                    Err(_) => break,
                }
            }
        }

        // Flush outgoing packets
        let mut out = [0u8; 65535];
        loop {
            match conn.send(&mut out) {
                Ok((write, _send_info)) => {
                    if write > 0 {
                        let _ = socket.send_to(&out[..write], peer);
                    }
                }
                Err(quiche::Error::Done) => break,
                Err(_) => break,
            }
        }

        if conn.is_closed() {
            println!("connection closed (dcid={:x?})", &conn_id);
            conns.remove(&conn_id);
        }
    }
}
