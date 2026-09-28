#!/usr/bin/env python3
"""Stand-in for the Voxtype daemon's level socket, for testing voxtype-overlay without a mic.

Usage: fake-daemon.py SOCKET TAKE...
TAKE is speech, loud, dead, quiet or restart (closes and rebinds the socket, as a daemon restart does).
Each take streams 16-byte frames (seq u32, min f32, max f32, peak_dbfs f32) at 100 Hz, like
voxtype's src/audio/levels.rs, to every connected client, with a 1.5 s pause between takes.
"""

import math
import os
import random
import socket
import struct
import sys
import time

FRAME_HZ = 100


def amplitude(take, t):
    if take == "dead":
        return 0.0
    if take == "quiet":
        return 0.002  # room noise only: a working mic nobody talks into
    # Words of ~0.6 s with short gaps, syllables at ~4 Hz inside each word.
    in_word = (t % 0.8) < 0.6 and not 1.6 < t < 2.4  # plus one longer pause
    syllable = 0.5 + 0.5 * math.sin(2 * math.pi * 4 * t)
    level = 0.25 if take == "loud" else 0.06
    return 0.002 + (level * syllable * random.uniform(0.6, 1.0) if in_word else 0)


def serve(path):
    if os.path.exists(path):
        os.unlink(path)
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(path)
    server.listen()
    server.setblocking(False)
    return server


def main():
    path, takes = sys.argv[1], sys.argv[2:]
    server = serve(path)
    clients = []
    seq = 0

    def accept():
        try:
            while True:
                clients.append(server.accept()[0])
        except BlockingIOError:
            pass

    for take in takes:
        time.sleep(1.5)
        accept()
        if take == "restart":
            for c in clients:
                c.close()
            clients.clear()
            server.close()
            server = serve(path)
            print("restarted", flush=True)
            continue
        print(f"take: {take}", flush=True)
        seq += 1000  # a new recording: the overlay sees a jump in seq and clears its history
        start = time.monotonic()
        duration = 3.0 if take in ("dead", "quiet") else 4.0
        for i in range(int(duration * FRAME_HZ)):
            accept()
            a = amplitude(take, i / FRAME_HZ)
            lo, hi = -a * random.uniform(0.8, 1.0), a * random.uniform(0.8, 1.0)
            peak = max(-lo, hi)
            db = -120.0 if peak <= 1e-6 else 20 * math.log10(peak)
            frame = struct.pack("=Ifff", seq, lo, hi, db)
            seq += 1
            for c in clients[:]:
                try:
                    c.sendall(frame)
                except OSError:
                    clients.remove(c)
            time.sleep(max(0, start + (i + 1) / FRAME_HZ - time.monotonic()))
    time.sleep(1.0)


if __name__ == "__main__":
    main()
