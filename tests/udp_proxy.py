"""Local impairment proxy for ENet integration tests (latency/jitter/loss)."""
import heapq
import random
import select
import socket
import threading
import time

class UDPProxy:
    def __init__(self, listen_port, upstream_port, rtt_ms=100, loss=0.01):
        self.listener = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.listener.bind(('127.0.0.1', listen_port))
        self.upstream = ('127.0.0.1', upstream_port)
        self.rtt = rtt_ms / 2000
        self.loss = loss
        self.peers = {}
        self.reverse = {}
        self.pending = []
        self.sequence = 0
        self.stopping = False
        self.random = random.Random(7341)
        self.thread = threading.Thread(target=self.run, daemon=True)
        self.thread.start()
    def queue(self, sender, target, data):
        if self.random.random() < self.loss:
            return
        self.sequence += 1
        delay = max(0, self.rtt + self.random.uniform(-0.01, 0.01))
        heapq.heappush(self.pending, (time.monotonic()+delay, self.sequence, sender, target, data))
    def run(self):
        while not self.stopping:
            readable, _, _ = select.select([self.listener]+list(self.reverse), [], [], 0.002)
            for source in readable:
                data, address = source.recvfrom(65535)
                if source is self.listener:
                    if address not in self.peers:
                        backend = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                        backend.bind(('127.0.0.1', 0))
                        self.peers[address] = backend
                        self.reverse[backend] = address
                    self.queue(self.peers[address], self.upstream, data)
                else:
                    self.queue(self.listener, self.reverse[source], data)
            while self.pending and self.pending[0][0] <= time.monotonic():
                _, _, sender, target, data = heapq.heappop(self.pending)
                sender.sendto(data, target)
    def close(self):
        self.stopping = True
        self.thread.join(timeout=2)
        self.listener.close()
        for backend in self.reverse:
            backend.close()
