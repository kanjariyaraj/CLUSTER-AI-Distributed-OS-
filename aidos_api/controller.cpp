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
#include <netinet/tcp.h>
#include <unistd.h>
#include <algorithm>
#include <numeric>
#include <sstream>
#include "../llama.cpp_src/vendor/cpp-httplib/httplib.h"
#include "../llama.cpp_src/vendor/nlohmann/json.hpp"

using json = nlohmann::json;
using namespace httplib;

const int DISCOVERY_PORT = 8888;

struct NodeInfo {
    std::string address;
    int port;
    int rpc_port;
    double load;
    double memory_total_gb;
    double memory_avail_gb;
    std::chrono::steady_clock::time_point last_seen;
};

std::map<std::string, NodeInfo> cluster_nodes;
std::mutex nodes_mutex;

std::map<std::string, std::unique_ptr<Client>> node_clients;
std::mutex clients_mutex;

Client* get_node_client(const std::string& host, int port) {
    std::string key = host + ":" + std::to_string(port);
    std::lock_guard<std::mutex> lock(clients_mutex);
    auto it = node_clients.find(key);
    if (it != node_clients.end()) {
        return it->second.get();
    }
    auto cli = std::make_unique<Client>(host, port);
    cli->set_tcp_nodelay(true);
    cli->set_keep_alive(true);
    cli->set_compress(true);
    cli->set_read_timeout(300, 0);
    cli->set_write_timeout(60, 0);
    cli->set_connection_timeout(10);
    Client* ptr = cli.get();
    node_clients[key] = std::move(cli);
    return ptr;
}

Client* get_marketplace_client() {
    static Client cli("localhost", 8083);
    cli.set_tcp_nodelay(true);
    cli.set_keep_alive(true);
    cli.set_compress(true);
    return &cli;
}

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
                    cluster_nodes[key] = {
                        ip,
                        port,
                        hb.value("rpc_port", 50052),
                        hb["load"],
                        hb.value("memory_total_gb", 0.0),
                        hb.value("memory_avail_gb", 0.0),
                        std::chrono::steady_clock::now()
                    };
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

std::vector<std::pair<std::string, NodeInfo>> select_nodes_for_model(double model_size_gb) {
    std::lock_guard<std::mutex> lock(nodes_mutex);

    std::vector<std::pair<std::string, NodeInfo>> candidates;
    for (auto const& [key, info] : cluster_nodes) {
        candidates.push_back({key, info});
    }

    std::sort(candidates.begin(), candidates.end(),
        [](auto const& a, auto const& b) {
            return a.second.memory_avail_gb > b.second.memory_avail_gb;
        });

    std::vector<std::pair<std::string, NodeInfo>> selected;
    double total_selected_memory = 0;

    for (auto const& candidate : candidates) {
        selected.push_back(candidate);
        total_selected_memory += candidate.second.memory_avail_gb;
        if (total_selected_memory >= model_size_gb) {
            break;
        }
    }

    if (total_selected_memory >= model_size_gb) {
        return selected;
    }

    return {};
}

json serialize_node(const std::string& key, const NodeInfo& info) {
    json n;
    n["id"] = key;
    n["address"] = info.address;
    n["port"] = info.port;
    n["rpc_port"] = info.rpc_port;
    n["load"] = info.load;
    n["memory_total_gb"] = info.memory_total_gb;
    n["memory_avail_gb"] = info.memory_avail_gb;
    return n;
}

int main() {
    std::thread disc_thread(start_discovery);
    disc_thread.detach();

    std::thread clean_thread(start_node_cleanup);
    clean_thread.detach();

    Server svr;
    svr.set_tcp_nodelay(true);
    svr.set_keep_alive_max_count(100);
    svr.set_read_timeout(300, 0);
    svr.set_write_timeout(60, 0);

    svr.Get("/nodes", [](const Request&, Response& res) {
        json out = json::array();
        std::lock_guard<std::mutex> lock(nodes_mutex);
        for (auto const& [key, info] : cluster_nodes) {
            out.push_back(serialize_node(key, info));
        }
        res.set_content(out.dump(), "application/json");
    });

    svr.Get("/rpc_endpoints", [](const Request&, Response& res) {
        json out = json::array();
        std::lock_guard<std::mutex> lock(nodes_mutex);
        for (auto const& [key, info] : cluster_nodes) {
            json ep;
            ep["node_id"] = key;
            ep["endpoint"] = "rpc://" + info.address + ":" + std::to_string(info.rpc_port);
            out.push_back(ep);
        }
        res.set_content(out.dump(), "application/json");
    });

    svr.Get("/cluster_memory", [](const Request&, Response& res) {
        std::lock_guard<std::mutex> lock(nodes_mutex);
        double total = 0, available = 0;
        int node_count = 0;
        for (auto const& [key, info] : cluster_nodes) {
            total += info.memory_total_gb;
            available += info.memory_avail_gb;
            node_count++;
        }
        json out;
        out["node_count"] = node_count;
        out["total_memory_gb"] = total;
        out["available_memory_gb"] = available;
        out["used_memory_gb"] = total - available;
        res.set_content(out.dump(), "application/json");
    });

    svr.Post("/launch", [](const Request& req, Response& res) {
        auto body = json::parse(req.body);
        std::string model_path = body.value("model", "");
        double model_size_gb = body.value("model_size_gb", 0.0);

        if (model_path.empty()) {
            res.status = 400;
            res.set_content("{\"error\": \"model path required\"}", "application/json");
            return;
        }

        std::vector<std::pair<std::string, NodeInfo>> selected;
        if (model_size_gb > 0) {
            selected = select_nodes_for_model(model_size_gb);
            if (selected.empty()) {
                double total_avail = 0;
                {
                    std::lock_guard<std::mutex> lock(nodes_mutex);
                    for (auto const& [k, v] : cluster_nodes)
                        total_avail += v.memory_avail_gb;
                }
                json err;
                err["error"] = "Insufficient cluster memory";
                err["model_size_gb"] = model_size_gb;
                err["available_cluster_memory_gb"] = total_avail;
                res.status = 503;
                res.set_content(err.dump(), "application/json");
                return;
            }
        } else {
            std::lock_guard<std::mutex> lock(nodes_mutex);
            for (auto const& [key, info] : cluster_nodes)
                selected.push_back({key, info});
        }

        json result;
        result["model"] = model_path;
        result["num_nodes"] = (int)selected.size();

        // Build RPC comma-separated URLs for --rpc flag
        std::stringstream rpc_ss;
        json rpc_list = json::array();
        json nodes_list = json::array();

        for (size_t i = 0; i < selected.size(); i++) {
            auto const& [key, info] = selected[i];
            if (i > 0) rpc_ss << ",";
            rpc_ss << info.address << ":" << info.rpc_port;

            json ep;
            ep["node_id"] = key;
            ep["rpc_endpoint"] = "rpc://" + info.address + ":" + std::to_string(info.rpc_port);
            rpc_list.push_back(ep);
            nodes_list.push_back(serialize_node(key, info));
        }

        result["rpc_endpoints"] = rpc_list;
        result["nodes"] = nodes_list;
        result["rpc_urls"] = rpc_ss.str();

        // Generate the full llama-server command
        std::stringstream cmd;
        cmd << "/opt/aidos/llama.cpp/llama-server";
        cmd << " --model " << model_path;
        cmd << " --port 8080";
        cmd << " --host 0.0.0.0";
        cmd << " --rpc rpc://" << rpc_ss.str();
        cmd << " --no-mmap";
        cmd << " -ngl 99";
        result["command"] = cmd.str();

        // Also generate a simpler equivalent for /opt/aidos/ollama compatibility
        std::stringstream ollama_cmd;
        ollama_cmd << "OLLAMA_RPC=\"rpc://" << rpc_ss.str() << "\"";
        ollama_cmd << " /opt/aidos/ollama/bin/ollama run " << model_path;
        result["ollama_command"] = ollama_cmd.str();

        res.set_content(result.dump(), "application/json");
    });

    svr.Post("/distribute", [](const Request& req, Response& res) {
        auto body = json::parse(req.body);
        std::string prompt = body.value("prompt", "");
        double model_size_gb = body.value("model_size_gb", 0.0);

        {
            std::lock_guard<std::mutex> lock(nodes_mutex);
            if (cluster_nodes.empty()) {
                res.status = 503;
                res.set_content("{\"error\": \"No nodes available\"}", "application/json");
                return;
            }
        }

        if (model_size_gb > 0) {
            auto selected = select_nodes_for_model(model_size_gb);
            if (selected.empty()) {
                double total_avail = 0;
                {
                    std::lock_guard<std::mutex> lock(nodes_mutex);
                    for (auto const& [k, v] : cluster_nodes)
                        total_avail += v.memory_avail_gb;
                }
                json err;
                err["error"] = "Insufficient cluster memory";
                err["model_size_gb"] = model_size_gb;
                err["available_cluster_memory_gb"] = total_avail;
                res.status = 503;
                res.set_content(err.dump(), "application/json");
                return;
            }

            json result;
            result["strategy"] = "tensor_split";
            result["num_nodes"] = (int)selected.size();
            json rpc_list = json::array();
            for (auto const& [key, info] : selected) {
                json ep;
                ep["node_id"] = key;
                ep["rpc_endpoint"] = "rpc://" + info.address + ":" + std::to_string(info.rpc_port);
                rpc_list.push_back(ep);
            }
            result["rpc_endpoints"] = rpc_list;

            std::stringstream rpc_ss;
            for (size_t i = 0; i < selected.size(); i++) {
                if (i > 0) rpc_ss << ",";
                rpc_ss << selected[i].first;
            }
            result["rpc_urls"] = rpc_ss.str() + ":50052";

            Client* mkt = get_marketplace_client();
            for (auto const& [key, info] : selected) {
                try {
                    json report;
                    report["node_id"] = key;
                    report["units"] = model_size_gb;
                    report["load"] = info.load;
                    mkt->Post("/report_work", report.dump(), "application/json");
                } catch (...) {}
            }

            res.set_content(result.dump(), "application/json");
            return;
        }

        std::string target_node;
        double best_mem = -1;
        {
            std::lock_guard<std::mutex> lock(nodes_mutex);
            for (auto const& [key, info] : cluster_nodes) {
                if (info.memory_avail_gb > best_mem) {
                    best_mem = info.memory_avail_gb;
                    target_node = key;
                }
            }
        }

        std::cout << "Distributing task to: " << target_node
                  << " (avail mem: " << best_mem << " GB)" << std::endl;

        Client* cli = get_node_client(target_node, 8081);
        json compute_body;
        compute_body["prompt"] = prompt;
        auto node_res = cli->Post("/compute", compute_body.dump(), "application/json");

        if (node_res) {
            Client* mkt = get_marketplace_client();
            json report;
            report["node_id"] = target_node;
            report["units"] = 1.0;
            report["load"] = 0.8;
            mkt->Post("/report_work", report.dump(), "application/json");

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
