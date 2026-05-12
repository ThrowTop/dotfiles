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

    function updateFromSnapshot(output) {
        const root = shellRoot;
        const sections = root.splitSections(output);
        const statLines = sections.__STAT__ || [];
        const statLine = statLines[0] || "";
        if (statLine) {
            const values = statLine.trim().split(/\s+/).slice(1).map(v => parseInt(v, 10));
            const idle = (values[3] || 0) + (values[4] || 0);
            let total = 0;
            for (let i = 0; i < values.length; i++) {
                total += values[i] || 0;
            }
            if (_previousCpuTotal >= 0 && total > _previousCpuTotal) {
                const totalDiff = total - _previousCpuTotal;
                const idleDiff = idle - _previousCpuIdle;
                root.cpuUsage = Math.max(0, Math.min(100, (1 - idleDiff / totalDiff) * 100));
            }
            _previousCpuTotal = total;
            _previousCpuIdle = idle;
        }

        const nextCpuCoreTotals = [];
        const nextCpuCoreIdles = [];
        const nextCpuCoreUsages = [];
        for (let i = 1; i < statLines.length; i++) {
            const line = statLines[i] || "";
            if (!/^cpu\d+\s/.test(line)) {
                continue;
            }
            const values = line.trim().split(/\s+/).slice(1).map(v => parseInt(v, 10));
            const idle = (values[3] || 0) + (values[4] || 0);
            let total = 0;
            for (let j = 0; j < values.length; j++) {
                total += values[j] || 0;
            }
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

        const mem = root.parseNumberMap((sections.__MEM__ || []).join("\n"));
        const memTotal = mem.MemTotal || 0;
        const memAvailable = mem.MemAvailable || (mem.MemFree || 0) + (mem.Buffers || 0) + (mem.Cached || 0);
        if (memTotal > 0) {
            root.memoryUsage = ((memTotal - memAvailable) / memTotal) * 100;
        }

        const tempRaw = parseFloat((sections.__TEMP__ || []).join("\n").trim());
        if (!isNaN(tempRaw)) {
            root.temperatureC = tempRaw > 1000 ? tempRaw / 1000 : tempRaw;
        }

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

        root.cpuHistory = root.appendHistory(root.cpuHistory, root.cpuUsage, root.statsHistoryLimit);
        root.memoryHistory = root.appendHistory(root.memoryHistory, root.memoryUsage, root.statsHistoryLimit);
        root.networkHistory = root.appendHistory(root.networkHistory, root.networkRxRate + root.networkTxRate, root.statsHistoryLimit);
    }
}
