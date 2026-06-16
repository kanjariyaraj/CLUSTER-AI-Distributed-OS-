#include <iostream>
#include <string>
#include <thread>
#include <chrono>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <fstream>
#include <cstring>
#include "../llama.cpp_src/vendor/cpp-httplib/httplib.h"
#include "../llama.cpp_src/vendor/nlohmann/json.hpp"

using json = nlohmann::json;
using namespace httplib;

const int DISCOVERY_PORT = 8888;

struct MemoryInfo {
    double total_gb;
    double available_gb;
};

MemoryInfo read_memory_info() {
    MemoryInfo info = {0, 0};
    std::ifstream meminfo("/proc/meminfo");
    std::string line;
    while (std::getline(meminfo, line)) {
        if (line.compare(0, 10, "MemTotal: ") == 0) {
            info.total_gb = std::stod(line.substr(10)) / 1024.0 / 1024.0;
        } else if (line.compare(0, 13, "MemAvailable: ") == 0) {
            info.available_gb = std::stod(line.substr(13)) / 1024.0 / 1024.0;
        }
    }
    return info;
}

void start_heartbeat(int node_port, int rpc_port) {
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    int broadcast = 1;
    setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof(broadcast));

    struct sockaddr_in broadcast_addr;
    broadcast_addr.sin_family = AF_INET;
    broadcast_addr.sin_port = htons(DISCOVERY_PORT);
    broadcast_addr.sin_addr.s_addr = inet_addr("255.255.255.255");

    while (true) {
        auto mem = read_memory_info();
        json heartbeat;
        heartbeat["type"] = "heartbeat";
        heartbeat["port"] = node_port;
        heartbeat["rpc_port"] = rpc_port;
        heartbeat["load"] = 1.0 - (mem.available_gb / mem.total_gb);
        heartbeat["memory_total_gb"] = mem.total_gb;
        heartbeat["memory_avail_gb"] = mem.available_gb;

        std::string msg = heartbeat.dump();
        sendto(sock, msg.c_str(), msg.length(), 0, (struct sockaddr*)&broadcast_addr, sizeof(broadcast_addr));

        std::this_thread::sleep_for(std::chrono::seconds(5));
    }
}

int main(int argc, char** argv) {
    int port = (argc > 1) ? std::stoi(argv[1]) : 8081;
    int rpc_port = (argc > 2) ? std::stoi(argv[2]) : 50052;

    std::thread hb_thread(start_heartbeat, port, rpc_port);
    hb_thread.detach();

    Server svr;
    svr.set_tcp_nodelay(true);
    svr.set_keep_alive_max_count(100);
    svr.set_read_timeout(300, 0);
    svr.set_write_timeout(60, 0);

    svr.Get("/memory", [](const Request&, Response& res) {
        auto mem = read_memory_info();
        json result;
        result["total_gb"] = mem.total_gb;
        result["available_gb"] = mem.available_gb;
        result["used_gb"] = mem.total_gb - mem.available_gb;
        result["load"] = 1.0 - (mem.available_gb / mem.total_gb);
        res.set_content(result.dump(), "application/json");
    });

    svr.Get("/rpc", [rpc_port](const Request&, Response& res) {
        json result;
        result["rpc_port"] = rpc_port;
        result["rpc_endpoint"] = "rpc://" + std::to_string(rpc_port);
        res.set_content(result.dump(), "application/json");
    });

    svr.Post("/compute", [](const Request& req, Response& res) {
        auto body = json::parse(req.body);
        std::string prompt = body["prompt"];
        std::cout << "Computing task: " << prompt << std::endl;

        json result;
        result["output"] = "Node result for: " + prompt;

        // Support binary response via CBOR if client requests it
        std::string accept = req.get_header_value("Accept");
        if (accept.find("application/cbor") != std::string::npos) {
            auto vec = json::to_cbor(result);
            std::string body(reinterpret_cast<const char*>(vec.data()), vec.size());
            res.set_content(body, "application/cbor");
        } else {
            res.set_content(result.dump(), "application/json");
        }
    });

    svr.Post("/compute_binary", [](const Request& req, Response& res) {
        auto body = json::from_cbor(req.body);
        std::string prompt = body["prompt"];
        std::cout << "Computing task (binary): " << prompt << std::endl;

        json result;
        result["output"] = "Node result for: " + prompt;

        auto vec = json::to_cbor(result);
        std::string cbor_body(reinterpret_cast<const char*>(vec.data()), vec.size());
        res.set_content(cbor_body, "application/cbor");
    });

    std::cout << "AIDOS Node Server starting on port " << port
              << " (rpc-server port: " << rpc_port << ")..." << std::endl;
    svr.listen("0.0.0.0", port);

    return 0;
}
