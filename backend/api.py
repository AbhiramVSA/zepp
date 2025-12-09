import logging
from fastapi import FastAPI
from fastapi.responses import HTMLResponse

from app.api.v1.audio_ws import router as audio_ws_router

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)

app = FastAPI(title="Voice App Backend")

app.include_router(audio_ws_router)


@app.get("/health")
async def health() -> dict[str, str]:
    """Simple health check endpoint."""
    return {"status": "ok"}


@app.get("/ws-test", response_class=HTMLResponse)
async def ws_test() -> str:
        """Lightweight WebSocket test page for manual verification."""
        return """
        <!DOCTYPE html>
        <html>
            <head>
                <meta charset=\"UTF-8\" />
                <title>WS Audio Test</title>
                <style>
                    body { font-family: Arial, sans-serif; margin: 24px; }
                    #log { white-space: pre-wrap; background: #f7f7f7; border: 1px solid #ddd; padding: 12px; height: 240px; overflow: auto; }
                    button { margin-right: 8px; }
                </style>
            </head>
            <body>
                <h2>WebSocket Audio Test</h2>
                <div>
                    <button id=\"connect\">Connect</button>
                    <button id=\"send\">Send Dummy Audio</button>
                    <button id=\"end\">Send End Event</button>
                    <button id=\"close\">Close</button>
                </div>
                <div id=\"log\"></div>
                <script>
                    const log = (msg) => {
                        const el = document.getElementById('log');
                        el.textContent += msg + '\n';
                        el.scrollTop = el.scrollHeight;
                    };

                    let ws;
                    document.getElementById('connect').onclick = () => {
                        ws = new WebSocket(`ws://${location.host}/ws/audio`);
                        ws.binaryType = 'arraybuffer';
                        ws.onopen = () => log('opened');
                        ws.onmessage = (e) => log('message: ' + e.data);
                        ws.onerror = (e) => log('error: ' + e.message);
                        ws.onclose = () => log('closed');
                    };

                    document.getElementById('send').onclick = () => {
                        if (!ws || ws.readyState !== WebSocket.OPEN) return log('not connected');
                        const chunk = new Uint8Array([0, 1, 2, 3]);
                        ws.send(chunk);
                        log('sent dummy bytes');
                    };

                    document.getElementById('end').onclick = () => {
                        if (!ws || ws.readyState !== WebSocket.OPEN) return log('not connected');
                        ws.send(JSON.stringify({ event: 'end' }));
                        log('sent end event');
                    };

                    document.getElementById('close').onclick = () => {
                        if (ws) ws.close();
                    };
                </script>
            </body>
        </html>
        """
