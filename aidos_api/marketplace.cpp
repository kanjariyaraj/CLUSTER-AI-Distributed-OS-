#include <iostream>
#include <string>
#include <map>
#include <mutex>
#include <vector>
#include <sstream>
#include <iomanip>
#include "../llama.cpp_src/vendor/cpp-httplib/httplib.h"
#include "../llama.cpp_src/vendor/nlohmann/json.hpp"

using json = nlohmann::json;
using namespace httplib;

struct Account {
    std::string node_id;
    double total_compute_units;
    double last_load;
};

std::map<std::string, Account> ledger;
std::mutex ledger_mutex;

std::string generate_dashboard_html() {
    std::lock_guard<std::mutex> lock(ledger_mutex);
    std::stringstream ss;
    ss << "<html><head><title>AIDOS Marketplace</title>";
    ss << "<style>body{font-family:sans-serif; background:#121212; color:#eee; padding:20px;} ";
    ss << "table{width:100%; border-collapse:collapse;} th,td{border:1px solid #333; padding:10px; text-align:left;} ";
    ss << "th{background:#1a1a1a;} .total{font-size:2em; color:#00ff88;}</style></head><body>";
    ss << "<h1>AIDOS AI Marketplace</h1>";
    
    double total_units = 0;
    for (auto const& [id, acc] : ledger) total_units += acc.total_compute_units;
    
    ss << "<div class='total'>Total Cluster Power: " << std::fixed << std::setprecision(2) << total_units << " AIDOS Credits</div>";
    ss << "<h3>Active Contributors</h3>";
    ss << "<table><tr><th>Node ID</th><th>Total Credits Earned</th><th>Real-Time Load</th></tr>";
    
    for (auto const& [id, acc] : ledger) {
        ss << "<tr><td>" << id << "</td><td>" << acc.total_compute_units << "</td><td>" << acc.last_load * 100 << "%</td></tr>";
    }
    
    ss << "</table></body></html>";
    return ss.str();
}

int main() {
    Server svr;

    // API: Register work completion
    svr.Post("/report_work", [](const Request& req, Response& res) {
        auto body = json::parse(req.body);
        std::string node_id = body["node_id"];
        double work_amount = body["units"];
        double current_load = body["load"];

        std::lock_guard<std::mutex> lock(ledger_mutex);
        ledger[node_id].node_id = node_id;
        ledger[node_id].total_compute_units += work_amount;
        ledger[node_id].last_load = current_load;

        std::cout << "Recorded " << work_amount << " units for node " << node_id << std::endl;
        res.set_content("{\"status\": \"ok\"}", "application/json");
    });

    // API: Get leaderboard
    svr.Get("/ledger", [](const Request&, Response& res) {
        json out = json::array();
        std::lock_guard<std::mutex> lock(ledger_mutex);
        for (auto const& [id, acc] : ledger) {
            json item;
            item["node_id"] = id;
            item["credits"] = acc.total_compute_units;
            out.push_back(item);
        }
        res.set_content(out.dump(), "application/json");
    });

    // Web Dashboard
    svr.Get("/", [](const Request&, Response& res) {
        res.set_content(generate_dashboard_html(), "text/html");
    });

    std::cout << "AIDOS Marketplace starting on port 8083..." << std::endl;
    svr.listen("0.0.0.0", 8083);

    return 0;
}
