const express = require('express')
const fs = require('fs')
const serveStatic = require('serve-static')
const { default: SseStream } = require('ssestream')

const tinyData = ''
const normalData =
    '{"symbol":"AAPL","price":192.45,"change":-1.23,"changePercent":-0.63,"volume":1245678,"timestamp":"2026-01-23T10:45:02Z"}'
const largeData =
    `{"timestamp":"2026-01-23T14:25:30Z","region":"us-east-1","nodes":[{"nodeId":"web-01","status":"healthy","cpuUsage":42.7,"memoryUsage":68.3,"diskUsage":55.1,"latencyMs":48,"activeConnections":1243,"lastHeartbeat":"2026-01-23T14:25:29Z"},{"nodeId":"web-02","status":"degraded","cpuUsage":92.1,"memoryUsage":89.5,"diskUsage":70.2,"latencyMs":312,"activeConnections":2105,"lastHeartbeat":"2026-01-23T14:25:28Z","alerts":["high_cpu","high_latency"]},{"nodeId":"db-primary","status":"healthy","cpuUsage":35.0,"memoryUsage":76.8,"diskUsage":82.4,"latencyMs":5,"activeConnections":89,"lastHeartbeat":"2026-01-23T14:25:30Z"},{"nodeId":"cache-01","status":"unreachable","lastSeen":"2026-01-23T14:24:55Z","error":"connectiontimeout"}],"summary":{"totalNodes":4,"healthy":2,"degraded":1,"down":1}}`

function getData(datasize) {
    if (datasize == '0') {
        return tinyData
    }
    if (datasize == '1') {
        return normalData
    }
    if (datasize == '2') {
        return largeData
    }
    return tinyData
}

const app = express()
app.use(serveStatic(__dirname))
app.get('/sse/range/:page/:count/:interval/:datasize?', (req, res) => {
    // console.log({
    //     method: req.method,
    //     url: req.url,
    //     headers: req.headers,
    //     params: req.params,
    //     query: req.query,
    //     body: req.body
    // });

    let page = Number(req.params.page)
    let count = Number(req.params.count)
    let interval = Number(req.params.interval)
    let data = getData(req.params.datasize)

    res.setHeader('Content-Type', 'text/event-stream')
    res.setHeader('Cache-Control', 'no-cache')
    res.setHeader('Connection', 'keep-alive')
    res.setHeader('Access-Control-Allow-Origin', '*')
    res.setHeader('Transfer-Encoding', 'chunked');

    const pusher = setInterval(() => {
        if (count <= 0) {
            clearInterval(pusher)
            res.end()
            return
        }
        res.write(`event: range\ndata: ${count}${data}\n\n`.repeat(page))
        count--
    }, interval)
    res.on('close', () => {
        console.log('lost connection')
        clearInterval(pusher)
    })
})
app.get('/sse', (req, res) => {
    console.log('new connection')
    console.log('URL:', req.url)
    console.log('Headers:', JSON.stringify(req.headers, null, 2))
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Access-Control-Allow-Origin', '*')
    const sseStream = new SseStream(req)
    sseStream.pipe(res)
    const pusher = setInterval(() => {
        sseStream.write({
            event: 'server-time',
            data: new Date().toTimeString()
        })
    }, 2000)
    res.on('close', () => {
        console.log('lost connection')
        clearInterval(pusher)
        sseStream.unpipe(res)
    })
})
const PORT = process.env.PORT || 9000
app.listen(PORT, '0.0.0.0', (err) => {
    if (err) {
        throw err
    }
    console.log(`server ready on http://0.0.0.0:${PORT}`)
})