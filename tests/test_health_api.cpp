#include "health_api.h"

#include <gtest/gtest.h>

TEST(HealthApiTest, HealthBodyIsOkJson) {
    EXPECT_EQ(build_health_response_body(), "{\"status\":\"ok\"}");
}

TEST(HealthApiTest, HttpResponseContainsStatusAndBody) {
    const std::string body = build_health_response_body();
    const std::string response = build_http_ok_response(body);

    EXPECT_NE(response.find("HTTP/1.1 200 OK"), std::string::npos);
    EXPECT_NE(response.find("Content-Type: application/json"), std::string::npos);
    EXPECT_NE(response.find(body), std::string::npos);
}

TEST(HealthApiTest, ContentLengthMatchesBodySize) {
    const std::string body = build_health_response_body();
    const std::string response = build_http_ok_response(body);
    const std::string expected = "Content-Length: " + std::to_string(body.size());

    EXPECT_NE(response.find(expected), std::string::npos);
}
