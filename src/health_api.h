#ifndef HEALTH_API_H
#define HEALTH_API_H

#include <string>

std::string build_health_response_body();
std::string build_http_ok_response(const std::string& body);

#endif
