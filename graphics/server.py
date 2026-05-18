import os
import json
import webbrowser
from http.server import HTTPServer, SimpleHTTPRequestHandler


class Handler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/book-of-shaders":
            files = sorted(
                [f for f in os.listdir("./book-of-shaders/") if f.endswith(".frag")]
            )
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(files).encode())
        else:
            super().do_GET()


url = "http://localhost:8080"
print(url)
webbrowser.open(url)
HTTPServer(("localhost", 8080), Handler).serve_forever()
