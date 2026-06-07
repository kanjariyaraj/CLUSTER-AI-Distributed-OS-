#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <mutex>
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

struct NodeInfo {
    std::string address;
    int port;
    double load;
    std::chrono::steady_clock::time_point last_seen;
};

std::map<std::string, NodeInfo> cluster_nodes;
std::mutex nodes_mutex;

void start_discovery() {
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    struct sockaddr_in server_addr;
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(DISCOVERY_PORT);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    if (bind(sock, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        std::cerr << "Failed to bind discovery socket" << std::endl;
        return;
    }

    char buffer[1024];
    while (true) {
        struct sockaddr_in client_addr;
        socklen_t addr_len = sizeof(client_addr);
        int len = recvfrom(sock, buffer, sizeof(buffer), 0, (struct sockaddr*)&client_addr, &addr_len);
        if (len > 0) {
            buffer[len] = '\0';
            try {
                auto hb = json::parse(buffer);
                if (hb["type"] == "heartbeat") {
                    std::string ip = inet_ntoa(client_addr.sin_addr);
                    int port = hb["port"];
                    std::string key = ip + ":" + std::to_string(port);

                    std::lock_guard<std::mutex> lock(nodes_mutex);
                    cluster_nodes[key] = {ip, port, hb["load"], std::chrono::steady_clock::now()};
                    // Use a more quiet log for discovered nodes to avoid spamming
                }
            } catch (...) {}
        }
    }
}

void start_node_cleanup() {
    while (true) {
        std::this_thread::sleep_for(std::chrono::seconds(5));
        auto now = std::chrono::steady_clock::now();
        std::lock_guard<std::mutex> lock(nodes_mutex);
        for (auto it = cluster_nodes.begin(); it != cluster_nodes.end(); ) {
            auto diff = std::chrono::duration_cast<std::chrono::seconds>(now - it->second.last_seen).count();
            if (diff > 15) {
                std::cout << "Node timed out: " << it->first << std::endl;
                it = cluster_nodes.erase(it);
            } else {
                ++it;
            }
        }
    }
}

int main() {
    std::thread disc_thread(start_discovery);
    disc_thread.detach();

    std::thread clean_thread(start_node_cleanup);
    clean_thread.detach();

    Server svr;

    svr.Get("/nodes", [](const Request&, Response& res) {
        json out = json::array();
        std::lock_guard<std::mutex> lock(nodes_mutex);
        for (auto const& [key, info] : cluster_nodes) {
            json n;
            n["id"] = key;
            n["load"] = info.load;
            out.push_back(n);
        }
        res.set_content(out.dump(), "application/json");
    });

    svr.Post("/distribute", [](const Request& req, Response& res) {
        auto body = json::parse(req.body);
        
        std::string target_node;
        {
            std::lock_guard<std::mutex> lock(nodes_mutex);
            if (cluster_nodes.empty()) {
                res.status = 503;
                res.set_content("{\"error\": \"No nodes available\"}", "application/json");
                return;
            }
            // Simple load balancing: pick the first available
            target_node = cluster_nodes.begin()->first;
        }

        std::cout << "Distributing task to: " << target_node << std::endl;
        Client cli(target_node);
        auto node_res = cli.Post("/compute", body.dump(), "application/json");
        
        if (node_res) {
            res.set_content(node_res->body, "application/json");
        } else {
            res.status = 500;
            res.set_content("{\"error\": \"Node communication failed\"}", "application/json");
        }
    });

    std::cout << "AIDOS Controller starting on port 8082..." << std::endl;
    svr.listen("0.0.0.0", 8082);

    return 0;
}
