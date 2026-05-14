import QtQuick

Item {
    id: controller

    required property var shellRoot

    property real _previousCpuTotal: -1
    property real _previousCpuIdle: -1
    property var _previousCpuCoreTotals: []
    property var _previousCpuCoreIdles: []
    property real _previousRxBytes: -1
    property real _previousTxBytes: -1
    property string _previousInterface: ""

    function updateRamStaticInfo(output) {
        const root = shellRoot;
        let type = "", speed = "";
        for (const line of output.split("\n")) {
            const eq = line.indexOf("=");
            if (eq < 0) continue;
            const key = line.slice(0, eq);
            const val = line.slice(eq + 1).trim();
            if (key === "E:MEMORY_DEVICE_0_TYPE" && val) type = val;
            if (key === "E:MEMORY_DEVICE_0_CONFIGURED_SPEED_MTS" && val) speed = val + " MT/s";
        }
        if (type || speed)
            root.ramSpeedText = [type, speed].filter(s => s.length > 0).join("  ·  ");
    }

    function updateCpuStaticInfo(output) {
        const root = shellRoot;
        const coresIdx = output.indexOf("__CORES__");
        const threadsIdx = output.indexOf("__THREADS__");
        const modelRaw = (coresIdx > 0 ? output.slice(0, coresIdx) : output).split(":").slice(1).join(":").trim();
        const coresRaw = (coresIdx >= 0 && threadsIdx > coresIdx) ? output.slice(coresIdx + 9, threadsIdx).split(":").slice(1).join(":").trim() : "";
        const threadsRaw = threadsIdx >= 0 ? output.slice(threadsIdx + 11).trim() : "";
        const modelMatch = modelRaw.match(/\bi[0-9]+-[0-9A-Za-z]+|Ryzen\s+[0-9]+\s+\S+/);
        root.cpuModelShort = modelMatch ? modelMatch[0] : modelRaw.split(/\s+/).pop();
        root.cpuCores = parseInt(coresRaw) || 0;
        root.cpuThreads = parseInt(threadsRaw) || 0;
    }

    function updateFromSnapshot(output) {
        const root = shellRoot;
        const popupOpen = root.systemStatsPopupOpen;
        const sections = root.splitSections(output);

        // Aggregate CPU — always needed for bar
        const statLines = sections.__STAT__ || [];
        const statLine = statLines[0] || "";
        if (statLine) {
            const values = statLine.trim().split(/\s+/).slice(1).map(v => parseInt(v, 10));
            const idle = (values[3] || 0) + (values[4] || 0);
            let total = 0;
            for (let i = 0; i < values.length; i++) total += values[i] || 0;
            if (_previousCpuTotal >= 0 && total > _previousCpuTotal) {
                const totalDiff = total - _previousCpuTotal;
                const idleDiff = idle - _previousCpuIdle;
                root.cpuUsage = Math.max(0, Math.min(100, (1 - idleDiff / totalDiff) * 100));
            }
            _previousCpuTotal = total;
            _previousCpuIdle = idle;
        }

        // Per-core CPU — only when popup is open (full /proc/stat was sent)
        if (popupOpen) {
            const nextCpuCoreTotals = [];
            const nextCpuCoreIdles = [];
            const nextCpuCoreUsages = [];
            for (let i = 1; i < statLines.length; i++) {
                const line = statLines[i] || "";
                if (!/^cpu\d+\s/.test(line)) continue;
                const values = line.trim().split(/\s+/).slice(1).map(v => parseInt(v, 10));
                const idle = (values[3] || 0) + (values[4] || 0);
                let total = 0;
                for (let j = 0; j < values.length; j++) total += values[j] || 0;
                const coreIndex = nextCpuCoreTotals.length;
                let usage = coreIndex < root.cpuCoreUsages.length ? Math.max(0, Math.min(100, Number(root.cpuCoreUsages[coreIndex]) || 0)) : 0;
                const previousTotal = coreIndex < _previousCpuCoreTotals.length ? Number(_previousCpuCoreTotals[coreIndex]) : -1;
                const previousIdle = coreIndex < _previousCpuCoreIdles.length ? Number(_previousCpuCoreIdles[coreIndex]) : -1;
                if (previousTotal >= 0 && total > previousTotal) {
                    const totalDiff = total - previousTotal;
                    const idleDiff = idle - previousIdle;
                    usage = Math.max(0, Math.min(100, (1 - idleDiff / totalDiff) * 100));
                }
                nextCpuCoreTotals.push(total);
                nextCpuCoreIdles.push(idle);
                nextCpuCoreUsages.push(usage);
            }
            _previousCpuCoreTotals = nextCpuCoreTotals;
            _previousCpuCoreIdles = nextCpuCoreIdles;
            root.cpuCoreUsages = nextCpuCoreUsages;
        }

        // Memory — always needed for bar
        const mem = root.parseNumberMap((sections.__MEM__ || []).join("\n"));
        const memTotal = mem.MemTotal || 0;
        const memAvailable = mem.MemAvailable || (mem.MemFree || 0) + (mem.Buffers || 0) + (mem.Cached || 0);
        if (memTotal > 0) {
            root.memoryUsage = ((memTotal - memAvailable) / memTotal) * 100;
            root.memoryUsedGB = (memTotal - memAvailable) / (1024 * 1024);
            root.memoryTotalGB = memTotal / (1024 * 1024);
        }

        // Temperature — always needed for bar
        const tempRaw = parseFloat((sections.__TEMP__ || []).join("\n").trim());
        if (!isNaN(tempRaw))
            root.temperatureC = tempRaw > 1000 ? tempRaw / 1000 : tempRaw;

        // Network — always needed for bar
        const iface = root.parseDefaultInterface((sections.__ROUTE__ || []).join("\n"));
        root.defaultInterface = iface;
        const counters = root.interfaceCounters((sections.__NET__ || []).join("\n"), iface);
        if (!iface || !counters) {
            root.networkRxRate = 0;
            root.networkTxRate = 0;
            _previousRxBytes = -1;
            _previousTxBytes = -1;
            _previousInterface = "";
        } else if (_previousInterface !== iface) {
            _previousInterface = iface;
            _previousRxBytes = counters.rx;
            _previousTxBytes = counters.tx;
            root.networkRxRate = 0;
            root.networkTxRate = 0;
        } else {
            if (_previousRxBytes >= 0 && _previousTxBytes >= 0) {
                root.networkRxRate = Math.max(0, counters.rx - _previousRxBytes);
                root.networkTxRate = Math.max(0, counters.tx - _previousTxBytes);
            }
            _previousRxBytes = counters.rx;
            _previousTxBytes = counters.tx;
        }

        // Load avg + freq + histories — only when popup is open
        if (popupOpen) {
            const loadLine = ((sections.__LOAD__ || []).join("\n").trim()).split(/\s+/);
            root.loadAvg1m  = parseFloat(loadLine[0]) || 0;
            root.loadAvg5m  = parseFloat(loadLine[1]) || 0;
            root.loadAvg15m = parseFloat(loadLine[2]) || 0;

            const freqValues = (sections.__FREQ__ || []).map(l => parseInt(l.trim())).filter(v => v > 0);
            if (freqValues.length > 0)
                root.cpuFreqGHz = Math.max(...freqValues) / 1000000;

            root.cpuHistory = root.appendHistory(root.cpuHistory, root.cpuUsage, root.statsHistoryLimit);
            root.memoryHistory = root.appendHistory(root.memoryHistory, root.memoryUsage, root.statsHistoryLimit);
            root.networkHistory = root.appendHistory(root.networkHistory, root.networkRxRate + root.networkTxRate, root.statsHistoryLimit);
            root.temperatureHistory = root.appendHistory(root.temperatureHistory, root.temperatureC, root.statsHistoryLimit);
        }

        // Power draw history — always while discharging, not gated on popup
        if (root.batteryDischarging) {
            const draw = Math.abs(Number(root.batteryDevice?.changeRate) || 0);
            root.powerDrawHistory = root.appendHistory(root.powerDrawHistory, draw, root.statsHistoryLimit);
        }
    }
}
