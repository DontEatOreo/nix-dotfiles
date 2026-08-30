"""Byte-accurate stdio proxy for JSON-RPC language servers."""

import atexit
import signal
import subprocess
import sys
import threading
from collections.abc import Callable, Sequence
from typing import BinaryIO, cast

type MessageFilter = Callable[[bytes], bytes]
type MessageObserver = Callable[[bytes], None]


def read_lsp_message(stream: BinaryIO) -> bytes | None:
    content_length = None
    while line := stream.readline():
        if line in {b"\n", b"\r\n"}:
            break
        name, separator, value = line.partition(b":")
        if separator and name.strip().lower() == b"content-length":
            content_length = int(value.strip())
    else:
        return None

    if content_length is None:
        raise ValueError("LSP message is missing Content-Length")
    body = stream.read(content_length)
    if len(body) != content_length:
        raise EOFError("LSP message ended before Content-Length bytes were read")
    return body


def write_lsp_message(stream: BinaryIO, body: bytes) -> None:
    stream.write(f"Content-Length: {len(body)}\r\n\r\n".encode())
    stream.write(body)
    stream.flush()


def proxy_lsp_server(
    argv: Sequence[str],
    observe_client_message: MessageObserver,
    filter_server_message: MessageFilter,
) -> int:
    server = subprocess.Popen(
        argv,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
    )
    if server.stdin is None or server.stdout is None:
        raise RuntimeError("failed to open language server standard streams")
    server_stdin = cast("BinaryIO", server.stdin)
    server_stdout = cast("BinaryIO", server.stdout)

    def stop_server() -> None:
        if server.poll() is None:
            server.terminate()

    def handle_signal(signum: int, _frame: object) -> None:
        stop_server()
        raise SystemExit(128 + signum)

    atexit.register(stop_server)
    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    def forward_client_messages() -> None:
        try:
            while (body := read_lsp_message(sys.stdin.buffer)) is not None:
                observe_client_message(body)
                write_lsp_message(server_stdin, body)
        except BrokenPipeError:
            pass
        finally:
            server_stdin.close()
            stop_server()

    threading.Thread(target=forward_client_messages, daemon=True).start()
    try:
        while (body := read_lsp_message(server_stdout)) is not None:
            write_lsp_message(sys.stdout.buffer, filter_server_message(body))
    except BrokenPipeError:
        stop_server()
    return server.wait()
