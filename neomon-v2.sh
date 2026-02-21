#!/bin/bash 

# 🧠 NEOMON V2 - Advanced System Monitor
# 👤 Owner: Nanakusa Chan
# 💬 Discord: nanakusa4me
# 🐙 GitHub: nanakusaChan

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${PURPLE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║     🧠 NEOMON V2 - ADVANCED SYSTEM MONITOR           ║${NC}"
echo -e "${PURPLE}║              👤 Owner: Nanakusa Chan                  ║${NC}"
echo -e "${PURPLE}║     💬 Discord: nanakusa4me  🐙 GitHub: nanakusaChan  ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════╝${NC}"

# 1. SYSTEM UPDATE
echo -e "${GREEN}[1/5] Updating system...${NC}"
sudo pacman -Syu --noconfirm

# 2. INSTALL PACKAGES
echo -e "${GREEN}[2/5] Installing Python and pip...${NC}"
sudo pacman -S --noconfirm python python-pip python-virtualenv

# 3. CREATE VIRTUAL ENVIRONMENT
echo -e "${GREEN}[3/5] Creating Python virtual environment...${NC}"
cd ~
rm -rf neomon-v2
mkdir -p neomon-v2
cd neomon-v2
python -m venv venv
source venv/bin/activate

# 4. INSTALL PYTHON PACKAGES
echo -e "${GREEN}[4/5] Installing Python packages...${NC}"
pip install --upgrade pip
pip install fastapi uvicorn psutil httpx python-multipart py-cpuinfo

# 5. CREATE ALL FILES
echo -e "${GREEN}[5/5] Creating NEOMON V2 files...${NC}"

mkdir -p backend
mkdir -p frontend/assets
mkdir -p docs

# ==================== BACKEND (ENHANCED) ====================
cat > backend/main.py << 'EOF'
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
import psutil
import time
import platform
import cpuinfo
from datetime import datetime
import os
import json
import socket
import subprocess

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class SystemMonitor:
    @staticmethod
    def get_system_info():
        uname = platform.uname()
        return {
            "system": uname.system,
            "node_name": uname.node,
            "release": uname.release,
            "version": uname.version,
            "machine": uname.machine,
            "processor": uname.processor,
            "cpu_brand": cpuinfo.get_cpu_info().get('brand_raw', 'Unknown'),
            "hostname": socket.gethostname(),
            "ip_address": socket.gethostbyname(socket.gethostname())
        }
    
    @staticmethod
    def get_cpu():
        return {
            "percent": psutil.cpu_percent(interval=1),
            "percent_per_core": psutil.cpu_percent(interval=1, percpu=True),
            "cores_logical": psutil.cpu_count(),
            "cores_physical": psutil.cpu_count(logical=False),
            "load_avg": psutil.getloadavg(),
            "frequency_current": psutil.cpu_freq().current if psutil.cpu_freq() else 0,
            "frequency_max": psutil.cpu_freq().max if psutil.cpu_freq() else 0,
            "frequency_min": psutil.cpu_freq().min if psutil.cpu_freq() else 0,
            "stats": {
                "ctx_switches": psutil.cpu_stats().ctx_switches,
                "interrupts": psutil.cpu_stats().interrupts,
                "soft_interrupts": psutil.cpu_stats().soft_interrupts,
                "syscalls": psutil.cpu_stats().syscalls if hasattr(psutil.cpu_stats(), 'syscalls') else 0
            }
        }
    
    @staticmethod
    def get_memory():
        mem = psutil.virtual_memory()
        swap = psutil.swap_memory()
        return {
            "ram": {
                "total": mem.total,
                "available": mem.available,
                "used": mem.used,
                "percent": mem.percent,
                "free": mem.free,
                "active": mem.active if hasattr(mem, 'active') else 0,
                "inactive": mem.inactive if hasattr(mem, 'inactive') else 0,
                "buffers": mem.buffers if hasattr(mem, 'buffers') else 0,
                "cached": mem.cached if hasattr(mem, 'cached') else 0,
                "shared": mem.shared if hasattr(mem, 'shared') else 0
            },
            "swap": {
                "total": swap.total,
                "used": swap.used,
                "free": swap.free,
                "percent": swap.percent,
                "sin": swap.sin if hasattr(swap, 'sin') else 0,
                "sout": swap.sout if hasattr(swap, 'sout') else 0
            }
        }
    
    @staticmethod
    def get_disk():
        disk = psutil.disk_usage('/')
        disk_io = psutil.disk_io_counters()
        partitions = []
        for partition in psutil.disk_partitions():
            try:
                usage = psutil.disk_usage(partition.mountpoint)
                partitions.append({
                    "device": partition.device,
                    "mountpoint": partition.mountpoint,
                    "fstype": partition.fstype,
                    "total": usage.total,
                    "used": usage.used,
                    "free": usage.free,
                    "percent": usage.percent
                })
            except:
                pass
        return {
            "root": {
                "total": disk.total,
                "used": disk.used,
                "free": disk.free,
                "percent": disk.percent
            },
            "partitions": partitions,
            "io": {
                "read_count": disk_io.read_count if disk_io else 0,
                "write_count": disk_io.write_count if disk_io else 0,
                "read_bytes": disk_io.read_bytes if disk_io else 0,
                "write_bytes": disk_io.write_bytes if disk_io else 0,
                "read_time": disk_io.read_time if disk_io else 0,
                "write_time": disk_io.write_time if disk_io else 0
            } if disk_io else {}
        }
    
    @staticmethod
    def get_uptime():
        boot_time = datetime.fromtimestamp(psutil.boot_time())
        uptime = datetime.now() - boot_time
        days = uptime.days
        hours = uptime.seconds // 3600
        minutes = (uptime.seconds % 3600) // 60
        seconds = uptime.seconds % 60
        return {
            "boot_time": boot_time.isoformat(),
            "boot_time_readable": boot_time.strftime("%Y-%m-%d %H:%M:%S"),
            "uptime_seconds": uptime.total_seconds(),
            "uptime_readable": f"{days}d {hours}h {minutes}m {seconds}s",
            "uptime": str(uptime).split('.')[0]
        }
    
    @staticmethod
    def get_users():
        users = []
        for user in psutil.users():
            users.append({
                "name": user.name,
                "terminal": user.terminal,
                "host": user.host,
                "started": datetime.fromtimestamp(user.started).isoformat(),
                "pid": user.pid
            })
        return users
    
    @staticmethod
    def get_sensors():
        temps = {}
        if hasattr(psutil, "sensors_temperatures"):
            sensors = psutil.sensors_temperatures()
            for name, entries in sensors.items():
                temps[name] = []
                for entry in entries:
                    temps[name].append({
                        "label": entry.label or name,
                        "current": entry.current,
                        "high": entry.high,
                        "critical": entry.critical
                    })
        
        fans = {}
        if hasattr(psutil, "sensors_fans"):
            fan_sensors = psutil.sensors_fans()
            for name, entries in fan_sensors.items():
                fans[name] = []
                for entry in entries:
                    fans[name].append({
                        "label": entry.label or name,
                        "current": entry.current
                    })
        
        return {"temperatures": temps, "fans": fans}

monitor = SystemMonitor()
last_network_time = time.time()
last_recv = 0
last_sent = 0
network_history = []

@app.get("/api/system")
async def get_system():
    return {
        "system_info": monitor.get_system_info(),
        "cpu": monitor.get_cpu(),
        "memory": monitor.get_memory(),
        "disk": monitor.get_disk(),
        "uptime": monitor.get_uptime(),
        "users": monitor.get_users(),
        "sensors": monitor.get_sensors()
    }

@app.get("/api/network")
async def get_network():
    global last_network_time, last_recv, last_sent, network_history
    
    net = psutil.net_io_counters()
    current_time = time.time()
    
    if last_network_time and current_time > last_network_time:
        time_diff = current_time - last_network_time
        download_speed = (net.bytes_recv - last_recv) / time_diff
        upload_speed = (net.bytes_sent - last_sent) / time_diff
    else:
        download_speed = upload_speed = 0
    
    # Network history (last 60 seconds)
    network_history.append({
        "time": current_time,
        "download": download_speed,
        "upload": upload_speed
    })
    if len(network_history) > 60:
        network_history.pop(0)
    
    last_recv = net.bytes_recv
    last_sent = net.bytes_sent
    last_network_time = current_time
    
    # Get network interfaces
    interfaces = []
    for name, addrs in psutil.net_if_addrs().items():
        for addr in addrs:
            interfaces.append({
                "interface": name,
                "family": str(addr.family),
                "address": addr.address,
                "netmask": addr.netmask,
                "broadcast": addr.broadcast
            })
    
    # Get connections
    try:
        connections = psutil.net_connections()
        connections_list = []
        for conn in connections[:50]:  # Limit to 50 connections
            connections_list.append({
                "fd": conn.fd,
                "family": conn.family,
                "type": conn.type,
                "laddr": f"{conn.laddr.ip}:{conn.laddr.port}" if conn.laddr else "",
                "raddr": f"{conn.raddr.ip}:{conn.raddr.port}" if conn.raddr else "",
                "status": conn.status,
                "pid": conn.pid
            })
        open_ports = len(set([conn.laddr.port for conn in connections if conn.status == 'LISTEN']))
    except:
        connections = []
        connections_list = []
        open_ports = 0
    
    return {
        "download_speed": download_speed,
        "upload_speed": upload_speed,
        "total_download": net.bytes_recv,
        "total_upload": net.bytes_sent,
        "packets_sent": net.packets_sent if hasattr(net, 'packets_sent') else 0,
        "packets_recv": net.packets_recv if hasattr(net, 'packets_recv') else 0,
        "errin": net.errin if hasattr(net, 'errin') else 0,
        "errout": net.errout if hasattr(net, 'errout') else 0,
        "dropin": net.dropin if hasattr(net, 'dropin') else 0,
        "dropout": net.dropout if hasattr(net, 'dropout') else 0,
        "active_connections": len(connections),
        "open_ports": open_ports,
        "connections": connections_list,
        "interfaces": interfaces,
        "history": network_history
    }

@app.get("/api/processes")
async def get_processes(limit: int = 10):
    processes = []
    for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent', 'memory_info', 'status', 'create_time', 'username']):
        try:
            pinfo = proc.info
            if pinfo['cpu_percent'] is None:
                pinfo['cpu_percent'] = 0
            if pinfo['memory_percent'] is None:
                pinfo['memory_percent'] = 0
            pinfo['memory_rss'] = pinfo['memory_info'].rss if pinfo['memory_info'] else 0
            pinfo['memory_vms'] = pinfo['memory_info'].vms if pinfo['memory_info'] else 0
            pinfo['create_time'] = datetime.fromtimestamp(pinfo['create_time']).isoformat() if pinfo['create_time'] else None
            processes.append(pinfo)
        except:
            pass
    
    top_cpu = sorted(processes, key=lambda x: x['cpu_percent'], reverse=True)[:limit]
    top_memory = sorted(processes, key=lambda x: x['memory_percent'], reverse=True)[:limit]
    
    return {
        "top_cpu": top_cpu,
        "top_memory": top_memory,
        "total_processes": len(processes),
        "process_count_by_status": {
            "running": len([p for p in processes if p.get('status') == 'running']),
            "sleeping": len([p for p in processes if p.get('status') == 'sleeping']),
            "stopped": len([p for p in processes if p.get('status') == 'stopped']),
            "zombie": len([p for p in processes if p.get('status') == 'zombie'])
        }
    }

@app.get("/api/battery")
async def get_battery():
    if hasattr(psutil, "sensors_battery"):
        battery = psutil.sensors_battery()
        if battery:
            return {
                "percent": battery.percent,
                "power_plugged": battery.power_plugged,
                "time_left": battery.secsleft if battery.secsleft != -1 else None
            }
    return {"error": "No battery found"}

@app.get("/api/owner")
async def get_owner():
    return {
        "name": "Nanakusa Chan",
        "discord": "nanakusa4me",
        "github": "nanakusaChan",
        "project": "NEOMON V2",
        "version": "2.0.0",
        "description": "Advanced System Monitor with Hacker Style UI"
    }

@app.get("/")
async def serve_frontend():
    return FileResponse(os.path.join(os.path.dirname(__file__), "../frontend/index.html"))

@app.get("/{path}")
async def serve_static(path: str):
    file_path = os.path.join(os.path.dirname(__file__), f"../frontend/{path}")
    if os.path.exists(file_path):
        return FileResponse(file_path)
    return {"error": "File not found"}
EOF

# ==================== FRONTEND INDEX (ENHANCED) ====================
cat > frontend/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NEOMON V2 - Advanced System Monitor</title>
    <link rel="stylesheet" href="style.css">
</head>
<body class="theme-dark-hacker">
    <div class="matrix-bg" id="matrixCanvas"></div>
    
    <div class="container">
        <nav class="navbar">
            <div class="logo">
                <h1>🧠 NEOMON <span class="version">v2.0</span></h1>
                <span class="owner-badge">by Nanakusa Chan</span>
            </div>
            <div class="nav-links">
                <button class="nav-btn active" data-page="home">🏠 HOME</button>
                <button class="nav-btn" data-page="system">💻 SYSTEM</button>
                <button class="nav-btn" data-page="network">🌐 NETWORK</button>
                <button class="nav-btn" data-page="process">📊 PROCESS</button>
                <button class="nav-btn" data-page="themes">🎨 THEMES</button>
                <button class="nav-btn" data-page="owner">👤 OWNER</button>
            </div>
        </nav>

        <!-- HOME PAGE -->
        <div id="home-page" class="page active">
            <div class="welcome-card">
                <h2>Welcome to NEOMON V2</h2>
                <p>Advanced System Monitor with Hacker Style UI</p>
                <div class="features-grid">
                    <div class="feature">
                        <span class="feature-icon">💻</span>
                        <h3>System Monitoring</h3>
                        <p>CPU, RAM, Disk, Swap usage with real-time graphs</p>
                    </div>
                    <div class="feature">
                        <span class="feature-icon">🌐</span>
                        <h3>Network Analysis</h3>
                        <p>Upload/Download speed, connections, ports, interfaces</p>
                    </div>
                    <div class="feature">
                        <span class="feature-icon">📊</span>
                        <h3>Process Manager</h3>
                        <p>Track top CPU/RAM processes, process details</p>
                    </div>
                    <div class="feature">
                        <span class="feature-icon">🎨</span>
                        <h3>10+ Themes</h3>
                        <p>Multiple hacker-style themes with Matrix effect</p>
                    </div>
                    <div class="feature">
                        <span class="feature-icon">🔌</span>
                        <h3>Network Ports</h3>
                        <p>Active connections and open ports monitoring</p>
                    </div>
                    <div class="feature">
                        <span class="feature-icon">👤</span>
                        <h3>Owner Info</h3>
                        <p>Discord: nanakusa4me | GitHub: nanakusaChan</p>
                    </div>
                </div>
                <div class="quick-stats">
                    <h3>Quick System Overview</h3>
                    <div class="stats-grid" id="quick-stats"></div>
                </div>
            </div>
        </div>

        <!-- SYSTEM PAGE -->
        <div id="system-page" class="page">
            <div class="dashboard">
                <div class="card">
                    <h2>💻 SYSTEM INFO</h2>
                    <div class="info-line"><span>Hostname:</span> <span id="hostname">-</span></div>
                    <div class="info-line"><span>OS:</span> <span id="os">-</span></div>
                    <div class="info-line"><span>Kernel:</span> <span id="kernel">-</span></div>
                    <div class="info-line"><span>CPU Model:</span> <span id="cpu-model">-</span></div>
                    <div class="info-line"><span>IP Address:</span> <span id="ip-address">-</span></div>
                </div>

                <div class="card">
                    <h2>📊 CPU</h2>
                    <div class="metric">
                        <label>Usage:</label>
                        <div class="progress-bar" id="cpuBar"><div class="progress-fill"></div></div>
                        <span id="cpuValue">0%</span>
                    </div>
                    <div class="info-line"><span>Physical Cores:</span> <span id="cpu-physical">-</span></div>
                    <div class="info-line"><span>Logical Cores:</span> <span id="cpu-logical">-</span></div>
                    <div class="info-line"><span>Frequency:</span> <span id="cpu-freq">- MHz</span></div>
                    <div class="info-line"><span>Load Avg:</span> <span id="loadAvg">0.00, 0.00, 0.00</span></div>
                </div>

                <div class="card">
                    <h2>🧠 MEMORY</h2>
                    <div class="metric">
                        <label>RAM:</label>
                        <div class="progress-bar" id="ramBar"><div class="progress-fill"></div></div>
                        <span id="ramValue">0%</span>
                    </div>
                    <div class="info-line"><span>Total RAM:</span> <span id="ram-total">-</span></div>
                    <div class="info-line"><span>Used RAM:</span> <span id="ram-used">-</span></div>
                    <div class="info-line"><span>Available:</span> <span id="ram-available">-</span></div>
                    
                    <div class="metric">
                        <label>SWAP:</label>
                        <div class="progress-bar" id="swapBar"><div class="progress-fill"></div></div>
                        <span id="swapValue">0%</span>
                    </div>
                </div>

                <div class="card">
                    <h2>💾 DISK</h2>
                    <div class="metric">
                        <label>Root:</label>
                        <div class="progress-bar" id="diskBar"><div class="progress-fill"></div></div>
                        <span id="diskValue">0%</span>
                    </div>
                    <div class="info-line"><span>Total:</span> <span id="disk-total">-</span></div>
                    <div class="info-line"><span>Used:</span> <span id="disk-used">-</span></div>
                    <div class="info-line"><span>Free:</span> <span id="disk-free">-</span></div>
                    <div id="partitions-list"></div>
                </div>

                <div class="card">
                    <h2>⏱️ UPTIME</h2>
                    <div class="info-line"><span>System:</span> <span id="uptime">-</span></div>
                    <div class="info-line"><span>Boot Time:</span> <span id="bootTime">-</span></div>
                    <div class="info-line"><span>Users Online:</span> <span id="users-online">-</span></div>
                </div>

                <div class="card">
                    <h2>🌡️ SENSORS</h2>
                    <div id="sensors-list"></div>
                </div>
            </div>
        </div>

        <!-- NETWORK PAGE -->
        <div id="network-page" class="page">
            <div class="dashboard">
                <div class="card">
                    <h2>🌐 NETWORK SPEED</h2>
                    <div class="speed-meter">
                        <div class="speed-item">
                            <span class="speed-label">⬇️ DOWNLOAD</span>
                            <span class="speed-value" id="downloadSpeed">0 B/s</span>
                        </div>
                        <div class="speed-item">
                            <span class="speed-label">⬆️ UPLOAD</span>
                            <span class="speed-value" id="uploadSpeed">0 B/s</span>
                        </div>
                    </div>
                    <div class="info-line"><span>Total Download:</span> <span id="totalDownload">0 B</span></div>
                    <div class="info-line"><span>Total Upload:</span> <span id="totalUpload">0 B</span></div>
                </div>

                <div class="card">
                    <h2>🔌 CONNECTIONS</h2>
                    <div class="info-line"><span>Active Connections:</span> <span id="connections">0</span></div>
                    <div class="info-line"><span>Open Ports:</span> <span id="ports">0</span></div>
                    <div class="info-line"><span>Packets Sent:</span> <span id="packets-sent">0</span></div>
                    <div class="info-line"><span>Packets Received:</span> <span id="packets-recv">0</span></div>
                </div>

                <div class="card full-width">
                    <h2>📡 NETWORK INTERFACES</h2>
                    <div id="interfaces-list"></div>
                </div>
            </div>
        </div>

        <!-- PROCESS PAGE -->
        <div id="process-page" class="page">
            <div class="dashboard">
                <div class="card full-width">
                    <h2>📋 TOP CPU PROCESSES</h2>
                    <div class="process-list">
                        <div class="process-header">
                            <span>PID</span>
                            <span>Name</span>
                            <span>User</span>
                            <span>CPU%</span>
                            <span>RAM%</span>
                            <span>Status</span>
                        </div>
                        <div id="processList"></div>
                    </div>
                </div>
            </div>
        </div>

        <!-- THEMES PAGE -->
        <div id="themes-page" class="page">
            <div class="themes-grid">
                <div class="theme-card" onclick="setTheme('dark-hacker')">
                    <div class="theme-preview dark-hacker"></div>
                    <h3>🌑 Dark Hacker</h3>
                </div>
                <div class="theme-card" onclick="setTheme('green-hacker')">
                    <div class="theme-preview green-hacker"></div>
                    <h3>🌿 Green Hacker</h3>
                </div>
                <div class="theme-card" onclick="setTheme('cyberpunk')">
                    <div class="theme-preview cyberpunk"></div>
                    <h3>⚡ Cyberpunk</h3>
                </div>
                <div class="theme-card" onclick="setTheme('matrix')">
                    <div class="theme-preview matrix"></div>
                    <h3>💚 Matrix</h3>
                </div>
                <div class="theme-card" onclick="setTheme('red-alert')">
                    <div class="theme-preview red-alert"></div>
                    <h3>🔴 Red Alert</h3>
                </div>
                <div class="theme-card" onclick="setTheme('blue-deep')">
                    <div class="theme-preview blue-deep"></div>
                    <h3>🔵 Deep Blue</h3>
                </div>
                <div class="theme-card" onclick="setTheme('purple-haze')">
                    <div class="theme-preview purple-haze"></div>
                    <h3>🟣 Purple Haze</h3>
                </div>
                <div class="theme-card" onclick="setTheme('amber-glow')">
                    <div class="theme-preview amber-glow"></div>
                    <h3>🟠 Amber Glow</h3>
                </div>
                <div class="theme-card" onclick="setTheme('minimal-white')">
                    <div class="theme-preview minimal-white"></div>
                    <h3>⚪ Minimal White</h3>
                </div>
                <div class="theme-card" onclick="setTheme('retro-terminal')">
                    <div class="theme-preview retro-terminal"></div>
                    <h3>📟 Retro Terminal</h3>
                </div>
            </div>
        </div>

        <!-- OWNER PAGE -->
        <div id="owner-page" class="page">
            <div class="owner-card">
                <div class="owner-avatar">👤</div>
                <h2>Nanakusa Chan</h2>
                <div class="owner-info">
                    <div class="owner-item">
                        <span class="owner-label">💬 Discord:</span>
                        <span class="owner-value">nanakusa4me</span>
                    </div>
                    <div class="owner-item">
                        <span class="owner-label">🐙 GitHub:</span>
                        <span class="owner-value">nanakusaChan</span>
                    </div>
                    <div class="owner-item">
                        <span class="owner-label">📁 Project:</span>
                        <span class="owner-value">NEOMON V2</span>
                    </div>
                    <div class="owner-item">
                        <span class="owner-label">📅 Version:</span>
                        <span class="owner-value">2.0.0</span>
                    </div>
                </div>
                <div class="owner-social">
                    <a href="https://github.com/nanakusaChan" target="_blank">GitHub</a>
                    <a href="#" onclick="copyDiscord()">Copy Discord</a>
                </div>
            </div>
        </div>
    </div>

    <script src="assets/matrix-bg.js"></script>
    <script src="script.js"></script>
</body>
</html>
EOF

# ==================== CSS (ENHANCED) ====================
cat > frontend/style.css << 'EOF'
:root {
    --bg-color: #0a0a0a;
    --text-color: #00ff00;
    --card-bg: #0f0f0f;
    --border-color: #00ff00;
    --progress-bg: #1a1a1a;
    --progress-fill: #00ff00;
    --nav-bg: #0c0c0c;
    --hover-color: #00cc00;
}

/* Theme: Dark Hacker */
.theme-dark-hacker {
    --bg-color: #0a0a0a;
    --text-color: #00ff00;
    --card-bg: #0f0f0f;
    --border-color: #00ff00;
    --progress-fill: #00ff00;
    --nav-bg: #0c0c0c;
    --hover-color: #00cc00;
}

/* Theme: Green Hacker */
.theme-green-hacker {
    --bg-color: #001000;
    --text-color: #00ff00;
    --card-bg: #002000;
    --border-color: #00ff00;
    --progress-fill: #00ff00;
    --nav-bg: #001500;
    --hover-color: #00aa00;
}

/* Theme: Cyberpunk */
.theme-cyberpunk {
    --bg-color: #000022;
    --text-color: #ff00ff;
    --card-bg: #110033;
    --border-color: #ff00ff;
    --progress-fill: #ff00ff;
    --nav-bg: #0a0022;
    --hover-color: #cc00cc;
}

/* Theme: Matrix */
.theme-matrix {
    --bg-color: #000000;
    --text-color: #00ff00;
    --card-bg: #001100;
    --border-color: #00ff00;
    --progress-fill: #00ff00;
    --nav-bg: #000a00;
    --hover-color: #00aa00;
}

/* Theme: Red Alert */
.theme-red-alert {
    --bg-color: #220000;
    --text-color: #ff0000;
    --card-bg: #330000;
    --border-color: #ff0000;
    --progress-fill: #ff0000;
    --nav-bg: #1a0000;
    --hover-color: #cc0000;
}

/* Theme: Deep Blue */
.theme-blue-deep {
    --bg-color: #000022;
    --text-color: #33aaff;
    --card-bg: #001133;
    --border-color: #33aaff;
    --progress-fill: #33aaff;
    --nav-bg: #000a1a;
    --hover-color: #2288dd;
}

/* Theme: Purple Haze */
.theme-purple-haze {
    --bg-color: #1a0033;
    --text-color: #cc88ff;
    --card-bg: #2a0044;
    --border-color: #cc88ff;
    --progress-fill: #cc88ff;
    --nav-bg: #15002a;
    --hover-color: #aa66dd;
}

/* Theme: Amber Glow */
.theme-amber-glow {
    --bg-color: #221100;
    --text-color: #ffaa00;
    --card-bg: #332200;
    --border-color: #ffaa00;
    --progress-fill: #ffaa00;
    --nav-bg: #1a0e00;
    --hover-color: #dd8800;
}

/* Theme: Minimal White */
.theme-minimal-white {
    --bg-color: #ffffff;
    --text-color: #000000;
    --card-bg: #f0f0f0;
    --border-color: #cccccc;
    --progress-fill: #000000;
    --nav-bg: #e0e0e0;
    --hover-color: #333333;
}

/* Theme: Retro Terminal */
.theme-retro-terminal {
    --bg-color: #000000;
    --text-color: #33ff33;
    --card-bg: #0a0a0a;
    --border-color: #33ff33;
    --progress-fill: #33ff33;
    --nav-bg: #050505;
    --hover-color: #22dd22;
}

* { margin: 0; padding: 0; box-sizing: border-box; }

body {
    font-family: 'Courier New', monospace;
    background-color: var(--bg-color);
    color: var(--text-color);
    min-height: 100vh;
    position: relative;
    overflow-x: hidden;
}

.matrix-bg {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: 0;
    opacity: 0.1;
    pointer-events: none;
}

.container {
    position: relative;
    z-index: 1;
    max-width: 1400px;
    margin: 0 auto;
    padding: 20px;
}

.navbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    background: var(--nav-bg);
    border: 1px solid var(--border-color);
    padding: 10px 20px;
    margin-bottom: 30px;
    border-radius: 5px;
}

.logo h1 {
    font-size: 1.8em;
    text-shadow: 0 0 10px currentColor;
}

.version {
    font-size: 0.5em;
    opacity: 0.7;
}

.owner-badge {
    font-size: 0.7em;
    opacity: 0.8;
    margin-left: 10px;
}

.nav-links {
    display: flex;
    gap: 10px;
}

.nav-btn {
    background: transparent;
    border: 1px solid var(--border-color);
    color: var(--text-color);
    padding: 8px 15px;
    cursor: pointer;
    font-family: inherit;
    font-size: 0.9em;
    transition: all 0.3s;
}

.nav-btn:hover, .nav-btn.active {
    background: var(--text-color);
    color: var(--bg-color);
}

.page {
    display: none;
}

.page.active {
    display: block;
}

.dashboard {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
    gap: 20px;
}

.card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    padding: 20px;
    border-radius: 5px;
    box-shadow: 0 0 10px rgba(0, 255, 0, 0.1);
}

.card.full-width {
    grid-column: 1 / -1;
}

.card h2 {
    margin-bottom: 15px;
    font-size: 1.2em;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 5px;
}

.metric {
    display: flex;
    align-items: center;
    margin-bottom: 15px;
    gap: 10px;
}

.metric label {
    min-width: 60px;
    font-weight: bold;
}

.progress-bar {
    flex: 1;
    height: 20px;
    background: var(--progress-bg);
    border: 1px solid var(--border-color);
    overflow: hidden;
}

.progress-fill {
    height: 100%;
    background: var(--progress-fill);
    transition: width 0.3s;
    width: 0%;
}

.info-line {
    display: flex;
    justify-content: space-between;
    margin-bottom: 8px;
    padding: 5px 0;
    border-bottom: 1px dashed var(--border-color);
}

/* Welcome Page */
.welcome-card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    padding: 30px;
    border-radius: 5px;
    text-align: center;
}

.welcome-card h2 {
    font-size: 2em;
    margin-bottom: 10px;
}

.features-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 20px;
    margin: 30px 0;
}

.feature {
    padding: 20px;
    border: 1px solid var(--border-color);
    border-radius: 5px;
    background: var(--bg-color);
}

.feature-icon {
    font-size: 2em;
    display: block;
    margin-bottom: 10px;
}

/* Process List */
.process-list {
    margin-top: 10px;
    max-height: 400px;
    overflow-y: auto;
}

.process-header {
    display: grid;
    grid-template-columns: 80px 1fr 100px 80px 80px 100px;
    padding: 10px;
    border-bottom: 1px solid var(--border-color);
    font-weight: bold;
    background: var(--bg-color);
    position: sticky;
    top: 0;
}

.process-row {
    display: grid;
    grid-template-columns: 80px 1fr 100px 80px 80px 100px;
    padding: 8px 10px;
    border-bottom: 1px dashed var(--border-color);
}

.process-row:hover {
    background: rgba(0, 255, 0, 0.1);
}

/* Themes Grid */
.themes-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 20px;
    padding: 20px;
}

.theme-card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 5px;
    padding: 15px;
    text-align: center;
    cursor: pointer;
    transition: transform 0.3s;
}

.theme-card:hover {
    transform: scale(1.05);
}

.theme-preview {
    width: 100%;
    height: 100px;
    border: 1px solid var(--border-color);
    margin-bottom: 10px;
    border-radius: 3px;
}

/* Theme Previews */
.theme-preview.dark-hacker { background: linear-gradient(45deg, #0a0a0a 50%, #00ff00 50%); }
.theme-preview.green-hacker { background: linear-gradient(45deg, #001000 50%, #00ff00 50%); }
.theme-preview.cyberpunk { background: linear-gradient(45deg, #000022 50%, #ff00ff 50%); }
.theme-preview.matrix { background: linear-gradient(45deg, #000000 50%, #00ff00 50%); }
.theme-preview.red-alert { background: linear-gradient(45deg, #220000 50%, #ff0000 50%); }
.theme-preview.blue-deep { background: linear-gradient(45deg, #000022 50%, #33aaff 50%); }
.theme-preview.purple-haze { background: linear-gradient(45deg, #1a0033 50%, #cc88ff 50%); }
.theme-preview.amber-glow { background: linear-gradient(45deg, #221100 50%, #ffaa00 50%); }
.theme-preview.minimal-white { background: linear-gradient(45deg, #ffffff 50%, #000000 50%); }
.theme-preview.retro-terminal { background: linear-gradient(45deg, #000000 50%, #33ff33 50%); }

/* Owner Page */
.owner-card {
    max-width: 500px;
    margin: 50px auto;
    background: var(--card-bg);
    border: 2px solid var(--border-color);
    border-radius: 10px;
    padding: 30px;
    text-align: center;
    box-shadow: 0 0 30px rgba(0, 255, 0, 0.2);
}

.owner-avatar {
    font-size: 5em;
    margin-bottom: 20px;
}

.owner-info {
    margin: 30px 0;
    text-align: left;
}

.owner-item {
    display: flex;
    justify-content: space-between;
    padding: 10px;
    border-bottom: 1px dashed var(--border-color);
}

.owner-label {
    font-weight: bold;
    opacity: 0.8;
}

.owner-value {
    font-family: monospace;
}

.owner-social {
    display: flex;
    gap: 15px;
    justify-content: center;
}

.owner-social a {
    color: var(--text-color);
    text-decoration: none;
    padding: 10px 20px;
    border: 1px solid var(--border-color);
    border-radius: 3px;
    transition: all 0.3s;
}

.owner-social a:hover {
    background: var(--text-color);
    color: var(--bg-color);
}

/* Speed Meter */
.speed-meter {
    display: flex;
    justify-content: space-around;
    margin: 20px 0;
    padding: 20px;
    background: var(--bg-color);
    border: 1px solid var(--border-color);
    border-radius: 5px;
}

.speed-item {
    text-align: center;
}

.speed-label {
    display: block;
    font-size: 0.9em;
    opacity: 0.7;
    margin-bottom: 5px;
}

.speed-value {
    font-size: 1.3em;
    font-weight: bold;
}

/* Responsive */
@media (max-width: 768px) {
    .navbar {
        flex-direction: column;
        gap: 10px;
    }
    
    .nav-links {
        flex-wrap: wrap;
        justify-content: center;
    }
    
    .process-header, .process-row {
        grid-template-columns: 60px 1fr 80px 60px 60px 80px;
        font-size: 0.8em;
    }
}
EOF

# ==================== JAVASCRIPT (ENHANCED) ====================
cat > frontend/script.js << 'EOF'
function formatBytes(b) { 
    if(b===0) return '0 B'; 
    const k=1024; 
    const s=['B','KB','MB','GB','TB']; 
    const i=Math.floor(Math.log(b)/Math.log(k)); 
    return parseFloat((b/Math.pow(k,i)).toFixed(2))+' '+s[i]; 
}

function formatSpeed(b) {
    return formatBytes(b) + '/s';
}

function setTheme(t) { 
    document.body.className = `theme-${t}`; 
    localStorage.setItem('neomon-theme', t); 
}

function copyDiscord() {
    navigator.clipboard.writeText('nanakusa4me');
    alert('Discord username copied!');
}

// Navigation
document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        
        const pageId = btn.dataset.page;
        document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
        document.getElementById(`${pageId}-page`).classList.add('active');
    });
});

// Format helpers
function formatBytesWithUnit(bytes, unit) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    const index = units.indexOf(unit);
    if (index === -1) return formatBytes(bytes);
    return (bytes / Math.pow(1024, index)).toFixed(2) + ' ' + unit;
}

async function fetchSystem() {
    try {
        const r = await fetch('/api/system');
        const d = await r.json();
        
        // System Info
        document.getElementById('hostname').textContent = d.system_info.hostname;
        document.getElementById('os').textContent = `${d.system_info.system} ${d.system_info.release}`;
        document.getElementById('kernel').textContent = d.system_info.version;
        document.getElementById('cpu-model').textContent = d.system_info.cpu_brand;
        document.getElementById('ip-address').textContent = d.system_info.ip_address;
        
        // CPU
        document.getElementById('cpuValue').textContent = d.cpu.percent + '%';
        document.getElementById('cpuBar').querySelector('.progress-fill').style.width = d.cpu.percent + '%';
        document.getElementById('cpu-physical').textContent = d.cpu.cores_physical;
        document.getElementById('cpu-logical').textContent = d.cpu.cores_logical;
        document.getElementById('cpu-freq').textContent = d.cpu.frequency_current.toFixed(0);
        document.getElementById('loadAvg').textContent = d.cpu.load_avg.map(x=>x.toFixed(2)).join(', ');
        
        // Memory
        document.getElementById('ramValue').textContent = d.memory.ram.percent + '%';
        document.getElementById('ramBar').querySelector('.progress-fill').style.width = d.memory.ram.percent + '%';
        document.getElementById('ram-total').textContent = formatBytes(d.memory.ram.total);
        document.getElementById('ram-used').textContent = formatBytes(d.memory.ram.used);
        document.getElementById('ram-available').textContent = formatBytes(d.memory.ram.available);
        
        document.getElementById('swapValue').textContent = d.memory.swap.percent + '%';
        document.getElementById('swapBar').querySelector('.progress-fill').style.width = d.memory.swap.percent + '%';
        
        // Disk
        document.getElementById('diskValue').textContent = d.disk.root.percent + '%';
        document.getElementById('diskBar').querySelector('.progress-fill').style.width = d.disk.root.percent + '%';
        document.getElementById('disk-total').textContent = formatBytes(d.disk.root.total);
        document.getElementById('disk-used').textContent = formatBytes(d.disk.root.used);
        document.getElementById('disk-free').textContent = formatBytes(d.disk.root.free);
        
        // Partitions
        const partitionsDiv = document.getElementById('partitions-list');
        if (partitionsDiv) {
            partitionsDiv.innerHTML = '<h3>Partitions:</h3>';
            d.disk.partitions.forEach(p => {
                partitionsDiv.innerHTML += `
                    <div class="info-line">
                        <span>${p.mountpoint} (${p.fstype}):</span>
                        <span>${p.percent}%</span>
                    </div>
                `;
            });
        }
        
        // Uptime
        document.getElementById('uptime').textContent = d.uptime.uptime_readable;
        document.getElementById('bootTime').textContent = d.uptime.boot_time_readable;
        document.getElementById('users-online').textContent = d.users.length;
        
        // Quick stats for home page
        const quickStats = document.getElementById('quick-stats');
        if (quickStats) {
            quickStats.innerHTML = `
                <div class="info-line"><span>CPU:</span><span>${d.cpu.percent}%</span></div>
                <div class="info-line"><span>RAM:</span><span>${d.memory.ram.percent}%</span></div>
                <div class="info-line"><span>Disk:</span><span>${d.disk.root.percent}%</span></div>
                <div class="info-line"><span>Uptime:</span><span>${d.uptime.uptime_readable}</span></div>
            `;
        }
        
    } catch(e) { 
        console.error('System error:', e); 
    }
}

async function fetchNetwork() {
    try {
        const r = await fetch('/api/network');
        const d = await r.json();
        
        document.getElementById('downloadSpeed').textContent = formatSpeed(d.download_speed);
        document.getElementById('uploadSpeed').textContent = formatSpeed(d.upload_speed);
        document.getElementById('totalDownload').textContent = formatBytes(d.total_download);
        document.getElementById('totalUpload').textContent = formatBytes(d.total_upload);
        document.getElementById('connections').textContent = d.active_connections;
        document.getElementById('ports').textContent = d.open_ports;
        document.getElementById('packets-sent').textContent = d.packets_sent;
        document.getElementById('packets-recv').textContent = d.packets_recv;
        
        // Interfaces
        const interfacesDiv = document.getElementById('interfaces-list');
        if (interfacesDiv) {
            interfacesDiv.innerHTML = '';
            d.interfaces.forEach(iface => {
                interfacesDiv.innerHTML += `
                    <div class="info-line">
                        <span>${iface.interface} (${iface.address}):</span>
                        <span>${iface.netmask || '-'}</span>
                    </div>
                `;
            });
        }
        
    } catch(e) { 
        console.error('Network error:', e); 
    }
}

async function fetchProcess() {
    try {
        const r = await fetch('/api/processes?limit=10');
        const d = await r.json();
        
        const list = document.getElementById('processList');
        if (list) {
            list.innerHTML = '';
            d.top_cpu.forEach(p => {
                const row = document.createElement('div');
                row.className = 'process-row';
                row.innerHTML = `
                    <span>${p.pid||'N/A'}</span>
                    <span>${p.name||'Unknown'}</span>
                    <span>${p.username||'N/A'}</span>
                    <span>${(p.cpu_percent||0).toFixed(1)}%</span>
                    <span>${(p.memory_percent||0).toFixed(1)}%</span>
                    <span>${p.status||'N/A'}</span>
                `;
                list.appendChild(row);
            });
        }
        
    } catch(e) { 
        console.error('Process error:', e); 
    }
}

// Initialize
document.addEventListener('DOMContentLoaded', ()=>{
    const t = localStorage.getItem('neomon-theme')||'dark-hacker';
    setTheme(t);
    
    fetchSystem();
    fetchNetwork();
    fetchProcess();
    
    setInterval(fetchSystem, 2000);
    setInterval(fetchNetwork, 2000);
    setInterval(fetchProcess, 5000);
});
EOF

# ==================== MATRIX BACKGROUND ====================
cat > frontend/assets/matrix-bg.js << 'EOF'
class MatrixBackground {
    constructor() {
        this.canvas = document.createElement('canvas');
        document.querySelector('.matrix-bg').appendChild(this.canvas);
        this.ctx = this.canvas.getContext('2d');
        
        this.resize();
        window.addEventListener('resize', ()=>this.resize());
        
        this.columns = Math.floor(this.width/20);
        this.drops = Array(this.columns).fill(1).map(()=>Math.random()*-this.height);
        
        this.animate();
    }
    
    resize() {
        this.width = window.innerWidth;
        this.height = window.innerHeight;
        this.canvas.width = this.width;
        this.canvas.height = this.height;
    }
    
    animate() {
        this.ctx.fillStyle = 'rgba(0,0,0,0.05)';
        this.ctx.fillRect(0, 0, this.width, this.height);
        
        this.ctx.fillStyle = '#0f0';
        this.ctx.font = '15px monospace';
        
        for(let i=0; i<this.drops.length; i++) {
            const c = String.fromCharCode(0x30A0 + Math.random()*96);
            this.ctx.fillText(c, i*20, this.drops[i]*20);
            
            if(this.drops[i]*20 > this.height && Math.random() > 0.975) {
                this.drops[i] = 0;
            }
            this.drops[i]++;
        }
        
        requestAnimationFrame(()=>this.animate());
    }
}

new MatrixBackground();
EOF

# ==================== README.md ====================
cat > README.md << 'EOF'
# 🧠 NEOMON V2 - Advanced System Monitor

![NEOMON V2](docs/neomon.png)

## 👤 Owner: Nanakusa Chan
- 💬 Discord: **nanakusa4me**
- 🐙 GitHub: **[nanakusaChan](https://github.com/nanakusaChan)**

## 🚀 Features

### 🟢 Core Features
- ✅ Real-time CPU monitoring (per-core, frequency, load average)
- ✅ Memory tracking (RAM, Swap, detailed memory info)
- ✅ Disk usage (partitions, I/O statistics)
- ✅ Network monitoring (speed, total traffic, connections, ports)
- ✅ Process manager (top CPU/RAM processes, details)
- ✅ System information (OS, kernel, hostname, IP)
- ✅ Uptime and user sessions
- ✅ Temperature sensors (if available)
- ✅ Battery status (for laptops)

### 🟡 Hacker Style
- 💻 Matrix rain background effect
- 📊 Animated progress bars with color alerts
- 🎨 **10+ Themes**:
  - 🌑 Dark Hacker
  - 🌿 Green Hacker
  - ⚡ Cyberpunk
  - 💚 Matrix
  - 🔴 Red Alert
  - 🔵 Deep Blue
  - 🟣 Purple Haze
  - 🟠 Amber Glow
  - ⚪ Minimal White
  - 📟 Retro Terminal
- 🎮 Retro terminal aesthetics

### 📱 Pages
- **🏠 HOME**: Overview and feature showcase
- **💻 SYSTEM**: Detailed system metrics
- **🌐 NETWORK**: Network statistics and interfaces
- **📊 PROCESS**: Process monitoring
- **🎨 THEMES**: 10+ themes to choose from
- **👤 OWNER**: Owner information and social links

## 🚀 Quick Start (Arch Linux / CachyOS)

```bash
# Download installer
curl -O https://raw.githubusercontent.com/nanakusaChan/neomon/main/neomon-v2.sh

# Make executable
chmod +x neomon-v2.sh

# Run installer
./neomon-v2.sh

# Start NEOMON
cd ~/neomon-v2
source venv/bin/activate
cd backend
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
