import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property color color: "transparent"
    property color outlineColor: "transparent"
    property color innerOutlineColor: "transparent"
    property real strokeWidth: 0
    property real innerStrokeWidth: 0
    property real radius: 0
    property real exponent: 3.5
    property real radiusScale: 1.25
    property bool directionalShine: false

    function pathFor(inset) {
        const x0 = inset;
        const y0 = inset;
        const x1 = Math.max(x0, width - inset);
        const y1 = Math.max(y0, height - inset);
        const r = Math.max(0, Math.min(radius * radiusScale - inset, (x1 - x0) / 2, (y1 - y0) / 2));
        if (r <= 0)
            return `M ${x0} ${y0} H ${x1} V ${y1} H ${x0} Z`;

        const power = 2 / Math.max(2, exponent);
        const segments = 10;
        let path = `M ${x0 + r} ${y0} H ${x1 - r}`;
        const corners = [
            [x1 - r, y0 + r, -Math.PI / 2, 0],
            [x1 - r, y1 - r, 0, Math.PI / 2],
            [x0 + r, y1 - r, Math.PI / 2, Math.PI],
            [x0 + r, y0 + r, Math.PI, Math.PI * 1.5]
        ];
        for (let corner = 0; corner < corners.length; corner++) {
            const values = corners[corner];
            for (let step = 1; step <= segments; step++) {
                const angle = values[2] + (values[3] - values[2]) * step / segments;
                const cosine = Math.cos(angle);
                const sine = Math.sin(angle);
                const x = values[0] + r * Math.sign(cosine) * Math.pow(Math.abs(cosine), power);
                const y = values[1] + r * Math.sign(sine) * Math.pow(Math.abs(sine), power);
                path += ` L ${x.toFixed(3)} ${y.toFixed(3)}`;
            }
        }
        return path + " Z";
    }

    function shinePathFor(reachDegrees, inset) {
        if (innerStrokeWidth <= 0 || width <= inset * 2 || height <= inset * 2)
            return "";

        const x0 = inset;
        const y0 = inset;
        const x1 = width - inset;
        const y1 = height - inset;
        const r = Math.max(0, Math.min(radius * radiusScale - inset, (x1 - x0) / 2, (y1 - y0) / 2));
        if (r <= 0)
            return "";

        const power = 2 / Math.max(2, exponent);
        const segments = 24;
        const edges = [];
        function addEdge(ax, ay, bx, by, normalDegrees) {
            edges.push([ax, ay, bx, by, normalDegrees]);
        }
        function addCorner(cx, cy, startAngle, endAngle) {
            let previousAngle = startAngle;
            let previousX = cx + r * Math.sign(Math.cos(startAngle)) * Math.pow(Math.abs(Math.cos(startAngle)), power);
            let previousY = cy + r * Math.sign(Math.sin(startAngle)) * Math.pow(Math.abs(Math.sin(startAngle)), power);
            for (let step = 1; step <= segments; step++) {
                const angle = startAngle + (endAngle - startAngle) * step / segments;
                const cosine = Math.cos(angle);
                const sine = Math.sin(angle);
                const x = cx + r * Math.sign(cosine) * Math.pow(Math.abs(cosine), power);
                const y = cy + r * Math.sign(sine) * Math.pow(Math.abs(sine), power);
                const midAngle = (previousAngle + angle) / 2;
                const midCosine = Math.cos(midAngle);
                const midSine = Math.sin(midAngle);
                const u = Math.sign(midCosine) * Math.pow(Math.abs(midCosine), power);
                const v = Math.sign(midSine) * Math.pow(Math.abs(midSine), power);
                const nx = Math.sign(u) * Math.pow(Math.abs(u), exponent - 1);
                const ny = Math.sign(v) * Math.pow(Math.abs(v), exponent - 1);
                let normal = Math.atan2(ny, nx) * 180 / Math.PI;
                if (normal < 0) normal += 360;
                addEdge(previousX, previousY, x, y, normal);
                previousX = x;
                previousY = y;
                previousAngle = angle;
            }
        }
        function angleDistance(a, b) {
            return Math.abs((a - b + 540) % 360 - 180);
        }

        addEdge(x0 + r, y0, x1 - r, y0, 270);
        addCorner(x1 - r, y0 + r, -Math.PI / 2, 0);
        addEdge(x1, y0 + r, x1, y1 - r, 0);
        addCorner(x1 - r, y1 - r, 0, Math.PI / 2);
        addEdge(x1 - r, y1, x0 + r, y1, 90);
        addCorner(x0 + r, y1 - r, Math.PI / 2, Math.PI);
        addEdge(x0, y1 - r, x0, y0 + r, 180);
        addCorner(x0 + r, y0 + r, Math.PI, Math.PI * 1.5);

        let path = "";
        let continuing = false;
        for (let index = 0; index < edges.length; index++) {
            const edge = edges[index];
            const selected = Math.min(angleDistance(edge[4], 90), angleDistance(edge[4], 270)) <= reachDegrees;
            if (selected) {
                if (!continuing)
                    path += ` M ${edge[0].toFixed(3)} ${edge[1].toFixed(3)}`;
                path += ` L ${edge[2].toFixed(3)} ${edge[3].toFixed(3)}`;
            }
            continuing = selected;
        }
        return path;
    }

    function shineColor(alphaScale) {
        return Qt.rgba(innerOutlineColor.r, innerOutlineColor.g, innerOutlineColor.b, innerOutlineColor.a * alphaScale);
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"

            PathSvg { path: root.pathFor(0) }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.strokeWidth > 0 ? root.outlineColor : "transparent"
            strokeWidth: root.strokeWidth
            joinStyle: ShapePath.RoundJoin

            PathSvg { path: root.pathFor(root.strokeWidth / 2) }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.innerStrokeWidth > 0 && !root.directionalShine ? root.innerOutlineColor : "transparent"
            strokeWidth: root.innerStrokeWidth
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap

            PathSvg { path: root.directionalShine ? "" : root.pathFor(root.strokeWidth + root.innerStrokeWidth / 2) }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.innerStrokeWidth > 0 && root.directionalShine ? root.shineColor(0.18) : "transparent"
            strokeWidth: root.innerStrokeWidth
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap

            PathSvg { path: root.directionalShine ? root.shinePathFor(58, root.strokeWidth + root.innerStrokeWidth / 2) : "" }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.innerStrokeWidth > 0 && root.directionalShine ? root.shineColor(0.38) : "transparent"
            strokeWidth: root.innerStrokeWidth
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap

            PathSvg { path: root.directionalShine ? root.shinePathFor(34, root.strokeWidth + root.innerStrokeWidth / 2) : "" }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.innerStrokeWidth > 0 && root.directionalShine ? root.shineColor(0.62) : "transparent"
            strokeWidth: root.innerStrokeWidth
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap

            PathSvg { path: root.directionalShine ? root.shinePathFor(14, root.strokeWidth + root.innerStrokeWidth / 2) : "" }
        }
    }
}
