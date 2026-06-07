#include <iostream>
#include <string>
#include <thread>
#include <chrono>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include "../llama.cpp_src/vendor/cpp-httplib/httplib.h"
#include "../llama.cpp_src/vendor/nlohmann/json.hpp"

using json = nlohmann::json;
using namespace httplib;

const int DISCOVERY_PORT = 8888;

void start_heartbeat(int node_port) {
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    int broadcast = 1;
    setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof(broadcast));

    struct sockaddr_in broadcast_addr;
    broadcast_addr.sin_family = AF_INET;
    broadcast_addr.sin_port = htons(DISCOVERY_PORT);
    broadcast_addr.sin_addr.s_addr = inet_addr("255.255.255.255");

    while (true) {
        json heartbeat;
        heartbeat["type"] = "heartbeat";
        heartbeat["port"] = node_port;
        heartbeat["load"] = 0.5; // Mock load (50%)

        std::string msg = heartbeat.dump();
        sendto(sock, msg.c_str(), msg.length(), 0, (struct sockaddr*)&broadcast_addr, sizeof(broadcast_addr));

        std::this_thread::sleep_for(std::chrono::seconds(5));
    }
}

int main(int argc, char** argv) {
    int port = (argc > 1) ? std::stoi(argv[1]) : 8081;

    // Start discovery heartbeat in background
    std::thread hb_thread(start_heartbeat, port);
    hb_thread.detach();

    Server svr;

    svr.Post("/compute", [](const Request& req, Response& res) {
        auto body = json::parse(req.body);
        std::string prompt = body["prompt"];
        std::cout << "Computing task: " << prompt << std::endl;

        // In a real system, this would call llama.cpp
        // For now, we mock the result
        json result;
        result["output"] = "Node result for: " + prompt;
        
        res.set_content(result.dump(), "application/json");
    });

    std::cout << "AIDOS Node Server starting on port " << port << "..." << std::endl;
    svr.listen("0.0.0.0", port);

    return 0;
}
