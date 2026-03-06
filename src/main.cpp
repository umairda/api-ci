#include "health_api.h"

#include <arpa/inet.h>
#include <csignal>
#include <cstring>
#include <iostream>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

namespace {
volatile std::sig_atomic_t keep_running = 1;

void handle_signal(int) {
    keep_running = 0;
}

bool is_health_request(const char* request_buf, ssize_t len) {
    if (len <= 0) {
        return false;
    }
    const std::string req(request_buf, static_cast<size_t>(len));
    return req.find("GET /health ") == 0;
}

std::string build_not_found_response() {
    const std::string body = "{\"error\":\"not found\"}";
    std::string response = "HTTP/1.1 404 Not Found\r\n";
    response += "Content-Type: application/json\r\n";
    response += "Content-Length: " + std::to_string(body.size()) + "\r\n";
    response += "Connection: close\r\n\r\n";
    response += body;
    return response;
}
} // namespace

int main() {
    std::signal(SIGINT, handle_signal);
    std::signal(SIGTERM, handle_signal);

    const int port = 8080;
    const int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        std::perror("socket");
        return 1;
    }

    int opt = 1;
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) {
        std::perror("setsockopt");
        close(server_fd);
        return 1;
    }

    sockaddr_in addr;
    std::memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);

    if (bind(server_fd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) < 0) {
        std::perror("bind");
        close(server_fd);
        return 1;
    }

    if (listen(server_fd, 16) < 0) {
        std::perror("listen");
        close(server_fd);
        return 1;
    }

    std::cout << "Health API listening on port " << port << std::endl;

    while (keep_running) {
        sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        int client_fd = accept(server_fd, reinterpret_cast<sockaddr*>(&client_addr), &client_len);

        if (client_fd < 0) {
            if (keep_running) {
                std::perror("accept");
            }
            continue;
        }

        char buffer[1024] = {0};
        ssize_t bytes = read(client_fd, buffer, sizeof(buffer));

        std::string response;
        if (is_health_request(buffer, bytes)) {
            response = build_http_ok_response(build_health_response_body());
        } else {
            response = build_not_found_response();
        }

        ssize_t total_written = 0;
        while (total_written < static_cast<ssize_t>(response.size())) {
            ssize_t written = write(
                client_fd,
                response.data() + total_written,
                response.size() - static_cast<size_t>(total_written));
            if (written <= 0) {
                break;
            }
            total_written += written;
        }

        close(client_fd);
    }

    close(server_fd);
    return 0;
}
