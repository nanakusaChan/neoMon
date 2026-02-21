#!/bin/bash

# 🧠 NEOMON - Arch CachyOS SON KURULUM
# Tüm hatalar düzeltildi, çalışır halde

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🧠 NEOMON KURULUYOR...        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════╝${NC}"

# 1. SİSTEM GÜNCELLEME
echo -e "${GREEN}[1/5] Sistem güncelleniyor...${NC}"
sudo pacman -Syu --noconfirm

# 2. GEREKLİ PAKETLER
echo -e "${GREEN}[2/5] Python ve pip yükleniyor...${NC}"
sudo pacman -S --noconfirm python python-pip python-virtualenv

# 3. SANAL ORTAM OLUŞTUR
echo -e "${GREEN}[3/5] Python sanal ortam oluşturuluyor...${NC}"
cd ~
rm -rf neomon  # Eski kurulumu temizle
mkdir -p neomon
cd neomon
python -m venv venv
source venv/bin/activate

# 4. PYTHON PAKETLERİ
echo -e "${GREEN}[4/5] Python paketleri yükleniyor...${NC}"
pip install --upgrade pip
pip install fastapi uvicorn psutil httpx python-multipart

# 5. TÜM DOSYALARI OLUŞTUR
echo -e "${GREEN}[5/5] NEOMON dosyaları oluşturuluyor...${NC}"

mkdir -p backend
mkdir -p frontend/assets

# ==================== BACKEND ====================
cat > backend/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
import psutil
import time
from datetime import datetime
import os

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class SystemMonitor:
    @staticmethod
    def get_cpu():
        return {
            "percent": psutil.cpu_percent(interval=1),
            "cores": psutil.cpu_count(),
            "load_avg": psutil.getloadavg()
        }
    
    @staticmethod
    def get_memory():
        mem = psutil.virtual_memory()
        swap = psutil.swap_memory()
        return {
            "ram": {
                "total": mem.total,
                "used": mem.used,
                "percent": mem.percent
            },
            "swap": {
                "total": swap.total,
                "used": swap.used,
                "percent": swap.percent
            }
        }
    
    @staticmethod
    def get_disk():
        disk = psutil.disk_usage('/')
        return {
            "total": disk.total,
            "used": disk.used,
            "percent": disk.percent
        }
    
    @staticmethod
    def get_uptime():
        boot_time = datetime.fromtimestamp(psutil.boot_time())
        uptime = datetime.now() - boot_time
        return {
            "boot_time": boot_time.isoformat(),
            "uptime": str(uptime).split('.')[0]
        }

monitor = SystemMonitor()
last_network_time = time.time()
last_recv = 0
last_sent = 0

@app.get("/api/system")
async def get_system():
    return {
        "cpu": monitor.get_cpu(),
        "memory": monitor.get_memory(),
        "disk": monitor.get_disk(),
        "uptime": monitor.get_uptime()
    }

@app.get("/api/network")
async def get_network():
    global last_network_time, last_recv, last_sent
    
    net = psutil.net_io_counters()
    current_time = time.time()
    
    if last_network_time and current_time > last_network_time:
        time_diff = current_time - last_network_time
        download_speed = (net.bytes_recv - last_recv) / time_diff
        upload_speed = (net.bytes_sent - last_sent) / time_diff
    else:
        download_speed = upload_speed = 0
    
    last_recv = net.bytes_recv
    last_sent = net.bytes_sent
    last_network_time = current_time
    
    try:
        connections = psutil.net_connections()
        open_ports = len(set([conn.laddr.port for conn in connections if conn.status == 'LISTEN']))
    except:
        connections = []
        open_ports = 0
    
    return {
        "download_speed": download_speed,
        "upload_speed": upload_speed,
        "total_download": net.bytes_recv,
        "total_upload": net.bytes_sent,
        "active_connections": len(connections),
        "open_ports": open_ports
    }

@app.get("/api/processes")
async def get_processes():
    processes = []
    for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
        try:
            pinfo = proc.info
            if pinfo['cpu_percent'] is None:
                pinfo['cpu_percent'] = 0
            if pinfo['memory_percent'] is None:
                pinfo['memory_percent'] = 0
            processes.append(pinfo)
        except:
            pass
    
    top_cpu = sorted(processes, key=lambda x: x['cpu_percent'], reverse=True)[:5]
    
    return {
        "top_cpu": top_cpu,
        "total_processes": len(processes)
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

# ==================== FRONTEND INDEX ====================
cat > frontend/index.html << 'EOF'
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NEOMON - System Monitor</title>
    <link rel="stylesheet" href="style.css">
</head>
<body class="theme-green">
    <div class="container">
        <header>
            <h1>🧠 NEOMON <span class="version">v1.0</span></h1>
            <div class="theme-switcher">
                <button onclick="setTheme('green')">🌿 Green</button>
                <button onclick="setTheme('cyberpunk')">⚡ Cyberpunk</button>
                <button onclick="setTheme('minimal')">⚪ Minimal</button>
                <button onclick="setTheme('red')">🔴 Red</button>
            </div>
        </header>

        <div class="matrix-bg" id="matrixCanvas"></div>

        <div class="dashboard">
            <div class="card">
                <h2>💻 SYSTEM</h2>
                <div class="metric">
                    <label>CPU:</label>
                    <div class="progress-bar" id="cpuBar"><div class="progress-fill"></div></div>
                    <span id="cpuValue">0%</span>
                </div>
                <div class="metric">
                    <label>RAM:</label>
                    <div class="progress-bar" id="ramBar"><div class="progress-fill"></div></div>
                    <span id="ramValue">0%</span>
                </div>
                <div class="metric">
                    <label>DISK:</label>
                    <div class="progress-bar" id="diskBar"><div class="progress-fill"></div></div>
                    <span id="diskValue">0%</span>
                </div>
                <div class="metric">
                    <label>SWAP:</label>
                    <div class="progress-bar" id="swapBar"><div class="progress-fill"></div></div>
                    <span id="swapValue">0%</span>
                </div>
                <div class="info-line">
                    <span>📊 Load Avg:</span>
                    <span id="loadAvg">0.00, 0.00, 0.00</span>
                </div>
            </div>

            <div class="card">
                <h2>🌐 NETWORK</h2>
                <div class="info-line"><span>⬇️ Download:</span><span id="downloadSpeed">0 B/s</span></div>
                <div class="info-line"><span>⬆️ Upload:</span><span id="uploadSpeed">0 B/s</span></div>
                <div class="info-line"><span>📦 Total DL:</span><span id="totalDownload">0 B</span></div>
                <div class="info-line"><span>📦 Total UL:</span><span id="totalUpload">0 B</span></div>
                <div class="info-line"><span>🔌 Connections:</span><span id="connections">0</span></div>
                <div class="info-line"><span>🔓 Open Ports:</span><span id="ports">0</span></div>
            </div>

            <div class="card">
                <h2>⏱️ UPTIME</h2>
                <div class="info-line"><span>🕒 System:</span><span id="uptime">0d 0h 0m</span></div>
                <div class="info-line"><span>🚀 Boot:</span><span id="bootTime">-</span></div>
            </div>

            <div class="card full-width">
                <h2>📋 TOP PROCESSES</h2>
                <div class="process-list">
                    <div class="process-header"><span>PID</span><span>Name</span><span>CPU%</span></div>
                    <div id="processList"></div>
                </div>
            </div>
        </div>
    </div>
    <script src="assets/matrix-bg.js"></script>
    <script src="script.js"></script>
</body>
</html>
EOF

# ==================== CSS ====================
cat > frontend/style.css << 'EOF'
:root {
    --bg-color: #0a0a0a;
    --text-color: #00ff00;
    --card-bg: #0f0f0f;
    --border-color: #00ff00;
    --progress-bg: #1a1a1a;
    --progress-fill: #00ff00;
}
.theme-green { --bg-color: #0a0a0a; --text-color: #00ff00; --card-bg: #0f0f0f; --border-color: #00ff00; --progress-fill: #00ff00; }
.theme-cyberpunk { --bg-color: #000022; --text-color: #ff00ff; --card-bg: #110033; --border-color: #ff00ff; --progress-fill: #ff00ff; }
.theme-minimal { --bg-color: #ffffff; --text-color: #000000; --card-bg: #f0f0f0; --border-color: #cccccc; --progress-fill: #000000; }
.theme-red { --bg-color: #220000; --text-color: #ff0000; --card-bg: #330000; --border-color: #ff0000; --progress-fill: #ff0000; }
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
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}
header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 30px;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 10px;
}
h1 { font-size: 2.5em; text-shadow: 0 0 10px currentColor; }
.version { font-size: 0.5em; opacity: 0.7; }
.theme-switcher button {
    background: transparent;
    border: 1px solid var(--border-color);
    color: var(--text-color);
    padding: 8px 12px;
    margin-left: 10px;
    cursor: pointer;
    font-family: inherit;
}
.theme-switcher button:hover {
    background: var(--text-color);
    color: var(--bg-color);
}
.dashboard {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
}
.card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    padding: 20px;
    border-radius: 5px;
}
.card.full-width { grid-column: 1 / -1; }
.card h2 {
    margin-bottom: 15px;
    font-size: 1.2em;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 5px;
}
.metric {
    display: flex;
    align-items: center;
    margin-bottom: 10px;
    gap: 10px;
}
.metric label { min-width: 60px; }
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
.process-list { margin-top: 10px; }
.process-header {
    display: grid;
    grid-template-columns: 80px 1fr 80px;
    padding: 10px;
    border-bottom: 1px solid var(--border-color);
    font-weight: bold;
}
.process-row {
    display: grid;
    grid-template-columns: 80px 1fr 80px;
    padding: 5px 10px;
    border-bottom: 1px dashed var(--border-color);
}
EOF

# ==================== JAVASCRIPT ====================
cat > frontend/script.js << 'EOF'
function formatBytes(b) { 
    if(b===0) return '0 B'; 
    const k=1024; 
    const s=['B','KB','MB','GB']; 
    const i=Math.floor(Math.log(b)/Math.log(k)); 
    return parseFloat((b/Math.pow(k,i)).toFixed(2))+' '+s[i]; 
}

function setTheme(t) { 
    document.body.className = `theme-${t}`; 
    localStorage.setItem('neomon-theme', t); 
}

async function fetchSystem() {
    try {
        const r = await fetch('/api/system');
        const d = await r.json();
        
        document.getElementById('cpuValue').textContent = d.cpu.percent+'%';
        document.getElementById('cpuBar').querySelector('.progress-fill').style.width = d.cpu.percent+'%';
        
        document.getElementById('ramValue').textContent = d.memory.ram.percent+'%';
        document.getElementById('ramBar').querySelector('.progress-fill').style.width = d.memory.ram.percent+'%';
        
        document.getElementById('diskValue').textContent = d.disk.percent+'%';
        document.getElementById('diskBar').querySelector('.progress-fill').style.width = d.disk.percent+'%';
        
        document.getElementById('swapValue').textContent = d.memory.swap.percent+'%';
        document.getElementById('swapBar').querySelector('.progress-fill').style.width = d.memory.swap.percent+'%';
        
        document.getElementById('loadAvg').textContent = d.cpu.load_avg.map(x=>x.toFixed(2)).join(', ');
        document.getElementById('uptime').textContent = d.uptime.uptime;
        document.getElementById('bootTime').textContent = new Date(d.uptime.boot_time).toLocaleString();
    } catch(e) { 
        console.error('System error:', e); 
    }
}

async function fetchNetwork() {
    try {
        const r = await fetch('/api/network');
        const d = await r.json();
        
        document.getElementById('downloadSpeed').textContent = formatBytes(d.download_speed)+'/s';
        document.getElementById('uploadSpeed').textContent = formatBytes(d.upload_speed)+'/s';
        document.getElementById('totalDownload').textContent = formatBytes(d.total_download);
        document.getElementById('totalUpload').textContent = formatBytes(d.total_upload);
        document.getElementById('connections').textContent = d.active_connections;
        document.getElementById('ports').textContent = d.open_ports;
    } catch(e) { 
        console.error('Network error:', e); 
    }
}

async function fetchProcess() {
    try {
        const r = await fetch('/api/processes');
        const d = await r.json();
        
        const list = document.getElementById('processList');
        list.innerHTML = '';
        
        d.top_cpu.forEach(p => {
            const row = document.createElement('div');
            row.className = 'process-row';
            row.innerHTML = `<span>${p.pid||'N/A'}</span><span>${p.name||'Unknown'}</span><span>${(p.cpu_percent||0).toFixed(1)}%</span>`;
            list.appendChild(row);
        });
    } catch(e) { 
        console.error('Process error:', e); 
    }
}

document.addEventListener('DOMContentLoaded', ()=>{
    const t = localStorage.getItem('neomon-theme')||'green';
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

# ==================== README ====================
cat > README.md << 'EOF'
# NEOMON - System Monitor

## 🚀 HIZLI BAŞLATMA

```bash
cd ~/neomon
source venv/bin/activate
cd backend
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
