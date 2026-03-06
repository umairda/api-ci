#include "health_api.h"

#include <sstream>

std::string build_health_response_body() {
    return "{\"status\":\"ok\"}";
}

std::string build_http_ok_response(const std::string& body) {
    std::ostringstream response;
    response << "HTTP/1.1 200 OK\r\n";
    response << "Content-Type: application/json\r\n";
    response << "Content-Length: " << body.size() << "\r\n";
    response << "Connection: close\r\n\r\n";
    response << body;
    return response.str();
}
